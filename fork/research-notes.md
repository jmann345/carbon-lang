# Research notes: methodology sources for the 0.1 push

This fork's process is modeled on two projects and their write-ups:

1. **"How Anthropic runs large-scale code migrations with Claude Code"**
   (claude.com/blog/ai-code-migration)
2. **"Rewriting Bun in Rust"** (bun.com/blog/bun-in-rust)

Both origin sites are blocked from this execution environment's network
policy; the content below was reconstructed from search snippets and
secondary coverage (Simon Willison, The Register, Developers Digest,
XenoSpectrum, 36kr, Andrew Kelley's response post). Treat exact wording as
paraphrase, numbers as reported.

## 1. The Anthropic migration framework

Headline: in one month, individual developers at Anthropic migrated 10
packages of tens-to-hundreds of thousands of lines each using Claude
Fable 5 / Opus 4.8 and dynamic workflows. Two flagship examples: Bun
Zig→Rust (~535K lines ported, ~1M lines of Rust produced, 11 days) and a
Python→TypeScript migration (165K lines over a weekend).

**Core insight: "You don't fix the code. You fix the process (loop) that
produced the code."** When a reviewer keeps catching the same mistake
across files, the fix is not per-file — you add one sentence to the
rulebook and regenerate the affected batch. The rulebook keeps growing;
the code never gets hand-patched against it.

### The six-step framework

1. **Set up the arbiter.** An objective, executable ground truth that
   decides success — typically an existing test/conformance suite. Agents
   perform best when verification is objective, because the model can
   grind against ground truth for days without a human arbitrating
   quality.
2. **Write the rulebook.** How code is to be translated/written: idioms,
   type mappings, error-handling conventions, what to refactor vs.
   translate mechanically. The rulebook comes *before* the gap inventory.
3. **Map the dependency graph.** Order workstreams so nothing is built on
   an unported/unfinished foundation.
4. **Create the gap list.** An inventory of places needing judgment
   (refactor rather than mechanical translation) — defined by what the
   rulebook's defaults *won't* cover. Rulebook + gap list are stress-tested
   together in a joint audit.
5. **Trial run ("shakedown cruise").** A mini-migration before scaling:
   e.g. one agent translates 3 files by the rulebook, another translates
   the same 3 files "like a senior engineer", a third diffs the two and
   proposes new rules. In Bun's case this caught two critical issues
   before they would have fanned out across all 1,448 files.
6. **Full run.** Scale the implement → review → fix loop across the
   dependency-ordered work list; then compile, execute, and compare
   behavior. Drift has nowhere to hide: reviewers cite the rule behind
   every finding, so a violation becomes a queue item instead of a quiet
   divergence; every edge case an agent hits becomes a rule every
   subsequent agent follows.

## 2. The Bun rewrite: concrete mechanics

- **Why**: mixing Zig manual memory management with JavaScriptCore's GC
  produced recurring use-after-free / double-free / leak-at-error-boundary
  bugs. In safe Rust these are compile errors — "compiler errors are a
  better feedback loop than a style guide."
- **Arbiter**: Bun's test suite is written in TypeScript, so it is
  implementation-language-independent — a true conformance suite with
  >1M assertions. 100% pass in CI before merge, on 6 platforms
  (macOS/Linux/Windows × x64/arm64).
- **Fleet shape**: ~50 dynamic Claude Code workflows over the project; at
  peak 4 workflows at once, each in its own git worktree, 16 Claudes per
  workflow ≈ 64 concurrent agents; peak ~1,300 lines/minute.
- **Fix loop**: batches of ~100 random failing test files sharded to one
  of 4 worktrees by folder. Per failing test: stacktrace + errors saved to
  a file → 1 implementer proposes a fix → 2 adversarial reviewers (fresh
  context windows, prompted to exhaustively argue why the change is wrong
  or buggy) → 1 fixer applies. Clippy sweep: 4 parallel fixer shards, 2
  reviewers per diff who both must approve, 9 rounds to zero violations.
- **Isolation**: systemd-run/cgroups for memory/CPU limits and pid
  namespace isolation per test run.
- **CI loop**: a workflow looped on each platform's CI failures until
  zero.
- **Numbers**: 11 days, ~$165K API cost at list pricing, 19 known
  regressions post-merge (all fixed).

### The criticism worth internalizing (Andrew Kelley)

The Zig creator's objection: "The argument for shipping a million lines of
unreviewed code is that the test suite is good enough to catch everything.
It's not sufficient to catch bugs in Zig code but it is sufficient in a
million lines of unreviewed slop?" — i.e. **an arbiter is only as good as
its coverage**, and a process that outruns reflection accumulates debt.
Consequences for this fork:

- Grow the arbiter *first and continuously*: every feature workstream
  lands with conformance tests before its implementation loop scales.
- Adversarial review is not optional ceremony; reviewers must cite the
  design doc/rule behind each finding.
- Prefer landing small, dependency-ordered increments that keep trunk
  green over big-bang branches.

## 3. Why Carbon-to-0.1 is *not* a migration, and what transfers

Carbon 0.1 is a **completion** problem (design + implement missing
features in an existing, well-tested compiler), not a translation problem.
What transfers directly:

- The **arbiter** concept → a 0.1 conformance suite: one executable test
  per milestone bullet (compile-and-run programs + interop programs),
  graded continuously.
- The **rulebook** → Carbon already has one: `docs/design/`, the accepted
  `proposals/`, and the toolchain style docs. Gaps in the rulebook are
  *design gaps* — exactly the "gap list" of places needing human judgment
  (= the user's design-fork decision points).
- The **dependency map** → feature dependency ordering (e.g. sum types
  before match-on-variant before `Optional` interop).
- The **trial run** → prove the loop end-to-end on one small feature
  before fanning out.
- The **implement → adversarial-review → fix loop** → per-feature loops
  grinding against `file_test` expectations and the conformance suite.

Key difference: milestone bullets need *design decisions* first, and per
Carbon's own evolution process those are normally proposals. In a personal
fork we replace the proposal committee with **the user at design forks**,
recorded in `fork/decision-log.md`.

## Sources

- [How Anthropic runs large-scale code migrations with Claude Code](https://claude.com/blog/ai-code-migration)
- [Rewriting Bun in Rust](https://bun.com/blog/bun-in-rust)
- [Simon Willison on the Bun rewrite](https://simonwillison.net/2026/Jul/8/rewriting-bun-in-rust/)
- [Developers Digest: 535K lines in 11 days](https://www.developersdigest.tech/blog/bun-rust-rewrite-535k-lines)
- [The Register: merged at the speed of AI](https://www.theregister.com/devops/2026/05/14/anthropics-bun-rust-rewrite-merged-at-speed-of-ai/5240381)
- [The Register: Zig creator's criticism](https://www.theregister.com/devops/2026/07/14/zig-creator-calls-buns-claude-rust-rewrite-unreviewed-slop/5270743)
- [Andrew Kelley: My Thoughts on the Bun Rust Rewrite](https://andrewkelley.me/post/my-thoughts-bun-rust-rewrite.html)
- [36kr deep dive](https://eu.36kr.com/en/p/3899401843017608)
