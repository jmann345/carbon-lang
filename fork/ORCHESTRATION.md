<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-08-08 (post-PR #13: W5-S3b — generic choice payload
synthesis)._
THIRTEEN PRs MERGED to `trunk`, most recently: PR 11 (exception-interop
differential pair), PR 12 (W5-S3a: payload-free generic-choice specifics
as match scrutinees), PR 13 (W5-S3b: payload synthesis + per-specific
layout — `Optional(T: type) { Some(value: T), None }` constructs and
matches at runtime through specifics; `CustomLayoutType` sentinel +
per-specific eval-hook recompute; SF-6 at monomorphization; generic
constructor synthesis; full alternative tables). S3b took FIVE CI
cycles, each defect root-caused before the next push (see the
decision-log five-cycle addendum): a definition-path assert, a missing
import-resolver case, a pre-existing non-canonical-blocks bug, a
two-defect constructor rework whose review caught a P0 memcpy-clobber
miscompile (fixed with `UpdateInit` sequencing), and value-less imported
alternative bindings (the resolver now propagates bound-value constants
— advancing upstream's own let-import TODO; two upstream
`fail_*.impl.carbon` splits now pass and were renamed). Notable
sub-decision: `ResolveSpecificDefinition`'s recursion guard is redesigned
to incremental publication (prefix reads legal, loud CHECK on forward
references). W-069 records the cross-file runtime-let gap. Go-forward:
**one workstream = one branch off `trunk` = one focused PR**.

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
| `claude/carbon-fork-0-1-w5-s3{,b}` | MERGED by way of PRs #12 (S3a) and #13 (S3b). S3c continues on a fresh branch off `trunk`. |
| `claude/carbon-fork-0-1-match-{replatform,s2d,s2e}` and `claude/carbon-fork-0-1-upstream-2026{0728,0808}` | MERGED by way of PRs #7/#8/#9/#10 and #6. |
| `claude/carbon-fork-0-1-w5` | MERGED by way of PR #3 (composition gate run 30 green). |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | STRANDED source for the F-008..F-011 design docs; reconstruction is NEXT, **gated on the user's veto-digest response** (presented 2026-07-20, unanswered). Reconstruct per the recipe pattern used for b0/w5 (overlay real content onto fresh branch off trunk; targeted-merge diverged files; prek + gate + PR). |
| `claude/carbon-fork-0-1-{7mwfb7,b0,7mwfb7-upstream-20260727}` and other `7mwfb7-*` | MERGED or superseded; do not stack new commits. |

### Scoreboard (source of truth: run the suite, don't trust this line)

80 PASS / 31 SKIP / 0 FAIL programs (111 total, 10 differential
C++-oracle pairs); **41/56 bullets green** (runner-side scoreboard at
the PR #13 head; verified from fork/conformance/out/scoreboard.json).
History: 73 → 74 at S2c → 77 at S2d/S2e → 78 at PR #11 → 79 at S3a
(choice_generic_roundtrip: the program whose SIGSEGV drove the S3a
crash fix) → 80 at S3b (types/choice_generic_diff: C++ std::variant
oracle over payload-carrying specifics, runtime-computed payloads incl.
a low-byte-1 discriminant-collision probe). The scoreboard regenerates
on the runner (`Fork: conformance suite`, fork/conformance-request.txt
trigger).

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
2.  W5-S3c (payload destructuring on specifics + the sum_types.md doc
    example, the M slice closing fork/w5-s3/plan.md; floor target 81/112
    per amended §8) then W5-S3p (prelude Result/Optional — GATED on the
    OPEN SF-9 fork); error-handling B1/B2/B3; threading defect fixes
    (F-008). Residues: W-067 (default-clause guards), W-068
    (fewer-than-two-alternative choices), W-069 (cross-file runtime
    let), tuple/var/ref/compile-time case patterns, non-binding payload
    subpatterns (W-008).
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
