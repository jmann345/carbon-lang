# RG-1 plan: the V-3a register classified at upstream f27a977d8

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 2, 2026-10-28, reviews A and B folded (section "Review fold
record (rev 2, 2026-10-28)" at the end); not signed off: the re-review decides.
Rev 1, 2026-10-27, was the planner's draft. Records only: no toolchain, prelude,
golden, program or workflow file changes with this plan or with any commit it
specifies RG-1 makes; the code realignments it files are their owners' commits
(D-RG-7). RG-1 is workstream W-342, W-343 and W-344 of
fork/inventory/work-items.json, scheduled by fork/ORCHESTRATION.md Next actions
item 6, on branch claude/carbon-fork-0-1-rg1 cut from trunk 0b999d449.

**Summary.** Every V-3a register entry on trunk and on the sixteen held heads is
classified against upstream's tip f27a977d8 by the rule of fork/rulebook.md R32,
and re-checked unchanged at the moved tip e6fddcf97 (section 0.1): 155 entries
in 26 blocks and V-3's design-fork entries (section 0.2). The verdicts are 19
DRIFT, 34 ALIGNED and 102 NONE; every NONE carries a quote of the nearest
upstream passage or a scripted silence check (section 4.2), and every NONE and
ALIGNED entry carries the standing register watch item W-355 (D-RG-17). Ten
entries, three of the DRIFTs among them, wait on an upstream decision or on an
item blocked by one (section 7). Eight DRIFT entries were already carried by
items filed before RG-1 (W-109 twice, W-320 with W-324, W-321, W-322, W-326
twice, and SC-1's W-139, whose break condition was already met when it was
filed: upstream's text predates the cut), and eleven are carried by items this
plan files: W-346 (F-006a), W-347 to W-351 and W-353 (SAFE-1's six departures
from accepted text), W-352 (OP-1's comparisons) and W-354 (D-SL-16's yield and
D-SL-19's keying, three entries). W-355 is the register watch item and W-356 a
fork crash RG-1's probe found. The two R29 decisions are: F-006a's `Ok`/`Err`
is a DRIFT (upstream's error-handling statement names `Result` and links the
choice-types section, whose result choice spells its alternatives `Success` and
`Failure`; W-346, owner EH-C, on trunk after the held PRs land and before UA-3,
reversing the user's F-006a under the 2026-10-21 directive, veto-able), and
F-009's `overload fn` is NONE (upstream's only spelling is p002875's
self-declared "placeholder syntax", and pattern_matching.md says there is no
approved design). Three held PRs carry drifts and wait for their owners'
realignment commits before they land (R32 (e)): PR 53 (SAFE-1, six), PR 56
(OP-1, W-352) and PR 60 (SC-1, W-139). Seven held branches gain one RG-1
records commit each (PR 53, PR 52, PR 60, PR 55, PR 56, PR 61 and PR 64), PR 57
and PR 64 also gain a merge commit of their base PR's new head, and RG-1's own
PR is records only, held, base trunk, first in the land sequence. Every RG-1
commit is staged unpushed, reviewed twice and fixed before any push (D-RG-13).
(amended 2026-10-28, review fold: A-M1 to A-M5, A-m1, A-m3, A-m4, B-B1, B-M2 to
B-M5, B-m5)

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
-   Review fold record (rev 2, 2026-10-28)

## §0 Audit

### §0.1 Upstream's tip

`git -C /home/user/carbon-lang fetch -q upstream trunk` at 2026-10-27 22:00 UTC
gave upstream/trunk f27a977d86e2a4f2af91d9b1a668c2ed299bd055, committed
2026-10-27 21:05:53 UTC, subject "Fix ASan CI failures due to `preserve_none`"
(upstream PR 8045). It is 131 commits past the fork's cut c1e83b0b7 and 14 past
21c825a3f, the tip the weekly check of 2026-10-26 read. Every upstream quote in
this plan is read at f27a977d8 with `git show f27a977d8:<path>`; none is read
from a fork copy of a page (R32 (a)).

The re-check at rev 2 (amended 2026-10-28, review fold: A-m4, B-m5): the fetch
at 2026-10-27 23:00 UTC gives e6fddcf9751b26ba4801e6bab7481bf6de00fa7a,
committed 2026-10-27 22:16:05 UTC, "Add all stores in File to CollectMemUsage"
(upstream PR 8050), two commits past f27a977d8; the other is c008bec1a, "Fix
clang-tidy issue with the `u` suffix" (upstream PR 8047). Together they touch
only toolchain/base/mem_usage.h, toolchain/lex/lex.cpp and
toolchain/sem_ir/file.cpp, none of them a file this plan quotes or checks.
Section 4.2's two scripts pass at both shas: "checked 230 quotes, 0 failed" and
"checked 89 silence checks, 0 failed". The classification stays named by
f27a977d8; R1 re-runs both scripts at the tip it fetches and names that sha
beside f27a977d8 in every record it writes (section 3.1), and a FAIL stops R1
until the plan is amended (R-1).

The fourteen commits from 21c825a3f to f27a977d8, by sha and subject (R32 (c),
for the record of this plan; the next weekly check classifies them):

| Commit | Subject | Paths that matter here |
| --- | --- | --- |
| c7de72757 | Adds support for exporting default values for concrete parameters of generic functions. (upstream PR 8019) | check/cpp/export.cpp; W-341's neighbour, no register entry |
| e9d8d06f9 | Add lifetime comments to CanonicalValueStore and IdentifierStore (upstream PR 8037) | none |
| 8779d15e1 | Optimize the `musttail`-dispatch in the lexer (upstream PR 8034) | lex/lex.cpp |
| 56d9bbc40 | Support C++ friend declarations for Carbon generic classes (upstream PR 8026) | check/cpp/import.cpp |
| 600fd55ba | Add a realistic header compile benchmark (upstream PR 8023) | none |
| dd30c7655 | Bump fast-uri from 3.1.8 to 3.1.9 (upstream PR 8028) | none |
| 57bf903ef | Keep resolving generics and templates until they're all resolved (upstream PR 7957) | check/generic.cpp, generic.h, function.cpp, check_unit.cpp, cpp/generate_ast.cpp; adjacent to CT-1's D-CT-17 and TP-1's entries, no entry's quote |
| 05a7ecbd3 | Move `SubobjectDestroy` and `SelfDestruct` out of interface `Destroy` (upstream PR 7942) | core/prelude/destroy.carbon, check/custom_witness.cpp, sem_ir/core_interface_kind.def; a prelude signature change, classified below |
| 7cc1d0898 | Add an AVX2 optimized newline scanner (upstream PR 8032) | lex/lex.cpp |
| 5f1dd4941 | Optimize the horizontal space skip fast path for x86 (upstream PR 8033) | lex/lex.cpp |
| 4c5734a8c | Make tag application and removal a compile time property (upstream PR 8042) | none of check, lower, prelude |
| 33863ed07 | Enhance benchmark source to have more call expressions (upstream PR 8029) | none |
| a45002667 | Clarify the infinitely recursive types through interop test (upstream PR 8046) | a test |
| f27a977d8 | Fix ASan CI failures due to `preserve_none` (upstream PR 8045) | lex/BUILD, lex/lex.cpp |

05a7ecbd3 is the window's one prelude signature change, and it is classified at
the tip, not deferred (amended 2026-10-28, review fold: A-M1, B-m9). At
f27a977d8 core/prelude/destroy.carbon declares `interface DestroyImpl` with the
TODO "rename to `Destroy` when `require impls` adds a witness table entry."
(:14), a blanket `impl forall [T: SubobjectDestroy] T as DestroyImpl` whose `Op`
is `"no_op"` (:23-24), `constraint Destroy` requiring both interfaces (:27-28)
and `fn SelfDestruct[T: Destroy](ref t: T)`, whose body calls
`t.(DestroyImpl.Op)();` and then `t.(SubobjectDestroy.Op)();` (:36-38). Every
scope cleanup calls it (check/control_flow.cpp:158
`BuildSelfDestructCall(context, destroy_id);`), and the custom witness now
serves only `SubobjectDestroy` (check/custom_witness.cpp:1054), so a declared
destructor is reached by ordinary impl selection for locals and fields alike;
upstream's own test declares it as `impl as Core.DestroyImpl` with
`_CSelfDestruct` calling the declared `Op`
(lower/testdata/var/destroy_control_flow.carbon :18 and :187-188). Three
consequences (D-RG-16): the fork's declared-destructor spelling `impl as
Destroy` (trunk's `Core.Buf`, PR 55's `StringBuf`, PR 57's
`DefaultOptionalStorage`) is ALIGNED with the :14 TODO, which names `Destroy` as
the interface's final name; SL-1's own break condition for D-SL-16 and D-SL-19
("if upstream's destroy-op synthesis starts calling declared impls, D-SL-16's
yield and D-SL-19's keying are dropped in favor of it", trunk :4430-4432) is
met, for locals as well as for the fields PR 51's UA-2 record already found, so
T5.6, T5.9 and H12.1 are DRIFTs carried by W-354; and OP-2's adapter arms and
UN-1's `CoreInterface` kinds keep their merge rules (H6.3, T9.1), which UA-3
applies.

### §0.2 The blocks and their entries

Each block was re-found by its opening words in the decision log at the head
named, not taken from the ledger's line numbers (the script is section 4.4,
widened at rev 2 to every paragraph that names the register, which found PR
51's; amended 2026-10-28, review fold: A-M1). "Entries" is the count section 2
enumerates; the split of a block's prose into entries is section 1's D-RG-12.

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
| T10 EH-B (with the `noexcept` fence UA-1's review counts at :6607) | trunk 0b999d449 | :5596-5617 | 4 |
| T11 EH-A | trunk 0b999d449 | :5961-5971 | 4 |
| T12 UA-1's watch list | trunk 0b999d449 | :6768-6782 | 7 |
| H1 SAFE-1 (PR 53) | claude/carbon-fork-0-1-safe adaae4e35 | :3920-3938 | 15 |
| H2 CM-1 (PR 52) | claude/carbon-fork-0-1-cmake ea573f672 | :3119-3133 | 7 |
| H3 EV-1 (PR 54) | claude/carbon-fork-0-1-ev cb3ef2e74 | :3538-3549 | 3 |
| H4 ST-1 (PR 55) | claude/carbon-fork-0-1-st 21307851a | :3503-3516 | 6 |
| H5 OP-1 (PR 56; PR 57's copy) | claude/carbon-fork-0-1-op 894139b34; op2 a080c7886 | :3529-3541; :4460-4472 | 6 |
| H6 OP-2 (PR 57) | claude/carbon-fork-0-1-op2 a080c7886 | :3779-3792 | 7 |
| H7 DD-1 (PR 58) | claude/carbon-fork-0-1-dd fcee90d9b | :4114-4129 | 6 |
| H8 VA-1 (PR 59; PR 66's copy) | claude/carbon-fork-0-1-va b0822a744; va2 43c8ab476 | :3609-3630; :3609-3630 | 8 |
| H9 SC-1 (PR 60) | claude/carbon-fork-0-1-sc 40a76ab81 | :4187-4202 | 6 |
| H10 TP-1 (PR 61; PR 64's copy) | claude/carbon-fork-0-1-tp 5661a35c8; ct 4a3220c11 | :4185-4208; :4185-4208 | 8 |
| H11 CT-1 (PR 64) | claude/carbon-fork-0-1-ct 4a3220c11 | :8341-8342, its entries in fork/cpp-templates/plan.md §0.10 :935-1004 at that head | 10 |
| H12 UA-2's register re-read (PR 51) | claude/carbon-fork-0-1-ua2 f96fe8a7a | :6226-6232 | 1 |
| C1 DR-0's register as extended on PR 63 and PR 65 (carries work items) | claude/carbon-fork-0-1-dr 89aabd125; dr-idx fee0ef31c | :241-255; :241-256 (the two entries beyond T0's three at :247-254) | 2 |
| C2 VA-2's register entries (PR 66; carry work items) | claude/carbon-fork-0-1-va2 43c8ab476 | :3672-3676 | 6 |

Totals: 26 blocks and the design-fork group T2; 64 entries on trunk (T0 to T12)
and 91 on the held heads (H1 to H12, 83, and C1 and C2, 8): 155. Rev 2's changes
to rev 1's 153 (amended 2026-10-28, review fold: A-M1, A-m2, A-m3): T10.4 added
(EH-B's `noexcept` fence, which UA-1's review counts among EH-B's entries); H3.4
removed (the twelve transcribed programs are not in EV-1's block); H8.2 split,
`(... x)` as a tuple becoming H8.8; H12 added (PR 51's paragraph). The ledger's
and the weekly check's cites (trunk 563135b40) sit 15 lines earlier for every
trunk block from F-006 on (the 2026-10-26 weekly's paragraph in DR-0 moved
them), and the held cites of W-343 match the heads above. T2 is not a block of
its own in the log: V-3 put F-006a on "a divergence-risk register" (:38-41),
OV-1's block keeps "F-009's register entries (closed sets, first-match, the
marker)" (:4977-4978), UN-1's keeps "the `union` keyword, the class-shaped union
declaration and the byte-reinterpretation read semantics" as "F-007's register
entries" (:5477-5479), and UA-1's review names all three (:6652-6653); RG-1
classifies them together and notes them after UA-1's review. H12 is PR 51's UA-2
record "The SL-1 register trigger (block 9 of the UA-1 review below) is met for
FIELDS — upstream's walk reaches declared impls through `SelfDestruct` — while
D-SL-16's yield still makes a `Buf` LOCAL free, so the yield stays" with its
"§0.6's register row, closed: re-read at UA-2, the UA-1 listing below stands"
(f96fe8a7a :6226-6232); the listing is a cross-reference to T1 to T12 and its
one new statement is H12.1. PR 62 (sv, 0ef8a0334) and PR 66 beyond C2 have no
register block of their own: the widened scan of each head's log (section 4.4)
finds none. PR 63's and PR 65's other three DR-0 entries are T0's.

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
5661a35c8). Re-read at rev 2: every head unchanged.

### §0.5 The id re-scan

CT-1's command (fork/cpp-templates/plan.md §0.11 on PR 64) widened to
`W-3[4-9][0-9]`, run after `git -C /home/user/carbon-lang fetch -q origin` (the
command is section 4.5). At rev 2 (amended 2026-10-28, review fold: A-m4) it
covers 136 origin refs, 25 local branches and 21 worktrees: the ledgers hold
W-340 (three), W-341 to W-344 (ten each) and W-345 (three); outside this plan's
own file, the text of `fork/` names W-346 and W-398 only as the bound "W-346 to
W-398" in VA-2's fork/variadics/va2-plan.md (:2830, :4196 and :10787 on PR 66's
head) and W-399 only as DR-1's range bound "no id from W-330 to W-399" in
fork/direction/plan.md (PR 63 and PR 65); no ledger holds W-346 or any id above
it. W-345 is VA-2's. RG-1 reserves W-346 to W-359, files W-346 to W-356 and
leaves W-357 to W-359 unused; it changes no item from W-320 to W-345 except the
three it owns, W-342, W-343 and W-344, whose notes it amends (section 3), and
W-139 on PR 60, whose notes SC-1's records commit amends (H60). The command is
repeated before each records commit (section 4.5).

## §1 Rules and decisions

Every decision is auto-adopted under R29(a), recorded in the RG-1 decision-log
entry for after-the-fact veto, and carries its break condition. Ids D-RG-1 to
D-RG-19 are minted in this plan only; RG-1 mints no F id.

**D-RG-1: the classification rule.** For each entry the plan states the fork
mechanism and where it lives at the head read, upstream's text for that
mechanism at f27a977d8 with page and line, and one verdict: DRIFT (upstream has
designed the mechanism and the fork spells it otherwise, R32 (d), whether the
fork's spelling came first or not), ALIGNED (the fork's spelling or rule is
upstream's), or NONE (a fork-local surface with no upstream counterpart:
upstream is silent). A NONE row shows the silence: a verbatim quote of the
nearest upstream passage, or a silence check of section 4.2 with its command and
result at the tip, and usually both (amended 2026-10-28, review fold: B-B1). An
entry whose classification or realignment waits on an upstream decision, or on
an item blocked by one, is marked "blocked" beside its verdict and is a residue
(section 7). Break condition: an owner directive that reinstates V-3's override
clause (D-DR-4's), which would turn the register back into notes.

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
`ref ElementType`, against a read-only `Core.Slice`. So does SelfDestruct's call
of `DestroyImpl.Op` against D-SL-16's yield (D-RG-16). Examples that fail it
here: p002875:481's "using placeholder syntax" (iii), README.md:622's "This is
provisional" for `String` (iii), p000157:228-229's "the details discussed here
should be considered provisional" for its `Result` sketch (iii),
functions.md:310's `Thread.Make`, written to show a lambda capture (ii), and
README.md:3164's `Result` under "Generic choice types", whose subject is
parameterization (ii) (amended 2026-10-28, review fold: A-m1, B-m4). Break
condition: an owner ruling that illustrative examples are direction (then T2's
`Thread` and the NONE verdicts resting on (ii) are re-read), or that a
placeholder is (then F-009 flips).

**D-RG-3: toolchain-internal surfaces are NONE.** SemIR instruction kinds, parse
node kinds, diagnostic kinds, function parameters, mangling markers, raw-dump
fields, fixes to upstream functions and merge rules are not upstream's "recorded
direction" under R32's list of sources; such an entry is NONE with a silence
check (a G check of section 4.2 that finds the identifier absent at the tip, or
an L check that counts the upstream commits to the file since the cut) and,
where upstream has a counterpart, the nearest passage; its merge rule is its
break condition (amended 2026-10-28, review fold: B-B1). Upstream's own later
internal code (4a8993af2's `storage_access_block_id`) is absorbed by the advance
UA-3 under that merge rule, and any item that already schedules the
reconciliation (W-258) is named. A NONE whose own break condition has already
fired at the tip is not left NONE: it is a DRIFT with a work item (D-SL-16 and
D-SL-19 against 05a7ecbd3, D-RG-16). A toolchain TODO that names a mechanism is
direction (DR-0's loop TODO): an entry implementing it otherwise is a DRIFT, and
one implementing it as named is ALIGNED (OP-2's adapter arms against
custom_witness.cpp:466-467). Break condition: an upstream design page or
proposal that specifies one of these surfaces.

**D-RG-4: partial implementations.** An entry that implements part of an
upstream-designed mechanism with upstream's spelling, its gap carried by a work
item, is ALIGNED with the gap named (TP-1's D-TP-12 and W-268, OP-2's
`UnformedInit` and W-200, CM-1's Core-object helper and W-003). It is a DRIFT
only when the fork's rule decides a case the design decides otherwise (SC-1's
D-SC-6). Break condition: a review that shows a gap item's case decided against
the design (then that entry is re-classified DRIFT and its item re-titled).

**D-RG-5 (R29): F-006a's `Ok`/`Err` is a DRIFT.** The ground is upstream's
statement about the mechanism, the README's "Error handling" section: "At this
point, errors are represented using `[choice types](#choice-types)` like
`Result` and `Optional`." (docs/design/README.md:3856-3860; its link markup set
in a code span). It names `Result` as Carbon's error representation (D-RG-2 (ii)
holds: the section's subject is error handling) and links the choice-types
section, which is the mechanism's own definition and whose result choice spells
its alternatives `Success(value: i32)` and `Failure(error: String)` (`choice
IntResult`, :2167-2177). The README's `Result` itself, under "Generic choice
types" (:3159-3166, `choice Result(T: type, Error: type)` with `Success(value:
T)` and `Failure(error: Error)`), has parameterization as its subject and so
only corroborates; p000157's sketch (:690-692) is provisional by its own
:228-229 and is not counted. No upstream text spells `Ok` or `Err`, and none
marks `Success` or `Failure` as placeholder. The fork's `Core.Result(T, E)` with
`Ok(value: T)` and `Err(error: E)` (core/prelude/types/result.carbon:28-31 at
trunk) is a second spelling under D-RG-2; "illustrative" was V-3's override
ground, which V-3b withdrew. W-346 reverses a user decision: "Sub-decision
F-006a (user, 2026-07-19): variant naming is `Ok`/`Err`, overriding the design
README's older Success/Failure spelling" (decision-log :716-718 at 0b999d449).
It does so under the owner directive of 2026-10-21 ("Direction drifts are not
permitted"), recorded as such and veto-able by the user after the fact. The
realignment renames the alternatives (payload names `value` and `error` and the
order, `Success` = 0, already match), with every use: the entry-point epilogue,
EH-B's `<carbon/expected.h>` comments, docs, goldens and programs. It is W-346,
owner EH-C (the `Core.Result` realignment, EH-A's successor), on trunk's base
after the held PRs land and before UA-3, so that it renames the uses the held
PRs add rather than amending them for a trunk name (D-RG-8): PR 54 adds 18 lines
naming `Ok` or `Err`, PR 56 2 (carried unchanged by PR 57), PR 62 4 and PR 63 1
(carried unchanged by PR 65; section 4.6) (amended 2026-10-28, review fold:
A-m1, A-m3, B-m4). Break condition: upstream adds a prelude `Result` or accepts
an error-handling proposal that spells the alternatives otherwise (W-346 takes
that spelling), or changes the README's examples to `Ok`/`Err` (W-346 is
withdrawn as ALIGNED), or the user vetoes the reversal (W-346 is withdrawn and
the veto recorded against R32).

**D-RG-6 (R29): F-009's `overload fn` is NONE.** Upstream's only spelling of an
overload-set introducer is p002875's "given the following, using placeholder
syntax:" (:481) before `overloaded fn Abs[...]` (:484-485), and
pattern_matching.md says "We do not yet have an approved design for overloaded
functions" (:696); upstream's lexer has no `overload` or `overloaded` token
(lex/token_kind.def; check T7.1) and its only toolchain mention is
sem_ir/function.h:547's "TODO: Also include parameters to support overloaded
functions." The semantics F-009 chose are ALIGNED: closed same-library sets
with static_open_extension.md:52-54 ("function overloading is limited in Carbon
to only signatures defined together in the same library") and
declaration-order first match with pattern_matching.md:696-697 ("it is
anticipated that declaration order will be used in that case too") and
p002875:473-476. Break condition: upstream accepts an overloading proposal or
lands a token or design page that spells the introducer; the fork then renames
(a mechanical change of lex/token_kind.def:221, the parser and the docs), filed
as a DRIFT at that weekly check.

**D-RG-7: what RG-1 amends on a held branch, and what it only files.** RG-1's
commit on a held branch is records and text only: the block's dated note,
corrections of a cite that points at a fork copy or of a stale count, dated
notes on the branch's own ledger items, and a dated blockquote on a fork page
that states upstream's position wrongly (PR 60's template_constraints.md, H60;
amended 2026-10-28, review fold: A-M3). A realignment that is a mechanical text
change with no consequence elsewhere is RG-1's; there is none this round. A
realignment that changes a design decision or code is the filed item's, owned by
the PR's workstream, made by a new commit on that PR's branch under its own
review before the PR lands, and RG-1's commit records the item. SAFE-1's six
are design changes, not restatements: each departure is named by its decision
id on three to five of PR 53's pages and the rules there are derived from it,
so restating upstream's sentence on one page would leave the others stating the
narrowed rule (amended 2026-10-28, review fold: A-M5). The dependent lines at
adaae4e35, by `git grep -n -E '<id>' origin/claude/carbon-fork-0-1-safe --
docs`:

| Item | Decision | Dependent lines on PR 53 (adaae4e35) |
| --- | --- | --- |
| W-347 | D-SAFE-8 (13 lines) | safety/mutation_safety.md :76, :143, :159, :850; safety/temporal_safety.md :75, :191, :212, :907, :947, :968, :1096, :1155; values.md :137 |
| W-348 | D-SAFE-17 (20 lines) | safety/README.md :322; safety/mutation_safety.md :74, :282, :419, :465, :619, :832, :886, :906, :936; safety/rust_interop.md :132, :399, :585, :633; safety/temporal_safety.md :250, :505, :628, :1128; values.md :137, :485 |
| W-349 | D-SAFE-11 (7 lines) | safety/mutation_safety.md :463; safety/temporal_safety.md :75, :321, :475, :524, :761, :1109 |
| W-350 | D-SAFE-15 (8 lines) | expressions/arithmetic.md :167; safety/spatial_safety.md :66, :248, :405, :420, :534, :584, :611 |
| W-351 | D-SAFE-14 (5 lines) | safety/README.md :561; safety/spatial_safety.md :66, :510, :556; slices.md :65 |
| W-353 | D-SAFE-13 (13 lines) | README.md :2151, :2175; safety/initialization_safety.md :64, :127, :193, :455, :517; safety/rust_interop.md :197, :217, :587; safety/temporal_safety.md :76, :585, :1125 |

(Paths are under docs/design/.) The re-derivation is SAFE-1's, scheduled in
ORCHESTRATION's Next actions with its plan amendment, two document reviews and
a fixer before PR 53 lands (A.8). Code realignments filed: SC-1's D-SC-6 (W-139,
PR 60), OP-1's comparisons (W-352, PR 56). Break condition: a reviewer shows one
of SAFE-1's six realignable by restating upstream's sentence with no dependent
line changing (then RG-1's commit carries that edit and the item is discharged
with it).

**D-RG-8: a held PR that only uses a trunk spelling does not carry its drift.**
PR 54's tutorial and three other held PRs name trunk's `Ok`/`Err` (PR 56, PR 62
and PR 63, whose lines PR 57 and PR 65 carry); the drift is trunk's prelude,
W-346 renames every use after the held PRs land, and no held PR is amended for
it. The same holds for D-SL-16's yield on every held head, PR 51 included: the
drift is trunk's code, and W-354 removes it at UA-3 (D-RG-16). Break condition:
W-346 is scheduled before a held PR that uses the spelling lands; that PR then
gains a rename commit before it lands.

**D-RG-9: an existing item that carries a drift is noted, not re-filed.** SC-1's
W-139 (PR 60's ledger) is the drift of D-SC-6; it gains a dated note on PR 60,
no new id. Its break condition ("upstream resolves issue 2153 toward checked
generics may call templates") was already met when W-139 was filed on
2026-10-12: upstream's generics/overview.md:375-379 and
appendix-witness.md:151-154 were last touched no later than 7134e23f2
(2026-09-29, the clone's shallow boundary), an ancestor of the cut c1e83b0b7
(2026-10-05), so upstream's text predates the cut and nothing "fired" in RG-1's
window (amended 2026-10-28, review fold: A-M3, B-M4). W-109, W-321, W-322 and
W-326 carry T0's, T5's and C1's drifts already. Break condition: an item's text
that no longer describes the drift (then a new id is filed and the old item
cross-referenced).

**D-RG-10: a held PR's drift is realigned before the PR lands, by any route
under the fork's control.** R32 (e) admits no carve-out: a held PR that carries
a drift is amended before it lands. An entry is "blocked" only when every
realignment route waits on upstream (C1.1's `Match.Continuation`, T5.7's and
C1.2's `like`). OP-1's comparisons (H5.4) are not blocked (amended 2026-10-28,
review fold: A-M2): D-OP-4's two closure routes were W-320's `.Some` pattern
(blocked on W-324) and "a by-reference accessor", and RG-1's read-only probe
(section 4.8) shows a third route under OP-1's control. On PR 57's install,
comparing the payloads in place over value-bound storage, `(a.value unsafe as T)
== (b.value unsafe as T)`, checks with no `Copy.Op` and no `SelfDestruct` call,
where the `Get()` route's copy emits one `Copy.Op` per operand and two
`SelfDestruct` calls. The accessor route as literally named cannot serve the
comparisons, whose `self` and `other` are value bindings of upstream's `EqWith`
and `OrderedWith` signatures: the probe's `GetRef(ref a)` is rejected with
"value expression passed to reference parameter", and a `-> val T` accessor does
not parse ("expected expression" at `val`). D-OP-4 rejected a storage-level
`Equal` because a new member of `OptionalStorage` must be implemented for the
pointer niche too, which needs pointer equality (W-174); a separate private
interface implemented only for the default storage avoids that, and the
comparison impls already require `T: Eq` or `T: Ordered`, which no pointer type
satisfies until W-174. W-352 is therefore a code commit by OP-1 on PR 56's
branch before PR 56 lands (merged into PR 57's), `blocked_by` empty, and PR 56
waits for it in the land sequence as PR 53 and PR 60 wait for theirs (section
5). Owner of the closure: OP-1, replacing W-344's "DR-1, W-320's owner, for the
closure" (amended 2026-10-28, review fold: B-m3). The `None()` entry (H5.5)
rides W-320 itself and stays a residue. Break condition: OP-1's re-derivation
shows the in-place route cannot keep D-OP-4's frozen signatures or F-015's API
(then W-352 gains `blocked_by: ["W-320"]` and PR 56 waits for W-320; it does not
land with the drift).

**D-RG-11: held blocks with no drift and no stale cite get no RG-1 commit now.**
PR 51's (H12), PR 54's (H3), PR 57's OP-2 block (H6), PR 58's (H7) and PR 59's
(H8, carried by PR 66) are classified in RG-1's entry, which names each by PR
and line, and their dated notes (Appendix A.4, "Land-time notes") are added by
the records commit of that PR's land sequence, scheduled in ORCHESTRATION's
Next actions at R1 (A.8) so that no note is left unscheduled. W-343 is narrowed
at R2 and discharged by the last of those land-time notes, PR 59's, which also
discharges the land-time obligation for PR 66's copy (amended 2026-10-28, review
fold: B-M2). Break condition: a land sequence without a records commit (the
RG-1 entry then stands as the block's note and W-343 is discharged by the
orchestrator's stamp naming it).

**D-RG-12: how a block's prose is split into entries.** Each mechanism a block
names is one entry: a list of names that rename together is one entry (SAFE-1's
library names), each dated departure or decision with its own break condition is
one (SAFE-1's eight departures, SL-1's D-SL-15 to D-SL-20), a list item whose
mechanisms take different verdicts is split (VA-1's (ii): the parse kinds H8.2
and `(... x)` as a tuple H8.8), and a sentence that only states a merge rule for
a file is one. A "the other block's entries stand" sentence is a
cross-reference, not an entry, and nothing outside a block's text is an entry
(EV-1's transcribed programs, rev 1's H3.4, are not in its block). An entry a
later review counts in a block (UA-1's review counting EH-B's `noexcept` fence)
is that block's (T10.4) (amended 2026-10-28, review fold: A-m2, A-m3). Break
condition: a reviewer's split that changes a verdict count, folded at the next
revision.

**D-RG-13: the order of work, with implementation reviews before any push.**
(amended 2026-10-28, review fold: B-M5)

1.  R1, RG-1's records commit on claude/carbon-fork-0-1-rg1 in its worktree
    /home/user/carbon-rg1 (the entry, the trunk notes, the ledger with W-346 to
    W-356 filed and W-342 discharged, ORCHESTRATION), committed and NOT pushed.
2.  The held records commits H53, H52, H60, H55, H56, H61 and H64, each made in
    a detached scratch worktree at its held head and kept reachable by a local
    ref `refs/rg1-stage/<pr>` (not a branch, never pushed), none pushed.
3.  Two independent implementation reviews of R1 and the seven staged commits,
    each re-running section 4's checks.
4.  A fixer with a budget of two rounds, each a NEW commit on top of the commit
    it fixes (never an amend, even unpushed); findings left after round 2 stop
    the work and go back to the orchestrator as a plan amendment.
5.  H57 (PR 57 merges H56's final head) and H64m (PR 64's staged head merges
    H61's final head), each checked by section 4.7's merge-trees first.
6.  The pushes, in the merge order: claude/carbon-fork-0-1-rg1 (R1 and its
    fixes), then PR 53, 52, 60, 55, 56, 57, 61 and 64 by `git push origin
    <sha>:<branch>` (a fast-forward of new commits); the stage refs are deleted;
    the description refreshes are written for the orchestrator (section 3.3).
7.  R2, the stamp on claude/carbon-fork-0-1-rg1 recording the pushed shas and
    narrowing W-343 and discharging W-344, then one focused review of R2.

Break condition: a held head that moves between staging and its push (its
staged commit is re-made on the new head by a fresh read, never rebased).

**D-RG-14: placement of the decision-log entry.** Directly after DR-0 and before
"B0 SF-1..5", because the log groups entries by workstream, DR-0 sits beside V-3
for amending it (V-3b), and RG-1 executes V-3b's "work queue whose entries each
carry a work item" for DR-0's register. DR-1's own entry, held on PR 63 and PR
65, goes there too: by the same rule DR-1 belongs directly after DR-0, so when
PR 63 lands after RG-1 its merge places DR-1's entry between DR-0's and RG-1's.
Likewise PR 60's SC-1 entry follows OV-3's block, where RG-1's T4 note goes, and
its merge keeps the note with OV-3's block, before SC-1's heading. These are the
three decision-log conflict regions section 4.7 allows (amended 2026-10-28,
review fold: B-M1). Break condition: a log reorganization that moves DR-0
(RG-1's entry moves with it).

**D-RG-15: ids.** W-346 to W-359 are reserved after the re-scan; W-346 to W-356
are filed by R1, W-357 to W-359 stay unused and are never reused. Break
condition: a re-scan before R1 that finds any of them in a ledger (the reserve
moves to the next free block of fourteen and every cite in Appendix A moves with
it before R1).

**D-RG-16: 05a7ecbd3 classified at the tip.** (amended 2026-10-28, review fold:
A-M1, B-m9) The fork's declared-destructor spelling, `impl as Destroy` with `fn
Op(ref self)` (trunk's buf.carbon, PR 55's `StringBuf`, PR 57's
`DefaultOptionalStorage`), is ALIGNED with destroy.carbon:14's TODO, "rename to
`Destroy` when `require impls` adds a witness table entry.", which names the
interface's final name; at the advance the fork's declarations take upstream's
interim `DestroyImpl` spelling only as far as the merged prelude requires, as a
merge mechanic. D-SL-16's yield (a declared impl wins destroy lookup over the
synthesized witness) and D-SL-19's class keying of `HasUserDestroyImpl` are
DRIFTs: SL-1's own break condition for both, "if upstream's destroy-op synthesis
starts calling declared impls" (trunk :4430-4432), is met at the tip for every
cleanup (destroy.carbon:36-38; control_flow.cpp:158; custom_witness.cpp:1054
serving only `SubobjectDestroy`), so the fork's yield is a second mechanism for
what upstream's `SelfDestruct` does. W-354, owner UA-3 (the advance that brings
05a7ecbd3), with SL-1's records, drops both at that advance; it cannot precede
it, because the fork's tree at the cut has no `DestroyImpl`, so it is in UA-3's
gate rather than before UA-3 (A.8). Break condition: upstream reverts 05a7ecbd3,
or its `SelfDestruct` stops calling `DestroyImpl.Op` (then T5.6, T5.9 and H12.1
return to NONE and W-354 is withdrawn).

**D-RG-17: the register stays a work queue (R32 (b)).** (amended 2026-10-28,
review fold: B-M2) Each entry carries a work item: a DRIFT its own (sections 2
and 7), and every NONE and ALIGNED entry W-355, the standing register watch item
filed by R1, owned by the weekly upstream check. At each weekly check W-355's
owner re-runs section 4.2's two scripts at the new tip, re-reads every NONE and
ALIGNED entry's break condition against the window's commits (R32 (c)), and
files a fired one as its own DRIFT item scheduled before UA-3; the dated note in
each block names W-355. A classified entry does not leave the register: it stays
in the queue under W-355 until its break condition fires or its mechanism is
removed. Break condition: an owner ruling that a classified NONE leaves the
register (then W-355 narrows to the ALIGNED entries).

**D-RG-18: a defect found by RG-1's probe is filed, not fixed.** The section 4.8
probe that tested D-OP-4's accessor route stopped trunk's install at the `CHECK`
`std::holds_alternative<CalleeState*>(state)` in
check/pattern_match.cpp:2207 after diagnosing "value expression passed to
reference parameter", where the nightly 2026.10.12 reports both diagnostics and
exits 1 (PR 57's install crashes the same way). It is W-356, owner UA-3 (re-run
at the advanced trunk; if it still stops there, the owning workstream of the
first fork frame is named and the item re-assigned), size S, filed by R1.
Break condition: the advance's re-run diagnoses cleanly (W-356 discharged with
that run's output).

**D-RG-19 (R29): ST-1's owning `Core.StringBuf` is NONE; the view's name follows
upstream's prelude.** (amended 2026-10-28, review fold: A-M4) Upstream designs
the view's name `Core.Str`: README.md:3706 ("C++'s `std::string_view` maps
directly to Carbon's `Core.Str`"), interoperability/README.md:260-261 ("Carbon's
`str` (which is an alias for `Core.Str`)"), accepted p006177:147-148 ("The
choice of `Str` over `String` for the non-owning view type is intentional."),
and a toolchain TODO that names the mechanism, sem_ir/type_info.h:381-382
("`str` / `Core.String`." then "TODO: Rename `Core.String` to `Core.Str`.").
Upstream's prelude and toolchain still spell the view `Core.String`, so the fork
keeping that class is upstream's current spelling, and D-ST-4's rejected option
(i), an early rename, is not a divergence: D-ST-4 rejected it partly because it
"preempts upstream's own rename". The owning type's name is NONE: upstream's
only text for it is README.md:627's `String` under :622's "This is provisional"
(D-RG-2 (iii)). Break condition: type_info.h:382's TODO lands upstream (the view
becomes `Core.Str` at that advance and `StringBuf` takes the owning name
README.md:627 gives, D-ST-4's break condition), or an accepted string design
names the owning type.

## §2 The classification tables

Every row gives the entry's mechanism and where it lives at the head read,
upstream's text at f27a977d8 (quoted verbatim, page:line, a quoted link's markup
set in a code span; section 4.2 re-reads each quoted line), the verdict, the
break condition and the work item. File paths without a repository prefix are
the fork's at the head named for the block; upstream paths are prefixed
"upstream". Each block's dated note is in Appendix A.3 (trunk) or A.4 (held).

A NONE row shows upstream's silence with a quote of the nearest passage, with a
silence check, or with both (D-RG-1; amended 2026-10-28, review fold: B-B1). A
check is named by its row and is a row of section 4.2's checks.tsv, re-run by
check_greps.sh at the tip: "check X: `git grep -c <flags> '<pattern>'` over
<paths> = N" sums the per-file counts at the tip; "N upstream commits since the
cut touch <paths>" is `git log --oneline c1e83b0b7..<tip> -- <paths> | wc -l`,
the state of a file a merge rule watches; "upstream's <dir>/ lists N entries" is
`git ls-tree --name-only <tip> <dir>/ | wc -l`. In a table cell `\|` is the
pattern's `|`. The item column names each DRIFT's own item; every NONE and
ALIGNED entry also carries W-355, the register watch item (D-RG-17), shown
alone where the entry has no other item.

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
| T1.1 | (i) the prelude name `Core.ControlFlow` (try.carbon:21) | silent at the tip, check T1.1: `git grep -c -w 'ControlFlow'` over core, docs/design, proposals, toolchain = 0: README.md:3858-3859 above; no `ControlFlow` in upstream | NONE | upstream names a `Try` carrier type | W-355 |
| T1.2 | (ii) the order `ControlFlow(C, B)`, continue first (try.carbon:21-23) | silent at the tip, check T1.2: `git grep -c -E '\bControlFlow\('` over core, docs/design, proposals, toolchain = 0, as T1.1 | NONE | as T1.1, with another parameter order | W-355 |
| T1.3 | (iii) the member spellings `Try`, `Branch`, `FromBreak`, `Continue`, `Break` (try.carbon:22-23, :37, :44, :47) | silent at the tip, check T1.3: `git grep -c -E 'interface Try\b\|FromBreak\|FromContinue'` over core, docs/design, proposals, toolchain = 0, as T1.1 | NONE | upstream designs a `?` operator or its interface | W-355 |

The block's parenthesis "with F-006a's `Ok`/`Err` already on the register" is a
cross-reference to T2.1.

### §2.T2 V-3's design-fork entries F-006a, F-007 and F-009 (V-3 trunk :31-41; UA-1's review :6597-6654)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T2.1 | F-006a: `Core.Result(T, E)`'s alternatives `Ok(value: T)` and `Err(error: E)` (core/prelude/types/result.carbon:28-31) | README.md:3856 "### Error handling", :3858-3860 "errors are represented using `[choice types](#choice-types)` like `Result` and `Optional`."; the linked section, :2167 "### Choice types", declares `choice IntResult {` (:2175) with `Success(value: i32),` and `Failure(error: String),` (:2176-2177); corroborating only, under "#### Generic choice types" (:3159): :3164-3166 `choice Result(T: type, Error: type) {` / `Success(value: T),` / `Failure(error: Error)`; p000157:691 `Success(T: value),` is provisional by its :229 "should be considered provisional" | **DRIFT** (R29, D-RG-5; amended 2026-10-28, review fold: A-m1, B-m4) | D-RG-5's | W-346, owner EH-C, trunk; reverses the user's F-006a (decision-log :716-718), veto-able |
| T2.2 | F-007: the `union` introducer keyword (lex/token_kind.def:176) | p000157:234-240 proposes "at least one and preferably both" of a `Storage` type and "A typed `union` facility, such as the one described in proposal" 0139 (:239); no `union` token or design page upstream (`git grep -w union -- toolchain/lex/token_kind.def` finds nothing); check T2.2: `git grep -c -w 'union'` over toolchain/lex/token_kind.def = 0 | NONE | upstream accepts a `union` proposal or adds the token | W-355 |
| T2.3 | F-007: the class-shaped union declaration (docs/design/unions.md; check: a `SemIR::Class` with `CustomLayoutType`) | silent at the tip, check T2.3: `git grep -c -E 'is_union\|UnionWithoutFields'` over toolchain = 0 beyond p000157:239 | NONE | as T2.2 | W-355 |
| T2.4 | F-007: reads as defined byte reinterpretation | silent at the tip, check T2.4: `git grep -c -i -E 'untagged union'` over docs/design, proposals = 1: no upstream page names union reads | NONE | an upstream union design that makes a read of an inactive field otherwise | W-355 |
| T2.5 | F-009: closed, same-library overload sets | static_open_extension.md:52-54 "function overloading is limited in Carbon to only signatures defined together in the same library." | ALIGNED | upstream allows open or cross-library overloading | W-355 |
| T2.6 | F-009: declaration-order first match | pattern_matching.md:696-697 "We do not yet have an approved design for overloaded functions, but it is anticipated that declaration order will be used in that case too."; p002875:475 "our current intent is to use the former approach" | ALIGNED | upstream designs best-match selection | W-355 |
| T2.7 | F-009: the marker `overload fn` (lex/token_kind.def:221) | p002875:481 "using placeholder syntax:" before :484 `overloaded fn Abs[T:! Unsigned](x: T) -> T { return x; }`; pattern_matching.md:696; upstream function.h:547 "TODO: Also include parameters to support overloaded functions." | NONE (R29, D-RG-6) | D-RG-6's | W-355 |

### §2.T3 SL-2 (trunk :3686-3697)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T3.1 | the `Span` mapping kind, `std::span<T>` to `Core.Slice(T')` on import (check/cpp/custom_type_mapping.cpp:118-136) | interoperability/README.md:255 "TODO: C++ view types such as `std::span` and other standard library types will" have corresponding types in Carbon; README.md:3707-3708 "Other view types, like `std::span`, are intended to map similarly." | ALIGNED | upstream maps `std::span` to another Carbon type, or not at all | W-355 |
| T3.2 | the export arm, `Core.Slice` to `std::span` (`RecognizedTypeInfo::Slice`, check/cpp/type_mapping.cpp:319) | README.md:3704-3708 (views "map transparently between C++ and the Carbon equivalents") | ALIGNED | as T3.1 | W-355 |
| T3.3 | the synthesized `CoreInterface::CppContiguousRange` and its witness (sem_ir/core_interface_kind.def:22, check/cpp/impl_lookup.cpp:600-610) | silent at the tip, check T3.3: `git grep -c -w 'CppContiguousRange'` over toolchain, core = 0: no `CppContiguousRange` upstream; its nearest is upstream's `CppRangeForIterate` kind (core_interface_kind.def:22 at the tip) for range-for | NONE | upstream synthesizes contiguous-range access another way (D-SL-9's, W-120) | W-120 |
| T3.4 | both prelude interop sections (core/prelude/types/cpp/slice.carbon; types/slice.carbon:100-106's blanket impl) | silent at the tip, check T3.4: `git grep -c -w 'Slice'` over core, toolchain/check, toolchain/sem_ir = 0: upstream has no `Slice` (`git grep -w Slice -- core toolchain/check toolchain/sem_ir` finds nothing) | NONE | as T3.3 | W-355 |
| T3.5 | D-SL-8: the name follows upstream's slice type when named | README.md:912 "**TODO:** Slices"; p004682:326 "is the closest fit with the current provisional syntax" for slices; the nearest passage, indexing.md:113 "And a type such as `std::span` could look like this:" before :116 `class Span(T: type) {` and :117 `impl as IndirectIndexWith(like i64) {`, is an example whose subject is `IndirectIndexWith` and names no slice type (D-RG-2 (ii); amended 2026-10-28, review fold: A-m2) | NONE | upstream names its slice type (rename, layout unchanged) | W-355 |
| T3.6 | D-SL-9: the witness synthesis | as T3.3; check T3.6: `git grep -c -w 'BuildCppContiguousRangeWitness'` over toolchain = 0 | NONE | D-SL-9's | W-120 |
| T3.7 | D-SL-21: the owning-to-view impl lives beside `Slice` (upstream's orphan rule applied) | upstream check/impl_validation.cpp `DiagnoseOrphanImpl` (the rule the fork applies; the block itself calls it "a fork convention, not a divergence") | ALIGNED | upstream changes its orphan rule | W-355 |
| T3.8 | D-SL-24: a C++ element whose copy constructor is deleted still maps | silent at the tip, check T3.8: `git grep -c -w 'BuildCopyWitness'` over toolchain/check = 2: upstream's `BuildCopyWitness` imports the deleted declaration as the witness | NONE | `BuildCopyWitness` declines deleted copy constructors | W-355 |

### §2.T4 OV-3 (trunk :4025-4033)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T4.1 | the `NamedDeclList` alternative of `MapInstIdToClangDeclOrType` and its `FindExternalVisibleDeclsByName` case (check/cpp/generate_ast.cpp:166-172, :275, :330) | silent at the tip, check T4.1: `git grep -c -w 'NamedDeclList'` over toolchain = 0: `grep -c NamedDeclList` of upstream check/cpp/generate_ast.cpp is 0 | NONE | upstream's external-source hand-off grows a list shape (keep whichever delivers every member) | W-355 |
| T4.2 | `overload_index` on a generated thunk (check/cpp/export.cpp:1388-1389) | silent at the tip, check T4.2: `git grep -c -w 'overload_index'` over toolchain = 0: function.h:547's TODO above; no keying | NONE | upstream's overloading keys its own thunks | W-355 |

The block's "OV-1's and OV-2's entries stand" is a cross-reference (T6, T7).

### §2.T5 SL-1 (trunk :4421-4432)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T5.1 | the builtins `pointer.offset`, `fail_stop`, `heap.allocate`, `heap.free` (sem_ir/builtin_function_kind.def:154, :157, :160-161) | values.md:1128-1129 "raw pointer arithmetic is expected to be provided at some point, but through specialized constructs given the specialized nature of these operations."; no such builtin upstream; check T5.1: `git grep -c -E 'pointer\.offset\|heap\.allocate\|heap\.free\|"fail_stop"'` over toolchain, core = 0 | NONE | upstream adds such builtins or constructs | W-355 |
| T5.2 | `Core.Slice(T)` (core/prelude/types/slice.carbon:24), D-SL-1 | README.md:912 "**TODO:** Slices"; p004682:326's "current provisional syntax" `[T]`; indexing.md:116 `class Span(T: type) {`, the example SL-1's block names as D-SL-3's target shape, is an example of `IndirectIndexWith` (D-RG-2 (ii); amended 2026-10-28, review fold: A-m2) | NONE | upstream names the slice type or its literal syntax | W-355 |
| T5.3 | `Core.Buf(T)` (core/prelude/types/buf.carbon:26) | README.md:885-886 "A heap-allocated dynamically sized array is written `buf(T)`, which is a shorthand for the library type `Core.Buf(T)`." | ALIGNED (the `buf(T)` shorthand is the gap) | upstream renames `Core.Buf` | W-110 (the shorthand) |
| T5.4 | the `Iterate` impl of `Slice(T)` (core/prelude/iterate.carbon:86-87) | upstream iterate.carbon:17 (the interface the impl implements) | ALIGNED | upstream changes `Iterate` (T0.3 is the cursor's drift) | W-321 for the cursor |
| T5.5 | D-SL-15: builtin operands' pointee completeness | silent at the tip, check T5.5: `git grep -c -F '"pointer.offset"'` over toolchain, core = 0: no general completeness rule for builtin operands upstream | NONE | upstream adds one (fold into it) | W-355 |
| T5.6 | D-SL-16: a class's declared `Destroy` impl wins destroy lookup over the synthesized witness (the yield in `CanDestroyClass`) | destroy.carbon:36-38 `fn SelfDestruct[T: Destroy](ref t: T) {` calling `t.(DestroyImpl.Op)();` and `t.(SubobjectDestroy.Op)();`; :23-24 `impl forall [T: SubobjectDestroy] T as DestroyImpl {` with `fn Op(ref self) = "no_op";`; check/control_flow.cpp:158 `BuildSelfDestructCall(context, destroy_id);` for every cleanup; custom_witness.cpp:1054 the custom witness serves `SubobjectDestroy` only; upstream's test declares `impl as Core.DestroyImpl {` (lower/testdata/var/destroy_control_flow.carbon:18) and its `_CSelfDestruct` calls the declared `Op` (:187-188); SL-1's own trigger "if upstream's destroy-op synthesis starts calling declared impls" (trunk :4430-4432) | **DRIFT** (D-RG-16; the block's break condition is met; amended 2026-10-28, review fold: A-M1, B-m9) | D-RG-16's | W-354, owner UA-3 with SL-1's records, at the advance that brings 05a7ecbd3 |
| T5.7 | D-SL-17: the literal-subscript rule (check/handle_index.cpp:107-114 comment and the rule) | indexing.md:105 `impl as IndexWith(like i64) {`; lex/token_kind.def:208 a `Like` keyword token only | DRIFT, blocked (on `like`) | W-326's | W-326 (DR-1, PR 63's and PR 65's ledgers; DR-1b's `LiteralSubscriptTargetType` replaces the rule) |
| T5.8 | D-SL-18: the prelude container impls are `final` | silent at the tip, check T5.8: `git grep -c -E 'class (Slice\|Buf)\b'` over core = 0: upstream has no slice or buffer impls | NONE | upstream's own container impls | W-355 |
| T5.9 | D-SL-19: `HasUserDestroyImpl` keyed by class | as T5.6: the trigger drops "D-SL-16's yield and D-SL-19's keying" together (trunk :4431), and at the tip a declared `DestroyImpl` impl is found by ordinary impl selection over the blanket `no_op` impl (destroy.carbon:23-24) | **DRIFT** (D-RG-16; amended 2026-10-28, review fold: A-M1, B-m9) | D-RG-16's | W-354 |
| T5.10 | D-SL-20: a `Buf` byte count that overflows fails-stop | silent at the tip, check T5.10: `git grep -c -F '"heap.allocate"'` over toolchain, core = 0 | NONE | an upstream allocation design | W-355 |
| T5.11 | D-SL-3's read-only element access, "if `IndirectIndexWith`/`ref` returns land" | upstream operators/index.carbon `IndirectIndexWith` with `Ref` (T0.2) | DRIFT | T0.2's | W-109, resolved on PR 65 |

### §2.T6 OV-2 (trunk :4718-4726)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T6.1 | the diagnostic kinds `OverloadSetFrozen`, `OverloadSetDeclaredHere` (diagnostics/kind.def:306-307) | silent at the tip, check T6.1: `git grep -c -E 'OverloadSetFrozen\|OverloadSetDeclaredHere'` over toolchain = 0: no overload sets upstream (T2.7) | NONE | upstream overloading's diagnostics | W-355 |
| T6.2 | the `replace_prev_inst` and `prev_decl_override` parameters, MOVED at UA-1 to `MergeOverloadMemberRedecl` (check/handle_function.cpp:177, :391) with `replace_prev_inst` dropped | silent at the tip, check T6.2: `git grep -c -E 'MergeOverloadMemberRedecl\|prev_decl_override'` over toolchain = 0: upstream's `TryMergeRedecl` has no member-targeted entry point | NONE | upstream's `TryMergeRedecl<Function>` grows one (retires the function) | W-355 |
| T6.3 | the `diagnose` parameter of `DeduceGenericCallArguments` (check/deduce.h:18-25) | silent at the tip, check T6.3: `git grep -c -F 'bool diagnose'` over toolchain/check/deduce.h = 0 (an internal parameter) | NONE | upstream adds its own non-diagnosing deduction | W-355 |
| T6.4 | the `GetApiClassDeclForQualifier` arm of `ResolveAsScope` (check/decl_name_stack.cpp:462, :523) | silent at the tip, check T6.4: `git grep -c -w 'GetApiClassDeclForQualifier'` over toolchain = 0: a fix to upstream's resolution of `fn C.F` in an impl file | NONE | upstream lands its own (keep whichever resolves it) | W-355 |
| T6.5 | the `OverloadSetValue` arm of `AddImportRefOrMerge` (check/import.cpp:359, :388) | silent at the tip, check T6.5: `git grep -c -w 'OverloadSetValue'` over toolchain = 0 (internal) | NONE | upstream's own import of sets | W-355 |

### §2.T7 OV-1 (trunk :4971-4978)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T7.1 | the `overload` keyword (lex/token_kind.def:221), F-009's marker | T2.7's quotes; check T7.1: `git grep -c -w 'overload'` over toolchain/lex/token_kind.def = 0 | NONE (R29, D-RG-6) | D-RG-6's | W-355 |
| T7.2 | the `:overload<N>` mangling marker (sem_ir/mangler.cpp:217-230) | silent at the tip, check T7.2: `git grep -c -F ':overload'` over toolchain/sem_ir/mangler.cpp = 0: function.h:547's TODO | NONE | upstream mangles overloads | W-355 |
| T7.3 | the `OverloadSetType`/`OverloadSetValue` inst kinds and the `OverloadSetId` store (sem_ir/inst_kind.def:129-130, ids.h:299) | silent at the tip, check T7.3: `git grep -c -w -E 'OverloadSetType\|OverloadSetValue\|OverloadSetId'` over toolchain = 0 (internal) | NONE | upstream's own representation | W-355 |
| T7.4 | the five diagnostic kinds `OverloadMarkerMismatch`, `OverloadMarkerPrevious`, `OverloadCandidateRejected`, `OverloadNoMatch`, `OverloadSetNotCallee` (diagnostics/kind.def:304-305, :315-317) | silent at the tip, check T7.4: `git grep -c -E 'Overload(Marker\|CandidateRejected\|NoMatch\|SetNotCallee)'` over toolchain = 0 | NONE | upstream's diagnostics | W-355 |
| T7.5 | the `overload_set_id` field of `Function::Print` (sem_ir/function.h:191, :279-280) | silent at the tip, check T7.5: `git grep -c -w 'overload_set_id'` over toolchain/sem_ir/function.h = 0 | NONE | upstream's field | W-355 |

### §2.T8 UN-2 (trunk :5179-5186)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T8.1 | `clang::TagTypeKind::Union` on export (check/cpp/export.cpp:81-82) | silent at the tip, check T8.1: `git grep -c -F 'TagTypeKind::Union'` over toolchain/check/cpp/export.cpp = 0: upstream exports no Carbon union (no `union` declaration, T2.2) | NONE | upstream exports unions | W-355 |
| T8.2 | the offset-zero layout arm (check/cpp/generate_ast.cpp:590's `layoutRecordType`, which supplies an offset of zero for every field, check/cpp/export.cpp:78-81) | silent at the tip, check T8.2: `git grep -c -w 'is_union'` over toolchain/check/cpp = 0 | NONE | as T8.1 | W-355 |

### §2.T9 UN-1 (trunk :5476-5484)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T9.1 | `Core.UnformedInit` as a `CoreInterface` kind and `CoreIdentifier` (sem_ir/core_interface_kind.def:42, check/core_identifier.def:95) | upstream core/prelude/default.carbon:17 `interface UnformedInit {` (the prelude interface the fork recognizes); upstream's kinds do not list it, and 05a7ecbd3 removed `Destroy` from them | NONE | upstream recognizes `UnformedInit` itself (keep upstream's) | W-355 |
| T9.2 | the `is_union` raw-dump field (sem_ir/class.h:92, :143) | silent at the tip, check T9.2: `git grep -c -w 'is_union'` over toolchain = 0: `git grep -c is_union` upstream toolchain/ is 0 | NONE | as T8.1 | W-355 |
| T9.3 | the four diagnostic kinds (diagnostics/kind.def:373-376) | silent at the tip, check T9.3: `git grep -c -E 'Union(FieldNotTriviallyCopyable\|InitNotSingleField\|InitUnknownField\|WithoutFields)'` over toolchain = 0 | NONE | as T8.1 | W-355 |

### §2.T10 EH-B (trunk :5596-5617)

Upstream's direction for the area: "Carbon may not provide seamless
interoperability support for C++ exceptions. For example, translating C++
exceptions to or from Carbon errors might require annotations or bridge code"
and "if Carbon code calls a C++ function without suitable annotations or
bridging, and that function exits with an exception, the program might
terminate" (upstream interoperability/philosophy_and_goals.md:405-410). The
fork's bridging fits it; its spellings are fork-local. UA-1's review counts a
fourth EH-B entry, "the `noexcept` fence" (trunk :6606-6607), which the block's
prose does not list; it is T10.4 (amended 2026-10-28, review fold: A-m3).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T10.1 | (i) `Cpp.Exception` as `Carbon::Exception { void* primary_; }` whose `.ptr()` is the `std::exception_ptr` (toolchain/install/include/carbon/expected.h:85) | silent at the tip, check T10.1: `git grep -c -E 'carbon/expected\.h\|primary_'` over toolchain/install, core = 0: no `Exception` in upstream core/ or interoperability pages | NONE | upstream designs an exception mapping | W-355 |
| T10.2 | (ii) `<carbon/expected.h>` mirroring the choice layout, with the foreign-exception contract (expected.h:30, :200-202) | silent at the tip, check T10.2: `git grep -c -i -E 'std::expected\|expected<'` over docs/design, proposals = 0: `git grep -c -i 'std::expected\|expected<'` of upstream docs/design and proposals is 0 | NONE | as T10.1 | W-355 |
| T10.3 | (iii) the catching thunk's names `<callee>__carbon_catching_thunk` and `.carbon_thunk_catch.<modes>` (check/cpp/thunk.cpp:598) | silent at the tip, check T10.3: `git grep -c -E 'carbon_catching_thunk\|carbon_thunk_catch'` over toolchain = 0 | NONE | as T10.1 | W-355 |
| T10.4 | the `noexcept` fence: a C++ exception escaping into Carbon reaches B0's still-`noexcept` thunk's terminate landing pad, after D-EH-5's boundary message (counted among EH-B's entries by UA-1's review, trunk :6606-6607, "the `noexcept` fence") | interoperability/philosophy_and_goals.md:408-410 "Furthermore, if Carbon code calls a C++ function without suitable annotations or bridging, and that function exits with an exception, the program might terminate." | ALIGNED (amended 2026-10-28, review fold: A-m3): the fence is the termination the page allows; upstream's toolchain has no fence yet; check T10.4: `git grep -c -w '__clang_call_terminate'` over toolchain = 0 | upstream designs propagation of C++ exceptions through Carbon frames, or bridging that does not terminate | W-355 |

### §2.T11 EH-A (trunk :5961-5971)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T11.1 | (i) `Core.Result(T, E)` as an independent prelude choice with a `final` `Try` impl (types/result.carbon:28, :40) | README.md:3860 "represented using `[choice types](#choice-types)` like `Result` and `Optional`."; :3164 `choice Result(T: type, Error: type) {` | ALIGNED (a choice; its alternatives are T2.1's drift) | upstream makes `Result` a class or a library type of another shape | W-346 for the alternatives |
| T11.2 | (i) the library name "prelude/types/result" (types/result.carbon:5) | silent at the tip, check T11.2: `git grep -c -F 'prelude/types/result'` over core, toolchain = 0: no `Result` library upstream | NONE | upstream adds one (take its name) | W-355 |
| T11.3 | (i) the first-alternative-is-success order, discriminant 0 (types/result.carbon:21-23, :28-31) | README.md:3165-3166 (`Success` first, then `Failure`) | ALIGNED | upstream orders them otherwise | W-355 |
| T11.4 | (ii) the `()` payload admission (check/type.cpp:337-360) | silent at the tip, check T11.4: `git grep -c -w 'IsInSliceChoicePayloadType'` over toolchain = 0: upstream's choice design has no payload allowlist | NONE | upstream lands a choice layout | W-355 |

### §2.T12 UA-1's watch list (trunk :6768-6782)

Each item is fork code inside an upstream function, marked "Fork (D-UA-n)":
D-RG-3 makes each NONE with its merge rule.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| T12.1 | the `if constexpr (IsClass)` union clauses in `TryMergeRedecl` (check/merge.cpp:740, :798) | silent at the tip, check T12.1: `git grep -c -w 'is_union'` over toolchain/check/merge.cpp = 0 (upstream has no union declaration) | NONE | upstream's own clause | W-355 |
| T12.2 | `TryMergeOverloadDecl` before `TryMergeRedecl` in `BuildFunctionDecl` (check/handle_function.cpp:465, :1145) | silent at the tip, check T12.2: `git grep -c -w 'TryMergeOverloadDecl'` over toolchain = 0 | NONE | upstream's member-targeted `TryMergeRedecl<Function>` (retires `MergeOverloadMemberRedecl`) | W-355 |
| T12.3 | the `is_choice`/`CustomLayoutType` clauses of `MakeSubobjectDestroyOpBody` (check/custom_witness.cpp:297-305, :872) | silent at the tip, check T12.3: `git grep -c -w 'is_choice'` over toolchain/check/custom_witness.cpp = 0; upstream rewrote the file in 05a7ecbd3 (UA-3's conflict, not a design) | NONE | upstream's own clause | W-355 |
| T12.4 | the fork-only `return_type_id` alternative in `FunctionDeclArgs` (check/function.h:54-55) | silent at the tip, check T12.4: `git grep -c -w 'return_type_id'` over toolchain/check/function.h = 0 | NONE | upstream's | W-355 |
| T12.5 | `BeginConditionalExprOperand`/`EndConditionalExprOperand` (check/control_flow.h:117-120) | silent at the tip, check T12.5: `git grep -c -E 'BeginConditionalExprOperand\|EndConditionalExprOperand'` over toolchain = 0: no such function upstream | NONE | upstream conditionalizes arm cleanups (retires W-122's guard) | W-355 |
| T12.6 | the null guard in `TryMapType`'s `FunctionType` arm (check/cpp/type_mapping.cpp:428) | silent at the tip, check T12.6: `git grep -c -F 'function.generic_id.has_value()'` over toolchain/check/cpp/type_mapping.cpp = 0 | NONE | upstream's own guard | W-355 |
| T12.7 | the null guard in `ExportFunctionToCppPointerConversion` (check/cpp/export.cpp:1646) | silent at the tip, check T12.7: `git grep -c -F "can't form a pointer to a template"` over toolchain/check/cpp/export.cpp = 1: upstream still asserts `CARBON_CHECK(!src_clang_decl->isTemplateDecl(),` (:1902-1903) where the fork's guard diagnoses a generic function (amended 2026-10-28, review fold: B-B1) | NONE | upstream's own guard | W-355 |

### §2.H1 SAFE-1 (PR 53, adaae4e35 :3920-3938)

Fork: PR 53's docs/design/safety/ pages and its F-013 entry (the D-SAFE
decisions at :3044-3600 of PR 53's log). PR 53 is documentation and records
only, so every realignment is text; D-RG-7 assigns the six DRIFTs (the five
departures and the zero-fill, H1.13) to SAFE-1 because each changes a decision
that three to five other pages state, and gives the dependent lines. PR 53
lands first, so these six gate the land sequence (section 5; amended 2026-10-28,
review fold: A-M5, B-M3).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H1.1 | `exclusive` (the `exclusive T*` pointer kind, D-SAFE-7) | p005914:182-184 "We expect to have more distinguished types of pointers in Carbon ... including both shared mutable pointers, and exclusive mutable pointers"; no spelling upstream; check H1.1: `git grep -c -E 'exclusive [A-Z][A-Za-z]*\*'` over docs/design, proposals = 0 | NONE (the kinds follow p005914's direction; the keyword is the fork's) | upstream spells its pointer kinds | W-355 |
| H1.2 | `unsafe permissive` (the mode marker) | safety/README.md:116-118 "Define the exact syntax ... The syntax for enabling the permissive mode must include the `unsafe` keyword" | ALIGNED | upstream defines the syntax otherwise | W-355 |
| H1.3 | `unsafe import` (D-SAFE-6) | safety/README.md:122 "**Future work**: Define how to mark `import`s of permissive libraries in" various contexts; check H1.3: `git grep -c -F 'unsafe import'` over docs/design, proposals = 0 | NONE | upstream defines the marker | W-355 |
| H1.4 | `unsafe class` | silent at the tip, check H1.4: `git grep -c -F 'unsafe class'` over docs/design, proposals = 0: `git grep -c 'unsafe class'` over upstream docs/design and proposals is 0 | NONE | upstream designs unsafe types | W-355 |
| H1.5 | `addr self: Self*` restored | p005434:1226 "### Restore `addr`" (under "## Future work", :1130): "To allow the `self` parameter to use one of the pointer semantics we create as part of the upcoming memory safety design, that can't be achieved with `ref`." (:1234-1236) | ALIGNED | upstream's memory-safety design restores `addr` otherwise, or not at all | W-355 |
| H1.6 | the prefix `unsafe` forms (`unsafe F(args)`, `unsafe *p`, `unsafe p->m`, `unsafe u.f`, `unsafe &u.f`, `unsafe s[i]`, `unsafe (...)`, `unsafe fn F(...) = "name"`) | safety/README.md:80-81 "We instead focus on the narrow and specific unsafe operations and constructs."; :98-99 "_Strict Carbon_ is the mode in which all unsafe code is marked with the `unsafe` keyword" | ALIGNED (the per-operation keyword; the forms' grammar is the fork's) | upstream designs another marking | W-355 |
| H1.7 | the library names `Core.Plain`, `Guarded`, `Box`, `Send`, `Sync`, `Freeze`, `Relocatable`, `Lifetime`, `DynCast`, `Move`, `Utf8`, `Atomic`, `Thread` | silent at the tip, check H1.7: `git grep -c -E 'Core\.(Plain\|Guarded\|Box\|Send\|Sync\|Freeze\|Relocatable\|Lifetime\|DynCast\|Move\|Utf8\|Atomic\|Thread)\b'` over docs/design, proposals, core = 1: no upstream type of these names (`git grep -w` over docs/design, core and the two safety proposals finds none, `Lifetime` and `Atomic` only in headings); `Box(T)` is p004682:322's placeholder ("`Box(T)` for a heap-allocated `T` value."); README.md:2150's move operator "is provisional"; functions.md:310's `Thread.Make` is a lambda example (D-RG-2 (ii)) | NONE | upstream names any of them (each renames) | W-355 |
| H1.8 | p005434:83 narrowed: `noalias`/`captures(none)` only for exclusive-kind refs (D-SAFE-8, PR 53 :3098-3125) | p005434:83 "The address of a `ref` binding is `nocapture` and `noalias`." | **DRIFT** | an accepted upstream memory-safety proposal that narrows :83 | W-347, owner SAFE-1 |
| H1.9 | p005434:663 narrowed: in Strict, `Plain`-field writes through other shared aliases during a non-`Plain` value binding stay erroneous and Debug-detected, not prevented (D-SAFE-17, PR 53 :3532-3568) | p005434:660-664 "Mutation of objects with a non-copy-value representation in an active value binding ("borrowed objects") is erroneous behavior." / "Our plan is to prevent mutation of borrowed objects in Carbon's strict safe dialect." | **DRIFT** | upstream relaxes :663 (its :665-669 conditions) | W-348, owner SAFE-1 |
| H1.10 | p005434:831-832 narrowed: a bound argument stays "not invalidated", not "immutable", for a returned loan's duration (D-SAFE-11(d), PR 53 :3297-3330) | p005434:831-832 "For full safety, we need each bound parameter to be immutable for the duration of the lifetime of the returned result."; :834 "We will reconsider this with the memory safety design." | **DRIFT** | upstream's memory-safety design reconsiders it otherwise | W-349, owner SAFE-1 |
| H1.11 | arithmetic.md's performance-build row withdrawn for Carbon code (D-SAFE-15, PR 53 :3483-3495; the block's ":155-158" is upstream's :156-158) | arithmetic.md:156-158 "In a performance build, the optimizer can assume that such conditions don't occur. As a consequence, if they do, the behavior of the program is not defined." | **DRIFT** | upstream withdraws or rewrites the row | W-350, owner SAFE-1 |
| H1.12 | safety/README.md:260-262's benchmarking disable withdrawn (D-SAFE-14, PR 53 :3427-3482) | safety/README.md:260-261 "Carbon will provide a way to disable the default hardening in release builds, but not in a supported way. Its use is expected to be strictly for benchmarking" purposes. | **DRIFT** | upstream withdraws the promise | W-351, owner SAFE-1 |
| H1.13 | zero-fill promoted to the Release baseline for every type, "there is no separate hardened mode" (D-SAFE-13 I5; PR 53's README.md:2151-2153 amendment); the block cites "docs/design/README.md:2147", PR 53's own copy (its :2147-2149) | README.md:2130-2132 "Types may define additional initialization for the `[hardened build mode](#build-modes)`. For example, this causes integers to be set to `0` when in unformed state in this mode."; safety/README.md:242 "Carbon will also have additional build modes to provide specific, narrow" capabilities, :248-250 "Release + specialized [hardening]: some users can afford significant run-time overhead in order to use additional hardening. Carbon will have several specialized build modes in this space."; :219 "The release build will include a baseline of hardening necessary to uphold the" memory-safety model; p005914:87-88 "allows, for example, zero-initialization rather than fail-stop behavior." | **DRIFT** (amended 2026-10-28, review fold: B-M3): upstream makes the extra initialization type-defined ("Types may define") and places it in a hardened mode that extends Release; the fork makes it language-mandated for every type in the Release baseline and removes the separate mode, the build-mode remapping H1.11 is; SAFE-1's own block lists it among its "departures from accepted text" | an accepted upstream memory-safety design that puts unformed-state zeroing in the Release baseline for every type | W-353, owner SAFE-1; cite corrected by H53 |
| H1.14 | the Permissive reading of p005914:206-208 (D-SAFE-18): Permissive assumes unannotated C++ pointer parameters do not escape, a diagnostic assumption only, while T8 withholds `noalias`/`captures(none)` at every such boundary | p005914:204-210 in full: "Lastly, Carbon's safety model will make fewer assumptions about what unsafe code is allowed to do than Rust. To avoid undefined behavior, the optimization of safe code will not rely on properties that are not established locally. For example, there won't be an assumption that a call to C++ code won't save a copy of pointers to passed-in objects. When there are restrictions on what unsafe code can do, we will endeavor to make violations into [erroneous behavior]" | ALIGNED, decided against the whole passage (amended 2026-10-28, review fold: B-M3): the passage limits what the safety model may assume about unsafe code so that no undefined behavior follows, and its example is an optimization assumption; the fork's Permissive assumption licenses no optimization (T8 withholds the attributes) and restricts nothing C++ may do, whose saving a copy stays defined, so it is a diagnostic heuristic outside the passage's rule; "departure" in SAFE-1's block is SAFE-1's disclosure, not upstream's text | an upstream memory-safety design that forbids diagnostics to assume a C++ callee does not save a copy, or that makes such a save erroneous behavior (:208-209's "endeavor") | W-355 |
| H1.15 | the `import Cpp` asymmetry (D-SAFE-6, A-13): `import Cpp` needs no marker | safety/README.md:122-124's future work, as H1.3; check H1.15: `git grep -c -F 'unsafe import'` over docs/design, proposals = 0 | NONE | as H1.3 | W-355 |

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
| H2.1 | the module and helper names `CMAKE_Carbon_*`, `carbon_add_library`, `carbon_add_executable`, `carbon_add_core_library`, `Carbon::core_io` (cmake/CMakeCarbonInformation.cmake, cmake/CarbonTargets.cmake) | silent at the tip, check H2.1: `git grep -c -E 'CMAKE_Carbon\|carbon_add_(library\|executable\|core_library)\|Carbon::core_io'` over the whole tree = 0 on names; p006333:371's `carbon_library` and `carbon_binary` are Bazel rules | NONE | upstream ships its own CMake support (rename) | W-355 |
| H2.2 | the block's claim that upstream's "thirteen `cmake` mentions are Bazel-internal" (measured on the fork's tree, its plan's audit row 1 counting two fork workflows) | at the tip `grep -rli cmake` outside .git, third_party, fork and testdata finds thirteen files, nine build or toolchain files and four texts: docs/project/milestones.md (:223, :230-231), proposals/p006333 (:368-370, :397-398, :418-421), docs/project/contribution_tools.md and proposals/p003797 | ALIGNED (CM-1 is milestones.md:230-231's deliverable; the claim is corrected by PR 52's commit) | upstream re-scopes the milestone | W-355 |
| H2.3 | README.md's one-line pointer and the `/examples/cmake/build-make/` line in .gitignore | silent at the tip, check H2.3: 0 upstream commits since the cut touch README.md, .gitignore (upstream-owned text the fork touches) | NONE | an upstream edit of those lines (merge rule) | W-355 |
| H2.4 | the `BUILD-SCRIPT` directive (fork harness) | silent at the tip, check H2.4: `git grep -c -F 'BUILD-SCRIPT'` over the whole tree = 0 | NONE | none | W-355 |
| H2.5 | D-CM-6's sibling wiring for the driver's single input per output | compile_subcommand.cpp:43-46 "we can only support a single input filename." with its TODO; p006333:99-100 "`carbon compile`: Take a single input to build, and produce a single output" `.o` | NONE (a build script around upstream's driver, no second driver mechanism) | the driver gains p006333's dependency mapping or multi-output (delete the wiring) | W-355 |
| H2.6 | D-CM-7's helper and D-CM-5's failing rule (the helper links the Core objects `carbon link` omits; shared libraries fail) | p006333:193-198 "This requires that `Core` files (not just the prelude) will have been compiled, so that their object files can be included in output. It's expected that this will be provided through on-demand runtimes. It should be possible to opt out of including these, for example so that the Bazel `carbon_binary` rule can use `carbon link` while also providing its own `Core` object files. However, it should be on-by-default." | ALIGNED with gaps (D-RG-4; amended 2026-10-28, review fold: A-m2): the helper supplies the Core objects itself, the opt-out route the proposal gives a build system, while `carbon link` lacks the on-by-default inclusion (W-003); shared libraries are W-132 | `carbon link` learns the Core objects (W-003; the helper then defers to it) or shared libraries (W-132) | W-003, W-132 |
| H2.7 | D-CM-9's NASM-style wiring through `OBJECT_DEPENDS` | silent at the tip, check H2.7: `git grep -c -i -w 'depfile'` over toolchain/driver = 0: upstream's driver writes no depfile | NONE | the driver writes a depfile (W-129) | W-129 |

### §2.H3 EV-1 (PR 54, cb3ef2e74 :3538-3549)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H3.1 | the three guide pages docs/guides/getting_started.md, tutorial.md and evaluator_faq.md, fork files in an upstream directory | silent at the tip, check H3.1: upstream's docs/guides/ lists 2 entries: `git ls-tree --name-only f27a977d8 docs/guides/` lists README.md and glossary.md only | NONE | upstream ships guides or a user FAQ there (D-EV-9's) | W-355 |
| H3.2 | they teach the fork's features (choice payloads, `match`, `Core.Result` and `?`, if-let) | as each feature's own entry (T1, T2.1, T11); check H3.2: `git grep -c -i -w 'tutorial'` over docs/guides = 0 | NONE | each feature's own | the tutorial's 18 `Ok`/`Err` lines are W-346's renames (D-RG-8) |
| H3.3 | upstream-owned text touched: README.md's two pointer lines, docs/project/faq.md's sentence, docs/guides/README.md's three items; README's shell commands untouched (D-EV-15) | silent at the tip, check H3.3: 0 upstream commits since the cut touch README.md, docs/project/faq.md, docs/guides/README.md (merge rule) | NONE | an upstream rewrite of README "Getting started" (re-place the pointers) | W-355 |

### §2.H4 ST-1 (PR 55, 21307851a :3503-3516)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H4.1 | the owning `Core.StringBuf` (D-ST-4) beside the view `Core.String`; the block cites "README.md:629's owning `String`", the fork's copy (trunk's README.md:629) | owning: README.md:622 "This is provisional, no design for string types has been through the" proposal process; :627 "`String` - a byte sequence treated as containing UTF-8 encoded text."; view: README.md:3706 "C++'s `std::string_view` maps directly to Carbon's `Core.Str`", interoperability/README.md:260-261 "Carbon's `str` (which is an alias for `Core.Str`) when importing C++ headers.", p006177:147-148 "The choice of `Str` over `String` for the non-owning view type is intentional.", sem_ir/type_info.h:381-382 "`str` / `Core.String`." and "TODO: Rename `Core.String` to `Core.Str`." | NONE for the owning name (R29, D-RG-19; amended 2026-10-28, review fold: A-M4); the view's `Core.String` is upstream's prelude spelling until the TODO lands, so D-ST-4's rejected early rename is not a divergence; the cite is corrected by H55 | type_info.h:382's TODO lands (the view becomes `Core.Str` and `StringBuf` takes README.md:627's owning name) | W-355 |
| H4.2 | `+` on strings decides issue 457 for the fork (D-ST-7) | arithmetic.md:186-187 "**TODO:** Decide whether strings are built-in types, and whether they support `+` for concatenation." | NONE | upstream decides issue 457 | W-355 |
| H4.3 | string.carbon:12, :14 and :37 edit upstream lines and :26-31 insert into upstream's class | silent at the tip, check H4.3: 0 upstream commits since the cut touch core/prelude/types/string.carbon (merge rule; re-run M-10) | NONE | an upstream edit of those lines | W-355 |
| H4.4 | check/cpp/export.cpp's null check :296-300 | silent at the tip, check H4.4: `git grep -c -F 'if (!decl_context)'` over toolchain/check/cpp/export.cpp = 3: a fix to upstream code; upstream's :402-404 still calls `ExportNameScopeToCpp(context, loc_id, class_info.parent_scope_id);` and then `ExportClassToCppInDeclContext(` with no check, where its other callers (:538, :914, :2077) check (amended 2026-10-28, review fold: B-B1) | NONE | upstream adds one (drop it) | W-355 |
| H4.5 | operators.carbon's two splits pinning other failures than upstream's | silent at the tip, check H4.5: 4 upstream commits since the cut touch toolchain/check/testdata/interop/cpp/operators/operators.carbon (golden merge rule) | NONE | an upstream refill | W-355 |
| H4.6 | the fork-owned fork_all_operands_conversion.carbon pinning upstream's TODO | silent at the tip, check H4.6: `git grep -c -F 'fork_all_operands_conversion'` over toolchain = 0 | NONE | upstream implements C++ operator lookup through operand conversions | W-355 |

### §2.H5 OP-1 (PR 56, 894139b34 :3529-3541; PR 57's copy a080c7886 :4460-4472)

W-344's block. The two copies are identical; PR 56's commit corrects both by
PR 57's merge of it (section 3.2). H5.4's realignment is OP-1's code commit on
PR 56's branch before PR 56 lands (W-352, D-RG-10; amended 2026-10-28, review
fold: A-M2).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H5.1 | optional.carbon:13 and :27 replace upstream lines; :205-275 fork-only | silent at the tip, check H5.1: 0 upstream commits since the cut touch core/prelude/types/optional.carbon (merge rule; re-run M-12) | NONE | an upstream edit of optional.carbon | W-355 |
| H5.2 | `final` on the comparison impls (D-OP-3) | silent at the tip, check H5.2: `git grep -c -E 'EqWith\|OrderedWith'` over core/prelude/types/optional.carbon = 0: upstream's optional.carbon has no `EqWith` or `OrderedWith` impl | NONE | upstream adds Optional comparisons | W-355 |
| H5.3 | F-015 itself, a fork design for a type upstream has not designed (D-OP-6) | core/prelude/types/optional.carbon:27-28 "We don't have an approved design for an `Optional` type yet, but it's used by the design for `Iterate`. The API here is a placeholder."; matchability is DR-0's (W-320) | NONE | an accepted upstream `Optional` design (re-derive F-015) | W-320 for matchability |
| H5.4 | the comparisons run `T.Copy` and `T.Destroy` once per value when both operands hold one (D-OP-4; `return self.Get() == other.Get();`, PR 56's optional.carbon:224) | comparison_operators.md:315-316 "these operations should have no observable side-effects." (`EqWith`) and :433-434 "the members of an `OrderedWith` implementation should have no observable side-effects." | **DRIFT**, not blocked (D-RG-10; amended 2026-10-28, review fold: A-M2): the in-place route is under OP-1's control (probe, section 4.8) | D-RG-10's | W-352, owner OP-1: a code commit on PR 56's branch before it lands, merged into PR 57's |
| H5.5 | `None()` is a function; the block says p002188:488-489 and pattern_matching.md:527-528 spell `Optional(T).None` as a value (the latter PR 56's own copy) | upstream core/prelude/types/optional.carbon:30 `fn None() -> Self {`; p002188:489-490 and pattern_matching.md:526-527 "Note that a pattern of the form `Optional(T).None` is an expression pattern and is compared using `==`." | ALIGNED with upstream's prelude, blocked (the pattern is W-320's) | W-320's and W-324's | W-320 (DR-1); cites corrected by PR 56's commit |
| H5.6 | F-015 says `Get()` on an empty `Optional(T*)` falsifies F-013's TY4 until W-173 | silent at the tip, check H5.6: `git grep -c -w 'TY4'` over docs/design, proposals = 0 (between two fork designs) | NONE | none; W-173 is discharged on PR 57 by OP-2 | W-173 |

### §2.H6 OP-2 (PR 57, a080c7886 :3779-3792)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H6.1 | lower/handle.cpp's value conversion in `AsCompatible` (D-OP2-1) | a fix to upstream code, which upstream still carries: upstream lower/handle.cpp:75-78 is `context.SetLocal(inst_id, context.GetValue(inst.source_id));` (:77) | NONE | upstream fixes it its own way (take upstream's if M-2's probes and W-171's arbiters pass) | W-355 |
| H6.2 | check/convert.cpp's swapped `ForType` calls (D-OP2-2) | upstream convert.cpp:1561-1569 still forms `value_rep` from `value_type_id` (:1564-1565) and `unformed_value_rep` from `target.type_id` (:1566-1567) | NONE | as H6.1 | W-355 |
| H6.3 | custom_witness.cpp's adapter arms, F-016 "an adapter is destroyed as its adapted type" (D-OP2-3) | upstream check/custom_witness.cpp:466-467 "TODO: Handle destruction of adapters generally by destroying the adapted type." (since 947c1eb52) | ALIGNED (the TODO's mechanism) | upstream implements the TODO (take upstream's arms) or an accepted adapter-destruction design | none; 05a7ecbd3 rewrote the file (UA-3's conflict) |
| H6.4 | optional.carbon :15, :18, :40-42 and :48 replace upstream lines and :276-307 are fork-only | silent at the tip, check H6.4: 0 upstream commits since the cut touch core/prelude/types/optional.carbon (merge rule M-11) | NONE | an upstream edit above :275 | W-355 |
| H6.5 | `Core.Optional(i32)` is not trivially destructible where `std::optional<int>` is (D-OP2-6) | silent at the tip, check H6.5: `git grep -c -i -E 'trivially destructible\|trivial destructor'` over core/prelude/types/optional.carbon = 0: no upstream text on Optional's triviality | NONE | an upstream Optional layout or triviality rule | W-196 |
| H6.6 | only `Core.Optional(T*)` is `UnformedInit`, "short of p000257's direction" (D-OP2-15) | p000257:274 "The intent is that most types have an unformed state"; upstream core/prelude/default.carbon:17 `interface UnformedInit {` | ALIGNED with a gap (D-RG-4) | upstream's Optional gains an unformed state | W-200 |
| H6.7 | the gap row DONE on a container run (D-OP2-16) | silent at the tip, check H6.7: `git grep -c -F 'gap-analysis'` over docs = 0 (process) | NONE | none | W-355 |

### §2.H7 DD-1 (PR 58, fcee90d9b :4114-4129)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H7.1 | every DD-1 edit to an upstream page is a dated blockquote or a new section, originals kept (D-DD-1) | silent at the tip, check H7.1: `git grep -c -F 'Fork amendment'` over docs = 0 (a documentation convention) | NONE | an upstream rewrite of the same placeholder (take upstream's) | W-355 |
| H7.2 | the fork pieces docs/design/interoperability/threads_and_atomics.md and four interop README sections | silent at the tip, check H7.2: upstream's docs/design/interoperability/ lists 4 entries: upstream's interoperability/ holds README.md, literals.md, macros.md and philosophy_and_goals.md | NONE | upstream adds a threads page | W-355 |
| H7.3 | the pages state measured toolchain behavior and follow the toolchain (D-DD-4) | silent at the tip, check H7.3: `git grep -c -F 'Fork amendment'` over docs/design/interoperability = 0 | NONE | none | W-355 |
| H7.4 | the guard parentheses: a `case` guard is `if (E)` | upstream's own parser requires them: parse/handle_match.cpp:166-178 (`auto open_paren = context.ConsumeIf(Lex::TokenKind::OpenParen);` at :169, "expected `(` after `if`" at :176); upstream's design pattern_matching.md:803 `_case_ ::= `case` _pattern_ [`if` _expression_]? `=>` _block_` differs, an upstream gap the page states | ALIGNED (with upstream's toolchain; the fork changed no line of it) | upstream's parser accepts an unparenthesized guard (take it at the advance; the page follows) | W-355 |
| H7.5 | the constant-value alias: `alias` of a constant value is accepted | p003938:82 "`alias` is not fully designed"; the behavior is upstream's toolchain's | NONE | an accepted `alias` design | W-355 |
| H7.6 | the documented toolchain gaps that carry items (W-183, W-185's grammar, W-188, W-189, W-014, W-127, W-192, W-193, W-194) | each item's accepted text, as its own entry records | ALIGNED with gaps (D-RG-4) | each item's | the nine items |

### §2.H8 VA-1 (PR 59, b0822a744 :3609-3630; PR 66's copy 43c8ab476)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H8.1 | (i) `each` is a keyword (D-VA-10) | variadics.md:47-48 each-names "are marked with the `each` keyword at the point of declaration and the point of use."; :92 "An _each-name_ consists of the keyword `each` followed by the name of a pack," | ALIGNED (upstream's lexer has no `each` token yet) | upstream makes `each` contextual (follow, refill the lex golden) | W-355 |
| H8.2 | (ii) the parse node kinds `PackExpansionExpr`, `PackExpansionPattern`, `EachNameExpr`, `EachBindingName` and three parse states | upstream parse/node_kind.def:292-293 `PackExpansionStart`, `PackExpansionStatement`; check/handle_pack_expansion.cpp:12 `return context.TODO(node_id, "HandlePackExpansionStart");`; check H8.2: `git grep -c -E 'PackExpansionExpr\|PackExpansionPattern\|EachNameExpr\|EachBindingName'` over toolchain/parse = 0 | NONE (internal; the item's `(... x)` tuple is H8.8; amended 2026-10-28, review fold: A-m2) | upstream adds its own (move the handlers onto them) | W-355 |
| H8.3 | (iii) a pack's bare name is a semantics TODO (D-VA-11) | silent at the tip, check H8.3: `git grep -c -i -F 'omit each-names'` over proposals/p002240-variadics.md = 2: p002240's "Omit each-names" is an alternative not adopted | NONE, blocked (watch) | upstream gives it a meaning or makes it an error | W-230 |
| H8.4 | (iv) eight SemIR instructions and `<pack arity>` | silent at the tip, check H8.4: `git grep -c -w -E 'PackElement\|PackExpansionExpr\|PackExpansionPattern\|PackExpansionStatement\|PackIndex\|PackLiteral\|PackType\|PackValue'` over toolchain/sem_ir/inst_kind.def = 0: upstream sem_ir/inst_kind.def has no pack instruction | NONE | upstream models packs (take upstream's, refill) | W-355 |
| H8.5 | (v) upstream's check golden variadics/pack_expansion.carbon carries VA-1's output | silent at the tip, check H8.5: 2 upstream commits since the cut touch toolchain/check/testdata/variadics/pack_expansion.carbon (merge rule) | NONE | the advance (take upstream's file and refill) | W-355 |
| H8.6 | (vi) the two cherry-picks are upstream's commits | upstream's own (2ec4bab59 and a045da8e6) | ALIGNED | upstream reverts or reshapes 2ec4bab59 | W-355 |
| H8.7 | (vii) the next advance's four added conflicts take the fork's side | silent at the tip, check H8.7: 1 upstream commits since the cut touch toolchain/check/handle_pack_expansion.cpp (merge rule, plan M-16) | NONE | the advance | W-355 |
| H8.8 | (ii) `(... x)` as a tuple: parentheses around a `...` form a tuple, not a grouping | variadics.md:137-139 "As a corollary, if the nearest enclosing delimiters around a `...` are parentheses, they will be interpreted as forming a tuple rather than as grouping." | ALIGNED (amended 2026-10-28, review fold: A-m2) | upstream changes the rule | W-355 |

### §2.H9 SC-1 (PR 60, 40a76ab81 :4187-4202)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H9.1 | `template constraint` parsed as the `template` modifier on `constraint` (D-SC-1), retiring upstream's two TODOs | generics/details.md:1072-1073 "use the `template` keyword before `constraint`."; :5494 "the keyword introducer `interface`, `constraint`, or `template constraint`,"; upstream check/handle_named_constraint.cpp:44-45 "TODO: PopSoloNodeId(`template`) ... Or maybe it should be a modifier, like `abstract class`?" and :113 "TODO: Support for `template constraint`." | ALIGNED (the source spelling is the design's) | upstream lands a two-token introducer (respell the parse, D-SC-1's) | W-355 |
| H9.2 | `NamedConstraint::is_template` and its members block: requirements checked by name, no witness (D-SC-4) | details.md:1073-1077 "Method, associated constant, and associated function requirements may only be declared inside a `template constraint`. ... a template constraint can depend on them." | ALIGNED | upstream lands member requirements with a witness table (D-SC-4's) | W-355 |
| H9.3 | `LookupImplWitness`'s structural check before the empty-constraint return and `IdentifiedFacetType`'s structural vector | silent at the tip, check H9.3: `git grep -c -w 'is_template'` over toolchain/sem_ir/named_constraint.h = 0: upstream returns `Empty` for a facet type with no interfaces | NONE (internal) | upstream's own representation | W-355 |
| H9.4 | `GetCallee`'s single-candidate look-through for a `cpp_overload_set_value` | silent at the tip, check H9.4: `git grep -c -w 'CalleeCppOverloadSet'` over toolchain/check = 3 (internal) | NONE | upstream's | W-355 |
| H9.5 | D-SC-6: a checked-generic argument passed to a template parameter whose constraint has structural requirements is rejected at the checked function's definition ("the conservative answer to leads issue 2153"); PR 60's docs/design/generics/template_constraints.md:456-468 says it "resolves upstream's open question" (:460-461) | generics/overview.md:375-379 "_We have decided to support passing a symbolic constant to a template parameter, see [leads issue #2153...], but incorporating it into the design is future work._"; appendix-witness.md:151-154 "Carbon's planned approach to support calling a templated function from a checked-generic function, decided in issue #2153, relies on monomorphization."; upstream check/call.cpp:387-388 wraps "symbolic template args in a `TemplateInst` so that all symbolic arguments are treated as templates." | **DRIFT** (W-139's break condition "upstream resolves issue 2153 toward checked generics may call templates" was already met when W-139 was filed: upstream's text predates the cut, D-RG-9; amended 2026-10-28, review fold: A-M3, B-M4) | an upstream design that makes such calls a definition-time error | W-139 (PR 60's ledger), owner SC-1, the page's paragraph in its scope; W-140 follows it; H60 adds the page's dated note |
| H9.6 | the `new_specific_id` parameter threaded through `CheckFunctionTypeMatches` | silent at the tip, check H9.6: `git grep -c -w 'new_specific_id'` over toolchain/check = 0 (internal) | NONE | upstream's `CheckFunctionTypeMatches` gains a specific for the new side (merge into it) | W-355 |

### §2.H10 TP-1 (PR 61, 5661a35c8 :4185-4208; PR 64's copy 4a3220c11)

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H10.1 | (i) `PointerDereferenceAction`, `AddrOfAction`, `TupleIndexAction`, `IndexAction` and `TemplateMemberLookupAmbiguous` | silent at the tip, check H10.1: `git grep -c -E 'PointerDereferenceAction\|AddrOfAction\|TupleIndexAction\|[^a-zA-Z]IndexAction\|TemplateMemberLookupAmbiguous'` over toolchain = 0: none of the five upstream (its action kinds, sem_ir/inst_kind.def:21-126, are others) | NONE | upstream defers these forms itself (take upstream's, autoupdate) | W-355 |
| H10.2 | (ii) D-TP-3's copied storage access chain in `InitializeAction::Target::storage_id` | upstream sem_ir/typed_insts.h:1312 `MetaInstId storage_access_block_id;` (4a8993af2, internal) | NONE (D-RG-3) | the advance that brings 4a8993af2 | W-258 |
| H10.3 | (iii) `array` as the builtin, D-TP-24's array arm | README.md:872-874 "The type of a direct-storage immutably sized array holding `N` values of type `T` is written `array(T, N)`, which is a shorthand for the library type `Core.Array(T, N)`. This type is defined in the prelude."; core/prelude/types/array.carbon:10 `private fn MakeArray(T: type, N: IntLiteral) -> type = "array.make_type";` and :13-14 `class Array(T: type, N: IntLiteral) {` / `adapt MakeArray(T, N);` (947c1eb52, after the cut) | ALIGNED at the tip (amended 2026-10-28, review fold: A-M1): the source spelling `array(T, N)` is upstream's shorthand, and the arm handles the builtin array type that upstream's `Core.Array` adapts; the arm itself is internal (D-RG-3), merged at UA-3, which re-measures W-253 | upstream drops the `array(T, N)` shorthand or the adapted builtin | W-253's evidence |
| H10.4 | (iv) D-TP-7 and D-TP-25 change upstream's `SpliceInst` lowering | silent at the tip, check H10.4: 1 upstream commits since the cut touch toolchain/lower/handle.cpp: fixes to upstream code | NONE | upstream's return-form commits 230227264 and 9fd28f730 (the advance's specific-aware resolution) | W-355 |
| H10.5 | (v) D-TP-12 defers impl lookup only for queries that name a template binding | p002200:205 "Impl lookup is delayed until all templated types, interfaces, and parameters" are known | ALIGNED with a gap (D-RG-4) | upstream draws the line differently (follow, refill default_init.carbon) | W-268 |
| H10.6 | (vi) D-TP-13's constraint lookup on instantiation only | p002200:200-202 "Member lookup into a templated type looks in the actual type value provided by the caller in addition to in any constraints on that type" | ALIGNED with gaps (D-RG-4) | upstream implements proposal 2200's name lookup (take it) | W-260, W-261, W-262, W-266 |
| H10.7 | (vii) D-TP-14's `semantics TODO` at the `import` in front of upstream's cross-file lowering TODO, cited as "lower/handle.cpp:524", PR 61's own copy (its :518-524) | upstream toolchain/lower/handle.cpp:384-390 "TODO: We don't yet have support for cross-file templates at all." ... `CARBON_FATAL("Cross-file template lowering not implemented yet");` | NONE (cite corrected by PR 61's commit) | upstream imports actions and splices (remove the TODO with W-250) | W-250 |
| H10.8 | (viii) D-TP-11 forms a generic class type with template-dependent arguments eagerly | silent at the tip, check H10.8: 0 upstream commits since the cut touch toolchain/check/testdata/generic/template/deduce_class_args.carbon (toolchain behavior) | NONE | upstream defers it (follow, refill deduce_class_args.carbon) | W-355 |

### §2.H11 CT-1 (PR 64, 4a3220c11 :8341-8342 and plan §0.10 :935-1004)

The block reads "the nine of plan §0.10"; §0.10 lists ten bullets at
4a3220c11 (:935, :941, :945, :951, :958, :960, :963, :967, :985, :996), the
tenth (`SpecificConstant`'s category) added at plan rev 4 (RR2-M1) before the
discharge commit 118fc1bc8 wrote the block. PR 64's commit corrects the count.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H11.1 | `NamesTemplateBinding` also for a `TemplateInst` and through `MetaInstId` operands (D-CT-5; TP-1's D-TP-12) | p002200:205 (as H10.5) | ALIGNED | upstream lands its own deferral of template-dependent impl lookup (keep upstream's) | W-355 |
| H11.2 | `DeferCppCallOnSymbolicArgs` and `ActionIsPerformable`'s C++-callee clause (D-CT-3, D-CT-6, F-021) | overview.md:375-379 and appendix-witness.md:151-154 (as H9.5); upstream call.cpp:387-388's `TemplateInst` wrapping; upstream's toolchain still diagnoses E-ARG | ALIGNED (it implements the decided direction) | upstream lands deferral of C++ calls on symbolic arguments (keep upstream's, re-decide F-021) | W-355 |
| H11.3 | the `MetaInstId`/`MetaInstBlockId` cases of `SubstInst` (D-CT-7) | silent at the tip, check H11.3: `git grep -c -F 'MetaInstId'` over toolchain/check/subst.cpp = 0: a fix to upstream code (24766e213 and eb66bebc3 edit `PopOperand` beside them) | NONE | the merge rule | W-355 |
| H11.4 | `PerformAction(InitializeAction)`'s return-slot condition (D-CT-8) | silent at the tip, check H11.4: 2 upstream commits since the cut touch toolchain/check/action.cpp (TP-1's code; 4a8993af2's storage block, H10.2) | NONE | the merge rule | W-355 |
| H11.5 | the `TSK_ImplicitInstantiation` marking in `BuildTemplateId` (D-CT-9) | silent at the tip, check H11.5: `git grep -c -w 'TSK_ImplicitInstantiation'` over toolchain/check/cpp = 0: `git grep -c TSK_ImplicitInstantiation` upstream check/cpp is 0 | NONE | upstream's fix for L-UNDEF | W-355 |
| H11.6 | the completion and the `CARBON_CHECK` in `IsMoveEquivalentToCopy` (D-CT-10) | upstream check/cpp/overload_resolution.cpp:156 `static auto IsMoveEquivalentToCopy(clang::QualType type) {` without them | NONE (a fix) | upstream's fix | W-355 |
| H11.7 | `DiscardGenericDeclIntoEnclosingGeneric` and its call in handle_alias.cpp (D-CT-17) | silent at the tip, check H11.7: `git grep -c -w 'DiscardGenericDeclIntoEnclosingGeneric'` over toolchain = 0: no such function upstream; 57bf903ef (2026-10-27) reworks generic.cpp's resolution loop beside it | NONE | upstream attaches an alias's value itself (keep upstream's) | W-355 |
| H11.8 | the alias check of D-CT-17 as amended: the concrete rule "alias refers to a runtime value" applied per specific | p002200:208-209 "type checking of any expression dependent on a templated parameter may not be completed until its value is known" | ALIGNED | upstream lands its own per-specific evaluation of an alias (keep upstream's) | W-355 |
| H11.9 | `SpecificConstant`'s expression category computed in its own specific (D-CT-17's use rule, rev 4) | upstream sem_ir/typed_insts.h:2009 `struct SpecificConstant {` with :2013 `.expr_category = ComputedExprCategory::SameAsFirstOperand,`, which expr_info.cpp:219-220 resolves by following the first operand without its specific (rev 1 cited expr_info.cpp:319, the constant-resolution case; amended 2026-10-28, review fold: B-B1); check H11.9: `git grep -c -F 'ComputedExprCategory::SameAsFirstOperand'` over toolchain/sem_ir/typed_insts.h = 8 | NONE (a fix) | upstream changes the category's computation | W-355 |
| H11.10 | the source edits of two upstream goldens and the refills of three | silent at the tip, check H11.10: 9 upstream commits since the cut touch toolchain/check/testdata/interop/cpp/template/var_template.carbon, toolchain/lower/testdata/interop/cpp/globals.carbon, toolchain/check/testdata/interop/cpp/template/generic_call.carbon, toolchain/check/testdata/interop/cpp/template/non_type_param.carbon, toolchain/check/testdata/interop/cpp/range_for.carbon (merge rule) | NONE | an upstream change to those files (take upstream's, refill) | W-355 |

### §2.H12 UA-2's register re-read (PR 51, f96fe8a7a :6226-6232)

Added at rev 2 (amended 2026-10-28, review fold: A-M1): rev 1's scan matched
three paragraph openers and missed this paragraph of UA-2's record, whose
listing re-reads T1 to T12 (a cross-reference) and whose one new statement is
H12.1.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item, note |
| --- | --- | --- | --- | --- | --- |
| H12.1 | UA-2's record that "The SL-1 register trigger ... is met for FIELDS" while "D-SL-16's yield still makes a `Buf` LOCAL free, so the yield stays" (measured at UA-2's reconciliation, before 05a7ecbd3) | as T5.6: at the tip every cleanup, locals included, calls `SelfDestruct` (control_flow.cpp:158), which calls the declared `DestroyImpl.Op` (destroy.carbon:37) | **DRIFT** (D-RG-16): the trigger is met for locals too; PR 51 is not amended for it (D-RG-8: the yield is trunk's code) | D-RG-16's | W-354 |

### §2.C1 DR-0's register as extended on PR 63 and PR 65 (89aabd125 :241-255; fee0ef31c :241-256)

Owned by DR-1; RG-1 re-reads and does not amend (DR-1's routed records commit
carries their notes, the 2026-10-26 weekly's routing).

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item |
| --- | --- | --- | --- | --- | --- |
| C1.1 | (iv) `Core.Optional` not matchable: upstream's pages conflict on `Match.Continuation` | sum_types.md:113 `let template Continuation: type;` against README.md:1076-1078 "`[Associated constants](#associated-constants)` are always checked generic bindings. This is not a contextual default: no other phase is possible for an associated constant, and so no phase keyword is allowed there." and generics/terminology.md:100-101 "`[Associated constants](#interface-parameters-and-associated-constants)` are always checked generic bindings."; unchanged since ac31fd198 (amended 2026-10-28, review fold: B-m7) | DRIFT, blocked (on upstream's own conflict) | W-324's | W-320, W-324 (DR-1) |
| C1.2 | (v) D-SL-17's literal-subscript rule as DR-1b's `LiteralSubscriptTargetType` | indexing.md:105 `impl as IndexWith(like i64) {`; lex/token_kind.def:208 `Like` only | DRIFT, blocked (on `like`) | W-326's | W-326 (DR-1) |

### §2.C2 VA-2's register entries (PR 66, 43c8ab476 :3672-3676; fork/variadics/va2-plan.md §1.12)

Owned by VA-2; each carries its item and its weekly next action
(ORCHESTRATION Next actions items 8 and 9). RG-1 records the verdict VA-2's
§1.12 states and does not amend.

| # | Entry | Upstream at f27a977d8 | Verdict | Break condition | Item |
| --- | --- | --- | --- | --- | --- |
| C2.1 | (i) `...expand`'s typechecking stops at the text | variadics.md:493 "> **TODO:** Discuss typechecking `...expand`." and :750 "> **TODO:** address `...expand`, `...and` and `...or`." (unchanged since 57ba07a97; amended 2026-10-28, review fold: B-m7); check C2.1: `git grep -c -F 'Discuss typechecking'` over docs/design/variadics.md = 1 | NONE, blocked (watch) | upstream settles `expand` | W-217 |
| C2.2 | (ii) tuple comparisons convert neither operand | comparison_operators.md:504-505 "Comparisons between tuples permit implicit conversions for either operand, but not both.", a narrowing, not a second spelling (VA-2's; amended 2026-10-28, review fold: B-m7) | ALIGNED with a gap (D-RG-4) | scheduled with W-222 | W-334 |
| C2.3 | (iii) a pack's bare name has no meaning yet | p002240:555 "### Omit each-names", :557 "Rather than having packs be distinguished by their names, we could instead" distinguish them by their types, an alternative considered and not adopted (variadics.md:982 lists it so; amended 2026-10-28, review fold: B-m7); check C2.3: `git grep -c -i -F 'omit each-names'` over docs/design/variadics.md = 1 | NONE, blocked (watch) | as H8.3 | W-230 |
| C2.4 | (iv) the fixed-arity `let` reading of :219-221 with :532-546 | variadics.md:219-221 "The binding pattern's type expression may contain an each-name (such as `each ElementType` in the `Zip` example), but if so, it must be a deduced parameter of the enclosing pattern." with :532-546 (VA-2's reading of the design's own text; amended 2026-10-28, review fold: B-m7) | ALIGNED, blocked (watch) | upstream narrows :219-221 | W-214 |
| C2.5 | (v) a segment's rank against a `?` | generics/details.md:4921-4922 "We pick the type structure with a non-`?` at the first difference as most specific.", naming only `?` and non-`?` entries (amended 2026-10-28, review fold: B-m7); check C2.5: `git grep -c -F 'segment'` over docs/design/generics/details.md = 0 | NONE, blocked (watch) | upstream ranks segments | W-338 |
| C2.6 | (vi) comparisons of orderings that are not total | comparison_operators.md:457-458 "There is no expectation that an `Ordered` implementation be a total order, a weak order, or a partial order" and :462-464 "**TODO:** The standard library should provide a way to specify that an ordering is a weak, partial, or total ordering, and a way to request such an ordering in a checked generic." (amended 2026-10-28, review fold: B-m7); check C2.6: `git grep -c -i -E 'total order\|weak order\|partial order'` over docs/design/expressions/comparison_operators.md = 3 | NONE, blocked (watch) | upstream decides | W-339 |

## §3 Commits, in order

Every commit is a NEW commit (never an amend, a rebase or a force-push), made
with `--author='jmann345 <jerrymannstan@gmail.com>'` and
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`, staged by
explicit path only (never `git add -A`, R20), after prek to a fixpoint with the
R31 counts recorded before and after (section 4.1). Each message ends, after a
blank line, with the two session attribution trailers the implementing harness
specifies (its Co-Authored-By line, then `Claude-Session:
https://claude.ai/code/session_018tx3BJWJhp2yYjHPRA5fNR`); the messages below
show the body only. Dates are the UTC date of the commit; this plan writes
2026-10-27, and an implementer committing on a later date substitutes it
everywhere a record says "classified 2026-10-27" for that commit's records. The
order and the review gate are D-RG-13's (amended 2026-10-28, review fold: B-M5):
nothing is pushed before the two implementation reviews and their fixes. The
held commits are made in a scratch worktree under /dev/shm/rg1-impl/ checked out
detached at the held head (`git worktree add --detach /dev/shm/rg1-impl/<pr>
origin/<branch>`), never in the held branch's own worktree; each staged commit
is kept reachable by `git update-ref refs/rg1-stage/<pr> HEAD` before its
worktree is removed, and after the reviews it is pushed with `git push origin
refs/rg1-stage/<pr>:refs/heads/<branch>` (a fast-forward of new commits); the
stage refs are deleted after the pushes.

### §3.1 On claude/carbon-fork-0-1-rg1 (base trunk 0b999d449)

**P (the plan).** Rev 1: `RG-1 plan (rev 1): the V-3a register classified at
upstream f27a977d8`. Rev 2 (this): `RG-1 plan (rev 2): reviews A and B folded,
25 findings`. Later revisions are new commits `RG-1 plan (rev N): <fold
summary>` with the same path, fork/register/rg1-plan.md.

**R1, the records.** Made after sign-off, committed in /home/user/carbon-rg1 and
not pushed until step 6 of D-RG-13. Message:

<!-- google-doc-style-ignore -->

```text
RG-1 records: the V-3a register classified at upstream f27a977d8; W-346 to W-356 filed, W-342 discharged (R32 (a), (b), (d))

Every entry of the 26 V-3a register blocks and V-3's design-fork entries is
classified against upstream f27a977d8 and re-checked at <tip>
(fork/register/rg1-plan.md section 2): 155 entries, 19 DRIFT, 34 ALIGNED, 102
NONE, 10 of them blocked; 230 quotes and 89 silence checks re-read at both shas.
F-006a's Ok/Err is a drift against README.md:3856-3860 and the choice-types
section it links (W-346, owner EH-C, reversing the user's F-006a under the
2026-10-21 directive, veto-able); F-009's overload fn is not one (p002875:481
calls its spelling placeholder syntax). SAFE-1's six departures from accepted
text are W-347 to W-351 and W-353, OP-1's comparisons' side effects W-352 (a
code commit on PR 56 before it lands), D-SL-16's yield and D-SL-19's keying
W-354 (at UA-3, against 05a7ecbd3's SelfDestruct); SC-1's W-139 is a drift whose
break condition was already met when it was filed. W-355 is the register's watch
item for every NONE and ALIGNED entry; W-356 a crash RG-1's probe found. The
decision-log entry is placed after DR-0; trunk's eleven blocks and V-3's group
gain their dated notes; W-342 is discharged and W-343 and W-344 narrowed;
ORCHESTRATION gains the rg1 row, a dated paragraph and the drifts in Next
actions. Records only.
```

<!-- google-doc-style-resume -->

`<tip>` is the nine-character sha R1's fetch gives (e6fddcf97 at rev 2); if it
differs from e6fddcf97, both scripts of section 4.2 are re-run at it first.
Paths: fork/decision-log.md (the entry of Appendix A.1 inserted after trunk
0b999d449's :276, the blank line after DR-0's "_Ids._" paragraph, which ends at
:275, and before "### B0 SF-1..5" at :277; the twelve notes of Appendix A.3,
inserted bottom up), fork/inventory/work-items.json (A.5's eleven items appended
after W-344 in id order, A.6's edits of W-342, W-343 and W-344, and A.6's
sentence appended to the top-level `source`), fork/ORCHESTRATION.md (A.8)
(amended 2026-10-28, review fold: B-m2). fork/gap-analysis.md is not changed: no
row's status changes, and the one row text that names the drifting spelling,
row 68's example `case .Ok(v: i32)` (fork/gap-analysis.md:68 at 0b999d449), is
rewritten by W-346's realignment when it lands, not by RG-1.

**R2, the stamp.** Made after the pushes of step 6. Message:

<!-- google-doc-style-ignore -->

```text
RG-1 records: the held-branch amendments recorded; W-344 discharged, W-343 narrowed to the land-time notes (R32 (b), (e))

Records the held branches' new heads: PR 53 <sha53>, PR 52 <sha52>, PR 60
<sha60>, PR 55 <sha55>, PR 56 <sha56> and PR 57's merge <sha57>, PR 61
<sha61>, PR 64's count correction <sha64> and its merge <sha64m>, and any fix
commits of D-RG-13 step 4 on those branches. W-344 is discharged; W-343 is
narrowed to the land-time notes of PR 51, PR 54, PR 57 (OP-2), PR 58 and
PR 59, scheduled in ORCHESTRATION; the RG-1 entry gains its held-commit
paragraph and ORCHESTRATION its rows and descriptions-refreshed note. Records
only.
```

<!-- google-doc-style-resume -->

Paths: fork/decision-log.md (A.2), fork/inventory/work-items.json (A.7),
fork/ORCHESTRATION.md (A.9), fork/register/rg1-plan.md (a "Landed notes"
section with the shas). The `<sha..>` placeholders are the only text the
implementer fills, each with the nine-character abbreviation of the commit made.
A focused review of R2 follows it (D-RG-13 step 7).

### §3.2 On the held branches, in the merge order

One RG-1 records commit per branch, its full text in Appendix A.4 and A.10; PR
57 and PR 64 also merge their base PR's new head, as a080c7886 merged W-323's
commit. Staged in this order (D-RG-13 step 2), merged at step 5, pushed at step
6 in the same order:

| Order | Branch (PR) | Head before | Commit | Paths |
| --- | --- | --- | --- | --- |
| 1 | claude/carbon-fork-0-1-safe (PR 53) | adaae4e35 | H53: `SAFE-1 records: six departures from accepted text filed as drifts W-347 to W-351 and W-353, the README and arithmetic cites corrected (RG-1; R32 (a), (b), (e))` | fork/decision-log.md |
| 2 | claude/carbon-fork-0-1-cmake (PR 52) | ea573f672 | H52: `CM-1 records: the CMake measurement corrected against upstream's tip and milestone (RG-1; R32 (a), (e))` | fork/decision-log.md |
| 3 | claude/carbon-fork-0-1-sc (PR 60) | 40a76ab81 | H60: `SC-1 records: D-SC-6 is a drift under R32 (d), W-139's break condition already met at its filing; the page's issue 2153 sentence noted (RG-1; R32 (b), (e))` | fork/decision-log.md, fork/inventory/work-items.json, docs/design/generics/template_constraints.md |
| 4 | claude/carbon-fork-0-1-st (PR 55) | 21307851a | H55: `ST-1 records: the README cite corrected to upstream's line, the view's Core.Str direction quoted (RG-1; R32 (a), (e))` | fork/decision-log.md |
| 5 | claude/carbon-fork-0-1-op (PR 56) | 894139b34 | H56: `OP-1 records: the register's cites corrected to upstream's, the comparisons' side effects filed as W-352, realigned here before this PR lands (RG-1; R32 (a), (b), (e); W-344)` | fork/decision-log.md |
| 6 | claude/carbon-fork-0-1-op2 (PR 57) | a080c7886 | H57: merge of H56's final head, `OP-2: merge OP-1's RG-1 records commit (R32 (e))` | the merge's paths |
| 7 | claude/carbon-fork-0-1-tp (PR 61) | 5661a35c8 | H61: `TP-1 records: the cross-file lowering TODO cited at upstream's line, (iii) re-read at the tip (RG-1; R32 (a), (e))` | fork/decision-log.md |
| 8 | claude/carbon-fork-0-1-ct (PR 64) | 4a3220c11 | H64: `CT-1 records: the register block names ten entries, not nine (RG-1; R32 (e), R10)` | fork/decision-log.md |
| 9 | claude/carbon-fork-0-1-ct (PR 64) | H64's final head | H64m: merge of H61's final head, `CT-1: merge TP-1's RG-1 records commit (R32 (e))` | the merge's paths |

H64 is made on 4a3220c11 itself and H64m after it (rev 1 had them the other
way), so that H64's line is the head's own :8342 and the merge comes last, after
the reviews (amended 2026-10-28, review fold: B-m2). PR 54, PR 58, PR 59, PR 62,
PR 63, PR 65, PR 66 and PR 51 gain no RG-1 commit: their blocks have no drift
and no stale cite, or none at all, and their notes are land-time notes
(D-RG-11). The realignment commits are not RG-1's: SAFE-1's on PR 53, SC-1's on
PR 60 and OP-1's on PR 56 (merged into PR 57) are their owners' new commits
under their own reviews, made after RG-1's pushes and before each PR lands
(section 5).

### §3.3 The description refreshes

The orchestrator re-posts each amended PR's description from a scratchpad file
through the GitHub API. For each PR of 3.2 the implementer writes
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/impl/pr_<NN>_refresh.md
holding the paragraph of Appendix A.11 under a heading "RG-1 amendment
(2026-10-27)", to be appended to the PR's current description, which the
orchestrator fetches, and names each file in its hand-off. No description is
edited by RG-1 directly.

## §4 Verification

Records only: no build, no toolchain change, no fill, no dispatch (R28; Actions
is disabled). Every measurement below is a records check or a read-only probe;
nothing here is of record in R9's sense.

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
touches the ledger, and a check that every id from W-346 to W-356 occurs once.
The held commits run prek in their scratch worktrees on their own paths.

### §4.2 Every quote and every silence re-read at the tip

Two tables in
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/fixer/
(the implementer copies both into its own scratch): quotes_rev2.tsv, the 230
quoted lines of section 2 (path, line, verbatim substring; rev 1's 140 and 90
added at rev 2), and checks.tsv, the 89 silence checks section 2's rows name
(amended 2026-10-28, review fold: B-B1, B-m7). The quote checker:

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

The silence checker (bin/check_greps.sh in the same directory):

<!-- google-doc-style-ignore -->

```sh
#!/bin/bash
# check_greps.sh <repo> <tip-sha> <checks.tsv>: re-runs each silence check; prints FAIL rows, exits 1 on any.
# Row: id<TAB>kind<TAB>flags<TAB>pattern<TAB>paths<TAB>expected.
#   G: sum of `git grep -c <flags> -e <pattern> <tip> -- <paths>`.
#   L: `git log --oneline c1e83b0b7..<tip> -- <paths> | wc -l` (upstream commits since the cut).
#   T: `git ls-tree --name-only <tip> <paths>/ | wc -l` (entries of an upstream directory).
repo=$1; tip=$2; tsv=$3; n=0; bad=0
# Empty flags or pattern are written "-" so that tab-separated read keeps every column.
while IFS=$'\t' read -r id kind flags pat paths want; do
  [ -z "$id" ] && continue
  n=$((n+1)); [ "$flags" = "-" ] && flags=""
  case $kind in
    G) got=$(git -C "$repo" grep -c $flags -e "$pat" "$tip" -- $paths 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}') ;;
    L) got=$(git -C "$repo" log --oneline "c1e83b0b7..$tip" -- $paths | wc -l) ;;
    T) got=$(git -C "$repo" ls-tree --name-only "$tip" "$paths/" | wc -l) ;;
  esac
  if [ "$got" != "$want" ]; then echo "FAIL $id ($kind) got $got want $want: $pat $paths"; bad=$((bad+1)); fi
done < "$tsv"
echo "checked $n silence checks, $bad failed"
[ "$bad" -eq 0 ]
```

<!-- google-doc-style-resume -->

Run as `check_quotes.sh /home/user/carbon-lang <sha> quotes_rev2.tsv` and
`check_greps.sh /home/user/carbon-lang <sha> checks.tsv`. At rev 2 both pass at
f27a977d8 and at e6fddcf97: "checked 230 quotes, 0 failed" and "checked 89
silence checks, 0 failed". The implementer re-runs both before R1 and before
R2; a FAIL means upstream moved, and the entry is re-read at the new tip before
any record is written (section 6, R-1). An L check counts commits since the cut
and so grows when upstream edits a merge-rule file; that FAIL is the merge
rule's own signal, re-read, and the expected count updated in the plan. Each
trunk note of A.3 names the checks of its block's NONE rows by row, and W-355's
owner runs both scripts at each weekly check (D-RG-17).

### §4.3 Every cite into the log

Before R1 and R2, for each block of section 0.2 and each line cite in Appendix
A's texts: `git show <head>:fork/decision-log.md | sed -n '<line>p'` contains
the block's opening words (the scan of 4.4 prints them), and each cite of a
held line in A.4 is re-read on the head the commit is made on. After R1, the
trunk block lines move (the RG-1 entry is inserted after :276 and each earlier
note shifts the blocks after it); the RG-1 entry cites the blocks at trunk
0b999d449 and says so, as DR-0's and the weekly's entries do. The held notes
cite RG-1's entry as "the decision-log entry "RG-1: ..." on
claude/carbon-fork-0-1-rg1, which lands first", not as trunk's, since it is not
on trunk when they are pushed (amended 2026-10-28, review fold: B-m8).

### §4.4 The block scan

<!-- google-doc-style-ignore -->

```sh
S=/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/<role>
mkdir -p $S/logs && cd /home/user/carbon-lang && git fetch -q origin
git show origin/trunk:fork/decision-log.md > $S/logs/trunk.md
for n in safe cmake ev st op op2 dd va sc tp sv dr ct dr-idx va2 ua2; do
  git show origin/claude/carbon-fork-0-1-$n:fork/decision-log.md > $S/logs/$n.md; done
python3 -I $S/bin/blocks2.py $S/logs            # trunk's blocks and lines
python3 -I $S/bin/blocks2.py $S/logs safe cmake ev st op op2 dd va sc tp sv dr ct dr-idx va2 ua2
```

<!-- google-doc-style-resume -->

blocks2.py (in fixer/bin/, rev 2's widening of the planner's blocks.py; amended
2026-10-28, review fold: A-M1) prints, per head, the paragraphs absent from
trunk's log that open with "_V-3a divergence-risk register entries",
"DIVERGENCE-RISK REGISTER REVIEW" or "_V-3a register re-check", and every other
paragraph absent from trunk that contains "register". At rev 2 the openers give
exactly the held blocks of section 0.2 (PR 57 two, PR 64 two, PR 66 VA-1's copy,
PR 62 and PR 51 none), and the mentions are each classified: PR 51's :6205-6232
holds H12 (its :6354-6402 is the review fold that closed the same row); PR 66's
:3667-3677 is C2; PR 63's :304-309 and :324-341 and PR 65's :305-310, :325-342
and :369-420 are DR-1's status notes of C1's and T0's entries; PR 56's
:2970-3225 and PR 57's :3901-4156 are D-OP-4's text naming H5.4; PR 54's
:2969-3306 is a decision naming its block; PR 53's :2936-3799, :3805-3836 and
:3875-3901 are its records' references to its block; and PR 60's :4110-4116 and
PR 51's :6138-6173 say "pre-registered", not the register.

### §4.5 The id re-scan

<!-- google-doc-style-ignore -->

```sh
cd /home/user/carbon-lang && git fetch -q origin
( for r in $(git for-each-ref --format='%(refname)' refs/remotes/origin refs/heads); do
    git show "$r:fork/inventory/work-items.json" 2>/dev/null; done
  for w in $(git worktree list --porcelain | sed -n 's/^worktree //p'); do
    cat "$w/fork/inventory/work-items.json" 2>/dev/null; done ) |
  grep -o '"W-3[4-9][0-9]"' | sort | uniq -c
git grep -n -o 'W-3[4-9][0-9]' $(git for-each-ref --format='%(refname)' refs/remotes/origin refs/heads) \
  -- fork ':!fork/register/rg1-plan.md' | awk -F: '{print $NF}' | sort | uniq -c
for w in $(git worktree list --porcelain | sed -n 's/^worktree //p'); do
  grep -r -o -h --exclude=rg1-plan.md 'W-3[4-9][0-9]' "$w/fork" 2>/dev/null; done | sort | uniq -c
```

<!-- google-doc-style-resume -->

Expected before R1, as measured at rev 2 over 136 origin refs, 25 local branches
and 21 worktrees (amended 2026-10-28, review fold: A-m4): ledgers W-340 3, W-341
to W-344 10 each, W-345 3; outside this plan's file, text W-346 and W-398 only
in fork/variadics/va2-plan.md's range bound and W-399 only in
fork/direction/plan.md (section 0.5). This plan's own file names the reserve and
is excluded. After R1: W-346 to W-356 once each in claude/carbon-fork-0-1-rg1's
ledger (and its local ref and worktree), nowhere else.

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

On 2026-10-27: ev 18, op 2, op2 2, sv 4, dr 1, dr-idx 1, every other head 0. The
same diff of op2 against op and of dr-idx against dr counts 0, so PR 57's two
are PR 56's and PR 65's one is PR 63's (amended 2026-10-28, review fold: A-m3).

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

The rule for R1 and R2 (amended 2026-10-28, review fold: B-M1): `git merge-tree`
of claude/carbon-fork-0-1-rg1 against trunk merges clean (it is trunk plus
records); against each held head, no new conflicted file, and in each file at
most the baseline's regions plus one region in work-items.json (the ledger tail,
where RG-1's eleven items and the head's own items both append after the last
item; resolved by keeping both in id order, as W-341 to W-344's merges are),
plus one region in ORCHESTRATION.md (the Next actions list), plus one region in
fork/decision-log.md for exactly three heads: sc (PR 60), where SC-1's entry
follows OV-3's block at the point of the T4 note (resolved by keeping the note
as the last paragraph of OV-3's block, before SC-1's heading), and dr (PR 63)
and dr-idx (PR 65), where DR-1's entry follows DR-0's "_Ids._" paragraph at the
point of A.1 (resolved by placing DR-1's entry directly after DR-0's and RG-1's
after DR-1's, D-RG-14). Reviewer B's simulation found those three, and the
fixer's at rev 2 confirms them and no other: trunk's log with a placeholder
paragraph at each insertion point of A.1 and A.3 (after :276, inline at :765,
and after :3697, :4033, :4432, :4726, :4978, :5186, :5484, :5617, :5971, :6654
and :6782), merged by `git merge-file -p <it> <merge base's log> <head's log>`,
gives the baseline's decision-log regions for every head except sc, dr and
dr-idx, which go from 0 to 1. For each held commit of 3.2: the new head's
merge-tree against trunk has the baseline's regions and no more (a held commit
edits only its own block's lines, its own items' notes and, for H60, a fork page
PR 60 adds), and against claude/carbon-fork-0-1-rg1 after R1 the same plus the
regions above. H57 and H64m are checked with `git merge-tree --write-tree
a080c7886 <H56's final head>` and `... <H64's final head> <H61's final head>`
before they are made: both must be clean (H56 and H61 change lines that PR 57
and PR 64 carry unchanged from their base heads, and H64 changes CT-1's block,
which H61 does not touch). Any other region stops the commit; the implementer
reads both sides and records the resolution in the commit's message.

### §4.8 No build; the read-only probes

No toolchain, prelude or test file changes, so no build, autoupdate, gate or
conformance run is owed. Every verdict rests on upstream's text, and the
toolchain facts quoted (upstream's parser requiring a guard's parentheses, H7.4;
upstream's `AsCompatible` and `ForType` lines, H6.1 and H6.2; upstream's
`SelfDestruct` and cleanup call, D-RG-16) are read from upstream's source at the
tip. One question needed a probe (amended 2026-10-28, review fold: A-M2):
whether OP-1's comparisons can compare in place under the fork's toolchain.
Three probe files, in
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/fixer/probe/,
were checked with `carbon compile --phase=check [--dump-sem-ir]
--output=/dev/null <file>` on the read-only installs, nothing built:

<!-- google-doc-style-ignore -->

```carbon
// inplace.carbon (the route W-352 takes)
library "inplace";
class Store(T: Core.Copy & Core.Destroy) {
  var value: Core.MaybeUnformed(T);
  var has_value: bool;
}
fn EqInPlace[T: Core.Copy & Core.Destroy & Core.Eq](a: Store(T), b: Store(T)) -> bool {
  return (a.value unsafe as T) == (b.value unsafe as T);
}
fn GetCopy[T: Core.Copy & Core.Destroy](s: Store(T)) -> T {
  return s.value unsafe as T;
}
fn EqCopy[T: Core.Copy & Core.Destroy & Core.Eq](a: Store(T), b: Store(T)) -> bool {
  return GetCopy(a) == GetCopy(b);
}
// refget.carbon: as above with
//   fn GetRef[T: Core.Copy & Core.Destroy](ref s: Store(T)) -> ref T { return s.value unsafe as T; }
//   fn EqRef[...](a: Store(T), b: Store(T)) -> bool { return GetRef(ref a) == GetRef(ref b); }
// valget.carbon: as above with `fn GetVal[...](s: Store(T)) -> val T { ... }`
```

<!-- google-doc-style-resume -->

Results. On PR 57's install (/home/user/carbon-build/carbon-op2,
version 0.0.0-0.dev+9f9ccd768) inplace.carbon checks with exit 0; in its SemIR
`fn @EqInPlace` has no `Copy` and no `SelfDestruct` call and calls
`EqWith.WithSelf.Equal` on the two `converted` (`unsafe as`) values, while `fn
@EqCopy` calls `GetCopy` twice (each a `Copy.WithSelf.Op` call) and
`Destroy.WithSelf.SelfDestruct` twice; the nightly 2026.10.12 also checks it
with exit 0. refget.carbon is rejected, "error: value expression passed to
reference parameter" at `GetRef(ref a)`, and then stops at "CHECK failure at
.../toolchain/check/pattern_match.cpp:2207:
std::holds_alternative<CalleeState*>(state)" on PR 57's install and on trunk's
(0.0.0-0.dev+0bdce60a5), exit 134, where the nightly reports the error for both
operands and exits 1: that is W-356 (D-RG-18). valget.carbon is rejected by all
three with "error: expected expression" at `val`. If a reviewer finds the
in-place route wrong, D-RG-10's break condition applies. No other probe ran.

## §5 Conflicts and the land order

RG-1's own PR is records only, base trunk, held like the others. It lands FIRST
in the land sequence, before PR 53: PR 53's amendment (H53) names W-347 to W-351
and W-353, which RG-1's ledger files, and R32 (e) requires PR 53's six
realignments before PR 53 lands, which needs the items scheduled on trunk; a
records-only PR that merges clean with trunk carries no risk to the land
sequence's gates. The merge order then reads: RG-1, PR 53, 51, 52, 60, 54, 55,
56, 57, 58, 59, 61, 62, 64, 63, 65, 66. Its conflicts with each later PR
are 4.7's, resolved at that PR's merge as the ledger tails and Next actions
lists are today, and the three decision-log regions as D-RG-14 says.

The held commits land with their PRs. Three PRs carry drifts and cannot land
until their owners' realignment commits are made on their branches and reviewed
(R32 (e); amended 2026-10-28, review fold: A-M2, A-M5):

-   PR 53 waits for SAFE-1's re-derivation of W-347 to W-351 and W-353 (a plan
    amendment of fork/safe/plan.md, a new commit on PR 53's branch, two
    document reviews and a fixer; D-RG-7's table names the dependent lines).
    Until then the land sequence is held at its first PR.
-   PR 60 waits for SC-1's W-139 (code: a checked-symbolic self deferred to
    monomorphization, with its goldens, fills and the template_constraints.md
    paragraph rewritten; D-RG-7). PR 60 is fourth in the order.
-   PR 56 waits for OP-1's W-352 (code: the comparisons compare in place, with
    their goldens and fills, D-RG-10), merged into PR 57's branch. PR 56 is
    seventh.

The sequence may run up to a waiting PR and stop there; it does not skip it,
because each later PR's records and merge-trees assume the earlier ones. W-346
lands on trunk after the held PRs (D-RG-8) and before UA-3, beside OV-4's
W-341; W-354 and W-356 are UA-3's own (D-RG-16, D-RG-18).

## §6 Risks and rejected alternatives

Each risk is falsifiable by the check named.

-   **R-1: upstream moves before R1.** A commit after e6fddcf97 changes a quoted
    line or a checked file. Falsifier: either script of 4.2 reports a FAIL at
    R1's fetch. Response: re-read the entry at the new tip; a changed verdict is
    a plan amendment (rev N), never an edit of R1's text in place.
-   **R-2: F-006a's verdict is wrong (the README's `Result` is only an
    example).** Falsifier: a design page or leads answer at the tip that calls
    the error-handling section's `Result` illustrative or names other
    alternatives, or the user's veto of the reversal. Response: W-346 is
    withdrawn by a dated note, its break condition. Rejected alternative: NONE
    on V-3's "illustrative" ground, because that ground was the override clause
    V-3b withdrew, and D-RG-5 rests on the error-handling statement and the
    section it links, not on the generic example (D-RG-2 (ii)).
-   **R-3: F-009's verdict is wrong (the placeholder is direction).** Falsifier:
    an owner ruling that a placeholder is direction. Response: a rename item
    (`overload` to `overloaded`), owner the overload workstream, is filed under
    a new id after a fresh re-scan (W-357 to W-359 stay unused). Rejected
    alternative: DRIFT now, because p002875 itself says "using placeholder
    syntax" and pattern_matching.md:696 says there is no approved design.
-   **R-4: SAFE-1's six are realignable by RG-1 as text.** Falsifier: a reviewer
    shows one departure whose page sentence can restate upstream's text with no
    dependent line of D-RG-7's table changing. Response: D-RG-7's break
    condition; that edit joins H53. Rejected alternative: RG-1 rewrites the six
    decisions itself; they interlock (D-SAFE-11(d) is "the D-SAFE-17 narrowing
    applied at a second site", D-SAFE-19 exports D-SAFE-17's binding as
    `&SharedView<T>`), and a records workstream re-deriving a safety design
    bypasses SAFE-1's reviews.
-   **R-5: a NONE hides a drift in an internal surface.** Falsifier: an upstream
    design page or proposal at the tip that names one of section 2's internal
    surfaces; section 4.2's G checks run that grep for each NONE row's
    identifier, and W-355's owner re-runs them weekly. Response: re-classify
    under D-RG-3's break condition.
-   **R-6: the in-place comparison route fails (W-352).** Falsifier: OP-1's
    realignment cannot keep D-OP-4's signatures or the comparisons' results
    (its own review). Response: D-RG-10's break condition; PR 56 then waits for
    W-320 and the land sequence stops at PR 56 (amended 2026-10-28, review fold:
    A-M2).
-   **R-7: the held commits conflict.** Falsifier: 4.7's merge-trees. Response:
    stop, read both sides, record the resolution.
-   **R-8: D-RG-8 leaves a held PR's text out of date.** Falsifier: PR 54 lands
    with its tutorial teaching `Ok`/`Err` while W-346 has already renamed trunk.
    Response: D-RG-8's break condition: W-346 is scheduled after the held PRs,
    so the case does not arise unless the schedule changes.
-   **R-9: the staged commits are lost before their push.** Falsifier: `git
    rev-parse refs/rg1-stage/<pr>` fails after a worktree is removed. Response:
    the stage ref is made before the worktree is removed (section 3), and a
    lost commit is re-made from Appendix A by a fresh read (amended 2026-10-28,
    review fold: B-M5).
-   **Rejected: reordering PR 53 later in the land sequence** so that SAFE-1's
    re-derivation does not hold the other PRs (amended 2026-10-28, review fold:
    A-M5). Cost: SC-1's W-144 collides with SAFE-1's W-144 and renumbers to
    W-151 only because SAFE-1 lands first (ORCHESTRATION :88-94); landing SC-1
    first reverses that renumbering across PR 60's ledger, records and PR
    description, and every later PR's merge-tree baseline changes. Kept first;
    break condition: SAFE-1's re-derivation is not signed off when every other
    PR before PR 66 is otherwise ready to land, and then the reorder is decided
    with W-144's renumbering as its own records commit.
-   **Rejected: landing PR 56 with W-352 recorded and blocked** (rev 1's
    D-RG-10). R32 (e) has no such exception, and the probe shows a route under
    OP-1's control (amended 2026-10-28, review fold: A-M2).
-   **Rejected: one work item for SAFE-1's departures.** Each departure has its
    own decision, page and break condition; one item would hide which ones are
    realigned.
-   **Rejected: notes on every held block now.** Five more held commits and
    description refreshes for blocks with no drift and no stale cite, against
    R32 (e)'s purpose; D-RG-11 schedules their notes with their land-time
    records instead.
-   **Rejected: one watch item per block instead of W-355.** One more id per
    block (23 blocks and V-3's group) for the same weekly action; W-355's
    evidence names the blocks it covers (A.5).
-   **Rejected: placing the RG-1 entry beside the weekly checks.** The weekly
    entries are a dated series; RG-1 executes V-3b and DR-0's register, which
    sit at the top (D-RG-14).

## §7 Residues

Entries whose classification or realignment waits on an upstream decision, or on
an item blocked by one; each is a register entry with a work item (R32 (b)) and
is re-checked at each weekly upstream check:

| Entry | Waits on | Work item | Re-check |
| --- | --- | --- | --- |
| H5.5 OP-1's `None()` against the `Optional(T).None` pattern | W-320 | W-320 | with W-324: sum_types.md:113 against README.md:1076-1078 |
| C1.1 `Core.Optional` not matchable | upstream's conflict | W-320, W-324 | as above |
| T5.7 and C1.2 the literal-subscript rule | upstream's `like` (lex/token_kind.def:208, a token only) | W-326 | indexing.md:101-121 and a `like` in parse or check |
| H8.3 and C2.3 a pack's bare name | the design (p002240's alternative not adopted) | W-230 | p002240 "Omit each-names" (:555) and variadics.md |
| C2.1 `...expand`'s typechecking | the design's TODO (variadics.md:493, :750) | W-217 | variadics.md :493 and upstream handle_pack_expansion.cpp |
| C2.4 the fixed-arity `let` reading | the design's text (variadics.md:219-221 with :532-546) | W-214 | both passages |
| C2.5 a segment's rank against `?` | the overlap rule (generics/details.md:4921-4929) | W-338 | the rule and upstream type_structure.cpp |
| C2.6 comparisons of non-total orderings | comparison_operators.md:457-464 and its TODO | W-339 | those lines |

Ten entries: T5.7, H5.5, H8.3, C1.1, C1.2, C2.1, C2.3, C2.4, C2.5 and C2.6, of
which three are DRIFTs (T5.7, C1.1 and C1.2) (amended 2026-10-28, review fold:
A-M2, A-m3). H5.4 is no longer a residue: W-352 is realigned on PR 56 (D-RG-10).
C2.2 is not a residue (it is scheduled with W-222). W-354 is not a residue
either: it waits on no upstream decision, only on the advance that brings
05a7ecbd3 (D-RG-16). No other entry waits: every other DRIFT is scheduled
(section 5), and every NONE and ALIGNED carries its break condition and W-355.

## Appendix A: records texts

Every text below is written as it is to stand in the file, hand-wrapped at 80
columns so that rumdl's reflow leaves it (R31: no line starts with a list
marker, a plus sign, a hash or a digit and a period unless it is a list item or
a heading meant as one). "2026-10-27" is the commit's UTC date (section 3), and
`<tip>` is the sha R1's fetch gives (section 3.1). Insertion points are lines at
the head named; within one file the implementer inserts from the bottom up, so
each earlier line number stays valid.

### A.1 The decision-log entry (R1; trunk, after DR-0's "_Ids._" paragraph)

Inserted after trunk 0b999d449's :276 (the blank line after DR-0's "_Ids._"
paragraph, which ends at :275) and before :277 ("### B0 SF-1..5: ..."),
followed by one blank line (amended 2026-10-28, review fold: B-m2):

<!-- google-doc-style-ignore -->

```text
### RG-1: the V-3a register classified at f27a977d8 (2026-10-27)

Placed here, in Decided directly after DR-0, because the log groups entries by
workstream and RG-1 carries out V-3b's rule for DR-0's register: the register
"is a work queue whose entries each carry a work item" (fork/rulebook.md R32
(b)). DR-1's entry, held on PR 63, goes between DR-0's and this one when it
lands. Line cites into this log are to the file at trunk 0b999d449, before this
entry and its notes moved them. Records only: no toolchain, prelude, golden or
program file changes with it.

_The work and the rule._ W-342, W-343 and W-344 asked for every V-3a register
entry to be classified against upstream's tip. Upstream trunk f27a977d8
(2026-10-27, "Fix ASan CI failures due to `preserve_none`", upstream PR 8045;
131 commits past the c1e83b0b7 cut, 14 past 21c825a3f) was read by sha and
re-checked unchanged at <tip>. fork/register/rg1-plan.md section 2 quotes
upstream's text for each of the 155 entries in 26 blocks and V-3's design-fork
group: on trunk DR-0's block, the eleven blocks that predate it and the
design-fork entries F-006a, F-007 and F-009 that V-3 registered and UA-1's
review names; on the held heads fourteen blocks, PR 51's UA-2 register re-read
among them. Its section 4.2 re-reads the 230 quoted lines and re-runs 89
silence checks, one for each NONE row whose upstream silence is shown by a
grep, a log count or a directory listing at the tip. An entry is a DRIFT when
upstream has designed its mechanism and the fork spells it otherwise (R32 (d)),
ALIGNED when the fork's spelling or rule is upstream's, and NONE when upstream
is silent. Upstream has designed a mechanism when text at the tip shows it with
a spelling, is about it, and does not call the spelling placeholder or
provisional (D-RG-2). Toolchain-internal surfaces are NONE, their merge rules
their break conditions, unless that condition has already fired (D-RG-3); a
partial implementation whose gap carries an item is ALIGNED (D-RG-4). The
decisions D-RG-1 to D-RG-19 are auto-adopted under R29(a), each with its break
condition in the plan's section 1.

_The count._ 19 DRIFT, 34 ALIGNED and 102 NONE; 10 entries, three DRIFTs among
them, wait on an upstream decision or on an item blocked by one (the plan's
section 7). Eight DRIFT entries were filed before RG-1 (W-109 twice, W-320 with
W-324, W-321, W-322, W-326 twice, and SC-1's W-139); eleven are carried by
items filed now: W-346, W-347 to W-351, W-352, W-353 and W-354 (three entries).
Every NONE and ALIGNED entry carries W-355, the register's watch item, re-read
at each weekly upstream check (D-RG-17), so the register stays a work queue.

_The two R29 decisions._ F-006a's `Ok`/`Err` is a DRIFT (D-RG-5). Upstream's
README, in its "Error handling" section, names `Result` as Carbon's error
representation ("At this point, errors are represented using `[choice
types](#choice-types)` like `Result` and `Optional`.",
docs/design/README.md:3856-3860), and the choice-types section it links spells a
result choice's alternatives `Success(value: i32)` and `Failure(error: String)`
(:2167-2177); the README's own `Result` under "Generic choice types"
(:3159-3166) spells them `Success(value: T)` and `Failure(error: Error)`. No
upstream text spells `Ok` or `Err` or marks `Success` and `Failure` as
placeholder, and "illustrative" was V-3's override ground, which V-3b withdrew.
W-346 renames the alternatives (the payload names and the order already match),
owner EH-C, on trunk's base after the held PRs land and before UA-3. It reverses
the user's sub-decision F-006a (2026-07-19, :716-718) under the owner directive
of 2026-10-21, and the user may veto it. Break condition: upstream adds a
prelude `Result` or an error-handling proposal with other alternatives (take
them), or changes the README's examples to `Ok`/`Err` (withdraw W-346), or the
user vetoes. F-009's `overload fn` is NONE (D-RG-6): upstream's only introducer
is p002875's "using placeholder syntax" (:481) before `overloaded fn`
(:484-485), and pattern_matching.md says "We do not yet have an approved design
for overloaded functions" (:696); F-009's closed same-library sets and
declaration-order first match are ALIGNED with static_open_extension.md:52-54
and pattern_matching.md:696-697. Break condition: upstream accepts a proposal or
lands a token or page that spells the introducer (then a rename is filed as a
drift).

_The drifts and their items._ Trunk: F-006a's `Ok`/`Err` (W-346, EH-C); SL-1's
D-SL-16 yield and D-SL-19 keying, whose own break condition ("if upstream's
destroy-op synthesis starts calling declared impls") 05a7ecbd3 meets: at the tip
`fn SelfDestruct[T: Destroy](ref t: T)` calls `t.(DestroyImpl.Op)();`
(core/prelude/destroy.carbon:36-38) for every cleanup
(check/control_flow.cpp:158), so W-354, owner UA-3 with SL-1's records, drops
both at the advance that brings 05a7ecbd3 (PR 51's UA-2 record of the trigger
met for fields is the same drift); the rest are DR-1's (W-109, W-321 and W-322,
resolved on PR 65, PR 63 and PR 62; D-SL-17's literal-subscript rule, W-326,
blocked on upstream's `like`). The fork's declared-destructor spelling `impl as
Destroy` is ALIGNED with destroy.carbon:14's "TODO: rename to `Destroy` when
`require impls` adds a witness table entry." PR 53, SAFE-1's departures from
accepted text: p005434:83's `noalias` on every `ref` binding narrowed by
D-SAFE-8 (W-347), p005434:663's plan to prevent mutation of borrowed objects in
Strict narrowed by D-SAFE-17 (W-348), p005434:831-832's "immutable" narrowed to
"not invalidated" by D-SAFE-11(d) (W-349), arithmetic.md:156-158's
performance-build row withdrawn by D-SAFE-15 (W-350), safety/README.md:260-262's
benchmarking disable withdrawn by D-SAFE-14 (W-351), and README.md:2130-2132's
type-defined initialization "for the hardened build mode" promoted by D-SAFE-13
to the Release baseline for every type with no separate hardened mode, where
safety/README.md:248-250 plans specialized hardened modes extending Release
(W-353); each is realigned by SAFE-1 by a new commit on PR 53's branch before it
lands (R32 (e)), and PR 53 lands first. PR 60: D-SC-6's definition-time
rejection of a checked-generic argument to a template parameter, where
generics/overview.md:375-379 records "We have decided to support passing a
symbolic constant to a template parameter" (leads issue 2153) and
appendix-witness.md:151-154 that the approach "relies on monomorphization":
W-139's break condition was already met when it was filed, upstream's text
predating the cut; SC-1 realigns on PR 60 before it lands. PR 56: the
comparisons run `T.Copy` and `T.Destroy`, against comparison_operators.md
:315-316 and :433-434's "should have no observable side-effects" (W-352, owner
OP-1, a code commit on PR 56 before it lands, comparing in place, a route a
read-only probe showed checks without a `Copy` or a `SelfDestruct` call). Not
drifts: the Permissive reading of p005914:204-210 (ALIGNED: the passage limits
what the safety model may assume so that no undefined behavior follows, and no
fork optimization relies on the diagnostic assumption), the restored `addr self:
Self*` (ALIGNED with p005434:1226-1236), OP-2's adapter destruction (ALIGNED
with upstream's TODO at check/custom_witness.cpp:466-467), the guard parentheses
DD-1 documents (ALIGNED with upstream's own parser, parse/handle_match.cpp:169
and :176), `Core.Buf` (ALIGNED with README.md:885-886), VA-1's `each` keyword
and `(... x)` tuple (ALIGNED with variadics.md:47-48, :92 and :137-139),
`template constraint` (ALIGNED with generics/details.md:1072-1073 and :5494),
TP-1's `array` arm (ALIGNED with README.md:872-874's `array(T, N)` shorthand for
the prelude's `Core.Array`), CM-1's Core-object helper (ALIGNED with
p006333:193-198, its gap W-003), EH-B's `noexcept` fence (ALIGNED with
interoperability/philosophy_and_goals.md:408-410) and `Core.StringBuf` (NONE:
README.md calls its string types "provisional", :622; the view keeps upstream's
prelude spelling `Core.String` until sem_ir/type_info.h:382's "TODO: Rename
`Core.String` to `Core.Str`." lands).

_Per block_ (lines at trunk 0b999d449 or at the held head; D, A and N are the
DRIFT, ALIGNED and NONE counts):

| Block | Lines | D / A / N | Items |
| --- | --- | --- | --- |
| DR-0's register | :241-247 | 3 / 0 / 0 | W-322, W-109, W-321 (resolved on held PRs) |
| F-006 (B1) | :757-765 | 0 / 0 / 3 | W-355 |
| V-3's F-006a, F-007, F-009 | :31-41, :6652-6653 | 1 / 2 / 4 | W-346; W-355 |
| SL-2 | :3686-3697 | 0 / 3 / 5 | W-120 (watch); W-355 |
| OV-3 | :4025-4033 | 0 / 0 / 2 | W-355 |
| SL-1 | :4421-4432 | 4 / 2 / 5 | W-354, W-326, W-109; W-110 (the `buf(T)` gap); W-355 |
| OV-2 | :4718-4726 | 0 / 0 / 5 | W-355 |
| OV-1 | :4971-4978 | 0 / 0 / 5 | W-355 |
| UN-2 | :5179-5186 | 0 / 0 / 2 | W-355 |
| UN-1 | :5476-5484 | 0 / 0 / 3 | W-355 |
| EH-B (with UA-1's `noexcept` fence) | :5596-5617, :6606-6607 | 0 / 1 / 3 | W-355 |
| EH-A | :5961-5971 | 0 / 2 / 2 | W-346 (the alternatives); W-355 |
| UA-1's watch list | :6768-6782 | 0 / 0 / 7 | W-355 |
| SAFE-1, PR 53 adaae4e35 | :3920-3938 | 6 / 4 / 5 | W-347 to W-351, W-353; W-355 |
| CM-1, PR 52 ea573f672 | :3119-3133 | 0 / 2 / 5 | W-003, W-132, W-129; W-355 |
| EV-1, PR 54 cb3ef2e74 | :3538-3549 | 0 / 0 / 3 | W-355 |
| ST-1, PR 55 21307851a | :3503-3516 | 0 / 0 / 6 | W-355 |
| OP-1, PR 56 894139b34 (PR 57 :4460-4472) | :3529-3541 | 1 / 1 / 4 | W-352; W-320; W-355 |
| OP-2, PR 57 a080c7886 | :3779-3792 | 0 / 2 / 5 | W-196, W-200 (gaps); W-355 |
| DD-1, PR 58 fcee90d9b | :4114-4129 | 0 / 2 / 4 | the nine documented gaps' items; W-355 |
| VA-1, PR 59 b0822a744 (and PR 66) | :3609-3630 | 0 / 3 / 5 | W-230 (watch); W-355 |
| SC-1, PR 60 40a76ab81 | :4187-4202 | 1 / 2 / 3 | W-139; W-355 |
| TP-1, PR 61 5661a35c8 (and PR 64) | :4185-4208 | 0 / 3 / 5 | W-258, W-268, W-260 to W-262, W-266, W-250; W-355 |
| CT-1, PR 64 4a3220c11 | :8341-8342, plan §0.10 | 0 / 3 / 7 | W-355 |
| UA-2's re-read, PR 51 f96fe8a7a | :6226-6232 | 1 / 0 / 0 | W-354 |
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
plan's rev 4); PR 60's template_constraints.md, which calls issue 2153
"upstream's open question", gains a dated note. Each is a new commit on its
branch (R32 (e)); PR 57 and PR 64 merge their base PR's commit. The blocks
without a drift or a stale cite (PR 51's, PR 54's, PR 57's OP-2, PR 58's, PR
59's) gain their notes with their PRs' land-time records, scheduled in
ORCHESTRATION (D-RG-11).

_Also filed._ W-355, the register watch item (D-RG-17), and W-356: the probe
that tested OP-1's routes stops trunk's toolchain at
check/pattern_match.cpp:2207's `CHECK` after "value expression passed to
reference parameter", where the nightly 2026.10.12 diagnoses; owner UA-3, re-run
at the advance (D-RG-18).

_Ids._ The re-scan of rg1-plan.md section 4.5 (136 origin refs, 25 local
branches, 21 worktrees, after a fetch) finds W-340 to W-345 in ledgers and
W-346, W-398 and W-399 only as range bounds in two plans' text. RG-1 reserves
W-346 to W-359, files W-346 to W-356, and leaves W-357 to W-359 unused.

_Not run._ No build, fill, gate, conformance or dispatch (R28); Actions is
disabled, so nothing is of record (R9). The probes of the plan's section 4.8
ran the read-only installs with `--phase=check` only.
```

<!-- google-doc-style-resume -->

### A.2 R2's paragraph (appended to the RG-1 entry, before its "_Ids._")

<!-- google-doc-style-ignore -->

```text
_Held commits (2026-10-27, R2)._ PR 53 <sha53> (H53), PR 52 <sha52> (H52), PR
60 <sha60> (H60), PR 55 <sha55> (H55), PR 56 <sha56> (H56) with PR 57's merge
<sha57> (H57), PR 61 <sha61> (H61), and PR 64's own <sha64> (H64) with its
merge <sha64m> (H64m), after two implementation reviews and their fixes; each
description is refreshed. W-344 is discharged; W-343 is narrowed to the
land-time notes of PR 51, PR 54, PR 57 (OP-2), PR 58 and PR 59.
```

<!-- google-doc-style-resume -->

### A.3 The notes in trunk's blocks (R1)

Each is a new paragraph after the block's last line (T1's is inline, T2's
follows UA-1's review), at trunk 0b999d449's lines, inserted bottom up in this
order: T12 (:6782), T2 (:6654), T11 (:5971), T10 (:5617), T9 (:5484), T8
(:5186), T7 (:4978), T6 (:4726), T5 (:4432), T4 (:4033), T3 (:3697), T1 (:765)
(amended 2026-10-28, review fold: B-m2). The common lead is "_RG-1 (classified
2026-10-27, upstream f27a977d8, re-checked at <tip>; the entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" has the quotes, and the checks
named are rows of fork/register/rg1-plan.md section 4.2):_". Each note names the
silence check of every NONE it records, by row, with the grep and its result,
and W-355 for every NONE and ALIGNED (amended 2026-10-28, review fold: B-B1,
B-M2).

<!-- google-doc-style-ignore -->

```text
[T12, a new paragraph after :6782]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: the V-3a register classified at f27a977d8 (2026-10-27)" has the
quotes, and the checks named are rows of fork/register/rg1-plan.md
section 4.2):_ the seven items (classified 2026-10-27, RG-1: NONE, W-355; fork code
inside upstream functions with no upstream design): upstream's toolchain has no
`is_union` in check/merge.cpp (check T12.1), no `TryMergeOverloadDecl` (T12.2),
no `is_choice` in check/custom_witness.cpp (T12.3), no `return_type_id` in
check/function.h (T12.4), no `BeginConditionalExprOperand` or
`EndConditionalExprOperand` (T12.5) and no `function.generic_id.has_value()`
in check/cpp/type_mapping.cpp (T12.6), each `git grep -c` 0 at the tip; and
upstream still asserts `CARBON_CHECK(!src_clang_decl->isTemplateDecl(), "can't
form a pointer to a template")` (check/cpp/export.cpp:1902-1903) where the
fork's guard diagnoses (T12.7). 05a7ecbd3 rewrote check/custom_witness.cpp, the
`is_choice` clauses' file, which is UA-3's merge rule, not a design.

[T2, a new paragraph after UA-1's review, after :6654]
_RG-1 on the design-fork entries (classified 2026-10-27, upstream f27a977d8,
re-checked at <tip>; the entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ F-006a's `Ok`/`Err` (classified
2026-10-27, RG-1: DRIFT, W-346, reversing the user's F-006a under the
2026-10-21 directive, veto-able; README.md:3856-3860 names `Result` as the
choice that represents errors and links the choice-types section, whose
`IntResult` spells `Success(value: i32)` and `Failure(error: String)`
(:2175-2177), as :3164-3166 spells `Result`'s `Success(value: T)` and
`Failure(error: Error)`); F-007's `union` keyword, class-shaped declaration and
byte-reinterpretation reads (classified 2026-10-27, RG-1: NONE, W-355;
p000157:239 proposes "A typed `union` facility", upstream's lexer has no
`union` token (check T2.2: 0), its toolchain no union class (T2.3: 0), and its
only untagged-union text is sum_types.md:94's "layout will presumably involve
untagged unions or some other low-level storage" primitive (T2.4: 1)); F-009's
closed sets and first match (classified 2026-10-27, RG-1: ALIGNED, W-355;
static_open_extension.md:52-54 and pattern_matching.md:696-697); F-009's marker
`overload fn` (classified 2026-10-27, RG-1: NONE, W-355; p002875:481 "using
placeholder syntax", pattern_matching.md:696).

[T11, after :5971]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ (i) `Core.Result` as a choice
(classified 2026-10-27, RG-1: ALIGNED, W-355; README.md:3859-3860 "errors are
represented using `[choice types](#choice-types)` like `Result`"; its
alternatives are W-346's), the library name (classified 2026-10-27, RG-1: NONE,
W-355; `git grep -c -F prelude/types/result` over upstream core and toolchain
is 0, check T11.2), the success-first order (classified 2026-10-27, RG-1:
ALIGNED, W-355; README.md:3165-3166); (ii) the `()` payload (classified
2026-10-27, RG-1: NONE, W-355; upstream has no payload allowlist,
`IsInSliceChoicePayloadType` 0, check T11.4).

[T10, after :5617]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ (i), (ii) and (iii) (classified
2026-10-27, RG-1: NONE, W-355; upstream designs no exception mapping:
`carbon/expected.h` and `primary_` 0 in upstream toolchain/install and core
(check T10.1), `std::expected` 0 in docs/design and proposals (T10.2),
`carbon_catching_thunk` 0 in toolchain (T10.3);
interoperability/philosophy_and_goals.md:405-410 allows that "translating C++
exceptions to or from Carbon errors might require annotations or bridge
code"); the `noexcept` fence UA-1's review counts (classified 2026-10-27,
RG-1: ALIGNED, W-355; the same page's :408-410 "the program might terminate").

[T9, after :5484]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ the three surfaces (classified
2026-10-27, RG-1: NONE, W-355; upstream does not recognize
core/prelude/default.carbon:17's `interface UnformedInit` as a kind, and has no
`is_union` (check T9.2: 0) and none of the four `Union...` diagnostics (T9.3:
0)); F-007's entries are noted after UA-1's review.

[T8, after :5186]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ both (classified 2026-10-27, RG-1:
NONE, W-355; upstream exports no Carbon union: `TagTypeKind::Union` 0 in
check/cpp/export.cpp (check T8.1), `is_union` 0 in check/cpp (T8.2)).

[T7, after :4978]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ the `overload` keyword (classified
2026-10-27, RG-1: NONE, W-355; p002875:481 introduces `overloaded fn` "using
placeholder syntax"; pattern_matching.md:696 "We do not yet have an approved
design for overloaded functions"; no `overload` in upstream's
lex/token_kind.def, check T7.1); the marker, the inst kinds and store, the five
diagnostics and the print field (classified 2026-10-27, RG-1: NONE, W-355;
internal: `:overload` 0 in sem_ir/mangler.cpp (T7.2), the three `OverloadSet`
names 0 (T7.3), the five diagnostics 0 (T7.4), `overload_set_id` 0 in
sem_ir/function.h (T7.5); upstream's only mention is sem_ir/function.h:547's
TODO); F-009's entries are noted after UA-1's review.

[T6, after :4726]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ the five (classified 2026-10-27,
RG-1: NONE, W-355; internal surfaces with their merge rules: the two
diagnostics (check T6.1), `MergeOverloadMemberRedecl` and
`prev_decl_override` (T6.2), `bool diagnose` in check/deduce.h (T6.3),
`GetApiClassDeclForQualifier` (T6.4) and `OverloadSetValue` (T6.5) are each 0
in upstream's toolchain).

[T5, after :4432]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ the four builtins (classified
2026-10-27, RG-1: NONE, W-355; values.md:1128-1129 expects pointer arithmetic
"through specialized constructs"; none of the four names upstream, check T5.1:
0); `Core.Slice` (classified 2026-10-27, RG-1: NONE, W-355; README.md:912
"**TODO:** Slices"; indexing.md:116's `class Span(T: type)` is an example of
`IndirectIndexWith`); `Core.Buf` (classified 2026-10-27, RG-1: ALIGNED, W-355;
README.md:885-886 "a shorthand for the library type `Core.Buf(T)`"; the
shorthand is W-110); the `Iterate` impl (classified 2026-10-27, RG-1: ALIGNED,
W-355; iterate.carbon's interface; its cursor is W-321's); D-SL-15, D-SL-18 and
D-SL-20 (classified 2026-10-27, RG-1: NONE, W-355; no `pointer.offset` (check
T5.5), slice or buffer class (T5.8) or `heap.allocate` (T5.10) upstream, each
0); D-SL-16 and D-SL-19 (classified 2026-10-27, RG-1: DRIFT, W-354: this
block's own break condition is met, since upstream's
`fn SelfDestruct[T: Destroy](ref t: T)` calls `t.(DestroyImpl.Op)();`
(core/prelude/destroy.carbon:36-38) for every cleanup
(check/control_flow.cpp:158); UA-3 drops the yield and the keying at the
advance that brings 05a7ecbd3; the declared spelling `impl as Destroy` is
ALIGNED with destroy.carbon:14's "TODO: rename to `Destroy` ..."); D-SL-17
(classified 2026-10-27, RG-1: DRIFT, W-326, blocked on `like`); D-SL-3
(classified 2026-10-27, RG-1: DRIFT, W-109, resolved on PR 65).

[T4, after :4033]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ both (classified 2026-10-27, RG-1:
NONE, W-355; internal: `NamedDeclList` (check T4.1) and `overload_index` (T4.2)
are 0 in upstream's toolchain).

[T3, after :3697]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes, and the checks named are rows of
fork/register/rg1-plan.md section 4.2):_ the `Span` mapping and the export arm
(classified 2026-10-27, RG-1: ALIGNED, W-355; README.md:3707-3708 "Other view
types, like `std::span`, are intended to map similarly"); the synthesized
interface, the prelude sections, D-SL-8, D-SL-9 and D-SL-24 (classified
2026-10-27, RG-1: NONE, W-355; README.md:912 "**TODO:** Slices"; upstream has
no `CppContiguousRange` (check T3.3: 0), no `Slice` in core, check or sem_ir
(T3.4: 0), no `BuildCppContiguousRangeWitness` (T3.6: 0), and its own
`BuildCopyWitness` (T3.8: 2 lines) is D-SL-24's merge point; W-120 watches
D-SL-9); D-SL-21 (classified 2026-10-27, RG-1: ALIGNED, W-355; upstream's own
orphan rule).

[T1, inline at :765, after "(with F-006a's `Ok`/`Err`
already on the register)." and before "_Mechanism (plan §2.4 as revised):_"]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
entry "RG-1: ..." has the quotes): (i) to (iii) NONE, W-355, upstream
README.md:3858-3859 "Carbon does not have language features dedicated to
error handling"; `ControlFlow` (checks T1.1 and T1.2) and `interface Try`,
`FromBreak` or `FromContinue` (T1.3) are 0 in upstream's core, docs/design,
proposals and toolchain; F-006a DRIFT, W-346._
```

<!-- google-doc-style-resume -->

In each note "the entry "RG-1: ..."" is written out in full, as in T12's and
T2's.

### A.4 The held blocks' amendments

The held notes cite RG-1's entry as being on claude/carbon-fork-0-1-rg1, which
lands first, since it is not on trunk when they are pushed (amended 2026-10-28,
review fold: B-m8). The common held lead is "_RG-1 (classified 2026-10-27,
upstream f27a977d8, re-checked at <tip>; the decision-log entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-27)" on claude/carbon-fork-0-1-rg1,
which lands first, and fork/register/rg1-plan.md section 2.Hn have the
quotes):_".

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
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" on claude/carbon-fork-0-1-rg1, which lands first, and
fork/register/rg1-plan.md section 2.H1 have the quotes):_ under V-3b each
departure from accepted text is a drift with its work item, realigned by
SAFE-1 by a new commit on this branch before it lands (R32 (e)): p005434:83
(classified 2026-10-27, RG-1: DRIFT, W-347), p005434:663 (classified
2026-10-27, RG-1: DRIFT, W-348), p005434:831-832 (classified 2026-10-27, RG-1:
DRIFT, W-349), arithmetic.md:156-158 (classified 2026-10-27, RG-1: DRIFT,
W-350), safety README.md:260-262 (classified 2026-10-27, RG-1: DRIFT, W-351)
and the zero-fill promotion (classified 2026-10-27, RG-1: DRIFT, W-353:
upstream README.md:2130-2132 lets types define additional initialization for
the hardened build mode, which safety README.md:248-250 plans as specialized
modes extending Release, where D-SAFE-13 I5 zero-fills every type in the
Release baseline with no separate mode; its cite above corrected from this
branch's copy). Each decision is named on three to five of this branch's pages
(rg1-plan.md D-RG-7 lists the lines), so each realignment is a re-derivation,
not a one-sentence edit. The Permissive reading of p005914:206-208 (classified
2026-10-27, RG-1: ALIGNED, W-355: read against p005914:204-210 in full, the
passage limits assumptions so that no undefined behavior follows and its
example is an optimization assumption; T8 withholds `noalias`, so no
optimization relies on the diagnostic assumption) is not a drift. `unsafe
permissive`, the prefix `unsafe` forms and the restored `addr self: Self*`
(classified 2026-10-27, RG-1: ALIGNED, W-355; safety README.md:116-118 and
:80-81, p005434:1226-1236) follow upstream; `exclusive`, `unsafe import`,
`unsafe class`, the library names and the `import Cpp` asymmetry (classified
2026-10-27, RG-1: NONE, W-355; no upstream spelling: `exclusive T*`, `unsafe
import` and `unsafe class` are each 0 in upstream's docs/design and proposals,
the library names only p004682:316's `Core.Box(Array(T, N))` table cell;
safety README.md:122-123 leaves import marking to future work). Since V-3b the
re-basing clause above reads "re-based under R32".
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
files mention CMake, nine of them build or toolchain files and four of them
text, among them docs/project/milestones.md, whose :230-231 names "Build system
integration for CMake" as a 0.1 deliverable this workstream delivers;
corrected 2026-10-27, RG-1, against upstream f27a977d8), so the module and
helper names

[new paragraph after :3133]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" on claude/carbon-fork-0-1-rg1, which lands first, and
fork/register/rg1-plan.md section 2.H2 have the quotes):_ the CMake support
(classified 2026-10-27, RG-1: ALIGNED, W-355; docs/project/milestones.md:230-231
and proposals/p006333:368-370); D-CM-7's helper and D-CM-5's rule (classified
2026-10-27, RG-1: ALIGNED with gaps W-003 and W-132; p006333:193-198 makes
`carbon link` include the Core objects by default with an opt-out for a build
system that provides its own, which the helper does); the names, the touched
upstream lines, the harness directive, D-CM-6 and D-CM-9 (classified
2026-10-27, RG-1: NONE, W-355; upstream has no `CMAKE_Carbon` or
`carbon_add_*` name and no `BUILD-SCRIPT` directive, each 0 in its whole tree,
no upstream commit since the cut touches README.md or .gitignore, and its
driver writes no depfile; compile_subcommand.cpp:43-46's single-input TODO and
p006333:99-100's `carbon compile` are the driver's, which this branch does not
change).
```

<!-- google-doc-style-resume -->

**H60, PR 60 (claude/carbon-fork-0-1-sc at 40a76ab81),** fork/decision-log.md,
fork/inventory/work-items.json and docs/design/generics/template_constraints.md
(the page's note added at rev 2; amended 2026-10-28, review fold: A-M3, B-M4,
B-m1).

<!-- google-doc-style-ignore -->

```text
[fork/decision-log.md, new paragraph after :4202]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" on claude/carbon-fork-0-1-rg1, which lands first, and
fork/register/rg1-plan.md section 2.H9 have the quotes):_ `template
constraint` and its member requirements (classified 2026-10-27, RG-1: ALIGNED,
W-355; generics/details.md:1072-1073 "use the `template` keyword before
`constraint`" and :5494); the structural vector, the look-through and
`new_specific_id` (classified 2026-10-27, RG-1: NONE, W-355; internal:
upstream's sem_ir/named_constraint.h has no `is_template` and its check has no
`new_specific_id`, each 0, and its `CalleeCppOverloadSet` arms have no
look-through); D-SC-6 (classified 2026-10-27, RG-1: DRIFT, W-139): its break
condition was already met when W-139 was filed, since
generics/overview.md:375-379 records "We have decided to support passing a
symbolic constant to a template parameter" (leads issue 2153) and
appendix-witness.md:151-154 that the approach "relies on monomorphization",
text that predates the cut; SC-1 realigns the definition-time rejection by a
new commit on this branch before it lands (R32 (e)), with
docs/design/generics/template_constraints.md's paragraph that calls issue 2153
"upstream's open question", which now carries a dated note; W-140 follows
W-139.

[fork/inventory/work-items.json, W-139's "notes": append]
 Classified 2026-10-27 by RG-1 (upstream f27a977d8, re-checked at <tip>; the
RG-1 decision-log entry on claude/carbon-fork-0-1-rg1): a drift under R32 (d).
This item's break condition was already met when it was filed:
docs/design/generics/overview.md:375-379 ("We have decided to support passing a
symbolic constant to a template parameter", leads issue 2153) and
appendix-witness.md:151-154 ("decided in issue #2153, relies on
monomorphization") were last touched no later than 7134e23f2 (2026-09-29), an
ancestor of the cut; upstream's check/call.cpp:387-388 wraps symbolic template
arguments in a `TemplateInst`. Owner SC-1: a new commit on PR 60's branch
before PR 60 lands (R32 (e)) defers the structural check of a checked-symbolic
self to each specific, with its goldens and fills, and rewrites
docs/design/generics/template_constraints.md:456-468, which calls issue 2153
"upstream's open question" (RG-1's dated note follows it); scheduled in
ORCHESTRATION's Next actions before UA-3.

[docs/design/generics/template_constraints.md, after :468 and a blank line]
> **RG-1 note (2026-10-27).** Upstream records leads issue 2153 as decided, not
> open: "We have decided to support passing a symbolic constant to a template
> parameter" (upstream docs/design/generics/overview.md:375-379), an approach
> that "relies on monomorphization" (appendix-witness.md:151-154). The
> definition-time rejection described above is therefore a drift under the
> fork's rulebook R32 (d), W-139, which SC-1 realigns on this branch before it
> lands; this paragraph is rewritten with it.
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
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" on claude/carbon-fork-0-1-rg1, which lands first, and
fork/register/rg1-plan.md section 2.H4 have the quotes):_ `Core.StringBuf`
(classified 2026-10-27, RG-1: NONE, W-355; README.md:622 "This is provisional,
no design for string types has been through the" proposal process, so the
owning name is undecided). The view's name is decided upstream: README.md:3706
and interoperability/README.md:260-261 map `std::string_view` to `Core.Str`,
p006177:147-148 chose `Str` "for the non-owning view type", and
sem_ir/type_info.h:382 carries "TODO: Rename `Core.String` to `Core.Str`.";
upstream's prelude still spells it `Core.String`, so this branch keeping that
class follows upstream's current spelling and D-ST-4's rejected early rename is
not a divergence; when the TODO lands, the view becomes `Core.Str` at that
advance and `StringBuf` takes README.md:627's owning name (D-ST-4's break
condition). `+` on strings (classified 2026-10-27, RG-1: NONE, W-355;
arithmetic.md:186-187 leaves issue 457 a TODO); the edited and inserted lines,
the null check and the three goldens' merge rules (classified 2026-10-27, RG-1:
NONE, W-355; no upstream commit since the cut touches
core/prelude/types/string.carbon, four touch operators.carbon, and upstream's
export.cpp:402-404 still has no null check where its other callers at :538,
:914 and :2077 do).
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
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" on claude/carbon-fork-0-1-rg1, which lands first, and
fork/register/rg1-plan.md section 2.H5 have the quotes):_ the comparisons'
`T.Copy` and `T.Destroy` (classified 2026-10-27, RG-1: DRIFT, W-352):
comparison_operators.md:315-316 and :433-434 say these operations "should have
no observable side-effects", so OP-1 realigns them by a new commit on this
branch before it lands (R32 (e)), comparing the held payloads in place over
value-bound storage with no `Copy` or `Destroy` per operand, a route RG-1's
read-only probe showed checks on PR 57's install (rg1-plan.md section 4.8 and
D-RG-10); OP-1 owns the closure, which W-344 had given to DR-1; `None()`
(classified 2026-10-27, RG-1: ALIGNED with upstream's
core/prelude/types/optional.carbon:30 `fn None() -> Self`, the pattern being
W-320's); the replaced lines, `final` and F-015 itself (classified 2026-10-27,
RG-1: NONE, W-355; optional.carbon:27-28 "The API here is a placeholder", no
upstream commit since the cut touches optional.carbon, and it has no `EqWith`
or `OrderedWith` impl); the TY4 statement (classified 2026-10-27, RG-1: NONE,
W-355; between two fork designs, `TY4` 0 in upstream's docs and proposals).
```

<!-- google-doc-style-resume -->

**H57, PR 57 (claude/carbon-fork-0-1-op2 at a080c7886).** `git merge --no-ff
<H56's final head>` with the message of A.10, made at D-RG-13 step 5; the OP-1
block's copy at :4460-4472 takes H56's text; no other file changes; no OP-2
note (D-RG-11). OP-1's later W-352 commit on PR 56 is merged into PR 57 the
same way by OP-1.

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
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" on claude/carbon-fork-0-1-rg1, which lands first, and
fork/register/rg1-plan.md section 2.H10 have the quotes):_ (iii) (classified
2026-10-27, RG-1: ALIGNED at the tip, W-355: upstream README.md:872-874 writes
the type `array(T, N)` as "a shorthand for the library type
`Core.Array(T, N)`", whose prelude class adapts the builtin the arm handles,
core/prelude/types/array.carbon:13-14; UA-3 absorbs 947c1eb52 under the merge
rule and re-measures W-253), (v) and (vi) (classified 2026-10-27, RG-1:
ALIGNED with gaps, p002200:200-206; W-268, W-260 to W-262 and W-266); (i),
(ii), (iv), (vii) and (viii) (classified 2026-10-27, RG-1: NONE, W-355;
internal surfaces and fixes with their merge rules: none of (i)'s five names is
in upstream's toolchain, and one upstream commit since the cut touches
lower/handle.cpp and none deduce_class_args.carbon; W-258 and W-250).
```

<!-- google-doc-style-resume -->

**H64 and H64m, PR 64 (claude/carbon-fork-0-1-ct at 4a3220c11).** H64 first, on
4a3220c11 itself, fork/decision-log.md; then H64m, `git merge --no-ff <H61's
final head>` at D-RG-13 step 5, the TP-1 block's copy at :4185-4208 taking
H61's text (amended 2026-10-28, review fold: B-m2):

<!-- google-doc-style-ignore -->

```text
[replace, :8342]
nine of plan §0.10, with their merge rules. Veto-able.
[with]
ten of plan §0.10 (the tenth, `SpecificConstant`'s category, added at plan rev
4, RR2-M1; counted 2026-10-27 by RG-1), with their merge rules. Veto-able.

[new paragraph after :8342]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" on claude/carbon-fork-0-1-rg1, which lands first, and
fork/register/rg1-plan.md section 2.H11 have the quotes):_
`NamesTemplateBinding`, the deferral of C++ calls on symbolic arguments (F-021)
and the per-specific alias check (classified 2026-10-27, RG-1: ALIGNED, W-355;
p002200:205-209, generics/overview.md:375-379 and appendix-witness.md:151-154);
the other seven (classified 2026-10-27, RG-1: NONE, W-355; fixes to upstream
code and golden edits with their merge rules: upstream's subst.cpp has no
`MetaInstId` case, its check/cpp no `TSK_ImplicitInstantiation`, its toolchain
no `DiscardGenericDeclIntoEnclosingGeneric`, and its `SpecificConstant` keeps
`ComputedExprCategory::SameAsFirstOperand`, sem_ir/typed_insts.h:2013).
```

<!-- google-doc-style-resume -->

**Land-time notes (D-RG-11), not committed now.** Added by each PR's
land-sequence records commit after its block, scheduled at R1 in
ORCHESTRATION's Next actions (A.8; amended 2026-10-28, review fold: A-M1, B-M2):

<!-- google-doc-style-ignore -->

```text
[UA-2, PR 51, after its :6232]
_RG-1 (classified 2026-10-27, upstream f27a977d8, re-checked at <tip>; the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" has the quotes):_ the SL-1 trigger statement above (classified
2026-10-27, RG-1: DRIFT, W-354): at upstream's tip
`fn SelfDestruct[T: Destroy](ref t: T)` calls `t.(DestroyImpl.Op)();`
(core/prelude/destroy.carbon:36-38) for every cleanup, locals included
(check/control_flow.cpp:158), so the trigger is met for locals too and W-354
drops D-SL-16's yield and D-SL-19's keying at the advance that brings
05a7ecbd3; this branch is not amended for it, since the yield is trunk's code.

[EV-1, PR 54, after its :3549]
_RG-1 (classified 2026-10-27, ...):_ the guides, their content and the touched
lines (classified 2026-10-27, RG-1: NONE, W-355; upstream's docs/guides lists
two entries, README.md and glossary.md, none says tutorial, and no upstream
commit since the cut touches README.md, docs/project/faq.md or
docs/guides/README.md); the tutorial's `Ok`/`Err` are renamed by W-346 after
the held PRs land.

[OP-2, PR 57, after its :3792]
_RG-1 (classified 2026-10-27, ...):_ the adapter arms (classified 2026-10-27,
RG-1: ALIGNED, W-355; upstream custom_witness.cpp:466-467 "TODO: Handle
destruction of adapters generally by destroying the adapted type.");
`UnformedInit` for `Optional(T*)` only (classified 2026-10-27, RG-1: ALIGNED
with W-200's gap, p000257:274); the two fixes, which upstream f27a977d8 still
needs (lower/handle.cpp:77, convert.cpp:1564-1567), the replaced lines, W-196
and the row (classified 2026-10-27, RG-1: NONE, W-355; no upstream commit since
the cut touches optional.carbon, whose text has no triviality rule).

[DD-1, PR 58, after its :4129]
_RG-1 (classified 2026-10-27, ...):_ the guard parentheses (classified
2026-10-27, RG-1: ALIGNED, W-355, with upstream's parser,
parse/handle_match.cpp:169 and :176, where pattern_matching.md:803 omits them);
the nine documented gaps (classified 2026-10-27, RG-1: ALIGNED with gaps, each
item's); the convention, the new pages, the measured-behavior rule and the
constant-value alias (classified 2026-10-27, RG-1: NONE, W-355; upstream's docs
have no "Fork amendment" convention, its interoperability/ lists four entries,
and p003938:82 says "`alias` is not fully designed").

[VA-1, PR 59, after its :3630]
_RG-1 (classified 2026-10-27, ...):_ (i) (classified 2026-10-27, RG-1:
ALIGNED, W-355; variadics.md:47-48 and :92 make `each` a keyword), (ii)'s
`(... x)` tuple (classified 2026-10-27, RG-1: ALIGNED, W-355; variadics.md
:137-139 "they will be interpreted as forming a tuple rather than as
grouping") and (vi) (classified 2026-10-27, RG-1: ALIGNED, W-355; upstream's
commits); (ii)'s parse kinds, (iv), (v) and (vii) (classified 2026-10-27,
RG-1: NONE, W-355; internal and merge rules: none of the parse kinds is in
upstream's parse, none of the eight instructions in its inst_kind.def, and
two upstream commits since the cut touch pack_expansion.carbon and one
handle_pack_expansion.cpp); (iii) (classified 2026-10-27, RG-1: NONE, W-230
watches it).
```

<!-- google-doc-style-resume -->

In these five "..." stands for the full lead of EV-1's, which is UA-2's.

### A.5 The eleven work items (R1; appended after W-344)

W-346 to W-351 as at rev 1 with their notes amended; W-352 rewritten; W-353 to
W-356 new (amended 2026-10-28, review fold: A-M1, A-M2, A-m1, A-m3, B-M2, B-M3,
B-m3, B-m4, B-m9). `<tip>` is filled as in section 3.1. The text below parses
as JSON when wrapped in brackets (section 4.1).

<!-- google-doc-style-ignore -->

```json
    {
      "id": "W-346",
      "kind": "missing-feature",
      "title": "EH-C (R32 (d); RG-1, D-RG-5): `Core.Result(T, E)`'s alternatives are spelled `Ok`/`Err` where upstream's README spells a result choice's `Success`/`Failure` -- rename them, with every use, after the held PRs land and before UA-3",
      "subsystem": "core/prelude (types/result.carbon) + toolchain/lower (the entry-point epilogue) + toolchain/install (carbon/expected.h) + docs/design + testdata and conformance programs",
      "size": "M",
      "bullet": "Error handling: dedicated control flow constructs",
      "evidence": [
        "upstream docs/design/README.md:3856-3860 at f27a977d8 (\"### Error handling\" ... \"At this point, errors are represented using [choice types](#choice-types) like `Result` and `Optional`.\"), the statement about the mechanism; the linked choice-types section :2167-2177 (`choice IntResult` with `Success(value: i32)` and `Failure(error: String)`); corroborating, under \"Generic choice types\", :3159-3166 (`choice Result(T: type, Error: type)` with `Success(value: T)` and `Failure(error: Error)`); proposals/p000157-design-direction-for-sum-types.md:690-692 spells the same but is provisional by its :228-229",
        "core/prelude/types/result.carbon:28-31 at trunk 0b999d449 (`choice Result(T: type, E: type)` with `Ok(value: T)` and `Err(error: E)`); fork/decision-log.md F-006a (:716-718 at 0b999d449, \"Sub-decision F-006a (user, 2026-07-19): variant naming is `Ok`/`Err`\") and V-3 (:38-41)",
        "lines naming `Ok` or `Err` that the held heads add (fork/register/rg1-plan.md section 4.6): PR 54 18, PR 56 2 (carried by PR 57), PR 62 4, PR 63 1 (carried by PR 65); fork/gap-analysis.md:68's example `case .Ok(v: i32)` at 0b999d449",
        "fork/register/rg1-plan.md D-RG-5 and section 2.T2; fork/rulebook.md R32 (a), (b), (d)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8, re-checked at <tip>), deciding F-006a under R29 (D-RG-5): upstream's README names `Result` as the choice that represents errors, in a statement about error handling that links the choice-types section, whose result choice spells its alternatives `Success` and `Failure`; no upstream text spells `Ok` or `Err` or marks that spelling as placeholder, so F-006a's spelling, which V-3 let override the README as illustrative, is a second spelling under R32 (d) now that V-3b withdrew the override. This reverses the user's sub-decision F-006a (2026-07-19) under the owner directive of 2026-10-21 (\"Direction drifts are not permitted\"); the user may veto it after the fact. Work: rename `Ok` to `Success` and `Err` to `Failure` (the payload names `value` and `error` and the order, `Success` = 0, already match) with every use: the prelude's `Try` impl, the entry-point exit-code epilogue, `<carbon/expected.h>`'s comments, docs/design/error_handling.md and the pages that teach it, goldens by autoupdate (never by hand), conformance programs; the type parameter `E` may stay. Owner: EH-C, the `Core.Result` realignment (EH-A's successor), on trunk's base after the held PRs land (PR 54, PR 56, PR 62 and PR 63 add uses it renames, carried by PR 57 and PR 65; D-RG-8) and before UA-3, beside OV-4's W-341. Break condition: upstream adds a prelude `Result` or accepts an error-handling proposal that spells the alternatives otherwise (take that spelling), or changes the README's examples to `Ok`/`Err` (withdraw this item as ALIGNED), or the user vetoes the reversal (withdraw it and record the veto against R32)."
    },
    {
      "id": "W-347",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-8 narrows p005434:83's `nocapture` and `noalias` on every `ref` binding to exclusive-kind refs -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: temporal_safety.md, mutation_safety.md) + docs/design/values.md + PR 53's F-013 entry",
      "size": "M",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md:83 at f27a977d8: \"The address of a `ref` binding is `nocapture` and `noalias`.\"",
        "PR 53 (claude/carbon-fork-0-1-safe, adaae4e35) fork/decision-log.md D-SAFE-8 (:3098-3125) and the register block (:3928-3929); the 13 dependent lines naming D-SAFE-8 on PR 53's docs (fork/register/rg1-plan.md D-RG-7's table)",
        "fork/register/rg1-plan.md section 2.H1 (H1.8)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). SAFE-1 dated this narrowing as a departure from accepted text; under V-3b it is a drift. Work: SAFE-1 re-derives D-SAFE-8 so that the design keeps p005434:83's rule for every `ref` binding (the shared-kind `ref` formed from a shared `T*` is then re-designed, for example as an `unsafe` formation or an exclusive one), with the dependent lines D-RG-7 lists, section 4's lists and the F-013 entry, by a new commit on PR 53's branch under SAFE-1's plan amendment, two document reviews and a fixer, before PR 53 lands (R32 (e)); W-348 and W-349 are re-derived with it where they interlock. Owner: SAFE-1. Break condition: an accepted upstream memory-safety proposal that narrows p005434:83 (cite it and close this item)."
    },
    {
      "id": "W-348",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-17 narrows p005434:663's plan to prevent mutation of borrowed objects in Strict (`Plain`-field writes through other shared aliases stay erroneous and Debug-detected) -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: mutation_safety.md, temporal_safety.md, rust_interop.md, README.md) + docs/design/values.md + PR 53's F-013 entry",
      "size": "M",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream p005434:660-664 at f27a977d8: \"Mutation of objects with a non-copy-value representation in an active value binding (\\\"borrowed objects\\\") is erroneous behavior.\" and \"Our plan is to prevent mutation of borrowed objects in Carbon's strict safe dialect.\"; :665-669 name when to relax it",
        "PR 53 fork/decision-log.md D-SAFE-17 (:3532-3568) and the register block (:3929); the 20 dependent lines naming D-SAFE-17 on PR 53's docs (fork/register/rg1-plan.md D-RG-7's table)",
        "fork/register/rg1-plan.md section 2.H1 (H1.9)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 re-derives D-SAFE-17 so that Strict prevents mutation of borrowed objects as p005434:663 plans (the eager-copy alternative D-SAFE-17 records is one route), with the dependent lines, the Rust mapping of D-SAFE-19 and the F-013 entry, by a new commit on PR 53's branch before it lands (R32 (e)), with W-347's review. Owner: SAFE-1. Break condition: upstream relaxes p005434:663 under its own :665-669 conditions."
    },
    {
      "id": "W-349",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-11(d) narrows p005434:831-832's \"immutable for the duration\" of a returned loan to \"not invalidated\" -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: temporal_safety.md, mutation_safety.md) + PR 53's F-013 entry",
      "size": "S",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream p005434:831-832 at f27a977d8: \"For full safety, we need each bound parameter to be immutable for the duration of the lifetime of the returned result.\"; :834 \"We will reconsider this with the memory safety design.\"",
        "PR 53 fork/decision-log.md D-SAFE-11(d) (:3297-3330) and the register block (:3929-3930); the 7 dependent lines naming D-SAFE-11 on PR 53's docs (fork/register/rg1-plan.md D-RG-7's table)",
        "fork/register/rg1-plan.md section 2.H1 (H1.10)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 re-derives D-SAFE-11(d) so that a bound argument stays immutable for a returned loan's duration, as p005434:831-832 states full safety needs, by a new commit on PR 53's branch before it lands (R32 (e)); it interlocks with W-348 (D-SAFE-11(d) is the D-SAFE-17 narrowing at a second site). Owner: SAFE-1. Break condition: upstream's memory-safety design reconsiders the rule (p005434:834) otherwise."
    },
    {
      "id": "W-350",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-15 withdraws arithmetic.md:156-158's performance-build row (overflow and division by zero are not defined there) for Carbon code -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/expressions/arithmetic.md (PR 53's amendment) + docs/design/safety (PR 53: spatial_safety.md) + PR 53's F-013 entry",
      "size": "S",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream docs/design/expressions/arithmetic.md:156-158 at f27a977d8: \"In a performance build, the optimizer can assume that such conditions don't occur. As a consequence, if they do, the behavior of the program is not defined.\"",
        "PR 53 fork/decision-log.md D-SAFE-15 (:3483-3495) and the register block (:3930-3931, which cites :155-158); the 8 dependent lines naming D-SAFE-15 on PR 53's docs (fork/register/rg1-plan.md D-RG-7's table)",
        "fork/register/rg1-plan.md section 2.H1 (H1.11)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 restores the performance-build row (Release keeps its wrapping and division fail-stop, the row describing the non-default performance build that safety/README.md:260-262 promises; W-351), and amends arithmetic.md's dated note, the dependent lines and the F-013 entry, by a new commit on PR 53's branch before it lands (R32 (e)). Owner: SAFE-1. Break condition: upstream withdraws or rewrites the row."
    },
    {
      "id": "W-351",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-14 withdraws safety/README.md:260-262's promise of an unsupported way to disable release hardening for benchmarking -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/safety (PR 53: README.md, spatial_safety.md) + docs/design/slices.md + PR 53's F-013 entry",
      "size": "S",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream docs/design/safety/README.md:260-262 at f27a977d8: \"Carbon will provide a way to disable the default hardening in release builds, but not in a supported way. Its use is expected to be strictly for benchmarking purposes.\"",
        "PR 53 fork/decision-log.md D-SAFE-14 (:3427-3482, SP4) and the register block (:3931-3932); the 5 dependent lines naming D-SAFE-14 on PR 53's docs (fork/register/rg1-plan.md D-RG-7's table)",
        "fork/register/rg1-plan.md section 2.H1 (H1.12)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343). Work: SAFE-1 keeps the promise (the per-site `unsafe fn GetUnchecked` stays as the supported opt-out, beside the unsupported build-level disable), amending the dependent lines and the F-013 entry by a new commit on PR 53's branch before it lands (R32 (e)); with W-350. Owner: SAFE-1. Break condition: upstream withdraws the promise."
    },
    {
      "id": "W-352",
      "kind": "missing-feature",
      "title": "OP-1 (R32 (b), (d), (e); RG-1, D-RG-10; W-344): `Core.Optional`'s comparisons copy and destroy each held payload (`T.Copy`, `T.Destroy`), where comparison_operators.md says comparisons \"should have no observable side-effects\" -- compare the payloads in place, by a new commit on PR 56 before it lands",
      "subsystem": "core/prelude/types/optional.carbon (PR 56's comparison impls; merged into PR 57) + their goldens",
      "size": "S",
      "bullet": "Stdlib: Optional",
      "evidence": [
        "upstream docs/design/expressions/comparison_operators.md:315-316 (`EqWith`: \"Additionally, these operations should have no observable side-effects.\") and :433-434 (\"the members of an `OrderedWith` implementation should have no observable side-effects.\") at f27a977d8",
        "PR 56 (claude/carbon-fork-0-1-op, 894139b34) core/prelude/types/optional.carbon:224 (`return self.Get() == other.Get();`) and fork/decision-log.md :3529-3541 (OP-1's block, D-OP-4's entry); PR 57 (a080c7886) :4460-4472",
        "RG-1's read-only probe (fork/register/rg1-plan.md section 4.8): over value-bound storage, `(a.value unsafe as T) == (b.value unsafe as T)` checks on PR 57's install with no `Copy.Op` and no `SelfDestruct` call, where the copying route emits one `Copy.Op` per operand and two `SelfDestruct` calls; a `ref` accessor cannot take the value-bound operands (\"value expression passed to reference parameter\") and `-> val` does not parse",
        "W-344 (the register entry); fork/register/rg1-plan.md section 2.H5 (H5.4) and D-RG-10"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8) from W-344's side-effects entry. Not blocked: D-OP-4's routes were W-320's `.Some` pattern (blocked on W-324) and a by-reference accessor; RG-1's probe shows a third route under OP-1's control, comparing in place through a separate private storage interface implemented for the default storage only, which avoids D-OP-4's objection that a new `OptionalStorage` member needs pointer equality (W-174): the comparison impls already require `T: Eq` or `T: Ordered`, which no pointer type satisfies until W-174. Work: OP-1 rewrites the comparison impls so that no `Copy` or `Destroy` of `T` runs per operand, signatures unchanged, with their goldens by autoupdate and fills, by a new commit on PR 56's branch under OP-1's review, merged into PR 57's, before PR 56 lands (R32 (e)); W-320's pattern may replace the route when it lands. Owner: OP-1, replacing W-344's \"DR-1, W-320's owner, for the closure\". Break condition: OP-1 shows the in-place route cannot keep D-OP-4's frozen signatures or F-015's API (then this item gains blocked_by W-320 and PR 56 waits for W-320; it does not land with the drift)."
    },
    {
      "id": "W-353",
      "kind": "design-needed",
      "title": "SAFE-1 (R32 (d), (e); RG-1): D-SAFE-13 I5 promotes zero-fill to the Release baseline for every type with no separate hardened mode, where upstream lets types define additional initialization for the hardened build mode -- realign by a new commit on PR 53 before it lands",
      "subsystem": "docs/design/README.md (PR 53's amendment :2151-2153) + docs/design/safety (PR 53: initialization_safety.md, temporal_safety.md, rust_interop.md) + PR 53's F-013 entry",
      "size": "M",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "upstream docs/design/README.md:2130-2132 at f27a977d8: \"Types may define additional initialization for the [hardened build mode](#build-modes). For example, this causes integers to be set to `0` when in unformed state in this mode.\"; docs/design/safety/README.md:242 and :248-250 (\"Release + specialized [hardening]: ... Carbon will have several specialized build modes in this space.\"); :219 (the release baseline of hardening); proposals/p005914-updating-carbon-s-safety-strategy.md:87-88 (\"allows, for example, zero-initialization rather than fail-stop behavior.\")",
        "PR 53 docs/design/README.md:2151-2153 (\"The fork promotes this zeroing to the Release baseline for every type; there is no separate hardened mode.\"), fork/decision-log.md D-SAFE-13 and the register block (:3932-3933, which cites the branch's own :2147); the 13 dependent lines naming D-SAFE-13 on PR 53's docs (fork/register/rg1-plan.md D-RG-7's table)",
        "fork/register/rg1-plan.md section 2.H1 (H1.13)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8; W-343; review fold B-M3 of the RG-1 plan). SAFE-1's own register block lists this promotion among its departures from accepted text. Work: SAFE-1 re-derives D-SAFE-13 I5 so that the extra initialization is type-defined and lives in a hardened mode extending Release, as README.md:2130-2132 and safety/README.md:248-250 state, keeping in the Release baseline only what the memory-safety model needs (safety/README.md:219) and stating how initialization errors avoid undefined behavior there (p005914:87-88), with the dependent lines and the F-013 entry, by a new commit on PR 53's branch before it lands (R32 (e)), with W-347's review. Owner: SAFE-1. Break condition: an accepted upstream memory-safety design that puts unformed-state zeroing in the Release baseline for every type (cite it and close this item)."
    },
    {
      "id": "W-354",
      "kind": "infra",
      "title": "UA-3 (R32 (b), (d); RG-1, D-RG-16): at the advance that brings 05a7ecbd3, drop D-SL-16's declared-impl yield and D-SL-19's class keying of `HasUserDestroyImpl` in favor of upstream's `SelfDestruct`, which calls the declared `DestroyImpl.Op` for every cleanup",
      "subsystem": "toolchain/check (custom_witness.cpp `CanDestroyClass`, the `HasClassKeyedImpl` scan, class.cpp's triviality predicate, C++ export triviality) + core/prelude (declared `impl as Destroy` spellings, as the merge requires)",
      "size": "M",
      "bullet": "Stdlib: Slices",
      "evidence": [
        "upstream core/prelude/destroy.carbon at f27a977d8: :14 \"// TODO: rename to `Destroy` when `require impls` adds a witness table entry.\", :23-24 the blanket `impl forall [T: SubobjectDestroy] T as DestroyImpl` with `fn Op(ref self) = \"no_op\";`, :27-28 `constraint Destroy`, :36-38 `fn SelfDestruct[T: Destroy](ref t: T)` calling `t.(DestroyImpl.Op)();` and `t.(SubobjectDestroy.Op)();` (05a7ecbd3, upstream PR 7942)",
        "upstream toolchain/check/control_flow.cpp:158 (`BuildSelfDestructCall(context, destroy_id);` for every cleanup) and check/custom_witness.cpp:1054 (the custom witness serves `SubobjectDestroy` only); upstream lower/testdata/var/destroy_control_flow.carbon:18 and :187-188 (a declared `impl as Core.DestroyImpl` called from `_CSelfDestruct`)",
        "fork/decision-log.md SL-1's register block (:4421-4432 at trunk 0b999d449: \"if upstream's destroy-op synthesis starts calling declared impls, D-SL-16's yield and D-SL-19's keying are dropped in favor of it\"), D-SL-16 (from :4158) and D-SL-19 (from :4221); PR 51 (claude/carbon-fork-0-1-ua2, f96fe8a7a) fork/decision-log.md :6226-6232 (the trigger met for fields)",
        "fork/register/rg1-plan.md D-RG-16 and section 2 (T5.6, T5.9, H12.1)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (upstream f27a977d8, re-checked at <tip>; review folds A-M1 and B-m9 of the RG-1 plan). SL-1's own break condition for D-SL-16 and D-SL-19 is met at upstream's tip for locals as well as fields, so the fork's yield is a second mechanism for what upstream's `SelfDestruct` does (R32 (d)). The fork's declared-destructor spelling `impl as Destroy` (trunk's buf.carbon, PR 55's `StringBuf`, PR 57's `DefaultOptionalStorage`) is ALIGNED with destroy.carbon:14's TODO; at the advance the declarations take upstream's interim `DestroyImpl` spelling only as far as the merged prelude requires. Work: at the advance that brings 05a7ecbd3 (UA-3), remove the `CanDestroyClass` yield and the class keying, let impl selection find the declared `DestroyImpl` impl over the blanket `no_op` one, re-measure lower/slice/buf.carbon's three `free` calls and the union and export triviality goldens by autoupdate, and record the result in SL-1's records. It cannot precede the advance: the fork's tree at the cut has no `DestroyImpl`. Owner: UA-3, with SL-1's records; in UA-3's gate. Break condition: upstream reverts 05a7ecbd3, or its `SelfDestruct` stops calling `DestroyImpl.Op` (then the entries return to NONE and this item is withdrawn)."
    },
    {
      "id": "W-355",
      "kind": "infra",
      "title": "Weekly upstream check (R32 (b); RG-1, D-RG-17): the V-3a register's NONE and ALIGNED entries, each classified by RG-1 with its break condition -- re-run RG-1's quote and silence checks at each new tip and file a fired break condition as its own drift item",
      "subsystem": "fork records (fork/decision-log.md register blocks; fork/register/rg1-plan.md section 4.2's checks)",
      "size": "S",
      "bullet": "none",
      "evidence": [
        "fork/register/rg1-plan.md section 2: 136 NONE and ALIGNED entries in 23 blocks and V-3's design-fork group, each with its break condition; section 4.2's quotes_rev2.tsv (230 quotes) and checks.tsv (89 silence checks) with check_quotes.sh and check_greps.sh",
        "fork/rulebook.md R32 (b): \"the V-3a register is a work queue reviewed at each weekly check, each entry carrying its work item\"; the 2026-10-26 weekly check's finding that no pre-DR-0 entry carried one (W-342)"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (review fold B-M2 of the RG-1 plan). A standing item: every NONE and ALIGNED register entry carries it (the blocks' RG-1 notes name it), so the register stays a work queue under R32 (b). Work, at each weekly upstream check: fetch the tip, run check_quotes.sh and check_greps.sh against it, re-read each NONE and ALIGNED entry's break condition against the window's design-page and prelude-signature commits (R32 (c)), and for each fired condition file a DRIFT item owned by the entry's workstream, scheduled before UA-3, with a dated note in the block. An L check's FAIL (an upstream commit to a merge-rule file) is the merge rule's signal and updates the expected count. Owner: the weekly upstream check. Break condition: an owner ruling that a classified NONE leaves the register (then this item narrows to the ALIGNED entries); it is discharged only if the register is retired."
    },
    {
      "id": "W-356",
      "kind": "toolchain-defect",
      "title": "Toolchain crash found by RG-1's probe: a value expression passed to a `ref` parameter of a generic function inside a `return` expression stops at check/pattern_match.cpp:2207's `CHECK` `std::holds_alternative<CalleeState*>(state)` after the diagnostic, on trunk's toolchain and PR 57's; the nightly 2026.10.12 diagnoses and exits 1",
      "subsystem": "toolchain/check (pattern_match.cpp)",
      "size": "S",
      "bullet": "Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation",
      "evidence": [
        "fork/register/rg1-plan.md section 4.8's refget.carbon: `fn GetRef[T: Core.Copy & Core.Destroy](ref s: Store(T)) -> ref T` called as `GetRef(ref a) == GetRef(ref b)` with value-bound `a` and `b`; /home/user/carbon-build/carbon-trunk (0.0.0-0.dev+0bdce60a5) and carbon-op2 (0.0.0-0.dev+9f9ccd768) print \"error: value expression passed to reference parameter\" then \"CHECK failure at .../toolchain/check/pattern_match.cpp:2207: std::holds_alternative<CalleeState*>(state)\", exit 134",
        "the nightly 2026.10.12 (0.0.0-0.nightly.2026.10.12+62f1cc6) reports the error for both operands and exits 1"
      ],
      "blocked_by": [],
      "notes": "Filed 2026-10-27 by RG-1 (D-RG-18), found while testing D-OP-4's accessor route for W-352; not fixed by RG-1, a records workstream. The nightly is upstream after the cut, so the crash is either an upstream defect at the cut fixed later or a fork regression. Work: at the advance UA-3, re-run the probe on the advanced trunk; if it still stops at the CHECK, bisect the fork commits on the stack's first fork frame and re-assign this item to that frame's workstream. Owner: UA-3 (triage). Break condition: the advance's re-run diagnoses cleanly (discharge with that run's output)."
    }
```

<!-- google-doc-style-resume -->

### A.6 The ledger's other R1 edits

<!-- google-doc-style-ignore -->

```text
[W-342 "notes": prepend]
DISCHARGED 2026-10-27 by RG-1's records (R1; fork/register/rg1-plan.md):
every entry of trunk's eleven pre-DR-0 blocks and V-3's design-fork group is
classified against upstream f27a977d8, re-checked at <tip>, in the
decision-log entry "RG-1: the V-3a register classified at f27a977d8
(2026-10-27)" and in each block's dated note: each DRIFT with its item
(F-006a's `Ok`/`Err` filed as W-346; SL-1's D-SL-16 and D-SL-19 as W-354;
D-SL-17 is W-326's, D-SL-3 W-109's), each ALIGNED with its quote, and each
NONE with the quote of the nearest upstream passage or a silence check of
rg1-plan.md section 4.2, named in the note by row with its grep and result;
both of section 4.2's scripts passed at R1's tip ("checked 230 quotes, 0
failed"; "checked 89 silence checks, 0 failed"); every NONE and ALIGNED
entry carries W-355; F-009's `overload fn` is NONE (D-RG-6). Original filing:

[W-343 "notes": append]
 Narrowed 2026-10-27 by RG-1's records (R1): the held blocks are classified in
the RG-1 decision-log entry; SAFE-1's six departures are W-347 to W-351 and
W-353, realigned by SAFE-1 on PR 53 before it lands, SC-1's D-SC-6 is W-139's
drift on PR 60, and PR 51's UA-2 statement is W-354's; the records commits on
PR 53, PR 52, PR 60, PR 55, PR 61 and PR 64 follow, R2 records them, and the
land-time notes of PR 51, PR 54, PR 57 (OP-2), PR 58 and PR 59, scheduled in
ORCHESTRATION, discharge this item with the last of them.

[W-344 "notes": append]
 Narrowed 2026-10-27 by RG-1's records (R1): the side-effects entry is filed as
W-352, owner OP-1, not blocked (RG-1's probe shows an in-place route), a code
commit on PR 56 before it lands; OP-1 replaces DR-1 as the owner of the
closure named above; the `None` entry stays W-320's; the cites' correction by
a new commit on PR 56, merged into PR 57, follows, and R2 discharges this item.

[top-level "source": append]
 Updated 2026-10-27 by the RG-1 records (the V-3a register classified at
upstream f27a977d8, R32 (b)): W-346..W-356 added (F-006a's `Ok`/`Err` for
EH-C; SAFE-1's six departures from accepted text; OP-1's comparisons' side
effects; D-SL-16's yield and D-SL-19's keying for UA-3; the register watch
item; a crash RG-1's probe found) -- ids from RG-1's reservation W-346..W-359
after a re-scan of 136 origin refs', 25 local branches' and 21 worktrees'
ledgers found none above W-345; W-357..W-359 reserved and unused; W-342
discharged, W-343 and W-344 narrowed.
```

<!-- google-doc-style-resume -->

The JSON strings hold these texts on one line each (no line breaks inside a
string), with the leading space where shown. If either script of section 4.2
fails at R1's tip, W-342 is narrowed, not discharged, until the plan is amended
and the scripts pass (amended 2026-10-28, review fold: B-B1).

### A.7 The ledger's R2 edits

<!-- google-doc-style-ignore -->

```text
[W-343 "notes": append]
 Narrowed again 2026-10-27 by RG-1's stamp (R2): the held records commits are
made (PR 53 <sha53>, PR 52 <sha52>, PR 60 <sha60>, PR 55 <sha55>, PR 61
<sha61>, PR 64 <sha64> and <sha64m>); the drifts are W-347 to W-351 and W-353
(SAFE-1, before PR 53 lands) and W-139 (SC-1, before PR 60 lands). Open: the
land-time notes of PR 51, PR 54, PR 57 (OP-2), PR 58 and PR 59; the last of
them discharges this item.

[W-344 "notes": prepend]
DISCHARGED 2026-10-27 by RG-1's stamp (R2): the cites are corrected on PR 56
(<sha56>) and merged into PR 57 (<sha57>); the side-effects entry is W-352,
owner OP-1, a code commit on PR 56 before it lands. Original filing:
```

<!-- google-doc-style-resume -->

### A.8 ORCHESTRATION at R1

**The "Last updated:" line (:13).** "Last updated: 2026-10-27 (VA-2, ..."
becomes "Last updated: 2026-10-27 (RG-1's records classify the V-3a register at
upstream f27a977d8: 155 entries, 19 DRIFT, 34 ALIGNED, 102 NONE; W-346 to W-356
filed; see the paragraph dated 2026-10-27 (RG-1) below; the earlier 2026-10-27
text follows). 2026-10-27 (VA-2, ..." with the rest unchanged.

**The Branches row**, after `claude/carbon-fork-0-1-va2`'s (:945):

<!-- google-doc-style-ignore -->

```text
| `claude/carbon-fork-0-1-rg1` | RG-1 records, the V-3a register classified at upstream f27a977d8 (W-342 discharged; W-343 and W-344 narrowed, W-344 discharged at R2, W-343 by the last land-time note), base trunk 0b999d449: plan fork/register/rg1-plan.md; R1 files W-346 (EH-C), W-347 to W-351 and W-353 (SAFE-1, PR 53), W-352 (OP-1, PR 56), W-354 and W-356 (UA-3) and W-355 (the weekly check); the held records commits on PR 53, 52, 60, 55, 56 (merged into 57), 61 and 64 (with 61 merged) follow after two implementation reviews; to be held open as its PR after R2, first in the land sequence. |
```

<!-- google-doc-style-resume -->

**The dated paragraph**, after the paragraph that opens "2026-10-27 (21:24 UTC):
VA-2 is IMPLEMENTED" (:563) and ends "Next: OV-4 (W-341) and RG-1 (W-342..W-344)
per item 6 below, then UA-3." (:596):

<!-- google-doc-style-ignore -->

```text
Later on 2026-10-27 (RG-1): the V-3a register is classified at upstream
f27a977d8 (2026-10-27, upstream PR 8045; re-checked at <tip>), records first,
on claude/carbon-fork-0-1-rg1 (decision-log entry "RG-1: the V-3a register
classified at f27a977d8 (2026-10-27)"; fork/register/rg1-plan.md). Every entry
of the 26 blocks and V-3's design-fork entries was read against the page at
the tip: 155 entries, 19 DRIFT, 34 ALIGNED, 102 NONE, 10 waiting on upstream;
every NONE carries its quote or silence check, and every NONE and ALIGNED the
watch item W-355. F-006a's `Ok`/`Err` is a drift against README.md's
`Success`/`Failure` (W-346, owner EH-C, after the held PRs land and before
UA-3, reversing the user's F-006a under the 2026-10-21 directive, veto-able);
F-009's `overload fn` is not (p002875 calls its spelling placeholder). Three
held PRs carry drifts and wait for their owners' realignment commits before
they land: PR 53 six (W-347 to W-351 and W-353, owner SAFE-1), PR 60 one
(D-SC-6, W-139, whose break condition was already met when it was filed), and
PR 56 one (the comparisons' side effects, W-352, owner OP-1, not blocked).
D-SL-16's yield and D-SL-19's keying are W-354, dropped at UA-3 against
05a7ecbd3's `SelfDestruct`; W-356 is a crash RG-1's probe found, UA-3's to
triage. RG-1's held records commits follow on PR 53, PR 52, PR 60, PR 55, PR
56 (merged into PR 57), PR 61 and PR 64 (with PR 61's merged), staged and
reviewed before any push, then the stamp R2. No build, merge or dispatch;
Actions is still disabled. Sixteen PRs are held open; none is merged.
```

<!-- google-doc-style-resume -->

**Next actions item 6** becomes (amended 2026-10-28, review fold: A-M5, B-M2,
B-m6):

<!-- google-doc-style-ignore -->

```text
6.  **R32 work from the 2026-10-26 weekly check and RG-1 (2026-10-27)**: W-341
    (OV-4: an `overload fn` member with Carbon default parameter values called
    with a defaulted argument omitted; the arity step and the overload probe
    follow `default_value_arity`, and F-009j is rewritten) after VA-2 lands and
    before UA-3, on trunk's base. RG-1 (W-342 discharged; W-344 at its stamp;
    W-343 by the last land-time note) classified the V-3a register at upstream
    f27a977d8; RG-1's own PR lands first. Its drifts, each before the PR that
    carries it lands: W-347 to W-351 and W-353 (SAFE-1: a plan amendment of
    fork/safe/plan.md, a re-derivation commit on PR 53's branch, two document
    reviews and a fixer, before PR 53 lands; the land sequence waits at PR 53
    until then), W-139 (SC-1: a fix commit on PR 60's branch with its fills
    and the template_constraints.md paragraph, under its own reviews, before
    PR 60 lands) and W-352 (OP-1: the in-place comparison commit on PR 56's
    branch with its fills, merged into PR 57's, under its own reviews, before
    PR 56 lands). After the held PRs land and before UA-3: W-346 (EH-C:
    `Core.Result`'s `Success`/`Failure`, on trunk's base, beside W-341). In
    UA-3's gate, because they need the advance: W-354 (drop D-SL-16's yield
    and D-SL-19's keying against 05a7ecbd3) and W-356 (re-run RG-1's crash
    probe). Land-time notes, each by its PR's land-sequence records commit
    after its register block (fork/register/rg1-plan.md Appendix A.4): PR 51,
    PR 54, PR 57's OP-2 block, PR 58 and PR 59; the last discharges W-343. At
    each weekly upstream check: W-355 (re-run RG-1's two scripts at the tip
    and re-read every NONE and ALIGNED entry's break condition), with W-324's
    re-check of C1.1. UA-3 follows W-341 and W-346.
```

<!-- google-doc-style-resume -->

### A.9 ORCHESTRATION at R2

In the Branches rows of `claude/carbon-fork-0-1-safe`, `-cmake`, `-sc`, `-st`,
`-op`, `-op2`, `-tp` and `-ct`, the head becomes the new one and the row gains
"; amended 2026-10-27 by RG-1's records commit <sha> (R32 (e)), the description
refreshed" (for op2: "by RG-1's merge <sha57> of PR 56's commit"; for ct: "by
RG-1's count correction <sha64> and its merge <sha64m> of PR 61's commit"). The
rg1 row's last clause becomes "R1 and R2 made; to be held open as its PR, first
in the land sequence." A sentence is appended to the RG-1 dated paragraph: "R2
(date): the held commits are made after two implementation reviews and
recorded; W-344 is discharged and W-343 waits on the five land-time notes."

### A.10 The held commits' messages (bodies)

<!-- google-doc-style-ignore -->

```text
H53  SAFE-1 records: six departures from accepted text filed as drifts W-347 to W-351 and W-353, the README and arithmetic cites corrected (RG-1; R32 (a), (b), (e))

A new commit on PR 53's branch, never a rewrite (R32 (e)), from RG-1's
classification at upstream f27a977d8 (fork/register/rg1-plan.md on
claude/carbon-fork-0-1-rg1, section 2.H1): the register block's departures at
p005434:83, :663 and :831-832, arithmetic.md:156-158, safety
README.md:260-262 and the zero-fill promotion against README.md:2130-2132 are
drifts under V-3b, filed on claude/carbon-fork-0-1-rg1 as W-347 to W-351 and
W-353 and realigned by SAFE-1 by a new commit here before this PR lands; the
zero-fill cite now names upstream's README.md:2130-2132 instead of this
branch's copy, and arithmetic.md's range is upstream's :156-158. Records only.

H52  CM-1 records: the CMake measurement corrected against upstream's tip and milestone (RG-1; R32 (a), (e))

A new commit on PR 52's branch (R32 (e)): the register block said upstream's
thirteen `cmake` mentions were Bazel-internal, a count taken on the fork's
tree; at upstream f27a977d8 thirteen files mention CMake, nine of them build
or toolchain files, and docs/project/milestones.md:230-231 names CMake
integration as a 0.1 deliverable, which this branch delivers (RG-1,
rg1-plan.md section 2.H2). No drift. Records only.

H60  SC-1 records: D-SC-6 is a drift under R32 (d), W-139's break condition already met at its filing; the page's issue 2153 sentence noted (RG-1; R32 (b), (e))

A new commit on PR 60's branch (R32 (e)): generics/overview.md:375-379 and
appendix-witness.md:151-154 record upstream's decision of leads issue 2153 to
support checked generics calling templates by monomorphization, text that
predates the cut, so D-SC-6's definition-time rejection is a drift and W-139's
break condition was met when it was filed (RG-1, rg1-plan.md section 2.H9).
The register block and W-139 say so, and template_constraints.md, which calls
the issue upstream's open question, gains a dated note; SC-1 realigns the check
and rewrites that paragraph by a new commit here before this PR lands. Records
and a dated documentation note only.

H55  ST-1 records: the README cite corrected to upstream's line, the view's Core.Str direction quoted (RG-1; R32 (a), (e))

A new commit on PR 55's branch (R32 (e)): the register block cited README.md:629
for upstream's owning `String`, the fork's copy's line; upstream's is :627 at
f27a977d8. No drift: README.md:622 calls the string types provisional, and the
view keeps upstream's prelude spelling until type_info.h:382's TODO renames it
`Core.Str` (RG-1, rg1-plan.md section 2.H4). Records only.

H56  OP-1 records: the register's cites corrected to upstream's, the comparisons' side effects filed as W-352, realigned here before this PR lands (RG-1; R32 (a), (b), (e); W-344)

A new commit on PR 56's branch (R32 (e)), from W-344: the block's cites become
upstream's p002188:489-490 and pattern_matching.md:526-527 (the latter was this
branch's own copy); the comparisons' `T.Copy` and `T.Destroy` against
comparison_operators.md's "should have no observable side-effects" are W-352,
which OP-1 realigns by a new commit here before this PR lands, comparing in
place (rg1-plan.md D-RG-10). Records only.

H57  OP-2: merge OP-1's RG-1 records commit (R32 (e))

Merges claude/carbon-fork-0-1-op at <sha56> (RG-1's H56) into PR 57's branch,
which is stacked on PR 56's. The OP-1 block's copy takes the corrected cites
and the dated note. No toolchain change.

H61  TP-1 records: the cross-file lowering TODO cited at upstream's line, (iii) re-read at the tip (RG-1; R32 (a), (e))

A new commit on PR 61's branch (R32 (e)): the register block cited
lower/handle.cpp:524, this branch's copy; upstream's TODO is
lower/handle.cpp:384-390 at f27a977d8. The `array` entry is read at the tip,
where `array(T, N)` is the shorthand for the prelude's `Core.Array` (RG-1,
rg1-plan.md section 2.H10). No drift. Records only.

H64  CT-1 records: the register block names ten entries, not nine (RG-1; R32 (e), R10)

A new commit on PR 64's branch (R32 (e)): plan §0.10 lists ten register
entries, the tenth (`SpecificConstant`'s category) added at plan rev 4
(RR2-M1) before the discharge commit wrote "the nine"; the block now says ten
and carries RG-1's dated note (rg1-plan.md section 2.H11). No drift. Records
only.

H64m CT-1: merge TP-1's RG-1 records commit (R32 (e))

Merges claude/carbon-fork-0-1-tp at <sha61> (RG-1's H61) into PR 64's branch,
which is stacked on PR 61's, after PR 64's own count correction. The TP-1
block's copy takes the corrected cite and the dated note. No toolchain change.
```

<!-- google-doc-style-resume -->

Each message's first line is the subject; the body follows a blank line, and
the two trailers follow the body after a blank line. No body line starts with a
digit and a period (amended 2026-10-28, review fold: A-m5).

### A.11 The description refreshes

Appended to each PR's description under "RG-1 amendment (2026-10-27)":

<!-- google-doc-style-ignore -->

```text
PR 53: RG-1 classified this PR's V-3a register block against upstream
f27a977d8 (commit <sha53>, records only). Six departures from accepted text
are drifts under R32 and V-3b, filed on RG-1's branch as W-347 (p005434:83's
`noalias`), W-348 (p005434:663), W-349 (p005434:831-832), W-350
(arithmetic.md's performance-build row), W-351 (safety README's benchmarking
disable) and W-353 (README.md:2130-2132's type-defined initialization for the
hardened build mode, promoted here to the Release baseline for every type);
SAFE-1 realigns them by a new commit on this branch, under its own plan
amendment and document reviews, before this PR lands. The zero-fill cite now
names upstream's README.md:2130-2132. The rest of the block is aligned with
upstream or has no upstream counterpart, and carries the watch item W-355.

PR 52: RG-1 corrected the register block's CMake measurement against upstream
f27a977d8 (commit <sha52>, records only): upstream has no CMake files, and its
docs/project/milestones.md:230-231 names CMake integration as a 0.1
deliverable, which this PR delivers; the Core-object helper follows
p006333:193-198's opt-out, its gap W-003. No drift.

PR 60: RG-1 found D-SC-6 to be a drift under R32 (commit <sha60>, records and
a dated page note only): upstream decided leads issue 2153
(generics/overview.md:375-379, appendix-witness.md:151-154), text older than
the fork's cut, so rejecting a checked-generic argument to a template
parameter at the definition contradicts it; W-139 is the item, its break
condition already met when it was filed, and SC-1 realigns the check and
rewrites template_constraints.md's paragraph by a new commit on this branch
before this PR lands.

PR 55: RG-1 corrected the register block's README cite to upstream's line
(README.md:627 at f27a977d8; commit <sha55>, records only). No drift: the
owning type's name is provisional upstream, and the view keeps upstream's
prelude spelling `Core.String` until upstream renames it `Core.Str`.

PR 56: RG-1 corrected the register block's cites to upstream's p002188:489-490
and pattern_matching.md:526-527 (commit <sha56>, records only, W-344) and
filed the comparisons' side effects as W-352: OP-1 realigns them by a new
commit on this branch, comparing the payloads in place, before this PR lands.

PR 57: PR 56's RG-1 records commit is merged (merge <sha57>); no OP-2 change.
OP-1's W-352 commit on PR 56 will be merged the same way.

PR 61: RG-1 corrected the register block's cite of the cross-file lowering TODO
to upstream's lower/handle.cpp:384-390 at f27a977d8 (commit <sha61>, records
only). No drift.

PR 64: the register block's count is corrected to the ten entries of plan
§0.10 (commit <sha64>, records only), and PR 61's RG-1 records commit is
merged (merge <sha64m>). No drift.
```

<!-- google-doc-style-resume -->

## Hand-off notes for the implementer

1.  Read this plan's section 1 before any record: the verdicts follow D-RG-2's
    test, and a reviewer's change of a verdict changes section 2, the counts
    (0.2, the summary, 3.1's R1 message, A.1, A.8) and the items together.
2.  Re-run section 4's checks first, at the tip you fetch: the quotes and the
    silence checks (4.2; copy quotes_rev2.tsv, checks.tsv and bin/ from
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/fixer/
    into your own scratch), the block scan (4.4, blocks2.py) and the re-scan
    (4.5). A moved upstream line, a failed silence check or a moved held head
    stops the work until the plan is amended (section 6, R-1 and R-7).
3.  Follow D-RG-13's seven steps: R1 and the seven held records commits are
    staged and not pushed until two implementation reviews and at most two
    fixer rounds (new commits only) are done; then H57 and H64m; then the
    pushes in the merge order; then R2 and its focused review.
4.  Edit the log bottom up: the trunk notes of A.3 in A.3's order (T12, T2,
    T11 to T3, then T1 inline), then A.1 after :276. Use the Edit tool or
    Write, never a shell append (R25), and run prek to a fixpoint with the R31
    counts of 4.1 before each commit.
5.  The ledger: append A.5's eleven items after W-344, keep two-space JSON
    indentation, fill `<tip>`, and apply A.6's string edits; `json.load` it
    before the commit.
6.  The held commits: one scratch worktree per branch under /dev/shm/rg1-impl/,
    detached at the head named in 3.2, a stage ref made before the worktree is
    deleted; check 4.7's merge-tree before each push; never touch the held
    worktrees under /home/user/carbon-<x> and never check out a held branch in
    the main checkout.
7.  Write each PR's refresh to
    scratchpad/rg1/impl/pr_<NN>_refresh.md (3.3, A.11) and name the files in the
    hand-off; the orchestrator re-posts them.
8.  R2 fills the `<sha..>` placeholders of A.2, A.7, A.9, A.10 and A.11 and
    nothing else.
9.  No model identifier in any file; the trailers are the one exception.
10. RG-1's PR opens held, base trunk, after R2 and its review; its land
    position is first (section 5). The three realignments RG-1 files on held
    branches (SAFE-1's on PR 53, SC-1's on PR 60, OP-1's on PR 56) are their
    owners' work, scheduled by A.8's item 6, not RG-1's.

## Review fold record (rev 2, 2026-10-28)

Reviews: A (APPROVE-WITH-AMENDMENTS, five MAJOR and five MINOR) and B (REJECT,
one BLOCKER, five MAJOR and nine MINOR), 25 findings. Every finding was
reproduced in the fixer's scratch
(/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/rg1/fixer/)
against upstream f27a977d8 and the moved tip e6fddcf97 and the held heads, and
all 25 are folded; none is rejected. Each fold is marked "(amended 2026-10-28,
review fold: <id>)" where it lands.

| Finding | Reproduced | Folded where |
| --- | --- | --- |
| A-M1 | destroy.carbon:14, :23-24 and :36-38, control_flow.cpp:158 and custom_witness.cpp:1054 at both shas; PR 51 f96fe8a7a :6226-6232 found by the widened scan | §0.1, §0.2 (H12), D-RG-16, T5.6, T5.9, H10.3, §2.H12, W-354, A.1, A.3 T5, A.4 (H61, PR 51's land-time note) |
| A-M2 | the probe of §4.8 on PR 57's, trunk's and the nightly installs | D-RG-10 rewritten, H5.4, W-352 (not blocked, a commit on PR 56), §5, R-6, §7, A.4 H56, A.8, A.10, A.11 |
| A-M3 | PR 60's template_constraints.md:456-468; `git blame` puts upstream's lines at 7134e23f2, an ancestor of the cut | D-RG-7, D-RG-9, H9.5, H60 (page note and W-139's note), A.1, A.10, A.11 |
| A-M4 | README.md:3706, interoperability/README.md:260-261, type_info.h:381-382, p006177:147-148 | D-RG-19, H4.1, A.4 H55, A.10, A.11 |
| A-M5 | the dependent lines on PR 53 by decision id | D-RG-7's table, §2.H1 intro, §5, the reorder alternative in §6, A.8 item 6, W-347 to W-351 and W-353 |
| A-m1 | README.md:3159 "#### Generic choice types" under "## Generics"; p000157:228-229 | D-RG-2, D-RG-5, T2.1, W-346, A.1 |
| A-m2 | indexing.md:113-117; p006333:193-198; variadics.md:137-139 | T3.5, T5.2, H2.6 (ALIGNED), H8.2 split into H8.8 (ALIGNED), D-RG-12, counts |
| A-m3 | EV-1's block at cb3ef2e74 :3538-3549; UA-1's review :6606-6607; op2 over op and dr-idx over dr count 0 | H3.4 removed, T10.4 added, summary and §7 (three blocked DRIFTs), D-RG-5 and W-346's PR list, §4.6 |
| A-m4 | e6fddcf97 two commits past; 136 refs, 21 worktrees, W-341 to W-344 ten each | §0.1, §0.5, §4.5, 3.1's `<tip>` |
| A-m5 | rev 1 :1990 "2.H10). Records only." | A.10's H61 body rewrapped |
| B-B1 | 57 rows said only "silent" | every NONE row given its nearest passage or a silence check; checks.tsv (89) and check_greps.sh in §4.2; the trunk notes of A.3 name the checks; W-342's discharge conditioned on both scripts (A.6) |
| B-M1 | the fixer's `git merge-file` simulation: sc, dr and dr-idx go from 0 to 1 decision-log region | D-RG-14, §4.7's rule, §5 |
| B-M2 | R32 (b) "each entry carrying its work item" | D-RG-17, W-355, D-RG-11 (land-time notes scheduled), A.8 item 6, A.6 and A.7 (W-343 narrowed) |
| B-M3 | PR 53's block :3929-3936 lists the zero-fill and the Permissive reading among its departures; safety/README.md:242-250; p005914:204-210 | H1.13 DRIFT (W-353), H1.14 re-quoted and decided ALIGNED, A.4 H53, A.11 |
| B-M4 | as A-M3 | D-RG-9, H9.5, H60, A.1, A.8, A.10, A.11: "already met when W-139 was filed" |
| B-M5 | rev 1's 3.2 pushed before any review | D-RG-13's seven steps, §3 preamble, R-9, hand-off notes 3 and 6 |
| B-m1 | rev 1 :1507 "2153) and appendix-witness.md..." | A.4 H60 rewritten |
| B-m2 | DR-0's "_Ids._" ends at :275, the blank is :276; H64's line; A.3's order | §3.1, A.1, A.3's order, H64 made on 4a3220c11 before H64m |
| B-m3 | W-344's "DR-1, W-320's owner, for the closure" | D-RG-10, W-352's notes, A.6's W-344 note |
| B-m4 | as A-m1, and decision-log :716-718 "F-006a (user, 2026-07-19)" | D-RG-5, W-346, A.1, A.8: the reversal recorded, veto-able |
| B-m5 | as A-m4 | §0.1, 3.1 |
| B-m6 | rev 1's A.8 item 6 put W-352 "before UA-3" while blocked | A.8 item 6 rewritten (W-352 before PR 56 lands; W-354 and W-356 in UA-3's gate; W-355 weekly) |
| B-m7 | C1 and C2 cited lines without text | C1.1 and C2.1 to C2.6 quoted verbatim and added to quotes_rev2.tsv |
| B-m8 | "trunk's entry", "trunk's twelve blocks", "nine of them build files" | §4.3, A.4's leads, 3.1's R1 message, H52 |
| B-m9 | upstream custom_witness.cpp at the tip | as A-M1: D-RG-16 and W-354 decided now, not left to UA-3 |

Beyond the findings: the probe for A-M2 found a crash, filed as W-356
(D-RG-18); H11.9's cite was corrected from expr_info.cpp:319 to
typed_insts.h:2009-2013 with expr_info.cpp:219-220; T12.7's row now shows that
upstream still asserts where the fork's guard diagnoses. Counts: 153 entries,
15/32/106 at rev 1 become 155, 19/34/102; items filed W-346 to W-352 become
W-346 to W-356. Status: rev 2, not signed off; the re-review decides.
