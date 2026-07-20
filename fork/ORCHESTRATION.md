<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-07-20 (weekly upstream check)._ PR #1 (match slice 1
plus all process/arbiter infra) MERGED to `trunk` (origin/trunk ==
6793618). Go-forward structure: **one workstream = one branch off `trunk`
= one focused PR** (the viability-review fix for the 162-file mega-PR
bloat).

**Weekly upstream-merge check (standing rule 5):** upstream
carbon-language/carbon-lang `trunk` is unchanged at `99cda60` — zero
divergence from our base, nothing to merge. No staging branch created.
Next check: Monday 14:00 UTC.

## Branches

| Branch | State |
| --- | --- |
| `trunk` | Integrated fork line: match, arbiter (101 programs), error-handling + unions design docs, R21/R23/R24/R25 prevention. Base all new work here. |
| `claude/carbon-fork-0-1-7mwfb7` | MERGED by way of PR #1 — finished; do not stack new commits. |
| `claude/carbon-fork-0-1-b0` | NEW off trunk: b0 exception-boundary reconstruction. |
| `claude/carbon-fork-0-1-7mwfb7-{b0-exceptions,w5-choice,design-docs}` | STRANDED ~17 commits behind trunk; source material for reconstruction, do NOT merge as-is. |

## Reconstruction recipe (stranded branch to fresh branch off trunk)

The stranded feature branches predate the merge plus prevention layers, so
reconstruct rather than rebase. For each (b0 first):

1.  `git checkout -B <new> origin/trunk`.
2.  Overlay ONLY the real code from the stranded branch. For b0:
    `toolchain/check/cpp/{import,thunk}.{cpp,h}` and
    `toolchain/driver/compile_options.{cpp,h}` overlay clean (trunk's match
    touched handle_match/node_stack/inst_namer, not these); the 4 programs
    under `fork/conformance/programs/error_handling/`; `fork/b0-exc/plan.md`.
3.  Targeted-merge (do NOT file-overlay — trunk's versions moved on): b0's
    COMPILE-ARGS directive into trunk's `runner.py`, and its doc into
    `fork/conformance/README.md`.
4.  DROP b0's `fork_build_toolchain.yaml` (stale, pre-R21) and its 72
    regenerated goldens (regenerate on trunk by way of autoupdate).
5.  Verify `uvx prek run --all-files` clean and `runner.py --self-test`
    (R25) before push.
6.  Push, then fast-check (compile), autoupdate (goldens), gate, PR.

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

1.  Reconstruct + land b0 exceptions (branch above): overlay code, push,
    autoupdate goldens, gate, open PR into trunk.
2.  Reconstruct + land w5-choice slice 1 (payload choices) the same way.
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
