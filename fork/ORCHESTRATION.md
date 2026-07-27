<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-07-27 (post-PR #4: trunk includes upstream 39916ad)._
ALL FOUR PRs MERGED to `trunk`: PR 1 (match), PR 4 (upstream
39916ad), PR 2 (B0 exception boundary), and PR 3 (W5 choice payloads
slice 1) — each behind a green composition gate of the exact resulting
tree plus adversarial review (2 reviewers per feature PR, a
merge-integrity audit for the upstream merge). Go-forward: **one
workstream = one branch off `trunk` = one focused PR**.

**Weekly upstream-merge outcome (standing rule 5, 2026-07-27):** upstream
`39916ad` staged, gate-green, scoreboard non-regressing, merged by way of
PR #4. Next check: Monday 14:00 UTC.

## Branches

| Branch | State |
| --- | --- |
| `trunk` | Integrated line: match + arbiter + upstream 39916ad (PR #4) + B0 exception boundary (PR #2). Base all new work here. |
| `claude/carbon-fork-0-1-w5` | MERGED by way of PR #3 (composition gate run 30 green). |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | STRANDED source for the F-008..F-011 design docs; reconstruction is NEXT, **gated on the user's veto-digest response** (presented 2026-07-20, unanswered). Reconstruct per the recipe pattern used for b0/w5 (overlay real content onto fresh branch off trunk; targeted-merge diverged files; prek + gate + PR). |
| `claude/carbon-fork-0-1-{7mwfb7,b0,7mwfb7-upstream-20260727}` and other `7mwfb7-*` | MERGED or superseded; do not stack new commits. |

### Scoreboard (source of truth: run the suite, don't trust this line)

73 PASS / 34 SKIP / 0 FAIL programs (107 total, 7 differential C++-oracle
pairs); **40/56 bullets green** (toolchain `fork-toolchain-30-7c8a55e69`,
the merged trunk composition). B0 flipped the exception-interop bullet;
W5 kept sum-types green after a real catch: upstream 39916ad made `base`
a reserved word in binding patterns, which broke choice_discriminant_diff
on its first merged-tree run — renamed to `seed` (this file's commit).

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
2.  Before W5-S2: re-platform match onto the pattern machinery (viability
    review finding — current impl is if/else-chain desugar).
3.  W5 slices 2-4; error-handling B1/B2/B3; threading defect fixes (F-008).
4.  Recorded follow-ups from the landing reviews: b0 fence-unbuildable
    fail_ golden candidate; w5 OneShot single-alt-payload testdata;
    multi-hop export-import scrutinee test; `choice C { A, A }`
    duplicate-name diagnostic (pre-0.1); S2 name-to-index metadata
    replacing constant excavation.
5.  Conformance depth: differential pair per flipped bullet; scoreboard in
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
