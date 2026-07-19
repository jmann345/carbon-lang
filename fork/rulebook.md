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
