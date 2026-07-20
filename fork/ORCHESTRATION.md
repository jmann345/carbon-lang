# Orchestration snapshot

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-07-20 ~04:00Z_ — PR #1 (match slice 1 + all process/arbiter infra) MERGED to `trunk` (origin/trunk == 6793618). Go-forward structure: **one workstream = one branch off `trunk` = one focused PR** (V-review fix for the 162-file mega-PR bloat).

## Branches

| Branch | State |
| --- | --- |
| `trunk` | Integrated fork line; has match, arbiter (101 programs), error-handling+unions design docs, R21/R23/R24/R25 prevention. Base all new work here. |
| `claude/carbon-fork-0-1-7mwfb7` | MERGED by way of PR #1 — finished; do not stack new commits. |
| `claude/carbon-fork-0-1-b0` | NEW off trunk: b0 exception-boundary reconstruction (this branch). |
| `claude/carbon-fork-0-1-7mwfb7-{b0-exceptions,w5-choice,design-docs}` | STRANDED ~17 commits behind trunk; source material for reconstruction, do NOT merge as-is. |

## Reconstruction recipe (stranded branch -> fresh branch off trunk)

The stranded feature branches predate the merge + prevention layers, so
reconstruct rather than rebase. For each (b0 first):

1.  `git checkout -B <new> origin/trunk`.
2.  Overlay ONLY the real code, from the stranded branch:
    -   **b0**: `toolchain/check/cpp/{import,thunk}.{cpp,h}`,
        `toolchain/driver/compile_options.{cpp,h}` (overlay clean — trunk's
        match touched handle_match/node_stack/inst_namer, not these);
        4 programs under `fork/conformance/programs/error_handling/`;
        `fork/b0-exc/plan.md`.
    -   **Targeted merges** (do NOT file-overlay — trunk's versions moved on):
        b0's COMPILE-ARGS directive into trunk's `runner.py` + its doc into
        `fork/conformance/README.md`.
    -   **DROP** b0's `fork_build_toolchain.yaml` (stale, pre-R21) and its
        72 regenerated goldens (regenerate on trunk by way of autoupdate).
3.  `uvx prek run --all-files` clean + `runner.py --self-test` (R25) before push.
4.  Push -> fast-check (compile) -> autoupdate (goldens) -> gate -> PR.

## Scoreboard (source of truth: run the suite, don't trust this line)

68 PASS / 33 SKIP / 0 FAIL programs (101 total, 5 differential C++-oracle
pairs); 39/56 bullets green (toolchain `fork-toolchain-11-c5281a36e`).
Merged to trunk; B0 will flip the exception-interop bullet when it lands.

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
