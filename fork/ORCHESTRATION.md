<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-08-18 (post-PR #28: the W-069 workstream —
cross-file runtime `let`, DISCHARGED)._ TWENTY-EIGHT PRs. The
three-slice workstream closed an upstream-acknowledged gap: W69a's
lowering-side promotion (lane a1 — exported backing storage minted at
lowering, SemIR/import_ref untouched, GetValue routing reachable only
where the old CHECK crashed), W69h's multi-unit conformance capability
(directory programs, per-unit compile mirroring upstream's bazel rule,
byte-identical rerun arbiter), and W69b's pointer-rep arm + the
restored runtime `let g` acceptance split + BOTH discharge arbiters
incl. the fork's FIRST multi-unit program. Floor **95/0/29 over 124**
(evidenced twice, addition-only), 43/56 bullets. Twelve review rounds;
three honest defect rounds rode the close (W-074 export-x crash minted;
W-075 alternative-constant copy gap minted; the pre-existing
AcquireValue folded-ref crash FIXED fenced; aggregate-consumption
residue recorded). The _C<name>.<package> let-storage symbol shape is a
divergence-register entry reviewed at each weekly merge; the
three-golden PromoteObject churn was adjudicated accept-and-declare
(R-7's falsifier fired as designed). Next: W-074/W-075 (new S
candidates), the library_multifile_export un-SKIP follow-up (unblocked
by W69h), conformance depth; W-066 stays blocked on W-008._
TWENTY-SEVEN PRs. Single-alternative and empty
choices now pass the match scrutinee gate: the discriminant repr walk
factored into a shared query (`IsMatchableChoiceType` — integer OR
empty-tuple discriminant, anything else fails safe), constant-true
dispatch (the W-067 shape) where no integer discriminant exists, real
payload extraction (lower golden pins `br i1 true`, no icmp), and the
S2e exhaustiveness machinery needed zero arithmetic change. Empty
choices = lane (b): type admission only (no zero-arm grammar minted —
design-grounded, recorded loudly with an amended-at marker after a
review catch). Four fail_todo pins flipped, each verified sanctioned
(R16a). Floor **93/0/29 over 122**, 43/56 bullets. Reviews: A APPROVE
zero should-fixes; B no blockers. One-pass CI (fast compile →
autoupdate +1311 with no-commit fixpoint → gate → conformance, exact
floor). Hook-environment quirk recorded (distro clang-format 18.1.3 vs
CI pin 21.1.8). Next: the W-069 plan round (cross-file runtime `let`
lowering — upstream gap, V-3a check first)._ TWENTY-SIX PRs. `default if (E) => ...` is now a
working fork feature under the design's own license
(pattern_matching.md Guards; p002188): shared parse guard production
with default+if lookahead (arms after a guarded default are reachable),
check-side guarded-irrefutable-arm CFG (constant-true test + spliced
guard; failure edge line-for-line the case-guard shape), and the
exhaustiveness pin — a guarded default never discharges the `default`
requirement, enforced structurally and falsified by two red-line fail
goldens. Zero new diagnostics (R6). Floor **92/0/29 over 121** (moved
only by control_flow/match_guarded_default.carbon on the already-PASS
match bullet), 43/56 bullets. Reviews clean; coverage falsifiers added
at the review round. Mid-slice the self-hosted runner died ~07:33Z
(killed the first gate attempt mid-test — diagnosed infra by step-level
evidence, re-fired green after the runner returned ~09:20Z; recorded,
CI unchanged). Next: W-068 (fewer-than-two-alternative choices), then
the W-069 plan round._ TWENTY-FIVE PRs. The two-regime sweep landed across the
nine-file surface: seven non-final sites got scope-qualifying retext
only (all four golden retexts line-count-preserving — runner autoupdate
was a STRICT NO-OP, run 32097812689); the W72b pair (final impl) took
the simplification (`return self.(Core.Try.Branch)();` replaces the
deleted `Diverge` helper — re-arbitrated green at runtime by
conformance run 32098017538, the first-ever lowering exercise of the
collapsed recursive-call shape); error_handling.md got a dated
fourth-round re-correction and its final sketches now use the recursive
trailing return. Floor unchanged, EXACTLY 91/0/29 over 120, 43/56
bullets. Review round: no code defects; blocker (arbiter run not armed
by the landing commit — same class as the W72b round, recurrence noted)
already resolved by the follow-up bump; bookkeeping fixes landed.
Residue recorded not actioned: question_final.carbon,
lower/question_generic_final.carbon, and fail_question_final.carbon
still carry `Diverge` inside final impls (comment refresh rides any
future touch). Next: conformance depth (W-066) + residues
W-067/W-068/W-069._ TWENTY-FOUR PRs. The continue-THREADING runtime arbiter
(question_generic_thread_diff: `final impl forall` + load-bearing
Combine chaining, i32 AND i64 with high-half-significant wide seeds,
C++ template oracle) went green at exactly the target floor —
**91/0/29 over 120**, bullet count still 43/56 (the pair deepens the
already-PASS error-handling bullet to 4 programs). Three CI rounds, all
honest: round 1 COMPILE-FAIL root-caused to the bare `[T: Combinable]`
facet lacking the implicit Destroy witness the `type` facet carries
(fixed with the precedented `& Core.Destroy` conjunct — a test-authoring
defect, not a toolchain defect); round 2 the R-5 broken-oracle drill,
red as the predicted DIFF-MISMATCH (run 32096324806); round 3 the
discharge run (32096689454). Two adversarial reviews folded pre-merge
(discharge-run wiring blocker; i64 truncation blind-spot widened away;
(a)/(b) V-3a vetoes recorded on the log; W-073 sweep surface grown to
nine files). W-072 DISCHARGED per plan §6 in full; W-073 (the
Diverge-idiom and comment-family sweep) unblocks next. Scoreboard
history: ... → 88 F8b → 89 F8c → 90 F8d → 91 W72b._ TWENTY-THREE PRs. The B2a-era "hard limit" (generic `?` continue values
untheadable as `T`) dissolved with ZERO compiler change: non-reduction
through non-`final` impls is upstream-DESIGNED; the ratified
error_handling.md sketches spell `final impl` and B1b's testdata
dropped the keyword (R17 postmortem + new rule R27 landed —
sketch-implementing testdata is diffed against the sketch's exact
spelling). `let v: T = mr?;` now compiles clean (direct/mixed/import,
SemIR-pinned as genuine reduction). P-9 SURPRISE: the in-body
recursive-Branch call ALSO collapses under `final` — W-073 minted
(evaluate retiring the Diverge idiom + the eight-file comment family).
W72c (Try success ctor) parked in the SF-9/S3p brief with the
`final`-spelling recurrence flag. Floor unchanged 90/0/29 over 119;
W-072 stays OPEN until W72b's continue-THREADING runtime differential
(91/0/29 over 120) goes green._ TWENTY-TWO
PRs. F8d closed the workstream on the FIX path (degrade never needed):
`std::thread(Carbon::Work)` constructs directly — a concrete
non-generic non-member Carbon function maps to a pointer to its
exported decl, argument embedded as DeclRefExpr+decay, mapping
confined to the call-argument path (a correctness-review blocker
narrowed it; export-side function types still diagnose), same-signature
thunk collisions probed and fixed by way of mangled-suffix asm labels.
90/0/29 over 119, 43/56 bullets. F-008 TOTALS: 4 slices, 4 PRs, 8
adversarial reviews, 3 pre-merge blockers fixed, D1/D2/D3 all FIXED
(W-021/022/023 discharged; W-020 doc half stays digest-gated). The
fix's movement reached two upstream goldens whose function-argument
cases now compile._ TWENTY-ONE
PRs. F8c landed adjudication-first (plan adjudication D): the
real-header run refuted H0 live (undefined `_Ctotal.Main.2`/`.3`), the
fix is module-symbol-table reuse in `BuildNonCppGlobalVariableDecl`
(the global-side sibling of the function path's name-keyed dedup;
W-022 DISCHARGED), and the fired H0-mock-divergence stop-and-explain
path is filed per §2.3 (a strictness-review catch). 89/0/30 over 119;
specialization-typed Carbon globals now link and run
(`std::atomic<i64>` bumped by two bridge threads against the oracle).
Remaining F-008: F8d only (`std::thread(carbon_fn)` — p003848
upstream re-check first; documented-limitation degrade sanctioned)._ TWENTY PRs. F8b: trivially-destructible exported classes drop
the C++ destructor thunk (predicate reuses CanDestroyType's
classification; the review round's impl-population blocker resolved by
mirrored cross-IR enumeration with a two-file falsifier golden; W-021
DISCHARGED); std::atomic(CarbonClass) runs store/exchange/load against
its C++ oracle at runtime; the threading/atomics bullet flips —
**43/56 bullets**, 88/0/31 over 119. Remaining F-008: F8c
(specialization-global link; real-header adjudication run FIRST), F8d
(std::thread(carbon_fn); documented-limitation degrade sanctioned)._
NINETEEN PRs. F-008 is underway per fork/f008/plan.md: F8a landed the
zero-flip harness (two green thread programs on already-PASS bullets —
H-P pthread linkage CONFIRMED live; three SKIP defect arbiters quoting
the measured diagnostics; -pthread oracle line; 86/0/33 over 119).
Next slice F8b: std::atomic(CarbonClass) destructor-thunk fix — the
threading bullet flips there; then F8c (specialization-global link,
real-header adjudication first), F8d (std::thread(carbon_fn), degrade
path sanctioned)._
EIGHTEEN PRs merged. B2a landed as PR #18: the language-wide
symbolic-choice destroy widening (W-071 discharged, the `?`
symbolic-operand gate deleted), PLUS the mixed-width miscompile its
differential arbiter caught — root-caused per the no-slop directive to
POISON covering-template filler (`EmitAsConstant(UninitializedValue)`,
upstream-authored; SROA whole-scalar poison under partial overwrite;
fixed to zeros, p000257-sanctioned, flagged upstreamable) after two
implemented-then-refuted candidates (full three-round record in
fork/b2/mixed-width-diagnosis.md), PLUS coalescer hardening (sret
pointee in type fingerprints; absent-fingerprint pairs never merge;
builtin callees fingerprinted by value — upstream dedup goldens
restored). Scoreboard 84/0/30 over 114; W-072 minted (projection
non-reduction, Try success-constructor gap). B2b = the SF-9 brief in
PR #18's body (options a/b/c; default (c) defer). OPEN user asks: SF-9
brief, Trivial→NonTrivial ratification (PR #18 digest item 1),
design-docs veto digest (2026-07-20). Next workstream: F-008 threading
fixes per the approved amended plan (coordinator sign-off 2026-08-17)._
SIXTEEN PRs MERGED to `trunk`. B1 is complete across PRs #15/#16:
postfix `?` parses, desugars through the fork's FIRST prelude additions
(`Core.ControlFlow(C, B)` + `Core.Try` in `prelude/try`), and
propagates at runtime over user-defined generic-choice Results —
`Ok(v)?` yields `v`, `Err(e)?` converts and early-returns, verified
against a C++ early-return oracle. B1b took four golden cycles (prelude
`ImplicitAs` import for the first prelude `choice`; trailing unreachable
returns after exhaustive matches — reachability ignores exhaustiveness;
the projection-non-reduction trailing-return correction plus the
symbolic-operand narrowing W-071: `?` on SYMBOLIC-typed operands is
TODO-gated pending a `Destroy` bound decision on `Try`'s associated
constants — future fork material). `Check Dependent PRs` is now guarded
upstream-only (it hardcodes upstream and passed by number coincidence). W5-S3 is COMPLETE across PRs #12/#13/#14:
S3a (payload-free generic-choice specifics as match scrutinees), S3b
(payload synthesis + per-specific layout — five CI cycles, each defect
root-caused before the next push, see the decision-log five-cycle
addendum; headline sub-decision: `ResolveSpecificDefinition` recursion
guard redesigned to incremental publication; imported-binding constants
advance upstream's let-import TODO; W-069 records the cross-file
runtime-let gap), and S3c (payload destructuring on specifics +
`sum_types.md:60-89` landing as a runtime differential — declaration and
no-`default` match verbatim, construction adapted per the disclosed
`Core.Copy` gap; W-010 generic residue CLOSED, W-011 choice half
closed). `Optional(T: type) { Some(value: T), None }` now declares,
constructs, matches, and destructures through specifics at runtime with
per-specific layouts. Go-forward: **one workstream = one branch off
`trunk` = one focused PR**.

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
| `trunk` | Integrated line: match re-platform S2a-S2e + W5-S3a generic-choice specifics + B0 + W5-S1/S2 + upstream e7050af. Base all new work here. |
| `claude/carbon-fork-0-1-{b1,b1b}` | MERGED by way of PRs #15/#16 — error-handling B1 complete. |
| `claude/carbon-fork-0-1-w5-s3{,b,c}` | MERGED by way of PRs #12/#13/#14 — W5-S3 complete. |
| `claude/carbon-fork-0-1-match-{replatform,s2d,s2e}` and `claude/carbon-fork-0-1-upstream-2026{0728,0808}` | MERGED by way of PRs #7/#8/#9/#10 and #6. |
| `claude/carbon-fork-0-1-w5` | MERGED by way of PR #3 (composition gate run 30 green). |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | STRANDED source for the F-008..F-011 design docs; reconstruction is NEXT, **gated on the user's veto-digest response** (presented 2026-07-20, unanswered). Reconstruct per the recipe pattern used for b0/w5 (overlay real content onto fresh branch off trunk; targeted-merge diverged files; prek + gate + PR). |
| `claude/carbon-fork-0-1-{7mwfb7,b0,7mwfb7-upstream-20260727}` and other `7mwfb7-*` | MERGED or superseded; do not stack new commits. |

### Scoreboard (source of truth: run the suite, don't trust this line)

95 PASS / 29 SKIP / 0 FAIL programs (124 total, 18 differential
C++-oracle pairs, 1 multi-unit); **43/56 bullets green** (runner-side
scoreboard at the PR #28 head; verified from fork/conformance/out/scoreboard.json —
the error-handling control-flow bullet is the fork's first
error-handling flip, now 4 programs deep incl. the W72b threading
arbiter). History: 73 → 77 at S2d/S2e → 78 at PR #11 → 79
at S3a → 80 at S3b → 81 at S3c → 83 at B1b
(error_handling/control_flow_constructs flip +
question_propagation_diff, a C++ early-return oracle) → 84 B2a → 86 F8a
→ 88 F8b → 89 F8c → 90 F8d → 91 W72b → 92 W-067 → 93 W-068 → 95 W-069. The scoreboard
regenerates on the runner (`Fork: conformance suite`,
fork/conformance-request.txt trigger).

### CI on jmann345/carbon-lang (self-hosted runner "jeromehome", 28-core Arch)

-   `Fork: build toolchain` — full merge gate: prek (R21) + tarball +
    clangd-tidy (R21) + `bazel test //toolchain/...` + release. Per-ref
    concurrency. Dispatch by way of workflow_dispatch on any ref.
-   `Fork: fast compile check` — auto-fires on toolchain/common/core pushes
    to claude/\*\*; builds `//toolchain:carbon` only (~2 min warm).
-   `Fork: autoupdate testdata` — regenerates goldens on the runner and
    pushes back (R15). Fire by way of push to `fork/autoupdate-request.txt`.
-   Runner offline detection: R14 (queued >10 min + nothing in_progress).

### Toolchains in the container

-   `/home/user/arbiter/carbon_toolchain-0.0.0-0.nightly.2026.07.19/bin/carbon` — upstream nightly
-   `/home/user/trial-tc/carbon_toolchain-0.0.0-0.dev/bin/carbon` — fork-built with match

### Next actions (dependency order)

1.  New S-sized candidates from the W-069 close: W-074 (export-x
    runtime-let crash — the sanctioned import_ref amendment round) and
    W-075 (choice alternative-constant copy gap); the
    library_multifile_export un-SKIP follow-up (adjudicated, unblocked
    by W69h's multi-unit capability). W-066 stays blocked on W-008;
    conformance depth rides alongside.
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
