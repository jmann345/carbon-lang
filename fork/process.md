# Process: how this fork gets to 0.1

Adaptation of the six-step migration framework (see
`research-notes.md`) to a *language-completion* project. The unit of work
is a **milestone bullet** from
`docs/project/milestones.md#milestone-01`, not a file.

## Roles

- **Claude (agent fleets)**: audits, designs options, implements, tests,
  adversarially reviews, fixes — autonomously between checkpoints.
- **The user**: decides at **design forks** — points where the Carbon
  design is unsettled, where we must diverge from upstream, or where scope
  is being traded. Every decision is recorded in `decision-log.md` with
  the options that were on the table. The user is the replacement for
  Carbon's proposal/review committee in this fork.

## The six steps, adapted

### 1. Arbiter — the 0.1 conformance suite (`fork/conformance/`)

An executable definition of "done" for 0.1:

- One or more **compile-and-run** Carbon programs per milestone bullet
  (not just check tests): expected exit codes / output.
- **Interop programs** pairing real C++ (built with Clang) with Carbon in
  both directions.
- A **grader script** that runs the whole suite and emits a scoreboard:
  `bullet → PASS / FAIL / NOT-WRITTEN`. The scoreboard percentage *is*
  the project's progress number. No feature is "done" by assertion — only
  by scoreboard.
- Built on the toolchain's existing `file_test` / testdata machinery where
  possible so tests double as upstream-style regression tests.

The suite is written *before or with* each feature, never after. This is
the direct answer to the "arbiter is only as good as its coverage"
criticism: growing the arbiter is a first-class workstream, permanently.

### 2. Rulebook

Already mostly exists — this is Carbon's superpower for an AI-driven push:

- `docs/design/**` — the language design (the spec to implement).
- `proposals/**` — accepted design decisions with rationale.
- Toolchain conventions: `toolchain/docs/**`, `CONTRIBUTING.md`, style
  docs, SemIR documentation.
- Fork-local additions: `fork/rulebook.md` (created during the trial run)
  collects process rules the way the migration rulebook did — e.g. "every
  new SemIR inst kind needs a formatter test", "diagnostics need
  `CARBON_DIAGNOSTIC` naming pattern X". When an adversarial reviewer
  catches the same class of mistake twice, it becomes a rule here, and
  affected work is regenerated, not hand-patched.

### 3. Dependency map

From the gap analysis (`gap-analysis.md`): workstreams ordered so nothing
builds on a missing foundation. Maintained as the ordering of the
workstream list; re-derived whenever the scoreboard changes shape.

### 4. Gap list = design forks

The inventory of milestone bullets where `docs/design/` is placeholder,
contradictory, or silent — the places mechanical implementation can't
proceed and human judgment is required. Each becomes a decision-log entry:
options researched by agents (including what upstream leans toward, what
C++ interop requires), presented to the user, decided, then implemented.

### 5. Trial run

Before scaling any feature workstream: run the full loop end-to-end on one
small, representative bullet — design check → conformance tests written →
implement → adversarial review → scoreboard flips to PASS → land. The
trial validates the harness (build, test runner, review loop, worktree
discipline) and seeds `rulebook.md`.

### 6. Scaled loop

Per workstream, the Bun-style loop, sized to this environment:

```
work item (failing conformance test or milestone bullet)
  → implementer agent (worktree, design docs in context)
  → 2 adversarial reviewers (fresh context; must cite the design doc,
    proposal, or rulebook rule behind every finding; prompted to refute)
  → fixer agent applies surviving findings
  → arbiter: full test suite + conformance scoreboard
  → green: commit to fork branch; red: loop with saved failure output
```

Compute realism: this container has 4 cores / 15 GB / ~30 GB disk — not
64 concurrent Claudes with 16-way test sharding. Concurrency comes from
*agent* parallelism (many readers/writers), while *build/test*
parallelism is serialized. Long grinds run as background workflows across
sessions; anything durable is committed and pushed before a session ends.

## Quantized state (the Bun-style machine-readable artifacts)

The Zig→Rust port worked because its state lived in machine-readable
artifacts every agent read and updated — a rulebook plus an inventory of
every struct/function to port. This fork's equivalents, all in-repo:

1. **`fork/conformance/out/scoreboard.json`** — behavioral truth: every
   milestone bullet → PASS/FAIL/SKIP with program-level detail.
2. **`fork/inventory/work-items.json`** — the work inventory: every known
   concrete gap (TODO stub, fail_todo test, missing feature slice,
   undesigned area) as a structured item with file:line evidence, owning
   bullet, and dependency edges. Agents claim items from here, never from
   vibes; discovering un-inventoried work means *adding the item first*.
3. **`fork/rulebook.md`** — process rules + toolchain traps, grown from
   repeated review findings; loaded by every producer/reviewer agent.
4. **`fork/decision-log.md`** — design authority between upstream
   proposals and implementation.

Every workstream loop starts by reading (1)+(2) and ends by updating them.

## Human-in-the-loop rule

Every design fork presented to the user comes with a curated reading list
(`fork/design-sprint/reading-list.md` format): in-repo sources first,
minimal external material second, and the one load-bearing concept named
explicitly — so the decider is always equipped to overrule the
recommendation.

**Sub-forks are forks.** Every design sub-decision — naming, syntax
spelling, default flag values, anything with more than one defensible
answer — goes to the user via AskUserQuestion, no matter how mundane
(user directive, 2026-07-19). Agents drafting design docs mark such
points as OPEN with a recommendation; they never silently decide. The
orchestrator batches accumulated sub-forks into AskUserQuestion rounds
and records outcomes here before the affected work merges.

**Never re-ask a decided fork.** Before any AskUserQuestion round, the
orchestrator checks `fork/decision-log.md` for already-decided IDs; a
decided fork is only re-opened with genuinely new information, and the
question must say so explicitly. (Tool-delivery failures are retried, but
a retry states that it is a retry.) One branch owns one scope: before
launching parallel workstreams, the orchestrator verifies their touched
paths are disjoint and records the scope map in ORCHESTRATION.md.

## North-star guard (against optimizing for our own tests)

The scoreboard is this fork's progress meter, but the goal is Google's
stated goal for Carbon: a performance-critical successor language with
seamless, incremental C++ interop (`docs/project/goals.md` — the
constitution). Tests we wrote can drift from that goal; three guards keep
them honest:

1. **Differential arbitration**: wherever possible, expected behavior is
   pinned by an independent implementation (paired C++ programs must
   produce byte-identical output), not by values the implementing agent
   chose.
2. **Evaluator simulation** (recurring workstream, after each major
   merge): a fresh-context agent acts as a skeptical C++ developer
   evaluating Carbon per the milestone's own goals — ports a small
   real-world C++ snippet using only the installed toolchain and public
   docs, no fork-internal knowledge. Friction, wrong results, and
   misleading diagnostics become inventory items regardless of what the
   scoreboard says. The scoreboard measures what we encoded; evaluator
   simulation measures what we forgot to encode.
3. **Rulebook R16/R17**: the anti-Goodhart prohibitions (goldens only via
   autoupdate, no test weakening, no special-casing, independently
   derivable expectations) and the convoluted-justification defect signal.

## Standing rules

1. **Trunk stays green.** The fork branch must always build and pass the
   pre-existing toolchain test suite. Feature work happens in worktrees /
   child branches and lands only when green.
2. **Scoreboard tells the truth.** Progress reports quote the conformance
   scoreboard, never vibes.
3. **Reviewers cite rules.** An adversarial finding without a design-doc /
   proposal / rulebook citation is itself a finding (either a missing rule
   or a spurious objection).
4. **Fix the loop, not the file.** Repeated mistake class → rulebook rule
   → regenerate.
5. **Upstream is a moving asset.** Upstream lands features weekly; before
   starting any workstream, check whether upstream has active work there
   (avoid burning tokens re-implementing what will arrive in a merge).
6. **User decides design forks; Claude decides everything else.**
