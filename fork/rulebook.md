# Rulebook

Fork-local process rules, in the migration-framework sense: when an
adversarial reviewer catches the same class of mistake twice, the fix is a
rule here — and affected work is regenerated against the rule, never
hand-patched around it. Every rule cites the incident that created it.
Agents doing implementation, review, or conformance work MUST load this
file into context.

## Toolchain facts (traps that cost an agent a loop)

- **R1. `Core.PrintStr` does not link under `compile`+`link`.** Its body
  lives in `core/io.impl.carbon`, linked only by `carbon build` or bazel
  `carbon_binary`. Use `Core.Print` / `Core.PrintChar` (inline
  printf/putchar) or `Cpp.std.cout` in conformance programs.
  (Origin: harness construction, 2026-07-19.)
- **R2. Default compile includes Core as extra compilation units.** Pass
  `--output-last-input-only`; do not copy `--no-include-carbon-core` from
  `install_test.py` without understanding it — verify flags against
  `toolchain/driver/compile_driver.cpp` defaults.
  (Origin: harness construction.)
- **R3. Derive syntax from working code** (`examples/advent2024/`,
  `toolchain/*/testdata/`, existing conformance programs), never from
  design docs alone — large parts of the documented design are
  unimplemented. (Origin: harness construction; reaffirmed by the 26-bullet
  growth run.)
- **R4. First `carbon link` on a fresh machine builds runtimes on demand**
  (minutes); use generous link timeouts in harnesses.
  (Origin: harness construction.)

## Process rules

- **R5. Parallel runner invocations must use private `--out` dirs.**
  Shared out dirs clobber scoreboards. (Origin: conformance-growth
  workflow design.)
- **R6. Code sketches inside SKIP programs must be compile-verified before
  commit.** A "ready-to-port" sketch that doesn't compile is a landmine
  for the un-skipping agent. (Origin: reviewer caught a missing
  `import Core library "io"` in `library_multifile_export.carbon`'s
  sketch, conformance-growth run.)
- **R7. `CONFORMANCE-BULLET` text must match the gap-analysis table
  character-for-character** — enforced by `runner.py --self-test`; run it
  before every commit that touches programs. (Origin: harness design.)
- **R8. Reviewer findings must cite the rule, design doc, proposal, or
  repo file behind them.** A finding with no citation is itself a finding.
  (Origin: fork/process.md standing rule 3.)
- **R9. A feature/bullet is "done" only when the scoreboard says PASS.**
  Progress reports quote `scoreboard.json`, never assertions.
  (Origin: fork/process.md standing rule 2.)
- **R10. SKIP reasons must state the exact blocking evidence** (compiler
  error text, missing-symbol name, or file:line of the stub) so un-skipping
  is mechanical when the blocker lands. (Origin: conformance-growth run.)
- **R18. Format-check changed C++ with the CI-pinned clang-format** (the
  `==` version in `.pre-commit-config.yaml`, currently 21.1.8) before
  commit. Distro clang-format disagrees with CI on files CI considers
  green — never use it as the arbiter. (Origin: W4 slice-1 adversarial
  review confirmed a violation invisible to local clang-format 18,
  2026-07-19.)
- **R19 (companion to R15). New or changed AUTOUPDATE goldens without regenerated CHECK lines
  fail `bazel test`.** When goldens cannot be autoupdated locally (no local
  build), the land sequence must run
  `bazel run //toolchain/testing:file_test -- --autoupdate ...` on the
  runner and commit the reconciliation *before* the merge gate is judged —
  a red first CI on empty goldens is expected, not a semantics failure.
  (Origin: W4 slice-1 adversarial review; fork/trial-w4/plan.md risk 1.)

## Adversarial-review protocol (applies at EVERY production step)

Every artifact class gets independent, fresh-context adversarial review
before it lands — separate agents with different objectives, per the Bun
loop (1 implementer, 2 reviewers, 1 fixer):

| Artifact | Producer | Adversary #1 (correctness) | Adversary #2 (strictness) | Gate |
| --- | --- | --- | --- | --- |
| Conformance program | writer agent | "prove the test is vacuous / wrong" | "prove the SKIP hides working behavior; check citations" | runner PASS + `--self-test` |
| Design doc / option paper | drafter agent | "find contradictions with accepted proposals + sibling designs" | "find interop / implementation-cost errors against the actual toolchain" | user decision at the fork |
| Compiler change | implementer agent | "find the input that breaks this; write the failing test" | "find the rule/style/SemIR-invariant violation; cite it" | `bazel test //toolchain/...` green + scoreboard non-regression |
| Inventory / audit data | scanner agent | random-sample verifier: "open N cited locations; confirm each exists and means what the item claims" | — | sample error rate 0 |

Review verdicts are structured (OK / NEEDS-FIX + cited findings); a fixer
agent applies surviving findings; repeated finding classes become rules
here.

- **R11. The fixer is its own agent.** Every loop iteration uses four
  distinct, fresh context windows: 1 implementer → 2 adversarial
  reviewers → 1 fixer, per the Bun rewrite's loop. The fixer is never the
  implementer continuing in its own context (it would inherit the
  implementer's blind spots) and never a reviewer (it would grade its own
  homework). Workflow scripts must invoke the fixer as a separate
  `agent()` call that receives the findings as data. (Origin: user
  directive, 2026-07-19; matches the Bun per-failing-test loop of
  1 implementer + 2 adversarial reviewers + 1 fixer.)

## Deterministic invariant layer (hooks)

- **R12. Mechanical invariants are enforced by PostToolUse hooks, not
  reviewers.** `.claude/settings.json` + `.claude/hooks/post_edit_invariants.sh`
  run on every Edit/Write by every agent: clang-format 21.1.8 (the exact
  CI pin) with re-read feedback on reformat, header-guard check for .h
  (CI's own script), license-header presence in upstream dirs, conformance
  `--self-test` on program edits, JSON parse, Python compile, trailing
  newline. Adversarial reviewers must NOT spend findings on anything this
  layer catches — their attention belongs to semantics, invariants the
  hook cannot check, and design conformance. When a reviewer catches a new
  *mechanical* class of error, the fix is extending the hook script, then
  a rulebook entry. (Origin: user directive after reviewer 2 burned a
  finding on clang-format, 2026-07-19.)
- **R13. Workflow YAML: never let commit-message text sit at column 0
  inside a `run: |` block** — it terminates the block scalar and becomes
  a stray top-level key that Actions rejects with a jobless failed run;
  use multiple `-m` flags instead. Python yaml.safe_load does NOT catch
  this (it happily parses the stray key) — validate root keys, not just
  parseability. (Origin: trial run, fork_autoupdate.yaml failure
  29696011228.)
- **R14. A run 'queued' >10 min while no other run is in_progress means
  the self-hosted runner is offline** — tell the user to restart it
  (`./run.sh`, or `svc.sh install` for persistence) instead of waiting;
  queued work survives and starts automatically on reconnect. (Origin:
  trial run, ~3.5h stall 2026-07-19.)
- **R15. New compiler features land with runner-side golden autoupdate:**
  push testdata with AUTOUPDATE markers and empty CHECK lines, fire the
  autoupdate workflow, let it commit the reconciliation back — never
  hand-author SemIR goldens. A green autoupdate run doubles as
  compile-validation of the feature code. (Origin: trial run.)

## Anti-Goodhart protocol (the tests serve the goal, never the reverse)

- **R16. Passing tests is necessary, never sufficient — and gaming them
  is the cardinal sin.** Concretely prohibited: (a) hand-editing golden
  CHECK lines in `toolchain/**/testdata/**` — goldens change ONLY via the
  runner-side autoupdate workflow (R15), so semantic drift is always a
  reviewed diff from a real compiler run, never an agent's assertion;
  (b) weakening, deleting, or SKIP-ing an existing test to make a run
  green — a SKIP added to a previously-passing program is presumed
  cheating until its reason cites a design/toolchain change that
  legitimately regressed it; (c) special-casing recognizable test inputs
  in compiler code (matching on test file names, magic constants from
  testdata); (d) deriving EXPECT values by running the implementation
  under test — expected outputs come from the design doc, from C++
  differential pairs, or from independent reasoning, and the reviewer
  must be able to re-derive them. Adversary #2's brief now includes an
  explicit Goodhart check: diff the goldens for weakened assertions,
  grep the implementation diff for input-specific special cases, and
  verify no test was deleted or skipped to force green.
  (Origin: user directive, 2026-07-19; Kelley critique of the Bun
  rewrite — "the arbiter is only as good as its coverage".)
- **R17. A convoluted justification is itself a defect signal.** Per the
  Bun rewrite's lesson: when an implementer, fixer, or rebuttal needs a
  long, winding explanation for why surprising code is actually fine —
  "this looks wrong but works because..." — the presumption is that the
  code is wrong and must be simplified or fixed. Reviewers treat
  multi-paragraph workaround rationales as findings in their own right:
  the burden is a one-sentence justification citing a design doc,
  proposal, or rulebook rule. Dispositions that rebut findings must cite
  evidence, not narrative. (Origin: user directive, 2026-07-19.)
- **R20. One committer per worktree.** Concurrent agents must not share a
  worktree when either will commit; the orchestrator never uses
  `git add -A` on a tree an agent is working in — explicit paths only.
  (Origin: commit 837bb60 accidentally swept the differential-harness
  agent's 12 staged files into the anti-Goodhart commit, 2026-07-19.)

## Gate parity (the root-cause fix from PR #1)

- **R21. The merge gate must be a superset of the destination's real
  acceptance gate.** PR #1 built and tested green on upstream's hosted CI
  across every platform, but failed `prek` and `clangd-tidy` — because our
  `fork_build_toolchain.yaml` gated only on `bazel test //toolchain/...`,
  a strict SUBSET of upstream's `tests.yaml` (prek + clangd-tidy +
  Default/Opt/ASan × 4 platforms). Every "green, gated merge" this session
  was green against a bar we authored, narrower than the project's — the
  Goodhart failure the north-star guard warns about, realized. Fix: the
  fork gate now runs upstream's OWN prek and clangd-tidy steps. Rule: when
  a workstream targets a destination with its own CI, the gate mirrors
  that CI or explicitly enumerates and justifies each omission; you never
  invent a reduced gate and call its green "mergeable." (Origin: PR #1
  prek/clangd-tidy failures, 2026-07-20.)
- **R22. Run the real gate; never re-approximate it.** The R12 hook was a
  hand-rolled subset of prek (clang-format + some prettier). A
  reimplemented gate drifts from the real config, and it only armed from
  its creation session — so every file written earlier (the audit,
  inventory, and early docs that ruff/prettier flagged in PR #1) bypassed
  it entirely. The hook stays as fast per-edit feedback, but the AUTHORITY
  is `prek run` (upstream's actual tool) on changed files, run in the loop
  before push — not a bespoke approximation. When feasible, run
  `prek run --files <changed>` locally; where the sandbox lacks prek, the
  runner-side R21 gate is the backstop. (Origin: PR #1, 2026-07-20.)
