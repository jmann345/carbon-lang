# Decision log

Every design fork — a point where the user chose among researched options —
is recorded here. Format: context, options considered, decision, date,
consequences. Undecided forks are listed as OPEN at the top.

## OPEN forks

- **F-005: Own-toolchain build environment.** The conformance arbiter
  currently runs on the upstream *prebuilt nightly* toolchain. The moment
  we modify compiler code, we need to build our own toolchain — infeasible
  in this container (4 CPU / ~30 GB disk / BCR downloads gated; a full
  LLVM+Clang build needs 30–50 GB and 4–8 h). Options when we get there:
  bigger session environment (60 GB+ disk, open network), CI-side builds
  (GitHub Actions on the fork), or a self-hosted runner.

## Decided

### F-001: What "0.1" means for this fork — **Staged official 0.1** (2026-07-19)

Chase the full official checklist from `docs/project/milestones.md`, in
dependency order, tagging intermediate fork milestones (`fork-0.1-alpha`,
`fork-0.1-beta`, …) as scoreboard tiers go green. Design authorship for
the undesigned bullets is in scope. Alternatives rejected: pragmatic
subset-0.1 (diverges from the official definition), upstream-lockstep
(too slow, not autonomous).

### F-002: Upstream relationship — **Bun-style merge gating** (2026-07-19)

User's words: "Follow the same approach used by the Bun zig->rust rewrite
for merging into my fork branch." Interpretation (recorded for review):
in the Bun rewrite, work happened in isolated worktrees/branches and
merged only after **100% of the pre-existing test suite passed in CI**.
Applied here:

- Feature work happens in child branches/worktrees, never directly on
  `claude/carbon-fork-0-1-7mwfb7`.
- A merge into the fork branch requires the full pre-existing toolchain
  test suite plus the conformance scoreboard to be green (no skipped or
  deleted tests to force a pass).
- Upstream trunk merges are treated the same way: merge upstream into a
  staging branch, re-run the suite, land only when green.

### F-003: First scaled track — **Design sprint + match chain in parallel** (2026-07-19)

After the conformance-harness trial (W1): agent fleets draft the missing
designs (error handling, unions, if-let/let-else, function overloading,
threading/atomics interop; then safe Carbon) with the user reviewing at
each design fork, while the implementation loop grinds
match semantics → choice payloads → std::variant/optional interop against
the harness.

### F-004: Arbiter toolchain source — **Upstream nightly prebuilt** (2026-07-19)

User approved adding `carbon-language/carbon-lang` to the session to
download the nightly prebuilt toolchain tarball (Linux x86_64). This
arbitrates *language behavior* while our fork's tree equals upstream
trunk; it cannot execute fork-local compiler changes — see OPEN F-005.
