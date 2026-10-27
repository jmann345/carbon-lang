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

Later on 2026-10-14 (13:50 UTC), the VA-1 discharge (pushed, PR to open and
hold): VA-1 (claude/carbon-fork-0-1-va, fork/variadics/plan.md rev 3, W-013, gap
row 53 "Generics: Definition-checked variadics"; the discharge commit sits on
the merge of trunk e25b27e34: definition-checked variadics, slice 1; upstream's
2ec4bab59 and a045da8e6 cherry-picked as its first two commits with upstream
authorship; W-013 stays open; W-212 to W-230 filed, W-231 of VA-1's reservation
unused; F-018 not minted; expected 137/0/21 over 158; row 53 PARTIAL expected)
is IMPLEMENTED AND DISCHARGED off trunk f67ab650d, after two plan reviews and a
focused re-review (rev 3, ec0b1a7b0, signed off) and two implementation reviews
(APPROVE-WITH-FIXES each, eleven distinct findings, all folded by fix 3
0ee9f2d1b and its fill 88b1b5bd2, none rejected) — 44a5ce6e3 and 663a29df6 (the
two cherry-picks), e90b4197e (lex and parse: the `each` keyword, pack expansion
elements and patterns), 275967b1d (check and SemIR: one pack of values per
function, eight new instructions, the slice's TODOs), 57d263799 (lowering per
specific, the un-SKIP of generics/variadics_each.carbon and eight new programs,
one with a C++17 oracle), three fix commits and four autoupdate fills, 9a0888ef0
(row 53 PARTIAL, expected), 9fad11984 (the implementation review fold record)
and e25b27e34 (the merge of trunk 3eb7f36f0, fork/ORCHESTRATION.md only).
Verification is container-built and NOT of record (Actions disabled): the
carbonbuild toolchain of 88b1b5bd2, which the merge does not change, file_test
1960/1960 on the merge commit, the expected scoreboard 137 PASS / 0 FAIL / 21
SKIP over 158, 49/56 bullets (scoreboard generated 2026-10-14T13:37:37Z), the
nine variadics programs the only change from the floor of record 128 / 0 / 22
over 150, and each of the plan's eight mutants caught by its predicted programs;
the gap header reads 30 / 22 / 4 / 0. Not run: Bazel and its tests (the gtest
unit tests, the diagnostics coverage test, lit tests, fuzzers) and the four
Bazel-backed prek hooks, hosted CI with its clangd-tidy step, ASan, LLVM-side
assertions, an opt-mode conformance toolchain, non-Linux platforms, any hosted
run, and any composition with the held PRs' toolchains (fork/variadics/plan.md
§8.9 and its landed notes). Merge order: PR 53, PR 51, PR 52, SC-1, PR 54, PR
55, PR 56, PR 57, then PR 58 through its state L integration commit; OX-1 and
VA-1 after PR 58 in the order their PRs open (OX-1 is at plan rev 5, not signed
off). None is merged. Id reservation: VA-1 reserved W-212..W-231 and filed W-212
to W-230 as reserved, after a re-scan of 77 refs found them named only as its
reservation (maximum W-244, DD-1's unused block); W-231 stays unused and is
never reused, and F-018 is not minted. The merge steps are Next actions item 5.

Later on 2026-10-27 (13:25 UTC; the VA-2 discharge; pushed, no PR yet): VA-2
(claude/carbon-fork-0-1-va2, stacked on PR 59, fork/variadics/va2-plan.md)
implements packs of different types, tuples with one pack segment, statement
expansions of `if` and variadic impls, makes the prelude's tuple Copy, EqWith
and OrderedWith single variadic impls, and fixes the lowering of nested
aggregate constants; W-225 discharged, W-212 and W-213 narrowed, W-330 to W-339
filed (W-335 discharged); expected 147 PASS / 0 FAIL / 21 SKIP over 168 on the
container run of 2026-10-27 on bdd7b2424, whose toolchain is the carbonbuild
toolchain of the fix 1ad7c9b5e, `conformance.sh` into a private directory with
scoreboard generated 2026-10-27T13:14:18Z and log
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2-impl/records/logs/conf_pre.log.
It merges last, after DR-1b, with the land-time test-only commit S-CT, a golden
split, after its merge of trunk (fork/variadics/va2-plan.md D-VA2-18), held
open. It is IMPLEMENTED AND HELD, no PR: plan rev 4 (7188540ca) was signed off
after two plan reviews (REJECT, ten findings; REJECT, fifteen) and two focused
re-reviews (REJECT, five; APPROVE-WITH-AMENDMENTS, four); the implementation
stopped and amended the plan five times (rev 5, 7, 9, 11 and 13), each amendment
folded after its focused re-review (rev 6, 8, 10, 12 and 14, every one
APPROVE-WITH-AMENDMENTS); and the two implementation reviews of C5 (REJECT,
three BLOCKER and five MINOR findings; APPROVE-WITH-FIXES, three MAJOR and eight
MINOR) were folded by the fix 1ad7c9b5e, its fill 5bc6e5070 and rev 15
bdd7b2424, so 76 findings (74 distinct) are folded across the plan's eleven
reviews and none is rejected. Commits: C0 d92a9c709 and C0b 64e9736c0 (the
lowering of nested aggregate constants, an upstream defect, W-335) with F0
8a7395cf1; C1 0aa8dd347 (packs of different types in implicit parameter lists)
with F1 1a7c360e0; C2 3af0471b6 (tuples with one pack segment, `let` pack
bindings, variadic impls) with F2 1afda55f0; C3 3a39d69db (statement expansions
of `if`) with F3 4a627cd6c; C4 b40003716 (the prelude's tuple Copy, EqWith and
OrderedWith) with F4 1a9a0a11b; C5 4b7ca618e (ten programs, three of them
differential); the fix and its fill; R 42a1ec16f (both rows PARTIAL); and the
discharge. Verification is container-built and NOT of record (Actions disabled):
on bdd7b2424, whose toolchain is the fix's, file_test 1977/1977 and the expected
scoreboard 147 PASS / 0 FAIL / 21 SKIP over 168, 49/56 bullets, ten PASS and ten
programs over PR 59's 137 / 0 / 21 over 158; eighteen mutants, each killed; and
the compositions with PR 55, PR 57 (holding PR 56), PR 60, PR 61, PR 62, PR 64
and DR-1b (on PR 63) and the land simulation (trunk ad2e45a66 with all fifteen
held PRs, then VA-2) on scratch mirrors, every program PASS on each
(fork/variadics/va2-plan.md §8.7). The id re-scan before D (after a fetch; 90
refs and 20 worktrees) found W-330..W-339 filed nowhere else, so all ten are
filed as reserved and none is unused. Round 1 of the focused re-review of the
fix commits and these records (2026-10-27, on f8d84ba75; both reviews
APPROVE-WITH-FIXES) is not dry: review 1's RR1-1-M1, MAJOR (a pack of facets
does not convert to a narrower facet type, so forwarding a tuple of one pack
segment and the prelude's variadic impls reject IN forms whose fixed-arity twins
run), and its RR1-1-m1 need a toolchain change, and review 2's four records-only
MINORs are folded by the records commit "VA-2 records: re-review round 1
recorded", which is not a fix commit; round 2 is owed, its fixer taking the fix
budget's last commit, and the PR opens held with base claude/carbon-fork-0-1-va
after the first dry round (fork/variadics/va2-plan.md, "Focused re-review of the
fold, VA-2, round 1 (2026-10-27)"). Round 2 (2026-10-27, pushed, no PR yet): its
fixer folded both code findings at the root by fix 3 ee6144ad9, the fix budget's
last commit, with its fill 903a0c321 and the records commit "VA-2 re-review fix:
round 2 folded into the records": a pack of facets converts to a pack of a
narrower facet type as a `PackFacetValue`, and a `let` pack pattern's diagnosed
binding type reports once; no TODO, no id, no shrink, W-225 still discharged;
expected file_test 1977/1977 and 147 / 0 / 21 over 168, MV-19 to MV-23 killed,
and the mirrors m64, m60, m57, m62 and mdr green with it; round 2's two reviews
read it next (fork/variadics/va2-plan.md, "Focused re-review of the fold, VA-2,
round 2 (2026-10-27)"). Merge order: PR 53, 51, 52, 60, 54, 55, 56, 57, 58, 59,
61, 62, 64, 63, 65, then VA-2 through its land-time items (Next actions item 6).
None is merged.

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
| `claude/carbon-fork-0-1-ox` | PLANNING — OX-1 operator export to C++ (W-054, gap row 48), cut from f67ab650d; reserves W-202..W-211, F-017 if minted; merges after DD-1. |
| `claude/carbon-fork-0-1-va` | PUSHED, PR TO OPEN AND HOLD — VA-1 definition-checked variadics slice 1, discharged on top of the trunk merge e25b27e34 (W-013 open; W-212..W-230 filed, W-231 unused; F-018 not minted; expected 137/0/21 over 158; row 53 PARTIAL expected); merges after PR 58, OX-1 and VA-1 in the order their PRs open. |
| `claude/carbon-fork-0-1-va2` | IMPLEMENTED AND HELD, no PR; ROUND 2 FIX UNDER REVIEW — VA-2 definition-checked variadics slice 2 at the records commit of re-review round 2, over fix 3 ee6144ad9 (the fix budget's last commit) and its fill 903a0c321 (toolchain ee6144ad9), on the round 1 records commit bdf941edc and the discharge D f8d84ba75, stacked on PR 59 (W-225 discharged, W-212 and W-213 narrowed; W-330..W-339 filed, W-335 discharged, none unused; no F id, and no id in round 2; expected gate 1977/1977 and 147/0/21 over 168, not of record; the gap rows "Generics: Definition-checked variadics" and "Stdlib: tuple/array library parts" PARTIAL); re-review round 1 (2026-10-27, on f8d84ba75) was not dry, and round 2's fixer folded its RR1-1-M1 (MAJOR, a pack of facets not converted to a narrower facet type) and RR1-1-m1 at the root by fix 3, with no TODO, no shrink and W-225 still discharged; round 2's two reviews read the fold next; the fix budget is used up, so a later code finding takes the plan's shrink line; the PR opens held with base claude/carbon-fork-0-1-va after the first dry round; merges last after PR 65 through its land-time items M, S-CT, F-M, L-F and L (Next actions item 6). |
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

Expected at VA-1, NOT of record: 137 PASS / 21 SKIP / 0 FAIL over 158, 49/56
bullets (a container run on the carbonbuild toolchain of 88b1b5bd2 at VA-1's
merge of trunk e25b27e34, scoreboard generated 2026-10-14T13:37:37Z; the
variadics bullet PASS over nine programs, its gap row PARTIAL), from the floor
of record 128 PASS / 22 SKIP / 0 FAIL over 150, 48/56 (the hosted conformance
run 37402970811 on 606a99c5a, which the line above predates; PR 55 and PR 56
re-quote that line on their branches).

Expected at VA-2, NOT of record: 147 PASS / 21 SKIP / 0 FAIL over 168, 49/56
bullets (a container run on the carbonbuild toolchain of the fix 1ad7c9b5e at
VA-2's head bdd7b2424, scoreboard generated 2026-10-27T13:14:18Z, the totals of
C5 4b7ca618e and of the fix's fill 5bc6e5070 too, and of fix 3's fill 903a0c321
in three runs, the first's scoreboard generated 2026-10-27T15:37:36Z); PR 59's
158 programs and VA-2's ten, six under the variadics bullet, which holds
fifteen, and four under the tuple/array bullet, which holds five, all PASS, both
gap rows PARTIAL. VA-2 is measured on PR 59 alone; its landing count is the
trunk that holds every held PR plus ten PASS and ten programs
(fork/variadics/va2-plan.md §5), which commit L re-quotes from the run on the
merge commit.

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
5.  VA-1 merge (`claude/carbon-fork-0-1-va`, W-013 slice 1; merges after PR 58,
    OX-1 and VA-1 in the order their PRs open; this item renumbers after the
    held PRs' own items at the land-time merge), in this order
    (fork/variadics/plan.md §3 item 11, §1.10 and §8.8):
    -   Merge the then-current trunk into the branch with a merge commit, never
        a rebase (trunk 3eb7f36f0 is merged as e25b27e34). A conflicted golden
        takes trunk's side and is refilled by autoupdate in a new "Autoupdate
        testdata goldens on the container arbiter" commit; the conformance
        README table is regenerated with `runner.py --update-readme-table`; the
        records keep trunk's rows and entries for other branches and this
        branch's VA-1 rows, re-anchored by bullet text, item id or heading; the
        gap header is recounted, never merged.
    -   Re-run plan §8.8 on that merge commit. The held PRs bring toolchain and
        prelude changes (SC-1 shares 18 toolchain files with VA-1, every hunk
        auto-merging, plan §6.2), so rebuild, refill (each changed golden in a
        fill commit), gate (the base's count plus VA-1's fourteen new goldens
        and upstream's four), conformance (the base's totals plus plan §5's
        delta, PASS up 9, SKIP down 1 and programs up 8), the mutants MU-1 to
        MU-8 and `runner.py --self-test`, and re-quote the totals from that run
        (R9), never adding them by hand.
    -   Re-anchor the records in new commits: the decision-log entry "VA-1:
        definition-checked variadics, slice 1 (2026-10-14)" above the
        then-newest landed workstream entry (plan §2.8); row 53 found by its
        bullet text and its run re-quoted; the header's counts recounted and its
        scoreboard sentence re-written from the run; W-212..W-230 after the
        then-last ledger item; W-013's `GetExplicitArityRange` line
        (toolchain/check/call.cpp:578 at e25b27e34) re-measured.
    -   Re-run the plan's id scan; if any of W-212..W-230 is taken by then,
        re-allocate from the maximum plus one, skipping every reserved block,
        and renumber in the same commit the records that name them (no source,
        golden or program header names one).
    -   When Actions returns, the hosted conformance run on a tree with VA-1 in
        it is the record (expected: PASS up 9, SKIP down 1 and programs up 8
        over the base; the variadics bullet PASS over nine programs; row 53
        PARTIAL), and the "not of record" phrases go in a records commit.
    -   At the next upstream advance VA-1 adds four conflicted files (plan
        M-16): toolchain/check/handle_pack_expansion.cpp,
        toolchain/parse/node_kind.def and toolchain/parse/typed_nodes.h take the
        fork's side, which holds upstream's lines, and
        toolchain/check/testdata/variadics/pack_expansion.carbon takes
        upstream's file and is refilled; the entry's V-3a register is reviewed
        then.

6.  VA-2 at land time (fork/variadics/va2-plan.md §3 item 15, D-VA2-18, §6.2,
    §8.8 and its "Landed notes (VA-2, 2026-10-27)";
    `claude/carbon-fork-0-1-va2`, last, after PR 65 through its land-time items;
    this item renumbers after the held PRs' own items at the land-time merge),
    each its own commit, in this order:
    -   M: a merge commit (`git merge --no-ff`, never a rebase) of the trunk
        that holds every PR before VA-2 in the merge order, after `git
        merge-tree` dry runs against that day's heads, resolved by §6.2's rules:
        convert.cpp's `ConvertTupleToType` and eval.cpp's `EvalContext` members
        keep both sides, PR 61's first (rules 1 and 2); the records and
        fork/conformance/README.md's table are taken from trunk and rewritten by
        L-F and L (rule 3); generic.cpp's `ResolveSpecificDefinition` takes
        upstream's `DefinitionResolution` arms, with the pack-iteration call in
        `NewlyResolved`, when trunk holds upstream's 57bf903ef (rule 4); a
        conflicted golden takes trunk's side and is refilled by F-M (rule 6),
        question_optional.carbon and lower/for/bindings.carbon on the land
        simulation; any other conflict is a stop (rule 5). M's message is the
        plan's, its fields filled.
    -   S-CT: the land-time test commit of D-VA2-14, the split file
        `fail_todo_cpp_call_on_hetero_element` (§A.11), no code: C1's refusal in
        `AddDependentActionInst` covers CT-1's deferred C++ calls once M brings
        them.
    -   F-M: the fill that M and S-CT need, autoupdate only, to its fixpoint:
        the held PRs' full-prelude goldens that C4's prelude renames,
        lower/for/bindings.carbon with both sides' lowering, S-CT's split and
        the conflicted goldens, as the land simulation measured; then the gate
        and conformance on the merged build.
    -   L-F: fork/conformance/README.md's table regenerated with runner.py's
        `--update-readme-table` on the merge commit, and every program header
        that names a count re-derived; no EXPECT line changes.
    -   L: the land-time records commit, after a second id re-scan (§8.10)
        immediately before its ledger edit: §8.1 to §8.4 re-run on the merge
        commit (its totals quoted from its scoreboard, never added by hand), the
        two gap rows replaced again by their bullet text, the ledger's evidence,
        the decision-log entry's held-state paragraph, this file's VA-2 row and
        paragraph, and the plan's landed notes, all re-quoting that run.
    -   Before M: the SC-1 with OP-2 item below is decided, and the three
        goldens that fail on the land simulation after F-M, held-side (CT-1's
        and DR-1b's land-time renames and SC-1's
        `self_facet_in_signature_required`), are carried by their own PRs'
        land-time commits.
    -   When Actions returns, the hosted autoupdate, gate and conformance runs
        on a tree with VA-2 in it are the record, and the "not of record"
        phrases go in a records commit.
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
    simulated trunk without VA-2 (fork/variadics/va2-plan.md §8.7, `mall` and
    T*), SC-1's named_constraint/template_constraint.carbon split
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
