# Orchestration snapshot

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-07-27 (post-PR #4: trunk includes upstream 39916ad)._
This copy lives on the w5 branch; PR #2 (b0) carries sibling edits to
fork/ state files — reconcile at whichever merges second.

**Weekly upstream-merge outcome (standing rule 5, 2026-07-27):** upstream
moved to `39916ad` (25 commits since `99cda60`). Staged, gate run 27
GREEN (release `fork-toolchain-27-fd4daca7b`), conformance scoreboard
non-regressing (68 PASS / 33 SKIP / 0 FAIL — byte-identical), MERGED to
trunk by way of PR #4. This branch (w5) has now merged that trunk back
in. Next check: Monday 14:00 UTC.

## Branches

| Branch | State |
| --- | --- |
| `claude/carbon-fork-0-1-7mwfb7` | Main fork branch; green (post-merge verified). Contains: fork/ process docs, conformance suite (96+ programs), match slice 1, error-handling + unions design docs |
| `claude/carbon-fork-0-1-7mwfb7-w4-match` | MERGED into fork branch; keep for history |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | ACTIVE: F-008..F-011 doc authoring. Scope: docs/design/** only |
| `claude/carbon-fork-0-1-b0` | GATE-GREEN; **PR #2 open into trunk, awaiting user review** (release `fork-toolchain-22-d2dad50e4`). |
| `claude/carbon-fork-0-1-w5` | GATE-GREEN (run 26, release `fork-toolchain-26-f40b4980f`); **PR #3 open into trunk, awaiting user review**. Six defects fixed in five adversarially-reviewed rounds during landing (see decision-log W5-S1 addendum). |
| `claude/carbon-fork-0-1-7mwfb7-{b0-exceptions,w5-choice,design-docs}` | STRANDED source branches; b0 + w5 fully reconstructed and superseded by the PRs above. design-docs reconstruction is NEXT, gated on the F-008..F-011 veto digest (presented 2026-07-20, unanswered). |

## Scoreboard (source of truth: run the suite, don't trust this line)

68 PASS / 33 SKIP / 0 FAIL programs (101 total, 5 differential C++-oracle
pairs); 39/56 bullets green (toolchain `fork-toolchain-11-c5281a36e`).

## CI on jmann345/carbon-lang (self-hosted runner "jeromehome", 28-core Arch)

-   `Fork: build toolchain` — full gate: tarball + `bazel test //toolchain/...`
    -   release. Per-ref concurrency. Dispatch by way of workflow_dispatch on any ref.
-   `Fork: fast compile check` — auto-fires on toolchain/common/core pushes to
    claude/**; builds `//toolchain/driver:carbon` only (~2 min warm).
-   `Fork: autoupdate testdata` — regenerates goldens on the runner and pushes
    back (R15). Fire by way of push to `fork/autoupdate-request.txt` or dispatch.
-   `Fork: mirror upstream nightly` — arbiter bootstrap; rarely needed now.
-   Runner offline detection: R14 (queued >10 min + nothing in_progress).

## Toolchains in the container

-   `/home/user/arbiter/carbon_toolchain-0.0.0-0.nightly.2026.07.19/bin/carbon` — upstream nightly
-   `/home/user/trial-tc/carbon_toolchain-0.0.0-0.dev/bin/carbon` — fork-built with match

## Next actions (dependency order)

1.  F-008..F-011 design-doc authoring (reuse design-docs branch; authors get
    the mark-OPEN-never-decide sub-fork instruction; batch sub-forks to the
    user by way of AskUserQuestion).
2.  W5 choice payloads implementation (contract: docs/design/unions.md
    "Relationship to choice types"); precede with the standing-rule-5
    upstream check (weekly Routine also armed).
3.  Error-handling B0 (--cpp-exceptions flag + fenced thunks; design final).
4.  Threading defect fixes (F-008, three defects, all decided).
5.  W-066 match usefulness diagnostics (after W-008).
6.  Conformance depth: differential Carbon-vs-C++ tests (harness support in
    progress), multi-program bullets.

## Standing user directives

-   Sub-forks ALWAYS by way of AskUserQuestion (process.md Human-in-the-loop).
-   Fixer is always a separate agent (R11); mechanical invariants by way of hooks
    (R12); user is commit author, Claude co-author.
