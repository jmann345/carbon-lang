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
PR #1 (match), PR #4 (upstream 39916ad), and PR #2 (B0 exception
boundary) are all MERGED to `trunk`. Go-forward structure: **one
workstream = one branch off `trunk` = one focused PR**.

**Weekly upstream-merge outcome (standing rule 5, 2026-07-27):** upstream
`39916ad` staged, gate-green, scoreboard non-regressing, merged by way of
PR #4. Next check: Monday 14:00 UTC.

## Branches

| Branch | State |
| --- | --- |
| `trunk` | Integrated line: match + arbiter + upstream 39916ad (PR #4) + B0 exception boundary (PR #2). Base all new work here. |
| `claude/carbon-fork-0-1-w5` | THIS branch: W5 slice 1, adversarially reviewed OK; **PR #3 open**, final composition (w5 + b0 + upstream) gating now. |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | STRANDED source for the F-008..F-011 design docs; reconstruction is NEXT, **gated on the user's veto-digest response** (presented 2026-07-20, unanswered). Reconstruct per the recipe pattern used for b0/w5 (overlay real content onto fresh branch off trunk; targeted-merge diverged files; prek + gate + PR). |
| `claude/carbon-fork-0-1-{7mwfb7,b0,7mwfb7-upstream-20260727}` and other `7mwfb7-*` | MERGED or superseded; do not stack new commits. |

## Scoreboard (source of truth: run the suite, don't trust this line)

68 PASS / 33 SKIP / 0 FAIL programs (101 total, 5 differential C++-oracle
pairs); 39/56 bullets green (toolchain `fork-toolchain-11-c5281a36e`).
Merged to trunk; B0 flips the exception-interop bullet when it lands.

## CI on jmann345/carbon-lang (self-hosted runner "jeromehome", 28-core Arch)

-   `Fork: build toolchain` — full merge gate: prek (R21) + tarball +
    clangd-tidy (R21) + `bazel test //toolchain/...` + release. Per-ref
    concurrency. Dispatch by way of workflow_dispatch on any ref.
-   `Fork: fast compile check` — auto-fires on toolchain/common/core pushes
    to claude/\*\*; builds `//toolchain:carbon` only (~2 min warm).
-   `Fork: autoupdate testdata` — regenerates goldens on the runner and
    pushes back (R15). Fire by way of push to `fork/autoupdate-request.txt`.
-   Runner offline detection: R14 (queued >10 min + nothing in_progress).

## Toolchains in the container

-   `/home/user/arbiter/carbon_toolchain-0.0.0-0.nightly.2026.07.19/bin/carbon` — upstream nightly
-   `/home/user/trial-tc/carbon_toolchain-0.0.0-0.dev/bin/carbon` — fork-built with match

## Next actions (dependency order)

1.  b0 exceptions: gate green, PR open — awaiting user review/merge.
2.  Reconstruct + land w5-choice slice 1 (payload choices) per the recipe
    (in progress on `claude/carbon-fork-0-1-w5`).
3.  Reconstruct + land design-docs (F-008..F-011) — the veto digest was
    presented to the user 2026-07-20; record any vetoes before it merges.
4.  W5 slices 2-4; then error-handling B1/B2/B3; threading defect fixes.
5.  Before W5-S2: re-platform match onto the pattern machinery (viability
    review finding — current impl is if/else-chain desugar).
6.  Conformance depth: differential pair per flipped bullet; scoreboard in CI.

## Standing user directives

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
