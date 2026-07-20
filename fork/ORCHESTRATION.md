# Orchestration snapshot

One-read resume state for any fresh session. **Update this file whenever
branches, in-flight CI, or next-actions change** (standing practice; the
quantized-state files carry the deep detail).

_Last updated: 2026-07-20 ~01:10Z_ (scope map: active branches are file-disjoint; expected merge collisions only in fork/ state files)

## Branches

| Branch | State |
| --- | --- |
| `claude/carbon-fork-0-1-7mwfb7` | Main fork branch; green (post-merge verified). Contains: fork/ process docs, conformance suite (96+ programs), match slice 1, error-handling + unions design docs |
| `claude/carbon-fork-0-1-7mwfb7-w4-match` | MERGED into fork branch; keep for history |
| `claude/carbon-fork-0-1-7mwfb7-design-docs` | ACTIVE: F-008..F-011 doc authoring. Scope: docs/design/** only |
| `claude/carbon-fork-0-1-7mwfb7-w5-choice` | ACTIVE: W5 S1 payload choices. Scope: check/handle_choice + match alt-patterns + choice testdata/programs |
| `claude/carbon-fork-0-1-7mwfb7-b0-exceptions` | ACTIVE: B0 exception boundary (gate dispatched). Scope: driver/compile_options, check/cpp/thunk.cpp, error_handling programs |

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
