# RG-1 plan: the V-3a register classified at upstream f27a977d8

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 1, 2026-10-27, the planner's draft for review. Records only:
no toolchain, prelude, golden, program or workflow file changes with this plan
or with any commit it specifies. RG-1 is workstream W-342, W-343 and W-344 of
fork/inventory/work-items.json, scheduled by fork/ORCHESTRATION.md Next actions
item 6, on branch claude/carbon-fork-0-1-rg1 cut from trunk 0b999d449.

**Summary.** Every V-3a register entry on trunk and on the sixteen held heads is
classified against upstream's tip f27a977d8 by the rule of fork/rulebook.md R32:
153 entries in 25 blocks and V-3's design-fork entries (section 0.2). The
verdicts are 15 DRIFT, 32 ALIGNED and 106 NONE; 11 entries, five of the DRIFTs
among them, wait on an upstream decision or on an item blocked by one (section
7). Eight DRIFT entries were already carried by items filed before RG-1 (W-109
twice, W-320 with W-324, W-321, W-322, W-326 twice, and SC-1's W-139, whose
break condition has fired at the tip), and seven are filed by this plan as W-346
to W-352. The two R29 decisions are: F-006a's `Ok`/`Err` is a DRIFT (upstream's
design page names `Result` as the choice that represents errors and spells its
alternatives `Success` and `Failure`; W-346, owner EH-C, on trunk after the held
PRs land and before UA-3), and F-009's `overload fn` is NONE (upstream's only
spelling is p002875's self-declared "placeholder syntax", and
pattern_matching.md says there is no approved design). Seven held branches gain
one records commit each (PR 53, PR 52, PR 60, PR 55, PR 56, PR 61 and PR 64), PR
57 and PR 64 also gain a merge commit of their base PR's new head, and RG-1's
own PR is records only, held, base trunk, first in the land sequence.

## Contents

-   §0 Audit
-   §1 Rules and decisions
-   §2 The classification tables
-   §3 Commits, in order
-   §4 Verification
-   §5 Conflicts and the land order
-   §6 Risks and rejected alternatives
-   §7 Residues
-   Appendix A: records texts
-   Hand-off notes for the implementer

## §0 Audit

### §0.1 Upstream's tip

`git -C /home/user/carbon-lang fetch -q upstream trunk` at 2026-10-27 22:00 UTC
gives upstream/trunk f27a977d86e2a4f2af91d9b1a668c2ed299bd055, committed
2026-10-27 21:05:53 UTC, subject "Fix ASan CI failures due to `preserve_none`"
(upstream PR 8045). It is 131 commits past the fork's cut c1e83b0b7 and 14 past
21c825a3f, the tip the weekly check of 2026-10-26 read. Every upstream quote in
this plan is read at f27a977d8 with `git show f27a977d8:<path>` or in the
detached worktree /dev/shm/rg1-planner/up at that sha (deleted when the plan is
committed); none is read from a fork copy of a page (R32 (a)). Section 4.2's
script re-reads all 140 quoted lines; on 2026-10-27 it reports "checked 140
quotes, 0 failed".

The fourteen commits since 21c825a3f, by sha and subject (R32 (c), for the
record of this plan; the next weekly check classifies them):

| Commit | Subject | Paths that matter here |
| --- | --- | --- |
| c7de72757 | Adds support for exporting default values for concrete parameters of generic functions. (upstream PR 8019) | check/cpp/export.cpp; W-341's neighbour, no register entry |
| e9d8d06f9 | Add lifetime comments to CanonicalValueStore and IdentifierStore (upstream PR 8037) | none |
| 8779d15e1 | Optimize the `musttail`-dispatch in the lexer (upstream PR 8034) | lex/lex.cpp |
| 56d9bbc40 | Support C++ friend declarations for Carbon generic classes (upstream PR 8026) | check/cpp/import.cpp |
| 600fd55ba | Add a realistic header compile benchmark (upstream PR 8023) | none |
| dd30c7655 | Bump fast-uri from 3.1.8 to 3.1.9 (upstream PR 8028) | none |
| 57bf903ef | Keep resolving generics and templates until they're all resolved (upstream PR 7957) | check/generic.cpp, generic.h, function.cpp, check_unit.cpp, cpp/generate_ast.cpp; adjacent to CT-1's D-CT-17 and TP-1's entries, no entry's quote |
| 05a7ecbd3 | Move `SubobjectDestroy` and `SelfDestruct` out of interface `Destroy` (upstream PR 7942) | core/prelude/destroy.carbon (`constraint Destroy` at :27, `fn SelfDestruct[T: Destroy](ref t: T)` at :36), check/custom_witness.cpp, sem_ir/core_interface_kind.def; a prelude signature change, see below |
| 7cc1d0898 | Add an AVX2 optimized newline scanner (upstream PR 8032) | lex/lex.cpp |
| 5f1dd4941 | Optimize the horizontal space skip fast path for x86 (upstream PR 8033) | lex/lex.cpp |
| 4c5734a8c | Make tag application and removal a compile time property (upstream PR 8042) | none of check, lower, prelude |
| 33863ed07 | Enhance benchmark source to have more call expressions (upstream PR 8029) | none |
| a45002667 | Clarify the infinitely recursive types through interop test (upstream PR 8046) | a test |
| f27a977d8 | Fix ASan CI failures due to `preserve_none` (upstream PR 8045) | lex/BUILD, lex/lex.cpp |

05a7ecbd3 is the window's one prelude signature change: `Destroy` becomes a
named constraint over the new `SubobjectDestroy` interface and `DestroyImpl`,
and `SelfDestruct` a free function. It changes no quote of this plan and fires
no entry's break condition by text; it touches the files of four entries (SL-1
D-SL-16 and D-SL-19, UA-1's watch-list item 3, OP-2's adapter arms and UN-1's
`CoreInterface` kinds), whose merge rules UA-3 applies. It is recorded here and
in the RG-1 decision-log entry for the next weekly check, which classifies it
under R32 (c); RG-1 files nothing for it (section 6, R-6).

### §0.2 The blocks and their entries

Each block was re-found by its opening words in the decision log at the head
named, not taken from the ledger's line numbers (the script is section 4.4).
"Entries" is the count section 2 enumerates; the split of a block's prose into
entries is section 1's D-RG-12.

| Block | Head read | Lines at that head | Entries |
| --- | --- | --- | --- |
| T0 DR-0's register (post-DR-0; carries work items) | trunk 0b999d449 | :241-247, re-check :249-262 | 3 |
| T1 F-006 / B1's landing note | trunk 0b999d449 | :757-765 (inside the paragraph :742-840) | 3 |
| T2 V-3's design-fork entries F-006a, F-007, F-009, reviewed at UA-1 | trunk 0b999d449 | V-3 :31-41; UA-1's review :6597-6654 (the entries named at :6652-6653) | 7 |
| T3 SL-2 | trunk 0b999d449 | :3686-3697 | 8 |
| T4 OV-3 | trunk 0b999d449 | :4025-4033 | 2 |
| T5 SL-1 | trunk 0b999d449 | :4421-4432 | 11 |
| T6 OV-2 | trunk 0b999d449 | :4718-4726 | 5 |
| T7 OV-1 | trunk 0b999d449 | :4971-4978 | 5 |
| T8 UN-2 | trunk 0b999d449 | :5179-5186 | 2 |
| T9 UN-1 | trunk 0b999d449 | :5476-5484 | 3 |
| T10 EH-B | trunk 0b999d449 | :5596-5617 | 3 |
| T11 EH-A | trunk 0b999d449 | :5961-5971 | 4 |
| T12 UA-1's watch list | trunk 0b999d449 | :6768-6782 | 7 |
| H1 SAFE-1 (PR 53) | claude/carbon-fork-0-1-safe adaae4e35 | :3920-3938 | 15 |
| H2 CM-1 (PR 52) | claude/carbon-fork-0-1-cmake ea573f672 | :3119-3133 | 7 |
| H3 EV-1 (PR 54) | claude/carbon-fork-0-1-ev cb3ef2e74 | :3538-3549 | 4 |
| H4 ST-1 (PR 55) | claude/carbon-fork-0-1-st 21307851a | :3503-3516 | 6 |
| H5 OP-1 (PR 56; PR 57's copy) | claude/carbon-fork-0-1-op 894139b34; op2 a080c7886 | :3529-3541; :4460-4472 | 6 |
| H6 OP-2 (PR 57) | claude/carbon-fork-0-1-op2 a080c7886 | :3779-3792 | 7 |
| H7 DD-1 (PR 58) | claude/carbon-fork-0-1-dd fcee90d9b | :4114-4129 | 6 |
| H8 VA-1 (PR 59; PR 66's copy) | claude/carbon-fork-0-1-va b0822a744; va2 43c8ab476 | :3609-3630; :3609-3630 | 7 |
| H9 SC-1 (PR 60) | claude/carbon-fork-0-1-sc 40a76ab81 | :4187-4202 | 6 |
| H10 TP-1 (PR 61; PR 64's copy) | claude/carbon-fork-0-1-tp 5661a35c8; ct 4a3220c11 | :4185-4208; :4185-4208 | 8 |
| H11 CT-1 (PR 64) | claude/carbon-fork-0-1-ct 4a3220c11 | :8341-8342, its entries in fork/cpp-templates/plan.md §0.10 :935-1004 at that head | 10 |
| C1 DR-0's register as extended on PR 63 and PR 65 (carries work items) | claude/carbon-fork-0-1-dr 89aabd125; dr-idx fee0ef31c | :241-255; :241-256 (the two entries beyond T0's three at :247-254) | 2 |
| C2 VA-2's register entries (PR 66; carry work items) | claude/carbon-fork-0-1-va2 43c8ab476 | :3672-3676 | 6 |

Totals: 25 blocks and the design-fork group T2; 63 entries on trunk (T0 to T12)
and 90 on the held heads (H1 to H11, 82, and C1 and C2, 8): 153. The ledger's
and the weekly check's cites (trunk 563135b40) sit 15 lines earlier for every
trunk block from F-006 on (the 2026-10-26 weekly's paragraph in DR-0 moved
them), and the held cites of W-343 match the heads above. T2 is not a block of
its own in the log: V-3 put F-006a on "a divergence-risk register" (:38-41),
OV-1's block keeps "F-009's register entries (closed sets, first-match, the
marker)" (:4977-4978), UN-1's keeps "the `union` keyword, the class-shaped union
declaration and the byte-reinterpretation read semantics" as "F-007's register
entries" (:5477-5479), and UA-1's review names all three (:6652-6653); RG-1
classifies them together and notes them after UA-1's review. PR 62 (sv,
0ef8a0334), PR 51 (ua2, f96fe8a7a) and PR 66 beyond C2 have no register block of
their own: a scan of each head's log for every block text absent from trunk
(section 4.4) finds none. PR 63's and PR 65's other three DR-0 entries are T0's.

### §0.3 What the 2026-10-26 weekly check already classified

The weekly check (trunk :6784-6923) re-read, at 21c825a3f, DR-0's (i) to (iii)
(resolved on PR 62, DR-1b and PR 63), C1's (iv) and (v) (HOLD; W-324's and
W-326's break conditions not fired) and C2's six (HOLD), each with quotes. For
trunk's eleven pre-DR-0 blocks it quoted only README.md:3164-3166 against
F-006a and p002875:481-485 against F-009 and found that "no window commit adds a
conflict in a file these blocks name"; for the ten held blocks it quoted
SAFE-1's departures; for OP-1's it quoted comparison_operators.md :316 and :434,
p002188:489-490 and pattern_matching.md:526-527. It classified no entry as drift
or none, and filed W-342 to W-344 for that work. Its quotes still hold at the
tip: `git log 21c825a3f..f27a977d8 -- <file>` is empty for every one of the 29
files its table cites (README.md, p002875, sum_types.md, operators/index.carbon,
indexing.md, iterate.carbon, range.carbon, loops.md, generics/terminology.md,
parse/handle_let.cpp, p001013 (its file is
proposals/p001013-generics-set-associated-constants-using-where-constraints.md),
handle_loop_statement.cpp, handle_match.cpp, types/optional.carbon,
lex/token_kind.def, handle_index.cpp, variadics.md, generics/details.md,
comparison_operators.md, type_structure.cpp, handle_pack_expansion.cpp,
operators/comparison.carbon, p002240, p005434, arithmetic.md, safety/README.md,
p005914, p002188 and pattern_matching.md). DR-0's re-check paragraph
(:249-262) stands as written; RG-1 adds no note to it.

### §0.4 The held heads read

All sixteen were read with `git show origin/<branch>:<path>` after `git -C
/home/user/carbon-lang fetch -q origin`; no held worktree was touched and no
held branch checked out. `git rev-parse` of each origin ref matches the task's
heads: PR 51 ua2 f96fe8a7a, PR 52 cmake ea573f672, PR 53 safe adaae4e35, PR 54
ev cb3ef2e74, PR 55 st 21307851a, PR 56 op 894139b34, PR 57 op2 a080c7886, PR
58 dd fcee90d9b, PR 59 va b0822a744, PR 60 sc 40a76ab81, PR 61 tp 5661a35c8, PR
62 sv 0ef8a0334, PR 63 dr 89aabd125, PR 64 ct 4a3220c11, PR 65 dr-idx
fee0ef31c, PR 66 va2 43c8ab476; origin/trunk is 0b999d449. PR 57 contains PR
56's head (merge base 894139b34) and PR 64 contains PR 61's (merge base
5661a35c8).

### §0.5 The id re-scan

CT-1's command (fork/cpp-templates/plan.md §0.11 on PR 64) widened to
`W-3[4-9][0-9]`, run after `git -C /home/user/carbon-lang fetch -q origin` over
135 origin refs, 25 local branches and 22 worktrees (the command is section
4.5): the ledgers hold W-340 (three refs), W-341 to W-344 (nine each) and W-345
(three); the text of `fork/` names W-346 and W-398 only as the bound "W-346 to
W-398" in VA-2's fork/variadics/va2-plan.md (:2830, :4196 and :10787 on PR
66's head) and W-399 only as DR-1's range bound "no id from W-330 to W-399" in
fork/direction/plan.md (PR 63 and PR 65); no ledger holds W-346 or any id above
it. W-345 is VA-2's. RG-1 reserves W-346 to W-359, files W-346 to W-352 and
leaves W-353 to W-359 unused; it changes no item from W-320 to W-345 except the
three it owns, W-342, W-343 and W-344, whose notes it amends (section 3). The
command is repeated before each records commit (section 4.5).

## §1 Rules and decisions

Every decision is auto-adopted under R29(a), recorded in the RG-1 decision-log
entry for after-the-fact veto, and carries its break condition. Ids D-RG-1 to
D-RG-15 are minted in this plan only; RG-1 mints no F id.

**D-RG-1: the classification rule.** For each entry the plan states the fork
mechanism and where it lives at the head read, upstream's text for that
mechanism at f27a977d8 with page and line, and one verdict: DRIFT (upstream has
designed the mechanism and the fork spells it otherwise, R32 (d), whether the
fork's spelling came first or not), ALIGNED (the fork's spelling or rule is
upstream's), or NONE (a fork-local surface with no upstream counterpart:
upstream is silent, shown by the nearest passage or by a grep that finds
nothing). An entry whose classification or realignment waits on an upstream
decision, or on an item blocked by one, is marked "blocked" beside its verdict
and is a residue (section 7). Break condition: an owner directive that
reinstates V-3's override clause (D-DR-4's), which would turn the register back
into notes.

**D-RG-2: the second-spelling test.** Upstream "has designed" a mechanism when
text at the tip (an accepted proposal, a design page, a prelude identity or
signature, or a toolchain TODO that names the mechanism) (i) states or shows it
with a spelling, (ii) is about that mechanism, or names it as Carbon's in a
statement about the mechanism, not a hypothetical in an example whose subject is
another feature, and (iii) does not mark the spelling as placeholder,
provisional or to be decided. When all three hold and the fork's spelling
differs, the entry is a DRIFT. DR-0's three drifts pass it: sum_types.md
declares `Match` and shows `Optional` with `impl as Match` (about the mechanism,
not marked provisional), against PR 62's scrutinee view; iterate.carbon signs
`fn Next(self, ref cursor: CursorType)` (a prelude signature), against the
pointer cursor; index.carbon declares `IndirectIndexWith` with `Ref` returning
`ref ElementType`, against a read-only `Core.Slice`. Examples that fail it here:
p002875:481's "using placeholder syntax" (iii), README.md:622's "This is
provisional" for `String` (iii), functions.md:310's `Thread.Make`, written to
show a lambda capture (ii). Break condition: an owner ruling that illustrative
examples are direction (then T2's `Thread` and the NONE verdicts resting on (ii)
are re-read), or that a placeholder is (then F-009 flips).

**D-RG-3: toolchain-internal surfaces are NONE.** SemIR instruction kinds,
parse node kinds, diagnostic kinds, function parameters, mangling markers,
raw-dump fields, fixes to upstream functions and merge rules are not upstream's
"recorded direction" under R32's list of sources; such an entry is NONE with the
grep that shows upstream has no counterpart, and its merge rule is its break
condition. Upstream's own later internal code (4a8993af2's
`storage_access_block_id`, 05a7ecbd3's `SubobjectDestroy`) is absorbed by the
advance UA-3 under that merge rule, and any item that already schedules the
reconciliation (W-258) is named. A toolchain TODO that names a mechanism is
direction (DR-0's loop TODO): an entry implementing it otherwise is a DRIFT, and
one implementing it as named is ALIGNED (OP-2's adapter arms against
custom_witness.cpp:466-467). Break condition: an upstream design page or
proposal that specifies one of these surfaces.

**D-RG-4: partial implementations.** An entry that implements part of an
upstream-designed mechanism with upstream's spelling, its gap carried by a work
item, is ALIGNED with the gap named (TP-1's D-TP-12 and W-268, OP-2's
`UnformedInit` and W-200). It is a DRIFT only when the fork's rule decides a
case the design decides otherwise (SC-1's D-SC-6). Break condition: a review
that shows a gap item's case decided against the design (then that entry is
re-classified DRIFT and its item re-titled).

**D-RG-5 (R29): F-006a's `Ok`/`Err` is a DRIFT.** Upstream's README names
`Result` as the choice that represents errors ("At this point, errors are
represented using `[choice types](#choice-types)` like `Result` and
`Optional`.", docs/design/README.md:3859-3860; its link markup set in a code
span) and declares it `choice Result(T: type, Error: type)` with `Success(value:
T)` and `Failure(error: Error)` (:3164-3166), as do its `IntResult` example
(:2175-2179) and accepted p000157's running example (:690-692); no upstream text
spells `Ok` or `Err`, and none marks `Success` or `Failure` as placeholder. The
fork's `Core.Result(T, E)` with `Ok(value: T)` and `Err(error: E)`
(core/prelude/types/result.carbon:28-31 at trunk) is a second spelling under
D-RG-2; "illustrative" was V-3's override ground, which V-3b withdrew. The
realignment renames the alternatives (payload names `value` and `error` and the
order, `Success` = 0, already match), with every use: the entry-point epilogue,
EH-B's `<carbon/expected.h>` comments, docs, goldens and programs. It is W-346,
owner EH-C (the `Core.Result` realignment, EH-A's successor), on trunk's base
after the held PRs land and before UA-3, so that it renames the uses PR 54, PR
56, PR 62, PR 63 and PR 65 add (18, 2, 4, 1 and 1 added lines name `Ok` or
`Err`, section 4.6) rather than amending five held PRs for a trunk name
(D-RG-8). Break condition: upstream adds a prelude `Result` or accepts an
error-handling proposal that spells the alternatives otherwise (W-346 takes that
spelling), or changes the README's examples to `Ok`/`Err` (W-346 is withdrawn as
ALIGNED).

**D-RG-6 (R29): F-009's `overload fn` is NONE.** Upstream's only spelling of an
overload-set introducer is p002875's "given the following, using placeholder
syntax:" (:481) before `overloaded fn Abs[...]` (:484-485), and
pattern_matching.md says "We do not yet have an approved design for overloaded
functions" (:696); upstream's lexer has no `overload` or `overloaded` token
(lex/token_kind.def) and its only toolchain mention is sem_ir/function.h:547's
"TODO: Also include parameters to support overloaded functions." The semantics
F-009 chose are ALIGNED: closed same-library sets with
static_open_extension.md:52-54 ("function overloading is limited in Carbon to
only signatures defined together in the same library") and declaration-order
first match with pattern_matching.md:696-697 ("it is anticipated that
declaration order will be used in that case too") and p002875:473-476. Break
condition: upstream accepts an overloading proposal or lands a token or design
page that spells the introducer; the fork then renames (a mechanical change of
lex/token_kind.def:221, the parser and the docs), filed as a DRIFT at that
weekly check.

**D-RG-7: what RG-1 amends on a held branch, and what it only files.** RG-1's
commit on a held branch is records only: the block's dated note, corrections of
a cite that points at a fork copy or of a stale count, and dated notes on the
branch's own ledger items. A realignment that is a mechanical text change with
no consequence elsewhere is RG-1's; there is none this round. A realignment that
changes a design decision (SAFE-1's five departures, which interlock D-SAFE-8,
D-SAFE-11, D-SAFE-14, D-SAFE-15 and D-SAFE-17 across six pages) or code (SC-1's
D-SC-6, OP-1's comparisons) is the filed item's, owned by the PR's workstream,
made by a new commit on that PR's branch under its own review, and RG-1's
commit records the item. Break condition: a reviewer finds one of SAFE-1's five
realignable by restating upstream's sentence alone (then RG-1's commit carries
that edit and the item is discharged with it).

**D-RG-8: a held PR that only uses a trunk spelling does not carry its drift.**
PR 54's tutorial and four other held PRs name trunk's `Ok`/`Err`; the drift is
trunk's prelude, W-346 renames every use after the held PRs land, and no held PR
is amended for it. Break condition: W-346 is scheduled before a held PR that
uses the spelling lands; that PR then gains a rename commit before it lands.

**D-RG-9: an existing item that carries a drift is noted, not re-filed.**
SC-1's W-139 (PR 60's ledger) is the drift of D-SC-6; it gains a dated note on
PR 60, no new id. W-109, W-321, W-322 and W-326 carry T0's, T5's and C1's drifts
already. Break condition: an item's text that no longer describes the drift
(then a new id is filed and the old item cross-referenced).

**D-RG-10: an entry blocked on another item.** OP-1's side-effects entry is a
DRIFT whose realignment needs W-320 (`Core.Optional` matchable by `Match`),
itself blocked on W-324 (upstream's pages conflict on `Match.Continuation`). It
is filed as W-352 with `blocked_by: ["W-320"]`, owner OP-1, re-checked with
W-324 at each weekly upstream check; PR 56 lands with the drift recorded in its
block and the item named, which is R32 (b)'s requirement for an entry that
cannot be realigned before the PR lands. The `None()` entry of the same block
rides W-320 itself. Break condition: W-324's break condition fires, or a
by-reference accessor lands on `Core.Optional` (D-OP-4's other route), and W-352
is unblocked and scheduled before UA-3.

**D-RG-11: held blocks with no drift and no stale cite get no commit.** Their
classification is recorded in trunk's RG-1 entry, which names each block by PR
and line, and their dated note (Appendix A.3) is added to the block by the
records commit of that PR's land sequence. Break condition: a land sequence
without a records commit (the RG-1 entry then stands as the block's note).

**D-RG-12: how a block's prose is split into entries.** Each mechanism a block
names is one entry: a list of names that rename together is one entry (SAFE-1's
library names), each dated departure or decision with its own break condition is
one (SAFE-1's eight departures, SL-1's D-SL-15 to D-SL-20), and a sentence that
only states a merge rule for a file is one. A "the other block's entries stand"
sentence is a cross-reference, not an entry. Break condition: a reviewer's
split that changes a verdict count, folded at rev 2.

**D-RG-13: the order of work.** R1, RG-1's records commit on
claude/carbon-fork-0-1-rg1 (the entry, the trunk notes, the ledger with W-346
to W-352 filed and W-342 discharged, ORCHESTRATION); then the held commits in
the merge order (PR 53, PR 52, PR 60, PR 55, PR 56 with PR 57's merge of it, PR
61 with PR 64's merge of it, then PR 64's own); then R2, the stamp on
claude/carbon-fork-0-1-rg1 recording their shas and discharging W-343 and W-344.
Each held commit's description refresh is written to a scratch file for the
orchestrator (section 3.3). Break condition: a held head that moves between R1
and its commit (that commit is re-based on the new head's text by a fresh read,
never a rewrite).

**D-RG-14: placement of the decision-log entry.** Directly after DR-0 and before
"B0 SF-1..5", because the log groups entries by workstream, DR-0 sits beside V-3
for amending it (V-3b), and RG-1 executes V-3b's "work queue whose entries each
carry a work item" for DR-0's register. Break condition: a log reorganization
that moves DR-0 (RG-1's entry moves with it).

**D-RG-15: ids.** W-346 to W-359 are reserved after the re-scan; W-346 to W-352
are filed by R1, W-353 to W-359 stay unused and are never reused. Break
condition: a re-scan before R1 that finds any of them in a ledger (the reserve
moves to the next free block of fourteen and every cite in Appendix A moves with
it before R1).

## §2 The classification tables

Every row gives the entry's mechanism and where it lives at the head read,
upstream's text at f27a977d8 (quoted verbatim, page:line, a quoted link's markup
set in a code span; section 4.2 re-reads each quoted line), the verdict, the
break condition and the work item. File paths without a repository prefix are
the fork's at the head named for the block; upstream paths are prefixed
"upstream". Each block's dated note is in Appendix A.3 (trunk) or A.4 (held).

### §2.T0 DR-0's register (trunk :241-247; re-check :249-262)

Already a work queue: each entry is a DRIFT with its item, owned by DR-1. Listed
for completeness; RG-1 adds no note (section 0.3).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, resolution |
| --- | --- | --- | --- | --- | --- |
| T0.1 | (i) PR 62's D-SV-7 `Core.Optional(T)` view | upstream sum_types.md:113 `let template Continuation: type;` inside `interface Match` (unchanged since fb7eff130) | DRIFT | D-DR-2's | W-322; resolved on PR 62 by 22fe50ff8 and its fill f4660e409 (D-DR-15) |
| T0.2 | (ii) D-SL-3's read-only `Core.Slice` | upstream core/prelude/operators/index.carbon `IndirectIndexWith` (unchanged since bc45989b2) | DRIFT | DR-1 slice 3's | W-109; resolved on DR-1b, PR 65 (3c54754bc with cf4904138; cdaa15710 with 06b6479d0) |
| T0.3 | (iii) the pointer cursor of `Core.Iterate.Next` at 11 sites | upstream core/prelude/iterate.carbon:17 `fn Next(self, ref cursor: CursorType) -> Optional(ElementType);` | DRIFT | W-321's | W-321; resolved on PR 63 (d0cfe8082 with c1cc72a09) |

### §2.T1 F-006, B1's landing note (trunk :757-765)

Fork: core/prelude/try.carbon at trunk. Upstream: "For now, Carbon does not have
language features dedicated to error handling, but we would consider adding some
in the future." (upstream docs/design/README.md:3858-3859); `git grep -w
ControlFlow` and `git grep -E 'interface Try|Core\.Try|FromBreak'` over upstream
core/, docs/design/ and proposals/ at f27a977d8 find nothing.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T1.1 | (i) the prelude name `Core.ControlFlow` (try.carbon:21) | silent: README.md:3858-3859 above; no `ControlFlow` in upstream | NONE | upstream names a `Try` carrier type | none |
| T1.2 | (ii) the order `ControlFlow(C, B)`, continue first (try.carbon:21-23) | silent, as T1.1 | NONE | as T1.1, with another parameter order | none |
| T1.3 | (iii) the member spellings `Try`, `Branch`, `FromBreak`, `Continue`, `Break` (try.carbon:22-23, :37, :44, :47) | silent, as T1.1 | NONE | upstream designs a `?` operator or its interface | none |

The block's parenthesis "with F-006a's `Ok`/`Err` already on the register" is a
cross-reference to T2.1.

### §2.T2 V-3's design-fork entries F-006a, F-007 and F-009 (V-3 trunk :31-41; UA-1's review :6597-6654)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T2.1 | F-006a: `Core.Result(T, E)`'s alternatives `Ok(value: T)` and `Err(error: E)` (core/prelude/types/result.carbon:28-31) | README.md:3858-3860 "errors are represented using `[choice types](#choice-types)` like `Result` and `Optional`."; :3164-3166 `choice Result(T: type, Error: type) {` / `Success(value: T),` / `Failure(error: Error)`; :2176-2177 `Success(value: i32),` / `Failure(error: String),`; p000157:691 `Success(T: value),` | **DRIFT** (R29, D-RG-5) | D-RG-5's | W-346, owner EH-C, trunk |
| T2.2 | F-007: the `union` introducer keyword (lex/token_kind.def:176) | p000157:234-240 proposes "at least one and preferably both" of a `Storage` type and "A typed `union` facility, such as the one described in proposal" 0139 (:239); no `union` token or design page upstream (`git grep -w union -- toolchain/lex/token_kind.def` finds nothing) | NONE | upstream accepts a `union` proposal or adds the token | none |
| T2.3 | F-007: the class-shaped union declaration (docs/design/unions.md; check: a `SemIR::Class` with `CustomLayoutType`) | silent beyond p000157:239 | NONE | as T2.2 | none |
| T2.4 | F-007: reads as defined byte reinterpretation | silent: no upstream page names union reads | NONE | an upstream union design that makes a read of an inactive field otherwise | none |
| T2.5 | F-009: closed, same-library overload sets | static_open_extension.md:52-54 "function overloading is limited in Carbon to only signatures defined together in the same library." | ALIGNED | upstream allows open or cross-library overloading | none |
| T2.6 | F-009: declaration-order first match | pattern_matching.md:696-697 "We do not yet have an approved design for overloaded functions, but it is anticipated that declaration order will be used in that case too."; p002875:475 "our current intent is to use the former approach" | ALIGNED | upstream designs best-match selection | none |
| T2.7 | F-009: the marker `overload fn` (lex/token_kind.def:221) | p002875:481 "using placeholder syntax:" before :484 `overloaded fn Abs[T:! Unsigned](x: T) -> T { return x; }`; pattern_matching.md:696; upstream function.h:547 "TODO: Also include parameters to support overloaded functions." | NONE (R29, D-RG-6) | D-RG-6's | none |

### §2.T3 SL-2 (trunk :3686-3697)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T3.1 | the `Span` mapping kind, `std::span<T>` to `Core.Slice(T')` on import (check/cpp/custom_type_mapping.cpp:118-136) | interoperability/README.md:255 "TODO: C++ view types such as `std::span` and other standard library types will" have corresponding types in Carbon; README.md:3707-3708 "Other view types, like `std::span`, are intended to map similarly." | ALIGNED | upstream maps `std::span` to another Carbon type, or not at all | none |
| T3.2 | the export arm, `Core.Slice` to `std::span` (`RecognizedTypeInfo::Slice`, check/cpp/type_mapping.cpp:319) | README.md:3704-3708 (views "map transparently between C++ and the Carbon equivalents") | ALIGNED | as T3.1 | none |
| T3.3 | the synthesized `CoreInterface::CppContiguousRange` and its witness (sem_ir/core_interface_kind.def:22, check/cpp/impl_lookup.cpp:600-610) | silent: no `CppContiguousRange` upstream; its nearest is upstream's `CppRangeForIterate` kind (core_interface_kind.def:22 at the tip) for range-for | NONE | upstream synthesizes contiguous-range access another way (D-SL-9's, W-120) | W-120 |
| T3.4 | both prelude interop sections (core/prelude/types/cpp/slice.carbon; types/slice.carbon:100-106's blanket impl) | silent: upstream has no `Slice` (`git grep -w Slice -- core toolchain/check toolchain/sem_ir` finds nothing) | NONE | as T3.3 | none |
| T3.5 | D-SL-8: the name follows upstream's slice type when named | README.md:912 "**TODO:** Slices"; p004682:326 "is the closest fit with the current provisional syntax" for slices | NONE | upstream names its slice type (rename, layout unchanged) | none |
| T3.6 | D-SL-9: the witness synthesis | as T3.3 | NONE | D-SL-9's | W-120 |
| T3.7 | D-SL-21: the owning-to-view impl lives beside `Slice` (upstream's orphan rule applied) | upstream check/impl_validation.cpp `DiagnoseOrphanImpl` (the rule the fork applies; the block itself calls it "a fork convention, not a divergence") | ALIGNED | upstream changes its orphan rule | none |
| T3.8 | D-SL-24: a C++ element whose copy constructor is deleted still maps | silent: upstream's `BuildCopyWitness` imports the deleted declaration as the witness | NONE | `BuildCopyWitness` declines deleted copy constructors | none |

### §2.T4 OV-3 (trunk :4025-4033)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T4.1 | the `NamedDeclList` alternative of `MapInstIdToClangDeclOrType` and its `FindExternalVisibleDeclsByName` case (check/cpp/generate_ast.cpp:166-172, :275, :330) | silent: `grep -c NamedDeclList` of upstream check/cpp/generate_ast.cpp is 0 | NONE | upstream's external-source hand-off grows a list shape (keep whichever delivers every member) | none |
| T4.2 | `overload_index` on a generated thunk (check/cpp/export.cpp:1388-1389) | silent: function.h:547's TODO above; no keying | NONE | upstream's overloading keys its own thunks | none |

The block's "OV-1's and OV-2's entries stand" is a cross-reference (T6, T7).

### §2.T5 SL-1 (trunk :4421-4432)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T5.1 | the builtins `pointer.offset`, `fail_stop`, `heap.allocate`, `heap.free` (sem_ir/builtin_function_kind.def:154, :157, :160-161) | values.md:1128-1129 "raw pointer arithmetic is expected to be provided at some point, but through specialized constructs given the specialized nature of these operations."; no such builtin upstream | NONE | upstream adds such builtins or constructs | none |
| T5.2 | `Core.Slice(T)` (core/prelude/types/slice.carbon:24), D-SL-1 | README.md:912 "**TODO:** Slices"; p004682:326's "current provisional syntax" `[T]` | NONE | upstream names the slice type or its literal syntax | none |
| T5.3 | `Core.Buf(T)` (core/prelude/types/buf.carbon:26) | README.md:885-886 "A heap-allocated dynamically sized array is written `buf(T)`, which is a shorthand for the library type `Core.Buf(T)`." | ALIGNED (the `buf(T)` shorthand is the gap) | upstream renames `Core.Buf` | W-110 (the shorthand) |
| T5.4 | the `Iterate` impl of `Slice(T)` (core/prelude/iterate.carbon:86-87) | upstream iterate.carbon:17 (the interface the impl implements) | ALIGNED | upstream changes `Iterate` (T0.3 is the cursor's drift) | W-321 for the cursor |
| T5.5 | D-SL-15: builtin operands' pointee completeness | silent: no general completeness rule for builtin operands upstream | NONE | upstream adds one (fold into it) | none |
| T5.6 | D-SL-16: a class's declared `Destroy` impl wins destroy lookup | silent on the mechanism; 05a7ecbd3 (2026-10-26) makes upstream's `Destroy` a constraint over `SubobjectDestroy` and `DestroyImpl` (destroy.carbon:27-29) with `fn SelfDestruct[T: Destroy](ref t: T)` (:36) | NONE | upstream's destroy-op synthesis calls declared impls; UA-3 measures whether 05a7ecbd3 does (section 6, R-6) | none |
| T5.7 | D-SL-17: the literal-subscript rule (check/handle_index.cpp:107-114 comment and the rule) | indexing.md:105 `impl as IndexWith(like i64) {`; lex/token_kind.def:208 a `Like` keyword token only | DRIFT, blocked (on `like`) | W-326's | W-326 (DR-1, PR 63's and PR 65's ledgers; DR-1b's `LiteralSubscriptTargetType` replaces the rule) |
| T5.8 | D-SL-18: the prelude container impls are `final` | silent: upstream has no slice or buffer impls | NONE | upstream's own container impls | none |
| T5.9 | D-SL-19: `HasUserDestroyImpl` keyed by class | silent; as T5.6 | NONE | as T5.6 | none |
| T5.10 | D-SL-20: a `Buf` byte count that overflows fails-stop | silent | NONE | an upstream allocation design | none |
| T5.11 | D-SL-3's read-only element access, "if `IndirectIndexWith`/`ref` returns land" | upstream operators/index.carbon `IndirectIndexWith` with `Ref` (T0.2) | DRIFT | T0.2's | W-109, resolved on PR 65 |

### §2.T6 OV-2 (trunk :4718-4726)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T6.1 | the diagnostic kinds `OverloadSetFrozen`, `OverloadSetDeclaredHere` (diagnostics/kind.def:306-307) | silent: no overload sets upstream (T2.7) | NONE | upstream overloading's diagnostics | none |
| T6.2 | the `replace_prev_inst` and `prev_decl_override` parameters, MOVED at UA-1 to `MergeOverloadMemberRedecl` (check/handle_function.cpp:177, :391) with `replace_prev_inst` dropped | silent: upstream's `TryMergeRedecl` has no member-targeted entry point | NONE | upstream's `TryMergeRedecl<Function>` grows one (retires the function) | none |
| T6.3 | the `diagnose` parameter of `DeduceGenericCallArguments` (check/deduce.h:18-25) | silent (an internal parameter) | NONE | upstream adds its own non-diagnosing deduction | none |
| T6.4 | the `GetApiClassDeclForQualifier` arm of `ResolveAsScope` (check/decl_name_stack.cpp:462, :523) | silent: a fix to upstream's resolution of `fn C.F` in an impl file | NONE | upstream lands its own (keep whichever resolves it) | none |
| T6.5 | the `OverloadSetValue` arm of `AddImportRefOrMerge` (check/import.cpp:359, :388) | silent (internal) | NONE | upstream's own import of sets | none |

### §2.T7 OV-1 (trunk :4971-4978)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T7.1 | the `overload` keyword (lex/token_kind.def:221), F-009's marker | T2.7's quotes | NONE (R29, D-RG-6) | D-RG-6's | none |
| T7.2 | the `:overload<N>` mangling marker (sem_ir/mangler.cpp:217-230) | silent: function.h:547's TODO | NONE | upstream mangles overloads | none |
| T7.3 | the `OverloadSetType`/`OverloadSetValue` inst kinds and the `OverloadSetId` store (sem_ir/inst_kind.def:129-130, ids.h:299) | silent (internal) | NONE | upstream's own representation | none |
| T7.4 | the five diagnostic kinds `OverloadMarkerMismatch`, `OverloadMarkerPrevious`, `OverloadCandidateRejected`, `OverloadNoMatch`, `OverloadSetNotCallee` (diagnostics/kind.def:304-305, :315-317) | silent | NONE | upstream's diagnostics | none |
| T7.5 | the `overload_set_id` field of `Function::Print` (sem_ir/function.h:191, :279-280) | silent | NONE | upstream's field | none |

### §2.T8 UN-2 (trunk :5179-5186)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T8.1 | `clang::TagTypeKind::Union` on export (check/cpp/export.cpp:81-82) | silent: upstream exports no Carbon union (no `union` declaration, T2.2) | NONE | upstream exports unions | none |
| T8.2 | the offset-zero layout arm (check/cpp/generate_ast.cpp:590's `layoutRecordType`, which supplies an offset of zero for every field, check/cpp/export.cpp:78-81) | silent | NONE | as T8.1 | none |

### §2.T9 UN-1 (trunk :5476-5484)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T9.1 | `Core.UnformedInit` as a `CoreInterface` kind and `CoreIdentifier` (sem_ir/core_interface_kind.def:42, check/core_identifier.def:95) | upstream core/prelude/default.carbon:17 `interface UnformedInit {` (the prelude interface the fork recognizes); upstream's kinds do not list it, and 05a7ecbd3 removed `Destroy` from them | NONE | upstream recognizes `UnformedInit` itself (keep upstream's) | none |
| T9.2 | the `is_union` raw-dump field (sem_ir/class.h:92, :143) | silent: `git grep -c is_union` upstream toolchain/ is 0 | NONE | as T8.1 | none |
| T9.3 | the four diagnostic kinds (diagnostics/kind.def:373-376) | silent | NONE | as T8.1 | none |

### §2.T10 EH-B (trunk :5596-5617)

Upstream's direction for the area: "Carbon may not provide seamless
interoperability support for C++ exceptions. For example, translating C++
exceptions to or from Carbon errors might require annotations or bridge code"
and "if Carbon code calls a C++ function without suitable annotations or
bridging, and that function exits with an exception, the program might
terminate" (upstream interoperability/philosophy_and_goals.md:405-410). The
fork's bridging fits it; its spellings are fork-local.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T10.1 | (i) `Cpp.Exception` as `Carbon::Exception { void* primary_; }` whose `.ptr()` is the `std::exception_ptr` (toolchain/install/include/carbon/expected.h:85) | silent: no `Exception` in upstream core/ or interoperability pages | NONE | upstream designs an exception mapping | none |
| T10.2 | (ii) `<carbon/expected.h>` mirroring the choice layout, with the foreign-exception contract (expected.h:30, :200-202) | silent: `git grep -c -i 'std::expected\|expected<'` of upstream docs/design and proposals is 0 | NONE | as T10.1 | none |
| T10.3 | (iii) the catching thunk's names `<callee>__carbon_catching_thunk` and `.carbon_thunk_catch.<modes>` (check/cpp/thunk.cpp:598) | silent | NONE | as T10.1 | none |

### §2.T11 EH-A (trunk :5961-5971)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T11.1 | (i) `Core.Result(T, E)` as an independent prelude choice with a `final` `Try` impl (types/result.carbon:28, :40) | README.md:3860 "represented using `[choice types](#choice-types)` like `Result` and `Optional`."; :3164 `choice Result(T: type, Error: type) {` | ALIGNED (a choice; its alternatives are T2.1's drift) | upstream makes `Result` a class or a library type of another shape | W-346 for the alternatives |
| T11.2 | (i) the library name "prelude/types/result" (types/result.carbon:5) | silent: no `Result` library upstream | NONE | upstream adds one (take its name) | none |
| T11.3 | (i) the first-alternative-is-success order, discriminant 0 (types/result.carbon:21-23, :28-31) | README.md:3165-3166 (`Success` first, then `Failure`) | ALIGNED | upstream orders them otherwise | none |
| T11.4 | (ii) the `()` payload admission (check/type.cpp:337-360) | silent: upstream's choice design has no payload allowlist | NONE | upstream lands a choice layout | none |

### §2.T12 UA-1's watch list (trunk :6768-6782)

Each item is fork code inside an upstream function, marked "Fork (D-UA-n)":
D-RG-3 makes each NONE with its merge rule.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T12.1 | the `if constexpr (IsClass)` union clauses in `TryMergeRedecl` (check/merge.cpp:740, :798) | silent (upstream has no union declaration) | NONE | upstream's own clause | none |
| T12.2 | `TryMergeOverloadDecl` before `TryMergeRedecl` in `BuildFunctionDecl` (check/handle_function.cpp:465, :1145) | silent | NONE | upstream's member-targeted `TryMergeRedecl<Function>` (retires `MergeOverloadMemberRedecl`) | none |
| T12.3 | the `is_choice`/`CustomLayoutType` clauses of `MakeSubobjectDestroyOpBody` (check/custom_witness.cpp:297-305, :872) | silent; upstream rewrote the file in 05a7ecbd3 (UA-3's conflict, not a design) | NONE | upstream's own clause | none |
| T12.4 | the fork-only `return_type_id` alternative in `FunctionDeclArgs` (check/function.h:54-55) | silent | NONE | upstream's | none |
| T12.5 | `BeginConditionalExprOperand`/`EndConditionalExprOperand` (check/control_flow.h:117-120) | silent: no such function upstream | NONE | upstream conditionalizes arm cleanups (retires W-122's guard) | none |
| T12.6 | the null guard in `TryMapType`'s `FunctionType` arm (check/cpp/type_mapping.cpp:428) | silent | NONE | upstream's own guard | none |
| T12.7 | the null guard in `ExportFunctionToCppPointerConversion` (check/cpp/export.cpp:1646) | silent | NONE | upstream's own guard | none |

### §2.H1 SAFE-1 (PR 53, adaae4e35 :3920-3938)

Fork: PR 53's docs/design/safety/ pages and its F-013 entry (the D-SAFE
decisions at :3044-3600 of PR 53's log). PR 53 is documentation and records
only, so every realignment is text; D-RG-7 assigns the five DRIFTs to SAFE-1
because each changes a decision the other pages depend on. PR 53 lands first,
so these five gate the land sequence (section 5).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H1.1 | `exclusive` (the `exclusive T*` pointer kind, D-SAFE-7) | p005914:182-184 "We expect to have more distinguished types of pointers in Carbon ... including both shared mutable pointers, and exclusive mutable pointers"; no spelling upstream | NONE (the kinds follow p005914's direction; the keyword is the fork's) | upstream spells its pointer kinds | none |
| H1.2 | `unsafe permissive` (the mode marker) | safety/README.md:116-118 "Define the exact syntax ... The syntax for enabling the permissive mode must include the `unsafe` keyword" | ALIGNED | upstream defines the syntax otherwise | none |
| H1.3 | `unsafe import` (D-SAFE-6) | safety/README.md:122 "**Future work**: Define how to mark `import`s of permissive libraries in" various contexts | NONE | upstream defines the marker | none |
| H1.4 | `unsafe class` | silent: `git grep -c 'unsafe class'` over upstream docs/design and proposals is 0 | NONE | upstream designs unsafe types | none |
| H1.5 | `addr self: Self*` restored | p005434:1226 "### Restore `addr`" (under "## Future work", :1130): "To allow the `self` parameter to use one of the pointer semantics we create as part of the upcoming memory safety design, that can't be achieved with `ref`." (:1234-1236) | ALIGNED | upstream's memory-safety design restores `addr` otherwise, or not at all | none |
| H1.6 | the prefix `unsafe` forms (`unsafe F(args)`, `unsafe *p`, `unsafe p->m`, `unsafe u.f`, `unsafe &u.f`, `unsafe s[i]`, `unsafe (...)`, `unsafe fn F(...) = "name"`) | safety/README.md:80-81 "We instead focus on the narrow and specific unsafe operations and constructs."; :98-99 "_Strict Carbon_ is the mode in which all unsafe code is marked with the `unsafe` keyword" | ALIGNED (the per-operation keyword; the forms' grammar is the fork's) | upstream designs another marking | none |
| H1.7 | the library names `Core.Plain`, `Guarded`, `Box`, `Send`, `Sync`, `Freeze`, `Relocatable`, `Lifetime`, `DynCast`, `Move`, `Utf8`, `Atomic`, `Thread` | silent: no upstream type of these names (`git grep -w` over docs/design, core and the two safety proposals finds none, `Lifetime` and `Atomic` only in headings); `Box(T)` is p004682:322's placeholder ("`Box(T)` for a heap-allocated `T` value."); README.md:2150's move operator "is provisional"; functions.md:310's `Thread.Make` is a lambda example (D-RG-2 (ii)) | NONE | upstream names any of them (each renames) | none |
| H1.8 | p005434:83 narrowed: `noalias`/`captures(none)` only for exclusive-kind refs (D-SAFE-8, PR 53 :3098-3125) | p005434:83 "The address of a `ref` binding is `nocapture` and `noalias`." | **DRIFT** | an accepted upstream memory-safety proposal that narrows :83 | W-347, owner SAFE-1 |
| H1.9 | p005434:663 narrowed: in Strict, `Plain`-field writes through other shared aliases during a non-`Plain` value binding stay erroneous and Debug-detected, not prevented (D-SAFE-17, PR 53 :3532-3568) | p005434:660-664 "Mutation of objects with a non-copy-value representation in an active value binding ("borrowed objects") is erroneous behavior." / "Our plan is to prevent mutation of borrowed objects in Carbon's strict safe dialect." | **DRIFT** | upstream relaxes :663 (its :665-669 conditions) | W-348, owner SAFE-1 |
| H1.10 | p005434:831-832 narrowed: a bound argument stays "not invalidated", not "immutable", for a returned loan's duration (D-SAFE-11(d), PR 53 :3297-3330) | p005434:831-832 "For full safety, we need each bound parameter to be immutable for the duration of the lifetime of the returned result."; :834 "We will reconsider this with the memory safety design." | **DRIFT** | upstream's memory-safety design reconsiders it otherwise | W-349, owner SAFE-1 |
| H1.11 | arithmetic.md's performance-build row withdrawn for Carbon code (D-SAFE-15, PR 53 :3483-3495; the block's ":155-158" is upstream's :156-158) | arithmetic.md:156-158 "In a performance build, the optimizer can assume that such conditions don't occur. As a consequence, if they do, the behavior of the program is not defined." | **DRIFT** | upstream withdraws or rewrites the row | W-350, owner SAFE-1 |
| H1.12 | safety/README.md:260-262's benchmarking disable withdrawn (D-SAFE-14, PR 53 :3427-3482) | safety/README.md:260-261 "Carbon will provide a way to disable the default hardening in release builds, but not in a supported way. Its use is expected to be strictly for benchmarking" purposes. | **DRIFT** | upstream withdraws the promise | W-351, owner SAFE-1 |
| H1.13 | zero-fill promoted to the Release baseline for every type (D-SAFE-13 I5); the block cites "docs/design/README.md:2147", PR 53's own copy (its :2144-2153) | README.md:2130-2132 "Types may define additional initialization for the `[hardened build mode](#build-modes)`. For example, this causes integers to be set to `0` when in unformed state in this mode."; safety/README.md:219 "The release build will include a baseline of hardening necessary to uphold the" memory-safety model; p005914:87-88 "Requires initialization errors to not have undefined behavior, but allows, for example, zero-initialization rather than fail-stop behavior." | ALIGNED (cite corrected by PR 53's commit) | upstream re-specifies a separate hardened mode, or makes unformed initialization type-defined only | none |
| H1.14 | the Permissive reading of p005914:206-208 (D-SAFE-18): Permissive assumes unannotated C++ pointer parameters do not escape, a diagnostic assumption only, while T8 withholds `noalias`/`captures(none)` at every such boundary | p005914:205-207 "To avoid undefined behavior, the optimization of safe code will not rely on properties that are not established locally. For example, there won't be an assumption that a call to C++ code won't save a copy" of pointers | ALIGNED (no optimization relies on it; the sentence governs optimization) | upstream extends the rule to diagnostics | none |
| H1.15 | the `import Cpp` asymmetry (D-SAFE-6, A-13): `import Cpp` needs no marker | safety/README.md:122-124's future work, as H1.3 | NONE | as H1.3 | none |

The block's re-basing clause ("If upstream lands the dedicated memory-safety
proposals p005914 defers to, every D-SAFE is re-based under V-3") is the block's
break condition, not an entry; under V-3b it reads "re-based under R32".

### §2.H2 CM-1 (PR 52, ea573f672 :3119-3133)

Upstream's direction for the area: milestones.md:230-231 "Build system
integration for CMake, and documentation for integrating with Make or similar
build systems." (a 0.1 deliverable, also :222-223) and p006333:368-370 ("The
intent is to be able to migrate a CMake, Makefile, or other build at relatively
low cost"). Upstream has no CMake files: `git ls-tree -r --name-only f27a977d8 |
grep -c -E 'CMakeLists.txt|\.cmake$'` is 0.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H2.1 | the module and helper names `CMAKE_Carbon_*`, `carbon_add_library`, `carbon_add_executable`, `carbon_add_core_library`, `Carbon::core_io` (cmake/CMakeCarbonInformation.cmake, cmake/CarbonTargets.cmake) | silent on names; p006333:371's `carbon_library` and `carbon_binary` are Bazel rules | NONE | upstream ships its own CMake support (rename) | none |
| H2.2 | the block's claim that upstream's "thirteen `cmake` mentions are Bazel-internal" (measured on the fork's tree, its plan's audit row 1 counting two fork workflows) | at the tip `grep -rli cmake` outside .git, third_party, fork and testdata finds thirteen files, nine build or toolchain files and four texts: docs/project/milestones.md (:223, :230-231), proposals/p006333 (:368-370, :397-398, :418-421), docs/project/contribution_tools.md and proposals/p003797 | ALIGNED (CM-1 is milestones.md:230-231's deliverable; the claim is corrected by PR 52's commit) | upstream re-scopes the milestone | none |
| H2.3 | README.md's one-line pointer and the `/examples/cmake/build-make/` line in .gitignore | silent (upstream-owned text the fork touches) | NONE | an upstream edit of those lines (merge rule) | none |
| H2.4 | the `BUILD-SCRIPT` directive (fork harness) | silent | NONE | none | none |
| H2.5 | D-CM-6's sibling wiring for the driver's single input per output | compile_subcommand.cpp:43-46 "we can only support a single input filename." with its TODO; p006333:99-100 "`carbon compile`: Take a single input to build, and produce a single output" `.o` | NONE (a build script around upstream's driver, no second driver mechanism) | the driver gains p006333's dependency mapping or multi-output (delete the wiring) | none |
| H2.6 | D-CM-7's helper and D-CM-5's failing rule (Core objects, shared libraries) | silent | NONE | `carbon link` learns the Core objects (W-003) or shared libraries (W-132) | W-003, W-132 |
| H2.7 | D-CM-9's NASM-style wiring through `OBJECT_DEPENDS` | silent: upstream's driver writes no depfile | NONE | the driver writes a depfile (W-129) | W-129 |

### §2.H3 EV-1 (PR 54, cb3ef2e74 :3538-3549)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H3.1 | the three guide pages docs/guides/getting_started.md, tutorial.md and evaluator_faq.md, fork files in an upstream directory | silent: `git ls-tree --name-only f27a977d8 docs/guides/` lists README.md and glossary.md only | NONE | upstream ships guides or a user FAQ there (D-EV-9's) | none |
| H3.2 | they teach the fork's features (choice payloads, `match`, `Core.Result` and `?`, if-let) | as each feature's own entry (T1, T2.1, T11) | NONE | each feature's own | the tutorial's 18 `Ok`/`Err` lines are W-346's renames (D-RG-8) |
| H3.3 | upstream-owned text touched: README.md's two pointer lines, docs/project/faq.md's sentence, docs/guides/README.md's three items; README's shell commands untouched (D-EV-15) | silent (merge rule) | NONE | an upstream rewrite of README "Getting started" (re-place the pointers) | none |
| H3.4 | the twelve transcribed programs under fork/conformance | silent (fork harness) | NONE | none | none |

### §2.H4 ST-1 (PR 55, 21307851a :3503-3516)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H4.1 | the owning `Core.StringBuf` (D-ST-4); the block cites "README.md:629's owning `String`", the fork's copy (trunk's README.md:629) | README.md:622 "This is provisional, no design for string types has been through the" proposal process; :627 "`String` - a byte sequence treated as containing UTF-8 encoded text."; p006177:147 "The choice of `Str` over `String` for the" non-owning view; upstream's prelude `class String` (core/prelude/types/string.carbon:16) is still the view | NONE (D-RG-2 (iii); the cite is corrected by PR 55's commit) | upstream renames its view to `Core.Str` and names the owning type (`StringBuf` takes that name, D-ST-4's) | none |
| H4.2 | `+` on strings decides issue 457 for the fork (D-ST-7) | arithmetic.md:186-187 "**TODO:** Decide whether strings are built-in types, and whether they support `+` for concatenation." | NONE | upstream decides issue 457 | none |
| H4.3 | string.carbon:12, :14 and :37 edit upstream lines and :26-31 insert into upstream's class | silent (merge rule; re-run M-10) | NONE | an upstream edit of those lines | none |
| H4.4 | check/cpp/export.cpp's null check :296-300 | silent: a fix to upstream code | NONE | upstream adds one (drop it) | none |
| H4.5 | operators.carbon's two splits pinning other failures than upstream's | silent (golden merge rule) | NONE | an upstream refill | none |
| H4.6 | the fork-owned fork_all_operands_conversion.carbon pinning upstream's TODO | silent | NONE | upstream implements C++ operator lookup through operand conversions | none |

### §2.H5 OP-1 (PR 56, 894139b34 :3529-3541; PR 57's copy a080c7886 :4460-4472)

W-344's block. The two copies are identical; PR 56's commit corrects both by
PR 57's merge of it (section 3.2).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H5.1 | optional.carbon:13 and :27 replace upstream lines; :205-275 fork-only | silent (merge rule; re-run M-12) | NONE | an upstream edit of optional.carbon | none |
| H5.2 | `final` on the comparison impls (D-OP-3) | silent: upstream's optional.carbon has no `EqWith` or `OrderedWith` impl | NONE | upstream adds Optional comparisons | none |
| H5.3 | F-015 itself, a fork design for a type upstream has not designed (D-OP-6) | core/prelude/types/optional.carbon:27-28 "We don't have an approved design for an `Optional` type yet, but it's used by the design for `Iterate`. The API here is a placeholder."; matchability is DR-0's (W-320) | NONE | an accepted upstream `Optional` design (re-derive F-015) | W-320 for matchability |
| H5.4 | the comparisons run `T.Copy` and `T.Destroy` once per value when both operands hold one (D-OP-4) | comparison_operators.md:315-316 "these operations should have no observable side-effects." (`EqWith`) and :433-434 "the members of an `OrderedWith` implementation should have no observable side-effects." | **DRIFT**, blocked (W-320, blocked on W-324) | D-RG-10's | W-352, owner OP-1 |
| H5.5 | `None()` is a function; the block says p002188:488-489 and pattern_matching.md:527-528 spell `Optional(T).None` as a value (the latter PR 56's own copy) | upstream core/prelude/types/optional.carbon:30 `fn None() -> Self {`; p002188:489-490 and pattern_matching.md:526-527 "Note that a pattern of the form `Optional(T).None` is an expression pattern and is compared using `==`." | ALIGNED with upstream's prelude, blocked (the pattern is W-320's) | W-320's and W-324's | W-320 (DR-1); cites corrected by PR 56's commit |
| H5.6 | F-015 says `Get()` on an empty `Optional(T*)` falsifies F-013's TY4 until W-173 | silent (between two fork designs) | NONE | none; W-173 is discharged on PR 57 by OP-2 | W-173 |

### §2.H6 OP-2 (PR 57, a080c7886 :3779-3792)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H6.1 | lower/handle.cpp's value conversion in `AsCompatible` (D-OP2-1) | a fix to upstream code, which upstream still carries: upstream lower/handle.cpp:75-78 is `context.SetLocal(inst_id, context.GetValue(inst.source_id));` (:77) | NONE | upstream fixes it its own way (take upstream's if M-2's probes and W-171's arbiters pass) | none |
| H6.2 | check/convert.cpp's swapped `ForType` calls (D-OP2-2) | upstream convert.cpp:1561-1569 still forms `value_rep` from `value_type_id` (:1564-1565) and `unformed_value_rep` from `target.type_id` (:1566-1567) | NONE | as H6.1 | none |
| H6.3 | custom_witness.cpp's adapter arms, F-016 "an adapter is destroyed as its adapted type" (D-OP2-3) | upstream check/custom_witness.cpp:466-467 "TODO: Handle destruction of adapters generally by destroying the adapted type." (since 947c1eb52) | ALIGNED (the TODO's mechanism) | upstream implements the TODO (take upstream's arms) or an accepted adapter-destruction design | none; 05a7ecbd3 rewrote the file (UA-3's conflict) |
| H6.4 | optional.carbon :15, :18, :40-42 and :48 replace upstream lines and :276-307 are fork-only | silent (merge rule M-11) | NONE | an upstream edit above :275 | none |
| H6.5 | `Core.Optional(i32)` is not trivially destructible where `std::optional<int>` is (D-OP2-6) | silent: no upstream text on Optional's triviality | NONE | an upstream Optional layout or triviality rule | W-196 |
| H6.6 | only `Core.Optional(T*)` is `UnformedInit`, "short of p000257's direction" (D-OP2-15) | p000257:274 "The intent is that most types have an unformed state"; upstream core/prelude/default.carbon:17 `interface UnformedInit {` | ALIGNED with a gap (D-RG-4) | upstream's Optional gains an unformed state | W-200 |
| H6.7 | the gap row DONE on a container run (D-OP2-16) | silent (process) | NONE | none | none |

### §2.H7 DD-1 (PR 58, fcee90d9b :4114-4129)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H7.1 | every DD-1 edit to an upstream page is a dated blockquote or a new section, originals kept (D-DD-1) | silent (a documentation convention) | NONE | an upstream rewrite of the same placeholder (take upstream's) | none |
| H7.2 | the fork pieces docs/design/interoperability/threads_and_atomics.md and four interop README sections | silent: upstream's interoperability/ holds README.md, literals.md, macros.md and philosophy_and_goals.md | NONE | upstream adds a threads page | none |
| H7.3 | the pages state measured toolchain behavior and follow the toolchain (D-DD-4) | silent | NONE | none | none |
| H7.4 | the guard parentheses: a `case` guard is `if (E)` | upstream's own parser requires them: parse/handle_match.cpp:166-178 (`auto open_paren = context.ConsumeIf(Lex::TokenKind::OpenParen);` at :169, "expected `(` after `if`" at :176); upstream's design pattern_matching.md:803 `_case_ ::= `case` _pattern_ [`if` _expression_]? `=>` _block_` differs, an upstream gap the page states | ALIGNED (with upstream's toolchain; the fork changed no line of it) | upstream's parser accepts an unparenthesized guard (take it at the advance; the page follows) | none |
| H7.5 | the constant-value alias: `alias` of a constant value is accepted | p003938:82 "`alias` is not fully designed"; the behavior is upstream's toolchain's | NONE | an accepted `alias` design | none |
| H7.6 | the documented toolchain gaps that carry items (W-183, W-185's grammar, W-188, W-189, W-014, W-127, W-192, W-193, W-194) | each item's accepted text, as its own entry records | ALIGNED with gaps (D-RG-4) | each item's | the nine items |

### §2.H8 VA-1 (PR 59, b0822a744 :3609-3630; PR 66's copy 43c8ab476)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H8.1 | (i) `each` is a keyword (D-VA-10) | variadics.md:47-48 each-names "are marked with the `each` keyword at the point of declaration and the point of use."; :92 "An _each-name_ consists of the keyword `each` followed by the name of a pack," | ALIGNED (upstream's lexer has no `each` token yet) | upstream makes `each` contextual (follow, refill the lex golden) | none |
| H8.2 | (ii) the parse node kinds `PackExpansionExpr`, `PackExpansionPattern`, `EachNameExpr`, `EachBindingName`, three parse states, `(... x)` as a tuple | upstream parse/node_kind.def:292-293 `PackExpansionStart`, `PackExpansionStatement`; check/handle_pack_expansion.cpp:12 `return context.TODO(node_id, "HandlePackExpansionStart");` | NONE (internal) | upstream adds its own (move the handlers onto them) | none |
| H8.3 | (iii) a pack's bare name is a semantics TODO (D-VA-11) | silent: p002240's "Omit each-names" is an alternative not adopted | NONE, blocked (watch) | upstream gives it a meaning or makes it an error | W-230 |
| H8.4 | (iv) eight SemIR instructions and `<pack arity>` | silent: upstream sem_ir/inst_kind.def has no pack instruction | NONE | upstream models packs (take upstream's, refill) | none |
| H8.5 | (v) upstream's check golden variadics/pack_expansion.carbon carries VA-1's output | silent (merge rule) | NONE | the advance (take upstream's file and refill) | none |
| H8.6 | (vi) the two cherry-picks are upstream's commits | upstream's own (2ec4bab59 and a045da8e6) | ALIGNED | upstream reverts or reshapes 2ec4bab59 | none |
| H8.7 | (vii) the next advance's four added conflicts take the fork's side | silent (merge rule, plan M-16) | NONE | the advance | none |

### §2.H9 SC-1 (PR 60, 40a76ab81 :4187-4202)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H9.1 | `template constraint` parsed as the `template` modifier on `constraint` (D-SC-1), retiring upstream's two TODOs | generics/details.md:1072-1073 "use the `template` keyword before `constraint`."; :5494 "the keyword introducer `interface`, `constraint`, or `template constraint`,"; upstream check/handle_named_constraint.cpp:44-45 "TODO: PopSoloNodeId(`template`) ... Or maybe it should be a modifier, like `abstract class`?" and :113 "TODO: Support for `template constraint`." | ALIGNED (the source spelling is the design's) | upstream lands a two-token introducer (respell the parse, D-SC-1's) | none |
| H9.2 | `NamedConstraint::is_template` and its members block: requirements checked by name, no witness (D-SC-4) | details.md:1073-1077 "Method, associated constant, and associated function requirements may only be declared inside a `template constraint`. ... a template constraint can depend on them." | ALIGNED | upstream lands member requirements with a witness table (D-SC-4's) | none |
| H9.3 | `LookupImplWitness`'s structural check before the empty-constraint return and `IdentifiedFacetType`'s structural vector | silent: upstream returns `Empty` for a facet type with no interfaces | NONE (internal) | upstream's own representation | none |
| H9.4 | `GetCallee`'s single-candidate look-through for a `cpp_overload_set_value` | silent (internal) | NONE | upstream's | none |
| H9.5 | D-SC-6: a checked-generic argument passed to a template parameter whose constraint has structural requirements is rejected at the checked function's definition ("the conservative answer to leads issue 2153") | generics/overview.md:375-379 "_We have decided to support passing a symbolic constant to a template parameter, see [leads issue #2153...], but incorporating it into the design is future work._"; appendix-witness.md:151-154 "Carbon's planned approach to support calling a templated function from a checked-generic function, decided in issue #2153, relies on monomorphization."; upstream check/call.cpp:387-388 wraps "symbolic template args in a `TemplateInst` so that all symbolic arguments are treated as templates." | **DRIFT** (W-139's break condition "upstream resolves issue 2153 toward checked generics may call templates" has fired) | an upstream design that makes such calls a definition-time error | W-139 (PR 60's ledger), owner SC-1; W-140 follows it |
| H9.6 | the `new_specific_id` parameter threaded through `CheckFunctionTypeMatches` | silent (internal) | NONE | upstream's `CheckFunctionTypeMatches` gains a specific for the new side (merge into it) | none |

### §2.H10 TP-1 (PR 61, 5661a35c8 :4185-4208; PR 64's copy 4a3220c11)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H10.1 | (i) `PointerDereferenceAction`, `AddrOfAction`, `TupleIndexAction`, `IndexAction` and `TemplateMemberLookupAmbiguous` | silent: none of the five upstream (its action kinds, sem_ir/inst_kind.def:21-126, are others) | NONE | upstream defers these forms itself (take upstream's, autoupdate) | none |
| H10.2 | (ii) D-TP-3's copied storage access chain in `InitializeAction::Target::storage_id` | upstream sem_ir/typed_insts.h:1312 `MetaInstId storage_access_block_id;` (4a8993af2, internal) | NONE (D-RG-3) | the advance that brings 4a8993af2 | W-258 |
| H10.3 | (iii) `array` as the builtin, D-TP-24's array arm | upstream 947c1eb52 makes `array` the class `Core.Array` (a prelude identity change after the cut) | ALIGNED (at the cut; UA-3 absorbs 947c1eb52 and re-measures) | the advance | W-253's evidence |
| H10.4 | (iv) D-TP-7 and D-TP-25 change upstream's `SpliceInst` lowering | silent: fixes to upstream code | NONE | upstream's return-form commits 230227264 and 9fd28f730 (the advance's specific-aware resolution) | none |
| H10.5 | (v) D-TP-12 defers impl lookup only for queries that name a template binding | p002200:205 "Impl lookup is delayed until all templated types, interfaces, and parameters" are known | ALIGNED with a gap (D-RG-4) | upstream draws the line differently (follow, refill default_init.carbon) | W-268 |
| H10.6 | (vi) D-TP-13's constraint lookup on instantiation only | p002200:200-202 "Member lookup into a templated type looks in the actual type value provided by the caller in addition to in any constraints on that type" | ALIGNED with gaps (D-RG-4) | upstream implements proposal 2200's name lookup (take it) | W-260, W-261, W-262, W-266 |
| H10.7 | (vii) D-TP-14's `semantics TODO` at the `import` in front of upstream's cross-file lowering TODO, cited as "lower/handle.cpp:524", PR 61's own copy (its :518-524) | upstream toolchain/lower/handle.cpp:384-390 "TODO: We don't yet have support for cross-file templates at all." ... `CARBON_FATAL("Cross-file template lowering not implemented yet");` | NONE (cite corrected by PR 61's commit) | upstream imports actions and splices (remove the TODO with W-250) | W-250 |
| H10.8 | (viii) D-TP-11 forms a generic class type with template-dependent arguments eagerly | silent (toolchain behavior) | NONE | upstream defers it (follow, refill deduce_class_args.carbon) | none |

### §2.H11 CT-1 (PR 64, 4a3220c11 :8341-8342 and plan §0.10 :935-1004)

The block reads "the nine of plan §0.10"; §0.10 lists ten bullets at
4a3220c11 (:935, :941, :945, :951, :958, :960, :963, :967, :985, :996), the
tenth (`SpecificConstant`'s category) added at plan rev 4 (RR2-M1) before the
discharge commit 118fc1bc8 wrote the block. PR 64's commit corrects the count.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H11.1 | `NamesTemplateBinding` also for a `TemplateInst` and through `MetaInstId` operands (D-CT-5; TP-1's D-TP-12) | p002200:205 (as H10.5) | ALIGNED | upstream lands its own deferral of template-dependent impl lookup (keep upstream's) | none |
| H11.2 | `DeferCppCallOnSymbolicArgs` and `ActionIsPerformable`'s C++-callee clause (D-CT-3, D-CT-6, F-021) | overview.md:375-379 and appendix-witness.md:151-154 (as H9.5); upstream call.cpp:387-388's `TemplateInst` wrapping; upstream's toolchain still diagnoses E-ARG | ALIGNED (it implements the decided direction) | upstream lands deferral of C++ calls on symbolic arguments (keep upstream's, re-decide F-021) | none |
| H11.3 | the `MetaInstId`/`MetaInstBlockId` cases of `SubstInst` (D-CT-7) | silent: a fix to upstream code (24766e213 and eb66bebc3 edit `PopOperand` beside them) | NONE | the merge rule | none |
| H11.4 | `PerformAction(InitializeAction)`'s return-slot condition (D-CT-8) | silent (TP-1's code; 4a8993af2's storage block, H10.2) | NONE | the merge rule | none |
| H11.5 | the `TSK_ImplicitInstantiation` marking in `BuildTemplateId` (D-CT-9) | silent: `git grep -c TSK_ImplicitInstantiation` upstream check/cpp is 0 | NONE | upstream's fix for L-UNDEF | none |
| H11.6 | the completion and the `CARBON_CHECK` in `IsMoveEquivalentToCopy` (D-CT-10) | upstream check/cpp/overload_resolution.cpp:156 `static auto IsMoveEquivalentToCopy(clang::QualType type) {` without them | NONE (a fix) | upstream's fix | none |
| H11.7 | `DiscardGenericDeclIntoEnclosingGeneric` and its call in handle_alias.cpp (D-CT-17) | silent: no such function upstream; 57bf903ef (2026-10-27) reworks generic.cpp's resolution loop beside it | NONE | upstream attaches an alias's value itself (keep upstream's) | none |
| H11.8 | the alias check of D-CT-17 as amended: the concrete rule "alias refers to a runtime value" applied per specific | p002200:208-209 "type checking of any expression dependent on a templated parameter may not be completed until its value is known" | ALIGNED | upstream lands its own per-specific evaluation of an alias (keep upstream's) | none |
| H11.9 | `SpecificConstant`'s expression category computed in its own specific (D-CT-17's use rule, rev 4) | silent: upstream sem_ir/expr_info.cpp's `SpecificConstant` case (:319) keeps `SameAsFirstOperand` | NONE (a fix) | upstream changes the category's computation | none |
| H11.10 | the source edits of two upstream goldens and the refills of three | silent (merge rule) | NONE | an upstream change to those files (take upstream's, refill) | none |

### §2.C1 DR-0's register as extended on PR 63 and PR 65 (89aabd125 :241-255; fee0ef31c :241-256)

Owned by DR-1; RG-1 re-reads and does not amend (DR-1's routed records commit
carries their notes, the 2026-10-26 weekly's routing).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item |
| --- | --- | --- | --- | --- | --- |
| C1.1 | (iv) `Core.Optional` not matchable: upstream's pages conflict on `Match.Continuation` | sum_types.md:113 `let template Continuation: type;` against README.md:1076-1078 and generics/terminology.md:100-106; unchanged since ac31fd198 | DRIFT, blocked (on upstream's own conflict) | W-324's | W-320, W-324 (DR-1) |
| C1.2 | (v) D-SL-17's literal-subscript rule as DR-1b's `LiteralSubscriptTargetType` | indexing.md:105 `impl as IndexWith(like i64) {`; lex/token_kind.def:208 `Like` only | DRIFT, blocked (on `like`) | W-326's | W-326 (DR-1) |

### §2.C2 VA-2's register entries (PR 66, 43c8ab476 :3672-3676; fork/variadics/va2-plan.md §1.12)

Owned by VA-2; each carries its item and its weekly next action
(ORCHESTRATION Next actions items 8 and 9). RG-1 records the verdict VA-2's
§1.12 states and does not amend.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item |
| --- | --- | --- | --- | --- | --- |
| C2.1 | (i) `...expand`'s typechecking stops at the text | variadics.md's TODO at :493 and :750 (unchanged since 57ba07a97) | NONE, blocked (watch) | upstream settles `expand` | W-217 |
| C2.2 | (ii) tuple comparisons convert neither operand | comparison_operators.md :504-505, a narrowing, not a second spelling (VA-2's) | ALIGNED with a gap (D-RG-4) | scheduled with W-222 | W-334 |
| C2.3 | (iii) a pack's bare name has no meaning yet | p002240's "Omit each-names", an alternative not adopted | NONE, blocked (watch) | as H8.3 | W-230 |
| C2.4 | (iv) the fixed-arity `let` reading of :219-221 with :532-546 | variadics.md:219-221 and :532-546 (VA-2's reading of the design's own text) | ALIGNED, blocked (watch) | upstream narrows :219-221 | W-214 |
| C2.5 | (v) a segment's rank against a `?` | generics/details.md:4921-4929 names only `?` and non-`?` entries | NONE, blocked (watch) | upstream ranks segments | W-338 |
| C2.6 | (vi) comparisons of orderings that are not total | comparison_operators.md:457-464 and its TODO | NONE, blocked (watch) | upstream decides | W-339 |

## §3 Commits, in order

Every commit is a NEW commit (never an amend, a rebase or a force-push), made
with `--author='jmann345 <jerrymannstan@gmail.com>'` and
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`, staged
by explicit path only (never `git add -A`, R20), after prek to a fixpoint with
the R31 counts recorded before and after (section 4.1). Each message ends, after
a blank line, with the two session attribution trailers the implementing
harness specifies (its Co-Authored-By line, then `Claude-Session:
https://claude.ai/code/session_018tx3BJWJhp2yYjHPRA5fNR`); the messages below
show the body only. Dates are the UTC date of the commit; this plan writes
2026-10-27, and an implementer committing on a later date substitutes it
everywhere a record says "classified 2026-10-27" for that commit's records.
The held commits are made in a scratch worktree under
/dev/shm/rg1-<role>/ checked out detached at the held head (`git worktree add
--detach /dev/shm/rg1-impl/<pr> origin/<branch>`), never in the held branch's
own worktree, and pushed with `git push origin HEAD:<branch>` (a fast-forward
of a new commit); the worktree is deleted afterwards.

### §3.1 On claude/carbon-fork-0-1-rg1 (base trunk 0b999d449)

**P (this commit), rev 1.** Message: `RG-1 plan (rev 1): the V-3a register
classified at upstream f27a977d8`. Path: fork/register/rg1-plan.md. Rev 2 and
later revisions fold the two plan reviews, each a new commit with the message
`RG-1 plan (rev N): <fold summary>` and the same path.

**R1, the records.** Made after sign-off. Message:

<!-- google-doc-style-ignore -->

```text
RG-1 records: the V-3a register classified at upstream f27a977d8; W-346 to W-352 filed, W-342 discharged (R32 (a), (b), (d))

Every entry of the 25 V-3a register blocks and V-3's design-fork entries is
classified against upstream f27a977d8 (fork/register/rg1-plan.md section
2): 15 DRIFT, 32 ALIGNED, 106 NONE, 11 of them blocked. F-006a's Ok/Err is a
drift against README.md:3164-3166 and :3858-3860 (W-346, owner EH-C); F-009's
overload fn is not one (p002875:481 calls its spelling placeholder syntax).
SAFE-1's five departures from accepted text are W-347 to W-351, OP-1's
comparisons' side effects W-352 (blocked on W-320); SC-1's W-139 is a drift
whose break condition fired. The decision-log entry is placed after DR-0;
trunk's twelve blocks gain their dated notes; W-342 is discharged and W-343
and W-344 narrowed; ORCHESTRATION gains the rg1 row, a dated paragraph and
the drifts in Next actions before UA-3. Records only.
```

<!-- google-doc-style-resume -->

Paths: fork/decision-log.md (the entry of Appendix A.1 inserted after DR-0's
"_Ids._" paragraph, which ends at trunk :274, and before "### B0 SF-1..5" at
:277; the twelve notes of Appendix A.3), fork/inventory/work-items.json (A.5's
seven items appended after W-344 in id order, A.6's edits of W-342, W-343 and
W-344, and A.6's sentence appended to the top-level `source`),
fork/ORCHESTRATION.md (A.8). fork/gap-analysis.md is not changed: no row's
status changes, and the one row text that names the drifting spelling, row 68's
example `case .Ok(v: i32)` (fork/gap-analysis.md:68 at 0b999d449), is rewritten
by W-346's realignment when it lands, not by RG-1. Push: `git push -u origin
claude/carbon-fork-0-1-rg1` was made with P; R1 is a plain push.

**R2, the stamp.** Made after the nine held commits of 3.2. Message:

<!-- google-doc-style-ignore -->

```text
RG-1 records: the held-branch amendments recorded; W-343 and W-344 discharged (R32 (e))

Records the held branches' new heads: PR 53 <sha53>, PR 52 <sha52>, PR 60
<sha60>, PR 55 <sha55>, PR 56 <sha56> and PR 57's merge <sha57>, PR 61
<sha61>, PR 64's merge <sha64m> and its count correction <sha64>. W-343 and
W-344 are discharged; the RG-1 entry gains its held-commit paragraph and
ORCHESTRATION its rows and descriptions-refreshed note. Records only.
```

<!-- google-doc-style-resume -->

Paths: fork/decision-log.md (A.2), fork/inventory/work-items.json (A.7),
fork/ORCHESTRATION.md (A.9), fork/register/rg1-plan.md (a "Landed notes"
section with the shas). The `<sha..>` placeholders are the only text the
implementer fills, each with the nine-character abbreviation of the commit
3.2 made.

### §3.2 On the held branches, in the merge order

One new commit per branch, its full text in Appendix A.4 and A.10; PR 57 and PR
64 also merge their base PR's new head, as a080c7886 merged W-323's commit.

| Order | Branch (PR) | Head before | Commit | Paths |
| --- | --- | --- | --- | --- |
| 1 | claude/carbon-fork-0-1-safe (PR 53) | adaae4e35 | H53: `SAFE-1 records: five departures from accepted text filed as drifts W-347 to W-351, the README cite corrected (RG-1; R32 (a), (b), (e))` | fork/decision-log.md |
| 2 | claude/carbon-fork-0-1-cmake (PR 52) | ea573f672 | H52: `CM-1 records: the CMake measurement corrected against upstream's tip and milestone (RG-1; R32 (a), (e))` | fork/decision-log.md |
| 3 | claude/carbon-fork-0-1-sc (PR 60) | 40a76ab81 | H60: `SC-1 records: D-SC-6 is a drift under R32 (d), W-139's break condition fired at upstream f27a977d8 (RG-1; R32 (b), (e))` | fork/decision-log.md, fork/inventory/work-items.json |
| 4 | claude/carbon-fork-0-1-st (PR 55) | 21307851a | H55: `ST-1 records: the README cite corrected to upstream's line at f27a977d8 (RG-1; R32 (a), (e))` | fork/decision-log.md |
| 5 | claude/carbon-fork-0-1-op (PR 56) | 894139b34 | H56: `OP-1 records: the register's cites corrected to upstream's at f27a977d8, the comparisons' side effects filed as W-352 (RG-1; R32 (a), (b), (e); W-344)` | fork/decision-log.md |
| 6 | claude/carbon-fork-0-1-op2 (PR 57) | a080c7886 | H57: merge of H56, `OP-2: merge OP-1's RG-1 records commit (R32 (e))` | the merge's paths |
| 7 | claude/carbon-fork-0-1-tp (PR 61) | 5661a35c8 | H61: `TP-1 records: the cross-file lowering TODO cited at upstream's line at f27a977d8 (RG-1; R32 (a), (e))` | fork/decision-log.md |
| 8 | claude/carbon-fork-0-1-ct (PR 64) | 4a3220c11 | H64m: merge of H61, `CT-1: merge TP-1's RG-1 records commit (R32 (e))` | the merge's paths |
| 9 | claude/carbon-fork-0-1-ct (PR 64) | H64m | H64: `CT-1 records: the register block names ten entries, not nine (RG-1; R32 (e), R10)` | fork/decision-log.md |

PR 54, PR 58, PR 59, PR 62, PR 63, PR 65, PR 66 and PR 51 gain no commit:
their blocks have no drift and no stale cite (D-RG-11), or none at all.

### §3.3 The description refreshes

The orchestrator re-posts each amended PR's description from a scratchpad file
through the GitHub API. For each PR of 3.2 the implementer writes
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/impl/pr_<NN>_refresh.md
holding the PR's current description (fetched by the orchestrator) with the
paragraph of Appendix A.11 appended under a heading "RG-1 amendment
(2026-10-27)", and names the file in its hand-off. No description is edited by
RG-1 directly.

## §4 Verification

Records only: no build, no toolchain, no fill, no dispatch (R28; Actions is
disabled). Every measurement below is a records check; nothing here is of
record in R9's sense.

### §4.1 prek and the R31 counts

For each markdown file a commit touches, before and after prek:

<!-- google-doc-style-ignore -->

```sh
R31=/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5/bin/r31.py
python3 -I "$R31" fork/register/rg1-plan.md   # and fork/decision-log.md, fork/ORCHESTRATION.md
cd /home/user/carbon-rg1 && XDG_CACHE_HOME=<private dir under scratchpad/rg1> \
  SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest \
  uvx prek run --files <the commit's files>
```

<!-- google-doc-style-resume -->

prek is re-run until it exits 0 with no file changed (two runs at least); the
heading counts per level and the list-item counts must be equal before and
after, except for the headings and items the commit adds, which the commit's
records state. The R31 diff check of the rulebook (`^\+\s*#{1,6}
[0-9]|^\+#[0-9]`) is run on every diff. JSON: `python3 -I -c 'import json;
json.load(open("fork/inventory/work-items.json"))'` before each commit that
touches the ledger, and a check that every id from W-346 to W-352 occurs once.

### §4.2 Every quote re-read at the tip

The 140 quoted lines of section 2 are a TSV (path, line, verbatim substring)
kept at scratchpad/rg1/planner/quotes.tsv and re-read by:

<!-- google-doc-style-ignore -->

```sh
#!/bin/bash
# check_quotes.sh <repo> <tip-sha> <quotes.tsv>: prints FAIL rows, exits 1 on any.
repo=$1; tip=$2; tsv=$3; n=0; bad=0
while IFS=$'\t' read -r path line sub; do
  [ -z "$path" ] && continue
  n=$((n+1))
  if ! git -C "$repo" show "$tip:$path" | sed -n "${line}p" | grep -qF -- "$sub"; then
    echo "FAIL $path:$line: $sub"; bad=$((bad+1))
  fi
done < "$tsv"
echo "checked $n quotes, $bad failed"
[ "$bad" -eq 0 ]
```

<!-- google-doc-style-resume -->

Run as `check_quotes.sh /home/user/carbon-lang f27a977d8 quotes.tsv`; on
2026-10-27 it printed "checked 140 quotes, 0 failed". The implementer copies the
TSV into its own scratch and re-runs it before R1 and before R2; a FAIL means
upstream moved, and the entry is re-read at the new tip before any record is
written (section 6, R-1).

### §4.3 Every cite into the log

Before R1 and R2, for each block of section 0.2 and each line cite in Appendix
A's texts: `git show <head>:fork/decision-log.md | sed -n '<line>p'` contains
the block's opening words (the scan of 4.4 prints them), and each cite of a
held line in A.4 is re-read on the head the commit is made on. After R1, the
trunk block lines move (the RG-1 entry is inserted at :276 and each earlier
note shifts the blocks after it); the RG-1 entry cites the blocks at trunk
0b999d449 and says so, as DR-0's and the weekly's entries do.

### §4.4 The block scan

<!-- google-doc-style-ignore -->

```sh
S=/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/<role>
mkdir -p $S/logs && cd /home/user/carbon-lang && git fetch -q origin
git show origin/trunk:fork/decision-log.md > $S/logs/trunk.md
for n in safe cmake ev st op op2 dd va sc tp sv dr ct dr-idx va2 ua2; do
  git show origin/claude/carbon-fork-0-1-$n:fork/decision-log.md > $S/logs/$n.md; done
python3 -I $S/bin/blocks.py $S/logs            # trunk's blocks and lines
python3 -I $S/bin/blocks.py $S/logs safe cmake ev st op op2 dd va sc tp sv dr ct dr-idx va2 ua2
```

<!-- google-doc-style-resume -->

blocks.py (kept at scratchpad/rg1/planner/bin/blocks.py) finds every paragraph
that opens with "_V-3a divergence-risk register entries", "DIVERGENCE-RISK
REGISTER REVIEW" or "_V-3a register re-check" and prints, per head, the blocks
whose text is absent from trunk's. On 2026-10-27 it printed trunk's fifteen
paragraphs (T0's two, T1 and T3 to T12, UA-1's review and the weekly's re-check
heading) and, per head, exactly the unique blocks of section 0.2 (PR 62 and PR
51 none; PR 57 two; PR 64 two; PR 66 VA-1's copy). VA-2's own entries, C2, are
written inline in its entry ("V-3a register entries, each with its work item:",
PR 66 :3672-3676) and are found by `grep -n 'V-3a register entries'` of PR 66's
log.

### §4.5 The id re-scan

<!-- google-doc-style-ignore -->

```sh
cd /home/user/carbon-lang && git fetch -q origin
( for r in $(git for-each-ref --format='%(refname)' refs/remotes/origin refs/heads); do
    git show "$r:fork/inventory/work-items.json" 2>/dev/null; done
  for w in $(git worktree list --porcelain | sed -n 's/^worktree //p'); do
    cat "$w/fork/inventory/work-items.json" 2>/dev/null; done ) |
  grep -o '"W-3[4-9][0-9]"' | sort | uniq -c
git grep -n -o 'W-3[4-9][0-9]' $(git for-each-ref --format='%(refname)' refs/remotes/origin refs/heads) -- fork |
  awk -F: '{print $NF}' | sort | uniq -c
for w in $(git worktree list --porcelain | sed -n 's/^worktree //p'); do
  grep -r -o -h 'W-3[4-9][0-9]' "$w/fork" 2>/dev/null; done | sort | uniq -c
```

<!-- google-doc-style-resume -->

Expected before R1 (2026-10-27): ledgers W-340 3, W-341 to W-344 9 each, W-345
3; text W-346, W-398 and W-399 only as range bounds (section 0.5). After R1:
W-346 to W-352 once in claude/carbon-fork-0-1-rg1's ledger (and its local ref
and worktree), nowhere else.

### §4.6 The model-identifier check and the `Ok`/`Err` count

`git diff <base>..HEAD | grep -n -i -E -f <scratch>/model_ids.txt`, with the
harness's model-identifier patterns kept in a scratch file and never in the
repository, finds nothing outside the trailers on every commit's diff. The count
of D-RG-5 is re-measured with:

<!-- google-doc-style-ignore -->

```sh
for n in safe cmake ev st op op2 dd va sc tp sv ct dr dr-idx va2 ua2; do
  b=origin/claude/carbon-fork-0-1-$n; base=$(git merge-base origin/trunk $b)
  echo "$n $(git diff $base $b -- . ':!fork/decision-log.md' ':!fork/inventory' ':!*plan*.md' |
    grep -E '^\+' | grep -c -E '\.Ok\b|\.Err\b|\bOk\(|\bErr\(')"; done
```

<!-- google-doc-style-resume -->

On 2026-10-27: ev 18, op 2, op2 2, sv 4, dr 1, dr-idx 1, every other head 0.

### §4.7 The merge-trees and their conflict rule

Baseline at 2026-10-27, `git merge-tree --write-tree origin/trunk
origin/<head>`, conflict regions (`grep -c '^<<<<<<<'` of the merged tree's
file) in fork/decision-log.md, fork/inventory/work-items.json,
fork/ORCHESTRATION.md and fork/gap-analysis.md, and no conflicted file outside
fork/:

| Head | decision-log | work-items | ORCHESTRATION | gap-analysis |
| --- | --- | --- | --- | --- |
| safe (PR 53) | 1 | 1 | 2 | 0 |
| ua2 (PR 51) | 0 | 2 | 0 | 1 |
| cmake (PR 52) | 1 | 2 | 3 | 0 |
| sc (PR 60) | 0 | 2 | 2 | 0 |
| ev (PR 54) | 1 | 2 | 4 | 0 |
| st (PR 55) | 1 | 2 | 3 | 1 |
| op (PR 56) | 1 | 2 | 3 | 2 |
| op2 (PR 57) | 1 | 2 | 3 | 2 |
| dd (PR 58) | 1 | 2 | 4 | 1 |
| va (PR 59) | 1 | 2 | 3 | 0 |
| tp (PR 61) | 0 | 1 | 2 | 0 |
| sv (PR 62) | 0 | 2 | 4 | 1 |
| ct (PR 64) | 0 | 2 | 2 | 0 |
| dr (PR 63) | 0 | 1 | 2 | 0 |
| dr-idx (PR 65) | 0 | 1 | 2 | 0 |
| va2 (PR 66) | 1 | 2 | 5 | 0 |

The rule for R1 and R2: `git merge-tree` of claude/carbon-fork-0-1-rg1 against
trunk merges clean (it is trunk plus records); against each held head, no new
conflicted file, and in each file of the table at most the baseline's regions
plus one region in work-items.json (the ledger tail, where RG-1's seven items
and the head's own items both append after the last item; resolved by keeping
both in id order, as W-341 to W-344's merges are) and plus one region in
ORCHESTRATION.md (the Next actions list); the decision log gains no region,
because RG-1's insertion after DR-0 and its notes inside trunk's blocks touch
no line a held head changes. For each held commit of 3.2: the new head's
merge-tree against trunk has the baseline's regions and no more (a held commit
edits only its own block's lines and its own items' notes), and against
claude/carbon-fork-0-1-rg1 after R1 the same plus the two tail regions above.
H57 and H64m are checked with `git merge-tree --write-tree a080c7886 <H56>`
and `... 4a3220c11 <H61>` before they are made: both must be clean (H56 and H61
change lines that PR 57 and PR 64 carry unchanged from their base heads). Any
other region stops the commit; the implementer reads both sides and records the
resolution in the commit's message.

### §4.8 No build

No toolchain, prelude or test file changes, so no build, autoupdate, gate or
conformance run is owed. The read-only comparison toolchains (trunk's
/home/user/carbon-build/carbon-trunk/install/bin/carbon, the held installs and
the nightly 2026.10.12) are not run: no classification needed a probe, because
every verdict rests on upstream's text, and the two toolchain facts quoted
(upstream's parser requiring a guard's parentheses, H7.4; upstream's
`AsCompatible` and `ForType` lines, H6.1 and H6.2) are read from upstream's
source at the tip.

## §5 Conflicts and the land order

RG-1's own PR is records only, base trunk, held like the others. It lands
FIRST in the land sequence, before PR 53: PR 53's amendment (H53) names
W-347 to W-351, which RG-1's ledger files, and R32 (e) requires PR 53's five
realignments before PR 53 lands, which needs the items scheduled on trunk; a
records-only PR that merges clean with trunk carries no risk to the land
sequence's gates. The merge order then reads: RG-1, PR 53, 51, 52, 60, 54, 55,
56, 57, 58, 59, 61, 62, 64, 63, 65, 66. Its conflicts with each later PR are
4.7's, resolved at that PR's merge as the ledger tails and Next actions lists
are today.

The held commits land with their PRs. Two of them change what a PR needs before
it lands:

-   PR 53 cannot land until W-347 to W-351 are realigned by SAFE-1 on its branch
    (a re-derivation commit under its own review; D-RG-7). Until then the land
    sequence is held at its first PR; RG-1's records say so in ORCHESTRATION.
-   PR 60 cannot land until W-139 is realigned by SC-1 on its branch (code: a
    checked-symbolic self deferred to monomorphization, with its goldens and
    fills; D-RG-7). PR 60 is fourth in the order, after PR 52.

PR 56 lands with W-352 recorded and blocked (D-RG-10). W-346 lands on trunk
after the held PRs (D-RG-8) and before UA-3, beside OV-4's W-341.

## §6 Risks and rejected alternatives

Each risk is falsifiable by the check named.

-   **R-1: upstream moves before R1.** A commit after f27a977d8 changes a quoted
    line. Falsifier: 4.2's script reports a FAIL. Response: re-read the entry
    at the new tip; a changed verdict is a plan amendment (rev N), never an
    edit of R1's text in place.
-   **R-2: F-006a's verdict is wrong (the README's `Result` is only an
    example).** Falsifier: a design page or leads answer at the tip that calls
    the README's `Result` illustrative or names other alternatives. Response:
    W-346 is withdrawn by a dated note, its break condition. Rejected
    alternative: NONE on V-3's "illustrative" ground, because that ground was
    the override clause V-3b withdrew and no upstream text marks the spelling
    provisional (D-RG-2 (iii)).
-   **R-3: F-009's verdict is wrong (the placeholder is direction).** Falsifier:
    an owner ruling that a placeholder is direction. Response: a rename item (`overload`
    to `overloaded`), owner the overload workstream, is filed under a new id
    after a fresh re-scan (W-353 to W-359 stay unused). Rejected alternative:
    DRIFT now, because p002875 itself says "using placeholder syntax" and
    pattern_matching.md:696 says there is no approved design.
-   **R-4: SAFE-1's five are realignable by RG-1 as text.** Falsifier: a
    reviewer shows one departure whose page sentence can restate upstream's text
    with no other page or decision changing. Response: D-RG-7's break condition;
    that edit joins H53. Rejected alternative: RG-1 rewrites the five decisions
    itself; they interlock (D-SAFE-11(d) is "the D-SAFE-17 narrowing applied at
    a second site", D-SAFE-19 exports D-SAFE-17's binding as `&SharedView<T>`),
    and a records workstream re-deriving a safety design bypasses SAFE-1's
    reviews.
-   **R-5: a NONE hides a drift in an internal surface.** Falsifier: an upstream
    design page or proposal at the tip that names one of section 2's internal
    surfaces (a grep of docs/design and proposals for each NONE row's
    identifier, run by the reviewer). Response: re-classify under D-RG-3's break
    condition.
-   **R-6: 05a7ecbd3 fires a break condition.** `Destroy` became a constraint
    over `SubobjectDestroy` and `DestroyImpl` (destroy.carbon:27-29). Falsifier:
    at UA-3, a declared `impl as Destroy` in a fork prelude type (`Core.Buf`) no
    longer compiles, or upstream's synthesized destruction now calls a declared
    `DestroyImpl.Op` (D-SL-16's break condition). Response: UA-3's audit
    measures it; RG-1 files nothing now, since no fork mechanism is a second
    spelling of the new constraint (the fork's spelling is upstream's at the
    cut) and the weekly check classifies the commit under R32 (c).
-   **R-7: the held commits conflict.** Falsifier: 4.7's merge-trees. Response:
    stop, read both sides, record the resolution.
-   **R-8: D-RG-8 leaves a held PR's text out of date.** Falsifier: PR 54 lands
    with its tutorial teaching `Ok`/`Err` while W-346 has already renamed trunk.
    Response: D-RG-8's break condition: W-346 is scheduled after the held PRs,
    so the case does not arise unless the schedule changes.
-   **Rejected: one work item for SAFE-1's five departures.** Each departure has
    its own decision, page and break condition; one item would hide which ones
    are realigned.
-   **Rejected: notes on every held block now.** Seven more held commits and
    description refreshes for blocks with no drift and no stale cite, against
    R32 (e)'s purpose; D-RG-11 records them in the RG-1 entry instead.
-   **Rejected: placing the RG-1 entry beside the weekly checks.** The weekly
    entries are a dated series; RG-1 executes V-3b and DR-0's register, which
    sit at the top (D-RG-14).

## §7 Residues

Entries whose classification or realignment waits on an upstream decision, or on
an item blocked by one; each is a register entry with a work item (R32 (b)) and
is re-checked at each weekly upstream check:

| Entry | Waits on | Work item | Re-check |
| --- | --- | --- | --- |
| H5.4 OP-1's comparisons' side effects | W-320, blocked on W-324 (upstream's own `Match.Continuation` conflict) | W-352 | with W-324: sum_types.md:113 against README.md:1076-1078 |
| H5.5 OP-1's `None()` against the `Optional(T).None` pattern | W-320 | W-320 | as above |
| C1.1 `Core.Optional` not matchable | upstream's conflict | W-320, W-324 | as above |
| T5.7 and C1.2 the literal-subscript rule | upstream's `like` (lex/token_kind.def:208, a token only) | W-326 | indexing.md:101-121 and a `like` in parse or check |
| H8.3 and C2.3 a pack's bare name | the design (p002240's alternative not adopted) | W-230 | p002240 "Omit each-names" (:555) and variadics.md |
| C2.1 `...expand`'s typechecking | the design's TODO (variadics.md:493, :750) | W-217 | variadics.md :493 and upstream handle_pack_expansion.cpp |
| C2.4 the fixed-arity `let` reading | the design's text (variadics.md:219-221 with :532-546) | W-214 | both passages |
| C2.5 a segment's rank against `?` | the overlap rule (generics/details.md:4921-4929) | W-338 | the rule and upstream type_structure.cpp |
| C2.6 comparisons of non-total orderings | comparison_operators.md:457-464 and its TODO | W-339 | those lines |

Eleven entries: T5.7, H5.4, H5.5, H8.3, C1.1, C1.2, C2.1, C2.3, C2.4, C2.5 and
C2.6. C2.2 is not a residue (it is scheduled with W-222). No other entry waits:
every other DRIFT is scheduled (section 5) and every NONE and ALIGNED carries
its break condition.

## Appendix A: records texts

Every text below is written as it is to stand in the file, hand-wrapped at 80
columns so that rumdl's reflow leaves it (R31: no line starts with a list
marker, a plus sign, a hash or a digit and a period unless it is a list item).
"2026-10-27" is the commit's UTC date (section 3). Insertion points are lines
at the head named; within one file the implementer inserts from the bottom
up, so each earlier line number stays valid.

### A.1 The decision-log entry (R1; trunk, after DR-0's "_Ids._" paragraph)

Inserted between trunk 0b999d449's :275 (the blank line after DR-0's "_Ids._"
paragraph) and :277 ("### B0 SF-1..5: ..."), followed by one blank line:

<!-- google-doc-style-ignore -->

```text
### RG-1: the V-3a register classified at f27a977d8 (2026-10-27)

Placed here, in Decided directly after DR-0, because the log groups entries by
workstream and RG-1 carries out V-3b's rule for DR-0's register: the register
"is a work queue whose entries each carry a work item" (fork/rulebook.md R32
(b)). Line cites into this log are to the file at trunk 0b999d449, before this
entry and its notes moved them. Records only: no toolchain, prelude, golden or
program file changes with it.

_The work and the rule._ W-342, W-343 and W-344 asked for every V-3a register
entry to be classified against upstream's tip. Upstream trunk f27a977d8
(2026-10-27, "Fix ASan CI failures due to `preserve_none`", upstream PR 8045;
131 commits past the c1e83b0b7 cut, 14 past 21c825a3f) was read by sha.
fork/register/rg1-plan.md section 2 quotes upstream's text for each of the 153
entries in 25 blocks and V-3's design-fork group: on trunk DR-0's block, the
eleven blocks that predate it and the design-fork entries F-006a, F-007 and
F-009 that V-3 registered and UA-1's review names, and on the held heads
thirteen blocks; its section 4.2 re-reads the
140 quoted lines. An entry is a DRIFT when upstream has designed its mechanism
and the fork spells it otherwise (R32 (d)), ALIGNED when the fork's spelling or
rule is upstream's, and NONE when upstream is silent. Upstream has designed a
mechanism when text at the tip shows it with a spelling, is about it, and does
not call the spelling placeholder or provisional (D-RG-2). Toolchain-internal
surfaces are NONE, their merge rules their break conditions (D-RG-3); a partial
implementation whose gap carries an item is ALIGNED (D-RG-4). The decisions
D-RG-1 to D-RG-15 are auto-adopted under R29(a), each with its break condition
in the plan's section 1.

_The count._ 15 DRIFT, 32 ALIGNED and 106 NONE; 11 entries wait on an upstream
decision or on an item blocked by one (the plan's section 7). Eight DRIFT
entries were filed before RG-1 (W-109 twice, W-320 with W-324, W-321, W-322,
W-326 twice, and SC-1's W-139); seven are filed now as W-346 to W-352.

_The two R29 decisions._ F-006a's `Ok`/`Err` is a DRIFT (D-RG-5). Upstream's
README names `Result` as the choice that represents errors ("At this point,
errors are represented using `[choice types](#choice-types)` like `Result` and
`Optional`.", docs/design/README.md:3859-3860) and declares `choice Result(T:
type, Error: type)` with `Success(value: T)` and `Failure(error: Error)`
(:3164-3166), as its `IntResult` (:2175-2179) and p000157 (:690-692) spell
them; no upstream text spells `Ok` or `Err` or marks `Success` and `Failure`
as placeholder, and "illustrative" was V-3's override ground, which V-3b
withdrew. W-346 renames the alternatives (the payload names and the order
already match), owner EH-C, on trunk's base after the held PRs land and before
UA-3. Break condition: upstream adds a prelude `Result` or an error-handling
proposal with other alternatives (take them), or changes the README's examples
to `Ok`/`Err` (withdraw W-346). F-009's `overload fn` is NONE (D-RG-6):
upstream's only introducer is p002875's "using placeholder syntax" (:481)
before `overloaded fn` (:484-485), and pattern_matching.md says "We do not yet
have an approved design for overloaded functions" (:696); F-009's closed
same-library sets and declaration-order first match are ALIGNED with
static_open_extension.md:52-54 and pattern_matching.md:696-697. Break
condition: upstream accepts a proposal or lands a token or page that spells
the introducer (then a rename is filed as a drift).

_The drifts and their items._ Trunk: F-006a's `Ok`/`Err` (W-346, EH-C); the
rest are DR-1's (W-109, W-321 and W-322, resolved on PR 65, PR 63 and PR 62;
D-SL-17's literal-subscript rule, W-326, blocked on upstream's `like`). PR 53,
SAFE-1's departures from accepted text: p005434:83's `noalias` on every `ref`
binding narrowed by D-SAFE-8 (W-347), p005434:663's plan to prevent mutation of
borrowed objects in Strict narrowed by D-SAFE-17 (W-348), p005434:831-832's
"immutable" narrowed to "not invalidated" by D-SAFE-11(d) (W-349),
arithmetic.md:156-158's performance-build row withdrawn by D-SAFE-15 (W-350)
and safety/README.md:260-262's benchmarking disable withdrawn by D-SAFE-14
(W-351); each is realigned by SAFE-1 by a new commit on PR 53's branch before
it lands (R32 (e)), and PR 53 lands first. PR 60: D-SC-6's definition-time
rejection of a checked-generic argument to a template parameter, where
generics/overview.md:375-379 records "We have decided to support passing a
symbolic constant to a template parameter" (leads issue 2153) and
appendix-witness.md:151-154 that the approach "relies on monomorphization":
W-139's break condition has fired, SC-1 realigns on PR 60 before it lands. PR
56: the comparisons run `T.Copy` and `T.Destroy`, against
comparison_operators.md:315-316 and :433-434's "should have no observable
side-effects" (W-352, owner OP-1, blocked on W-320 and so on W-324; PR 56 lands
with it recorded). Not drifts: the zero-fill promotion (ALIGNED with
safety/README.md:219-222 and p005914:87-88), the Permissive reading of
p005914:206-208 (ALIGNED: the sentence governs optimization, and no fork
optimization relies on the assumption), the restored `addr self: Self*`
(ALIGNED with p005434:1226-1236), OP-2's adapter destruction (ALIGNED with
upstream's TODO at check/custom_witness.cpp:466-467), the guard parentheses
DD-1 documents (ALIGNED with upstream's own parser, parse/handle_match.cpp:169
and :176), `Core.Buf` (ALIGNED with README.md:885-886), VA-1's `each` keyword
(ALIGNED with variadics.md:47-48 and :92), `template constraint` (ALIGNED with
generics/details.md:1072-1073 and :5494) and `Core.StringBuf` (NONE: README.md
calls its string types "provisional", :622).

_Per block_ (lines at trunk 0b999d449 or at the held head; D, A and N are the
DRIFT, ALIGNED and NONE counts):

| Block | Lines | D / A / N | Items |
| --- | --- | --- | --- |
| DR-0's register | :241-247 | 3 / 0 / 0 | W-322, W-109, W-321 (resolved on held PRs) |
| F-006 (B1) | :757-765 | 0 / 0 / 3 | none |
| V-3's F-006a, F-007, F-009 | :31-41, :6652-6653 | 1 / 2 / 4 | W-346 |
| SL-2 | :3686-3697 | 0 / 3 / 5 | W-120 (watch) |
| OV-3 | :4025-4033 | 0 / 0 / 2 | none |
| SL-1 | :4421-4432 | 2 / 2 / 7 | W-326, W-109; W-110 (the `buf(T)` gap) |
| OV-2 | :4718-4726 | 0 / 0 / 5 | none |
| OV-1 | :4971-4978 | 0 / 0 / 5 | none |
| UN-2 | :5179-5186 | 0 / 0 / 2 | none |
| UN-1 | :5476-5484 | 0 / 0 / 3 | none |
| EH-B | :5596-5617 | 0 / 0 / 3 | none |
| EH-A | :5961-5971 | 0 / 2 / 2 | W-346 (the alternatives) |
| UA-1's watch list | :6768-6782 | 0 / 0 / 7 | none |
| SAFE-1, PR 53 adaae4e35 | :3920-3938 | 5 / 5 / 5 | W-347 to W-351 |
| CM-1, PR 52 ea573f672 | :3119-3133 | 0 / 1 / 6 | none |
| EV-1, PR 54 cb3ef2e74 | :3538-3549 | 0 / 0 / 4 | none |
| ST-1, PR 55 21307851a | :3503-3516 | 0 / 0 / 6 | none |
| OP-1, PR 56 894139b34 (PR 57 :4460-4472) | :3529-3541 | 1 / 1 / 4 | W-352; W-320 |
| OP-2, PR 57 a080c7886 | :3779-3792 | 0 / 2 / 5 | W-196, W-200 (gaps) |
| DD-1, PR 58 fcee90d9b | :4114-4129 | 0 / 2 / 4 | the nine documented gaps' items |
| VA-1, PR 59 b0822a744 (and PR 66) | :3609-3630 | 0 / 2 / 5 | W-230 (watch) |
| SC-1, PR 60 40a76ab81 | :4187-4202 | 1 / 2 / 3 | W-139 |
| TP-1, PR 61 5661a35c8 (and PR 64) | :4185-4208 | 0 / 3 / 5 | W-258, W-268, W-260 to W-262, W-266, W-250 |
| CT-1, PR 64 4a3220c11 | :8341-8342, plan §0.10 | 0 / 3 / 7 | none |
| DR-0 extended, PR 63 and PR 65 | :247-254 | 2 / 0 / 0 | W-320 with W-324, W-326 |
| VA-2, PR 66 43c8ab476 | :3672-3676 | 0 / 2 / 4 | W-217, W-334, W-230, W-214, W-338, W-339 |

_Records corrected on the held branches._ Cites of a fork copy or a stale count:
PR 53's "docs/design/README.md:2147" (its own copy; upstream's text is at
:2130-2132) and "arithmetic.md:155-158" (upstream :156-158); PR 52's
"thirteen `cmake` mentions are Bazel-internal" (measured on the fork's tree;
upstream's thirteen files include docs/project/milestones.md, whose :230-231
names "Build system integration for CMake" as a 0.1 deliverable); PR 55's
"README.md:629" (the fork's copy; upstream :627); PR 56's "p002188:488-489" and
"pattern_matching.md:527-528" (upstream :489-490 and :526-527, the latter cite
PR 56's own copy); PR 61's "lower/handle.cpp:524" (its own copy; upstream
:384-390); PR 64's "the nine of plan §0.10" (ten: the tenth was added at the
plan's rev 4). Each is a new commit on its branch (R32 (e)); PR 57 and PR 64
merge their base PR's commit. The blocks without a drift or a stale cite (PR
54's, PR 57's OP-2, PR 58's, PR 59's) are not amended now; their notes join
their PRs' land-time records (D-RG-11).

_05a7ecbd3._ Of the fourteen upstream commits since 21c825a3f, one changes a
prelude signature: `Destroy` becomes a constraint over `SubobjectDestroy` and
`DestroyImpl` (core/prelude/destroy.carbon:27-29) and `SelfDestruct` a free
function (:36). It fires no entry's break condition by text and is the next
weekly check's to classify under R32 (c); UA-3 measures D-SL-16's.

_Ids._ The re-scan of rg1-plan.md section 4.5 (135 origin refs, 25 local
branches, 22 worktrees, after a fetch) finds W-340 to W-345 in ledgers and W-346,
W-398 and W-399 only as range bounds in two plans' text. RG-1 reserves W-346 to
W-359, files W-346 to W-352, and leaves W-353 to W-359 unused.

_Not run._ No build, fill, gate, conformance or dispatch (R28); Actions is
disabled, so nothing is of record (R9).
```

<!-- google-doc-style-resume -->

### A.2 R2's paragraph (appended to the RG-1 entry, before its "_Ids._")

<!-- google-doc-style-ignore -->

```text
_Held commits (2026-10-27, R2)._ PR 53 <sha53> (H53), PR 52 <sha52> (H52), PR
60 <sha60> (H60), PR 55 <sha55> (H55), PR 56 <sha56> (H56) with PR 57's merge
<sha57> (H57), PR 61 <sha61> (H61) with PR 64's merge <sha64m> (H64m) and PR
64's own <sha64> (H64); each description is refreshed. W-343 and W-344 are
discharged.
```

<!-- google-doc-style-resume -->

### A.3 The notes in trunk's blocks (R1)

Each is a new paragraph after the block's last line (T1's is inline, T2's
follows UA-1's review), at trunk 0b999d449's lines, inserted bottom up. The
common lead is "_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry
"RG-1: the V-3a register classified at f27a977d8 (2026-10-27)" has the
quotes):_".

<!-- google-doc-style-ignore -->

```text
[T12, a new paragraph after :6782]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" has the quotes):_ each of the
seven items (classified 2026-10-27, RG-1: NONE, fork code inside upstream
functions with no upstream design; 05a7ecbd3 rewrote check/custom_witness.cpp,
the `is_choice` clauses' file, which is UA-3's merge rule, not a design).

[T11, after :5971]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ (i) `Core.Result` as a choice (classified 2026-10-27, RG-1: ALIGNED,
README.md:3859-3860 "errors are represented using `[choice types](#choice-types)`
like `Result`"; its alternatives are W-346's), the library name (classified
2026-10-27, RG-1: NONE, no upstream `Result` library), the success-first order
(classified 2026-10-27, RG-1: ALIGNED, README.md:3165-3166); (ii) the `()`
payload (classified 2026-10-27, RG-1: NONE, no payload allowlist upstream).

[T10, after :5617]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ (i), (ii) and (iii) (classified 2026-10-27, RG-1: NONE, upstream
designs no exception mapping; interoperability/philosophy_and_goals.md:405-410
allows that "translating C++ exceptions to or from Carbon errors might require
annotations or bridge code").

[T9, after :5484]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ the three surfaces (classified 2026-10-27, RG-1: NONE, upstream has no
`union` declaration and does not recognize core/prelude/default.carbon:17's
`interface UnformedInit` as a kind); F-007's entries are noted after UA-1's
review.

[T8, after :5186]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ both (classified 2026-10-27, RG-1: NONE, upstream exports no Carbon
union).

[T7, after :4978]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ the `overload` keyword (classified 2026-10-27, RG-1: NONE, p002875:481
introduces `overloaded fn` "using placeholder syntax"; pattern_matching.md:696
"We do not yet have an approved design for overloaded functions"); the marker,
the inst kinds and store, the five diagnostics and the print field (classified
2026-10-27, RG-1: NONE, internal, upstream's only mention is
sem_ir/function.h:547's TODO); F-009's entries are noted after UA-1's review.

[T6, after :4726]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ the five (classified 2026-10-27, RG-1: NONE, internal surfaces with
their merge rules).

[T5, after :4432]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ the four builtins (classified 2026-10-27, RG-1: NONE, values.md:1128-1129
expects pointer arithmetic "through specialized constructs"); `Core.Slice`
(classified 2026-10-27, RG-1: NONE, README.md:912 "**TODO:** Slices");
`Core.Buf` (classified 2026-10-27, RG-1: ALIGNED, README.md:885-886 "a shorthand
for the library type `Core.Buf(T)`"; the shorthand is W-110); the `Iterate`
impl (classified 2026-10-27, RG-1: ALIGNED, iterate.carbon's interface; its
cursor is W-321's); D-SL-15, D-SL-16, D-SL-18, D-SL-19 and D-SL-20 (classified
2026-10-27, RG-1: NONE; 05a7ecbd3 makes upstream's `Destroy` a constraint and
UA-3 measures D-SL-16's break condition); D-SL-17 (classified 2026-10-27, RG-1:
DRIFT, W-326, blocked on `like`); D-SL-3 (classified 2026-10-27, RG-1: DRIFT,
W-109, resolved on PR 65).

[T4, after :4033]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ both (classified 2026-10-27, RG-1: NONE, internal; upstream's
generate_ast.cpp has no list shape and upstream keys no overload thunks).

[T3, after :3697]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes):_ the `Span` mapping and the export arm (classified 2026-10-27, RG-1:
ALIGNED, README.md:3707-3708 "Other view types, like `std::span`, are intended
to map similarly"); the synthesized interface, the prelude sections, D-SL-8,
D-SL-9 and D-SL-24 (classified 2026-10-27, RG-1: NONE, README.md:912
"**TODO:** Slices"; W-120 watches D-SL-9); D-SL-21 (classified 2026-10-27,
RG-1: ALIGNED, upstream's own orphan rule).

[T2, a new paragraph after UA-1's review, after :6654]
_RG-1 on the design-fork entries (classified 2026-10-27, upstream f27a977d8;
the entry "RG-1: the V-3a register classified at f27a977d8 (2026-10-27)" has the
quotes):_ F-006a's `Ok`/`Err` (classified 2026-10-27, RG-1: DRIFT, W-346;
README.md:3164-3166 spells `Result`'s `Success(value: T)` and `Failure(error:
Error)`, and :3859-3860 names `Result` as the choice that represents errors);
F-007's `union` keyword, class-shaped declaration and byte-reinterpretation
reads (classified 2026-10-27, RG-1: NONE, p000157:239 proposes "A typed `union`
facility" and no upstream page or token designs one); F-009's closed sets and
first match (classified 2026-10-27, RG-1: ALIGNED,
static_open_extension.md:52-54 and pattern_matching.md:696-697); F-009's marker
`overload fn` (classified 2026-10-27, RG-1: NONE, p002875:481 "using
placeholder syntax", pattern_matching.md:696).

[T1, inline at :765, after "(with F-006a's `Ok`/`Err`
already on the register)." and before "_Mechanism (plan §2.4 as revised):_"]
_RG-1 (classified 2026-10-27, upstream f27a977d8; the entry "RG-1: ..." has the
quotes): (i) to (iii) NONE, upstream README.md:3858-3859 "Carbon does not have
language features dedicated to error handling", no `ControlFlow` or `Try`
upstream; F-006a DRIFT, W-346._
```

<!-- google-doc-style-resume -->

In each note "the entry "RG-1: ..."" is written out in full, as in T12's and
T2's.

### A.4 The held blocks' amendments

**H53, PR 53 (claude/carbon-fork-0-1-safe at adaae4e35), fork/decision-log.md.**
Two replacements in the block, then a new paragraph after :3938:

<!-- google-doc-style-ignore -->

```text
[replace, :3930]  arithmetic.md:155-158 (the performance-build
[with]            arithmetic.md:156-158 (the performance-build
[replace, :3932]  docs/design/README.md:2147 (zero-fill promoted to the
[with]            docs/design/README.md:2130-2132 (upstream's at f27a977d8;
                  this branch's copy :2147-2149; zero-fill promoted to the

[new paragraph after :3938]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" and fork/register/rg1-plan.md
section 2.H1 have the quotes):_ under V-3b each departure from accepted text is
a drift with its work item, realigned by SAFE-1 by a new commit on this branch
before it lands (R32 (e)): p005434:83 (classified 2026-10-27, RG-1: DRIFT,
W-347), p005434:663 (classified 2026-10-27, RG-1: DRIFT, W-348),
p005434:831-832 (classified 2026-10-27, RG-1: DRIFT, W-349),
arithmetic.md:156-158 (classified 2026-10-27, RG-1: DRIFT, W-350) and safety
README.md:260-262 (classified 2026-10-27, RG-1: DRIFT, W-351). The zero-fill
promotion (classified 2026-10-27, RG-1: ALIGNED, safety README.md:219-222 and
p005914:87-88; its cite above corrected from this branch's copy) and the
Permissive reading of p005914:206-208 (classified 2026-10-27, RG-1: ALIGNED,
the sentence governs optimization, and T8 withholds `noalias`) are not drifts.
`unsafe permissive`, the prefix `unsafe` forms and the restored `addr self:
Self*` (classified 2026-10-27, RG-1: ALIGNED, safety README.md:116-118 and
:80-81, p005434:1226-1236) follow upstream; `exclusive`, `unsafe import`,
`unsafe class`, the library names and the `import Cpp` asymmetry (classified
2026-10-27, RG-1: NONE, no upstream spelling; safety README.md:122-124 leaves
import marking to future work). Since V-3b the re-basing clause above reads
"re-based under R32".
```

<!-- google-doc-style-resume -->

**H52, PR 52 (claude/carbon-fork-0-1-cmake at ea573f672),
fork/decision-log.md.**

<!-- google-doc-style-ignore -->

```text
[replace, :3121-3122]
cmake/ or examples/cmake/ directory, no build-systems guide; its thirteen
`cmake` mentions are Bazel-internal), so the module and helper names
[with]
cmake/ or examples/cmake/ directory, no build-systems guide; thirteen of its
files mention CMake, nine of them build files and four of them text, among them
docs/project/milestones.md, whose :230-231 names "Build system integration for
CMake" as a 0.1 deliverable this workstream delivers; corrected 2026-10-27,
RG-1, against upstream f27a977d8), so the module and helper names

[new paragraph after :3133]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" and fork/register/rg1-plan.md
section 2.H2 have the quotes):_ the CMake support (classified 2026-10-27, RG-1:
ALIGNED, docs/project/milestones.md:230-231 and proposals/p006333:368-370); its
names, the touched upstream lines, the harness directive and D-CM-5, D-CM-6,
D-CM-7 and D-CM-9 (classified 2026-10-27, RG-1: NONE, upstream has no CMake
files; compile_subcommand.cpp:43-46's single-input TODO and p006333:99-100's
`carbon compile` are the driver's, which this branch does not change).
```

<!-- google-doc-style-resume -->

**H60, PR 60 (claude/carbon-fork-0-1-sc at 40a76ab81),** fork/decision-log.md
and fork/inventory/work-items.json.

<!-- google-doc-style-ignore -->

```text
[fork/decision-log.md, new paragraph after :4202]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" and fork/register/rg1-plan.md
section 2.H9 have the quotes):_ `template constraint` and its member
requirements (classified 2026-10-27, RG-1: ALIGNED, generics/details.md:1072-1073
"use the `template` keyword before `constraint`" and :5494); the structural
vector, the look-through and `new_specific_id` (classified 2026-10-27, RG-1:
NONE, internal); D-SC-6 (classified 2026-10-27, RG-1: DRIFT, W-139): its break
condition has fired, since generics/overview.md:375-379 records "We have decided
to support passing a symbolic constant to a template parameter" (leads issue
2153) and appendix-witness.md:151-154 that the approach "relies on
monomorphization", so SC-1 realigns the definition-time rejection by a new
commit on this branch before it lands (R32 (e)); W-140 follows W-139.

[fork/inventory/work-items.json, W-139's "notes": append]
 Classified 2026-10-27 by RG-1 (upstream f27a977d8; trunk's RG-1 entry): a
drift under R32 (d), because this item's break condition has fired --
docs/design/generics/overview.md:375-379 ("We have decided to support passing a
symbolic constant to a template parameter", leads issue 2153) and
appendix-witness.md:151-154 ("decided in issue #2153, relies on
monomorphization"); upstream's check/call.cpp:387-388 wraps symbolic template
arguments in a `TemplateInst`. Owner SC-1: a new commit on PR 60's branch
before PR 60 lands (R32 (e)) defers the structural check of a checked-symbolic
self to each specific, with its goldens; scheduled in ORCHESTRATION's Next
actions before UA-3.
```

<!-- google-doc-style-resume -->

**H55, PR 55 (claude/carbon-fork-0-1-st at 21307851a), fork/decision-log.md.**

<!-- google-doc-style-ignore -->

```text
[replace, :3504]
fork-local name `Core.StringBuf` (README.md:629's owning `String`, p006177's
[with]
fork-local name `Core.StringBuf` (upstream README.md:627's owning `String`,
:629 in the fork's copy, corrected 2026-10-27 by RG-1; p006177's

[new paragraph after :3516]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" and fork/register/rg1-plan.md
section 2.H4 have the quotes):_ `Core.StringBuf` (classified 2026-10-27, RG-1:
NONE, README.md:622 "This is provisional, no design for string types has been
through the" proposal process, and upstream's prelude `String` is still the
view); `+` on strings (classified 2026-10-27, RG-1: NONE, arithmetic.md:186-187
leaves issue 457 a TODO); the edited and inserted lines, the null check and the
three goldens' merge rules (classified 2026-10-27, RG-1: NONE).
```

<!-- google-doc-style-resume -->

**H56, PR 56 (claude/carbon-fork-0-1-op at 894139b34), fork/decision-log.md.**

<!-- google-doc-style-ignore -->

```text
[replace, :3539]
p002188:488-489 and pattern_matching.md:527-528 spell `Optional(T).None` as a
[with]
p002188:489-490 and pattern_matching.md:526-527 (upstream's at f27a977d8,
corrected 2026-10-27 by RG-1 from :488-489 and this branch's copy's :527-528)
spell `Optional(T).None` as a

[new paragraph after :3541]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" and fork/register/rg1-plan.md
section 2.H5 have the quotes):_ the comparisons' `T.Copy` and `T.Destroy`
(classified 2026-10-27, RG-1: DRIFT, W-352, blocked by W-320 and so on W-324):
comparison_operators.md:315-316 and :433-434 say these operations "should have
no observable side-effects", and the realignment compares through W-320's
`.Some` pattern when it lands, so this branch lands with the drift recorded
here (R32 (b)); `None()` (classified 2026-10-27, RG-1: ALIGNED with upstream's
core/prelude/types/optional.carbon:30 `fn None() -> Self`, the pattern being
W-320's); the replaced lines, `final` and F-015 itself (classified 2026-10-27,
RG-1: NONE, optional.carbon:27-28 "The API here is a placeholder"); the TY4
statement (classified 2026-10-27, RG-1: NONE, between two fork designs).
```

<!-- google-doc-style-resume -->

**H57, PR 57 (claude/carbon-fork-0-1-op2 at a080c7886).** `git merge --no-ff
<H56>` with the message of A.10; the OP-1 block's copy at :4460-4472 takes
H56's text; no other file changes; no OP-2 note (D-RG-11).

**H61, PR 61 (claude/carbon-fork-0-1-tp at 5661a35c8), fork/decision-log.md.**

<!-- google-doc-style-ignore -->

```text
[replace, :4205]
lowering TODO (lower/handle.cpp:524); when upstream imports actions and splices,
[with]
lowering TODO (upstream lower/handle.cpp:384-390 at f27a977d8, this branch's
:518-524, corrected 2026-10-27 by RG-1); when upstream imports actions and
splices,

[new paragraph after :4208]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" and fork/register/rg1-plan.md
section 2.H10 have the quotes):_ (iii) (classified 2026-10-27, RG-1: ALIGNED at
the cut; UA-3 absorbs 947c1eb52), (v) and (vi) (classified 2026-10-27, RG-1:
ALIGNED with gaps, p002200:200-206; W-268, W-260 to W-262 and W-266); (i), (ii),
(iv), (vii) and (viii) (classified 2026-10-27, RG-1: NONE, internal surfaces and
fixes with their merge rules; W-258 and W-250).
```

<!-- google-doc-style-resume -->

**H64m and H64, PR 64 (claude/carbon-fork-0-1-ct at 4a3220c11).** H64m: `git
merge --no-ff <H61>`, the TP-1 block's copy at :4185-4208 taking H61's text.
H64, fork/decision-log.md:

<!-- google-doc-style-ignore -->

```text
[replace, :8342]
nine of plan §0.10, with their merge rules. Veto-able.
[with]
ten of plan §0.10 (the tenth, `SpecificConstant`'s category, added at plan rev
4, RR2-M1; counted 2026-10-27 by RG-1), with their merge rules. Veto-able.

[new paragraph after the block]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" and fork/register/rg1-plan.md
section 2.H11 have the quotes):_ `NamesTemplateBinding`, the deferral of C++
calls on symbolic arguments (F-021) and the per-specific alias check (classified
2026-10-27, RG-1: ALIGNED, p002200:205-209, generics/overview.md:375-379 and
appendix-witness.md:151-154); the other seven (classified 2026-10-27, RG-1:
NONE, fixes to upstream code and golden edits with their merge rules).
```

<!-- google-doc-style-resume -->

**Land-time notes (D-RG-11), not committed now.** Added by each PR's
land-sequence records commit after its block:

<!-- google-doc-style-ignore -->

```text
[EV-1, PR 54, after its :3549]
_RG-1 (classified 2026-10-27, upstream f27a977d8; trunk's entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" has the quotes):_ the guides,
their content, the touched lines and the programs (classified 2026-10-27,
RG-1: NONE, upstream docs/guides holds README.md and glossary.md only); the
tutorial's `Ok`/`Err` are renamed by W-346 after the held PRs land.

[OP-2, PR 57, after its :3792]
_RG-1 (classified 2026-10-27, ...):_ the adapter arms (classified 2026-10-27,
RG-1: ALIGNED, upstream custom_witness.cpp:466-467 "TODO: Handle destruction of
adapters generally by destroying the adapted type."); `UnformedInit` for
`Optional(T*)` only (classified 2026-10-27, RG-1: ALIGNED with W-200's gap,
p000257:274); the two fixes, which upstream f27a977d8 still needs
(lower/handle.cpp:77, convert.cpp:1564-1567), the replaced lines, W-196 and the
row (classified 2026-10-27, RG-1: NONE).

[DD-1, PR 58, after its :4129]
_RG-1 (classified 2026-10-27, ...):_ the guard parentheses (classified
2026-10-27, RG-1: ALIGNED with upstream's parser, parse/handle_match.cpp:169 and
:176, where pattern_matching.md:803 omits them); the nine documented gaps
(classified 2026-10-27, RG-1: ALIGNED with gaps, each item's); the convention,
the new pages, the measured-behavior rule and the constant-value alias
(classified 2026-10-27, RG-1: NONE; p003938:82 "`alias` is not fully
designed").

[VA-1, PR 59, after its :3630]
_RG-1 (classified 2026-10-27, ...):_ (i) (classified 2026-10-27, RG-1: ALIGNED,
variadics.md:47-48 and :92 make `each` a keyword) and (vi) (classified
2026-10-27, RG-1: ALIGNED, upstream's commits); (ii), (iv), (v) and (vii)
(classified 2026-10-27, RG-1: NONE, internal and merge rules); (iii)
(classified 2026-10-27, RG-1: NONE, W-230 watches it).
```

<!-- google-doc-style-resume -->

In these four "..." stands for the full lead of EV-1's.

### A.5 The seven work items (R1; appended after W-344)

<!-- google-doc-style-ignore -->

```json
    {
      "id": "W-346",
      "kind": "missing-feature",
      "title": "EH-C (R32 (d); RG-1, D-RG-5): `Core.Result(T, E)`'s alternatives are spelled `Ok`/`Err` where upstream's README spells `Result`'s `Success`/`Failure` -- rename them, with every use, after the held PRs land and before UA-3",
      "subsystem": "core/prelude (types/result.carbon) + toolchain/lower (the entry-point epilogue) + toolchain/install (carbon/expected.h) + docs/design + testdata and conformance programs",
      "size": "M",
      "bullet": "Error handling: dedicated control flow constructs",
      "evidence": [
        "upstream docs/design/README.md:3859-3860 at f27a977d8 (\"At this point, errors are represented using [choice types](#choice-types) like `Result` and `Optional`.\") and :3164-3166 (`choice Result(T: type, Error: type)` with `Success(value: T)` and `Failure(error: Error)`); :2175-2179 (`IntResult`) and proposals/p000157-design-direction-for-sum-types.md:690-692 spell the same alternatives",
        "core/prelude/types/result.carbon:28-31 at trunk 0b999d449 (`choice Result(T: type, E: type)` with `Ok(value: T)` and `Err(error: E)`); fork/decision-log.md F-006a (:716-718 at 0b999d449) and V-3 (:38-41)",
        "lines naming `Ok` or `Err` that the held heads add (fork/register/rg1-plan.md section 4.6): PR 54 18, PR 56 2, PR 57 2, PR 62 4, PR 63 1, PR 65 1; fork/gap-analysis.md:68's example `case .Ok(v: i32)` at 0b999d449",
        "fork/register/rg1-plan.md D-RG-5 and section 2.T2; fork/rulebook.md R32 (a), (b), (d)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8), deciding F-006a under R29 (D-RG-5): upstream's README names `Result` as the choice that represents errors and spells its alternatives `Success` and `Failure`; no upstream text spells `Ok` or `Err` or marks the README's spelling as placeholder, so F-006a's spelling, which V-3 let override the README as illustrative, is a second spelling under R32 (d) now that V-3b withdrew the override. Work: rename `Ok` to `Success` and `Err` to `Failure` (the payload names `value` and `error` and the order, `Success` = 0, already match) with every use: the prelude's `Try` impl, the entry-point exit-code epilogue, `<carbon/expected.h>`'s comments, docs/design/error_handling.md and the pages that teach it, goldens by autoupdate (never by hand), conformance programs; the type parameter `E` may stay. Owner: EH-C, the `Core.Result` realignment (EH-A's successor), on trunk's base after the held PRs land (PR 54, PR 56, PR 57, PR 62, PR 63 and PR 65 add uses it renames; D-RG-8) and before UA-3, beside OV-4's W-341. Break condition: upstream adds a prelude `Result` or accepts an error-handling proposal that spells the alternatives otherwise (take that spelling), or changes the README's examples to `Ok`/`Err` (withdraw this item as ALIGNED)."
    },
    {
      "id": "W-347",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-8 narrows p005434:83's `nocapture` and `noalias` on every `ref` binding to exclusive-kind refs -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: temporal_safety.md, mutation_safety.md) + PR 53's F-013 entry",
      "size": "M",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md:83 at f27a977d8: \"The address of a `ref` binding is `nocapture` and `noalias`.\"",
        "PR 53 (claude/carbon-fork-0-1-safe, adaae4e35) fork/decision-log.md D-SAFE-8 (:3098-3125) and the register block (:3928-3929)",
        "fork/register/rg1-plan.md section 2.H1 (H1.8)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). SAFE-1 dated this narrowing as a departure from accepted text; under V-3b it is a drift. Work: SAFE-1 re-derives D-SAFE-8 so that the design keeps p005434:83's rule for every `ref` binding (the shared-kind `ref` formed from a shared `T*` is then re-designed, for example as an `unsafe` formation or an exclusive one), with the pages, section 4's lists and the F-013 entry, by a new commit on PR 53's branch under SAFE-1's review, before PR 53 lands (R32 (e)); W-348 and W-349 are re-derived with it where they interlock. Owner: SAFE-1. Break condition: an accepted upstream memory-safety proposal that narrows p005434:83 (cite it and close this item)."
    },
    {
      "id": "W-348",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-17 narrows p005434:663's plan to prevent mutation of borrowed objects in Strict (`Plain`-field writes through other shared aliases stay erroneous and Debug-detected) -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: mutation_safety.md, values.md's dated note) + PR 53's F-013 entry",
      "size": "M",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream p005434:660-664 at f27a977d8: \"Mutation of objects with a non-copy-value representation in an active value binding (\"borrowed objects\") is erroneous behavior.\" and \"Our plan is to prevent mutation of borrowed objects in Carbon's strict safe dialect.\"; :665-669 name when to relax it",
        "PR 53 fork/decision-log.md D-SAFE-17 (:3532-3568) and the register block (:3929)",
        "fork/register/rg1-plan.md section 2.H1 (H1.9)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 re-derives D-SAFE-17 so that Strict prevents mutation of borrowed objects as p005434:663 plans (the eager-copy alternative D-SAFE-17 records is one route), with the pages, the Rust mapping of D-SAFE-19 and the F-013 entry, by a new commit on PR 53's branch before it lands (R32 (e)). Owner: SAFE-1. Break condition: upstream relaxes p005434:663 under its own :665-669 conditions."
    },
    {
      "id": "W-349",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-11(d) narrows p005434:831-832's \"immutable for the duration\" of a returned loan to \"not invalidated\" -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: temporal_safety.md) + PR 53's F-013 entry",
      "size": "S",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream p005434:831-832 at f27a977d8: \"For full safety, we need each bound parameter to be immutable for the duration of the lifetime of the returned result.\"; :834 \"We will reconsider this with the memory safety design.\"",
        "PR 53 fork/decision-log.md D-SAFE-11(d) (:3297-3330) and the register block (:3929-3930)",
        "fork/register/rg1-plan.md section 2.H1 (H1.10)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 re-derives D-SAFE-11(d) so that a bound argument stays immutable for a returned loan's duration, as p005434:831-832 states full safety needs, by a new commit on PR 53's branch before it lands (R32 (e)); it interlocks with W-348 (D-SAFE-11(d) is the D-SAFE-17 narrowing at a second site). Owner: SAFE-1. Break condition: upstream's memory-safety design reconsiders the rule (p005434:834) otherwise."
    },
    {
      "id": "W-350",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-15 withdraws arithmetic.md:156-158's performance-build row (overflow and division by zero are not defined there) for Carbon code -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/expressions/arithmetic.md (PR 53's amendment) + docs/design/safety (PR 53) + PR 53's F-013 entry",
      "size": "S",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream docs/design/expressions/arithmetic.md:156-158 at f27a977d8: \"In a performance build, the optimizer can assume that such conditions don't occur. As a consequence, if they do, the behavior of the program is not defined.\"",
        "PR 53 fork/decision-log.md D-SAFE-15 (:3483-3495) and the register block (:3930-3931, which cites :155-158)",
        "fork/register/rg1-plan.md section 2.H1 (H1.11)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 restores the performance-build row (Release keeps its wrapping and division fail-stop, the row describing the non-default performance build that safety/README.md:260-262 promises; W-351), and amends arithmetic.md's dated note, the pages and the F-013 entry, by a new commit on PR 53's branch before it lands (R32 (e)). Owner: SAFE-1. Break condition: upstream withdraws or rewrites the row."
    },
    {
      "id": "W-351",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-14 withdraws safety/README.md:260-262's promise of an unsupported way to disable release hardening for benchmarking -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: README.md, spatial_safety.md) + PR 53's F-013 entry",
      "size": "S",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream docs/design/safety/README.md:260-262 at f27a977d8: \"Carbon will provide a way to disable the default hardening in release builds, but not in a supported way. Its use is expected to be strictly for benchmarking purposes.\"",
        "PR 53 fork/decision-log.md D-SAFE-14 (:3427-3482, SP4) and the register block (:3931-3932)",
        "fork/register/rg1-plan.md section 2.H1 (H1.12)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 keeps the promise (the per-site `unsafe fn GetUnchecked` stays as the supported opt-out, beside the unsupported build-level disable), amending the pages and the F-013 entry by a new commit on PR 53's branch before it lands (R32 (e)); with W-350. Owner: SAFE-1. Break condition: upstream withdraws the promise."
    },
    {
      "id": "W-352",
      "kind": "missing-feature",
      "title": "OP-1 (R32 (b), (d); RG-1, D-RG-10; W-344): `Core.Optional`'s comparisons copy and destroy each held payload (`T.Copy`, `T.Destroy`), where comparison_operators.md says comparisons \"should have no observable side-effects\" -- compare through W-320's `.Some` pattern when it lands",
      "subsystem": "core/prelude/types/optional.carbon (PR 56's comparison impls; PR 57's copy)",
      "size": "S",
      "bullet": "Stdlib: Optional",
      "evidence": [
        "upstream docs/design/expressions/comparison_operators.md:315-316 (`EqWith`: \"Additionally, these operations should have no observable side-effects.\") and :433-434 (\"the members of an `OrderedWith` implementation should have no observable side-effects.\") at f27a977d8",
        "PR 56 (claude/carbon-fork-0-1-op, 894139b34) fork/decision-log.md :3529-3541 (OP-1's block, D-OP-4's entry); PR 57 (a080c7886) :4460-4472",
        "W-344 (the register entry); W-320 (`Core.Optional` matchable by `Match`), blocked on W-324",
        "fork/register/rg1-plan.md section 2.H5 (H5.4) and D-RG-10"
      ],
      "blocked_by": ["W-320"],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8) from W-344's side-effects entry. Work: rewrite the comparison impls to compare the held payloads through W-320's `.Some` pattern bindings, without a `Copy` or a `Destroy` per operand, with their goldens by autoupdate. Owner: OP-1, on trunk's base after W-320 lands; PR 56 lands with this drift recorded in its block (D-RG-10). Re-checked with W-324 at each weekly upstream check. Break condition: W-324's break condition fires (W-320 proceeds, and this item after it), or a by-reference accessor lands on `Core.Optional` (D-OP-4's other route; this item is unblocked and scheduled before UA-3)."
    }
```

<!-- google-doc-style-resume -->

### A.6 The ledger's other R1 edits

<!-- google-doc-style-ignore -->

```text
[W-342 "notes": prepend]
DISCHARGED 2026-10-27 by RG-1's records (R1; fork/register/rg1-plan.md):
every entry of trunk's blocks is classified against upstream f27a977d8 in the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)", each DRIFT with its item (F-006a's `Ok`/`Err` filed as W-346;
SL-1's D-SL-17 is W-326's, D-SL-3 W-109's), each ALIGNED and NONE with its
quote; F-009's `overload fn` is NONE (D-RG-6). Original filing:

[W-343 "notes": append]
 Narrowed 2026-10-27 by RG-1's records (R1): the ten held blocks are classified
in the RG-1 decision-log entry; SAFE-1's five departures are W-347 to W-351,
realigned by SAFE-1 on PR 53 before it lands, and SC-1's D-SC-6 is W-139's
drift on PR 60; the records commits on PR 53, PR 52, PR 60, PR 55, PR 61 and
PR 64 follow, and R2 discharges this item.

[W-344 "notes": append]
 Narrowed 2026-10-27 by RG-1's records (R1): the side-effects entry is filed as
W-352 (owner OP-1, blocked_by W-320); the cites' correction by a new commit on
PR 56, merged into PR 57, follows, and R2 discharges this item.

[top-level "source": append]
 Updated 2026-10-27 by the RG-1 records (the V-3a register classified at
upstream f27a977d8, R32 (b)): W-346..W-352 added (F-006a's `Ok`/`Err` for
EH-C; SAFE-1's five departures from accepted text; OP-1's comparisons' side
effects, blocked by W-320) -- ids from RG-1's reservation W-346..W-359 after a
re-scan of 135 origin refs', 25 local branches' and 22 worktrees' ledgers found
none above W-345; W-353..W-359 reserved and unused; W-342 discharged, W-343
and W-344 narrowed.
```

<!-- google-doc-style-resume -->

The JSON strings hold these texts on one line each (no line breaks inside a
string), with the leading space where shown.

### A.7 The ledger's R2 edits

<!-- google-doc-style-ignore -->

```text
[W-343 "notes": prepend]
DISCHARGED 2026-10-27 by RG-1's stamp (R2): the held blocks' records commits
are made (PR 53 <sha53>, PR 52 <sha52>, PR 60 <sha60>, PR 55 <sha55>, PR 61
<sha61>, PR 64 <sha64m> and <sha64>); the drifts are W-347 to W-351 (SAFE-1,
before PR 53 lands) and W-139 (SC-1, before PR 60 lands). Original filing:

[W-344 "notes": prepend]
DISCHARGED 2026-10-27 by RG-1's stamp (R2): the cites are corrected on PR 56
(<sha56>) and merged into PR 57 (<sha57>); the side-effects entry is W-352,
blocked by W-320. Original filing:
```

<!-- google-doc-style-resume -->

### A.8 ORCHESTRATION at R1

**The "Last updated:" line.** "Last updated: 2026-10-27 (VA-2, ..." becomes
"Last updated: 2026-10-27 (RG-1's records classify the V-3a register at upstream
f27a977d8: 153 entries, 15 DRIFT, 32 ALIGNED, 106 NONE; W-346 to W-352 filed;
see the paragraph dated 2026-10-27 (RG-1) below; the earlier 2026-10-27 text
follows). 2026-10-27 (VA-2, ..." with the rest unchanged.

**The Branches row**, after `claude/carbon-fork-0-1-va2`'s:

<!-- google-doc-style-ignore -->

```text
| `claude/carbon-fork-0-1-rg1` | RG-1 records, the V-3a register classified at upstream f27a977d8 (W-342 discharged; W-343 and W-344 discharged at R2), base trunk 0b999d449: plan fork/register/rg1-plan.md; R1 files W-346 (EH-C), W-347 to W-351 (SAFE-1, PR 53) and W-352 (OP-1, blocked by W-320); the held commits on PR 53, 52, 60, 55, 56 (merged into 57), 61 (merged into 64) and 64 follow; to be held open as its PR after R2, first in the land sequence. |
```

<!-- google-doc-style-resume -->

**The dated paragraph**, after the paragraph that opens "2026-10-27 (21:24 UTC):
VA-2 is IMPLEMENTED" and ends "Next: OV-4 (W-341) and RG-1 (W-342..W-344) per
item 6 below, then UA-3.":

<!-- google-doc-style-ignore -->

```text
Later on 2026-10-27 (RG-1): the V-3a register is classified at upstream
f27a977d8 (2026-10-27, upstream PR 8045), records first, on
claude/carbon-fork-0-1-rg1 (decision-log entry "RG-1: the V-3a register
classified at f27a977d8 (2026-10-27)"; fork/register/rg1-plan.md). Every entry
of the 25 blocks and V-3's design-fork entries was read against the page at the
tip: 153 entries, 15 DRIFT, 32 ALIGNED, 106 NONE, 11 waiting on upstream.
F-006a's `Ok`/`Err` is a drift against README.md's `Success`/`Failure` (W-346,
owner EH-C, after the held PRs land and before UA-3); F-009's `overload fn` is
not (p002875 calls its spelling placeholder). PR 53 carries five drifts, its
departures from accepted text (W-347 to W-351, owner SAFE-1), so the land
sequence's first PR waits on SAFE-1's re-derivation commit; PR 60 carries one,
D-SC-6 (W-139, whose break condition fired: upstream decided issue 2153), which
SC-1 realigns before PR 60 lands; PR 56's comparisons' side effects are W-352,
blocked by W-320. Held records commits follow on PR 53, PR 52, PR 60, PR 55, PR
56 (merged into PR 57), PR 61 (merged into PR 64) and PR 64, then the stamp R2.
No build, merge or dispatch; Actions is still disabled. Sixteen PRs are held
open; none is merged.
```

<!-- google-doc-style-resume -->

**Next actions item 6** becomes:

<!-- google-doc-style-ignore -->

```text
6.  **R32 work from the 2026-10-26 weekly check and RG-1 (2026-10-27)**: W-341
    (OV-4: an `overload fn` member with Carbon default parameter values called
    with a defaulted argument omitted; the arity step and the overload probe
    follow `default_value_arity`, and F-009j is rewritten) after VA-2 lands and
    before UA-3, on trunk's base. RG-1 (W-342 discharged; W-343 and W-344 at its
    stamp) classified the V-3a register at upstream f27a977d8; its drifts, each
    before UA-3: W-347 to W-351 (SAFE-1: a re-derivation commit on PR 53's
    branch under its own review before PR 53 lands, which is first in the land
    sequence after RG-1's own PR), W-139 (SC-1: a fix commit on PR 60's branch,
    with its fills, before PR 60 lands), W-346 (EH-C: `Core.Result`'s
    `Success`/`Failure`, on trunk's base after the held PRs land, beside W-341)
    and W-352 (OP-1, blocked by W-320 and so on W-324: re-checked with W-324 at
    each weekly upstream check). UA-3 follows W-341 and W-346.
```

<!-- google-doc-style-resume -->

### A.9 ORCHESTRATION at R2

In the Branches rows of `claude/carbon-fork-0-1-safe`, `-cmake`, `-sc`, `-st`,
`-op`, `-op2`, `-tp` and `-ct`, the head becomes the new one and the row gains
"; amended 2026-10-27 by RG-1's records commit <sha> (R32 (e)), the description
refreshed" (for op2 and ct: "by RG-1's merge <sha> of PR 56's (PR 61's)
commit", and ct also "and its count correction <sha64>"). The rg1 row's last
clause becomes "R1 and R2 made; to be held open as its PR, first in the land
sequence." A sentence is appended to the RG-1 dated paragraph: "R2 (date): the
held commits are made and recorded; W-343 and W-344 are discharged."

### A.10 The held commits' messages (bodies)

<!-- google-doc-style-ignore -->

```text
H53  SAFE-1 records: five departures from accepted text filed as drifts W-347 to W-351, the README cite corrected (RG-1; R32 (a), (b), (e))

A new commit on PR 53's branch, never a rewrite (R32 (e)), from RG-1's
classification at upstream f27a977d8 (fork/register/rg1-plan.md on
claude/carbon-fork-0-1-rg1, section 2.H1): the register block's departures at
p005434:83, :663 and :831-832, arithmetic.md:156-158 and safety
README.md:260-262 are drifts under V-3b, filed on trunk as W-347 to W-351 and
realigned by SAFE-1 by a new commit here before this PR lands; the zero-fill
cite now names upstream's README.md:2130-2132 instead of this branch's copy,
and arithmetic.md's range is upstream's :156-158. Records only.

H52  CM-1 records: the CMake measurement corrected against upstream's tip and milestone (RG-1; R32 (a), (e))

A new commit on PR 52's branch (R32 (e)): the register block said upstream's
thirteen `cmake` mentions were Bazel-internal, a count taken on the fork's
tree; at upstream f27a977d8 thirteen files mention CMake, and
docs/project/milestones.md:230-231 names CMake integration as a 0.1
deliverable, which this branch delivers (RG-1, rg1-plan.md section 2.H2). No
drift. Records only.

H60  SC-1 records: D-SC-6 is a drift under R32 (d), W-139's break condition fired at upstream f27a977d8 (RG-1; R32 (b), (e))

A new commit on PR 60's branch (R32 (e)): generics/overview.md:375-379 and
appendix-witness.md:151-154 record upstream's decision of leads issue 2153 to
support checked generics calling templates by monomorphization, so D-SC-6's
definition-time rejection is a drift (RG-1, rg1-plan.md section 2.H9). The
register block and W-139 say so; SC-1 realigns the check by a new commit here
before this PR lands. Records only.

H55  ST-1 records: the README cite corrected to upstream's line at f27a977d8 (RG-1; R32 (a), (e))

A new commit on PR 55's branch (R32 (e)): the register block cited README.md:629
for upstream's owning `String`, the fork's copy's line; upstream's is :627 at
f27a977d8. No drift: README.md:622 calls the string types provisional (RG-1,
rg1-plan.md section 2.H4). Records only.

H56  OP-1 records: the register's cites corrected to upstream's at f27a977d8, the comparisons' side effects filed as W-352 (RG-1; R32 (a), (b), (e); W-344)

A new commit on PR 56's branch (R32 (e)), from W-344: the block's cites become
upstream's p002188:489-490 and pattern_matching.md:526-527 (the latter was this
branch's own copy); the comparisons' `T.Copy` and `T.Destroy` against
comparison_operators.md's "should have no observable side-effects" are filed on
trunk as W-352, blocked by W-320, and this PR lands with the drift recorded
(rg1-plan.md D-RG-10). Records only.

H57  OP-2: merge OP-1's RG-1 records commit (R32 (e))

Merges claude/carbon-fork-0-1-op at <sha56> (RG-1's H56) into PR 57's branch,
which is stacked on PR 56's. The OP-1 block's copy takes the corrected cites
and the dated note. No toolchain change.

H61  TP-1 records: the cross-file lowering TODO cited at upstream's line at f27a977d8 (RG-1; R32 (a), (e))

A new commit on PR 61's branch (R32 (e)): the register block cited
lower/handle.cpp:524, this branch's copy; upstream's TODO is
lower/handle.cpp:384-390 at f27a977d8. No drift (RG-1, rg1-plan.md section
2.H10). Records only.

H64m CT-1: merge TP-1's RG-1 records commit (R32 (e))

Merges claude/carbon-fork-0-1-tp at <sha61> (RG-1's H61) into PR 64's branch,
which is stacked on PR 61's. The TP-1 block's copy takes the corrected cite
and the dated note. No toolchain change.

H64  CT-1 records: the register block names ten entries, not nine (RG-1; R32 (e), R10)

A new commit on PR 64's branch (R32 (e)): plan §0.10 lists ten register
entries, the tenth (`SpecificConstant`'s category) added at plan rev 4
(RR2-M1) before the discharge commit wrote "the nine"; the block now says ten
and carries RG-1's dated note (rg1-plan.md section 2.H11). No drift. Records
only.
```

<!-- google-doc-style-resume -->

Each message's first line is the subject; the body follows a blank line, and
the two trailers follow the body after a blank line.

### A.11 The description refreshes

Appended to each PR's description under "RG-1 amendment (2026-10-27)":

<!-- google-doc-style-ignore -->

```text
PR 53: RG-1 classified this PR's V-3a register block against upstream
f27a977d8 (commit <sha53>, records only). Its five departures from accepted
text are drifts under R32 and V-3b, filed on trunk as W-347 (p005434:83's
`noalias`), W-348 (p005434:663), W-349 (p005434:831-832), W-350
(arithmetic.md's performance-build row) and W-351 (safety README's benchmarking
disable); SAFE-1 realigns them by a new commit on this branch, under its own
review, before this PR lands. The zero-fill cite now names upstream's
README.md:2130-2132. The rest of the block is aligned with upstream or has no
upstream counterpart.

PR 52: RG-1 corrected the register block's CMake measurement against upstream
f27a977d8 (commit <sha52>, records only): upstream has no CMake files, and its
docs/project/milestones.md:230-231 names CMake integration as a 0.1
deliverable, which this PR delivers. No drift.

PR 60: RG-1 found D-SC-6 to be a drift under R32 (commit <sha60>, records
only): upstream decided leads issue 2153 (generics/overview.md:375-379,
appendix-witness.md:151-154), so rejecting a checked-generic argument to a
template parameter at the definition contradicts it; W-139 is the item, and
SC-1 realigns the check by a new commit on this branch before this PR lands.

PR 55: RG-1 corrected the register block's README cite to upstream's line
(README.md:627 at f27a977d8; commit <sha55>, records only). No drift.

PR 56: RG-1 corrected the register block's cites to upstream's p002188:489-490
and pattern_matching.md:526-527 (commit <sha56>, records only, W-344) and filed
the comparisons' side effects as W-352, blocked by W-320: this PR lands with
the drift recorded.

PR 57: PR 56's RG-1 records commit is merged (merge <sha57>); no OP-2 change.

PR 61: RG-1 corrected the register block's cite of the cross-file lowering TODO
to upstream's lower/handle.cpp:384-390 at f27a977d8 (commit <sha61>, records
only). No drift.

PR 64: PR 61's RG-1 records commit is merged (merge <sha64m>), and the register
block's count is corrected to the ten entries of plan §0.10 (commit <sha64>,
records only). No drift.
```

<!-- google-doc-style-resume -->

## Hand-off notes for the implementer

1.  Read this plan's section 1 before any record: the verdicts follow D-RG-2's
    test, and a reviewer's change of a verdict changes section 2, the counts
    (0.2, the summary, A.1, A.8) and the items together.
2.  Re-run section 4's checks first: the quotes (4.2, 140 lines), the block scan
    (4.4), the re-scan (4.5). A moved upstream line or a moved held head stops
    the work until the plan is amended (section 6, R-1 and R-7).
3.  Edit the log bottom up: the trunk notes of A.3 from T12 to T1, then A.1 at
    :276. Use the Edit tool or Write, never a shell append (R25), and run prek
    to a fixpoint with the R31 counts of 4.1 before each commit.
4.  The ledger: append A.5's seven items after W-344, keep two-space JSON
    indentation, and apply A.6's string edits; `json.load` it before the commit.
5.  The held commits: one scratch worktree per branch under /dev/shm/rg1-impl/,
    detached at the head named in 3.2, deleted after its push; check 4.7's
    merge-tree before each push; never touch the held worktrees under
    /home/user/carbon-<x> and never check out a held branch in the main
    checkout.
6.  Write each PR's refresh to
    scratchpad/rg1/impl/pr_<NN>_refresh.md (3.3, A.11) and name the files in the
    hand-off; the orchestrator re-posts them.
7.  R2 fills the `<sha..>` placeholders of A.2, A.7, A.9, A.10 and A.11 and
    nothing else.
8.  No model identifier in any file; the trailers are the one exception.
9.  RG-1's PR opens held, base trunk, after R2 and its review; its land position
    is first (section 5).
