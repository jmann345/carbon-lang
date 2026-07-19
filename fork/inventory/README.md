# fork/inventory — the work inventory

This directory holds **`work-items.json`**, artifact (2) of the fork's
quantized state (see `fork/process.md`, "Quantized state"): every known
concrete gap between this fork and the 0.1 milestone — TODO stubs,
fail_todo golden tests, missing feature slices, undesigned areas — as a
structured item with file:line evidence, owning milestone bullet, and
dependency edges.

Built 2026-07-19 by deduplicating 99 raw findings from four scanners
(check-TODO scan, fail_todo golden-test scan, conformance-SKIP scan,
design-sprint scan) into **65 work items**, W-001..W-065, topologically
ordered: an item never precedes anything it is blocked by.

## How to use it

Per `fork/process.md`:

- **Agents claim items from here, never from vibes.** Every workstream
  loop starts by reading `fork/conformance/out/scoreboard.json` (behavioral
  truth) plus this inventory, and ends by updating both.
- **Discovering un-inventoried work means adding the item first** — with
  file:line evidence and an owning bullet — before doing the work.
- **`bullet`** is copied *exactly* from the per-bullet table in
  `fork/gap-analysis.md` (`"none"` = fork-process/infra work or a feature
  with no owning 0.1 bullet, e.g. lambdas). 38 distinct bullets are
  covered.
- **`blocked_by`** references work-item ids (`W-###`), design-fork ids
  (`F-006`..`F-011`, the six design-sprint decisions gated by W-005), or
  external upstream markers. Items with an empty list are startable now.
- **`evidence`** paths are repo-relative and were opened/verified during
  inventory construction or by the originating scanner; per the
  gap-analysis preamble, spot-check before building on a claim.
- Sizes: S < M < L < XL. `kind` ∈ todo-stub | fail-test | missing-feature
  | design-needed | infra.

## Counts

**By kind** (65 total):

| kind | count | meaning |
| --- | --- | --- |
| design-needed | 23 | needs a user decision / accepted design before or alongside implementation |
| todo-stub | 21 | `context.TODO` / `CARBON_FATAL` sites in the toolchain |
| missing-feature | 11 | feature slice absent entirely |
| infra | 6 | fork process, harness, CI, platforms |
| fail-test | 4 | pre-staged fail_todo goldens pinning a known gap |

**By subsystem** (coarse grouping):

| area | count |
| --- | --- |
| toolchain/check/cpp (C++ interop check layer, incl. export/thunk/mapping) | 20 |
| toolchain/check core (+ sem_ir) | 12 |
| full-stack language features (lex+parse+check+lower) | 8 |
| check + lower cross-cutting | 5 |
| core/prelude (stdlib) | 5 |
| docs/design + proposals (design authorship) | 5 |
| fork process / conformance harness | 5 |
| toolchain/lower only | 2 |
| toolchain/driver / platform / CI | 2 |
| docs/guides + examples/build-integration | 3 |

**By size:** 13 S, 36 M, 13 L, 3 XL (the XLs: W-013 variadics, W-059
Windows, W-063 safe-Carbon design).

## Top 10 highest-leverage items

1. **W-008** — match checking + lowering (W4). The single widest
   unblocker: gates W-010/W-011/W-012/W-017/W-018, flips two scoreboard
   entries, and all 14 check handlers are already-parsed TODO stubs.
2. **W-005** — DS-0: register F-006..F-011 and run the six user
   decisions. An S-sized item that gates 20+ design-blocked items; nothing
   in the design sprint can land until the forks are decided.
3. **W-063** — safe-Carbon concrete design (W3). The stated reason 0.1
   slipped; XL but pure design, parallelizable with everything.
4. **W-013** — definition-checked variadics (W6). XL with zero blockers
   and a complete accepted design; also unblocks stdlib tuple work.
5. **W-014** — template lowering + dependent operations (W7). Removes the
   only hard compiler crash on a designed feature and gates W-028, W-043.
6. **W-009** — UN-1 native `union`. Settles the overlapping-storage
   primitive that choice payloads (W-010) and Core.Result (W-017) lower
   onto — the sprint's load-bearing storage decision (coherence risk 1).
7. **W-002** — conformance harness v2. Flips SKIPs that are not feature
   gaps (clang-args, multi-file) and creates arbitration channels for
   every doc/build-system bullet; the arbiter is the progress number.
8. **W-001** — upstream-merge staging flow. Upstream lands weekly; without
   the F-002 gate every other item risks re-implementing or colliding
   with incoming trunk work.
9. **W-059** — Windows end-to-end (W10). XL, independent of language
   features, and an explicit 0.1 install bullet — start early or it
   becomes the tail.
10. **W-016** — EH-B0 exception fencing flag. S-sized, replaces real UB at
    every Carbon↔C++ boundary today, first stage of the whole
    error-handling chain, and the threading doc (W-020) freezes on its
    default.

## Maintenance

- Update an item's `evidence`/`notes` when the cited lines move after an
  upstream merge (W-001's staging flow is the natural checkpoint).
- When an item completes, record the flipped scoreboard entries in its
  closing commit and remove it (or mark it done) here in the same change.
- One item per coherent feature slice: extend an existing item's evidence
  rather than adding near-duplicates.
