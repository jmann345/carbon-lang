# Rulebook

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Fork-local process rules, in the migration-framework sense: when an
adversarial reviewer catches the same class of mistake twice, the fix is a
rule here — and affected work is regenerated against the rule, never
hand-patched around it. Every rule cites the incident that created it.
Agents doing implementation, review, or conformance work MUST load this
file into context.

## Toolchain facts (traps that cost an agent a loop)

-   **R1. `Core.PrintStr` does not link under `compile`+`link`.** Its body
    lives in `core/io.impl.carbon`, linked only by `carbon build` or bazel
    `carbon_binary`. Use `Core.Print` / `Core.PrintChar` (inline
    printf/putchar) or `Cpp.std.cout` in conformance programs.
    (Origin: harness construction, 2026-07-19.)
-   **R2. Default compile includes Core as extra compilation units.** Pass
    `--output-last-input-only`; do not copy `--no-include-carbon-core` from
    `install_test.py` without understanding it — verify flags against
    `toolchain/driver/compile_driver.cpp` defaults.
    (Origin: harness construction.)
-   **R3. Derive syntax from working code** (`examples/advent2024/`,
    `toolchain/*/testdata/`, existing conformance programs), never from
    design docs alone — large parts of the documented design are
    unimplemented. (Origin: harness construction; reaffirmed by the 26-bullet
    growth run.)
-   **R4. First `carbon link` on a fresh machine builds runtimes on demand**
    (minutes); use generous link timeouts in harnesses.
    (Origin: harness construction.)

## Process rules

-   **R5. Parallel runner invocations must use private `--out` dirs.**
    Shared out dirs clobber scoreboards. (Origin: conformance-growth
    workflow design.)
-   **R6. Code sketches inside SKIP programs must be compile-verified before
    commit.** A "ready-to-port" sketch that doesn't compile is a landmine
    for the un-skipping agent. (Origin: reviewer caught a missing
    `import Core library "io"` in `library_multifile_export.carbon`'s
    sketch, conformance-growth run. Second occurrence: F8a's
    `cpp_thread_carbon_fn_diff.carbon` sketch carried a declare-before-use
    error — `Work` preceded `RuntimeSeed` — found only at the F8d un-SKIP,
    2026-08-18. Response: commented-out future bodies in conformance
    sketches must be arbiter-parse-checked where a toolchain for them
    exists, and the un-SKIP commit must disclose any mechanical repair it
    made — the F8d handling, one recorded reorder in the commit message and
    decision log, is the template.)
-   **R7. `CONFORMANCE-BULLET` text must match the gap-analysis table
    character-for-character** — enforced by `runner.py --self-test`; run it
    before every commit that touches programs. (Origin: harness design.)
-   **R8. Reviewer findings must cite the rule, design doc, proposal, or
    repository file behind them.** A finding with no citation is itself a
    finding. (Origin: fork/process.md standing rule 3.)
-   **R9. A feature/bullet is "done" only when the scoreboard says PASS.**
    Progress reports quote `scoreboard.json`, never assertions.
    (Origin: fork/process.md standing rule 2.)
-   **R10. SKIP reasons must state the exact blocking evidence** (compiler
    error text, missing-symbol name, or file:line of the stub) so un-skipping
    is mechanical when the blocker lands. (Origin: conformance-growth run.)
-   **R18. Format-check changed C++ with the CI-pinned clang-format** (the
    `==` version in `.pre-commit-config.yaml`, currently 21.1.8) before
    commit. Distro clang-format disagrees with CI on files CI considers
    green — never use it as the arbiter. (Origin: W4 slice-1 adversarial
    review confirmed a violation invisible to local clang-format 18,
    2026-07-19.)
-   **R19 (companion to R15). New or changed AUTOUPDATE goldens without
    regenerated CHECK lines fail `bazel test`.** When goldens cannot be
    autoupdated locally (no local build), the land sequence must run `bazel run
    //toolchain/testing:file_test -- --autoupdate ...` on the runner and commit
    the reconciliation _before_ the merge gate is judged — a red first CI on
    empty goldens is expected, not a semantics failure. (Origin: W4 slice-1
    adversarial review; fork/trial-w4/plan.md risk 1.)
-   **R27. Testdata or conformance code implementing a design-doc sketch
    must be DIFFED against the sketch's exact spelling before landing —
    declaration modifiers included.** Semantic review of impl bodies is
    not a spelling diff. (Origin: W-072 — the doc's `Try` impl sketches
    carried `final` from the original F-006 commit 9fdad04; the B1b
    testdata idiom (6b0b80e) dropped it, and the third-round correction
    3099532 edited the very lines carrying `final` without noticing the
    modifier; the omission survived every review because testdata was
    checked against the doc's semantics, never diffed against the
    sketch's spelling.) R6 (compile-verified sketches) points the other
    direction — doc/sketch → compiling code; R27 covers code → sketch
    spelling fidelity — so this is a new rule, not an R6 extension.

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

-   **R11. The fixer is its own agent.** Every loop iteration uses four
    distinct, fresh context windows: 1 implementer → 2 adversarial
    reviewers → 1 fixer, per the Bun rewrite's loop. The fixer is never the
    implementer continuing in its own context (it would inherit the
    implementer's blind spots) and never a reviewer (it would grade its own
    homework). Workflow scripts must invoke the fixer as a separate
    `agent()` call that receives the findings as data. (Origin: user
    directive, 2026-07-19; matches the Bun per-failing-test loop of
    1 implementer + 2 adversarial reviewers + 1 fixer.)

## Deterministic invariant layer (hooks)

-   **R12. Mechanical invariants are enforced by PostToolUse hooks, not
    reviewers.** `.claude/settings.json` +
    `.claude/hooks/post_edit_invariants.sh` run on every Edit/Write by every
    agent: clang-format 21.1.8 (the exact CI pin) with re-read feedback on
    reformat, header-guard check for .h (CI's own script), license-header
    presence in upstream dirs, conformance `--self-test` on program edits, JSON
    parse, Python compile, trailing newline. Adversarial reviewers must NOT
    spend findings on anything this layer catches — their attention belongs to
    semantics, invariants the hook cannot check, and design conformance. When a
    reviewer catches a new _mechanical_ class of error, the fix is extending the
    hook script, then a rulebook entry. (Origin: user directive after reviewer 2
    burned a finding on clang-format, 2026-07-19.)
-   **R13. Workflow YAML: never let commit-message text sit at column 0
    inside a `run: |` block** — it terminates the block scalar and becomes
    a stray top-level key that Actions rejects with a jobless failed run;
    use multiple `-m` flags instead. Python yaml.safe_load does NOT catch
    this (it happily parses the stray key) — validate root keys, not just
    parseability. (Origin: trial run, fork_autoupdate.yaml failure
    29696011228.)
-   **R14. A run 'queued' >10 min while no other run is in_progress means
    the self-hosted runner is offline** — tell the user to restart it
    (`./run.sh`, or `svc.sh install` for persistence) instead of waiting;
    queued work survives and starts automatically on reconnect. (Origin:
    trial run, ~3.5h stall 2026-07-19.)
-   **R15. New compiler features land with runner-side golden autoupdate:**
    push testdata with AUTOUPDATE markers and empty CHECK lines, fire the
    autoupdate workflow, let it commit the reconciliation back — never
    hand-author SemIR goldens. A green autoupdate run doubles as
    compile-validation of the feature code. (Origin: trial run.)

## Anti-Goodhart protocol (the tests serve the goal, never the reverse)

-   **R16. Passing tests is necessary, never sufficient — and gaming them is the
    cardinal sin.** Concretely prohibited: (a) hand-editing golden CHECK lines
    in `toolchain/**/testdata/**` — goldens change ONLY by way of the
    runner-side autoupdate workflow (R15), so semantic drift is always a
    reviewed diff from a real compiler run, never an agent's assertion; (b)
    weakening, deleting, or SKIP-ing an existing test to make a run green — a
    SKIP added to a previously-passing program is presumed cheating until its
    reason cites a design/toolchain change that legitimately regressed it; (c)
    special-casing recognizable test inputs in compiler code (matching on test
    file names, magic constants from testdata); (d) deriving EXPECT values by
    running the implementation under test — expected outputs come from the
    design doc, from C++ differential pairs, or from independent reasoning, and
    the reviewer must be able to re-derive them. Adversary #2's brief now
    includes an explicit Goodhart check: diff the goldens for weakened
    assertions, grep the implementation diff for input-specific special cases,
    and verify no test was deleted or skipped to force green. (Origin: user
    directive, 2026-07-19; Kelley critique of the Bun rewrite — "the arbiter is
    only as good as its coverage".)
-   **R17. A convoluted justification is itself a defect signal.** Per the
    Bun rewrite's lesson: when an implementer, fixer, or rebuttal needs a
    long, winding explanation for why surprising code is actually fine —
    "this looks wrong but works because..." — the presumption is that the
    code is wrong and must be simplified or fixed. Reviewers treat
    multi-paragraph workaround rationales as findings in their own right:
    the burden is a one-sentence justification citing a design doc,
    proposal, or rulebook rule. Dispositions that rebut findings must cite
    evidence, not narrative. (Origin: user directive, 2026-07-19.)
-   **R20. One committer per worktree.** Concurrent agents must not share a
    worktree when either will commit; the orchestrator never uses
    `git add -A` on a tree an agent is working in — explicit paths only.
    (Origin: commit 837bb60 accidentally swept the differential-harness
    agent's 12 staged files into the anti-Goodhart commit, 2026-07-19.)

## Gate parity (the root-cause fix from PR #1)

-   **R21. The merge gate must be a superset of the destination's real
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
-   **R22. Run the real gate; never re-approximate it.** The R12 hook was a
    hand-rolled subset of prek (clang-format + some prettier). A
    reimplemented gate drifts from the real config, and it only armed from
    its creation session — so every file written earlier (the audit,
    inventory, and early docs that ruff/prettier flagged in PR #1) bypassed
    it entirely. The hook stays as fast per-edit feedback, but the AUTHORITY
    is `prek run` (upstream's actual tool) on changed files, run in the loop
    before push — not a bespoke approximation. When feasible, run
    `prek run --files <changed>` locally; where the sandbox lacks prek, the
    runner-side R21 gate is the backstop. (Origin: PR #1, 2026-07-20.)
-   **R23. The invariant hook covers `fork/` too, and the CI prek gate is the
    authority.** PR #1's lint failures were files under `fork/` — license
    headers, ruff-format, codespell — that escaped because R12's hook only
    policed `toolchain/core/common/testing/scripts`. The hook now enforces
    the license header on `fork/` source files (excluding JSON data files,
    which `json.load` can't parse with a comment header, and `*-request.txt`)
    and runs ruff on Python. The hook is the fast local prevention layer; the
    runner-side prek in the merge gate (R21) remains the authority — the hook
    is best-effort, not a reimplementation of prek. (Origin: PR #1, 2026-07-20.)
-   **R24. Differential `.diff.cpp` oracles are excluded from clangd-tidy.**
    They are standalone C++ programs compiled at runtime by the conformance
    runner with the Carbon toolchain's clang++, not bazel targets, so they
    have no compile_commands entry — clangd-tidy fails to resolve their
    standard-library includes. Excluded in clangd_tidy.yaml's paths-filter,
    same category as the existing `!**/*.tpl.h`. (Origin: PR #1 clangd-tidy
    failures on the differential fixtures, 2026-07-20.)
-   **R25. Run `uvx prek run --all-files` locally before every push to a
    PR branch; never modify committed files by way of shell append.** The R23
    Edit/Write hook does not fire on `cat >>`/`sed -i`, and it does not run
    rumdl/markdown checks at all — so a shell-appended rulebook entry
    reached CI with a rumdl violation, costing a runner round-trip. The
    discipline: edit by way of Edit/Write (hook fires) and run the real prek
    locally before pushing (it is fast and needs no build), so the R21 CI
    gate is a backstop, not the first detector. (Origin: PR #1, my `cat >>`
    to `rulebook.md` bypassed the hook, 2026-07-20.)
-   **R26. Golden autoupdate runs to fixpoint — expect two passes when a change
    adds output lines.** file_test's SemIR names embed source line numbers
    (`%x.locNN`). When a compiler change adds output lines (for example B0's
    thunk decls in the `imports` block), autoupdate pass 1 inserts the new CHECK
    lines, which shifts the source lines below them — so the `locNN` values it
    wrote (computed from the pre-shift compile) are stale by exactly the shift,
    and the test stays red with "Autoupdate would make changes". Pass 2
    converges: renumbering `locNN` does not change the CHECK line count.
    Discipline: after an autoupdate that touches files whose diff adds/removes
    CHECK lines above source code, fire a second pass and verify it is
    loc-number-only before gating; a pass-2 diff with structural changes means
    real nondeterminism — stop and diagnose instead of looping. This red-loop is
    what stranded the original b0 branch. (Origin: b0 reconstruction runs 19-22,
    2026-07-27.) Superseded in part by R28: the fixpoint is now proven by the
    gate's file_test pass, not by a separate second autoupdate pass.
-   **R28. The self-hosted runner is the fork owner's own machine — the
    agent does not use it. Only the owner dispatches runs on it.** On
    2026-09-26 the owner said, twice: "You no longer have permission to use
    my computer for this project, but you must still finish it. You can test
    your work more sparingly. [...] Figure out another way. You're no longer
    squatting in there." Discipline: (a) all four self-hosted workflows
    (autoupdate, gate, conformance, fast check) are `workflow_dispatch`
    ONLY — no push trigger, no request-file bump; the agent never dispatches
    them and never asks for a run on a schedule; (b) verification the agent
    runs itself lives on GitHub-hosted runners (`Fork: hosted verification`,
    fork_hosted.yaml — modes compile/autoupdate/gate/conformance; upstream's
    public remote cache read-only; the first compile probe took 18 minutes
    end to end, run 36230850086), backed by fresh-context reviews with
    precise hand-traced golden predictions; (c) goldens still come only from
    autoupdate (R16 stands — hand-written goldens are the cheating the owner
    also forbade), so a workstream whose goldens are unfilled is parked as an
    OPEN PR labelled "awaiting owner-dispatched autoupdate + gate +
    conformance", with the exact dispatch list in fork/ORCHESTRATION.md;
    trunk receives only verified merges; (d) R26's fixpoint rule is proven by
    the gate's file_test pass whenever the owner does dispatch. (Origin:
    owner directive, 2026-09-26, mid-W-077; superseding the same-day
    "rationed use" draft after one accidental fire on a merge push, cancelled
    within a minute.)
-   **R29. Throughput rules (owner directive 2026-09-27: "work more
    efficiently", "finish everything without making mistakes", "no more
    questions").** (a) Autonomy: no AskUserQuestion; every fork decision
    auto-adopts the design recommendation under V-2/V-3 and is recorded in
    the decision log for after-the-fact veto. (b) Slice size: one PR per
    milestone feature, not per diagnostic or sub-shape. (c) Review budget by
    evidence: plan reviews stay TWO (they have caught a blocker in nearly
    every round); implementation reviews drop to ONE once hosted
    verification (autoupdate fixpoint + gate + conformance) is fully green
    — across W-078a/W-078b/W-077 the second implementation review produced
    only comment nits. (d) Pipelining: the next workstream's planner starts
    while the current one is in review or verification; hosted autoupdate
    runs concurrently with reviews (a refill after a fix is free). (e) Kill
    detection: a review agent whose output is silent for over an hour is
    dead — relaunch, do not wait. (Origin: owner directives, 2026-09-27.)
-   **R30. Bidirectional assertions: a conformance program that pins a
    documented divergence between Carbon and C++ semantics asserts BOTH
    sides' results in one program, and never carries a `.diff.cpp` oracle
    that would make the two agree.** An exported Carbon `overload fn` set is
    resolved by Carbon callers by declaration-order first-match and by C++
    callers under C++'s best-viable-match rules (fork decision F-009), so the
    same argument can select a different member on each side, or be rejected
    by C++ where Carbon accepts it. That divergence is a documented property,
    and a property is pinned by asserting it, not by averaging it away: the
    program prints the Carbon-side selection and the C++-side selection (or
    the C++-side rejection goes in a `fail_` golden) as separate EXPECT lines,
    hand-derived from each side's own rules, and the header states the rule
    that makes them differ. A `.diff.cpp` differential oracle is the wrong
    instrument here by construction — it asserts that a C++ program and the
    Carbon program agree, so it can only pass by hiding the divergence or
    by not exercising it — and the agreeing direction needs no oracle either,
    because its C++ side is already the oracle for its own lines. Discipline:
    (a) every program that exercises an exported overload set asserts both
    directions, the agreeing case and the diverging case in sibling programs
    with cross-referencing headers; (b) no `.diff.cpp` sibling for either; (c)
    a change that makes the diverging program's two sides agree is a design
    change to F-009, recorded in the decision log before the EXPECT moves,
    never a test fix. Precedent:
    fork/conformance/programs/interop/cpp_export_overload_set_divergence.carbon
    (Carbon 1, C++ 2) beside cpp_export_overload_set.carbon (1 2 2 1).
    (Origin: the rule the overloading paper proposed and fork/overload/plan.md
    §5.C.2 asked OV-3 to allocate at discharge under the next free number;
    OV-3 discharge, 2026-10-05.)
-   **R31. Never let a `#NNNN` reference, a list-marker character or a cron
    field start a markdown line — at column 0 or at list-continuation indent;
    verify heading counts per level AND list-item counts before and after any
    reflow.** The wrapping is not token-neutral: rumdl's MD013 reflow
    (upstream's `.rumdl.toml`, `[MD013] reflow = true`, applied by the
    pre-commit `rumdl` hook, which .pre-commit-config.yaml runs twice) breaks
    prose at spaces — inside code spans too — and the hook's second pass then
    "fixes" what landed at a line start: a column-0 paragraph line beginning
    with `#7784, #7813 …` trips MD018 ("No space after # in heading") and
    becomes an H2, after which every following heading in the file is one level
    deeper; a line beginning with a cron tail (asterisk, space, asterisk, space,
    digit) trips MD004/MD069 and becomes a list item that swallows the rest of
    the sentence. The damage is silent (prek exits green) and cumulative (each
    reflow can add a heading or an item). Probe nuance (2026-10-05, re-probed
    with rumdl 0.2.78 under upstream's config, two `--fix` passes): a
    continuation line indented under a list item is NOT parsed as a heading — an
    indented line beginning with `#7784, #7813` stays text — but an indented
    continuation beginning with a plus sign, an asterisk, a dash, or a digit and
    a period DOES become a nested list item (the cron tail became a nested item
    reading "1 and the rest of the sentence"). So only `#` is safe when
    indented; the hazard set is `#`, `*`, `+`, `-` and `N.` at the start of ANY
    line. Attribution (corrected 2026-10-05): the prek `prettier` hook is
    `types_or: [html, javascript, json, yaml]` and the R12 hook runs prettier on
    `*.json|*.yaml` only and no rumdl — neither touches markdown; the
    manufactured headings came from hand-wrapped text plus the rumdl hook's
    MD018/MD004 fixes (the fork's `.rumdl.toml` has MD013 off but
    MD018/MD004/MD069 on), and a reflow commit's wrapping comes from upstream's
    `.rumdl.toml` through that same hook. Discipline: (a) in paragraphs, write
    PR and issue references so no wrap can put `#` first — as bare numbers in
    dense lists ("PRs 7784, 7813") or attached to the preceding word — and spell
    cron schedules out in words ("the three trailing cron fields", "weekly,
    Mondays 14:00 UTC") or put them in a fenced block, never in a prose code
    span; (b) before and after any commit that reflows markdown (a lint-config
    change, a `--all-files` prek run, a rumdl version bump), record per-file
    heading counts per level (`grep -c '^## '`, `'^### '`, …) and list-item
    counts INCLUDING indented items (`grep -cE '^\s*-   '`, `grep -cE
    '^\s*[0-9]+\. '`) and diff them — a changed count is a manufactured heading
    or list item to repair by rephrasing, never by reverting the whole file's
    reflow; (c) grep the diff for new lines matching `^\+\s*#{1,6}
    [0-9]|^\+#[0-9]` — manufactured headings, and the latent form: an
    un-converted column-0 `#NNNN` that the next reflow would convert; list
    manufacture is detected by the count diff in (b) alone, because a grep for
    added dash-marker lines matches every re-wrapped first line of an existing
    item (146 hits, 1 real, on the measured copy). The R12 hook does not catch
    this class (it runs no heading-structure check), so the count diff is the
    detector. (d) A second non-neutral hook: check-google-doc-style substitutes
    words inside code spans and fenced blocks alike (Google's word list: the
    Latin abbreviations, the three-letter synonym of "by way of", the short
    forms of "repository" — the GitHub REST path segment included), honoring
    only its column-0 `<!-- google-doc-style-ignore -->` / `<!--
    google-doc-style-resume -->` line pairs; a command or quoted output whose
    literal text contains such a word is written between that pair (precedent
    fork/w078b/plan.md:31), and a fold that "reproduces" a command re-runs it
    from the committed text, after prek — the upstream-advance plan's `gh api`
    path was rewritten into the refused form in rev 1, rev 2 and the rev 3 draft
    before this was noticed. (Origin: upstream-advance plan review, rev B B3,
    2026-10-05 — the fork's rumdl hook had already turned two PR lists in
    fork/upstream/plan.md §0.2 into headings reading "7784, #7813, …" and "7689,
    #7700, …" and the weekly Routine's cron schedule (Mondays 14:00 UTC) into a
    list item, the decision log carries a heading reading "7741
    template-dependent assignment, …" at :5562 from the same mechanism, and a
    reflow experiment under upstream's `.rumdl.toml` re-levelled every H3 of
    fork/ORCHESTRATION.md to H4 behind a manufactured "12/#13/#14: S3a …"
    heading; second occurrence of the class after the R25 rumdl miss, so a rule.
    Scope, probe nuance and attribution corrected by the rev-3 re-review of that
    plan, 2026-10-05.)
