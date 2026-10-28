<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

Last updated: 2026-10-28 (RG-1's records classify the V-3a register at upstream
f27a977d8: 155 entries, 19 DRIFT, 33 ALIGNED, 103 NONE; W-346 to W-356 filed;
see the paragraph dated 2026-10-28 (RG-1) below; the earlier 2026-10-27 text
follows).
2026-10-27 (VA-2, definition-checked variadics slice 2, is
implemented, reviewed and held open as PR 66, stacked on PR 59; sixteen PRs
are held open, PR 51 to PR 66, none merged; see the paragraph dated 2026-10-27
below; the earlier 2026-10-26 text follows).
2026-10-26 (VA-2's plan, definition-checked variadics slice 2, is
signed off at rev 4 and its implementation has started on
claude/carbon-fork-0-1-va2, stacked on PR 59; see the third paragraph dated
2026-10-26 below; the earlier 2026-10-26 text follows).
2026-10-26 (DR-1b is held open as PR 65, stacked on PR 63, after
its implementation review and a focused re-review of four rounds (rounds 1 to 3
APPROVE-WITH-FIXES with comment-only MINORs and, at round 3, one MAJOR,
RR3-1-M1; round 4 dry after the shrink line); fifteen PRs are held open; VA-2,
variadics slice 2, is being planned on claude/carbon-fork-0-1-va2; see the
second paragraph dated 2026-10-26 below; the earlier 2026-10-26 text follows).
2026-10-26 (weekly check fired under R32: the cut HOLDS at 117 upstream commits
with 97 conflicting files, one drift is filed as W-341 and three register work
items as W-342 to W-344; see the paragraph dated 2026-10-26 below; the
2026-10-22 text follows). 2026-10-22 (CT-1 is held open as PR 64 after a dry
focused re-review, stacked on PR 61, and DR-1a as PR 63; DR-1b is under
implementation; PR 62, PR 56 and PR 57 carry DR-1's realignment commits; the
owner's direction-drift directive is R32 and DR-0, with DR-1's slice 1 stopped
on upstream's own conflict; see the paragraph dated 2026-10-22 and the six dated
2026-10-21 below; the 2026-10-19 text follows). 2026-10-19 (weekly check fired
again: the cut HOLDS at 85 upstream commits with 96 conflicting files and GitHub
Actions on the repository is still DISABLED, see the paragraph dated 2026-10-19
below; the 2026-10-12 text follows). 2026-10-12 (weekly check fired; BLOCKED:
GitHub Actions on the repository is DISABLED — every `workflow_dispatch` of
`Fork: hosted verification` returns "Actions has been disabled for this
repository", the repository's own scheduled workflows last ran 2026-10-08, the
repository is public, and this session has no access to repository settings — so
under R28 there is no autoupdate, gate or conformance arbiter at all. The
session was also out of usage credits from 2026-10-06 04:30 UTC until this
firing, and the container was recreated in between (worktrees, the clang-19
syntax harness and the bazel cache were lost; rebuilt: worktrees only). STATE:
UA-2 reconciliation on claude/carbon-fork-0-1-ua2 at ace101b0d is complete —
three probes un-SKIPped and PASSING (templates_dependent_member,
cpp_template_symbolic_arg, cpp_template_on_carbon_generic; the two Box(T)
programs needed a constructor-initialized dependent `var` and a declared
`Core.Copy`, root cause an upstream limitation of the REAL prelude's constrained
`DefaultOrUnformed` impl, pinned by
check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon), W-108
DISCHARGED on the fill (a `Core.Buf` field is freed through the owner's
synthesized SubobjectDestroy; an owner with its own `impl as Destroy` still
leaks — the 0.1 limit), ledger and gap re-cites done, of-record conformance run
37413300832: 131 PASS / 0 FAIL / 19 SKIP over 150, 48/56 bullets — but its gate
never ran: implementation review APPROVE-WITH-FIXES (nine findings, all folded
in round 3, 05a5c30f7: of-record runs recorded, W-126 declared-owner leak and
W-127 real-prelude `DefaultOrUnformed` limit filed, the prelude pin's failing
split retriaged to `fail_todo_` with its CHECK lines cleared for the next
refill); PR #51 is OPEN and HELD, not merged — land sequence once Actions
returns: autoupdate (one split) → gate → conformance → merge. SC-1 (template
structural conformance, W-027) plan rev 2 signed off at e612aebc6 on
claude/carbon-fork-0-1-sc after two reviews (both APPROVE-WITH-AMENDMENTS); the
commit-1 implementer died with the credits and is NOT relaunched: new toolchain
code cannot be filled or gated. Weekly: upstream 62f1cc6a3 is 36 commits past
the cut with 70 conflicting files (a tree-wide `ParameterizedClassType` rename);
the cut HOLDS, recorded in the decision log. OWNER DECISION NEEDED (R29:
recorded, not asked): re-enable Actions on the repository, or permit the
session's container to install bazelisk + LLVM 21.1.8 and build against
upstream's public read-only bazel cache (the tool-permission layer declined that
setup when attempted) — until one of these, no code lands. Next cron Monday
2026-10-19; the owner's machine is never used.

Later on 2026-10-12 (after the weekly stamp above): three PRs are OPEN and HELD
against trunk 0bdce60a5 — PR #51 (UA-2, claude/carbon-fork-0-1-ua2, head
f96fe8a7a), PR #52 (CM-1, claude/carbon-fork-0-1-cmake, head ea573f672: the
CMake language modules, examples/cmake, the Make guide; gap rows 84/87 expected
DONE, W-060/W-061 discharged, W-128..W-133 filed) and PR #53 (SAFE-1,
claude/carbon-fork-0-1-safe, head adaae4e35: the safe-Carbon design F-013 with
D-SAFE-1..23, the safety README rewrite plus five category pages and the
safe-Rust interop analysis, gap row 89 expected DONE on document review, W-063
discharged, W-144..W-150 filed). SC-1 (claude/carbon-fork-0-1-sc, W-027) is
IMPLEMENTED through commit 3 at 42841fa8d — structural_conformance.{h,cpp},
seven diagnostics, 18 goldens, the two conformance programs, W-134..W-144 filed,
every implementation review folded — and its golden fill is in progress; its
W-144 collides with SAFE-1's W-144 and renumbers to W-151 at its landing (SAFE-1
lands first). Each PR body carries its own verification record and names exactly
what did not run. None is merged. Merge order when the land sequence runs: #53
(no program moves), #51, #52, then SC-1.

Id reservations (2026-10-13, so concurrent workstreams never collide): W-151 is
SC-1's renumber of its W-144 (SAFE-1 owns W-144); W-152 to W-159 are reserved
for EV-1 (claude/carbon-fork-0-1-ev, fork/evaluator/plan.md, signed off at rev
2: the evaluator guides for W-062, gap row 90); ST-1 (claude/carbon-fork-0-1-st,
fork/string/plan.md: Core.String operations for W-057, gap row 77) starts at
W-160 and mints fork design id F-014. A reserved id that goes unused stays
unused. EV-1 merges after PR 52 (its state C integration commit); ST-1's order
is set at its sign-off.

Later on 2026-10-13: PR 54 (EV-1, claude/carbon-fork-0-1-ev, head cb3ef2e74: the
three evaluator guides, twelve transcribed programs, W-062 discharged, W-152,
W-153 and W-155 filed, expected 137/0/22 over 159) and PR 55 (ST-1,
claude/carbon-fork-0-1-st, head 21307851a: str comparison, Core.StringBuf and
concatenation under F-014, W-057 discharged, W-160 to W-167 filed, expected
133/0/21 over 154) are OPEN and HELD; both were verified on the container-built
toolchain (every PR body names exactly what ran and what did not), not on a
hosted run. SC-1 is through fill round 3 (head 2497d5000, gate 1959/1959,
conformance 130/0/21 over 151) with a round-3 review in progress; W-168 and
W-169 are reserved for its late residues. OP-1 (claude/carbon-fork-0-1-op,
fork/optional/plan.md: Core.Optional comparison for W-058) is in planning with
ids from W-170 and fork design id F-015 if minted. Merge order now: PR 53, PR
51, PR 52, SC-1, PR 54 (EV-1, after its state C integration commit), PR 55
(ST-1), then OP-1. None is merged.

On 2026-10-14: PR 56 (OP-1, claude/carbon-fork-0-1-op, head 379f20f67: the
Core.Optional comparison impls and the fork design F-015, W-058 discharged,
W-170 to W-179 and W-195 filed, expected 132/0/25 over 157; the Optional row
stays PARTIAL by D-OP-13, bounded by W-170 and W-171) is OPEN and HELD, verified
on the container-built toolchain. SC-1 is through fill round 5 (head a9c887101:
the root fix, a concrete requirement type; gate 1959/1959, conformance 130/0/21
over 151) with its round-5 review in progress; W-168 is filed, W-169 reserved.
DD-1 (claude/carbon-fork-0-1-dd, fork/designdocs/plan.md: design docs without
placeholders, W-065) is at plan rev 3, not yet signed off, with ids W-180 to
W-189 and W-191 to W-194. W-190 was allocated by both OP-1 and DD-1 in
parallel; both moved off it (OP-1 to W-195, DD-1 to W-191), so W-190 stays
unused and is never reused. Merge order: PR 53, PR 51, PR 52, SC-1, PR 54,
PR 55, PR 56, then DD-1. None is merged.

Later on 2026-10-14: PR 57 (OP-2, claude/carbon-fork-0-1-op2, head 628273444,
stacked on PR 56 and targeting claude/carbon-fork-0-1-op until PR 56 merges:
Core.Optional owns and destroys its value, the MaybeUnformed
value-representation fix in lowering, the checked Get, fork design F-016; W-170,
W-171 and W-173 discharged, W-196 to W-201 filed; expected 139/0/22 over 161;
the Optional row DONE expected under D-OP2-16) is OPEN and HELD, verified on the
container-built toolchain. SC-1 is through fill round 9 (round 8 review: no
BLOCKER, two MAJOR disclosure findings, folded in round 9; W-232 filed by round
9 in place of W-200, which OP-2 holds); DD-1 is in its third document-review
round (a REJECT on templates.md completeness claims, fold in progress, a fourth
focused round owed). Two workstreams are cut from this trunk tip: OX-1
(claude/carbon-fork-0-1-ox, fork/opexport/plan.md, W-054: Carbon operator impls
exported as C++ operator overloads, gap row 48; reserves W-202 to W-211 and
F-017 if a design decision is minted) and VA-1 (claude/carbon-fork-0-1-va,
fork/variadics/plan.md, W-013: the first slice of definition-checked variadics,
gap row 53; reserves W-212 to W-231 and F-018 if minted). SC-1 rounds after 9
take W-232 and up. Upstream trunk was fetched read-only as the upstream remote
(66a250ad9, 50 commits past the cut; the cut HOLDS): upstream has started
variadics with 2ec4bab59 (lex and parse of pack-expansion statements and expand;
no each) and a045da8e6, so VA-1 is planned on upstream's node shapes. Merge
order: PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, PR 56, PR 57, then DD-1; OX-1
and VA-1 after DD-1 in the order their PRs open. None is merged.

Later on 2026-10-14 (08:35 UTC): PR 58 (DD-1, claude/carbon-fork-0-1-dd, head
fcee90d9b: design docs without placeholders, W-065 and the documentation half
of W-020 discharged, W-182 to W-185, W-188, W-189 and W-191 to W-194 filed,
W-240 to W-244 reserved and unused; expected 147/0/22 over 169; row 70 DONE
expected, row 91 PARTIAL until state L) is OPEN and HELD; its fourth
document-review round was a round of both document reviews under D-DD-11, not
the "fourth focused round" the stamp above calls it, and both reviews returned
APPROVE-WITH-AMENDMENTS, so no further round is owed. The PR description and
the not-run list together exceed the length GitHub allows for a description,
so the not-run list is the first comment on PR 58. SC-1 is in fill round 10
(the round-9 review: no BLOCKER, both reviews APPROVE-WITH-FIXES; W-233 and
W-234 filed; SC-1 reserves W-233 to W-239). OX-1 and VA-1 plans at rev 1 are
under adversarial review. Merge order: PR 53, PR 51, PR 52, SC-1, PR 54, PR 55,
PR 56, PR 57, then PR 58 through its state L integration commit; OX-1 and VA-1
after PR 58. None is merged.

Later on 2026-10-14 (14:00 UTC): PR 59 (VA-1, claude/carbon-fork-0-1-va, head
b0822a744, 19 commits over trunk 3eb7f36f0 of which the first two are upstream
cherry-picks 2ec4bab59 and a045da8e6 with upstream authorship:
definition-checked variadics slice 1, one pack `... each x: T` per function,
statement and call-argument expansions, per-arity lowering; W-013 stays open
with the slice in its notes, W-212 to W-230 filed, W-231 unused; expected
137/0/21 over 158, 49/56; gap row 53 DESIGN-ONLY to PARTIAL expected) is OPEN
and HELD, verified on the container-built toolchain (gate 1960/1960, eight
mutants as predicted). Its two implementation reviews (APPROVE-WITH-FIXES, 5 and
7 findings) were folded in a fix commit that changed four toolchain files and
has no review of its own on record, as the PR body states. OX-1's plan reached
rev 5 without a sign-off: three focused re-reviews each REJECTed the
operator-export mechanism because exports made inside the Clang Sema that
Carbon's own operator, call and conversion resolution consults leak into that
resolution; the fourth re-review found three of its nine invariants failing on
programs, so OX-1 is being PARKED at plan rev 6 with a root-cause record (row 48
stays MISSING, W-202 to W-211 and F-017 stay reserved and unused). SC-1 is in
fill round 13 (the round-12 review: no BLOCKER, both reviews APPROVE-WITH-FIXES
with 5 findings each). Merge order: PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, PR
56, PR 57, PR 58 through its state L integration commit, then PR 59. None is
merged.

Later on 2026-10-15 (01:30 UTC): PR 60 (SC-1, claude/carbon-fork-0-1-sc, head
40a76ab81, 83 commits over trunk 8068151ed: template-style structural
conformance (F-010), `template constraint` method and associated-function
requirements satisfied by a type's own members; W-027 implemented; W-134 to
W-143, W-151, W-168, W-169 and W-232 to W-239 filed; expected 130/0/21 over
151, 49/56; gap row 55, line 60 on the branch, MISSING to PARTIAL expected) is
OPEN and HELD, verified on the container-built toolchain (gate 1959/1959).
Eighteen fill rounds: each round's diff had two implementation reviews, folded
by the next round; round 17's toolchain change (866468cba, merge.cpp) was
reviewed with no MAJOR or BLOCKER and both reviews found the branch dry, and
round 18 (885a7c30a) is records only, so no toolchain change is unreviewed.
The PR description is the summary; the full review record and verification
are its first comment (GitHub's description limit). `git merge-tree` of
40a76ab81 against trunk 8bfd78ae3 conflicts in fork/ORCHESTRATION.md only,
and against PRs 53, 52 and 51 in the files the PR description names with
their resolutions. TP-1 (claude/carbon-fork-0-1-tp, W-014, gap row 54) has
its plan rev 3 signed off, commits C1 to C5, P and M pushed, and the fold of
its implementation review pushed at 824f29c4e; its discharge is in progress
and its PR opens after a focused re-review of the fix commits. Merge order: PR
53, PR 51, PR 52, PR 60, PR 54, PR 55, PR 56, PR 57, PR 58 through its state L
integration commit, PR 59, then TP-1. None is merged.

Later on 2026-10-19 (14:10 UTC, weekly check fired): upstream trunk 3056e7e31
is 85 commits past the c1e83b0b7 cut (49 since last week); a `git merge-tree`
dry run against trunk 5674fe88b conflicts in 96 files, 30 sources and
grammars and 66 goldens (decision-log entry "Weekly upstream merge
2026-10-19"); the cut HOLDS, no staging branch was pushed, and the advance
(UA-3) is scheduled after the held PRs land, under the UA-1 flow. A
`workflow_dispatch` of `Fork: hosted verification` still returns "Actions
has been disabled for this repository", so nothing is of record and the ten
held PRs stay open; the daily Actions re-test routine ends with this firing
as its prompt provided, and the weekly Routine re-tests. TP-1's focused
re-review (round 1: review 1 APPROVE-WITH-FIXES with 2 MAJOR and 4 MINOR,
review 2 REJECT with 1 BLOCKER, 2 MAJOR and 5 MINOR, both on bf8e1b4cc) is
being folded by its fixer; its PR opens when a round is dry. SV-1 (the
std::optional and std::variant interop mapping, W-011's open half, gap row
68) is the next workstream, branch claude/carbon-fork-0-1-sv cut from
5674fe88b, W-275 to W-294 and F-020 reserved; W-267 to W-274 are held for
TP-1's re-review residues. Merge order unchanged: PR 53, PR 51, PR 52, PR
60, PR 54, PR 55, PR 56, PR 57, PR 58 through its state L integration
commit, PR 59, then TP-1, then SV-1. None is merged.

Later on 2026-10-20 (13:00 UTC): PR 61 (TP-1, claude/carbon-fork-0-1-tp, head
e408ad4d6, 97 commits over 8bfd78ae3, its merge base with trunk: integrated
templates, the W-014 slice with DD-1's W-183, W-192 and W-193 and UA-2's
W-127, which land-time records discharge; template-dependent initializers,
for loops, dereference, indexing and calls checked on instantiation,
class-argument deduction, constraint lookup; toolchain at 813804758; W-250 to
W-274 filed, W-272 discharged within TP-1; F-019 not minted; expected
137/0/22 over 159, 48/56; gap row 54 stays PARTIAL) is OPEN and HELD,
verified on the container-built toolchain (gate 1955/1955). Its
implementation review REJECTed on a lowering crash; the fold's fix commits
then had a focused re-review of nine rounds, each round two fresh reviews, a
fixer and a records pass, every fix at its root cause (the last three: an
action keeps a struct or tuple literal as its operand, so a deferred literal
takes its class's defaults on instantiation; a class specific is resolved
before a field default is read in it); round 9 was dry (both reviews, no
MAJOR or BLOCKER, no toolchain change), so the PR opened. The description is
the summary and the full verification record is its first comment (GitHub's
description limit). `git merge-tree` of e408ad4d6 against trunk f3156a375
conflicts in fork/ORCHESTRATION.md only (this file's TP-1 row and status
paragraphs); against the held PRs in the record files, and with PR 60 in
convert.cpp and member_access.cpp, each with its resolution in the PR body.
SV-1 (the std::optional and std::variant interop mapping, W-011's open half,
gap row 68) is planning on claude/carbon-fork-0-1-sv (fork/sumtype-interop/
plan.md rev 1 under way; W-275 to W-294 and F-020 reserved). Merge order: PR
53, PR 51, PR 52, PR 60, PR 54, PR 55, PR 56, PR 57, PR 58 through its state L
integration commit, PR 59, PR 61 through its land-time commits (M over the
merged trunk, S over SC-1, F6, the id re-scan, L with its document review,
the records commit), then SV-1. None is merged.

Later on 2026-10-21 (00:10 UTC): SV-1's plan (fork/sumtype-interop/plan.md on
claude/carbon-fork-0-1-sv) is SIGNED OFF FOR IMPLEMENTATION at rev 5,
30153bbc2, after five reviews (A REJECT with 13 findings, B REJECT with 17, the
focused re-review of rev 2 REJECT with 6, of rev 3 REJECT with 6, of rev 4
APPROVE-WITH-AMENDMENTS with 4; 46 findings, every one folded, none rejected;
the plan's own prototype crashes in overload sets and on a VA-1 pack element
were found and fixed by the reviews). F-020 is minted by the plan: a C++
std::optional or std::variant keeps its imported class and converts by value,
through its accessors, to and from a specific of a prelude generic choice in
Core.CppCompat (StdOptional(T), StdVariant1 to StdVariant8, alternatives by C++
index), which match and the other refutable contexts consume; the departure
from SF-8's default lean is recorded for veto. W-275 to W-285 are used by the
plan (W-278 withdrawn; W-282, W-283 and W-284 conditional) and W-286 to W-294
held; row 68 is predicted PARTIAL on W-177 narrowed, W-011 discharged. The
implementation workflow started at 00:00 UTC (C1 to C3 with fills, P, Doc, the
held-state measurements on mirrors over PR 57, PR 60, PR 59 and PR 61, two
implementation reviews, the fixer, R and D; M-VA, F-M and Doc-M are land-time
commits after PR 61). TP-1: after PR 61 opened, SV-1's fixer found X-1, a match
on a template-dependent choice that stopped the TP-1 compiler at
pattern_match.cpp:1409 where trunk reports a TODO; round 10 fixed it at the
root (eafca5cb9: the alternative pattern's name is resolved through the
member-access action in the choice's definition, so a template-dependent
specific's designator has the scrutinee's type and the program runs), both
round-10 reviews found only MINORs (review 1 four, records only; review 2
seven, one test-only), round 11 folds the test-only finding and is under
review, and PR 61's description and first comment are re-posted from the
branch when a round is dry. W-295 to W-299 are reserved to TP-1 for its
round-10 and later residues: W-295 to W-297 are filed on its branch (crashes
shared with trunk and the nightly, found by round 10 and its reviews), W-298
and W-299 held. Merge order unchanged: PR 53, PR 51, PR 52, PR 60, PR 54, PR
55, PR 56, PR 57, PR 58 through its state L integration commit, PR 59, PR 61
through its land-time commits, then SV-1 through its land-time commits M,
M-VA, F-M, Doc-M, R and D. None is merged.

Later on 2026-10-21 (02:33 UTC): TP-1's round 11 is DRY. Its fixer changed one
golden and no toolchain file (06f61260c: the work-item id deleted from
match_choice.carbon's header comment and the split
fail_unknown_alternative_class_template; b412e602b its fill; fe52530a4 the
records); its two fresh reviews at fe52530a4 were both APPROVE-WITH-FIXES and
dry, with six MINOR findings, all records only (review 1 one, filed as W-298:
a choice alternative whose parameter type a template action forms stops the
compiler while the choice's definition is checked, as on trunk; review 2
five), folded in 5661a35c8, PR 61's head. W-295 to W-298 are filed on the
branch and W-299 is unused. The container measurements at the head, EXPECTED
and not of record: file_test 1957 of 1957, conformance 138/0/22 over 160 with
48 of 56 bullets. PR 61's description and first comment were refreshed from
the records-writer's drafts after a container restart (a finisher, a
fresh-context verifier with ten findings, one of them a BLOCKER wording about
prek runs, and a fixer that folded all ten) and re-posted at 02:28 and 02:32
UTC, each verified byte-exact through the public API. No round 12 is owed;
PR 61 stays held open and merges after PR 59. SV-1's
implementation reached its held-state measurements (C1 to C3 with fills, P
and Doc pushed at 8243dbe97: gate 1950 of 1950, conformance 134/0/21 over 155
as predicted; M, the records-only merge of trunk 481f05612, at f30429458; the
mutants and the composition mirrors under way). Merge order unchanged. None
is merged.

Later on 2026-10-21 (08:52 UTC): SV-1 is IMPLEMENTED, REVIEWED AND HELD OPEN AS
PR 62 (claude/carbon-fork-0-1-sv, head 3a6531157, base trunk; toolchain
a4d979619). The implementation followed the signed-off plan: C1 to C3 with
their fills, P (one program un-SKIPped and five new ones against C++
oracles), Doc, the held-state measurements (19 mutants, 18 killed and M16
recorded as defensive; four full composition mirrors over PR 57, PR 60, PR 59
and PR 61 with exactly the predicted red sets; clang-tidy; the id re-scan)
and two records-only merges of trunk. Two implementation reviews (review 1
REJECT: a BLOCKER, a sum value passed by value to a declared-only C++
function stopped the compiler in clang, and a MAJOR, the Carbon-to-C++
direction failed for every class with a pointer alternative; review 2
APPROVE-WITH-FIXES, ten MINORs) were folded by a separate fixer in two of the
three fix commits allowed, each at the root in SV-1's own code, with mutants
M23 to M25 pinning them; then R (gap row 68 stays PARTIAL on W-177, narrowed)
and D (W-011 DISCHARGED; F-020 minted; W-275 to W-277, W-279 to W-281 and
W-285 filed). The focused re-review of the fold: round 1 found no BLOCKER or
MAJOR but one golden pin missing (mutant M26 survived), round 2's fixer added
two splits with no toolchain change and filed W-286 (a trunk-origin stop on
an incomplete C++ class under a Destroy constraint, shared by trunk, the
nightly and every held PR), and round 2's two fresh reviews found only
records-only MINORs, folded in 3a6531157: round 2 is dry. W-284 is held for
M-VA, W-282 stays conditional at land time, W-283 and W-287 to W-294 are
unused, W-278 withdrawn. Expected, not of record: file_test 1950 of 1950,
conformance 134/0/21 over 155 with 48 of 56 bullets. The description and
first comment were posted from the branch's texts and verified byte-exact
through the public API, apart from the posting tool's footer. SV-1 merges
last, after PR 61, through its land-time items (M over the trunk that holds
PR 51 to PR 61, M-VA, F-M, Doc-M, the second id re-scan and the land-time
records commit). Twelve PRs are held open (PR 51 to PR 62); none is merged;
the next workstream is chosen from the gap analysis's open rows.

Later on 2026-10-21 (16:05 UTC): CT-1's plan is SIGNED OFF at rev 4
(fork/cpp-templates/plan.md on claude/carbon-fork-0-1-ct, 62530b76e; the
worktree is cut from PR 61's head 5661a35c8 and the branch is stacked on PR 61).
CT-1 is W-043: a C++ class, function, alias or variable template named with a
symbolic Carbon type argument is formed and instantiated per specific, in
checked generics and in TP-1's templates, for gap rows 56 and 42 (the two SKIP
programs cpp_template_symbolic_arg and cpp_template_on_carbon_generic). The
plan went through two adversarial reviews (A REJECT with twelve findings, B
APPROVE-WITH-AMENDMENTS with thirteen), a fold to rev 2, a focused re-review
(REJECT: a crash on an alias of a template-dependent value, fixed at the root
as D-CT-17, an alias in a generic belongs to the generic, and a destructor
omission on a deferred call's discarded temporary, shipped with a pin and a
break condition as D-CT-18), a fold to rev 3, a second focused re-review
(APPROVE-WITH-AMENDMENTS, one MAJOR: a specific's constant read through an
alias, folded at the root as the one-field change of an existing instruction
kind's expression category) and a fold to rev 4: thirty findings, all folded,
none rejected. The prototype v14 (sixteen toolchain files, 388 lines added and
33 removed, relinked over TP-1's objects) measured, EXPECTED and not of record:
a gate of 1951 of 1957 with six predicted refills, 1959 of 1959 after the fills
of its two new goldens, and conformance 147/0/20 over 167 with 48 of 56 bullets
(the two SKIP programs un-SKIPped and seven programs added, one of them a
differential pair). CT-1 reserves W-300..W-319 (W-300..W-309 to be filed at
its discharge), mints F-021 (D-CT-16, the checked-generic C++ rule), narrows
TP-1's W-268 and discharges TP-1's W-273, and merges after PR 62 through its
land-time items M, S-VA, L-F, L and the land-time records commit. Its
implementation workflow has started (C1, F1, C2, F2, P, the held-state
measurements with five composition mirrors, two implementation reviews, the
fixer, R and D, then the focused re-review loop capped at three rounds); the PR
opens held when the loop is dry. Twelve PRs are held open; none is merged.

Later on 2026-10-21 (17:21 UTC): the owner's directive "Direction drifts are not
permitted", asked with the question "why didn't the fork have matchable optional
types in the first place?", is recorded as R32 (fork/rulebook.md) and as V-3b
and entry DR-0 (fork/decision-log.md); it withdraws V-3's override clause
('upstream intent is the default preference, overridable with stated good
reason'). The answer, in four sentences. W5 put the `Match` interface out of
scope (W5-S1, R-8) and recommended replacing the class by a choice for SF-9, but
that owner question was never asked, and on 2026-09-27, the day R29(a) took
effect, EH-A auto-adopted KEEP as D-EH-1 with a break condition keyed only on
making `Optional` a choice. SF-6's scalar-only payload gate could not have
carried a choice `Optional` of a class anyway, and OP-1 (PR 56) kept the class
by D-OP-7 and filed matchability as W-177. Upstream's loops.md began desugaring
`for` through `case .Some(<pattern>)` on 2026-10-07 (df3cf9294, PR 7381,
proposal p007381, two days after the cut), and the fork missed it: OP-1's V-3
compared the prelude against upstream 62f1cc6a3 but read loops.md from the
fork's copy, PR 56 wrote a Fork amendment into loops.md pinning
`HasValue`/`Get`, and neither weekly check named PR 7381. PR 62's D-SV-7
scrutinee view is a fourth spelling, and two more drifts stand: upstream's
`IndirectIndexWith` with a `ref`-returning `Ref` (PRs 7974, 7975) against
D-SL-3's read-only `Slice`, and upstream's `ref cursor` `Iterate.Next` against
the fork's pointer cursor at 11 sites. Decisions, auto-adopted under R29(a),
each with its break condition in DR-0: D-DR-1 schedules the realignment
workstream DR-1 after CT-1's implementation and before UA-3, on trunk's base
with the held PRs composed on mirrors, in three slices (`Match` for classes and
`Core.Optional`'s `impl as Match`, with `.Some`/`.None` patterns, `match`, `if
let`, `while let`, the `for` desugaring and the `Try` body, `HasValue`/`Get`
kept; `Iterate.Next`'s `ref cursor` with every impl and the loop checker;
`Core.Slice`'s element access writable through `IndirectIndexWith`'s `Ref`),
ordered and split by the plan's reviews; D-DR-2 records PR 62's D-SV-7 view as a
V-3a divergence, retired by slice 1 through a new commit on PR 62's branch;
D-DR-3 owes PR 56 a new commit rewriting the loops.md Fork amendment (:116-118)
to upstream's current desugaring and adding a dated correction naming df3cf9294
to OP-1's V-3 paragraph; D-DR-4 makes every V-3 check compare against upstream's
tip by sha and quote the page at that tip, and every weekly check list
mechanism-changing commits by subject (R32). Ids: DR-1 reserves W-320..W-329 and
files W-320 (`Core.Optional` matchable by `Match`, closes W-177; slice 1), W-321
(the `ref cursor` signature, 11 sites; slice 2), W-322 (retire D-SV-7's view)
and W-323 (PR 56's record corrections); W-324..W-329 are reserved and unused;
W-109 gains a dated note naming slice 3; CT-1 keeps W-300..W-319; a re-scan of
68 origin refs and 16 worktrees found no other W-3xx id. Schedule: DR-1 is the
first of the Next actions below. Twelve PRs are held open; none is merged.

Later on 2026-10-21 (20:34 UTC): DR-1's plan is SIGNED OFF at rev 3
(fork/direction/plan.md on claude/carbon-fork-0-1-dr, a9943e467, cut from trunk
f68681114): two adversarial reviews, both REJECT with twelve and nineteen
findings, a fold to rev 2, a focused re-review (APPROVE-WITH-AMENDMENTS, six)
and a fold to rev 3; thirty-seven findings, all folded, none rejected. Its
central finding: upstream's own pages conflict on how the Match interface
declares its Continuation (sum_types.md writes a template associated constant;
README.md, generics/terminology.md and upstream's parser forbid any phase
keyword on an associated constant; the impl-scope let the class example relies
on was removed by proposal p001013), so the Match route for Core.Optional
cannot be written on either toolchain without a fork spelling, which R32
forbids. Slice 1 (W-320) therefore stops at the plan, blocked on W-324, a
register entry that watches upstream's resolution at each weekly check; no
F-022 is minted. DR-1 is two PRs on trunk's base: DR-1a, Core.Iterate.Next's
ref cursor (W-321; measured, EXPECTED and not of record: nine goldens refilled,
gate 1942 of 1942, conformance 128/0/22), and DR-1b, stacked on it, element
access through IndirectIndexWith with Core.Slice and Core.Buf writing through
Ref and upstream 230227264 cherry-picked (W-109; gate 1946 of 1946, conformance
130/0/22 over 152); both compose on CT-1's head (1963 of 1963, 149/0/20 over
169, after a per-specific index deferral for template-dependent operands). Made
now, by new commits on the held PRs' branches: W-322 retires PR 62's D-SV-7
view (measured on a mirror: gate 1950 of 1950, conformance 133/0/22 over 155,
the view's program SKIPped) and W-323 corrects PR 56's loops.md amendment and
V-3 paragraph, merged into PR 57. Residues W-324..W-327 and W-329 are filed at
R0; W-328 is reserved for W-320's resumption. The implementation workflow has
started. CT-1's implementation review 1 found one BLOCKER (a lowering stop when
a Carbon generic call's result is stored into a C++ specialization member in a
checked generic) and three MAJORs, and review 2 six records-only MINORs; the
fixer is folding them at the root (224ee2f8f and its fill so far); the records
and the focused re-review loop follow. Twelve PRs are held open; none is
merged.

Later on 2026-10-22 (00:07 UTC): CT-1 is IMPLEMENTED, REVIEWED AND HELD OPEN AS
PR 64 (claude/carbon-fork-0-1-ct, head 4a3220c11, base
claude/carbon-fork-0-1-tp, stacked on PR 61; toolchain 224ee2f8f). The
implementation followed the signed-off plan with no stop-and-amend revision: C1,
F1, C2, F2 and P reproduced every predicted fill, gate and total; the held-state
measurements ran the mutants and five full composition mirrors (PR 51, 57, 59,
60 and 62). Two implementation reviews (review 1 REJECT: a BLOCKER, a lowering
stop when a Carbon generic call's result is stored into a C++ specialization
member in a checked generic, three MAJORs and four MINORs; review 2
APPROVE-WITH-FIXES, six records-only MINORs) were folded by a separate fixer at
the root in the three fix commits the plan allows, each with its fill and a
mutant pinning it; then R (gap rows 56 and 42 stay PARTIAL with corrected text)
and D (W-043 DISCHARGED; TP-1's W-273 discharged and W-268 narrowed;
W-300..W-311 filed, W-312..W-319 unused; F-021 minted). The focused re-review's
round 1 (two fresh reviews, both APPROVE-WITH-FIXES with twelve records-only
MINORs, folded in 4a3220c11; both re-ran the PR 62 mirror at its moved head
0ef8a0334) is dry. Expected, not of record: file_test 1959 of 1959, conformance
147/0/20 over 167 with 48 of 56 bullets. The description and first comment were
posted from the branch's texts and verified byte-exact through the public API
apart from the posting tool's footer. CT-1 merges after PR 62 through M, S-VA,
L-F, L and the land-time records commit. DR-1a is HELD OPEN AS PR 63
(claude/carbon-fork-0-1-dr, head 18a7e8934, base trunk; toolchain d0cfe8082):
Core.Iterate.Next takes a ref cursor as upstream's p007381 adopted, nine goldens
refilled, gate 1942 of 1942, conformance unchanged at 128/0/22; its one
implementation review found three records-only MINORs, folded. DR-1b
(IndirectIndexWith; W-109) is under implementation on
claude/carbon-fork-0-1-dr-idx, stacked on PR 63. DR-1's held-PR commits are made
and pushed: W-322 on PR 62 (head 0ef8a0334: the D-SV-7 Core.Optional view
retired under R32 (d), gate 1950 of 1950, conformance 133/0/22 over 155, its
focused review's four MINORs folded), W-323 on PR 56 (894139b34) and PR 57's
merge of it (a080c7886); the three descriptions were refreshed with dated
amendments and verified through the API. Fourteen PRs are held open (PR 51 to PR
64); none is merged.

Later on 2026-10-26 (14:44 UTC, weekly check fired): the first weekly check
under R32. Upstream trunk 21c825a3f is 117 commits past the c1e83b0b7 cut (32
since last week's 3056e7e31); a `git merge-tree` dry run against trunk 563135b40
conflicts in 97 files, 31 sources and grammars and 66 goldens (last week 96, 30
and 66; the one new file is toolchain/driver/compile_options.cpp); 1846 upstream
files are touched since the cut, 791 are fork-modified and 197 are in both
(decision-log entry "Weekly upstream check 2026-10-26 (R32 direction
register)"). The cut HOLDS and UA-3 stays scheduled after the held PRs land. Of
the window's 32 commits, 20 touch the design, prelude or toolchain paths: one
drift, twelve advances for UA-3's audit, seven unrelated; no prelude signature
changed. The drift: 503f09037 extends upstream's positional default parameter
values, which trunk has carried since UA-1, while F-009j says there are no
Carbon-native default arguments and an overload set's arity step is exact, so a
member called with a defaulted argument omitted is rejected; it is filed as
W-341, owner OV-4, after VA-2 and before UA-3, and no held PR is amended. The
V-3a register at the tip: (i) to (iii) are resolved on PR 62, DR-1b and PR 63;
(iv) and (v) HOLD with W-324's and W-326's break conditions not fired; VA-2's
six plan-state entries are unchanged; trunk's eleven pre-DR-0 blocks, the ten
held-branch blocks and OP-1's block HOLD but carry no work item, so W-342, W-343
(SAFE-1's departures on PR 53 first) and W-344 are filed for RG-1, the register
classification. The dated notes for W-324 and W-326 and the (i) sha stamp are
routed to DR-1's workflow, since those items live on PR 63's and DR-1b's
branches. No build, no merge, no dispatch; Actions is still disabled (the newest
run is of 2026-10-08), so nothing is of record. Fourteen PRs are held open; none
is merged.

Later on 2026-10-26 (15:35 UTC): DR-1b is IMPLEMENTED, REVIEWED AND HELD OPEN AS
PR 65 (claude/carbon-fork-0-1-dr-idx, head fee0ef31c, base
claude/carbon-fork-0-1-dr, stacked on PR 63; toolchain 7a442f632): element
access through IndirectIndexWith as upstream's index.carbon defines it, with
Core.Slice and Core.Buf writing through Ref and upstream 230227264 cherry-picked
(W-109 discharged). The implementation stopped once under the stop-and-amend
rule (the PR 51 and PR 57 mirrors' red sets differed from the plan's prediction;
the plan's rev 4, f551057ea on PR 63's branch, records them and the amend
re-review's six MINORs were folded in round 1's records (c1b19da06)). Its
implementation review (APPROVE-WITH-FIXES: one MAJOR, the literal-subscript rule
ignoring an IndirectIndexWith(Core.IntLiteral) impl, and six MINORs) was folded
at the root by a separate fixer (fddfcf42a and its fill bcd9ba06f, the comment
commits 8deb75262 and 7a442f632, and round 4's shrink-line split 0cd4e5d2e with
W-340 filed), then a focused re-review of four rounds (rounds 1 to 3
APPROVE-WITH-FIXES with comment-only MINORs and, at round 3, one MAJOR,
RR3-1-M1; round 4 dry after the shrink line). Expected, not of record: file_test
1946 of 1946, conformance 130/0/22 over 152. PR 63's description carries a dated
amendment naming rev 4 and the fold. The re-review loop paused from 2026-10-22
to 2026-10-26 on the account's weekly usage limit and resumed from its journals.
Next: VA-2, definition-checked variadics slice 2 (W-212, W-213, W-225; gap rows
53 and 74; stacked on PR 59), chosen under R32 because upstream's own prelude
TODO and accepted design spell it; its plan workflow runs on
claude/carbon-fork-0-1-va2. Fifteen PRs are held open (PR 51 to PR 65); none is
merged.

Later on 2026-10-26 (17:05 UTC): VA-2's plan is SIGNED OFF at rev 4
(fork/variadics/va2-plan.md on claude/carbon-fork-0-1-va2, 7188540ca, cut from
PR 59's head b0822a744, toolchain 88b1b5bd2): two adversarial reviews, both
REJECT with ten and fifteen findings, a fold to rev 2, a focused re-review
(REJECT: one BLOCKER, a generic with a pack of different types defined in
another library crashed in lowering, the shape of the planned prelude impls)
and a fold to rev 3 fixing it at the root, a second focused re-review
(APPROVE-WITH-AMENDMENTS: one MAJOR, compile-time each-names accepted outside
implicit parameter lists, and three MINORs) and a fold to rev 4; thirty-four
findings as reported, thirty-three distinct, all folded, none rejected. VA-2
takes W-212 (packs of different types in implicit parameter lists), W-213
(tuples with one pack segment, narrowed) and W-225 (the prelude's tuple Copy,
EqWith and OrderedWith as variadic impls), with a prerequisite lowering fix
for nested aggregate constants (a defect on every toolchain since the cut,
upstream's tip included); it was chosen under R32 because upstream's own
prelude TODO and the accepted design p002240 spell it, and its V-3 check reads
upstream at 21c825a3f. The plan predicts, EXPECTED and not of record: gate
1975 of 1975 and conformance 147/0/21 over 168 from PR 59's 1960 of 1960 and
137/0/21 over 158; both gap rows stay PARTIAL by their bullet texts. One PR,
stacked on PR 59, merging last after PR 65 through M, S-CT, F-M, L-F and L;
W-330..W-339 are its ids. The implementation workflow has started. Fifteen
PRs are held open (PR 51 to PR 65); none is merged.

2026-10-27 (21:24 UTC): VA-2 is IMPLEMENTED, REVIEWED AND HELD OPEN as PR 66
(claude/carbon-fork-0-1-va2 at 43c8ab476, base claude/carbon-fork-0-1-va, PR
59's b0822a744; forty-two commits: plan rev 1 to rev 16, C0 and C0b with F0,
C1 to C5 with F1 to F4, the implementation-review fold's fix and fill, R, D,
and the focused re-review loop's four rounds with fix 3 and fix 4, their
fills and their records). The implementation stopped five times on a
difference from the plan's predictions and each time a plan amender, a
focused re-review and a fold preceded the stage's re-run (rev 5 to rev 14).
Twenty-one reviews in all (two plan reviews, two focused plan re-reviews,
five stop-and-amend re-reviews, two implementation reviews and the loop's
eight): 104 findings, 100 distinct, all folded, none rejected. The fix budget
of three was spent by the fold's fix (destruction, facet packs and indexing
of tuples with a pack segment), its records fold and round 2's fix 3 (packs
of facets converted to a narrower facet type); round 2's three code findings
(a file-scope `let` pack pattern aborting the compiler, an unpinned import,
a compile-time pack expanded as call arguments passed as one argument, which
ran a deduced callee with the wrong arity) were answered under D-VA2-19's
break condition, no shrink line reaching them without breaking measured
rows: plan rev 16 specified and measured fix 4, round 3's two reviews read
it before it was committed and found it sound, and round 4 committed it with
its fill and records; round 4's reviews were dry (six records-only MINORs,
folded). Expected, not of record: gate 1977 of 1977, conformance 147/0/21
over 168, bullets 49/0/7 of 56, from PR 59's 1960 and 137/0/21 over 158;
twenty-six mutants killed; eight composition mirrors green, both sides'
programs passing. Records: W-225 discharged, W-212 and W-213 narrowed,
W-330..W-339 and W-345 filed (W-335 discharged); the gap rows "Generics:
Definition-checked variadics" and "Stdlib: tuple/array library parts" stay
PARTIAL. PR 66 merges last, after PR 65, through M, S-CT, F-M, L-F and L
(the plan's section 3 item 15 and the branch's ORCHESTRATION item 6). The
land simulation exposed two held-side defects, routed and not VA-2's: SC-1's
`self_facet_in_signature_required` split failing against OP-2's storage, and
PR 59's abort on a pack expansion pattern in a choice alternative's
parameter list. Sixteen PRs are held open (PR 51 to PR 66); none is merged.
Next: OV-4 (W-341) and RG-1 (W-342..W-344) per item 6 below, then UA-3.

Later on 2026-10-28 (RG-1): the V-3a register is classified at upstream
f27a977d8 (2026-10-27, upstream PR 8045; re-checked at e6fddcf97), records
first, on claude/carbon-fork-0-1-rg1 (decision-log entry "RG-1: the V-3a
register classified at f27a977d8 (2026-10-28)"; fork/register/rg1-plan.md).
Every entry of the 26 blocks and V-3's design-fork entries was read against the
page at the tip: 155 entries, 19 DRIFT, 33 ALIGNED, 103 NONE, 10 waiting on
upstream; every NONE carries its quote or silence check, and every NONE and
ALIGNED outside VA-2's six, which carry VA-2's items, the watch item W-355,
whose weekly run uses fork/register/check_quotes.sh and check_greps.sh. F-006a's
`Ok`/`Err` is a drift against README.md's `Success`/`Failure` (W-346, owner
EH-C, after the held PRs land and before UA-3, reversing the user's F-006a under
the 2026-10-21 directive, veto-able); F-009's `overload fn` is not (p002875
calls its spelling placeholder). Three held PRs carry drifts and wait for their
owners' realignment commits before they land: PR 53 six (W-347 to W-351 and
W-353, owner SAFE-1), PR 60 one (D-SC-6, W-139, whose break condition was
already met when it was filed), and PR 56 one (the comparisons' side effects,
W-352, owner OP-1, not blocked). D-SL-16's yield and D-SL-19's keying are W-354,
dropped at UA-3 against 05a7ecbd3's `SelfDestruct`; W-356 is a crash RG-1's
probe found, UA-3's to triage. RG-1's held records commits follow on PR 53, PR
52, PR 60, PR 55, PR 56 (merged into PR 57), PR 61 and PR 64 (with PR 61's
merged), staged and reviewed before any push, then the stamp R2. No build, merge
or dispatch; Actions is still disabled. Sixteen PRs are held open; none is
merged. Merge order, as fork/register/rg1-plan.md section 5 gives it:
RG-1, PR 53, 51, 52, 60, 54, 55, 56, 57, 58, 59, 61, 62, 64, 63, 65, 66.

Earlier (post-PR #50, 2026-10-06): UPSTREAM ADVANCE (UA-1) LANDED — the cut
moved from 631f8fb (2026-08-20) to upstream c1e83b0b7 (2026-10-05): 183
commits, 105 conflicts, every class-B mechanism re-expressed inside
upstream's structure, two class-C deletions, one source conflict at the
SL-2 re-merge; floor 128 PASS / 0 / 22 SKIP over 150 (run 37402970811),
48/56 bullets; two upstream latent bugs fixed on the way (a null `QualType`
in `TryMapType`'s generic-function arm; `if`-expression arm and
short-circuit operand cleanups destroying an unconstructed temporary).

FIFTY PRs. Seven weekly checks held the cut because the merge was too large to
do safely by hand; it was done in one planned flow instead — two adversarial
plan reviews, a focused re-review, an implementation review, five hosted fill
passes, every miss written down with why review did not see it. The fork now
sits on upstream's tip with nothing deferred.

Earlier on 2026-10-06 (post-PR #49: SL-2 LANDED — the dynamic-extent
`std::span<T>` imports as `Core.Slice(T')` and `Core.Slice` exports as
`std::span`, and a C++ owning container with `data()`/`size()` converts to a
`Core.Slice` view through the synthesized `Core.CppContiguousRange`. Gap row
82 MISSING → DONE; header 30 DONE / 21 PARTIAL / 4 MISSING / 1 DESIGN-ONLY.
Floor 128 / 0 / 22 over 150, run 37390640614. Five hosted rounds; the
of-record conformance run FAILED both new programs after a green gate — a
`ClassDecl` cast ICE in C++ conversion lookup and an upstream latent lowering
bug that skipped constant elements of a mixed array literal — both fixed at
the root.)

FORTY-NINE PRs. The slice now crosses the C++ boundary in both directions, and
the two bugs that the of-record conformance run surfaced after a green gate — a
conversion-lookup ICE and a lowering path that left constant array elements
uninitialized — are exactly why the runtime suite is the bar and the golden fill
is not: both goldens were green, both programs were wrong._ FORTY-EIGHT PRs.
Function overloading is finished end to end — same-file sets, import across
libraries and api/impl, generic members, and export to C++ — with the one
divergence from C++ written down and tested rather than papered over. The
thunk-symbol collision that review found (every member's thunk mangled alike;
lowering would have run member 0 for every C++ overload) is the kind of silent
wrong-member bug the hosted fill alone would never have shown._ FORTY-SEVEN PRs.
Slices exist, and so — for the first time — do user destructors: the slice that
needed `free` to run found that no declared `Destroy` impl had ever been
selected, and fixed that at the root rather than documenting a leak. Four hosted
rounds for one slice is the loop earning its keep; each miss is written down
with why review did not see it._ FORTY-SIX PRs. Overload sets now cross library
boundaries the way the design asks — whole, closed, with the api/impl rules
reading the api file's facts — and the slice's two review rounds plus three
hosted fills each caught something the previous layer had traced as clean, which
is the loop working rather than failing: every miss is written down with its
root cause._ FORTY-FIVE PRs. Overloading exists in Carbon proper: the design's
marked, closed sets with first-match resolution, landed with the loop's one real
invariant (every probe exit restores block, region and cleanup depth under
CHECK) and with the one mirror site no review caught — the export-name switch —
found by the hosted fill as a runtime fatal, exactly where a compile probe is
blind. The imported-member mangling collapse was first gated, then its pin
filled EMPTY and proved the gate unreachable, so the gate went and the root fix
(the stored index) landed instead._ FORTY-FOUR PRs. Unions are closed out end to
end: native declaration, layout by construction, and a C++ round trip that the
embedded Clang itself asserts (`sizeof`, `alignof`, `__is_union`) — plus the
first Carbon-side call through a return-address thunk for a Carbon-owned record,
which the plan had mis-cited as precedented and the fill proved anyway. One
design-fidelity hole caught by review (non-aggregate imported unions were
initializable from Carbon) closed at the root._ FORTY-THREE PRs. Unions exist
natively: the design's write-safe, read-reinterpret union with C++-compatible
layout by construction, its 0.1 field rule made precise (prelude `Copy` impls
are trusted; user `Copy`/`Destroy` impls, choice-typed and imported C++ fields
rejected loudly), and the first `Core.UnformedInit` witness a class type ever
synthesized. The deferral defect was a one-list omission in the parser that no
review caught by reading — the hosted fill caught it in minutes, which is
exactly what the fill is for._ FORTY-TWO PRs. The error-handling remainder is
closed: a C++ exception crossing into Carbon is either fenced (terminate, now
with a message naming the boundary) or, when the call is the operand of `?`,
caught into a `Cpp.Exception` that `?` propagates, and a Carbon `Result` crosses
back into C++ as a byte-compatible `Carbon::expected`. The slice cost seven
hosted round trips; every one was a real defect fixed at its root and each is
written down, including the pre-existing export-namespace crash that only a real
header could expose._ FORTY-ONE PRs. The design's if-let family exists: a `let`/`var`
pattern in an `if`/`while` condition or a `let … else { diverge }` declaration
runs through the same refutable engine as a `match` arm, so every pattern form
`match` accepts (alternatives with payloads, tuples, literals, `var`/`ref`
bindings, structs) works there too and gains nothing new to maintain. Two
authoring errors in the positive goldens were caught by the hosted fill and
fixed at the source; the second autoupdate round converged the location markers
the first fill's inserted CHECK lines had shifted (a known two-pass property of
autoupdate — always run it twice when a fill inserts STDERR lines above dumped
code). Existing match goldens: byte-identical._ FORTY PRs. The error-handling
remainder's first slice: the design's `Core.Result` finally exists in the
prelude (the first `match` compiled inside package `Core`), `?` works on both
`Result` and `Optional`, and a `Result`-returning entry point turns into an exit
code plus a stderr line naming `E`. Two runner-exposed corrections recorded as
review misses per R28(d): a symbolic `T` bound by a non-`type` facet carries
only its declared interfaces (so moving it needs `Destroy`), and `PadToType`
CHECK-failed on a folded zero-sized choice constant (`U.A(())`) — fixed at the
root, not papered over. Eight lower goldens moved by debug-info line numbers
only. Lesson banked in the workflow: file_test isolates crashes and exits 0, so
the hosted autoupdate now greps its own log for stack dumps._ THIRTY-NINE PRs.
The design's canonical `var my_opt: Optional(i32) = Optional(i32).None;` now
compiles and runs: LookupChoiceCopyWitness mirrors the destroy witness
(is_choice gate, symbolic deferral under the SF-6 triviality fence, concrete
builds by way of BuildPrimitiveCopyWitness), the Copy dispatch case leaves
upstream's TODO block with the TODO intact, and the lower PrimitiveCopy arm
gains the return-slot form. One genuine regression root-caused pre-merge
(arity-vs-repr misdispatch on monomorphized slot-carrying calls — lesson: repr
questions are answered at call sites, not signatures; mono_from_generic pins the
class). The fork's tripwire flipped exactly as its header predicted (§2.6
re-derived). Declared + pinned: user out-of-line choice Copy impls are shadowed
by the synthesized witness (the Destroy posture). Floor UNCHANGED **96/0/28 over
124**, 43/56 bullets; the roundtrip pair restored doc-verbatim. Next:
conformance depth or a W-008 slice (unblocks W-066)._ THIRTY PRs. The sanctioned
import_ref.cpp amendment round, plan-first: one contiguous 20-line hunk peeks
through non-constant ExportDecls in TryResolveInstCanonical (Done(NotConstant),
the eval-forwarding invariant CHECKed; V-3a sanction proven by the design's
export-name sentence + p003938 + upstream's own var-export golden). Six probes
with fills audited against pre-registered predictions verbatim; the W69a
ExportDecl chase arm got its first lower-side pin (one _Cx.Main across the
export route). Floor UNCHANGED **96/0/28 over 124**, 43/56 bullets. Both reviews
APPROVE; the probe-placement deviation recorded. Upstream's
non-constant-BindNames TODO sits at the hunk boundary — the weekly merge
surfaces any collision. Next: W-075 (choice alternative-constant copy gap — V-3a
check first) or conformance depth; W-066 stays blocked on W-008._ TWENTY-NINE
PRs. The adjudicated W69h follow-up landed: the SKIP stub became a real 5-unit
multi-unit program (api/impl split runtime-load-bearing with a visible LINK-FAIL
failure mode; the export Rect + export-import chain compile-arbitrated in
series; the W-074 crash shape deliberately dodged). Floor **96/0/28 over 124**
(this one program SKIP→PASS, verified line-by-line; the Libraries bullet was
already PASS). One clean adversarial review; comment-only folds. Next: W-074
(import_ref amendment round — upstream-hot, small plan round first), W-075
(choice alternative-constant copy — V-3a check), conformance depth; W-066 stays
blocked on W-008._ TWENTY-EIGHT PRs. The three-slice workstream closed an
upstream-acknowledged gap: W69a's lowering-side promotion (lane a1 — exported
backing storage minted at lowering, SemIR/import_ref untouched, GetValue routing
reachable only where the old CHECK crashed), W69h's multi-unit conformance
capability (directory programs, per-unit compile mirroring upstream's bazel
rule, byte-identical rerun arbiter), and W69b's pointer-rep arm + the restored
runtime `let g` acceptance split + BOTH discharge arbiters incl. the fork's
FIRST multi-unit program. Floor **95/0/29 over 124** (evidenced twice,
addition-only), 43/56 bullets. Twelve review rounds; three honest defect rounds
rode the close (W-074 export-x crash minted; W-075 alternative-constant copy gap
minted; the pre-existing AcquireValue folded-ref crash FIXED fenced;
aggregate-consumption residue recorded). The C<name>.<package> let-storage
symbol shape is a divergence-register entry reviewed at each weekly merge; the
three-golden PromoteObject churn was adjudicated accept-and-declare (R-7's
falsifier fired as designed). Next: W-074/W-075 (new S candidates), the
library_multifile_export un-SKIP follow-up (unblocked by W69h), conformance
depth; W-066 stays blocked on W-008. TWENTY-SEVEN PRs. Single-alternative and
empty choices now pass the match scrutinee gate: the discriminant repr walk
factored into a shared query (`IsMatchableChoiceType` — integer OR empty-tuple
discriminant, anything else fails safe), constant-true dispatch (the W-067
shape) where no integer discriminant exists, real payload extraction (lower
golden pins `br i1 true`, no icmp), and the S2e exhaustiveness machinery needed
zero arithmetic change. Empty choices = lane (b): type admission only (no
zero-arm grammar minted — design-grounded, recorded loudly with an amended-at
marker after a review catch). Four fail_todo pins flipped, each verified
sanctioned (R16a). Floor **93/0/29 over 122**, 43/56 bullets. Reviews: A APPROVE
zero should-fixes; B no blockers. One-pass CI (fast compile → autoupdate +1311
with no-commit fixpoint → gate → conformance, exact floor). Hook-environment
quirk recorded (distro clang-format 18.1.3 vs CI pin 21.1.8). Next: the W-069
plan round (cross-file runtime `let` lowering — upstream gap, V-3a check
first)._ TWENTY-SIX PRs. `default if (E) => ...` is now a working fork feature
under the design's own license (pattern_matching.md Guards; p002188): shared
parse guard production with default+if lookahead (arms after a guarded default
are reachable), check-side guarded-irrefutable-arm CFG (constant-true test +
spliced guard; failure edge line-for-line the case-guard shape), and the
exhaustiveness pin — a guarded default never discharges the `default`
requirement, enforced structurally and falsified by two red-line fail goldens.
Zero new diagnostics (R6). Floor **92/0/29 over 121** (moved only by
control_flow/match_guarded_default.carbon on the already-PASS match bullet),
43/56 bullets. Reviews clean; coverage falsifiers added at the review round.
Mid-slice the self-hosted runner died ~07:33Z (killed the first gate attempt
mid-test — diagnosed infra by step-level evidence, re-fired green after the
runner returned ~09:20Z; recorded, CI unchanged). Next: W-068
(fewer-than-two-alternative choices), then the W-069 plan round._ TWENTY-FIVE
PRs. The two-regime sweep landed across the nine-file surface: seven non-final
sites got scope-qualifying retext only (all four golden retexts
line-count-preserving — runner autoupdate was a STRICT NO-OP, run 32097812689);
the W72b pair (final impl) took the simplification (`return
self.(Core.Try.Branch)();` replaces the deleted `Diverge` helper — re-arbitrated
green at runtime by conformance run 32098017538, the first-ever lowering
exercise of the collapsed recursive-call shape); error_handling.md got a dated
fourth-round re-correction and its final sketches now use the recursive trailing
return. Floor unchanged, EXACTLY 91/0/29 over 120, 43/56 bullets. Review round:
no code defects; blocker (arbiter run not armed by the landing commit — same
class as the W72b round, recurrence noted) already resolved by the follow-up
bump; bookkeeping fixes landed. Residue recorded not actioned:
question_final.carbon, lower/question_generic_final.carbon, and
fail_question_final.carbon still carry `Diverge` inside final impls (comment
refresh rides any future touch). Next: conformance depth (W-066) + residues
W-067/W-068/W-069._ TWENTY-FOUR PRs. The continue-THREADING runtime arbiter
(question_generic_thread_diff: `final impl forall` + load-bearing Combine
chaining, i32 AND i64 with high-half-significant wide seeds, C++ template
oracle) went green at exactly the target floor — **91/0/29 over 120**, bullet
count still 43/56 (the pair deepens the already-PASS error-handling bullet to 4
programs). Three CI rounds, all honest: round 1 COMPILE-FAIL root-caused to the
bare `[T: Combinable]` facet lacking the implicit Destroy witness the `type`
facet carries (fixed with the precedented `& Core.Destroy` conjunct — a
test-authoring defect, not a toolchain defect); round 2 the R-5 broken-oracle
drill, red as the predicted DIFF-MISMATCH (run 32096324806); round 3 the
discharge run (32096689454). Two adversarial reviews folded pre-merge
(discharge-run wiring blocker; i64 truncation blind-spot widened away; (a)/(b)
V-3a vetoes recorded on the log; W-073 sweep surface grown to nine files). W-072
DISCHARGED per plan §6 in full; W-073 (the Diverge-idiom and comment-family
sweep) unblocks next. Scoreboard history: ... → 88 F8b → 89 F8c → 90 F8d → 91
W72b._ TWENTY-THREE PRs. The B2a-era "hard limit" (generic `?` continue values
untheadable as `T`) dissolved with ZERO compiler change: non-reduction through
non-`final` impls is upstream-DESIGNED; the ratified error_handling.md sketches
spell `final impl` and B1b's testdata dropped the keyword (R17 postmortem + new
rule R27 landed — sketch-implementing testdata is diffed against the sketch's
exact spelling). `let v: T = mr?;` now compiles clean (direct/mixed/import,
SemIR-pinned as genuine reduction). P-9 SURPRISE: the in-body recursive-Branch
call ALSO collapses under `final` — W-073 minted (evaluate retiring the Diverge
idiom + the eight-file comment family). W72c (Try success ctor) parked in the
SF-9/S3p brief with the `final`-spelling recurrence flag. Floor unchanged
90/0/29 over 119; W-072 stays OPEN until W72b's continue-THREADING runtime
differential (91/0/29 over 120) goes green._ TWENTY-TWO PRs. F8d closed the
workstream on the FIX path (degrade never needed): `std::thread(Carbon::Work)`
constructs directly — a concrete non-generic non-member Carbon function maps to
a pointer to its exported decl, argument embedded as DeclRefExpr+decay, mapping
confined to the call-argument path (a correctness-review blocker narrowed it;
export-side function types still diagnose), same-signature thunk collisions
probed and fixed by way of mangled-suffix asm labels. 90/0/29 over 119, 43/56
bullets. F-008 TOTALS: 4 slices, 4 PRs, 8 adversarial reviews, 3 pre-merge
blockers fixed, D1/D2/D3 all FIXED (W-021/022/023 discharged; W-020 doc half
stays digest-gated). The fix's movement reached two upstream goldens whose
function-argument cases now compile._ TWENTY-ONE PRs. F8c landed
adjudication-first (plan adjudication D): the real-header run refuted H0 live
(undefined `_Ctotal.Main.2`/`.3`), the fix is module-symbol-table reuse in
`BuildNonCppGlobalVariableDecl` (the global-side sibling of the function path's
name-keyed dedup; W-022 DISCHARGED), and the fired H0-mock-divergence
stop-and-explain path is filed per §2.3 (a strictness-review catch). 89/0/30
over 119; specialization-typed Carbon globals now link and run (`std::atomic<i64>`
bumped by two bridge threads against the oracle). Remaining F-008: F8d only (`std::thread(carbon_fn)`
— p003848 upstream re-check first; documented-limitation degrade sanctioned)._
TWENTY PRs. F8b: trivially-destructible exported classes drop the C++ destructor
thunk (predicate reuses CanDestroyType's classification; the review round's
impl-population blocker resolved by mirrored cross-IR enumeration with a
two-file falsifier golden; W-021 DISCHARGED); std::atomic(CarbonClass) runs
store/exchange/load against its C++ oracle at runtime; the threading/atomics
bullet flips — **43/56 bullets**, 88/0/31 over 119. Remaining F-008: F8c
(specialization-global link; real-header adjudication run FIRST), F8d
(std::thread(carbon_fn); documented-limitation degrade sanctioned)._ NINETEEN
PRs. F-008 is underway per fork/f008/plan.md: F8a landed the zero-flip harness
(two green thread programs on already-PASS bullets — H-P pthread linkage
CONFIRMED live; three SKIP defect arbiters quoting the measured diagnostics;
-pthread oracle line; 86/0/33 over 119). Next slice F8b:
std::atomic(CarbonClass) destructor-thunk fix — the threading bullet flips
there; then F8c (specialization-global link, real-header adjudication first),
F8d (std::thread(carbon_fn), degrade path sanctioned)._ EIGHTEEN PRs merged. B2a
landed as PR #18: the language-wide symbolic-choice destroy widening (W-071
discharged, the `?` symbolic-operand gate deleted), PLUS the mixed-width
miscompile its differential arbiter caught — root-caused per the no-slop
directive to POISON covering-template filler
(`EmitAsConstant(UninitializedValue)`, upstream-authored; SROA whole-scalar
poison under partial overwrite; fixed to zeros, p000257-sanctioned, flagged
upstreamable) after two implemented-then-refuted candidates (full three-round
record in fork/b2/mixed-width-diagnosis.md), PLUS coalescer hardening (sret
pointee in type fingerprints; absent-fingerprint pairs never merge; builtin
callees fingerprinted by value — upstream dedup goldens restored). Scoreboard
84/0/30 over 114; W-072 minted (projection non-reduction, Try
success-constructor gap). B2b = the SF-9 brief in PR #18's body (options a/b/c;
default (c) defer). OPEN user asks: SF-9 brief, Trivial→NonTrivial ratification
(PR #18 digest item 1), design-docs veto digest (2026-07-20). Next workstream:
F-008 threading fixes per the approved amended plan (coordinator sign-off
2026-08-17)._ SIXTEEN PRs MERGED to `trunk`. B1 is complete across PRs #15/#16:
postfix `?` parses, desugars through the fork's FIRST prelude additions (`Core.ControlFlow`
and `Core.Try` in `prelude/try`), and propagates at runtime over user-defined
generic-choice Results — `Ok(v)?` yields `v`, `Err(e)?` converts and
early-returns, verified against a C++ early-return oracle. B1b took four golden
cycles (prelude `ImplicitAs` import for the first prelude `choice`; trailing
unreachable returns after exhaustive matches — reachability ignores
exhaustiveness; the projection-non-reduction trailing-return correction plus the
symbolic-operand narrowing W-071: `?` on SYMBOLIC-typed operands is TODO-gated
pending a `Destroy` bound decision on `Try`'s associated constants — future fork
material). `Check Dependent PRs` is now guarded upstream-only (it hardcodes
upstream and passed by number coincidence). W5-S3 is COMPLETE across PRs
12/13/14: S3a (payload-free generic-choice specifics as match scrutinees), S3b
(payload synthesis + per-specific layout — five CI cycles, each defect
root-caused before the next push, see the decision-log five-cycle addendum;
headline sub-decision: `ResolveSpecificDefinition` recursion guard redesigned to
incremental publication; imported-binding constants advance upstream's
let-import TODO; W-069 records the cross-file runtime-let gap), and S3c (payload
destructuring on specifics + `sum_types.md:60-89` landing as a runtime
differential — declaration and no-`default` match verbatim, construction adapted
per the disclosed `Core.Copy` gap; W-010 generic residue CLOSED, W-011 choice
half closed). `Optional(T: type) { Some(value: T), None }` now declares,
constructs, matches, and destructures through specifics at runtime with
per-specific layouts. Go-forward: **one workstream = one branch off `trunk` =
one focused PR**.

**Upstream advance (2026-10; standing rule 5, D-UA-13):** the cut is upstream
`c1e83b0b7` (2026-10-05, PR 7897) as of the UA-1 merge (PR #50, 14801f14a); the
deferred set is EMPTY at the merge. Staged on
claude/carbon-fork-0-1-upstream-advance per fork/upstream/plan.md (183 commits,
105 conflicts, five hosted fill passes, four fix/triage rounds), pre-merge
scoreboard 126/0/23 over 149 (run 37399118672), gate 37403008794 and conformance
37402970811 (128 PASS / 0 FAIL / 22 SKIP over 150 programs, 48/56 bullets) on
606a99c5a; full record in the decision-log entry "Upstream advance 2026-10: cut
631f8fb → c1e83b0b7 (2026-10-06)". Weekly check: the Routine `Weekly
upstream-merge check (carbon fork)` keeps its prompt (it measures from `git
merge-base`, D-UA-13); its first post-advance firing, Monday 2026-10-12, should
report a SMALL deferred set (upstream's commits since c1e83b0b7, one week's
worth) and no fork-modified overlap beyond the usual check-core files; a large
count or a conflict in a non-check-core file is the signal to look at. The
PREVIOUS outcomes (2026-08-17 and 2026-08-08) are retained below for the record.

**Weekly upstream-merge outcome (standing rule 5, 2026-08-17, PR #17):**
upstream `864845c` (15 commits over e7050af, covering the 08-10 AND 08-17
firings — the session was credit-suspended between them) staged, 9
golden-only conflicts (zero code), two-pass R26 reconciliation (a
header-split snippet-number pair converged on pass 2), gate green,
conformance 83/0/30 over 113 non-regressing, merged as PR #17. Ops: a
GitHub codeload 503/429 outage killed several runner jobs at Set-up;
`4ea5ef4` (ImplWitnessTable fingerprints) flagged for the in-flight B2a
coalescer work. Next check: Monday 2026-08-24 14:00 UTC. The PREVIOUS
outcome (2026-08-08) is retained below for the record.

**Weekly upstream-merge outcome (standing rule 5, 2026-08-08):** upstream
`e7050af` (37 commits over the ten-day gap; struct-pattern parsing,
parse-dump format change, clang-module-per-file interop, RTTI/exceptions
off) staged on the S2d tip, 16 conflicts resolved (2 code, 14 goldens),
runner-reconciled to R26 fixpoint, gate run 42 green, merge-integrity
audit OK (its one blocker adjudicated false: upstream de-marked
overloads.carbon's dump ranges), conformance floor held, merged by way
of PR #9. Ops notes: the runner host's glibc upgrade made runner-built
binaries unrunnable in the dev container — conformance now runs on the
runner by way of the new `Fork: conformance suite` workflow
(fork/conformance-request.txt trigger, scoreboard committed back);
Nightly Release is guarded to the upstream repository (user decision — the
workflow needs an upstream-only GCS credential and never built fork
code). Next check: Monday 14:00 UTC.

## Branches

| Branch | State |
| --- | --- |
| `claude/carbon-fork-0-1-ua2` | HELD OPEN as PR #51 — UA-2 reconciliation at 05a5c30f7, fill + of-record conformance 37413300832 (131/0/19 over 150) done, gate impossible (Actions disabled); merge when a gate runs. |
| `claude/carbon-fork-0-1-cmake` | HELD OPEN as PR #52 — CM-1 CMake integration at ea573f672 (gap rows 84/87 expected DONE, W-060/W-061 discharged, W-128..W-133); verification record in the PR; merge when the land sequence runs. |
| `claude/carbon-fork-0-1-safe` | HELD OPEN as PR #53 — SAFE-1 safe-Carbon design (F-013) at adaae4e35, documentation and records only (gap row 89 expected DONE on document review, W-063 discharged, W-144..W-150); merges first in the land sequence after RG-1's PR (fork/register/rg1-plan.md section 5). |
| `claude/carbon-fork-0-1-ev` | HELD OPEN as PR #54 — EV-1 evaluator guides and twelve transcribed programs at cb3ef2e74 (W-062 discharged; W-152, W-153, W-155 filed; expected 137/0/22 over 159); state T, merges after PR 52 through its state C integration commit. |
| `claude/carbon-fork-0-1-st` | HELD OPEN as PR #55 — ST-1 str comparison, Core.StringBuf and concatenation (F-014) at 21307851a (W-057 discharged; W-160..W-167 filed; expected 133/0/21 over 154); merges after EV-1. |
| `claude/carbon-fork-0-1-op` | HELD OPEN as PR 56 — OP-1 Core.Optional comparison and F-015 at 894139b34 (first held at 379f20f67; amended 2026-10-21 by DR-1's W-323 records commit, which corrects the loops.md amendment, OP-1's V-3 paragraph, optional.md's matchability text and W-177's route, the description refreshed; W-058 discharged; W-170..W-179, W-195 filed; expected 132/0/25 over 157; row stays PARTIAL); merges after PR 55. |
| `claude/carbon-fork-0-1-op2` | HELD OPEN as PR 57 — OP-2 Core.Optional ownership, the MaybeUnformed representation fix, checked Get and F-016 at a080c7886 (first held at 628273444; a080c7886 merges PR 56's W-323 commit, the description refreshed), stacked on PR 56 (W-170, W-171, W-173 discharged; W-196..W-201 filed; expected 139/0/22 over 161; Optional row DONE expected); merges after PR 56, before DD-1. |
| `claude/carbon-fork-0-1-ox` | PARKED at plan rev 6 (pushed as a record, head 14f06b8b3, no PR; decision-log entry "OX-1 parked") — OX-1 operator export to C++ (W-054, gap row 48 stays MISSING): four focused re-reviews, the export mechanism leaks into Carbon's own resolution; W-202..W-211, W-245..W-249 and F-017 reserved and unused; a future plan must separate operator exports from the Sema Carbon's own lookup consults. |
| `claude/carbon-fork-0-1-va` | HELD OPEN as PR 59 — VA-1 definition-checked variadics slice 1 at b0822a744 (W-013 open with the slice recorded; W-212..W-230 filed; W-231 unused; expected 137/0/21 over 158; row 53 PARTIAL expected); merges after PR 58. |
| `claude/carbon-fork-0-1-dd` | HELD OPEN as PR 58 — DD-1 design docs without placeholders at fcee90d9b (W-065 discharged; W-182..W-185, W-188, W-189, W-191..W-194 filed; W-240..W-244 reserved, unused; expected 147/0/22 over 169; row 70 DONE expected; row 91 PARTIAL until state L); four document-review rounds folded; merges last of the held PRs through its state L integration commit. |
| `claude/carbon-fork-0-1-sc` | HELD OPEN as PR 60 — SC-1 template-style structural conformance (F-010) at 40a76ab81 (W-027 implemented; W-134..W-143, W-151, W-168, W-169, W-232..W-239 filed; expected 130/0/21 over 151; gap row 55 PARTIAL expected); eighteen fill rounds, round 17's toolchain change reviewed with no MAJOR or BLOCKER and the branch found dry; merges after PR 52, before PR 54. |
| `claude/carbon-fork-0-1-tp` | HELD OPEN as PR 61 — TP-1 integrated templates at e408ad4d6 (toolchain 813804758; W-014 open with the slice recorded; W-250..W-274 filed, W-272 discharged within TP-1; expected 137/0/22 over 159; gap row 54 stays PARTIAL); nine focused re-review rounds after the implementation review, round 9 dry; round 10 opened after the PR on an external finding (X-1, a crash where trunk diagnoses, fixed at the root at eafca5cb9) and found only MINORs; round 11 (one golden, no toolchain file) DRY at 5661a35c8, six MINOR records-only findings folded; W-295..W-298 filed from the block W-295..W-299 reserved to TP-1 (W-299 unused); the description and first comment re-posted at 5661a35c8; expected 138/0/22 over 160; merges last, after PR 59, through its land-time commits M, S, F6, L and the records commit. |
| `claude/carbon-fork-0-1-sv` | HELD OPEN as PR 62 — SV-1 std::optional and std::variant interop mapping at 0ef8a0334 (toolchain 4a9c18b07; first held at 3a6531157, then amended 2026-10-21 by DR-1's W-322 commit, which retires the D-SV-7 Core.Optional view under R32 (d), and its focused review's four MINORs folded, the description and first comment refreshed; W-011 DISCHARGED; gap row 68 stays PARTIAL, W-177 not narrowed; F-020 minted; W-275..W-277, W-279..W-281, W-285 and W-286 filed, W-284 held for M-VA, W-282 conditional at land time, W-283 and W-287..W-294 unused, W-278 withdrawn; expected 133/0/22 over 155 with the view's program SKIPped; gate 1950 of 1950); plan rev 5 signed off after five reviews, two implementation reviews folded in two fix commits, focused re-review round 2 dry; merges last, after PR 61, through its land-time items M, M-VA, F-M, Doc-M and the records commit. |
| `claude/carbon-fork-0-1-ct` | HELD OPEN as PR 64 — CT-1 C++ templates on symbolic Carbon type arguments, instantiated per specific, at 4a3220c11 (toolchain 224ee2f8f; base claude/carbon-fork-0-1-tp, stacked on PR 61; W-043 DISCHARGED, TP-1's W-273 discharged and W-268 narrowed; W-300..W-311 filed, W-312..W-319 unused; F-021 minted; gap rows 56 and 42 stay PARTIAL; expected 1959 of 1959 and 147/0/20 over 167); plan rev 4 signed off after four reviews, two implementation reviews folded in three fix commits, focused re-review round 1 dry; merges after PR 62 through its land-time items M, S-VA, L-F, L and the land-time records commit. |
| `claude/carbon-fork-0-1-dr` | HELD OPEN as PR 63 — DR-1a Core.Iterate.Next takes a ref cursor (R32; W-321 discharged) at 18a7e8934 (toolchain d0cfe8082; base trunk; expected 1942 of 1942 and 128/0/22 over 150); DR-1's plan rev 3 signed off with slice 1 (W-320, Match for Core.Optional) stopped on upstream's own conflict and blocked on W-324; W-324..W-327 and W-329 filed, W-328 reserved; one implementation review (three records-only MINORs) folded; plan rev 4 (f551057ea) records DR-1b's stop-and-amend; DR-1b (IndirectIndexWith, W-109) is HELD OPEN as PR 65 on claude/carbon-fork-0-1-dr-idx, stacked on this branch; merges after CT-1 through M-a and L-a, then DR-1b through M-b, C-b and L-b. |
| `claude/carbon-fork-0-1-dr-idx` | HELD OPEN as PR 65 — DR-1b element access through `IndirectIndexWith`, `Core.Slice` and `Core.Buf` writing through `Ref`, upstream 230227264 cherry-picked (R32; W-109 DISCHARGED) at fee0ef31c (toolchain 7a442f632; base claude/carbon-fork-0-1-dr, stacked on PR 63; expected 1946 of 1946 and 130/0/22 over 152); one stop-and-amend (plan rev 4), one implementation review folded at the root (fddfcf42a and its fill bcd9ba06f, the comment commits 8deb75262 and 7a442f632, and round 4's shrink-line split 0cd4e5d2e with W-340 filed), a focused re-review of four rounds (rounds 1 to 3 APPROVE-WITH-FIXES with comment-only MINORs and, at round 3, one MAJOR, RR3-1-M1; round 4 dry after the shrink line); merges after DR-1a through M-b, C-b and L-b. |
| `claude/carbon-fork-0-1-va2` | HELD OPEN as PR 66 (stacked on PR 59, base claude/carbon-fork-0-1-va) — VA-2 definition-checked variadics slice 2 at 43c8ab476 (2026-10-27; forty-two commits over PR 59's b0822a744: plan rev 1 to rev 16, C0, C0b, C1 to C5 with their fills, the fold's fix and fill, R, D, the re-review loop's four rounds with fix 3, fix 4 by D-VA2-19's break condition, their fills and records; 104 findings over twenty-one reviews, all folded, none rejected, round 4 dry; W-225 discharged, W-212 and W-213 narrowed, W-330..W-339 and W-345 filed; gap rows 53 and 74 stay PARTIAL; expected, not of record: 1977 of 1977 and 147/0/21 over 168); merges last after PR 65 through M, S-CT, F-M, L-F and L. |
| `claude/carbon-fork-0-1-rg1` | RG-1 records, the V-3a register classified at upstream f27a977d8 (W-342 discharged; W-343 and W-344 narrowed, W-344 discharged at R2, W-343 by the last land-time note), base trunk 0b999d449: plan fork/register/rg1-plan.md, with the register's check scripts and tables beside it (check_quotes.sh, check_greps.sh, rg1-quotes.tsv, rg1-checks.tsv); R1 files W-346 (EH-C), W-347 to W-351 and W-353 (SAFE-1, PR 53), W-352 (OP-1, PR 56), W-354 and W-356 (UA-3) and W-355 (the weekly check); the held records commits on PR 53, 52, 60, 55, 56 (merged into 57), 61 and 64 (with 61 merged) follow after two implementation reviews; to be held open as its PR after R2, first in the land sequence. |
| `claude/carbon-fork-0-1-upstream-advance` | MERGED by way of PR #50 (14801f14a) — UA-1 (cut 631f8fb → c1e83b0b7); gate 37403008794 / conformance 37402970811 on 606a99c5a. UA-2 reconciliation cuts from the new trunk. |
| `trunk` | Integrated line: match re-platform S2a-S2e + W5-S3a generic-choice specifics + B0 + W5-S1/S2 + upstream e7050af. Base all new work here. |
| `claude/carbon-fork-0-1-{b1,b1b}` | MERGED by way of PRs #15/#16 — error-handling B1 complete. |
| `claude/carbon-fork-0-1-w5-s3{,b,c}` | MERGED by way of PRs #12/#13/#14 — W5-S3 complete. |
| `claude/carbon-fork-0-1-match-{replatform,s2d,s2e}` and `claude/carbon-fork-0-1-upstream-2026{0728,0808}` | MERGED by way of PRs #7/#8/#9/#10 and #6. |
| `claude/carbon-fork-0-1-w5` | MERGED by way of PR #3 (composition gate run 30 green). |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | STRANDED source for the F-008..F-011 design docs (the veto-digest gate dissolved under R29). The F-009 overloading page (functions_overloading.md + its cross-references) is PORTED by the OV-1/OV-3 slices — do not re-land it; the F-008/F-010/F-011 portions are ported by their own workstreams (F-011's if-let docs landed with W-012). Reconstruct per the recipe pattern used for b0/w5 (overlay real content onto fresh branch off trunk; targeted-merge diverged files; prek + gate + PR). |
| `claude/carbon-fork-0-1-{7mwfb7,b0,7mwfb7-upstream-20260727}` and other `7mwfb7-*` | MERGED or superseded; do not stack new commits. |

### Scoreboard (source of truth: run the suite, don't trust this line)

126 PASS / 23 SKIP / 0 FAIL programs (149 total); **47/56 bullets green**
(GitHub-hosted scoreboard at the PR #48 head, run 37357609478; verified from
fork/conformance/out/scoreboard.json — the error-handling control-flow bullet is
the fork's first error-handling flip, now 4 programs deep incl. the W72b
threading arbiter). History: 73 → 77 at S2d/S2e → 78 at PR #11 → 79 at S3a → 80
at S3b → 81 at S3c → 83 at B1b (error_handling/control_flow_constructs flip +
question_propagation_diff, a C++ early-return oracle) → 84 B2a → 86 F8a → 88 F8b
→ 89 F8c → 90 F8d → 91 W72b → 92 W-067 → 93 W-068 → 95 W-069 → 96 multifile →
100 W-076 → 101 W-078 → 102 W-077 → 106 EH-A → 108 W-012 → 112 EH-B → 114 UN-1 →
116 UN-2 → 118 OV-1 → 121 OV-2 → 124 SL-1 → 126 OV-3 → 128 SL-2. The scoreboard
regenerates on GitHub-hosted runners only (`Fork: hosted verification`, mode
`conformance`; R28).

### CI on jmann345/carbon-lang (GitHub-hosted only — R28)

-   `Fork: hosted verification` (`.github/workflows/fork_hosted.yaml`,
    workflow_dispatch input `mode` ∈ compile | autoupdate | gate |
    conformance) on ubuntu-22.04, reading upstream's public remote cache
    through `./.github/actions/build-setup-common`: compile ~18 min,
    autoupdate ~13 min (fails on any stack dump / CHECK failure in its
    own log; pushes the fill back to the ref), gate ~25 min (`prek
    --all-files` + `bazel test //toolchain/...`), conformance ~20 min
    (commits `fork/conformance/out/scoreboard.json`). Per-ref
    concurrency; dispatch gate + conformance only after the autoupdate
    push, since a queued run pins the SHA at dispatch time.
-   The four self-hosted workflows (`Fork: build toolchain`, `Fork: fast
    compile check`, `Fork: autoupdate testdata`, `Fork: conformance
    suite`) are workflow_dispatch-only and are NEVER dispatched: the
    owner's machine is off limits (R28; runner files removed by the
    one-shot `fork_runner_cleanup.yaml`, run 36229750515).

### Toolchains in the container

-   `/home/user/arbiter/carbon_toolchain-0.0.0-0.nightly.2026.07.19/bin/carbon`
    — upstream nightly
-   `/home/user/trial-tc/carbon_toolchain-0.0.0-0.dev/bin/carbon` — fork-built
    with match
-   The container's clang 18 cannot build the toolchain, but `clang++-19`
    with libc++ (installed 2026-10-05) and the tablegen outputs built from
    the bazel-cached llvm-project give a `-fsyntax-only -std=c++20` check
    under the toolchain's `-Werror` set: the harness is
    `scratchpad/syn/check_one.sh <path>` (per-worktree variants). It
    catches compile errors in a fix round before the hosted autoupdate
    does; it proves nothing about behavior, and the hosted runs stay the
    arbiter (R28).

### Next actions (dependency order)

1.  **DR-1 (fork/direction/plan.md, rev 4, signed off)**: DR-1a, the `ref`
    cursor (W-321), is held open as PR 63 and DR-1b, `IndirectIndexWith` (W-109,
    stacked on DR-1a), as PR 65; W-322's removal-only commit on PR 62's branch
    (0ef8a0334, reviewed) and W-323's records commit on PR 56's branch
    (894139b34), merged into PR 57's (a080c7886), are made, and the three
    descriptions are re-posted; W-320 (`Core.Optional` matchable by `Match`)
    stopped at the plan on upstream's own conflict, watched by W-324 at each
    weekly upstream check. Both DR-1 PRs merge after CT-1 (PR 64).
2.  **VA-2 (definition-checked variadics slice 2)** is held open as PR 66
    (claude/carbon-fork-0-1-va2 at 43c8ab476, stacked on PR 59): generic and
    heterogeneous packs (W-212, narrowed), tuples with one pack segment (W-213,
    narrowed) and variadic impls with the prelude tuple `Copy`, `Eq` and
    `Ordered` (W-225, discharged; gap rows 53 and 74 stay PARTIAL). It merges
    last, after PR 65, through its land-time items M, S-CT, F-M, L-F and L
    (fork/variadics/va2-plan.md section 3 item 15, D-VA2-18, section 6.2 and
    section 8.8, and the branch's ORCHESTRATION Next actions item 6, which
    spells each out); before M, item 10 below is decided and hand-off notes 7
    (PR 59's array-stride layout) and 9 (item 13 below) are ruled. After it:
    the match residues W-076, W-078, W-079 and W-080 (W-066 was discharged
    2026-09-26; W-008's open residues are those four), the exception-interop
    residues W-083..W-085 and W-123, and the lowering fatals W-041 with DR-1's
    audit residues W-325, W-327 and W-329.
3.  Reconstruct + land design-docs (F-008..F-011) — **gated on the
    user's veto-digest response** (presented 2026-07-20, unanswered).
4.  W5-S3p (prelude Result/Optional) is no longer gated: SF-9 was decided by
    D-EH-1 (2026-09-27, the class identity kept) and EH-A landed Core.Result and
    Optional's Try impl (W72c Try.FromContinue and the `final`-spelling
    recurrence flag rode with it); W5-S4 (std::variant mapping) landed as SV-1,
    held open as PR 62. Residues: W-067 (default-clause guards), W-068
    (fewer-than-two-alternative choices), W-069 (cross-file runtime let), W-070
    (unit break types, discharged at EH-A by D-EH-2), choice `Core.Copy`
    construction gap, tuple/var/ref/compile-time case patterns, non-binding
    payload subpatterns (W-008).
5.  Conformance depth: differential pair per flipped bullet; scoreboard in
    CI when GitHub Actions is enabled again.
6.  **R32 work from the 2026-10-26 weekly check and RG-1 (2026-10-28)**: W-341
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
    each weekly upstream check: W-355 (run fork/register/check_quotes.sh and
    check_greps.sh over their tables at the tip, and re-read the break
    condition of every NONE and ALIGNED entry outside VA-2's, which items 8
    and 9 re-read), with W-324's re-check of C1.1 and H5.5 and W-326's of
    T5.7 and C1.2 (indexing.md:101-121 and a `like` in upstream's parse or
    check). UA-3 follows W-341 and W-346.
7.  W-332 (p002687's termination rule): owner VA-2 until it lands, then the next
    impl-lookup workstream; take upstream's implementation at each advance if it
    lands first.
8.  W-338 and W-339 (VA-2's V-3a register entries (v) and (vi)): at each weekly
    upstream check, re-read generics/details.md "Overlap rule",
    comparison_operators.md :311-316 and :457-464 and comparison.carbon's
    Compare TODO, and upstream's type_structure.cpp; open the realignment if
    upstream decides otherwise.
9.  W-214, W-217, W-230 (VA-2's V-3a register entries (iv), (i), (iii)): at each
    weekly upstream check, re-read variadics.md :219-221 with :532-546, :493 and
    p002240's "Omit each-names".
10. SC-1 (PR 60) with OP-2 (PR 57): on VA-2's land simulation and on the
    simulated trunk without VA-2 (fork/variadics/va2-plan.md section 8.7, `mall`
    and T*), SC-1's named_constraint/template_constraint.carbon split
    `self_facet_in_signature_required` fails after the fill with `unable to
    monomorphize specific <none>` at `fn Next(self) -> Core.Optional(Self);`,
    against OP-2's `DefaultOptionalStorage`; no plan names it. SC-1's and OP-2's
    owners decide which land-time fill or fix commit carries it, before either
    lands.
11. The a03, a19 and a20 class (upstream's defects; VA-2's M-20 and R-13): a
    `var` of a one-element tuple of a tuple of run-time values gives an
    indeterminate value (wrong code), and such a tuple initialized from a
    run-time call or returned stops at the `CHECK` `new_storage_id.has_value()`
    in check/convert.cpp, on PR 59, trunk and the nightly 2026.10.12. Request an
    id for the class and file it with an owner; W-330 to W-339 are all filed.
12. Core's `String.Reserve` and `String.Append`, which the design's StrCat over
    `String` needs with W-220 (VA-2's W-212, narrowed): request an id and an
    owner, the next Core.String workstream.
13. A pack expansion pattern in a choice alternative's parameter list (PR 59's;
    VA-2's RR4-1-m1 and the plan's hand-off note 9): `choice C { A(... each x:
    i32) }` passes VA-1's check and aborts in lowering at
    lower/file_context.h:187 ("Lowering symbolic type"), on PR 59, on VA-2 and
    on VA-2's land simulation alike; trunk and the nightly 2026.10.12 reject it
    at parse. Request an id for it and route the fix to PR 59 under its own
    review: in handle_pack_expansion.cpp's `Pattern` case, a list whose
    declaration is a choice alternative refused with a TODO, pinned by a
    `fail_todo_` split. VA-2 changes no file for it.

### Standing user directives

-   Design forks decided by the user; sub-forks follow the V-2 veto-digest
    model (synchronous only for genuine forks / directive-reversals /
    resource spends / scope changes; mundane ones auto-adopt + appear in a
    per-merge veto digest). Decision entropy, not importance, is the test.
-   Fixer is always a separate agent (R11); mechanical invariants by way of the
    edit hook (R12/R23); run `uvx prek run` locally before every push
    (R25); user is commit author, Claude co-author.
-   Upstream alignment is a veto criterion, not a permission gate (V-3a):
    contradicting accepted upstream direction is vetoed; ambiguity permits
    creative fork design at full speed. Amended 2026-10-21 (V-3b, R32, decision
    log DR-0): direction drifts are not permitted. The override clause is
    withdrawn: where upstream's recorded direction, read at upstream's tip, and
    a fork design diverge, the fork realigns. A second spelling of a mechanism
    upstream has designed is a drift even before upstream implements it.
