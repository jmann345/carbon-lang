<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-08-18 (post-PR #21: F8c COMPLETE)._ TWENTY-ONE
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

89 PASS / 30 SKIP / 0 FAIL programs (119 total, 16 differential
C++-oracle pairs); **43/56 bullets green** (runner-side scoreboard at
the PR #16 head; verified from fork/conformance/out/scoreboard.json —
the error-handling control-flow bullet is the fork's first
error-handling flip). History: 73 → 77 at S2d/S2e → 78 at PR #11 → 79
at S3a → 80 at S3b → 81 at S3c → 83 at B1b
(error_handling/control_flow_constructs flip +
question_propagation_diff, a C++ early-return oracle). The scoreboard
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

1.  Reconstruct + land design-docs (F-008..F-011) — **gated on the
    user's veto-digest response** (presented 2026-07-20, unanswered).
2.  Error-handling B2/B3 per F-006 (next plan round); W5-S3p (prelude
    Result/Optional) stays GATED on the OPEN SF-9 fork — and W-071
    (Try associated-constant `Destroy` bounds, gating symbolic-operand
    `?`) is adjacent fork material for the same ask; W5-S4
    (std::variant mapping) rides its deferred planning decision;
    threading defect fixes (F-008). Residues: W-067 (default-clause
    guards), W-068 (fewer-than-two-alternative choices), W-069
    (cross-file runtime let), W-070 (unit break types, SF-9-blocked),
    choice `Core.Copy` construction gap, tuple/var/ref/compile-time
    case patterns, non-binding payload subpatterns (W-008).
3.  Conformance depth: differential pair per flipped bullet; scoreboard in
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
