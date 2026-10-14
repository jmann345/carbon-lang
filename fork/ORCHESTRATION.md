<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

Last updated: 2026-10-06 (post-PR #50: UPSTREAM ADVANCE (UA-1) LANDED — the cut
moved from 631f8fb (2026-08-20) to upstream c1e83b0b7 (2026-10-05): 183 commits,
105 conflicts (31 sources and docs, 74 goldens), every class-B mechanism
re-expressed inside upstream's structure (D-UA-6 redeclarations, D-UA-7 thunk
fence, D-UA-9 destroy witnesses), two class-C deletions (S3b publication, the
F8d embedding), one source conflict at the SL-2 re-merge. Floor UNCHANGED at 128
PASS / 0 / 22 SKIP over 150 (quoted from scoreboard.json, run 37402970811),
48/56 bullets — the bar was non-regression and it held; the pre-merge board was
trunk's pre-SL-2 floor exactly. Two upstream latent bugs fixed on the way: a
null `QualType` in the generic-function arm of `TryMapType`, and `if`-expression
arm / short-circuit operand cleanups that destroyed an unconstructed temporary
on the other path (caught by upstream's new SSA verifier against the fork's `?`
operator). The mirrored-nightly A/B was not run (no nightly at or after
2026-10-02 mirrored). NEXT: UA-2 reconciliation (fork/upstream/plan.md §8.5:
un-SKIP the §0.6 probes, the W-108 pin golden, ledger and gap-analysis re-cites,
the pre-existing manufactured decision-log heading, optional A/B for the record;
expected ceiling 129 / 0 / 20 over 150 if the probes flip), then variadics,
CMake integration, safe-Carbon design. Next cron Monday 2026-10-12 (first
post-advance firing: expect a small deferred set); the owner's machine is never
used. Appended 2026-10-12 (SC-1 commit-3 fold): SC-1 (template structural
conformance, W-027) is OPEN on claude/carbon-fork-0-1-sc and HELD awaiting the
fork toolchain's autoupdate + gate + conformance — see the Branches row; no
measured numbers yet, so the floor above stands. Appended 2026-10-13 (SC-1 fill
rounds 1 and 2, restated by the fill-rounds records commit): SC-1 is
implemented, filled, gated and conformance-verified on the container-built
toolchain, as measured there: file_test 1959 passed, 0 failed, and conformance
130 / 0 / 21 over 151 with 49/56 bullets. Hosted results: not run (Actions
disabled), so none of it is of record (R9) and the floor above still stands. Its
PR is to be opened and held open until the land sequence (Branches row). Fill
round 3 (same day; 0efe76e7d, bc8b37290, 5171e5eda) folded round 2's two
implementation reviews (REJECT on one BLOCKER, and APPROVE-WITH-FIXES; 15
findings: 13 fixed as asked, MAJOR-1 and F5 in part, F5's ledger id following at
round 4) and re-measured the same numbers on the toolchain stamped
0.0.0-0.dev+bc8b37290, again on 5171e5eda for the records commit after it,
2497d5000. Fill round 4 (same day; aa67ea281, ff490bd48, d232d4753) folds round
3's two implementation reviews (REJECT on one BLOCKER, and APPROVE-WITH-FIXES;
13 findings, 13 fixed as asked, though round 4's own reviews found the BLOCKER's
crash class still open through `typeof` and template instantiation): a
requirement passed as a value, which checked clean and aborted lowering, is
refused; an impl inside a `union` body has its structural `require` checked; the
round-2 residue is W-168. Re-measured on the toolchain stamped
0.0.0-0.dev+ff490bd48: the same numbers, again on d232d4753 for the records
commit after it. Fill round 5 (same day) folds round 4's two implementation
reviews (both REJECT; 9 findings, all fixed, none rejected): a requirement named
with no self type is now a value of its own concrete type, so `typeof` of it and
a template instantiated with a facet type no longer abort lowering; the `.Self`
lookup is deleted; value uses are refused by type, at instantiation too. Commits
616d0bc4f (fixes), 18775fee3 (goldens) and df5120d03 (records); re-measured on
the toolchain stamped 0.0.0-0.dev+18775fee3: the same numbers, again on
df5120d03 for the records commit after it, a9c887101. Fill round 6 (2026-10-14)
folds round 5's two implementation reviews (both APPROVE-WITH-FIXES; 11
findings, none rejected): an object holding a requirement's type (a class field)
was refused at every destroy, so a reference kept a reference is no longer
refused, values staying refused; the type's import is pinned; the miss (o) cause
and round 5's prediction tally (R16(d)) are corrected. Commits 56e400145
(fixes), fb12f63cb (goldens) and 857d5b048 (records); re-measured on the
toolchain stamped 0.0.0-0.dev+fb12f63cb: the same numbers, again on 857d5b048
for the records commit after it, 4bc4802ae. Fill round 7 (same day) folds round
6's two implementation reviews (REJECT on one BLOCKER, and APPROVE-WITH-FIXES; 7
findings, none rejected): names of a template constraint's body that depend on
its `Self` checked clean in non-template code and aborted lowering, so `Self` is
a checked-phase binding (D-SC-10's break condition); `const` and array types
hold the requirement's type; a class value's field holding it is reached through
a reference; a refused tuple-index base is diagnosed once. Commits c0fa52df2
(fixes), 36181a729 (goldens) and 30716a8c2 (records); measured on the toolchain
built from its sources and re-measured on the toolchain rebuilt from 36181a729
with a clean tree: the same numbers, again on 30716a8c2 for the records commit
after it, fa4cd094d. Fill round 8 (same day) folds round 7's two implementation
reviews (both APPROVE-WITH-FIXES; 9 findings, none rejected): the checked-phase
`Self` is kept as a trade, and what it rejects (requirement signatures that use
`Self` beyond what the constraint requires, filed as W-169) and accepts (a
`require` that takes `Self` as an argument) is recorded and pinned; the
compound-access TODO names a symbolic facet. Commits 4c2ecee22 (fixes),
3245ec0d2 (goldens), 253dd4031 and a13e70542 (records); measured on the
toolchain built from its sources and re-measured on the toolchain rebuilt from
3245ec0d2 with a clean tree: the same numbers, again on a13e70542 for the
records commit after it, ee1f905b0. Fill round 9 (same day) folds round 8's two
implementation reviews (both APPROVE-WITH-FIXES; 12 findings, one rejected in
part): a requirement whose declaration has an error no longer fails each use a
second time; the trade's lost and restorable signatures are pinned in the
repository and the records' overstatements corrected (`Core.Slice(Self)` and
`Core.Optional(Self)` were satisfiable through a class declaring its `Core.Copy`
and `Core.Destroy` impls, and `require impls Core.Copy & Core.Destroy` restores
both); gap row 60 states the limit; the symbolic-facet compound access is filed
as W-232. Commits 58dc46eb6 (fixes), a5078358c (goldens) and 6231d5b42
(records); measured on the toolchain built from its sources and re-measured on
the toolchain rebuilt from a5078358c with a clean tree: the same numbers, again
on 6231d5b42 for itself and for the records commit after it, ae807c7e8. Round
8's review counted 2 MAJOR (review 2's disclosure findings) and no BLOCKER, all
folded by round 9. Fill round 10 (same day) folds round 9's two implementation
reviews (both APPROVE-WITH-FIXES; 11 findings, none rejected; 2 MAJOR, one
finding of both, and no BLOCKER): only a requirement that cannot be compared
with a type's member, because its declaration or the member's has an error, is
skipped, so every other requirement, constraint and interface is checked and
reported again (round 9's guard had hidden them; the skip's own test was still
too broad, fill round 11 below); a requirement with a tuple pattern parameter,
which aborted every use, is a TODO (W-234); the follow-on of an overload set or
a blanket impl after such an error is filed as W-233; gap row 60 lists
`Core.Optional(Self)`; an incomplete type is reported for an interface of the
facet type it does not implement too, pinned. Commits 3ae639811 (fixes),
001cdb4c7 (goldens), 04755f23b (the incomplete-type split), 0d7ee5c19 (its
golden) and 6247769bb (records); measured on the toolchain built from its
sources and re-measured on the toolchain rebuilt from 001cdb4c7 with a clean
tree: the same numbers, again on 6247769bb for the records commit after it,
444ccbafe, which completes round 9's review record. Round 9's review counted 2
MAJOR (MAJOR-1, the one finding of both reviews) and no BLOCKER, all folded by
round 10. Round 10's own diff, a toolchain change (structural_conformance.cpp
and .h, impl_lookup.cpp, handle_named_constraint.cpp), had two implementation
reviews (both APPROVE-WITH-FIXES; 8 findings, none rejected; 2 MAJOR, MAJOR-1
one finding of both, and no BLOCKER), folded by fill round 11 (same day): a
mismatch against a requirement or a member with an error is skipped only where
the error causes it, so every other difference is reported as trunk's impl
analog reports it (round 10 skipped any mismatch next to an error, which hid
them); a tuple pattern parameter under a default value is the TODO too; the
impl-lookup cycle after the error and W-233's member side are pinned; the
ledger's SC-1 cites are checked mechanically at the head and re-pointed; the PR
body's full review record and verification move to its first comment (GitHub's
65,536-character description limit), as PR 58 did, the body keeping a per-round
summary of each and the NOT run paragraph. Commits 2ee29f311 (fixes), e7783c80e
(goldens), fa9038828, 93f2b9f24 and 62e25dcdd (records); measured on the
toolchain built from its sources and re-measured on the toolchain rebuilt from
e7783c80e with a clean tree: the same numbers, again on fa9038828 for 93f2b9f24
and on 93f2b9f24 for 62e25dcdd. Round 11's own diff, a toolchain change
(structural_conformance.cpp, merge.cpp and .h, handle_named_constraint.cpp), had
two implementation reviews (both APPROVE-WITH-FIXES; 10 findings, none rejected;
2 MAJOR, MAJOR-1 one finding of both, and no BLOCKER), folded by fill round 12
(same day): an erroneous default value was read as no error (a spurious mismatch
beside one, a new abort on two), so the error handling is one rule, D-SC-5(d)'s
comparison in an errors-match mode of upstream's own comparison, in which an
error type matches any type and a parameter whose default value is the error is
compared by its type; a requirement with `self` needs a member with `self`;
upstream's abort on two erroneous default values is filed as W-235. Commits
a6289f86e (fixes), 62d39c9f6 (goldens), 9af776bac and 395096d51 (records);
measured on the toolchain built from its sources and re-measured on the
toolchain rebuilt from 62d39c9f6 with a clean tree: the same numbers, again on
9af776bac for the records commit after it (gate 1959 passed, 0 failed;
conformance 130 / 0 / 21 over 151, 49/56). Round 12's own diff, a toolchain
change (structural_conformance.cpp, merge.cpp and .h, function.cpp and .h), had
two implementation reviews (both APPROVE-WITH-FIXES; 10 findings, none rejected;
2 MAJOR, MAJOR-1 one finding of both, and no BLOCKER), folded by fill round 13
(same day): the errors-match mode compared a parameter with an error by its type
alone, which hid its binding form (`ref y: i32 = Undefined` against `y: i32`,
which trunk's impl analog reports) and whether a default value is there, so it
compares such a parameter as declared, only an erroneous type or default value
counting as equal; an erroneous return type no longer matches none; the three
missing fork markers are added; the rule is stated identically in the code,
D-SC-9, the decision log and the design page; trunk's thunk abort on an
interface member's default value is filed as W-236. Commits dfd22bdd6 (fixes),
2af5604a3 (goldens), 6992c6cc5 (records) and the records commit after it,
d3db9878c; measured on the toolchain built from its sources and re-measured on
the toolchain rebuilt from dfd22bdd6: the same numbers, again on 6992c6cc5 for
itself and for the records commit after it (gate 1959 passed, 0 failed;
conformance 130 / 0 / 21 over 151, 49/56). Round 13's own diff, a toolchain
change (merge.cpp and .h, function.cpp and .h, comments in
structural_conformance.cpp), had two implementation reviews (both
APPROVE-WITH-FIXES; 10 findings, two rejected in part; 1 MAJOR and no BLOCKER),
folded by fill round 14 (same day): a parameter declared with a form that has an
error, which upstream makes the error itself, matched any parameter, so a
default value on the other side went uncompared; its default value's presence is
now compared and its binding form, part of the erroneous form, is stated as
counted equal; `GetDeclaredParamPattern` returns no pattern only for such a
parameter (a check of its other kinds, which aborted on an expression-pattern
requirement, is removed and that shape pinned); the return form's exclusion is
recorded; W-236's trigger is qualified and both upstream aborts are confirmed on
the nightly; the impl-file `MissingDefinitionInImpl` at a requirement is filed
as W-237. Commits 8fd124de8 (fixes), 0d596103e (goldens), 55d77c5e1 (the check
removed), f02f4dcf5 (its golden), 9197882e5 (records) and the records commit
after it, b3bb7bf31; measured on the toolchain built from
its sources and re-measured on the toolchain rebuilt from 55d77c5e1: the same
numbers, again on 9197882e5 for itself and for the records commit after it (gate
1959 passed, 0 failed; conformance 130 / 0 / 21 over 151, 49/56). Round 14's own
diff, a toolchain change (merge.cpp, comments in merge.h and
structural_conformance.cpp), had two implementation reviews (both
APPROVE-WITH-FIXES; 8 findings, none rejected; 1 MAJOR and no BLOCKER), folded
by fill round 15 (same day): a requirement with an expression pattern parameter,
which aborted every use against a member with one, is a TODO and is not
collected, as one with a tuple pattern parameter is, and upstream's aborts on
such a parameter, on import among them, are filed as W-238; a member's `self`
declared with a form that has an error is stated and pinned as a missing `self`;
the return form's exclusion is pinned; gap row 60 lists W-237 and W-238;
D-SC-9's mechanism cites are re-pointed. Commits 4bf275786 (the fix), fd736eb5d
(goldens) and the records commit after them, the branch head (Branches row);
measured on the toolchain built from its sources and re-measured on the
toolchain rebuilt from 4bf275786: the same numbers (gate 1959 passed, 0 failed;
conformance 130 / 0 / 21 over 151, 49/56). Round 15's own diff changes the
toolchain (handle_named_constraint.cpp, a comment in merge.cpp) and has no
implementation review on record: the round 15 toolchain change is unreviewed, so
the PR is not yet opened; it is to
be opened and held when a review round finds no MAJOR or BLOCKER and changes no
toolchain file.

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
| `claude/carbon-fork-0-1-sc` | IMPLEMENTED, FILLED, GATED AND CONFORMANCE-VERIFIED ON THE CONTAINER-BUILT TOOLCHAIN — ROUND 15 TOOLCHAIN CHANGE UNREVIEWED; the PR is to be opened and HELD OPEN until the land sequence once a review round finds no MAJOR or BLOCKER and changes no toolchain file. SC-1 (W-027, fork/structural/plan.md rev 2): `template constraint` method and associated-function requirements in three commits (33b22ecbd SC-1a, 1f207c892 SC-1b, 43575bf1d SC-1c) with their review folds (0a1339807, 098ba3d64, 42841fa8d), then fifteen fill rounds (1a7cce0b2 fixes, bcaeadb98 goldens, 2f4ebbf6e records; 6f2f40d3c fixes, 502e7861a goldens, cb85e6b8b records, and the fill-rounds records commit 830447980; 0efe76e7d fixes, bc8b37290 goldens, 5171e5eda records and the records commit 2497d5000 after it, folding round 2's two implementation reviews (REJECT: 1 BLOCKER, 1 MAJOR, 4 MINOR; APPROVE-WITH-FIXES: 2 MAJOR, 7 MINOR; 13 of the 15 fixed as asked, MAJOR-1 in part with its second guard declined on evidence, F5 in part with its ledger id deferred to round 4): a requirement `fn` as an impl member, which passed check and aborted lowering, is now rejected at the impl; round 4's aa67ea281 fixes, ff490bd48 goldens, d232d4753 records and the records commit 77838fdd5 after it, folding round 3's two implementation reviews (REJECT: 1 BLOCKER, 1 MAJOR, 2 MINOR; APPROVE-WITH-FIXES: 2 MAJOR, 7 MINOR; 13 fixed as asked): a requirement passed as a value, which checked clean and aborted lowering, is refused in `Convert`; an impl inside a `union` body has its structural `require` checked at the union's end; round 5's 616d0bc4f fixes, 18775fee3 goldens, df5120d03 records and the records commit a9c887101 after it, folding round 4's two implementation reviews (REJECT: 2 BLOCKER, 2 MAJOR, 1 MINOR; REJECT: 1 BLOCKER, 1 MAJOR, 2 MINOR; 9 findings, all fixed, none rejected): round 4's check was a use-site guard (R17), and `typeof` of a requirement and a template instantiated with a facet type still checked clean and aborted lowering, so a requirement named with no self type is now a value of its own concrete type, `StructuralRequirementType` (D-SC-20 replaced, the `.Self` lookup deleted), its value uses refused by type and at instantiation, the kind renamed `StructuralRequirementUsed`; round 6's 56e400145 fixes, fb12f63cb goldens, 857d5b048 records and the records commit 4bc4802ae after it, folding round 5's two implementation reviews (APPROVE-WITH-FIXES: 1 MAJOR, 2 MINOR; APPROVE-WITH-FIXES: 2 MAJOR, 6 MINOR; 11 findings, none rejected): a class, tuple, struct or array with a field of a requirement's type was refused at every destroy, so a reference kept a reference is not refused (D-SC-20 amended and narrowed), the type's import is pinned by import splits, miss (o)'s cause and round 5's prediction tally (R16(d)) are corrected; round 7's c0fa52df2 fixes, 36181a729 goldens, 30716a8c2 records and the records commit fa4cd094d after it, folding round 6's two implementation reviews (REJECT: 1 BLOCKER, 1 MAJOR, 1 MINOR; APPROVE-WITH-FIXES: 1 MAJOR, 3 MINOR; 7 findings, none rejected): names of a template constraint's body that depend on its `Self` (an alias of `Self`, nested declarations) checked clean in non-template code and aborted lowering, through D-SC-10's template-phase `Self`, so `Self` is a checked-phase binding (D-SC-10's break condition, the template phase an SC-B2 prerequisite), `const` and array types hold the requirement's type, a class value's field holding it is reached through a reference, and a refused tuple-index base is not diagnosed twice; round 8's 4c2ecee22 fixes, 3245ec0d2 goldens, 253dd4031 and a13e70542 records and the records commit ee1f905b0 after them, folding round 7's two implementation reviews (APPROVE-WITH-FIXES: 1 MAJOR, 2 MINOR; APPROVE-WITH-FIXES: 2 MAJOR, 4 MINOR; 9 findings, none rejected): the checked-phase `Self` is kept as a trade, re-weighed, with the requirement signatures it rejects at the definition (some satisfiable through round 6) filed as W-169 and the `require` with a `Self` argument it accepts pinned, and the compound-access TODO names a symbolic facet; round 9's 58dc46eb6 fixes, a5078358c goldens, 6231d5b42 records and the records commit ae807c7e8 after it, folding round 8's two implementation reviews (APPROVE-WITH-FIXES: 4 MINOR; APPROVE-WITH-FIXES: 2 MAJOR, 6 MINOR; 12 findings, one rejected in part): a mismatch against a requirement whose declaration has an error is not diagnosed again at each use, the trade's lost and restorable signatures are pinned in the repository, the records' overstatements are corrected (`Core.Slice(Self)` and `Core.Optional(Self)` were satisfiable through a class declaring its `Core.Copy` and `Core.Destroy` impls, and `require impls Core.Copy & Core.Destroy` restores both) and the symbolic-facet compound access is filed as W-232; round 10's 3ae639811 fixes, 001cdb4c7 goldens, 04755f23b and 0d7ee5c19 (an incomplete type's interfaces after its structural error pinned, and the golden), 6247769bb records and the records commit 444ccbafe after it, folding round 9's two implementation reviews (APPROVE-WITH-FIXES: 1 MAJOR, 4 MINOR; APPROVE-WITH-FIXES: 1 MAJOR, 5 MINOR; 11 findings, none rejected): only a requirement that cannot be compared with the type's member, because its declaration or the member's has an error, is skipped, so the failures round 9's guard hid are reported again, a requirement with a tuple pattern parameter is a TODO instead of an abort at every use, and the follow-on of an overload set or a blanket impl after such an error is filed as W-233 and the TODO as W-234; round 11's 2ee29f311 fixes, e7783c80e goldens, fa9038828 and 93f2b9f24 records and the records commit 62e25dcdd after them, folding round 10's two implementation reviews (APPROVE-WITH-FIXES: 1 MAJOR, 2 MINOR; APPROVE-WITH-FIXES: 2 MAJOR, 3 MINOR; 8 findings, none rejected): round 10's skip was still too broad, hiding a difference from a requirement or a member with an error that the error does not cause (a parameter count, a `self` form, a parameter or return type beside the error, a member that is not a function), so a mismatch is skipped only where the error causes it, as trunk's impl analog reports every other difference, a tuple pattern under a default value is the TODO too, and the ledger's SC-1 cites are re-pointed at the head; round 12's a6289f86e fixes, 62d39c9f6 goldens, 9af776bac and 395096d51 records, folding round 11's two implementation reviews (APPROVE-WITH-FIXES: 2 MAJOR, 3 MINOR; APPROVE-WITH-FIXES: 1 MAJOR, 4 MINOR; 10 findings, none rejected): an erroneous default value was read as no error, giving a spurious mismatch beside one and a new abort on two, and the records justified the skip by trunk's thunk, so the error handling is one rule, D-SC-5(d)'s comparison in an errors-match mode of upstream's own comparison (an error type matches any type, a parameter whose default value is the error is compared by its type), a requirement with `self` needs a member with `self`, and upstream's abort on two erroneous default values is filed as W-235; round 13's dfd22bdd6 fixes, 2af5604a3 goldens, 6992c6cc5 records and the records commit d3db9878c after it, folding round 12's two implementation reviews (APPROVE-WITH-FIXES: 1 MAJOR, 4 MINOR; APPROVE-WITH-FIXES: 1 MAJOR, 4 MINOR; 10 findings, none rejected): the errors-match mode compared a parameter with an error by its type alone, which hid its binding form (one case trunk's analog reports) and whether a default value is there, so it compares such a parameter as declared, only an erroneous type or default value counting as equal, an erroneous return type no longer matches none, the three missing fork markers are added, the rule is stated identically in the code, D-SC-9, the decision log and the design page, and trunk's thunk abort on an interface member's default value is filed as W-236; and round 14's 8fd124de8 fixes, 0d596103e goldens, 55d77c5e1 fixes, f02f4dcf5 goldens, 9197882e5 records and the records commit b3bb7bf31 after it, folding round 13's two implementation reviews (APPROVE-WITH-FIXES: 1 MAJOR, 3 MINOR; APPROVE-WITH-FIXES: 6 MINOR; 10 findings, two rejected in part): a parameter declared with a form that has an error, which upstream makes the error itself, matched any parameter, hiding a default value on the other side, so its default value's presence is compared and its binding form is stated as part of the error, `GetDeclaredParamPattern` returns no pattern only for such a parameter (8fd124de8's check of its other kinds aborted on an expression-pattern requirement and is removed by 55d77c5e1, which pins that shape), the return form's exclusion is recorded, W-236's trigger is qualified, and the impl-file `MissingDefinitionInImpl` at a requirement is filed as W-237; round 15's 4bf275786 fix, fd736eb5d goldens and the records commit after them, the head, folding round 14's two implementation reviews (APPROVE-WITH-FIXES: 1 MAJOR, 2 MINOR; APPROVE-WITH-FIXES: 5 MINOR; 8 findings, none rejected): a requirement with an expression pattern parameter, which aborted every use against a member with one, is a TODO and is not collected, upstream's aborts on such a parameter, on import among them, filed as W-238, a member's `self` declared with a form that has an error is stated and pinned as a missing `self`, and the return form's exclusion is pinned); docs page ported, two conformance programs under the structural bullet, ledger W-027 → implemented (W-134..W-143, W-151, W-168, W-169, W-232, W-233, W-234, W-235, W-236, W-237 and W-238 filed, W-168 the round-2 residue, W-169 round 8's, W-232 round 9's, W-233 and W-234 round 10's, W-235 round 12's, W-236 round 13's, W-237 round 14's, W-238 round 15's). Container results, as measured there (carbonbuild: fastbuild of the branch, Carbon assertions on; toolchain 0.0.0-0.dev+4bf275786 since round 15, 0.0.0-0.dev+55d77c5e1 at round 14, 0.0.0-0.dev+dfd22bdd6 at round 13, 0.0.0-0.dev+62d39c9f6 at round 12, 0.0.0-0.dev+e7783c80e at round 11, 0.0.0-0.dev+001cdb4c7 at round 10, 0.0.0-0.dev+a5078358c at round 9, 0.0.0-0.dev+3245ec0d2 at round 8, 0.0.0-0.dev+36181a729 at round 7, 0.0.0-0.dev+fb12f63cb at round 6, 0.0.0-0.dev+18775fee3 at round 5, 0.0.0-0.dev+ff490bd48 at round 4, 0.0.0-0.dev+bc8b37290 at round 3, 0.0.0-0.dev+6f2f40d3c before): autoupdate to fixpoint over the 19 SC-1 goldens; file_test gate 1959 passed / 0 failed (re-run on bc8b37290, on 5171e5eda with that toolchain, on ff490bd48, on d232d4753 with that toolchain, on 18775fee3, on df5120d03 with that toolchain, on fb12f63cb, on 857d5b048 with that toolchain, on the round-7 pre-commit build, on 36181a729, on 30716a8c2 with that toolchain, on the round-8 pre-commit build, on 3245ec0d2, on a13e70542 with that toolchain, on the round-9 pre-commit build, on a5078358c, on 6231d5b42 with that toolchain for itself and again for the records commit after it, on the round-10 pre-commit build, on 001cdb4c7, on 0d7ee5c19, on 6247769bb with that toolchain for the records commit after it, on the round-11 pre-commit build, on e7783c80e, on fa9038828 with that toolchain for 93f2b9f24, on 93f2b9f24 for the records commit after it, on the round-12 pre-commit build, on 62d39c9f6, on 9af776bac with that toolchain for itself and again for 395096d51, on the round-13 pre-commit build, on dfd22bdd6, on 6992c6cc5 with that toolchain for itself and again for d3db9878c, on the round-14 pre-commit builds, on 0d596103e with the toolchain rebuilt from 8fd124de8, on f02f4dcf5 with the toolchain rebuilt from 55d77c5e1, and on 9197882e5 with that toolchain for itself and again for b3bb7bf31, on the round-15 pre-commit build and on fd736eb5d with the toolchain rebuilt from 4bf275786); conformance into a private outdir 130 / 0 / 21 over 151, 49/56 (the same on 5171e5eda, on ff490bd48, on d232d4753, on 18775fee3, on df5120d03, on fb12f63cb, on 857d5b048, on the round-7 pre-commit build, on 36181a729, on 30716a8c2, on the round-8 pre-commit build, on 3245ec0d2, on a13e70542, on the round-9 pre-commit build, on a5078358c, on 6231d5b42 for itself and again for the records commit after it, on the round-10 pre-commit build, on 001cdb4c7, on 6247769bb for the records commit after it, on e7783c80e, on fa9038828 for 93f2b9f24, on 93f2b9f24 for the records commit after it, on the round-12 pre-commit build, on 62d39c9f6, on 9af776bac for 395096d51, on the round-13 pre-commit build, on dfd22bdd6, on 6992c6cc5 for itself and again for d3db9878c, on 0d596103e with the toolchain rebuilt from 8fd124de8, on f02f4dcf5 with the toolchain rebuilt from 55d77c5e1, and on 9197882e5 for b3bb7bf31, and on fd736eb5d with the toolchain rebuilt from 4bf275786), exactly generics/structural_conformance (SKIP → PASS, `42`, `7`) and the new interop/cpp_structural_conformance (PASS, `7`, `0`) moving. Hosted results: NOT RUN (Actions disabled), so none of this is of record (R9) until a hosted autoupdate, gate and conformance run on the PR head; fork/ORCHESTRATION.md conflicts with trunk's later header and Branches edits and is resolved at the merge. Round 9's review counted 2 MAJOR (MAJOR-1, the one finding of both reviews) and no BLOCKER, all folded by round 10; round 10's review counted 2 MAJOR (MAJOR-1, the one finding of both reviews; review 2's MAJOR-2, the PR body's length) and no BLOCKER, all folded by round 11; round 11's review counted 2 MAJOR (MAJOR-1, the one finding of both reviews; review 1's MAJOR-2, the records' rationale for the skip) and no BLOCKER, all folded by round 12; round 12's review counted 2 MAJOR (MAJOR-1, the one finding of both reviews) and no BLOCKER, all folded by round 13; round 13's review counted 1 MAJOR (review 1's) and no BLOCKER, all folded by round 14; round 14's review counted 1 MAJOR (review 1's, one finding of both reviews) and no BLOCKER, all folded by round 15; round 15's own diff, a toolchain change (handle_named_constraint.cpp, a comment in merge.cpp), has no implementation review on record: round 15 toolchain change unreviewed. Records: the plan's "Landed notes (SC-1 fill rounds, 2026-10-13)" and the decision log's "SC-1 fill rounds (2026-10-13)", which holds all fifteen rounds (the separate round-3 entry is folded into it). |
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
