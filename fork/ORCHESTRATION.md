<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-07-29 (post-PR #7: match re-platform S2a-S2c merged)._
SEVEN PRs MERGED to `trunk`: PR 1 (match), PR 4 (upstream 39916ad),
PR 2 (B0 exception boundary), PR 3 (W5 choice payloads slice 1), PR 5
(review follow-ups), PR 6 (upstream 7d89ac9), PR 7 (match re-platform
S2a-S2c: pattern machinery + constant patterns + bindings + choice
payload destructuring, discharging W5-S2) — each behind a green
composition gate of the exact resulting tree plus adversarial review
(2 reviewers per feature slice, a merge-integrity audit per upstream
merge). Go-forward: **one workstream = one branch off `trunk` = one
focused PR**.

**Weekly upstream-merge outcome (standing rule 5, 2026-07-28):** upstream
`7d89ac9` (8 commits; shared-ASTContext flag, orphan-rule anchoring)
staged, 3 conflicts resolved, goldens runner-reconciled to R26 fixpoint,
gate run 35 green, merge-integrity audit OK (no blockers), merged by way
of PR #6. Recorded advisory: the two interop cpp import goldens carry a
permanent fork-vs-upstream `CppInteropParseNote` placement difference
(the fork's thunk is the "use") and will re-conflict whenever upstream
edits those STDERR blocks. Next check: Monday 14:00 UTC.

## Branches

| Branch | State |
| --- | --- |
| `trunk` | Integrated line: match re-platform S2a-S2c (PR #7) + B0 + W5-S1 + follow-ups + upstream 7d89ac9. Base all new work here. |
| `claude/carbon-fork-0-1-match-replatform` | MERGED by way of PR #7 (gate runs 34/36/37/38 green; four slices, each two-adversary reviewed + fixer rounds; W5-S2 discharged). |
| `claude/carbon-fork-0-1-upstream-20260728` | MERGED by way of PR #6. |
| `claude/carbon-fork-0-1-w5` | MERGED by way of PR #3 (composition gate run 30 green). |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | STRANDED source for the F-008..F-011 design docs; reconstruction is NEXT, **gated on the user's veto-digest response** (presented 2026-07-20, unanswered). Reconstruct per the recipe pattern used for b0/w5 (overlay real content onto fresh branch off trunk; targeted-merge diverged files; prek + gate + PR). |
| `claude/carbon-fork-0-1-{7mwfb7,b0,7mwfb7-upstream-20260727}` and other `7mwfb7-*` | MERGED or superseded; do not stack new commits. |

### Scoreboard (source of truth: run the suite, don't trust this line)

74 PASS / 33 SKIP / 0 FAIL programs (107 total, 7 differential C++-oracle
pairs); **41/56 bullets green** (toolchain `fork-toolchain-38-723e88e95`,
the S2c tree = the PR #7 head). S2c flipped "Control flow: matching —
sum-type consumption incl. std::variant/std::optional interop" to PASS
by way of the un-SKIPped choice_payload_roundtrip_diff differential program.
Earlier context: B0 flipped the exception-interop bullet; upstream
39916ad's `base` reservation broke choice_discriminant_diff once —
renamed to `seed`.

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
2.  Match re-platform remainder: S2d (guards, plan §3.4 — discharges the
    three "match case guard" TODO sites + flips two conformance SKIP
    evidences; must resolve the recorded S2c engine-fold deviation and
    re-derive R-7 for guards) then S2e (exhaustiveness, plan §3.5) —
    each on a fresh branch off trunk through the full R11 loop.
3.  W5 slices 3-4 (S2 destructuring landed with PR #7); error-handling
    B1/B2/B3; threading defect fixes (F-008).
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
