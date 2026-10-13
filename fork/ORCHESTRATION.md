<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

Last updated: 2026-10-13 (the ST-1 discharge: the dated paragraph after this
one). Earlier, 2026-10-12 (weekly check fired; BLOCKED: GitHub Actions on
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

ST-1 discharge (2026-10-13; pushed, PR to open and hold): ST-1
(claude/carbon-fork-0-1-st, fork/string/plan.md rev 3, W-057, gap row 77,
fork design F-014) is IMPLEMENTED AND DISCHARGED off trunk 80a11e7f0 —
84ff63560 (core/prelude/types/string.carbon 32 → 275 lines: byte-wise `==`,
`!=`, `<`, `<=`, `>` and `>=` on `str`, the owning `Core.StringBuf`, `+` and
`+=`, `i64` `str` subscripts; the export.cpp null check; eight CHECK-free
goldens), 16a87052f (the autoupdate fill: exactly the ten predicted goldens),
d8d10bf70 (string_missing_ops SKIP → PASS, four new String programs,
docs/design/strings.md, three dated amendments), 34e3af720 (both
implementation reviews folded, 15 MINOR, none rejected) and the discharge
commit (row 77 PARTIAL → DONE with filed limits, header 31 / 20 / 4 / 1,
W-057 DISCHARGED, W-160..W-167 filed, the F-014 decision-log entry).
Verification is container-built and NOT of record (Actions disabled): the
carbonbuild toolchain of 84ff63560, file_test 1950/1950 (1942 + 8), the
expected scoreboard 133 PASS / 0 FAIL / 21 SKIP over 154, 48/56 bullets
(scoreboard generated 2026-10-13T19:47:00Z), the five String programs the only
change from the floor of record 128 / 0 / 22 over 150, and the plan's
allocation shim balanced (`bad=0`) on all six String programs. Not run: Bazel
and its tests, clangd-tidy, any hosted run, an opt-mode toolchain, LLVM
assertions, non-Linux. Merge position: LAST, after PR 53, PR 51, PR 52, SC-1
and EV-1. Trunk 9d3ca60a3 (the id reservations and the EV-1 and ST-1 Branches
rows) is NOT merged into the branch, because the session's permission policy
refused that merge twice; merging it conflicts on the ST-1 Branches row only.
The merge steps are Next actions item 5; the SAFE-1 reconciliation ST-1 owes
at its rebase is item 6.

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
| `claude/carbon-fork-0-1-ev` | PLAN SIGNED OFF (rev 2) — EV-1 evaluator guides (W-062, gap row 90); ids W-152..W-159 reserved; implementation in progress on the container toolchain; merges after PR 52. |
| `claude/carbon-fork-0-1-st` | DISCHARGED AND PUSHED, PR to open and hold — ST-1 str comparison, `Core.StringBuf` and concatenation (F-014; W-057 DISCHARGED, gap row 77 expected DONE, W-160..W-167 filed) at 84ff63560, 16a87052f, d8d10bf70 and 34e3af720 plus the discharge commit; container-built verification only (file_test 1950/1950; expected 133/0/21 over 154, 48/56), not of record; merges LAST, after PR 53, PR 51, PR 52, SC-1 and EV-1 (Next actions 5 and 6). |
| `claude/carbon-fork-0-1-sc` | IMPLEMENTED, FILL IN PROGRESS — SC-1 template structural conformance, commits 1-3 at 42841fa8d with reviews folded (W-134..W-144; W-144 renumbers to W-151 at landing); PR after the fill converges. |
| `claude/carbon-fork-0-1-upstream-advance` | MERGED by way of PR #50 (14801f14a) — UA-1 (cut 631f8fb → c1e83b0b7); gate 37403008794 / conformance 37402970811 on 606a99c5a. UA-2 reconciliation cuts from the new trunk. |
| `trunk` | Integrated line: match re-platform S2a-S2e + W5-S3a generic-choice specifics + B0 + W5-S1/S2 + upstream e7050af. Base all new work here. |
| `claude/carbon-fork-0-1-{b1,b1b}` | MERGED by way of PRs #15/#16 — error-handling B1 complete. |
| `claude/carbon-fork-0-1-w5-s3{,b,c}` | MERGED by way of PRs #12/#13/#14 — W5-S3 complete. |
| `claude/carbon-fork-0-1-match-{replatform,s2d,s2e}` and `claude/carbon-fork-0-1-upstream-2026{0728,0808}` | MERGED by way of PRs #7/#8/#9/#10 and #6. |
| `claude/carbon-fork-0-1-w5` | MERGED by way of PR #3 (composition gate run 30 green). |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | STRANDED source for the F-008..F-011 design docs (the veto-digest gate dissolved under R29). The F-009 overloading page (functions_overloading.md + its cross-references) is PORTED by the OV-1/OV-3 slices — do not re-land it; the F-008/F-010/F-011 portions are ported by their own workstreams (F-011's if-let docs landed with W-012). Reconstruct per the recipe pattern used for b0/w5 (overlay real content onto fresh branch off trunk; targeted-merge diverged files; prek + gate + PR). |
| `claude/carbon-fork-0-1-{7mwfb7,b0,7mwfb7-upstream-20260727}` and other `7mwfb7-*` | MERGED or superseded; do not stack new commits. |

### Scoreboard (source of truth: run the suite, don't trust this line)

128 PASS / 22 SKIP / 0 FAIL programs (150 total); **48/56 bullets green**
(fork/conformance/out/scoreboard.json, generated 2026-10-06 by the hosted
conformance run 37402970811 on 606a99c5a: the floor of record, re-quoted from
the file at the ST-1 discharge, a quotation fix, not a regeneration; the line
had read 126 / 23 / 0 over 149 and 47/56 from the PR 48 run 37357609478).
Expected at ST-1, NOT of record: 133 PASS / 21 SKIP / 0 FAIL over 154, 48/56
(a container run on the carbonbuild toolchain of 84ff63560, scoreboard
generated 2026-10-13T19:47:00Z; the String bullet PASS over six programs).
History: 73 → 77 at S2d/S2e → 78 at PR #11 → 79 at S3a → 80
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
5.  ST-1 merge (`claude/carbon-fork-0-1-st`, F-014, W-057; merges LAST,
    after PR 53, PR 51, PR 52, SC-1 and EV-1), in this order:
    -   Merge trunk into the branch with a merge commit, never a rebase
        (AGENTS.md; the EV-1 precedent dff212ccc). Trunk 9d3ca60a3's ST-1
        Branches row conflicts with the branch's row: keep trunk's EV-1 row
        and the branch's ST-1 row, and drop trunk's "PLAN rev 1 in review"
        row; the id reservations (trunk's fork/ORCHESTRATION.md:69-75) merge
        cleanly.
    -   At the rebase onto a trunk holding PR 53, PR 51, PR 52, SC-1 and EV-1
        (fork/string/plan.md §6's same-anchor rules): re-anchor the F-014
        decision-log entry above the then-newest landed entry; re-apply the
        gap header's delta (the String row from PARTIAL to DONE) to whatever
        the header reads; re-read row 77's and row 41's lines; regenerate the
        conformance README table with `runner.py --update-readme-table`;
        append W-160..W-167 after the then-last ledger item; rebuild, refill
        (plan §7 R-9: SC-1's member-access changes) and re-run file_test (the
        base's count plus 8) and conformance, and re-quote the totals from
        that run (R9), never adding them by hand.
    -   Re-stamp, in a new commit if the merge date is not 2026-10-13, every
        landing-date stamp: strings.md's status line (:29-30), the three Fork
        amendment lines (docs/design/README.md:636,
        docs/design/expressions/arithmetic.md:190,
        docs/design/interoperability/README.md:303), W-057's "LANDED
        2026-10-13" title, row 77's "DISCHARGED 2026-10-13", the §W9
        paragraph's "DISCHARGED 2026-10-13" and the decision-log heading's
        date.
    -   strings.md, row 77 and the ledger cite W-126 (filed on the UA-2
        branch only) and W-148 (on the SAFE-1 branch only) on the assumption
        that PR 51 and PR 53 merge before ST-1, as this merge order has them;
        if either has not merged by then, its id is replaced by its item's
        title in a new commit.
    -   The id scan at the discharge read 68 refs: trunk W-125, ua2 W-127,
        cmake W-133, safe W-150, sc W-151, ev W-155, and W-160..W-167 unfiled
        elsewhere. Re-run it at the rebase; if any of W-160..W-167 is taken,
        re-allocate and renumber, in the same commit, docs/design/strings.md
        (W-160..W-167), the interoperability README's amendment (W-161) and
        string_concat_loop.carbon's header (W-160).
    -   When Actions returns, the hosted conformance run on the PR head is
        the record (expected: PASS +5, SKIP −1, programs +4 over the base,
        the String bullet PASS over six programs), and the "not of record"
        phrases go in a records commit.
    -   The carbonbuild gate.sh prints "0 failed" on a red file_test run
        (ST1-IR2-8); its fix goes in with the carbonbuild landing (the
        pending R28 amendment), and until then the gate verdict is read from
        the exit status and the log lines (plan §8.3).
6.  The SAFE-1 reconciliation ST-1 owes, verbatim from fork/string/plan.md
    §2.6 (PR 53 had not landed at ST-1's discharge). ST-1 merges after PR 53,
    so ST-1 makes these edits at its rebase; if ST-1 lands first, SAFE-1's
    rebase makes them:
    -   **W-144 (SAFE-1's, if on trunk at discharge):** its evidence gains
        `StringBuf.AsStr`, `StringBuf as ImplicitAs(str)`'s `Convert` (the view
        producers that need `bound self`) and `String.UnsafeMake` (an
        `UnsafeMake` for the `unsafe fn Make` rename), at their landed
        string.carbon lines; if PR 53 has not landed, the same three go into the
        ORCHESTRATION note of the SAFE-1 reconciliation below (amended
        2026-10-13, review fold: A-2 / B1). It also gains the interface
        declaration `ImplicitAs(Dest).Convert`
        (core/prelude/operators/as.carbon:23), with `As(Dest).Convert` (:18) and
        `UnsafeAs(Dest).Convert` (:13) for the workaround blankets at :27-34, as
        needing `bound self` beside `IndexWith.At` and `Copy.Op`: by F-013 T5(e)
        an impl may drop but not add `bound`, so without it the `Convert` impl
        cannot keep the loan (D-ST-11; the same fallback applies if PR 53 has
        not landed; amended 2026-10-13, review fold: RR-N-2).
    -   **SAFE-1 reconciliation** (amended 2026-10-13, review fold: B1). If PR
        53 has landed first (the ORCHESTRATION merge order), ST-1 makes these
        edits at its rebase; otherwise they go, verbatim, into ORCHESTRATION's
        "Next actions" for SAFE-1's rebase: (1) under EX-TM-7b's outcome
        (temporal_safety.md:831-840 on the safe branch), a dated ST-1 amendment:
        "Measured (ST-1 M-7, <date>): today's toolchain destroys a declaration
        initializer's temporaries at the end of the enclosing block, so this
        `v[0]` reads the live block (it prints 7 after a second `Make(4, 9)`);
        the design's loan still ends at the full-expression, and the next
        statement's use is `StrictBorrowOfTemporary`"; (2) dated amendments to
        spatial_safety.md SP2's one-gap list (:130-149) and to :433-438: `str`
        subscripts through the `"string.at"` builtin are unchecked (W-162), so a
        read through `Core.String` is not one of SP2's checked shapes; (3)
        initialization_safety.md:103-104's `types/string.carbon :28` becomes
        `:34`; (4) the W-144 evidence item above; (5) strings.md states
        D-SAFE-12 as the view rule (§2.5); (6) dated amendments to
        spatial_safety.md SP3 (:159-201) and to temporal_safety.md T2's "Copies
        preserve loans" paragraph (:264-273): the interface declaration
        `ImplicitAs(Dest).Convert` (core/prelude/operators/as.carbon:23), with
        `As(Dest).Convert` and `UnsafeAs(Dest).Convert` for the workaround
        blankets at :27-34, carries `bound self` per T5(e), beside
        `IndexWith.At` and `Copy.Op`, because an owner-to-view `Convert` (`Slice(T)
        as ImplicitAs(Slice(const T))`'s at slice.carbon:80-84, `StringBuf as
        ImplicitAs(str)`'s) creates a loan rather than preserving one, so T2's
        "every `ImplicitAs` impl is not a loan boundary" reads such a `Convert`
        as a `bound self` producer (amended 2026-10-13, review fold: RR-N-2);
        (7) under T4 (temporal_safety.md:303-317), a dated ST-1 example: "`s +=
        s;` on a `Core.StringBuf` is `StrictSharedBorrowInvalidated`: the
        by-value `other` is a shared loan on `s` (M8) and the `ref self` call
        invalidates `s` (M3(d)); it is memory-safe in today's toolchain, and the
        fork's spelling is `s += Core.StringBuf.Make(s);`", and, if W-148 is on
        trunk at discharge, its notes name D-ST-14's four expected trips
        (amended 2026-10-13, review fold: RR-N-1).
    -   **Cross-branch re-cites, conditional:** if SAFE-1 (PR 53) has landed
        first, its citations of string.carbon:16-27 and :16-28
        (docs/design/safety/mutation_safety.md:312, rust_interop.md:202,
        temporal_safety.md:736 and :960) become :16-32 and :16-34, and
        mutation_safety.md's `Plain` table gains the row "`Core.StringBuf` |
        no | owns a heap block, `impl as Destroy` frees it
        (string.carbon:141-171)" with a dated ST-1 note; the decision log's
        historical entries are not edited.

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
