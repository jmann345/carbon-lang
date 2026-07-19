# Fork of carbon-lang: the road to 0.1

This is jmann345's fork of
[google/carbon-lang](https://github.com/carbon-language/carbon-lang),
forked from trunk at `99cda60` (2026-07). The goal: drive this fork to
the **0.1 milestone** — Carbon's own definition of a minimum viable
product for C++ developers to evaluate seriously
(`docs/project/milestones.md#milestone-01`) — using AI agent fleets with
the user deciding at design forks.

The Carbon core team's own estimate puts 0.1 at end-of-2026 *at the
earliest*. This fork attempts to compress that using the process that
ported Bun from Zig to Rust in 11 days: an objective arbiter, a living
rulebook, dependency-ordered workstreams, and implement → adversarial
review → fix loops that grind against ground truth.

## Layout of this directory

| File | Purpose |
| --- | --- |
| `research-notes.md` | Exhaustive extraction of the two methodology sources (Anthropic migration framework, Bun rewrite) and the criticism worth internalizing |
| `process.md` | The six-step framework adapted to language completion; roles; standing rules |
| `gap-analysis.md` | Every 0.1 milestone bullet mapped to DONE / PARTIAL / MISSING / DESIGN-ONLY with evidence, plus dependency-ordered workstreams |
| `decision-log.md` | Design forks: options researched, user decisions, consequences |
| `rulebook.md` | (created during the trial run) fork-local process rules that grow whenever review catches a repeated mistake class |
| `conformance/` | (created with the harness workstream) the arbiter: executable 0.1 conformance suite + scoreboard |

## Status

- [x] Methodology research and process definition (F-001 amended 2026-07-20: fork-0.1 targets Linux/macOS; Windows is post-0.1)
- [x] Repo audited against the 0.1 checklist (11-area agent audit)
- [x] Design forks F-001..F-005 decided (see `decision-log.md`)
- [x] Arbiter: nightly toolchain mirrored + conformance scoreboard v1 (93 programs: 60 PASS / 33 SKIP / 0 FAIL; all 56 bullets covered: 38 PASS / 18 SKIP)
- [x] Own-toolchain CI loop closed: jeromehome builds the branch, gates on `bazel test //toolchain/...`, publishes a release; fork-built toolchain scores identical parity (60 PASS / 33 SKIP / 0 FAIL)
- [x] Trial run COMPLETE: match slice 1 through the full loop (tests-first -> implement -> 2 adversarial reviewers -> fixer -> runner-side autoupdate -> full suite green -> gated merge). Scoreboard: 63 PASS / 33 SKIP / 0 FAIL; 39/56 bullets green
- [x] Design docs landed: error handling (F-006, Ok/Err) and unions (F-007, choice-vs-union doctrine), all 23 sub-decisions user-ratified
- [ ] Scaled workstreams: W5 choice payloads, error-handling B0, F-008..F-011 doc authoring
