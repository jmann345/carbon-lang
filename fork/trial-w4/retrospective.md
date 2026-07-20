# Trial run retrospective: match slice 1 (W4-S1)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

The process trial (fork/process.md step 5) completed 2026-07-19: one
milestone bullet taken through the entire loop, validating every piece of
the factory on real compiler code.

## What the loop proved

-   **Compile-first-try is achievable without a local build.** The
    implementation (~185 lines in check + node_stack/inst_namer support)
    compiled on the first CI attempt. Credit: the invariants reviewer's
    compile-focused pass, and mirroring sibling handlers exactly (R3
    applied to C++).
-   **Adversarial review earns its cost.** 12 findings, including two that
    golden tests would NOT have caught: the design-mandated `==` operand
    order (literal == scrutinee, p002188) and the TryGetIntTypeInfo gate
    admitting adapter classes like Core.Char with wrong diagnostics.
-   **Runner-side autoupdate closes the golden-file gap.** New testdata
    ships with empty CHECK lines; the autoupdate workflow rebuilds and
    reconciles on the runner, pushing goldens back (c5281a3). This is the
    standing pattern for all future compiler work.
-   **The scoreboard moved for the first time**: 60→63 PASS programs,
    38→39 bullets, matching flipped SKIP→PASS with runtime-verified
    behavior on the fork-built toolchain (fork-toolchain-11-c5281a36e).

## Loop timings (single self-hosted runner, warm cache)

autoupdate ~7 min; full build+test gate ~4 min; end-to-end
implement→merged ≈ one working day dominated by agent time and one
runner-offline stall (see R14).

## Scope trades

Recorded as W4-S1 in fork/decision-log.md: match_switch narrowed to
slice-1 arms and un-SKIPped; guard coverage preserved in a new SKIP
program; usefulness diagnostics deferred as W-066.
