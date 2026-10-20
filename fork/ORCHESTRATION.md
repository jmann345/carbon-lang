<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

Last updated: 2026-10-12 (weekly check fired; BLOCKED: GitHub Actions on
the repository is DISABLED — every `workflow_dispatch` of `Fork: hosted
verification` returns "Actions has been disabled for this repository", the
repository's own scheduled workflows last ran 2026-10-08, the repository is
public, and this session has no access to repository settings — so under R28
there is no autoupdate, gate or conformance arbiter at all. The session was
also out of usage credits from 2026-10-06 04:30 UTC until this firing, and
the container was recreated in between (worktrees, the clang-19 syntax
harness and the bazel cache were lost; rebuilt: worktrees only). STATE: UA-2
reconciliation on claude/carbon-fork-0-1-ua2 at ace101b0d is complete —
three probes un-SKIPped and PASSING (templates_dependent_member,
cpp_template_symbolic_arg, cpp_template_on_carbon_generic; the two Box(T)
programs needed a constructor-initialized dependent `var` and a declared
`Core.Copy`, root cause an upstream limitation of the REAL prelude's
constrained `DefaultOrUnformed` impl, pinned by
check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon),
W-108 DISCHARGED on the fill (a `Core.Buf` field is freed through the
owner's synthesized SubobjectDestroy; an owner with its own `impl as Destroy`
still leaks — the 0.1 limit), ledger and gap re-cites done, of-record
conformance run 37413300832: 131 PASS / 0 FAIL / 19 SKIP over 150, 48/56
bullets — but its gate never ran: implementation review APPROVE-WITH-FIXES
(nine findings, all folded in round 3, 05a5c30f7: of-record runs recorded,
W-126 declared-owner leak and W-127 real-prelude `DefaultOrUnformed` limit
filed, the prelude pin's failing split retriaged to `fail_todo_` with its
CHECK lines cleared for the next refill); PR #51 is OPEN and HELD, not
merged — land sequence once Actions returns: autoupdate (one split) → gate →
conformance → merge. SC-1 (template structural conformance,
W-027) plan rev 2 signed off at e612aebc6 on claude/carbon-fork-0-1-sc after
two reviews (both APPROVE-WITH-AMENDMENTS); the commit-1 implementer died
with the credits and is NOT relaunched: new toolchain code cannot be filled
or gated. Weekly: upstream 62f1cc6a3 is 36 commits past the cut with 70
conflicting files (a tree-wide `ParameterizedClassType` rename); the cut
HOLDS, recorded in the decision log. OWNER DECISION NEEDED (R29: recorded,
not asked): re-enable Actions on the repository, or permit the session's
container to install bazelisk + LLVM 21.1.8 and build against upstream's
public read-only bazel cache (the tool-permission layer declined that setup
when attempted) — until one of these, no code lands. Next cron Monday
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

Later on 2026-10-14 (the TP-1 discharge; pushed, PR to open and hold): TP-1
(claude/carbon-fork-0-1-tp, fork/templates/plan.md rev 3, a W-014 slice with
W-127, W-183, W-192 and W-193, gap row 54 "Generics: Integrated templates") is
IMPLEMENTED AND HELD off trunk b2576f6c3, after two plan reviews (REJECT, 13 and
14 findings) and a focused re-review (APPROVE-WITH-AMENDMENTS, six), all folded
(rev 3 aaf43d5a4, signed off), and two implementation reviews (REJECT with seven
findings, APPROVE-WITH-FIXES with thirteen, nineteen distinct), folded by three
fix commits, none rejected and IR1-M3 narrowed and filed as W-266 -- C1
675e0dd94 (template-dependent initializers keep their storage; lowering reads
the specific), C2 637e3efaf (cross-library generics are a `semantics TODO` at
the `import`; dependent operations print as expressions), C3 438b3c971 (four
action kinds: dependent `*`, `->`, `&`, tuple element access and indexing, and
calls of function-typed values, checked on instantiation), C4 781908afb
(deduction through a class's arguments, deferred impl lookup), C5 df6487a05
(constraint lookup on instantiation), each with its autoupdate fill, P 32c8ed777
(eight programs, one with a C++ oracle), M 6efc3f257 (the merge of trunk
8bfd78ae3, records only), 4e1f07a91 (the state-T measurements), the fold's
7c7b1b170 (with a ninth program) and 12bd6d67a with their fills 17501c978 and
f360b8735 and its records commit 824f29c4e, R 35e2240b5 (row 54 PARTIAL, one
dated held-state sentence) and the discharge. W-014 stays OPEN with the slice in
its notes; W-250 to W-266 are filed after W-125, and W-267 to W-269 stay unused
(the id re-scan before D, over the 78 other fork and trunk refs: maximum W-249,
nothing in W-250..W-269 or F-019 elsewhere, so no re-allocation); F-019 is not
minted; the discharges of W-127 (PR 51's) and W-183, W-192 and W-193 (PR 58's)
wait for the land-time records commit, because those items are not on trunk.
Verification is container-built and NOT of record (Actions disabled): on the
head 824f29c4e, whose toolchain is the carbonbuild toolchain of 12bd6d67a,
file_test 1955/1955 and the expected scoreboard 137 PASS / 0 FAIL / 22 SKIP over
159, 48/56 bullets (scoreboard generated 2026-10-15T00:56:22Z), the nine
template programs the only change from the floor of record 128 / 0 / 22 over
150; all 25 mutants killed. In the held state S, F6 and L are measured, not
committed: composed over SC-1 1646988dc (with S) and VA-1 b0822a744, every
composed golden passes (1972 of 1972, 1973 of 1973), and PR 58's checker reports
0 errors with TP-1's toolchain on copies of fcee90d9b with Appendix C applied.
Not run: Bazel and its tests, hosted CI with its clangd-tidy step, ASan, macOS
and Windows, LLVM-side assertions, the owner's runner, and every land-time item
(fork/templates/plan.md, "Landed notes (TP-1, 2026-10-14)"). Merge order: PR 53,
PR 51, PR 52, SC-1, PR 54, PR 55, PR 56, PR 57, PR 58 through its state L
integration commit, PR 59, then TP-1 through its land-time commits M, S, F6 and
L (Next actions item 5). None is merged.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 1, folded;
pushed; RE-REVIEW ROUND 2 OWED): two reviews of the fold's
commits 7c7b1b170..bf8e1b4cc returned REJECT (one BLOCKER, two MAJOR, five
MINOR) and APPROVE-WITH-FIXES (two MAJOR, four MINOR), thirteen distinct
findings, all folded and none rejected (fork/templates/plan.md, "Focused
re-review of the fold (2026-10-15)", round 1): four toolchain fix commits with
their fills -- 632f92117 (a runtime result of a deferred action used as a type
is diagnosed at that operand in the specific, and a tuple type with a
`T.Elem` element lowers) with d069d639d, d8f6ab60a (an imported class template
whose field type or method declaration holds an action, and an imported
interface or named constraint whose declaration holds one, report W-250's TODO
instead of crashing) with 22b9074bd, 73b3124dd (dependent operations print with
their precedence and interface members by name) with 831289fad, and ba64734e7
(the diagnosed operand is an error in its specific, and a runtime `as` target
is diagnosed) with 1f0bc7be0 -- the formatting commit 67a9dd91c, and a records
commit. W-267 to W-270 are filed (an action's temporaries never destroyed,
`var e: T.Elem;` rejected where it is defined, `return {} as T;` for a class
without `Copy`, and an interface or named constraint whose later parameter's
type depends on a template parameter crashing in its own library), each the
same on trunk; TP-1 reserves W-250..W-274 and W-271 to W-274 stay unused; the
id re-scan over the 79 other refs finds the ids only in trunk's own
reservation sentence. Verification is container-built and NOT of record
(Actions disabled): on 1f0bc7be0 file_test 1955/1955 and the expected
scoreboard 137 PASS / 0 FAIL / 22 SKIP over 159, 48/56 bullets (scoreboard
generated 2026-10-19T15:28:25Z by the container clock); thirty-three mutants
re-run and killed, nine of them new; 213 probes swept on the fork, trunk and the
nightly, the fork stopping on none that trunk and the nightly do not stop on
the same way. `git merge-tree` of the head against trunk f3156a375 conflicts in
this file only, and merges trunk's stale TP-1 Branches row beside this one,
which the land-time merge drops (the PR body's "Conflicts"). Neither review
judged the branch dry, both re-measured bf8e1b4cc (gate 1955/1955,
conformance 137/0/22 over 159, 48/56 bullets, EXPECTED), and the fixer changed
six toolchain source files and four goldens, so RE-REVIEW ROUND 2 OWED: two
fresh reviews of 632f92117..c874c270f and the records commit that records
round 1, then a fixer for what they find; the PR opens and is held after a round
with no BLOCKER or MAJOR whose fixer changes no toolchain file. The merge order
is unchanged.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 2, folded;
pushed; RE-REVIEW ROUND 3 OWED): two fresh reviews of the round-1 fixer's
commits 632f92117..c874c270f and the records commit 764e55445 returned
APPROVE-WITH-FIXES (two MAJOR, one MINOR) and APPROVE-WITH-FIXES (one MAJOR,
three MINOR, two of them records only), seven distinct findings, all folded and
none rejected (fork/templates/plan.md, "Focused re-review of the fold
(2026-10-15)", round 2): four toolchain fix commits with their fills --
2165322c5 (every runtime operand that a specific needs constant is an error
there, so `array(x.0, x.1)` no longer stops the compiler) with e6a663c22,
123eb40ca (`->` prints as `p->n`) with 8af8ad78b, b678e2985 (a class
template's literal whose array field has a template-dependent bound is
converted on instantiation, as on trunk, and a deferred runtime literal with a
template value element lowers) with 7ea3fed97, and 94227d82c (an imported
entity whose data names one that cannot be imported reports W-250's TODO
instead of crashing after it) with 4fcbf62ef -- 282930a73, which makes two of
the new tests worklists for clang-tidy, f44280c1c with its fill 24bf5ea45,
which removes an aggregate-level deferral that the round's own fix had made
redundant, and a records commit. W-271 is filed (a generic class from another
library that declares a nested class or interface stops the compiler where the
class is used, with or without a template parameter, as on trunk and the
nightly); TP-1 reserves W-250..W-274 and W-272 to W-274 stay unused.
Verification is container-built and NOT of record (Actions disabled): on
24bf5ea45 file_test 1955/1955 and the expected scoreboard 137 PASS / 0 FAIL /
22 SKIP over 159, 48/56 bullets (scoreboard generated 2026-10-19T18:50:58Z by
the container clock); every mutant killed but the two recorded survivors; 284
probes swept on the fork, trunk and the nightly, the fork stopping on none
that trunk compiles. `git merge-tree` of the head against trunk f3156a375 and
each held PR gives the PR body's conflict table unchanged. Neither review
judged the branch dry, both re-measured 764e55445 (gate 1955/1955, conformance
137/0/22 over 159, 48/56 bullets, EXPECTED), and the fixer changed five
toolchain source files, four goldens and one program, so RE-REVIEW ROUND 3
OWED: two fresh reviews of the round-2 fixer's commits 2165322c5..bdc1f62d7 and
the records commit after them that records round 2's reviews, then a fixer for
what they find; the PR opens and is held after a round with no BLOCKER or MAJOR
whose fixer changes no toolchain file. The merge order does not change.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 3, folded;
pushed; RE-REVIEW ROUND 4 OWED): two fresh reviews of the round-2 fixer's
commits 2165322c5..bdc1f62d7 and the records commit aa57bfe1c returned
APPROVE-WITH-FIXES (one MAJOR) and APPROVE-WITH-FIXES (the same MAJOR, two
MINOR records only), three distinct findings, all folded and none rejected
(fork/templates/plan.md, "Focused re-review of the fold (2026-10-15)", round
3): 68102438e with its fill d0fbfd56b (W-250's import test follows each
reference the import loads, so an imported entity that names a template
through a callee, a specific's argument, a tuple or struct element or a field
reports the TODO instead of stopping the compiler after it), d54c37f91 (the
file records what each walk that reaches no action reached, so the wider walk
does not slow the gate), ada45a7c6 with its fill e7dc20a43 (three more splits
that pin what three of the round's mutants change), and the records commits
9923c79fc and 3afd3ec92 and a records pass over the reviews' runs; no residue
filed, W-272 to W-274 stay unused. Verification is container-built and NOT of
record (Actions disabled): on e7dc20a43 with d54c37f91's toolchain file_test
1955/1955 and the expected scoreboard 137 PASS / 0 FAIL / 22 SKIP over 159,
48/56 bullets (scoreboard generated 2026-10-19T20:56:03Z by the container
clock); every mutant of the walk killed but the seven recorded
survivors whose paths others cover; 110 cross-library probes swept on the
fork, trunk and the nightly, the fork stopping on none that trunk compiles.
`git merge-tree` of the head against trunk f3156a375 and each held PR gives
the PR body's conflict table unchanged (context.h and import_ref.cpp merge
cleanly). Neither review judged the branch dry, both re-measured aa57bfe1c
(gate 1955/1955, conformance 137/0/22 over 159, 48/56 bullets, EXPECTED), and
the fixer changed two toolchain source files and one golden, so RE-REVIEW
ROUND 4 OWED: two fresh reviews of the round-3 fixer's commits
68102438e..3afd3ec92 and the records commit after them that records round 3's
reviews, then a fixer for what they find; the PR opens and is held after a
round with no BLOCKER or MAJOR whose fixer changes no toolchain file. The
merge order does not change.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 4, folded;
pushed; RE-REVIEW ROUND 5 OWED): two fresh reviews of the round-3 fixer's
commits 68102438e..3afd3ec92 and the records commit f3f99c1c1 returned REJECT
(one BLOCKER) and APPROVE-WITH-FIXES (one MAJOR, two MINOR records only), four
distinct findings, all folded and none rejected (fork/templates/plan.md,
"Focused re-review of the fold (2026-10-15)", round 4): c841ad9e7 with its fill
043e67106 (a class template's literal whose field type is produced by a template
action, such as `T.Item`, `T.Item*` or a class `C(M + 1)`, is converted on
instantiation instead of stopping lowering), 0f2002243 with its fill e0facdb04
(W-250's import test walks the `require` declarations of an interface or named
constraint, so a parameter-dependent `require` that names a class template
reports the TODO instead of stopping the compiler after it), 6aa403cd6 with its
fill a1285a786 (a class value whose literal leaves a field to its default is
converted on instantiation too), b0501358f with its fill 3d6685b8b (a split that
pins the concrete `require` shape a mutant changes), and the records commits
after them (9db2fbb12; 7beed27b7, which completes it after a container restart
at 00:31 UTC on 2026-10-20 by the container clock, re-measuring 9db2fbb12 with
the same results; and a records pass over the reviews' runs, which re-measures
7beed27b7 with the same results and splits the PR description, moving its
verification record to the PR's first comment); one residue filed, W-272 (such a
literal that leaves a field to its default is rejected on instantiation, as on
trunk and the nightly), and W-273 and W-274 stay unused. Verification is
container-built and NOT of record (Actions disabled): on 3d6685b8b with
6aa403cd6's toolchain file_test 1955/1955 and the expected scoreboard 137 PASS /
0 FAIL / 22 SKIP over 159, 48/56 bullets (scoreboard generated
2026-10-19T23:30:16Z by the container clock); every round-4 mutant killed but
the seven recorded survivors whose paths others cover or no measured shape
reaches; the first review's 14 crash probes compile and run, and the ten
`require` probes that stopped the compiler after the TODO report it with no
crash, where trunk and the nightly stop all ten at the SpliceInst FATAL. `git
merge-tree` of the head against trunk f3156a375 and each held PR gives the PR
body's conflict table unchanged (round 4's convert.cpp and import_ref.cpp hunks
merge cleanly). Neither review judged the branch dry, and the fixer changed two
toolchain source files and three goldens, so RE-REVIEW ROUND 5 OWED: two fresh
reviews of the round-4 fixers' commits c841ad9e7..7beed27b7 (the fix commits
c841ad9e7..3d6685b8b and the records commits 9db2fbb12 and 7beed27b7) and the
records commit after them that records round 4's reviews, then a fixer for what
they find; the PR opens and is held after a round with no BLOCKER or MAJOR whose
fixer changes no toolchain file. The merge order does not change.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 5, folded;
pushed; RE-REVIEW ROUND 6 OWED): two fresh reviews of the round-4 fixers'
commits c841ad9e7..7beed27b7 and the records commit 7dd4e1e7c returned
APPROVE-WITH-FIXES (one MAJOR, one MINOR records only) and APPROVE-WITH-FIXES
(one MAJOR, two MINOR, one records only), four distinct findings, the MAJOR
found by both, all folded and none rejected (fork/templates/plan.md, "Focused
re-review of the fold (2026-10-15)", round 5): 0bd0756c8 with its fill
2f2cc9bb4 (a class value whose literal leaves a field to its default is
deferred only when its class's fields hold a part known only per instantiation,
as an initializer is, so the constant literals that 6aa403cd6 turned into
rejections on instantiation compile and run again, as at f3f99c1c1), aec81d0ee
with its fill 82bb5a749 (the two splits that pin the remaining rejection are
named `fail_todo_`), and the records commits after them (82ab5f78a, and a
records pass over the reviews' runs, which re-measures 82ab5f78a with the same
results); no residue filed, and W-273 and W-274 stay unused. Verification is
container-built and NOT of record (Actions disabled): on 82bb5a749 with
0bd0756c8's toolchain file_test 1955/1955 and the expected scoreboard 137 PASS /
0 FAIL / 22 SKIP over 159, 48/56 bullets (scoreboard generated
2026-10-20T02:48:42Z by the container clock); every round-5 mutant killed but
the four recorded survivors whose paths others cover or that no measured shape
reaches (amended 2026-10-15, focused re-review of the fold: RR6r2-m1); the
eleven class-value probes that the round-4 head rejected print their twins'
values. `git merge-tree` of the head against trunk f3156a375 and each held PR
gives the PR body's conflict table unchanged (round 5's convert.cpp hunk merges
cleanly). Neither review judged the branch dry, and the fixer changed one
toolchain source file and three goldens, so RE-REVIEW ROUND 6 OWED: two fresh
reviews of the round-5 fixer's commits 0bd0756c8..82ab5f78a (the fix commits
0bd0756c8..82bb5a749 and the records commit 82ab5f78a) and the records commit
after them that records round 5's reviews, then a fixer for what they find; the
PR opens and is held after a round with no BLOCKER or MAJOR whose fixer changes
no toolchain file. The merge order does not change.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 6, folded;
pushed; RE-REVIEW ROUND 7 OWED): two fresh reviews of the round-5 fixer's
commits 0bd0756c8..82ab5f78a and the records commit d50052bde returned
APPROVE-WITH-FIXES (one MAJOR, two MINOR) and APPROVE-WITH-FIXES (one MAJOR,
one MINOR records only), five distinct findings, all folded and none rejected
(fork/templates/plan.md, "Focused re-review of the fold (2026-10-15)", round
6): 4d015cf18 with its fill 464eca298 (a class literal that leaves to its
default a field whose default initializer splices in a template action, such
as `var k: i32 = N + 1;`, is converted on instantiation, where it stopped
lowering, and is rejected there as trunk rejects it), 1d4e7419c with its fill
873a6b70a (two lower splits that kill the round-4 mutants M70 and M72),
080963a68 with its fill 8b94adb03 (a check split that kills M75 and pins
W-273), 2dfd39e63 with its fill e193865fc (two check splits that pin a constant
literal nested in a value converted on instantiation whole, a form of W-272's
mechanism that predates the round), and the records commits after them
(2cb6bfec0, and a records pass over the reviews' runs, which re-measures
2cb6bfec0 with the same results); one residue filed, W-273, a class template
whose field type names a class-scope alias of a `where` facet type, rejected
where trunk and the nightly stop the compiler, and W-272 widened; W-274 stays
unused. Verification is container-built and NOT of record (Actions disabled): on
e193865fc with 4d015cf18's toolchain file_test 1955/1955 and the expected
scoreboard 137 PASS / 0 FAIL / 22 SKIP over 159, 48/56 bullets (scoreboard
generated 2026-10-20T04:39:57Z by the container clock); every round-6 mutant
killed but M76, which only completes the walk; a sweep of 1281 earlier probes
changes only the round's own shapes. `git merge-tree` of the head against trunk
f3156a375 and each held PR gives the PR body's conflict table unchanged (round
6's convert.cpp hunk merges cleanly). Neither review judged the branch dry, and
the fixer changed one toolchain source file and three goldens, so RE-REVIEW
ROUND 7 OWED: two fresh reviews of the round-6 fixer's commits
4d015cf18..2cb6bfec0 (the fix commits 4d015cf18..e193865fc and the records
commit 2cb6bfec0) and the records commit after them that records round 6's
reviews, then a fixer for what they find; the PR opens and is held after a round
with no BLOCKER or MAJOR whose fixer changes no toolchain file. The merge order
does not change.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 7, folded;
pushed; RE-REVIEW ROUND 8 OWED): two fresh reviews of the round-6 fixer's
commits 4d015cf18..2cb6bfec0 and the records commit aff28da43 returned
APPROVE-WITH-FIXES (two MINOR, records only, judged dry) and APPROVE-WITH-FIXES
(one MAJOR, one MINOR records only, not dry), four distinct findings, all folded
and none rejected (fork/templates/plan.md, "Focused re-review of the fold
(2026-10-15)", round 7): c4d609c8d with its fill a6c7910d6 (an action keeps a
struct or tuple literal as its operand instead of the literal's constant value,
so a constant literal deferred to instantiation takes the defaults of the
class's concrete specific, nested literals included; `var k: T = 7;` in a class
template, which round 6's deferral had turned from running into a rejection,
runs again, and so does every form that W-272 recorded, whose six pins lose
`fail_todo_`), b82630e75 with its fill d29e91e5c (a lower split that kills the
round's surviving mutant M85), and the records commits after them (2b58312ea:
W-270 widened to a class template whose later parameter's type is produced, the
records' comparisons with trunk and the nightly corrected, three paragraphs
rewrapped; and a records pass over the reviews' runs, which rewraps nine more
paragraphs and re-measures 2b58312ea with the same results); no residue filed,
W-272 discharged within TP-1, W-274 stays unused. Verification is
container-built and NOT of record (Actions disabled): on d29e91e5c with
c4d609c8d's toolchain file_test 1955/1955 and the expected scoreboard 137 PASS /
0 FAIL / 22 SKIP over 159, 48/56 bullets (scoreboard generated
2026-10-20T07:06:51Z by the container clock), every program equal to round 6's
run; every round-7 mutant killed but M76, which only completes the walk; a sweep
of 1445 earlier probes changes only the shapes that the fix makes compile or
brings to their twins' behavior. `git merge-tree` of the head against trunk
f3156a375 and each held PR gives the PR body's conflict table unchanged (round
7's eval.cpp hunk and the two refilled eval goldens merge cleanly). Review 2 did
not judge the branch dry, and the fixer changed two toolchain source files and
six goldens, so RE-REVIEW ROUND 8 OWED: two fresh reviews of the round-7 fixer's
commits c4d609c8d..2b58312ea (the fix commits c4d609c8d..d29e91e5c and the
records commit 2b58312ea) and the records commit after them that records round
7's reviews, then a fixer for what they find; the PR opens and is held after a
round with no BLOCKER or MAJOR whose fixer changes no toolchain file. The merge
order does not change.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 8, folded;
pushed; RE-REVIEW ROUND 9 OWED): two fresh reviews of the round-7 fixer's
commits c4d609c8d..2b58312ea and the records commit 9bf11355d returned
APPROVE-WITH-FIXES (one MAJOR, two MINOR records only, not dry) and
APPROVE-WITH-FIXES (the same MAJOR, three MINOR, one of them records only, not
dry), five distinct findings, all folded and none rejected
(fork/templates/plan.md, "Focused re-review of the fold (2026-10-15)", round 8):
1572d4d65 with 6e08becbc and their fill 6983fc5ca (a template action's
conversion reads a class template's field default from the class specific's
resolved definition, so a checked generic that calls such a template with a
symbolic argument, which stopped the compiler since rounds 6 and 7 where trunk
and the nightly reject it, is rejected on instantiation with a diagnostic;
splits pin it, round 7's reach to checked generics whose types are `eval fn`
results and to template-dependent call arguments, and a constant initializer
that is not a literal, with an upstream TODO restored and narrowed), 813804758
(the resolution for every default read; no golden change), and the records
commits after them (3a4176711 and its correction 1a9fbb6de; and a records pass
over the reviews' runs, which rewraps six paragraphs and re-measures 1a9fbb6de
with the same results); one residue filed, W-274, a checked generic that calls
such a template for a class whose object representation depends on a type
parameter, which still stops the compiler as on trunk and the nightly, so
W-250..W-274 are all filed. Verification is container-built and NOT of record
(Actions disabled): on 813804758 with its own toolchain file_test 1955/1955 and
the expected scoreboard 137 PASS / 0 FAIL / 22 SKIP over 159, 48/56 bullets
(scoreboard generated 2026-10-20T09:51:04Z by the container clock), every
program equal to round 7's run, and again at 1a9fbb6de with the same results;
every round-8 mutant killed; a sweep of 1902 earlier probes changes only the
seven forms that stopped and are rejected now. `git merge-tree` of the head
against trunk f3156a375 and each held PR gives the PR body's conflict table
unchanged (round 8's convert.cpp hunks merge cleanly). Neither review judged the
branch dry, and the fixer changed one toolchain source file and four goldens, so
RE-REVIEW ROUND 9 OWED: two fresh reviews of the round-8 fixer's commits
1572d4d65..1a9fbb6de (the fix commits 1572d4d65..813804758 and the records
commits 3a4176711 and 1a9fbb6de) and the records commit after them that records
round 8's reviews, then a fixer for what they find; the PR opens and is held
after a round with no BLOCKER or MAJOR whose fixer changes no toolchain file.
The merge order does not change.

Later on 2026-10-15 (TP-1's focused re-review of the fold, round 9, folded;
pushed; RE-REVIEW DRY AT ROUND 9, PR TO OPEN AND HOLD): two fresh reviews of the
round-8 fixer's commits 1572d4d65..1a9fbb6de and the records commit c08623fc6
returned APPROVE-WITH-FIXES (two MINOR, records only, dry) and
APPROVE-WITH-FIXES (three MINOR, records only, dry), five distinct findings, all
folded and none rejected (fork/templates/plan.md, "Focused re-review of the fold
(2026-10-15)", round 9) in the records commit b31a62d62, which changes no
toolchain, golden or program file: the plan's §1.1 gains TR-22 (a symbolic
constant passed to a template parameter, OUT and unchanged from trunk), TR-4 and
D-TP-24 say where a constant literal that leaves a default runs and that round
8's three `fail_` splits pin trunk's limit for a symbolic argument, W-267 is
widened to the actions of a checked generic whose types are `eval fn` results
and W-274 to an object representation that depends on an array bound or a
class-template field type, with a second shape in its notes, and W-256's and
W-272's cites follow round 8's moved lines; no residue filed. Verification is
container-built and NOT of record (Actions disabled): at c08623fc6, whose
toolchain is 813804758's and which b31a62d62 leaves unchanged, file_test
1955/1955 and the expected scoreboard 137 PASS / 0 FAIL / 22 SKIP over 159,
48/56 bullets (scoreboard generated 2026-10-20T11:53:27Z by the container
clock), every program equal to round 8's run. `git merge-tree` of the round's
head against trunk f3156a375 and each held PR gives the PR body's conflict table
unchanged. A records pass over the reviews' runs, the records commit after
b31a62d62, names b31a62d62 in the records, re-cites W-264's class value
temporary to convert.cpp:1590, corrects D-TP-24's closing sentence, rewraps four
paragraphs by hand, re-runs the id re-scan and `git merge-tree` with the same
results and re-measures b31a62d62 with the same results (file_test 1955/1955;
137/0/22 over 159, 48/56 bullets; NOT of record), with no toolchain, golden or
program file changed. Both reviews judged the branch dry, and the fixer changed
no toolchain file, so the re-review is complete: no round 10 is owed, and the
TP-1 PR opens against trunk and is held open, as PR 51 to PR 60 are. The merge
order does not change.

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
| `claude/carbon-fork-0-1-safe` | HELD OPEN as PR #53 — SAFE-1 safe-Carbon design (F-013) at adaae4e35, documentation and records only (gap row 89 expected DONE on document review, W-063 discharged, W-144..W-150); merges first in the land sequence. |
| `claude/carbon-fork-0-1-ev` | HELD OPEN as PR #54 — EV-1 evaluator guides and twelve transcribed programs at cb3ef2e74 (W-062 discharged; W-152, W-153, W-155 filed; expected 137/0/22 over 159); state T, merges after PR 52 through its state C integration commit. |
| `claude/carbon-fork-0-1-st` | HELD OPEN as PR #55 — ST-1 str comparison, Core.StringBuf and concatenation (F-014) at 21307851a (W-057 discharged; W-160..W-167 filed; expected 133/0/21 over 154); merges after EV-1. |
| `claude/carbon-fork-0-1-op` | HELD OPEN as PR 56 — OP-1 Core.Optional comparison and F-015 at 379f20f67 (W-058 discharged; W-170..W-179, W-195 filed; expected 132/0/25 over 157; row stays PARTIAL); merges after PR 55. |
| `claude/carbon-fork-0-1-op2` | HELD OPEN as PR 57 — OP-2 Core.Optional ownership, the MaybeUnformed representation fix, checked Get and F-016 at 628273444, stacked on PR 56 (W-170, W-171, W-173 discharged; W-196..W-201 filed; expected 139/0/22 over 161; Optional row DONE expected); merges after PR 56, before DD-1. |
| `claude/carbon-fork-0-1-ox` | PARKED at plan rev 6 (pushed as a record, head 14f06b8b3, no PR; decision-log entry "OX-1 parked") — OX-1 operator export to C++ (W-054, gap row 48 stays MISSING): four focused re-reviews, the export mechanism leaks into Carbon's own resolution; W-202..W-211, W-245..W-249 and F-017 reserved and unused; a future plan must separate operator exports from the Sema Carbon's own lookup consults. |
| `claude/carbon-fork-0-1-va` | HELD OPEN as PR 59 — VA-1 definition-checked variadics slice 1 at b0822a744 (W-013 open with the slice recorded; W-212..W-230 filed; W-231 unused; expected 137/0/21 over 158; row 53 PARTIAL expected); merges after PR 58. |
| `claude/carbon-fork-0-1-tp` | IMPLEMENTED AND HELD, RE-REVIEW DRY AT ROUND 9, PR TO OPEN AND HOLD -- TP-1 integrated templates, toolchain at 813804758 (splits through 6983fc5ca) after round 8 of the focused re-review of the fold, records through round 9's records commits (b31a62d62 and the records pass after it; round 9: two APPROVE-WITH-FIXES on c08623fc6, both dry, five MINOR records-only findings folded with no toolchain change); no round 10 is owed, and the PR opens against trunk and is held open (W-014 OPEN; W-250..W-274 filed, W-272 discharged within TP-1; F-019 not minted; W-127, W-183, W-192, W-193 discharged at land time; gate 1955/1955 and conformance 137/0/22 over 159 on the container toolchain, expected; row "Generics: Integrated templates" stays PARTIAL); lands after PR 59 by the land-time items in Next actions (item 5). |
| `claude/carbon-fork-0-1-dd` | HELD OPEN as PR 58 — DD-1 design docs without placeholders at fcee90d9b (W-065 discharged; W-182..W-185, W-188, W-189, W-191..W-194 filed; W-240..W-244 reserved, unused; expected 147/0/22 over 169; row 70 DONE expected; row 91 PARTIAL until state L); four document-review rounds folded; merges last of the held PRs through its state L integration commit. |
| `claude/carbon-fork-0-1-sc` | IMPLEMENTED AND FILLED on the container toolchain — SC-1 template structural conformance through fill round 3 at 2497d5000 (gate 1959/1959, conformance 130/0/21 over 151; W-134..W-143, W-151; W-168/W-169 reserved); round-3 review in progress, PR after it. |
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

Expected at TP-1, NOT of record: 137 PASS / 22 SKIP / 0 FAIL over 159, 48/56
bullets (a container run on the carbonbuild toolchain of 12bd6d67a at TP-1's
head 824f29c4e, scoreboard generated 2026-10-15T00:56:22Z; nine programs join
the "Generics: Integrated templates" bullet, already PASS, and its gap row stays
PARTIAL), from the floor of record 128 PASS / 22 SKIP / 0 FAIL over 150, 48/56
(the hosted conformance run 37402970811 on 606a99c5a). TP-1 is measured on trunk
alone; its landing count is PR 59's expected state with every earlier PR plus
nine PASS (fork/templates/plan.md §5).

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

1.  A W-008 slice (tuple/var/ref/compile-time case patterns,
    non-binding payload subpatterns — unblocks W-066's usefulness
    diagnostics) or conformance depth (differential pairs for flipped
    bullets lacking one). W-066 stays blocked on W-008.
2.  Reconstruct + land design-docs (F-008..F-011) — **gated on the
    user's veto-digest response** (presented 2026-07-20, unanswered).
3.  W5-S3p (prelude Result/Optional) stays GATED on the OPEN SF-9 fork
    (default (c) DEFER; carries W72c Try.FromContinue + the
    `final`-spelling recurrence flag); W5-S4 (std::variant mapping)
    rides its deferred planning decision. Residues: W-067
    (default-clause guards), W-068 (fewer-than-two-alternative
    choices), W-069 (cross-file runtime let), W-070 (unit break types,
    SF-9-blocked), choice `Core.Copy` construction gap,
    tuple/var/ref/compile-time case patterns, non-binding payload
    subpatterns (W-008).
4.  Conformance depth: differential pair per flipped bullet; scoreboard in
    CI; W-066 match usefulness diagnostics.
5.  TP-1 at land time (fork/templates/plan.md §3; `claude/carbon-fork-0-1-tp`,
    after PR 59; this item renumbers after the held PRs' own items at the
    land-time merge): repeat M over the trunk that holds PR 51 to PR 60, keeping
    TP-1's appended record blocks after the PRs'; S; F6, with PR 51's split
    renamed; the id re-scan; L with its document review; a records commit that
    recomposes the row over the merged one (§2.8) and discharges W-127, W-183,
    W-192 and W-193; the id re-scan before D's landed notes. In this order:
    -   M: merge the then-current trunk into the branch with a merge commit,
        never a rebase, after repeating plan §0.9's dry run against the heads of
        that day. M resolves conflicts only: SC-1's
        `PerformAction(ConvertAction)` and `(ConvertToCategoryAction)` keep
        SC-1's check first and A2's `PendingBlock` after it, member_access.cpp's
        includes put `pointer_dereference.h` beside `structural_conformance.h`,
        the conformance README table is regenerated with `runner.py
        --update-readme-table`, and each record file takes trunk's text with
        TP-1's appended blocks after the PRs' (row 54 found by its bullet text,
        W-250..W-273 after the then-last item, the decision-log entry above the
        entry that then follows "Full autonomy and the throughput protocol",
        this item and TP-1's Branches row, trunk's own stale TP-1 Branches row
        dropped, since a merge keeps both rows without a conflict). The focused
        re-review's convert.cpp hunk, in `ConvertTupleToType`, merges cleanly,
        and so do its round 2's, in `ConvertStructToClass` and the class
        literal test before `ConvertTupleToArray`, its round 3's
        import_ref.cpp and context.h, and its round 4's convert.cpp
        (`ConvertStructToClass` and the class field tests before it) and
        import_ref.cpp, and its round 7's eval.cpp and its two refills of check
        eval/call.carbon and eval/symbolic.carbon.
    -   S, "TP-1 (7): over SC-1, a template constraint's requirement defers to
        the type in constraint lookup": plan §2.5's text, member_access.cpp only
        (measured at state T and at the fold: SC-1's nine template-constraint
        goldens pass again; mutant M18 reverts it).
    -   F6: refill what the merge changes, TP-1's ten refills recomputed, PR
        51's `fail_todo_unformed_dependent_var` renamed `unformed_dependent_var`
        and refilled, and any SC-1 or VA-1 golden the merged toolchain changes
        (measured: none). M, S and F6 are judged together: the full build,
        autoupdate to its fixpoint, gate, conformance (the base's totals plus
        nine PASS), the mutants and `runner.py --self-test`, re-quoted from that
        run (R9).
    -   The id re-scan of the plan's front matter (its three commands), before
        L, the first commit that publishes an id outside the plan.
    -   L, "TP-1: integration with PR 58" (plan §2.9, Appendix C), then its
        document review (two reviewers, R29(c)) and fold commits, each with
        `python3 fork/designdocs/check_samples.py` with and without
        `--toolchain` (simulated: 70 fixtures, 0 errors both ways).
    -   A records commit: the row recomposed over the merged row (§2.8's full
        row, one TP-1 sentence), W-127, W-183, W-192 and W-193 discharged with
        Appendix E's texts, W-014's merged-tree sentence, Appendix E's
        ORCHESTRATION stamp, and the merged tree's gate, conformance and checker
        runs in the plan's landed notes.
    -   The second id re-scan, immediately before that commit's ledger edit; a
        collision re-allocates from the maximum plus one, skipping every
        reserved block, rewrites L's and R's ids in a commit before it, and is
        recorded against 637e3efaf and 12bd6d67a, whose messages name W-250.
    -   When Actions returns, the hosted autoupdate, gate and conformance runs
        on a tree with TP-1 in it are the record (expected: PASS up 9 and
        programs up 9 over the base; the bullet PASS; row 54 PARTIAL), and the
        "not of record" phrases go in a records commit.

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
    creative fork design at full speed.
