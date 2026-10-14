<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Operator export plan: Carbon operator impls as C++ operator overloads (OX-1, W-054)

**Status:** rev 5 -- NOT signed off: RR3-B1, RR3-B2 (the third focused
re-review's two BLOCKER findings). Rev 5 (2026-10-14) folds the third focused
re-review, of rev 4 (145fdaa62), which returned REJECT with 2 BLOCKER, 1 MAJOR
and 1 MINOR findings: rev 4's fold of RR2-1 not resolved for the recognized
types (its RR3-B1: the non-diagnosing predicate never mapped `str`, `Core.Slice`
or `Core.Result`, whose C++ form depends on a header, so a sibling impl that
named one still rejected Carbon-only programs that trunk accepts), rev 4's fold
of RR2-2 not resolved (its RR3-B2: removing every exported operator before
ranking let Carbon's own expression select, and lower through, a C++ template
that only an export made viable, where C++ selects the export and trunk the
impl), the plan presenting those outcomes as the rule (its RR3-M1), and the
predicate's mirror of type_mapping.cpp left unnamed (its RR3-m1). The
re-review's ids are kept as they are, none of which reads as a measurement or an
earlier finding. All four are folded and none is rejected. RR3-B1 and RR3-B2
take the routes the re-review proposes and prototyped as its `v7y` and `v7x`,
with two corrections the fixer measured (R17): the set of classes in progress is
threaded through the recognized-type mapping, which `v7y` left undone and which
overflows the stack for a class that names itself through a slice of pointers,
and an optional pointer's argument, a facet value, is unwrapped as
type_mapping.cpp unwraps it, which `v7`'s predicate missed, refusing a class
with such a field (M-42 (a)). RR3-B2's rule is stated as measured, with the one
boundary its proposal leaves, an exported operator that C++ reaches only by
converting an operand, and the evidence for not moving it (M-42 (b), §7 A-19).
Every amended sentence is marked "(amended 2026-10-14, review fold: RR3-n)",
with n one of B1, B2, M1 and m1, and tabled in the
[third focused re-review fold](#third-focused-re-review-rev-5-2026-10-14). The
verdict was REJECT, so rev 5 is not signed off: RR3-B1 and RR3-B2 were the
blockers, and whether their fold resolves them is the next re-review's to
confirm. The rev 5 fixer re-measured in its own scratch tree,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1-fixer3`
(`$Z` below), with its binaries, fills and conformance output on a tmpfs,
`/dev/shm/ox1-fixer3` (`$Y`, linked as `$Z/shm`); the third re-reviewer's trees
are `$RR3`, `…/scratchpad/ox1-rr3`, and `/dev/shm/ox1-rr3`, the directory that
also holds rev 3's `$H`. The prototype `v8` (§2.1 to §2.4) replaces `v7`:
`FindClangOperator` resolves first with the exported operators present and
leaves an exported operator that C++ selects with every operand an exact match
to Carbon's impl lookup, and `IsUnmappableWithoutExport` maps a recognized type
once the Carbon classes it names pass the predicate. M-8, M-12 to M-14, M-16,
M-18, M-19, M-31, M-33, M-37, M-38 and M-40 were re-run on `v8`, and M-41 and
M-42 added; every other number of rev 4 stands as measured.

**Rev 4** (2026-10-14, 145fdaa62, not signed off: RR-1-NR, NEW-B1, the second
focused re-review's two BLOCKER findings, cited here as RR2-1 and RR2-2) folded
the second focused re-review, of rev 3 (fd324a642), which
returned REJECT with 2 BLOCKER and 3 MINOR findings: rev 3's fold of RR-1 not
resolved (its RR-1-NR), RR-2 resolved only in its narrow form, the same hazard
through Carbon's calls and conversions (its NEW-B1), and three MINOR findings
(its m-1 to m-3). This plan cites them as RR2-1 (RR-1-NR), RR2-2 (NEW-B1) and
RR2-3 to RR2-5 (m-1 to m-3), so that none reads as a rev 3 RR-n or a
measurement. All five are folded and none is rejected. RR2-1 and RR2-2 take the
route the re-review proposes: no export can emit a diagnostic, whatever makes
the lookup (D-OX-9), Carbon's operator expressions still never select an
exported operator (D-OX-11), and the guarantee is restated to what holds: a C++
template sees a Carbon class's exported operators whoever instantiates it
(D-OX-21). The fold goes one step further than the finding asked, with its
evidence (R17): the dynamically scoped flag of rev 2 and rev 3 is removed
rather than kept beside the new rule, because with it a trait's value depended
on whether Carbon's deduction or C++ code instantiated it first (M-33, M-37),
and the lookup cache it protected is gone too, because every lookup of an
operator name now asks again (D-OX-12), which leaves W-205 nothing to cover.
Every amended sentence is marked "(amended 2026-10-14, review fold: RR2-n)" and
tabled in the
[second focused re-review fold](#second-focused-re-review-rev-4-2026-10-14).
The verdict was REJECT, so rev 4 is not signed off: RR2-1 and RR2-2 were the
blockers, and whether their fold resolves them is the next re-review's to
confirm. The rev 4 fixer re-measured in its own scratch tree,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1-fixer2`
(`$K` below), with its binaries, fills and conformance output on a tmpfs,
`/dev/shm/ox1-fx2` (`$L`, linked as `$K/shm`); the second re-reviewer's trees
are `$RR2`, `…/scratchpad/ox1-rr2`, and `/dev/shm/ox1-rr2`. The prototype `v7`
(§2.1 to §2.4) replaces `v6`: no flag and no context.h hunk, a SemIR predicate
that decides without a diagnostic whether a class can be exported, the deleted
operator template standing for every impl whose operand C++ cannot be given,
every operator lookup asked again, and exported operators left out of Carbon's
notes. M-8 to M-14, M-16, M-18 to M-20, M-22, M-23, M-26 and M-30 to M-36 were
re-run on `v7`, and M-37 to M-40 added; every other number of rev 3 stands as
measured.

**Rev 3** (2026-10-14, fd324a642, not signed off: RR-1, RR-2, the first
re-review's B-1 and OX-B-1) folded the focused re-review of rev 2 (7d71f02b3),
which returned REJECT with 2 BLOCKER, 1 MAJOR and 3 MINOR findings: review A's
B-1 (A-1 here) and review B's OX-B-1 (B-1 here) not resolved, review B's OX-B-2
(B-2 here) resolved, and four new findings. This plan cites the re-review's
findings as RR-1 (its B-1), RR-2 (its OX-B-1), RR-3 (its RR-M-1) and RR-4 to
RR-6 (its RR-m-1 to RR-m-3), so that none reads as rev 2's A-n or B-n. All six
are folded and none is rejected: RR-3 takes the route its finding proposes, with
a second resolution pass the finding did not foresee (M-32), and RR-4 extends
W-205 rather than taking a new id. Every amended sentence is marked "(amended
2026-10-14, review fold: RR-n)" and tabled in the
[focused re-review fold](#focused-re-review-rev-3-2026-10-14). The verdict was
REJECT, so rev 3 is not signed off: RR-1 and RR-2 were the blockers, and whether
their fold resolves them is the next re-review's to confirm. The rev 3 fixer
re-measured in its own scratch tree,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1/rr3`
(`$G` below), with the binaries and fill mirrors on a tmpfs, `/dev/shm/ox1-rr3`
(`$H`, linked as `$G/shm`), because the root file system had under 60 MB free;
the re-reviewer's tree is `$RR`, `…/scratchpad/ox1-rr`. The prototype `v6` (§2.1
to §2.4: the re-reviewer's scope change, `$RR/v5b/operators-scope.diff`, a
second removal pass after overload resolution, the deleted default `!=` and the
deleted operator templates of D-OX-22) replaces `v5`; M-8, M-12, M-13, M-14,
M-16, M-18, M-19, M-28 and M-30 were re-run on `v6`, and M-31 to M-36 added;
every other number of rev 2 stands as measured.

**Rev 2** (2026-10-14) was the fold of the two plan reviews of R29(c), for a
focused re-review (both reviews REJECTed rev 1; the ST-1 and OP-2 precedent).
Review A (toolchain soundness) returned REJECT with 1 BLOCKER, 5 MAJOR and 4
MINOR findings; review B (concreteness, process and cross-workstream) returned
REJECT with 2 BLOCKER, 3 MAJOR and 7 MINOR. Review A numbered its findings B-1,
M-1..M-5 and m-1..m-4, and review B OX-B-1..OX-B-12; this plan cites them as
A-1..A-10 (A-1 is review A's B-1, A-2..A-6 its M-1..M-5, A-7..A-10 its m-1..m-4)
and B-1..B-12, so that none reads as a measurement M-n; the rejected
alternatives of §7.2 keep their numbering and are always cited as "§7 A-n".
Every amended sentence, row or entry is marked "(amended 2026-10-14, review
fold: A-n)" or "(... review fold: B-n)" and tabled in the
[Review fold record](#review-fold-record-rev-2-2026-10-14): all 22 are folded
and none is rejected outright; A-1 is folded partly by a route other than the
one proposed, with its evidence (R17), and A-7 takes the second of the two
routes its finding offers. The fixer re-ran every measurement a finding is about
in its own scratch tree,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1-fixer`
(`$F` below; the planner's tree is `$X`, §0.2): the reviewers' probes copied
under `$F/probes/A-*` and `$F/probes/B-*`, the planner's under `$F/probes/P`,
the fixer's own under `$F/probes/V`, each run on the trunk install, on the
planner's `v4` and on the rev 2 prototype `v5`. Rev 2 replaces the toolchain
spec (`v4` → `v5`, §2.1 to §2.4), the goldens (§2.5) and two programs (§2.6), so
M-7, M-8, M-12, M-13, M-14, M-16, M-18 and M-19 were re-run on `v5` and M-20 to
M-30 added; every other number of rev 1 stands as measured. Rev 1 was the
planner's draft (3128eded5). Nothing below is implemented. Branch
`claude/carbon-fork-0-1-ox`, cut from trunk f67ab650d, whose toolchain and core
sources equal the upstream cut 0bdce60a5 (the toolchain and core paths of `git
diff --stat 0bdce60a5 f67ab650d` print nothing); trunk has since moved to
3eb7f36f0 by two fork/ORCHESTRATION.md-only stamps (44761146d records this
workstream and its id reservation; 3eb7f36f0 records DD-1 as PR 58, SC-1's and
DD-1's new id blocks and these plan reviews), and is not merged into the branch.
Every line number below is against f67ab650d unless a branch is named. Every
measured outcome in §0.2 was taken in this container with the trunk build
(`/home/user/carbon-build/carbon-trunk`, `carbon version` reporting
`0.0.0-0.dev+0bdce60a5`) and its file_test, the upstream nightly 2026.10.12 (an
oracle for the failure only, never for an EXPECT; R16(d), R30), and prototype
toolchains relinked from the trunk build's objects with this plan's §2.1 to §2.4
compiled in (§0.2, setup); no toolchain was built, nothing under
/home/user/carbon-build was modified, no worktree other than this one was
touched (others were read with `git show`), and the owner's runner was not used
(R28). At rev 2 the spec of §2.1 to §2.4 was the prototype `v5`: the diff
`$F/ox1-v5.diff` (sha256 d32f99f5…08919f04, 829 lines) compiled with the trunk
build's flags, clang-format 21.1.8 clean, and measured end to end; the copy
embedded in §2.1 was that diff as prek leaves it, whitespace-normalized (a blank
context line loses its leading space), so its own hash differed, and it applied
with `git apply` to f67ab650d and yielded the five files whose sha256 §2.1
listed, which is the identity check (rev 1 claimed the embedded copy was `v4`
"byte for byte"; it was not; amended 2026-10-14, review fold: A-10, B-7). At rev
3 the spec is the prototype `v6`, `$G/ox1-v6.diff` (sha256 41091975…8dc7ba, 1033
lines), embedded and identified the same way (§2.1; amended 2026-10-14, review
fold: RR-1, RR-2, RR-3, RR-5). At rev 4 the spec is the prototype `v7`,
`$K/ox1-v7.diff` (sha256 c5e39e50…9403f4, 1333 lines, four files: it has no
context.h hunk), embedded and identified the same way (§2.1; amended 2026-10-14,
review fold: RR2-1, RR2-2, RR2-5). At rev 5 the spec is the prototype `v8`,
`$Z/ox1-v8.diff` (sha256 ae0c89ec…7a7170, 1401 lines, the same four files),
embedded and identified the same way (§2.1; amended 2026-10-14, review fold:
RR3-B1, RR3-B2).

**Item:** W-054, "Export Carbon operator impls as C++ operator overloads" (kind
missing-feature, size L, subsystem toolchain/check/cpp, blocked_by W-007).
**Milestone row:** fork/gap-analysis.md:48, "Type system: C++ interop —
exporting Carbon operator overloads into C++", MISSING, evidence "No evidence
anywhere of exporting Carbon operator impls for use from C++ (audit: 'operator
interop is one-directional')"; records refer to the row by its bullet text (R7),
because held PRs move its line. **Bullet text** (docs/project/milestones.md:129
to :132): "Operator overloading", "C++ interop:", "Exporting Carbon overloads
into C++". **Arbiter:**
fork/conformance/programs/interop/cpp_operator_export.carbon, SKIP,
EXPECT-STDOUT `42`. **Criterion:** the bullet, read under F-017 (D-OX-1,
D-OX-4, D-OX-14, D-OX-18): every concrete operator impl of the checking file
whose `Self` or operand is a Carbon class that C++ sees as a record of its own,
the design overview's "Carbon types implementing an operator overload"
(docs/design/README.md:3666), and whose interface has a C++ overloaded-operator
counterpart ([over.oper]) is usable from C++ with that operator; every case left
out is filed with its reason; and the overview's conversions, "the
`ImplicitAs(U)` Carbon interface corresponds to implicit conversions in C++"
(:3679-3680), are inside the bullet and filed as W-208, which bounds the row
(rev 1's criterion named every concrete impl of the file, which impls with no
Carbon class among their types falsify, and left conversions out; amended
2026-10-14, review fold: B-3, A-6, B-4).

**Outcome this plan commits to:** the arbiter un-SKIPs to PASS with its EXPECT
`42` re-derived from the program text (30 plus 12; §1.8), its body
byte-identical to the commented sketch (M-15, R6, R27); the impls of 31 `Core`
interface members across seven families (arithmetic, negation, bitwise and
shift, compound assignment, increment and decrement, comparison, indexing)
export as C++ operators — member operators when the impl's `Self` is the
exported class, non-member operators found by argument-dependent lookup in the
operand class's innermost enclosing namespace when it is not (D-OX-2, D-OX-3) —
with `!=` available for an impl that keeps `EqWith`'s default `NotEqual`,
move-only classes included (D-OX-5); an impl whose operand has no C++ form is
omitted, one whose result alone has none is declared deleted, as is the default
`!=` beside it (D-OX-9), and the generic impls of an operator are one deleted
operator template, so that C++ rejects an operand Carbon would resolve to a
generic impl rather than convert it for a concrete one (D-OX-22); no export can
emit a diagnostic, whatever makes the lookup, C++ code or a Carbon operator
expression, call or conversion that asks C++, because a class that cannot be
exported is never named: an impl whose result names one is declared deleted, and
one whose operand names one is stood for by the deleted operator template, and a
recognized type whose C++ type is declared by a header the file does not
include, such as `str` without `<string_view>`, has no C++ form (D-OX-9,
D-OX-22; M-37, M-39, M-41; the recognized types amended 2026-10-14, review fold:
RR3-B1); every lookup of an operator name asks again, so a lookup finds every
impl declared before it, whatever lookups came earlier (D-OX-12; M-38); a Carbon
operator expression never calls an exported operator: when C++ selects one with
every operand an exact match, Carbon's impl lookup selects the impl it calls, as
C++ does, and otherwise no exported operator is a candidate for Carbon (D-OX-11;
M-10, M-22, M-26, M-41); and a C++ template sees a Carbon class's exported
operators whoever instantiates it, so a Carbon call or conversion, or an
operator expression for which C++ selects no exactly matching export, can select
a C++ function that an exported operator makes viable, which can call the export
(D-OX-21; M-37, M-40, M-42; rev 3 stated that every Carbon-only program compiles
and lowers as on trunk, which RR2-1 and RR2-2 falsified, and rev 4 that a Carbon
operator expression could select such a function where C++ selects the export,
under C++20 a rewritten candidate Carbon cannot call, which RR3-B2 falsified as
a rule; amended 2026-10-14, review fold: RR2-1, RR2-2, RR3-B2, RR3-M1); six new
conformance programs, one per family plus the non-member form, PASS with
hand-derived EXPECTs (§1.8); four new goldens (three check, one lower; 75
splits) fill by autoupdate in two passes with no existing golden changing (M-8,
M-12; the deleted operators, the scope of Carbon's lookup and the 55 splits
amended 2026-10-14, review fold: RR-1, RR-2, RR-3, RR-5; the 66 splits amended
2026-10-14, review fold: RR2-1, RR2-2, RR2-4; the 75 splits amended 2026-10-14,
review fold: RR3-B1, RR3-B2); F-017 is minted with a new design page,
docs/design/interoperability/operators.md, and a dated amendment to
docs/design/interoperability/README.md (D-OX-13); the row moves MISSING →
PARTIAL, **expected, not of record** (D-OX-14), bounded by W-208 (conversions),
with W-202, W-204, W-206, W-207 and W-209 to W-211 filed under it as limits
(W-205 is not filed: every lookup asking again leaves it nothing to cover;
amended 2026-10-14, review fold: RR2-1) and W-203, a pre-existing defect the
audit found, filed under the type-export row; the header moves +1 PARTIAL, −1
MISSING (rev 1 said DONE and +1 DONE; amended 2026-10-14, review fold: A-6, B-4,
B-3). Conformance: PASS +7, SKIP −1, programs +6, bullets +1 PASS (from the
floor of record 128 / 0 / 22 over 150, 48/56, to 135 / 0 / 21 over 156, 49/56,
measured in the container on `v5`, `v6`, `v7` and `v8`, M-13): the bullet's
programs all pass while the row stays PARTIAL, as OP-1's Optional row did
(fork/ORCHESTRATION.md, PR 56).

**Id allocation (recorded so no workstream collides):** re-scanned for rev 2 and
again for rev 3 (the same results; SC-1's local and `origin` heads were then
both 444ccbafe; amended 2026-10-14, review fold: RR-4), and for rev 4 over 77
refs (the same results; SC-1's local and `origin` heads now both 62e25dcdd;
amended 2026-10-14, review fold: RR2-1), over the refs `trunk`, `origin/trunk`
and every local and `origin` `claude/carbon-fork-0-1-*` branch with the commands
below (M-18): the ledger maximum is W-234 (SC-1 round 10,
claude/carbon-fork-0-1-sc at 0d7ee5c19 and 444ccbafe; its `origin` copy,
ae807c7e8, has W-232), and no ref other than this branch allocates any of
W-202..W-211 or F-017: they appear only as reservation text, in trunk's and
origin/trunk's fork/ORCHESTRATION.md, the stale 7mwfb7 copies of it, DD-1's
fork/ORCHESTRATION.md, decision-log.md, designdocs/plan.md and gap-analysis.md,
and VA-1's fork/variadics/plan.md (amended 2026-10-14, review fold: A-10, B-8).
OP-2 holds W-196..W-201 and F-016; W-190 is unused forever; W-169 is SC-1's
reserve; W-170..W-179 and W-195 are OP-1's; W-180..W-194 DD-1's; W-212..W-231
VA-1's (F-018 if VA-1 mints one); SC-1 holds W-232 and reserves W-233..W-239
(W-233 and W-234 filed), and DD-1 reserves W-240..W-244, unused (trunk
3eb7f36f0's stamp; amended 2026-10-14, fixer re-scan). **OX-1 reserves
W-202..W-211** and, at rev 2, uses all ten (§1.10: W-210 and W-211, rev 1's
spares, are filed by the folds of B-3 and A-3; amended 2026-10-14, review fold:
B-3, A-3); rev 3 files nothing new: RR-4's memoized templates and the fixer's
namespace-order finding (M-36) extend W-205, whose subject, what C++ code sees
after an earlier lookup, they share (amended 2026-10-14, review fold: RR-4). Rev
4 files nothing new and uses nine of the ten: W-205 is not filed, because every
lookup of an operator name now asks again (D-OX-12), which leaves of its subject
only C++'s own rule for a template instantiated before an impl is declared
(M-33, M-38); it stays reserved to OX-1, unused, and is never reused (amended
2026-10-14, review fold: RR2-1). Rev 5 files nothing new either: no finding of
the third re-review is a residue, and the id scan re-run for it over 77 refs
finds no allocation of any reserved id on another ref, the ledger maximum now
W-235 on SC-1's heads (M-18; amended 2026-10-14, review fold: RR3-B1,
RR3-B2). A residue that the implementation reviews find
therefore needs a new block from the orchestrator, recorded in
fork/ORCHESTRATION.md before the id is written; it never takes an id from a
block reserved to another workstream. **OX-1 mints fork design id F-017**
(D-OX-13). An id counts as **taken** only by an allocation on a ref other than
this branch: a ledger entry `"id": "W-202"` to `"id": "W-211"` in that ref's
fork/inventory/work-items.json, or a decision-log heading naming F-017; a
mention in a plan, a stamp or a row is the reservation, not an allocation
(amended 2026-10-14, review fold: B-8). Immediately before the discharge commit
writes the ledger, the commands are re-run; if an id is taken by then, the
residues re-allocate from a block the orchestrator assigns (skipping every
reserved block), the design id from the next free F-id, and the landed notes say
so.

```bash
cd /home/user/carbon-ox
refs=$(git for-each-ref --format='%(refname:short)' \
  refs/heads/claude/carbon-fork-0-1-* refs/remotes/origin/claude/carbon-fork-0-1-* \
  refs/heads/trunk refs/remotes/origin/trunk)
# The ledger maximum.
for r in $refs; do
  git show "$r":fork/inventory/work-items.json 2>/dev/null \
    | grep -oE '"id": "W-[0-9]+"' | grep -oE '[0-9]+'
done | sort -n | tail -1
# Allocations of the reserved ids on any other ref: must print nothing.
for r in $refs; do
  case "$r" in *carbon-fork-0-1-ox) continue ;; esac
  git show "$r":fork/inventory/work-items.json 2>/dev/null \
    | grep -E '"id": "W-(20[2-9]|21[01])"' | sed "s#^#$r: #"
  git show "$r":fork/decision-log.md 2>/dev/null \
    | grep -E '^#+ .*F-017' | sed "s#^#$r: #"
done
# Mentions (the reservation text), for the record only.
for r in $refs; do git grep -l -E 'W-20[2-9]|W-21[01]|F-017' "$r" -- fork docs; done | sort -u
```

**Design authority** (each cited where used):

-   docs/design/README.md:3657-3693, "Operator overloading" under C++
    interoperability, provisional ("no design for this has been through the
    proposal process yet", :3659-3660): "Carbon types implementing an operator
    overload using an interface should get the corresponding operator overload
    in C++. So implementing `ModWith(U)` in Carbon for a type effectively
    implements `operator%` in C++ for that type" (:3666-3668); "However, there
    may be edge cases around implicit conversions or overload selection that
    don't map completely into Carbon" (:3672-3673); "they are matched according
    to which operation has the most similar semantics rather than using the
    same symbols. For example, the `^x` operation and `BitComplement` interface
    in Carbon corresponds to the `~x` operation and `operator~` function in C++"
    (:3676-3679); and, in the same paragraph, "Similarly, the `ImplicitAs(U)`
    Carbon interface corresponds to implicit conversions in C++, which can be
    written in multiple different ways" (:3679-3681), which puts conversions
    inside this section's mapping (D-OX-18; rev 1's quote stopped before it;
    amended 2026-10-14, review fold: A-6, B-4).
-   docs/design/interoperability/README.md:350, "## TODO: The operator
    interoperability model", an empty section: the accepted design does not
    decide the export mapping, hence F-017. :212-238, "Overload resolution",
    the OV-3 amendment (F-009): an exported overload set "appears to C++ as an
    ordinary C++ overload set", resolved "under C++'s rules", "a documented
    divergence"; D-OX-15 follows it.
-   The accepted proposal
    proposals/p006254-c-interop-toolchain-implementation-for-function-calls.md
    at :210-216, "Operator calls": "Carbon identifies the operator call, looks
    up potential C++ operator functions (both member and non-member), and uses
    Clang's overload resolution to select the best candidate". D-OX-11 keeps
    exported Carbon impls out of that candidate set: an exported operator is
    not a C++ operator function but a Carbon impl seen from C++, which
    Carbon's impl lookup finds itself (amended 2026-10-14, review fold: B-11;
    D-OX-21's share of it removed, review fold: RR2-1). Where Clang's
    resolution of that candidate set would select an exported operator with
    every operand an exact match, Carbon's impl lookup selects the impl that
    the operator calls, so Carbon and C++ agree (amended 2026-10-14, review
    fold: RR3-B2).
-   proposals/p000845-as-expressions.md:184-187: "The `As` interface provides
    the same functionality as single-argument `explicit` constructors and
    `explicit` conversion functions in C++, and can be used to expose those
    operations for interoperability purposes" (D-OX-18; amended 2026-10-14,
    review fold: B-4).
-   docs/design/expressions/README.md:326-358, the operator table (which
    operators exist and which are statements); arithmetic.md:214-292,
    bitwise.md:192-271, comparison_operators.md:248-271 (`EqWith`, its default
    `NotEqual` "`return not (self==u);`" at :260, "The expression `x!=y` calls
    `x.(EqWith(U).NotEqual)(y)`" at :271) and :345-380 (`OrderedWith` with
    `Compare`, which the prelude does not declare), indexing.md:46-97 (`IndexWith.At`
    and the `ref` forms), pointer_operators.md:21-36 (dereference is not an
    interface).
-   core/prelude/operators/arithmetic.carbon:24-91, bitwise.carbon:22-79,
    comparison.carbon:11-34 (`default fn NotEqual`, :14-16; "TODO: fn Compare",
    :24), index.carbon:7-10 (`At` only), deref.carbon:8-10 (`CppUnsafeDeref`,
    for imported C++ types).
-   proposals/p001178-rework-operator-interfaces.md:84-88: "The intent to
    provide a low-level interface for individual operators is directly motivated
    by the desire to provide strong interoperability with operators defined in
    C++"; p000702-comparison-operators.md:339-340: "Overriding `!=` separately
    from `==` is expected to be used to support floating-point NaN comparisons
    and for C++ interoperability";
    p001191-bitwise-and-shift-operators.md:140-143: "permitting separate
    overloading of each of the bitwise operators with custom return types. This
    should allow smooth interoperability with C++ overloaded operators".
-   docs/project/milestones.md:200, "Interfaces powering language syntax
    (operators, conversions, etc.)", a bullet of "Language and syntax support
    library components" under "#### Standard library components" (:190): it
    lists the prelude interfaces the 0.1 library must provide and says nothing
    about the scope of the interop bullet at :129-132, so it is no evidence
    either way on conversions (rev 1 cited it as :169, which is "Good
    equivalents for a range of existing C/C++ looping constructs", and as
    naming operators and conversions apart; amended 2026-10-14, review fold:
    A-6, B-4).
-   fork/decision-log.md, "OV-3: overload-set export, documented divergence"
    (:3517 on): F-009's sub-fork F-009i intended an unmappable set member to be
    omitted after its semantics TODO so that "the exportable subset stays
    callable", and **D-OV-18** recorded that this is false as landed: the TODO
    is an error, so a set with an unmappable member REJECTS the unit
    (:3595-3606). D-OX-9 follows D-OV-18 for a class C++ cannot export, departs
    from it for an operand that has no C++ form at all, and declares a deleted
    operator for a result that has none (rev 1 summarized F-009i as "omitted
    after its TODO" and left D-OV-18 out; amended 2026-10-14, review fold: B-2).
    Rulebook R30.
-   fork/inventory/work-items.json, W-007 (the contention-file discipline:
    additive edits, sequencing), W-118 (two set members with one C++
    signature), W-109 (write-through indexing), W-045 (import-direction
    rewrites).

V-3: no accepted proposal or leads' direction is contradicted. The direction of
the export is the design overview's (:3666-3668, provisional); its form — member
or non-member, the default `!=`, the void compound assignments, the by-value
`operator[]`, the omission of operand-unmappable impls, the deleted declaration
of result-unmappable ones and of their default `!=`, the deleted operator
template of generic impls and of impls whose operand C++ cannot export, every
operator lookup asked again and none able to diagnose, and C++ templates seeing
the exports whoever instantiates them (amended 2026-10-14, review fold: RR-1,
RR-3, RR-5, RR2-1, RR2-2) — fills a silence of the accepted design (the README
section is empty) and is minted as fork design F-017 for after-the-fact veto
(R29(a)). p006254's "Operator calls" is kept: Carbon still resolves among the
C++ operator functions with Clang's overload resolution, and an exported Carbon
impl is not one of them; Clang's resolution over every candidate only decides
whether C++ would select an exported operator exactly, in which case Carbon's
impl lookup selects its impl (D-OX-11; amended 2026-10-14, review fold: B-11,
RR3-B2).
Conversions are not exported in 0.1 and the row stays PARTIAL for them
(D-OX-18), so the overview's `ImplicitAs` sentence is deferred, not contradicted
(amended 2026-10-14, review fold: A-6, B-4). The divergences it documents (C++
conversions on operands, base-class member lookup, the impl function's own
signature, by-value operands; D-OX-15) are the overview's own caveat
(:3672-3673) and follow OV-3's precedent.

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Sub-feature table (verified in-tree at f67ab650d)

| # | Element | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Exported Carbon class | LANDED, lazy | toolchain/check/cpp/export.cpp:61-98 `ExportClassToCppInDeclContext` creates the `CXXRecordDecl` in the parent's mapped context and sets external lexical and visible storage (:93-95); `ExportClassToCpp` :277-311; the definition is produced by `CarbonExternalASTSource::CompleteType` (generate_ast.cpp:443-588: `final`, base, `ExportAllFieldsToCpp`, the destructor unless trivially copyable, virtual functions); every other member is produced on demand by name. |
| 2 | The name-lookup hook | LANDED; operator names unanswered | generate_ast.cpp:330-441 `FindExternalVisibleDeclsByName`: the switch on the name kind (:364-387) answers `Identifier` and `CXXConstructorName` and returns `false` for every other kind (`default:`, :385-386), operator names among them; a found Carbon entity maps through `MapInstIdToClangDeclOrType` (:202-293). |
| 3 | Function and method export | LANDED | export.cpp `FunctionInfo` :646-753 (`self_param` :682-686; `GetCppName` an identifier or a constructor name, :723-730); `BuildFunctionInfo` :774-825 exports the callee's parent scope first (:780-784), and an impl's scope is neither a namespace nor a class, so it reaches the TODO `non-class non-namespace name scope` (:157); `BuildCppToCarbonThunkDecl` :1096-1191 takes the C++ name as a parameter (:1098), creates a `CXXMethodDecl` in a record (:1148-1151) and a `FunctionDecl` elsewhere (:1167-1170), `inline`, always-inline and internal-linkage (:1185-1188); its type from `BuildCppToCarbonThunkFunctionType` :1028-1093 (`const` for `self`, `&` for `ref self`, :1080-1089); `BuildCppToCarbonThunkBody` :1209-1325 (`*this` as the first argument, :1246-1250; `return_storage` and an NRVO return, :1219-1243 and :1300-1320); `BuildCarbonToCarbonThunk` :1332-1399 generates `<name>__carbon_thunk` in the callee's parent scope (:1337-1342, :1371) and defines it with `BuildThunkDefinitionForExport` (check/thunk.cpp:385-440); `GetOrExportFunctionToCpp` :1606-1644 registers the export in `clang_decls` (:1632-1642). |
| 4 | Overload-set export (OV-3) | LANDED | generate_ast.cpp:256-289, the `OverloadSetValue` arm: each member through `GetOrExportFunctionToCpp`, delivered as one list; export.cpp:1378-1389, the `overload_index` hunk. |
| 5 | Thunk bodies | LANDED | C++ side: export.cpp:1209-1325. Carbon side: check/thunk.cpp:385-440 (`BuildThunkCall` :309-326, `PerformThunkCall` :270-302, which forms `self.(callee)` for a `self` parameter, :292-296). toolchain/check/cpp/thunk.cpp (`BuildCalleeCallExpr` :725, `BuildReturnValueStore` :810, `BuildThunkBody` :916, `BuildCatchingThunkBody` :958) is the import direction, Carbon calling C++ (§0.3 item 3). |
| 6 | Type mapping | LANDED | type_mapping.cpp:504 `MapToCppType`; :196-372 `TryMapClassType` (recognized types; otherwise `ExportClassToCpp`, :366); returns a null type, without a diagnostic, for an unmappable type (a tuple, for one); mapping a class type exports the class, which can diagnose (export.cpp:69, :141, :157, :266, :353), and completing it maps every field (:513; M-20). A recognized type is mapped without exporting a class, except an `Optional` of anything but a pointer (:267-285, a facet value unwrapped before the pointer test): `str`, `Core.Slice` and `Core.Result` to `std::string_view`, `std::span` and `Carbon::expected` (:286-362) and `Cpp.Exception` to `Carbon::Exception` (:260-266), each found by name in the translation unit (`LookupCppType`, `LookupCppClassTemplate`) and null when its header is not included, and a `Core.Result` whose argument class is not trivially copyable for export to null as well (`MapResultArgToCppType`, :156-182) (M-41; amended 2026-10-14, review fold: RR3-B1, RR3-m1). |
| 7 | Impl storage | LANDED; no index by `Self` | sem_ir/impl.h:18-104 (`self_id`, `interface`, `scope_id`, `witness_id`, `defined`); `ImplStore`'s lookup map is keyed by `(self constant, SpecificInterface)` (:249), so "every impl whose `Self` is `C`" needs a walk of `context.impls()`, as `CollectCandidateImplsForQuery` walks it (check/impl_lookup.cpp:699-726). An impl's functions are entries of its own name scope; a default member is not (M-3). |
| 8 | The import direction (the inverse table) | LANDED | check/cpp/operators.cpp:36-209 `GetClangOperatorKind` maps `Core` interface and member names to `OverloadedOperatorKind`; `FindClangOperator` :864-953 runs Clang's operator overload resolution and rejects a rewritten candidate as a TODO (:891-898). |
| 9 | Carbon's operator expressions ask C++ | LANDED | Two paths, both through `FindClangOperator`: check/operator.cpp:83 and :138 (`BuildUnaryOperator`, `BuildBinaryOperator`) call `LookupCppOperator` (operators.cpp:802-862) **before** Carbon's impl lookup whenever an operand is a C++ class type, and call the C++ operator if one is found; and check/impl_lookup.cpp:1327-1339, for a concrete query with a C++ type among the operands, has `LookupCppImpl` (cpp/impl_lookup.cpp:638-724) build a witness from a C++ operator (operators.cpp:741-800), which replaces any Carbon impl found. Each runs Clang's operator lookup on the operand types, the exported Carbon class among them (M-9, M-10; the first path amended 2026-10-14, review fold: B-1). |
| 10 | `Core` operator interfaces | LANDED (prelude) | core/prelude/operators/arithmetic.carbon:24-91, bitwise.carbon:22-79, comparison.carbon:11-34 (`default fn NotEqual`; no `Compare`), index.carbon:7-10 (`At` only); no dereference interface for Carbon types (deref.carbon:8-10 is `CppUnsafeDeref`). |
| 11 | `inline Cpp` | LANDED | generate_ast.cpp:59-86 and :616-700 (the code is parsed into the file's Clang AST against the exported declarations, in place); the default language mode is C++17 (M-6). |
| 12 | Arbiter | SKIP | fork/conformance/programs/interop/cpp_operator_export.carbon, EXPECT `42`, `return 1;` guard, the body commented out. |
| 13 | Docs | SILENT | docs/design/interoperability/README.md:350, an empty "TODO" section; docs/design/README.md:3657-3693, provisional. DD-1 (claude/carbon-fork-0-1-dd) fills the README section and says the export is not implemented (§6.2). |
| 14 | Clang's per-name lookup cache | LANDED (Clang) | clang/lib/AST/DeclBase.cpp:1921-1965 in /home/user/llvm-src: `DeclContext::lookupImpl` `try_emplace`s (:1952) an entry for the name, asks the external source only for a new entry or one with external declarations, and keeps the entry, empty or not, for every later lookup; upstream e476a2bd3 erases an empty entry the source did not fill, so that a later lookup asks again; an entry marked as having external declarations (`StoredDeclsList::setHasExternalDecls`, DeclContextInternals.h) is asked about again at every lookup (:1953), which OX-1 relies on for every operator name it answers (D-OX-12; amended 2026-10-14, review fold: A-4, RR2-1). |
| 15 | Clang's deferred template deduction, and its memoized instantiations | LANDED (Clang) | clang/lib/Sema/SemaOverload.cpp in /home/user/llvm-src: for every candidate-set kind but `CSK_InitByUserDefinedConversion` and `CSK_CodeCompletion`, an operator's (`CSK_Operator`) and a call's (`CSK_Normal`) among them, `shouldDeferTemplateArgumentDeduction` holds (:13603-13623), so `AddTemplateOverloadCandidate` records a function template as a deferred candidate (:8384-8403), and `BestViableFunction` deduces its arguments in `InjectNonDeducedTemplateCandidates` (:11559-11584) unless a non-template candidate is a perfect match (:11641-11661). The deduction instantiates what the template's signature names, a SFINAE trait among them, and Clang keeps each class-template specialization it instantiates, so a trait's value is fixed by the operators visible at its first instantiation (D-OX-21, M-31, M-33; added 2026-10-14, review fold: RR-1, RR-4; rev 3 named the operator's kind only, amended 2026-10-14, review fold: RR2-2). |

### §0.2 Measurements

Setup, under the planner's scratch directory (`$X` below is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1`):
`$X/bin/relink.py` (the ST-1 and OP-2 relink recipe, generalized) compiles each
patched source with the `cxx`, `cflags` and per-object `extra` flags of
`/home/user/carbon-build/carbon-trunk/build.ninja`, the include root switched to
this worktree (whose headers equal the build's) and an overlay directory first
for a patched header, into `$X/tc/<variant>/obj/`, and relinks `bin/file_test`
and `bin/carbon-busybox` from the trunk build's objects with the patched objects
substituted, writing only under `$X/tc/<variant>/`. Each `install-<variant>` is
a `cp -a` of the trunk install with its busybox replaced. `bin/run.sh` compiles
one program with `--output-last-input-only` (R2), links and runs it;
`bin/mrun.sh` does the same for several units, each compiled last in turn as the
conformance runner does; `bin/ft.sh` runs a file_test in test mode over the full
manifest from this worktree with the trunk runfiles; `bin/fill.sh` previews a
new golden by substituting it for an existing manifest entry in a scratch mirror
(`interop/cpp/class/export/static.carbon` holds check `operator.carbon`,
`layout.carbon` holds `operator_ast.carbon`, lower `mangle.carbon` holds lower
`operator.carbon`), then runs two autoupdate passes and a test-mode pass.
Variants: `v1` (member operators only), `v2` (plus the default `!=` and the
Carbon-side guard), `v3` (plus non-member operators), `v4` (plus the silent
omission of unmappable impls: rev 1's spec), and the mutants of M-14.
`XDG_CACHE_HOME` was a directory under `$X` for every `carbon` run.

Rev 2's setup, under `$F` (amended 2026-10-14, review fold: all): `$F/bin/`
holds copies of the planner's scripts, with `relink.py` taught to take a
precompiled object (`<obj>=<path>.o`) and a `TARGETS` list; `$F/src/v5/` holds
the five patched sources and `$F/inc/` the two patched headers (export.h, and
check/cpp/context.h, whose `CppContext` gains one trailing `bool`;
generate_ast.cpp, which allocates the `CppContext` with `std::make_unique`, is
recompiled, but the constructor is defined in check/cpp/context.cpp, whose
trunk object rev 2's and rev 3's relinks kept, so the measured `v5` and `v6`
never ran the member's `= false` initializer; the second re-reviewer's relink
of `v6` with context.cpp recompiled reproduced all 105 single-file probes, so
no measurement moves, and §8.5 now recompiles context.cpp whenever context.h
changes; rev 2 said the class was constructed only in generate_ast.cpp;
amended 2026-10-14, review fold: RR2-5). `v5` is §2.1 to
§2.4 (`$F/tc/v5f`, installed as `$F/install-v5`; an earlier link, `$F/tc/v5`,
differed from it in two comments only and measured identically wherever both
ran). `bin/probe.sh <install> <cache> <out> <programs...>` compiles each
program (with the compile arguments of a first-line `// ARGS:` comment), links
and runs it when it defines `Run`, and prints one line per program;
`bin/fill2.sh <file_test> <mirror> <log> [passes]` previews §2.5's four
goldens as the planner's `fill.sh` did, with
`interop/cpp/class/export/base.carbon` holding the fourth,
`operator_cxx20.carbon`, and a snapshot after each autoupdate pass; the mutants
M1 to M3 of M-14 are `v5`'s export.cpp with one edit each, linked with `v5`'s
other two objects (`$F/bin/mutants.sh`). `XDG_CACHE_HOME` was a directory under
`$F/cache/` for every `carbon` run.

Rev 3's setup, under `$G` and `$H` (amended 2026-10-14, review fold: RR-1 to
RR-6): `$G/bin/` holds copies of rev 2's scripts, with `fill3.sh` and `ft3.sh`
keeping their mirrors and temporary files under `$H`, and `mkinst.sh <busybox>
<dir>`, which makes an install as a symbolic-link copy of the trunk install with
the relinked busybox hard-linked in. `$G/src/` holds `v6`'s three patched
sources and `$G/inc/` its two patched headers, started from the re-reviewer's
application of rev 2's embedded diff (`$RR/apply`, whose five sha256 sums are
§2.1's at rev 2); `$G/ox1-v6.diff` is what `git diff` prints in a scratch
repository of f67ab650d's five files after they are replaced (the same procedure
yields `$F/ox1-v5.diff` byte for byte from `v5`'s files). `v6` is `$H/tc/v6`,
installed as `$H/install-v6`; `n1` is `v6` without the second removal pass of
`FindClangOperator` (`$G/mut/operators_n1.cpp`); the mutants M1 to M3 of M-14
are `v6`'s export.cpp with M-14's three edits (`$G/mut/m*_export.cpp`). The
probes are the re-reviewer's (`$G/probes/RR`, copied from `$RR/p`), rev 2's 69
(`$F/probes/list3.txt`) and the rev 3 fixer's (`$G/probes/G`, `S` and `W`), each
run with `bin/probe.sh`; compact logs and fill snapshots are under `$G` and
`$G/ev`. `XDG_CACHE_HOME` was a directory under `$H/cache/` for every `carbon`
run.

Rev 4's setup, under `$K` and `$L` (amended 2026-10-14, review fold: RR2-1 to
RR2-5): `$K/bin/` holds copies of the second re-reviewer's scripts
(`relink.py`, `probe2.sh`, `mrun.sh`, `mkinst.sh`, `fill.sh`, `ft.sh`), their
scratch paths moved under `$L`, with `multi.sh` (the seven multi-unit probes of
every round, library unit first) and `cmp3.py` (three probe logs joined by
name). `$K/src/` holds `v7`'s three patched sources and `$K/inc/` its one
patched header, export.h; `v7` changes no other header, so its relink compiles
export.cpp, operators.cpp and generate_ast.cpp only (a variant that changes
check/cpp/context.h also recompiles context.cpp, §8.5). `$K/ox1-v7.diff` is
what `git diff` prints in a scratch repository of f67ab650d's four files after
they are replaced. `v7` is `$L/tc/v7`, installed as `$L/install-v7`; the
mutants of M-14 are `$L/tc/m1` to `m3`, built from `$K/mut/m*_export.cpp`. The
probe lists are `$K/lists/single.txt` (the second re-reviewer's 105
single-file probes of every round), `atk.txt` (its 25 probes, `$RR2/probes`)
and `x.txt` (the rev 4 fixer's, `$K/probes/X` and `Y`), each run with
`bin/probe2.sh`, and the seven multi-unit probes; the logs are
`$K/runs-{single,atk,x,multi}-*.log`, the trunk and `v6` logs of the single-file
list being the second re-reviewer's (`/dev/shm/ox1-rr2/runs-{trunk,v6}.log`)
and `v6` its `/dev/shm/ox1-rr2/install-v6`. `XDG_CACHE_HOME` was a directory
under `$L` for every `carbon` run.

Rev 5's setup, under `$Z` and `$Y` (amended 2026-10-14, review fold: RR3-B1,
RR3-B2, RR3-M1, RR3-m1): `$Z/bin/` holds copies of the third re-reviewer's
scripts (`relink.py`, `mkinst.sh`, `p1.sh` and `prun.sh`, its four-way parallel
form of `probe2.sh`, `multi.sh`, `fill.sh` and `ft.sh`), their scratch paths
moved under `$Y`, with `cmpn.py` (probe logs joined by name), `goldens.py`
(§2.5's four sources extracted from this plan or put back), `edit_goldens.py`
(rev 5's edits of them), `splits.py` (the splits whose outcome contradicts their
name) and `mutants.sh` (M-14). `$Z/src/` holds `v8`'s three patched sources and
`$Z/inc/` its one patched header, export.h, which is `v7`'s; `$Z/ox1-v8.diff` is
what `git diff` prints in a scratch repository of f67ab650d's four files after
they are replaced (`$Z/repository`). `v8` is `$Y/tc/v8`, installed as
`$Y/install-v8`; `$Y/tc/v8f`, relinked after the last edit of operators.cpp, a
comment, has a byte-identical operators.cpp object and busybox, so every
measurement of `v8` is of §2.1's diff. `v8e` (`$Z/v8e/operators.cpp`) and the
third re-reviewer's `v7`, `v7x` and `v7y` (`/dev/shm/ox1-rr3/install-*`) are the
comparison builds of M-41 and M-42, and the mutants of M-14 are `$Y/tc/m1` to
`m3`. The probe list is `$Z/lists_v8.txt`: the third re-reviewer's 169
single-file probes of every round (its `lists_every.txt`, which holds its 134
content-unique ones), its `k7`, and the rev 5 fixer's 15 (`$Z/p/F`), 185 in
all, each run with `bin/prun.sh` on trunk, `v7`, `v7x` and `v8`
(`$Z/runs-all-*.log`), and the seven multi-unit probes with `bin/multi.sh`
(`$Z/runs-multi-*.log`). `XDG_CACHE_HOME` was a directory under `$Y` for every
`carbon` run.

**M-1. The arbiter's body fails on trunk and on the nightly, for one reason.**
The SKIP body, uncommented (`$X/probes/p1/op_export.carbon`), compiled with the
trunk install and with the nightly 2026.10.12
(`0.0.0-0.nightly.2026.10.12+62f1cc6`): both exit 1 with the single diagnostic

```text
op_export.carbon:20:13: error: invalid operands to binary expression ('Carbon::Meters' and 'Carbon::Meters')
   20 |   return (a + b).value;
      |           ~ ^ ~
```

What the `inline Cpp` block sees, from `carbon compile` with `--phase=check` and
`--dump-cpp-ast` on the same program with `a+b` replaced by `a.value+b.value`
(trunk): `namespace Carbon` holds `class Meters definition` with
`<undeserialized declarations>`, `DefinitionData ... aggregate standard_layout
trivially_copyable pod trivial`, a `FinalAttr`, `FieldDecl ... value 'int'
mutable`, `CXXMethodDecl ... Make 'Carbon::Meters (int)' static inline
internal-linkage` whose body calls `Make__carbon_thunk 'void (const int &, const
Carbon::Meters &)'` and returns `return_storage` by NRVO, and the implicit
trivial destructor. There is no operator declaration of any kind, and the impl's
`Op` has no C++ view: it is not a member of the class's scope, and operator
names are never answered (§0.1 rows 2 and 3). The record is complete and its
members appear on demand, so a C++ operator lookup into it is a lookup Carbon
can answer. On `v5` the same program prints `42` (M-13).

**M-2. Every path an exported Carbon class reaches today, and where an
operator would enter.** Read end to end (§0.1 rows 1 to 6): a class becomes a
record on first use by name or by type mapping; its fields are exported as a
group at completion or layout; a method, class function, constructor-named
function, overload set, variable or nested type is exported when Clang asks the
class or namespace for that identifier; a virtual function is declared at
completion. Not exported: anything without an identifier name (operators,
conversions), a generic member function (TODO, export.cpp:1596-1598), a
specific of a generic class's members (TODO :68-71 and the generic-class
destructor gap, generate_ast.cpp:506-518), and impls, whose functions live in
impl scopes that `ExportNameScopeToCpp` cannot map (:151-159). The C++
declaration of an exported function is built by `BuildCppToCarbonThunkDecl`
under any `DeclarationName` it is given, and its body by
`BuildCppToCarbonThunk`; both are static functions of export.cpp that take a
`FunctionInfo`, so an impl's `Op` can be exported under `operator+` by new code
that builds the `FunctionInfo` itself, without `BuildFunctionInfo`'s scope
export (M-4).

**M-3. Where an operator impl lives in SemIR.** `carbon compile` with
`--phase=check` and `--dump-sem-ir` of a class `Money` with one `i32` field and
`impl Money as Core.EqWith(Money)` declaring only `Equal`
(`$X/probes/eq/eq.sem`): the impl block holds
`%Money.as.EqWith.impl.Equal.decl`, the witness table is `impl_witness_table
(%Money.as.EqWith.impl.Equal.decl, constants.%EqWith.WithSelf.NotEqual.3da)` —
the default `NotEqual` is the interface's own function with the impl's specific,
not a function of the impl — and the impl scope's members are `.Money =
<poisoned>` and `.Equal = ...`. So a lookup of `NotEqual` in the impl scope
finds nothing, and a lookup of a name the impl's checking poisoned finds an
entry that is not `is_found()`: `v1`, which called `target_inst_id()` on such an
entry, failed `CHECK failure at toolchain/sem_ir/name_scope.h:83: is_found()` on
`a!=b` (the fix is `GetImplMemberFunctionId`'s `is_found()` test, §2.1). The
`Core` interfaces are recognized by name: `CoreIdentifier` names every operator
interface and member (check/core_identifier.def:19-97), while
`SemIR::CoreInterface` (sem_ir/core_interface_kind.def) lacks the bitwise
interfaces, `BitComplement` and `IndexWith`, so `interface.core_interface`
cannot classify them; an interface is a `Core` one when
`IsCorePackage(interface.parent_scope_id)` holds, as `GetCoreInterface` tests
(check/custom_witness.cpp:1440-1449).

**M-4. How Clang asks for an operator, and the form that answers it.** `v1`
(member operators only) failed M-3's CHECK inside the hook, and its stack is the
lookup path: `ExportOperatorsToCpp` ←
`CarbonExternalASTSource::FindExternalVisibleDeclsByName` ←
`DeclContext::lookupImpl` ← `LookupDirect` ← `Sema::LookupQualifiedName` ←
`Sema::AddMemberOperatorCandidates` ← `Sema::LookupOverloadedBinOp` ←
`Sema::CreateOverloadedBinOp`, the record being the left operand's class. With
`v3`, the same hook also receives `namespace Carbon` with the operator name from
argument-dependent lookup on an exported operand (M-7's `3*m`). Clang caches
each answer per context and name: `DeclContext::lookupImpl` returns a stored
entry without asking again once it holds no external declarations
(clang/lib/AST/DeclBase.cpp:1951-1954 in /home/user/llvm-src), so each class and
namespace is asked once per operator name (§0.1 row 14). The declarations that
answer are a `CXXMethodDecl` named `DeclarationNames.getCXXOperatorName(kind)`
in the record (the member form) and a `FunctionDecl` of that name in the
namespace (the non-member form); `v1` exported the arbiter's `operator+` as
`CXXMethodDecl ... used operator+ 'Carbon::Meters (Carbon::Meters) const'
inline internal-linkage` whose body calls `Op__carbon_thunk 'void (const
Carbon::Meters &, const Carbon::Meters &, const Carbon::Meters &)'`, and the
program printed `42` (`$X/probes/p1/v1`). The generated Carbon thunk lowers as
`_COp__carbon_thunk.Meters.Main:AddWith.b69bc498d15e4c3c.Core`, mangled by the
impl's `Self` and the interface's specific (sem_ir/mangler.cpp:92-158), so two
impls of one interface never share a thunk symbol.

**M-5. How values cross.** As for an exported method (export.cpp:1006-1024,
:1209-1325): a value parameter of class type is a by-value C++ parameter
(`operator+(Carbon::Money) const`; a trivially copyable class is passed in a
register, `i32 %.coerce`, lower fill M-12), passed to the Carbon thunk by
`const&`; the result is constructed in the C++ operator's `return_storage` by
the Carbon thunk through a reference parameter and returned by NRVO; a `bool`
result is loaded (LValueToRValue, :1310-1315). A class with a user `Destroy`
(`$X/probes/edge/e9_nontrivial.carbon`: `a+b` on two `Tracked`, then the
destroy count) prints `42 4` with the operator and `42 4` with the equivalent
exported method `a.Plus(b)` on trunk (`e9b_method.carbon`): the operator
inherits the method's value passing exactly, including the by-value
parameter's copy and its destruction (re-run on `v5`: `42 4` and `42 4`). A
by-value parameter also means that C++ copies an lvalue operand, which a class
C++ cannot copy rejects where Carbon accepts it (M-25, D-OX-15; amended
2026-10-14, review fold: A-7).

**M-6. The `inline Cpp` dialect, and what it does to `!=`.** An `inline Cpp`
function returning `__cplusplus` prints `201703` on trunk and on `v5`
(`$X/probes/std/std.carbon`): C++17, which never rewrites `a!=b` as `!(a==b)`.
`v1`, exporting only declared members, rejected `(a!=b)` for an impl without
`NotEqual` with `invalid operands to binary expression ('Carbon::Money' and
'Carbon::Money')` (`$X/probes/fam/fam.compile.log`). With `v2` onwards the
default `operator!=` is declared, and `e7_cxx20.carbon` (only `impl Money as
EqWith(i32)`) rejects `5==m` with `invalid operands to binary expression ('int'
and 'Carbon::Money')` under the default dialect and under
`--clang-arg=-std=c++20` alike, while `m==5` compiles: with `operator!=`
declared beside `operator==`, C++20's reversed `==` candidate is not formed.
At rev 2 this is pinned under C++20, not only measured: the new golden
operator_cxx20.carbon, with `EXTRA-ARGS: --clang-arg=-std=c++20`, rejects
`5 == m` for a member `EqWith(i32)`, `m == 5` for a non-member
`i32 as EqWith(Money)` and `5 > m` for an `OrderedWith(i32)`, each with
`invalid operands`, and compiles a move-only class's `==` and `!=` (M-12, M-21;
rev 1's only pin, `fail_reversed_equality`, runs in C++17, where no reversed
candidate exists; amended 2026-10-14, review fold: A-2).

**M-7. The prototype across every family (re-run on `v5`).**
`$X/probes/fam/fam.carbon` (member operators: `Money` with `AddWith(Money)`,
`SubWith(Money)`, `MulWith(i32)`, `DivWith(i32)`, `ModWith(i32)`, `Negate`, five
compound assignments, `Inc`, `Dec`, `EqWith` with the default `NotEqual`,
`OrderedWith`; `Bits` (a `u8`) with the bitwise, complement, shift and bitwise
compound impls; `Tri` with `IndexWith(i32)`; `Unknowable` with a declared
`NotEqual`) prints `9500450,21002331,-42,2,101110,10,8140843,300115,789,0` on
`v4` and `v5`, each value hand-derived in the probe's comments (950 and 450;
2100, 233 and 1; -42; the compound chain ending at 2; the comparison digits 1 0
1 1 1 0 and 1 0; 8, 14, 6 and 243; 30, 1 and 15; 7 8 9; 0 0 for an unknown
value). `$X/probes/nm/nm.carbon` (non-member operators: `impl i32 as
MulWith(Money)` with a `+ 1` marker, `i32 as EqWith(Money)` with the default
`NotEqual`, `i32 as OrderedWith(Money)`, `i32 as SubAssignWith(Money)`, `Cpp.Foo
as AddWith(Money)`) prints `30 31 111110 42 42 33`, the `31` showing that `3*m`
reached the `i32` impl and not `m*3`'s. Both print the same under
`--clang-arg=-std=c++20` (`$F/probes/P/fam_cxx20.carbon`, `nm_cxx20.carbon`).
The AST dump of `fam.carbon` (`v2`) lists 33 operator declarations of the shapes
§1.1 tabulates, among them `operator+= 'void (Carbon::Money) &'`, `operator++
'void () &'`, `operator~ 'Carbon::Bits () const'`, `operator[] 'int (int)
const'`; `nm.carbon`'s lists `FunctionDecl ... operator* 'Carbon::Money (int,
Carbon::Money)'` and `operator-= 'void (int &, Carbon::Money)'` in `namespace
Carbon` (`v3`). Probes of single features, re-run on `v5` (`$F/probes/P/`): a
class in a Carbon namespace with an `extend impl` in its body (`e5_namespace`)
prints `42` through `Carbon::Units::Money`; a derived class whose base has the
impl (`e11_base`) prints `42` (C++ member lookup reaches the base; §1.7); a
non-member operator whose operand is a nested class prints `42` (M-24).

**M-8. Golden blast radius: none.** file_test in test mode over the whole
manifest (1942 files) from this worktree: trunk 1942 passed; `v1`, `v3`,
`v3`-final and `v4`, 1942 passed each (`$X/ft-*.log`); `v5`, 1942 passed
(`$F/ft-v5f.log`, 76.6 s wall time; and `$F/ft-v5.log` for the first link),
`.failed` lists empty. No existing golden applies a C++ operator to an exported
Carbon class, and none evaluates a Carbon operator whose operands mix a C++ type
with a Carbon class that has an operator impl (the only paths §2 reaches), so no
existing golden gains or loses a line; §4 lists no refills. M-8 shows that no
existing golden moves; it does not cover the shapes of M-20 to M-26, which the
goldens did not contain and which §2.5's new splits now pin (amended 2026-10-14,
review fold: B-1). Re-run on `v6`: 1942 passed, `.failed` empty, 46.5 s wall
time (`$G/ev/ft-v6.summary`; amended 2026-10-14, review fold: RR-1, RR-3, RR-5).
Re-run on `v7`: 1942 passed, `.failed` empty, 71.2 s wall time
(`$L/ft-v7f.log`; amended 2026-10-14, review fold: RR2-1, RR2-2). Re-run on
`v8`: 1942 passed, `.failed` empty, 38.5 s wall time (`$Y/ft-v8.log`; amended
2026-10-14, review fold: RR3-B1, RR3-B2).

**M-9. Carbon-only code, and why rev 1's fix was not enough.** Carbon's own
operator expressions ask C++ whenever an operand is a C++ type (§0.1 row 9),
and Clang's operator lookup then asks the exported Carbon class (M-4). With
`v3`, which exported an unmappable impl after its per-function TODO (the
landed OV-3 behavior, D-OV-18), `$X/probes/side/side2.carbon` — `impl Money as
Core.AddWith(Cpp.Foo) where .Result = (i32, i32)` and the Carbon-only function
`CarbonSide`, which returns `(m+f).0` — fails with `side2.carbon:7:3: error:
semantics TODO: 'failed to map Carbon return type to C++ type'`; trunk accepts
it. `v4` omitted an impl whose signature mapped to null before building
anything (`IsOperatorSignatureMappable`) and accepted `side2.carbon`; but that
predicate mapped every type with `MapToCppType`, which exports a class and can
diagnose, and `v4` still exported every operator of the class during Carbon's
own lookup, so five more Carbon-only shapes that trunk accepts failed on `v4`
(M-20, M-22, M-23). `v5` exported nothing during Carbon's own call of
`LookupOverloadedBinOp` and cached no answer for it (D-OX-21): `side2.carbon`
and every shape of M-20, M-22 and M-23 compile on `v5` and `v6` as on trunk,
pinned by the `carbon_side_*` splits (M-12). But Clang deduces a template
candidate's arguments later, in `BestViableFunction` (§0.1 row 15), which `v5`
ran after clearing the flag, so a Carbon-only expression could still export
through a lookup nested in that deduction and be rejected (RR-1); `v6` holds the
flag across overload resolution, and no impl's signature is mapped for a
Carbon-only expression at all (M-31; amended 2026-10-14, review fold: RR-1) (rev
1 said the
silent omission was the fix and that R-1's third shape would be a BLOCKER, which
review A found; amended 2026-10-14, review fold: A-1, B-1). On `v7` there is
no flag (D-OX-21 at rev 4): Carbon's own lookups export as any lookup does, and
no export can diagnose, because nothing that names a class C++ cannot export is
declared (D-OX-9); `side2.carbon` and every Carbon-only shape of M-20, M-22,
M-23 and M-31 compile on `v7`, and the second re-reviewer's a1, a4, b1, c1 and
c3, which `v6` rejected at `Holder`, compile and run (M-37) (amended
2026-10-14, review fold: RR2-1, RR2-2). On `v8` the third re-reviewer's nine
Carbon-only programs whose sibling impl names `str`, `Core.Slice` or
`Core.Result` without the header that declares its C++ type, which `v7`
rejected with the mapping's TODO, print trunk's values (M-41; amended
2026-10-14, review fold: RR3-B1).

**M-10. Carbon operator expressions keep calling the impl.** With `v1`,
`$X/probes/mixed/mixed.carbon`'s Carbon function `m+f` (`impl Money as
AddWith(Cpp.Foo)`) lowered to `call void
@_ZNK6Carbon5MoneyplE3Foo.carbon_thunk.__`: Carbon's lookup found the exported
`Money::operator+(Foo)` as the best C++ candidate and called the impl through
the C++ operator and two thunks (§0.1 row 9 replaces the Carbon witness with a
C++ one). `v2` to `v4` added a guard that declined such a best viable function
after overload resolution, in the `OR_Success` arm only; it missed an ambiguous
result (M-22) and the synthesized non-member `!=`, which it did not recognize
(M-26). `v5` replaced it (D-OX-11): Carbon's lookup exported nothing (D-OX-21),
and an operator C++ code exported earlier was marked non-viable before
`BestViableFunction`, recognized by its `clang_decls` registration, the default
`!=` included. That missed a C++ template that only an operator exported during
the deferred deduction made viable (RR-2, M-31); `v6` holds the flag across
`BestViableFunction` and repeats the removal after it (M-32), so for a
Carbon-only program every `OverloadingResult` is the one Clang gives without
exported operators (amended 2026-10-14, review fold: RR-2). `mixed.carbon`
prints `42 42` on `v5` and `v6`; the lower
splits `carbon_side_cpp_operand` (`_CCarbonSide.Main` calls
`_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core` directly, after `AddInCpp`
exported `Money::operator+(Foo)`) and `carbon_side_default_not_equal` (M-26) pin
it. Rev 1's accepted side effect, the unused
`_COp__carbon_thunk.Money.Main:AddWith.1ea11ae296c4d4df.Core` that the
Carbon-only `$X/probes/side/side.carbon` defined (§7 R-5), is gone: the
LLVM IR of `side.carbon` (`--phase=lower --dump-llvm-ir`) has 2 definitions
and no `carbon_thunk` on trunk and on `v5`, and 3, one a thunk, on `v4`
(`$F/probes/R5/`; amended 2026-10-14, review fold: A-3, A-4, B-1). On `v7` the
two removal passes stand without the flag, and the notes of a rejected
expression leave exported operators out (D-OX-11; RR2-3); `mixed.carbon` prints
`42 42`, and `carbon_side_cpp_operand`'s `CarbonSide` still calls
`_COp.Money...` directly. Because Carbon's lookups now export, a module can
define the Carbon thunk of an operator that nothing calls: `side.carbon`
defines 3 functions on `v7`, one a `_COp__carbon_thunk`, as on `v4`, where
trunk and `v6` define 2, and its `CarbonSide` calls the impl as on trunk (M-40)
(amended 2026-10-14, review fold: RR2-1, RR2-3). On `v8` Carbon's lookup first
resolves with the exported operators present and, when C++ selects one with
every operand an exact match, returns no C++ operator, so the impl lookup
selects the impl; `mixed.carbon` prints `42 42`, `carbon_side_cpp_operand`'s
`CarbonSide` calls `_COp.Money...` directly, and `side.carbon` defines 3
functions as on `v7` (M-40) (amended 2026-10-14, review fold: RR3-B2).

**M-11. The edges, each measured on `v4` and re-run on `v5` unless named.** (a)
A generic impl, `impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)`
(`e1_generic`): C++ `m*3` fails `invalid operands to binary expression
('Carbon::Money' and 'int')` on `v4` and `v5`, and `overload resolution selected
deleted operator '*'` on `v6`, whose deleted operator template stands for the
generic impl (D-OX-22); Carbon's `m*3` compiles; with a concrete `impl Money as
MulWith(i64)` beside it, C++ on `v5` converts and calls that one, and on `v6`
rejects the use (M-28, M-32; amended 2026-10-14, review fold: RR-3). (b) An
impl declared after the `inline Cpp` block that uses it (`e3_after`): `invalid
operands`, as C++ itself would reject a use before the declaration. (c) A
second impl of an operator declared after C++ code looked that operator up
(`e4_cache`): the second block's `m+40` fails with `invalid operands ...
('Carbon::Money' and 'int')` and a note naming only the first impl's candidate
(M-4's caching); a Carbon expression in between does not cause this on `v5`
(M-23). (d) A class imported from another library (`e6`, two units through
`bin/mrun.sh`): C++ `m+m` fails `invalid operands`, because only
`context.impls()` is walked and the library's impls are not imported (W-204);
and the class itself is exported wrongly on trunk and on the nightly — `e6b`
(`.cents` of an imported class) fails `no member named 'cents' in
'Carbon::Money'`, and `e6c` (an exported method `Plus` returning the imported
class by value, then `Get()`) links, runs and prints `-1265344497` on trunk and
`-1536643875` on the nightly where 42 is right: the AST dump shows `class Money
definition ... empty aggregate`, no `FieldDecl`, so a 4-byte Carbon result is
written into a 1-byte C++ object (W-203, filed under the type-export row; an
upstream defect; not re-run). (e) Two impls whose operands map to one C++ type
(`e12_samesig`, `AddWith(i64)` and `AddWith(Cpp.long)`): Carbon itself rejects
the pair (`found non-final impl with the same type structure as another
non-final impl`), and C++ reports `use of overloaded operator '+' is
ambiguous`, the W-118 shape (W-207). (f) C++'s operand conversions
(`e13_conv`): C++ `m*k` with `long k = 3` calls the `MulWith(i32)` impl and
prints `42`, while Carbon's `m*k` with `k: i64` fails `cannot access member of
interface 'Core.MulWith(i64)' in type 'Money' that does not implement that
interface` (`e13b`) — the documented divergence (§1.7), now pinned on both
sides (`arithmetic` and `fail_conversion_carbon_side`; amended 2026-10-14,
review fold: A-9, B-10). On `v7`, (c)'s second block compiles and `e4_cache`
prints `5 42`: every lookup asks again (D-OX-12, M-38) (amended 2026-10-14,
review fold: RR2-1).

**M-12. The new goldens fill, and fail without the feature (re-measured at rev 4
and at rev 5).** `bin/fill.sh` with `v7`'s file_test on the four sources of
§2.5: three autoupdate passes, then test mode, 4 passed (`$L/fill-v7f.*`). Pass
2 changes three files (30, 28 and 6 diff lines: the `[[@LINE...]]` offsets of
`CHECK:STDERR` source snippets in the two check goldens with diagnostics, and
the AST golden's `<line:N:...>` positions) and not the lower golden, which no
longer has a diagnostic above its code; pass 3 equals pass 2, so the fill needs
two passes (R26) and a third is the fixpoint check (rev 3's pass 2 changed all
four, the lower golden's debug locations moving below rev 3's unused-binding
warnings; amended 2026-10-14, review fold: RR2-4). CHECK lines written: 122
(check `operator.carbon`, 1580 lines: the `CHECK:STDERR` of its 17 `fail_`
splits), 217 (`operator_ast.carbon`, 284 lines), 19 (`operator_cxx20.carbon`,
170 lines) and 1701 (lower `operator.carbon`, 2025 lines, with
`--clang-arg=-fno-exceptions`); rev 3's sources wrote 156, 220, 15 and 1215.
Every `fail_` split fails for its intended reason (§4), and no other split has
any diagnostic, a warning included: the unused bindings of rev 2's
`carbon_side_candidates`, rev 3's splits, the AST golden and the lower
`generic_impl` are now named `_` or marked `unused` (rev 3 counted only
`carbon_side_candidates`'s two warnings and missed eight; amended 2026-10-14,
review fold: RR2-4). The same sources under trunk's file_test
(`$L/fill-trunk4.au1`): 29 positive splits fail, 28 names because `non_member`
is a split of both the check and the lower golden: arithmetic,
signature_from_impl_function, compound_assignment, comparison,
move_only_not_equal, bitwise, index, non_member (check), non_member_nested,
namespace, base_class, unmappable_impl, deleted_result_unselected,
unexportable_operand_class, non_member_unexportable_operand, sfinae_detection,
cpp_side_unrelated_impl, carbon_side_then_cpp, carbon_side_trait_sees_export,
non_member_before_operand, impl_after_lookup, operator (the AST golden),
move_only_equality, member, default_not_equal, non_member (lower),
carbon_side_cpp_operand, carbon_side_default_not_equal and generic_impl; and two
`fail_` splits compile there, `fail_user_cpp_operator_ambiguous`, which pins an
ambiguity that only the export creates (W-211; rev 2 and rev 3 did not list it),
and `fail_todo_carbon_side_rewritten_candidate`, which pins a C++20 candidate
that only the export makes viable (M-37). The Carbon-side splits
`carbon_side_unmappable`, `carbon_side_unexportable_class`,
`carbon_side_generic_class`, `carbon_side_unrelated_impl`,
`carbon_side_candidates`, `carbon_side_user_cpp_operator`,
`carbon_side_deferred_template`, the four `carbon_side_*_unexportable` splits
and the lower `carbon_side_template_candidate`, `carbon_side_template_body`,
`carbon_side_call_template` and `carbon_side_conversion_template`, and the
library split `money_lib`, pass on trunk, the four lower ones with other calls
(M-37). Under `v6`'s file_test (the second re-reviewer's
`/dev/shm/ox1-rr2/tc/v6`, `$L/fill-v6r4.au1`) ten rev 4 splits fail, each
catching a `v6` defect or its flag: the four `carbon_side_*_unexportable`
splits, `unexportable_operand_class`, `sfinae_detection` and
`non_member_unexportable_operand` with `Holder`'s TODO,
`carbon_side_trait_sees_export` (the flag kept the trait false), and
`impl_after_lookup` and `non_member_before_operand` (the cached answer);
`fail_todo_carbon_side_rewritten_candidate` compiles there, the flag having
hidden the export from the deduction; and the lower
`carbon_side_template_candidate`'s `CarbonSide` calls the impl instead of the
template (amended 2026-10-14, review fold: RR2-1, RR2-2, RR2-4). Rev 3's and rev
2's measurements of `v5` and `v4` stand for their own sources: under `v5` rev
3's guards `carbon_side_deferred_template` and `todo_carbon_side_memoized_trait`
failed, and under `v4` the file aborted at the move-only splits (`CHECK failure
at .../export.cpp:2152: equal_call.isUsable()`, M-21). Re-measured at rev 5
(amended 2026-10-14, review fold: RR3-B1, RR3-B2, RR3-M1): `bin/fill.sh` with
`v8`'s file_test on rev 5's sources, three autoupdate passes, then test mode, 4
passed (`$Y/fill-v8.*`); pass 2 changes the same three files by 30, 28 and 6
diff lines and pass 3 nothing. CHECK lines: 122 (check `operator.carbon`, 1715
lines), 217 (`operator_ast.carbon`, 284 lines, byte-identical to `v7`'s fill),
15 (`operator_cxx20.carbon`, 208 lines; the renamed
`carbon_side_rewritten_candidate` has none) and 2228 (lower `operator.carbon`,
2676 lines). No positive split has any diagnostic and every `fail_` split fails
(`bin/splits.py` prints nothing). Under trunk's file_test
(`$Y/fill-trunk.snap1`) 33 positive splits fail, 32 names: rev 4's 29 and
`str_operand_without_header`, `self_referential_operand`, and the lower
`carbon_side_call_template_body` and `carbon_side_agrees_with_cpp_side`;
`fail_user_cpp_operator_ambiguous` still compiles there, and the renamed
`carbon_side_rewritten_candidate` and the other new Carbon-side splits pass, as
Carbon-only programs that trunk accepts should. Under `v7`'s file_test (the
third re-reviewer's `/dev/shm/ox1-rr3/tc/v7`, `$Y/fill-v7.snap2`) seven splits
fail, each on a defect rev 5 fixes: `carbon_side_str_operand_without_header`,
`str_operand_without_header`, `carbon_side_result_without_header` and
`carbon_side_slice_field` with the mapping's TODO or `<carbon/expected.h>` error
(M-41), `self_referential_operand` with `overload resolution selected deleted
operator '+'` (M-42 (a)), and `carbon_side_rewritten_candidate` and
`carbon_side_rewritten_ordering` with W-045's TODO for a rewritten candidate;
and four lower splits' Carbon functions call a C++ template where `v8`'s call
the impl: `carbon_side_template_candidate`, `carbon_side_template_body`,
`carbon_side_compound_template` (the template's `operator+=`, which assigns
nothing) and `carbon_side_agrees_with_cpp_side` (both templates).

**M-13. Conformance (re-run on `v5`).** Trunk, the 150 programs of record: 128
PASS / 0 FAIL / 22 SKIP, 48/56 bullets (`$X/conf-trunk`; the floor of record).
`v4`, the same programs: 128 / 0 / 22, 48/56 (`$X/conf-v4-current`). `v5`, the
program tree with §2.6 applied (`$F/progs-full`: the arbiter un-SKIPped, six new
programs, rev 2's compare and nonmember programs and headers): 135 PASS / 0 FAIL
/ 21 SKIP over 156, 49/56 bullets, the row's bullet PASS with 7 programs
(`$F/conf-full-v5`). Trunk on the seven: 7 COMPILE-FAIL (`$F/conf-progs-trunk`).
`runner.py --self-test --programs $F/progs-full`: 156 programs parsed, 56
bullets, one error, the stale README program table that commit 5 regenerates
(§3). Re-run on `v6` over the same tree (whose seven programs equal §2.6's
byte for byte): 135 / 0 / 21 over 156, 49/56 (`$G/ev/conf-full-v6.log`; amended
2026-10-14, review fold: RR-1, RR-3, RR-5). Re-run on `v7` over the same tree:
135 / 0 / 21 over 156, 49/56 (`$L/conf-full-v7f.log`; amended 2026-10-14,
review fold: RR2-1, RR2-2). Re-run on `v8` over the same tree: 135 / 0 / 21
over 156, 49/56 (`$Y/conf-full-v8.log`; amended 2026-10-14, review fold:
RR3-B1, RR3-B2).

**M-14. The programs are not vacuous (re-run on `v5`, three mutants).** Each
mutant is `v5`'s export.cpp with one edit, relinked with `v5`'s other objects
and run over the seven programs (`$F/conf-progs-m1` to `-m3`). M1 swaps the
`AddWith` and `SubWith` rows (`+` calls `SubWith`): cpp_operator_export
COMPILE-FAIL, cpp_operator_export_arithmetic OUTPUT-MISMATCH (prints
`450,950,2100,233,1,-700`), cpp_operator_export_nonmember COMPILE-FAIL. M2 drops
the `!` from the default `!=`: cpp_operator_export_compare OUTPUT-MISMATCH
(`10,10,100,110,1,11,0`: the `!=` line `10` for `101`),
cpp_operator_export_nonmember OUTPUT-MISMATCH (its `!=` line `10` for `101`).
M3 swaps the `EqWith.NotEqual` and `OrderedWith.Less` rows (review A's third
mutant): cpp_operator_export_compare COMPILE-FAIL (`Unknowable`'s `!=` finds no
`Less`), cpp_operator_export_nonmember OUTPUT-MISMATCH (its `<` line `0` for
`100`). The other programs pass under each mutant because they do not use the
mutated rows. With rev 2's encoding, 100·(x op y) + 10·(x op x) + (y op x),
every within-family swap of the comparison operators changes a printed value
(§1.8; rev 1's true/false pairs printed `10` for several swaps; amended
2026-10-14, review fold: A-8). Re-run on `v6`, the same three edits applied to
`v6`'s export.cpp: the same seven outcomes per mutant
(`$G/ev/conf-progs-m*.log`; amended 2026-10-14, review fold: RR-3, RR-5).
Re-run on `v7`, the same three edits applied to `v7`'s export.cpp
(`$K/mut/m*.diff`): M1 and M2 give the same outcomes; M3 makes
cpp_operator_export_compare and cpp_operator_export_nonmember both
COMPILE-FAIL, the second with `use of overloaded operator '<' is ambiguous`
where `v6` printed `0` for `100`, because the swapped table builds the default
`!=` during the `<` lookup, and its reuse looks for it under `operator!=`
(D-OX-12); each mutant still fails the programs it failed
(`$L/conf-progs-m*.log`; amended 2026-10-14, review fold: RR2-1). Re-run on
`v8`, the same three edits applied to `v8`'s export.cpp (`$Z/mut/m*.diff`,
`$Z/bin/mutants.sh`): the seven outcomes of each mutant are `v7`'s
(`$Y/conf-progs-m*.log`; amended 2026-10-14, review fold: RR3-B1, RR3-B2).

**M-15. The un-SKIP is the sketch.** The arbiter's commented body, uncommented,
diffed against §2.6's program from `import Core` to `fn Run`: identical, the C++
comment line included; `Run`'s body is the sketch's "Intended body" verbatim
(two lines). No mechanical repair is needed (R6), and the spelling is the
sketch's (R27).

**M-16. Collisions, by `git apply --check` of the §2.1 to §2.4 diff (re-run on
`v5`, heads of 2026-10-14).** On the five files at claude/carbon-fork-0-1-st
(21307851a, PR 55): applies, two hunks at offset 5 (its 5-line null check at
export.cpp:293-300). At claude/carbon-fork-0-1-sc (0d7ee5c19),
claude/carbon-fork-0-1-op (379f20f67, PR 56), claude/carbon-fork-0-1-op2
(628273444, PR 57), claude/carbon-fork-0-1-dd (fcee90d9b),
claude/carbon-fork-0-1-va (aced92197), the PR 51 to 54 branches and trunk
44761146d: applies with no offset (`$F/applytest/`). At upstream/trunk
66a250ad9 (in /home/user/carbon-lang): export.cpp and export.h apply at
offsets; context.h's hunk does not (upstream's `CppContext` lacks the fork's
`boundary_write_decl` members), nor do generate_ast.cpp's include hunk
(upstream's e476a2bd3 already includes `clang/AST/DeclContextInternals.h`, so
the fork's line is dropped there) and operators.cpp's (the fork's include block
differs): three context refreshes at the next advance. No branch touches
check/cpp/context.h, generate_ast.cpp or operators.cpp, and VA-1's plan names
none of the five files (§6.2). The other files each branch touches are in §6.2
(heads refreshed: rev 1 named SC-1 ee1f905b0, OP-2 c396efeae and DD-1
e27b917c8; amended 2026-10-14, review fold: A-10, B-8). Re-run with `v6`'s diff
(`$H/applytest/`): the same results, at trunk 3eb7f36f0, SC-1 444ccbafe, VA-1
be623188d (its rev 2 plan), the other heads as named, and EV-1, SAFE-1, CM-1 and
UA-2 (cb3ef2e74, adaae4e35, ea573f672, f96fe8a7a); no branch touches any of the
five files except ST-1's export.cpp hunk (amended 2026-10-14, review fold:
RR-1, RR-3, RR-5). Re-run with `v7`'s diff (`$L/applytest/`): it applies with
no offset at f67ab650d, trunk 3eb7f36f0, SC-1 62e25dcdd (local and `origin`),
OP-1, OP-2, DD-1, EV-1, SAFE-1, CM-1, UA-2 and VA-1's `origin` head
ec0b1a7b0; at ST-1 with two export.cpp hunks at offset 5; and at VA-1's local
head 275967b1d, its C4 commit, not yet pushed, with one export.cpp hunk at
offset 12: VA-1 now adds 12 lines to `ExportFunctionToCpp` (export.cpp:1597, a
TODO for exporting a variadic function), so export.cpp has a second contender,
disjoint from OX-1's hunks (§6.2). At upstream/trunk 66a250ad9 only
generate_ast.cpp's and operators.cpp's include hunks fail, and `v7` has no
context.h hunk to refresh (amended 2026-10-14, review fold: RR2-1, RR2-5).
Re-run with `v8`'s diff (`$Y/applytest/`): it applies with no offset at
f67ab650d, trunk 3eb7f36f0, SC-1 395096d51 (local and `origin`), OP-1, OP-2,
DD-1, EV-1, SAFE-1, CM-1 and UA-2; at ST-1 with two export.cpp hunks at offset
5; at VA-1 9a0888ef0, its local and `origin` head, with one export.cpp hunk at
offset 12; and at upstream/trunk 66a250ad9 only generate_ast.cpp's and
operators.cpp's include hunks fail (amended 2026-10-14, review fold: RR3-B1,
RR3-B2).

**M-17. Upstream has not started operator export.** In /home/user/carbon-lang,
`git merge-base 0bdce60a5 upstream/trunk` is c1e83b0b7, the true upstream cut;
`git log c1e83b0b7..upstream/trunk` lists 50 commits (re-run at rev 2: the
same), four under toolchain/check/cpp: e476a2bd3 (exporting names after a lookup
failure: it restructures `FindExternalVisibleDeclsByName` and stops caching
negative lookups), 62f1cc6a3 (`GenericClassType` renamed
`ParameterizedClassType`), 947c1eb52 (`Core.Array`), ae5d1efd1
(`CalleeFunctionInfo` renamed); and 4ab46d448 renames entities for
`-share-cpp-ast`. `git grep CXXOperatorName upstream/trunk --
toolchain/check/cpp` finds only the import direction (import.cpp:1880,
thunk.cpp:400, impl_lookup.cpp:188). OX-1 uses none of the renamed entities; its
names (`ExportOperatorsToCpp`, `ExportNonMemberOperatorsToCpp`,
`IsExportedCarbonOperator`, `CanExportTypeWithoutDiagnostic`) have no
upstream counterpart to align with; e476a2bd3's change is the one to
re-integrate at the next advance: its negative-lookup erasure lets a failed
identifier lookup be asked again, as D-OX-12 lets every operator lookup be
(§6.3; rev 3 named `in_carbon_operator_lookup`, which `v7` removes; amended
2026-10-14, review fold: RR2-1).

**M-18. Ids (re-run at rev 2).** The id-allocation commands of the head, over
76 refs: ledger maximum W-234 (claude/carbon-fork-0-1-sc at 0d7ee5c19); no
allocation of W-202..W-211 or F-017 on any other ref; the mentions are the
reservation text listed in the head; F-016 is OP-2's (rev 1 measured W-232;
amended 2026-10-14, review fold: A-10, B-8). Re-run at rev 3: the same, W-234
now on claude/carbon-fork-0-1-sc and its `origin` copy, both at 444ccbafe
(amended 2026-10-14, review fold: RR-4). Re-run at rev 4 over 77 refs: the
same, SC-1's local and `origin` heads both at 62e25dcdd (amended 2026-10-14,
review fold: RR2-1). Re-run at rev 5 over 77 refs: no allocation of
W-202..W-211 or F-017 on any other ref; the ledger maximum is now W-235, on
SC-1's local and `origin` heads, both at 395096d51 (amended 2026-10-14, review
fold: RR3-B1, RR3-B2).

**M-19. Cost, per family (`v5`, export.cpp line spans with their comments).**
Shared by every family: the entry type and table header (14 + 4 lines),
`IsOperatorImplOfKind` (22), `IsUnmappableWithoutExport` (25), the export kind
and `ClassifyOperatorExport` (9 + 23), `GetImplMemberFunctionId` (25),
`GetExportedOperatorSignature` and `RegisterExportedOperator` (11 + 11),
`BuildCppOperatorDecl` (82), `ExportImplFunctionAsCppOperator` (56),
`ExportImplOperators` (47), `ExportOperatorsToCpp` (29),
`IsExportedCarbonOperator` (17), the generate_ast.cpp arm (39 with its
include), the operators.cpp suppression and filter (21 with two includes) and
the context.h member (11): about 440 lines. Per family, rows of the table:
arithmetic 5, negation 1, bitwise and shift 6, compound assignment 10,
increment and decrement 2, comparison 6 plus `BuildDefaultNotEqualOperator`
(116), and one row for indexing. The non-member form:
`GetCarbonRecordClassType` (20), `ExportNonMemberOperatorsToCpp` (38) and the
3-line condition in `BuildCppToCarbonThunkBody`. Test cost: §4 (splits) and §5
(programs). Compile cost: one walk of `context.impls()` per class (or
namespace) and operator name, the first time C++ code looks that name up there
(M-4), none for a class whose operators C++ never uses, and none for Carbon's
own operator expressions (D-OX-21), plus one `clang_decls` lookup per C++
candidate of each Carbon operator expression with a C++ operand (the filter).
At rev 3 (`v6`; amended 2026-10-14, review fold: RR-1, RR-3, RR-5):
`IsOperatorImplOfKind` 23, `GetImplMemberFunctionId` 26,
`ExportOperatorsToCpp` 38, `IsExportedCarbonOperator` 22, the operators.cpp
hunk 42 (its removal helper 19), `BuildDefaultNotEqualOperator` 126 with the
deleted `!=`, `ExportNonMemberOperatorsToCpp` 49, and the generic impls'
deleted templates 133 (`BuildDeletedOperatorTemplate` 95,
`ExportGenericImplAsDeletedOperator` 38): about 480 shared lines, and 133 for
the generic impls. Compile cost adds, for a Carbon operator expression whose
overload resolution deduced a deleted operator template C++ code exported
earlier, a second `BestViableFunction` over the same candidates. At rev 4
(`v7`; amended 2026-10-14, review fold: RR2-1, RR2-2): the non-diagnosing
predicate, `CanExportTypeWithoutDiagnostic` and
`CanExportClassWithoutDiagnostic` with their wrapper and forward declaration,
229 lines; `ClassifyOperatorExport` 37; `ExportImplFunctionAsCppOperator` with
its result type 70; `GetExportedOperatorInstId` 19;
`BuildDefaultNotEqualOperator` 134; `BuildDeletedOperatorTemplate` 89 and
`ExportDeletedOperatorTemplate` 63; `ExportImplOperators` 51;
`ExportOperatorsToCpp` 43; `ExportNonMemberOperatorsToCpp` 55;
`IsExportedCarbonOperator` 15; the generate_ast.cpp arm 32 with its include;
the operators.cpp hunk 44, its flag scope gone and a notes filter added; and no
context.h member: 1226 lines added in all, 1119 of them in export.cpp. Compile
cost: every lookup of an operator name in a Carbon class or namespace walks
`context.impls()` again (D-OX-12), Carbon's own lookups included, and each
class type of a signature is checked by a SemIR walk of its enclosing scopes,
fields, base and virtual functions. At rev 5 (`v8`; amended 2026-10-14, review
fold: RR3-B1, RR3-B2): `MapsByExportingClass` 33 lines with its comment;
`IsUnmappableWithoutExport` 37 (rev 4: 25); `CanExportTypeWithoutDiagnostic` 60
(77), its recognized-type switch replaced by one loop over the type arguments;
`CanExportClassWithoutDiagnostic` 146 (142) and `ClassifyOperatorExport` 42
(37), which pass the set of classes in progress on; operators.cpp's hunk 70
lines added (44), `IsExactMatchOfExportedCarbonOperator` 17 with its comment
and `FindClangOperator` 8 lines longer; 1294 lines added in all, 1161 of them
in export.cpp. Compile cost adds, for a Carbon operator expression with a C++
operand, one `BestViableFunction` with the exported operators present, the
resolution without them running only when one was viable, and the mapping of
each recognized type of a signature, which looks its C++ type up by name.

**M-20. Review A's side shapes, on trunk, `v4` and `v5` (A-1).** Review A's
probes (`$F/probes/A-side/`), each with `impl Money as Core.AddWith(Cpp.Foo)`
or a sibling: (a) `.Result = Holder`, where `class Holder { var t: (i32, i32);
}`; (b) a further `impl Money as AddWith(Holder)`; (c) `.Result =
Wrapper((i32, i32))`; (d) `.Result = Vec(3)` with `class Vec(N: i32)`; (f) an
unrelated `impl Vec(3) as Core.ImplicitAs(Money)` — each with a Carbon-only
`m + f`. Trunk and `v5` compile all five; `v4` rejects each with a semantics
TODO (`failed to map Carbon type to C++`, `failed to map specific type arg to
C++`, `binding maps to a non-type template parameter`). (g), the same
`ImplicitAs` impl beside a valid C++ `m + m`: trunk `invalid operands` (no
export), `v4` the TODO, `v5` compiles (the walks select impls by interface and
`Self` from SemIR before any type is mapped). (e), a valid C++ `m + m` beside
`impl Money as AddWith(Holder)`: trunk `invalid operands`, `v4` and `v5`
``semantics TODO: `failed to map Carbon type to C++` `` at Holder's tuple field.
That diagnostic is the class's own, as on trunk: `v_trunk_holder_fn1.carbon`,
with no operator, has C++ call an exported `fn Take(h: Holder)` with a `Money`,
and trunk and `v5` both report the same TODO at the same field, because C++
overload resolution completes `Holder` to rank the candidate; so does `m + m`
on `v5`, whose `AddWith(Holder)` candidate it must rank. It is the landed
OV-3 behavior for a member C++ cannot export (D-OV-18), kept by D-OX-9 and
pinned at rev 2 and rev 3 by `fail_todo_unexportable_operand_class` (amended
2026-10-14, review fold: A-1). On `v7` all seven shapes compile, (e) and (g)
included, and (e)'s C++ `m + m` runs: the `AddWith(Holder)` impl is never
declared, the deleted operator template standing for it, so nothing completes
`Holder` and the exact match selects the `Money` impl (D-OX-9 (3);
`unexportable_operand_class`, M-38). OX-1 thereby departs from D-OV-18 for
operators: an overload-set member that names such a class still reports the
class's TODO at a C++ call, and an operator never does (amended 2026-10-14,
review fold: RR2-1).

**M-21. The default `!=` of a move-only class (A-2).** Review A's
`n1_nocopy_default_ne.carbon` (`class Money { var n: Cpp.NoCopy; }`, `NoCopy`
with a deleted copy and a defaulted move constructor, `EqWith(Money)` with
`Equal` only, C++ `std::move(a) != std::move(b)`) aborts `v4` with `CHECK
failure at .../export.cpp:2152: equal_call.isUsable()`, and `n2` (`==` only)
aborts it under `-std=c++20`, where Clang looks `operator!=` up for every `==`.
On `v5` both compile under both dialects (`$F/probes/V/n1_cxx20.carbon`,
`n2_cxx20.carbon`), and `v_ne_nocopy_run.carbon`, which compares
`Carbon::Money{NoCopy(1)}` with `Carbon::Money{NoCopy(2)}` and two equal ones,
prints `10 1` (`!=` then `==`, each 10·(1 vs 2) + (3 vs 3)) under C++17 and
C++20; trunk rejects all four with `invalid operands`. `v5` passes each
by-value parameter on to `operator==` as an xvalue, as a C++ implicit move
does, and builds the body under a `Sema::SFINAETrap`, declaring no `!=` and
diagnosing nothing if the call is still invalid. Pinned by `move_only_not_equal`
(C++17) and `move_only_equality` (C++20) (amended 2026-10-14, review fold: A-2).

**M-22. Carbon-side candidates and hand-written C++ operators (A-3, B-1).**
Review B's `gen.carbon` (concrete `AddWith(i32)` and `AddWith(i64)`, a generic
`AddWith(T)`, and a C++ `Foo` converting to both `int` and `long`),
`enum.carbon` (a C++ enum with `AddWith(i64)`, `AddWith(u32)` and the generic
impl) and `amb.carbon` (the `Foo` impl with a tuple result) print `3` on trunk,
`v5` and `v6`; `v4` rejects all three with `use of overloaded operator '+' is
ambiguous`, because its guard acted only on `OR_Success`. Review A's
`u2_user_cpp_operator_carbon_side.carbon` (a hand-written C++
`operator+(const Carbon::Money&, const Foo&)` beside `impl Money as
AddWith(Cpp.Foo)`, used from Carbon) prints `1042` on trunk and `v5` and is
ambiguous on `v4`. Review B's `userop.carbon` (a hand-written C++
`operator+(const Carbon::Money&, long)` and a C++ enum operand) is rejected on
trunk and `v5` with ``cannot implicitly convert expression of type `Color` to
`i64` `` (Carbon selects the hand-written operator, then cannot convert), and on
`v4` with ``cannot access member of interface `Core.AddWith(Cpp.Color)` ``: the
exported `operator+(int)` outranked the hand-written one and the guard
discarded it, so `v4` changed which C++ function Carbon would call.
`v_member_after_cpp.carbon` (C++ code exports `Money::operator+(Foo)` first, and
a hand-written `operator+(const Carbon::Money&, long)` exists) prints `42 42` on
`v5`. C++-only code is a different matter: review A's
`u1_user_cpp_operator.carbon`, whose hand-written `operator+(const
Carbon::Money&, const Carbon::Money&)` duplicates `impl Money as
AddWith(Money)`, prints `1042` on trunk and is ambiguous on `v4` and `v5`,
because C++ now sees two equally good candidates; that is filed as W-211 and
pinned by `fail_user_cpp_operator_ambiguous` (amended 2026-10-14, review fold:
A-3, B-1; the `v6` results added, RR-2). On `v7` the same: `gen`, `enum`,
`amb`, `u2`, `userop` and `v_member_after_cpp` behave as on `v6`, and `u1` is
ambiguous (M-38) (amended 2026-10-14, review fold: RR2-1). On `v8` the same
(M-41): `u2`'s hand-written operator and the exported one tie, so C++ selects
no exported operator, Carbon's lookup leaves the export out and calls the
hand-written operator (`1042`), and `u1` stays ambiguous for C++ code (W-211)
(amended 2026-10-14, review fold: RR3-B2).

**M-23. A Carbon-only expression and later C++ lookups (A-4).** Review A's
`o1_carbon_side_poisons.carbon` and `o2_without_carbon_side.carbon` differ by
one Carbon function, `CarbonSide`, whose `m + f` sits between `impl Money as
AddWith(Cpp.Foo)` and `impl Money as AddWith(Money)`; a later `inline Cpp`
block applies `a + b` to two `Money`. `v4` rejects `o1` (`invalid operands`,
the note naming only the `Foo` candidate) and compiles `o2`; `v5` compiles both,
because Carbon's lookup leaves no answer cached (D-OX-21). Pinned by
`carbon_side_then_cpp`. The C++-to-C++ order of M-11(c) was unchanged at
rev 2 and rev 3 (W-205) (amended 2026-10-14, review fold: A-4). On `v7`, which
has no flag, `o1` compiles because the C++ lookup asks again, as every lookup
does (D-OX-12), and M-11(c) compiles too (amended 2026-10-14, review fold:
RR2-1).

**M-24. A nested operand class (A-5).** Review A's `n_nested.carbon`, adapted
(`$F/probes/V/v_nested.carbon`: `class Outer { class Inner }`, `impl i32 as
SubWith(Outer.Inner)` and `impl Outer.Inner as AddWith(Outer.Inner)`): `v4`
rejects C++ `50 - Carbon::Outer::Inner::Make(8)` with `invalid operands`
(its walk required the operand's direct parent to be the namespace); `v5`
prints `42 42 42` (member, non-member, and Carbon's own). Pinned by
`non_member_nested` (amended 2026-10-14, review fold: A-5).

**M-25. Signatures (A-7).** Review A's `s1_result_mismatch.carbon`: `impl Money
as AddWith(i32) where .Result = i64 { fn Op(self, k: i32) -> i32 }` and `impl
Money as SubWith(i32) { fn Op(self, k: i64) -> i32 }`. On `v4` and `v5` it
prints `42 1`: Carbon types `m + k` as `i64`, C++ `decltype(m + 1)` is `int`,
and C++ accepts `m - 4294967296L` (the function's `i64` parameter; the impl
body's `k as i32` truncates it to 0), where Carbon's `m - k` needs `k: i32`.
The exported operator is the impl function as written, as an exported method
is, so this is a divergence of D-OX-15's kind, documented and pinned by
`signature_from_impl_function`. `v_noncopy_lvalue.carbon` (`class Money { var
n: Cpp.NoCopy; }`, `AddWith(Money)`): Carbon's `a + b` compiles, and C++'s
`a + b` on two `const Carbon::Money&` fails on `v5` with `call to
implicitly-deleted copy constructor of 'Carbon::Money'`, the by-value operand
of M-5; pinned by `fail_noncopyable_lvalue_operand` (rev 1's §1.7 said C++
rejects nothing Carbon accepts; amended 2026-10-14, review fold: A-7).

**M-26. Carbon's `!=` and the default non-member `!=` (B-1).** Review B's
`ne.carbon` (`impl Cpp.Foo as EqWith(Money)` with `Equal` only, the Carbon
function `CarbonNe(f, m) = f != m`) lowered on `v4` to a call of
`_ZN6CarbonneE3FooNS_5MoneyE.carbon_thunk.__`, through the synthesized C++
`operator!=` (review B's `ne.ll`). On `v5`, `CarbonNe`'s LLVM IR is identical to
trunk's: one call of `_CNotEqual.EqWith.Core.8d8286e58955f8ab`, the interface's
default `NotEqual` for the impl (`$F/probes/B-p5/ne.{trunk,v5}.ll`).
`v_ne_after_cpp.carbon`, where C++ code exports and caches the default
`Carbon::operator!=(Foo, Money)` first, prints `1 0` on `v5`, and the lower
split `carbon_side_default_not_equal` pins that its `CarbonSide` calls
`_CNotEqual.EqWith.Core.8d8286e58955f8ab` while `CppSide` reaches
`_ZN6CarbonneE3FooNS_5MoneyE`: the default `!=` is registered in `clang_decls`
like every exported operator, so the filter recognizes it (amended 2026-10-14,
review fold: B-1). On `v6`, `ne.carbon`'s module has the same function
definitions as trunk's (M-31), and the re-reviewer's `ne_after.carbon`, where
C++ code uses the default `!=` first, prints `10 10 1 0` (amended 2026-10-14,
review fold: RR-2). On `v7`, `CarbonNe` still makes one call, of
`_CNotEqual.EqWith.Core.8d8286e58955f8ab`, and the module also defines
`_CEqual__carbon_thunk.Foo.Cpp:EqWith...`, the Carbon thunk of the `==` that
Carbon's lookup exported, which nothing calls (15 definitions, trunk 14;
M-40); `ne_after.carbon` prints `10 10 1 0` (amended 2026-10-14, review fold:
RR2-1). On `v8`, C++ selects the exported default `Carbon::operator!=(Foo,
Money)` with both operands exact, so Carbon's lookup returns no C++ operator and
`CarbonNe` calls `_CNotEqual.EqWith.Core.8d8286e58955f8ab` once, as on trunk;
the module still defines the unused `==` thunk (15 definitions, M-40), and
`ne_after.carbon` prints `10 10 1 0` (amended 2026-10-14, review fold:
RR3-B2).

**M-27. A result with no C++ form (B-2).** Review B's `sel.carbon`: `impl Money
as AddWith(i32) where .Result = (i32, i32)` and `impl Money as AddWith(i64)
where .Result = i32` returning 1000, with Carbon's `(m + k).0` for `k: i32` and
C++'s `Make(5) + k` for `int k`. `v4`, which omitted the tuple impl, prints `5
1000`: C++ converted `k` to `long` and called the impl Carbon does not select.
Trunk rejects the C++ use (`invalid operands`); `v5` rejects it with
`overload resolution selected deleted operator '+'`, the tuple impl being
declared `operator+(int) const = delete` with a `void` result. Pinned by
`fail_deleted_result`, by `deleted_result_unselected` (a `long` operand still
selects the `i64` impl) and by the AST golden's `operator* 'void (int) const'
inline delete` (amended 2026-10-14, review fold: B-2).

**M-28. A generic impl and C++'s conversions (found folding B-2; corrected at
rev 3).** `$F/probes/V/v_generic_conv.carbon`: `impl forall [T:
Core.ImplicitAs(i32)] Money as MulWith(T)` returning 1 and `impl Money as
MulWith(i64)` returning 2. On `v5`, Carbon's `m * k` with `k: i32` prints `1`
and C++'s `m * k` with `int k` prints `2`: C++ never saw the generic impl and
converted `k` to `long`, B-2's hazard for a generic impl. Rev 2 kept that on the
premise that no deleted declaration can cover a generic impl, which is false
(RR-3): the re-reviewer's `$RR/dt.cpp` declares `int operator*(long) const`
beside `template <typename T> void operator*(T) const = delete;`, and the trunk
install's `carbon clang -- -fsyntax-only -std=c++17` rejects `m * k` for an `int
k` with `overload resolution selected deleted operator '*'` ("candidate function
[with T = int] has been explicitly deleted") and accepts it for a `long k`, a
non-template exact match being preferred to a template's
([over.match.best.general]; re-checked by the rev 3 fixer). On `v6` (D-OX-22)
`v_generic_conv.carbon` fails at C++'s `m * k` with that error, Carbon's `m * k`
is unchanged, and C++'s `m * 3L` still calls the `i64` impl (M-32). Pinned by
`fail_generic_impl_conversion`, `fail_generic_impl_conversion_non_member` and
the lower split `generic_impl` (rev 2's `generic_impl_hidden`):
`_CCarbonSide.Main` calls the generic impl's specific,
`_CCarbonSideCppOperand.Main` its specific for `Cpp.Foo`, and
`_ZNK6Carbon5MoneymlEl`, for a `long` operand, the `i64` impl's thunk (amended
2026-10-14, review fold: B-2, RR-3).

**M-29. Impls with no Carbon class among their types (B-3).** Review B's
`foreign.carbon`: `impl Cpp.Foo as Core.AddWith(i32)` and `impl Cpp.Foo as
Core.Negate`, both concrete impls of this file. C++ `MakeFoo(40) + 2` fails
`invalid operands to binary expression ('Foo' and 'int')` on trunk, `v4` and
`v5`, and `-MakeFoo(42)` `invalid argument type 'Foo' to unary expression`:
C++'s argument-dependent lookup for `Foo` and `int` never asks namespace
`Carbon`. Filed as W-210, pinned by `fail_todo_non_carbon_operands`, and the
criterion is narrowed to impls whose `Self` or operand is a Carbon class (the
head; D-OX-4) (amended 2026-10-14, review fold: B-3).

**M-30. Every other probe, re-run on `v5`.** The 69 programs of
`$F/probes/list3.txt` (the reviewers', the planner's and the fixer's) on trunk
and `v5` (`$F/runs-trunk3.log`, `$F/runs-v5f.log`): every C++ use of an
exported operator that M-7 and M-11 list behaves as stated; review A's
generic-function, impl-body, generic-class-method and self-recursive probes
(`A-ctx/g1` to `g4`) print `42`, `43`, `42` and `42` on trunk and `v5`; the
adapter probe (`A-adapt/a1_adapter`) fails on trunk and `v5` alike, in Carbon
(cannot copy a value of type Meters, before any export); `x2` (an `extend
impl` member named from C++ as `a.Op(b)`) fails `no member named 'Op'` on trunk
and `v5`, the impl member having no identifier export, and `x1`, which adds the
operator form, fails on `v5` only at `a.Op(b)`. Re-run on `v6`
(`$G/runs-fx-v6.log`): identical to `$F/runs-v5f.log` except `e1_generic` and
`v_generic_conv`, now rejected at their C++ use (M-32); the re-reviewer's 26
probes on trunk and `v6` are `$G/runs-rr-trunk.log` and `$G/runs-rr-v6.log`
(amended 2026-10-14, review fold: RR-1 to RR-6). Re-run on `v7`: M-38.

**M-31. Overload resolution's deferred deduction, and the scope of
Carbon's lookup (RR-1, RR-2).** Clang 21 records a function-template
candidate of an operator's candidate set as deferred and deduces it in
`BestViableFunction` (§0.1 row 15), and `v5` cleared
`in_carbon_operator_lookup()` before calling it, so a lookup nested in
that deduction (libc++'s `__optional_eq_t` check of `Money == int`, or an
inline SFINAE trait's `T + T`) exported Money's operators during Carbon's
own expression. The re-reviewer's Carbon-only probes (`$G/probes/RR/O`
and `T`), on trunk, `v5` (the re-reviewer's `$RR/install-rr`, and rev 2's
own `$F/install-v5`, `$G/runs-rr-v5.log`) and `v6`: `o2_optional_holder`
(`m == o` for `o: Cpp.std.optional(i32)`, beside a sibling
`EqWith(Holder)`) prints `0`, fails with `Holder`'s TODO, and prints `0`;
`t5_carbon_only_holder` (a hand-written `template <class T, typename
EnableIf<HasPlus<T>::value>::type = 0> int operator+(const T&, const
Foo&)`, `impl Money as AddWith(Cpp.Foo)`, a sibling `AddWith(Holder)`,
Carbon-only `m + f`) prints `7`, fails with the TODO, and prints `7`;
`o3_optional_observable` prints `1`, `0` and `1`, and `t4_carbon_only`
`7`, `102` and `7`, where `v5` selected a libc++ or hand-written C++
template that only the operator exported during its deduction made
viable, and lowered through that export (`$RR/ll/o1.rr.ll` uses
`_ZNK6Carbon5MoneyeqENSt2_C8optionalIiEE`). `v6` runs
`LookupOverloadedBinOp` and `BestViableFunction` inside one
`SaveAndRestore` (the re-reviewer's `$RR/v5b/operators-scope.diff`,
clang-formatted): the five probes behave as on trunk, and the LLVM IR of
`ne`, `o1_optional`, `o3_optional_observable`, `t4_carbon_only` and
`side` (`--phase=lower --dump-llvm-ir`) has trunk's function definitions,
each identical to trunk's once debug-location and attribute-group
references are removed (`$G/ev/ll/`). The re-reviewer's relink of the
scope change alone (`$RR/install-v5b`) measured the same for those probes
and the 69 of M-30 identical to `v5`'s. Pinned by
`carbon_side_deferred_template` (t5's shape without a std header; it
fails on `v5`) and the lower `carbon_side_template_candidate` (t4's
shape; on `v5` its `CarbonSide` calls the template's thunk) (added
2026-10-14, review fold: RR-1, RR-2). On `v7`, which has no flag (D-OX-21 at
rev 4): `o2_optional_holder` prints `0`, `t5_carbon_only_holder` `102`,
`o3_optional_observable` `0` and `t4_carbon_only` `102`. No program is
rejected, and t4's and o3's C++ templates are viable through an exported
operator and selected, which rev 4 states as the rule rather than hides
(D-OX-21, M-37): o3's `m == o` calls libc++'s `operator==(const T&, const
optional<U>&)`, which for an empty optional returns false without comparing,
where Carbon's impl returns true, and otherwise compares `m == *o` through the
exported `Money::operator==(std::optional<int>)`, an `int` converting to
`std::optional<int>`; t5's `Holder` impl is stood for by the deleted operator
template, so nothing completes `Holder` (amended 2026-10-14, review fold:
RR2-1, RR2-2). Those two outcomes were not the rule but rev 4's removal of
every export before ranking (RR3-B2, RR3-M1): on `v8`, which resolves first
with the exported operators present, `o2_optional_holder` prints `0`,
`t5_carbon_only_holder` `7`, `o3_optional_observable` `1` and `t4_carbon_only`
`7`, trunk's values, because C++ selects the exported `Money::operator+(Foo)`
or `Money::operator==(std::optional<int>)`, a function that is not a template
and that both operands match exactly, without deducing the template (§0.1 row
15), and Carbon's impl lookup then selects the impl; o3's `CarbonSide` calls
`_CEqual.Money...` (M-40), and the third re-reviewer's k1 and k2 print the same
value for the same expression in C++ (M-41) (amended 2026-10-14, review fold:
RR3-B2, RR3-M1).

**M-32. Generic impls as a deleted operator template (RR-3).** `$G/probes/G` on
`v6` (trunk exports no operator, so every C++ use there is `invalid operands`):
`g1_member_int` (M-28's pair, C++ `m * k` for `int k`) and `g11_generic_only`
(the generic impl alone, `m * 3`) fail with `overload resolution selected
deleted operator '*'`; `g2_member_long` prints `1 2 2 3` (Carbon's `m * k` for
`k: i32` and for `k: i64`, then C++'s `m * k` for `long k` and `m * m2` with a
concrete `MulWith(Money)`: each non-template exact match is preferred to the
template); `g3_nonmember_int` (`impl forall [T: Core.ImplicitAs(i32)] T as
MulWith(Money)` beside `impl i64 as MulWith(Money)`, C++ `k * m`) fails with the
deleted `operator*`, and `g4_nonmember_long` prints `1 2 2`; `g5_compound_int`
(a generic `AddAssignWith(T)` beside `AddAssignWith(i64)`, C++ `m += k`) fails
with the deleted `operator+=`, which is `&`-qualified as the concrete one is,
and `g6_compound_long` prints `1 2`; `g7_eq_int` (a generic `EqWith(T)` with the
default `NotEqual`, C++ `m != k`) fails with the deleted `operator!=`,
`g8_eq_long` prints `0 1`, and `g10_eq_cxx20` prints `1` under `-std=c++20`. The
C++ AST of `g2_member_long` has `FunctionTemplateDecl ... operator*` holding
`CXXMethodDecl ... operator* 'void (type-parameter-0-0) const' inline delete`,
and deleted specializations for `long` and `Carbon::Money` that overload
resolution formed and did not select. A specialization is deduced in
`BestViableFunction`, after the first removal pass (§0.1 row 15), so `v6`
removes recognized specializations again after it and re-resolves when one was
viable: `g9_carbon_after_cpp` (C++'s `m * 3L` exports the template first; then
Carbon's `m * f` for `f: Cpp.Foo`, with `impl Cpp.Foo as ImplicitAs(i32)`)
prints `2 42` on `v6`, and on `n1`, without the second pass, Carbon's `m * f`
fails with `overload resolution selected deleted operator '*'` (added
2026-10-14, review fold: RR-3). Re-run on `v7`: the same (M-38). The template
now also stands for a concrete impl whose operand C++ cannot export (D-OX-22,
M-39), and it is registered under the first impl it stands for, not that
impl's function, so that a later lookup reuses it (amended 2026-10-14, review
fold: RR2-1).

**M-33. Templates instantiated before an export (RR-4).** The re-reviewer's `t1`
to `t3` (`$G/probes/RR/T`) share an inline `HasPlus<T>` trait (`T + T`) and t4's
template `operator+`. On `v6`: `t1_carbon_first` (Carbon's `m + f`, then C++'s
`HasPlus<Carbon::Money>::value`) prints `7 0`; `t2_no_carbon` (the trait alone)
prints `1`; `t3_cpp_first` (the trait first, then Carbon's `m + f`) prints `102
1`, where trunk prints `7 0`. Clang keeps `HasPlus<Carbon::Money>` from its
first instantiation (§0.1 row 15): in `t1` that was Carbon's deduction, which
exports nothing, so the later C++ trait does not see `Money::operator+(Money)`;
in `t3` it was C++ code, which exported the operator, so Carbon's later `m + f`
finds the hand-written template viable and selects it, a C++ function and not an
export. Neither program is Carbon-only, so D-OX-11's break condition does not
fire, but D-OX-11's, D-OX-21's and the page's statements are qualified for them,
and W-205, the residue for what C++ code sees after an earlier lookup, is
extended to cover them. Pinned by `todo_carbon_side_memoized_trait` (t1's order,
with a `static_assert` that the trait is false; on `v5` it fails, because `v5`
exported during the deduction) (added 2026-10-14, review fold: RR-4). On
`v7` `t1` prints `102 1`, `t2` `1` and `t3` `102 1`: the trait has one value
whoever instantiates it first, and `carbon_side_trait_sees_export` (rev 3's
`todo_carbon_side_memoized_trait`, its `static_assert` inverted) pins `t1`'s
order (amended 2026-10-14, review fold: RR2-1). On `v8` `t1` and `t3` print
`7 1` and `t2` `1`: Carbon's `m + f` uses the impl, C++ selecting the exported
`Money::operator+(Foo)` exactly without deducing the template, and the trait,
which C++ code instantiates, sees the export. `carbon_side_trait_sees_export`
therefore has no `Cpp.Foo` impl at rev 5, so that Carbon's resolution of
`m + f` itself deduces the template and instantiates the trait first (amended
2026-10-14, review fold: RR3-B2, RR3-M1).

**M-34. The default `!=` beside a deleted `==` (RR-5).** The re-reviewer's
`ne_deleted_eq2.carbon`: `impl Money as EqWith(i32)` whose `Equal` returns
`(Tag, bool)`, converted to `bool` by `impl (Tag, bool) as ImplicitAs(bool)`, so
its `operator==(int)` is deleted (D-OX-9 (2)), and `impl Money as EqWith(i64)`
whose `NotEqual` returns true. On `v5`, C++'s `Make(5) != k` for `int k` printed
`1` through the `i64` impl, where Carbon's `m != k` for `k: i32` prints `0`; on
`v6` the default `!=` of a deleted `operator==` is declared deleted too, `void
(int) const`, and registered like every exported operator, and C++'s use fails
with `overload resolution selected deleted operator '!='`; so does
`ne_deleted_eq.carbon` (an `Equal` returning `(Money,)`). Pinned by
`fail_deleted_result_not_equal` (added 2026-10-14, review fold: RR-5). The
re-reviewer's Carbon-only `ne_deleted_eq_carbon_only.carbon` aborts in lowering
(`CHECK failure at .../lower.cpp:48: !llvm::verifyModule(...)`) on trunk and
`v6` alike, a pre-existing defect of the `(Money,)`-returning `Equal` unrelated
to export (a fixer observation; see the hand-off).

**M-35. A detection of an operator whose impl names a class C++ cannot export
(RR-6).** The re-reviewer's `sfinae_detect.carbon` (`impl Money as
AddWith(Holder)`, `Holder` with a tuple field, and an inline trait that only
detects `Money + Money`) prints `0` on trunk and is rejected on `v5` and `v6`
with ``sfinae_detect.carbon:8:20: error: semantics TODO: `failed to map Carbon
type to C++` ``: C++ ranks the `Holder` candidate, which completes
`Carbon::Holder`, and a Carbon diagnostic is not a substitution failure. Trunk's
own type export does the same: `$G/probes/S/s1_trunk_sfinae_fn.carbon`, a trait
that detects a C++ call of an exported `fn Take(h: Holder)`, is rejected on
trunk and `v6` with the same TODO at the same field. D-OX-9 (3) counts a
detection as a use, and `fail_todo_sfinae_detection` pins it (added 2026-10-14,
review fold: RR-6). On `v7` `sfinae_detect` prints `0`, as on trunk:
`Money + Money` selects the deleted operator template that stands for the
`Holder` impl, a substitution failure, and nothing completes `Holder`;
`s1_trunk_sfinae_fn` is still rejected, the export of a function not being an
operator's (`sfinae_detection`; amended 2026-10-14, review fold: RR2-1).

**M-36. A non-member operator whose operand class C++ has not yet named (found
by the rev 3 fixer).** `$G/probes/W/w1_namespace_order.carbon`: `impl Money as
MulWith(i32)` and `impl i32 as MulWith(Euro)`; C++ computes `Money::Make(20) *
2`, then `2 * Euro::Make(1)`. On `v5` and `v6` the second fails with `invalid
operands to binary expression ('int' and 'Carbon::Euro')`: the first `*` makes
argument-dependent lookup ask namespace `Carbon` for `operator*` before C++ has
named `Euro`, the non-member walk keeps only impls whose operand class is
already exported (D-OX-3), and Clang keeps the answer (M-4).
`w2_namespace_order_seen`, whose C++ names `Euro` first (as a parameter type),
prints `40 2`. It is an order of C++ code, as W-205's impl declared after a
lookup is, so W-205 is extended to it, and `fail_todo_non_member_before_operand`
pins it (added 2026-10-14, fixer finding). On `v7` `w1` prints `40 2`: the
second lookup asks again (D-OX-12), and `non_member_before_operand` pins it
(amended 2026-10-14, review fold: RR2-1).

**M-37. The second re-review's probes, and the rule (RR2-1, RR2-2).** Its 25
probes (`$RR2/probes`, `$K/lists/atk.txt`) on trunk, `v6` and `v7`
(`$K/runs-atk-{trunk,v6,v7}.log`). Every Carbon-only shape that `v6` rejected
at `Holder` compiles and runs on `v7`: a1 (an unconstrained template whose body
tests `HasPlus<T>`) and a4 (the same, `constexpr`) print `102`, and b1 (a Carbon
call of a SFINAE function template), c1 and c3 (an `as` conversion and an
implicit argument conversion through SFINAE converting constructors) print
`100`, where trunk prints `1`; their siblings without `Holder`, a2, a6, b2, c2
and c4, print the same on `v6` and `v7`; a3 (a template whose body adds
`a+a` when `HasPlus<T>` holds) prints `10` on both, its module calling the
exported `_ZNK6Carbon5MoneyplES0_` from the template (M-40). e4 (Carbon's
`m+f` through a user-defined conversion to `Bar`, whose constructor templates
test `HasPlus`) prints `102` on `v7`, where trunk and `v6` print `3`: the
deduction inside Carbon's own overload resolution sees the export too. e2
(C++20: a hand-written `operator==(const Foo&, const T&)` enabled by
`HasEq<T>`) is rejected on `v7` with ``semantics TODO: `Rewriting operator==
using operator== is not supported` ``, where trunk and `v6` print `1`: the
exported `Money::operator==(Money)` makes the reversed candidate `f == m`
viable, Carbon's lookup selects it, the only C++ candidate that is not an
export, and Carbon cannot call a rewritten candidate yet (W-045's "secondary
==/<=> rewrites"); `fail_todo_carbon_side_rewritten_candidate` pins it. e6 and
e6b are rejected as on trunk, and e6b's notes are trunk's but for the
hand-written template, noted as a candidate rather than a substitution
failure, the export having made it viable; `v6`'s extra `Holder` TODO is gone
(RR2-3). e1 prints `10` on all three, and a5 is rejected on all three for its
`auto` return type. cx1 to cx6, the second re-reviewer's C++ programs, print
`42 33 10`, `42 42 42`, `10 1`, `10 100`, `42 42 10` and `7 42` on `v6` and
`v7`, and cx3b is rejected under C++17, as expected; trunk rejects all seven.
So on `v7` no export emits a diagnostic, and a C++ template behaves one way
whoever instantiates it, where rev 3's flag gave t4 and a1 different answers
to the same question, `HasPlus<Money>`, by whether a template asked it in its
signature or its body, and t1 and t3 different trait values by which side
asked first (M-33). On `v8` (M-41's run; amended 2026-10-14, review fold:
RR3-B2, RR3-M1): a1, a2, a3, a4 and a6 print `7`, and a5, which trunk, `v6` and
`v7` reject for its `auto` return type, prints `7`: C++ prefers the exported
`Money::operator+(Foo)`, a function that is not a template, to the
unconstrained template that ties with it, and Carbon now gives C++'s answer,
the impl, where trunk printed `1` and `v7` `102` or `10`; e2 prints trunk's
`1`, C++ preferring the exported `Money::operator==(Foo)`, which is not
rewritten, to the reversed candidate, so rev 4's
`fail_todo_carbon_side_rewritten_candidate` is the positive
`carbon_side_rewritten_candidate`; b1, b2 and c1 to c4 print `100` and e4
`102`, as on `v7`, because a Carbon call, a conversion and e4's operator
expression, whose only C++ candidate is a hand-written operator reached
through a constructor template, select the function that C++ code selects for
the same question, viable through an exported operator (D-OX-21); e1, e6, e6b
and cx1 to cx6 behave as on `v7`. The pairs of rev 4's argument agree on `v8`
too: t4 and a1 both print `7`, and t1 and t3 both `7 1` (M-33).

**M-38. Every earlier probe, on `v7` (RR2-1, RR2-2).** The 105 single-file
probes of every round (`$K/lists/single.txt`, the second re-reviewer's list)
on `v7` (`$K/runs-single-v7.log`), joined by name with the second
re-reviewer's trunk and `v6` logs (`$K/bin/cmp3.py`): 97 equal `v6`, and the 8
that differ are this fold's: `e_cpp_unrelated` (M-20 (e)) compiles where `v6`
reported `Holder`'s TODO; `sfinae_detect` prints `0`, trunk's result, where
`v6` reported it (M-35); `e4_cache` prints `5 42` and `w1_namespace_order`
`40 2`, because every lookup asks again (M-11(c), M-36); and `t1_carbon_first`
(`102 1`), `t4_carbon_only` (`102`), `t5_carbon_only_holder` (`102`) and
`o3_optional_observable` (`0`) select the C++ template that an export makes
viable, by the rule (M-31, M-33, M-37). `ne_deleted_eq_carbon_only` aborts in
lowering on trunk, `v6` and `v7` alike (M-34). The seven multi-unit probes
(`$K/bin/multi.sh`) behave as on trunk and `v6` (`$K/runs-multi-v7.log`,
`$K/runs-multi-trunk.log`; `e6c` still prints an indeterminate value, W-203).
Re-run on `v8` with the third re-reviewer's 169 probes of every round, which
hold these 105 (M-41, `$Z/runs-all-v8.log`); the seven multi-unit probes behave
as on trunk (`$Z/runs-multi-{trunk,v8}.log`, `e6c` an indeterminate value)
(amended 2026-10-14, review fold: RR3-B1, RR3-B2).

**M-39. The rev 4 fixer's probes (`$K/probes/X` and `Y`;
`$K/runs-x-{trunk,v6,v7}.log`).** `x1_reask_member` (lookups of `+`, `!=`,
`==` and a generic `*` on one class, in two C++ blocks with a Carbon `m+f`
between them) prints `40012 42 2012` on `v6` and `v7`, and
`x2_reask_nonmember`, its non-member form, `42012 42102`: an answer asked again
holds one declaration per impl, one default `!=` and one deleted template,
never a duplicate. `x3_unexportable_operand` (`AddWith(Holder)` beside
`AddWith(Money)` and `AddWith(i64)`) prints `42 2`, and `x3b`, with an `int`
operand, is rejected with `overload resolution selected deleted operator '+'`,
where `v6` reports `Holder`'s TODO; `x4_unexportable_result` (`.Result =
Holder`) is rejected the same way in C++, and its Carbon-only form `x4b`
prints `42` on all three; `x5_nonmember_unexportable` (`impl i32 as
SubWith(Holder)` beside `SubWith(Money)`, C++ naming `Carbon::Holder` through
a pointer) prints `42`, where `v6` reports the TODO; `x6_virtual_operand` (a
class with a virtual function as an operand) prints `42` on `v6` and `v7`, the
predicate admitting it; `x7_cxx20_rewritten` is M-37's e2.
`y1_incomplete_result` (an impl whose function's result class is completed
after the impl, its function never defined) compiles on `v6` and `v7` and fails
to link, the function having no definition; trunk rejects its C++ `+`.

**M-40. What the Carbon-only programs' modules define (`--phase=lower
--dump-llvm-ir`, `$K/ll/`).** On trunk, `v6` and `v7`: `side.carbon` defines
2, 2 and 3 functions and `ne.carbon` 14, 14 and 15, the extra one each time
the Carbon thunk of an operator that Carbon's lookup exported and nothing
calls, their `CarbonSide` and `CarbonNe` calling the impl and the interface's
default `NotEqual` on all three; `t4_carbon_only` defines 14, 14 and 18, its
`CarbonSide` on `v7` calling the hand-written template's specialization,
`_ZplIN6Carbon5MoneyETnN8EnableIf...RK3Foo`, beside the thunks of both
exported operators; `o1_optional` and `o3_optional_observable` define 20, 20
and 33, their `CarbonSide` on `v7` calling libc++'s `operator==`, which calls
the exported `_ZNK6Carbon5MoneyeqENSt2_C8optionalIiEE`; and
`a3_body_route_export` defines 16, 19 and 19, its template calling
`_ZNK6Carbon5MoneyplES0_` on `v6` and `v7`. The lower golden pins these
shapes (§4). On `v8` (`$Z/ll/`; amended 2026-10-14, review fold: RR3-B2,
RR3-M1): `side.carbon` defines 3 and `ne.carbon` 15, as on `v7`;
`t4_carbon_only` 16, `o1_optional` and `o3_optional_observable` 21, and
`a3_body_route_export` 16; each `CarbonSide` and `CarbonNe` calls the impl or
the interface's default `NotEqual`, as on trunk, and every definition `v8` adds
to trunk's is the Carbon thunk of an exported operator that nothing calls
(a3's 16 are trunk's less the template's specialization and its thunk, plus
the two exported operators' thunks).

**M-41. The third re-review's probes, on `v8` (RR3-B1, RR3-B2).** Its 36
probes (`$RR3/p/P`, `K` and `C`, with `k7`, in `$Z/lists_v8.txt`) on trunk,
`v7`, its `v7x` and `v8` (`$Z/runs-all-{trunk,v7,v7x,v8}.log`). RR3-B1's nine
Carbon-only programs, each a Carbon `m + f` (`f - m` in p13, `m != f` in p14)
beside one sibling impl that names `str`, `Core.Slice(i32)` or
`Core.Result(i32, i32)` in a file that does not include the header declaring
its C++ type (p1 to p5, p10, p13, p14 and p18), print trunk's `7`, `7`, `7`,
`7`, `7`, `7`, `4`, `1` and `7` on `v8`, where `v7` and `v7x` reject each with
the mapping's semantics TODO or `exporting Core.Result(i32, i32) to C++
requires #include <carbon/expected.h>`; p1c, the documented C++ use beside p1's
`str` impl, prints `7` on `v8` and is rejected by the same TODO on `v7`; and
p1h, p1 with `<string_view>`, prints `7` on all four. `v8`'s
`IsUnmappableWithoutExport` maps such a recognized type once the Carbon classes
it names pass the predicate, and the null mapping omits an operand's impl (p1,
p3, p13, p14), declares a result's operator deleted (p2, p5, p10), or fails a
field's class, whose impl the deleted operator template then stands for (p4,
p18); the header decides, as `f4` shows the other way (M-42 (c)). The other P
probes behave as on trunk on every build. RR3-B2's programs, each one
expression in Carbon and in C++, now print one value twice: k1 (t4's shape)
`7 7`, k2 (o3's) `1 1`, k4 (`m += f` with a `HasPlus`-gated `operator+=`
template) `7 7` and k7 (a2's) `7 7`, where `v7` printed Carbon's `102`, `0`,
`5` and `102` against C++'s `7`, `1`, `7` and `7`; trunk rejects each C++ side.
The Carbon-only k3b (e2 without `Holder`) and k5 (`m < f` under C++20, with a
hand-written `<=>` template enabled by `HasEq`) print trunk's `1`, where `v7`
reports W-045's TODO, and their C++ sides k3 and k5c print `1`; k4b prints
trunk's `7`, where `v7` printed `5`, the template's `operator+=` silently
dropping the assignment; k6 prints `10` on all four. The C++-side programs c1
to c6 print `42030`, `420042`, `11`, `21`, `4211` and `9111` on `v7`, `v7x` and
`v8`, the values the re-reviewer derived by hand. `v8` differs from `v7x` in
RR3-B1's probes and f1 only (M-42 (a)). Of the 185 probes, those that trunk
accepts and whose result differs on `v8` are D-OX-21's consequences (t2; b1,
b2 and c1 to c4; e4; t1's and t3's trait), C++'s answer for an exported
operator that ties with a hand-written template (a1 to a4, a6 and k7, `7`
where trunk printed `1`), C++ code that W-211 rejects (u1), and the C++ side of
f9 (M-42 (b)); no program that trunk accepts is rejected, and no Carbon
operator expression for which C++ selects an exported operator exactly calls
anything but the impl (added 2026-10-14, review fold: RR3-B1, RR3-B2,
RR3-M1).

**M-42. The rev 5 fixer's probes (`$Z/p/F`, `$Z/runs-all-*.log`, and
`$Y/out-f-v7y`, `$Y/out-f-v8e`).** (a) The predicate's set of classes in
progress and an optional pointer. `f1_self_optional_ptr` (a class `Node` with a
`Core.Optional(Node*)` field, `impl Node as AddWith(Node)` and
`AddWith(Cpp.Foo)`; C++'s `Node::Make(40) + Node::Make(2)`, then Carbon's `m +
f`) prints `42 1042` on `v8`; `v7`, `v7x` and the re-reviewer's `v7y` reject the
C++ use with `overload resolution selected deleted operator '+'`, because the
optional's argument is a `FacetValue` wrapping the pointer, which
type_mapping.cpp unwraps before its pointer test (:271-275) and `v7`'s predicate
did not, so it took the optional for a class of package `Core`, refused that
class, and so refused `Node`: a false refusal in R-9's safe direction.
`f2c_self_slice_ptr_cxx20` (a `Core.Slice(Node*)` field under `-std=c++20`,
where `<span>` declares `std::span`) compiles on `v7`, `v7x` and `v8`, and
`v7y`, whose recognized-type mapping restarts the predicate without the set,
overflows the stack (`rc=139`), as on `f2` and `f2b` (C++17, where `<span>`
declares nothing), which trunk, `v7` and `v8` reject with the class's own TODO
at its field when C++ code completes `Node`. `self_referential_operand` pins
f1's shape. (b) The boundary of RR3-B2's rule. `f3_nonexact_export_template`
(k1's template and `impl Money as AddWith(Money)`, beside `impl Money as
AddWith(Cpp.Bar)` and a C++ `Foo` that converts to `Bar`; one `m + f` in C++,
then in Carbon) prints `7 102` on `v7`, `v7x` and `v8`: C++ selects the exported
`Money::operator+(Bar)` through the conversion, a function that is not a
template being preferred to the template that ties with it, and Carbon, whose
impl lookup has no `AddWith(Cpp.Foo)` and converts no operand, resolves among
the other C++ candidates and selects the template; trunk rejects both sides, as
trunk and `v8` reject `f3b`, the same without the template, in Carbon's impl
lookup. Two other rules were measured. `v8e` (`$Z/v8e/operators.cpp`), which
lets Carbon call such an export, prints `7 7` for f3 and `7` for f3b, its
`CarbonSide` lowering through `_ZNK6Carbon5MoneyplE3Bar.carbon_thunk.__`, and
changes `f9b_base_handwritten_converted_carbon_only` (a hand-written
`operator+(const Carbon::Base&, const Bar&)` for a `Money` that extends `Base`,
where C++ prefers the exported operator, an exact object argument against a
derived-to-base one) from trunk's `102` to `7`; and leaving such an expression
to Carbon's impl lookup, as for an exact match, rejects f9b, which has no
`AddWith(Cpp.Foo)`, where trunk prints `102`. `v8` keeps the boundary: f9b
prints trunk's `102` (f9, Carbon then C++, `102 7`), and f3's Carbon side is a
template that C++ ranks below an exported operator Carbon's own rules cannot
select (D-OX-11, D-OX-21, §7 A-19). (c) The rest.
`f4_str_operand_with_header_cpp` (C++'s `Money::Make(40) +
std::string_view("ab")` with `<string_view>`) prints `42` on `v7` and `v8`;
`f6_optional_ptr_unexportable` (an operand `Core.Optional(Holder*)`) prints `7`
on all four, the predicate refusing `Holder` through the pointer; `f7` and `f7b`
(an `i16` operand) are rejected by Carbon's impl lookup on all four, an `i16`
not being a C++ class type for which Carbon asks C++; `f5` (a
`Core.Result(Owned2, i32)` result) is rejected on all four by Carbon itself,
`function returns incomplete type`, as the re-reviewer's p16 is; and `f8` and
`f8b` (a hand-written `operator+(const Carbon::Money&, long)` reached through a
C++ `operator int()`) abort in lowering on trunk, `v7` and `v8` alike (`handle_call.cpp:984:
args_ok: Argument mismatch`), a pre-existing defect of calling a C++ function
through a conversion function, unrelated to export (see the hand-off) (added
2026-10-14, review fold: RR3-B1, RR3-B2, RR3-M1).

### §0.3 Ledger and brief claims found stale (each corrected where §2 says)

1.  W-054's evidence cites `fork/gap-analysis.md:30`; the row is line 48
    (corrected at discharge, §2.8).
2.  The brief places a 5-line null check in toolchain/check/cpp/export.cpp on
    SC-1's branch; it is ST-1's (PR 55, claude/carbon-fork-0-1-st,
    ExportClassToCpp :293-300); `git diff --stat f67ab650d
    claude/carbon-fork-0-1-sc -- toolchain/check/cpp` prints nothing (§6.2).
3.  The brief describes toolchain/check/cpp/thunk.cpp's `BuildThunkBody`,
    `BuildCalleeCallExpr`, `BuildReturnValueStore` and the catching variants as
    the bodies that call Carbon functions from C++; they are the import
    direction's (Carbon calling C++). The export bodies are export.cpp's
    `BuildCppToCarbonThunkBody` and check/thunk.cpp's
    `BuildThunkDefinitionForExport` (§0.1 row 5). OX-1 edits neither thunk.cpp.
4.  Row 47's evidence and the brief credit the import direction with
    "spaceship rewrites"; a rewritten candidate is a semantics TODO
    (operators.cpp:891-898; the `fail_todo_spaceship_rewrites` and
    `fail_todo_comparison_rewrites` splits of
    toolchain/check/testdata/interop/cpp/operators/), W-045's scope.
5.  The brief lists `Deref` among the families; Carbon has no dereference
    interface for its own types (§0.1 row 10), so there is nothing to export.
6.  The brief allows `<=>` "if the imported-direction rewrite logic suggests a
    symmetric mapping"; the prelude's `OrderedWith` has no `Compare` to export
    (comparison.carbon:24), so `<=>` is W-206.
7.  W-007's notes end "Remaining contender: SC-B3 (W-029)"; OX-1 is a contender
    in export.cpp, landed by the same sequencing (§2.8 appends the record).
8.  DD-1's interoperability README (held, not on trunk) says "The 0.1 toolchain
    implements the first direction", "The other direction is not implemented: a
    Carbon type's operator interface implementations are not exported as C++
    operators (fork work item W-054)" and, in "Using Carbon from C++", "Carbon
    operator implementations are not exported as C++ operators"; all three are
    replaced at OX-1's merge of trunk (§6.2.1; the first added 2026-10-14,
    review fold: B-9).
9.  The commit shape the brief suggests ("toolchain and goldens in one commit if
    either alone breaks file_test") is measured, not assumed: the toolchain
    alone leaves file_test green (M-8), so they are separate commits (§3). Two
    of rev 1's own claims were stale too. Its D-OX-18 and W-208 cited
    docs/project/milestones.md:169, which is a loops bullet; the
    operators-and-conversions line is :200, a standard-library bullet (corrected
    in the head, D-OX-18 and §2.8; amended 2026-10-14, review fold: A-6, B-4).
    And its D-OX-11 recognized a member operator as exported whenever its record
    is Carbon-owned, which also matches Clang's implicit members of that record
    (`operator=`), so `v5` recognizes exactly the declarations registered in
    `clang_decls` (a fixer correction). At rev 3, two of rev 2's claims were
    stale too: M-28 said that no deleted declaration can cover a generic impl,
    which a deleted operator template does (D-OX-22), and D-OX-11 said every
    `OverloadingResult` was the one Clang gives without exported operators,
    which the deduction Clang defers to overload resolution falsified (M-31;
    amended 2026-10-14, review fold: RR-1, RR-2, RR-3). At rev 4, four of rev
    3's claims were stale: §0.1 row 15 named only an operator's candidate set
    as deferring template deduction, which every kind but two does (RR2-2);
    the setup said `CppContext` was constructed only in generate_ast.cpp,
    whose constructor is context.cpp's (RR2-5); §4 and M-12 allowed only
    `carbon_side_candidates`'s two warnings, where the fill had ten (RR2-4);
    and D-OX-11 and D-OX-21 said a Carbon-only program lowers as on trunk,
    which the second re-reviewer's a1 to c4 falsified on `v6` (RR2-1, RR2-2)
    (amended 2026-10-14, review fold: RR2-1 to RR2-5).

### §0.4 Decisions this plan auto-adopts (R29(a): the design recommendation under V-2/V-3, veto-able after the fact)

Each decision carries the one sentence that would break it. D-OX-21 is rev 2's
(amended 2026-10-14, review fold: A-1, A-4); its scope, and D-OX-22, are rev 3's
(amended 2026-10-14, review fold: RR-1, RR-3). Rev 4 rewrites D-OX-12 and
D-OX-21 and amends D-OX-3, D-OX-4, D-OX-9, D-OX-11, D-OX-14, D-OX-16, D-OX-20
and D-OX-22 (amended 2026-10-14, review fold: RR2-1, RR2-2). Rev 5 rewrites
D-OX-11 and amends D-OX-9, D-OX-16 and D-OX-21 (amended 2026-10-14, review
fold: RR3-B1, RR3-B2, RR3-M1).

-   **D-OX-1 (the operator set).** Exported: the members of the `Core`
    interfaces whose Carbon operator has a C++ overloadable counterpart —
    `AddWith`, `SubWith`, `MulWith`, `DivWith`, `ModWith`, `Negate`,
    `BitAndWith`, `BitOrWith`, `BitXorWith`, `BitComplement`, `LeftShiftWith`,
    `RightShiftWith`, the ten `*AssignWith` interfaces, `Inc`, `Dec`, `EqWith`
    (`Equal`, `NotEqual`), `OrderedWith` (`Less`, `LessOrEquivalent`,
    `Greater`, `GreaterOrEquivalent`) and `IndexWith.At`: 31 members, the
    inverse of the import table (operators.cpp:36-209) less what Carbon does not
    route through an interface (`AssignWith`, unused for `=`, :123-128). Not
    exported, each for a stated reason: dereference and address-of (no
    interface), `<=>` (no `Compare` in the prelude, W-206), `As` and
    `ImplicitAs` (conversions, in the bullet but not in 0.1: W-208, which
    bounds the row, D-OX-18; amended 2026-10-14, review fold: A-6, B-4).
    **Breaks if** a `Core` interface of the prelude whose Carbon operator C++
    can overload is missing from the table without a filed reason.
-   **D-OX-2 (member operators).** A complete, non-generic impl whose `Self` is
    exactly the exported class is a member operator of that class's record:
    `const` for a `self` member, `&`-qualified for `ref self`, by-value
    parameters, the result by value — the exported-method mapping unchanged
    (export.cpp:1028-1093), applied to the impl function as declared, which
    can differ from the interface's signature (M-25, D-OX-15; amended
    2026-10-14, review fold: A-7). C++ then finds it by member lookup on the
    left operand only, as Carbon finds an impl by lookup on `Self` only.
    **Breaks if** C++ finds a member operator for an impl whose `Self` is not
    the class, or misses one whose `Self` is (M-7 and the `arithmetic`..`index`
    splits).
-   **D-OX-3 (non-member operators).** A complete, non-generic binary impl
    whose `Self` is not a Carbon class C++ sees as a record of its own (a Carbon
    primitive such as `i32`, which is a recognized type, or an imported C++
    type; decided from SemIR, never by mapping `Self`) and whose interface
    argument is a non-generic Carbon class exported with the namespace `N` as
    its innermost enclosing namespace is a non-member operator `R
    operator@(S, C)` declared in `N`, so C++ finds it by argument-dependent
    lookup on the `C` operand, nested classes included; `operator[]` is
    excluded because C++ requires it to be a member (rev 1 compared the
    operand's direct parent with `N`, which missed a nested class, and mapped
    `Self` with `MapToCppType` before checking the interface; amended
    2026-10-14, review fold: A-5, A-1). **Breaks if** `int-Carbon::Money` (or
    `Foo+Carbon::Money` for an imported `Foo`, or `int-Carbon::Outer::Inner`)
    does not reach the `i32` (or `Cpp.Foo`) impl in C++, whether C++ named the
    operand class before or after its first lookup of the operator in that
    namespace (M-7 `nm.carbon`, M-24, M-36, the `non_member`,
    `non_member_nested` and `non_member_before_operand` splits, the nonmember
    program; rev 3 left the second order to W-205; amended 2026-10-14, fixer
    finding, and review fold: RR2-1).
-   **D-OX-4 (which impls).** Only impls of the checking file's
    `context.impls()`: concrete (no `generic_id`), complete at the time C++
    looks the operator up, of an interface in package `Core` with a row for the
    operator in §1.1's table — tested on SemIR before any type of the impl is
    mapped — and with a Carbon class that C++ sees as a record of its own as
    `Self` (the member form) or as the operand (the non-member form). A generic
    impl is not callable from C++ and is filed (W-202), but the walks declare
    the operator's generic impls as one deleted operator template (D-OX-22;
    amended 2026-10-14, review fold: RR-3); an impl on a specific of a generic
    class (W-202), an impl of an imported library (W-204, blocked by W-203) and
    an impl with no such class among its types (W-210) are filed (amended
    2026-10-14, review fold: A-1, B-3). An impl whose operand or result names a
    class that C++ cannot export without a diagnostic is classified by D-OX-9
    (3) (amended 2026-10-14, review fold: RR2-1). **Breaks if** a concrete,
    complete impl of the file with such a class as `Self` or operand is not
    exported, and its signature names no class that D-OX-9 (3) rejects.
-   **D-OX-5 (the default `!=`).** An `EqWith` impl that does not declare
    `NotEqual` gets `operator!=` built in C++ as `!(a==b)` over the exported
    `operator==`, of the same form (member or non-member); a declared
    `NotEqual` is exported as itself. That is the interface's default body,
    `not self.Equal(other)` (comparison.carbon:14-16,
    comparison_operators.md:260), and C++17, the `inline Cpp` default, has no
    rewrite to supply it (M-6). The body passes each by-value parameter on to
    `operator==` as an xvalue, as a C++ implicit move does, so a move-only class
    has `!=` too (M-21); it is built under a `Sema::SFINAETrap`, and if the call
    is still invalid (a class C++ can neither copy nor move) no `operator!=` is
    declared and nothing is diagnosed; the declaration is registered in
    `clang_decls` like every exported operator, so Carbon's own lookup
    recognizes it (D-OX-11, M-26) (rev 1 passed lvalues and asserted the call,
    which aborted the compiler for a move-only class; amended 2026-10-14, review
    fold: A-2, B-1). Beside an `operator==` declared deleted (D-OX-9 (2)), the
    default `!=` is declared deleted too, with `operator==`'s type, so that C++
    rejects `a != b` rather than convert an operand for another impl (M-34;
    amended 2026-10-14, review fold: RR-5). **Breaks if** C++ `a!=b` and Carbon
    `a!=b` disagree for any impl (the compare program's `Unknown` line and
    M-14's M2), C++ `a != b` selects another impl by a conversion where `==` is
    deleted (`fail_deleted_result_not_equal`), or the compiler stops on a `!=`
    (the `move_only_*` splits).
-   **D-OX-6 (no synthesized candidates).** Because `operator!=` accompanies
    `operator==` (D-OX-5) and no `<=>` is exported, C++20 forms no reversed or
    rewritten candidate, so in every dialect C++ accepts exactly the operand
    orders Carbon has impls for. The one exception is a class C++ can neither
    copy nor move, which gets no default `!=` (D-OX-5), and whose `==` C++ can
    then call only with prvalues anyway. **Breaks if** C++ accepts `5==m` for a
    class that has only `Money as EqWith(i32)`, `m==5` for one that has only
    `i32 as EqWith(Money)`, or `5>m` for one that has only `Money as
    OrderedWith(i32)`, under `-std=c++20` (operator_cxx20.carbon's three
    `fail_reversed_*` splits; rev 1 named only a C++17 split; amended
    2026-10-14, review fold: A-2).
-   **D-OX-7 (statements stay statements).** The compound assignments and
    `Inc`/`Dec` take `ref self`, so they export `&`-qualified and `void`, as
    Carbon's statements produce no value; only prefix `++`/`--` exist, as
    Carbon has no postfix form; `=` is not an interface operator and stays C++'s
    copy assignment. **Breaks if** C++ `a+=b` on an lvalue does not modify
    `a` (the compound program), or a temporary or `a++` is accepted (the two
    `fail_` splits).
-   **D-OX-8 (indexing by value).** `IndexWith(I).At` takes `self` and returns
    a value, so `operator[]` is a `const` member returning the element by
    value; several `IndexWith` impls form one C++ overload set. **Breaks if**
    C++ `t[i]` differs from Carbon `t[i]` for the same impl (the index program).
-   **D-OX-9 (what has no C++ form).** Decided per impl function, after D-OX-4
    has selected the impl and before any type of it is mapped, by
    `ClassifyOperatorExport` (§2.1). (1) An operand (`self` or the parameter)
    whose type has no C++ mapping, decided without exporting anything (a type
    whose mapping stops at a tuple, a struct or another kind `MapToCppType` does
    not map, under `const`, pointer and array wrappers, or a recognized type
    whose C++ type the translation unit does not declare, such as `str` without
    `<string_view>`, mapped once every Carbon class it names passes (3); amended
    2026-10-14, review fold: RR3-B1): the impl is omitted without a diagnostic,
    because C++ cannot form such an operand, so the omission cannot change which
    impl a C++ expression selects. (2) A result with no C++ mapping, decided the
    same way, or an array result, which C++ cannot return by value: the operator
    is declared deleted, with a `void` result, so a C++ expression that would
    select it is rejected (`overload resolution selected deleted operator`)
    rather than resolved to another impl by a conversion (M-27); the default
    `!=` beside it is deleted too (D-OX-5, M-34; amended 2026-10-14, review
    fold: RR-5). (3) A type that names a Carbon class is checked by
    `CanExportTypeWithoutDiagnostic`, which reads SemIR only and repeats the
    checks of the class's export and completion, its enclosing scopes, a
    specific's bindings and arguments, its base, fields and own virtual
    functions, recursively, and answers no for whatever it cannot decide (an
    abstract class, a function type); a recognized type is decided by its own
    mapping, not by a mirror of it: one whose mapping exports a Carbon class
    (`MapsByExportingClass`: a class that is not a recognized type, an
    `Optional` of anything but a pointer) is checked as that class, and any
    other is mapped once the Carbon classes it names pass, a null mapping being
    no C++ form, as in (1) and (2), and a field of that type failing its class
    (M-41, M-42; rev 4 never mapped a recognized type, so its export reported
    the mapping's TODO for `str`, `Core.Slice` and `Core.Result` without their
    headers; amended 2026-10-14, review fold: RR3-B1): an operand whose type it
    rejects is never named, the operator's deleted operator template standing
    for the impl (D-OX-22), and a result it rejects makes the operator deleted,
    as in (2); a non-member impl whose operand class it rejects is not declared
    at all, C++ being unable to form that operand. Nothing declared names a
    class that cannot be exported, so nothing completes one, and no export emits
    a diagnostic, whatever makes the lookup: C++ code, a detection such as a
    SFINAE trait, or a Carbon operator expression, call or conversion (M-37,
    M-39). The predicate errs in the safe direction: a class it wrongly rejects
    makes a C++ use with that operand select the deleted template and be
    rejected, never convert for another impl (§7 A-12). Rev 3 exported such a
    class and let its export report its own semantics TODO at every lookup that
    ranked the operator, the OV-3 behavior of D-OV-18, which the second
    re-review showed rejecting Carbon-only programs through C++ templates, calls
    and conversions (amended 2026-10-14, review fold: RR-6, RR2-1, RR2-2). (4) A
    generic impl has no C++ form at all; the operator's generic impls are one
    deleted operator template (D-OX-22; amended 2026-10-14, review fold: RR-3).
    Rev 1 omitted every impl whose signature mapped to null, decided by mapping
    it, and argued that C++ cannot form an unmappable operand; that argument
    holds for operands only, the mapping itself diagnosed for some classes, and
    the omission of a result-unmappable impl let C++ select another impl
    (amended 2026-10-14, review fold: A-1, B-2). **Breaks if** any export emits
    a diagnostic (the `*_unexportable*`, `carbon_side_*_without_header` and
    `carbon_side_slice_field` splits, `sfinae_detection`, M-37, M-39, M-41), or
    a C++ expression selects an impl other than the one C++ overload resolution
    would select over all of the operator's impls of the file, a generic impl or
    an impl whose operand cannot be exported standing as the deleted template
    (the `fail_deleted_result`, `fail_deleted_result_not_equal`,
    `fail_generic_impl_conversion`, `fail_generic_impl_conversion_non_member`,
    `fail_unexportable_operand_conversion` and `fail_unexportable_result_class`
    splits; rev 2 exempted generic impls on a false premise, M-28; amended
    2026-10-14, review fold: RR-3, RR-5, RR2-1).
-   **D-OX-10 (thunks and symbols).** No new thunk kind: the C++ operator is
    built by `BuildCppToCarbonThunkDecl` under the operator's name, or by
    `BuildCppOperatorDecl` for the non-member form, and calls the generated
    Carbon thunk `<member>__carbon_thunk` in the impl's scope, which mangles by
    the impl's `Self` and interface specific
    (`_COp__carbon_thunk.Money.Main:AddWith.<specific>.Core`, M-4), so two impls
    never share a symbol; the C++ operators are inline, always-inline and
    internal to the translation unit, as exported methods are; a deleted
    operator has no body and no thunk. Two impls whose operand types map to one
    C++ type are two same-signature declarations, ambiguous at every C++ use
    (W-207, the W-118 shape). **Breaks if** two impls' thunks mangle equal
    (lowering would reuse one, the OV-3 R-10 failure).
-   **D-OX-11 (Carbon never calls an export; rewritten at rev 5).** An
    exported Carbon operator is never called by Carbon's own operator lookup.
    `FindClangOperator` first resolves its candidates as Clang does for C++
    code, the exported operators included. When C++ selects an exported
    operator that is not a deleted template's specialization, without a
    rewrite and with every operand an exact match
    (`IsExactMatchOfExportedCarbonOperator`), it returns no C++ operator, and
    Carbon's impl lookup, in `BuildBinaryOperator` and in `LookupCppImpl`,
    selects the impl that the operator calls, so the Carbon expression and the
    same C++ expression call one impl (M-41: t4, o3, t5, e2 and k1 to k7 give
    C++'s value). Otherwise (an ambiguity, a deleted operator template's
    specialization, a rewritten candidate, or an exported operator that C++
    reaches only by converting an operand, which Carbon's impl lookup never
    does, D-OX-15 (1)) it marks every candidate that `IsExportedCarbonOperator`
    recognizes non-viable and resolves again, as often as a resolution
    deduces a viable specialization of a deleted operator template (M-32), and
    leaves exported operators out of the notes of a rejected expression
    (RR2-3); that result is the one Clang gives over the C++ candidates that
    are not exports. So a hand-written C++ operator that ties with an exported
    one, W-211's ambiguity in C++, is still the one Carbon uses (M-22), while
    one that C++ ranks below an exactly matching exported operator, such as
    an unconstrained template, is not: Carbon calls the impl, as C++ does (a1
    to a6, which trunk resolved to the template; M-41). Which C++ functions
    are viable is C++'s question, answered as for C++ code (D-OX-21).
    p006254's "Operator calls" stands: an exported operator is Carbon's own
    impl seen from C++, not a C++ operator function (rev 1 checked only the
    `OR_Success` result, after overload resolution, and missed the
    non-member default `!=`; rev 2's removal ran before the deduction that
    could export, rev 3's flag hid the exports from the deductions of
    Carbon's own operator lookup only, and both promised that a Carbon-only
    program lowers as on trunk, which the C++ templates that Carbon's calls,
    conversions and selections instantiate falsified; rev 4 removed every
    exported operator before ranking, so a template that only an export made
    viable won where C++ selects the export, t4, o3, a1 to a6, e2 and k1 to
    k7, RR3-B2; amended 2026-10-14, review fold: A-3, B-1, B-11, RR-1, RR-2,
    RR-3, RR-4, RR2-1, RR2-2, RR2-3, RR3-B2, RR3-M1). **Breaks if** a Carbon
    operator expression calls an exported C++ operator, gives a result other
    than C++'s where C++ selects an exported operator exactly (the lower
    `carbon_side_cpp_operand`, `carbon_side_default_not_equal`,
    `carbon_side_template_candidate`, `carbon_side_template_body`,
    `carbon_side_compound_template` and `carbon_side_agrees_with_cpp_side`
    splits, the C++20 `carbon_side_rewritten_candidate` and
    `carbon_side_rewritten_ordering`, M-41's k1 to k7), or otherwise differs
    from the one Clang gives over the C++ candidates that are not exports (the
    lower `generic_impl` split, `carbon_side_candidates`,
    `carbon_side_user_cpp_operator`, M-22, M-26, M-32).
-   **D-OX-12 (laziness, and no cache).** Operators are exported when a
    lookup of their name reaches the class or namespace, whatever makes it,
    and Clang is asked again at every later lookup: the external source marks
    the name's entry as having external declarations, empty or not
    (`StoredDeclsList::setHasExternalDecls`, §0.1 row 14), and answers with
    every declaration exported so far and any the file's impls now allow,
    reusing each one built before (`clang_decls` for an impl's operator, the
    previous answer for a default `!=` and a deleted template). So an impl
    declared before a lookup is found by it, whatever lookups came earlier
    (M-11(c), M-23, M-36). What C++ code sees still follows C++'s own order:
    an impl declared after a C++ use is not seen by it (`fail_impl_after_use`),
    and a class-template specialization keeps what was declared at its first
    instantiation (M-33). Rev 1 to rev 3 kept Clang's first answer, so an
    impl declared after a C++ lookup, or a non-member operator whose operand
    class C++ had not yet named, was missed (W-205), and rev 2 and rev 3 kept
    Carbon's own lookups out of the cache with D-OX-21's flag (amended
    2026-10-14, review fold: A-4, RR-4, RR2-1). **Breaks if** an operator C++
    looks up after its impl is complete is not found (the
    `impl_after_lookup`, `non_member_before_operand` and
    `carbon_side_then_cpp` splits), or an answer asked again holds a duplicate
    declaration (M-39's `x1` and `x2`).
-   **D-OX-13 (F-017 and its docs).** The accepted design leaves the operator
    model empty (README :350) and the overview is provisional, so the mapping
    is fork design F-017, documented on a new page,
    docs/design/interoperability/operators.md, with a dated amendment under the
    README's operator section (§2.7); the page, not the README, carries the
    text, because DD-1 rewrites the README (+847 lines, §6.2). **Breaks if** an
    accepted upstream proposal or the leads decide the export differently
    (V-3), or upstream starts operator export (M-17's check, repeated at each
    advance).
-   **D-OX-14 (the row).** Row "Type system: C++ interop — exporting Carbon
    operator overloads into C++" moves MISSING → PARTIAL, expected and not of
    record (R9: the run of record needs Actions). It is bounded by W-208: the
    design overview's operator-overloading interop section maps `ImplicitAs`
    to C++ implicit conversions in the same paragraph as `BitComplement` to
    `operator~` (docs/design/README.md:3676-3681), and conversions are not
    exported in 0.1 (D-OX-18). Every other limit — W-202, W-204, W-206,
    W-207 and W-209 to W-211 — is a generic, cross-library, not-yet-designed,
    non-Carbon or C++-side case, filed under the row as a limit (W-205, the
    ordering case, is not filed at rev 4; amended 2026-10-14, review fold:
    RR2-1); the concrete
    set D-OX-4 names is usable from C++ in both operand positions (M-7, M-13,
    M-24). The bullet's seven programs all PASS while the row is PARTIAL, as
    for OP-1's Optional row (rev 1 recorded DONE and kept PARTIAL as a fallback,
    resting on a miscited milestone line, and referred to precedent rows by
    line number; amended 2026-10-14, review fold: A-6, B-4, B-3, B-8). **Breaks
    if** the plan reviews or the leads read the bullet as excluding conversions
    (then the row is DONE with W-208 a limit, a one-word and one-sentence change
    of §2.8), or a concrete same-file impl of D-OX-1's set and D-OX-4's scope
    does not export (then the row stays PARTIAL with that case filed).
-   **D-OX-15 (divergences, documented).** C++ resolves an exported operator
    under C++'s rules, as it resolves an exported overload set (F-009, OV-3):
    (1) it converts operands (`m*3L` calls `MulWith(i32)`, M-11(f)); (2) it
    searches base classes (`d+d` calls the base's impl, M-7); (3) it sees the
    impl function's own declared signature, so the C++ result type is the
    function's return type where Carbon types the expression by the
    interface's `Result`, and C++ takes the function's parameter type where
    Carbon checks the interface argument (M-25); (4) it copies a by-value
    operand, so a class C++ cannot copy is not an lvalue operand in C++ where it
    is in Carbon (M-25). Carbon's impl lookup does none of these — the
    overview's "edge cases around implicit conversions or overload selection"
    (:3672-3673). Each is pinned on both sides by goldens: (1) `arithmetic`'s
    `3L` assertion and `fail_conversion_carbon_side`; (2) `base_class` and
    `fail_base_class_carbon_side`; (3) `signature_from_impl_function`, whose
    Carbon side is the interface's own typing; (4)
    `fail_noncopyable_lvalue_operand`, whose `CarbonSide` compiles. They are
    goldens, not conformance programs, so R30's two-sided program obligation
    does not arise; the arithmetic and index programs' headers cross-reference
    them (R30(a); rev 1 listed (1) and (2) and pinned (1) on the C++ side only;
    amended 2026-10-14, review fold: A-7, A-9, B-10). **Breaks if** C++ selects
    an impl that no C++ overload resolution over the exported declarations
    would select (that would be a toolchain defect, not a divergence).
-   **D-OX-16 (W-007 discipline).** New functions, one new switch arm
    (generate_ast.cpp, not a contention file), `FindClangOperator`'s first
    resolution with every candidate and its exact-match test, its
    candidate-removal helper and the resolution again without the exported
    operators, and a filter for its notes (operators.cpp, not a contention
    file; rev 2 and rev 3 also added a `CppContext` member in
    check/cpp/context.h and a flag scope, which rev 4 removes; amended
    2026-10-14, review fold: RR-1, RR-3, RR2-1, RR2-3, RR3-B2), and one
    in-function hunk
    in a contention file: the condition
    `target.self_param && isa<clang::CXXMethodDecl>(function_decl)` in
    `BuildCppToCarbonThunkBody` (export.cpp:1247). It is behaviour-preserving,
    because the unchanged line below it casts `function_decl` to
    `CXXMethodDecl` unconditionally whenever `target.self_param` is set, so
    every existing caller already passes a method there; the non-member form is
    the only caller that does not. Nothing is moved or renamed; thunk.cpp (both)
    and type_mapping.cpp are untouched (amended 2026-10-14, review fold: A-1,
    A-3, A-4). **Breaks if** any existing golden changes (M-8: none).
-   **D-OX-17 (programs).** Seven programs for the bullet: the un-SKIPped
    arbiter and one per family (arithmetic with negation, compound assignment
    with increment, comparison, bitwise and shift, indexing, the non-member
    form), each EXPECT hand-derived (§1.8), none with a `.diff.cpp` oracle: the
    agreeing direction needs none (R30(b)), and the divergences live in
    goldens (D-OX-15). Each comparison is printed as 100·(x op y) +
    10·(x op x) + (y op x), a value unique to each of the six operators, so a
    swapped or mis-mapped comparison changes a line (rev 1's true/false pairs
    printed the same `10` under several swaps; amended 2026-10-14, review fold:
    A-8). **Breaks if** a program passes with its family's operator mis-mapped
    (M-14's three mutants are the check).
-   **D-OX-18 (conversions are in the bullet, not in 0.1).** `As(T)` and
    `ImplicitAs(T)` are not exported in 0.1, and the row is PARTIAL for them
    (W-208, D-OX-14). The bullet is read under the design overview, whose
    operator-overloading interop section puts `ImplicitAs(U)` and C++'s
    implicit conversions into the same correspondence as `BitComplement` and
    `operator~` (docs/design/README.md:3679-3681), and proposal p000845 says
    `As` provides the functionality of C++'s `explicit` constructors and
    conversion functions "for interoperability purposes" (:184-187); the
    import table also lists `As` and `ImplicitAs` among the operator interfaces
    (operators.cpp:42-52, "TODO: Support destructors and conversions").
    docs/project/milestones.md:200 lists "operators, conversions" as the
    prelude interfaces the library must provide, and does not bear on the
    interop bullet. Exporting them is not a row of the operator table: C++
    spells a conversion as a conversion function or a converting constructor
    ([class.conv.fct], [class.conv.ctor]) rather than an overloaded operator,
    Clang collects a class's conversion functions from its definition rather
    than by name lookup, so they need an eager export at completion that no
    other export does, and an `impl X as ImplicitAs(C)` would become a
    constructor of `C`, a design choice of its own (rev 1 excluded conversions
    from the bullet on the strength of a miscited milestone line, quoting the
    overview only up to the `BitComplement` sentence; amended 2026-10-14,
    review fold: A-6, B-4). **Breaks if** the plan reviews or the leads read
    the bullet as excluding conversions (then D-OX-14's DONE alternative
    applies), or conversions are exported (then W-208 is discharged and the
    row is re-judged).
-   **D-OX-19 (merge position and the merge of trunk).** OX-1 is cut from
    trunk, not stacked, and merges after DD-1 (PR 58) and PR 57, in the order
    fork/ORCHESTRATION.md records at 3eb7f36f0 (PR 53, PR 51, PR 52, SC-1,
    PR 54 to PR 57, then PR 58 through its state L integration commit, then
    OX-1 and VA-1); before its discharge commit it
    merges trunk (a merge commit, never a rebase) and re-verifies the merge
    commit (§3, §8.8), and that merge applies §6.2.1's three sentence
    replacements in DD-1's README text if DD-1 has merged (rev 1 assumed a
    merge it did not schedule; amended 2026-10-14, review fold: B-5, B-9).
    **Breaks if** DD-1 merges after OX-1; then DD-1's next fold applies the same
    replacements and the ORCHESTRATION stamp says so.
-   **D-OX-20 (no new SemIR, no new diagnostics).** The feature adds no
    instruction kind, no `CARBON_DIAGNOSTIC`, and no SemIR formatting; its
    observable outputs are C++ declarations (the AST golden), generated thunks
    (the lower golden) and Clang's own diagnostics, and no Carbon
    diagnostic: no export emits one (D-OX-9 (3)), and the semantics TODO texts
    that `BuildCppOperatorDecl` keeps from `BuildCppToCarbonThunkFunctionType`
    for a type that does not map are unreachable after the classification
    (rev 3 relied on the existing semantics TODOs of type export; amended
    2026-10-14, review fold: RR2-1). **Breaks if** an implementation
    review finds a case that needs a Carbon diagnostic to be usable (it would
    be added with its own golden split and recorded here).
-   **D-OX-21 (one lookup for everyone; rev 2, rewritten at rev 4, amended at
    rev 5).** A lookup of an operator name in an exported Carbon class or
    namespace exports the same declarations whoever makes it: C++ code,
    Carbon's operator lookup (`FindClangOperator`, §0.1 row 9), Carbon's call
    and conversion resolution (overload_resolution.cpp, `LookupCppConversion`),
    Clang's deduction of a deferred template candidate for any of them (§0.1
    row 15), or a template instantiated at the end of the file. No export can
    be rejected (D-OX-9), no answer is cached (D-OX-12), and Carbon's operator
    expressions never call an export, agreeing with C++ where C++ selects one
    exactly (D-OX-11). So a C++ template sees a Carbon class's exported
    operators whoever instantiates it, and that has three consequences for a
    Carbon-only program, each C++'s own answer to the same C++ question or the
    stated boundary of D-OX-11. A Carbon call or conversion with a C++ callee
    selects the C++ function that an exported operator makes viable (b1, b2,
    c1 to c4, M-37), and the body of a C++ function it calls, instantiated at
    the end of the file, can call the export (the lower
    `carbon_side_call_template_body`). A Carbon operator expression for which
    C++ itself selects a function that is not an export selects it too (e4;
    `carbon_side_trait_sees_export`), and a trait it tests has the same value
    whichever side asked first (M-33). Where C++ reaches an exported operator
    only by converting an operand, which Carbon's impl lookup never does,
    Carbon resolves among the C++ candidates that are not exports, and a
    template that the export makes viable can be selected there (f3: C++ `7`,
    Carbon `102`, trunk rejects both sides; M-42 (b)): calling the export
    instead would lower a Carbon expression through it and change which
    function a program that trunk accepts calls, and leaving the expression to
    the impl lookup would reject that program (f9b; §7 A-19). A module also
    defines the Carbon thunks of the operators that Carbon's lookups exported,
    which nothing may call (M-10, M-40). Rev 4 listed t4, o3, a2, a3 and e2
    here as consequences; they were rev 4's removal of every export before
    ranking, and on `v8` they give C++'s value (D-OX-11, M-41). Rev 2 and rev
    3 set `CppContext::in_carbon_operator_lookup()` while `FindClangOperator`
    resolved a Carbon expression's candidates, so that those lookups exported
    and cached nothing; it is removed, because a dynamic scope cannot tell the
    instantiations Clang performs for a Carbon expression from those it
    performs for C++ code, one `PerformPendingInstantiations` loop
    instantiating both a1's Carbon-selected `operator+<Money>` and cx1's
    C++-selected `Sum<Money>`, and because inside its scope it made a trait's
    value depend on who instantiated it first (§7 A-8, A-18; amended
    2026-10-14, review fold: A-1, A-4, A-3, B-1, RR-1, RR-2, RR-4, RR2-1,
    RR2-2, RR3-B2, RR3-M1). **Breaks if** an export emits a diagnostic
    (D-OX-9), a C++ template behaves differently for C++ code than for a
    Carbon call, conversion or operator expression that C++ resolves to it
    (`carbon_side_trait_sees_export` and the lower `carbon_side_call_template`,
    `carbon_side_conversion_template` and `carbon_side_call_template_body`
    splits), or the leads require Carbon-only programs to lower exactly as on
    trunk: then the calls, conversions and templates above need a mechanism
    that classifies each of Clang's instantiations by its origin, which a
    scoped flag cannot (§7 A-18).
-   **D-OX-22 (the impls C++ cannot call are one deleted operator template;
    rev 3, extended at rev 4).** C++ cannot call a generic impl (W-202), nor
    an impl whose operand names a class that cannot be exported without a
    diagnostic (D-OX-9 (3)), and leaving either out let a C++ operand that
    converts to a concrete impl's parameter type select that impl where
    Carbon selects the one left out (M-28), B-2's hazard. So for the binary
    operator impls of these two kinds whose `Self` is the class, the member
    walk declares one deleted member template `template <typename T> void
    operator@(T) const = delete;` (`&` instead of `const` for `ref self`), and
    for those whose operand is a Carbon class and whose `Self` is not, the
    non-member walk declares one deleted template `template <typename T> void
    operator@(T, C) = delete;` per operand class `C` (`T&` first for `ref
    self`); each is registered under the first impl it stands for, and a later
    lookup reuses it (D-OX-12); `IsExportedCarbonOperator` recognizes a
    specialization by its template. C++ prefers a non-template to a template
    specialization when their conversions tie ([over.match.best.general]), so
    an operand that exactly matches a concrete impl still selects it, and any
    other operand selects the deleted template and is rejected (M-32, M-39). A
    unary impl needs no template: C++ converts no object operand of a member
    operator (amended 2026-10-14, review fold: RR2-1). **Breaks if** C++
    selects a concrete impl by converting an operand that Carbon would resolve
    to an impl the template stands for (`fail_generic_impl_conversion`,
    `fail_generic_impl_conversion_non_member`,
    `fail_unexportable_operand_conversion`), rejects an operand that exactly
    matches a concrete impl (the lower `generic_impl` split,
    `unexportable_operand_class`), or the template is a candidate for Carbon's
    own lookup (`generic_impl`'s `CarbonSideCppOperand`,
    `g9_carbon_after_cpp`, M-32) (added 2026-10-14, review fold: RR-3).

## §1 Design

### §1.1 The export mapping (F-017; D-OX-1)

| `Core` member | C++ | Form when `Self` is the class | Form otherwise (D-OX-3) |
| --- | --- | --- | --- |
| `AddWith(U).Op` | `a + b` | `R operator+(U) const` | `R operator+(S, C)` |
| `SubWith(U).Op` | `a - b` | `R operator-(U) const` | `R operator-(S, C)` |
| `MulWith(U).Op` | `a * b` | `R operator*(U) const` | `R operator*(S, C)` |
| `DivWith(U).Op` | `a / b` | `R operator/(U) const` | `R operator/(S, C)` |
| `ModWith(U).Op` | `a % b` | `R operator%(U) const` | `R operator%(S, C)` |
| `Negate.Op` | `-a` | `R operator-() const` | (unary: none) |
| `BitAndWith(U).Op` | `a & b` | `R operator&(U) const` | `R operator&(S, C)` |
| `BitOrWith(U).Op` | <code>a \| b</code> | <code>R operator\|(U) const</code> | <code>R operator\|(S, C)</code> |
| `BitXorWith(U).Op` | `a ^ b` | `R operator^(U) const` | `R operator^(S, C)` |
| `BitComplement.Op` | `~a` | `R operator~() const` | (unary: none) |
| `LeftShiftWith(U).Op` | `a << b` | `R operator<<(U) const` | `R operator<<(S, C)` |
| `RightShiftWith(U).Op` | `a >> b` | `R operator>>(U) const` | `R operator>>(S, C)` |
| `AddAssignWith(U).Op` .. `ModAssignWith(U).Op` | `+=` `-=` `*=` `/=` `%=` | `void operator+=(U) &` .. | `void operator+=(S&, C)` .. |
| `BitAndAssignWith(U).Op` .. `RightShiftAssignWith(U).Op` | `&=` <code>\|=</code> `^=` `<<=` `>>=` | `void operator&=(U) &` .. | `void operator&=(S&, C)` .. |
| `Inc.Op`, `Dec.Op` | `++a`, `--a` | `void operator++() &` | (unary: none) |
| `EqWith(U).Equal` | `a == b` | `bool operator==(U) const` | `bool operator==(S, C)` |
| `EqWith(U).NotEqual` | `a != b` | `bool operator!=(U) const`, or `!(*this == b)` (D-OX-5) | `bool operator!=(S, C)`, or `!(a == b)` |
| `OrderedWith(U).Less` .. `GreaterOrEquivalent` | `<` `<=` `>` `>=` | `bool operator<(U) const` .. | `bool operator<(S, C)` .. |
| `IndexWith(I).At` | `a[i]` | `E operator[](I) const` | (C++: members only) |

`R`, `U` and `E` are the impl function's own declared return and parameter
types, which Carbon's impl checking lets differ from the interface's
(`Result`, the interface argument, `ElementType`) when they convert (M-25,
D-OX-15); `S` is the impl's `Self` and `C` the exported Carbon class the
interface argument names; each maps by `MapToCppType` (§0.1 row 6), and
D-OX-9 decides what has no C++ form (rev 1 said `R` was the interface's
`Result`; amended 2026-10-14, review fold: A-7). The table is
`OperatorExportTable` (§2.1), one row per interface member with its explicit
parameter count (0 unary, 1 binary) and `OverloadedOperatorKind`; one operator
name can come from two interfaces (`-` from `SubWith` and `Negate`), which
Clang tells apart by parameter count. A generic impl, or one whose operand
C++ cannot export, has no row form: the operator's impls of those kinds are one
deleted template, `void` in either form (D-OX-22; amended 2026-10-14, review
fold: RR-3, RR2-1).

### §1.2 How C++ finds it (D-OX-2, D-OX-3, D-OX-12, D-OX-21)

Clang asks the external source for an operator name in two contexts (M-4): the
left operand's class, for member candidates, and each associated namespace, for
argument-dependent lookup. A new arm of `FindExternalVisibleDeclsByName`'s
name-kind switch answers both: `ExportOperatorsToCpp` for a Carbon-owned record,
`ExportNonMemberOperatorsToCpp` for a Carbon-owned namespace. The arm answers
every lookup the same way, whoever makes it (D-OX-21; rev 2 and rev 3 answered
nothing while Carbon's own operator lookup ran; amended 2026-10-14, review
fold: RR2-1). Each walk visits
`context.impls()` in order and first keeps, from SemIR alone, the impls D-OX-4
admits whose interface has a row for the operator (`IsOperatorImplOfKind`:
complete, non-generic, `Core`, and the table; M-3), so an impl of any other
interface, an `ImplicitAs` impl on a class C++ cannot export among them, is
never mapped (M-20 (g)). The member walk then keeps the impls whose `Self`
constant is the record's class type. The non-member walk keeps the impls whose
`Self` is not a Carbon class C++ sees as a record of its own
(`GetCarbonRecordClassType`: a class type from a Carbon scope that is not a
recognized type such as `i32`), whose one interface argument is such a class,
non-generic, already exported and exportable without a diagnostic (D-OX-9 (3)),
and whose exported declaration has this namespace as its innermost enclosing
namespace (`getEnclosingNamespaceContext`),
where argument-dependent lookup on it looks (M-24; amended 2026-10-14, review
fold: A-1, A-5). For each kept impl and each table row of the operator, the
function the impl declares under the row's member name
(`GetImplMemberFunctionId`: a found entry of the impl's scope, M-3) is
classified (D-OX-9) and exported, declared deleted or omitted, once, and an
exported or deleted declaration is registered in `clang_decls`, keyed by the
declaration and the all-by-value signature and mapped to the function's first
declaration, as `GetOrExportFunctionToCpp` records an exported function
(:1632-1642); the registration is what `IsExportedCarbonOperator` looks up
(D-OX-11). The generic impls a walk meets, and the impls whose operand C++
cannot export (D-OX-9 (3)), are not exported; the walk declares one deleted
operator template for them (D-OX-22), registered under the first of them.
Clang would keep the list per context and name; the arm marks the entry as
still having external declarations, empty or not, so that the next lookup asks
again and receives the declarations built before, reused, beside any new ones
(D-OX-12; rev 3 cached a C++ lookup's answer, an empty one as "none"; amended
2026-10-14, review fold: RR-1, RR-3, RR2-1).

### §1.3 Equality, inequality and ordering (D-OX-5, D-OX-6)

`Equal` exports as `operator==`. `NotEqual` exports as itself when the impl
declares it; otherwise `BuildDefaultNotEqualOperator` declares `operator!=`
beside the exported `operator==`, with its type and parameters, and builds the
body `return !(*this==other);` (a `CXXMemberCallExpr` of `operator==` under
`UO_LNot`, M-12's AST golden) or, for the non-member form, `return !(a==b);`
(a call of the non-member `operator==`), each by-value parameter passed on as
an xvalue (`ImplicitCastExpr <NoOp>` to `xvalue`, as Clang's own implicit moves
are built), under a `Sema::SFINAETrap`; if the call is invalid the declaration
is removed and nothing is diagnosed (M-21; amended 2026-10-14, review fold:
A-2). Beside a deleted `operator==` (D-OX-9 (2)), the default `!=` is a
deleted declaration of the same type (M-34; amended 2026-10-14, review fold:
RR-5). The declaration is registered like any exported operator (M-26; amended
2026-10-14, review fold: B-1). Because both are declared together and no `<=>`
exists, Clang under `-std=c++20` adds no reversed or rewritten candidate (M-6,
operator_cxx20.carbon). The four `OrderedWith` members export one to one; there
is no `Compare` to export (W-206).

### §1.4 Statements and indexing (D-OX-7, D-OX-8)

`*AssignWith`, `Inc` and `Dec` members take `ref self`: the member form is
`&`-qualified (`BuildCppToCarbonThunkFunctionType`'s existing `RQ_LValue`,
export.cpp:1081-1082) and returns `void`; the non-member form takes `S&`
first (`MapToCppParamType` maps a `ref` parameter to an lvalue reference,
:1013-1014), as `int k; k-=m` needs. `IndexWith.At` takes `self`: a `const`
member returning the element by value.

### §1.5 What is not exported, and why (D-OX-1, D-OX-4, D-OX-9, D-OX-18)

| Case | Measured | Reason | Filed |
| --- | --- | --- | --- |
| `As`, `ImplicitAs` | — | conversions are in the bullet (README.md:3679-3681) but are not overloaded operators in C++ and need an eager export at completion (D-OX-18); **bounds the row** | W-208 |
| Generic impl; impl on a specific of a generic class | M-11(a), M-28, M-32 | a generic `Op` needs a C++ template to be callable; meanwhile the operator's generic impls are one deleted operator template (D-OX-22), so C++ rejects an operand Carbon would resolve to a generic impl instead of converting it for a concrete impl; a specific of a generic class exports nothing | W-202 |
| Impls of an imported library | M-11(d) | only `context.impls()` is walked; and an imported class exports as an empty record | W-204 (blocked by W-203) |
| An imported Carbon class at all | M-11(d) | pre-existing: fields are not exported, by-value results corrupt memory | W-203 (type-export row) |
| A template that C++ instantiated before an impl was declared | M-33 | C++'s own rule, as for `fail_impl_after_use`: a class-template specialization keeps what was declared at its first instantiation; every lookup asks again, so an impl declared before a lookup is found (D-OX-12; rev 1 to rev 3 filed the cached answers here, M-11(c), M-36) | (C++'s rule; W-205 unused) |
| `<=>` | §0.3 item 6 | no `OrderedWith.Compare` in the prelude | W-206 |
| Two impls mapping to one C++ signature | M-11(e) | non-injective type mapping; C++ ambiguity | W-207 |
| `a[i] = v` | — | the prelude's `IndexWith` has only `At` (W-109) | W-209 |
| An impl with no Carbon class among its types (`impl Cpp.Foo as AddWith(i32)`, `impl Cpp.Foo as Negate`) | M-29 | C++'s argument-dependent lookup never asks namespace `Carbon`; exporting it needs a declaration in the C++ type's own namespace | W-210 |
| A hand-written C++ operator that duplicates an exported impl | M-22 | C++ sees two equally good candidates; C++ code written before OX-1 to fill the gap is now ambiguous (Carbon's own expressions are not; D-OX-11) | W-211 |
| Postfix `++`/`--`, unary `+`, `!`, `&&`, <code>\|\|</code>, `,`, `->`, unary `*` and `&`, `()`, `=` | the `fail_postfix_increment` split | Carbon has no interface for them | (by design, §2.7) |
| An impl whose operand has no C++ form | M-9, M-41, `unmappable_impl`, `carbon_side_str_operand_without_header` | omitted: C++ cannot form the operand, a tuple, or a recognized type such as `str` whose C++ type the file's headers do not declare (D-OX-9 (1)) | (by design) |
| An impl whose result alone has no C++ form | M-27, M-34, M-41 | declared deleted, and the default `!=` beside it too, a `Core.Result` without `<carbon/expected.h>` among them (D-OX-9 (2)) | (by design) |
| An impl whose signature names a class C++ cannot export | M-20 (e), M-35, M-37, M-39, M-41 | never named: an operand that names it is stood for by the deleted operator template, a result that names it makes the operator deleted, and a non-member impl whose operand class it is is not declared, so nothing completes the class and no export diagnoses; a field with no C++ form, such as a `Core.Slice` without `<span>`, makes a class one (D-OX-9 (3), D-OX-22) | (by design) |

(The W-208, W-210, W-211, D-OX-9 and M-28 rows amended 2026-10-14, review
fold: A-6, B-4, B-3, A-3, A-1, B-2; the generic-impl, W-205, result and class
rows amended 2026-10-14, review fold: RR-3, RR-4, RR-5, RR-6, with the fixer's
M-36 in the W-205 row; the W-205 and class rows amended again 2026-10-14,
review fold: RR2-1; the operand, result and class rows amended 2026-10-14,
review fold: RR3-B1.)

### §1.6 The diagnostic policy (D-OX-9)

No export emits a diagnostic, whatever makes the lookup (amended 2026-10-14,
review fold: RR2-1, RR2-2). `ClassifyOperatorExport` decides each selected impl
function before anything is built or mapped. `IsUnmappableWithoutExport`
strips `const`, pointer and array types to their leaf; a function leaf, and a
class leaf whose mapping exports a Carbon class, are never reported
unmappable, because mapping them exports them; any other type is mapped, a
recognized type such as `str` once the Carbon classes it names pass
`CanExportTypeWithoutDiagnostic`, so that its mapping exports nothing that can
diagnose, and a null mapping, such as `str` in a file without `<string_view>`,
is "no C++ form" (rev 4 never mapped a recognized type, so its export reported
the mapping's TODO; amended 2026-10-14, review fold: RR3-B1).
`CanExportTypeWithoutDiagnostic` then decides from SemIR whether every class a
type names can be exported and completed without a diagnostic, answering no
when it cannot decide. An operand with no C++ form omits the impl; an operand
that names a class it rejects leaves the impl to the operator's deleted
operator template (D-OX-22), as a generic impl is; a result with no C++ form,
an array result or a result that names a class it rejects makes a deleted
declaration, and the default `!=` beside it is deleted too (M-34); every other
impl is exported, naming only classes that export cleanly. Every failure is
then Clang's own diagnostic at a C++ use (`invalid operands to binary
expression`, `no viable overloaded '+='`, `cannot increment value of type`,
`overload resolution selected deleted operator`), with Clang's notes listing
the exported candidates (M-11(c), M-27), and a C++ detection of an operator, a
SFINAE trait among them, is a substitution failure where a use would be
rejected, never a hard error (M-35). Rev 3 exported a class C++ cannot export
and reported its semantics TODO at every lookup that ranked the operator, a
detection and Carbon's own expressions, calls and conversions included (M-20
(e), M-35, M-37) (amended 2026-10-14, review fold: A-1, B-2, RR-3, RR-5, RR-6,
RR2-1, RR2-2).

### §1.7 Carbon's own expressions, and the divergences (D-OX-11, D-OX-15, D-OX-21)

Carbon's operator expressions ask C++ in two places, `BuildBinaryOperator` (and
`BuildUnaryOperator`) before Carbon's impl lookup and `LookupCppImpl` within it
(§0.1 row 9), both through `FindClangOperator`. That lookup exports and asks
again as any lookup does (D-OX-21, D-OX-12), and its candidates are first
resolved as for C++ code. When C++ selects an exported operator with every
operand an exact match, Carbon's impl lookup selects the impl that the
operator calls, so the Carbon expression and the same C++ expression call one
impl (M-41). Otherwise every exported candidate, a deleted template's
specialization included, is non-viable for Carbon and left out of its notes
(D-OX-11, D-OX-22), so the Carbon impl stands where it stood and a
hand-written C++ operator that ties with an exported one is still used (M-22,
M-26), while one that C++ ranks below an exactly matching exported operator,
such as an unconstrained template, yields to the impl, as in C++ (a1 to a6). A
C++ template sees the exported operators whoever instantiates it, so a Carbon
call or conversion, or an operator expression that C++ itself resolves to such
a template, can select a C++ function that an exported operator makes viable,
and that function can call the export; and where C++ reaches an exported
operator only by converting an operand, Carbon, whose impl lookup converts no
operand, resolves among the other C++ candidates, where a template that the
export makes viable can win (M-37, M-40, M-42) (rev 3 said a Carbon-only
program sees exactly the C++ functions it saw before OX-1, which held for its
operator expressions' own deductions only; rev 4 let a Carbon operator
expression select such a template where C++ selects the export exactly, under
C++20 a rewritten candidate that Carbon cannot call yet; amended 2026-10-14,
review fold: RR-1, RR-2, RR-4, RR2-1, RR2-2, RR3-B2, RR3-M1). In C++, the
exported declarations take part in ordinary C++ overload resolution, with the
four documented divergences of D-OX-15: operand conversions, base-class member
lookup, the impl function's own signature, and by-value operands (M-11(f), M-7,
M-25). The first three let C++ accept what Carbon does not; the fourth makes C++
reject an lvalue operand of a class it cannot copy, which Carbon accepts (rev 1
said "C++ rejects nothing Carbon accepts"; amended 2026-10-14, review fold:
A-7). One more C++-side change is not a divergence but a migration: C++ code
that wrote its own operator for an exported class to fill the gap now has two
candidates (W-211, M-22).

### §1.8 EXPECT re-derivation (R16(d): from the program text, never from a run)

Each value below follows from the program's Carbon impl bodies and C++ calls
alone; the runs of M-13 agree, and M-14's mutants disagree.

-   cpp_operator_export: `Make(30)+Make(12)` adds the `value` fields:
    `30+12=42`.
-   cpp_operator_export_arithmetic, from 700 and 250 cents: `700+250=950`;
    `700-250=450`; `700*3=2100`; `700/3=233` (`i32` division truncates toward
    zero, arithmetic.md "Integer types"); `700%3=1`; negation gives `-700`.
-   cpp_operator_export_compound, each from 10: `10+5=15`; `10-3=7`;
    `10*4=40`; `10/4=2`; `10%6=4`; two increments and a decrement give `11`.
-   cpp_operator_export_compare, with a = 1 and b = 2, each line
    100·(a op b) + 10·(a op a) + (b op a): `==` gives 0, 1 and 0, so `10`;
    `!=` 1, 0 and 1, so `101`; `<` 1, 0 and 0, so `100`; `<=` 1, 1 and 0, so
    `110`; `>` 0, 0 and 1, so `1`; `>=` 0, 1 and 1, so `11`; for `Unknowable`,
    value 0 against 1, `Equal` and the declared `NotEqual` are both false, so
    the line is 10·0 + 0 = `0` (the default `NotEqual` would make it 1)
    (amended 2026-10-14, review fold: A-8).
-   cpp_operator_export_bitwise, with x = 12 (`0b1100`) and y = 10 (`0b1010`)
    as `u8`: AND gives `8`, OR `14`, XOR `6`, the complement `255-12=243`, the
    left shift by two `48`, `128>>3=16`; z starts at 3 and becomes 12, 13, 12,
    9 and finally `4` under `<<=2`, `|=1`, `&=14`, `^=5` and `>>=1`.
-   cpp_operator_export_index, fields 7, 8 and 9: `7*100+8*10+9=789`;
    `t[true]` is the `bool` impl (an exact match beats the `bool`-to-`int`
    promotion), the last field, and `t[false]` the first: `9*10+7=97`.
-   cpp_operator_export_nonmember: `50-8=42` (the `i32` impl, `Self` on the
    left; the other order would give `-42`); then each comparison as
    100·(4 op m) + 10·(5 op m) + (6 op m) with m's 5 cents: `==` 0, 1, 0, so
    `10`; `!=`, through `NotEqual`'s default, 1, 0, 1, so `101`; `<` 1, 0, 0,
    so `100`; `<=` 1, 1, 0, so `110`; `>` 0, 0, 1, so `1`; `>=` 0, 1, 1, so
    `11`; `10-3=7` written back to the C++ `int`; `30+3=33` (amended
    2026-10-14, review fold: A-8).

### §1.9 Docs and records (D-OX-13, D-OX-14)

The design text is §2.7: a new page and a dated amendment. The records (§2.8)
are written by commit 5 (the row) and commit 6 (everything else, after the
merge of trunk and its re-verification, §3): W-054 discharged and its evidence
corrected; W-202..W-211 filed; W-007's notes extended; the row's status and
evidence; the header delta; the decision-log entry "OX-1 / F-017" with its
V-3a register entries; fork/ORCHESTRATION.md's stamp and Branches row; the
conformance README's generated table (amended 2026-10-14, review fold: B-5,
B-12).

### §1.10 Residues (ids reserved at the head; full ledger entries in §2.8)

| Id | Title | Bullet | blocked_by |
| --- | --- | --- | --- |
| W-202 | OX-1 residue: generic operator impls are not callable from C++ (an operator's generic impls are one deleted operator template), and the operator impls of a generic class's specifics are not exported | the row | — |
| W-203 | Exporting a Carbon class imported from another library yields an empty C++ record: no fields, and a by-value result corrupts memory (upstream defect) | Type system: C++ interop — importing C++ types / exporting Carbon types | — |
| W-204 | OX-1 residue: operator impls declared in an imported library are not exported to C++ | the row | W-203 |
| W-205 | Not filed at rev 4, reserved and unused: rev 1 to rev 3 filed here what C++ code saw after its earlier lookups, which every lookup asking again removes (D-OX-12); a template instantiated before an impl is declared follows C++'s own rule (M-33) | — | — |
| W-206 | OX-1 residue: `<=>` is not exported; the prelude's `OrderedWith` has no `Compare` | the row | — |
| W-207 | OX-1 residue: two operator impls whose operand types map to one C++ type are ambiguous at every C++ use (the W-118 shape) | the row | — |
| W-208 | OX-1 residue (bounds the row): `As` and `ImplicitAs` impls are not exported as C++ conversions | the row | — |
| W-209 | OX-1 residue: `operator[]` returns by value; the `ref` forms of indexing are not exported | the row | W-109 |
| W-210 | OX-1 residue: operator impls with no Carbon class among their types (a C++ or primitive `Self` with a non-Carbon operand, or a unary impl on a C++ type) are not exported to C++ | the row | — |
| W-211 | OX-1 residue: a hand-written C++ operator for an exported Carbon class that duplicates a Carbon operator impl is ambiguous with the exported operator in C++ | the row | — |

(W-202's and W-208's titles and the W-210 and W-211 rows amended 2026-10-14,
review fold: B-2, A-6, B-4, B-3, A-3; W-202's and W-205's titles amended
2026-10-14, review fold: RR-3, RR-4, with the fixer's M-36 in W-205's; W-205
withdrawn 2026-10-14, review fold: RR2-1.)

## §2 Implementation spec, file by file

### §2.1 to §2.4 Toolchain (four files, one diff; clang-format 21.1.8 clean; compiled and measured as `v8`)

The diff below is `v8` (`$Z/ox1-v8.diff`, sha256
ae0c89ecd1632e6d1efadd0fec223995669737333b99d7259387afae947a7170, 1401 lines):
1294 lines added and 4 removed over export.cpp (+1161, −1), export.h (+31),
generate_ast.cpp (+32) and operators.cpp (+70, −3); check/cpp/context.h, which
rev 2's and rev 3's flag changed, is untouched. Rev 4's `v7` (`$K/ox1-v7.diff`,
1333 lines) differs from it in export.cpp and operators.cpp only, and rev 3's
`v6` (`$G/ox1-v6.diff`, 1033 lines) in every file (amended 2026-10-14, review
fold: RR2-1, RR2-2, RR2-3, RR3-B1, RR3-B2). The copy below is the same diff
after prek, which strips the leading space of a blank context line; it applies
to f67ab650d with `git apply` and yields these files, the identity check
(amended 2026-10-14, review fold: A-10, B-7):

```text
3a470228ac37860f987273a0bea0e4798a20cd690109b79bfbd141900c4fab47  toolchain/check/cpp/export.cpp
81a3b30ec0cc2402319edb63efb6232708818251013075b7d07856f392af63f5  toolchain/check/cpp/export.h
d86af1cc23face4f72e152dd0435d4ab76990f3eba4a2b6083e7a48203865634  toolchain/check/cpp/generate_ast.cpp
1dd7b38d70379ebb44c64e1784e454b170bfb5afae290ba257743e0e186ac233  toolchain/check/cpp/operators.cpp
```

It applies to every live branch's four files, to ST-1's and to VA-1's head
with offsets 5 and 12, and needs two context refreshes on upstream/trunk
(M-16); every file passes `clang-format --style=file` from the CI pin (R18).
Invariants, by hunk (rev 1's `IsOperatorSignatureMappable` and the
post-resolution guard are gone; amended 2026-10-14, review fold: A-1, A-2, A-3,
A-4, A-5, B-1, B-2; rev 3's changes amended 2026-10-14, review fold: RR-1,
RR-2, RR-3, RR-5; rev 4's amended 2026-10-14, review fold: RR2-1, RR2-2, RR2-3,
RR2-5; rev 5's amended 2026-10-14, review fold: RR3-B1, RR3-B2, RR3-m1):

-   **check/cpp/context.h (no hunk at rev 4).** Rev 2's and rev 3's
    `in_carbon_operator_lookup()` member is gone with the flag (D-OX-21), so
    `CppContext`, and the constructor that context.cpp defines for it, are
    unchanged (RR2-5).
-   **export.cpp, the includes and the table (new).** `OperatorExportTable` is
    §1.1; `num_explicit_params` separates `-a` from `a-b`.
    `IsOperatorImplOfKind` is the walks' SemIR-only first test (complete,
    generic or not as the caller asks, `Core`, a table row for the operator
    kind, a binary one for a generic impl); `type_info.h` is included for
    `RecognizedTypeInfo`, and `type_completion.h` for `TryToCompleteType`.
-   **export.cpp, `BuildCppToCarbonThunkBody` (the one in-function hunk,
    D-OX-16).** The `this` argument is passed only for a method; the
    non-member form's first parameter is `self` and is passed by the loop that
    follows like every other parameter, matching the generated Carbon thunk's
    parameter order (`self`, the explicit parameters, the result). For every
    existing caller the new conjunct is true: the body already does
    `cast<clang::CXXMethodDecl>(function_decl)` under `target.self_param`.
-   **export.cpp, the classification (D-OX-9).** `MapsByExportingClass`
    tells the class types whose mapping exports a Carbon class, as
    type_mapping.cpp's `TryMapClassType` does (:196-372): a class that is not a
    recognized type, an `Optional` of anything but a pointer (its argument's
    facet value unwrapped first, :271-275) and an integer type whose bit width
    does not embed. `IsUnmappableWithoutExport` never maps a function type or
    such a class (whose mapping exports it) and maps every other type, a
    recognized type only once `CanExportTypeWithoutDiagnostic` passes it, so
    that the mapping exports nothing that can diagnose; a null mapping, such as
    `str` without `<string_view>`, `Core.Slice` without `std::span` or
    `Core.Result` without `<carbon/expected.h>`, is no C++ form.
    `CanExportTypeWithoutDiagnostic` strips `const`, pointer and array types
    and fails a function type, a symbolic type and an error; a class that
    `MapsByExportingClass` goes to `CanExportClassWithoutDiagnostic`, and any
    other class type, a recognized one, passes if its type arguments do; both
    pass the set of classes in progress on, through `IsUnmappableWithoutExport`
    too. `CanExportClassWithoutDiagnostic`
    repeats from SemIR what exporting and completing the class check: a
    class imported from C++ passes; the class must complete
    (`TryToCompleteType`, which does not diagnose) and must not be abstract;
    each enclosing scope up to one already mapped is a namespace with an
    identifier name or a non-specific class that passes; a specific's bindings
    are types and its arguments map and pass; its base, fields and own
    virtual functions' parameter and return types pass, none of the latter an
    array by value. A class reached again through its own fields, an optional
    pointer's pointee or a slice's element type among them, is decided by the
    outer call (rev 4 never mapped a recognized type and missed the facet value;
    RR3-B1, M-42 (a)). `ClassifyOperatorExport` returns `Omit` for an operand
    with no C++ form, `Template` for an operand the predicate rejects,
    `Deleted` for a result with no C++ form, an array result or a result the
    predicate rejects, and `Export` otherwise; the member form does not check
    `self`, the record's own class.
-   **export.cpp, the shared export path.** `GetImplMemberFunctionId` returns
    `None` for a member the impl leaves to its default and for a name the
    impl's checking poisoned (M-3), and rejects a function with an enclosing
    specific unless the impl is generic, whose functions have one.
    `ExportImplFunctionAsCppOperator` reuses an earlier export through
    `clang_decls`, builds the `FunctionInfo` itself (the impl scope cannot be
    exported, M-2), checks the shape (a `self`, the row's parameter count),
    classifies, and then declares, or reports that the deleted operator
    template stands for the function (`ImplOperatorExport`): a member operator
    to export by the existing `BuildCppToCarbonThunkDecl` with the operator's
    `DeclarationName`, a non-member or deleted one by `BuildCppOperatorDecl`;
    an exported one gets its body from the existing `BuildCppToCarbonThunk`;
    an exported or deleted one is registered (`RegisterExportedOperator`: the
    declaration with the all-by-value signature, mapped to the function's
    first declaration), and `GetExportedOperatorInstId` reads a registration
    back. `BuildCppOperatorDecl` maps each parameter with `MapToCppParamType`
    (a `ref` parameter becomes `S&`), gives a member `const` or `&` as an
    exported method has, and declares it inline, always-inline and
    internal-linkage, or deleted with a `void` result; the semantics TODOs it
    keeps for a type that does not map are unreachable after the
    classification.
-   **export.cpp, the default `!=`.** `BuildDefaultNotEqualOperator` first
    reuses the `operator!=` that an earlier lookup built beside the same
    `operator==` (the context's `noload_lookup` of the name, matched by its
    registration), so that an answer asked again holds one. Otherwise it gives
    the new declaration `operator==`'s type, parameters, inline, always-inline
    and internal-linkage attributes, and the body `!(this->operator==(p))` or
    `!operator==(p0, p1)`, each by-value parameter passed as an xvalue
    (`ImplicitCastExpr` `CK_NoOp` to `VK_XValue`), under a `Sema::SFINAETrap`;
    if the call, the negation or the return is invalid, the declaration is
    removed and none is returned. A valid one goes to the AST consumer as
    `BuildCppToCarbonThunk` hands its decls on (export.cpp:1463-1464), so
    CodeGen emits it on use, and is registered under `Equal`'s first
    declaration (the reverse map keeps `operator==`, which was registered
    first). Beside a deleted `operator==` it builds no body: the declaration,
    of `operator==`'s `void` type, is deleted and registered (RR-5).
-   **export.cpp, the walks.** `ExportImplOperators` takes one impl's rows for
    the operator (a non-member only binary rows, never `operator[]`), builds
    the default `!=` from the exported `operator==`, deleted or not, and
    returns whether a row's function is left to the deleted operator template.
    `ExportOperatorsToCpp` returns nothing for a specific of a generic class
    (W-202) and keeps the impls whose `Self` is the record's class: a concrete
    one is exported, and the first generic one, or the first concrete one
    left to the template, makes the record's deleted operator template.
    `ExportNonMemberOperatorsToCpp` keeps the impls whose `Self` is not a
    Carbon record class (`GetCarbonRecordClassType`, SemIR only) and whose one
    interface argument is one, exported, exportable without a diagnostic and
    with this namespace as its innermost enclosing namespace
    (`getEnclosingNamespaceContext()->Equals`): a concrete one is exported, and
    a generic one, or a concrete one left to the template, makes one deleted
    operator template per operand class.
-   **export.cpp, the deleted operator templates (D-OX-22; extended at rev
    4).** `BuildDeletedOperatorTemplate` builds a `FunctionTemplateDecl` over a
    `CXXMethodDecl` of type `void (T) const` (`&` for `ref self`) or a
    `FunctionDecl` of type `void (T, C)` (`T&` first for `ref self`), whose
    `TemplateTypeParmDecl` is at depth 0, index 0; each parameter has a
    trivial `TypeSourceInfo` and is set into the function type's
    `FunctionProtoTypeLoc`, which template argument deduction substitutes (the
    first `v6` link, without them, crashed in `Sema::SubstParmVarDecl` on the
    first deduction, M-32's probes); the function is deleted, the template
    added to the context and the function registered under the first impl the
    template stands for. `ExportDeletedOperatorTemplate` finds that impl's
    function for the operator's row (`Equal`'s for a default `NotEqual`), maps
    the non-member form's operand class, reuses the template that an earlier
    lookup declared in the context (for that operand class), and declares one
    otherwise.
-   **export.cpp, `IsExportedCarbonOperator`.** True for an overloaded
    operator that `GetExportedOperatorInstId` finds registered and not
    imported: exactly the declarations OX-1 created, member or non-member, the
    default `!=` and the deleted operator templates included, a template's
    specialization being recognized by its primary template's templated
    declaration, and never Clang's implicit members of an exported record.
    The signature is looked up, never added (`CanonicalValueStore::Lookup`).
-   **export.h.** Three declarations, with comments naming F-017 and the page.
-   **generate_ast.cpp, the `CXXOperatorName` arm.** Placed first in the
    switch, before `Identifier`: record → member walk, namespace → non-member
    walk, whoever asks; the entry is set to the answer, or to none, and marked
    as still having external declarations (`DeclContextInternals.h`), so that
    every later lookup asks again (D-OX-12); the arm returns before the
    identifier-based lookup below it, which never sees an operator name.
-   **operators.cpp, `FindClangOperator`.** No flag: `LookupOverloadedBinOp`
    can export as any lookup can (D-OX-21). `BestViableFunction` first
    resolves the candidates as for C++ code, the exported operators included;
    for a success or a deleted result whose best candidate
    `IsExactMatchOfExportedCarbonOperator` accepts (its function recognized by
    `IsExportedCarbonOperator` and not a template specialization, no
    `RewriteKind`, and every conversion a standard one of exact-match rank),
    it returns `InstId::None`, so that the caller's impl lookup selects the
    impl. Otherwise `RemoveExportedCarbonOperators` makes every candidate
    whose function `IsExportedCarbonOperator` recognizes non-viable, with
    `ovl_non_default_multiversion_function`, the failure kind Clang's
    `NoteFunctionCandidate` skips silently, and while it removed a viable
    one, `BestViableFunction` runs again over the same candidates, which
    resets every candidate's `Best` flag (SemaOverload.cpp:11679) and deduces
    any template candidate the previous run left deferred for a perfect match,
    a deleted operator template's specialization among them, which the next
    removal takes (rev 4 removed the exported operators before the first
    resolution, RR3-B2). The
    `NoteCandidates` calls of the ambiguous and deleted arms take a filter
    that leaves exported operators out of the notes, the deferred candidates
    that `CompleteCandidates` deduces for them included (RR2-3). The switch
    below takes the result, Clang's over the candidates that are not exports
    (D-OX-11).

```diff
diff --git a/toolchain/check/cpp/export.cpp b/toolchain/check/cpp/export.cpp
index 518dd86..667d5e7 100644
--- a/toolchain/check/cpp/export.cpp
+++ b/toolchain/check/cpp/export.cpp
@@ -12,6 +12,7 @@
 #include "clang/Sema/EnterExpressionEvaluationContext.h"
 #include "clang/Sema/Sema.h"
 #include "llvm/Support/Casting.h"
+#include "toolchain/check/core_identifier.h"
 #include "toolchain/check/cpp/access.h"
 #include "toolchain/check/cpp/import.h"
 #include "toolchain/check/cpp/location.h"
@@ -25,10 +26,12 @@
 #include "toolchain/check/pattern.h"
 #include "toolchain/check/thunk.h"
 #include "toolchain/check/type.h"
+#include "toolchain/check/type_completion.h"
 #include "toolchain/diagnostics/format_providers.h"
 #include "toolchain/sem_ir/generic.h"
 #include "toolchain/sem_ir/mangler.h"
 #include "toolchain/sem_ir/pattern.h"
+#include "toolchain/sem_ir/type_info.h"
 #include "toolchain/sem_ir/typed_insts.h"
 #include "toolchain/sem_ir/vtable.h"

@@ -1244,7 +1247,9 @@ static auto BuildCppToCarbonThunkBody(Context& context,

   llvm::SmallVector<clang::Expr*> call_args;
   // For methods, pass the `this` pointer as the first argument to the callee.
-  if (target.self_param) {
+  // A non-member operator (fork decision F-017) declares `self` as its first
+  // parameter instead, which the loop below passes like the others.
+  if (target.self_param && isa<clang::CXXMethodDecl>(function_decl)) {
     call_args.push_back(
         GetThisArg(sema, clang_loc, cast<clang::CXXMethodDecl>(function_decl)));
   }
@@ -1901,4 +1906,1159 @@ auto ExportVarToCpp(Context& context, SemIR::InstId inst_id,
   return var_decl;
 }

+namespace {
+// One row of the operator export table (fork decision F-017): the `Core`
+// operator interface and member function that a C++ overloaded operator calls
+// when C++ applies it to an exported Carbon class that implements that
+// interface. The table is the inverse of the import direction's
+// `GetClangOperatorKind` (check/cpp/operators.cpp), restricted to the members
+// that are operators in C++.
+struct OperatorExportEntry {
+  CoreIdentifier interface_name;
+  CoreIdentifier member_name;
+  // The number of explicit parameters after `self`: 0 for a unary operator, 1
+  // for a binary operator.
+  int num_explicit_params;
+  clang::OverloadedOperatorKind op_kind;
+};
+}  // namespace
+
+static constexpr OperatorExportEntry OperatorExportTable[] = {
+    // Arithmetic.
+    {CoreIdentifier::AddWith, CoreIdentifier::Op, 1, clang::OO_Plus},
+    {CoreIdentifier::SubWith, CoreIdentifier::Op, 1, clang::OO_Minus},
+    {CoreIdentifier::MulWith, CoreIdentifier::Op, 1, clang::OO_Star},
+    {CoreIdentifier::DivWith, CoreIdentifier::Op, 1, clang::OO_Slash},
+    {CoreIdentifier::ModWith, CoreIdentifier::Op, 1, clang::OO_Percent},
+    {CoreIdentifier::Negate, CoreIdentifier::Op, 0, clang::OO_Minus},
+    // Bitwise and shift.
+    {CoreIdentifier::BitAndWith, CoreIdentifier::Op, 1, clang::OO_Amp},
+    {CoreIdentifier::BitOrWith, CoreIdentifier::Op, 1, clang::OO_Pipe},
+    {CoreIdentifier::BitXorWith, CoreIdentifier::Op, 1, clang::OO_Caret},
+    {CoreIdentifier::BitComplement, CoreIdentifier::Op, 0, clang::OO_Tilde},
+    {CoreIdentifier::LeftShiftWith, CoreIdentifier::Op, 1, clang::OO_LessLess},
+    {CoreIdentifier::RightShiftWith, CoreIdentifier::Op, 1,
+     clang::OO_GreaterGreater},
+    // Compound assignment.
+    {CoreIdentifier::AddAssignWith, CoreIdentifier::Op, 1, clang::OO_PlusEqual},
+    {CoreIdentifier::SubAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_MinusEqual},
+    {CoreIdentifier::MulAssignWith, CoreIdentifier::Op, 1, clang::OO_StarEqual},
+    {CoreIdentifier::DivAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_SlashEqual},
+    {CoreIdentifier::ModAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_PercentEqual},
+    {CoreIdentifier::BitAndAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_AmpEqual},
+    {CoreIdentifier::BitOrAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_PipeEqual},
+    {CoreIdentifier::BitXorAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_CaretEqual},
+    {CoreIdentifier::LeftShiftAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_LessLessEqual},
+    {CoreIdentifier::RightShiftAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_GreaterGreaterEqual},
+    // Increment and decrement: Carbon's are prefix only.
+    {CoreIdentifier::Inc, CoreIdentifier::Op, 0, clang::OO_PlusPlus},
+    {CoreIdentifier::Dec, CoreIdentifier::Op, 0, clang::OO_MinusMinus},
+    // Comparison. A `NotEqual` the impl does not declare is the interface's
+    // default, `not self.Equal(other)`, and is exported as `!(a == b)`
+    // (`BuildDefaultNotEqualOperator`).
+    {CoreIdentifier::EqWith, CoreIdentifier::Equal, 1, clang::OO_EqualEqual},
+    {CoreIdentifier::EqWith, CoreIdentifier::NotEqual, 1,
+     clang::OO_ExclaimEqual},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::Less, 1, clang::OO_Less},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::LessOrEquivalent, 1,
+     clang::OO_LessEqual},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::Greater, 1,
+     clang::OO_Greater},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::GreaterOrEquivalent, 1,
+     clang::OO_GreaterEqual},
+    // Indexing.
+    {CoreIdentifier::IndexWith, CoreIdentifier::At, 1, clang::OO_Subscript},
+};
+
+// Returns whether `impl` is a complete impl of a `Core` interface that has a
+// row in `OperatorExportTable` for `op_kind`, and is generic if and only if
+// `generic` is; a generic impl must have a binary row. Only the impl's SemIR is
+// read, so an impl that is not an operator of this kind is never mapped to C++.
+static auto IsOperatorImplOfKind(Context& context, const SemIR::Impl& impl,
+                                 clang::OverloadedOperatorKind op_kind,
+                                 bool generic) -> bool {
+  if (!impl.is_complete() || impl.generic_id.has_value() != generic ||
+      !impl.interface.interface_id.has_value()) {
+    return false;
+  }
+  const auto& interface = context.interfaces().Get(impl.interface.interface_id);
+  if (!context.name_scopes().IsCorePackage(interface.parent_scope_id)) {
+    return false;
+  }
+  return llvm::any_of(
+      OperatorExportTable, [&](const OperatorExportEntry& entry) {
+        return entry.op_kind == op_kind &&
+               (!generic || entry.num_explicit_params == 1) &&
+               context.core_identifiers().AddNameId(entry.interface_name) ==
+                   interface.name_id;
+      });
+}
+
+static auto CanExportTypeWithoutDiagnostic(
+    Context& context, SemIR::TypeId type_id,
+    llvm::SmallVectorImpl<SemIR::TypeId>& classes_in_progress) -> bool;
+
+static auto CanExportClassWithoutDiagnostic(
+    Context& context, SemIR::TypeId class_type_id, SemIR::ClassType class_type,
+    llvm::SmallVectorImpl<SemIR::TypeId>& classes_in_progress) -> bool;
+
+// Returns whether `MapToCppType` maps `class_type` by exporting a Carbon class:
+// `TryMapClassType` (type_mapping.cpp) does so for a class that is not a
+// recognized type, for an `Optional` of anything but a pointer, and for an
+// integer type whose bit width it cannot embed. Every other recognized type is
+// mapped without exporting a class, to a C++ builtin type or to a C++ type that
+// is found by name in the translation unit (`std::string_view` for `str`,
+// `std::span` for `Core.Slice`, `Carbon::expected` for `Core.Result`,
+// `Carbon::Exception` for `Cpp.Exception`), and to the null type when the
+// header that declares it is not included.
+static auto MapsByExportingClass(Context& context, SemIR::ClassType class_type)
+    -> bool {
+  auto type_info =
+      SemIR::RecognizedTypeInfo::ForType(context.sem_ir(), class_type);
+  switch (type_info.kind) {
+    case SemIR::RecognizedTypeInfo::None:
+      return true;
+    case SemIR::RecognizedTypeInfo::Numeric:
+      return !type_info.numeric.bit_width_id.is_embedded_value();
+    case SemIR::RecognizedTypeInfo::Optional: {
+      auto args = context.inst_blocks().GetOrEmpty(type_info.args_id);
+      if (args.size() != 1) {
+        return true;
+      }
+      auto arg_id = args.front();
+      if (auto facet = context.insts().TryGetAs<SemIR::FacetValue>(arg_id)) {
+        arg_id = facet->type_inst_id;
+      }
+      return !context.insts().Is<SemIR::PointerType>(arg_id);
+    }
+    default:
+      return false;
+  }
+}
+
+// Returns whether `type_id` has no C++ mapping, decided without a diagnostic.
+// Mapping a type whose leaf is a Carbon class that `MapsByExportingClass`, or a
+// function type, exports that entity, which can diagnose, so such a type is
+// never reported unmappable here: `CanExportTypeWithoutDiagnostic` decides it.
+// Any other type is mapped, a recognized type once every Carbon class it names
+// passes `CanExportTypeWithoutDiagnostic`, so that the mapping exports nothing
+// that can diagnose; a null mapping, such as `str` in a translation unit
+// without `<string_view>`, is no C++ form.
+static auto IsUnmappableWithoutExport(
+    Context& context, SemIR::TypeId type_id,
+    llvm::SmallVectorImpl<SemIR::TypeId>& classes_in_progress) -> bool {
+  for (auto inner_type_id = type_id;;) {
+    auto inst = context.types().GetAsInst(inner_type_id);
+    if (auto const_type = inst.TryAs<SemIR::ConstType>()) {
+      inner_type_id =
+          context.types().GetTypeIdForTypeInstId(const_type->inner_id);
+    } else if (auto pointer_type = inst.TryAs<SemIR::PointerType>()) {
+      inner_type_id =
+          context.types().GetTypeIdForTypeInstId(pointer_type->pointee_id);
+    } else if (auto array_type = inst.TryAs<SemIR::ArrayType>()) {
+      inner_type_id = context.types().GetTypeIdForTypeInstId(
+          array_type->element_type_inst_id);
+    } else if (inst.Is<SemIR::FunctionType>()) {
+      return false;
+    } else if (auto class_type = inst.TryAs<SemIR::ClassType>()) {
+      if (MapsByExportingClass(context, *class_type) ||
+          !CanExportTypeWithoutDiagnostic(context, inner_type_id,
+                                          classes_in_progress)) {
+        return false;
+      }
+      break;
+    } else {
+      break;
+    }
+  }
+  return MapToCppType(context, type_id).isNull();
+}
+
+// Returns whether mapping `type_id` to C++, and completing in C++ every Carbon
+// class that the mapping names, emits no diagnostic. C++ overload resolution
+// completes the class of a by-value parameter to rank a candidate, so an
+// exported operator whose signature named a class that C++ cannot export would
+// report that class's diagnostic at every lookup that ranks it, whatever made
+// the lookup (fork decision F-017). Only SemIR is read, and the answer is
+// conservative: a type it cannot decide is reported as not exportable, and the
+// caller then declares a deleted operator in place of the impl, never one that
+// C++ could select by a conversion.
+static auto CanExportTypeWithoutDiagnostic(
+    Context& context, SemIR::TypeId type_id,
+    llvm::SmallVectorImpl<SemIR::TypeId>& classes_in_progress) -> bool {
+  while (true) {
+    auto inst = context.types().GetAsInst(type_id);
+    if (auto const_type = inst.TryAs<SemIR::ConstType>()) {
+      type_id = context.types().GetTypeIdForTypeInstId(const_type->inner_id);
+    } else if (auto pointer_type = inst.TryAs<SemIR::PointerType>()) {
+      type_id =
+          context.types().GetTypeIdForTypeInstId(pointer_type->pointee_id);
+    } else if (auto array_type = inst.TryAs<SemIR::ArrayType>()) {
+      type_id = context.types().GetTypeIdForTypeInstId(
+          array_type->element_type_inst_id);
+    } else {
+      break;
+    }
+  }
+  auto inst = context.types().GetAsInst(type_id);
+  if (inst.Is<SemIR::FunctionType>() || inst.Is<SemIR::SymbolicBinding>() ||
+      inst.Is<SemIR::FacetAccessType>() || inst.Is<SemIR::ErrorInst>()) {
+    // Mapping a function type exports the function, which can diagnose.
+    return false;
+  }
+  auto class_type = inst.TryAs<SemIR::ClassType>();
+  if (!class_type) {
+    // No other type exports anything when it is mapped.
+    return true;
+  }
+  if (MapsByExportingClass(context, *class_type)) {
+    return CanExportClassWithoutDiagnostic(context, type_id, *class_type,
+                                           classes_in_progress);
+  }
+  // A recognized type that is mapped without exporting a class: its mapping
+  // maps each type argument, an optional pointer's pointee, a slice's element
+  // type and a result's two types.
+  auto type_info =
+      SemIR::RecognizedTypeInfo::ForType(context.sem_ir(), *class_type);
+  for (auto arg_id : context.inst_blocks().GetOrEmpty(type_info.args_id)) {
+    if (auto facet = context.insts().TryGetAs<SemIR::FacetValue>(arg_id)) {
+      arg_id = facet->type_inst_id;
+    }
+    auto arg_type_id = context.types().TryGetTypeIdForTypeConstantId(
+        context.constant_values().Get(arg_id));
+    if (!arg_type_id.has_value() ||
+        !CanExportTypeWithoutDiagnostic(context, arg_type_id,
+                                        classes_in_progress)) {
+      return false;
+    }
+  }
+  return true;
+}
+
+// Returns whether `class_type` can be exported to C++ and completed there
+// without a diagnostic: the checks of `ExportClassToCpp`,
+// `ExportNameScopeToCpp`, `ExportClassSpecificToCpp`, `ExportGenericBindings`
+// and `CarbonExternalASTSource::CompleteType` (its fields, base, destructor and
+// virtual functions), read from SemIR. `classes_in_progress` holds the classes
+// whose answer is being computed, so that a class reached again through its own
+// fields is decided by the outer call.
+static auto CanExportClassWithoutDiagnostic(
+    Context& context, SemIR::TypeId class_type_id, SemIR::ClassType class_type,
+    llvm::SmallVectorImpl<SemIR::TypeId>& classes_in_progress) -> bool {
+  const auto& class_info = context.classes().Get(class_type.class_id);
+  if (class_info.scope_id.has_value() &&
+      context.name_scopes().Get(class_info.scope_id).is_cpp_scope()) {
+    // A class imported from C++ is not exported.
+    return true;
+  }
+  if (llvm::is_contained(classes_in_progress, class_type_id)) {
+    return true;
+  }
+  if (!TryToCompleteType(context, class_type_id, SemIR::LocId::None) ||
+      class_info.inheritance_kind == SemIR::Class::InheritanceKind::Abstract) {
+    return false;
+  }
+  classes_in_progress.push_back(class_type_id);
+  auto result = [&]() {
+    // The enclosing scopes, up to one that is already mapped to C++.
+    for (auto scope_id = class_info.parent_scope_id;;) {
+      if (!scope_id.has_value()) {
+        return false;
+      }
+      const auto& scope = context.name_scopes().Get(scope_id);
+      if (scope.clang_decl_context_id().has_value()) {
+        break;
+      }
+      auto scope_inst_id =
+          context.constant_values().GetConstantInstId(scope.inst_id());
+      if (context.insts().Is<SemIR::Namespace>(scope_inst_id)) {
+        if (!GetClangIdentifierInfo(context, scope.name_id())) {
+          return false;
+        }
+      } else if (auto parent_class = context.insts().TryGetAs<SemIR::ClassType>(
+                     scope_inst_id)) {
+        if (parent_class->specific_id.has_value() ||
+            !CanExportClassWithoutDiagnostic(
+                context, context.types().GetTypeIdForTypeInstId(scope_inst_id),
+                *parent_class, classes_in_progress)) {
+          return false;
+        }
+      } else {
+        return false;
+      }
+      scope_id = scope.parent_scope_id();
+    }
+    // A specific of a generic class: every binding is a type, and every
+    // argument maps.
+    if (class_type.specific_id.has_value()) {
+      if (!class_info.generic_id.has_value()) {
+        return false;
+      }
+      for (auto binding_id : context.inst_blocks().Get(
+               context.generics().Get(class_info.generic_id).bindings_id)) {
+        auto binding = context.insts().TryGetAs<SemIR::SymbolicBinding>(
+            context.constant_values().GetConstantInstId(binding_id));
+        if (!binding ||
+            !context.types().Is<SemIR::FacetType>(binding->type_id)) {
+          return false;
+        }
+      }
+      for (auto arg_id : context.inst_blocks().Get(
+               context.specifics().Get(class_type.specific_id).args_id)) {
+        auto arg_type_id = context.types().TryGetTypeIdForTypeConstantId(
+            context.constant_values().Get(arg_id));
+        if (!arg_type_id.has_value() ||
+            IsUnmappableWithoutExport(context, arg_type_id,
+                                      classes_in_progress) ||
+            !CanExportTypeWithoutDiagnostic(context, arg_type_id,
+                                            classes_in_progress)) {
+          return false;
+        }
+      }
+    }
+    // The base class and the fields, each of which C++ completes.
+    if (auto base_type_id =
+            class_info.GetBaseType(context.sem_ir(), class_type.specific_id);
+        base_type_id.has_value() &&
+        !CanExportTypeWithoutDiagnostic(context, base_type_id,
+                                        classes_in_progress)) {
+      return false;
+    }
+    for (const auto& field : class_info.GetStructTypeFields(
+             context.sem_ir(), class_type.specific_id)) {
+      auto field_type_id =
+          context.types().GetTypeIdForTypeInstId(field.type_inst_id);
+      if (IsUnmappableWithoutExport(context, field_type_id,
+                                    classes_in_progress) ||
+          !CanExportTypeWithoutDiagnostic(context, field_type_id,
+                                          classes_in_progress)) {
+        return false;
+      }
+    }
+    // The class's own virtual functions are declared at completion.
+    if (class_info.vtable_decl_id.has_value()) {
+      LoadImportRef(context, class_info.vtable_decl_id);
+      auto vtable_decl_id = context.constant_values().GetConstantInstId(
+          class_info.vtable_decl_id);
+      for (auto entry_id : context.inst_blocks().Get(
+               context.vtables()
+                   .Get(context.insts()
+                            .GetAs<SemIR::VtableDecl>(vtable_decl_id)
+                            .vtable_id)
+                   .virtual_functions_id)) {
+        if (!entry_id.has_value()) {
+          continue;
+        }
+        auto callee = GetCalleeAsFunction(context.sem_ir(), entry_id);
+        const auto& function = context.functions().Get(callee.function_id);
+        if (function.parent_scope_id != class_info.scope_id) {
+          continue;
+        }
+        FunctionInfo target(context, callee.function_id, function,
+                            /*decl_context=*/nullptr,
+                            /*export_as_constructor=*/false);
+        for (const auto& param : target.explicit_params) {
+          if (IsUnmappableWithoutExport(context, param.type_id,
+                                        classes_in_progress) ||
+              context.types().Is<SemIR::ArrayType>(param.type_id) ||
+              !CanExportTypeWithoutDiagnostic(context, param.type_id,
+                                              classes_in_progress)) {
+            return false;
+          }
+        }
+        if (target.return_type_id.has_value() &&
+            (IsUnmappableWithoutExport(context, target.return_type_id,
+                                       classes_in_progress) ||
+             context.types().Is<SemIR::ArrayType>(target.return_type_id) ||
+             !CanExportTypeWithoutDiagnostic(context, target.return_type_id,
+                                             classes_in_progress))) {
+          return false;
+        }
+      }
+    }
+    return true;
+  }();
+  classes_in_progress.pop_back();
+  return result;
+}
+
+// Returns whether `type_id` can be exported without a diagnostic
+// (`CanExportTypeWithoutDiagnostic`).
+static auto CanExportWithoutDiagnostic(Context& context, SemIR::TypeId type_id)
+    -> bool {
+  llvm::SmallVector<SemIR::TypeId> classes_in_progress;
+  return CanExportTypeWithoutDiagnostic(context, type_id, classes_in_progress);
+}
+
+namespace {
+// How an operator impl's function is exported (fork decision F-017).
+enum class OperatorExportKind : uint8_t {
+  // Declared and defined, calling the impl's function.
+  Export,
+  // Declared deleted: the result has no by-value C++ form, or names a class
+  // that cannot be exported without a diagnostic.
+  Deleted,
+  // Not declared, and stood for by the operator's deleted operator template:
+  // an operand names a type that cannot be exported without a diagnostic.
+  Template,
+  // Not declared: an operand has no C++ form.
+  Omit,
+};
+}  // namespace
+
+// Classifies `target`, an operator impl's function, before any type of it that
+// names a Carbon class is mapped. C++ cannot form an operand of a type that has
+// no C++ mapping, such as a tuple, or `str` without `<string_view>`, so
+// omitting such an impl cannot change which impl a C++ expression selects. An
+// operand whose type cannot be exported without a diagnostic is never named
+// either: the operator's deleted operator template stands for the impl, so that
+// C++ rejects an operand it would otherwise convert for another impl. An impl
+// whose result has no by-value C++ form, or cannot be exported without a
+// diagnostic, is declared deleted, so that a C++ expression that would select
+// it is rejected rather than resolved to another impl by a conversion. No
+// export of an operator can therefore emit a diagnostic.
+static auto ClassifyOperatorExport(Context& context, const FunctionInfo& target,
+                                   bool is_member) -> OperatorExportKind {
+  llvm::SmallVector<SemIR::TypeId> operand_type_ids;
+  if (!is_member) {
+    operand_type_ids.push_back(target.self_param->type_id);
+  }
+  for (const auto& param : target.explicit_params) {
+    operand_type_ids.push_back(param.type_id);
+  }
+  llvm::SmallVector<SemIR::TypeId> classes_in_progress;
+  if (llvm::any_of(operand_type_ids, [&](SemIR::TypeId type_id) {
+        return IsUnmappableWithoutExport(context, type_id, classes_in_progress);
+      })) {
+    return OperatorExportKind::Omit;
+  }
+  if (!llvm::all_of(operand_type_ids, [&](SemIR::TypeId type_id) {
+        return CanExportTypeWithoutDiagnostic(context, type_id,
+                                              classes_in_progress);
+      })) {
+    return OperatorExportKind::Template;
+  }
+  if (target.return_type_id.has_value() &&
+      (IsUnmappableWithoutExport(context, target.return_type_id,
+                                 classes_in_progress) ||
+       context.types().Is<SemIR::ArrayType>(target.return_type_id) ||
+       !CanExportTypeWithoutDiagnostic(context, target.return_type_id,
+                                       classes_in_progress))) {
+    return OperatorExportKind::Deleted;
+  }
+  return OperatorExportKind::Export;
+}
+
+// Returns the function that `impl` declares as its `member_name`, or `None`
+// when the impl leaves that member to the interface's `default fn`.
+static auto GetImplMemberFunctionId(Context& context, const SemIR::Impl& impl,
+                                    CoreIdentifier member_name)
+    -> SemIR::FunctionId {
+  auto& impl_scope = context.name_scopes().Get(impl.scope_id);
+  auto entry_id =
+      impl_scope.Lookup(context.core_identifiers().AddNameId(member_name));
+  if (!entry_id) {
+    return SemIR::FunctionId::None;
+  }
+  // A name the impl does not declare can still have an entry: checking the
+  // impl poisons the names it looked up in its own scope.
+  const auto& result = impl_scope.GetEntry(*entry_id).result;
+  if (!result.is_found()) {
+    return SemIR::FunctionId::None;
+  }
+  LoadImportRef(context, result.target_inst_id());
+  auto callee = SemIR::GetCallee(context.sem_ir(), result.target_inst_id());
+  auto* callee_function = std::get_if<SemIR::CalleeFunction>(&callee);
+  if (!callee_function || (callee_function->enclosing_specific_id.has_value() &&
+                           !impl.generic_id.has_value())) {
+    return SemIR::FunctionId::None;
+  }
+  return callee_function->function_id;
+}
+
+// Returns the `clang_decls` signature under which an exported operator is
+// registered: every parameter by value.
+static auto GetExportedOperatorSignature(const clang::FunctionDecl* decl)
+    -> SemIR::ClangDeclSignature {
+  SemIR::ClangDeclSignature signature{
+      .kind = SemIR::ClangDeclSignature::Normal,
+      .num_params = static_cast<int32_t>(decl->getNumParams())};
+  signature.passing_modes.assign(
+      signature.num_params, SemIR::ClangDeclSignature::PassingMode::ByValue);
+  return signature;
+}
+
+// Records `operator_decl` as the C++ export of `inst_id`, so that a later
+// lookup reuses it and `IsExportedCarbonOperator` recognizes it.
+static auto RegisterExportedOperator(Context& context,
+                                     clang::FunctionDecl* operator_decl,
+                                     SemIR::InstId inst_id) -> void {
+  context.clang_decls().Add(
+      {.key = SemIR::ClangDeclKey::ForFunctionDecl(
+           operator_decl, context.clang_decl_signatures().Add(
+                              GetExportedOperatorSignature(operator_decl))),
+       .inst_id = inst_id});
+}
+
+// Declares the C++ operator `op_kind` for `target` in `decl_context`: a member
+// of a record, whose `self` is the object parameter, or a non-member of a
+// namespace, whose first parameter is `self`. A deleted declaration returns
+// `void`. Returns null after a diagnostic if a type does not map.
+static auto BuildCppOperatorDecl(Context& context, SemIR::LocId loc_id,
+                                 const FunctionInfo& target,
+                                 clang::DeclContext* decl_context,
+                                 clang::OverloadedOperatorKind op_kind,
+                                 bool deleted) -> clang::FunctionDecl* {
+  clang::ASTContext& ast_context = context.ast_context();
+  auto clang_loc = GetCppLocation(context, loc_id);
+  auto* record_decl = dyn_cast<clang::CXXRecordDecl>(decl_context);
+
+  llvm::SmallVector<FunctionInfo::Param> params;
+  if (!record_decl) {
+    params.push_back(*target.self_param);
+  }
+  llvm::append_range(params, target.explicit_params);
+  llvm::SmallVector<clang::QualType> param_types;
+  for (const auto& param : params) {
+    auto cpp_type = MapToCppParamType(context, loc_id, param);
+    if (cpp_type.isNull()) {
+      context.TODO(loc_id, "failed to map Carbon type to C++");
+      return nullptr;
+    }
+    param_types.push_back(cpp_type);
+  }
+  clang::QualType return_type = ast_context.VoidTy;
+  if (!deleted && target.return_type_id.has_value()) {
+    return_type = MapToCppType(context, target.return_type_id);
+    if (return_type.isNull()) {
+      context.TODO(loc_id, "failed to map Carbon return type to C++ type");
+      return nullptr;
+    }
+  }
+  clang::FunctionProtoType::ExtProtoInfo ext_proto_info;
+  if (record_decl) {
+    // As for an exported method: `ref self` is `&`, `self` is `const`.
+    if (target.self_param->kind == ParamPatternKind::Ref) {
+      ext_proto_info.RefQualifier = clang::RQ_LValue;
+    } else {
+      ext_proto_info.TypeQuals.addConst();
+    }
+  }
+  auto function_type =
+      ast_context.getFunctionType(return_type, param_types, ext_proto_info);
+  clang::DeclarationNameInfo name_info(
+      ast_context.DeclarationNames.getCXXOperatorName(op_kind), clang_loc);
+  auto* tinfo = ast_context.getTrivialTypeSourceInfo(function_type, clang_loc);
+  clang::FunctionDecl* function_decl = nullptr;
+  if (record_decl) {
+    function_decl = clang::CXXMethodDecl::Create(
+        ast_context, record_decl, clang_loc, name_info, function_type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInline=*/true,
+        clang::ConstexprSpecKind::Unspecified, clang_loc,
+        clang::AssociatedConstraint());
+    function_decl->setAccess(clang::AS_public);
+  } else {
+    function_decl = clang::FunctionDecl::Create(
+        ast_context, decl_context, clang_loc, name_info, function_type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true,
+        /*hasWrittenPrototype=*/true, clang::ConstexprSpecKind::Unspecified,
+        clang::AssociatedConstraint());
+  }
+  llvm::SmallVector<clang::ParmVarDecl*> param_decls;
+  for (auto type : param_types) {
+    param_decls.push_back(clang::ParmVarDecl::Create(
+        ast_context, function_decl, clang_loc, clang_loc, /*Id=*/nullptr, type,
+        /*TInfo=*/nullptr, clang::SC_None, /*DefArg=*/nullptr));
+  }
+  function_decl->setParams(param_decls);
+  decl_context->addHiddenDecl(function_decl);
+  if (deleted) {
+    function_decl->setDeletedAsWritten();
+  } else {
+    function_decl->addAttr(
+        clang::AlwaysInlineAttr::CreateImplicit(ast_context));
+    function_decl->addAttr(
+        clang::InternalLinkageAttr::CreateImplicit(ast_context));
+  }
+  return function_decl;
+}
+
+namespace {
+// The outcome of exporting one operator impl function.
+struct ImplOperatorExport {
+  // The C++ operator declared for the function, or null.
+  clang::FunctionDecl* decl = nullptr;
+  // Whether the operator's deleted operator template stands for the function
+  // (`OperatorExportKind::Template`).
+  bool needs_template = false;
+};
+}  // namespace
+
+// Exports `function_id`, an impl's member, as the C++ operator `entry.op_kind`
+// of `decl_context`: a member operator of a record, through the same C++ and
+// Carbon thunks as an exported method, or a non-member operator of a
+// namespace. Declares nothing if the function's shape is not the operator's or
+// `ClassifyOperatorExport` omits it or leaves it to the deleted operator
+// template. An earlier export of the function is reused, because every C++
+// lookup of an operator name asks again (`FindExternalVisibleDeclsByName`).
+static auto ExportImplFunctionAsCppOperator(Context& context,
+                                            clang::DeclContext* decl_context,
+                                            SemIR::FunctionId function_id,
+                                            const OperatorExportEntry& entry)
+    -> ImplOperatorExport {
+  const auto& function = context.functions().Get(function_id);
+  SemIR::LocId loc_id(function.first_decl_id());
+
+  if (const auto* clang_decl =
+          context.clang_decls().Lookup(function.first_decl_id())) {
+    return {.decl = dyn_cast<clang::FunctionDecl>(clang_decl->decl())};
+  }
+
+  FunctionInfo target(context, function_id, function, decl_context,
+                      /*export_as_constructor=*/false);
+  if (!target.self_param || static_cast<int>(target.explicit_params.size()) !=
+                                entry.num_explicit_params) {
+    return {};
+  }
+  clang::FunctionDecl* operator_decl = nullptr;
+  switch (ClassifyOperatorExport(context, target,
+                                 isa<clang::CXXRecordDecl>(decl_context))) {
+    case OperatorExportKind::Omit:
+      return {};
+    case OperatorExportKind::Template:
+      return {.needs_template = true};
+    case OperatorExportKind::Deleted:
+      operator_decl = BuildCppOperatorDecl(context, loc_id, target,
+                                           decl_context, entry.op_kind,
+                                           /*deleted=*/true);
+      break;
+    case OperatorExportKind::Export:
+      // A member operator is declared exactly as an exported method is.
+      operator_decl =
+          isa<clang::CXXRecordDecl>(decl_context)
+              ? BuildCppToCarbonThunkDecl(
+                    context, loc_id, target,
+                    context.ast_context().DeclarationNames.getCXXOperatorName(
+                        entry.op_kind))
+              : BuildCppOperatorDecl(context, loc_id, target, decl_context,
+                                     entry.op_kind, /*deleted=*/false);
+      if (operator_decl) {
+        BuildCppToCarbonThunk(context, loc_id, target, operator_decl,
+                              /*extra_name=*/"");
+      }
+      break;
+  }
+  if (!operator_decl) {
+    return {};
+  }
+  RegisterExportedOperator(context, operator_decl, function.first_decl_id());
+  return {.decl = operator_decl};
+}
+
+// Returns the instruction that `decl` is registered under in `clang_decls` if
+// it is an exported operator (`RegisterExportedOperator`), and `None`
+// otherwise.
+static auto GetExportedOperatorInstId(Context& context,
+                                      clang::FunctionDecl* decl)
+    -> SemIR::InstId {
+  auto signature_id = context.clang_decl_signatures().Lookup(
+      GetExportedOperatorSignature(decl));
+  if (!signature_id.has_value()) {
+    return SemIR::InstId::None;
+  }
+  auto clang_decl_id = context.clang_decls().LookupId(
+      SemIR::ClangDeclKey::ForFunctionDecl(decl, signature_id));
+  if (!clang_decl_id.has_value() ||
+      context.clang_decls().Get(clang_decl_id).is_imported) {
+    return SemIR::InstId::None;
+  }
+  return context.clang_decls().Get(clang_decl_id).inst_id;
+}
+
+// Builds `operator!=` for an `EqWith` impl that leaves `NotEqual` to its
+// default, `not self.Equal(other)` (docs/design/expressions/
+// comparison_operators.md, "Equality"), as `!(a == b)` over the exported
+// `operator==`, beside it and of the same form, member or non-member: C++17
+// does not rewrite `a != b` itself. Each by-value parameter is passed on as an
+// xvalue, as a C++ implicit move would, so a move-only class works; if the call
+// is still invalid (a class C++ can neither copy nor move), no `operator!=` is
+// declared and nothing is diagnosed. A deleted `operator==` gets a deleted
+// `operator!=` of the same type. The `operator!=` that an earlier lookup of the
+// name in this context built is reused.
+static auto BuildDefaultNotEqualOperator(Context& context,
+                                         clang::FunctionDecl* equal_decl,
+                                         SemIR::InstId equal_inst_id)
+    -> clang::FunctionDecl* {
+  clang::ASTContext& ast_context = context.ast_context();
+  clang::Sema& sema = context.clang_sema();
+  auto clang_loc = equal_decl->getLocation();
+  auto* decl_context = equal_decl->getDeclContext();
+
+  clang::DeclarationNameInfo name_info(
+      ast_context.DeclarationNames.getCXXOperatorName(clang::OO_ExclaimEqual),
+      clang_loc);
+  for (auto* decl : decl_context->noload_lookup(name_info.getName())) {
+    if (auto* function_decl = dyn_cast<clang::FunctionDecl>(decl);
+        function_decl &&
+        GetExportedOperatorInstId(context, function_decl) == equal_inst_id) {
+      return function_decl;
+    }
+  }
+  auto type = equal_decl->getType();
+  auto* tinfo = ast_context.getTrivialTypeSourceInfo(type, clang_loc);
+  auto* equal_method_decl = dyn_cast<clang::CXXMethodDecl>(equal_decl);
+  clang::FunctionDecl* not_equal_decl = nullptr;
+  if (equal_method_decl) {
+    not_equal_decl = clang::CXXMethodDecl::Create(
+        ast_context, equal_method_decl->getParent(), clang_loc, name_info, type,
+        tinfo, clang::SC_None, /*UsesFPIntrin=*/false,
+        /*isInline=*/true, clang::ConstexprSpecKind::Unspecified, clang_loc,
+        clang::AssociatedConstraint());
+    not_equal_decl->setAccess(clang::AS_public);
+  } else {
+    not_equal_decl = clang::FunctionDecl::Create(
+        ast_context, decl_context, clang_loc, name_info, type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true,
+        /*hasWrittenPrototype=*/true, clang::ConstexprSpecKind::Unspecified,
+        clang::AssociatedConstraint());
+  }
+  llvm::SmallVector<clang::ParmVarDecl*> params;
+  for (const auto* equal_param : equal_decl->parameters()) {
+    params.push_back(clang::ParmVarDecl::Create(
+        ast_context, not_equal_decl, clang_loc, clang_loc, /*Id=*/nullptr,
+        equal_param->getType(), /*TInfo=*/nullptr, clang::SC_None,
+        /*DefArg=*/nullptr));
+  }
+  not_equal_decl->setParams(params);
+  decl_context->addHiddenDecl(not_equal_decl);
+  if (equal_decl->isDeleted()) {
+    // `Equal`'s result has no C++ form, and the default `NotEqual` calls
+    // `Equal`: `operator!=` is deleted too, so that a C++ `a != b` that would
+    // select it is rejected rather than resolved to another impl by a
+    // conversion.
+    not_equal_decl->setDeletedAsWritten();
+    RegisterExportedOperator(context, not_equal_decl, equal_inst_id);
+    return not_equal_decl;
+  }
+  not_equal_decl->addAttr(clang::AlwaysInlineAttr::CreateImplicit(ast_context));
+  not_equal_decl->addAttr(
+      clang::InternalLinkageAttr::CreateImplicit(ast_context));
+
+  bool valid = false;
+  {
+    clang::Sema::ContextRAII context_raii(sema, not_equal_decl);
+    clang::EnterExpressionEvaluationContext evaluated(
+        sema, clang::Sema::ExpressionEvaluationContext::PotentiallyEvaluated);
+    clang::Sema::SFINAETrap trap(sema);
+    sema.ActOnStartOfFunctionDef(nullptr, not_equal_decl);
+    llvm::SmallVector<clang::Expr*> args;
+    for (auto* param : params) {
+      clang::Expr* arg =
+          sema.BuildDeclRefExpr(param, param->getType().getNonReferenceType(),
+                                clang::VK_LValue, clang_loc);
+      if (!param->getType()->isReferenceType()) {
+        arg = clang::ImplicitCastExpr::Create(
+            ast_context, param->getType(), clang::CK_NoOp, arg,
+            /*BasePath=*/nullptr, clang::VK_XValue, clang::FPOptionsOverride());
+      }
+      args.push_back(arg);
+    }
+    clang::ExprResult equal_call;
+    if (equal_method_decl) {
+      auto* member_expr = sema.BuildMemberExpr(
+          GetThisArg(sema, clang_loc,
+                     cast<clang::CXXMethodDecl>(not_equal_decl)),
+          /*IsArrow=*/false, clang_loc, clang::NestedNameSpecifierLoc(),
+          clang::SourceLocation(), equal_method_decl,
+          clang::DeclAccessPair::make(equal_method_decl, clang::AS_public),
+          /*HadMultipleCandidates=*/false,
+          clang::DeclarationNameInfo(equal_decl->getDeclName(), clang_loc),
+          ast_context.BoundMemberTy, clang::VK_PRValue, clang::OK_Ordinary);
+      equal_call = sema.BuildCallToMemberFunction(/*S=*/nullptr, member_expr,
+                                                  clang_loc, args, clang_loc);
+    } else {
+      clang::ExprResult callee = sema.BuildDeclRefExpr(
+          equal_decl, equal_decl->getType(), clang::VK_LValue, clang_loc);
+      equal_call = sema.BuildCallExpr(/*S=*/nullptr, callee.get(), clang_loc,
+                                      args, clang_loc);
+    }
+    clang::StmtResult return_stmt = clang::StmtError();
+    if (equal_call.isUsable() && !trap.hasErrorOccurred()) {
+      auto not_expr = sema.CreateBuiltinUnaryOp(clang_loc, clang::UO_LNot,
+                                                equal_call.get());
+      if (not_expr.isUsable()) {
+        return_stmt = sema.BuildReturnStmt(clang_loc, not_expr.get());
+      }
+    }
+    llvm::SmallVector<clang::Stmt*, 1> stmts;
+    valid = return_stmt.isUsable() && !trap.hasErrorOccurred();
+    if (valid) {
+      stmts.push_back(return_stmt.get());
+    }
+    sema.ActOnFinishFunctionBody(
+        not_equal_decl, clang::CompoundStmt::Create(ast_context, stmts,
+                                                    clang::FPOptionsOverride(),
+                                                    clang_loc, clang_loc));
+  }
+  if (!valid) {
+    not_equal_decl->setInvalidDecl();
+    decl_context->removeDecl(not_equal_decl);
+    return nullptr;
+  }
+  sema.getASTConsumer().HandleTopLevelDecl(clang::DeclGroupRef(not_equal_decl));
+  RegisterExportedOperator(context, not_equal_decl, equal_inst_id);
+  return not_equal_decl;
+}
+
+// Declares a deleted C++ operator template in `decl_context` for the binary
+// operator `op_kind`, which stands for the operator's impls that C++ cannot
+// call: a member `template <typename T> void operator@(T) const = delete;` of a
+// record (`&` instead of `const` for `ref self`), or a non-member
+// `template <typename T> void operator@(T, C) = delete;` of a namespace (`T&`
+// for `ref self`), whose `C` is `operand_type`. `target` is the function of one
+// of those impls, and `impl_inst_id` the impl that the template is registered
+// under. They are the generic impls, and the concrete ones whose operand C++
+// cannot be given without a diagnostic (`OperatorExportKind::Template`):
+// without this declaration, a C++ operand that converts to another impl's
+// parameter type would select that impl where Carbon selects one of them. A
+// non-template exact match is still preferred to the template.
+static auto BuildDeletedOperatorTemplate(
+    Context& context, const FunctionInfo& target, SemIR::InstId impl_inst_id,
+    clang::DeclContext* decl_context, clang::OverloadedOperatorKind op_kind,
+    clang::QualType operand_type) -> clang::FunctionTemplateDecl* {
+  clang::ASTContext& ast_context = context.ast_context();
+  SemIR::LocId loc_id(target.function.first_decl_id());
+  auto clang_loc = GetCppLocation(context, loc_id);
+  auto* record_decl = dyn_cast<clang::CXXRecordDecl>(decl_context);
+  bool ref_self = target.self_param->kind == ParamPatternKind::Ref;
+
+  auto* type_param = clang::TemplateTypeParmDecl::Create(
+      ast_context, decl_context, clang_loc, clang_loc, /*D=*/0, /*P=*/0,
+      /*Id=*/nullptr, /*Typename=*/true, /*ParameterPack=*/false);
+  auto param_type = ast_context.getTemplateTypeParmType(
+      /*Depth=*/0, /*Index=*/0, /*ParameterPack=*/false, type_param);
+  llvm::SmallVector<clang::QualType> param_types;
+  clang::FunctionProtoType::ExtProtoInfo ext_proto_info;
+  if (record_decl) {
+    param_types.push_back(param_type);
+    if (ref_self) {
+      ext_proto_info.RefQualifier = clang::RQ_LValue;
+    } else {
+      ext_proto_info.TypeQuals.addConst();
+    }
+  } else {
+    param_types.push_back(
+        ref_self ? ast_context.getLValueReferenceType(param_type) : param_type);
+    param_types.push_back(operand_type);
+  }
+  auto function_type = ast_context.getFunctionType(ast_context.VoidTy,
+                                                   param_types, ext_proto_info);
+  clang::DeclarationNameInfo name_info(
+      ast_context.DeclarationNames.getCXXOperatorName(op_kind), clang_loc);
+  auto* tinfo = ast_context.getTrivialTypeSourceInfo(function_type, clang_loc);
+  clang::FunctionDecl* function_decl = nullptr;
+  if (record_decl) {
+    function_decl = clang::CXXMethodDecl::Create(
+        ast_context, record_decl, clang_loc, name_info, function_type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInline=*/true,
+        clang::ConstexprSpecKind::Unspecified, clang_loc,
+        clang::AssociatedConstraint());
+    function_decl->setAccess(clang::AS_public);
+  } else {
+    function_decl = clang::FunctionDecl::Create(
+        ast_context, decl_context, clang_loc, name_info, function_type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true,
+        /*hasWrittenPrototype=*/true, clang::ConstexprSpecKind::Unspecified,
+        clang::AssociatedConstraint());
+  }
+  // Template argument deduction substitutes into the type's parameters.
+  auto proto_loc = tinfo->getTypeLoc().castAs<clang::FunctionProtoTypeLoc>();
+  llvm::SmallVector<clang::ParmVarDecl*> param_decls;
+  for (auto [index, type] : llvm::enumerate(param_types)) {
+    auto* param_decl = clang::ParmVarDecl::Create(
+        ast_context, function_decl, clang_loc, clang_loc, /*Id=*/nullptr, type,
+        ast_context.getTrivialTypeSourceInfo(type, clang_loc), clang::SC_None,
+        /*DefArg=*/nullptr);
+    param_decl->setScopeInfo(/*scopeDepth=*/0, index);
+    proto_loc.setParam(index, param_decl);
+    param_decls.push_back(param_decl);
+  }
+  function_decl->setParams(param_decls);
+  function_decl->setDeletedAsWritten();
+  auto* template_decl = clang::FunctionTemplateDecl::Create(
+      ast_context, decl_context, clang_loc, name_info.getName(),
+      clang::TemplateParameterList::Create(ast_context, clang_loc, clang_loc,
+                                           {type_param}, clang_loc,
+                                           /*RequiresClause=*/nullptr),
+      function_decl);
+  function_decl->setDescribedFunctionTemplate(template_decl);
+  if (record_decl) {
+    template_decl->setAccess(clang::AS_public);
+  }
+  decl_context->addHiddenDecl(template_decl);
+  RegisterExportedOperator(context, function_decl, impl_inst_id);
+  return template_decl;
+}
+
+// Declares the deleted operator template (`BuildDeletedOperatorTemplate`) that
+// stands for `impl`, an impl of the binary operator `op_kind`, in
+// `decl_context`, or reuses the one an earlier lookup of the name in this
+// context declared, and appends it to `operator_decls`.
+static auto ExportDeletedOperatorTemplate(
+    Context& context, const SemIR::Impl& impl, clang::DeclContext* decl_context,
+    clang::OverloadedOperatorKind op_kind,
+    llvm::SmallVectorImpl<clang::NamedDecl*>& operator_decls) -> void {
+  const auto& interface = context.interfaces().Get(impl.interface.interface_id);
+  for (const auto& entry : OperatorExportTable) {
+    if (entry.op_kind != op_kind || entry.num_explicit_params != 1 ||
+        context.core_identifiers().AddNameId(entry.interface_name) !=
+            interface.name_id) {
+      continue;
+    }
+    auto function_id =
+        GetImplMemberFunctionId(context, impl, entry.member_name);
+    if (!function_id.has_value() &&
+        entry.member_name == CoreIdentifier::NotEqual) {
+      // The default `NotEqual` has `Equal`'s parameters.
+      function_id =
+          GetImplMemberFunctionId(context, impl, CoreIdentifier::Equal);
+    }
+    if (!function_id.has_value()) {
+      return;
+    }
+    FunctionInfo target(context, function_id,
+                        context.functions().Get(function_id), decl_context,
+                        /*export_as_constructor=*/false);
+    if (!target.self_param || target.explicit_params.size() != 1) {
+      return;
+    }
+    // The non-member form names the operand class, which the walk has checked.
+    clang::QualType operand_type;
+    if (!isa<clang::CXXRecordDecl>(decl_context)) {
+      operand_type = MapToCppParamType(
+          context, SemIR::LocId(target.function.first_decl_id()),
+          target.explicit_params.front());
+      if (operand_type.isNull()) {
+        return;
+      }
+    }
+    for (auto* decl : decl_context->noload_lookup(
+             context.ast_context().DeclarationNames.getCXXOperatorName(
+                 op_kind))) {
+      auto* template_decl = dyn_cast<clang::FunctionTemplateDecl>(decl);
+      if (template_decl &&
+          GetExportedOperatorInstId(context, template_decl->getTemplatedDecl())
+              .has_value() &&
+          (operand_type.isNull() ||
+           context.ast_context().hasSameType(
+               template_decl->getTemplatedDecl()->getParamDecl(1)->getType(),
+               operand_type))) {
+        operator_decls.push_back(template_decl);
+        return;
+      }
+    }
+    operator_decls.push_back(
+        BuildDeletedOperatorTemplate(context, target, impl.first_decl_id(),
+                                     decl_context, op_kind, operand_type));
+    return;
+  }
+}
+
+// Exports the members of `impl` that C++ spells `op_kind` as operators of
+// `decl_context` (the member walk's record or the non-member walk's
+// namespace), appending them to `operator_decls`. Returns whether the
+// operator's deleted operator template stands for one of them.
+static auto ExportImplOperators(
+    Context& context, const SemIR::Impl& impl, clang::DeclContext* decl_context,
+    clang::OverloadedOperatorKind op_kind,
+    llvm::SmallVectorImpl<clang::NamedDecl*>& operator_decls) -> bool {
+  const auto& interface = context.interfaces().Get(impl.interface.interface_id);
+  bool is_member = isa<clang::CXXRecordDecl>(decl_context);
+  bool needs_template = false;
+  for (const auto& entry : OperatorExportTable) {
+    // C++ requires `operator[]` to be a member, and a non-member operator has
+    // the operand that argument-dependent lookup found it by.
+    if (entry.op_kind != op_kind ||
+        context.core_identifiers().AddNameId(entry.interface_name) !=
+            interface.name_id ||
+        (!is_member && (entry.num_explicit_params != 1 ||
+                        entry.op_kind == clang::OO_Subscript))) {
+      continue;
+    }
+    ImplOperatorExport result;
+    if (auto function_id =
+            GetImplMemberFunctionId(context, impl, entry.member_name);
+        function_id.has_value()) {
+      result = ExportImplFunctionAsCppOperator(context, decl_context,
+                                               function_id, entry);
+    } else if (entry.member_name == CoreIdentifier::NotEqual) {
+      if (auto equal_id =
+              GetImplMemberFunctionId(context, impl, CoreIdentifier::Equal);
+          equal_id.has_value()) {
+        result = ExportImplFunctionAsCppOperator(
+            context, decl_context, equal_id,
+            {.interface_name = CoreIdentifier::EqWith,
+             .member_name = CoreIdentifier::Equal,
+             .num_explicit_params = 1,
+             .op_kind = clang::OO_EqualEqual});
+        if (result.decl) {
+          result.decl = BuildDefaultNotEqualOperator(
+              context, result.decl,
+              context.functions().Get(equal_id).first_decl_id());
+        }
+      }
+    }
+    if (result.decl) {
+      operator_decls.push_back(result.decl);
+    }
+    needs_template |= result.needs_template;
+  }
+  return needs_template;
+}
+
+auto ExportOperatorsToCpp(Context& context, clang::CXXRecordDecl* record_decl,
+                          clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*> {
+  llvm::SmallVector<clang::NamedDecl*> operator_decls;
+  auto carbon_class =
+      SemIR::GetAsCarbonOwnedClass(context.sem_ir(), record_decl);
+  if (!carbon_class) {
+    return operator_decls;
+  }
+  auto [class_type_id, class_type] = *carbon_class;
+  // TODO: Export the operator impls of a generic class's specifics.
+  if (class_type.specific_id.has_value()) {
+    return operator_decls;
+  }
+  auto class_const_id = context.types().GetConstantId(class_type_id);
+
+  // Impls are visited in the order they were added to the file, which is
+  // declaration order for the impls this file declares. Only an impl whose
+  // `Self` is exactly this class exports here, as a member operator, so C++
+  // finds it by member lookup on the left operand as Carbon finds it by impl
+  // lookup on `Self`. The impls of the operator that C++ cannot call, generic
+  // ones included, share one deleted operator template.
+  bool has_template = false;
+  for (const auto& impl : context.impls().values()) {
+    if (context.constant_values().Get(impl.self_id) != class_const_id) {
+      continue;
+    }
+    bool needs_template = false;
+    if (IsOperatorImplOfKind(context, impl, op_kind, /*generic=*/false)) {
+      needs_template = ExportImplOperators(context, impl, record_decl, op_kind,
+                                           operator_decls);
+    } else {
+      needs_template =
+          IsOperatorImplOfKind(context, impl, op_kind, /*generic=*/true);
+    }
+    if (needs_template && !has_template) {
+      has_template = true;
+      ExportDeletedOperatorTemplate(context, impl, record_decl, op_kind,
+                                    operator_decls);
+    }
+  }
+  return operator_decls;
+}
+
+// Returns the class type that `type_inst_id` names if it is a class defined in
+// Carbon that is not a recognized type (such as `i32`), which C++ sees as a
+// record of its own.
+static auto GetCarbonRecordClassType(Context& context,
+                                     SemIR::InstId type_inst_id)
+    -> std::optional<SemIR::ClassType> {
+  auto class_type = context.constant_values().TryGetInstAs<SemIR::ClassType>(
+      context.constant_values().Get(type_inst_id));
+  if (!class_type) {
+    return std::nullopt;
+  }
+  const auto& class_info = context.classes().Get(class_type->class_id);
+  if (!class_info.scope_id.has_value() ||
+      context.name_scopes().Get(class_info.scope_id).is_cpp_scope() ||
+      SemIR::RecognizedTypeInfo::ForType(context.sem_ir(), *class_type).kind !=
+          SemIR::RecognizedTypeInfo::None) {
+    return std::nullopt;
+  }
+  return class_type;
+}
+
+auto ExportNonMemberOperatorsToCpp(Context& context,
+                                   clang::NamespaceDecl* namespace_decl,
+                                   clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*> {
+  llvm::SmallVector<clang::NamedDecl*> operator_decls;
+  // The operand classes whose deleted operator template is declared.
+  llvm::SmallVector<SemIR::ClassId> template_operand_class_ids;
+  for (const auto& impl : context.impls().values()) {
+    // A binary operator impl whose operand type is a Carbon class exported
+    // with this namespace as its innermost enclosing namespace, where C++'s
+    // argument-dependent lookup on that operand looks, and whose `Self` is not
+    // a Carbon class: such a `Self` has the impl as a member operator instead
+    // (`ExportOperatorsToCpp`). Only SemIR is read before the impl is known
+    // to be one. An operand class that cannot be exported without a
+    // diagnostic is never named, so its impls are not declared at all: C++
+    // cannot form such an operand.
+    bool generic = impl.generic_id.has_value();
+    if (!IsOperatorImplOfKind(context, impl, op_kind, generic) ||
+        !impl.interface.specific_id.has_value() ||
+        GetCarbonRecordClassType(context, impl.self_id)) {
+      continue;
+    }
+    auto args = context.inst_blocks().Get(
+        context.specifics().Get(impl.interface.specific_id).args_id);
+    if (args.size() != 1) {
+      continue;
+    }
+    auto operand_class = GetCarbonRecordClassType(context, args.front());
+    if (!operand_class || operand_class->specific_id.has_value()) {
+      continue;
+    }
+    const auto* operand_decl = context.clang_decls().Lookup(
+        context.classes().Get(operand_class->class_id).first_decl_id());
+    if (!operand_decl ||
+        !operand_decl->decl()
+             ->getDeclContext()
+             ->getEnclosingNamespaceContext()
+             ->Equals(namespace_decl) ||
+        !CanExportWithoutDiagnostic(
+            context, context.types().GetTypeIdForTypeConstantId(
+                         context.constant_values().Get(args.front())))) {
+      continue;
+    }
+    bool needs_template =
+        generic || ExportImplOperators(context, impl, namespace_decl, op_kind,
+                                       operator_decls);
+    if (needs_template && !llvm::is_contained(template_operand_class_ids,
+                                              operand_class->class_id)) {
+      template_operand_class_ids.push_back(operand_class->class_id);
+      ExportDeletedOperatorTemplate(context, impl, namespace_decl, op_kind,
+                                    operator_decls);
+    }
+  }
+  return operator_decls;
+}
+
+auto IsExportedCarbonOperator(Context& context,
+                              const clang::FunctionDecl* function_decl)
+    -> bool {
+  if (!function_decl->isOverloadedOperator()) {
+    return false;
+  }
+  // A specialization of a deleted operator template is recognized by its
+  // template.
+  if (const auto* primary_template = function_decl->getPrimaryTemplate()) {
+    function_decl = primary_template->getTemplatedDecl();
+  }
+  return GetExportedOperatorInstId(
+             context, const_cast<clang::FunctionDecl*>(function_decl))
+      .has_value();
+}
+
 }  // namespace Carbon::Check
diff --git a/toolchain/check/cpp/export.h b/toolchain/check/cpp/export.h
index c02a6ae..0787797 100644
--- a/toolchain/check/cpp/export.h
+++ b/toolchain/check/cpp/export.h
@@ -141,6 +141,37 @@ auto ExportDestructorToCpp(Context& context, const SemIR::Class& class_info,
 auto ExportVarToCpp(Context& context, SemIR::InstId inst_id,
                     SemIR::VarStorage var_storage) -> clang::VarDecl*;

+// Exports the operator impls of the Carbon class behind `record_decl` that C++
+// spells as `op_kind` as member operators of `record_decl`, and returns them
+// (fork decision F-017; docs/design/interoperability/operators.md). Only a
+// complete, non-generic impl in this file whose `Self` is exactly the class
+// exports. Nothing exported can diagnose: an impl with an operand that has no
+// C++ mapping is omitted, one whose result has none or names a class that C++
+// cannot export without a diagnostic is declared deleted, and the class's
+// generic impls of a binary operator, with its impls whose operand names such a
+// class, are declared as one deleted operator template. Declarations an earlier
+// call returned are returned again. Returns an empty list when no impl exports.
+auto ExportOperatorsToCpp(Context& context, clang::CXXRecordDecl* record_decl,
+                          clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*>;
+
+// Exports the binary operator impls whose `Self` is not a Carbon class and
+// whose operand type is an exported Carbon class whose innermost enclosing
+// namespace is `namespace_decl`, as non-member operators of that namespace that
+// C++ finds by argument-dependent lookup on the operand (fork decision F-017),
+// as `ExportOperatorsToCpp` exports member operators, with one deleted operator
+// template per operand class. Returns them.
+auto ExportNonMemberOperatorsToCpp(Context& context,
+                                   clang::NamespaceDecl* namespace_decl,
+                                   clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*>;
+
+// Returns whether `function_decl` is a Carbon operator impl exported to C++ by
+// `ExportOperatorsToCpp` or `ExportNonMemberOperatorsToCpp`, a default
+// `operator!=` and a specialization of a deleted operator template among them.
+auto IsExportedCarbonOperator(Context& context,
+                              const clang::FunctionDecl* function_decl) -> bool;
+
 }  // namespace Carbon::Check

 #endif  // CARBON_TOOLCHAIN_CHECK_CPP_EXPORT_H_
diff --git a/toolchain/check/cpp/generate_ast.cpp b/toolchain/check/cpp/generate_ast.cpp
index 0a71687..98128f5 100644
--- a/toolchain/check/cpp/generate_ast.cpp
+++ b/toolchain/check/cpp/generate_ast.cpp
@@ -9,6 +9,7 @@

 #include "clang/AST/ASTContext.h"
 #include "clang/AST/Decl.h"
+#include "clang/AST/DeclContextInternals.h"
 #include "clang/AST/Mangle.h"
 #include "clang/Basic/DiagnosticParse.h"
 #include "clang/Basic/FileManager.h"
@@ -363,6 +364,37 @@ auto CarbonExternalASTSource::FindExternalVisibleDeclsByName(

   clang::IdentifierInfo* identifier = nullptr;
   switch (decl_name.getNameKind()) {
+    case clang::DeclarationName::CXXOperatorName: {
+      // A C++ overloaded operator applied to an exported Carbon class finds
+      // the class's Carbon operator impls by member lookup (fork decision
+      // F-017), and an impl whose `Self` is not a Carbon class by
+      // argument-dependent lookup in its operand class's namespace. No other
+      // Carbon entity answers an operator name. The answer grows as the file
+      // declares impls and C++ names their operand classes, so no answer is
+      // final: the entry stays marked as having external declarations, empty
+      // or not, and every later lookup, whatever makes it, asks again and gets
+      // every declaration exported so far.
+      auto* mutable_decl_context =
+          const_cast<clang::DeclContext*>(decl_context);
+      llvm::SmallVector<clang::NamedDecl*> operator_decls;
+      if (auto* record_decl =
+              dyn_cast<clang::CXXRecordDecl>(mutable_decl_context)) {
+        operator_decls = ExportOperatorsToCpp(
+            *context_, record_decl, decl_name.getCXXOverloadedOperator());
+      } else if (auto* namespace_decl =
+                     dyn_cast<clang::NamespaceDecl>(mutable_decl_context)) {
+        operator_decls = ExportNonMemberOperatorsToCpp(
+            *context_, namespace_decl, decl_name.getCXXOverloadedOperator());
+      }
+      if (operator_decls.empty()) {
+        SetNoExternalVisibleDeclsForName(decl_context, decl_name);
+      } else {
+        SetExternalVisibleDeclsForName(decl_context, decl_name, operator_decls);
+      }
+      (*decl_context->getPrimaryContext()->getLookupPtr())[decl_name]
+          .setHasExternalDecls();
+      return !operator_decls.empty();
+    }
     case clang::DeclarationName::Identifier: {
       identifier = decl_name.getAsIdentifierInfo();
       break;
diff --git a/toolchain/check/cpp/operators.cpp b/toolchain/check/cpp/operators.cpp
index 73cc8c1..d183ff7 100644
--- a/toolchain/check/cpp/operators.cpp
+++ b/toolchain/check/cpp/operators.cpp
@@ -11,6 +11,7 @@
 #include "toolchain/check/convert.h"
 #include "toolchain/check/core_identifier.h"
 #include "toolchain/check/cpp/custom_type_mapping.h"
+#include "toolchain/check/cpp/export.h"
 #include "toolchain/check/cpp/import.h"
 #include "toolchain/check/cpp/location.h"
 #include "toolchain/check/cpp/overload_resolution.h"
@@ -861,6 +862,44 @@ auto LookupCppOperator(Context& context, SemIR::LocId loc_id, Operator op,
   return FindClangOperator(context, loc_id, *op_kind, *maybe_arg_exprs);
 }

+// A Carbon operator impl exported to C++ is not a C++ operator function but
+// Carbon's own impl seen from C++, which Carbon's impl lookup finds itself
+// (fork decision F-017): marks each such candidate non-viable, so that overload
+// resolution gives the result Clang gives without it, and returns whether one
+// was viable. `ovl_non_default_multiversion_function` is the failure kind Clang
+// itself ignores silently in its notes.
+static auto RemoveExportedCarbonOperators(
+    Context& context, clang::OverloadCandidateSet& candidate_set) -> bool {
+  bool removed_viable = false;
+  for (auto& candidate : candidate_set) {
+    if (candidate.Function &&
+        IsExportedCarbonOperator(context, candidate.Function)) {
+      removed_viable |= candidate.Viable;
+      candidate.Viable = false;
+      candidate.FailureKind = clang::ovl_non_default_multiversion_function;
+    }
+  }
+  return removed_viable;
+}
+
+// Returns whether `candidate`, the candidate that C++ overload resolution
+// selects for an operator expression, is a concrete Carbon operator impl
+// exported to C++ (not a specialization of a deleted operator template) that it
+// selects without a rewrite and with every operand an exact match. Carbon's own
+// impl lookup then selects the impl that the exported operator calls.
+static auto IsExactMatchOfExportedCarbonOperator(
+    Context& context, const clang::OverloadCandidate& candidate) -> bool {
+  return candidate.Function && !candidate.RewriteKind &&
+         !candidate.Function->getPrimaryTemplate() &&
+         IsExportedCarbonOperator(context, candidate.Function) &&
+         llvm::all_of(candidate.Conversions,
+                      [](const clang::ImplicitConversionSequence& conversion) {
+                        return conversion.isStandard() &&
+                               conversion.Standard.getRank() ==
+                                   clang::ICR_Exact_Match;
+                      });
+}
+
 static auto FindClangOperator(Context& context, SemIR::LocId loc_id,
                               clang::OverloadedOperatorKind op_kind,
                               llvm::ArrayRef<clang::Expr*> arg_exprs)
@@ -877,8 +916,34 @@ static auto FindClangOperator(Context& context, SemIR::LocId loc_id,
   sema.LookupOverloadedBinOp(candidate_set, op_kind, clang::UnresolvedSet<0>{},
                              arg_exprs);

+  // The lookup can export Carbon operator impls, as any C++ lookup of an
+  // operator on a Carbon class can (fork decision F-017). The candidates are
+  // first resolved as they are for C++ code, exported operators included. When
+  // C++ selects one with every operand an exact match, Carbon's own impl lookup
+  // selects the same impl, so no C++ operator is returned, and Carbon agrees
+  // with C++. Otherwise an exported operator, which is Carbon's own impl seen
+  // from C++ and not a C++ operator function, is no candidate for Carbon's
+  // expression: every one is removed and the candidates are resolved again,
+  // and again whenever that resolution deduced a viable specialization of a
+  // deleted operator template.
   clang::OverloadCandidateSet::iterator best_viable_fn;
-  switch (candidate_set.BestViableFunction(sema, loc, best_viable_fn)) {
+  auto result = candidate_set.BestViableFunction(sema, loc, best_viable_fn);
+  if ((result == clang::OverloadingResult::OR_Success ||
+       result == clang::OverloadingResult::OR_Deleted) &&
+      IsExactMatchOfExportedCarbonOperator(context, *best_viable_fn)) {
+    return SemIR::InstId::None;
+  }
+  while (RemoveExportedCarbonOperators(context, candidate_set)) {
+    result = candidate_set.BestViableFunction(sema, loc, best_viable_fn);
+  }
+  // Clang's notes deduce any template candidate still deferred; an exported
+  // operator is not noted either.
+  auto is_not_exported = [&](clang::OverloadCandidate& candidate) {
+    return !candidate.Function ||
+           !IsExportedCarbonOperator(context, candidate.Function);
+  };
+
+  switch (result) {
     case clang::OverloadingResult::OR_Success: {
       if (!best_viable_fn->Function) {
         // The best viable candidate was a builtin. Let the Carbon operator
@@ -931,7 +996,8 @@ static auto FindClangOperator(Context& context, SemIR::LocId loc_id,
               loc, sema.PDiag(clang::diag::err_ovl_ambiguous_oper_binary)
                        << spelling << arg_exprs[0]->getType()
                        << arg_exprs[1]->getType()),
-          sema, clang::OCD_AmbiguousCandidates, arg_exprs, spelling, loc);
+          sema, clang::OCD_AmbiguousCandidates, arg_exprs, spelling, loc,
+          is_not_exported);
       return SemIR::ErrorInst::InstId;
     }
     case clang::OverloadingResult::OR_Deleted:
@@ -947,7 +1013,8 @@ static auto FindClangOperator(Context& context, SemIR::LocId loc_id,
                               best_viable_fn->Function->getOverloadedOperator())
                        << (message != nullptr)
                        << (message ? message->getString() : llvm::StringRef())),
-          sema, clang::OCD_AllCandidates, arg_exprs, spelling, loc);
+          sema, clang::OCD_AllCandidates, arg_exprs, spelling, loc,
+          is_not_exported);
       return SemIR::ErrorInst::InstId;
   }
 }
```

### §2.5 Goldens (sources only: `// AUTOUPDATE`, no CHECK lines; R15, R16(a))

Four new files, filled only by autoupdate (commit 4): rev 2 adds
operator_cxx20.carbon and 23 splits (amended 2026-10-14, review fold: A-1, A-2,
A-3, A-4, A-5, A-7, A-9, B-1, B-2, B-3, B-10). Rev 3 adds eight splits —
`fail_generic_impl_conversion`, `fail_generic_impl_conversion_non_member`,
`fail_deleted_result_not_equal`, `fail_todo_sfinae_detection`,
`carbon_side_deferred_template`, `todo_carbon_side_memoized_trait`,
`fail_todo_non_member_before_operand` and the lower
`carbon_side_template_candidate` — renames the lower `generic_impl_hidden` to
`generic_impl`, with a `long` C++ operand and a Carbon function with a C++
operand, adds a generic `DivWith` impl to the AST golden, and comments
`fail_todo_generic_impl` and the file headers (amended 2026-10-14, review fold:
RR-1 to RR-6, and the fixer's M-36). Rev 4 renames four splits that now
compile, `fail_todo_unexportable_operand_class` to
`unexportable_operand_class`, `fail_todo_sfinae_detection` to
`sfinae_detection` (now with an `Euro` that has `+`),
`fail_todo_non_member_before_operand` to `non_member_before_operand` and
`fail_todo_impl_after_lookup` to `impl_after_lookup`, and
`todo_carbon_side_memoized_trait` to `carbon_side_trait_sees_export`, its
`static_assert` inverted; adds `fail_unexportable_operand_conversion`,
`fail_unexportable_result_class`, `non_member_unexportable_operand` and the
four `carbon_side_*_unexportable` splits (the second re-reviewer's a1, a4, b1
and c1 with c3) to the check golden, `fail_todo_carbon_side_rewritten_candidate`
(its e2) to the C++20 golden, and `carbon_side_template_body`,
`carbon_side_call_template` and `carbon_side_conversion_template` (its a3, b2
and c2) to the lower golden, whose `carbon_side_template_candidate` now
expects the template; names every unused binding `_` or marks it `unused`;
and rewrites the comments that said Carbon's lookup exports nothing (amended
2026-10-14, review fold: RR2-1, RR2-2, RR2-4). Rev 5 adds five splits to the
check golden, `carbon_side_str_operand_without_header`,
`str_operand_without_header`, `carbon_side_result_without_header`,
`carbon_side_slice_field` (the re-reviewer's p1, p1c, p2 and p18) and
`self_referential_operand` (the fixer's f1); renames
`fail_todo_carbon_side_rewritten_candidate` to the positive
`carbon_side_rewritten_candidate` and adds `carbon_side_rewritten_ordering`
(its k5, without `<compare>`, which file_test's environment lacks: the
template's `<=>` returns `int`) to the C++20 golden; adds
`carbon_side_call_template_body`, `carbon_side_compound_template` (its k4b)
and `carbon_side_agrees_with_cpp_side` (its k1 and k2, k2's `std::optional`
replaced by a class template `Opt` with the same mixed `==` template) to the
lower golden, whose `carbon_side_template_candidate` and
`carbon_side_template_body` now expect the impl; drops the `Cpp.Foo` impl from
`carbon_side_trait_sees_export`, `carbon_side_template_body_unexportable` and
`carbon_side_constexpr_body_unexportable`, so that C++ and Carbon select their
template, whose deduction or body these splits pin; and rewrites the comments
that said no exported operator is ever a candidate for Carbon (amended
2026-10-14, review fold: RR3-B1, RR3-B2, RR3-M1). Splits whose name begins
`fail_` must fail; the others must compile (M-12 measured both ways on trunk,
`v4`, `v5`, `v6`, `v7` and `v8`). No existing golden changes (M-8).

#### toolchain/check/testdata/interop/cpp/class/export/operator.carbon (55 splits)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator.carbon

// Carbon operator impls on an exported Carbon class are C++ operators (fork
// decision F-017, docs/design/interoperability/operators.md): an impl whose
// `Self` is the class is a member operator, `const` for a `self` member and
// lvalue-ref-qualified (`&`) for a `ref self` one; an impl whose `Self` C++
// sees as anything else and whose operand is the class is a non-member
// operator in the class's innermost enclosing namespace, found by
// argument-dependent lookup. An impl with an operand that has no C++ form is
// omitted, one whose result has none or names a class that C++ cannot export
// is declared deleted, and the generic impls of an operator, with the impls
// whose operand names such a class, are one deleted operator template, so no
// export emits a diagnostic. Every C++ lookup of an operator name asks again,
// whatever made it. A Carbon operator expression with a C++ operand agrees with
// C++ when C++ selects an exported operator with every operand an exact match:
// Carbon's impl lookup then selects the impl that the operator calls.
// Otherwise no exported operator is a C++ candidate for it, and C++ templates
// see the exported operators whether C++ code or a Carbon expression, call or
// conversion instantiates them (the `carbon_side_*` splits). The
// `static_assert`s pin the C++ result types.
// The sibling operator_ast.carbon pins the declarations Clang is handed,
// operator_cxx20.carbon the C++20 behavior, and lower/.../operator.carbon the
// thunks and which function a Carbon expression calls.

// --- arithmetic.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents + other.cents); }
}
impl Money as Core.SubWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents - other.cents); }
}
impl Money as Core.MulWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents * k); }
}
impl Money as Core.DivWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents / k); }
}
impl Money as Core.ModWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents % k; }
}
impl Money as Core.Negate where .Result = Money {
  fn Op(self) -> Money { return Money.Make(-self.cents); }
}

inline Cpp '''
using Carbon::Money;
static_assert(__is_same(decltype(Money::Make(1) + Money::Make(2)), Money));
static_assert(__is_same(decltype(Money::Make(1) - Money::Make(2)), Money));
static_assert(__is_same(decltype(Money::Make(1) * 3), Money));
// C++ converts a `long` operand to the impl's `int`; Carbon would need an
// `impl Money as MulWith(i64)` (a documented divergence; the Carbon side is
// fail_conversion_carbon_side).
static_assert(__is_same(decltype(Money::Make(1) * 3L), Money));
static_assert(__is_same(decltype(Money::Make(1) / 3), Money));
static_assert(__is_same(decltype(Money::Make(1) % 3), int));
static_assert(__is_same(decltype(-Money::Make(1)), Money));
inline int Use(const Money& a, const Money& b) {
  return (a + b - b * 2 / 3).cents + a % 7 + (-a).cents;
}
''';

// --- fail_conversion_carbon_side.carbon

library "[[@TEST_NAME]]";

class Money {
  var cents: i32;
}

impl Money as Core.MulWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents * k; }
}

// Carbon looks up `MulWith(i64)` and does not convert the operand, where C++'s
// `m * 3L` converts it to the `int` impl (arithmetic), a documented
// divergence.
fn Use(m: Money, k: i64) -> i32 { return m * k; }

// --- signature_from_impl_function.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

// C++ sees the impl function's own declared signature: Carbon types `m + k` as
// the interface's `Result`, `i64`, and C++ as the function's `i32`; and C++
// takes the function's `i64` parameter, so `m - 1L` compiles, where Carbon's
// `m - k` needs `k: i32`. Both are documented divergences.
impl Money as Core.AddWith(i32) where .Result = i64 {
  fn Op(self, k: i32) -> i32 { return self.cents + k; }
}
impl Money as Core.SubWith(i32) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents - (k as i32); }
}

inline Cpp '''
static_assert(__is_same(decltype(Carbon::Money::Make(1) + 1), int));
inline int Use(Carbon::Money m) { return m - 1L; }
''';

// --- compound_assignment.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}
impl Money as Core.MulAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents *= k; }
}
impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}
impl Money as Core.Dec {
  fn Op(ref self) { --self.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Use(Money a, Money b) {
  static_assert(__is_same(decltype(a += b), void));
  static_assert(__is_same(decltype(++a), void));
  a += b;
  a *= 2;
  ++a;
  --a;
  return a.cents;
}
''';

// --- fail_compound_assignment_rvalue.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}

inline Cpp '''
using Carbon::Money;
// A `ref self` operator is `&`-qualified: like a `ref self` method, it is not
// callable on a temporary.
inline void Use(Money b) { Money::Make(1) += b; }
''';

// --- fail_postfix_increment.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}

inline Cpp '''
// Carbon's `++` is a prefix statement: only `operator++()` is exported.
inline void Use(Carbon::Money& a) { a++; }
''';

// --- comparison.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl Money as Core.OrderedWith(Money) {
  fn Less(self, other: Money) -> bool { return self.cents < other.cents; }
  fn LessOrEquivalent(self, other: Money) -> bool { return self.cents <= other.cents; }
  fn Greater(self, other: Money) -> bool { return self.cents > other.cents; }
  fn GreaterOrEquivalent(self, other: Money) -> bool { return self.cents >= other.cents; }
}

class Unknowable {
  var v: i32;
}

impl Unknowable as Core.EqWith(Unknowable) {
  fn Equal(self, o: Unknowable) -> bool { return self.v != 0 and o.v != 0 and self.v == o.v; }
  fn NotEqual(self, o: Unknowable) -> bool { return self.v != 0 and o.v != 0 and self.v != o.v; }
}

inline Cpp '''
using Carbon::Money;
static_assert(__is_same(decltype(Money() == Money()), bool));
static_assert(__is_same(decltype(Money() != Money()), bool));
static_assert(__is_same(decltype(Money() < Money()), bool));
inline bool Use(Money a, Money b, Carbon::Unknowable u) {
  return (a == b) && (a != b) && (a < b) && (a <= b) && (a > b) && (a >= b) && (u != u);
}
''';

// --- move_only_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct NoCopy {
  explicit NoCopy(int v) : v(v) {}
  NoCopy(const NoCopy&) = delete;
  NoCopy(NoCopy&&) = default;
  int v;
};
''';

class Money {
  var n: Cpp.NoCopy;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, o: Money) -> bool { return self.n.v == o.n.v; }
}

inline Cpp '''
// The default `operator!=` moves its by-value operands on to `operator==`, so
// a move-only class has it too.
inline bool Use() {
  return Carbon::Money{NoCopy(1)} != Carbon::Money{NoCopy(2)};
}
''';

// --- fail_reversed_equality.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `m == 5` but not `5 == m`; with `operator!=` exported beside
// `operator==`, C++20 does not synthesize the reversed candidate either.
impl Money as Core.EqWith(i32) {
  fn Equal(self, k: i32) -> bool { return self.cents == k; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return m == 5; }
inline bool Reversed(Carbon::Money m) { return 5 == m; }
''';

// --- bitwise.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Bits {
  var v: u8;
}

impl Bits as Core.BitAndWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v & o.v}; }
}
impl Bits as Core.BitOrWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v | o.v}; }
}
impl Bits as Core.BitXorWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v ^ o.v}; }
}
impl Bits as Core.BitComplement where .Result = Bits {
  fn Op(self) -> Bits { return {.v = ^self.v}; }
}
impl Bits as Core.LeftShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return {.v = self.v << (n as u8)}; }
}
impl Bits as Core.RightShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v >>= (n as u8); }
}

inline Cpp '''
using Carbon::Bits;
static_assert(__is_same(decltype(~Bits()), Bits));
inline int Use(Bits a, Bits b) {
  Bits c = (a & b) | (a ^ b);
  c >>= 1;
  return (~c << 2).v;
}
''';

// --- index.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Pair {
  var first: i32;
  var second: i32;
}

impl Pair as Core.IndexWith(i32) where .ElementType = i32 {
  fn At(self, i: i32) -> i32 { if (i == 0) { return self.first; } return self.second; }
}
impl Pair as Core.IndexWith(bool) where .ElementType = i32 {
  fn At(self, b: bool) -> i32 { if (b) { return self.second; } return self.first; }
}

inline Cpp '''
using Carbon::Pair;
static_assert(__is_same(decltype(Pair()[0]), int));
// Two impls of one interface are one C++ overload set: `true` selects the
// `bool` member by exact match, as Carbon's `p[true]` selects `IndexWith(bool)`.
inline int Use(const Pair& p) { return p[0] + p[true]; }
''';

// --- non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}
impl i32 as Core.SubAssignWith(Money) {
  fn Op(ref self, m: Money) { self -= m.cents; }
}
impl Cpp.Foo as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self.n + m.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Use(Money m, int k, Foo f) {
  k -= m;
  return (50 - m) + (5 == m) + (4 != m) + k + (f + m);
}
''';

// --- non_member_nested.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Outer {
  class Inner {
    var cents: i32;
  }
}

impl i32 as Core.SubWith(Outer.Inner) where .Result = i32 {
  fn Op(self, m: Outer.Inner) -> i32 { return self - m.cents; }
}

inline Cpp '''
// Argument-dependent lookup on a nested class looks in its innermost enclosing
// namespace, `Carbon`, which declares the non-member operator.
inline int Use(Carbon::Outer::Inner m) { return 50 - m; }
''';

// --- namespace.carbon

library "[[@TEST_NAME]]";

import Cpp;

namespace Units;

class Units.Money {
  var cents: i32;
  extend impl as Core.SubWith(Units.Money) where .Result = i32 {
    fn Op(self, o: Units.Money) -> i32 { return self.cents - o.cents; }
  }
}

impl i32 as Core.MulWith(Units.Money) where .Result = i32 {
  fn Op(self, m: Units.Money) -> i32 { return self * m.cents; }
}

inline Cpp '''
inline int Use(Carbon::Units::Money a, Carbon::Units::Money b) {
  return (a - b) + 2 * a;
}
''';

// --- base_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

base class Base {
  var v: i32;
}

class Derived {
  extend base: Base;
}

impl Base as Core.AddWith(Base) where .Result = i32 {
  fn Op(self, o: Base) -> i32 { return self.v + o.v; }
}

inline Cpp '''
// C++ member lookup finds `Base::operator+` from a `Derived` and converts
// both operands to `Base`; Carbon's impl lookup for `Derived` finds no
// `AddWith` impl (fail_base_class_carbon_side), a documented divergence.
inline int Use(const Carbon::Derived& d) { return d + d; }
''';

// --- fail_base_class_carbon_side.carbon

library "[[@TEST_NAME]]";

base class Base {
  var v: i32;
}

class Derived {
  extend base: Base;
}

impl Base as Core.AddWith(Base) where .Result = i32 {
  fn Op(self, o: Base) -> i32 { return self.v + o.v; }
}

fn Use(d: Derived) -> i32 { return d + d; }

// --- fail_noncopyable_lvalue_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct NoCopy {
  explicit NoCopy(int v) : v(v) {}
  NoCopy(const NoCopy&) = delete;
  NoCopy(NoCopy&&) = default;
  int v;
};
''';

class Money {
  var n: Cpp.NoCopy;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.n.v + o.n.v; }
}

// Carbon passes `b` as a value, without a copy.
fn CarbonSide(a: Money, b: Money) -> i32 { return a + b; }

inline Cpp '''
// The exported operator takes its operand by value, as an exported method
// does, so C++ copies an lvalue operand, and `Money` cannot be copied: a
// documented divergence.
inline int CppSide(const Carbon::Money& a, const Carbon::Money& b) { return a + b; }
''';

// --- fail_todo_generic_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T) where .Result = i32 {
  fn Op(self, k: T) -> i32 { return self.cents * (k as i32); }
}

inline Cpp '''
// The generic impl has no C++ form (fork work item W-202): it is declared as a
// deleted operator template, so C++ rejects the use.
inline int Use(Carbon::Money m) { return m * 3; }
''';

// --- fail_generic_impl_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon's `m * k` for `k: i32` selects the generic impl. Its deleted operator
// template matches an `int` operand exactly, so C++ rejects `m * k` instead of
// converting `k` to `long` for the `i64` impl.
impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T) where .Result = i32 {
  fn Op(self, k: T) -> i32 { return self.cents * (k as i32); }
}
impl Money as Core.MulWith(i64) where .Result = i32 {
  fn Op(self, _: i64) -> i32 { return self.cents; }
}

inline Cpp '''
inline int Use(Carbon::Money m, int k) { return m * k; }
''';

// --- fail_generic_impl_conversion_non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// The non-member form of `fail_generic_impl_conversion`: C++ rejects `k * m`
// instead of converting `k` to `long` for the `i64` impl.
impl forall [T: Core.ImplicitAs(i32)] T as Core.MulWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return (self as i32) * m.cents; }
}
impl i64 as Core.MulWith(Money) where .Result = i32 {
  fn Op(unused self, m: Money) -> i32 { return m.cents; }
}

inline Cpp '''
inline int Use(int k, Carbon::Money m) { return k * m; }
''';

// --- unmappable_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith((i32, i32)) where .Result = i32 {
  fn Op(self, p: (i32, i32)) -> i32 { return self.cents + p.0 + p.1; }
}

inline Cpp '''
// The tuple impl has no C++ form and is omitted without a diagnostic; C++
// cannot form a tuple operand, so the omission cannot change which impl a
// C++ `+` selects.
inline int Use(Carbon::Money m) { return m + m; }
''';

// --- deleted_result_unselected.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(i32) where .Result = (i32, i32) {
  fn Op(self, k: i32) -> (i32, i32) { return (self.cents, k); }
}
impl Money as Core.AddWith(i64) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents + (k as i32); }
}

inline Cpp '''
// The tuple-result impl is declared deleted; a `long` operand selects the
// `i64` impl by exact match, as Carbon's `m + k` does for `k: i64`.
inline int Use(Carbon::Money m, long k) { return m + k; }
''';

// --- fail_deleted_result.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// The exact match for a C++ `int`, but its tuple result has no C++ form: the
// operator is declared deleted, so C++ rejects `m + k` instead of converting
// `k` to `long` for the `i64` impl, which Carbon's `m + k` does not select.
impl Money as Core.AddWith(i32) where .Result = (i32, i32) {
  fn Op(self, k: i32) -> (i32, i32) { return (self.cents, k); }
}
impl Money as Core.AddWith(i64) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents + (k as i32); }
}

inline Cpp '''
inline int Use(Carbon::Money m, int k) { return m + k; }
''';

// --- fail_deleted_result_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

class Tag {}

impl (Tag, bool) as Core.ImplicitAs(bool) {
  fn Convert(self) -> bool { return self.1; }
}

// `Equal`'s tuple result has no C++ form, so `operator==(int)` is deleted, and
// so is the `operator!=(int)` that stands for the default `NotEqual`: C++
// rejects `m != k` instead of converting `k` to `long` for the `i64` impl.
impl Money as Core.EqWith(i32) {
  fn Equal(self, k: i32) -> (Tag, bool) { return ({}, self.cents == k); }
}
impl Money as Core.EqWith(i64) {
  fn Equal(unused self, _: i64) -> bool { return false; }
  fn NotEqual(unused self, _: i64) -> bool { return true; }
}

inline Cpp '''
inline bool Use(Carbon::Money m, int k) { return m != k; }
''';

// --- unexportable_operand_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// A class C++ cannot export: its tuple field has no C++ form.
class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}

inline Cpp '''
// The `Holder` impl is not declared: the deleted operator template stands for
// it, so no candidate names `Carbon::Holder` and nothing completes it, and the
// exact match selects the `Money` impl.
inline int Use(Carbon::Money m) { return m + m; }
''';

// --- fail_unexportable_operand_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}
impl Money as Core.AddWith(i64) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents + (k as i32); }
}

inline Cpp '''
// The deleted operator template that stands for the `Holder` impl matches an
// `int` exactly, so C++ rejects `m + k` rather than convert `k` to `long` for
// the `i64` impl, which Carbon's `m + k` does not select for `k: i32`.
inline int Use(Carbon::Money m, int k) { return m + k; }
''';

// --- fail_unexportable_result_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = Holder {
  fn Op(self, f: Cpp.Foo) -> Holder { return {.t = (self.cents, f.n)}; }
}

inline Cpp '''
// The result names `Holder`, which C++ cannot export: the operator is declared
// deleted, with a `void` result, and `Holder` is never completed.
inline void Use(Carbon::Money m, Foo f) { m + f; }
''';

// --- non_member_unexportable_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl i32 as Core.SubWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self - h.t.0; }
}
impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}

inline Cpp '''
// C++ names `Holder` without completing it, so argument-dependent lookup on
// `m` finds an exported operand class that C++ cannot export: the non-member
// walk declares nothing for its impl, and nothing completes `Holder`.
inline int Use(Carbon::Holder* p, Carbon::Money m) { return 50 - m; }
''';

// --- sfinae_detection.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

class Euro {
  var cents: i32;
}

// A class C++ cannot export: its tuple field has no C++ form.
class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}
impl Euro as Core.AddWith(Euro) where .Result = i32 {
  fn Op(self, o: Euro) -> i32 { return self.cents + o.cents; }
}
impl Euro as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}

inline Cpp '''
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
// A detection completes no class: `Money + Money` selects the deleted operator
// template that stands for the `Holder` impl, a substitution failure, as Carbon
// has no `Money + Money`; `Euro + Euro` selects the `Euro` impl.
static_assert(!HasPlus<Carbon::Money>::value);
static_assert(HasPlus<Carbon::Euro>::value);
''';

// --- cpp_side_unrelated_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Vec(N: i32) {
  var x: i32;
}

class Money {
  var cents: i32;
}

// Not an operator impl: C++'s lookup of `operator+` never maps its `Self`,
// whose non-type parameter has no C++ form.
impl Vec(3) as Core.ImplicitAs(Money) {
  fn Convert(self) -> Money { return {.cents = self.x}; }
}
impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
inline int Use(Carbon::Money m) { return m + m; }
''';

// --- carbon_side_unmappable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

// Carbon's impl lookup for `Money as AddWith(Cpp.Foo)` asks C++ for an
// operator, which looks up `operator+` in the exported `Carbon::Money`. That
// lookup declares the impl's operator deleted, its tuple result having no C++
// form. C++ selects it, every operand an exact match, so Carbon's lookup finds
// no C++ operator and uses the impl, which Carbon can call.
impl Money as Core.AddWith(Cpp.Foo) where .Result = (i32, i32) {
  fn Op(self, f: Cpp.Foo) -> (i32, i32) { return (self.cents, f.n); }
}

fn Use(m: Money, f: Cpp.Foo) -> i32 { return (m + f).0; }

// --- carbon_side_unexportable_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = Holder {
  fn Op(self, f: Cpp.Foo) -> Holder { return {.t = (self.cents, f.n)}; }
}
impl Money as Core.SubWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents - f.n; }
}
impl Money as Core.SubWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents - h.t.0; }
}

// Carbon-only: no lookup maps `Holder`, which C++ cannot export. The `+`
// impl's result names it, so its operator is deleted; the `-` impl's operand
// names it, so the deleted operator template stands for that impl.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return (m + f).t.0 + (m - f); }

// --- carbon_side_generic_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Wrapper(T: type) {
  var v: T;
}

class Vec(N: i32) {
  var x: i32;
}

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = Wrapper((i32, i32)) {
  fn Op(self, f: Cpp.Foo) -> Wrapper((i32, i32)) { return {.v = (self.cents, f.n)}; }
}
impl Money as Core.SubWith(Cpp.Foo) where .Result = Vec(3) {
  fn Op(self, f: Cpp.Foo) -> Vec(3) { return {.x = self.cents - f.n}; }
}

// Carbon-only: neither result, a specific C++ cannot export, is mapped; both
// operators are deleted.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return (m + f).v.0 + (m - f).x; }

// --- carbon_side_unrelated_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Vec(N: i32) {
  var x: i32;
}

class Money {
  var cents: i32;
}

impl Vec(3) as Core.ImplicitAs(Money) {
  fn Convert(self) -> Money { return {.cents = self.x}; }
}
impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

// Carbon-only: the `ImplicitAs` impl's `Self` is never mapped.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_candidates.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo {
  int n;
  operator int() const { return n; }
  operator long() const { return n; }
};
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents + k; }
}
impl Money as Core.AddWith(i64) where .Result = i32 {
  fn Op(self, _: i64) -> i32 { return self.cents; }
}
impl forall [T: type] Money as Core.AddWith(T) where .Result = i32 {
  fn Op(self, _: T) -> i32 { return self.cents; }
}

// Carbon-only: `Foo` converts to both `int` and `long`, so the two concrete
// impls would be equally good C++ candidates, and C++ selects the deleted
// operator template that stands for the generic impl, an exact match. That is
// not an exported operator that Carbon's impl lookup can stand for, so no
// exported operator is a candidate for Carbon's lookup, which finds no C++
// candidate and selects the generic impl.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_user_cpp_operator.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

inline Cpp '''
// A hand-written C++ operator for the exported class.
inline int operator+(const Carbon::Money& m, const Foo& f) { return m.cents + f.n + 1000; }
''';

// For C++ code this expression is ambiguous between the hand-written operator
// and the exported `Money::operator+(Foo)` (fork work item W-211). C++ selects
// no exported operator, so none is a candidate for Carbon's lookup, which
// finds the hand-written operator, as it did before operator impls were
// exported.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_then_cpp.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

// Carbon's lookup for this expression asks C++ about `operator+` in
// `Carbon::Money`, which exports the `Cpp.Foo` impl...
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
// ...and every lookup asks again, so this one exports the `Money` impl too.
inline int CppSide(Carbon::Money a, Carbon::Money b) { return a + b; }
''';

// --- carbon_side_deferred_template.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
// A hand-written operator template, enabled for a `T` that has `T + T`.
template <class T, typename EnableIf<HasPlus<T>::value>::type = 0>
int operator+(const T& a, const Foo& f) { return 100 + f.n; }
''';

class Money {
  var cents: i32;
}

// A class C++ cannot export: its tuple field has no C++ form.
class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}
impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

// Carbon-only: Carbon's lookup finds the template and the exported
// `Money::operator+(Foo)`, beside the deleted operator template that stands
// for the `Holder` impl, so `Holder` is never completed. C++ selects the
// exported operator, an exact match that is not a template, without deducing
// the template's arguments; so does Carbon's lookup, which then uses the impl
// (the lower `carbon_side_template_candidate` split pins the call).
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_trait_sees_export.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
template <class T, typename EnableIf<HasPlus<T>::value>::type = 0>
int operator+(const T& a, const Foo& f) { return 100 + f.n; }
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// No impl has a `Cpp.Foo` operand, so overload resolution for this expression
// deduces the template's arguments, which instantiates
// `HasPlus<Carbon::Money>`, whose lookup exports `Money::operator+(Money)`...
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

inline Cpp '''
// ...so the trait that Clang keeps is true, as it is when C++ code instantiates
// it first: a template sees the exported operators whoever instantiates it.
static_assert(HasPlus<Carbon::Money>::value);
''';

// --- carbon_side_template_body_unexportable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
// An unconstrained template that tests `T + T` in its body.
template <class T>
int operator+(const T& a, const Foo& f) { return HasPlus<T>::value ? 100 + f.n : 1; }
''';

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}

// Carbon-only: no impl has a `Cpp.Foo` operand, so C++ and Carbon's `m + f`
// select the template, whose body Clang instantiates at the end of the file
// and which looks up `Money + Money`; no export there names `Holder`, so the
// program compiles.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_constexpr_body_unexportable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
// A `constexpr` template, whose body Clang instantiates when Carbon's lookup
// marks the selected specialization referenced.
template <class T>
constexpr int operator+(const T& a, const Foo& f) { return HasPlus<T>::value ? 100 + f.n : 1; }
''';

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}

fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_call_unexportable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
template <class T, typename EnableIf<HasPlus<T>::value>::type = 0>
int Pick(const T&, int) { return 100; }
template <class T> int Pick(const T&, long) { return 1; }
''';

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}

// Carbon-only: Carbon's call deduces the SFINAE overload, whose lookup of
// `Money + Money` names no `Holder` (the lower `carbon_side_call_template`
// split pins which overload is called).
fn Use(m: Money) -> i32 { return Cpp.Pick(m, 0 as i32); }

// --- carbon_side_conversion_unexportable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
struct Bar {
  int v;
  template <class T, typename EnableIf<!HasPlus<T>::value>::type = 0> Bar(const T&) : v(1) {}
  template <class T, typename EnableIf<HasPlus<T>::value>::type = 0> Bar(const T&) : v(100) {}
};
inline int GetV(const Bar& b) { return b.v; }
''';

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}

// Carbon-only: an `as` conversion and an implicit argument conversion through
// SFINAE-constrained converting constructors, whose lookup of `Money + Money`
// names no `Holder`.
fn Use(m: Money) -> i32 { let b: Cpp.Bar = m as Cpp.Bar; return b.v + Cpp.GetV(m); }

// --- carbon_side_str_operand_without_header.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}
// `str` maps to `std::string_view`, found by name, and this file does not
// include `<string_view>`: the operand has no C++ form, so the impl is omitted.
impl Money as Core.AddWith(str) where .Result = i32 {
  fn Op(self, _: str) -> i32 { return self.cents; }
}

// Carbon-only: the lookup that this expression makes declares nothing for the
// `str` impl, so no export diagnoses.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- str_operand_without_header.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}
// Omitted, as in `carbon_side_str_operand_without_header`.
impl Money as Core.AddWith(str) where .Result = i32 {
  fn Op(self, _: str) -> i32 { return self.cents; }
}

inline Cpp '''
inline int CppSide(Carbon::Money m, Foo f) { return m + f; }
''';

// --- carbon_side_result_without_header.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}
// `Core.Result` maps to `Carbon::expected`, found by name, and this file does
// not include `<carbon/expected.h>`: the result has no C++ form, so the
// operator is declared deleted.
impl Money as Core.AddWith(Money) where .Result = Core.Result(i32, i32) {
  fn Op(self, o: Money) -> Core.Result(i32, i32) {
    return Core.Result(i32, i32).Ok(self.cents + o.cents);
  }
}

// Carbon-only: no export diagnoses.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_slice_field.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

// `Core.Slice` maps to `std::span`, found by name, which this file does not
// declare: the field has no C++ form, so C++ cannot export `Tagged`.
class Tagged {
  var s: Core.Slice(i32);
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}
// Stood for by the deleted operator template, so `Tagged` is never named.
impl Money as Core.AddWith(Tagged) where .Result = i32 {
  fn Op(self, _: Tagged) -> i32 { return self.cents; }
}

// Carbon-only: no export diagnoses.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- self_referential_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

// A class that names itself through an optional pointer field, which maps to
// `Node*`: deciding whether C++ can export `Node` reaches `Node` again, and the
// inner question is answered by the outer one.
class Node {
  var v: i32;
  var next: Core.Optional(Node*);
}

impl Node as Core.AddWith(Node) where .Result = i32 {
  fn Op(self, o: Node) -> i32 { return self.v + o.v; }
}

inline Cpp '''
inline int CppSide(Carbon::Node a, Carbon::Node b) { return a + b; }
''';

// --- fail_user_cpp_operator_ambiguous.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
// A hand-written C++ operator that duplicates the Carbon impl, as C++ code had
// to write before operator impls were exported: the two are equally good
// candidates (fork work item W-211).
inline int operator+(const Carbon::Money& a, const Carbon::Money& b) { return a.cents + b.cents; }
inline int Use() { return Carbon::Money::Make(30) + Carbon::Money::Make(12); }
''';

// --- fail_todo_non_carbon_operands.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

// Neither type is a Carbon class: C++'s argument-dependent lookup never asks
// namespace `Carbon`, so the impl is not exported (fork work item W-210).
impl Cpp.Foo as Core.AddWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.n + k; }
}

inline Cpp '''
inline int Use(Foo f) { return f + 2; }
''';

// --- fail_impl_after_use.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

inline Cpp '''
inline int Use(Carbon::Money m) { return m + m; }
''';

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// --- non_member_before_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

class Euro {
  var cents: i32;
}

impl Money as Core.MulWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents * k; }
}
impl i32 as Core.MulWith(Euro) where .Result = i32 {
  fn Op(self, e: Euro) -> i32 { return self * e.cents; }
}

inline Cpp '''
// C++'s first lookup of `operator*` in namespace `Carbon` is argument-dependent
// lookup for `m * 2`, before C++ has named `Euro`: the `i32` impl, whose
// operand C++ has not seen, is not exported then...
inline int First(Carbon::Money m) { return m * 2; }
''';

// ...and every lookup asks again, so this one, after C++ named `Euro`, exports
// it.

inline Cpp '''
inline int Second(Carbon::Euro e) { return 2 * e; }
''';

// --- impl_after_lookup.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
inline int First(Carbon::Money m) { return m + m; }
''';

// Declared after C++ looked `operator+` up: every lookup asks again, so the
// next one exports this impl too.
impl Money as Core.AddWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents + k; }
}

inline Cpp '''
inline int Second(Carbon::Money m) { return m + 1; }
''';

// --- money_lib.carbon

library "[[@TEST_NAME]]";

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// --- fail_todo_imported_class.carbon

library "[[@TEST_NAME]]";

import Cpp;
import library "money_lib";

inline Cpp '''
// An imported class's impls are not enumerated (W-204), and the class itself
// exports as an empty C++ record (W-203).
inline int Use(Carbon::Money m) { return m + m; }
''';
```

#### toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon (1 split, `--dump-cpp-ast`)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-cpp-ast
// SET-CHECK-SUBSET
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon

// The C++ AST that exported Carbon operator impls produce (fork decision
// F-017): `CXXMethodDecl`s of the exported class for impls whose `Self` is
// the class — `const` for `self`, `&` for `ref self` — each an inline
// function whose body calls the impl member's own Carbon thunk
// (`Op__carbon_thunk`, `Equal__carbon_thunk`); an `operator!=` beside an
// `operator==` whose impl leaves `NotEqual` to its default, with the body
// `!(*this == other)`, its operand moved on as an xvalue; a deleted
// `operator*` returning `void` for an impl whose result, a tuple, has no C++
// form; a deleted `operator/` template returning `void` for a generic impl,
// beside the concrete impl's `operator/(long)`; and a `FunctionDecl` in
// `namespace Carbon` for an impl whose `Self` is `i32`. The sibling
// operator.carbon pins the uses.

// --- operator.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return {.cents = self.cents + other.cents}; }
}
impl Money as Core.AddAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents += k; }
}
impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl Money as Core.MulWith(Money) where .Result = i32 {
  fn Op(self, other: Money) -> i32 { return self.cents * other.cents; }
}
impl Money as Core.MulWith(i32) where .Result = (i32, i32) {
  fn Op(self, k: i32) -> (i32, i32) { return (self.cents, k); }
}
impl forall [T: Core.ImplicitAs(i32)] Money as Core.DivWith(T) where .Result = i32 {
  fn Op(self, k: T) -> i32 { return self.cents / (k as i32); }
}
impl Money as Core.DivWith(i64) where .Result = i32 {
  fn Op(self, _: i64) -> i32 { return self.cents; }
}

inline Cpp '''
inline int Use(Carbon::Money a, Carbon::Money b) {
  a += 1;
  return (a + b != b) + (1 - a) + a * b + a / 2L;
}
''';
```

#### toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon (6 splits, `-std=c++20`)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-std=c++20
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon

// Exported Carbon operator impls under C++20 (fork decision F-017,
// docs/design/interoperability/operators.md): `operator!=` is always declared
// beside `operator==`, and no `operator<=>` is exported, so C++20 synthesizes
// no reversed or rewritten candidate, and C++ accepts exactly the operand
// orders that Carbon has impls for. A C++ template's own reversed or
// rewritten candidate can still be made viable by an exported operator; C++
// prefers the exported operator that every operand matches exactly, which is
// not rewritten, and so does Carbon's operator expression, which then uses the
// impl (the `carbon_side_*` splits). The sibling operator.carbon pins the
// default language mode, C++17.

// --- move_only_equality.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct NoCopy {
  explicit NoCopy(int v) : v(v) {}
  NoCopy(const NoCopy&) = delete;
  NoCopy(NoCopy&&) = default;
  int v;
};
''';

class Money {
  var n: Cpp.NoCopy;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, o: Money) -> bool { return self.n.v == o.n.v; }
}

inline Cpp '''
// C++20 looks up `operator!=` for every `==`, which builds the default
// `operator!=`: it moves its by-value operands on to `operator==`.
inline bool Use() {
  return (Carbon::Money{NoCopy(1)} == Carbon::Money{NoCopy(1)}) &&
         (Carbon::Money{NoCopy(1)} != Carbon::Money{NoCopy(2)});
}
''';

// --- fail_reversed_equality.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `m == 5` but not `5 == m`.
impl Money as Core.EqWith(i32) {
  fn Equal(self, k: i32) -> bool { return self.cents == k; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return m == 5; }
inline bool Reversed(Carbon::Money m) { return 5 == m; }
''';

// --- fail_reversed_equality_non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `5 == m` but not `m == 5`.
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return 5 == m; }
inline bool Reversed(Carbon::Money m) { return m == 5; }
''';

// --- fail_reversed_ordering.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `m < 5` but not `5 > m`; with no `operator<=>`, C++20 does not
// rewrite either.
impl Money as Core.OrderedWith(i32) {
  fn Less(self, k: i32) -> bool { return self.cents < k; }
  fn LessOrEquivalent(self, k: i32) -> bool { return self.cents <= k; }
  fn Greater(self, k: i32) -> bool { return self.cents > k; }
  fn GreaterOrEquivalent(self, k: i32) -> bool { return self.cents >= k; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return m < 5; }
inline bool Reversed(Carbon::Money m) { return 5 > m; }
''';

// --- carbon_side_rewritten_candidate.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasEq { static constexpr bool value = false; };
template <class T> struct HasEq<T, decltype(void(Decl<const T&>() == Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
template <class T, typename EnableIf<HasEq<T>::value>::type = 0>
bool operator==(const Foo&, const T&) { return false; }
''';

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, o: Money) -> bool { return self.cents == o.cents; }
}
impl Money as Core.EqWith(Cpp.Foo) {
  fn Equal(unused self, _: Cpp.Foo) -> bool { return true; }
}

// Carbon-only: C++20 forms the reversed candidate `f == m` from the template,
// which `Money == Money`, an exported operator, makes viable. C++ prefers the
// exported `Money::operator==(Foo)`, which is not rewritten and which every
// operand matches exactly, and so does Carbon's lookup, which then uses the
// `EqWith(Cpp.Foo)` impl.
fn Use(m: Money, f: Cpp.Foo) -> bool { return m == f; }

// --- carbon_side_rewritten_ordering.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasEq { static constexpr bool value = false; };
template <class T> struct HasEq<T, decltype(void(Decl<const T&>() == Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
// A hand-written `<=>` template, enabled for a `T` that has `T == T`; C++20
// rewrites `a < b` as `(a <=> b) < 0` for any result that compares with `0`.
template <class T, typename EnableIf<HasEq<T>::value>::type = 0>
int operator<=>(const T&, const Foo&) { return 1; }
''';

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, o: Money) -> bool { return self.cents == o.cents; }
}
impl Money as Core.OrderedWith(Cpp.Foo) {
  fn Less(unused self, _: Cpp.Foo) -> bool { return true; }
  fn LessOrEquivalent(unused self, _: Cpp.Foo) -> bool { return true; }
  fn Greater(unused self, _: Cpp.Foo) -> bool { return false; }
  fn GreaterOrEquivalent(unused self, _: Cpp.Foo) -> bool { return false; }
}

// Carbon-only: C++20 forms the rewritten candidate `(m <=> f) < 0` from the
// template, which `Money == Money`, an exported operator, makes viable. C++
// prefers the exported `Money::operator<(Foo)`, which is not rewritten, and so
// does Carbon's lookup, which then uses the `OrderedWith` impl.
fn Use(m: Money, f: Cpp.Foo) -> bool { return m < f; }
```

#### toolchain/lower/testdata/interop/cpp/class/export/operator.carbon (13 splits)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/export/operator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/export/operator.carbon

// The lowering of exported Carbon operator impls (fork decision F-017): the
// C++ operator inlines into its caller and calls the impl member's Carbon
// thunk, `_COp__carbon_thunk.<class>.<package>:<interface>...`, which calls
// the impl member `_COp.<class>...`; a default `!=` negates the `==` thunk's
// result; a Carbon operator expression with a C++ operand calls the Carbon
// impl directly, never its C++ export, even after C++ code exported it, and
// when C++ selects the exported operator with every operand an exact match,
// Carbon calls the impl that the operator calls, as C++ does; a C++ template
// sees the exported operators whoever instantiates it, so a Carbon call or
// conversion can select a C++ function that only an exported operator makes
// viable, and a C++ function that Carbon calls can call the export; and a
// generic impl's deleted operator template yields to a concrete impl's exact
// match in C++ and is never Carbon's candidate.

// --- member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return {.cents = self.cents + other.cents}; }
}
impl Money as Core.AddAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents += k; }
}

inline Cpp '''
inline int AddInCpp(Carbon::Money a, Carbon::Money b) {
  a += 2;
  return (a + b).cents;
}
''';

fn Call(a: Money, b: Money) -> i32 { return Cpp.AddInCpp(a, b); }

// --- default_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}

inline Cpp '''
inline bool NotEqualInCpp(Carbon::Money a, Carbon::Money b) { return a != b; }
''';

fn Call(a: Money, b: Money) -> bool { return Cpp.NotEqualInCpp(a, b); }

// --- non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}

inline Cpp '''
inline int SubInCpp(Carbon::Money m) { return 50 - m; }
''';

fn Call(m: Money) -> i32 { return Cpp.SubInCpp(m); }

// --- carbon_side_cpp_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

inline Cpp '''
inline int AddInCpp(Carbon::Money m, Foo f) { return m + f; }
''';

// Carbon's impl lookup for `Money as AddWith(Cpp.Foo)` also asks C++, which
// selects the `Money::operator+(Foo)` that `AddInCpp` exported, every operand
// an exact match; that operator is Carbon's own impl seen from C++, so the call
// below calls `_COp.Money...` directly.
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

fn CppSide(m: Money, f: Cpp.Foo) -> i32 { return Cpp.AddInCpp(m, f); }

// --- carbon_side_default_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Cpp.Foo as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self.n == m.cents; }
}

inline Cpp '''
// Exports `Equal` as `Carbon::operator==(Foo, Money)` and the default
// `Carbon::operator!=(Foo, Money)` beside it.
inline bool NotEqualInCpp(Foo f, Carbon::Money m) { return f != m; }
''';

// C++ selects the exported default `operator!=`, every operand an exact match,
// so Carbon's lookup uses the impl: this calls the interface's default
// `NotEqual` for the impl.
fn CarbonSide(f: Cpp.Foo, m: Money) -> bool { return f != m; }

fn CppSide(f: Cpp.Foo, m: Money) -> bool { return Cpp.NotEqualInCpp(f, m); }

// --- carbon_side_template_candidate.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
// Viable only for a `T` that has `T + T`.
template <class T, typename EnableIf<HasPlus<T>::value>::type = 0>
int operator+(const T& a, const Foo& f) { return 100 + f.n; }
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

// Carbon-only: the template would be viable through the exported
// `Money::operator+(Money)`, but C++ selects the exported
// `Money::operator+(Foo)`, an exact match that is not a template, without
// deducing the template's arguments, and so does Carbon's lookup: this calls
// `_COp.Money...`, the impl.
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_template_body.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
// An unconstrained template whose body applies `T + T` when it can.
template <class T>
int operator+(const T& a, const Foo& f) {
  if constexpr (HasPlus<T>::value) {
    return a + a;
  } else {
    return f.n;
  }
}
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

// Carbon-only: C++ prefers the exported `Money::operator+(Foo)` to the
// unconstrained template, a function that is not a template winning the tie,
// and so does Carbon's lookup: this calls `_COp.Money...`, the impl, and the
// template's body is never instantiated.
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_call_template.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
template <class T, typename EnableIf<HasPlus<T>::value>::type = 0>
int Pick(const T&, int) { return 100; }
template <class T> int Pick(const T&, long) { return 1; }
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// Carbon-only: the call's deduction sees the exported `Money::operator+`, so it
// calls the `int` overload, the exact match.
fn CarbonSide(m: Money) -> i32 { return Cpp.Pick(m, 0 as i32); }

// --- carbon_side_conversion_template.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
struct Bar {
  int v;
  template <class T, typename EnableIf<!HasPlus<T>::value>::type = 0> Bar(const T&) : v(1) {}
  template <class T, typename EnableIf<HasPlus<T>::value>::type = 0> Bar(const T&) : v(100) {}
};
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// Carbon-only: the conversion's deduction sees the exported
// `Money::operator+`, so it calls the constructor that sets `v` to 100.
fn CarbonSide(m: Money) -> i32 { let b: Cpp.Bar = m as Cpp.Bar; return b.v; }

// --- carbon_side_call_template_body.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
template <class T> int Sum(const T& a, const T& b) { return a + b; }
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// Carbon-only: the call selects `Sum<Carbon::Money>`, a C++ function; its body,
// C++ code that Clang instantiates at the end of the file, calls the exported
// `Money::operator+(Money)`, whose thunk calls the `Money` impl.
fn CarbonSide(m: Money) -> i32 { return Cpp.Sum(m, m); }

// --- carbon_side_compound_template.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
// Viable only for a `T` that has `T + T`; it assigns nothing.
template <class T, typename EnableIf<HasPlus<T>::value>::type = 0>
void operator+=(T&, const Foo&) {}
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddAssignWith(Cpp.Foo) {
  fn Op(ref self, f: Cpp.Foo) { self.cents += f.n; }
}

// Carbon-only: C++ selects the exported `Money::operator+=(Foo) &`, an exact
// match that is not a template, and so does Carbon's lookup: this calls
// `_COp.Money...`, the `AddAssignWith` impl, which assigns.
fn CarbonSide(f: Cpp.Foo) -> i32 {
  var m: Money = {.cents = 5};
  m += f;
  return m.cents;
}

// --- carbon_side_agrees_with_cpp_side.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
template <class T> T&& Decl();
template <class T, class = void> struct HasPlus { static constexpr bool value = false; };
template <class T> struct HasPlus<T, decltype(void(Decl<const T&>() + Decl<const T&>()))> { static constexpr bool value = true; };
template <bool B> struct EnableIf {};
template <> struct EnableIf<true> { using type = int; };
template <class T, typename EnableIf<HasPlus<T>::value>::type = 0>
int operator+(const T& a, const Foo& f) { return 100 + f.n; }
// An optional-like class template with the shape of `std::optional`'s mixed
// `==`, viable when `T == U` is.
template <class U> struct Opt {
  Opt() : has(false), v() {}
  Opt(U u) : has(true), v(u) {}
  bool has;
  U v;
};
template <class T, class U, class = decltype(Decl<const T&>() == Decl<const U&>())>
bool operator==(const T& t, const Opt<U>& o) { return o.has ? t == o.v : false; }
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}
impl Money as Core.EqWith(Cpp.Opt(i32)) {
  fn Equal(unused self, _: Cpp.Opt(i32)) -> bool { return true; }
}

// The same expressions in Carbon and in C++. Each template is viable through an
// exported operator (`Money + Money`, and `Money == int`, which converts the
// `int` to an `Opt<int>`), but C++ selects the exported `Money::operator+(Foo)`
// and `Money::operator==(Opt<int>)`, exact matches that are not templates, and
// Carbon's expressions call the impls that those operators call,
// `_COp.Money...` and `_CEqual.Money...`.
fn CarbonPlus(m: Money, f: Cpp.Foo) -> i32 { return m + f; }
fn CarbonEq(m: Money, o: Cpp.Opt(i32)) -> bool { return m == o; }

inline Cpp '''
inline int CppPlus(const Carbon::Money& m, const Foo& f) { return m + f; }
inline bool CppEq(const Carbon::Money& m, const Opt<int>& o) { return m == o; }
''';

fn CppPlusSide(m: Money, f: Cpp.Foo) -> i32 { return Cpp.CppPlus(m, f); }
fn CppEqSide(m: Money, o: Cpp.Opt(i32)) -> bool { return Cpp.CppEq(m, o); }

// --- generic_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Cpp.Foo as Core.ImplicitAs(i32) {
  fn Convert(self) -> i32 { return self.n; }
}
impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T) where .Result = i32 {
  fn Op(self, k: T) -> i32 { return self.cents * (k as i32); }
}
impl Money as Core.MulWith(i64) where .Result = i32 {
  fn Op(self, _: i64) -> i32 { return self.cents; }
}

inline Cpp '''
// The generic impl is a deleted operator template (fork work item W-202); a
// `long` operand matches the `i64` impl's non-template operator exactly, which
// C++ prefers to the template.
inline int MulInCpp(Carbon::Money m, long k) { return m * k; }
''';

// Carbon selects the generic impl for an `i32` operand...
fn CarbonSide(m: Money, k: i32) -> i32 { return m * k; }

// ...and for a C++ operand: Carbon's lookup deduces the deleted template that
// `MulInCpp` exported, which is no candidate for it.
fn CarbonSideCppOperand(m: Money, f: Cpp.Foo) -> i32 { return m * f; }

fn CppSide(m: Money, k: i64) -> i32 { return Cpp.MulInCpp(m, k); }
```

### §2.6 Conformance programs (bullet "Type system: C++ interop — exporting Carbon operator overloads into C++", R7)

All seven are single-file `run` programs in fork/conformance/programs/interop/.
The arbiter keeps its filename and bullet; its SKIP line, guard and the
"Write-tests-first stub" header go, its body is the sketch (M-15). Each EXPECT
is re-derived in §1.8. Rev 2 re-encodes the compare and nonmember programs'
comparisons and adds the divergence cross-references to the arithmetic and
index headers (amended 2026-10-14, review fold: A-8, A-9). Rev 3 and rev 4
change no program; all seven pass on `v7` (M-13; amended 2026-10-14, review
fold: RR2-1).

#### interop/cpp_operator_export.carbon (SKIP → PASS)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// A Carbon class's `Core.AddWith` impl is C++'s `operator+` on the exported
// `Carbon::` type (fork decision F-017): an `inline Cpp` block applies `+`
// to two `Carbon::Meters` values, and Carbon reads the sum back through
// `Cpp.`, so the round trip is observable at runtime (mirroring
// interop/cpp_export_function.carbon). Shape verbatim from
// types/operator_overloading.carbon and
// toolchain/check/testdata/operators/overloaded/add.carbon. 30 + 12 = 42: the
// impl adds the two `value` fields, and `.value` reads the result's field.

import Core library "io";
import Cpp;

class Meters {
  var value: i32;
  fn Make(n: i32) -> Meters { return {.value = n}; }
}

impl Meters as Core.AddWith(Meters) where .Result = Meters {
  fn Op(self, other: Meters) -> Meters {
    return Meters.Make(self.value + other.value);
  }
}

inline Cpp '''
inline int AddMetersInCpp() {
  Carbon::Meters a = Carbon::Meters::Make(30);
  Carbon::Meters b = Carbon::Meters::Make(12);
  // The exported Carbon Core.AddWith impl must surface as operator+ here.
  return (a + b).value;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddMetersInCpp());
  return 0;
}
```

#### interop/cpp_operator_export_arithmetic.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   950
//   450
//   2100
//   233
//   1
//   -700
//
// The arithmetic family (fork decision F-017): `AddWith`, `SubWith`,
// `MulWith`, `DivWith` and `ModWith` impls whose `Self` is the class are
// C++ member operators `+ - * / %`, and `Negate` is the unary `-`, each a
// `const` member because each `Op` takes `self` by value. Every value is
// computed by C++ from two amounts of 700 and 250 cents: 700 + 250 = 950;
// 700 - 250 = 450; 700 * 3 = 2100; 700 / 3 = 233 (Carbon's `i32` division
// truncates); 700 % 3 = 1; -(700) = -700. `MulWith(i32)` takes C++'s `int`
// operand, the mixed-type case. C++ resolves these operators under its own
// rules, so it also converts a `long` operand to that `int`, where Carbon needs
// an `i64` impl: a documented divergence (docs/design/interoperability/
// operators.md, "Divergences"), pinned by the `arithmetic` and
// `fail_conversion_carbon_side` splits of
// toolchain/check/testdata/interop/cpp/class/export/operator.carbon.

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents + other.cents); }
}
impl Money as Core.SubWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents - other.cents); }
}
impl Money as Core.MulWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents * k); }
}
impl Money as Core.DivWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents / k); }
}
impl Money as Core.ModWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents % k); }
}
impl Money as Core.Negate where .Result = Money {
  fn Op(self) -> Money { return Money.Make(-self.cents); }
}

inline Cpp '''
using Carbon::Money;
inline int Sum() { return (Money::Make(700) + Money::Make(250)).cents; }
inline int Difference() { return (Money::Make(700) - Money::Make(250)).cents; }
inline int Product() { return (Money::Make(700) * 3).cents; }
inline int Quotient() { return (Money::Make(700) / 3).cents; }
inline int Remainder() { return (Money::Make(700) % 3).cents; }
inline int Negated() { return (-Money::Make(700)).cents; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Sum());
  Core.Print(Cpp.Difference());
  Core.Print(Cpp.Product());
  Core.Print(Cpp.Quotient());
  Core.Print(Cpp.Remainder());
  Core.Print(Cpp.Negated());
  return 0;
}
```

#### interop/cpp_operator_export_compound.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   15
//   7
//   40
//   2
//   4
//   11
//
// The compound-assignment and increment family (fork decision F-017):
// `AddAssignWith` .. `ModAssignWith`, `Inc` and `Dec` impls take `ref self`,
// so each is a C++ member operator qualified `&` that returns `void` (in
// Carbon these are statements, docs/design/expressions/README.md), and writes
// through to the C++ object it is applied to. Each C++ function starts from
// 10 cents: 10 += 5 is 15; 10 -= 3 is 7; 10 *= 4 is 40; 10 /= 4 is 2
// (truncating); 10 %= 6 is 4; ++, ++, -- from 10 is 11 (prefix only: Carbon
// has no postfix form).

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}
impl Money as Core.SubAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents -= other.cents; }
}
impl Money as Core.MulAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents *= k; }
}
impl Money as Core.DivAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents /= k; }
}
impl Money as Core.ModAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents %= k; }
}
impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}
impl Money as Core.Dec {
  fn Op(ref self) { --self.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int AddAssign() { Money a = Money::Make(10); a += Money::Make(5); return a.cents; }
inline int SubAssign() { Money a = Money::Make(10); a -= Money::Make(3); return a.cents; }
inline int MulAssign() { Money a = Money::Make(10); a *= 4; return a.cents; }
inline int DivAssign() { Money a = Money::Make(10); a /= 4; return a.cents; }
inline int ModAssign() { Money a = Money::Make(10); a %= 6; return a.cents; }
inline int IncDec() { Money a = Money::Make(10); ++a; ++a; --a; return a.cents; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddAssign());
  Core.Print(Cpp.SubAssign());
  Core.Print(Cpp.MulAssign());
  Core.Print(Cpp.DivAssign());
  Core.Print(Cpp.ModAssign());
  Core.Print(Cpp.IncDec());
  return 0;
}
```

#### interop/cpp_operator_export_compare.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   101
//   100
//   110
//   1
//   11
//   0
//
// The comparison family (fork decision F-017): `EqWith.Equal` is C++'s `==`,
// `OrderedWith`'s four members are `<`, `<=`, `>` and `>=`. With a = 1 and
// b = 2, each C++ function returns 100 * (a op b) + 10 * (a op a) + (b op a),
// which differs for every operator, so a swapped or mis-mapped operator prints
// another operator's value: `==` gives 0, 1, 0, so 10; `!=` 1, 0, 1, so 101;
// `<` 1, 0, 0, so 100; `<=` 1, 1, 0, so 110; `>` 0, 0, 1, so 1; and `>=`
// 0, 1, 1, so 11.
// `Money` leaves `NotEqual` to the interface's default, `not self.Equal(o)`
// (docs/design/expressions/comparison_operators.md), exported as `!(a == b)`.
// `Unknowable` defines its own `NotEqual`, under which an unknown value (0)
// is neither equal nor unequal to anything: (z == one) * 10 + (z != one) is 0
// because C++ calls that `NotEqual`; rewriting `!=` as `!(==)` would print 1.

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl Money as Core.OrderedWith(Money) {
  fn Less(self, other: Money) -> bool { return self.cents < other.cents; }
  fn LessOrEquivalent(self, other: Money) -> bool { return self.cents <= other.cents; }
  fn Greater(self, other: Money) -> bool { return self.cents > other.cents; }
  fn GreaterOrEquivalent(self, other: Money) -> bool { return self.cents >= other.cents; }
}

class Unknowable {
  var v: i32;
  fn Make(v: i32) -> Unknowable { return {.v = v}; }
}

impl Unknowable as Core.EqWith(Unknowable) {
  fn Equal(self, o: Unknowable) -> bool {
    return self.v != 0 and o.v != 0 and self.v == o.v;
  }
  fn NotEqual(self, o: Unknowable) -> bool {
    return self.v != 0 and o.v != 0 and self.v != o.v;
  }
}

inline Cpp '''
using Carbon::Money;
inline Money A() { return Money::Make(1); }
inline Money B() { return Money::Make(2); }
inline int Code(bool ab, bool aa, bool ba) { return ab * 100 + aa * 10 + ba; }
inline int Eq() { return Code(A() == B(), A() == A(), B() == A()); }
inline int Ne() { return Code(A() != B(), A() != A(), B() != A()); }
inline int Lt() { return Code(A() < B(), A() < A(), B() < A()); }
inline int Le() { return Code(A() <= B(), A() <= A(), B() <= A()); }
inline int Gt() { return Code(A() > B(), A() > A(), B() > A()); }
inline int Ge() { return Code(A() >= B(), A() >= A(), B() >= A()); }
inline int Unknown() {
  Carbon::Unknowable z = Carbon::Unknowable::Make(0);
  Carbon::Unknowable one = Carbon::Unknowable::Make(1);
  return (z == one) * 10 + (z != one);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.Eq());
  Core.Print(Cpp.Ne());
  Core.Print(Cpp.Lt());
  Core.Print(Cpp.Le());
  Core.Print(Cpp.Gt());
  Core.Print(Cpp.Ge());
  Core.Print(Cpp.Unknown());
  return 0;
}
```

#### interop/cpp_operator_export_bitwise.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
//   14
//   6
//   243
//   48
//   16
//   4
//
// The bitwise and shift family (fork decision F-017): `BitAndWith`,
// `BitOrWith`, `BitXorWith`, `LeftShiftWith` and `RightShiftWith` are C++'s
// `& | ^ << >>`; Carbon's unary `^x`, `BitComplement`, is C++'s `~x` (the
// operation with the most similar semantics, docs/design/README.md, "Operator
// overloading" under C++ interop); the compound forms are `&= |= ^= <<= >>=`.
// `Bits` holds a `u8` (C++ `unsigned char`). With x = 12 (0b1100) and
// y = 10 (0b1010): x & y = 8; x | y = 14; x ^ y = 6; ~x = 255 - 12 = 243;
// x << 2 = 48; 128 >> 3 = 16; and z = 3, then z <<= 2 (12), z |= 1 (13),
// z &= 14 (12), z ^= 5 (9), z >>= 1 (4).

import Core library "io";
import Cpp;

class Bits {
  var v: u8;
  fn Make(v: u8) -> Bits { return {.v = v}; }
}

impl Bits as Core.BitAndWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v & o.v); }
}
impl Bits as Core.BitOrWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v | o.v); }
}
impl Bits as Core.BitXorWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v ^ o.v); }
}
impl Bits as Core.BitComplement where .Result = Bits {
  fn Op(self) -> Bits { return Bits.Make(^self.v); }
}
impl Bits as Core.LeftShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return Bits.Make(self.v << (n as u8)); }
}
impl Bits as Core.RightShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return Bits.Make(self.v >> (n as u8)); }
}
impl Bits as Core.BitAndAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v &= o.v; }
}
impl Bits as Core.BitOrAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v |= o.v; }
}
impl Bits as Core.BitXorAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v ^= o.v; }
}
impl Bits as Core.LeftShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v <<= (n as u8); }
}
impl Bits as Core.RightShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v >>= (n as u8); }
}

inline Cpp '''
using Carbon::Bits;
inline Bits X() { return Bits::Make(12); }
inline Bits Y() { return Bits::Make(10); }
inline int And() { return (X() & Y()).v; }
inline int Or() { return (X() | Y()).v; }
inline int Xor() { return (X() ^ Y()).v; }
inline int Complement() { return (~X()).v; }
inline int ShiftLeft() { return (X() << 2).v; }
inline int ShiftRight() { return (Bits::Make(128) >> 3).v; }
inline int Compound() {
  Bits z = Bits::Make(3);
  z <<= 2;
  z |= Bits::Make(1);
  z &= Bits::Make(14);
  z ^= Bits::Make(5);
  z >>= 1;
  return z.v;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.And());
  Core.Print(Cpp.Or());
  Core.Print(Cpp.Xor());
  Core.Print(Cpp.Complement());
  Core.Print(Cpp.ShiftLeft());
  Core.Print(Cpp.ShiftRight());
  Core.Print(Cpp.Compound());
  return 0;
}
```

#### interop/cpp_operator_export_index.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   789
//   97
//
// The indexing family (fork decision F-017): `IndexWith(I).At` is C++'s
// `operator[]`, a `const` member returning the element by value (`At` takes
// `self` and returns a value; the `ref` forms are W-109's). Two impls of one
// interface, `IndexWith(i32)` and `IndexWith(bool)`, are one C++ overload
// set: `t[true]` selects the `bool` member by exact match (`bool` to `int`
// would be a promotion), as Carbon's `t[true]` selects `IndexWith(bool)`; where
// the two sides' rules differ (operand conversions, base classes), the
// divergence is documented (docs/design/interoperability/operators.md,
// "Divergences") and pinned by the `arithmetic`, `fail_conversion_carbon_side`,
// `base_class` and `fail_base_class_carbon_side` splits of
// toolchain/check/testdata/interop/cpp/class/export/operator.carbon. With
// fields 7, 8, 9: t[0] * 100 + t[1] * 10 + t[2] = 789; t[true] is the last
// field (9) and t[false] the first (7), so t[true] * 10 + t[false] = 97.

import Core library "io";
import Cpp;

class Triple {
  var a: i32;
  var b: i32;
  var c: i32;
  fn Make(a: i32, b: i32, c: i32) -> Triple { return {.a = a, .b = b, .c = c}; }
}

impl Triple as Core.IndexWith(i32) where .ElementType = i32 {
  fn At(self, i: i32) -> i32 {
    if (i == 0) {
      return self.a;
    }
    if (i == 1) {
      return self.b;
    }
    return self.c;
  }
}
impl Triple as Core.IndexWith(bool) where .ElementType = i32 {
  fn At(self, last: bool) -> i32 {
    if (last) {
      return self.c;
    }
    return self.a;
  }
}

inline Cpp '''
inline int Digits() {
  const Carbon::Triple t = Carbon::Triple::Make(7, 8, 9);
  return t[0] * 100 + t[1] * 10 + t[2];
}
inline int Ends() {
  const Carbon::Triple t = Carbon::Triple::Make(7, 8, 9);
  return t[true] * 10 + t[false];
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.Digits());
  Core.Print(Cpp.Ends());
  return 0;
}
```

#### interop/cpp_operator_export_nonmember.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   10
//   101
//   100
//   110
//   1
//   11
//   7
//   33
//
// Operator impls whose `Self` is not an exported Carbon class (fork decision
// F-017): `impl i32 as SubWith(Money)` is the non-member C++ operator
// `int operator-(int, Carbon::Money)` in `namespace Carbon`, found by
// argument-dependent lookup on the `Money` operand, and so are `EqWith`,
// `OrderedWith` and `SubAssignWith` from `i32`, and `AddWith(Money)` from
// the C++ type `Foo`. The left operand is `Self`, as in Carbon: 50 - m(8)
// = 42 (the other order would be -42). Each comparison returns
// 100 * (4 op m(5)) + 10 * (5 op m(5)) + (6 op m(5)), which differs for every
// operator: `==` 0, 1, 0, so 10; `!=`, from `Equal` alone through `NotEqual`'s
// default, 1, 0, 1, so 101; `<` 1, 0, 0, so 100; `<=` 1, 1, 0, so 110; `>`
// 0, 0, 1, so 1; `>=` 0, 1, 1, so 11. Then k = 10, k -= m(3) leaves 7 in the
// C++ `int`; and Foo{30} + m(3) = 33.

import Core library "io";
import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}
impl i32 as Core.OrderedWith(Money) {
  fn Less(self, m: Money) -> bool { return self < m.cents; }
  fn LessOrEquivalent(self, m: Money) -> bool { return self <= m.cents; }
  fn Greater(self, m: Money) -> bool { return self > m.cents; }
  fn GreaterOrEquivalent(self, m: Money) -> bool { return self >= m.cents; }
}
impl i32 as Core.SubAssignWith(Money) {
  fn Op(ref self, m: Money) { self -= m.cents; }
}
impl Cpp.Foo as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self.n + m.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Difference() { return 50 - Money::Make(8); }
inline Money M() { return Money::Make(5); }
inline int Code(bool lo, bool eq, bool hi) { return lo * 100 + eq * 10 + hi; }
inline int Eq() { return Code(4 == M(), 5 == M(), 6 == M()); }
inline int Ne() { return Code(4 != M(), 5 != M(), 6 != M()); }
inline int Lt() { return Code(4 < M(), 5 < M(), 6 < M()); }
inline int Le() { return Code(4 <= M(), 5 <= M(), 6 <= M()); }
inline int Gt() { return Code(4 > M(), 5 > M(), 6 > M()); }
inline int Ge() { return Code(4 >= M(), 5 >= M(), 6 >= M()); }
inline int Assign() { int k = 10; k -= Money::Make(3); return k; }
inline int Foreign() { return Foo{30} + Money::Make(3); }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Difference());
  Core.Print(Cpp.Eq());
  Core.Print(Cpp.Ne());
  Core.Print(Cpp.Lt());
  Core.Print(Cpp.Le());
  Core.Print(Cpp.Gt());
  Core.Print(Cpp.Ge());
  Core.Print(Cpp.Assign());
  Core.Print(Cpp.Foreign());
  return 0;
}
```

### §2.7 Docs (D-OX-13; a new page and a dated amendment, never a rewrite)

#### docs/design/interoperability/operators.md (new)

The page's example is the arbiter's program, so it is compile-verified by the
conformance run (R6); its prose claims are each a measurement of §0.2 or a
split of §2.5. The page carries the two table-of-contents marker lines that
`printf '<!-- %s -->\n' toc tocstop` prints: the first on its own line after the
license comment, the second on its own line after the table of contents, as in
docs/design/interoperability/README.md:9 and its matching stop line. They are
not written out literally in this plan, because prek's `markdown-toc` hook
replaces the text between the first such pair in any markdown file, fenced or
not (pre_commit_hooks/markdown_toc.py:45-72 in the prek cache), so a literal
pair here would overwrite this copy with the plan's own table of contents; on
the page the hook fills the list from the headings (amended 2026-10-14, review
fold: B-12). Rev 2 rewrites the mapping table's result column, the sections on
Carbon's own expressions and divergences, adds "Conversions" and a migration
note, and extends the 0.1 limits (amended 2026-10-14, review fold: A-1, A-3,
A-6, A-7, B-2, B-3, B-4, B-11). Rev 3 rewrites "Implementations with no C++
form", "Carbon operator expressions are unchanged" and two of the 0.1 limits,
for the deleted default `!=`, the generic impls' deleted template, detections
and C++ code's earlier lookups, and adds an alternative (amended 2026-10-14,
review fold: RR-1 to RR-6). Rev 4 rewrites the last paragraph of
"Implementations with no C++ form" for classes C++ cannot export, replaces
"Carbon operator expressions are unchanged", whose title no longer holds, with
"Carbon operator expressions", drops W-205's limit and adds an alternative
(amended 2026-10-14, review fold: RR2-1, RR2-2). Rev 5 rewrites "Carbon
operator expressions" for C++'s exact choice of an exported operator and the
one boundary, names the header-dependent types in "Implementations with no
C++ form", corrects the last sentence of "Hand-written C++ operators", and
adds an alternative (amended 2026-10-14, review fold: RR3-B1, RR3-B2,
RR3-M1).

````markdown
# Exporting Carbon operators to C++

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

## Table of contents

-   [Overview](#overview)
-   [The mapping](#the-mapping)
-   [Member and non-member operators](#member-and-non-member-operators)
-   [Equality and inequality](#equality-and-inequality)
-   [Assignment, increment, and indexing](#assignment-increment-and-indexing)
-   [Implementations with no C++ form](#implementations-with-no-c-form)
-   [Carbon operator expressions](#carbon-operator-expressions)
-   [Divergences](#divergences)
-   [Conversions](#conversions)
-   [Hand-written C++ operators](#hand-written-c-operators)
-   [0.1 limits](#01-limits)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

## Overview

> **Fork design (F-017, 2026-10-14).** No accepted proposal specifies how Carbon
> operators are used from C++. This page is the fork's design decision F-017
> (fork/decision-log.md, "OX-1"), recorded for after-the-fact veto.

The [design overview](../README.md#operator-overloading-1) says that Carbon types
implementing an operator overload using an interface "should get the
corresponding operator overload in C++", so that "implementing `ModWith(U)` in
Carbon for a type effectively implements `operator%` in C++ for that type", and
that operations are matched "according to which operation has the most similar
semantics rather than using the same symbols". This page decides how, for the
operators; conversions are not yet exported (see [Conversions](#conversions)).

An `impl` of one of the `Core` operator interfaces below, for a Carbon class, is
a C++ operator on the exported Carbon type. C++ code in an `inline Cpp` block
that applies the operator calls the impl's function, through the same kind of
thunk as an exported method:

```carbon
import Core library "io";
import Cpp;

class Meters {
  var value: i32;
  fn Make(n: i32) -> Meters { return {.value = n}; }
}

impl Meters as Core.AddWith(Meters) where .Result = Meters {
  fn Op(self, other: Meters) -> Meters {
    return Meters.Make(self.value + other.value);
  }
}

inline Cpp '''
inline int AddMetersInCpp() {
  Carbon::Meters a = Carbon::Meters::Make(30);
  Carbon::Meters b = Carbon::Meters::Make(12);
  return (a + b).value;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddMetersInCpp());
  return 0;
}
```

This prints `42`.

## The mapping

| `Core` interface member                     | C++ operator                            | Form                       |
| ------------------------------------------- | --------------------------------------- | -------------------------- |
| `AddWith(U).Op`                             | `a + b`                                 | `const`                    |
| `SubWith(U).Op`                             | `a - b`                                 | `const`                    |
| `MulWith(U).Op`                             | `a * b`                                 | `const`                    |
| `DivWith(U).Op`                             | `a / b`                                 | `const`                    |
| `ModWith(U).Op`                             | `a % b`                                 | `const`                    |
| `Negate.Op`                                 | `-a`                                    | `const`                    |
| `BitAndWith(U).Op`                          | `a & b`                                 | `const`                    |
| `BitOrWith(U).Op`                           | <code>a \| b</code>                     | `const`                    |
| `BitXorWith(U).Op`                          | `a ^ b`                                 | `const`                    |
| `BitComplement.Op`                          | `~a`                                    | `const`                    |
| `LeftShiftWith(U).Op`                       | `a << b`                                | `const`                    |
| `RightShiftWith(U).Op`                      | `a >> b`                                | `const`                    |
| `AddAssignWith(U).Op` .. `ModAssignWith(U)` | `+=` `-=` `*=` `/=` `%=`                | `&`-qualified, `void`      |
| `BitAndAssignWith(U).Op` .. shifts          | `&=` <code>\|=</code> `^=` `<<=` `>>=` | `&`-qualified, `void`      |
| `Inc.Op`, `Dec.Op`                          | `++a`, `--a`                            | `&`-qualified, `void`      |
| `EqWith(U).Equal`                           | `a == b`                                | `const`                    |
| `EqWith(U).NotEqual`                        | `a != b`                                | `const`                    |
| `OrderedWith(U).Less`                       | `a < b`                                 | `const`                    |
| `OrderedWith(U).LessOrEquivalent`           | `a <= b`                                | `const`                    |
| `OrderedWith(U).Greater`                    | `a > b`                                 | `const`                    |
| `OrderedWith(U).GreaterOrEquivalent`        | `a >= b`                                | `const`                    |
| `IndexWith(I).At`                           | `a[i]`                                  | `const`                    |

The table is the inverse of the C++ operator import, which maps the same C++
operators onto the same interfaces. An exported operator is the impl's function
as declared, mapped as for an exported method: a value parameter is a C++
by-value parameter, `self` makes a `const` member operator, `ref self` an
lvalue-ref-qualified (`&`) one, and the result, the function's declared return
type, is returned by value. A function's parameter and return types may differ
from the interface's argument and `Result` where Carbon converts between them;
C++ sees the function's own types (see [Divergences](#divergences)).

Carbon's prefix `^` is C++'s `~`: they are the operations with the most similar
semantics. Some C++ operators have no Carbon interface to come from, so a Carbon
type never has them: unary `+`, postfix `++` and `--`, `!`, `&&`, `||`, the
comma operator, `->`, unary `*` and `&`, `()`, and `<=>`.

## Member and non-member operators

Carbon finds an operator by looking up the impl for the type of its left
operand, `Self`. When `Self` is the exported Carbon class, the impl is a
member operator of that class, so C++ finds it by member lookup on the left
operand, as Carbon does. When `Self` is any other type — a Carbon primitive such
as `i32`, or an imported C++ type — and the operand is an exported Carbon class,
the impl is a non-member operator declared in the innermost C++ namespace that
encloses that class, which C++ finds by argument-dependent lookup on the
operand, a nested class's included:

```carbon
impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
```

is `int Carbon::operator-(int, Carbon::Money)`, and C++'s `50-m` calls it.
C++ requires `operator[]` to be a member, so only an `IndexWith` impl whose
`Self` is the class is exported.

## Equality and inequality

`a==b` calls `EqWith(U).Equal` and `a!=b` calls `EqWith(U).NotEqual`. An impl
that does not define `NotEqual` uses the interface's default,
`not self.Equal(other)` ([comparison operators](../expressions/comparison_operators.md#equality)),
and `operator!=` is then exported as `!(a==b)`, passing its operands on as a
C++ implicit move would, so `!=` is available in every C++ language mode, for a
class that can only be moved too. Because `operator!=` is declared beside
`operator==`, C++20 does not synthesize reversed `==` candidates: C++ accepts
`5==m` only if Carbon has an `impl i32 as EqWith(Money)`, as Carbon does. No
`<=>` is exported, so C++ never rewrites the relational operators either.

## Assignment, increment, and indexing

The compound assignment operators and `++`/`--` are statements in Carbon and
take `ref self`, so the exported operators are `&`-qualified, return `void`, and
modify the object C++ applies them to; `a+=b` on a temporary does not compile.
`a = b` is not an operator interface in Carbon and stays C++'s copy assignment.
`IndexWith(I).At` takes `self` and returns a value, so `a[i]` is a `const`
member returning the element by value and cannot be assigned to.

## Implementations with no C++ form

An impl whose operand type has no C++ form, such as a tuple, is not exported:
C++ code cannot form such an operand, so leaving it out cannot change which
impl a C++ expression selects. A type whose C++ form is declared by a header
has no C++ form where that header is not included: `str` is `std::string_view`
only with `<string_view>`, `Core.Slice(T)` is `std::span` only where `<span>`
declares it, and `Core.Result(T, E)` is `Carbon::expected` only with
`<carbon/expected.h>`. An impl whose result alone has no C++ form is
exported as a deleted operator, so that a C++ expression that would select it
is rejected, rather than converted to the operand type of another impl:

```carbon
impl Money as Core.AddWith(i32) where .Result = (i32, i32) { ... }
impl Money as Core.AddWith(i64) where .Result = i32 { ... }
```

Here C++'s `m + k` with an `int k` is an error ("overload resolution selected
deleted operator"), while `m + k` with a `long k` calls the `i64` impl, as
Carbon does for an `i64` operand. When `operator==` is deleted this way and the
impl leaves `NotEqual` to its default, `operator!=` is deleted too.

A generic impl has no C++ form either. The generic impls of an operator are
declared together as one deleted operator template, `template <typename T> void
operator*(T) const = delete;` for `impl forall [T: Core.ImplicitAs(i32)] Money
as Core.MulWith(T)`, so that C++ rejects an operand that Carbon would resolve to
the generic impl rather than convert it to a concrete impl's parameter type; an
operand that exactly matches a concrete impl still selects it, because C++
prefers a function that is not a template.

A class that C++ cannot export at all, such as one with a tuple field, or with
a `Core.Slice` field where `std::span` is not declared, is never
named by an exported operator: an impl whose operand is such a class is
represented by the same deleted operator template as a generic impl, and one
whose result is such a class is exported as a deleted operator. So no use of an
operator, and no type trait that asks whether one applies, ever needs that
class, and exporting operators never reports an error of its own; an operand
that exactly matches another impl still selects it.

## Carbon operator expressions

When an operand of a Carbon operator expression is a C++ type, Carbon also asks
C++ for a matching operator, which it resolves with C++ overload resolution
(see the
[C++ interop proposal's operator calls](/proposals/p006254-c-interop-toolchain-implementation-for-function-calls.md#operator-calls)).
When C++ would select an exported operator, and every operand matches it
exactly, Carbon calls the impl that the operator stands for, as C++ does:
Carbon's impl lookup selects that impl itself. Otherwise an exported operator
is never one of Carbon's candidates, because it is Carbon's own impl seen from
C++, so the Carbon impl is called directly wherever Carbon's impl lookup finds
it, and a hand-written C++ operator that is exactly as good a match as an
exported operator, which C++ reports as ambiguous, is the one Carbon calls. A
hand-written C++ operator that C++ ranks below an exactly matching exported
operator, such as an unconstrained template, is not called: the impl is, in
Carbon as in C++.

A C++ template sees a Carbon class's exported operators whatever instantiates
it: C++ code, or a Carbon call, conversion or operator expression that asks C++
for a function. A C++ function that is viable only because a Carbon class has
an exported operator, such as a template constrained on that operator, is
therefore a candidate for Carbon too, and it can call the exported operator.
Carbon selects it where C++ code would, and also where C++ would instead
convert an operand to call an exported operator, a conversion that Carbon's
own impl lookup does not make. A template that C++ instantiated before an
`impl` was declared keeps what it saw then, as in C++.

## Divergences

Each side resolves an operator expression under its own rules, as for an
exported [overload set](README.md#overload-resolution):

-   C++ applies its implicit conversions to the operands of an exported
    operator, so `m*3L` calls an `impl Money as MulWith(i32)` by converting the
    `long` to `int`, where Carbon would need an impl for `i64`.
-   C++ member lookup searches base classes, so `d+d` on a class derived
    from a Carbon base class calls the base's `AddWith(Base)` impl after
    converting both operands to the base, where Carbon finds no impl for the
    derived class.
-   C++ sees the impl function's own signature: for
    `impl Money as AddWith(i32) where .Result = i64` whose `Op` returns `i32`,
    Carbon's `m + k` is an `i64` and C++'s `m + 1` an `int`; and a function
    whose parameter is `i64` takes a C++ `long` that Carbon's `AddWith(i32)`
    lookup would not.
-   C++ passes a value operand by value, so it copies an lvalue operand: a class
    that C++ cannot copy, such as one with a move-only C++ field, can be an
    operand in Carbon but only an rvalue operand in C++.

The divergence is bounded to which impl runs, the static type C++ gives the
result, or whether the expression compiles; every exported operator calls
exactly one Carbon impl function.

## Conversions

The design overview also says that "the `ImplicitAs(U)` Carbon interface
corresponds to implicit conversions in C++", and the
[`as` expressions proposal](/proposals/p000845-as-expressions.md) that `As` provides the
functionality of C++'s `explicit` constructors and conversion functions for
interoperability. Neither is exported yet (fork work item W-208): C++ spells a
conversion as a conversion function or a converting constructor, not an
overloaded operator, and Clang collects a class's conversion functions from its
definition rather than by name, so exporting them is a design of its own.

## Hand-written C++ operators

C++ code may have declared its own operator for an exported Carbon class before
Carbon operator impls were exported. Where it duplicates an impl, C++ now finds
two equally good candidates and reports the use as ambiguous (fork work item
W-211); remove the hand-written operator. Carbon's own operator expressions are
not ambiguous: they call the hand-written operator where C++ finds the two
equally good (see
[Carbon operator expressions](#carbon-operator-expressions)).

## 0.1 limits

-   A generic impl, such as `impl forall [T: Core.ImplicitAs(i32)] Money as
    Core.MulWith(T)`, cannot be called from C++, and the impls of a specific of
    a generic class are not exported (fork work item W-202); a C++ use that
    Carbon would resolve to a generic impl is rejected (see [Implementations
    with no C++ form](#implementations-with-no-c-form)).
-   Only the impls of the file that contains the `inline Cpp` block are
    exported; the impls of an imported library are not (W-204), and a class
    imported from another library is not yet exported correctly (W-203).
-   `<=>` is not exported until `OrderedWith` declares its three-way `Compare`
    (W-206).
-   Two impls whose operand types map to one C++ type make every use of that
    operator ambiguous in C++ (W-207).
-   `As` and `ImplicitAs` are not exported as C++ conversions (W-208).
-   `a[i]` returns a value until the reference forms of indexing exist
    (W-209, W-109).
-   An impl with no Carbon class among its types, such as
    `impl Cpp.Foo as AddWith(i32)`, is not exported, because C++'s
    argument-dependent lookup does not look in namespace `Carbon` for it
    (W-210).

## Alternatives considered

-   Exporting only `operator+`, the arbiter's case: rejected, because the
    bullet is the whole operator mapping, not one operator.
-   Exporting every impl as a non-member operator: rejected, because C++ would
    then convert the left operand implicitly, which Carbon's dispatch on `Self`
    never does.
-   Hidden friend functions for impls whose `Self` is the class: rejected,
    because argument-dependent lookup finds a friend through either operand,
    so C++ would convert the left operand implicitly, as with a non-member
    operator.
-   Leaving `!=` to C++20's rewrite of `==`: rejected, because the default
    language mode of an `inline Cpp` block is C++17, and because the rewrite
    adds reversed `==` candidates that Carbon does not have.
-   Leaving out an impl whose result has no C++ form: rejected, because C++
    could then select another impl by converting the operand.
-   Leaving a generic impl out of C++ entirely: rejected for the same reason;
    its deleted operator template keeps C++ from converting the operand for a
    concrete impl.
-   Hiding the exported operators from the C++ templates that Carbon's own
    operator lookup instantiates: rejected, because Clang instantiates
    templates for Carbon and for C++ code in the same places, so the same
    template would answer differently for each, and a type trait would keep
    whichever answer came first.
-   For a Carbon operator expression whose operand C++ would convert to call an
    exported operator, calling that operator: rejected, because Carbon's impl
    lookup converts no operand, and calling the export would apply C++'s
    conversions to a Carbon impl and change which function an existing Carbon
    program calls; leaving the expression to Carbon's impl lookup instead
    would reject programs that call a hand-written C++ operator today.
-   Making each exported operator evaluate the Carbon operator expression
    rather than call the impl's function: rejected for 0.1, because only
    concrete impls are exported, for which impl lookup selects exactly that
    impl, so both call the same function, and the expression form needs a new
    kind of thunk.

## References

-   [Bidirectional interoperability with C and C++](README.md)
-   [Design overview: operator overloading in C++ interoperability](../README.md#operator-overloading-1)
-   [Operator expressions](../expressions/README.md#operators)
-   Proposal
    [#702: Comparison operators](/proposals/p000702-comparison-operators.md)
-   Proposal [#845: `as` expressions](/proposals/p000845-as-expressions.md)
-   Proposal
    [#1178: Rework operator interfaces](/proposals/p001178-rework-operator-interfaces.md)
-   Proposal
    [#1191: Bitwise and shift operators](/proposals/p001191-bitwise-and-shift-operators.md)
-   Proposal
    [#6254: C++ interop toolchain implementation for function calls](/proposals/p006254-c-interop-toolchain-implementation-for-function-calls.md)
````

#### docs/design/interoperability/README.md (amendment)

Inserted after the heading at :350, "## TODO: The operator interoperability
model", which stays as it is (DD-1 replaces the section; §6.2.1 gives the
merge-time edit):

```markdown
> **Fork amendment (2026-10-14, F-017).** The export direction is specified in
> [Exporting Carbon operators to C++](operators.md): an implementation of a
> `Core` operator interface for a Carbon class is a C++ operator on the exported
> Carbon type — a member operator when the implementing type is that class, and
> otherwise a non-member operator in the class's namespace that C++ finds by
> argument-dependent lookup. C++ resolves these operators under its own rules,
> a documented divergence like that of exported overload sets; conversions are
> not yet exported.
```

### §2.8 Records (commit 5 moves the row; commit 6 writes the rest, after the merge of trunk and §8.8)

**The row** (commit 5, fork/gap-analysis.md:48 at f67ab650d; re-read its line at
the merge of trunk, R7). Status MISSING → PARTIAL (D-OX-14); the evidence cell
becomes (the status, W-208's clause and the residue list amended 2026-10-14,
review fold: A-6, B-4, B-3, A-3; the decision-log entry and the README
amendment are no longer cited from commit 5, which precedes them, B-5; the
deleted operators, Carbon's lookup and W-202's and W-205's clauses amended
2026-10-14, review fold: RR-1, RR-2, RR-3, RR-4, RR-5; the diagnostics,
Carbon's lookup, the deleted templates and W-205 amended 2026-10-14, review
fold: RR2-1, RR2-2; Carbon's lookup amended 2026-10-14, review fold:
RR3-B2):

```text
OX-1 landed (W-054 DISCHARGED <date>, fork/opexport/plan.md, fork design F-017, docs/design/interoperability/operators.md): an impl of a `Core` operator interface for a Carbon class is a C++ operator on the exported Carbon type — the arithmetic, negation, bitwise and shift, compound-assignment, increment and decrement, comparison and indexing interfaces, 31 members — a member operator (`const` for `self`, `&` for `ref self`) when the impl's `Self` is the class, and otherwise a non-member operator in the class's innermost enclosing namespace found by argument-dependent lookup (`int - Carbon::Money` from `impl i32 as SubWith(Money)`, `Foo + Carbon::Money` from an imported C++ `Self`); `!=` is exported for an impl that keeps `EqWith`'s default `NotEqual`, as `!(a == b)`, so C++17 has it and C++20 synthesizes no reversed `==`; an impl whose operand has no C++ form is omitted, one whose result has none or names a class C++ cannot export is declared deleted, as is the default `!=` beside it, and the generic impls of an operator, with those whose operand C++ cannot export, are one deleted operator template, so C++ rejects an operand Carbon would resolve to one of them; no export emits a diagnostic, every operator lookup asks again, and Carbon's own operator expressions never call an exported operator, calling the impl where C++ selects its operator exactly, while C++ templates see the exports whoever instantiates them (cpp/class/export/operator.carbon, operator_ast.carbon, operator_cxx20.carbon, lower cpp/class/export/operator.carbon). 7/7 programs PASS — interop/cpp_operator_export (SKIP -> PASS, EXPECT 42) and cpp_operator_export_{arithmetic,compound,compare,bitwise,index,nonmember} — expected, not of record: container run on the built toolchain, GitHub Actions disabled. C++ resolves the exported operators under C++'s rules (operand conversions, base-class lookup, the impl function's own signature, by-value operands), a documented divergence. PARTIAL: the design overview maps `ImplicitAs` to C++ implicit conversions in the same section (docs/design/README.md:3679-3681), and `As`/`ImplicitAs` are not exported (W-208). Filed limits: generic impls, not callable from C++, and generic-class specifics (W-202), impls of an imported library (W-204, blocked by W-203), `<=>` (W-206), same-signature impls (W-207), `ref` indexing (W-209), impls with no Carbon class among their types (W-210), hand-written C++ operators that duplicate an impl (W-211).
```

**The header** (commit 5): "N DONE / M PARTIAL / K MISSING / L DESIGN-ONLY" as
it stands at the commit becomes M+1 PARTIAL and K−1 MISSING (at f67ab650d: 30 /
21 / 4 / 1 → 30 / 22 / 3 / 1), and the reconciliation sentence after it names
the expected conformance totals of §5 relative to the trunk floor at the
commit, "expected, not of record". Recompute with `grep -cE '^\| [^|]+ \| DONE
\|' fork/gap-analysis.md` and the same for PARTIAL, MISSING and DESIGN-ONLY,
before and after; commit 6 recounts it on the merge commit (amended 2026-10-14,
review fold: A-6, B-4, B-5).

**The ledger** (commit 6, fork/inventory/work-items.json). W-054 becomes (its
title, evidence and notes amended 2026-10-14, review fold: RR-1, RR-2, RR-3, and
again, review fold: RR2-1, RR2-2, RR2-3; its title, evidence and notes again,
review fold: RR3-B1, RR3-B2):

```json
{
 "id": "W-054",
 "title": "OX-1 (LANDED <date>): Carbon operator impls exported as C++ operator overloads (fork design F-017) — member operators for impls on the exported class, non-member operators found by argument-dependent lookup otherwise, the default `!=`, deleted operators for results with no C++ form or that name a class C++ cannot export, and deleted operator templates for generic impls and impls whose operand C++ cannot export; no export emits a diagnostic, every operator lookup asks again, and Carbon's own operator expressions never call an export, calling the impl where C++ selects its operator exactly",
 "kind": "implemented",
 "subsystem": "toolchain/check/cpp (export, generate_ast, operators) + docs/design/interoperability",
 "size": "L",
 "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++",
 "evidence": [
  "toolchain/check/cpp/export.cpp (`OperatorExportTable`, `IsOperatorImplOfKind`, `MapsByExportingClass`, `IsUnmappableWithoutExport`, `CanExportTypeWithoutDiagnostic`, `CanExportClassWithoutDiagnostic`, `ClassifyOperatorExport`, `GetImplMemberFunctionId`, `RegisterExportedOperator`, `GetExportedOperatorInstId`, `BuildCppOperatorDecl`, `ExportImplFunctionAsCppOperator`, `BuildDefaultNotEqualOperator`, `BuildDeletedOperatorTemplate`, `ExportDeletedOperatorTemplate`, `ExportImplOperators`, `ExportOperatorsToCpp`, `ExportNonMemberOperatorsToCpp`, `IsExportedCarbonOperator`; the one in-function hunk, `BuildCppToCarbonThunkBody`'s `isa<clang::CXXMethodDecl>` condition)",
  "toolchain/check/cpp/generate_ast.cpp (`FindExternalVisibleDeclsByName`: the `CXXOperatorName` arm, which answers every lookup alike and marks the entry so that Clang asks again)",
  "toolchain/check/cpp/operators.cpp (`FindClangOperator`: resolves first as C++ code does and leaves an exported operator that C++ selects with every operand an exact match, `IsExactMatchOfExportedCarbonOperator`, to Carbon's impl lookup; otherwise `RemoveExportedCarbonOperators` makes exported Carbon operators non-viable and the candidates are resolved again, and its notes leave them out)",
  "toolchain/check/testdata/interop/cpp/class/export/operator.carbon (55 splits), operator_ast.carbon and operator_cxx20.carbon (6 splits); toolchain/lower/testdata/interop/cpp/class/export/operator.carbon (13 splits); filled at <fill commit>",
  "fork/conformance/programs/interop/cpp_operator_export.carbon (SKIP -> PASS) and cpp_operator_export_{arithmetic,compound,compare,bitwise,index,nonmember}.carbon",
  "docs/design/interoperability/operators.md (F-017); <the README text at the merge commit: DD-1's operator section as §6.2.1 edits it, or this plan's dated amendment if DD-1 has not merged>; fork/opexport/plan.md; fork/decision-log.md \"OX-1 / F-017\"",
  "fork/gap-analysis.md, the row \"Type system: C++ interop — exporting Carbon operator overloads into C++\" (line 48 at f67ab650d; the original evidence's :30 was stale), PARTIAL, bounded by W-208"
 ],
 "blocked_by": [],
 "notes": "Discharged by OX-1 (fork/opexport/plan.md). W-007's precondition was met by sequencing, as for EH-B, UN-2 and OV-3: no other export.cpp contender was in flight except ST-1's disjoint 5-line hunk (PR 55), and every OX-1 edit is a new function, a new switch arm in generate_ast.cpp, a first resolution with an exact-match test, a candidate-removal helper and a notes filter in operators.cpp, or the one behaviour-preserving condition in BuildCppToCarbonThunkBody; thunk.cpp and type_mapping.cpp untouched. The row stays PARTIAL for conversions (W-208). Residues W-202, W-204 and W-206..W-211 under this row; W-203 under the type-export row; W-205 reserved and unused."
}
```

New items (commit 6; `kind`, `subsystem` and `size` as below, `evidence` as
cited; W-202, W-205 and W-208 amended and W-210 and W-211 added 2026-10-14,
review fold: B-2, A-4, A-6, B-4, B-3, A-3; W-202 and W-205 amended again
2026-10-14, review fold: RR-3, RR-4, with the fixer's M-36; W-205 withdrawn and
W-202's evidence amended 2026-10-14, review fold: RR2-1):

```json
[
 {"id": "W-202", "title": "OX-1 residue: generic operator impls are not callable from C++ (an operator's generic impls are one deleted operator template), and the operator impls of a generic class's specifics are not exported", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["toolchain/check/cpp/export.cpp `BuildDeletedOperatorTemplate` and `ExportDeletedOperatorTemplate` (the deleted template) and `ExportOperatorsToCpp` (skips a class specific)", "toolchain/check/testdata/interop/cpp/class/export/operator.carbon splits fail_todo_generic_impl (`impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)`: C++ `m * 3` is `overload resolution selected deleted operator '*'`; Carbon's `m * 3` compiles), fail_generic_impl_conversion and fail_generic_impl_conversion_non_member (beside a concrete `i64` impl, C++ `m * k` and `k * m` for an `int k` are rejected, not converted)", "toolchain/lower/testdata/interop/cpp/class/export/operator.carbon split generic_impl (a `long` operand selects the `i64` impl; Carbon's `m * k` for `k: i32` and `m * f` for a C++ operand call the generic impl)", "fork/opexport/plan.md M-11(a), M-28, M-32, D-OX-22"], "blocked_by": [], "notes": "A generic impl's `Op` needs a C++ template that calls the impl's specific for each C++ argument type (or one declaration per argument type C++ asks about), the machinery of the generics-export row (W-117 is the overload-set analogue). Until then each operator's generic impls are one deleted operator template, so a C++ use that Carbon would resolve to a generic impl is rejected rather than converted for a concrete impl (M-28, M-32); rev 2 of the plan left them invisible, a silent mis-selection. Filed at the OX-1 discharge."},
 {"id": "W-203", "title": "Exporting a Carbon class imported from another library yields an empty C++ record: no fields, and an exported method returning it by value corrupts memory (upstream defect)", "kind": "toolchain-defect", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — importing C++ types / exporting Carbon types", "evidence": ["fork/opexport/plan.md M-11(d): `.cents` of an imported class is `no member named 'cents'`; an exported `Plus` returning the imported class then `Get()` prints -1265344497 on trunk 0bdce60a5 and -1536643875 on the nightly 2026.10.12 where 42 is right; the C++ AST shows `class Money definition ... empty aggregate` with no FieldDecl", "toolchain/check/cpp/export.cpp:570-618 `ExportAllFieldsToCpp` (a struct field whose class-scope entry is not found is skipped, :581-583)"], "blocked_by": [], "notes": "Found by the OX-1 audit; pre-existing and upstream. The root cause is not yet confirmed: the hypothesis is that `LookupClassFieldByStructField` does not find an imported class's fields in its scope before their import refs are loaded. Fix belongs to the type-export row, not to OX-1."},
 {"id": "W-204", "title": "OX-1 residue: operator impls declared in an imported library are not exported to C++", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["toolchain/check/cpp/export.cpp `ExportOperatorsToCpp` walks `context.impls()` only (the impl lookup's import of associated libraries' impls, check/impl_lookup.cpp:669-691, has no counterpart)", "operator.carbon splits money_lib + fail_todo_imported_class", "fork/opexport/plan.md M-11(d)"], "blocked_by": ["W-203"], "notes": "Needs the class's defining library's impls imported (filtered to the Core operator interfaces), and W-203's class export fixed first. When it lands, check that two files exporting the same impl's operator do not both define the external `<member>__carbon_thunk` symbol at link time (exported methods share that open question)."},
 {"id": "W-206", "title": "OX-1 residue: `<=>` is not exported; the prelude's `OrderedWith` has no `Compare`", "kind": "missing-feature", "subsystem": "core/prelude + toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["core/prelude/operators/comparison.carbon:24 (`TODO: fn Compare`)", "docs/design/expressions/comparison_operators.md:345-380 (`fn Compare(self, u: U) -> Ordering`)"], "blocked_by": [], "notes": "When `Compare` lands, export it as `operator<=>` returning a C++ ordering type that `Ordering`'s four values map to (`std::partial_ordering`, given `Incomparable`), and revisit D-OX-6: `<=>` lets C++20 rewrite the relational operators."},
 {"id": "W-207", "title": "OX-1 residue: two operator impls whose operand types map to one C++ type are ambiguous at every C++ use (the W-118 shape)", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["fork/opexport/plan.md M-11(e) (`AddWith(i64)` beside `AddWith(Cpp.long)`: Carbon rejects the pair as same-structure non-final impls; C++ reports `use of overloaded operator '+' is ambiguous`)"], "blocked_by": [], "notes": "Reachable only with `final` impls or types such as `Core.CppCompat.Long64` beside `i64` (W-118's notes). Each impl keeps its own thunk symbol, so no call has the wrong ABI."},
 {"id": "W-208", "title": "OX-1 residue (bounds the row): `As` and `ImplicitAs` impls are not exported as C++ conversions", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export, generate_ast)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["docs/design/README.md:3679-3681 (`ImplicitAs(U)` corresponds to implicit conversions in C++, in the operator-overloading interop section)", "proposals/p000845-as-expressions.md:184-187 (`As` exposes C++'s `explicit` constructors and conversion functions for interoperability)", "toolchain/check/cpp/operators.cpp:42-52 (the import direction's `As`/`ImplicitAs`: `TODO: Support destructors and conversions`)", "fork/opexport/plan.md D-OX-18"], "blocked_by": [], "notes": "The row is PARTIAL until this lands. Clang collects conversion functions from the class definition, so these need an eager export at `CompleteType`, explicit for `As`, implicit for `ImplicitAs`; and C++ may convert by constructor or by conversion function (an `impl X as ImplicitAs(C)` is a converting constructor of `C`), a design choice F-017 does not make. docs/project/milestones.md:200 (the prelude's 'operators, conversions') does not bear on the scope."},
 {"id": "W-209", "title": "OX-1 residue: `operator[]` returns by value; the `ref` forms of indexing are not exported", "kind": "missing-feature", "subsystem": "core/prelude + toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["core/prelude/operators/index.carbon:7-10 (`At` only)", "docs/design/expressions/indexing.md:46-97 (`IndexWith.Ref`, `IndirectIndexWith`)"], "blocked_by": ["W-109"], "notes": "When W-109 adds the `ref` forms, export `Ref` as a non-`const` `operator[]` returning `E&` beside the `const` one."},
 {"id": "W-210", "title": "OX-1 residue: operator impls with no Carbon class among their types are not exported to C++ (a C++ or primitive `Self` with a non-Carbon operand, or a unary impl on a C++ type)", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export, generate_ast)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["operator.carbon split fail_todo_non_carbon_operands (`impl Cpp.Foo as AddWith(i32)`: C++ `f + 2` is `invalid operands`)", "fork/opexport/plan.md M-29 (`impl Cpp.Foo as Negate`: `invalid argument type 'Foo' to unary expression`)"], "blocked_by": [], "notes": "C++'s argument-dependent lookup for such operands never asks namespace `Carbon`. Exporting them needs the external source to answer operator lookups in the C++ type's own namespace (a C++-owned context the source does not serve today) or in the global namespace, and a rule for impls on Carbon primitives, which C++ sees as builtin types with no associated namespace. Outside the row's criterion as narrowed by OX-1 (the design overview's 'Carbon types implementing an operator overload'), filed as a limit."},
 {"id": "W-211", "title": "OX-1 residue: a hand-written C++ operator for an exported Carbon class that duplicates a Carbon operator impl is ambiguous with the exported operator in C++", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export) + docs/design/interoperability", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["operator.carbon split fail_user_cpp_operator_ambiguous (`operator+(const Carbon::Money&, const Carbon::Money&)` beside `impl Money as AddWith(Money)`: `use of overloaded operator '+' is ambiguous`; on trunk the same program printed 1042)", "fork/opexport/plan.md M-22"], "blocked_by": [], "notes": "C++ code written before OX-1 to fill the gap changes meaning: it now fails to compile. Carbon's own operator expressions are unaffected (D-OX-11). The page's 'Hand-written C++ operators' section gives the migration (remove the hand-written operator); a diagnostic note pointing at the Carbon impl, or a rule preferring one candidate, is the open design."}
]
```

W-007's notes gain (commit 6; the operators.cpp clause amended 2026-10-14,
review fold: RR-1, RR-3, and again, with VA-1's hunk, review fold: RR2-1, and
again, review fold: RR3-B2): "OX-1
(<date>, fork/opexport/plan.md D-OX-16): landed additively by sequencing — new
functions in export.cpp and export.h, a new `CXXOperatorName` arm in
generate_ast.cpp, a first resolution with an exact-match test, a
candidate-removal helper and a notes filter in operators.cpp's
`FindClangOperator`, and ONE in-function hunk in a contention
file, `BuildCppToCarbonThunkBody`'s `target.self_param &&
isa<clang::CXXMethodDecl>(function_decl)` condition, behaviour-preserving for
every earlier caller; thunk.cpp and type_mapping.cpp untouched; nothing moved or
renamed; ST-1's disjoint export.cpp hunk, in PR 55, and VA-1's, in
`ExportFunctionToCpp`, were the other contenders in flight. W-054's blocked_by
edge is cleared. Remaining contender: SC-B3 (W-029)."

**The decision log** (commit 6, fork/decision-log.md, newest first under
"Decided"): an entry headed "### OX-1 / F-017: Carbon operator impls exported as
C++ operator overloads (<date>)" that records, in the ST-1 entry's order: the
bullet and the row's move (MISSING → PARTIAL, bounded by W-208, expected and not
of record, the header delta, the conformance totals as expected); the context
(the empty README section, the provisional overview and its `ImplicitAs`
sentence, p006254's "Operator calls", V-3); the landed commits by hash (§3's
commits 2 to 6, the plan's revisions, the review folds, the merge of trunk);
WHAT LANDED by mechanism (the table, the two walks, the classification and its
non-diagnosing class predicate, which maps the recognized types, the deleted
declarations, the deleted operator templates, the default `!=`, every operator
lookup asked again, the first resolution with every candidate and its
exact-match test, the candidate removal and resolution again and the notes
filter, the one in-function hunk); D-OX-1..D-OX-22 as a veto digest, one line
each with its break condition; the residues W-202..W-204 and W-206..W-211 (W-205
unused); DEVIATIONS from this plan (each with its measurement); the verification
record of §8 (what ran, on which commit, what did not); and the V-3a
divergence-risk register entries (process.md standing rule 7, as the OV-3, ST-1
and OP-2 entries carry them, reviewed at each upstream merge): (1) the
`CXXOperatorName` arm of `FindExternalVisibleDeclsByName` against upstream
e476a2bd3's restructure (a `GetCarbonOwnedDecl` prologue, the re-export guard
for a filled entry and the negative-lookup erasure): on merge, keep upstream's
prologue and put the arm after it, and drop the duplicate
`DeclContextInternals.h` include; (2) the arm's marking of every operator entry
as having external declarations, so that Clang asks again at every lookup
(D-OX-12): if upstream gives the external source a way to extend or invalidate a
stored answer, use it; (3) the candidate filter's use of
`ovl_non_default_multiversion_function` as a silent non-viable marker: if Clang
changes how that kind is noted, or upstream adds a way to exclude candidates,
switch; (4) the `isa<clang::CXXMethodDecl>` conjunct in
`BuildCppToCarbonThunkBody`, against any upstream change of that function's
`this` handling; (5) the deleted operator templates' programmatic
`FunctionTemplateDecl` (parameters set into the type's `FunctionProtoTypeLoc`)
and `FindClangOperator`'s resolutions before and after the removal, the first
relying on Clang's perfect-match shortcut and conversion ranks to tell an
exactly matching exported operator, against Clang changes to the instantiation
of a declaration built that way, to `OverloadCandidateSet`'s deferral and its
`Best` flags, or to `ImplicitConversionSequence`'s ranks: at each LLVM update,
re-run M-31's, M-32's and M-41's probes; and (6)
`CanExportClassWithoutDiagnostic`, which repeats the checks of
`ExportClassToCpp`, `ExportNameScopeToCpp`, `ExportClassSpecificToCpp`,
`ExportGenericBindings` and `CompleteType`, and `MapsByExportingClass`, which
repeats which recognized kinds type_mapping.cpp's `TryMapClassType` maps by
exporting a Carbon class (the other recognized kinds, `MapResultArgToCppType`
and the `LookupCppType` and `LookupCppClassTemplate` header lookups are mapped
by the predicate, not repeated): whenever upstream or the fork changes any of
them, re-check it and re-run M-37's, M-39's, M-41's and M-42's probes. The entry
is the decision record F-017 (the register entries and the merge added
2026-10-14, review fold: B-12, B-5; the fifth entry and D-OX-22 added
2026-10-14, review fold: RR-1, RR-3; the second and sixth entries amended
2026-10-14, review fold: RR2-1; the fifth and sixth entries amended 2026-10-14,
review fold: RR3-B2, RR3-m1).

**fork/ORCHESTRATION.md** (commit 6, on the merge commit, whose trunk side
carries the Branches row for `claude/carbon-fork-0-1-ox` that 44761146d added;
f67ab650d has none): a dated stamp paragraph after the latest one — "OX-1
(claude/carbon-fork-0-1-ox, head <hash>: Carbon operator impls exported as C++
operator overloads, fork design F-017; W-054 discharged, W-202 to W-204 and
W-206 to W-211 filed; expected <totals>; row PARTIAL, bounded by W-208) is OPEN
and HELD, verified on the container-built toolchain at the merge commit" — and
that Branches row changed from PLANNING to "HELD OPEN as PR <n> — OX-1 at <hash>
(W-054 discharged; W-202..W-204 and W-206..W-211 filed; expected <totals>; row
PARTIAL, W-208); merged trunk after DD-1 and PR 57" (amended 2026-10-14, review
fold: B-5; the residue list amended 2026-10-14, review fold: RR2-1).

**fork/conformance/README.md** (commit 5): the generated program table, by
`python3 fork/conformance/runner.py --update-readme-table` (the arbiter's row
from SKIP to `run`, six new `run` rows); `--self-test` then passes; commit 6
regenerates it on the merge commit.

## §3 Commit structure (one PR, "OX-1: Carbon operator impls exported as C++ operator overloads", R29(b))

Every commit `--author="jmann345 <jerrymannstan@gmail.com>"`, committer
`Claude <noreply@anthropic.com>`, the session trailers after a blank line,
explicit paths only (R20). A problem found after a commit exists is fixed by a
new commit, never by amending or rebasing one (AGENTS.md: the history of a PR is
never rewritten; amended 2026-10-14, review fold: B-12).

1.  **This plan** (fork/opexport/plan.md), then its review folds: rev 2
    (folding reviews A and B of rev 1, 3128eded5), rev 3 (folding the focused
    re-review of rev 2, 7d71f02b3), rev 4 (folding the second focused
    re-review, of rev 3, fd324a642), rev 5 (this revision, folding the third
    focused re-review, of rev 4, 145fdaa62), and a rev 6 if the next re-review
    asks for one (amended 2026-10-14, review fold: RR-1, RR-2, RR2-1, RR3-B1,
    RR3-B2).
2.  **Toolchain**: toolchain/check/cpp/export.cpp, export.h, generate_ast.cpp
    and operators.cpp, §2.1 to §2.4 applied with `git apply`. Alone it keeps
    file_test green (M-8: 1942 of 1942 with `v5`, `v6`, `v7` and `v8`), so it is
    a commit of its own (context.h no longer changes; amended 2026-10-14, review
    fold: RR2-1).
3.  **Golden sources**: the four files of §2.5 with `// AUTOUPDATE` and no
    CHECK lines. file_test is red from here until commit 4, as R19 expects for
    unfilled goldens.
4.  **The fill**: "Autoupdate testdata goldens on the container arbiter" —
    `autoupdate.sh` twice (R26; M-12 measured that pass 2 changes three of the
    four files, rev 2's and rev 3's all four; amended 2026-10-14, a fixer
    correction), then a third pass that must change nothing, then `gate.sh`;
    only the four new files change.
5.  **Programs, docs and the row**: the seven programs of §2.6, the README
    program table (`--update-readme-table`),
    docs/design/interoperability/operators.md and the README amendment (§2.7),
    and the row and header of §2.8, quoting §8.4's container run on commit 2's
    build (which commits 3 and 4 do not change), as expected, not of record.
    The row names no record that commit 6 writes.
6.  **Discharge**, after everything in the next paragraph: the ledger (W-054,
    W-202..W-204 and W-206..W-211, W-007's notes; amended 2026-10-14, review
    fold: RR2-1), the decision-log entry, the ORCHESTRATION
    stamp and Branches row, the row's and header's re-quote and the README
    table from §8.8's run on the merge commit, and this plan's landed notes;
    preceded by the id re-scan of the head.

**Between commits 5 and 6**, in this order (the OP-2 plan's sequence; amended
2026-10-14, review fold: B-5, B-12): the implementation reviews of R29(c) (two,
because Actions is disabled and no hosted verification can be green; the OP-1
and OP-2 precedent); their fold by a separate fixer agent (R11: never the
implementer continuing, never a reviewer), in new commits ("OX-1 fixes: fold the
implementation reviews"), each refill its own "Autoupdate testdata goldens on
the container arbiter" commit; then the merge of trunk, taken when DD-1 (PR 58)
and PR 57 have merged (D-OX-19; fork/ORCHESTRATION.md's order at 3eb7f36f0 puts
PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, PR 56 and PR 57 before PR 58, and OX-1
and VA-1 after PR 58); then §8.8 on the merge commit; then commit 6. Before each
of commits 2 to 6 and each fix commit, `uvx prek run --files <that commit's
files>` runs to a fixpoint, with R31's heading and list-item counts recorded
before and after for every `.md` in the commit; before hand-over, `uvx prek run`
with `--all-files` in place of the file list runs to a fixpoint too (R25).

**The merge of trunk** (a merge commit, never a rebase; amended 2026-10-14,
review fold: B-5). Each kind of conflict has a fixed rule:

-   **Goldens.** A conflicted golden takes trunk's side
    (`git checkout --theirs <path>`, trunk being the merged branch) and is
    refilled by autoupdate in a new "Autoupdate testdata goldens on the
    container arbiter" commit after the merge; CHECK lines are never merged by
    hand (R16(a)). OX-1's four new goldens do not conflict, but the lower golden
    includes min_prelude/full.carbon, whose prelude PR 55 and PR 57 change; if
    §8.8's gate shows any of the four (or any trunk golden) red on the merge
    commit, that refill commit refills it.
-   **The interop README.** If DD-1 has merged, the README takes trunk's side,
    OX-1's dated amendment of §2.7 is dropped, and §6.2.1's three sentence
    replacements are applied in the merge's resolution, with R31's counts
    before and after; if DD-1 has not, the amendment stays and DD-1's next fold
    applies §6.2.1 (D-OX-19's break condition).
-   **Records.** gap-analysis.md, work-items.json, decision-log.md,
    ORCHESTRATION.md and conformance/README.md keep trunk's rows and entries for
    other branches and take this branch's OX-1 rows, re-anchored by bullet text,
    item id or heading, never by line number (R7); the gap header is recounted,
    never merged; the README table is regenerated by
    `runner.py --update-readme-table`.
-   **Ids.** If any of W-202..W-211 or F-017 is taken by then (the head's
    test), the head's re-allocation rule applies in a new commit to every
    program header, golden source, doc and record that names it.
-   **Dates.** If commit 6's date differs from commit 5's, commit 6 re-stamps
    every `<date>` commit 5 wrote (the page's F-017 line, the README amendment
    if kept, the row) to the landing date.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

No existing golden is refilled (M-8). Predicted key lines, each taken from the
`v8` fill in the scratch mirror (`$Y/fill-v8.snap3/`, M-12; rev 4's were from
the `v7` fill, `$L/fill-v7f.snap3/`, rev 3's from the `v6` fill,
`$G/ev/fill-v6.snap3/`, and rev 2's from the `v5` fill,
`$F/fill-v5f.snap3/`) with the split's own filename in place of the
substitute's (amended 2026-10-14, review fold: A-1, A-2, A-3, A-4, A-5, A-7,
A-9, B-1, B-2, B-3, B-6, B-10; the rev 3 rows and counts amended 2026-10-14,
review fold: RR-1 to RR-6; the rev 4 rows, counts and falsifiers amended
2026-10-14, review fold: RR2-1, RR2-2, RR2-4; the rev 5 rows and counts
amended 2026-10-14, review fold: RR3-B1, RR3-B2, RR3-M1):

| File / split | Must | Key line(s) |
| --- | --- | --- |
| check operator.carbon: arithmetic, signature_from_impl_function, compound_assignment, comparison, move_only_not_equal, bitwise, index, non_member, non_member_nested, namespace, base_class, unmappable_impl, deleted_result_unselected, unexportable_operand_class, non_member_unexportable_operand, sfinae_detection, cpp_side_unrelated_impl, carbon_side_unmappable, carbon_side_unexportable_class, carbon_side_generic_class, carbon_side_unrelated_impl, carbon_side_candidates, carbon_side_user_cpp_operator, carbon_side_then_cpp, carbon_side_deferred_template, carbon_side_trait_sees_export, carbon_side_template_body_unexportable, carbon_side_constexpr_body_unexportable, carbon_side_call_unexportable, carbon_side_conversion_unexportable, carbon_side_str_operand_without_header, str_operand_without_header, carbon_side_result_without_header, carbon_side_slice_field, self_referential_operand, non_member_before_operand, impl_after_lookup, money_lib | compile | no output at all (no SemIR ranges, no warning; the `static_assert`s hold) |
| fail_conversion_carbon_side | fail | ``error: cannot access member of interface `Core.MulWith(i64)` in type `Money` that does not implement that interface [MissingImplInMemberAccess]`` |
| fail_compound_assignment_rvalue | fail | `error: no viable overloaded '+=' [CppInteropParseError]`; note `candidate function not viable: expects an lvalue for object argument` |
| fail_postfix_increment | fail | `error: cannot increment value of type 'Carbon::Money' [CppInteropParseError]` |
| fail_reversed_equality | fail | `error: invalid operands to binary expression ('int' and 'Carbon::Money') [CppInteropParseError]` (the `Reversed` line only) |
| fail_base_class_carbon_side | fail | ``error: cannot access member of interface `Core.AddWith(Derived)` in type `Derived` that does not implement that interface [MissingImplInMemberAccess]`` |
| fail_noncopyable_lvalue_operand | fail | `error: call to implicitly-deleted copy constructor of 'Carbon::Money' [CppInteropParseError]`; notes `copy constructor of 'Money' is implicitly deleted because field 'n' has a deleted copy constructor`, `'NoCopy' has been explicitly marked deleted here`, `passing argument to parameter here` (the `CppSide` line only) |
| fail_todo_generic_impl | fail | `error: overload resolution selected deleted operator '*' [CppInteropParseError]`; note `candidate function [with $0 = int] has been explicitly deleted` |
| fail_generic_impl_conversion | fail | `error: overload resolution selected deleted operator '*' [CppInteropParseError]`; notes `candidate function [with $0 = int] has been explicitly deleted` and `candidate function` (the `i64` impl's) |
| fail_generic_impl_conversion_non_member | fail | the same error and notes, for the non-member `operator*` |
| fail_deleted_result | fail | `error: overload resolution selected deleted operator '+' [CppInteropParseError]`; notes `candidate function has been explicitly deleted` and `candidate function` |
| fail_deleted_result_not_equal | fail | `error: overload resolution selected deleted operator '!=' [CppInteropParseError]`; notes `candidate function has been explicitly deleted` and `candidate function` |
| fail_unexportable_operand_conversion | fail | `error: overload resolution selected deleted operator '+' [CppInteropParseError]`; notes `candidate function [with $0 = int] has been explicitly deleted`, at the `Holder` impl's `Op`, and `candidate function`, the `i64` impl's |
| fail_unexportable_result_class | fail | `error: overload resolution selected deleted operator '+' [CppInteropParseError]`; note `candidate function has been explicitly deleted` |
| fail_user_cpp_operator_ambiguous | fail | `error: use of overloaded operator '+' is ambiguous (with operand types 'Carbon::Money' and 'Carbon::Money') [CppInteropParseError]`; two `candidate function` notes |
| fail_todo_non_carbon_operands | fail | `error: invalid operands to binary expression ('Foo' and 'int') [CppInteropParseError]` |
| fail_impl_after_use | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'Carbon::Money')` |
| fail_todo_imported_class | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'Carbon::Money')` |
| check operator_ast.carbon: operator | compile | `CXXMethodDecl ... used operator+= 'void (int) &' inline internal-linkage`; `CXXMethodDecl ... used operator+ 'Carbon::Money (Carbon::Money) const'` calling `Op__carbon_thunk`; `CXXMethodDecl ... used operator!= 'bool (Carbon::Money) const'` whose body is `UnaryOperator ... prefix '!'` over the `.operator==` call with an `ImplicitCastExpr ... 'Carbon::Money' xvalue <NoOp>` argument; `CXXMethodDecl ... operator* 'void (int) const' inline delete external-linkage` beside `used operator* 'int (Carbon::Money) const'`; `FunctionTemplateDecl ... operator/` with `TemplateTypeParmDecl ... typename depth 0 index 0` and `CXXMethodDecl ... operator/ 'void (type-parameter-0-0) const' inline delete`, beside `used operator/ 'int (long) const'`; `FunctionDecl ... used operator- 'int (int, Carbon::Money)' inline internal-linkage` in `namespace Carbon` (217 CHECK lines) |
| check operator_cxx20.carbon: move_only_equality, carbon_side_rewritten_candidate, carbon_side_rewritten_ordering | compile | no output (15 CHECK lines in the file, all in the three `fail_` splits) |
| fail_reversed_equality | fail | `error: invalid operands to binary expression ('int' and 'Carbon::Money') [CppInteropParseError]` (the `Reversed` line) |
| fail_reversed_equality_non_member | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'int') [CppInteropParseError]`; note `candidate function not viable: no known conversion from 'Carbon::Money' to 'int' for 1st argument` |
| fail_reversed_ordering | fail | `error: invalid operands to binary expression ('int' and 'Carbon::Money') [CppInteropParseError]` |
| lower operator.carbon: member | compile | `define void @"_COp__carbon_thunk.Money.Main:AddWith.7b773fb4f7cbc162.Core"`; `define internal i32 @_ZNK6Carbon5MoneyplES0_` calling it; `define internal void @_ZNR6Carbon5MoneypLEi` |
| default_not_equal | compile | `define internal noundef zeroext i1 @_ZNK6Carbon5MoneyneES0_` calling `@_ZNK6Carbon5MoneyeqES0_` and negating its result |
| non_member | compile | `define internal noundef i32 @_ZN6CarbonmiEiNS_5MoneyE` calling `@"_COp__carbon_thunk.Int.be1e879c1ad406d8.Core:SubWith.7b773fb4f7cbc162.Core"` |
| carbon_side_cpp_operand | compile | `define i32 @_CCarbonSide.Main` whose one call is `call i32 @"_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core"`; `@_CCppSide.Main` reaches `@_ZNK6Carbon5MoneyplE3Foo` |
| carbon_side_default_not_equal | compile | `define i1 @_CCarbonSide.Main` calling `@_CNotEqual.EqWith.Core.8d8286e58955f8ab` (the interface's default for the impl), which calls `@"_CEqual.Foo.Cpp:EqWith.7b773fb4f7cbc162.Core"`; `@_CCppSide.Main` reaches `@_ZN6CarbonneE3FooNS_5MoneyE`, which calls `@_ZN6CarboneqE3FooNS_5MoneyE` |
| carbon_side_template_candidate | compile | `define i32 @_CCarbonSide.Main` whose one call is `call i32 @"_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core"`, the impl; the module defines the Carbon thunks of both exported `operator+` and no specialization of the template |
| carbon_side_template_body | compile | `define i32 @_CCarbonSide.Main` whose one call is `call i32 @"_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core"`; no specialization of the template is defined |
| carbon_side_call_template | compile | `define i32 @_CCarbonSide.Main` calling `@_Z4PickIN6Carbon5MoneyETnN8EnableIfIXsr7HasPlusIT_EE5valueEE4typeELi0EEiRKS3_i.carbon_thunk.__`, the `int` overload |
| carbon_side_conversion_template | compile | `define i32 @_CCarbonSide.Main` calling `@_ZN3BarC1IN6Carbon5MoneyETnN8EnableIfIXsr7HasPlusIT_EE5valueEE4typeELi0EEERKS4_.carbon_thunk._`, the constructor that `HasPlus` enables (its sibling would mangle `EnableIfIXntsr7HasPlus`) |
| carbon_side_call_template_body | compile | `define i32 @_CCarbonSide.Main` calling `@_Z3SumIN6Carbon5MoneyEEiRKT_S4_.carbon_thunk.__`; `@_Z3SumIN6Carbon5MoneyEEiRKT_S4_` calls `@_ZNK6Carbon5MoneyplES0_`, which calls `@"_COp__carbon_thunk.Money.Main:AddWith.7b773fb4f7cbc162.Core"` |
| carbon_side_compound_template | compile | `define i32 @_CCarbonSide.Main` calling `@"_COp.Money.Main:AddAssignWith.1ea11ae296c4d4df.Core"`, the impl, and no specialization of the `operator+=` template |
| carbon_side_agrees_with_cpp_side | compile | `define i32 @_CCarbonPlus.Main` calling `@"_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core"` and `define i1 @_CCarbonEq.Main` calling `@"_CEqual.Money.Main:EqWith.03e072b0483abf5b.Core"`; `@_CCppPlusSide.Main` and `@_CCppEqSide.Main` reach `@_ZNK6Carbon5MoneyplE3Foo` and `@_ZNK6Carbon5MoneyeqE3OptIiE`, which call those impls' Carbon thunks; no specialization of either template is defined |
| generic_impl | compile | `define i32 @_CCarbonSide.Main` calling the generic impl's specific `@"_COp.Money.Main:MulWith.dc0fcff0a74064b8.Core.cfa19092a257b072"`; `define i32 @_CCarbonSideCppOperand.Main` calling its specific `@"_COp.Money.Main:MulWith.dc0fcff0a74064b8.Core.c939ee6833dfffac"`; `define internal noundef i32 @_ZNK6Carbon5MoneymlEl` calling `@"_COp__carbon_thunk.Money.Main:MulWith.f249b435619a5146.Core"` (2228 CHECK lines in the file) |

The fingerprints in symbol names are the fill's; a reviewer checks the shapes,
not the hex digits, which depend on the specific's fingerprint and are
reproduced by any fill of the same sources. Falsifiers: any crash; a golden
outside §2.5's four in the fill's diff; a `fail_` split that compiles or a
non-`fail_` split with any diagnostic, a warning included (rev 3 excepted
`carbon_side_candidates`'s two warnings and missed eight; amended 2026-10-14, a
fixer correction, and review fold: RR2-4); any key
line above that the fill does not reproduce; a third autoupdate pass that
changes anything (R26).

## §5 Conformance: one SKIP → PASS, six new; delta PASS +7, SKIP −1, programs +6

From the floor of record 128 / 0 / 22 over 150, 48/56 bullets (trunk;
re-measured in the container, M-13) to 135 / 0 / 21 over 156, 49/56 (M-13, `v5`,
`v6`, `v7` and `v8`). Programs that move: interop/cpp_operator_export (SKIP →
PASS). New, PASS: interop/cpp_operator_export_arithmetic, _compound, _compare,
_bitwise, _index, _nonmember. No other program changes status (128 of 128 PASS
stay PASS under `v4`; the full tree under `v5`, `v6`, `v7` and `v8` has no
failure). The bullet "Type system: C++ interop — exporting Carbon operator
overloads into C++" goes from SKIP to PASS with 7 programs, while its row is
PARTIAL (D-OX-14). At OX-1's land time the totals are measured, not computed:
§8.8 runs the conformance suite on the merge commit, and commit 6 quotes that
run (amended 2026-10-14, review fold: B-5).

## §6 Churn and collision analysis

### §6.1 Churn

toolchain: export.cpp +1161/−1, export.h +31, generate_ast.cpp +32,
operators.cpp +70/−3, and no context.h change (rev 4: +1119/−1, +31, +32,
+44/−3; rev 3: +797/−1, +29, +41, +42/−5, +11; rev 2: +625/−1, +27, +41,
+22/−3, +11). Goldens: four new files (1593, 68, 193 and 447 source lines;
after the fill 1715, 284, 208 and 2676 lines); no existing golden changes (the
toolchain and golden counts amended 2026-10-14, review fold: RR-1 to RR-6, and
again, review fold: RR2-1, RR2-2, RR2-4, and again, review fold: RR3-B1,
RR3-B2). Programs: one
modified, six new. Docs: one new page (≈300 lines), one 8-line amendment.
Records: the row and header, the ledger (one item replaced, ten added, one note
extended), the decision log, ORCHESTRATION, the conformance README table
(amended 2026-10-14, review fold: all).

### §6.2 Collisions (measured against each live branch at the heads named, 2026-10-14)

| Branch (PR) | Head | Shared paths | Resolution |
| --- | --- | --- | --- |
| ST-1 (PR 55) | 21307851a | export.cpp (+5 at :293-300), interop README (+5 at :300), prelude and its full-prelude goldens, records | the diff applies at offset 5 (M-16); the README hunks are disjoint; OX-1's lower golden is refilled at the merge if the prelude change moves it (§3) |
| SC-1 | 395096d51 (re-measured at rev 5; still none of OX-1's files) | records only (no file under toolchain/check/cpp; its toolchain work is in check/, impl_lookup.cpp among it, which OX-1 does not edit) | applies cleanly (M-16) |
| UA-2 (PR 51) | f96fe8a7a | records only | none |
| CM-1 (PR 52), SAFE-1 (PR 53), EV-1 (PR 54) | ea573f672, adaae4e35, cb3ef2e74 | records only | none |
| OP-1 (PR 56) | 379f20f67 | records only (prelude and other check files) | none |
| OP-2 (PR 57) | 628273444 | records; core/prelude/types/optional.carbon and toolchain/lower/handle.cpp, which refill full-prelude lower goldens | the diff applies cleanly; OX-1's lower golden includes the full prelude, so it is refilled at the merge if needed (§3) |
| DD-1 (PR 58) | fcee90d9b | docs/design/interoperability/README.md (+847: it fills "The operator interoperability model"), docs/design/README.md (a fork note at :3659 linking that section), records; its records mention W-202..W-211 only as OX-1's reservation | §6.2.1's three replacements at OX-1's merge of trunk after DD-1 |
| VA-1 | 9a0888ef0 (local and `origin`; re-measured at rev 5) | export.cpp: C4 adds a 12-line TODO for exporting a variadic function to `ExportFunctionToCpp` (export.cpp:1597), a W-007 contention-file hunk disjoint from OX-1's; records; its other toolchain edits (check/context.h, call.cpp, deduce.cpp, lower and parse files, among others) touch none of OX-1's four files | the diff applies at offset 12 (M-16); VA-1 merges after OX-1 or DD-1, whichever is later (ORCHESTRATION at 3eb7f36f0), and its merge of trunk takes OX-1's hunks unchanged; the id blocks are disjoint |

(Heads, the PR 55 and PR 57 prelude paths and the VA-1 row amended 2026-10-14,
review fold: A-10, B-5, B-8; SC-1's and VA-1's heads re-measured with `v6`'s
diff, amended 2026-10-14, review fold: RR-1, RR-3, RR-5, and with `v7`'s, VA-1's
export.cpp hunk found, amended 2026-10-14, review fold: RR2-1, and with `v8`'s,
amended 2026-10-14, review fold: RR3-B1, RR3-B2.)

#### §6.2.1 The merge-time edit of DD-1's text

At OX-1's merge of trunk after DD-1: drop OX-1's amendment block (§2.7) and keep
DD-1's section; in it, make three replacements, each of a whole sentence
wherever DD-1's wrapping puts it (re-checked at DD-1's head fcee90d9b, where
they are at :1113-1116, :1187-1189 and :782-784; amended 2026-10-14, review
fold: B-9). In "The operator interoperability model", replace the sentence that
begins

```text
The 0.1 toolchain implements the first direction: a Carbon operator expression with a C++ operand looks up the C++ operator functions, members and non-members, and resolves among them with C++ overload resolution (proposal 6254, "Operator calls").
```

with

```text
The 0.1 toolchain implements both directions. In the first, a Carbon operator expression with a C++ operand looks up the C++ operator functions, members and non-members, and resolves among them with C++ overload resolution (proposal 6254, "Operator calls"); a Carbon operator exported to C++ is not among them.
```

replace the section's last sentence

```text
The other direction is not implemented: a Carbon type's operator interface implementations are not exported as C++ operators (fork work item W-054).
```

with

```text
The other direction is specified in [Exporting Carbon operators to C++](operators.md) (fork design F-017): a Carbon type's operator interface implementations are C++ operators; conversions are not yet exported (fork work item W-208).
```

and in "Using Carbon from C++" replace

```text
Carbon operator implementations are not exported as C++ operators ([The operator interoperability model](#the-operator-interoperability-model)),
```

with

```text
Carbon operator implementations are C++ operators ([Exporting Carbon operators to C++](operators.md)),
```

Records: every branch edits fork/ORCHESTRATION.md, decision-log.md,
gap-analysis.md and work-items.json; OX-1's edits are an appended entry, one
row, new items and one note, merged at the merge of trunk by §3's rules.

### §6.3 Upstream

Upstream has not started operator export (M-17). At the next advance,
e476a2bd3's restructured `FindExternalVisibleDeclsByName` (a
`GetCarbonOwnedDecl` prologue, a re-export guard for an entry already filled,
and the erasure of an empty entry after a failed identifier lookup) takes OX-1's
arm as one more case after the prologue; its erasure lets a failed identifier
lookup be asked again, as OX-1's marking of every operator entry lets every
operator lookup be (D-OX-12). generate_ast.cpp's and operators.cpp's include
hunks need their context refreshed, and the fork's `DeclContextInternals.h`
include is dropped as upstream's duplicate (M-16; the decision log's V-3a
entries, §2.8; rev 3 used the erasure for Carbon's own lookups and refreshed
context.h too; amended 2026-10-14, review fold: RR2-1).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1 (Carbon-only code rejected).** Carbon's own operator expressions,
    calls and conversions with a C++ operand or callee reach Clang's lookups in
    the exported class, directly or through the templates they instantiate
    (M-9, M-37). Rev 4 removes the cause instead of narrowing when it may
    fire: no export can emit a diagnostic (D-OX-9), and no answer is cached
    (D-OX-12); rev 2's and rev 3's flag, which kept Carbon's operator lookup
    from exporting, was falsified twice by exactly this risk (M-31, M-37) and
    is gone. Falsifier: any `carbon_side_*` split, the four
    `carbon_side_*_unexportable` splits among them, or any Carbon-only probe
    of M-20, M-22, M-23, M-26, M-31 or M-37 rejected by an export's
    diagnostic, or a Carbon operator expression lowered through an exported
    operator. A Carbon-only program can still change in the ways R-11 states
    (rev 1's R-1 fired on review A's third shapes, and rev 4's on the
    recognized types, RR3-B1, M-41; amended 2026-10-14, review fold: A-1, B-1,
    RR-1, RR-2, RR2-1, RR2-2, RR3-B1).
-   **R-2 (the condition hunk).** D-OX-16's claim that every earlier caller
    passes a method under `self_param`. Falsifier: any existing golden changing
    (M-8 says none), or a `cast` assertion in the gate.
-   **R-3 (hand-written C++ operators).** C++ code that declared its own
    operator for an exported class, beside a Carbon impl of the same operator,
    now has two candidates; where they tie, C++ reports an ambiguity (M-22,
    W-211). Carbon's own expressions are not ambiguous: they use a hand-written
    operator that ties with an exported one, and the impl where C++ prefers
    an exactly matching exported operator to a hand-written template (a1 to
    a6, D-OX-11). Falsifier: a Carbon-only expression for which C++ selects no
    exactly matching export and whose result differs from Clang's over the C++
    candidates that are not exports (the `carbon_side_user_cpp_operator`
    split, `userop.carbon`); the C++-side ambiguity is accepted, documented
    with its migration, and filed (rev 1 treated both sides as a user error;
    amended 2026-10-14, review fold: A-3, RR3-B2).
-   **R-4 (hook reach).** Unqualified lookups of an operator name inside
    `namespace Carbon` C++ code (the support header) reach the non-member walk;
    it only answers for impls whose operand is a Carbon class with that
    namespace as its innermost enclosing namespace. Falsifier: a support-header
    use that changes behaviour; none exists in the goldens (M-8).
-   **R-5 (the lookup-cache contract).** D-OX-12 marks every operator entry
    as having external declarations, relying on `DeclContext::lookupImpl`
    asking the source again for such an entry (DeclBase.cpp:1951-1954) and on
    `SetExternalVisibleDeclsForName` replacing the declarations it answered
    before with the new list (`replaceExternalDecls`), which keeps C++ code's
    own declarations of the name; and the second removal pass relies on Clang
    deducing an operator candidate set's deferred template candidates inside
    `BestViableFunction` (§0.1 row 15). Falsifier: `impl_after_lookup`,
    `non_member_before_operand`, `carbon_side_then_cpp` or `generic_impl`
    failing, M-39's `x1` or `x2` printing anything else, or a Clang update
    that changes lookupImpl, the `StoredDeclsList` external-declarations bit,
    `shouldDeferTemplateArgumentDeduction` or `BestViableFunction` (re-checked
    at each advance, §6.3). Rev 2's and rev 3's erasure of the entry during
    Carbon's own lookup is gone with the flag, and rev 1's R-5 (unused thunks
    from Carbon's lookup) is back as a stated consequence (R-11) (amended
    2026-10-14, review fold: A-4, RR-1, RR2-1).
-   **R-6 (fill drift).** All four goldens need two autoupdate passes (M-12). A
    third pass that changes anything is nondeterminism: stop and diagnose (R26).
-   **R-7 (the row's status).** D-OX-14 records PARTIAL on the overview's
    `ImplicitAs` sentence; the reviews or the leads may read the bullet as
    operators only. Then the row is DONE with W-208 a limit, a one-word and
    one-sentence change in §2.8 (rev 1 recorded DONE with PARTIAL as the
    fallback; amended 2026-10-14, review fold: A-6, B-4).
-   **R-8 (the non-viable marker).** The candidate filter reuses
    `ovl_non_default_multiversion_function`, whose notes Clang skips
    (SemaOverload.cpp `NoteFunctionCandidate`, "Do nothing, these should simply
    be ignored"), and the notes of a Carbon-side diagnostic also filter
    exported operators out, the deferred specializations deduced for the
    notes included (RR2-3). Falsifier: a Clang note printed for an exported
    operator in a Carbon-side diagnostic, or a Clang update that changes the
    kind's handling (a V-3a register entry, §2.8) (amended 2026-10-14, review
    fold: RR2-3).
-   **R-9 (the non-diagnosing predicate).** `CanExportTypeWithoutDiagnostic`
    repeats from SemIR the checks of the class export and completion code
    (D-OX-9 (3)): `ExportClassToCpp`, `ExportNameScopeToCpp`,
    `ExportClassSpecificToCpp`, `ExportGenericBindings` and
    `CarbonExternalASTSource::CompleteType` (export.cpp, generate_ast.cpp);
    and `MapsByExportingClass` repeats which recognized kinds type_mapping.cpp's
    `TryMapClassType` (:196-372) maps by exporting a Carbon class: one that is
    not a recognized type, an `Optional` of anything but a pointer (its facet
    value unwrapped as at :271-275), and an integer type whose bit width does
    not embed. The other recognized kinds are no longer mirrored but mapped,
    once the Carbon classes they name pass, so `TryMapClassType`'s arms for
    them, the header lookups `LookupCppType` and `LookupCppClassTemplate`
    (`str`, `Core.Slice`, `Core.Result`, `Cpp.Exception`) and
    `MapResultArgToCppType` (:156-182, a `Core.Result` argument class trivially
    copyable for export) answer for themselves (M-41). If that code gains a
    check the predicate lacks, or a recognized kind starts or stops exporting
    a Carbon class, an export could diagnose again, and if the predicate
    rejects a class that exports cleanly, a C++ use with that operand is
    rejected by the deleted template where it could have worked. Falsifier: a
    diagnostic from an export (M-37's, M-39's and M-41's probes, the
    `*_unexportable*`, `carbon_side_*_without_header` and
    `carbon_side_slice_field` splits), or a deleted-template rejection for an
    operand whose class C++ can export (`x6_virtual_operand` for virtual
    functions, `self_referential_operand` and M-42's f1 for an optional
    pointer); re-checked whenever the export code or type_mapping.cpp changes
    (the sixth V-3a entry, §2.8). Rev 3's R-9 accepted the class's own
    diagnostic at every C++ use, a detection included; rev 4's named the class
    export code only, while its predicate let the recognized types through
    unmapped and missed an optional pointer's facet value, the drift RR3-B1
    and M-42 (a) found (amended 2026-10-14, review fold: RR-6, RR2-1, RR3-B1,
    RR3-m1).
-   **R-10 (the deleted template's construction).**
    `BuildDeletedOperatorTemplate` builds a function template outside the
    parser, and template argument deduction substitutes into its declaration:
    the first `v6` link, whose parameters had no type-source info, crashed in
    `Sema::SubstParmVarDecl` on the first deduction (M-32). Falsifier: a crash,
    or a deduction that fails where a written template's succeeds, in M-32's
    probes or the generic splits; re-checked at each LLVM update (the fifth V-3a
    entry, §2.8) (added 2026-10-14, review fold: RR-3).
-   **R-11 (what the rule changes for Carbon-only programs).** A C++ template
    sees the exported operators whoever instantiates it (D-OX-21). The rule's
    consequences, each C++'s own answer to the same C++ question: a Carbon
    call or conversion with a C++ callee selects the C++ function that an
    export makes viable, and a C++ function it calls can call the export in
    its body (b1, b2, c1 to c4; the lower `carbon_side_call_template`,
    `carbon_side_conversion_template` and `carbon_side_call_template_body`);
    a Carbon operator expression for which C++ itself selects a function that
    is not an export selects it too (e4; `carbon_side_trait_sees_export`); a
    trait has one value whoever instantiates it (t1 to t3, M-33); and a module
    defines the Carbon thunks of the operators that Carbon's lookups exported
    (M-40). The boundary of D-OX-11: where C++ reaches an exported operator
    only by converting an operand, a Carbon operator expression resolves among
    the other C++ candidates, and a template that the export makes viable can
    win there (f3, M-42 (b), §7 A-19). Resolved at rev 5, and not the rule's
    consequences but rev 4's removal of every export before ranking (RR3-B2,
    RR3-M1): t4, o3, t5 and k1 to k7 now give C++'s value, which for t4, o3,
    t5, k3b, k4b and k5 is trunk's; e2 and x7, which rev 4 rejected with
    W-045's TODO, print trunk's `1`; and a1 to a6, where an unconstrained
    hand-written template ties with the exported operator, print C++'s `7`
    where trunk printed `1` (a5 rejected for its `auto` return type) (D-OX-11,
    M-41). Each is pinned (§4) and documented on the page. Falsifier: the
    leads require such a program to lower as on trunk; then the consequences
    above need a mechanism that classifies Clang's instantiations by origin
    (§7 A-18) (added 2026-10-14, review fold: RR2-1, RR2-2; the consequences
    and the resolved cases split 2026-10-14, review fold: RR3-B2, RR3-M1).

### §7.2 Rejected alternatives

-   **§7 A-1: export only `operator+`, the arbiter's case, to flip the row.**
    Rejected as the Goodhart move R16 forbids in spirit: the arbiter would pass
    while the bullet ("Exporting Carbon overloads into C++") stays mostly
    unmet; M-19 shows the other families cost table rows, not mechanisms.
-   **§7 A-2: every impl as a non-member operator.** Rejected: C++ would then
    convert the left operand implicitly, which Carbon's dispatch on `Self` never
    does (D-OX-2).
-   **§7 A-3: hidden friends.** Rejected for the same reason: argument-dependent
    lookup finds a friend through either operand.
-   **§7 A-4: leave `!=` to C++20's rewrite.** Rejected: the default dialect is
    C++17 (M-6), and the rewrite adds reversed `==` candidates Carbon lacks.
-   **§7 A-5: export the witness table's default `NotEqual` function.**
    Rejected for 0.1: it is the interface's function with the impl's specific
    (M-3), which the export path cannot take (it requires a non-generic
    function, export.cpp:891); the C++ `!(a==b)` is the default's body by the
    design text (comparison_operators.md:260).
-   **§7 A-6: export the Carbon operator expression (a thunk that calls through
    the interface) instead of the impl's function.** Rejected for 0.1: for a
    concrete impl both select the same function, and it needs a new thunk kind
    in check/thunk.cpp, a contention file.
-   **§7 A-7: keep OV-3's TODO for an unmappable impl.** Rejected for an
    operand or result with no C++ form at all (D-OX-9 (1) and (2)); kept for a
    class C++ cannot export (D-OX-9 (3), D-OV-18) (amended 2026-10-14, review
    fold: A-1).
-   **§7 A-8: suppress export while Carbon's impl lookup runs (a context
    flag).** Rejected at rev 1 as a new piece of `Context` state; **adopted at
    rev 2** as D-OX-21, because the silent omission and the guard that rev 1
    preferred were each falsified (M-20, M-22, M-23, M-26) (amended 2026-10-14,
    review fold: A-1, A-4); its scope covers overload resolution from rev 3
    (M-31; amended 2026-10-14, review fold: RR-1). **Rejected again at rev 4**:
    a dynamic scope around one call site cannot cover the instantiations Clang
    performs for a Carbon expression after it, and inside it made a trait's
    value depend on who asked first (M-33, M-37, D-OX-21; amended 2026-10-14,
    review fold: RR2-1).
-   **§7 A-9: export conversions (`As`, `ImplicitAs`) now.** Rejected for 0.1
    (D-OX-18): a design of its own; the row stays PARTIAL for it (W-208).
-   **§7 A-10: a differential `.diff.cpp` oracle per program.** Rejected: the
    agreeing direction needs none (R30(b)), and an oracle would hide the
    divergences D-OX-15 documents.
-   **§7 A-11: record the row DONE by reading the bullet as operators only.**
    Rejected at rev 2 (rev 1's choice): the overview's operator-overloading
    interop section maps `ImplicitAs` to C++ conversions in the same paragraph
    as `BitComplement` to `operator~`, and the only contrary evidence rev 1
    cited was a miscited, unrelated milestone line (D-OX-18) (amended
    2026-10-14, review fold: A-6, B-4).
-   **§7 A-12: a side-effect-free SemIR predicate that predicts whether a class
    exports without a diagnostic, to omit such impls silently (review A's
    proposal for A-1).** Rejected: C++'s own overload resolution completes an
    operand class to rank a candidate, so the predicate would have to reproduce
    `CompleteType`'s whole pipeline — parent scopes, bases, fields, destructor
    and virtual functions — to be exact; and an inexact one is unsafe in the
    unsafe direction, because omitting an impl whose operand class C++ _can_
    form lets C++ pick another impl by a derived-to-base or other conversion,
    B-2's hazard. The class's own diagnostic is what an exported method or
    overload set reports for the same class (M-20, D-OV-18) (amended
    2026-10-14, review fold: A-1). **Adopted at rev 4 in a conservative form**
    (D-OX-9 (3)): nothing it rejects is omitted, an operand it rejects being
    stood for by the deleted operator template, which an operand of any other
    type selects rather than convert for another impl, so its inexactness can
    only reject a C++ use, never redirect one (amended 2026-10-14, review fold:
    RR2-1).
-   **§7 A-13: `const&` operands for exported operators.** Rejected for 0.1: it
    would remove M-25's by-value divergence and D-OX-5's xvalue, but it departs
    from the exported-method mapping D-OX-2 keeps (export.cpp `PassAsConstRef`
    gives `const&` to arrays only, with a TODO about other types), and it would
    not avoid M-20 (e), because a reference to `Holder` from a `Money` still
    makes C++ consider `Holder`'s constructors.
-   **§7 A-14: export the witness-table entry (the interface's signature at the
    impl's specific) instead of the impl function (review A's proposal for
    A-7).** Deferred, not adopted for 0.1: when the signatures differ the entry
    is a thunk that impl checking generates, which `GetImplMemberFunctionId`
    cannot reach by name and whose export path is unexercised; the observable
    difference is the C++ static type and the accepted operand conversions, a
    divergence of D-OX-15's kind, so 0.1 documents and pins it (M-25,
    `signature_from_impl_function`) (amended 2026-10-14, review fold: A-7).
-   **§7 A-15: export impls with no Carbon class among their types (B-3's
    alternative to narrowing).** Rejected for 0.1: the external source answers
    lookups only in Carbon-owned contexts, and such an impl's operands are found
    by argument-dependent lookup in C++-owned namespaces or none (a primitive);
    filed as W-210, outside the narrowed criterion (amended 2026-10-14, review
    fold: B-3).
-   **§7 A-16: keep generic impls invisible to C++ (rev 2's choice), or record
    the conversion it allows as a fifth divergence of D-OX-15 (the re-review's
    alternative for RR-3).** Rejected at rev 3: C++ then selects a concrete impl
    by converting an operand that Carbon resolves to the generic impl (M-28),
    the silent mis-selection B-2 graded a BLOCKER for a result with no C++ form,
    and a deleted operator template prevents it at the cost of 133 lines
    (D-OX-22, M-32) (added 2026-10-14, review fold: RR-3).
-   **§7 A-17: inject the deferred template candidates before the removal pass
    (the public `OverloadCandidateSet::InjectNonDeducedTemplateCandidates`)
    instead of a second pass after `BestViableFunction`.** Rejected: it deduces
    every template candidate, which Clang 21 skips when a non-template candidate
    is a perfect match (SemaOverload.cpp:11641-11661), so Carbon's lookup would
    instantiate templates that trunk never instantiates, each of them memoized
    (M-33); the second pass runs only when a deleted template's specialization
    was viable, and resolves the candidates Clang itself formed (added
    2026-10-14, review fold: RR-3).
-   **§7 A-18: keep rev 3's flag beside the non-diagnosing exports (rev 3's
    resolution of RR-2, which made t4 and o3 print trunk's `7` and `1`).**
    Rejected at rev 4: the flag hides the exports from the deductions of
    Carbon's own operator lookup only, so the same C++ question,
    `HasPlus<Money>`, gets one answer in a template's signature and another in
    its body (t4 against a1), and a trait keeps whichever answer came first
    (t1 against t3, M-33); one `PerformPendingInstantiations` loop
    instantiates a1's Carbon-selected `operator+<Money>` and cx1's C++
    `Sum<Money>`, which no scope can tell apart (D-OX-21). If the leads
    require Carbon-only programs to lower exactly as on trunk, the mechanism
    must classify each instantiation by origin, which Clang does not record
    (added 2026-10-14, review fold: RR2-1, RR2-2). Rev 4 also concluded that
    t4's and o3's `7` and `1` could only come back with such a mechanism, which
    RR3-B2 showed false: resolving first with the exported operators present
    and leaving an exactly matching one to Carbon's impl lookup gives t4, o3
    and e2 their trunk values and a1 to a6 C++'s, with no flag (D-OX-11, M-41);
    the mechanism remains the only way to give the rule's consequences of
    R-11 their trunk values (amended 2026-10-14, review fold: RR3-B2).
-   **§7 A-19: for an exported operator that C++ reaches only by converting an
    operand, let Carbon's operator expression call it (`v8e`), or leave the
    expression to Carbon's impl lookup as for an exact match.** Rejected at
    rev 5 (M-42 (b)): calling it lowers a Carbon operator expression through
    the exported operator and its thunks, which D-OX-11 exists to exclude,
    applies C++'s operand conversions to a Carbon impl, and changes which
    function a program that trunk accepts calls (f9b, `102` to `7`); leaving it
    to the impl lookup rejects f9b, which trunk accepts. The boundary that
    remains, a template that C++ ranks below such an export and that the
    export makes viable (f3), is stated in D-OX-21 with its evidence (added
    2026-10-14, review fold: RR3-B2).

## §8 Verification and discharge

`$CB` below is the carbonbuild script directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild`
(not in the repository; its README.md documents it), and `$OUT` a fresh output
directory under the implementer's scratch (amended 2026-10-14, review fold:
B-12).

1.  Build and install this worktree (a full build; the planner and the fixer
    relinked only, so the first full build is the implementer's):
    `$CB/build.sh /home/user/carbon-ox` then `$CB/install.sh
    /home/user/carbon-ox`, whose `carbon version` is stamped with the head.
2.  Fill (commit 4): `$CB/autoupdate.sh /home/user/carbon-ox
    toolchain/check/testdata/interop/cpp/class/export/operator.carbon
    toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon
    toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon
    toolchain/lower/testdata/interop/cpp/class/export/operator.carbon`, three
    times; the third run changes nothing (R26). Then `$CB/gate.sh
    /home/user/carbon-ox`: the trunk count plus four (`1942+4=1946` files at
    f67ab650d), all passing.
3.  Self-test: `python3 fork/conformance/runner.py --self-test` passes after
    `python3 fork/conformance/runner.py --update-readme-table`.
4.  Conformance (commit 5's quote): `XDG_CACHE_HOME=$OUT/cache
    $CB/conformance.sh /home/user/carbon-ox $OUT/conf`: 135 / 0 / 21 over 156,
    49/56 on this branch alone.
5.  The mutants of M-14, rebuilt from the implemented export.cpp with the
    planner's relink recipe (`$F/bin/relink.py <dir>
    obj/toolchain/check/cpp/export.cpp.o=<mutant source>` plus the build's own
    generate_ast and operators objects, `TARGETS=bin/carbon-busybox`; a
    relink of a change to check/cpp/context.h also recompiles
    obj/toolchain/check/cpp/context.cpp.o, which defines `CppContext`'s
    constructor) or by a second full build, each run with `--filter
    cpp_operator_export`: each must fail the programs M-14 names (rev 3
    rebuilt them from `v6`, rev 4 from `v7` and rev 5 from `v8`, M-14; the
    context.cpp clause amended 2026-10-14, review fold: RR2-5).
6.  The probes of M-9, M-10 and M-20 to M-30 (`$F/probes/list3.txt`, with
    `$F/bin/probe.sh <install> <cache> <out> $(cat $F/probes/list3.txt)`), and
    those of M-31 to M-36 (`$G/probes/RR`, `G`, `S` and `W`, with
    `$G/bin/probe.sh`), and those of M-37 to M-39 (`$K/lists/single.txt`,
    `atk.txt` and `x.txt` with `$K/bin/probe2.sh <install> <cache> <out>
    <list>`, and `$K/bin/multi.sh <install> <cache> <out>`): each prints what
    §0.2 says, `$K/runs-*-v7.log` being rev 4's results; and those of M-41
    and M-42 (`$Z/lists_v8.txt`, a superset of every list above, with
    `$Z/bin/prun.sh <install> <cache> <out> <list>`), `$Z/runs-all-v8.log`
    being rev 5's results (amended 2026-10-14, review fold: RR-1 to RR-6,
    RR2-1, RR2-2, RR3-B1, RR3-B2).
7.  prek: before each commit, to a fixpoint (a run that changes nothing), with
    R31's heading and list-item counts before and after for every `.md`:

    ```bash
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest \
      uvx prek run --files <that commit's files>
    ```

    and before hand-over, the same with `--all-files` in place of `--files ...`,
    to a fixpoint (R25).
8.  On the merge commit of §3, before commit 6: steps 1, 2 (`gate.sh` only, and
    an autoupdate commit if it is red), 3, 4 and 6 again; commit 6 quotes this
    run, and the id re-scan of the head is run last.

Not run, and why: no hosted gate, autoupdate or conformance (Actions is
disabled, R28); no `bazel test` (no Bazel in the container); no clangd-tidy
(not installed); no run of the programs on macOS; the multi-file thunk-symbol
question (W-204's note) cannot be exercised until W-203 is fixed.

## Hand-off notes for the implementer

-   §2.1 to §2.4 is a measured diff: apply it (`git apply`) rather than
    retyping, check the four sha256 sums §2.1 lists, and keep it identical
    unless a review finding changes it (amended 2026-10-14, review fold:
    RR2-1).
-   The previews used substituted file names; the real files' `[[@TEST_NAME]]`
    and TIP lines differ, which is why the fill must run on the real paths.
-   `$F/probes/list3.txt` (69 programs) with `$F/bin/probe.sh` is the quickest
    regression set for an implementation-review finding; `$F/runs-trunk3.log`
    and `$G/runs-fx-v6.log` are the expected results (rev 2's `$F/runs-v5f.log`
    differs in `e1_generic` and `v_generic_conv` only), and rev 3's own probes
    (`$G/probes/RR`, `G`, `S`, `W`; `$G/runs-rr-trunk.log`, `$G/runs-rr-v6.log`
    and M-31 to M-36) cover the deferred deduction, the deleted templates, the
    deleted `!=`, detections and the namespace order (amended 2026-10-14, review
    fold: RR-1 to RR-6); rev 4's lists, `$K/lists/single.txt` (105 programs),
    `atk.txt` (25) and `x.txt` (10), with `$K/runs-*-{trunk,v6,v7}.log`, are
    the regression set for D-OX-9's predicate, D-OX-12's re-asking and the
    rule of D-OX-21 (amended 2026-10-14, review fold: RR2-1, RR2-2); rev 5's
    `$Z/lists_v8.txt` (185 programs, every earlier list's among them) with
    `$Z/runs-all-{trunk,v7,v7x,v8}.log` is the regression set for both, the
    recognized types and the exact-match rule of D-OX-11 (amended 2026-10-14,
    review fold: RR3-B1, RR3-B2).
-   Clang's deferral of template deduction into `BestViableFunction` (§0.1
    row 15) is part of the second removal pass's contract, the deleted
    templates are built outside the parser (R-10), and D-OX-12 relies on the
    external-declarations bit (R-5): at any LLVM update, re-run M-31's, M-32's
    and M-39's probes (added 2026-10-14, review fold: RR-1, RR-3; amended
    2026-10-14, review fold: RR2-1).
-   `CanExportClassWithoutDiagnostic` mirrors the class export code, and
    `MapsByExportingClass` mirrors which recognized kinds type_mapping.cpp's
    `TryMapClassType` maps by exporting a Carbon class; a change to
    `ExportClassToCpp`, `ExportNameScopeToCpp`, the specific export,
    `CompleteType` or `TryMapClassType`'s recognized arms must be mirrored
    there, while the other recognized kinds, `MapResultArgToCppType` and the
    header lookups (`LookupCppType`, `LookupCppClassTemplate`) are mapped, not
    mirrored (R-9; added 2026-10-14, review fold: RR2-1; amended 2026-10-14,
    review fold: RR3-m1).
-   The re-reviewer's Carbon-only `ne_deleted_eq_carbon_only.carbon` aborts in
    lowering on trunk too (M-34): a pre-existing defect, not OX-1's, unfiled
    because OX-1 has no id left; report it to the orchestrator, who may assign a
    block for it (added 2026-10-14, a fixer observation). So does M-42's
    `f8b_conversion_handwritten_carbon_only`, a Carbon call of a hand-written
    C++ `operator+(const Carbon::Money&, long)` through a C++ `operator int()`,
    which aborts in lowering (`handle_call.cpp:984: args_ok`) on trunk too
    (added 2026-10-14, a fixer observation).
-   Watch R31 in every markdown edit: §1.8 and §2.8 hold arithmetic and code
    spans that a reflow could push to a line start, and the page's two
    table-of-contents markers (§2.7) must be written on the page only.
-   Nine of the ten reserved ids are used; W-205 stays reserved and unused,
    and is never reused; a new residue needs a new block from the orchestrator
    (the head; amended 2026-10-14, review fold: RR2-1).
-   If DD-1 has merged when OX-1 merges trunk, apply §6.2.1's three
    replacements in the merge and drop the amendment block of §2.7.

## Review fold record (rev 2, 2026-10-14)

Every finding of the two rev 1 reviews, its grade, its disposition and where it
is folded. Review A (toolchain soundness) returned REJECT with 1 BLOCKER, 5
MAJOR and 4 MINOR findings; review B (concreteness, process and
cross-workstream) returned REJECT with 2 BLOCKER, 3 MAJOR and 7 MINOR. All 22
are folded and none is rejected outright; A-1 is folded partly by a route other
than the one proposed, with its evidence (R17), and A-7 takes the second of the
two routes its finding offers. Review A's ids are cited as A-1 (its B-1),
A-2..A-6 (its M-1..M-5) and A-7..A-10 (its m-1..m-4), review B's as B-1..B-12
(its OX-B-1..OX-B-12), so that none reads as a measurement; the rejected
alternatives of §7 are always cited as "§7 A-n". The fixer re-opened every cited
location (f67ab650d; DD-1 at fcee90d9b; trunk 44761146d; upstream/trunk
66a250ad9; the SemaOverload.cpp, DeclBase.cpp and markdown_toc.py sources cited)
and re-ran every measurement a finding is about in its own scratch tree (`$F`),
on the trunk install, the planner's `v4` and the rev 2 prototype `v5`; each
reproduction is the §0.2 entry the table names. Rev 2 changes §2.1 to §2.4
(`v5`), §2.5 (a fourth golden and 23 splits) and §2.6 (two programs re-encoded,
two headers), so M-7, M-8, M-12, M-13, M-14, M-16, M-18 and M-19 were re-run and
M-20 to M-30 added; every number those changes could move was re-measured, and
every other number of rev 1 stands as measured.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| A-1 (review A's B-1): D-OX-9's silent omission is not silent; export-time TODOs reject Carbon-only programs, and an unrelated impl breaks a valid C++ use | BLOCKER | Reproduced (M-20: (a) to (d) and (f) compile on trunk, fail on `v4` with the TODOs review A names; (e) and (g) fail on `v4`). Folded: Carbon's own lookup exports nothing (D-OX-21, review A's fix 4 and §7 A-8 adopted), so (a)-(d) and (f) compile; the walks select impls by interface, operator and `Self` from SemIR before any mapping (fixes 2 and 3), so (g) compiles; `IsOperatorSignatureMappable` is replaced by `ClassifyOperatorExport`, whose `IsUnmappableWithoutExport` maps no class or function type (fix 1 in part); the shapes are pinned (fix 5) and M-8, M-12, M-13 re-run (fix 6). Folded by another route for (e): the class is exported and its own TODO stands, as on trunk for an exported function taking `Holder` (`v_trunk_holder_fn1.carbon`) and as OV-3 landed it (D-OV-18), because C++ overload resolution itself completes the operand class, and the exact SemIR predicate fix 1 proposes would have to reproduce `CompleteType`, while an inexact one could let C++ select another impl by conversion (§7 A-12); pinned by `fail_todo_unexportable_operand_class`. Re-opened by the focused re-review as RR-1 (fix 4's "Carbon's own lookup exports nothing" was false on `v5`: Clang's deferred deduction ran after the flag was cleared) and folded at rev 3 (amended 2026-10-14, review fold: RR-1) | Head (Outcome, V-3); §0.1 rows 6, 9; §0.2 setup, M-9, M-20; D-OX-3, D-OX-4, D-OX-9, D-OX-16, D-OX-21; §1.2; §1.5; §1.6; §2.1; §2.5 (`carbon_side_unexportable_class`, `carbon_side_generic_class`, `carbon_side_unrelated_impl`, `cpp_side_unrelated_impl`, `fail_todo_unexportable_operand_class`); §2.7 page; §4; §7 R-1, R-9, A-7, A-8, A-12 |
| A-2 (review A's M-1): the default `!=` aborts the compiler for a non-copyable operand; C++20's `==` triggers it | MAJOR | Reproduced (M-21: `n1` aborts `v4` at export.cpp:2152, `n2` aborts it under `-std=c++20`). Folded as proposed: the arguments are xvalues (`ImplicitCastExpr <NoOp>` to `xvalue`), the three `CARBON_CHECK`s are a diagnostic-free bail under a `Sema::SFINAETrap` that removes the declaration; `move_only_not_equal` (C++17) and the new golden operator_cxx20.carbon's `move_only_equality` (C++20) pin it; `v_ne_nocopy_run.carbon` prints `10 1` in both dialects. D-OX-6's C++20 claims are pinned there too | §0.2 M-6, M-21; D-OX-5, D-OX-6; §1.3; §2.1; §2.5; §4 |
| A-3 (review A's M-2): the guard acts only on `OR_Success`; trunk-accepted programs become ambiguous, one Carbon-only | MAJOR | Reproduced (M-22: `u2` and review B's `gen`, `enum`, `amb` ambiguous on `v4`, `1042`/`3` on trunk; `userop` shows `v4` also changed which C++ function Carbon would call). Folded by fix 1's preferred route: no export during Carbon's lookup (D-OX-21) plus marking exported operators non-viable before `BestViableFunction` (D-OX-11), so every result equals Clang's without them; `u2`, `gen`, `enum`, `amb` and `userop` match trunk on `v5`. Fix 2: the C++-only `u1` is filed as W-211 with the page's migration note and `fail_user_cpp_operator_ambiguous`. Fix 3: D-OX-11, R-3 and the page corrected | §0.2 M-10, M-22; D-OX-11, D-OX-16; §1.5; §1.7; §1.10 W-211; §2.1; §2.5; §2.7 page ("Carbon operator expressions are unchanged", "Hand-written C++ operators"); §2.8 W-211; §7 R-3 |
| A-4 (review A's M-3): a Carbon-only expression poisons later C++ lookups | MAJOR | Reproduced (M-23: `o1` rejected, `o2` accepted on `v4`). Folded as proposed (§7 A-8 adopted): during Carbon's lookup the arm erases the empty entry `lookupImpl` created, as e476a2bd3 does; `o1` compiles on `v5`; `carbon_side_then_cpp` pins it; W-205, D-OX-12 and the page say only C++ code's lookups are cached | §0.1 row 14; §0.2 M-23; D-OX-12, D-OX-21; §1.2; §1.5; §2.1; §2.5; §2.7 page; §2.8 W-205; §7 R-5 |
| A-5 (review A's M-4): no non-member export for a nested operand class | MAJOR | Reproduced (M-24: `50 - Carbon::Outer::Inner::Make(8)` is `invalid operands` on `v4`). Folded as proposed: the namespace test is `getEnclosingNamespaceContext()->Equals(namespace)`; `v_nested.carbon` prints `42 42 42` on `v5`; `non_member_nested` pins it, so D-OX-14's break condition no longer fires on it | §0.2 M-24; D-OX-3; §1.2; §2.1; §2.5; §2.7 page |
| A-6 (review A's M-5): D-OX-18 cites the wrong milestone line and is contradicted by README.md:3679-3681 | MAJOR | Reproduced (milestones.md:169 is a loops bullet; :200 is under "#### Standard library components"; README.md:3679-3681 maps `ImplicitAs` to C++ conversions in the same section). Folded by the first route: the row is recorded PARTIAL now, bounded by W-208; D-OX-18 is rewritten, citing :200 correctly as not bearing on the scope; every :169 citation is gone | Head (Criterion, Outcome, design authority, V-3); §0.3, closing paragraph; D-OX-1, D-OX-14, D-OX-18; §1.5; §1.10; §2.7 page ("Conversions"); §2.8 row, header, W-208; §7 R-7, A-9, A-11 |
| A-7 (review A's m-1): exported operators use the impl function's signature; the docs and §1.1 are wrong | MINOR | Reproduced (M-25: `s1` prints `42 1`, C++ `decltype(m+1)` is `int` against Carbon's `i64`; `v_noncopy_lvalue.carbon` rejected in C++, accepted in Carbon). Folded by the proposal's second route: §1.1, D-OX-2, the page's table and mapping text say "the impl function as declared"; D-OX-15 gains the signature and by-value divergences; `signature_from_impl_function` and `fail_noncopyable_lvalue_operand` pin them; §1.7's "rejects nothing" corrected. The first route, exporting the witness entry, is §7 A-14, deferred with its reason | §0.2 M-5, M-25; D-OX-2, D-OX-15; §1.1; §1.7; §2.5; §2.7 page; §7 A-13, A-14 |
| A-8 (review A's m-2): the compare program cannot tell several operators apart | MINOR | Reproduced (rev 1's pairs give `10` for the listed swaps). Folded as proposed: 100·(a op b) + 10·(a op a) + (b op a), EXPECTs `10 101 100 110 1 11 0` re-derived by hand before any run; the nonmember program's comparisons re-encoded the same way (six lines); M-14's third mutant (`!=`/`<` rows swapped) is caught (compare COMPILE-FAIL, nonmember OUTPUT-MISMATCH) | §0.2 M-14; D-OX-17; §1.8; §2.6 |
| A-9 (review A's m-3): only the C++ half of the conversion divergence is pinned | MINOR | Reproduced (`e13b` pinned nowhere). Folded as proposed: `fail_conversion_carbon_side`; the arithmetic and index program headers cross-reference the divergence goldens | §0.2 M-11; D-OX-15; §2.5; §2.6 |
| A-10 (review A's m-4): stale or inexact measurement and record claims | MINOR | Reproduced (the embedded diff did not hash to rev 1's sha256; pass 2 changed both check goldens; heads moved; DD-1 mentions the reservation; VA-1 unassessed). Folded as proposed: the hash restated as the diff file's, with the five files' sums as the identity check; M-12 restated (at rev 2 pass 2 changes all four goldens); M-16, M-18 and §6.2 re-measured at the 2026-10-14 heads; VA-1's files assessed (none of OX-1's five, none of W-007's three) | Head (Status, Id allocation); §0.2 M-12, M-16, M-18; §2.1; §6.2 |
| B-1: the guard is unsound: Carbon-only code rejected, and Carbon's `!=` goes through an exported operator | BLOCKER | Reproduced (M-22 `gen`, `enum`, `amb`; M-26: `ne.carbon` lowered through `_ZN6CarbonneE3FooNS_5MoneyE.carbon_thunk.__` on `v4`). Folded as proposed: exported candidates are non-viable before `BestViableFunction` (D-OX-11); the default `!=` is registered in `clang_decls`, so it is recognized; and Carbon's lookup exports nothing (D-OX-21). `ne.carbon`'s `CarbonNe` lowers identically to trunk; the lower split `carbon_side_default_not_equal` (after C++ code exported the default `!=`) and the check splits `carbon_side_candidates` pin it; M-8 is restated as covering existing goldens only. Re-opened by the focused re-review as RR-2 (a C++ template made viable by an operator exported during the deferred deduction) and folded at rev 3 (amended 2026-10-14, review fold: RR-2) | §0.1 row 9; §0.2 M-8, M-9, M-10, M-22, M-26; D-OX-5, D-OX-11, D-OX-21; §1.3; §1.7; §2.1; §2.5; §4; §7 R-1 |
| B-2: D-OX-9's argument is false for a result-only unmappable impl; C++ silently selects another impl | BLOCKER | Reproduced (M-27: `sel.carbon` prints `5 1000` on `v4`). Folded as proposed: an operand with no C++ form is omitted; a result with none (or an array) is a deleted declaration with a `void` result, so `sel.carbon`'s C++ use is `overload resolution selected deleted operator '+'`; `fail_deleted_result`, `deleted_result_unselected` and the AST golden's deleted `operator*` pin it; D-OX-9, its break condition, §1.6, the page and the golden comments rewritten, D-OV-18 cited. The fixer found the same hazard for a generic impl (M-28) and kept it on the premise that no deleted declaration can cover it, which the focused re-review showed false (RR-3): at rev 3 a deleted operator template covers it (D-OX-22) and `generic_impl_hidden` is `generic_impl`; the re-review found B-2 itself RESOLVED (amended 2026-10-14, review fold: RR-3) | Head (design authority, V-3); §0.2 M-27, M-28; D-OX-9; §1.5; §1.6; §1.10 W-202; §2.1; §2.5; §2.7 page; §2.8 W-202; §4 |
| B-3: impls in the file on C++ types are not exported and not filed; D-OX-14's break condition fires | MAJOR | Reproduced (M-29: `foreign.carbon` fails on trunk, `v4` and `v5`). Folded as proposed: the criterion is narrowed to impls whose `Self` or operand is a Carbon class C++ sees as a record (README.md:3666); W-210 filed (impls with no Carbon class among their types, unary ones on C++ types included), pinned by `fail_todo_non_carbon_operands`, in §1.5, the page's 0.1 limits and the row; D-OX-4 and D-OX-14 decide against the narrowed criterion (with A-6, PARTIAL) | Head (Criterion, Id allocation); §0.2 M-29; D-OX-4, D-OX-14; §1.5; §1.10; §2.5; §2.7 page; §2.8 row, W-210; §7 A-15 |
| B-4: D-OX-18 is miscited and quotes its authority selectively | MAJOR | Reproduced (as A-6; also p000845:184-187 and operators.cpp:42-52). Folded with A-6: milestones.md:200 cited correctly, README.md:3679-3681 and p000845:184-187 quoted in the design-authority list and on the page, the exclusion argued and the row recorded PARTIAL; the scope question is named in D-OX-14's and D-OX-18's break conditions for the re-review and the leads to rule on | Head (Criterion, design authority, V-3); D-OX-14, D-OX-18; §2.7 page; §2.8 W-208; §7 R-7, A-11 |
| B-5: no merge of trunk or post-merge re-verification is scheduled; the records depend on one | MAJOR | Reproduced (§3 had commits 1-6 only; f67ab650d's ORCHESTRATION has no `-ox` row, 44761146d's has; the records cited an amendment §6.2.1 drops; PR 55 and PR 57 change the prelude). Folded as proposed: §3 gains "Between commits 5 and 6" (two implementation reviews, a separate R11 fixer in new commits, refills as their own commits) and "The merge of trunk" with its resolution rules; §8.8 re-verifies the merge commit and commit 6 quotes it; the ORCHESTRATION row is edited on the merge commit; the ledger cites the README text as it stands at the merge commit; §6.2 records the PR 55 and PR 57 prelude paths | D-OX-19; §1.9; §2.8 (row, header, ledger, ORCHESTRATION, README table); §3; §5; §6.2; §8 |
| B-6: M-12 undercounts the positive splits that fail on trunk | MINOR | Reproduced (14 failures, 13 names: `non_member` is a split of two goldens). Folded: at rev 2, 23 failures, 22 names, the lower `non_member` listed, the duplicate name explained | §0.2 M-12 |
| B-7: the "byte for byte" sha256 claim is false for the embedded diff | MINOR | Reproduced (rev 1's embedded text hashed to f4ee6267…). Folded as proposed: the embedded diff is described as prek-normalized, and the five resulting files' sha256 are the identity check (verified by applying the embedded copy) | Head (Status); §2.1 |
| B-8: stale collision heads; the id re-scan cannot tell a mention from an allocation; a row cited by line | MINOR | Reproduced (OP-2 628273444, DD-1 then 6b692aa14 and now fcee90d9b, SC-1 then ae807c7e8 and now 0d7ee5c19; DD-1's four files mention the reservation; D-OX-14 named "row 82"). Folded as proposed: §6.2 and M-16 re-measured; "taken" is mechanical (a ledger `"id"` or an F-017 decision heading on another ref) and the commands print allocations and mentions separately; D-OX-14 names no row by number | Head (Id allocation); §0.2 M-16, M-18; D-OX-14; §6.2 |
| B-9: the merge-time edit leaves DD-1's "implements the first direction" stale | MINOR | Reproduced (fcee90d9b:1113-1116). Folded as proposed: a third replacement, "The 0.1 toolchain implements both directions. In the first, ...", which also says an exported Carbon operator is not a candidate; R31 counts at the merge | §0.3 item 8; D-OX-19; §3; §6.2.1 |
| B-10: the conversion divergence is pinned on the C++ side only | MINOR | Reproduced (as A-9). Folded with A-9: `fail_conversion_carbon_side`, cited in D-OX-15 and on the page | §0.2 M-11; D-OX-15; §2.5; §2.7 page |
| B-11: the design authority omits p006254, whose mechanism the guard modifies | MINOR | Reproduced (p006254:210-216, "Operator calls"). Folded as proposed: cited in the design-authority list, V-3 and D-OX-11, and on the page, which says why an exported impl is not a C++ operator function | Head (design authority, V-3); D-OX-11; §2.7 page |
| B-12: process steps missing or not concrete | MINOR | Reproduced (no `--all-files` pass; no R11 fixer or no-amend rule; no script paths or arguments; no V-3a entries; no toc lines). Folded as proposed: §8 gives `$CB`'s path and every command with its arguments, and a `--all-files` fixpoint before hand-over; §3 names the separate fixer and forbids amending; §2.8's decision-log entry lists four V-3a register entries; §2.7 gives the page's two marker lines by the command that prints them, because prek's `markdown-toc` hook would rewrite the text between a literal pair in this plan (its source cited) | §2.7; §2.8 decision log; §3; §8 |

Corrections the fixer made that no review raised, found while re-measuring: rev
1's `IsExportedCarbonOperator` treated every overloaded-operator member of a
Carbon-owned record as exported, which also matches Clang's implicit members
(`operator=`), so `v5` recognizes exactly the `clang_decls` registrations (§0.3,
closing paragraph); rev 1's M-11(c) and W-205 described C++-only caching, which
after A-4's fold is the whole of it; the ledger maximum moved from W-232 to
W-234 during the fold (SC-1 round 10), and DD-1's head from 6b692aa14 to
fcee90d9b, at which §6.2.1's three sentences were re-read; trunk moved to
3eb7f36f0, whose stamp makes DD-1 PR 58, puts OX-1 after it and gives SC-1
W-233..W-239 and DD-1 W-240..W-244, which the head, D-OX-19, §3 and §6.2 now
cite; and with W-210 and W-211 filed, all ten reserved ids are used, so the head
says what a further residue needs.

### Focused re-review (rev 3, 2026-10-14)

The focused re-review of rev 2 (7d71f02b3) returned **REJECT** with 2 BLOCKER, 1
MAJOR and 3 MINOR findings. It relinked rev 2's embedded diff (its five sha256
sums matched §2.1) as `$RR/install-rr`, reproduced the fixer's 69 probes
exactly, and found review A's B-1 and review B's OX-B-1 (A-1 and B-1 here) not
resolved, review B's OX-B-2 (B-2) resolved, and four new findings; it edited no
repository file. This plan cites its findings as RR-1 to RR-6, below. All six
are folded and none is rejected. The rev 3 fixer re-opened every cited location
(SemaOverload.cpp :8384-8403, :11559-11584, :11641-11661, :13604-13623 and
:11679; the plan's lines; fork/decision-log.md :3595-3606) and re-ran each
measurement a finding is about in its own trees, `$G` and `$H` (head), on the
trunk install, rev 2's `v5` (`$F/install-v5`, `$F/tc/v5f`), the re-reviewer's
`$RR/install-rr` and `$RR/install-v5b` where cited, and the rev 3 prototype
`v6`; each reproduction is the §0.2 entry the table names. Rev 3 changes §2.1 to
§2.4 (`v6`), §2.5 (eight new splits, one renamed and rewritten, the AST golden
extended) and no program, so M-8, M-12, M-13, M-14, M-16, M-18, M-19, M-28 and
M-30 were re-run and M-31 to M-36 added. The verdict was REJECT, so rev 3 is not
signed off (the head's Status): whether RR-1's and RR-2's fold resolves them is
the next re-review's to confirm.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| RR-1 (the re-review's B-1, re-opening A-1): D-OX-21 ends before `BestViableFunction`, where Clang 21 runs deferred template deduction, so a Carbon-only operator expression still exports and an unrelated unexportable impl rejects it | BLOCKER | Reproduced (M-31: on `v5`, `o2_optional_holder` and `t5_carbon_only_holder` fail with `Holder`'s TODO where trunk prints `0` and `7`; the cited Clang lines re-read, §0.1 row 15). Folded as proposed: `LookupOverloadedBinOp` and `BestViableFunction` run inside one `SaveAndRestore` (the re-reviewer's `operators-scope.diff`, clang-formatted); D-OX-21 restated to cover overload resolution, and Clang's deferral added to R-5's contract; pinned by `carbon_side_deferred_template` (t5's shape, an inline SFINAE template operator, no std header; it fails on `v5`) and the lower `carbon_side_template_candidate`; M-8, M-12 and M-13 re-measured on `v6` (1942 passed; three passes, 4 passed; 135 / 0 / 21) and R-1's falsifier re-run (`o1` to `o3`, `t4` and `t5` as on trunk; five modules' function definitions identical to trunk's) | Head (Status, Outcome); §0.1 row 15; §0.2 M-8, M-9, M-12, M-13, M-31; D-OX-11, D-OX-16, D-OX-21; §1.2; §1.7; §2.1; §2.5; §2.7 page; §2.8; §3; §4; §7 R-1, R-5, A-8 |
| RR-2 (its OX-B-1, re-opening B-1): Carbon's own `==` still resolves to a C++ function made viable by an exported operator, and lowers through that export | BLOCKER | Reproduced (M-31: on `v5`, `o3_optional_observable` prints `0` and `t4_carbon_only` `102`, where trunk prints `1` and `7`). Folded as proposed: the same scope change, after which `o3` prints `1`, `t4` `7`, and `o1`'s, `o3`'s and `t4`'s modules have trunk's function definitions; pinned by the lower `carbon_side_template_candidate` (t4's shape without a std header: its Carbon side calls the Carbon impl, where `v5`'s called the template's thunk); D-OX-11, §1.7, the page's "Carbon operator expressions are unchanged", the row's evidence and W-054's title restated to what holds: Carbon's lookup, its deferred deductions included, exports nothing, and a template C++ code instantiated against an exported operator keeps that state (RR-4) | Head (Outcome); §0.2 M-10, M-26, M-31; D-OX-11; §1.7; §2.5; §2.7 page; §2.8 (row, W-054); §4 |
| The re-review's disposition of review B's OX-B-2 (B-2 here) | — | RESOLVED by the re-review (`sel.carbon` is rejected with `overload resolution selected deleted operator '+'`); `v6` prints the same; its contrived gap through the default `!=` is RR-5 | §0.2 M-27 (unchanged) |
| RR-3 (its RR-M-1): M-28's silent mis-selection for generic impls is kept on a false premise; a deleted function template covers it | MAJOR | Reproduced (`$RR/dt.cpp` re-compiled with the trunk install's clang: deleted for an `int`, the non-template for a `long`; `v_generic_conv` prints `1 2` on `v5`). Folded as proposed, with an addition the finding did not foresee: one deleted member template per operator for the generic impls whose `Self` is the class and one non-member template per operand class for the others (D-OX-22), recognized by `IsExportedCarbonOperator` through `getPrimaryTemplate()`; and, because Clang deduces the specialization inside `BestViableFunction`, after the existing removal, a second removal pass and resolution after it, without which Carbon's own `m * f` after a C++ use is rejected (`n1`, M-32). `generic_impl_hidden` became `generic_impl`, two `fail_generic_impl_conversion` splits pin both forms, and M-28, W-202's notes and the rev 2 fold record are corrected | Head; §0.2 M-11, M-19, M-28, M-32; D-OX-4, D-OX-9, D-OX-22; §1.1; §1.2; §1.5; §1.6; §1.10; §2.1; §2.5; §2.7 page; §2.8 (row, W-202, decision log); §4; §7 R-10, A-16, A-17 |
| RR-4 (its RR-m-1): memoized template state still crosses the Carbon/C++ boundary after the scope fix; D-OX-21's break condition and D-OX-11's "every `OverloadingResult`" are falsified | MINOR | Reproduced (M-33: on `v6`, `t1` prints `7 0`, `t2` `1` and `t3` `102 1`, where trunk prints `7 0` for `t3`). Folded as proposed: D-OX-11, D-OX-21, §1.7 and the page are qualified for memoized instantiations, and W-205 is extended (no new id: its subject is what C++ code sees after earlier lookups, so no block was needed from the orchestrator); `todo_carbon_side_memoized_trait` pins `t1`'s order (and fails on `v5`) | Head (Id allocation); §0.1 row 15; §0.2 M-33; D-OX-11, D-OX-12, D-OX-21; §1.5; §1.7; §1.10; §2.5; §2.7 page; §2.8 W-205 |
| RR-5 (its RR-m-2): the default `!=` is dropped when `operator==` is declared deleted, so C++ `!=` converts to another impl | MINOR | Reproduced (M-34: `ne_deleted_eq2` prints `0 1` on `v5`, Carbon `0`, C++ `1`). Folded as proposed: beside a deleted `operator==` the default `!=` is declared deleted, with `operator==`'s `void` type, and registered; `fail_deleted_result_not_equal` pins it | §0.2 M-34; D-OX-5, D-OX-9; §1.3; §1.5; §1.6; §2.1; §2.5; §2.7 page; §2.8 row; §4 |
| RR-6 (its RR-m-3): D-OX-9 (3)'s class-export TODO is a hard error in a SFINAE detection that trunk accepts, and the plan does not say so | MINOR | Reproduced (M-35: `sfinae_detect` prints `0` on trunk and fails on `v5` and `v6`); trunk's own type export fails the same way for a detection of an exported function (`s1_trunk_sfinae_fn`). Folded as proposed: D-OX-9 (3), §1.6, R-9 and the page say that a detection is a use, where the TODO is a hard error; `fail_todo_sfinae_detection` pins it; the optional residue is not filed, the hard error being the type export's own, as on trunk | §0.2 M-35; D-OX-9; §1.5; §1.6; §2.5; §2.7 page; §4; §7 R-9 |

Corrections the rev 3 fixer made that no review raised, found while
re-measuring: the non-member walk keeps only impls whose operand class C++ has
already exported, so a namespace's first `operator*` lookup before C++ names
`Euro` leaves `Euro`'s non-member operator out for good (M-36, pre-existing in
`v5`; found when a first draft of `fail_generic_impl_conversion` put a member
and a non-member use in one split), filed by extending W-205 and pinned by
`fail_todo_non_member_before_operand`; rev 2's M-12 said no other split had a
diagnostic, but `carbon_side_candidates` has two unused-binding warnings in both
revisions' fills (M-12); the first `v6` link crashed in `Sema::SubstParmVarDecl`
because the template's parameters had no type-source info (R-10); the
re-reviewer's `ne_deleted_eq_carbon_only.carbon` aborts in lowering on trunk
too, a pre-existing defect left to the orchestrator (M-34, the hand-off); SC-1's
head moved to 444ccbafe and VA-1's to be623188d, at which the diff and the id
scan were re-run (M-16, M-18); and because the root file system had under 60 MB
free, the rev 3 binaries, mirrors and caches were kept on a tmpfs (`$H`) and
only compact evidence under `$G`.

### Second focused re-review (rev 4, 2026-10-14)

The second focused re-review, of rev 3 (fd324a642), returned **REJECT** with 2
BLOCKER and 3 MINOR findings. It applied rev 3's embedded diff (its five
sha256 sums and its +920/−6 matched §2.1), relinked `v6` with context.cpp
recompiled, reproduced every earlier probe and the fill byte for byte, and
found rev 3's fold of RR-1 not resolved, RR-2 resolved only in its narrow
form, and the same hazard through Carbon's calls and conversions; it edited
no repository file. This plan cites its findings as RR2-1 (its RR-1-NR), RR2-2
(its NEW-B1) and RR2-3 to RR2-5 (its m-1 to m-3). All five are folded and none
is rejected. The rev 4 fixer re-opened every cited location
(SemaOverload.cpp :8384-8403, :11641-11661, :13440-13475 and :13603-13623;
SemaExpr.cpp :19352-19355; Sema.cpp :1287; DeclBase.cpp :1921-1965 and
:1651-1680; DeclContextInternals.h's `StoredDeclsList`; overload_resolution.cpp
:312; operators.cpp's v6 lines :352, :405, :905, :937, :966 and :980;
generate_ast.cpp :1133; context.cpp :13-15) and re-ran each measurement in its
own trees, `$K` and `$L` (head), on the trunk install, the second
re-reviewer's `v6` and the rev 4 prototype `v7`; each reproduction is the §0.2
entry the table names. Rev 4 changes §2.1 to §2.4 (`v7`), §2.5 (four splits
renamed and one inverted, eleven added, the comments and unused bindings
rewritten) and no program, so M-8 to M-14, M-16, M-18 to M-20, M-22, M-23,
M-26 and M-30 to M-36 were re-run and M-37 to M-40 added. The verdict was
REJECT, so rev 4 is not signed off (the head's Status): whether RR2-1's and
RR2-2's fold resolves them is the next re-review's to confirm.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| RR2-1 (its RR-1-NR, re-opening RR-1): a Carbon-only operator expression still exports, after the flag's scope and in the instantiation it schedules, and is rejected at an unrelated `Holder` or lowers through an export | BLOCKER | Reproduced (M-37: on `v6`, a1 and a4 fail with `Holder`'s TODO where trunk prints `1`, and a2, a3 and a6 print `102`, `10` and `102`; the cited `MarkFunctionReferenced`, fragment-end `PerformPendingInstantiations` and `NoteCandidates` paths re-read). Folded by the route proposed, and one step further: no export can emit a diagnostic, because `ClassifyOperatorExport` checks every class a signature names with a SemIR predicate before anything is mapped, an operand that fails being stood for by the deleted operator template and a result that fails making the operator deleted (D-OX-9 (3), D-OX-22; fix 1); `RemoveExportedCarbonOperators` keeps both passes (fix 2); the Outcome, D-OX-11, D-OX-21, R-1, §1.7, the page's section, the row and W-054 state what holds, a Carbon operator expression never selecting an export and a C++ template seeing the exports whoever instantiates it, and a2, a3, b2 and c2 are documented (fix 3); a1, a3 (lower), a4, b1 and c1 are pinned (fix 4); every probe of every round re-run on `v7` (fix 5, M-37 to M-40). Further than proposed, with evidence (R17): the flag is removed rather than kept beside the new rule, because with it a template's answer depended on whether it was asked in a signature or a body and by which side first (t4 against a1, t1 against t3; §7 A-18), and the lookup cache it protected is replaced by asking again at every lookup (D-OX-12), so `carbon_side_then_cpp` holds without it and W-205 is left with nothing to cover. Consequences stated, not hidden: t4 and o3 select the C++ template again, as on `v5` (M-31), e4 prints `102`, a C++20 reversed candidate is rejected with W-045's TODO (e2, `fail_todo_carbon_side_rewritten_candidate`), and unused Carbon thunks are defined (M-40); R-11 | Head (Status, Outcome, ids, design authority, V-3); §0.1 row 14; §0.2 setup, M-9 to M-14, M-17, M-19, M-20, M-23, M-26, M-31 to M-33, M-35 to M-40; §0.3; D-OX-4, D-OX-9, D-OX-11, D-OX-12, D-OX-14, D-OX-16, D-OX-20, D-OX-21, D-OX-22; §1.1; §1.2; §1.5; §1.6; §1.7; §1.10; §2.1; §2.5; §2.7 page; §2.8 (row, W-054, W-202, W-205, W-007, decision log, ORCHESTRATION); §3; §4; §6.1; §6.3; §7 R-1, R-5, R-9, R-11, A-8, A-12, A-18; §8; hand-off |
| RR2-2 (its NEW-B1): the same hazard through Carbon's call and conversion resolution, which Clang also defers | BLOCKER | Reproduced (M-37: on `v6`, b1, c1 and c3 fail with `Holder`'s TODO where trunk prints `1`, and b2, c2 and c4 print `100`; SemaOverload.cpp:13603-13623 re-read: every kind but `CSK_InitByUserDefinedConversion` and `CSK_CodeCompletion` defers). Folded as proposed, by construction rather than by more scopes: the non-diagnosing exports cover overload_resolution.cpp and `LookupCppConversion` because nothing an export declares can diagnose, whatever lookup builds it (b1, c1 and c3 print `100` on `v7`); §0.1 row 15 corrected; one rule for every template instantiated against a Carbon class, whoever triggers it (D-OX-21); b1 and c1 (with c3) pinned by `carbon_side_call_unexportable` and `carbon_side_conversion_unexportable`, b2 and c2 by the lower `carbon_side_call_template` and `carbon_side_conversion_template` | Head (Outcome); §0.1 row 15; §0.2 M-9, M-12, M-37, M-38; D-OX-11, D-OX-21; §1.7; §2.5; §2.7 page; §4; §7 R-1, R-11, A-18 |
| RR2-3 (its m-1): `FindClangOperator`'s diagnostic arms deduce deferred templates after the scope, export, gain an extra `Holder` TODO and note a template viable only through the export | MINOR | Reproduced (M-37: e6b on `v6` reports `Holder`'s TODO before the deleted-function error, and notes the template as a candidate). Folded by the root cause, as the finding proposes: with no export able to diagnose, e6b's extra TODO is gone on `v7`; and both `NoteCandidates` calls take a filter that leaves exported operators out of the notes, the deferred specializations that `CompleteCandidates` deduces for them included. The template noted as viable is the rule of D-OX-21, not a leak (its notes are trunk's otherwise) | §0.2 M-10, M-37; D-OX-11, D-OX-16; §2.1; §7 R-8 |
| RR2-4 (its m-2): §4's falsifier fires on the plan's own fill: two positive splits and three `fail_` splits carry unused-binding warnings, and M-12 repeats rev 2's oversight | MINOR | Reproduced (the `v6` fill, `/dev/shm/ox1-rr2/fill-v6.snap3`, has ten `UnusedBinding` warnings: the AST golden's `operator`, the lower `generic_impl`, `fail_generic_impl_conversion`, `fail_generic_impl_conversion_non_member`, `fail_deleted_result_not_equal`'s four and `carbon_side_candidates`'s two). Folded by the first route the finding offers: every unused binding is named `_` or marked `unused`, the fill was redone by autoupdate (M-12: no warning in any split, and pass 2 no longer changes the lower golden), and §4's falsifier now admits no diagnostic in a positive split | §0.2 M-12; §0.3; §2.5; §4 |
| RR2-5 (its m-3): the setup's claim that `CppContext` is constructed only in generate_ast.cpp is false, and the measured `v6` never ran the `= false` initializer | MINOR | Reproduced (the constructor is check/cpp/context.cpp:13-15; rev 3's relink log names export, operators and generate_ast only). Folded as proposed: the sentence corrected, and §8.5's relink recipe recompiles context.cpp.o whenever context.h changes; `v7` removes the context.h member, so its relink needs neither | §0.2 setup; §0.3; §2.1; §8.5 |

Corrections the rev 4 fixer made that no review raised, found while
re-measuring: VA-1's local head 275967b1d (its C4 commit) adds a 12-line hunk
to export.cpp's `ExportFunctionToCpp`, a second contender in that W-007 file,
which §6.2, M-16 and W-007's notes now record (the diff applies at offset 12);
SC-1's heads moved to 62e25dcdd; rev 2's and rev 3's M-12 did not list
`fail_user_cpp_operator_ambiguous` among the `fail_` splits that compile on
trunk (it pins an ambiguity only the export creates); and under the swapped
table of M-14's M3, `v7`'s nonmember program fails to compile rather than
print a wrong value, because the default `!=` built during a `<` lookup is not
found again under its own name (M-14).

### Third focused re-review (rev 5, 2026-10-14)

The third focused re-review, of rev 4 (145fdaa62), returned **REJECT** with 2
BLOCKER, 1 MAJOR and 1 MINOR findings. It applied rev 4's embedded diff (its
four sha256 sums and its +1226/−4 matched §2.1), relinked `v7`, reproduced the
134 content-unique single-file probes of every round, the seven multi-unit
probes, M-8 and M-12 byte for byte, wrote 36 programs of its own (`$RR3/p/C`,
`K` and `P`, six of them C++-side programs), prototyped both fixes as `v7x`
(operators.cpp) and `v7y` (`v7x` with the export.cpp fix) with file_test passing
on each, and edited no repository file. Its ids, RR3-B1, RR3-B2, RR3-M1 and
RR3-m1, are kept. All four are folded and none is rejected. The rev 5 fixer
re-opened every cited location (type_mapping.cpp :156-182, :196-372, :260-362;
export.cpp's `v7` classification, :2009-2318; operators.cpp's `v7`
`FindClangOperator`; SemaOverload.cpp :11559-11584 and :11630-11690, the
deferred injection and the perfect-match shortcut) and re-ran each measurement
in its own trees, `$Z` and `$Y` (head), on the trunk install, the re-reviewer's
`v7`, `v7x` and `v7y`, and the rev 5 prototype `v8`; each reproduction is the
§0.2 entry the table names. Rev 5 changes §2.1 to §2.4 (`v8`), §2.5 (eight
splits added, one renamed and made positive, three changed, the comments
rewritten) and no program, so M-8, M-12 to M-14, M-16, M-18, M-19, M-31, M-33,
M-37, M-38 and M-40 were re-run and M-41 and M-42 added. The verdict was REJECT,
so rev 5 is not signed off (the head's Status): whether RR3-B1's and RR3-B2's
fold resolves them is the next re-review's to confirm.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| RR3-B1: RR2-1 not resolved: the non-diagnosing predicate never maps a recognized type, so an impl naming `str`, `Core.Slice` or `Core.Result` without its header is exported and its thunk or field mapping reports the TODO, rejecting Carbon-only programs that trunk accepts | BLOCKER | Reproduced (M-41: on `v7` p1 to p5, p10, p13, p14 and p18 are rejected with the mapping's TODO or the `<carbon/expected.h>` error where trunk prints `7`, `7`, `7`, `7`, `7`, `7`, `4`, `1` and `7`; p1h with the header prints `7`; p1c, the C++ use, is rejected too). Folded by the route proposed, prototyped as `v7y`: `IsUnmappableWithoutExport` maps every recognized type whose mapping exports no Carbon class once the Carbon classes it names pass the predicate, a null mapping omitting an operand's impl, deleting a result's operator and failing a field's class (fix 1); and with the two corrections the fix's own measurement needed (R17): the set of classes in progress is threaded through the mapping, which `v7y` left undone and which overflows the stack for `f2c` (M-42 (a)), and `MapsByExportingClass` unwraps an optional's facet-value argument as type_mapping.cpp does, which `v7`'s predicate missed, refusing f1's `Node` (M-42 (a)). `CanExportTypeWithoutDiagnostic`'s recognized-type switch becomes one loop over the type arguments. The three splits proposed are added, `carbon_side_str_operand_without_header`, `carbon_side_result_without_header` and `carbon_side_slice_field`, with p1c's C++ side as `str_operand_without_header` and f1 as `self_referential_operand`; R-9, the hand-off and the sixth V-3a entry name type_mapping.cpp (with RR3-m1) | Head (Status, Outcome, ids); §0.1 row 6; §0.2 setup, M-8, M-9, M-12 to M-14, M-16, M-18, M-19, M-38, M-41, M-42; D-OX-9; §1.5; §1.6; §2.1; §2.5; §2.7 page; §2.8 (W-054, V-3a); §4; §6.1; §7 R-1, R-9; §8; hand-off |
| RR3-B2: RR2-2 not resolved: removing every exported operator before ranking makes Carbon's own expression select, and lower through, a C++ candidate that neither C++ nor trunk selects; R-11 and §7 A-18's claim that only classifying instantiations by origin could fix it is false | BLOCKER | Reproduced (M-41: on `v7` k1, k2, k4 and k7 print Carbon's `102`, `0`, `5` and `102` against C++'s `7`, `1`, `7` and `7`; k3b and k5 are rejected with W-045's TODO where trunk and C++ print `1`; k4b drops the assignment). Folded by the route proposed, prototyped as `v7x`: `FindClangOperator` resolves first with the exported operators present, and when C++ selects one that is not a deleted template's specialization, without a rewrite and with every operand an exact match, it returns no C++ operator so that Carbon's impl lookup selects the impl; otherwise it removes the exports and resolves again, as often as a resolution deduces a viable deleted-template specialization (fix 1). D-OX-11 is rewritten, and D-OX-21, §1.7, the page, R-11 and §7 A-18 restated: Carbon's operator expression agrees with C++ where C++ selects an exported operator exactly, and templates still see exports in calls, conversions and bodies (b1, b2, c1 to c4, e4) (fix 2). M-31, M-37 and M-40 re-measured, M-41 added (fix 3). The lower `carbon_side_template_candidate` and `carbon_side_template_body` are refilled, `fail_todo_carbon_side_rewritten_candidate` is the positive `carbon_side_rewritten_candidate`, k4b and k5 are `carbon_side_compound_template` (lower) and `carbon_side_rewritten_ordering` (C++20), and k1 with k2 is the lower `carbon_side_agrees_with_cpp_side` (fix 4). The a1 to a6 change is stated: they print C++'s `7` where trunk printed `1` (fix 5). One boundary the proposed rule leaves is measured and stated, with the evidence for not moving it (R17): where C++ reaches an exported operator only by converting an operand, Carbon resolves among the other candidates (f3: C++ `7`, Carbon `102`, trunk rejects both); calling the export instead (`v8e`) lowers through it and changes f9b's callee from trunk's, and leaving the expression to the impl lookup rejects f9b, which trunk accepts (M-42 (b), D-OX-21, §7 A-19) | Head (Status, Outcome, design authority, V-3); §0.2 M-10, M-12, M-19, M-22, M-26, M-31, M-33, M-37, M-40 to M-42; D-OX-11, D-OX-16, D-OX-21; §1.7; §2.1; §2.5; §2.7 page; §2.8 (row, W-054, W-007, decision log, V-3a); §3; §4; §7 R-3, R-11, A-18, A-19; §8; hand-off |
| RR3-M1: the plan presents mechanism artifacts (t4, o3, a2, a3, e2, t5, x7) as consequences of D-OX-21's rule, and its goldens and Breaks-if conditions pin them | MAJOR | Reproduced (M-41: C++'s own resolution of k1, k2, k3, k5c and k7 selects the export). Folded as proposed, after RR3-B2's fix: R-11 lists the rule's consequences (b1, b2, c1 to c4, e4, a call's template body, the trait's one value, the unused thunks) apart from the cases resolved at rev 5 (t4, o3, t5, e2, x7, a1 to a6, k1 to k7), with f3 as D-OX-11's stated boundary; M-31, M-33, M-37, M-38 and M-40 are corrected; D-OX-21's Breaks-if names calls, conversions and C++'s own selection; the page's section says what Carbon calls where C++ selects an export; §4's key lines expect the impl; and `carbon_side_trait_sees_export`, `carbon_side_template_body_unexportable` and `carbon_side_constexpr_body_unexportable` lose their `Cpp.Foo` impl, so that they pin a template C++ itself selects | Head (Outcome); §0.2 M-31, M-33, M-37, M-38, M-40, M-41; D-OX-21; §1.7; §2.5; §2.7 page; §4; §7 R-11 |
| RR3-m1: R-9 and the hand-off name only the class export code as what the predicate mirrors; type_mapping.cpp's recognized-type arms and `MapResultArgToCppType`, which it also mirrored and where it drifted, are not named | MINOR | Reproduced (rev 4's R-9, hand-off bullet and sixth V-3a entry; type_mapping.cpp :156-182 and :196-372 re-read). Folded as proposed: R-9, the hand-off bullet and the sixth V-3a entry name `TryMapClassType`, `MapResultArgToCppType`, `LookupCppType` and `LookupCppClassTemplate`, and say that after RR3-B1's fix only the kinds whose mapping exports a Carbon class remain mirrored (`MapsByExportingClass`), the rest being mapped; §0.1 row 6 states the recognized types' mapping | §0.1 row 6; D-OX-9; §2.1; §2.8 (V-3a); §7 R-9; hand-off |

Corrections the rev 5 fixer made that no review raised, found while
re-measuring: §3's commit 4 said that the fill's pass 2 changes all four
files, rev 3's measurement, where M-12 has measured three since rev 4; SC-1's
heads moved to 395096d51, with the ledger maximum W-235, and VA-1's C4 commit
is now its local and `origin` head, 9a0888ef0 (M-16, M-18, §6.2); and M-42
(c)'s `f8b`, a Carbon call of a hand-written C++ operator through a C++
conversion function, aborts in lowering on trunk too, a pre-existing defect
recorded in the hand-off beside M-34's.
