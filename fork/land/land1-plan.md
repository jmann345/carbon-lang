<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# LAND-1 plan: landing the held PRs into trunk under R33

**Status:** rev 8, 2026-11-02 -- SIGNED OFF FOR IMPLEMENTATION.
Rev 8 (2026-11-02) folds round 5 of the focused re-review: round 5 of rev 7
(e2420b1c6) resolved RR4-1 and RR4-2 and found no BLOCKER, no MAJOR and
three MINORs, RR5-1 to RR5-3, all folded here (see the round-5 fold record
at the end), so by the orchestrator's ruling's sign-off rule (its item 3)
the plan is signed off (the section "Sign-off" at the end). Rev 7
(2026-11-01) folded round 4 of the focused re-review: round 4 of rev 6
(7cc793057) found no BLOCKER, two MAJORs, RR4-1 and RR4-2, and five MINORs,
RR4-3 to RR4-7, all folded there (see the round-4 fold record at the end):
D-LAND-22 decides, under R29 and with the measurement, that the template
assignment abort PR 61 and PR 64 reach is W-259's, a trunk defect, so both
land, and PR 63's records commit writes the (i) stamp the weekly upstream
check routed to DR-1.
Rev 6 (2026-11-01) recorded the orchestrator's ruling under R29 after round 3
verbatim (the section "Orchestrator's ruling (2026-11-01, after round 3)"),
restated PR 53's gate by its item 2, and folded the completeness audit of its
item 1: twelve agents, one per ready PR, tabled 381 land-time steps, 202
MAPPED, 32 MOVED, 72 UNMAPPED and 75 NOT-A-STEP; every UNMAPPED step was
folded with a text or a rule and a dated mark (the rev-6 fold record at the
end); rounds 4 and 5 followed under the same sign-off rule. Rev 5
(2026-11-01) folded round 3 of the focused re-review: round 3 of rev 4
(81699e9c4) resolved RR2-1 to RR2-4
and found two MAJORs, RR3-1 and RR3-2, and four MINORs, RR3-3 to RR3-6, all
folded here (see the round-3 fold record at the end); sign-off needs a round
with no BLOCKER and no MAJOR. Rev 4 (2026-11-01) folded the focused
re-review's round 2, RR2-1 (MAJOR) and RR2-2 to RR2-4. Rev 3 (2026-11-01)
folded the focused re-review's round 1, RR1-1
(BLOCKER), RR1-2 (MAJOR) and RR1-3 to RR1-6. Rev 2 (2026-11-01) folded
reviews A and B of rev 1, 25 findings, none rejected (the review fold
record); rev 1 was the planner's draft of the same day. Records only: this
plan changes no toolchain, prelude, golden, program or workflow file. It
carries out fork/rulebook.md R33 and decision-log entry LD-0 (the owner,
2026-11-01: "Go ahead and merge changes that are correct"), scheduled by
fork/ORCHESTRATION.md's Next actions lead (trunk bb9fbba9c :1171-1175) and its
paragraph dated 2026-11-01 (17:42 UTC) (:745-760).

**Summary.** Eighteen PRs are held open, PR 51 to PR 68; none is merged, and
every pushed head equals the head the task names (section 0.1). Twelve are
correct now and land in the recorded relative order: PR 67, 51, 52, 54, 55,
58, 61, 62, 64, 63, 65 and 68 (D-LAND-1). Six wait behind named gates: PR 53
(its realignment, SAFE-3 stopped; amended 2026-11-01, ruling fold: the
ruling's item 2), PR 60 (W-139), PR 56 and PR 57 (W-352), and, a finding of
this
audit, PR 59 and its stacked PR 66, because trunk's Next actions item 13 owes
PR 59 a crash fix (a pack in a choice alternative's parameter list aborts in
lowering where trunk rejects it at parse) and VA-2's hand-off note 7 owes it a
ruling on a second abort (D-LAND-2). PR 61 and PR 64 make a template's
assignment through a literal subscript abort in lowering where trunk rejects
it, but trunk aborts the same way on the variable subscript, and the root is
W-259, TP-1's filed residue in trunk's assignment check, which upstream's tip
shares; so both land and W-259 records the abort (D-LAND-22; added
2026-11-01, review fold: RR4-1). A sequential dry run of the twelve merges
over trunk bb9fbba9c, re-run for rev 2 with the gap rule corrected so that a
row both sides changed is composed and never dropped, resolves every conflict
by a recorded rule (section 0.5). The non-records conflicts are three, each
anticipated by the plan of the PR that lands second: two conformance programs
at PR 64 (CT-1's C.6 rule), and toolchain/check/handle_loop_statement.cpp with
a golden at PR 63 and toolchain/check/handle_index.cpp with a golden at PR 65
(DR-1's M-a and M-b rules). The gated PRs' later merges carry seven
toolchain-file conflicts, measured in section 0.6, which their follow-ons own.
Each landing is one merge commit, the plan's land-time commits, an optional
refill commit and a records commit, verified by the carbonbuild arbiter in
/home/user/carbon-trunk, reviewed by fresh agents and pushed in two phases:
the code first, then the records commit once GitHub shows the PR merged
(D-LAND-11). The static scoreboard goes from 128 PASS / 0 FAIL / 22 SKIP over
150 to 193 / 0 / 15 over 208, and the gap tally from 30/21/4/1 to 36/16/3/1
(section 4). (Amended 2026-11-01, review fold: A-B1 / A-M4 / B-M4.)

## Contents

-   Section 0: audit (the held state, owed items, conflicts, the dry run,
    goldens, scoreboards, the arbiter, ids, stacked PRs, disk, the register
    checks at upstream's tip)
-   Section 1: decisions D-LAND-1 to D-LAND-22
-   Section 2: spec, one subsection per landing in land order
-   Section 3: the process, the actors and the follow-ons
-   Section 4: the scoreboard progression and its stop values
-   Section 5: risks and rejected alternatives
-   Section 6: verification and what is not run
-   Hand-off notes
-   Appendix A: the per-landing record templates
-   Appendix B: the ORCHESTRATION stamps
-   Appendix C: each landing's fields, targets and own texts
-   Orchestrator's ruling (2026-11-01, after round 3)
-   Review fold record (rev 2, 2026-11-01)
-   Focused re-review fold record (rev 3, 2026-11-01)
-   Focused re-review fold record, round 2 (rev 4, 2026-11-01)
-   Focused re-review fold record, round 3 (rev 5, 2026-11-01)
-   Review fold record (rev 6, 2026-11-01)
-   Focused re-review fold record, round 4 (rev 7, 2026-11-01)
-   Focused re-review fold record, round 5 (rev 8, 2026-11-02)
-   Sign-off
-   Landing-time rulings (the orchestrator's rulings under R29 during the
    landing)

Conventions. `trunk` is origin/trunk bb9fbba9c unless a section says otherwise.
A file:line cite names the sha it was read at. `$P` is the planner's scratch
directory
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/planner,
`$F` the rev-2 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer,
`$F1` the rev-3 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer1,
`$F2` the rev-4 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer2
(added 2026-11-01, review fold: RR2-1), `$F3` the rev-5 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer3
(added 2026-11-01, review fold: RR3-2), `$F4` the rev-6 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer4
(added 2026-11-01, ruling fold: the ruling's item 2), `$F5` the rev-7 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer4/rev7
(added 2026-11-01, review fold: RR4-1), `$F6` the rev-8 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer5
(added 2026-11-02, review fold: RR5-1), `$Y` and `$W` SV-1's rev-5 and rev-4
fixers' scratch directories,
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5
and
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer4,
as SV-1's plan names them (0ef8a0334 fork/sumtype-interop/plan.md:172-173 and
:181-183; added 2026-11-01, review fold: RR4-5), `$CB` the arbiter's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild,
and `$X` the expected trees, `$F/expected` (rev 1's `$P/expected` is superseded
from PR 58 on, section 0.5; amended 2026-11-01, review fold: A-B1 / A-M4). The
placeholders are exactly those of the table below; each is measured as its row
says, and no other placeholder appears in a text this plan gives. No placeholder
survives into a commit (amended 2026-11-01, review fold: B-M5 / B-m6). A PR's
own text that Appendix C cites by its plan's lines, rather than giving it, keeps
that plan's slots, each set where Appendix C cites it: TP-1's `YYYY-MM-DD` and
CT-1's `<YYYY-MM-DD>` to `<date>`, TP-1's `<merged ...>` values to the landing's
measurements (C.8), CT-1's `<gate N of N>` and `<P / F / S over N>` to the
landing's final gate and conformance in the slots' own forms (C.10; amended
2026-11-02, PR 64's landing, the implementer's stop at step 9: ruling (15)), and
DR-1's three `<sha>` slots to `<merge sha>` and `<land-time shas>` (C.12; added
2026-11-02, sign-off check).

| Placeholder | Value | Measured by |
| --- | --- | --- |
| `<date>`, `<hh:mm>` | the UTC date and time the records edits were written at step 9, kept at step 12 | `date -u +%F` and `date -u +%H:%M` when the records edits are written at step 9 (reworded 2026-11-02, FC2-3, from the commit-time rule that RV67-2's ruling superseded; the records commit's message states 'records written <date> <hh:mm> UTC, committed <now> UTC') |
| `<now>` | the records commit's UTC date and time, written in the records commit's message only, never in a records text | `date -u +%F` and `date -u +%H:%M` when the records commit is made (added 2026-11-02, FC2-1, the orchestrator's ruling under R29) |
| `<prev>` | the date in the current ORCHESTRATION header's first clause | that clause, read before the records edit |
| `<trunk before>` | origin/trunk before the landing | `git rev-parse --short=9 origin/trunk` at step 1 |
| `<head>` | the PR's pushed head | `git ls-remote origin` at step 1 (section 0.1's value) |
| `<base>` | the PR's base branch, which is `trunk` at every landing (PR 64 and PR 65 after their retargets) | `pull_request_read`'s `base` at step 1 (added 2026-11-01, review fold: RR1-6) |
| `<merge sha>` | the landing's merge commit | `git rev-parse --short=9 HEAD` after step 5 |
| `<land-time shas>` | the commits after the merge, oldest first, comma-separated, or `none` | `git log --reverse --format=%h <merge sha>..HEAD` before the records commit |
| `<conflicts>` | each conflicted file as `<path> (<regions>, <rule>)`, in `git diff --name-only --diff-filter=U` order, a file or region not in `$X` marked `not in the dry run` | step 3 |
| `<refilled>` | each refilled golden as `<path> (<PRs whose changes combine>; <added>/<removed>)`, the two numbers its `git diff --numstat` against the commit before the refill (the numstat added 2026-11-01, ruling fold: AUD-63-7) | step 7 |
| `<rescan>` | each land-time id re-scan of D-LAND-21 as `<the ids> at <the point>: <the refs that file them>`, `;`-separated, or `none` where the PR's plan prescribes none | D-LAND-21's runs (added 2026-11-01, ruling fold: AUD-61-T15 / AUD-61-T26) |
| `<g0>`, `<gn>` | the merge's gate at step 4, before any refill: tests passed and tests run | step 4's `gate.log`: `[  PASSED  ] <g0> tests` and `[==========] <gn> tests from 1 test suite ran` (added 2026-11-01, review fold: RR1-6) |
| `<g>` | the landing's final gate (after step 7's refill, or step 4's when nothing is refilled): tests passed, which equals tests run | that gate's `gate.log`, `[  PASSED  ] <g> tests` |
| `<p>`, `<f>`, `<s>`, `<n>` | conformance PASS, FAIL (the five failure kinds summed), SKIP and programs | the landing's `scoreboard.json` `totals` |
| `<b>` | bullets PASS of 56 | the landing's `scoreboard.json` `bullets` |
| `<tally>` | the gap tally as DONE/PARTIAL/MISSING/DESIGN-ONLY | `python3 -I $F/bin/gaptally.py fork/gap-analysis.md` after the records edits |
| `<t1>`, `<t2>`, `<t3>`, `<t4>` | `<tally>`'s four numbers, DONE, PARTIAL, MISSING and DESIGN-ONLY | as `<tally>` (added 2026-11-01, review fold: RR1-5) |
| `<tip>` | upstream trunk's head | `git fetch upstream` then `git ls-remote upstream refs/heads/trunk`, 9 characters, at the check |
| `<q>`, `<qf>`, `<c>`, `<cf>` | quotes checked and failed, silence checks checked and failed | check_quotes.sh and check_greps.sh output at `<tip>` (D-LAND-19) |
| `<the FAIL rows' ids>` | the ids of the rows check_quotes.sh and check_greps.sh report failed at `<tip>`, listed as the scripts print them, or `none` | that output (D-LAND-19; added 2026-11-02, sign-off check) |
| `<mut>` | the mutants D-LAND-20 re-runs, each as `<id> (<what turned red, or "survives" for a recorded survivor>)`, with `; <probe set> not run: <reason>` inside the parentheses for each probe set of its record the landing does not run, comma-separated, or `none` | D-LAND-20's runs at the landing (added 2026-11-01, review fold: RR2-1; the probe sets added 2026-11-01, review fold: RR3-5) |
| `<dd>`, `<ddt>`, `<ddn>` | DD-1's checker's summary at the commit that names them (L, or PR 58's state-L commit), without `--toolchain`, with the landing's and with the 2026.10.12 nightly's | the last line that `python3 -I fork/designdocs/check_samples.py` prints, the same with `--toolchain /home/user/carbon-build/carbon-trunk/install/bin/carbon`, and with `--toolchain /home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon` (added 2026-11-01, review fold: RR2-1; `<ddn>` added 2026-11-01, ruling fold: AUD-58-U3) |
| `<r31>` | R31's counts of the markdown files the commit that names it edits (docs/design/interoperability/README.md at PR 64's L; the nine files of PR 58's state-L commit, one after another) before the edit, after it and after prek | `r31.py` at each point, written `<before> / <after> / <after prek>`, each as `r31.py` prints its headings, bullets, numbered and rows fields (added 2026-11-01, review fold: RR2-1; the state-L commit added 2026-11-01, ruling fold: AUD-58-U2) |
| `<v3>`, `<v3n>` | the places at `<tip>` of F-021's four upstream quotes and of E-ARG's `CppCallArgTypeNotSupported`, and the count of upstream commits since c1e83b0b7 that section 2.9's log reads (CT-1's section 0.10 set: its sixteen toolchain files and three testdata paths, toolchain/check/cpp/, docs/design/ and proposals/) | section 2.9's `git grep -n -F` of each quote and its `git grep -n CppCallArgTypeNotSupported` at `<tip>`, as `<path>:<line>`, comma-separated, and its `git log --oneline` line count (added 2026-11-01, review fold: RR2-1; the set and E-ARG amended 2026-11-01, review fold: RR3-2) |
| `<landed>`, `<held>` | PRs landed and held after this landing | the stage number (section 3) and 18 minus it |
| `<merged_at>`, `<api sha>` | GitHub's `merged_at` and `merge_commit_sha` for the PR | `pull_request_read` after phase 1 (D-LAND-11) |
| `<r>` | this plan's revision at sign-off | its Status line |
| `<trailers>` | the session's two attribution trailers | written by the implementer into commit messages only |

## §0 Audit

### §0.1 The held state

`git ls-remote origin` (2026-11-01, after `git fetch origin`; re-run for rev 2
at 19:00 UTC) gives trunk and the mirror claude/carbon-fork-0-1-7mwfb7 both at
bb9fbba9c, and every held head equal to the task's list; the GitHub API
(`list_pull_requests`, state open) gives all eighteen open, `merged: false`,
with the bases below. No head moved.

| PR | Workstream | Branch suffix | Head | Base (API) | Own files: toolchain / core / goldens / programs / docs / records / other |
| --- | --- | --- | --- | --- | --- |
| 67 | RG-1 | rg1 | 56e2e5bbd | trunk | 0 / 0 / 0 / 0 / 0 / 8 / 0 |
| 53 | SAFE-1 | safe | 2407efa74 | trunk | 0 / 0 / 0 / 2 / 14 / 6 / 0 |
| 51 | UA-2 | ua2 | f96fe8a7a | trunk | 0 / 0 / 3 / 3 / 2 / 5 / 0 |
| 52 | CM-1 | cmake | e6bc32a6d | trunk | 0 / 0 / 0 / 2 / 2 / 7 / 19 |
| 60 | SC-1 | sc | cc4daba00 | trunk | 42 / 0 / 19 / 2 / 5 / 7 / 0 |
| 54 | EV-1 | ev | cb3ef2e74 | trunk | 0 / 0 / 0 / 14 / 5 / 12 / 1 |
| 55 | ST-1 | st | c3cdecc5d | trunk | 1 / 1 / 10 / 7 / 4 / 6 / 0 |
| 56 | OP-1 | op | 9f12209d8 | trunk | 0 / 1 / 3 / 11 / 4 / 6 / 0 |
| 57 | OP-2 | op2 | e23113ba2 | op (PR 56) | 3 / 1 / 33 / 9 / 2 / 6 / 0 |
| 58 | DD-1 | dd | fcee90d9b | trunk | 0 / 0 / 0 / 20 / 11 / 74 / 0 |
| 59 | VA-1 | va | b0822a744 | trunk | 45 / 0 / 18 / 10 / 1 / 6 / 0 |
| 61 | TP-1 | tp | 66aa13132 | trunk | 32 / 0 / 25 / 11 / 0 / 6 / 0 |
| 62 | SV-1 | sv | 0ef8a0334 | trunk | 12 / 2 / 13 / 12 / 2 / 6 / 0 |
| 64 | CT-1 | ct | 551a03328 | tp (PR 61) | 16 / 0 / 9 / 10 / 0 / 7 / 0 |
| 63 | DR-1a | dr | 89aabd125 | trunk | 1 / 2 / 10 / 1 / 2 / 5 / 0 |
| 65 | DR-1b | dr-idx | fee0ef31c | dr (PR 63) | 5 / 4 / 17 / 3 / 1 / 6 / 0 |
| 66 | VA-2 | va2 | 43c8ab476 | va (PR 59) | 46 / 2 / 79 / 13 / 0 / 6 / 0 |
| 68 | OV-4 | ov4 | 097c76473 | trunk | 4 / 0 / 4 / 3 / 1 / 7 / 0 |

Own files are `git diff --name-only <base>...<head>`, with the parent's head as
the base for the four stacked PRs ($P/ownfiles.txt); "other" is PR 52's cmake/
and examples/cmake/ tree and PR 54's docs/guides index. Records-only: PR 67.
Documentation and records with programs, no toolchain: PR 53, 51, 52, 54 and
PR 58. Prelude changes: PR 55, 56, 57, 62, 63, 65 and 66. Toolchain changes:
PR 55 (one file), 57, 59, 60, 61, 62, 63, 64, 65, 66 and 68 (rewrapped
2026-11-01, review fold: B-m1).

Two Branches rows cite a sha that is not the head: PR 51's row
(ORCHESTRATION.md:1093) names 05a5c30f7, and the head f96fe8a7a is its child,
"Autoupdate testdata goldens on the container arbiter" (2026-10-12 20:56 UTC),
after which /home/user/carbon-build/carbon-ua2/logs/gate.log records "Ran 1945
tests ... [ PASSED ] 1945 tests"; PR 63's row (:1107) names 18a7e8934, and the
head 89aabd125 is nine records commits later (`git log 18a7e8934..89aabd125`,
the last "DR-1 plan: focused re-review of DR-1b's fold, round 4 recorded",
2026-10-26). Neither is a moved head: the rows were not restamped, and each
landing's records commit rewrites its row (section 2). Nine local worktree
branches lag or lead their pushed heads (carbon-cmake ea573f672, -ct 4a3220c11,
-op 894139b34, -op2 a080c7886, -sc 40a76ab81, -st 21307851a, -tp 5661a35c8,
and the local claude/carbon-fork-0-1-safe, which at rev 2's re-scan is
db91f602a, "SAFE-3 plan (rev 10)", 2026-11-01 18:59 UTC, SAFE-3's unpushed
work ahead of 2407efa74); LAND-1 merges the pushed heads only, from origin.

Review state, from each plan's Status and the rows: PR 67 rev 5 signed off,
three implementation-review rounds folded (row :1110); PR 51 implementation
review folded at 05a5c30f7, container gate 1945 of 1945 at f96fe8a7a (above);
PR 52, 54 and 55 signed off and held with their verification records (rows
:1094, :1096, :1097); PR 58 four document-review rounds folded (:1102); PR 61
round 11 dry (:1104); PR 62 focused re-review round 2 dry (:1105); PR 64 round
1 dry (:1106); PR 63 implementation review folded and PR 65 round 4 dry
(:1107-1108); PR 68 re-review round 1 dry (:1111). The expected scoreboards the
rows state are each against the PR's own base: PR 51 131/0/19 over 150, PR 54
137/0/22 over 159, PR 55 133/0/21 over 154, PR 58 147/0/22 over 169, PR 61
138/0/22 over 160, PR 62 133/0/22 over 155, PR 64 1959 of 1959 and 147/0/20
over 167, PR 63 1942 of 1942 and 128/0/22 over 150, PR 65 1946 of 1946 and
130/0/22 over 152, PR 68 1946 of 1946 and 130/0/22 over 152; PR 52's row
states none. Section 4 turns each into the PASS delta the landing must show.

### §0.2 Owed items and the not-ready PRs

-   PR 53: SAFE-2 stopped at its plan rev 14 (row :1095; the 2026-10-29
    paragraph :706-743), and SAFE-3 stopped at its plan rev 12 (14c1ac8ac,
    2026-11-01) under its re-think ruling's break condition, RT1-B1 and
    RT2-B1: C++ code reaching, from an address it receives, a Carbon place
    that the carrier closure of D-SAFE3-13 does not name (14c1ac8ac
    fork/safe/safe3-plan.md:9-44); the pushed head stays 2407efa74, which
    carries SAFE-1's six filed drifts W-347 to W-351 and W-353, living in PR
    67's ledger; SAFE-2's and SAFE-3's commits are unpushed and mirrored at
    claude/carbon-fork-0-1-safe-wip; W-365 and W-366 stay reserved and
    unfiled; the orchestrator stamps the stop on trunk from safe3-plan.md
    Appendix D's stop path after Appendix B.1's stamp (amended 2026-11-01,
    ruling fold: the ruling's item 2).
-   PR 60: W-139 is owed on its branch (Next actions item 6, :1224-1226).
-   PR 56 and PR 57: W-352 is owed on PR 56's branch and merged into PR 57's
    (:1226-1228).
-   PR 60 with PR 57: Next actions item 10 (:1252-1258) says SC-1's
    `self_facet_in_signature_required` split fails against OP-2's
    `DefaultOptionalStorage` on VA-2's land simulation and that the two owners
    decide which commit carries it before either lands.
-   PR 59: Next actions item 13 (:1269-1277) says a pack expansion pattern in a
    choice alternative's parameter list passes VA-1's check and aborts in
    lowering at lower/file_context.h:187 on PR 59, where trunk and the upstream
    nightly of 2026-10-12 reject it at parse, and routes the fix "to PR 59 under
    its own review"; VA-2's hand-off note 9 (43c8ab476
    fork/variadics/va2-plan.md, "For the orchestrator: a pack in a choice
    alternative's parameter list on PR 59") gives the fix's shape and its break
    condition, "PR 59 landing on trunk before the fix". VA-2's hand-off note 7
    ("defect A on PR 59") says PR 59 aborts at its lower/type.cpp layout check
    on VA-1's own forms e09, e11 and e13 and asks the orchestrator to rule
    whether PR 59 takes the array-stride layout as a fix commit or records why
    not; item 2 (:1185-1198) requires both notes ruled before VA-2's M. Neither
    ruling nor fix is on any branch. PR 66 contains PR 59's commits.
-   No other "before PR N lands" item is in the Next actions: items 11 and 12
    are owner requests that gate no PR, and item 11's class is on trunk too.

### §0.3 Land-time steps by plan

Each plan specifies its land-time steps as commits on its own branch: a merge of
trunk into the branch (M or an integration commit), compositions, refills and a
records commit. Section 2 maps every item of each list below to a step at the
landing or to a named follow-on (amended 2026-11-01, review fold: B-M6), and
D-LAND-3 turns the branch-side steps into trunk-side commits. The sources: RG-1
56e2e5bbd fork/register/rg1-plan.md section 5 (:1607-1640) and Appendix A.4's
land-time notes (:2526-2587) with its date rule (:1076-1079, :3479-3482), the
section 6 rejection's break condition (:1699-1707) and W-355's L-check rule
(:1394-1397); UA-2 none of its own (its fill is the head); CM-1 e6bc32a6d
fork/cmake/plan.md D-CM-14's Option B trigger (:432-438), D-CM-16's ids
"verified at merge" (:453-454), section 5.1's delta rule (:908-912) and
section 5.4's revert (:966-973), where rev 5 said CM-1 names none (amended
2026-11-01,
ruling fold: AUD-52-02); EV-1 cb3ef2e74 fork/evaluator/plan.md section 3 item 6
(:1830-1842), states T and C (:296-311), section 2.F.2 and 2.F.3 (:1677-1686,
:1744-1746), R-8 (:2034-2045) and its branch's land-sequence item
(fork/ORCHESTRATION.md:103-116); ST-1 c3cdecc5d fork/string/plan.md landed
notes' conditional items (:3103-3110) and its branch's Next actions item 5
(fork/ORCHESTRATION.md:524-562); DD-1 fcee90d9b fork/designdocs/plan.md §2.13
and §2.14 (:4180-4276), §8.5's integration-commit texts (:5665-5678, :5783-5810)
and its merge position (:6658); TP-1 66aa13132 fork/templates/plan.md §1.12
(:2924-2957), §3 items 7 to 13 (:5192-5316), Appendix E's land-time texts
(:17744 on), its landed notes' Ledger re-cites (:7905-7914, "At land time the
records commit re-cites them to the merged tree"; added 2026-11-01, review fold:
RR3-4) and its landed notes' land-time items (a) to (h) (:7919-7936, item (c)
judging M, S and F6 "with §8's build, autoupdate, gate, conformance and
mutants"; amended 2026-11-01, review fold: RR2-1); SV-1 0ef8a0334
fork/sumtype-interop/plan.md §1.15 (:2392-2399), §3 item 8 (:4606-4830),
Appendix C.6 and C.7 (:9351-9420) and the landed notes' Next actions text
(:9566-9576); CT-1 551a03328 fork/cpp-templates/plan.md §2.11 items 1 to 5
(:2725-2760) with Appendix C.1 to C.11, its landed notes' "R32 at landing"
(:4793-4799) and land-time items (a) to (g) (:4809-4868), and its branch's Next
actions item 6, "CT-1 at land time" (551a03328 fork/ORCHESTRATION.md:1220-1267;
added 2026-11-01, review fold: RR2-1); DR-1 89aabd125 and fee0ef31c
fork/direction/plan.md §1.16 (:1547-1642), §2.2 (:2190-2245), §8 items 5, 9 and
10 (:2623-2650, :2701-2774), Appendix C.2 and C.3 (:3428-3469, :3525-3532), its
landed notes' "At land time" items (:5151-5175, :5449-5477) and section 0.8's
rows for PR 56, PR 57, PR 59 and PR 60 (:708-712), where rev 5 cited :1547-1620
and :2755-2775 (amended 2026-11-01, ruling fold: AUD-63-12 / AUD-63-13); OV-4
097c76473 fork/overload/ov4-plan.md §3's land-time commits (:1749-1803), §6.2
(:1901), R-5 (:1991-1996), §8.8 (:2368-2372) and Appendix D.6 and D.7 (:4042,
:4108). TP-1's front matter's id re-scans (:582-597), its section 2.8 rule for R
(:5000-5005) and D-TP-16 (:3474-3478) are sources too. Rev 6's completeness
audit (the ruling's item 1) enumerated each ready PR's land-time steps from all
of its records, the other held plans' steps prescribed at its landing included;
the rev-6 fold record tables each step with its status and disposition (added
2026-11-01, ruling fold: the ruling's item 1).

### §0.4 Conflicts against trunk

`git merge-tree --write-tree bb9fbba9c <head>` for each head conflicts in
records files only; regions (`grep -c '^<<<<<<<'` of the merged file):

| PR | decision-log | work-items | ORCHESTRATION | gap-analysis |
| --- | --- | --- | --- | --- |
| 67 | 1 | 0 | 5 | 0 |
| 53 | 1 | 1 | 2 | 0 |
| 51 | 0 | 2 | 0 | 1 |
| 52 | 1 | 2 | 3 | 0 |
| 60 | 0 | 2 | 2 | 0 |
| 54 | 1 | 2 | 4 | 0 |
| 55 | 1 | 2 | 3 | 1 |
| 56 | 1 | 2 | 3 | 2 |
| 57 | 1 | 2 | 3 | 2 |
| 58 | 1 | 2 | 4 | 1 |
| 59 | 1 | 2 | 3 | 0 |
| 61 | 0 | 1 | 2 | 0 |
| 62 | 0 | 2 | 4 | 1 |
| 64 | 0 | 2 | 2 | 0 |
| 63 | 1 | 1 | 2 | 0 |
| 65 | 1 | 1 | 2 | 0 |
| 66 | 1 | 2 | 5 | 0 |
| 68 | 0 | 0 | 4 | 0 |

Against RG-1's baseline of 2026-10-27 (rg1-plan.md section 4.7), PR 63's and
PR 65's decision-log regions are new (1, not 0), and PR 67's ORCHESTRATION
regions are five: trunk's LD-0 entry sits directly after DR-0's, where RG-1's
entry and DR-1's also go (D-RG-14), and trunk's 2026-10-29 and 2026-11-01
stamps rewrote the header, item 6 and the rows.

### §0.5 The sequential dry run

Rev 2's run (amended 2026-11-01, review fold: A-B1 / A-M4 / A-m1 / B-B1). A
detached worktree /dev/shm/land1-fixer/wt at bb9fbba9c merged the twelve heads
in D-LAND-1's order, each by `git merge --no-ff --no-commit`, resolved by
D-LAND-5's rules with `$F/bin/step.sh` (`trymerge2.sh`, `md3v2.py`, the
planner's `ledger3.py`, `dlorder.py`) and `$F/bin/compose_rows.py` for the rows
that GA-1b and GA-1c decide, the non-records files taken from the planner's
references, and committed in the scratch (never pushed; the driver from PR 58 on
is `$F/bin/redo.sh`). Unlike rev 1's run, it also commits the two land-time
commits whose text a later merge sees: DD-1's state L for PR 51, PR 54 and PR 55
at PR 58 (`$F/bin/stateL58.py`, the texts of section 2.6), and SV-1's row-68
sentence by C.7's fallback at PR 62 (section 2.8). Each landing's stages and
region report are in `$X/pr<N>/stages/`, the scratch commit and tree in
`merge_sha.txt` and `tree.txt`, and `runner.py --self-test` in `selftest.txt`;
`$F/shas.txt` lists them.

| Step | Scratch commits | Conflicted files (regions) | Rules applied |
| --- | --- | --- | --- |
| PR 67 | 52227b4e8 | ORCHESTRATION (5), decision-log (1) | OR-1, OR-2 (2), OR-3, OR-4; DL-3 (RG-1's entry before LD-0) |
| PR 51 | 88519a79f | gap-analysis (1), work-items | GA-1 (row 79: both edits kept by the word merge); LG-1 (14 items) |
| PR 52 | 5b6cc69ed | ORCHESTRATION (3), decision-log (1), work-items | OR-1, OR-2, OR-4 with OR-5 (the W-128 item); DL-1; LG-1 (11) |
| PR 54 | 61458bc92 | ORCHESTRATION (4), decision-log (1), gap-analysis (4), work-items | OR-1 to OR-4 with OR-5 (the W-152 item); DL-1; GA-1 (row 90), GA-2 (3: header, prose, section W11); LG-1, LG-3 (W-002, W-003) |
| PR 55 | 8beb5d7d5 | ORCHESTRATION (4), decision-log (1), gap-analysis (3), work-items | OR-1, OR-2, OR-4 (2) with OR-5 (items 5 and 6); DL-1; GA-1 (2), GA-2 (header); LG-1 |
| PR 58 | a33d05cae, then 94dba6b21 | ORCHESTRATION (4), conformance/README.md (1), decision-log (1), gap-analysis (4), work-items | OR-1 to OR-4 with OR-5 (DD-1's correction note); README-1; DL-1; GA-1 (row 67), GA-1b (row 54 composed, row 91 DD-1's cell), GA-2 (header); LG-1, LG-2, LG-3, LG-5, LG-6 (W-043, W-065) |
| PR 61 | d03be4456 | ORCHESTRATION (2), conformance/README.md, gap-analysis (1), work-items | OR-3, OR-4 with OR-5; README-1; GA-1c (row 54: trunk's row, TP-1's R composes it); LG-1 |
| PR 62 | ef8f684f9, then 9f94b3409 | ORCHESTRATION (4), gap-analysis (1), work-items | OR-1 to OR-4 with OR-5; GA-1c (row 68: trunk's row, SV-1's R appends C.7's sentence); LG-1 |
| PR 64 | e21480b05 | ORCHESTRATION (2), conformance/README.md, two programs (2 each), decision-log (1), gap-analysis (2), work-items | OR-3, OR-4 with OR-5; README-1; PROG-1; DL-1; GA-1c (rows 42 and 56: trunk's rows, CT-1's C.4 replaces them); LG-1, LG-7 (W-043) |
| PR 63 | f2110e0fd | ORCHESTRATION (2), decision-log (1), gap-analysis (2), work-items, handle_loop_statement.cpp (1), interop/cpp/range_for.carbon (25) | OR-2, OR-4; DL-3 (DR-1's entry directly after DR-0's); GA-1 (row 67, the Optional row), GA-1b (row 68: DR-1a's row plus SV-1's sentence); LG-1; TC-1; GOLD-1 |
| PR 65 | d3eb55f7a | ORCHESTRATION (1), conformance/README.md, gap-analysis (1), work-items, handle_index.cpp (3), operators/overloaded/string_indexing.carbon (2) | OR-2; README-1; GA-1b (row 79: DR-1b's row with trunk's W-108 clause); LG-1, LG-6 (the source header); TC-2; GOLD-1 |
| PR 68 | 5cf7406f1 | ORCHESTRATION (4), work-items | OR-1 to OR-4; LG-1 |

Every scratch commit passes `runner.py --self-test` ("N programs parsed, 56
bullets in table, OK") and `json.load` of the ledger (232 items at the end).
The model-identifier grep of `git diff bb9fbba9c..5cf7406f1`, with the
patterns kept in $P/model_ids.txt, finds nothing. DD-1's
`fork/designdocs/check_samples.py` reports "1 errors: W2 entry no longer hits:
docs/design/expressions/arithmetic.md | Strings | (c)" on the PR 58 merge
a33d05cae (0 at fcee90d9b), because PR 55, landed before it, fills the section
that DD-1 allowlists as "held PR 55 (ST-1)"; after the state-L commit 94dba6b21
it reports 0 errors, and so at every later scratch commit. EV-1's
`fork/evaluator/check_samples.py` reports 0 errors from PR 54 on. Section 2's
gap-row check (`$F/bin/rowcheck.py`, D-LAND-9) passes at every step with the
rows section 2 names; on rev 1's merges it reports 8 missing segments at PR 65
and 16 at PR 58 ($F/checkers.txt has the checker runs). The dry run did not
simulate PR 54's state C commit ($F/checkers.txt: 'state C not simulated'), so
its check at PR 54 was the merge's, 0 missing with no row named; at the landing
the state C rewrite of row 90 makes row 90 a named row (section 2.4 as
amended 2026-11-02, the orchestrator's ruling under R29).

Rev 1's run ($P/expected) is identical to rev 2's through PR 55. From PR 58 on
it differs: rev 1's GA-2 took trunk's side for whole gap rows both sides
changed, which dropped DR-1b's row 79 (its DONE status, W-326 and W-340
sentences), DD-1's rows 54 and 91 and SV-1's row 68 text; it did not commit the
two land-time commits above; it put DR-1's decision-log entry after LD-0,
against D-RG-14; and its committed PR 64 tree kept CT-1's W-043 discharge,
which LG-7 takes from DD-1's side (its saved file applied LG-7). The rev-2 run
also finds a records conflict rev 1 could not: once SV-1's row-68 sentence is
on trunk, PR 63's merge conflicts on row 68, which GA-1b composes.

Non-records conflicts, all anticipated by the plan of the PR that lands
second: at PR 64, fork/conformance/programs/interop/cpp_template_symbolic_arg
.carbon and cpp_template_on_carbon_generic.carbon against PR 51 (CT-1's
Appendix C.6, "Appended to PR 51's header in both programs, which keep CT-1's
body", 551a03328 fork/cpp-templates/plan.md:7031-7046); at PR 63,
toolchain/check/handle_loop_statement.cpp against PR 61 and
toolchain/check/testdata/interop/cpp/range_for.carbon against PR 61 and PR 64
(DR-1's M-a: "handle_loop_statement.cpp takes DR-1a's side and drops TP-1's
pointer completeness requirement and its include", and range_for "is refilled
against trunk's merged text", fee0ef31c fork/direction/plan.md:1555-1582); at
PR 65, toolchain/check/handle_index.cpp against PR 61 and
operators/overloaded/string_indexing.carbon against PR 55 (M-b: "handle_index
.cpp resolves onto TP-1's `PerformIndex`" and string_indexing's "two conflict
blocks at M-b are CHECK lines only and take trunk's side", :1583-1596). The 25
range_for regions and the 2 string_indexing regions hold `// CHECK:` lines
only (counted). No conflict between two ready PRs is unanticipated in this
run.

The run's limit (added 2026-11-01, review fold: A-M4). It commits the merges,
the compositions of D-LAND-5 and the two land-time commits named above, and no
other land-time commit: not the records commits (rows, paragraphs, headers,
ledger notes, decision-log sentences, Landed paragraphs), not TP-1's F6 and L,
EV-1's state C, CT-1's L-F and L, DR-1's L-a, C-b and L-b, OV-4's L-R, nor
Appendix B.1's stamp (TP-1's L and CT-1's L are applied apart, below; amended
2026-11-01, review fold: RR1-2). A later merge can conflict with those: three
are predicted, all at PR 65's merge: two from the heads, against PR 63's
Landed paragraph in fork/direction/plan.md and its decision-log sentence in
DR-1's entry, PL-1 and DL-4, and DL-5 on DR-0's register block, where PR
63's records commit writes Appendix C.11's (i) sentence (measured on
copies, `$F5/rr4-2/`; amended 2026-11-02, review fold: RR5-1); and a
refill or a records text may meet a later PR's edit (PR 63's
range_for against F6's refill; PR 64's W-043 against PR 58's records note). So
the conflict sets above are those of this sequence, not of the landings
themselves: D-LAND-6 step 2a re-runs the remaining merges over the pushed trunk
before each landing, and step 3 compares the landing's conflict set and regions
with `$X` and records every difference.

The two L commits over the state-L split (added 2026-11-01, review fold: RR1-2).
PR 58's state-L commit 94dba6b21 removes "held PR 51" from the lines that TP-1's
and CT-1's L texts quote, so neither applies as written: `git apply --check` of
TP-1's templates.md diff, extracted from 66aa13132 fork/templates/plan.md
Appendix C by `$F1/bin/extract_l61.py`, fails on the PR 61 scratch merge
d03be4456 ("patch failed: docs/design/templates.md:361", hunk 9), and `patch`
takes that hunk only with fuzz 1; CT-1's C.1 anchor "(fork work item W-043, and
W-127 on held PR 51)." occurs nowhere on the PR 64 scratch merge e21480b05
(`$F1/n2_apply_check.txt`). With section 2.7's and Appendix C.8's state-L
context for hunk 9 and comments for X20 and X23, and Appendix C.10's anchor,
both apply in scratch commits outside the chain (never pushed): TP-1's L on
d03be4456 is 9e0ccecdb, where DD-1's checker reports "19 program blocks, 70
fixtures, 2 W2 hits (1 allowlisted, 1 qualified); 0 errors"; on e21480b05,
TP-1's L (f0d62063d) then CT-1's L by `$F1/bin/apply_l64.py` (6f6e2f388) give
71 fixtures and 0 errors (`$F1/n2_l61_checker.txt`, `n2_l64_checker.txt` and
`n2_shas.txt`). No later merge of the run touches a file
either L edits (`git diff --stat d03be4456 5cf7406f1` over
docs/design/templates.md, docs/design/interoperability/ and fork/designdocs/ is
empty), so the chain's later commits are unchanged by them. The `--toolchain`
mode is the landing's (section 6).

Records interactions the dry run found that no plan names (each is a records
correction in the named landing's records commit, not a merge rule): at PR 58,
W-043's notes keep DD-1's appended sentence that the SKIP reason of
cpp_template_symbolic_arg.carbon "is stale", while PR 51, landed before it,
un-SKIPped that program; at PR 54, PR 55, PR 58 and PR 65 the gap-analysis
header's tally is taken from trunk's side (GA-2), so each records commit
recomputes it from the rows (section 0.7); at PR 67, trunk's LD-0 and RG-1's
entry share an insertion point that D-RG-14 predates; at PR 63, DR-1a's row-68
clause "the held PR 62's D-SV-7 view, a second spelling, is removed by a commit
on its branch (W-322, 2026-10-21)" is a historical clause once PR 62 has
landed; and the Next actions items that OR-4 would drop (OR-5): PR 52's W-128
item, PR 54's W-152 item, PR 55's items 5 and 6 with the ST-1 paragraph that
names them, and PR 58's correction note under item 3 (amended 2026-11-01,
review fold: A-M1).

### §0.6 The follow-ons' merges, measured now

`git merge-tree --write-tree --name-only 5cf7406f1 <head>` (the gated heads
onto rev 2's last scratch commit; rev 1 measured the same sets onto d4119d2f3):

| PR | Conflicted files outside the records files |
| --- | --- |
| 53 | none (ORCHESTRATION, decision-log, gap-analysis, work-items) |
| 60 | docs/design/templates.md, toolchain/check/convert.cpp, toolchain/check/member_access.cpp, toolchain/check/merge.cpp (and conformance/README.md) |
| 56 | docs/design/control_flow/loops.md, docs/design/error_handling.md |
| 57 | loops.md, error_handling.md, toolchain/lower/testdata/array/iterate.carbon, lower/testdata/for/break_continue.carbon, lower/testdata/for/for.carbon |
| 59 | toolchain/check/handle_function.cpp |
| 66 | toolchain/check/convert.cpp, toolchain/check/eval.cpp, toolchain/check/handle_function.cpp (and conformance/README.md) |

These are MAJOR facts for the follow-ons, and each is a composition some plan
already specifies for the opposite order: PR 60's merge.cpp with OV-4's
`CheckOverloadMemberParamsMatch` (ov4-plan.md section 3, M's message: "OV-4's
CheckOverloadMemberParamsMatch passes SemIR::SpecificId::None and nullptr for
SC-1's two new parameters") and member_access.cpp with TP-1's S
(fork/templates/plan.md:5206-5212); PR 57's three lower goldens are DR-1a's
"m57 red set" (fork/direction/plan.md:1566-1574); PR 59's
handle_function.cpp is OV-4's "keeps VA-1's pack gate before OV-4's default
look-through"; loops.md is M-a's "drops PR 56's F-015 amendment in the
corrected form C.7 gives it". PR 53's merge auto-merges docs/design/README.md
and expressions/arithmetic.md over the state-L split of section 2.6.

### §0.7 Goldens, prelude, refills and the gap tally

Goldens or toolchain files that two of the twelve change (own diffs,
$P/ownfiles.txt): range_for.carbon (PR 61, 64, 63), string_indexing.carbon
(PR 55, 65), slice/basic.carbon (PR 63, 65, stacked), and
deduce_class_args.carbon and default_init.carbon (PR 61, 64, stacked); in
toolchain sources call.cpp (61, 64, 65, 68), convert.cpp (61, 62, 64, 65),
handle_index.cpp (61, 65), handle_loop_statement.cpp (61, 63),
refutable_binding.cpp and diagnostics/kind.def (61, 62), and action.cpp,
eval.cpp, impl_lookup.cpp, member_access.cpp, expr_info.cpp and typed_insts.h
(61, 64, stacked); core/prelude/iterate.carbon (63, 65, stacked). Only the
first two combine two unstacked PRs' goldens, at PR 63 and PR 65, and their
refills are DR-1's L-a and L-b. The plans predict these further refills at the
landings where they apply: TP-1's F6 (TP-1's ten refills recomputed on the
merged tree, the landed notes' item (c), 66aa13132
fork/templates/plan.md:7923-7925, whose count section 3 item 8's "seven"
predates, amended 2026-11-01, review fold: RR3-4; and PR 51's split
`fail_todo_unformed_dependent_var` refilled under its own name, CHECK lines
only: the split's shape still fails on TP-1's
toolchain, so F6 does not rename it), SV-1's F-M (its own goldens; the PR 57
part waits), CT-1's L-F (C-2's rename of that split to `unformed_dependent_var`
and its refill, the shape compiling on CT-1's toolchain; C.11's split waits
with S-VA), DR-1's L-a (check and lower
generic/template/for_range and interop/cpp/range_for; the m57 three wait), L-b
(check generic/template/index, slice/write_through's split, renamed with its
comment reworded by Appendix C.12's text, amended 2026-11-01, review fold:
RR3-1, string_indexing 2/2) and OV-4's F-M (predicted none). Prelude changes
(PR 55, 62, 63, 65) can move full-prelude dumps; the gate finds any such
golden and D-LAND-8 refills it.

F6 and C-2, measured (added 2026-11-01, review fold: RR1-1). CT-1 found that
TP-1's predicted rename fails: 551a03328 fork/cpp-templates/plan.md C-2
(:864-878, "So TP-1's F6 rename would leave a split without the `fail_`
prefix that still reports an error ... the rename and refill move to CT-1's
land-time fill") and hand-off note H-1 (:4297-4305). Reproduced by this
revision on the split's shape, `fn F[T: type](unused x: T) { var unused v:
Cpp.S(T); }` with PR 51's header (`$F1/n1probe`): the TP-1 install
/home/user/carbon-build/carbon-tp (version eafca5cb9, whose toolchain/ and
core/ differ from 66aa13132 only in two testdata files) reports "cannot convert
type `S(<cannot stringify inst59000038: {kind: TemplateInst, ...}>)` into type
implementing `Core.DefaultOrUnformed`", exit 1; the CT-1 install (224ee2f8f,
the same relation to 551a03328) compiles it, exit 0; trunk's (0bdce60a5)
reports the `<splice of ...>` form PR 51's CHECK lines hold. file_test reports a
split without the `fail_` prefix that fails as a problem autoupdate cannot fix
(testing/file_test/file_test_base.cpp:131-160, `GetFailPrefixProblems`), so a
rename at PR 61 would stop stage 7. F6 therefore keeps the name, and PR 64's
L-F renames the split; CT-1's section 1.16 fallback, which assumed PR 61 landed
the rename, does not apply.

The gap tally of each scratch commit's rows (`$F/bin/gaptally.py`, rev 2) is
30/21/4/1 at trunk, PR 67 and PR 51; 32/20/3/1 at PR 52; 33/19/3/1 at PR 54;
34/18/3/1 at PR 55; 35/17/3/1 from PR 58 to PR 63; and 36/16/3/1 at PR 65 and
PR 68, where DR-1b's row 79 is DONE. The header the merges keep says 32/20/3/1
from PR 52 on, with CM-1's "130 PASS / 0 FAIL / 20 SKIP over 150 programs, 49/56
bullets PASS, stated as expected, not of record (Actions disabled)", so every
landing's records commit rewrites the header's first sentence by Appendix A.8
with the measured `<tally>` and the landing's container-measured scoreboard
(amended 2026-11-01, review fold: A-B1 / RR1-5). Six rows move
to DONE: rows 84 and 87 at PR 52 ("Project: toolchain drop-in usage as Clang
C++ toolchain with common Make/CMake build systems" and "Project: CMake
build-system integration plus Make documentation"), row 90 at PR 54 ("Project:
basic evaluator documentation (getting started to FAQs)"), row 77 at PR 55
("Stdlib: String and string-literal types"), row 70 at PR 58 ("C++ interop:
threading, atomics, memory model, synchronization") and row 79 at PR 65
("Stdlib: Slices"); D-LAND-18 (f) requires each one's bullet to PASS in that
landing's scoreboard (R9). On trunk's committed scoreboard (bb9fbba9c) and on
PR 51's (f96fe8a7a), one DONE row's bullet is not PASS: "Project: detailed
safety strategy" (SKIP); that is the baseline exception set, measured again at
stage 0 (added 2026-11-01, review fold: B-M3).

### §0.8 Scoreboards, measured statically

`runner.py --self-test` on each scratch commit counts the programs and the
`// SKIP:` directives; a program with no SKIP is expected to PASS. The
counts are the merge's, before any land-time commit: trunk 150 and 22 SKIP;
PR 67 150, 22; PR 51 150, 19; PR 52 150, 17; PR 54 159, 17; PR 55 163, 16; PR
58 182, 16; PR 61 192, 16; PR 62 197, 16; PR 64 204, 16; PR 63 204, 16; PR 65
206, 16; PR 68 208, 16. EV-1's state C commit un-SKIPs
project/evaluator_tutorial_cpp_library.carbon (its SKIP text: "Un-SKIP
mechanically once PR 52 is on trunk"), so from PR 54 on the SKIP count is one
less (section 4). The sixteen SKIPs at the last scratch merge are listed in
$P/skips_tip.txt. Bullets are measured by the run only. For comparison, OV-4's
mall mirror of all eighteen heads measured 224 PASS, 0 FAIL, 14 SKIP over 238
in 133.2 s ($P/../../ov4-impl/fixer/mall/scoreboard.json).

The committed `fork/conformance/out/scoreboard.json` (added 2026-11-01, review
fold: B-m5): trunk's is the hosted run of 2026-10-06 02:26 UTC, 128/0/22 over
150; PR 51 brings its hosted run of 2026-10-06 04:36 UTC, 131/0/19 over 150
(run 37413300832); no other ready PR changes it, and `.gitignore` ignores the
directory, so `conformance.sh <worktree> <out>` with `<out>` outside the
repository never touches it. D-LAND-17 decides what it holds.

### §0.9 The arbiter

$CB/README.md and the scripts: `build.sh <worktree>` generates the ninja file
from the worktree's BUILD files and builds carbon-busybox, file_test and
make-installation-digest incrementally into /home/user/carbon-build/<worktree
basename>; `install.sh` lays out the install tree and runfiles; `gate.sh` runs
file_test in test mode over every testdata file of
toolchain/{check,codegen,driver,format,language_server,lex,lower,parse}
(log logs/gate.log); `autoupdate.sh <worktree> [files]` is the only script that
writes the worktree, rewriting CHECK lines like
toolchain/autoupdate_testdata.py; `conformance.sh <worktree> <outdir>` runs
fork/conformance/runner.py against the install. Measured present:
/home/user/carbon-trunk (clean, local branch trunk at 563135b40, behind
origin/trunk bb9fbba9c by records-only commits); its build directory
/home/user/carbon-build/carbon-trunk with bin/carbon-busybox, file_test,
make-installation-digest and install/bin/carbon (2026-10-12; `carbon version`
prints `0.0.0-0.dev+0bdce60a5`; `git diff --stat 0bdce60a5 bb9fbba9c` changes
five files, all under fork/, so the build is trunk's toolchain); the LLVM build
/home/user/llvm-build/lib/libLLVM.so -> libLLVM.so.24.0git; the nightly
/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12.

Timings from the logs: the first trunk build took about 17 minutes on 4 cores
(README); OV-4's full mall build 326 steps in 7m39.8s and its one-file
incremental build 9.5 s (ov4-impl/fixer/mall/build.log and
logs/build-fix1.log); gate.sh 22.6 s to 81.3 s wall over 1942 to 1977 tests
(/home/user/carbon-build/*/logs/gate.log); conformance 65.5 s over 150
programs (README) and 133.2 s over 238 (the mall). Per landing: records-only
about 5 minutes (a relink for the version stamp, gate, conformance); a
toolchain landing whose merge touches a widely included header (typed_insts.h,
kind.def: PR 61, 62, 64) near a full rebuild, 8 to 17 minutes, then about 5
minutes of gate, autoupdate and conformance; about 3 hours of machine time for
the twelve.

Covered: the fork's toolchain built with Carbon's assertions on (`-Og`, no
`NDEBUG`), every file_test golden, the conformance runner's programs, DD-1's
and EV-1's sample checkers, prek with the SKIP set below. Not covered (README
"Does not reproduce", amended 2026-11-01, review fold: A-m3 / B-m2): LLVM's own
assertions (the CMake LLVM is Release), gtest unit tests, lit tests, fuzzers,
install_test.py, clang_runtimes_test and every other Bazel-only target, the
correctness of Bazel's BUILD dependencies and layering (ninja's generated graph
does not enforce them), the four prek hooks the environment skips
(`fix-cc-deps`, `check-build-graph`, `check-bazel-mod-deps`,
`forbid-llvm-googletest`), the opt-mode conformance toolchain, clang-tidy,
macOS, Windows, ASan and other platforms. R33 (b) owes R21's hosted gate on
everything landed under R33 when Actions returns, and each landing's record
names the skipped hooks.

### §0.10 The id re-scan

`git grep -E 'W-3[6-9][0-9]'` over fork/ of 168 refs (every origin ref and
local branch, after `git fetch origin`) and `grep -r` over the fork/ of the 23
worktrees: W-360 to W-366 are in use (W-364 reserved unused by OV-4; W-365 and
W-366 SAFE-3's); W-367 appears only as plan text on
claude/carbon-fork-0-1-safe and claude/carbon-fork-0-1-safe-wip
(fork/safe/safe3-plan.md, "so W-367 stays free"), never as an item; W-398 and
W-399 appear only as range bounds in five plans' text; W-368 to W-397 appear
nowhere. W-357 to W-359 are RG-1's and W-364 OV-4's, reserved unused. The next
free id is W-367 (D-LAND-13). Rev 2's re-scan (2026-11-01 19:00 UTC, every
origin ref, local branch and worktree, pattern `W-3(6[7-9]|70)`) finds W-367 to
W-370 only in this plan on land-prep and W-367 only as safe3-plan.md's text on
the local safe branch (now db91f602a), the safe-wip mirror and
/home/user/carbon-safe; no ledger files any of them.

### §0.11 Stacked PRs and GitHub's merged state

GitHub marks a PR merged when a push to its base branch makes the PR's head
commit reachable from that branch; a merge commit of the head into trunk does
so for a PR whose base is trunk. PR 64's base is claude/carbon-fork-0-1-tp and
PR 65's claude/carbon-fork-0-1-dr (section 0.1), so a push of trunk that
contains their heads does not reach their bases. The safe order, which holds
whichever way GitHub treats a later retarget: the parent lands and is pushed
and the API shows it merged; the orchestrator then changes the child's base to
trunk (`update_pull_request` with `base: trunk`) and confirms it with
`pull_request_read`, so the child's diff shows its own commits; the child
lands and is pushed; the API shows it merged. Not measured: whether GitHub
marks a PR merged when it is retargeted to a base that already contains its
head; the order above never relies on it, and the first landing (PR 67, base
trunk) measures the plain case (D-LAND-11).

### §0.12 Disk

`df -h /home/user`: 3.7 GB available at rev 1, 3.5 GB at rev 2; /dev/shm: 16 GB
tmpfs. The landing build directory is 159 MB and builds in place; a
conformance output directory is about 2 MB (the mall's 1.8 MB) and the
runtimes cache 8.7 MB. No build directory is copied. Rev 2's dry-run worktree
is removed after the plan's commit.

### §0.13 The register checks at upstream's tip

Added 2026-11-01 (review fold: B-M2). PR 67 lands RG-1's check scripts and
tables (fork/register/check_quotes.sh with rg1-quotes.tsv, check_greps.sh with
rg1-checks.tsv), which passed in full at e6fddcf97 (273 quotes, 89 silence
checks; rg1-plan.md's landed notes). At upstream trunk 68569d234
(2026-11-01 06:22 UTC), run by SAFE-3's re-think at 17:46 UTC (scratchpad
safe3/rethink/logs/pr67-checks.txt), they report "checked 273 quotes, 8 failed"
and "checked 89 silence checks, 2 failed". Upstream moves, so a check at the
day's tip can fail; RG-1's W-355 owns re-reading those rows at each weekly
check. Rev 1's "the upstream tip at which the checks pass" invites choosing an
old tip; D-LAND-19 replaces it.

## §1 Decisions

**D-LAND-1, the ready set and the land order.** Twelve PRs land, in the
recorded order with the gated PRs skipped: PR 67, 51, 52, 54, 55, 58, 61, 62,
64, 63, 65, 68. Each is correct by R33 (a): its reviews are dry (section 0.1),
its land-time steps that apply to the trunk it lands on are made by the
landing (section 2), and its merged trunk is verified before the push; the
abort on a template's assignment that PR 61 and PR 64 reach is not theirs, by
D-LAND-22 (added 2026-11-01, review fold: RR4-1). The
recorded order is kept among them; no records-only PR is moved, because each
plan's merge rules assume the earlier ones. RG-1's section 5 says the sequence
"does not skip" a waiting PR "because each later PR's records and merge-trees
assume the earlier ones"; the dry run replaces that assumption by measurement
(sections 0.5 and 0.6), and every plan whose merge position assumed a gated
PR names its own break condition for a changed order: TP-1's D-TP-19 ("if the
merge order of record changes, the merge position is decided again"), SV-1's
D-SV-15 ("the dry runs of §8.6 are repeated against whatever has landed, and
only the textual rules change"), DR-1's D-DR-20 and OV-4's section 3 (M names
the trunk "that then holds PR 51 to PR 67"). LAND-1 decides those positions
again here, and PR 67's records commit marks RG-1's sentence superseded
(section 2.1). _Break condition:_ a landing whose gate or conformance fails
because a gated PR is absent, or a review that finds a ready PR incorrect
without a gated PR; that landing stops (D-LAND-10) and the order is re-planned.

**D-LAND-2, PR 59 and PR 66 are gated.** R33 (c): "a PR that is not yet
correct, one with an owed fix ... is not merged until it is". Trunk's Next
actions item 13 owes PR 59 a fix "under its own review" for an abort where
trunk diagnoses, and note 7's defect A is a second abort on VA-1's own forms
awaiting a ruling (section 0.2); the fork has treated such an abort as a defect
fixed at the root before a PR is held (TP-1's X-1, row :1104). PR 66 contains
PR 59's commits and carries both. The fix's owner is VA-1's workstream: a new
commit on PR 59's branch under VA-1's review, with VA-2's hand-off notes 7 and
9 as its spec (amended 2026-11-01, review fold: B-m8). The class is an abort
whose root lies in the PR's own scope, as X-1's lay in TP-1's D-TP-11 and
TR-13 and item 13's lies in VA-1's packs; an abort whose root is a
trunk defect that trunk reaches on the same operation and that a PR's plan
filed as out of its scope before the PR was held is not the PR's (D-LAND-22;
added 2026-11-01, review fold: RR4-1). _Break condition:_ the
orchestrator rules, with the evidence on record, that item 13 is not a defect
of PR 59 (for example, that upstream's own toolchain at its tip aborts the
same way), and records why in ORCHESTRATION; PR 59 then lands as G-59/66
describes without the fix.

**D-LAND-3, land-time commits are made on trunk.** Each plan's land-time
merge of trunk into its branch (M, M-a, M-b, the integration commits) becomes
the trunk-side merge commit of the PR's head, whose tree is the same; its
compositions, refills and records become trunk-side commits after the merge,
with the plan's texts. No commit is added to a ready PR's branch, so no held
branch is pushed by LAND-1 and every PR's history is untouched (AGENTS.md).
_Break condition:_ a plan step that only its branch can carry (none found).

**D-LAND-4, steps that compose with a gated PR move to its follow-on.** A
ready PR's land-time step whose object is a gated PR's code, page, golden,
ledger item or decision is not made at the ready PR's landing; it becomes a
land-time step of the gated PR's follow-on, with the same text, named in that
follow-on's Next actions item by Appendix B.1 (section 3). The moved steps:
TP-1's S (over SC-1) with its mutant M18 to G-60 and its VA-1 compositions
(F6's, measured none) to G-59; OV-4's SC-1 arguments in M to G-60 and its
VA-1 gate order to G-59; SV-1's M-VA and W-284 (with its `blocked_by` W-219)
to G-59, and its Doc-M (optional.md and the F-015 paragraph), C.5's W-177
evidence, C.8's
F-015 references, the W-177 cite in match_core_optional_diff.carbon's header
and F-M's PR 57 part to G-56/57; CT-1's S-VA with C.11's split and its mutant
M18 to G-59 (the two M18s added 2026-11-01, review fold: RR2-1); DR-1's
loops.md rule in M-a to G-56 and L-a's m57 refills to G-57; DD-1's state-L
texts for PR 53, PR 56 and SC-1 to their follow-ons; ST-1's SAFE-1
reconciliation edits to G-53; RG-1's land-time notes for PR 57 and PR 59 to
G-57 and G-59, with W-343's discharge (D-LAND-15). (Amended 2026-11-01, review
fold: B-M6.) The completeness audit added these moved steps, each named in
Appendix B.1's item 14 to 17 (added 2026-11-01, ruling fold: the AUD ids
named): to G-53, ST-1's re-reads of the pages SAFE-1 moves (arithmetic.md's
Strings section and values.md:168, c3cdecc5d fork/string/plan.md:2835-2838,
with W-057's evidence re-cited; AUD-55-22), the W-148 id restored where PR
55's landing wrote its title (AUD-55-11), and SAFE-2's DR-1 note on
`IndirectIndexWith.Ref` under W-144 (14c1ac8ac
fork/safe/safe2-plan.md:1174-1190), whose premise "PR 65 lands after PR 53"
LAND-1's order reverses (AUD-65-F2); to G-60, TP-1's M rules for SC-1's
hunks (66aa13132 fork/ORCHESTRATION.md:1091-1094, fork/templates/plan.md:1395
and :5194-5195; AUD-61-T06), CT-1's composition
with PR 60 and its break conditions (551a03328
fork/cpp-templates/plan.md:814-851; AUD-64-a5) and DR-1's call.cpp and
convert.cpp test of SC-1's added lines (fee0ef31c
fork/direction/plan.md:712; AUD-65-A15); to G-56/57, OP-2's fold of W-197
into W-126, due once PR 51 has landed (e23113ba2
fork/optional2/plan.md:1374-1376, fork/ORCHESTRATION.md:725-730;
AUD-51-E20), CT-1's composition with PR 57 (551a03328
fork/cpp-templates/plan.md:832-840; AUD-64-a6), DR-1's error_handling.md
rule, both sides' amendments in date order, and row 78's DR-0 sentence kept
beside PR 57's DONE text (fee0ef31c fork/direction/plan.md:708-709,
:1635-1639; AUD-63-11 / AUD-63-12), W-323's discharge note (:3441;
AUD-63-21), SV-1's nested-pointer leg of cpp_sum_type_roundtrip_diff with
its oracle and the conditional refill of fail_todo_core_optional.carbon
(0ef8a0334 fork/sumtype-interop/plan.md:1948-1964; AUD-62-S09), and Doc-M's
texts re-derived under SV-1's section 1.14 document review (:2350-2353;
AUD-62-S12); to G-59/66, SV-1's mutants M19 and M21 with M-VA (the landed
notes' item (b); AUD-62-S06), W-284's clauses in C.6 to C.9 and A.3's row
(AUD-62-S23) and DR-1's call.cpp and convert.cpp test of VA-1's added lines
(fee0ef31c fork/direction/plan.md:711; AUD-65-A15). C.5's W-177 note was
withdrawn at W-322 (0ef8a0334 fork/sumtype-interop/plan.md:9250-9255), so
only its evidence moves (amended 2026-11-01, ruling fold: AUD-62-S12).
_Break condition:_ a moved step whose absence makes a ready landing's gate
fail (D-LAND-1's).

**D-LAND-5, the merge rules.** Measured on the dry run and applied by the
implementer by hand, the saved files in `$X` being the reference (amended
2026-11-01, review fold: A-B1 / A-M1 / A-m1):

-   OR-1: ORCHESTRATION's header region takes trunk's side; the records commit
    restamps the header.
-   OR-2: Branches rows are merged row by row by their first cell; a row both
    sides changed takes trunk's; the records commit rewrites the landed row.
    Where the merge keeps two rows with the PR's branch in the first cell,
    trunk's stale row and the PR's own, without a conflict (measured: two tp
    rows at d03be4456 fork/ORCHESTRATION.md:1733 and :1736, two ct rows at
    e21480b05), A.3's row replaces both, as TP-1's item 7 and CT-1's item 6
    drop trunk's stale row (66aa13132 fork/ORCHESTRATION.md:1101-1103,
    551a03328 :1231-1233; amended 2026-11-01, ruling fold: AUD-61-T05).
-   OR-3: dated paragraphs inserted on both sides are both kept, in date
    order, the PR's first on the same date (it predates trunk's stamp of it);
    each side's inserted block of dated paragraphs is kept whole and placed by
    its first paragraph's date, the PR's block first on the same date, as the
    dry run's merges place them (amended 2026-11-02, PR 61's landing, review
    round 1: RB61-3; ruling (12): PR 61's block, first dated 2026-10-14,
    precedes trunk's paragraphs of 2026-10-15 to 2026-10-21, and PR 64's and
    PR 65's blocks are placed the same way).
-   OR-4: a region both sides edited takes trunk's side (the newer
    orchestrator text); the region report lists the PR side's words trunk
    lacks.
-   OR-5: in an OR-4 region of the Next actions, each item the PR side added
    is either carried by the records commit, verbatim with a dated carry mark,
    or named in the records commit's message as discharged by the landing (a
    PR's own "at land time" item, whose steps the landing makes or D-LAND-4
    moves); section 2 and Appendix C list which, landing by landing.
-   DL-1: decision-log entries inserted at one point are both kept, trunk's
    first, in the log's workstream grouping, except where DL-2 or DL-3
    decides. DL-2 (added 2026-11-01, ruling fold: AUD-54-12 / AUD-55-02 /
    AUD-61-T04): the landed region after the entry "Full autonomy and the
    throughput protocol (2026-09-27)" is newest first, and PR 52's, PR 54's,
    PR 55's, PR 58's and PR 61's heads each put their entry directly after
    that entry; their plans place it there at land time, above every entry
    landed before it (EV-1's section 2.F.3, cb3ef2e74
    fork/evaluator/plan.md:1744-1746, "above CM-1's or SAFE-1's if either
    has merged"; ST-1's item 5, c3cdecc5d fork/ORCHESTRATION.md:530-532;
    DD-1's "first in the landed region", fcee90d9b
    fork/designdocs/plan.md:340; TP-1's, 66aa13132
    fork/templates/plan.md:18347-18349; CM-1's "above SL-2" holds there).
    So at those five landings the PR's entry goes directly after that
    entry, above trunk's: step 9 checks that its heading is the first
    level-3 heading after that entry's. The dry run applied DL-1 there (CM-1 at
    :3397, EV-1 at :3690 and ST-1 at :4378 of 8beb5d7d5, DD-1 at :5056 of
    a33d05cae, after OX-1's), so `$X`'s decision-log files from PR 52 to
    PR 58 differ from DL-2's in the entries' order only, and at PR 61 a
    decision-log region the dry run did not have is predicted (TP-1's
    entry and trunk's DD-1 entry at one point), which DL-2 decides; step 3
    records both. DL-3: the order at the DR-0 group
    is DR-0, DR-1, RG-1, LD-0, as D-RG-14 implies (RG-1's after DR-0's and
    DR-1's; LD-0 the newest): at PR 67 RG-1's entry goes before LD-0, and at PR
    63 DR-1's goes directly after DR-0's, before RG-1's (`$F/bin/dlorder.py`).
    DL-4: where a PR's head appends paragraphs to an entry whose end trunk has
    given a Landed sentence (A.6), the PR's paragraphs go first and the Landed
    sentences stay last, in landing order (predicted at PR 65 for DR-1's entry).
    DL-5 (added 2026-11-01, review fold: RR4-2): at PR 65, DR-0's register
    block, where PR 63's records commit appended the (i) sentence of
    Appendix C.11 and DR-1b's side appends its "(ii) resolved" sentence at
    the same point, after "(iii) resolved 2026-10-21 by DR-1a, d0cfe8082
    and its fill c1cc72a09.", keeps both, (i) first, in Appendix C.12's
    four lines, with trunk's re-check paragraph after it unchanged (measured
    by merging a copy of f2110e0fd's log with the (i) sentence against
    fee0ef31c's over 89aabd125's: one conflict, this region;
    `$F5/rr4-2/`).
-   PL-1: where a PR's plan file gains a section after the section to which
    trunk appended a Landed paragraph (A.5), trunk's paragraph stays at the end
    of its own section and the PR's section follows (predicted at PR 65 for
    fork/direction/plan.md).
-   GA-1: gap rows merge row by row; a row one side changed takes that side; a
    row both sides changed keeps both edits when the word merge succeeds.
-   GA-1b: a row both sides changed whose word merge fails is composed in the
    merge: the PR's row, with each clause trunk added since the merge base
    carried verbatim where it does not overlap the PR's text, and a trunk clause
    the PR's text supersedes dropped only where section 2 names it. Never
    trunk's row whole. Section 2 gives each such row's composition.
-   GA-1c: a row whose PR plan recomposes it at land time (TP-1's R for row 54
    at PR 61, SV-1's R by C.7's fallback for row 68 at PR 62, CT-1's C.4 for
    rows 42 and 56 at PR 64) takes trunk's row in the merge, and the records
    commit writes the plan's text over it.
-   GA-2: the header and the prose sections (never a row) edited on both sides
    take trunk's side in the merge; the records commit writes the PR's text
    for them as section 2 says and the header from the measured `<tally>`.
-   LG-1: ledger items merge by id; an item one side changed takes that side;
    a new item is inserted after the last item with a smaller number;
    `json.load` must pass. This id order is the place the plans' "after the
    then-last ledger item" asks for (ST-1's item 5, c3cdecc5d
    fork/ORCHESTRATION.md:535-536; TP-1's item 7, 66aa13132 :1095-1100):
    the ledger is kept in id order, so a later block goes after the last
    smaller id, not after W-356 (recorded 2026-11-01, ruling fold: the
    audit's S55-07 and T03 notes). LG-2 to LG-6: an item both sides
    changed keeps
    both edits: disjoint words merged, lines both appended kept trunk's then
    the PR's, list elements unioned, a PR insertion placed after trunk's edits
    at that point. LG-7: CT-1's W-043 rule (section 2.9) overrides LG-5.
-   README-1: fork/conformance/README.md takes trunk's side and its program
    table is regenerated by `runner.py --update-readme-table` (DR-1's rule).
-   PROG-1: CT-1's C.6 for its two programs (section 2.9).
-   TC-1 and TC-2: DR-1's M-a and M-b for handle_loop_statement.cpp and
    handle_index.cpp (sections 2.10 and 2.11).
-   GOLD-1: CHECK-only regions take trunk's side, and the refill commit
    recomputes them (D-LAND-8).

_Break condition:_ a region no rule decides, or a non-records conflict no
plan names: the landing stops (D-LAND-10).

**D-LAND-6, the per-merge procedure** in /home/user/carbon-trunk, for PR N
with head H, by the implementer (section 2's subsection gives N's specifics;
amended 2026-11-01, review fold: A-M2 / A-M4 / A-m3 / B-B1 / B-M4 / B-m2).
Where section 2 interleaves steps 6 and 7, section 2's order governs (at
PR 64 the rename commit, the refill, the comment commit, then L, in the
order of section 2.9; at PR 65 C-b, the probes, the rename commit, then the
refill, in the order of section 2.11), and each commit of steps 6 and 7 is
still gated before it is made (added 2026-11-01, review fold: RR3-3):

1.  `git fetch origin`; confirm `git ls-remote origin` shows H for PR N's
    branch (a moved head stops the landing) and trunk where the last push
    left it; `pull_request_read` for PR N gives `<base>`, which must be
    `trunk` (another base stops the landing; added 2026-11-01, review fold:
    RR1-6).
2.  `git checkout trunk && git pull --ff-only`; then, in a scratch worktree
    under /dev/shm, `git merge-tree --write-tree --name-only` of H and of each
    later ready head onto the pushed trunk, recorded with the differences
    from `$X/pr<N>/conflicted.txt` (A-M4's re-run).
3.  `git merge --no-ff --no-commit H`; resolve each conflicted file by
    D-LAND-5, comparing with `$X/pr<N>/`; then
    `git diff --name-only --diff-filter=U` is empty; prek (the command of
    hand-off note 6) on the resolved files to a fixpoint, its changes part of
    the resolution; `git add` each resolved path by name (R20). A conflicted
    file or region not in `$X` with a rule that decides it is recorded in the
    merge message as `not in the dry run`; one no rule decides stops the
    landing.
4.  `$CB/build.sh /home/user/carbon-trunk` and `$CB/install.sh
    /home/user/carbon-trunk`; `$CB/gate.sh /home/user/carbon-trunk`;
    `XDG_CACHE_HOME=/home/user/carbon-build/carbon-trunk/cache
    $CB/conformance.sh /home/user/carbon-trunk <out>` with `<out>` under
    `scratchpad/land1/impl/pr<N>/`, outside the repository. This gate may
    report, besides "Autoupdate would make changes", a `fail_`-prefix
    problem (testing/file_test/file_test_base.cpp:131-160) only for a split
    that section 2 names as renamed by a land-time commit of this landing,
    which is expected at PR 64 and PR 65 (sections 2.9 and 2.11); it is
    counted in A.1's `<g0>` and `<gn>`, and step 6's rename commit resolves
    it. Any other failure of this gate that autoupdate cannot fix stops the
    landing (added 2026-11-01, review fold: RR2-4).
5.  Commit the merge with Appendix A.1's message, the results of step 4 in it.
6.  The plan's land-time code, page and program commits, if section 2 lists
    any, each brought to a prek fixpoint before its commit, then built, gated
    and committed with section 2's message. For each markdown file such a
    commit edits, R31's counts before the edit, after it and after prek
    (`r31.py`) go in its message, unchanged but for the headings, list items
    and rows the commit's own text adds or removes, as TP-1's section 8 item
    6 (66aa13132 fork/templates/plan.md:6008-6017) and DD-1's state-L check
    (fcee90d9b fork/designdocs/plan.md:5592-5599) ask (added 2026-11-01,
    ruling fold: AUD-61-T18 / AUD-58-U2).
7.  Refill: if the gate after step 6's commits (step 4's when section 2 lists
    none) reports "Autoupdate would make changes", run
    `$CB/autoupdate.sh /home/user/carbon-trunk <files>` on exactly those
    files, gate again (every golden passes) and commit Appendix A.2's refill
    commit (D-LAND-8). A failure of any other kind in the gate after the
    landing's last rename commit, a `fail_`-prefix problem among them, stops
    the landing; where section 2 names no rename commit, that gate is the one
    after step 6's commits (amended 2026-11-01, review fold: RR2-4 / RR3-3). A
    gate before the last rename commit (step 4's, and at PR 65 C-b's) may
    report, besides "Autoupdate would make changes", only the `fail_`-prefix
    problem step 4 allows for the split that rename commit renames; any other
    failure there stops the landing. At PR 61 and PR 64, D-LAND-20's mutants
    run after this step (added 2026-11-01, review fold: RR2-1). Then prek on
    every other file the landing changed
    (`git diff --name-only <trunk before>..HEAD`): a change there is a defect
    of the PR's head, which stops the landing (D-LAND-10).
8.  Conformance on the landing's final code tree (again if steps 6 or 7
    changed a program, the prelude or the toolchain), DD-1's checker from PR
    58 on (`python3 -I fork/designdocs/check_samples.py` and the same with
    `--toolchain /home/user/carbon-build/carbon-trunk/install/bin/carbon`,
    both 0 errors) and EV-1's from PR 54 on (`python3 -I
    fork/evaluator/check_samples.py`, 0 errors); then D-LAND-18's stop rule.
9.  The records texts (D-LAND-9), edited in the worktree and not yet
    committed, then: prek on each edited file to a fixpoint; R31's counts of
    each edited markdown file before the edit, after it and after prek
    (`r31.py`); `json.load` of the ledger; `runner.py --self-test`; the
    model-identifier grep of `git diff <trunk before>`; the gap-row check
    `python3 -I $F/bin/rowcheck.py <trunk before> H WORKTREE <rows>` with the
    rows section 2 names, which must report 0 missing; the rows named being
    also, by rowcheck.py's own rule (a row a plan rewrites, section 2), every
    row that a land-time commit section 2 prescribes or a records text
    Appendix C gives rewrites, each listed in the implementer's report with
    the commit or text that rewrites it and verified by the review against
    the plan's text, a missing segment of any other row stopping the landing
    (amended 2026-11-02, the orchestrator's ruling under R29 at PR 55's stop,
    the second of the class after PR 54's paragraph (5)); at PR 52, 54, 55, 58
    and 61, DL-2's check of the entry's place; and the re-read of
    fork/ORCHESTRATION.md's four regions, the header, the dated paragraphs,
    the Branches table and the Next actions, against `<trunk before>`'s
    (`git diff <trunk before> -- fork/ORCHESTRATION.md`): every row,
    paragraph and item there before is there once, and each change is the
    merge's or a text this plan gives, OV-4's R-5 check
    (097c76473 fork/overload/ov4-plan.md:1991-1996) at every landing (added
    2026-11-01, ruling fold: AUD-68-19); the edits saved as
    `records.patch` beside the logs. The edits hold `<merged_at>` and
    `<api sha>` unfilled.
10. The review (D-LAND-10) of the commits of steps 5 to 7, the logs and
    `records.patch`.
11. Phase 1: `git push origin trunk` and `git push origin
    trunk:claude/carbon-fork-0-1-7mwfb7` (fast-forwards; the records edits
    are uncommitted, so only the reviewed commits go); then
    `pull_request_read` for PR N must return `merged: true`, and its
    `merged_at` and `merge_commit_sha` are recorded.
12. Phase 2: fill `<merged_at>` and `<api sha>`, check that `git diff` differs
    from `records.patch` in those two values only, prek again to a fixpoint,
    commit the records commit (section 2's message) and push trunk and the
    mirror as in step 11. The records commit's message states 'records written
    <date> <hh:mm> UTC, committed <now> UTC' (added 2026-11-02, RV67-2 and
    FC2-3, the orchestrator's ruling under R29).

Every commit: `--author='jmann345 <jerrymannstan@gmail.com>'`,
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`, a new
commit (never an amend, rebase or force-push), explicit paths only, the
message ending after a blank line with `<trailers>`. Each records commit's
message names prek's result and its SKIP set. _Break condition:_ none; the
procedure is the rule's.

**D-LAND-7, verification and the baseline.** Before PR 67, stage 0 runs step
4 on trunk itself (bb9fbba9c plus Appendix B.1's stamp, which changes no
toolchain file): expected 1942 of 1942 and 128/0/22 over 150 with 48 bullets,
as the README's validation measured on 0bdce60a5, whose toolchain is trunk's
(section 0.9), and the DONE-row exception set of section 0.7. Every landing
then runs the whole arbiter, records-only ones included (about 5 minutes), so
every record has the same form. Results are labelled container-measured; by
R33 (b), "while hosted checks are unavailable, R9's scoreboard is the
arbiter's, labelled container-measured", and R21's hosted gate is owed on
every landing when Actions returns (amended 2026-11-01, review fold: B-m3).
_Break condition:_ the baseline differs from that expectation; LAND-1 stops
before PR 67 and the difference is the first finding.

**D-LAND-8, refills.** Only `autoupdate.sh` writes CHECK lines (R16), on the
files the gate names, to its fixpoint, in a commit of its own whose message
names each file and which PRs' changes combined in it; a refill that changes a
line other than a CHECK line, or a golden no merged PR or plan explains, stops
the landing. A rename a plan specifies before a refill (CT-1's C-2 at PR 64's
L-F, DR-1's L-b) is its own commit before the autoupdate, with the comment
edits the plan specifies with it in the same commit (DR-1's L-b rewords the
split's comment, Appendix C.12; amended 2026-11-01, review fold: RR3-1);
TP-1's F6 renames nothing (section 0.7; amended 2026-11-01, review fold:
RR1-1). _Break condition:_ none.

**D-LAND-9, the records texts** ("Land PR N: records", committed at step 12)
write Appendix A.3's row, A.4's dated paragraph and header, A.5's Landed
paragraph in the PR's plan, A.6's decision-log sentence, Appendix C's texts for
the landing (the plan's own land-time records texts, the OR-5 carries, the
GA-1c and GA-2 texts, the ledger notes and the Next actions marks), each at
the target Appendix C names, the gap header's first sentence by A.8 at every
landing, ORCHESTRATION's Scoreboard paragraph by A.9, and A.10's mark on each
landed gap row that A.10 lists. No free text is written: a text this plan
does not give is a stop (D-LAND-10). (Amended 2026-11-01, review fold: B-M5 /
A-B1 / RR1-5.) _Break
condition:_ a plan's land-time text that contradicts the merged trunk; the
records texts state the measured fact and cite the plan's line (R17), never
the stale text. A file:line cite inside a records text names the lines of the
tree the records commit produces, so a cite that the landing's own records
edit moves is written at its moved lines, and the orchestrator's landing-time
rulings with their plan amendments go in the landing's records commit
(amended 2026-11-02, fold check FC1-1 at PR 67, the orchestrator's ruling
under R29). A fork/gap-analysis.md line cite in the ledger or the decision log
names the tree of the date it carries (its entry's or its mark's), the rows
being named by their bullet text (R7); a later landing that moves the lines
does not re-pin it, and a landing re-pins only the cites its own texts write
or its own section names, measured on its records tree (amended 2026-11-02,
fold check FC55-1 at PR 55, the orchestrator's ruling under R29).

**D-LAND-10, the review and stop-and-amend.** Fresh agents review each landing
before phase 1: one for every landing, and two for PR 61 (TP-1's section 3
item 9, the merged head's implementation reviews A and B, both of which also
review L as its document review, item 11, because TP-1's section 2.9 says "L
is reviewed by a document review (two reviewers, R29(c))"; amended
2026-11-01, review fold: RR1-3). The review covers the merge
commit's diff against both parents (which is only the conflict resolution
against the PR's side), the code, page and refill commits, the logs, the
conformance comparison and `records.patch`, against this plan and the PR's
plan. A BLOCKER or MAJOR, a gate failure, a stop of D-LAND-18, an unanticipated
conflict or a moved head stops the landing before phase 1: the implementer
returns the difference and the orchestrator rules. A defect in the landing's
own commits is fixed by a new commit on top, reviewed again; a defect in the
PR itself is fixed on the PR's branch by a new commit under its own review,
the unpushed landing is discarded (`git reset --hard origin/trunk` in the
landing worktree only, nothing pushed), and the merge is redone on the new
head. A landing once pushed is undone only by a revert commit. _Break
condition:_ none.

**D-LAND-11, the push and GitHub.** Two phases (amended 2026-11-01, review
fold: B-M4 / B-m4): after a review with no BLOCKER or MAJOR, the implementer
pushes the merge and its code and refill commits (step 11), reads the API, and
only on `merged: true` commits and pushes the records commit that says LANDED
(step 12); the records therefore never say LANDED before GitHub does. If the
API does not return `merged: true`, the records edits are discarded (`git
checkout --` of the edited files), nothing more is pushed, and the
orchestrator rules; the pushed commits stay, and the next records text states
the API's answer. For PR 64 and PR 65 the orchestrator changes the base to
trunk after PR 61's and PR 63's phase 2, and confirms it, before their stages
start (section 0.11). _Break condition:_ GitHub does not mark PR 67 merged
after its phase 1; then every later landing re-measures the rule before
relying on it.

**D-LAND-12, the follow-ons.** Each gated PR lands by its own follow-on when its
gate is met, by LAND-1's procedure, in this order of preference: G-53 (PR 53)
when the realignment of PR 53's branch completed under the orchestrator's
re-ruling of the C++ boundary question (fork/safe/safe3-plan.md D-SAFE3-13
and its rev 11 and rev 12 fold records), its commits and reviews dry and PR
53's head pushed, and the PR 67 note commit the realignment owes is on trunk
as a records commit, since PR 67 has landed: SAFE-2's and SAFE-3's specified
commit, not the ledger alone, but the six items' notes in the ledger,
rg1-checks.tsv's widened H1.7, the eleven rows rg1-quotes.tsv gains,
rg1-plan.md's H1.7 and H1.13 with the counts (284 quotes, 89 checks) and
RG-1's decision-log entry (14c1ac8ac fork/safe/safe2-plan.md:1240-1270,
fork/safe/safe3-plan.md D-SAFE3-10 :2406-2418 and section 3 step 7
:3193-3213, whose own break condition, PR 67 landed first, puts it on
trunk). SAFE-3 stopped at its plan rev 12 (14c1ac8ac, 2026-11-01) under its
re-think ruling's break condition (RT1-B1 and RT2-B1: C++ code reaching,
from an address it receives, a Carbon place that the carrier closure does
not name); the orchestrator stamps that stop on trunk from safe3-plan.md
Appendix D's stop path after Appendix B.1's stamp; PR 53's pushed head
stays 2407efa74, and W-365 and W-366 stay reserved and unfiled (amended
2026-11-01, ruling fold: the ruling's item 2 / AUD-67-P29); G-60 (PR 60)
when W-139's fix commit is on PR 60's branch under SC-1's reviews and item
10 is decided; G-56/57 (PR 56, then PR 57) when W-352's commit is on PR
56's branch, merged into PR 57's, under OP-1's reviews,
and item 10 is decided; G-59/66 (PR 59, then PR 66), owned by VA-1's workstream,
when item 13's fix (W-367, filed on PR 59's branch) and note 7's ruling are on
PR 59's branch under VA-1's review and VA-2's item 2 preconditions hold. A
follow-on whose merge carries code compositions (G-60, G-56/57, G-59/66) first
merges trunk into its own branch (a new merge commit, never a rebase) with the
moved steps, fills and gates them under its own reviews and pushes, so its trunk
landing is records-only. No follow-on waits on another except PR 57 on PR 56 and
PR 66 on PR 59. Appendix B.1's items 14 to 17 name every moved step (amended
2026-11-01, review fold: B-m8). _Break condition:_ a follow-on's plan that
requires a different order; the orchestrator rules and this plan is amended.

**D-LAND-13, ids.** LAND-1 takes W-367 to W-370 from the re-scan: W-367 for
item 13's abort, filed by G-59/66 in PR 59's branch's ledger
(fork/inventory/work-items.json on claude/carbon-fork-0-1-va) by a records
commit beside the fix, so the fix commit cites an item on its own branch and
the item reaches trunk with PR 59; W-368 for note 7's defect A if the ruling
makes it a PR 59 fix, filed the same way (otherwise unused); W-369 and W-370
for a residue a landing finds, filed in trunk's ledger by that landing's
records commit, or, under D-LAND-22's break condition, W-369 in TP-1's
branch's ledger (fork/inventory/work-items.json on
claude/carbon-fork-0-1-tp) by a records commit beside the fix, as W-367 is
filed (otherwise unused; amended 2026-11-02, review fold: RR5-2).
Appendix B.1 records the reservation, so
SAFE-3, whose plan text keeps W-367 free, takes W-371 onward (amended
2026-11-01, review fold: B-m8): W-371 stays the next id of PR 53's
realignment, SAFE-3 having stopped with W-365 and W-366 reserved and
unfiled; rev 6 mints nothing (amended 2026-11-01, ruling fold: the
ruling's item 2). _Break condition:_ any of W-367 to W-370 filed
elsewhere first; LAND-1 then takes the next free id after a re-scan.

**D-LAND-14, DD-1's state L in part.** DD-1's section 2.13 applies "after
merging trunk with every held PR on it". At PR 58's landing the state-L texts
for PR 51, PR 54 and PR 55 are made, split by PR where one text covers two:
the held-PR citations of W-127, W-155 and W-167 lose "held", the EV-1
sentences, the literals.md note (PR 55), the README disclosure sentence
narrowed to the section PR 53 still owes, and the `ALLOWLIST` entry for
arithmetic.md's "Strings" removed, with DD-1's section 2.14 evidence
amendments for those three PRs (W-014, W-127, W-155, W-167) and row 91's
pending clause marked; the verbatim texts are in section 2.6 and Appendix C.7,
and the dry run's checker passes on them (section 0.5). The texts for PR 53
(assignment.md, threads_and_atomics.md, mutation_safety.md, the README's full
state-L sentence and the dropped "held PR" definition, the PR 53 `ALLOWLIST`
entry, W-188's notes), PR 56 (the interop pointer to optional.md) and SC-1
(template_constraints.md) are made by G-53, G-56 and G-60; until then their
state-T texts, which name the held PRs, stay true, and row 91 stays PARTIAL.
From PR 58's landing on, every landing runs both checker modes (D-LAND-6
step 8). (Amended 2026-11-01, review fold: A-M2 / B-B1.) DD-1's D-DD-9 break
condition fires, since PR 58 lands before SC-1 and PR 53 (fcee90d9b
fork/designdocs/plan.md:638-644): it would file W-187 "to apply the state-L
texts and ledger amendments and flip row 91 when those PRs land". The
follow-ons' Next actions items 14 to 16 carry those steps by name and row
91's mark names them, so W-187 stays unused, and PR 58's A.5 and A.6 say so
(Appendix C.7; added 2026-11-01, ruling fold: AUD-58-U4). _Break condition:_
a state-L text that cannot be split by PR; it then waits whole for the last
follow-on, and the checker's `ALLOWLIST` keeps its entry until then; or a
follow-on abandoned, and the orchestrator's stamp then files W-187 with the
texts that follow-on carried.

**D-LAND-15, W-343.** RG-1 narrowed W-343 to five land-time notes, discharged
by the last (rg1-plan.md:500-504). PR 51's, PR 54's and PR 58's are made now,
each after the text anchor Appendix C names (amended 2026-11-01, review fold:
B-M5); PR 57's and PR 59's by G-57 and G-59, and whichever lands last
discharges W-343. Each note is the text after its locator line (the
bracketed "[UA-2, PR 51, after its :6232]" and the like are not written:
UA-2's note is rg1-plan.md:2534-2542, EV-1's :2545-2550, OP-2's
:2553-2560, DD-1's :2563-2570 and VA-1's :2573-2583), with "..." replaced
by UA-2's lead as A.4 says (:2588), `<tip>` D-LAND-19's, and every
"2026-10-27" read "2026-10-28", the entry's title included, by RG-1's own
date rule (56e2e5bbd fork/register/rg1-plan.md:1076-1079 and its landed
notes' Dates, :3479-3482), so the lead names the heading trunk holds after
PR 67, "RG-1: the V-3a register classified at f27a977d8 (2026-10-28)"
(56e2e5bbd fork/decision-log.md:277), and every pushed H-note's
"classified 2026-10-28" agrees (added 2026-11-01, ruling fold:
AUD-67-P25 / AUD-51-E16 / AUD-58-U8). _Break condition:_ a follow-on
abandoned; the orchestrator's stamp then discharges W-343 by RG-1's own
break condition (:504-506).

**D-LAND-16, the orchestrator's steps** (amended 2026-11-01, review fold: B-m4
/ B-m6). Before stage 0: sign-off of this plan by its reviews; then one push
of land-prep's commits (the signed-off plan) and Appendix B.1's stamp commit
to trunk and the mirror by fast-forward, so every record that cites
fork/land/land1-plan.md finds it on trunk. Per landing: the retargets of
D-LAND-11 and the PR's description, prepended with Appendix A.7's Landed line.
After the twelfth: Appendix B.2's stamp. The implementer does everything else
in section 3, including both pushes and the API reads. _Break condition:_
none.

**D-LAND-17, the committed conformance scoreboard** (added 2026-11-01, review
fold: B-m5). fork/conformance/out/scoreboard.json stays the last hosted
scoreboard: after PR 51's merge it is PR 51's hosted run 37413300832 (131/0/19
over 150, 2026-10-06), a record of that tree, which the file's own `generated`
and `toolchain` fields state. LAND-1 never writes it: the container
scoreboards are written outside the repository and quoted in each landing's
records, which are R9's record while hosted checks are unavailable (R33 (b));
the first hosted run after Actions returns regenerates it (R21). _Break
condition:_ a tool or a records text that reads the file as trunk's current
scoreboard; that reader is corrected, or the file is regenerated by a hosted
run.

**D-LAND-18, the conformance stop rule** (added 2026-11-01, review fold: A-M3
/ B-M3). R33 (a) requires "the conformance runner's scoreboard not regressing
against the PR's expected scoreboard". At D-LAND-6 step 8 the landing stops
(D-LAND-10) on any of:

-   (a) FAIL, the sum of COMPILE-FAIL, LINK-FAIL, RUN-FAIL, OUTPUT-MISMATCH and
    DIFF-MISMATCH, above 0;
-   (b) a program that PASSed in the previous landing's `scoreboard.json`
    (stage 0's for PR 67) and does not PASS now;
-   (c) a program the landing's tree expects to PASS (no `// SKIP:` directive,
    by name from `runner.py --self-test`) that does not PASS, or one with a
    SKIP directive that does;
-   (d) PASS, FAIL, SKIP or programs different from section 4's row, unless a
    land-time commit section 2 names accounts for each difference by name;
-   (e) a PASS delta over the previous landing different from section 4's
    expected delta, which is the PR's own recorded delta adjusted as section 4
    names;
-   (f) bullets PASS below the previous landing's count, or a bullet whose
    `gap_status` is DONE and whose `status` is not PASS, other than the
    baseline set stage 0 measures (R9).

The landing's record quotes each value. _Break condition:_ none; a difference
is explained by a named commit or it stops the landing.

**D-LAND-19, the register checks at the tip** (added 2026-11-01, review fold:
B-M2). Where a landing's text names an upstream tip (the RG-1 notes of PR 51,
PR 54 and PR 58, PR 67's W-355 note, PR 64's R32 comparison of F-021, OV-4's
L-R; PR 64's added 2026-11-01, review fold: RR2-1), `<tip>` is upstream trunk's
head on the landing day, fetched at the check, never a tip chosen because the
checks pass at it. Both scripts run over the whole tables there:
`fork/register/check_quotes.sh /home/user/carbon-lang <tip>
fork/register/rg1-quotes.tsv` and `fork/register/check_greps.sh
/home/user/carbon-lang <tip> fork/register/rg1-checks.tsv`, their counts
quoted in the records commit's message and each FAIL row appended by id to
W-355's notes (Appendix C.2's text, at every landing this decision names,
with that landing's PR number); a note whose own entries fail says so in
its lead (Appendix C.3), and so does a register row OV-4's L-R adds
(Appendix C.13; amended 2026-11-01, ruling fold: AUD-68-15). _Break
condition:_ none.

**D-LAND-20, the mutants at PR 61, PR 64, PR 65 and PR 68** (added
2026-11-01, review fold: RR2-1; PR 65 and PR 68 added 2026-11-01, ruling
fold: AUD-65-A11 / AUD-68-17). TP-1's landed notes item (c) judges M, S
and F6 "with §8's build, autoupdate, gate, conformance and mutants" (66aa13132
fork/templates/plan.md:7927-7928), and CT-1's item (c) ends L-F with "then the
gate, conformance and the mutants on the merged build" (551a03328
fork/cpp-templates/plan.md:4842). Both plans re-run a recorded mutant only
when a change can alter its result, TP-1 by file and CT-1 by function: TP-1's
round 3, "The other mutants of earlier rounds mutate files round 3 does not
change and are not re-run" (fork/templates/plan.md:6389-6390), and its
round 8, "none re-run by the fixer, as no toolchain file changes" (:7121);
CT-1's implementation-review fold re-ran "M1, M2, M6, M7, M15 and M22, the
mutants of the functions the fix touches"
(fork/cpp-templates/plan.md:3871-3872). The landing applies the file rule,
which for CT-1 is a superset of its function rule, to its merged build and
adds the killers (the rules' description amended 2026-11-01, review fold:
RR3-5): after step 7 (at PR 64 after L-F's
comment commit, section 2.9), the implementer re-runs each mutant the PR's plan
names whose edited file is in
`git diff --name-only <head> HEAD -- toolchain core ':!*/testdata/*'`, or one
of whose named killers this landing's refill commit changes or a rename commit
renames. Each is the edit its plan's last
record of it ran (CT-1's `.diff` files in scratchpad/ct1-impl/fixer/mut/ for M1,
M1c, M2, M6, M7, M15, M22 to M26, M75 and M75r, and in
scratchpad/ct1-impl/stage4/mut/ for the others; TP-1's in the scratch of the
round that last ran it: scratchpad/tp1-impl/stage4/ for stage 4's mutants
(bin/mutate.py, bin/allmut.sh), scratchpad/tp1-fixer/ for the
implementation-review fold's (bin/relink.sh), scratchpad/tp1-rr/ for the
focused re-review rounds' (fixer-r1 to fixer-r9) and scratchpad/tp1-x1/ for
rounds 10 and 11's; amended 2026-11-01, review fold: RR3-5), applied to the
merged source, its translation units recompiled over
/home/user/carbon-build/carbon-trunk's objects and relinked into /dev/shm
(deleted after), and run over the whole gate, the programs and every probe
set its record ran, each probe set compared with the same set run on the
landing's unmutated install (added 2026-11-01, review fold: RR3-5). For the
six CT-1 mutants predicted at PR 64 that is the steps of their driver,
scratchpad/ct1-impl/fixer/bin/mutrun.sh, with carbon-trunk's worktree and
build in place of carbon-ct's: the gate, the programs and the 250 probes of
scratchpad/ct1-impl/fixer/logs/list_r1.tsv (`mut_<m>_r1.tsv`), and for M75
and M75r also the 403 of scratchpad/ct1-impl/stage4/list403.tsv
(`mut_<m>_mx.tsv`), as the records of 551a03328
fork/cpp-templates/plan.md:3866-3875 and :3891-3892 state them. A probe set
the landing does not run
is named beside its mutant in `<mut>` as not run, with the reason. Each must
reproduce its record: killed by its named killer, or, for a
mutant its plan records as surviving or reaching nothing (CT-1's M12, M1, M75
and M75r), the same again. Measured on the dry run
(`$F2/rr2-1_mutant_filesets.txt`): at PR 61 the file rule names none, because
TP-1's 32 non-testdata files and the merge's non-testdata changes from
66aa13132, core/prelude/types/string.carbon and toolchain/check/cpp/export.cpp
(PR 55's), are disjoint, and F6 and L change no source; at PR 64 it names the
six CT-1 mutants that edit convert.cpp, which PR 62 changes: M6, M7, M23, M24,
M75 and M75r, each of whose edits applies to e21480b05's convert.cpp
(`patch --dry-run`, `$F2/rr2-1_mutant_apply.txt`). No named killer of either
plan is in the merge's testdata diff from its head (at PR 64 that diff holds
the goldens of PR 51, PR 55 and PR 62 only); the killer rule's refill and
rename part is
measured at step 7. TP-1's M18 reverts S and CT-1's M18 S-VA, so each moves with
its step (D-LAND-4). Every other named mutant is not re-run and keeps its record
on the PR's head: section 6 lists them, and the PR's A.5 Landed paragraph says
so by C.8's and C.10's mutant sentences. Two more plans name land-time
mutants (added 2026-11-01, ruling fold: AUD-65-A11 / AUD-68-17). At PR 65,
DR-1's section 8 item 5 names "C-b at merge: the dependence check removed
(generic/template/index's `index_class_with_index_with` fails as on the
mirror before C-b)" (fee0ef31c fork/direction/plan.md:2648-2650): after
section 2.11's refill, C-b's `if` statement with its body (from `if
(OperandDependence(context, operand_type_id) ==` through its closing brace)
is removed from the merged handle_index.cpp, the hoisted `index_type_id`
declaration kept, the translation unit recompiled and relinked into
/dev/shm as above, and the gate run: it must fail on that split of check
generic/template/index and on nothing else. DR-1's other mutants of item 5
edit files the file rule does not name at this landing or mutate the
branch's state before C-b, and keep their records on fee0ef31c. At PR 68,
OV-4's section 8.8 runs section 8.5 on the merge commit (097c76473
fork/overload/ov4-plan.md:2368-2372): the file rule applies to the mutants
of section 8.5's record (:2146-2199) by their driver,
scratchpad/ov4-impl/fixer/mbin/mutants.py with run_mutant.sh, probe.sh and
norm.sh, over the gate and the probes its record ran; measured on the dry
run's 5cf7406f1, of the two files those mutants edit only
toolchain/check/call.cpp differs from 097c76473, so M1, M2 and M8 are
predicted, and M3, M4, M5 and M5b (handle_function.cpp) and M6 (B.1, a
program) keep their records. C.12's and C.13's mutant sentences record both
in A.5. _Break condition:_ a re-run mutant that
does not reproduce its record, or an edit that does not apply to the merged
source; the landing stops (D-LAND-10) and the PR's workstream rules by its own
break condition (CT-1's, "a mutant that turns nothing red other than M12, M1
(subsumed, with M1c killed) and M75", fork/cpp-templates/plan.md:3906-3911).

**D-LAND-21, the land-time id re-scans** (added 2026-11-01, ruling fold:
AUD-55-12 / AUD-61-T15 / AUD-61-T26 / AUD-63-15 / AUD-65-A10). Five plans
(six landings; amended 2026-11-01, review fold: RR4-6) prescribe an id
re-scan at land time: ST-1's for W-160 to W-167 (c3cdecc5d
fork/ORCHESTRATION.md:553-558, fork/string/plan.md:2305-2316), TP-1's three
commands, before L and before the records commit's ledger edit (66aa13132
fork/templates/plan.md:582-597), SV-1's section 8 item 7 (the landed notes'
item (f)), CT-1's item (e), and DR-1's section 8 item 10 for `W-32[4-9]`
at PR 63's and PR 65's records commits (fee0ef31c
fork/direction/plan.md:2773-2774, :5171, :5472-5473). The implementer runs
each with the plan's own command over every origin ref, local branch and
worktree after `git fetch origin`, at the points the plan names. Expected:
each of the PR's own ids is filed only on a ref on the PR's own line, one
that contains the PR's head or that the head contains, or that descends from
a commit the head contains which already files those ids and is an ancestor
of a ref that contains the head (each by `git merge-base --is-ancestor`: its
branch, a lagging local copy, a stacked child's branch or that child's lagging
copy, the landing's trunk; amended 2026-11-02, the implementer's stop at PR
61's re-scan before L, where CT-1's lagging local copy 4a3220c11, a descendant
of 5661a35c8 and an ancestor of 551a03328, filed TP-1's ids; the orchestrator's
ruling under R29), and named elsewhere only as plan
text; read
literally after step 5, TP-1's rule would re-allocate, because trunk then
holds TP-1's ids, and this reading replaces it. Any other ref that files one
of them as a ledger item is a collision: the landing stops (D-LAND-10),
because the re-allocation those plans prescribe rewrites texts already
published, which only a fix the orchestrator rules may do. Each run's
outcome is `<rescan>`, quoted in the records commit's message and written
by A.4, A.5 and A.6. Measured by the rev-6 fixer (2026-11-01, every
origin ref and local branch): W-160 to W-167 are filed only on origin's st
branch (c3cdecc5d) and on the local st branch and origin/pr/55, both at
21307851a, an ancestor of c3cdecc5d. _Break condition:_ a collision; the
orchestrator rules the re-allocation and this plan is amended.

**D-LAND-22, the template assignment abort at PR 61 and PR 64** (added
2026-11-01, review fold: RR4-1). Decided here under R29 on the measurement,
not left to the landing's review. The rev-7 fixer compiled four programs
with the existing installs, no build (`$F5/probe/`; each install's tree
differs from its PR's head in testdata only, by `git diff --stat` over
toolchain/ and core/). Each declares the class `V` below; lit is this file,
var has `fn G[template T: type](v: T, i: i64) { v[i] = 5; }` called as
`G(v, 0)`, nt_lit has `v[0] = 5;` in `Run` and no `G`, and rd_lit has
`fn G[template T: type](v: T) -> i32 { return v[1]; }` called inside
`Core.Print(G(v))`.

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
class V { var x: i32; }
impl V as Core.IndexWith(i64) where .ElementType = i32 {
  fn At(self, i: i64) -> i32 { return self.x + (i as i32); }
}
fn G[template T: type](v: T) { v[0] = 5; }
fn Run() -> i32 {
  var v: V = {.x = 5};
  G(v);
  return 0;
}
```

<!-- google-doc-style-resume -->

On trunk's install (0bdce60a5, trunk's toolchain at bb9fbba9c) and on UA-2's,
ST-1's, SV-1's, DR-1a's and OV-4's, lit is rejected (rc 1, "unable to
monomorphize specific `G(V)`", `V` not implementing
`Core.IndexWith(Core.IntLiteral)`), var stops at lower.cpp:48 (rc 134,
"Store operand must be a pointer"), nt_lit is rejected ("expression is not
assignable") and rd_lit is rejected as lit is. On TP-1's (eafca5cb9) and
CT-1's (224ee2f8f), lit and var stop at lower.cpp:48, nt_lit is rejected
the same way and rd_lit compiles. On DR-1b's own tree (7a442f632) lit, var
and rd_lit are rejected at monomorphization (W-340). The 2026.10.12 nightly
stops on var at lower.cpp:48. The root: outside a template, trunk's
assignment check rejects a left operand that is not a durable reference;
inside one, the operand's category is `Dependent`, which that check skips
(toolchain/check/handle_operator.cpp:110-118 at bb9fbba9c and 66aa13132,
"(lhs_cat != SemIR::ExprCategory::Dependent &&"), and nothing checks it when
the template is instantiated, so a value reaches lowering as a store's
address. That is W-259, filed by TP-1 as out of its scope before PR 61 was
held: "an assignment whose left operand is template-dependent is not checked
on instantiation for being an assignable reference" (66aa13132
fork/templates/plan.md:1743-1745, TR-21, and :1504-1509; its ledger entry).
Upstream's tip has the same check, the same quote at 68569d234
toolchain/check/handle_operator.cpp:110-118, and its nightly stops on var as
trunk does. Trunk's rejection of lit does not diagnose the assignment: it
is trunk's rejection of every literal subscript of such a type in a
template, the valid rd_lit included, which TP-1's change removes, as trunk
already compiles `v[1]` outside a template. So the abort that PR 61 makes
reachable from lit is W-259's, a trunk defect, and not a defect of PR 61's
change (D-LAND-2's class, as amended): X-1's root lay in TP-1's own
D-TP-11, whose class types formed in the definition reached an alternative
pattern through a deferred member access (66aa13132
fork/templates/plan.md:140-145, "TR-13 and D-TP-11 amended"), and item
13's in VA-1's packs, while TP-1's hunks in handle_operator.cpp change only
the `&` and prefix `*` handlers (:270 and :378 at bb9fbba9c) and leave the
assignment's handler (:97) as trunk has it. PR 61 and PR 64 land; PR 61's
records commit writes Appendix C.8's W-259 note, which records both forms
and widens W-259's break condition to them; W-369 stays unused, because a
second item for one root would duplicate W-259; the fix stays W-259's, in
the order W-014's notes give TP-1's next slice ("then W-255 and W-264, and
W-254 and W-259", 66aa13132 fork/inventory/work-items.json). The check at
the landings: at
PR 61, PR 64 and PR 65, D-LAND-10's reviewers compile the four programs on
the landing's install. Expected at PR 61 and PR 64: lit and var stop at
lower.cpp:48 with "Store operand must be a pointer", nt_lit gives
"expression is not assignable" and rd_lit compiles. Predicted at PR 65 the
same, since C-b makes `IndexWith` serve a template operand per specific
(fee0ef31c fork/direction/plan.md:1602-1606) and leaves the assignment
check alone; there, a form that is diagnosed instead is recorded on W-259 by
Appendix C.12's sentence. Any other result, rd_lit or nt_lit failing
otherwise or a stop anywhere but lower.cpp:48, stops the landing
(D-LAND-10). _Break condition:_ a landing's review finds a program that
`<trunk before>` compiles, or diagnoses for its own error, and the landing's
install aborts on, with the root in the PR's own scope; or the orchestrator
rules W-259's abort the PR's. Then PR 61 and PR 64 wait for a fix commit on
TP-1's branch under TP-1's review, W-369 filed with it as D-LAND-13 files
W-367, and stages 7 to 12 are re-planned.

## §2 Spec, per landing

Each subsection gives the head, the base, the files, the conflicts and rules
from the dry run, the steps, the expected scoreboard after the landing and the
rows the gap-row check names; the texts are in Appendix C. "Static" counts are
section 0.8's. The scoreboard values are section 4's.

### §2.1 PR 67, RG-1

Head 56e2e5bbd, base trunk; 8 records files. Conflicts: ORCHESTRATION (OR-1,
OR-2 twice, OR-3, OR-4) and decision-log (DL-3: RG-1's entry, then LD-0).
Steps: merge; no land-time step of its own (RG-1's A.4 notes are the later
PRs'); D-LAND-19's checks at the tip; records with Appendix C.2's texts: the
dated marks on rg1-plan.md section 5's "held at PR 53" and "does not skip it"
sentences and on W-343, W-355's tip note and item 6's RG-1 clause (amended
2026-11-01, review fold: B-M7 / B-M2), and, by the completeness audit, the
same mark on the six other lines that restate the superseded order, in
rg1-plan.md (:865-867, :1630, :1632-1633, :1679-1680, :1730-1732) and in
RG-1's decision-log entry (56e2e5bbd fork/decision-log.md:376-377), and a
dated mark on section 6's rejection of reordering PR 53, which D-LAND-1
supersedes under R33 without that rejection's break condition being met
("every other PR before PR 66 is otherwise ready to land", 56e2e5bbd
fork/register/rg1-plan.md:1704-1707, while PR 56, PR 57, PR 59 and PR 60
are not; amended 2026-11-01, review fold: RR4-3), and whose W-144
renumbering commit is moot, the
renumbering to W-151 being on PR 60's branch already (2f4ebbf6e; cc4daba00
fork/structural/plan.md:3111-3112; amended 2026-11-01, ruling fold:
AUD-67-P11 / AUD-67-P12); C.2's W-355 note limited to the landing, W-355's
owner keeping the L-check rule (AUD-67-P28). Expected: 1942 of 1942;
128/0/22 over 150; tally 30/21/4/1. Gap-row check: no row named. Next: PR
64's and PR 65's bases are unaffected.

### §2.2 PR 51, UA-2

Head f96fe8a7a (the container fill), base trunk. Conflicts: gap-analysis
(GA-1, the Slices row keeps trunk's DR-0 sentence and UA-2's W-108 narrowing),
ledger (LG-1, 14 decisions). Steps: merge; D-LAND-19's checks; records with
RG-1's UA-2 land-time note after its register block (Appendix C.3; amended
2026-11-01, review fold: B-M2 / B-M5), the note being rg1-plan.md:2534-2542
with D-LAND-15's date rule (amended 2026-11-01, ruling fold: AUD-51-E16).
Expected: 1945 of 1945 (its own gate);
131/0/19 over 150. Gap-row check: no row named. OP-2's fold of W-197 into
W-126, due once PR 51 has landed, is G-56/57's (item 16), because W-197 is
on PR 57's ledger only (amended 2026-11-01, ruling fold: AUD-51-E20).
Deferred: none of its own (its split
`fail_todo_unformed_dependent_var` is refilled under its name by PR 61's F6
and renamed by PR 64's L-F, C-2; amended 2026-11-01, review fold: RR1-1). Its
committed scoreboard.json is D-LAND-17's.

### §2.3 PR 52, CM-1

Head e6bc32a6d, base trunk; cmake/ and examples/cmake/ (19 files). Conflicts:
ORCHESTRATION (OR-1, OR-2, OR-4 with OR-5), decision-log (DL-1), ledger
(LG-1). Steps: merge; the gate runs unchanged goldens; conformance runs the
BUILD-SCRIPT programs (examples/cmake/test.sh); records with OR-5's carry of
the W-128 item (Appendix C.4; amended 2026-11-01, review fold: A-M1).
Expected: 1945 of 1945 (trunk's 1942 and PR 51's three); 133/0/17 over 150;
tally 32/20/3/1, rows 84 and 87 DONE with their bullets PASS. Gap-row check:
no row named. Deferred: none. CM-1's own land-time steps (amended
2026-11-01, ruling fold: AUD-52-02 / AUD-52-03 / AUD-52-07 / AUD-52-08):
its delta rule, "PASS +2, SKIP -2, total unchanged", bullets 48 to 49
(e6bc32a6d fork/cmake/plan.md:908-912), is section 4's "PR's own delta"
for this landing; its ids W-128 to W-133, filed on the assumption that PR
51 takes W-126 and W-127 and "verified at merge" (D-CM-16, :453-454), are
verified at step 9 by `json.load` with a count of duplicate ids, which must
be 0, and W-126 to W-133 each once (measured on the dry run's 5b6cc69ed:
152 items, no duplicate); D-CM-14's Option B trigger, "cmake: command not
found" in the run's log (:432-438), and section 5.4's revert of rows 84
and 87 to PARTIAL or MISSING if the first run shows anything but the two
PASS lines (:966-973), are this landing's first run of record (R33 (b)):
either outcome stops the landing (D-LAND-18), and the SKIP, the rows'
revert and the decision-log record CM-1 prescribes are a fix commit on PR
52's branch under CM-1's review (D-LAND-10), never a landing commit. The
container has the tools the BUILD-SCRIPT channel needs (measured by the
audit: /usr/bin/cmake 3.28.3, ninja and make; OV-4's mall mirror ran both
BUILD-SCRIPT programs to PASS). The "not of record" labels PR 52 brings,
in rows 84 and 87, in section W11's arbiter sentence and in W-060's and
W-061's notes, take A.10's mark (amended 2026-11-01, ruling fold: the
audit's P52-22 note).

### §2.4 PR 54, EV-1

Head cb3ef2e74, base trunk. Conflicts: ORCHESTRATION (OR-1 to OR-4, OR-5),
decision-log (DL-1), gap-analysis (GA-1 on row 90, GA-2 on the header, the
back-half sentence and section W11), ledger (LG-1, LG-3 on W-002 and W-003:
CM-1's note then EV-1's). Steps: merge; then EV-1's state C commit "Land PR
54: EV-1 integration with PR 52 (state C)" with the content of
fork/evaluator/plan.md section 3 item 6 (:1830-1842): the C++-library
program's two-line un-SKIP (section 2.E.2), `evaluator_samples_self_check()` in
runner.py's `--self-test` (section 2.E.4), the build_systems.md links and the
W-131 and W-133 citations of D-EV-10, row 90, the header and section W11 in
their state C texts (sections 2.F.1 and 5.3; the tally 33/19/3/1; 2.F.1's
clause on 'the expected scoreboard the parenthetical quotes' has no object on
the merged trunk, whose header parenthetical is A.8's measured sentence from
PR 52's landing, so it is not written and A.8's sentence from this landing's
measurements governs, D-LAND-9's break condition; recorded 2026-11-02, the
orchestrator's ruling under R29; the header clause's '2026-10-DD' takes the
PR's own state T value 2026-10-13, cb3ef2e74 fork/gap-analysis.md:19, and
A.8's sentence replaces the clause in the records commit, recorded 2026-11-02,
R54-1, the orchestrator's ruling under R29), W-131's and
W-133's notes, its message recording section 8.2's state C verification line
and the R31 counts re-run (amended 2026-11-01, review fold: A-m2 / B-M6). The
completeness audit's additions to that commit, each by Appendix C.5's texts
(amended 2026-11-01, ruling fold: AUD-54-07 / AUD-54-08 / AUD-54-09 /
AUD-54-10 / AUD-54-11): section W11's state C text with `<date>` in place
of its "2026-10-DD", its "not of record" label taking A.10's mark in the
records commit; W-131's, W-133's and W-002's state C notes; the conformance
README table regenerated by `runner.py --update-readme-table`, the
C++-library row going from SKIP to `external-build` (section 2.E.8,
cb3ef2e74 fork/evaluator/plan.md:1610-1615), without which `--self-test`
fails; and, by R-8 (:2041-2045, "every other runner.py line cited in the
records re-pinned against the merged runner"), every runner.py line cite of
the records re-pinned in that commit to the lines holding the same code in
the runner after state C, by C.8's re-cite rule, a cite whose code is gone
stopping the landing: EV-1's decision-log entry's (runner.py:516-524,
:546-551, :321 and :453-462 on 61458bc92) and the ledger's, W-002's
evidence (fork/conformance/runner.py:652, :597, :413 and :1665) and W-060's
(:597), measured on 61458bc92 and unmoved by the dry run's merges through
5cf7406f1, which lack state C and PR 58's join; no gap row cites a
runner.py line (measured on 61458bc92 and 5cf7406f1). PR 58's join commit
re-pins the same set against the runner it leaves (section 2.6; amended
2026-11-01, review fold: RR4-4). Then EV-1's land sequence (cb3ef2e74
fork/ORCHESTRATION.md:109-116; added 2026-11-01, ruling fold: AUD-54-16 /
AUD-54-17 / AUD-54-18), after step 8:
`python3 -I fork/evaluator/check_faq.py --which fork --toolchain
/home/user/carbon-build/carbon-trunk/install/bin/carbon`, where any mismatch
stops the landing (D-EV-21, :638-653); the same with `--which nightly` and
the newest upstream nightly, fetched as docs/guides/getting_started.md's
download block fetches it into a directory under `scratchpad/land1/impl/`
(the installed 2026.10.12 nightly when the fetch fails or the fetched
nightly cannot be run under the session's permission policy, named in the
records commit's message as the reason with the fetched nightly's version
and sha256; amended 2026-11-02, the orchestrator's ruling under R29, on
the 2026.11.01 nightly fetched and refused at this landing); and the runner with
that nightly's busybox and `--filter project/evaluator`, expected 9 PASS and 2
COMPILE-FAIL (D-EV-2, :340-345). A nightly result other than EV-1's stops
the landing, and the guides' label change D-EV-2 then prescribes is a fix
on PR 54's branch under EV-1's review (D-LAND-10); the nightly and both
results go in the records commit's message. EV-1's entry goes by DL-2,
above CM-1's (section 2.F.3, :1744-1746; AUD-54-12). Then
records with RG-1's EV-1 note and the W-152 carry (Appendix C.5). Expected:
1945 of 1945; 143/0/16 over 159 after state C (static 142/0/17 at the merge).
Gap-row check: row 90 named (the state C commit writes EV-1's
section 5.3 state C text over the PR's row, which the merge took by GA-1;
amended 2026-11-02, the implementer's stop at step 9, the orchestrator's
ruling under R29). Deferred: none.

### §2.5 PR 55, ST-1

Head c3cdecc5d, base trunk; one toolchain file and one prelude file.
Conflicts: ORCHESTRATION (OR-1, OR-2, OR-4 twice, OR-5), decision-log (DL-1),
gap-analysis (GA-1 twice, GA-2 on the header), ledger (LG-1). Steps: merge;
build, gate (a prelude change); refill only what the gate names; then two
land-time commits of ST-1's item 5 (c3cdecc5d fork/ORCHESTRATION.md:540-552;
added 2026-11-01, ruling fold: AUD-55-09 / AUD-55-11), each by Appendix
C.6's texts: "Land PR 55: ST-1's landing-date stamps re-stamped", since the
merge date is not 2026-10-13, and "Land PR 55: W-148 cited by its title
until PR 53 lands", since PR 53 has not merged; the id re-scan of W-160 to
W-167 by D-LAND-21 before the records edit (AUD-55-12); records with
the header `<tally>` (34/18/3/1 expected) and the header's landed list gaining
ST-1's clause by C.6 (added 2026-11-02, RV55-1, the orchestrator's ruling under
R29) and W-126 cited by id (PR 51 has
landed, as ST-1's landed notes assumed, :3107-3109), and OR-5: item 5 (ST-1's
merge steps) discharged by the landing, item 6 (the SAFE-1 reconciliation)
carried as G-53's item by Appendix B.1, and the ST-1 dated paragraph's item
numbers marked (Appendix C.6; amended 2026-11-01, review fold: A-M1), row
77's floor of record re-read (ST-1's row text, fork/string/plan.md:2230-2232,
"re-read at rebase": the committed scoreboard is PR 51's, D-LAND-17;
AUD-55-05) and item 5's re-read of row 77's and row 41's lines (C.6's three
re-pins to the records tree's :79 and :43; added 2026-11-02, RV55-2, the
orchestrator's ruling under R29) and the entry placed by DL-2 (AUD-55-02).
With those steps made,
item 5 is discharged by the landing, as C.6 says (amended 2026-11-01,
ruling fold: the audit's S55-19 note). Expected: 1953 of 1953 (section 4);
148/0/15 over 163. Gap-row check: row 77 named (C.6's re-stamp commit, its
W-148 commit and its floor-of-record re-read rewrite words of the PR's row;
amended 2026-11-02, the implementer's stop at step 9, the orchestrator's
ruling under R29). Deferred to G-53: W-144's
additions, the seven SAFE-1 reconciliation edits and the cross-branch
re-cites (:3103-3106, fork/string/plan.md section 2.6), and the re-reads of
arithmetic.md's Strings section and values.md:168 with W-057's evidence
cite, both moved by SAFE-1 (:2835-2838; on 2407efa74 merged onto 5cf7406f1
the amendment moves from arithmetic.md:190 to :199), and the W-148 id
restored (amended 2026-11-01, ruling fold: AUD-55-22 / AUD-55-11).

### §2.6 PR 58, DD-1

Head fcee90d9b, base trunk; 20 programs, 11 pages, 74 records and sample
files. Conflicts: ORCHESTRATION (OR-1 to OR-4, OR-5), fork/conformance/README.md
(README-1, 182 programs), decision-log (DL-1), gap-analysis (GA-1 on row 67,
GA-1b on rows 54 and 91, GA-2 on the header), ledger (LG-1 to LG-6; W-043 and
W-065 both edited).

<!-- google-doc-style-ignore -->

GA-1b (amended 2026-11-01, review fold: A-B1): row 54
("Generics: Integrated templates") is DD-1's row with trunk's UA-2 sentence
appended before the closing `|`, verbatim: " Lowering of a template
instantiated in its defining file landed with the 2026-10 upstream advance
(upstream PR 7727; generics/templates_dependent_member SKIP -> PASS on hosted
run 37407530104, UA-2) while cross-file template lowering is still
CARBON_FATAL (lower/handle.cpp:513) and pattern splices CARBON_FATAL in thunk,
local and match-case matching (pattern_match.cpp:2174-2180; W-014), as UA-2
recorded." (both cites hold on the merged tree: lower/handle.cpp:513 is the
cross-file FATAL, pattern_match.cpp:2174, 2177 and 2180 the three splice
FATALs); trunk's "self-described skeletal placeholder (templates.md:24)" is
superseded by DD-1's "no longer self-describes as a placeholder". Row 91
("Goal: design docs documented, cohesive, understandable without
placeholders") is DD-1's cell whole, because DD-1 section 2.14 says "its cell
replaces PR 51's rewrite of the same cell".

<!-- google-doc-style-resume -->

Steps (amended 2026-11-01, review fold: A-M2 / B-B1): merge; then the state-L
commit "Land PR 58: DD-1 state L for PR 51, PR 54 and PR 55" with the texts of
Appendix C.7 (the held-PR citations, the literals.md note, the README sentence
narrowed to PR 53's section, the `ALLOWLIST` entry for arithmetic.md's
"Strings" removed, the EV-1 sentences), checked by both checker modes (0
errors; the dry run's 94dba6b21 is the reference), its message C.7's, with
DD-1's state-L checks in it: the W2 output expected and actual, both checker
modes, `--self-test`, the totals, DD-1's section 8.10 Not-run list verbatim
and the nineteen programs on the nightly (fcee90d9b
fork/designdocs/plan.md:5600-5607), and for its nine markdown files R31's
counts, the heading sets compared before and after (`comm`) and the grep
for a manufactured heading (:5592-5599; added 2026-11-01, ruling fold:
AUD-58-U2 / AUD-58-U3); then the commit "Land PR 58: DD-1's checker joins
runner.py --self-test (D-DD-6)", because EV-1's state C commit (PR 54) put
`evaluator_samples_self_check()` in runner.py's `--self-test`, which is
D-DD-6's condition (:567-571): Appendix C.7's rule, `--self-test` printing
its `OK` line after it, a toolchain dependency or a run past `--self-test`'s
budget limiting the join to the diff, quote and W2 checks by D-DD-6's own
break condition (added 2026-11-01, ruling fold: AUD-58-U1), the join
commit re-pinning section 2.4's runner.py cites (EV-1's decision-log
entry's, W-002's and W-060's) by C.8's re-cite rule against the runner it
leaves, EV-1's R-8 applying to every runner.py change (added 2026-11-01,
review fold: RR4-4); then records
with DD-1's
section 2.14 evidence amendments for W-014, W-127, W-155 and W-167, row 91's
dated mark, RG-1's DD-1 note (rg1-plan.md:2562-2570), the header `<tally>`
(35/17/3/1 expected), a dated note on W-043, and OR-5's carry of DD-1's
correction note under item 3 (Appendix C.7), and by the completeness audit
(added 2026-11-01, ruling fold: AUD-58-U4 / AUD-58-U5 / AUD-58-U6 /
AUD-58-U7 / AUD-58-U8): the ledger source's "OP-2 reserves W-196..W-199"
made W-196..W-201, OP-2's hand-off to this commit (e23113ba2
fork/ORCHESTRATION.md:739-743); W-057's and W-161's evidence cites of
docs/design/README.md and docs/design/interoperability/README.md re-cited
by C.8's re-cite rule, since the merge moves ST-1's amendment lines
(measured: :636 to :657 and :303 to :981 on 94dba6b21); A.5's and A.6's
sentence on W-187 (D-LAND-14) and on F-016's re-read against trunk
(fcee90d9b fork/designdocs/plan.md:6804-6812: F-016 is OP-2's, minted on
held PR 57 as trunk's fork/ORCHESTRATION.md:163 says, and DD-1 mints no
fork design id); RG-1's DD-1 note by D-LAND-15's rule. DD-1's step to amend
or annotate trunk's "a fourth focused round" (:4369-4373) is already made:
trunk's paragraph at bb9fbba9c fork/ORCHESTRATION.md:183-190 records that
the fourth round was one of both document reviews, so the landing makes no
edit for it. Expected: 1953 of 1953;
167/0/15 over 182; row 70 DONE with its bullet PASS. Gap-row check: row 91
named (DD-1's cell supersedes the UA-2 re-read). Deferred: state L for PR 53,
PR 56 and SC-1 (D-LAND-14).

### §2.7 PR 61, TP-1

Head 66aa13132, base trunk; 32 toolchain files, 25 goldens. Conflicts:
ORCHESTRATION (OR-3, OR-4, OR-5), README-1 (192 programs), gap-analysis
(GA-1c on row 54), ledger (LG-1, W-014 both edited). Steps, mapping section 3
items 7 to 13 (amended 2026-11-01, review fold: B-M6): item 7, M, is the merge
("M resolves conflicts only", fork/templates/plan.md:5192-5205); item 8's S
moves to G-60, and F6 is the refill of every golden the gate names, with
TP-1's ten refills recomputed (the landed notes' item (c), :7923-7925;
amended 2026-11-01, review fold: RR3-4) and PR 51's split refilled under its
name `fail_todo_unformed_dependent_var`, CHECK lines only: F6 drops TP-1's
rename of that split (:5212-5214 and Appendix A's F6 line, :15210-15212),
because the
split's shape still fails on TP-1's toolchain and file_test rejects a failing
split without the `fail_` prefix (section 0.7; CT-1's C-2 and H-1), and PR
64's L-F renames it (section 2.9; amended 2026-11-01, review fold: RR1-1);
M and F6 are judged with D-LAND-20's mutants (the landed notes' item (c),
66aa13132 fork/templates/plan.md:7927-7928: the file rule names none at this
landing, the killer rule is measured at step 7, and M18 moves to G-60 with
S; added 2026-11-01, review fold: RR2-1); item 9's implementation reviews A
and B on the merged head are D-LAND-10's
two reviewers; item 10's fix commits, if a review finds a defect in the PR, go
to PR 61's branch (D-LAND-10); item 11: the id re-scan of the front matter,
then L "Land PR 61: TP-1 integration with PR 58" with Appendix C's texts
(:16086 on) as Appendix C.8 adapts them to PR 58's state-L text (hunk 9's
context line and the comments of X20 and X23 without "held PR 51"; amended
2026-11-01, review fold: RR1-2), both checker modes on L and on any fold
commit, and L's document review by both reviewers, A and B, with a fold
commit if either finds anything (TP-1's section 2.9, "two reviewers, R29(c)";
amended 2026-11-01, review fold: RR1-3); item 12, R: row 54
recomposed by section 2.8's rule over the merged row, which is not PR 58's
text verbatim (it carries the UA-2 sentence GA-1b appended), so R keeps it and
appends TP-1's sentence, re-citing every file:line to the landing's tree; item
13, D: Appendix E's land-time texts (:17744 on: W-014's notes, the discharges
of W-127, W-183, W-192 and W-193, W-127's as Appendix C.8 gives it with C.8's
sentence on PR 51's split appended to W-127's notes, the held-state
sentences replaced by the merged tree's values), the evidence the landed
notes' Ledger re-cites name re-cited to the merged tree (:7905-7914: W-250,
W-251, W-253, W-256, W-264 and W-265, and W-014's notes' lower/handle.cpp
cite, by Appendix C.8's rule; added 2026-11-01, review fold: RR3-4), the
landed notes with both id re-scans' outcomes (the one before L and one
before the records commit),
C.8's F6 sentence at the end of A.5 and A.6, and C.8's mutant sentence at
the end of A.5 (amended 2026-11-01, review fold: RR1-1 / RR2-1 / RR2-3).
Expected: 1968 of 1968, the split passing as a `fail_`
split;
177/0/15 over 192. Gap-row check: row 54 named (R writes it). Deferred to
G-60: S (member_access.cpp, :5206-5212) and M's rules for SC-1's hunks
(66aa13132 fork/ORCHESTRATION.md:1091-1094; AUD-61-T06); to G-59: the VA-1
compositions F6 measured as none.

The completeness audit's additions to this landing (added 2026-11-01, ruling
fold: the AUD ids named): the entry goes by DL-2, directly after "Full
autonomy and the throughput protocol" (fork/templates/plan.md:18347-18349;
AUD-61-T04); A.3's row replaces both tp rows by OR-2 (AUD-61-T05); the two
id re-scans by D-LAND-21, their outcomes in `<rescan>` (AUD-61-T15); L's
message carries R31's counts of docs/design/templates.md before L, after it
and after prek by step 6 (AUD-61-T18); R appends, after the merged row's
UA-2 clause, which cites lower/handle.cpp:513 for the cross-file
`CARBON_FATAL` that TP-1's change moves to :524 (measured on a33d05cae and
d03be4456), the marker section 2.8 prescribes for a later clause TP-1
changes (:5000-5005), C.8's text, and R's commit message quotes the row it
started from (:5002-5003; AUD-61-T20 / AUD-61-T21); Appendix E's
ORCHESTRATION stamp (:18456-18468) is replaced by A.3's row and A.4's
paragraph, whose `<rescan>` holds the re-scans' outcomes, because its
"merged after PR 59" is false under D-LAND-1 and its other fields are A.4's
(AUD-61-T25); the landed notes and the decision-log entry record the
merged checker runs and both re-scans' outcomes by C.8's sentence for A.5
and A.6 (AUD-61-T26); TP-1's item (h), the "not of record" phrases replaced
once Actions returns (:7935-7936), is A.10's mark at this landing, which
section 2.7 item 13's D makes by replacing the notes, so that the search finds
no label and no mark is written (amended 2026-11-02, review round 1: RV61A-2,
RB61-1; ruling (12)), R33 (b) making the container scoreboard R9's record now
(AUD-61-T28); D-TP-16's
break condition, an upstream template commit subsuming one of C1 to C5
before TP-1's merge (:3474-3478), is checked at D-LAND-19's `<tip>`:
`git log --oneline c1e83b0b7..<tip> --` over TP-1's 32 non-testdata files
(`git diff --name-only bb9fbba9c...66aa13132 -- toolchain core
':!*/testdata/*'`), each commit read and judged as section 2.9 judges, the
verdicts saved as `tp1-d16.txt` beside the logs and reviewed by D-LAND-10,
a subsuming commit stopping the landing for TP-1's next revision to take
it as C0 (measured by the rev-6 fixer: 44 such commits at 68569d234, not
judged here; AUD-61-T29); and DR-1's round-1 note, "passed to PR 61's and
CT-1's records" (fee0ef31c fork/direction/plan.md:4285-4296, :4528-4533) and
in neither head's records, is carried at this landing and at PR 64's by
C.8's and C.10's note sentence at the end of A.5, and checked by
D-LAND-22, which decides its outcome now (amended 2026-11-01, review fold:
RR4-1): D-LAND-10's reviewers at PR 61 and PR 64 compile D-LAND-22's four
programs on the landing's install, the note's literal form, a template
`v[0] = 5` on a by-value type with only `IndexWith`, among them, and expect
what D-LAND-22 measured on TP-1's and CT-1's installs (the literal and the
variable template forms stop at lower.cpp:48, W-259's abort; the same
assignment outside a template is rejected as not assignable; the
template's literal read compiles), any other result stopping the landing;
PR 61's records commit writes C.8's W-259 note; and `s[i] = 5` on a
`Core.Slice(i32)` or `Core.Buf(i32)` as a template `T` CHECK-fails on
trunk too, which DR-1b fixes (AUD-61-T30).

### §2.8 PR 62, SV-1

Head 0ef8a0334, base trunk; 12 toolchain files, 2 prelude files. Conflicts:
ORCHESTRATION (OR-1 to OR-4, OR-5), gap-analysis (GA-1c on row 68), ledger
(LG-1). Steps, mapping section 3 item 8 and the landed notes' item (g) (amended
2026-11-01, review fold: A-B1 / B-M6): M is the merge (records "take trunk's
text"); M-VA moves to G-59; F-M refills SV-1's own goldens
(stdlib/optional.carbon, stdlib/variant.carbon,
choice/optional_pointer_payload.carbon and the four function-pointer goldens, as
the gate names them; the PR 57 part moves to G-57); Doc-M moves to G-56; the
second id re-scan (section 8 item 7's command) and section 8 item 11's checker
runs (D-LAND-6 step 8); the records commit: row 68 by C.7's fallback (the merged
row verbatim, then C.7's sentence as amended at W-322's commit, with
`YYYY-MM-DD` the landing date and without the `<, VA-1 pack elements (W-284)>`
clause, then the landing's count; Appendix C.9), the absolute count re-quoted
into W-011's note and the decision-log entry, x19 checked on the merged trunk
(W-282 filed with C.4's text only if it stops there), the notes on W-252 and
W-263 by Appendix C.6's texts (TP-1's items, on trunk since PR 61), evidence
re-cited to the merged tree, and item 4's Next actions mark; C.5, C.8, W-284 and
the header cite of match_core_optional_diff.carbon move to their follow-ons
(D-LAND-4). Expected: 1976 of 1976; 182/0/15 over 197. Gap-row check: row 68
named (C.7 drops the branch's PR 56 clause, "`Core.Optional` itself is not
matchable (W-177, F-015)", because PR 56 is absent).

The completeness audit's additions (added 2026-11-01, ruling fold: the AUD
ids named). The section 8.6 mirrors that the landed notes' item (a) repeats
at M against that day's heads (0ef8a0334
fork/sumtype-interop/plan.md:4745-4746, :5325-5326) are replaced by the
landing itself: step 2's merge-trees, the build of the merged trunk, the
gate and conformance are the measurement the mirrors predicted. Their probe
sets, `$Y`'s probes rx, rt, cr, cz and w (44 programs) and `$W`'s probes/tp
(h1 to h3, t2 to t7, x20, q05), are run on the landing's install with
SV-1's runner of the round that last ran them and compared with the
outputs the plan names (amended 2026-11-01, review fold: RR4-5): for the
44, "what they print on C3" (:5361-5364), whose record is the C3 run's log,
scratchpad/sv1-impl/stage3/probes-c3-y.txt (44 lines, one per program, the
six W-263 stops y11, z1, z5, z7, z8 and z9 among them); for probes/tp, the
mirrors' table (:5367-5372), whose PR 61 row (:5372) gives h1, h2, h3, t2,
t4, t5, t6, t7 and x20 W-279's TODO under "unable to monomorphize
specific", q05 5 and t3 `3 4`; a different output stopping the landing; a
set whose sources are gone from the scratchpad is named not run in the
records commit's message with that reason (AUD-62-S04). x19 is the
composition probe of SV-1's fixer,
scratchpad/sv1-fixer/probes/x/x19_tp_choice_match.carbon (66aa13132
fork/templates/plan.md:10207-10211), not section 0's x19 (0ef8a0334
fork/sumtype-interop/plan.md:627): compiled and run on the landing's
install it must compile and print 0, and only if it stops does W-282 get
C.4's text (:4793-4797; AUD-62-S18). "Evidence re-cited to the merged tree"
(the landed notes' item (g)) is C.8's re-cite rule over the evidence of
W-011 and of SV-1's filed items on the merged ledger; measured by the
audit, W-280's handle_binding_pattern.cpp:518-528 and W-286's
impl_lookup.cpp:253-281 are in files no ready PR before PR 62 changes, so
those keep their lines (AUD-62-S21). M-VA's mutants M19 and M21 and
W-284's clauses go with M-VA to item 17, and the nested-pointer leg, the
conditional refill of fail_todo_core_optional.carbon and Doc-M's
re-derivation to item 16 (D-LAND-4; AUD-62-S06 / AUD-62-S23 / AUD-62-S09 /
AUD-62-S12). The `bool` payload split, the `bool` program leg and the
core_optional_view refill that the branch's item 5 still lists were
withdrawn at W-322 (:1959-1964), and OR-5's message says so (the audit's
S10 note).

### §2.9 PR 64, CT-1

Head 551a03328, base claude/carbon-fork-0-1-tp, retargeted to trunk after PR
61's phase 2. Conflicts: ORCHESTRATION (OR-3, OR-4, OR-5), README-1 (204
programs), PROG-1 on the two programs (PR 51's header with C.6's paragraph
appended, `<YYYY-MM-DD>` the landing date, and CT-1's body, `var b:
Cpp.Box(T);`), decision-log (DL-1), gap-analysis (GA-1c on rows 42 and 56),
ledger (LG-7: W-043 "taken from DD-1's side whole", CT-1's discharge reapplied
by the records commit, fork/cpp-templates/plan.md:2730-2737). Steps, mapping
CT-1's landed notes' items (a) to (g) and its branch's item 6 (section 0.3;
amended 2026-11-01, review fold: RR2-1): merge (item (a), M); step 4's gate
reports PR 51's split `fail_todo_unformed_dependent_var` as succeeded ("if
success is expected, remove the `fail_` prefix"), as expected, because CT-1's
toolchain compiles its shape: it is counted in A.1's `<g0>` and `<gn>` and the
rename commit resolves it (added 2026-11-01, review fold: RR2-4); S-VA (item
(b)) moves to G-59 with its mutant M18; L-F (item (c)), by C-2's own rule
(fork/cpp-templates/plan.md:864-878 and section 2.11 item 3; not section 1.16's
fallback, since PR 61's F6 keeps the name): first a rename commit,
"Land PR 64: PR 51's split renamed for CT-1's L-F (C-2)", whose only edits are
this plan's Appendix C.10 texts for
toolchain/check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon
(the split line, as TP-1's Appendix A F6 line gives it, and a dated header
note); then the refill of every golden the gate names, that split among
them, which CT-1's toolchain compiles (section 0.7; amended 2026-11-01, review
fold: RR1-1); then, in CT-1's order, a comment commit, "Land PR 64: A.2's
nested_alias_through_specific comment names the constants (CT-1 L-F)", whose
only edit is Appendix C.10's two comment lines for lines 260 and 261 of
toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon (RR1r2-m7
of CT-1's focused re-review), the same line count, checked as an autoupdate
no-op after the comment commit: with `G` set to
toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon,
`$CB/autoupdate.sh /home/user/carbon-trunk $G` then
`git status --porcelain -- $G` prints nothing (added 2026-11-01, review
fold: RR2-1; the order amended 2026-11-01, review fold: RR3-6); then the
gate, conformance and D-LAND-20's mutants on the merged
build (M6, M7, M23, M24, M75 and M75r by the file rule; added 2026-11-01,
review fold: RR2-1); L (item (d)) "Land PR 64: CT-1 interoperability page and
fixture X37 over PR 58" (C.1, with this plan's Appendix C.10 anchor; X37 with
its `SAMPLES` entry after X09's and X09's limit comment, checked with and
without `--toolchain`; the dry run's checker result is section 0.5's; amended
2026-11-01, review fold: RR1-2), with R27's spelling diff (each of the page's
`var b: Cpp.Box(T);` and `Cpp.Twice(x)` found by `grep -F` in X37, and the
first in both programs, as CT-1's C.1 names its spellings) and R31's counts of
docs/design/interoperability/README.md before L, after it and after prek, both
in C.10's message for L (added 2026-11-01, review fold: RR2-1); the second id
re-scan (item (e)) immediately before the records commit's ledger edit;
records (items (f) and (g)): rows 56 and 42 by C.4, found by bullet text, with
the interop golden counts measured on the landing's tree, C.2's discharge over
DD-1's W-043 (including the PR 58 note of section 2.6), W-127's sentence
(C.10), R32's comparison below, the decision-log entry's held-state paragraph
brought up to date by C.10's sentence (item (g), C.7's fallback: the merged
log holds one CT-1 entry, measured at e21480b05, so only the held-state
paragraph is brought up to date), and C.10's sentences at the end of A.5 (the
checker runs, the mutants and R32's result; added 2026-11-01, review fold:
RR2-1).

R32's V-3 comparison of F-021 (the landed notes' "R32 at landing",
551a03328 fork/cpp-templates/plan.md:4793-4799; added 2026-11-01, review fold:
RR2-1), at D-LAND-19's `<tip>`: `git grep -n -F` finds each of F-021's four
upstream quotes there, "relies on monomorphization" in
docs/design/generics/appendix-witness.md (leads issue 2153, CT-1's
:149-155), "We have decided to support passing a symbolic constant to a
template" in docs/design/generics/overview.md (CT-1's :375-379), "More direct
interoperation is being considered" in
proposals/p002200-template-generics.md (CT-1's p002200:1089-1096) and
"arguments are treated as templates." in toolchain/check/call.cpp (the
`TemplateInst` comment, CT-1's call.cpp:749-750); `git grep -n
CppCallArgTypeNotSupported <tip> -- toolchain/check/cpp/type_mapping.cpp`
finds E-ARG, the diagnostic whose presence is F-021's premise (CT-1's
section 1.17, :1897-1903); and the log of CT-1's own comparison, section 0.10
(:891-935, a verdict per upstream commit to each file CT-1 changes), is
repeated over that set widened to the directories F-021's rule and its
quotes live in (amended 2026-11-01, review fold: RR3-2): `git log --oneline
c1e83b0b7..<tip> --` over the sixteen files of
`git diff --name-only 66aa13132...551a03328 -- toolchain core ':!*/testdata/*'`,
toolchain/check/cpp/, toolchain/check/testdata/interop/cpp/template,
toolchain/check/testdata/interop/cpp/range_for.carbon,
toolchain/lower/testdata/interop/cpp/globals.carbon, docs/design/ and
proposals/ (`$F3/rr3-2_paths.txt`). Each commit gets a verdict as the
table of section 0.10 gives one: a commit that table lists, or that the
measurement below judges, keeps its verdict; every later one is read (its
message and its diff to the set) and judged at the landing; the verdicts are
saved as `r32.txt` beside the logs and reviewed by D-LAND-10. A commit that
lands a
rule for a checked generic's C++ calls that differs from F-021 (F-021's break
condition, fork/cpp-templates/plan.md:1913-1916), a quote not found, or E-ARG
not found stops the landing (D-LAND-10), and F-021 is re-decided by CT-1's
break condition; otherwise C.10's R32 sentence records `<v3>` and `<v3n>`.
Measured at 68569d234 (`$F3/rr3-2_r32_68569d234.txt`, which supersedes
`$F2/rr2-1_r32_68569d234.txt`): the quotes at appendix-witness.md:154,
overview.md:376, p002200-template-generics.md:1095 and call.cpp:388; E-ARG
at type_mapping.cpp:461 (its `CARBON_DIAGNOSTIC`) and :464 (its `Emit`);
and 59 commits, none such. 29 are in section 0.10's table (:908-925) and
keep its verdicts. Of the other 30, 57bf903ef (2026-10-26, "Keep resolving
generics and templates until they're all resolved") is adjacent: it loops
the end-of-file resolution (check_unit.cpp, cpp/generate_ast.cpp, generic.cpp
and generic.h) and states no rule; its new test
interop/cpp/template/bidirectional_generic_call.carbon exercises upstream's
`TemplateInst` deferral, which F-021 extends
(`Cpp.UsesCarbonInterface(T).Get(t)`, a member of a class template named
with `T`), and X37's shape, `var unused w: Cpp.Wrapper(T);` in
`fn Make[T: type]`, which passes under min_prelude/int.carbon, whose
parts/default.carbon:19 declares the unconstrained
`impl forall [T: type] T as DefaultOrUnformed` that PR 51's header names for
generic_call.carbon, while the real prelude's core/prelude/default.carbon:50
still requires `T: UnformedInit` at that tip. Commit 04f456ddd adds a
`SpecificConstant` case to
`FindStorageArgForInitializerInSpecific`, another function than CT-1's
`GetExprCategoryImpl` hunk in expr_info.cpp; ac31fd198 and fb7eff130
(impl_lookup.cpp) and c6b54b57e and bf91a8b4d (typed_insts.h) touch neither
`NamesTemplateBinding` nor `SpecificConstant`; 309d3d63c and 05a7ecbd3 are
cpp/operators.cpp's (05a7ecbd3's generic_call.carbon change meets CT-1's
refill as text only); the other 22 are eleven C++ export commits
(export.cpp and generate_ast.cpp), a generic class with a virtual C++ base
(2e2125585), two friend imports, a rename in import.cpp and thunk.cpp, two
goldens' diagnostic rendering (c608c35e1), a test comment (a45002667) and
five docs and proposals commits, none stating anything on a checked
generic's C++ calls.

Expected: 1978 of 1978; 189/0/15 over 204. Gap-row check: rows 42 and 56 named
(C.4 replaces them). Deferred to G-59: S-VA with its mutant M18 and C.11's
split; to G-60: CT-1's PR 60 composition, re-measured at the follow-on's
merge with t08, t09, t13 and t14 and tc5 and tc6, and its break
conditions (551a03328 fork/cpp-templates/plan.md:765, :814-851,
:4044-4082); to G-56/57: its PR 57 composition, the red set empty but
TP-1's lower/template/for_range.carbon refill, and its break condition
(:832-840; amended 2026-11-01, ruling fold: AUD-64-a5 / AUD-64-a6). DR-1's
note passed to CT-1's records is carried here as at PR 61 and checked by
D-LAND-22, with the same expected results as at PR 61, which
`<trunk before>` already holds (section 2.7; the audit's x1 note; amended
2026-11-01, review fold: RR4-1).

### §2.10 PR 63, DR-1a

Head 89aabd125, base trunk. Conflicts: ORCHESTRATION (OR-2, OR-4),
decision-log (DL-3: DR-1's entry directly after DR-0's, before RG-1's; amended
2026-11-01, review fold: A-m1), gap-analysis (GA-1 on row 67 and the Optional
row, GA-1b on row 68), ledger (LG-1), TC-1 (handle_loop_statement.cpp:
DR-1a's side, TP-1's `RequireCompleteType` block and its
`#include "toolchain/check/type_completion.h"` dropped; the result equals
89aabd125's file), GOLD-1 (range_for.carbon, 25 CHECK regions). GA-1b (added
2026-11-01, review fold: A-M4): row 68 is DR-1a's row with trunk's SV-1
sentence (section 2.8's) appended verbatim before the closing `|`. Steps:
merge (M-a; loops.md's rule moves to G-56); L-a as the refill: check
generic/template/for_range, lower template/for_range and interop/cpp/range_for,
its count recorded at L-a (fork/direction/plan.md:1555-1582), and, since
DR-1's section 4 says "the fill must reproduce these lines" (:2438, :2449),
A.2's `<refilled>` numstats must be 12/17 for check
generic/template/for_range and 137/137 for lower template/for_range, a
different numstat stopping the landing (D-LAND-8), and range_for's is
recorded (amended 2026-11-01, ruling fold: AUD-63-7); records with the
row-68 mark and item 1's mark (Appendix C.11), the id re-scan by D-LAND-21
(AUD-63-15), and the notes trunk's weekly upstream check of 2026-10-26
routed to DR-1 as a commit on its branch (bb9fbba9c
fork/decision-log.md:6903-6912, fork/ORCHESTRATION.md:536-540), which no
head carries and D-LAND-3 makes this records commit's: W-322's discharge
note and the dated notes of W-324 and W-326, by Appendix C.11's texts; and
the "(i) sha stamp" on PR 63's copy of DR-0's register block, the records
fix trunk routed, "(i) resolved 2026-10-21 by W-322's 22fe50ff8 and its
fill f4660e409 on PR 62" (bb9fbba9c fork/decision-log.md:6908-6909),
written by Appendix C.11's text after the block's "(iii) resolved"
sentence (AUD-63-20; amended 2026-11-01, review fold: RR4-2). The merge
does not make it: the merged block is PR 63's copy, whose (i) still reads
"(W-322, retired by DR-1 slice 1)" with no sha while (iii) carries its own
(f2110e0fd fork/decision-log.md:242-255), and trunk's dated paragraph
after it (bb9fbba9c :249-253) says only that the stamp is "routed to
DR-1". At PR 65, DL-5 keeps that sentence beside DR-1b's "(ii) resolved"
one. DR-1's section 8 item 9
re-run before M-a "if it has moved from 118fc1bc8" (:5151-5153) is not
owed: item 9's own rule re-runs a mirror only when a head has moved in
toolchain/, core/ or fork/conformance/ (:2707-2709), and `git diff`
118fc1bc8 551a03328 and 4a3220c11 551a03328 over those three is empty
(measured by the rev-6 fixer); the landing's step 4 gate and conformance on
the merged trunk is the composition's measurement, recorded in A.5
(AUD-63-13). Expected: 1978 of 1978;
189/0/15 over 204. Gap-row check: no row named. Deferred to G-56: loops.md's
rule, error_handling.md's date-order rule and W-323's discharge note; to
G-57: the m57 refills (lower array/iterate, for/break_continue, for/for)
and row 78's DR-0 sentence beside PR 57's DONE text (fee0ef31c
fork/direction/plan.md:708-709, :1635-1639, :3441; amended 2026-11-01,
ruling fold: AUD-63-11 / AUD-63-12 / AUD-63-21).

### §2.11 PR 65, DR-1b

Head fee0ef31c, base claude/carbon-fork-0-1-dr, retargeted to trunk after PR
63's phase 2. Conflicts: ORCHESTRATION (OR-2), README-1 (206 programs),
gap-analysis (GA-1b on row 79), ledger (LG-1, LG-6 on the source header), TC-2
(handle_index.cpp: DR-1b's side with TP-1's `SemIR::LocId loc_id` parameter
and the default arm's `return elem_id;`, by $P/bin/resolve65.py), GOLD-1
(string_indexing.carbon, trunk's side), and, predicted from the heads, PL-1 on
fork/direction/plan.md and DL-4 on DR-1's decision-log entry (section 0.5's
limit), and DL-5 on DR-0's register block, where PR 63's records commit
wrote the (i) sentence (measured on copies, `$F5/rr4-2/`; added
2026-11-01, review fold: RR4-2). GA-1b (amended 2026-11-01, review fold:
A-B1): row 79 ("Stdlib: Slices") is DR-1b's row with its clause "a `Buf`
held in a field is not freed — aggregate destroy ops are still the
member-destruction placeholder (W-108)" replaced by trunk's clause
verbatim, "a `Buf` held in a field of an owner that declares its own
`impl as Destroy`, or in a choice payload, is not freed (W-108
narrowed at UA-2, 2026-10-06: ... W-125 for payloads)" (the full clause is
`$F/expected/pr65/row79_clause.txt`); its status is DONE, so the tally is
36/16/3/1 from here on. Steps: merge (M-b); step 4's gate reports
slice/write_through.carbon's split `fail_todo_template_index_with_only` as
succeeded ("if success is expected, remove the `fail_` prefix"), as expected:
DR-1 measured it before and after C-b, "1962 passed and 1 failed, L-b's
rename 1/1" (fee0ef31c fork/direction/plan.md:2756-2758); it is counted in
A.1's `<g0>` and `<gn>`, and L-b's rename commit resolves it (added
2026-11-01, review fold: RR2-4); C-b, "Land PR 65: DR-1b: index a
template-dependent operand per specific (TP-1's IndexAction)", DR-1's own
message (amended 2026-11-01, ruling fold: the audit's A3 note), the block
of fork/direction/plan.md:2204-2225 at the head of `PerformIndex`'s default
arm, removing the arm's later
`auto index_type_id = context.insts().Get(index_inst_id).type_id();` (the
hoist section 2.2 names; :271 on the dry run's tree; amended 2026-11-01,
review fold: B-m7); the nine probes on the landing's install, by
`TCS="trunk:/home/user/carbon-build/carbon-trunk/install/bin/carbon"
<S>/dr1b-rr/rev1-r4/bin/run4.sh <probe>` with `<S>` the scratchpad, over
rev1-r4/probes_mct's t10_tmpl_iw_var, t15_tmpl_iw_i32var, t16_tmpl_dep_sub,
t18_tmpl_member_iw, n06_tmpl_ptr, n15_tmpl_iwlit, n32_tmpl_vec_generic_iw and
n13_tmpl_mixed and rec-r4/p/a4_tmpl_constrained, expected `7`, `8`, `9`, `6`,
`8`, `5`, `7`, `3 7` and `9` (:1602-1612; a different output stops the
landing; added 2026-11-01, review fold: B-M6); L-b (amended 2026-11-01,
review fold: RR3-1; fee0ef31c fork/direction/plan.md:1586-1590, :2451,
:3065-3068, :4821-4823 and :5463-5466): first a rename commit, "Land PR 65:
DR-1b's write_through split renamed and its comment reworded (L-b)", whose
only edits, in toolchain/check/testdata/slice/write_through.carbon, are the
split line `// --- fail_todo_template_index_with_only.carbon` made
`// --- template_index_with_only.carbon` and the split's six-line comment
replaced by Appendix C.12's six lines, which say that the choice is made per
specific (DR-1's :3066-3067); then the refill of every golden the gate names
(check generic/template/index, slice/write_through, string_indexing 2/2),
in which write_through.carbon's diff is exactly the split's seven
`// CHECK:STDERR:` lines removed and nothing added (DR-1's "the refill 0/7",
:2451; the split has no SemIR dump), any other change to it stopping the
landing (D-LAND-8); records discharging W-340
with M-b's, C-b's and L-b's shas (C.2), row 79's W-340 sentence in the past
tense (C.3), the DR-1 entry's dated note, the header `<tally>` and item 1's
mark (Appendix C.12). Expected: 1982 of 1982; 191/0/15 over 206; row 79 DONE
with its bullet PASS. Gap-row check: no row named. Deferred: none of its own
steps; DR-1's call.cpp and convert.cpp test of the gated PRs' added lines
(fee0ef31c fork/direction/plan.md:711-712) to G-59 and G-60, and SAFE-2's
DR-1 note to G-53 (D-LAND-4).

The completeness audit's additions (added 2026-11-01, ruling fold: the AUD
ids named): DR-1's composition re-run before M-b "if it has moved from
4a3220c11" (:5449-5451) is not owed, by item 9's rule, as at PR 63
(section 2.10; AUD-65-A1); the id re-scan by D-LAND-21 (:5472-5473;
AUD-65-A10); C-b's
mutant by D-LAND-20, after the refill (AUD-65-A11); the refill's numstat for
check generic/template/index must be 16/41 (DR-1's section 4, :2450), as
write_through.carbon's must be 0/7; C.2's discharge text with its three sha
slots filled as C.12 says (AUD-65-B2) and C.3's past tense with row 79's
marks kept (C.12; AUD-65-B3); and the A.5 sentence of C.12 that records
SAFE-2's DR-1 note, whose premise "PR 65 lands after PR 53" this order
reverses, as item 14's (AUD-65-F2). C-b's message is DR-1's own, prefixed
as every landing commit is (:5459-5461; the audit's A3 note).

Round 4's additions (added 2026-11-01, review fold: RR4-7 / RR4-1).
handle_index.cpp is the one C++ file a landing writes beyond either head's
text, by TC-2's resolution and C-b (TC-1's result equals 89aabd125's
file), and DR-1's section 8 item 6 runs
clang-tidy on each changed translation unit (fee0ef31c
fork/direction/plan.md:2683-2694) on DR-1b's own tree, while mct-b
checked C-b with clang-format only ("C-b +19/-1, clang-format clean",
:2733 and :2757; mct-b's rebuild at :5418-5422). So after C-b's build,
`ninja -C /home/user/carbon-build/carbon-trunk -t compdb` writes the
compile database to `<S>/land1/impl/pr65-tidy/compile_commands.json`
(`<S>` the scratchpad, as above; measured: the build's ninja file gives 323
entries, handle_index.cpp among them), and in /home/user/carbon-trunk
`/home/user/llvm/bin/clang-tidy` runs with `-p <S>/land1/impl/pr65-tidy`
and `--checks=-modernize-use-trailing-return-type` on
toolchain/check/handle_index.cpp, as item 6 runs it (clang-tidy 21.1.8,
the repository's .clang-tidy otherwise); DR-1 recorded rc 0 with no
user warning on f774ee836 and 7a442f632, and any user warning stops the
landing for a fix by PR 65's workstream (D-LAND-10), the result going into
the records commit's message and C.12's A.5 sentence. D-LAND-22's four
programs are compiled on the landing's install after the refill, with
D-LAND-22's expected results or C.12's W-259 sentence.

### §2.12 PR 68, OV-4

Head 097c76473, base trunk. Conflicts: ORCHESTRATION (OR-1 to OR-4), ledger
(LG-1). Steps, with OV-4's own messages and D.7 texts adapted as Appendix
C.13 gives them (amended 2026-11-01, review fold: B-M1 / B-M2 / A-m4): M is the
merge, with A.1's message replacing OV-4's M message (PR 59, PR 60 and PR 66
are not landed, so its handle_function.cpp and merge.cpp sentences do not
apply and the merge has no toolchain conflict); F-M, if the gate names an OV-4
golden (predicted none), is A.2's refill commit; L-R: Appendix D.6's rows T2.8
and T2.9 inserted after T2.7 in fork/register/rg1-plan.md, its checks and
quotes appended to rg1-checks.tsv and rg1-quotes.tsv, with D-LAND-19's checks
at `<tip>` over the whole tables and the two rows' own checks counted apart,
R31's counts of rg1-plan.md showing two table rows more, and Appendix C.13's
message; L is the records commit: section 8.1 to 8.4's re-run is D-LAND-6's
steps 4 to 8, and D.7's ledger, decision-log and ORCHESTRATION texts are
replaced by Appendix C.13's. Expected: 1986 of 1986; 193/0/15 over 208.
Gap-row check: no row named. Deferred to G-60: SC-1's two arguments in
`CheckOverloadMemberParamsMatch`; to G-59: the pack gate order in
handle_function.cpp. The completeness audit's additions (added 2026-11-01,
ruling fold: AUD-68-15 / AUD-68-17 / AUD-68-19): L-R's failing rows go to
W-355 by C.2's note with this landing's number, and a failure among T2.8's
or T2.9's own quotes or checks is said in that row's cell by C.13's clause
(097c76473 fork/overload/ov4-plan.md:4104-4106; measured by the audit at
68569d234: two of T2.8's quotes fail, pattern_match.cpp:950 and
handle_pattern_list.cpp:185, so the clause is predicted); section 8.8's
re-run of section 8.5 is D-LAND-20's PR 68 part, M1, M2 and M8 predicted;
R-5's re-read of the four ORCHESTRATION regions is step 9's, at every
landing.

## §3 The process

The implementation workflow runs one stage per landing, in order, each
stopping on D-LAND-10 (amended 2026-11-01, review fold: B-m4 / B-m6). Before
stage 0 the orchestrator pushes the signed-off plan with Appendix B.1's stamp
(D-LAND-16). Stage 0 is the baseline (D-LAND-7); stages 1 to 12 are PR 67, 51,
52, 54, 55, 58, 61, 62, 64, 63, 65 and 68. The actors:

| Step | Actor |
| --- | --- |
| D-LAND-6 steps 1 to 9, the land-time commits, prek, R31, the checks, D-LAND-20's mutants and section 2.9's R32 comparison | the implementer |
| D-LAND-10's review, one fresh agent per landing, two at PR 61 | the reviewers |
| a fix of the landing's own commits | a fixer, a new commit, reviewed again |
| a fix of a PR's code or texts | the PR's workstream, on its branch (D-LAND-10) |
| phase 1, the API read (`merged`, `merged_at`, `merge_commit_sha`), phase 2 | the implementer |
| the retargets of PR 64 and PR 65 (`update_pull_request`), confirmed by `pull_request_read` | the orchestrator, between stages 8 and 9 and stages 10 and 11 |
| the PR description's Landed line (Appendix A.7) | the orchestrator |
| Appendix B.1 before stage 0 and B.2 after stage 12 | the orchestrator |

The implementer writes no ORCHESTRATION text beyond each records commit's row,
paragraph, header and Appendix C's marks and carries.

The follow-ons, each its own workstream with its own reviews, entered when
D-LAND-12's gate holds; Appendix B.1's items 14 to 17 name their steps:

-   G-53 (PR 53), entered once the realignment of PR 53's branch completed
    under the orchestrator's re-ruling of the C++ boundary question
    (fork/safe/safe3-plan.md D-SAFE3-13 and its rev 11 and rev 12 fold
    records); SAFE-3 stopped at its plan rev 12 (14c1ac8ac, 2026-11-01)
    under its re-think ruling's break condition (RT1-B1 and RT2-B1), the
    orchestrator stamping the stop on trunk from safe3-plan.md Appendix D's
    stop path after B.1's stamp, PR 53's pushed head staying 2407efa74 and
    W-365 and W-366 reserved and unfiled (amended 2026-11-01, ruling fold:
    the ruling's item 2): records-only merge (section 0.6); land-time: the
    PR 67 note commit on trunk across the six items' notes, rg1-checks.tsv,
    rg1-quotes.tsv, rg1-plan.md and RG-1's log entry (D-LAND-12;
    AUD-67-P29), ST-1's SAFE-1 edits and its re-reads of the pages SAFE-1
    moves, the W-148 id restored, SAFE-2's DR-1 note on
    `IndirectIndexWith.Ref` (D-LAND-4), DD-1's state L for PR 53, RG-1's
    H53 notes already on the head.
-   G-60 (PR 60): merge of trunk into PR 60's branch resolving convert.cpp,
    member_access.cpp, merge.cpp and templates.md, with TP-1's S and its
    mutant M18 (amended 2026-11-01, review fold: RR2-1) and M's rules for
    SC-1's hunks, OV-4's two arguments, DD-1's state L for SC-1, CT-1's PR
    60 composition and DR-1's call.cpp and convert.cpp test (amended
    2026-11-01, ruling fold: AUD-61-T06 / AUD-64-a5 / AUD-65-A15), item 10's
    decided commit, fills, gate, its review; then the trunk landing.
-   G-56/57 (PR 56, then PR 57 retargeted to trunk): W-352; loops.md by M-a's
    rule and C.7; error_handling.md with both sides' amendments in date
    order, DR-1a's (on trunk from PR 63) and OP-1's, by DR-1's rule
    (fee0ef31c fork/direction/plan.md:708), where rev 5 said "by DD-1's and
    OP-1's texts", DD-1 leaving error_handling.md untouched (amended
    2026-11-01, ruling fold: AUD-63-11 and the audit's N6 note); row 78's
    DR-0 sentence beside PR 57's DONE text; W-323's discharge note; DR-1a's
    m57 refills; CT-1's PR 57 composition; OP-2's W-197 fold into W-126;
    SV-1's Doc-M re-derived under its section 1.14 review, C.5's W-177
    evidence, C.8, the W-177 header cite, F-M's PR 57 part, the
    nested-pointer leg and the conditional refill; DD-1's state L for PR
    56; RG-1's OP-2 note (amended 2026-11-01, ruling fold: AUD-63-12 /
    AUD-63-21 / AUD-64-a6 / AUD-51-E20 / AUD-62-S09 / AUD-62-S12).
-   G-59/66 (PR 59, then PR 66 retargeted to trunk), owned by VA-1's
    workstream: W-367's fix and note 7's ruling on PR 59, W-367 (and W-368 if
    the ruling makes a fix) filed in PR 59's branch's ledger;
    handle_function.cpp by OV-4's rule; SV-1's M-VA with its mutants M19
    and M21, and W-284 with its clauses; CT-1's S-VA
    with its mutant M18 and C.11's split (amended 2026-11-01, review fold:
    RR2-1); DR-1's call.cpp and convert.cpp test (amended 2026-11-01, ruling
    fold: AUD-62-S06 / AUD-62-S23 / AUD-65-A15); RG-1's VA-1 note and
    W-343's discharge if it is the last;
    then VA-2's own M, S-CT, F-M, L-F and L (va2-plan.md section 3 item 15)
    over convert.cpp, eval.cpp and handle_function.cpp.

## §4 Scoreboard progression

Static expectation (section 0.8), PASS / FAIL / SKIP over programs, after each
landing's land-time commits, and the stop values of D-LAND-18 (amended
2026-11-01, review fold: A-B1 / A-M3 / B-M3). The gate column is the merged
tree's golden count: the `.carbon` files under the eight testdata directories
gate.sh runs, plus two (`git ls-tree` of each scratch merge; the rule
reproduces the logged gate counts of trunk 1942, PR 51 1945, PR 61 1957, PR 64
1959, PR 63 1942, PR 65 1946 and PR 68 1946 on their own heads). Every one of
them must pass. The landing delta is PASS over the previous row; the PR's own
delta is its recorded expected PASS over its own base (section 0.1).

| After | Programs | PASS / FAIL / SKIP | Landing delta | PR's own delta | Gap tally | Gate (merged) |
| --- | --- | --- | --- | --- | --- | --- |
| trunk (baseline) | 150 | 128 / 0 / 22 | -- | -- | 30/21/4/1 | 1942 |
| PR 67 | 150 | 128 / 0 / 22 | 0 | 0 | 30/21/4/1 | 1942 |
| PR 51 | 150 | 131 / 0 / 19 | 3 | 3 | 30/21/4/1 | 1945 |
| PR 52 | 150 | 133 / 0 / 17 | 2 | 2 (PASS +2, SKIP -2, fork/cmake/plan.md:908-912; the cell amended 2026-11-01, ruling fold: AUD-52-02) | 32/20/3/1 | 1945 |
| PR 54 | 159 | 143 / 0 / 16 | 10 | 9, plus state C's un-SKIP | 33/19/3/1 | 1945 |
| PR 55 | 163 | 148 / 0 / 15 | 5 | 5 | 34/18/3/1 | 1953 |
| PR 58 | 182 | 167 / 0 / 15 | 19 | 19 | 35/17/3/1 | 1953 |
| PR 61 | 192 | 177 / 0 / 15 | 10 | 10 | 35/17/3/1 | 1968 |
| PR 62 | 197 | 182 / 0 / 15 | 5 | 5 | 35/17/3/1 | 1976 |
| PR 64 | 204 | 189 / 0 / 15 | 7 | 9, less the two programs PR 51 un-SKIPped | 35/17/3/1 | 1978 |
| PR 63 | 204 | 189 / 0 / 15 | 0 | 0 | 35/17/3/1 | 1978 |
| PR 65 | 206 | 191 / 0 / 15 | 2 | 2 | 36/16/3/1 | 1982 |
| PR 68 | 208 | 193 / 0 / 15 | 2 | 2 | 36/16/3/1 | 1986 |

Bullets: 48 PASS at the baseline; never below the previous landing's count;
the bullets of rows that move to DONE (section 0.7) PASS at that landing. A
renamed split (C-2 at PR 64's L-F, L-b; amended 2026-11-01, review fold:
RR1-1) keeps the gate count; a land-time commit that adds or
removes a golden names it, and the count moves by exactly that. The arbiter's
values are recorded beside these; a difference D-LAND-18 does not explain
stops the landing.

The completeness audit's folds change no value of this table (checked
2026-11-01, ruling fold: the audit's count check): the land-time
commits it adds at the ready landings are records, page, comment and
`runner.py` edits (PR 54's README table and W-002, W-131 and W-133 notes,
PR 55's re-stamp and W-148 commits, PR 58's `--self-test` join), none of
which adds, removes or re-SKIPs a program or a golden; the program and
golden steps it names (SV-1's nested-pointer leg, CT-1's compositions) are
the follow-ons'.

## §5 Risks and rejected alternatives

-   R-1, a composition hidden by the order. A ready PR may need a gated PR's
    code to be correct. Falsifier: a landing's gate or conformance fails, or
    its review finds a defect that names a gated PR; D-LAND-1's break
    condition stops it.
-   R-2, prelude drift in goldens. PR 55, 62, 63 and 65 change the prelude;
    a golden of another PR may change. Falsifier: the gate names a golden no
    plan predicts; D-LAND-8 refills it only with an explanation, else stops.
-   R-3, the follow-ons grow. Moving compositions to G-60 and G-59/66 makes
    them larger. Falsifier: section 0.6's conflict sets grow when measured
    again at each follow-on's start; the follow-on re-plans.
-   R-4, id collision with PR 53's realignment, SAFE-3 having stopped with
    W-365 and W-366 reserved and unfiled (amended 2026-11-01, ruling fold:
    the ruling's item 2). Falsifier: W-367 to W-370 found filed by
    another workstream at the stamp; D-LAND-13's break condition.
-   R-7, a land-time step left unmapped (added 2026-11-01, ruling fold: the
    ruling's item 1). A plan's land-time step that section 2 neither carries
    nor names as moved is a step the landing silently drops. Falsifier:
    rounds 4 and 5 of the focused re-review, and each landing's review
    (D-LAND-10), which checks the PR's own records against section 2 and
    the rev-6 fold record; a step found unmapped stops the landing.
-   R-5, the scratch references go stale. A head that moves after this plan,
    or a land-time commit the dry run did not make, changes a later merge.
    Falsifier: step 1's head check and step 2's re-run of the remaining
    merges; the differences are recorded and a non-records one stops the
    landing (amended 2026-11-01, review fold: A-M4).
-   R-6, a records text drops a PR's row or item. Falsifier: the gap-row check
    of D-LAND-6 step 9 and OR-5's list in section 2 (added 2026-11-01, review
    fold: A-B1 / A-M1).
-   Rejected: all twelve in one merge. It would verify only the end state, so a
    regression could not be attributed to a PR, and no PR's records commit
    could state its own measurement.
-   Rejected: squash or rebase merges. They rewrite or drop the PRs' history
    (AGENTS.md, the owner's directive), and GitHub would not mark the PRs
    merged.
-   Rejected: GitHub's merge button. It cannot resolve the records conflicts
    of section 0.4 and would merge unverified, against R33 (a).
-   Rejected: waiting for Actions. R33 is the owner's directive to merge on
    container verification while hosted checks are unavailable; R21's hosted
    gate is owed afterwards (R33 (b)).
-   Rejected: landing PR 53 as it is. Its head carries six filed drifts (W-347
    to W-351, W-353), and R32 (e) and R33 (c) require the realignment first.
-   Rejected: landing PR 59 now with its fix as a later trunk commit. R33 (c)
    gates the PR itself, and trunk would carry two aborts on VA-1's forms in
    the meantime.
-   Rejected: holding PR 61 and PR 64 for a fix of the template assignment
    abort (added 2026-11-01, review fold: RR4-1). The abort is W-259's, a
    trunk defect that trunk reaches with a variable subscript and that TP-1
    filed out of its scope before PR 61 was held (D-LAND-22); holding them
    would also hold PR 63 and PR 65, whose merge rules assume CT-1, and
    leave the root unfixed, since the fix is W-259's assignment action,
    not a change to PR 61. D-LAND-22's break condition reopens it.
-   Rejected: stopping at PR 53, as RG-1's section 5 recorded. Only PR 67
    would land; the dry run shows the twelve merge by recorded rules.
-   Rejected: taking trunk's side for a gap row both sides changed (rev 1's
    GA-2). It drops the PR's status and text (rev 1's run lost row 79's DONE,
    W-326 and W-340 and rows 54, 68 and 91's PR text).
-   Rejected: one push with the records commit. The records would say LANDED
    before GitHub shows the PR merged (B-M4).

## §6 Verification and what is not run

Planner, measured: `git ls-remote origin` and the API listing; every
merge-tree of section 0.4; the twelve-step dry run with `--self-test`,
`json.load` and the model-identifier grep at every step; the follow-on
merge-trees; the id re-scan; the arbiter's paths and logs; `df`. Rev 2's fixer,
measured (2026-11-01): `git ls-remote` of trunk, the mirror and all eighteen
heads (unchanged); the dry run re-run with GA-1b, GA-1c, DL-3 and the two
land-time commits (section 0.5); DD-1's and EV-1's checkers on every scratch
commit from PR 54 on; the gap-row check on rev 1's and rev 2's merges; the gap
tallies; the follow-on merge-trees onto 5cf7406f1; the id re-scan for W-367 to
W-370; the safe3 log of the register checks at 68569d234; the DR-1 probe
sources and runner; the decision-log and plan-file anchors of Appendix C on the
dry run's tree. Rev 3's fixer, measured (2026-11-01, review fold: RR1-1 to
RR1-6): `git ls-remote` of all eighteen heads (unchanged); the split shape of
section 0.7 compiled with the existing installs of TP-1, CT-1 and trunk (no
build); TP-1's L extracted and applied with `git apply`, as written and with
C.8's state-L context, on d03be4456, and CT-1's L with Appendix C.10's anchor on
e21480b05, with DD-1's checker (section 0.5); the B.1 anchors and the A.10
rows on bb9fbba9c and the scratch commits; the SV-1 id-list lines of C.9.
Rev 4's fixer, measured (2026-11-01, review fold: RR2-1 to RR2-4):
`git ls-remote` of all eighteen heads (unchanged); D-LAND-20's file sets, the
merges' non-testdata diffs from 66aa13132 and 551a03328 against TP-1's and
CT-1's own files, and the six convert.cpp mutants' edits by
`patch --dry-run` on 551a03328's and e21480b05's convert.cpp (all apply); the
comment of template_symbolic_arg.carbon:260-261 on 551a03328 and e21480b05;
the CT-1 decision-log entry and its held-state paragraph's last sentence on
e21480b05 (one entry, the anchor once); F-021's four quotes and the
`git log` at upstream 68569d234; fork/cpp-templates/plan.md absent at
bb9fbba9c and d03be4456; trunk's Scoreboard paragraph and scoreboard.json;
file_test_base.cpp:131-160 and DR-1's gate line. Rev 5's fixer, measured
(2026-11-01, review fold: RR3-1 to RR3-6): `git ls-remote` of all eighteen
heads (unchanged); write_through.carbon at fee0ef31c and d3eb55f7a
(identical, 831 lines, the split's comment at :121-126 and its seven STDERR
lines at :140-146, no SemIR dump in the split) and C.12's rename and comment
applied to a copy (831 lines, seven lines changed;
`$F3/rr3-1_write_through.txt`); the widened R32 log at upstream 68569d234,
59 commits, each given a verdict, the four quotes and E-ARG
(`$F3/rr3-2_r32_68569d234.txt`); TP-1's Ledger re-cites and its item (c)
count (`$F3/rr3-4_tp1_recites.txt`); the mutant scratch directories of TP-1
and CT-1's mutrun.sh with its probe lists (`$F3/rr3-5_mutants.txt`). Rev 6's
fixer, measured (2026-11-01, ruling fold): `git ls-remote` of all eighteen
heads and of claude/carbon-fork-0-1-safe-wip (14c1ac8ac), unchanged; every
UNMAPPED step's cite opened on its head; the decision-log entries directly
after "Full autonomy" on the heads of PR 52, 54, 55, 58 and 61 (DL-2); the
`W-148` occurrences on 8beb5d7d5 (strings.md 2, row 77 1, the ledger 6) and
W-148's title on 2407efa74; ST-1's eight 2026-10-13 stamps on 8beb5d7d5;
the ST-1 amendment lines on 94dba6b21 (README.md:657, interoperability
README:981) and on 2407efa74 merged onto 5cf7406f1 (arithmetic.md:199);
the refs that file W-160 to W-167; lower/handle.cpp's cross-file FATAL at
:513 on a33d05cae and :524 on d03be4456; `git diff` of CT-1's 118fc1bc8 and
4a3220c11 against 551a03328 over toolchain/, core/ and fork/conformance/
(empty); the 44 upstream commits to TP-1's 32 files in
c1e83b0b7..68569d234; the files OV-4's mutants edit against 5cf7406f1; and
the W-322, W-324 and W-326 notes on 89aabd125 and fee0ef31c. Rev 7's
fixer, measured (2026-11-01, review fold: RR4-1 to RR4-7): `git ls-remote`
of trunk (bb9fbba9c), all eighteen heads and
claude/carbon-fork-0-1-safe-wip (14c1ac8ac), unchanged; D-LAND-22's four
programs compiled with the existing installs of trunk, UA-2, ST-1, SV-1,
TP-1, CT-1, DR-1a, DR-1b and OV-4 and with the 2026.10.12 nightly (no
build; `$F5/probe/`), each install's tree equal to its head's but for
testdata; handle_operator.cpp's assignment check at
bb9fbba9c, 66aa13132 and upstream 68569d234 and TP-1's two hunks there;
W-259 on 66aa13132; the (i) stamp's region on f2110e0fd and its merge
against fee0ef31c on copies (`$F5/rr4-2/`); the runner.py cites of the
ledger and gap rows on 61458bc92 to 5cf7406f1; SV-1's C3 probe log and
mirrors' table; `ninja -t compdb` over carbon-trunk's build file and
clang-tidy 21.1.8's path. Not run
by the planner or the fixers, by rule: any build, gate, autoupdate, mutant
or conformance run; the checkers' `--toolchain` mode; the merged trees'
compilation (the TC-1 and TC-2 files are mechanical references, built first
by stage 10 and stage 11);
the register checks at a tip. Not run by LAND-1, by D-LAND-20 (added
2026-11-01, review fold: RR2-1): every mutant TP-1's and CT-1's plans name
other than the ones D-LAND-20's rules select at PR 61 and PR 64 (predicted:
none of TP-1's, and CT-1's M6, M7, M23, M24, M75 and M75r), each keeping its
record on 66aa13132 or 551a03328 as the PR's A.5 paragraph says; and both
M18s until G-60 and G-59; DR-1's mutants of section 8 item 5 other than C-b's
and OV-4's of section 8.5 other than the file rule's (predicted M1, M2 and
M8), each keeping its record on fee0ef31c or 097c76473; SV-1's M19 and M21
until G-59 (added 2026-11-01, ruling fold: AUD-65-A11 / AUD-68-17 /
AUD-62-S06). Not run by LAND-1 at all: clang-tidy on any file but
handle_index.cpp after C-b, the one C++ file a landing writes beyond either
head's text, which section 2.11 runs it on (amended 2026-11-01, review
fold: RR4-7), the Bazel-only
tests, the BUILD-dependency hooks prek skips, LLVM with assertions, macOS,
Windows and other platforms, and R21's hosted gate, which R33 (b) owes when
Actions returns.

## Hand-off notes

1.  The saved files in `$X/pr<N>/` are references for the resolution, not
    inputs to copy blindly: the PR 64 ledger's W-043 is set to DD-1's side by
    LG-7, PR 63's range_for and PR 65's string_indexing hold trunk's CHECK
    lines until the refill, and the dry run's PR 62 row-68 count is the
    placeholder `<p>/<f>/<s> over <n>`.
2.  Run `$F/bin/gaptally.py fork/gap-analysis.md` in each records commit and
    write the header's first sentence from it by Appendix A.8; run
    `$F/bin/rowcheck.py` as step 9 says.
3.  The google-doc-style hook rewrites some words inside code spans; check
    every records text after prek and restore code by hand (SAFE-1's hand-off
    note 4).
4.  Keep the model-identifier patterns in $P/model_ids.txt, never in the
    repository.
5.  /home/user/carbon-trunk's local trunk is behind origin by records-only
    commits; stage 0's `git pull --ff-only` brings it to the pushed trunk with
    this plan and B.1's stamp.
6.  prek: `cd /home/user/carbon-trunk && XDG_CACHE_HOME=<a private directory
    under the scratchpad>
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <files>` to a fixpoint; the four skipped hooks are
    named in every records commit message (section 0.9).
7.  The state-L texts of section 2.6 are the ones the dry run applied
    (`$F/bin/stateL58.py`); the literals.md note's date is the landing date.
8.  At PR 61, PR 51's split keeps `fail_todo_unformed_dependent_var` and F6
    refills its CHECK lines only; at PR 64, L-F renames it by Appendix C.10
    before the autoupdate. At PR 64 step 4's gate, on the merge, reports that
    split as succeeded ("if success is expected, remove the `fail_` prefix"),
    and at PR 65 it reports slice/write_through.carbon's
    `fail_todo_template_index_with_only` the same way: both are expected,
    counted in
    A.1's `<g0>` and `<gn>`, and resolved by the rename commit (L-F's, L-b's)
    before the refill (sections 2.9 and 2.11; added 2026-11-01, review fold:
    RR2-4). If PR 61's gate reports that split as succeeded, or PR 64's gate
    after the rename commit reports it failed, the toolchain is not the one
    section 0.7 measured: the landing stops (D-LAND-10). The L texts are
    `$F1/bin/extract_l61.py`'s output with `--state-l` and
    `$F1/bin/apply_l64.py` with Appendix C.10's anchor, as
    section 0.5 applied them (added 2026-11-01, review fold: RR1-1 / RR1-2).

## Appendix A: the per-landing record templates

The fields are Appendix C.1's columns for the landing and the placeholders of
the conventions table; nothing else is filled in (amended 2026-11-01, review
fold: B-M5 / B-m3).

### A.1 The merge commit's message

<!-- google-doc-style-ignore -->

```text
Land PR <N>: <title>

Merges claude/carbon-fork-0-1-<suffix> at <head> (PR <N>, base <base>)
into trunk <trunk before> under R33, as fork/land/land1-plan.md section
<spec> specifies.

Conflicts and rules: <conflicts>.

Container-measured on the merge's tree (R33 (b)): build ok; gate <g0>
of <gn> before any refill (each golden that fails is renamed by a
land-time commit that section <spec> names or refilled by this landing's
refill commit, fork/land/land1-plan.md Appendix A.2, which states the
gate after it); conformance <p>/<f>/<s> over <n>, bullets <b> of 56.
prek clean on the resolved files (SKIP=fix-cc-deps,
check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest).

<trailers>
```

The merge's `<g0>` and `<gn>` are step 4's; `<g0>` equals `<gn>` when
nothing fails, and then no refill commit follows. The conformance values of
A.1 are the merge's too; A.3 to A.7 carry the landing's final ones (amended
2026-11-01, review fold: RR1-6). At PR 64 and PR 65 the split that the
landing's section (2.9 or 2.11) renames is among the failures `<g0>` leaves
out (amended 2026-11-01, review fold: RR2-4).

### A.2 The refill commit's message

```text
Land PR <N>: goldens refilled after the merge

Autoupdate (carbonbuild autoupdate.sh, R16) on the files the merged
toolchain changes: <refilled>. CHECK lines only. Gate after: <g> of <g>.

<trailers>
```

### A.3 The Branches row

```text
| `claude/carbon-fork-0-1-<suffix>` | LANDED as PR <N> by merge <merge sha> (<date>, LAND-1, R33; GitHub merged_at <merged_at>, merge_commit_sha <api sha>) — <workstream>: <summary>; land-time commits <land-time shas>; container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; moved to follow-ons: <moved>; R21's hosted gate owed when Actions returns (R33 (b)). |
```

It replaces the PR's row in the Branches table.

### A.4 The dated paragraph and the header

```text
<date> (<hh:mm> UTC): PR <N> (<workstream>) LANDED on trunk by merge
<merge sha> under R33 (fork/land/land1-plan.md section <spec>), GitHub
merged_at <merged_at>; container-measured (R33 (b)): gate <g> of <g>,
conformance <p>/<f>/<s> over <n>, <b>/56 bullets, gap tally <tally>;
id re-scans: <rescan>; <landed> PRs landed, <held> held. Next: <next>.
```

The "id re-scans" clause is added 2026-11-01 (ruling fold: AUD-61-T25 /
AUD-61-T26), as are A.5's and A.6's; TP-1's Appendix E stamp is replaced by
this paragraph and A.3's row.

The paragraph goes directly before the paragraph that begins "Earlier
(post-PR #50, 2026-10-06): UPSTREAM ADVANCE (UA-1) LANDED", after the last
dated paragraph. The header: the current first line's "Last updated: " is
removed and this clause is put before it:

```text
Last updated: <date> (PR <N> landed by LAND-1; <landed> PRs landed,
<held> held; see the paragraph dated <date> (<hh:mm> UTC) below; the
earlier <prev> text follows).
```

### A.5 The Landed paragraph in the PR's plan

```text
<workstream> landed on trunk (LAND-1, <date>): merged as PR <N> by
<merge sha> (head <head>, trunk before <trunk before>; GitHub merged_at
<merged_at>) under R33, fork/land/land1-plan.md section <spec>;
land-time commits <land-time shas>; container-measured (R33 (b)): gate
<g> of <g>, conformance <p> PASS, <f> FAIL, <s> SKIP over <n>, <b> of 56
bullets; id re-scans: <rescan>; moved to follow-ons: <moved>.
```

It goes at the target Appendix C.1's "Plan file and anchor" column names.

### A.6 The decision-log sentence

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR <N> by
<merge sha> (GitHub merged_at <merged_at>); container-measured (R33 (b)):
gate <g> of <g>, conformance <p>/<f>/<s> over <n>; id re-scans: <rescan>;
moved to follow-ons: <moved>.
```

It is the last paragraph of the entry Appendix C.1's "Decision-log entry"
column names (DL-4 when a later merge appends to the same entry). PR 68 takes
Appendix C.13's paragraph in its place.

### A.7 The PR description's Landed line (the orchestrator's)

```text
**Landed** on trunk <date> by merge <merge sha> (LAND-1, R33; GitHub
merged_at <merged_at>): container-measured gate <g> of <g>, conformance
<p>/<f>/<s> over <n>, <b>/56 bullets; moved to follow-ons: <moved>.
Record: fork/ORCHESTRATION.md's paragraph dated <date> (<hh:mm> UTC).
```

It is prepended to the PR's description, which is otherwise unchanged.

### A.8 The gap header's first sentence

Added 2026-11-01 (review fold: RR1-5). At every landing, in
fork/gap-analysis.md's "Scoreboard" section, the text from the paragraph's
start through its first "fork/inventory/work-items.json ledger;" is replaced
by this (the rest of the paragraph, from "the original 2026-07-19 audit read",
stays):

```text
**<t1> DONE / <t2> PARTIAL / <t3> MISSING / <t4> DESIGN-ONLY** across 56
milestone bullets (reconciled <date> at PR <N>'s landing, LAND-1, against
that landing's container-measured conformance scoreboard, R33 (b) — <p>
PASS / <f> FAIL / <s> SKIP over <n> programs, <b>/56 bullets PASS — and the
fork/inventory/work-items.json ledger;
```

### A.9 ORCHESTRATION's Scoreboard paragraph

Added 2026-11-01 (review fold: RR1-5). At every landing, directly under
fork/ORCHESTRATION.md's heading "Scoreboard (source of truth: run the suite,
don't trust this line)", this paragraph is put before the hosted record, in
place of the previous landing's paragraph of this form:

```text
Container-measured at PR <N>'s landing (<date>, LAND-1, R33 (b)): <p> PASS
/ <s> SKIP / <f> FAIL programs (<n> total); **<b>/56 bullets green**; gate
<g> of <g>. R21's hosted run is owed when Actions returns; the paragraph
below is the hosted history; the last hosted scoreboard is
fork/conformance/out/scoreboard.json's (D-LAND-17).
```

The last sentence is amended 2026-11-01 (review fold: RR2-2): the paragraph
below it states 126/23/0 over 149 at PR 48's head (bb9fbba9c
fork/ORCHESTRATION.md:1123-1124), while the last hosted scoreboard is the
committed scoreboard.json's, 128/0/22 over 150 (2026-10-06) on trunk and,
from PR 51 on, run 37413300832's 131/0/19 over 150 (section 0.8).

### A.10 The mark on a landed gap row's labels

Added 2026-11-01 (review fold: RR1-5). Each gap row below carries a "not of
record" label (in any case, "EXPECTED, not of record" among them) that its
PR wrote while it was held, measured on the dry run's scratch commits; the
landing's records commit appends this before the row's closing `|`:

```text
 (Landed <date> as PR <N>, LAND-1: each "not of record" label above is superseded by this landing's container-measured scoreboard, R33 (b), <p>/<f>/<s> over <n> with <b>/56 bullets.)
```

The rows, by landing: PR 52, rows 84 ("Project: toolchain drop-in usage as
Clang C++ toolchain with common Make/CMake build systems") and 87 ("Project:
CMake build-system integration plus Make documentation"); PR 54, row 90
("Project: basic evaluator documentation (getting started to FAQs)"); PR 55,
row 77 ("Stdlib: String and string-literal types"); PR 58, row 70 ("C++
interop: threading, atomics, memory model, synchronization", two labels);
PR 65, rows 79 ("Stdlib: Slices") and 82 ("Stdlib C++ interop: transparent
non-owning contiguous container mapping (incl. owning->view)"); PR 68, row
60 ("Functions: function overloading (Carbon-native)"). No other landing
brings such a label; trunk's rows carry none. Each row is found by its bullet
text. The gap-row check of D-LAND-6 step 9 runs after the mark.

The same label outside the rows (added 2026-11-01, ruling fold: AUD-61-T28 /
AUD-54-07 and the audit's P52-22 note): R33 (b) makes the container
scoreboard R9's record at every landing, so a "not of record" label the
landing brings into a ledger item's `notes`, a prose section of
fork/gap-analysis.md or fork/ORCHESTRATION.md's Scoreboard section
(amended 2026-11-02, PR 61's landing, review round 1: RB61-1; ruling (12):
TP-1's "Expected at TP-1, NOT of record" paragraph, which the merge places under
the Scoreboard heading below A.9's paragraph, takes the mark after its first
sentence), found by `git diff <trunk before> HEAD --
fork/inventory/work-items.json fork/gap-analysis.md fork/ORCHESTRATION.md` and
a search of the
added text for "not of record" in any case, a label broken across two
lines included, takes the mark too: appended to the item's `notes` with a
leading space, or after the sentence that holds the label in the prose,
in this form:

```text
 (LAND-1, <date>: the "not of record" label above is superseded by PR <N>'s landing's container-measured scoreboard, R33 (b), <p>/<f>/<s> over <n> with <b>/56 bullets.)
```

Measured on the dry run's scratch commits (the first commit whose ledger
item's notes match `not\s+of\s+record`), these are: at PR 52 W-060's and
W-061's notes and section W11's arbiter sentence "PASS locally on
nightly 2026.10.12, not of record until a hosted run"; at PR 54 W-062's
notes and
section W11's state C sentence, which the state C commit writes; at PR 55
W-057's notes; at PR 58 W-020's and W-065's notes; at PR 61 W-014's notes,
which take no mark (amended 2026-11-02, PR 61's landing, review round 1:
RV61A-2, RB61-1; ruling (12)): section 2.7 item 13's D replaces them by
Appendix E's land-time text before step 9's search, which then finds no label
(`git diff d13f47ea7 -- fork/inventory/work-items.json fork/gap-analysis.md |
grep '^+' | grep -ciE 'not\s+of\s+record'` gives 0 on the records tree), and
TP-1's item (h) is made by that replacement; at PR 62 W-011's notes; at PR 65
W-109's notes; none at PR 67, 51, 63 and 68, and at PR 64 W-043's notes, where
C.2's "Measured in the container (EXPECTED, not of record, R9)" sentence brings
the label, found by step 9's search (amended 2026-11-02, PR 64's landing, the
implementer's stop at step 9: ruling (15)), and CT-1's "Expected at CT-1, NOT of
record" paragraph, which the merge places in fork/ORCHESTRATION.md's Scoreboard
section and which takes the prose mark after its first sentence, the one ending
"both rows PARTIAL." (A.10's prose rule as ruling (12) item (3b) widened it; the
heads of PR 63, PR 65 and PR 68 bring no such label; amended 2026-11-02, PR 64's
landing, review round 1: RV64-1, ruling (16)), and trunk's own W-321 label is
not a landing's. The plans' own steps for these labels, ST-1's and TP-1's "once
Actions returns ... a records commit" (c3cdecc5d fork/ORCHESTRATION.md:559-562;
66aa13132 fork/templates/plan.md:7935-7936), are made by this mark; R21's hosted
gate stays owed (A.3).

<!-- google-doc-style-resume -->

## Appendix B: the ORCHESTRATION stamps

The orchestrator's texts, verbatim but for the placeholders (amended
2026-11-01, review fold: B-M7 / A-m4 / B-m6 / B-m8).

<!-- google-doc-style-ignore -->

### B.1 At sign-off, before stage 0

The dated paragraph, after the 2026-11-01 (17:42 UTC) paragraph:

```text
<date> (<hh:mm> UTC): LAND-1's plan (fork/land/land1-plan.md, rev <r>) is
signed off and on trunk. Twelve PRs land in this order, each verified in
the container, reviewed, and recorded only after GitHub shows it merged:
PR 67, 51, 52, 54, 55, 58, 61, 62, 64, 63, 65 and 68. Six wait, each for
its follow-on (Next actions items 14 to 17): PR 53 (its realignment, SAFE-3
stopped), PR 60 (W-139
and item 10), PR 56 and PR 57 (W-352 and item 10), and PR 59 with PR 66
(item 13's fix, W-367, and note 7's ruling, D-LAND-2). W-367 to W-370 are
reserved to LAND-1. Eighteen PRs are held open; none is merged yet. The
Branches rows' merge positions are superseded by this order: each landing
rewrites its PR's row, and each waiting PR's row carries a dated mark.
```

In each waiting PR's Branches row, directly after the merge-position clause
quoted first, the mark that follows it (added 2026-11-01, review fold:
RR1-5):

```text
claude/carbon-fork-0-1-safe, after "merges first in the land sequence after RG-1's PR (fork/register/rg1-plan.md section 5)":
 (superseded <date> by LAND-1, fork/land/land1-plan.md D-LAND-12: waits for its realignment, completed under the orchestrator's re-ruling of the C++ boundary question, SAFE-3 having stopped, and lands by Next actions item 14)
claude/carbon-fork-0-1-sc, after "merges after PR 52, before PR 54":
 (superseded <date> by LAND-1, fork/land/land1-plan.md D-LAND-12: lands by Next actions item 15 once W-139's fix and item 10 are done)
claude/carbon-fork-0-1-op, after "merges after PR 55":
 (superseded <date> by LAND-1, fork/land/land1-plan.md D-LAND-12: lands by Next actions item 16 once W-352's commit and item 10 are done)
claude/carbon-fork-0-1-op2, after "merges after PR 56, before DD-1":
 (superseded <date> by LAND-1, fork/land/land1-plan.md D-LAND-12: lands by Next actions item 16 after PR 56)
claude/carbon-fork-0-1-va, after "merges after PR 58":
 (superseded <date> by LAND-1, fork/land/land1-plan.md D-LAND-12: lands by Next actions item 17 once item 13's fix and note 7's ruling are on its branch)
claude/carbon-fork-0-1-va2, after "merges last after PR 65 through M, S-CT, F-M, L-F and L":
 (superseded <date> by LAND-1, fork/land/land1-plan.md D-LAND-12: lands by Next actions item 17 after PR 59)
```

Each quoted clause occurs once in its row at bb9fbba9c (measured).

The header clause, put before the current "Last updated: " line as A.4 says:

```text
Last updated: <date> (LAND-1's plan rev <r> signed off: twelve PRs land
in the recorded order, six wait for their follow-ons; see the paragraph
dated <date> (<hh:mm> UTC) below; the earlier 2026-11-01 text follows).
```

The Next actions lead (:1171-1175), replaced whole by:

```text
LAND-1 comes first (R33, 2026-11-01): fork/land/land1-plan.md (rev <r>,
signed off <date>) lands twelve held PRs into trunk in the recorded
order, each merged when it is correct and verified in the container: PR
67, 51, 52, 54, 55, 58, 61, 62, 64, 63, 65 and 68. Six wait behind their
gates, each landing by its follow-on (items 14 to 17): PR 53 after the
realignment of its branch completed under the orchestrator's re-ruling of
the C++ boundary question (fork/safe/safe3-plan.md D-SAFE3-13 and its rev
11 and rev 12 fold records), PR 60 after W-139 and item 10, PR 56 and PR 57
after W-352
and item 10, and PR 59 and PR 66 after item 13's fix and note 7's ruling.
The items below stand as the work still owed on the branches and after
the landing.
```

In item 2, "It merges last, after PR 65, through its land-time items" becomes:

```text
It lands last, by item 17 after PR 59, through its land-time items
```

In item 6, "held open as PR 68 on claude/carbon-fork-0-1-ov4, base trunk,
merging after PR 66 and before EH-C and UA-3 through M, F-M, L-R and L
(fork/overload/ov4-plan.md section 3);" becomes:

```text
held open as PR 68 on claude/carbon-fork-0-1-ov4, base trunk; LAND-1
lands it twelfth, after PR 65 and before PR 59, PR 60 and PR 66, through
the merge and OV-4's F-M, L-R and L as fork/land/land1-plan.md section
2.12 adapts them, before EH-C and UA-3;
```

In item 6, "the land sequence waits at PR 53 until then" becomes:

```text
PR 53 waits for it by item 14 while LAND-1 lands the ready PRs
```

In item 13, "Request an id for it and route the fix to PR 59 under its own
review:" becomes:

```text
W-367 is reserved for it (fork/land/land1-plan.md D-LAND-13) and is filed
in PR 59's branch's ledger with the fix, which goes to PR 59 under VA-1's
review (item 17):
```

Four items appended after item 13:

```text
14. G-53, PR 53 (fork/land/land1-plan.md D-LAND-12): lands by LAND-1's
    procedure once the realignment of PR 53's branch completed under the
    orchestrator's re-ruling of the C++ boundary question
    (fork/safe/safe3-plan.md D-SAFE3-13 and its rev 11 and rev 12 fold
    records), SAFE-3 having stopped at its plan rev 12 (14c1ac8ac) with PR
    53's pushed head 2407efa74 and W-365 and W-366 reserved and unfiled,
    and once the PR 67 note commit the realignment owes is on trunk as a
    records commit, across the six items' notes, rg1-checks.tsv's H1.7,
    rg1-quotes.tsv's eleven rows, rg1-plan.md's H1.7 and H1.13 with the
    counts and RG-1's decision-log entry (fork/safe/safe2-plan.md, the
    placement of the six items' notes; fork/safe/safe3-plan.md D-SAFE3-10).
    Its land-time steps: ST-1's SAFE-1 reconciliation (W-144's additions,
    the seven edits and the cross-branch re-cites of fork/string/plan.md
    section 2.6 and its landed notes' conditional items, on trunk from PR
    55's landing), ST-1's re-reads of arithmetic.md's Strings section and
    values.md:168 with W-057's evidence re-cited, and W-148's id put back
    where PR 55's landing wrote its title; SAFE-2's DR-1 note that
    `IndirectIndexWith.Ref`, on trunk from PR 65's landing, takes `bound
    self` under W-144, with fork/safe/safe2-plan.md section 0.8's
    counterexample; DD-1's state L for PR 53 (fork/designdocs/plan.md
    section 2.13: assignment.md, threads_and_atomics.md,
    safety/mutation_safety.md, README.md's state-L sentence, as PR 58's
    landing narrowed it to "One section stays TODO-only until held work
    lands", and its "held PR" definition dropped once no page cites a held
    PR, the ALLOWLIST's PR 53 entry removed, W-188's notes, row 91 DONE if
    section 5's condition holds); RG-1's H53 notes, already on the head.
15. G-60, PR 60 (D-LAND-12): once W-139's fix commit is on PR 60's branch
    under SC-1's reviews and item 10 is decided, a merge of trunk into PR
    60's branch (never a rebase) resolving convert.cpp, member_access.cpp,
    merge.cpp and templates.md, with TP-1's S (fork/templates/plan.md
    section 3 item 8) and its mutant M18, TP-1's M rules for SC-1's hunks
    (`PerformAction(ConvertAction)` and `(ConvertToCategoryAction)` keep
    SC-1's check first and A2's `PendingBlock` after it, member_access.cpp's
    includes put `pointer_dereference.h` beside `structural_conformance.h`,
    fork/templates/plan.md section 3 item 7), OV-4's two SC-1 arguments in
    CheckOverloadMemberParamsMatch (fork/overload/ov4-plan.md section 3,
    M's message), DD-1's state L for SC-1 (template_constraints.md, X12
    deleted from the samples and the checker's table, templates.md with
    SC-1's paragraph and then DD-1's section, fork/designdocs/plan.md
    section 2.13), CT-1's PR 60 composition re-measured with t08, t09, t13,
    t14, tc5 and tc6 under its break conditions
    (fork/cpp-templates/plan.md section 0.9), DR-1's test that SC-1's added
    call.cpp and convert.cpp lines create no `TemporaryStorage` return
    argument, pass no `return_arg_id` and add no `ConvertCallArgs` call
    (fork/direction/plan.md section 0.8), item 10's decided commit, fills,
    gate and review; then the trunk landing.
16. G-56/57, PR 56 then PR 57 retargeted to trunk (D-LAND-12): once
    W-352's commit is on PR 56's branch, merged into PR 57's, under OP-1's
    reviews, and item 10 is decided. Steps: loops.md by DR-1's M-a rule
    (fork/direction/plan.md section 1.16) and C.7; error_handling.md with
    both sides' amendments in date order, DR-1a's and OP-1's, by DR-1's
    rule (section 0.8); row 78's DR-0 sentence kept beside PR 57's DONE
    text, as DR-1's C.3 rewrites it (section 1.16); W-323's discharge note,
    DR-1's C.2 text with PR 56's commit 894139b34; DR-1a's m57 refills
    (lower array/iterate, for/break_continue, for/for); CT-1's PR 57
    composition, its red set empty but TP-1's for_range refill, under its
    break condition (fork/cpp-templates/plan.md section 0.9); OP-2's fold
    of W-197 into W-126, W-197's title gaining "(FOLDED into W-126)", W-126
    gaining W-197's OP-2 note and the Optional row, row 43 and optional.md
    naming W-126 again (fork/optional2/plan.md, its ORCHESTRATION item);
    SV-1's Doc-M (optional.md and the F-015 paragraph), its texts
    re-derived under SV-1's section 1.14 document review, since they
    describe the view W-322 retired, C.5's W-177 evidence (its note
    withdrawn), C.8's F-015 references, the W-177 cite in
    match_core_optional_diff.carbon's header, F-M's PR 57 part, the
    nested-pointer leg of cpp_sum_type_roundtrip_diff with its oracle
    (expected `-10 -20 81 -1 -2 81`) and the refill of
    fail_todo_core_optional.carbon only if PR 57's merge changes it
    (fork/sumtype-interop/plan.md section 3 item 8 and section 1.7); DD-1's
    state L for PR 56; RG-1's OP-2 note (W-343), by D-LAND-15's rule.
17. G-59/66, PR 59 then PR 66 retargeted to trunk (D-LAND-12), owned by
    VA-1's workstream: once item 13's fix and W-367 and note 7's ruling
    (W-368 if it makes a fix) are on PR 59's branch under VA-1's review
    and item 2's preconditions hold. Steps: handle_function.cpp by OV-4's
    rule (VA-1's pack gate before OV-4's default look-through); SV-1's
    M-VA with its mutants M19 and M21, and W-284 with its blocked_by W-219
    and its clauses in row 68, the decision-log entry's D-SV-4 and id-list
    clauses, W-011's notes and the SV-1 Branches row
    (fork/sumtype-interop/plan.md Appendix C.6 to C.9); CT-1's S-VA with
    its mutant M18 and C.11's split; TP-1's VA-1 compositions (measured
    none); DR-1's test that VA-1's added call.cpp and convert.cpp lines
    create no `TemporaryStorage` return argument, pass no `return_arg_id`
    and add no `ConvertCallArgs` call (fork/direction/plan.md section 0.8);
    RG-1's VA-1 note, by D-LAND-15's rule, and W-343's discharge if it is
    the last; then VA-2's
    own M, S-CT, F-M, L-F and L
    (fork/variadics/va2-plan.md section 3 item 15) over convert.cpp,
    eval.cpp and handle_function.cpp.
```

Items 15 and 17 name TP-1's and CT-1's mutant M18 with the step it reverts
(amended 2026-11-01, review fold: RR2-1; D-LAND-4 and D-LAND-20). Item 14
restates PR 53's gate by the ruling's item 2, and items 14 to 17 name the
moved steps the completeness audit added to D-LAND-4; item 16 says
error_handling.md's rule is DR-1's, where rev 5 credited DD-1, whose head
leaves that page untouched (amended 2026-11-01, ruling fold: the ruling's
item 2, AUD-55-11, AUD-55-22, AUD-65-F2, AUD-61-T06, AUD-64-a5, AUD-65-A15,
AUD-51-E20, AUD-64-a6, AUD-63-11, AUD-63-12, AUD-63-21, AUD-62-S06,
AUD-62-S09, AUD-62-S12, AUD-62-S23, and the audit's MV2, MV4, MV5 and N6
notes).

### B.2 After the twelfth landing

```text
<date> (<hh:mm> UTC): LAND-1 stages 1 to 12 are done: 12 PRs landed, 6
held. Trunk <trunk before> holds PR 67, 51, 52, 54, 55, 58, 61, 62, 64,
63, 65 and 68, verified in the container at each landing (final: gate
<g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; gap tally
<tally>); R21's hosted gate is owed on all twelve when Actions returns
(R33 (b)). Held: PR 53, PR 60, PR 56, PR 57, PR 59 and PR 66, each
landing by Next actions items 14 to 17 when its gate holds.
```

Here `<trunk before>` is origin/trunk after stage 12's phase 2, measured as
the conventions say, and the other values are stage 12's.

<!-- google-doc-style-resume -->

## Appendix C: each landing's fields, targets and own texts

Added 2026-11-01 (review fold: B-M5 / B-M1 / B-M6 / B-M7 / A-M1 / A-M2 / A-m4
/ B-B1). The texts are verbatim but for the placeholders.

<!-- google-doc-style-ignore -->

### C.1 The fields and the targets

The fields of Appendix A, by landing, each column filling the placeholder
of its name, `<N>` the PR column's (added 2026-11-02, sign-off check;
`<moved>` is "none" where the column is
empty; PR 61's and PR 64's Moved cells name M18, amended 2026-11-01, review
fold: RR2-1):

| PR | Suffix | Spec | Workstream | Title | Summary | Moved | Next |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 67 | rg1 | 2.1 | RG-1 | RG-1, the V-3a register classified against upstream | records only: the V-3a register classified at upstream f27a977d8; W-342 and W-344 discharged, W-343 narrowed to the land-time notes, W-346 to W-356 filed | none | PR 51 (UA-2) |
| 51 | ua2 | 2.2 | UA-2 | UA-2, upstream reconciliation | the reconciliation of the 2026-10 upstream advance, with the container fill f96fe8a7a (1945 of 1945) and hosted conformance 37413300832 (131/0/19 over 150) | none | PR 52 (CM-1) |
| 52 | cmake | 2.3 | CM-1 | CM-1, CMake language modules, examples/cmake and Make documentation | CMake language modules, examples/cmake and the Make documentation; gap rows 84 and 87 DONE; W-060 and W-061 discharged, W-128 to W-133 filed | none | PR 54 (EV-1) |
| 54 | ev | 2.4 | EV-1 | EV-1, evaluator documentation | the evaluator guides and transcribed programs, in state C with PR 52; gap row 90 DONE; W-062 discharged, W-152, W-153 and W-155 filed | none | PR 55 (ST-1) |
| 55 | st | 2.5 | ST-1 | ST-1, str comparison, Core.StringBuf and concatenation | F-014: str comparison, Core.StringBuf and concatenation; gap row 77 DONE; W-057 discharged, W-160 to W-167 filed | to Next actions item 14: W-144's additions, the seven SAFE-1 reconciliation edits and the cross-branch re-cites | PR 58 (DD-1) |
| 58 | dd | 2.6 | DD-1 | DD-1, design docs without placeholders | design docs without placeholders, with state L for PR 51, PR 54 and PR 55; gap row 70 DONE, row 91 PARTIAL until state L for PR 53, PR 56 and SC-1; W-065 discharged | to items 14, 15 and 16: state L for PR 53, SC-1 and PR 56 | PR 61 (TP-1) |
| 61 | tp | 2.7 | TP-1 | TP-1, integrated templates | integrated templates with F6's refills (PR 51's split refilled under its fail_todo_ name, which PR 64's L-F renames) and L over PR 58; W-127 for the template shape, W-183, W-192 and W-193 discharged; gap row 54 PARTIAL | to item 15: S and its mutant M18; to item 17: the VA-1 compositions | PR 62 (SV-1) |
| 62 | sv | 2.8 | SV-1 | SV-1, std::optional and std::variant interop mapping | F-020: std::optional and std::variant interop mapping; W-011 DISCHARGED; W-284 held until M-VA lands (item 17); gap row 68 PARTIAL | to item 17: M-VA and W-284; to item 16: Doc-M, C.5, C.8, the W-177 header cite and F-M's PR 57 part | PR 64 (CT-1), after the orchestrator retargets it to trunk |
| 64 | ct | 2.9 | CT-1 | CT-1, C++ templates on symbolic Carbon type arguments | F-021: C++ templates on symbolic Carbon type arguments, instantiated per specific; PR 51's split renamed unformed_dependent_var by L-F (C-2); W-043 DISCHARGED; gap rows 56 and 42 PARTIAL | to item 17: S-VA with its mutant M18, and C.11's split | PR 63 (DR-1a) |
| 63 | dr | 2.10 | DR-1a | DR-1a, Core.Iterate.Next takes a ref cursor | R32: Core.Iterate.Next takes a ref cursor; W-321 discharged | to item 16: loops.md's M-a rule and the m57 refills | PR 65 (DR-1b), after the orchestrator retargets it to trunk |
| 65 | dr-idx | 2.11 | DR-1b | DR-1b, subscripting prefers IndirectIndexWith | R32: subscripting prefers IndirectIndexWith and Core.Slice and Core.Buf write through Ref, with C-b over TP-1; W-109 and W-340 discharged; gap row 79 DONE | none | PR 68 (OV-4) |
| 68 | ov4 | 2.12 | OV-4 | OV-4, `overload fn` members with default parameter values | W-341 DISCHARGED: `overload fn` members with upstream's default parameter values; W-360 to W-363 to UA-3 | to item 15: SC-1's two arguments; to item 17: VA-1's pack gate order | Appendix B.2's stamp, then the follow-ons |

`<moved>` also names the steps the completeness audit moved, appended to the
cell above with "; " (added 2026-11-01, ruling fold: the AUD ids of
D-LAND-4): PR 51, "to item 16: OP-2's fold of W-197 into W-126"; PR 55,
"to item 14: the re-reads of the pages SAFE-1 moves and W-148's id"; PR
61, "to item 15: M's rules for SC-1's hunks"; PR 62, "to item 17: M-VA's
mutants M19 and M21 and W-284's clauses; to item 16: the nested-pointer
leg and Doc-M's re-derivation"; PR 64, "to items 15 and 16: its PR 60 and
PR 57 compositions"; PR 63, "to item 16: error_handling.md's rule, row
78's DR-0 sentence and W-323's note"; PR 65, "to items 15 and 17: DR-1's
call.cpp and convert.cpp test; to item 14: SAFE-2's DR-1 note". PR 55's
A.6 target is its heading as section 2.5's re-stamp commit leaves it,
`### ST-1 / F-014: str comparison, Core.StringBuf, concatenation (<date>)`
(amended 2026-11-01, ruling fold: AUD-55-09).

The targets of A.5 and A.6 (each anchor checked unique on the dry run's tree):

| PR | Plan file and anchor (A.5) | Decision-log entry (A.6) |
| --- | --- | --- |
| 67 | fork/register/rg1-plan.md, the end of the file (its last section, "Landed notes (RG-1, 2026-10-28)") | `### RG-1: the V-3a register classified at f27a977d8 (2026-10-28)` |
| 51 | fork/upstream/plan.md, the end of the file, under a new heading `### Landed notes (UA-2, LAND-1)` after the section "Landed notes (UA-1, 2026-10-06)" | `### Upstream reconciliation 2026-10 (UA-2)` |
| 52 | fork/cmake/plan.md, the end of the file ("Landed notes (discharge, 2026-10-12)") | `### CM-1: CMake language modules, example project, Make documentation (2026-10-12)` |
| 54 | fork/evaluator/plan.md, the end of the file ("Landed notes (EV-1)") | `### EV-1: evaluator documentation: getting started, tutorial, FAQ, transcribed programs (2026-10-13)` |
| 55 | fork/string/plan.md, the end of the file ("Landed notes (ST-1, 2026-10-13)") | `### ST-1 / F-014: str comparison, Core.StringBuf, concatenation (2026-10-13)` |
| 58 | fork/designdocs/plan.md, the end of "Landed notes (DD-1, 2026-10-14)", before `## Document-review fold 2 (2026-10-14)` | `### DD-1: design docs without placeholders (2026-10-14)` |
| 61 | fork/templates/plan.md, the end of "Landed notes (TP-1, 2026-10-14)", before `## Focused re-review of the fold (2026-10-15)` | `### TP-1: integrated templates (2026-10-14)` |
| 62 | fork/sumtype-interop/plan.md, the end of "Landed notes (SV-1, 2026-10-21)", before `## Focused re-review of the fold, round 1 (2026-10-21)` | the level-3 heading "SV-1 / F-020: `std::optional` and `std::variant` interop mapping (2026-10-21)" |
| 64 | fork/cpp-templates/plan.md, the end of "Landed notes (CT-1, 2026-10-21)", before `## Appendix A: golden sources` | `### CT-1: C++ templates on symbolic Carbon type arguments (2026-10-21)` |
| 63 | fork/direction/plan.md, the end of "Landed notes (DR-1a, 2026-10-21)", the end of the file at this landing | `### DR-1: direction realignment: the ref cursor, IndirectIndexWith, D-SV-7 retired, Match stopped on upstream's conflict (2026-10-21)` |
| 65 | fork/direction/plan.md, the end of "Landed notes (DR-1b, 2026-10-22)", the end of the file after PL-1 | DR-1's entry, after PR 63's sentence (DL-4) |
| 68 | fork/overload/ov4-plan.md, the end of the file, under a new heading `## Landed notes (OV-4, LAND-1)` | the level-3 heading "OV-4: `overload fn` members with default parameter values (W-341) (2026-10-28)", with C.13's paragraph |

### C.2 PR 67's own texts

In fork/register/rg1-plan.md section 5, after "Until then the land sequence is
held at PR 53, the second in the order after RG-1's own PR (amended 2026-10-28,
implementation review: R2-m1).", and after "it does not skip it, because each
later PR's records and merge-trees assume the earlier ones.", each:

```text
 (Superseded <date> by LAND-1's D-LAND-1, fork/land/land1-plan.md: PR 53
waits for its realignment, SAFE-3 having stopped, by its follow-on while
the ready PRs land past it, the dry run of that plan's section 0.5 having
measured that their records and merge-trees hold without the waiting
PRs.)
```

The same mark, after each of the six other lines that restate the
superseded order (added 2026-11-01, ruling fold: AUD-67-P11): in
rg1-plan.md, after "so these six gate the land sequence (section 5; amended
2026-10-28, review fold: A-M5, B-M3)." (:865-867), "PR 60
is fifth in the order." (:1630), "PR 56 is eighth (the ordinals count RG-1's
PR; amended 2026-10-28, implementation review: R2-m1)." (:1632-1633), "the
land sequence stops at PR 56 (amended 2026-10-28, review fold: A-M2)."
(:1679-1680) and "while PR 53, first in the land sequence, waits on it"
(:1730-1732), and in RG-1's decision-log entry after "and PR 53 lands first
after RG-1's PR (fork/register/rg1-plan.md section 5)." (56e2e5bbd
fork/decision-log.md:376-377), each anchor once on 56e2e5bbd.

After section 6's rejected alternative's last words, "with W-144's
renumbering as its own records commit." (rg1-plan.md:1699-1707; added
2026-11-01, ruling fold: AUD-67-P12; the text amended 2026-11-01, review
fold: RR4-3, because the break condition is not met, PR 56, PR 57, PR 59
and PR 60 not being ready):

```text
 (Superseded <date> by LAND-1's D-LAND-1 under R33, fork/land/land1-plan.md, which lands the ready PRs before PR 53 without this break condition being met; the renumbering commit is moot, SC-1's W-144 having been renumbered W-151 on PR 60's branch by 2f4ebbf6e.)
```

Appended to W-343's `notes` (restated 2026-11-01, ruling fold: the ruling's
item 2):

```text
 LAND-1 (<date>, fork/land/land1-plan.md, R33): landings resume; PR 53 waits for its realignment, SAFE-3 having stopped at its plan rev 12 (Next actions item 14), while the ready PRs land; the land-time notes of PR 51, PR 54 and PR 58 are made by their landings and those of PR 57 and PR 59 by items 16 and 17, the last of them discharging this item (D-LAND-15).
```

Appended to W-355's `notes` at each landing D-LAND-19 names, `<N>` that
landing's PR (amended 2026-11-01, ruling fold: AUD-67-P28 / AUD-68-15):

```text
 LAND-1 (<date>, PR <N>'s landing): at upstream <tip>, check_quotes.sh reports <q> quotes with <qf> failed and check_greps.sh <c> silence checks with <cf> failed over the tables as that landing leaves them (at 68569d234, 2026-11-01, as PR 67 landed them: 273 with 8 failed and 89 with 2 failed); the failing rows, <the FAIL rows' ids>, are this item's to re-read by its own rules, an L check's expected count included (fork/register/rg1-plan.md:1398-1401); the landing edits no row and no expected count.
```

The last placeholder is the scripts' own output, listed as printed, or
`none` (the conventions table; amended 2026-11-02, sign-off check). The cite
names the L-check rule's lines in the tree the records commit produces:
:1394-1397 at the merge, :1398-1401 once PR 67's records edit adds its four
lines at :867, re-measured at each later landing that edits rg1-plan.md above
the rule (amended 2026-11-02, fold check FC1-1 at PR 67, by D-LAND-9's break
condition as the ruling states it). In Next
actions item 6, "is held open as PR 67, first in the land sequence" becomes
"landed on trunk <date> as PR 67 by merge <merge sha> (LAND-1)".

### C.3 PR 51's own texts

RG-1's note "[UA-2, PR 51, after its :6232]" of rg1-plan.md Appendix A.4,
its text :2534-2542 without the locator line :2533, verbatim with `<tip>`
D-LAND-19's and every "2026-10-27" read "2026-10-28" by D-LAND-15's date
rule (amended 2026-11-01, ruling fold: AUD-51-E16 / AUD-67-P25), inserted
as a paragraph after
the paragraph of UA-2's decision-log entry that ends "with block 9's SL-1
trigger met for fields, as just recorded." If a FAIL row of D-LAND-19 is one of
the note's own quotes or checks, "re-checked at <tip>" is followed by "(<the
FAIL rows' ids> fail there; W-355)". OR-5: no item.

### C.4 PR 52's own texts

The "not of record" labels of W-060's and W-061's notes and of section
W11's arbiter sentence take A.10's mark (added 2026-11-01, ruling fold:
the audit's P52-22 note). OR-5: appended as the last Next actions item
(numbered next):

```text
W-128: install the cmake/ language modules into the toolchain tree
(lib/carbon/cmake/ beside the Bazel files, with a CarbonConfig.cmake for
`find_package(Carbon CONFIG)`) and add a Bazel-side integration test of
examples/cmake — needs a toolchain/install/BUILD change that can only be
built and tested with bazel, so it waits for an arbiter; then the example
drops its relative CMAKE_MODULE_PATH. (Carried <date> from PR 52's branch
by LAND-1; the container arbiter builds without Bazel, so the wait
stands.)
```

### C.5 PR 54's own texts

RG-1's note "[EV-1, PR 54, after its :3549]" (rg1-plan.md:2545-2550, with the
UA-2 lead in place of "...", as A.4 says, by D-LAND-15's rule; amended
2026-11-01, ruling fold: AUD-67-P25), after the paragraph of EV-1's entry
that ends "the pointers are re-placed in that merge. Veto-able."

The state C commit's texts (added 2026-11-01, ruling fold: AUD-54-07 /
AUD-54-08 / AUD-54-09). In section W11 of fork/gap-analysis.md as the merge
leaves it (trunk's side, CM-1's text), the sentence from "Evaluator docs
remain thin" through "is W-062 and stays open." becomes EV-1's state C
sentence (cb3ef2e74 fork/evaluator/plan.md:1655-1661) with `<date>` for
its "2026-10-DD":

```text
The evaluator guides LANDED with EV-1 (fork/evaluator/plan.md, <date>):
docs/guides/getting_started.md, tutorial.md and evaluator_faq.md beside
the build-systems guide; W-062 is discharged.
```

and "(W-062, open)." becomes EV-1's (:1661-1665), verbatim, its label
taking A.10's mark in the records commit:

```text
(met at EV-1, W-062 discharged: docs/guides/tutorial.md, its samples
transcribed into project/evaluator_tutorial_*, ten PASS locally, not of
record until a hosted run; the fork's build-from-source block is quoted
from the hosted job, not run).
```

Appended to W-131's `notes` (section 2.F.2, :1683-1685, from section 0.1
row 11, :117):

```text
 EV-1 (state C, <date>, LAND-1): a C-ABI object with no standard library, compiled by g++ 13 or by the system clang++ 21.1.8, links under `carbon link` (fork/evaluator/plan.md section 0.1 row 11); a function using `std::string` compiled by either fails to link (`ld.lld: error: undefined symbol: std::__cxx11::basic_string<...>`), and compiled by `carbon clang` it links.
```

Appended to W-133's `notes` (:1685-1686):

```text
 EV-1 (state C, <date>, LAND-1): docs/guides/evaluator_faq.md's entry "The short output flag needs an equals sign" documents the workaround.
```

In W-002's `notes`, "the C++-library tutorial program waits for PR 52's
BUILD-SCRIPT channel (SKIP in the meantime, D-EV-12)." becomes
(section 0.2 item 9's state C sentence, :1677-1679):

```text
answered for the C++-library tutorial program by the BUILD-SCRIPT channel (state C at PR 54's landing, <date>, LAND-1; D-EV-12).
```

Re-pin note (added 2026-11-02, R54-2, the orchestrator's ruling under R29): in
EV-1's decision-log entry, inside the parenthetical "(:564-575)" that the state
C commit re-pinned, the records commit appends after the cite "; re-pinned at
the landing, 2026-11-02, LAND-1: the merged runner's `run_cmd` is PR 52's,
with `cwd` and `env` parameters that the compile, link and run calls
at :700, :727 and :748 leave unset".

Ledger re-cites (added 2026-11-02, R54-3, the orchestrator's ruling under
R29), by C.8's re-cite rule, measured on the records tree: W-062's evidence
"fork/gap-analysis.md:93 (row 90, DONE on transcription plus document review;
the header's three added lines moved it from :90)" becomes
"fork/gap-analysis.md:91 (row 90, DONE on transcription plus document review;
the header's three added lines moved it from :90, and LAND-1's header rewrites
to :91, re-pinned 2026-11-02 at PR 54's landing)", its
"fork/gap-analysis.md:264-281 (the W11 paragraph and arbiter, with the EV-1
notes)" becomes "fork/gap-analysis.md:266-290 (the W11 paragraph and arbiter,
with the EV-1 notes; re-pinned 2026-11-02 at PR 54's landing)", and W-060's
"fork/gap-analysis.md:262-283 (§W11 rewritten)" becomes
"fork/gap-analysis.md:262-290 (§W11 rewritten; re-pinned 2026-11-02 at
PR 54's landing, whose state C text and A.10 marks extended the section)".

OR-5:
appended as the last Next actions item:

```text
W-152 (EV-1 residue), after the owner's Actions decision: publish a
current fork toolchain artifact from a Bazel build of record and retire
or relabel the stale `fork-toolchain-*` prereleases;
docs/guides/getting_started.md then gains its download path (D-EV-5's
break condition). (Carried <date> from PR 54's branch by LAND-1.)
```

### C.6 PR 55's own texts

After "The merge steps are Next actions item 5; the SAFE-1 reconciliation ST-1
owes at its rebase is item 6." in ST-1's dated paragraph:

```text
 (Amended <date> by LAND-1: PR 55 landed by merge <merge sha>, which made
the merge steps; the SAFE-1 reconciliation is Next actions item 14's,
for PR 53.)
```

OR-5: the branch's item 5 is discharged by the landing (the message says so)
and item 6 is item 14's text.

The re-stamp commit (section 2.5; added 2026-11-01, ruling fold:
AUD-55-09), by ST-1's item 5 (c3cdecc5d fork/ORCHESTRATION.md:540-547),
each text found once on the merge (measured on 8beb5d7d5): in
docs/design/strings.md's status line, "**Fork design (F-014, 2026-10-13):"
becomes "**Fork design (F-014, <date>):" and "status: ST-1 landed
2026-10-13.**" becomes "status: ST-1 landed <date>.**"; "> **Fork amendment
(2026-10-13, F-014)" becomes "> **Fork amendment (<date>, F-014)" in
docs/design/README.md, docs/design/expressions/arithmetic.md and
docs/design/interoperability/README.md, once each; W-057's title "ST-1
(LANDED 2026-10-13): W9c: string equality, concatenation, and owning
variant" becomes "ST-1 (LANDED <date>): W9c: string equality,
concatenation, and owning variant"; "W-057 DISCHARGED 2026-10-13" becomes
"W-057 DISCHARGED <date>" in fork/gap-analysis.md, twice, in row 77 and in
section W9; and the decision-log heading "### ST-1 / F-014: str comparison,
Core.StringBuf, concatenation (2026-10-13)" becomes "### ST-1 / F-014: str
comparison, Core.StringBuf, concatenation (<date>)". Other "2026-10-13"
dates, the discharge's own records among them, are not landing stamps and
stay.

The W-148 commit (section 2.5; added 2026-11-01, ruling fold: AUD-55-11),
by ST-1's item 5 (:548-552) and fork/string/plan.md:2301-2305: each
`W-148` in docs/design/strings.md, row 77 of fork/gap-analysis.md and
fork/inventory/work-items.json (measured on 8beb5d7d5: 2, 1 and 6, the
ledger's in its `source` field, W-057's notes and W-166's notes) is
replaced by W-148's title as 2407efa74's ledger gives it, in double
quotes (escaped in the JSON), followed by " (on held PR 53's ledger)":

```text
"SAFE-1 residue: stage 4 loan checker — loans T1 to T8 over SemIR's block graph (NLL liveness), the Store rule, `bound` per T5 (a)-(e), `exclusive T*` and the reborrow/same-kind-copy clauses, the no-invalidation rule M3 with `Core.Plain` synthesis, `addr self` body checks, M5 payload sub-loans, M8 value-binding loans with the Debug shadow count (`MutationDuringValueBinding`), `Core.Guarded(T)`, `Core.Relocatable`/`Core.Move`/`~x`, `noalias`/`captures(none)` under T8, `--strict-checks=error` as the default"
```

ST-1's rule names those three files; ST-1's decision-log entry, a dated
record that names the SAFE-1 branch, keeps the id. G-53 puts the id back
where this commit wrote the title (item 14).

In row 77, "floor of record 128/0/22 over 150, run 37402970811" becomes
(ST-1's "re-read at rebase", fork/string/plan.md:2230-2232; added
2026-11-01, ruling fold: AUD-55-05):

```text
floor of record 131/0/19 over 150, run 37413300832 (re-read <date> at PR 55's landing, LAND-1: the committed scoreboard.json, D-LAND-17)
```

PR 55's A.5 Landed paragraph ends with this sentence (added 2026-11-01,
ruling fold: the audit's S55-01 note):

```text
The merge of trunk 9d3ca60a3 that this plan's landed notes and the decision-log entry record as refused at the discharge was made on the branch afterwards, by 21307851a, which the landed head c3cdecc5d contains.
```

Header clause (added 2026-11-02, RV55-1, the orchestrator's ruling under R29;
GA-2's PR text for the header): in the gap header's paragraph, "and CMake
build-system integration with Make documentation have since landed" becomes
"and CMake build-system integration with Make documentation, and string
comparison, the owning `Core.StringBuf` and concatenation have since landed",
the PR's clause (c3cdecc5d fork/gap-analysis.md:31-32), written by the records
commit; it moves every row down one line.

Line re-pins (added 2026-11-02, RV55-2, the orchestrator's ruling under R29),
by C.8's re-cite rule, row 77 at :79 and row 41 at :43 on the records tree: in
the ST-1 decision-log entry, "fork/gap-analysis.md row 77, now line 81, reads"
becomes "fork/gap-analysis.md row 77, now line 79 (line 81 on the branch;
re-read 2026-11-02 at PR 55's landing, LAND-1), reads"; W-057's evidence
"(line 81 on this branch after the header edit)" becomes "(line 81 on this
branch after the header edit; line 79 on trunk, re-read 2026-11-02 at PR 55's
landing, LAND-1)"; W-167's evidence "line 45 on this branch)" becomes "line 45
on this branch, line 43 on trunk, re-read 2026-11-02 at PR 55's landing,
LAND-1)".

### C.7 PR 58's own texts

The state-L commit (D-LAND-14; `$F/bin/stateL58.py` applies exactly these):

-   docs/design/templates.md, twice: "(fork work item W-127, held PR 51)"
    becomes "(fork work item W-127)".
-   docs/design/interoperability/README.md: "(fork work item W-043, and W-127
    on held PR 51)" becomes "(fork work item W-043, and W-127)".
-   docs/design/pattern_matching.md: "is rejected (fork work item W-155, on
    held PR 54)." becomes "is rejected (fork work item W-155)."
-   docs/design/blocks_and_statements.md: "arm (fork work item W-155, on held
    PR 54)." becomes "arm (fork work item W-155)."
-   docs/design/assignment.md: "work item W-167, on held PR 55)." becomes
    "work item W-167)."
-   docs/guides/tutorial.md and docs/guides/evaluator_faq.md: the two EV-1
    sentences of DD-1's section 2.13, verbatim.
-   fork/designdocs/check_samples.py: the `ALLOWLIST` line
    `("expressions/arithmetic.md", "Strings", "c"): "held PR 55 (ST-1)",` is
    deleted.
-   docs/design/expressions/literals.md and docs/design/README.md: the two
    texts below.

After literals.md's line "No design for string types has been through the
proposal process yet.", a blank line and:

```markdown
> **Fork note (<date>).** Fork decision F-014 designs the string types; see
> [Strings](../strings.md).
```

In README.md's disclosure note, the four lines from "> Two sections stay
TODO-only until held work lands:" to "> (held PR 55). The provisional notes
that remain qualify the text beside" and the next line's "> them." become:

```markdown
> One section stays TODO-only until held work lands:
> [Lifetime and move semantics](#lifetime-and-move-semantics) (held PR 53).
> The provisional notes that remain qualify the text beside them.
```

The records commit, besides A.3 to A.6: the evidence entries appended (DD-1
section 2.14 and section 8.5), one string each:

```text
W-014: check/import_ref.cpp:5087 FATAL, TryResolveInstCanonical on SpliceInst (nightly 2026.10.12: import_ref.cpp:4875): a template function called from another library crashes check (DD-1 probe PR-A, 2026-10-13)
W-014: fork/designdocs/samples/X13 to X16 (the operators `*`, `->` and `&` and tuple element access on a template-dependent value, rejected at the definition), X17 with generic/template/call.carbon's split (calls of a template-dependent value) and probe PR-AK (the lowering of template-dependent tuples, lower/aggregate.cpp:67, values that differ from run to run) (DD-1, third document-review fold, 2026-10-14)
W-014: fork/designdocs/samples/X28 (a `for` loop whose range depends on a template parameter, inst.h:249 while checking the loop's header, PR-AN), X29 to X31 with PR-AO and PR-AK's h01 (returning a tuple, struct or array built from a template parameter: a crash during checking, in ResolveSpecificDefinition; the nightly 2026.10.12 runs the array form, X31), X32 (a class template's method returning `(T, T)`, lowering, function_context.cpp:223) and X33 (the third fold's tuple destructuring) (DD-1, fourth document-review fold, 2026-10-14)
W-127: fork/designdocs/samples/X20 and X23 (`var y: T;` for a template parameter, rejected) (DD-1, third document-review fold, 2026-10-14)
W-155: DD-1 fixture R20 (`IsTrue`, pattern_matching.md :613-618) and probe PR-L (an irrefutable `case x: i32` arm and an irrefutable struct arm, both rejected)
W-167: DD-1 probe PR-I: `var s: Secret = {.x = 1}; s = {.x = 2};` for a class whose one field is `private`, outside the class, accepted on the fork and the nightly
```

W-155's cite of pattern_matching.md is re-measured after the state-L edits and
the line range corrected if it moved. Appended to W-043's `notes`:

```text
 LAND-1 (<date>): the SKIP of fork/conformance/programs/interop/cpp_template_symbolic_arg.carbon that DD-1's sentence above calls stale was removed by PR 51 (UA-2 round 1), which landed before PR 58.
```

In row 91, after "the two W2 allowlist entries":

```text
 (PR 55's section and its entry done at PR 58's landing, LAND-1, <date>; PR 53's remains, with PR 56's interop link and SC-1's template-constraints link, D-LAND-14)
```

RG-1's note "[DD-1, PR 58, after its :4129]" (rg1-plan.md:2563-2570, with
the UA-2 lead in place of "...", `<tip>` D-LAND-19's and the 2026-10-28
dates, by D-LAND-15's rule; amended 2026-11-01, ruling fold: AUD-58-U8),
after the paragraph of DD-1's entry that ends "DR4b-8), the page states
both. Veto-able."

The state-L commit's message (added 2026-11-01, ruling fold: AUD-58-U2 /
AUD-58-U3):

```text
Land PR 58: DD-1 state L for PR 51, PR 54 and PR 55

DD-1's state L in part (fork/designdocs/plan.md section 2.13, as
fork/land/land1-plan.md D-LAND-14 and Appendix C.7 split it by PR): the
held-PR citations of PR 51, PR 54 and PR 55, the EV-1 sentences, the
literals.md note, the README disclosure narrowed to PR 53's section and
the ALLOWLIST entry for arithmetic.md's "Strings" removed.

W2 expected: 2 hits, 1 allowlisted and 1 qualified (the dry run's
94dba6b21); check_samples.py: <dd>; with --toolchain: <ddt>; the
nineteen programs on nightly 2026.10.12 (DD-1 section 8 item 1): <ddn>;
runner.py --self-test: OK; conformance <p>/<f>/<s> over <n>. R31 of the
nine markdown files (headings, bullets, numbered, rows): <r31>; heading
sets before and after compared with comm, none added or lost; no
manufactured heading. prek clean
(SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest).
Not run, DD-1's section 8.10 list:

<trailers>
```

DD-1's section 8.10 Not-run list follows its line, verbatim as fcee90d9b
fork/designdocs/plan.md section 8.10 gives it (DD-1's section 8 item 1,
:5592-5607), before the trailers.

The `--self-test` join (section 2.6; added 2026-11-01, ruling fold:
AUD-58-U1), "Land PR 58: DD-1's checker joins runner.py --self-test
(D-DD-6)": in fork/conformance/runner.py, beside the
`evaluator_samples_self_check()` that EV-1's state C commit added, a
function `designdocs_samples_self_check()` that is the same code with
fork/designdocs/check_samples.py for EV-1's path,
`designdocs-samples self-check` for its label and `module.main([])` for its
call, DD-1's `main()` gaining in the same commit the `argv` parameter an
in-process caller needs (`def main(argv: list[str] | None = None) -> int:`,
`parser.parse_args(argv)`; standalone use unchanged), because written as the
same code the hook exits 2 under `runner.py --self-test`, argparse reading the
runner's `sys.argv` (amended 2026-11-02, the implementer's stop at step 6, the
orchestrator's ruling under R29), called right after it,
only when `--self-test` has no filter (EV-1's section 2.E.4, cb3ef2e74
fork/evaluator/plan.md:1580-1586); it runs DD-1's checker without
`--toolchain`, so its toolchain-free checks join, as D-DD-6 says. The same
commit re-pins section 2.4's runner.py cites, EV-1's decision-log entry's
and the `evidence` of W-002 and W-060, by C.8's re-cite rule against the
runner it leaves (added 2026-11-01, review fold: RR4-4).

The records commit's further texts (added 2026-11-01, ruling fold:
AUD-58-U4 / AUD-58-U6 / AUD-58-U7): in fork/inventory/work-items.json's
`source`, "W-192..W-194 spare; OP-2 reserves W-196..W-199);" becomes
"W-192..W-194 spare; OP-2 reserves W-196..W-201);"; W-057's and W-161's
evidence cites of docs/design/README.md and
docs/design/interoperability/README.md are re-cited by C.8's re-cite rule
(:636 to :657 and :303 to :981 on 94dba6b21); and PR 58's A.5 Landed
paragraph and A.6 sentence each end with:

```text
D-DD-9's break condition fired, PR 58 landing before SC-1 and PR 53: W-187 stays unused, because the remaining state-L texts are land-time steps of Next actions items 14 to 16 (fork/land/land1-plan.md D-LAND-14) and row 91's mark names them. The sentences that F-016 "stays unallocated" were re-read against trunk: F-016 is OP-2's, minted on held PR 57 (fork/ORCHESTRATION.md), and DD-1 mints no fork design id (D-DD-3).
```

OR-5: DD-1's note, verbatim after item 3's text:

```text
    (Corrected 2026-10-14 at the DD-1 discharge: the gate dissolved under
    R29; F-009's and F-011's pages have landed, F-010's page is SC-1's, and
    F-008's page is docs/design/interoperability/threads_and_atomics.md,
    DD-1, so the stranded branch's F-008 draft is not ported; see its
    Branches row.)
```

Re-pin (added 2026-11-02, FC55-2 at PR 55, the orchestrator's ruling under
R29): in the ST-1 decision-log entry's D-ST-16 paragraph,
"(gap-analysis.md:241-244)" becomes "(gap-analysis.md:246-249,
re-pinned 2026-11-02 at PR 58's landing, LAND-1; :241-244 on ST-1's branch)",
the lines of section W9's Arbiter paragraph measured on this landing's records
tree.

### C.8 PR 61's own texts

TP-1's: L's texts are 66aa13132 fork/templates/plan.md Appendix C (:16086 on),
adapted to PR 58's state-L commit (section 2.6), which removed "held PR 51"
from three lines they quote (amended 2026-11-01, review fold: RR1-2). The
templates.md diff's hunk 9 (:16234-16245) is this, its first context line
being state L's:

```diff
@@ -361,6 +423,11 @@
     compiles (fork work item W-127). A method of a class with a
     template parameter is rejected the same way, as the fork note in
     [Types with template parameters](#types-with-template-parameters) shows.
+    (Resolved by TP-1, <date>: `F(5 as i32)` returns 5 for the function
+    whose body is `var y: T; y = x; return y;`; for a tuple argument, the
+    instantiation reports that `(i32, i32)` does not implement
+    `Core.DefaultOrUnformed`, as `var y: (i32, i32);` does without a template
+    parameter.)
 -   `partial T*` for a template parameter `T` is rejected with
     `` `partial` applied to final type `T` ``, as for a checked parameter,
     although whether the template argument is final is known only on
```

In fork/designdocs/samples/X20_template_uninit_var.carbon (:16670-16671),
the comment's last two lines are:

```carbon
// `T` into type implementing `Core.DefaultOrUnformed` `` (fork work item
// W-127).
```

In X23_template_class_uninit_var.carbon (:16753-16754), the comment's last two
lines become one:

```carbon
// is defined (fork work item W-127). X20 pins the same form in a function.
```

TP-1's run date 2026-10-20, in sixteen added lines of the diff and in no
context line, is L's `<date>`, as TP-1's Appendix C says ("L uses its own
date"). These texts apply with `git apply` on the PR 61 tree, and DD-1's
checker reports 0 errors on them (section 0.5).

R's row is section 2.8's rule applied to the merged row; D's land-time texts
are Appendix E's (:17744 on), with `YYYY-MM-DD` the landing date and the
`<merged ...>` values the landing's measurements, the id re-scans' outcomes
quoted from their output, but for W-127's notes paragraph (:17839-17845),
which is TP-1's without its last clause, "PR 51's split lost its `fail_todo_`
prefix in F6", since F6 keeps that name; it names the template shape only, as
CT-1's H-1 asks (amended 2026-11-01, review fold: RR1-1):

```text
DISCHARGED by TP-1: impl lookup for a query that names a template binding selects no impl in the definition and keeps the deferred witness (impl_lookup.cpp `QueryNamesTemplateBinding`), so `var y: T;` resolves `DefaultOrUnformed` on instantiation (X20 and X23 run; default_init.carbon); checked generics keep their lookup (facet/period_self.carbon and interop/cpp/template/generic_call.carbon unchanged).
```

The checked-generic shape, PR 51's split, is CT-1's C.10 sentence at PR 64.
Until then W-127 reads DISCHARGED while PR 51's split, whose header names
W-127 as its open limit (f96fe8a7a dependent_var_full_prelude.carbon, "W-127
carries the limit and its removal condition"), still fails, so this is
appended to W-127's `notes` after the paragraph above (added 2026-11-01,
review fold: RR2-3):

```text
 LAND-1 (<date>): PR 51's split, the checked-generic shape, stays fail_todo_unformed_dependent_var until CT-1's L-F (PR 64).
```

The landed notes' Ledger re-cites (66aa13132
fork/templates/plan.md:7905-7914; added 2026-11-01, review fold: RR3-4): in
the `evidence` of
W-250, W-251, W-253, W-256, W-264 and W-265 and in W-014's `notes`, each
cite the list names (W-250 lower/handle.cpp:517-524, W-251
handle_operator.cpp:323-342, W-253 convert.cpp:448-459, W-256
convert.cpp:2278, W-264 handle_loop_statement.cpp:220-222 and :230 with
convert.cpp :496, :1115 and :1267, W-265 sem_ir/expr_info.cpp:365, W-014
lower/handle.cpp:524) keeps its path and its words, and only its line
numbers change, to the lines that hold the same code in that file on the
landing's tree after the refill (read by `git show` of HEAD and the cite's
path); an item absent from the merged
ledger or closed is left as it is. A cite whose code is not found on that
tree stops the landing (D-LAND-9's break condition), and evidence in a file
TP-1 does not change keeps its lines, as the landed notes say. The rule extends
(added 2026-11-02, review round 2: RV61A2-1; ruling (13)) to every other
present-tense cite in W-014's `evidence` and in the merged row 54 that points
into a file the landing changes outside testdata (`git diff --name-only
d13f47ea7 HEAD -- toolchain core ':!*/testdata/*'`): W-014's evidence cite
toolchain/lower/handle.cpp:513 is :524 on the landing's tree; the merged row's
DD-1 cite toolchain/lower/handle.cpp:494-505, a row's text being kept verbatim,
takes a marker in R's marker's form after DD-1's parenthetical, "(TP-1,
2026-11-02: the same-file SpliceInst lowering cited above as
toolchain/lower/handle.cpp:494-505 is toolchain/lower/handle.cpp:500-516 on this
tree.)"; a dated measurement records the tree it names and stays as measured:
W-014's evidence cites import_ref.cpp:5087 with the nightly's :4875,
lower/aggregate.cpp:67, inst.h:249 and function_context.cpp:223 (DD-1's probes
of 2026-10-13 and 2026-10-14) and the UA-2 entry of 2026-10-06 in W-014's
`notes`, re-cited to upstream c1e83b0b7, with lower/handle.cpp:513.

TP-1's decision-log entry (66aa13132 fork/decision-log.md:4147-4149) and its
plan (:5212-5214) state F6's rename as planned, and its Appendix C quotes
the "held PR 51" lines that PR 58's state-L commit changed; PR 61's A.5
Landed paragraph and A.6 sentence each end with this text, which records
what the landing did instead (the cite and the second sentence amended
2026-11-01, review fold: RR2-3: fork/cpp-templates/plan.md reaches trunk
only at PR 64, and R27 asks that L's departure from TP-1's text be
recorded):

```text
F6 kept PR 51's split's name, fail_todo_unformed_dependent_var, because its shape still fails on TP-1's toolchain (551a03328 fork/cpp-templates/plan.md (held PR 64) C-2 and H-1); PR 64's L-F renames it. L's templates.md hunk 9 context line and the X20 and X23 comments follow PR 58's state-L text, which removed "held PR 51" from the lines TP-1's Appendix C quotes (fork/land/land1-plan.md Appendix C.8).
```

PR 61's A.5 Landed paragraph then ends with this sentence (D-LAND-20; added
2026-11-01, review fold: RR2-1):

```text
Mutants (the landed notes' item (c); fork/land/land1-plan.md D-LAND-20): re-run <mut>; every other mutant of section 8 item 5 edits a file this landing does not change and keeps its record on 66aa13132; M18 reverts S and waits with it for Next actions item 15.
```

R's marker (section 2.7; added 2026-11-01, ruling fold: AUD-61-T20), after
the merged row's UA-2 clause "... (pattern_match.cpp:2174-2180; W-014), as
UA-2 recorded." and before TP-1's sentence, the line number re-cited by
this appendix's re-cite rule (:524 on d03be4456):

```text
 (TP-1, <date>: the cross-file template lowering `CARBON_FATAL` cited above as lower/handle.cpp:513 is lower/handle.cpp:524 on this tree.)
```

R's TP-1 sentence (section 2.8's full-row block, 66aa13132
fork/templates/plan.md:4993) carries two clauses of the held-state sentence
(66aa13132 fork/gap-analysis.md:54) that the full-row block never took
(added 2026-11-02, PR 61's landing, review round 1: RV61A-1; ruling (12)): after
"(proposal 2200; W-183, discharged)," the clause "a class template's literal
whose field has a template-dependent array bound or a produced type such as
`T.Item` converts on instantiation, taking the defaults of the fields it omits,"
and, before "; status unchanged", the clause ", and a `match`, a pattern
condition or `let` ... `else` on a template-dependent choice value (a generic
choice applied to a template parameter, or a choice declared in a class
template) or on `Core.Int(N)` for a template `N` is checked in the definition
and runs (round 10 of the focused re-review of the fold; this clause and the
class template literal's are the held-state sentence's, carried into the
land-time sentence at LAND-1's landing, 2026-11-02, fork/land/land1-plan.md
ruling (12))".

PR 61's A.5 Landed paragraph and A.6 sentence then end with this sentence
(added 2026-11-01, ruling fold: AUD-61-T26):

```text
On the merged tree, L's check_samples.py reported "<dd>" and, with --toolchain, "<ddt>"; the id re-scans before L and before the records commit: <rescan>.
```

PR 61's and PR 64's A.5 Landed paragraphs end with DR-1's note, as DR-1
passed it to their records (fee0ef31c fork/direction/plan.md:4285-4296;
added 2026-11-01, ruling fold: AUD-61-T30):

```text
DR-1's note, passed to this plan's records (fork/direction/plan.md, DR-1b's re-review round 4): a template `v[0] = 5` on a by-value type with only `IndexWith` CHECK-fails at lower.cpp:48 on CT-1's install, where trunk diagnoses; with a variable subscript, `x[i] = 5` on such a type CHECK-fails there on trunk too, and `s[i] = 5` on a `Core.Slice(i32)` or `Core.Buf(i32)` as a template `T` CHECK-fails on trunk and prints `5 5` once DR-1b lands. The landing's review compiled the literal and variable forms, the same assignment outside a template and a template's literal read on this landing's install, with the results fork/land/land1-plan.md D-LAND-22 gives: the abort is W-259's, an assignment whose template-dependent left operand is not checked on instantiation, which trunk reaches with the variable form; trunk rejected the literal form only because it rejected every literal subscript of such a type in a template, the read included.
```

PR 61's A.5 Landed paragraph and A.6 sentence then end with this sentence (added
2026-11-02, review round 2: RB61R2-1; ruling (13)), the landed notes' item (e)
(66aa13132 fork/templates/plan.md:7919-7936) asking for the checker runs on L's
fold commits too:

```text
L's document-review fold a11a5ea2f (review round 1's finding RB61-2; TP-1's section 2.9, which makes a fold of that review a fix commit of L; fork/land/land1-plan.md, Landing-time rulings, paragraph (12), item (4a)) adds to templates.md's W-259 bullet the sentence C.8's W-259 note states, which TP-1's Appendix C predates (D-LAND-22), so the landed page differs from Appendix C there as well as where the sentence on L above says; check_samples.py, with and without --toolchain, reported on it the two outputs quoted above.
```

DR-1's note's last sentence is amended 2026-11-01 (review fold: RR4-1; the
antecedent named 2026-11-02, the fold check of PR 61's review round 2:
FC61-2-1, ruling (14)).
Appended to W-259's `notes` by PR 61's records commit (D-LAND-22;
added 2026-11-01, review fold: RR4-1):

```text
 LAND-1 (<date>, PR 61's landing, fork/land/land1-plan.md D-LAND-22): a value left operand is not checked either and stops lowering: in `fn G[template T: type](v: T) { v[0] = 5; }`, and with `v[i] = 5` for `i: i64`, called with a class that implements only `Core.IndexWith(i64)`, the assignment is accepted and the compiler stops at lower.cpp:48 ("Store operand must be a pointer") on this landing's install; trunk before TP-1 stopped there on the variable subscript and rejected the literal one only because it rejected every literal subscript of such a type in a template, and outside a template both are rejected as not assignable. The check this item needs is handle_operator.cpp's, which skips a `Dependent` left operand here and at upstream 68569d234 alike. Break condition widened: both splits flip to `fail_`, and both forms above are diagnosed.
```

OR-5: the branch's "TP-1 at land time" item is discharged by the landing (the
message lists S as item 15's, the VA-1 compositions as item 17's and the
rename of PR 51's split as PR 64's L-F).

### C.9 PR 62's own texts

Row 68 (C.7's fallback), the merged row with this appended before its closing
`|`:

```text
 SV-1 (<date>, fork/sumtype-interop/plan.md, F-020) lands the interop half (W-011 DISCHARGED): a C++ `std::optional<T>` / `std::variant<Ts...>` keeps its C++ class and converts by value, through its accessors, to and from `Core.CppCompat.StdOptional(T)` / `StdVariant1..8` (alternatives `.Alt0`, `.Alt1`, ... by C++ index; `std::monostate` as `()`), and `match`, `if`-`let`, `while`-`let` and `let`-`else` consume it with exhaustiveness; a C++ `std::optional<T>` converts to and from `Core.Optional(T)` in one step for a non-pointer `T`; match_sum_type_payload un-SKIPped, 10 conformance programs PASS (the 5 above, match_sum_type_payload, match_std_optional_diff, match_std_variant_diff, cpp_sum_type_roundtrip_diff and cpp_sum_type_library, against C++ oracles; match_core_optional_diff SKIP since W-322's commit); 0.1 limits, each diagnosed: class-type or non-trivial alternatives (W-275, SF-6), more than 8 alternatives (W-276), qualified alternatives (W-277), template-deferred conversions (W-279), `ref` payload bindings (W-280), sum classes nested in tuple scrutinees (W-281), C++ `T&&` parameters (W-285), file scope (W-036). `Core.Optional(T)` itself is not matched: D-SV-7's view was retired (W-322, R32 (d)), and W-320 waits on W-324. SV-1: container-measured at its landing, <p>/<f>/<s> over <n> (R33 (b)).
```

Appended to W-011's `notes` (whose count reads "133/0/22 over 155") and as
the last sentence of the paragraph of SV-1's decision-log entry that states "133
/ 0 / 22 over 155":

```text
 Landed <date> (LAND-1): <p>/<f>/<s> over <n> on the merged trunk, container-measured (R33 (b)).
```

W-252's and W-263's notes: Appendix C.6's texts (0ef8a0334
fork/sumtype-interop/plan.md:9351-9363), each only if the item is on the
merged trunk and open, `YYYY-MM-DD` the landing date and W-252's alternative
the measured one. In Next actions item 4, "landed as SV-1, held open as PR
62" becomes "landed as SV-1, merged to trunk <date> as PR 62 (LAND-1)".

OR-5 (added 2026-11-01, review fold: RR1-4): the branch's item 5, "SV-1 at
land time" (0ef8a0334 fork/ORCHESTRATION.md, Next actions item 5), which OR-4
drops ($F/expected/pr62, ORCHESTRATION region 4), is discharged by the
landing; the message lists M-VA and W-284 as item 17's and Doc-M, C.5, C.8
and F-M's PR 57 part as item 16's. Its other steps map to section 2.8: M is
the merge; F-M's own goldens, the second id re-scan and section 8 item 11 are
steps of the landing; the absolute count re-quoted into row 68, W-011's note
and the decision-log entry, x19 for W-282, the notes on W-252 and W-263, the
re-cited evidence and C.7's fallback are the records commit's texts above.
Its step "the id lists of the decision-log entry and this row completed"
maps so: the entry's id list (0ef8a0334 fork/decision-log.md:7002-7005)
keeps "W-284 held until M-VA lands", which stays true because M-VA is item
17's, and "W-282 unused (X-1 fixed by TP-1 at eafca5cb9)" while x19 holds;
if x19 files W-282 (section 2.8), that clause becomes "W-282 filed
(<date>, LAND-1: x19 fails on the merged trunk)"; the row is A.3's, whose
summary (C.1) names W-284's state, and A.3's row replaces the branch's
"W-284 held until M-VA lands; W-282 unused" whole.

Two departures from SV-1's words, recorded (R27; added 2026-11-01, ruling
fold: the audit's S15 and S16 notes): SV-1's item (g) re-quotes the count
"into" W-011's note and the entry's scoreboard sentence, and this appendix
appends the landed count beside the held-tree one, which stays as SV-1's
measurement on its own base, so no measured count is overwritten; and
row 68's sentence ends with "container-measured at its landing" where C.7
gave its held-state evidence label, because R33 (b) makes the landing's
scoreboard R9's record. The records commit's message names each probe set
of section 2.8 not run, each on a line that begins "Not run:" and gives
the set's name and, in parentheses, its reason; none is expected
(AUD-62-S04).

### C.10 PR 64's own texts

CT-1's: C.1 (L), C.2 (W-043's discharge over DD-1's entry, including C.7's
LAND-1 note), C.4 (rows 42 and 56, with the interop golden counts measured on
the landing's tree in place of 164 and 56), C.6 (the two programs, in the
merge), C.10 (W-127), with `<YYYY-MM-DD>` the landing date. C.2's
`<the original seven entries, kept, then DD-1's at land time>` stands for the
merged tree's W-043 `evidence` entries, verbatim and in their order (seven on
this tree: PR 51's six rewritten entries and DD-1's X09 entry, PR 51 having
rewritten the original seven before PR 58 landed), C.2's six entries following
them; its `<the original notes, kept, then DD-1's at land time>` stands for the
merged tree's W-043 `notes` verbatim (DD-1's sentence and C.7's LAND-1 note
included), whose final period is the template's, C.2's text following after
one space from "DISCHARGED at CT-1"; the branch's held-state sentence ("Held
state (2026-10-21): ...") is not carried, this records commit being the event
it announces, and the branch's round sentence ("Focused re-review, round 1
(2026-10-22): ...") is kept after C.2's text, as C.2's intro says; C.2's
`<gate N of N>` and `<P / F / S over N>` are the landing's final gate and
conformance in the slots' own forms, "1978 of 1978" and "189 / 0 / 15 over
204" at this landing (added 2026-11-02, PR 64's landing, the implementer's
stop at step 9: ruling (15)). C.1's replaced
sentence runs from "One limit in 0.1:" to its state-L end, "(fork work item
W-043, and W-127).", which PR 58's state-L commit made of the "(fork work
item W-043, and W-127 on held PR 51)." that C.1 quotes (amended 2026-11-01,
review fold: RR1-2).

L-F's rename commit (section 2.9; added 2026-11-01, review fold: RR1-1), in
toolchain/check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon:
the line `// --- fail_todo_unformed_dependent_var.carbon` becomes
`// --- unformed_dependent_var.carbon` (TP-1's Appendix A F6 line,
:15210-15212), and after the header comment's last line, `// condition.`,
come these lines, so that the header's "The failing split is `fail_todo_`"
and the split's "Predicted:" comment read as history:

```carbon
//
// At PR 64's landing (<date>, LAND-1), CT-1's land-time fill renamed the
// split `unformed_dependent_var`: its shape compiles since CT-1
// (fork/cpp-templates/plan.md C-2), so the failure described above and the
// split's prediction are historical.
```

L-F's comment commit, after the refill (section 2.9; added 2026-11-01, review
fold: RR2-1; CT-1's landed notes' item (c), 551a03328
fork/cpp-templates/plan.md:4834-4841), in
lines 260 and 261 of
toolchain/lower/testdata/interop/cpp/template_symbolic_arg.carbon:

```carbon
// lowered as the outer specific's constant: the load of `Traits<long>::size`
// and of `Traits<short>::size`.
```

become, the same line count:

```carbon
// lowered as the outer specific's constant: the constants 8 and 2 of
// `Traits<long>::size` and `Traits<short>::size`.
```

L's message (section 2.9; added 2026-11-01, review fold: RR2-1; the landed
notes' item (d)):

```text
Land PR 64: CT-1 interoperability page and fixture X37 over PR 58

CT-1's land-time L (fork/cpp-templates/plan.md Appendix C.1 and its
landed notes' item (d), with the anchor fork/land/land1-plan.md Appendix
C.10 adapts to PR 58's state-L text): the sentence of
docs/design/interoperability/README.md's "Using C++ templates" from "One
limit in 0.1:" replaced by C.1's paragraph dated <date>; fixture
X37_cpp_template_symbolic_uninit.carbon with its SAMPLES entry after
X09's; X09's comment updated.

check_samples.py: <dd>; with --toolchain: <ddt>. R27: the page's
`var b: Cpp.Box(T);` and `Cpp.Twice(x)` occur verbatim in X37, and the
first in interop/cpp_template_symbolic_arg.carbon and
cpp_template_on_carbon_generic.carbon. R31 (README.md, headings,
bullets, numbered, rows): <r31>. prek clean (SKIP=fix-cc-deps,
check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest).

<trailers>
```

PR 64's A.5 Landed paragraph ends with these sentences (added 2026-11-01,
review fold: RR2-1; the landed notes' items (c) and (f) and its "R32 at
landing"; the R32 sentence's set amended 2026-11-01, review fold: RR3-2):

```text
L-F reworded A.2's nested_alias_through_specific comment to name the constants 8 and 2 (item (c)), an autoupdate no-op; L's check_samples.py reported "<dd>" and, with --toolchain, "<ddt>" (item (f)). Mutants (item (c); fork/land/land1-plan.md D-LAND-20): re-run <mut>; every other mutant of section 8 item 5 edits a file this landing does not change and keeps its record on 551a03328; M18 waits with S-VA for Next actions item 17. R32 (the "R32 at landing" note above): F-021's V-3 comparison (sections 0.10 and 1.17) was repeated at upstream <tip>, where its four quotes and E-ARG's CppCallArgTypeNotSupported are at <v3>, and none of the <v3n> upstream commits since c1e83b0b7 to CT-1's files as section 0.10 lists them, toolchain/check/cpp/, docs/design/ and proposals/, each judged as section 0.10 judges (fork/land/land1-plan.md section 2.9), lands a rule for a checked generic's C++ calls that differs from F-021, so F-021 stands.
```

PR 64's A.5 Landed paragraph also ends with C.8's DR-1 note sentence
(section 2.9; added 2026-11-01, ruling fold: AUD-61-T30).

In CT-1's decision-log entry, after the held-state paragraph's last words, "no
residue is filed and W-312 to W-319 stay unused." (once in the entry at
e21480b05), C.7's fallback (the landed notes' item (g)) appends (added
2026-11-01, review fold: RR2-1):

```text
 Brought up to date <date> (LAND-1, fork/land/land1-plan.md section 2.9): merged into trunk as PR 64 by <merge sha> after PR 61 (TP-1) and PR 62, with land-time commits <land-time shas> (L-F and L); container-measured (R33 (b)) on the merged trunk, the absolute count re-quoted from its scoreboard: gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; F-021's V-3 comparison repeated at upstream <tip> (fork/cpp-templates/plan.md, its Landed notes); S-VA and its mutant M18 wait for Next actions item 17.
```

OR-5 (amended 2026-11-01, review fold: RR2-1): the branch's "TP-1 at land
time" item is discharged by PR 61's landing (C.8), and its "CT-1 at land
time" item, item 6 (551a03328 fork/ORCHESTRATION.md:1220-1267), by this
landing, each of its steps mapped by section 2.9: M is the merge, with LG-7,
PROG-1 and README-1 for its rules and OR-2 with A.3's row for "trunk's stale
CT-1 Branches row dropped"; S-VA and M18 are item 17's (the message says so);
L-F is the rename commit, the refill, the comment commit with its autoupdate
no-op, and the gate, conformance and D-LAND-20's mutants; L is the L commit
with both checker modes, R27's spelling diff and R31's counts in its message;
the second id re-scan precedes the records commit; the records commit's
steps are C.4's rows, C.2's discharge, W-127's sentence, R32's comparison,
the held-state sentence above and the checker runs in A.5's sentences; and
its last step, the hosted runs when Actions returns, is R33 (b)'s owed hosted
gate, A.3's last clause.

### C.11 PR 63's own texts

In row 68, after "is removed by a commit on its branch (W-322, 2026-10-21).":

```text
 (PR 62 landed on trunk with the view removed, LAND-1 stage 8.)
```

In Next actions item 1, "is held open as PR 63 and DR-1b, `IndirectIndexWith`
(W-109, stacked on DR-1a), as PR 65;" becomes "landed on trunk <date> as PR 63
(LAND-1), and DR-1b, `IndirectIndexWith` (W-109, stacked on DR-1a), is held
open as PR 65;".

The notes routed to DR-1 by trunk's weekly upstream check of 2026-10-26
(bb9fbba9c fork/decision-log.md:6903-6912), appended by this records
commit, since D-LAND-3 bars the branch commit they were routed to (added
2026-11-01, ruling fold: AUD-63-20). To W-322's `notes`, DR-1's C.2 text
(fee0ef31c fork/direction/plan.md:3439-3440) with PR 62's commit:

```text
 DISCHARGED 2026-10-21 by PR 62's commit 22fe50ff8 (C.6), with its fill f4660e409 (routed to DR-1 by the weekly upstream check of 2026-10-26; written <date> at PR 63's landing, LAND-1).
```

To W-324's and W-326's `notes`, each:

```text
 Weekly upstream check 2026-10-26 (V-3a register re-check at upstream 21c825a3f): HOLDS, no break condition fired (fork/decision-log.md, "Weekly upstream check 2026-10-26 (R32 direction register)"; routed to DR-1, written <date> at PR 63's landing, LAND-1).
```

The (i) sha stamp the same check routed to DR-1 (bb9fbba9c
fork/decision-log.md:6908-6909; added 2026-11-01, review fold: RR4-2): in
fork/decision-log.md's DR-0 register block, the line "fill c1cc72a09.",
which ends the sentence "(iii) resolved 2026-10-21 by DR-1a, d0cfe8082 and
its fill c1cc72a09." (:254-255 on f2110e0fd, once in the file), becomes
these two lines:

```text
fill c1cc72a09. (i) resolved 2026-10-21 by W-322's 22fe50ff8 and its fill
f4660e409 on PR 62 (written <date> at PR 63's landing, LAND-1).
```

### C.12 PR 65's own texts

DR-1's: Appendix C.2's W-340 discharge note (fee0ef31c
fork/direction/plan.md:3463-3469) with M-b's sha `<merge sha>` and C-b's and
L-b's from `<land-time shas>`, and C.3's past tense for row 79's W-340
sentence. Their exact form (added 2026-11-01, ruling fold: AUD-65-B2 /
AUD-65-B3): in C.2's text, "M-b <sha>" takes `<merge sha>`, "C-b <sha>"
the first sha of `<land-time shas>`, and in "L-b <sha>" the one slot takes
the second and third shas of `<land-time shas>`, the rename commit's and
the refill's, joined by " and "; in row 79, the sentence from "On
DR-1b's own tree, before M-b and C-b," through "RR4-2-m1)." (measured on
d3eb55f7a) becomes, its marks kept and one added:

```text
Before M-b and C-b, DR-1b's own tree rejected a subscript of template-dependent type on a type that implements only `IndexWith` (W-340, discharged at M-b with C-b; added 2026-10-22 by DR-1b's re-review round 4, reworded 2026-10-26 by the records of its reviews, RR4-2-m1; put in the past tense <date> at PR 65's landing, LAND-1).
```

PR 65's A.5 Landed paragraph ends with these sentences (added 2026-11-01,
ruling fold: AUD-65-F2 / AUD-65-A11):

```text
SAFE-2's note for DR-1 (fork/safe/safe2-plan.md section 0.8, on PR 53's unpushed realignment), that `IndirectIndexWith.Ref` takes `bound self` under W-144, assumed that PR 65 lands after PR 53; PR 65 landed first, so the note and its counterexample are Next actions item 14's, for PR 53's landing. Mutants (section 8 item 5; fork/land/land1-plan.md D-LAND-20): C-b's dependence check removed, re-run: <mut>; every other mutant keeps its record on fee0ef31c.
```

L-b's rename commit (section 2.11; added 2026-11-01, review fold: RR3-1).
DR-1's plan says the split's comment is reworded at L-b, "its comment says
that the choice is made per specific" (fee0ef31c
fork/direction/plan.md:3066-3067), without the text. In
toolchain/check/testdata/slice/write_through.carbon (identical at fee0ef31c
and on the dry run's PR 65 merge d3eb55f7a), the line
`// --- fail_todo_template_index_with_only.carbon` becomes
`// --- template_index_with_only.carbon`, and the split's comment, these six
lines:

```carbon
// The current behavior, pinned: for a template-dependent operand, the
// non-diagnosing `IndirectIndexWith` attempt is deferred to monomorphization,
// so the `IndexWith` fallback does not run, and the deferred lookup's failure
// there is an error. `V` implements only `IndexWith(i64)`, so `G(V)` is
// rejected. Choosing between the two interfaces per specific, when the
// template is instantiated, makes this valid.
```

becomes, the same line count, so that the file keeps its 831 lines until the
refill drops the seven STDERR lines:

```carbon
// For a template-dependent operand, the choice between `IndirectIndexWith`
// and `IndexWith` is made per specific, when the template is instantiated.
// `V` implements only `IndexWith(i64)`, so `G(V)` uses `IndexWith` and is
// valid (W-340, discharged). Before the choice was made per specific, the
// deferred `IndirectIndexWith` lookup failed at monomorphization and
// rejected `G(V)`.
```

DR-1's plan names the DR-1 entry's dated note without its text
(:1612-1615); it is this, before PR 65's A.6 sentence:

```text
_W-340 discharged (<date>, LAND-1):_ M-b <merge sha>, then C-b and L-b
(<land-time shas>) on trunk, by fork/direction/plan.md section 1.16: t10,
t15, t16 and t18 print 7, 8, 9 and 6, n06, n15, n32 and n13 print 8, 5, 7
and `3 7`, and a4 prints 9 on the landing's toolchain; check
slice/write_through.carbon's split is `template_index_with_only`, its
comment saying that the choice is made per specific.
```

The note's last clause is amended 2026-11-01 (review fold: RR3-1).

DL-5's resolution at PR 65's merge (added 2026-11-01, review fold: RR4-2):
the conflict's two sides, trunk's two lines of C.11 and DR-1b's "fill
c1cc72a09. (ii) resolved 2026-10-22 by DR-1b, 3c54754bc and its fill" and
"cf4904138, with 230227264's code by cdaa15710 and its fill 06b6479d0.",
become these four lines, the date in them the one PR 63's records commit
wrote, then trunk's blank line and re-check paragraph as trunk has them:

```text
fill c1cc72a09. (i) resolved 2026-10-21 by W-322's 22fe50ff8 and its fill
f4660e409 on PR 62 (written <date> at PR 63's landing, LAND-1). (ii)
resolved 2026-10-22 by DR-1b, 3c54754bc and its fill cf4904138, with 230227264's
code by cdaa15710 and its fill 06b6479d0.
```

PR 65's A.5 Landed paragraph also ends with this sentence (section 2.11;
added 2026-11-01, review fold: RR4-7 / RR4-1):

```text
clang-tidy 21.1.8, run after C-b on the merged toolchain/check/handle_index.cpp as fork/direction/plan.md section 8 item 6 runs it (--checks=-modernize-use-trailing-return-type over the build's compile database), returned rc 0 with no user warning; fork/land/land1-plan.md D-LAND-22's four programs gave the results it predicts on this landing's install, or the one W-259's notes record.
```

Only where one of D-LAND-22's two template forms is diagnosed on PR 65's
install instead, this is appended to W-259's `notes`, with "the literal
form is" replaced by "the variable form is" or "both forms are" as
measured, and the diagnostic goes into the records commit's message:

```text
 LAND-1 (<date>, PR 65's landing, fork/land/land1-plan.md D-LAND-22): on this tree the literal form is diagnosed, not stopped.
```

In Next actions item 1, as C.11 left it, "is held open as PR
65;" becomes "landed on trunk <date> as PR 65 (LAND-1);", and "Both DR-1 PRs
merge after CT-1 (PR 64)." becomes "Both DR-1 PRs landed after CT-1 (PR 64),
LAND-1."

### C.13 PR 68's own texts

These replace OV-4's D.7 texts and its M, F-M and L messages; A.3's row
replaces D.7's "MERGED WITH THE LANDED TRUNK" state, A.4's header and
paragraph replace D.7's, and the paragraph below replaces both D.7's
decision-log paragraph and A.6's sentence. L-R's message, replacing section
3's:

```text
Land PR 68: OV-4 register rows T2.8 and T2.9 (L-R)

Rows T2.8 and T2.9 inserted after T2.7 in fork/register/rg1-plan.md, their
checks and quotes appended to rg1-checks.tsv and rg1-quotes.tsv
(fork/overload/ov4-plan.md Appendix D.6). Checked at upstream <tip>: the
whole tables, <c> silence checks with <cf> failed and <q> quotes with
<qf> failed (D-LAND-19, the failures W-355's); the two rows' own checks
are among them and listed by id.

<trailers>
```

In Appendix D.6's rows T2.8 and T2.9, a cell that reads "re-read at <tip>"
is followed, when one of that row's own quotes or checks fails at `<tip>`,
by " (<the FAIL rows' ids> fail there; W-355)", C.3's form, the ids as the
scripts print them, and those rows go to W-355's notes by C.2's text with
this landing's number (097c76473 fork/overload/ov4-plan.md:4104-4106;
added 2026-11-01, ruling fold: AUD-68-15). PR 68's A.5 Landed paragraph
ends with this sentence (added 2026-11-01, ruling fold: AUD-68-17):

```text
Mutants (section 8.8's re-run of section 8.5; fork/land/land1-plan.md D-LAND-20): re-run <mut>; every other mutant edits a file this landing does not change, or a program, and keeps its record on 097c76473.
```

Appended to W-341's `notes`, replacing D.7's ledger text:

```text
 Landed <date>: merged into trunk as PR 68 by merge <merge sha> (LAND-1, fork/land/land1-plan.md section 2.12), trunk before <trunk before> holding PR 67, 51, 52, 54, 55, 58, 61, 62, 64, 63 and 65, with PR 53, 56, 57, 59, 60 and 66 held; land-time commits <land-time shas> (L-R: register rows T2.8 and T2.9, checked at upstream <tip>); container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over <n>. It landed before PR 59, PR 60 and PR 66 (D-LAND-1), not after VA-2 as the owner line above says; SC-1's two arguments in CheckOverloadMemberParamsMatch go to Next actions item 15 and VA-1's pack gate order in handle_function.cpp to item 17.
```

The decision-log paragraph, the last of OV-4's entry:

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR 68 by
<merge sha> (GitHub merged_at <merged_at>), trunk before <trunk before>
holding PR 67, 51, 52, 54, 55, 58, 61, 62, 64, 63 and 65, by
fork/land/land1-plan.md D-LAND-5's rules (OR-1 to OR-4 and LG-1), the code
rules of fork/overload/ov4-plan.md section 6.2 going to the follow-ons;
land-time commits
<land-time shas>, L-R checked at upstream <tip> (<c> silence checks with
<cf> failed, <q> quotes with <qf> failed over the whole tables).
Container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s>
over <n>, <b>/56 bullets; moved to follow-ons: SC-1's two arguments
(item 15) and VA-1's pack gate order (item 17).
```

In item 6, the text from "W-341 (OV-4) is implemented" through "its residues
W-360 to W-363 go to UA-3.", as B.1 left it, becomes:

```text
W-341 (OV-4) landed on trunk <date> as PR 68 by merge <merge sha>
(LAND-1); its residues W-360 to W-363 go to UA-3, after EH-C (W-346);
SC-1's two arguments and VA-1's pack gate order go to items 15 and 17.
```

<!-- google-doc-style-resume -->

## Orchestrator's ruling (2026-11-01, after round 3)

Recorded verbatim (added 2026-11-01, ruling fold: the ruling's item 2); rev
6 carries it out (the Status line and the rev-6 fold record).

<!-- google-doc-style-ignore -->

> Ruling of the orchestrator under R29, 2026-11-01, on the LAND-1 plan at
> rev 5 (01f17f2ad), after the third focused re-review round, the cap of
> three. Round 1 found one BLOCKER and one MAJOR, round 2 one MAJOR and
> round 3 two MAJORs and no BLOCKER, every finding from round 2 on being a
> mapping omission: a land-time step that a ready PR's own records
> prescribe (CT-1's landed notes items and its branch's Next actions item
> 6, TP-1's mutants, DR-1's L-b comment reword, CT-1's R32 comparison set)
> that section 2 did not carry or name as moved. The reviewers find these
> one at a time; the plan needs them found whole before the landing,
> because an unmapped step is a step the landing silently drops. So: (1)
> before round 4, a completeness audit, one fresh agent per ready PR,
> enumerates every land-time step the PR's own records prescribe (its
> plan's land-time section and its 'Landed notes' or 'land-sequence
> records commit' paragraphs with every lettered or numbered item, its
> branch's fork/ORCHESTRATION.md Next actions item for itself and its
> Branches row's land notes, its decision-log entry's land-time sentences,
> RG-1's Appendix A.4 note for it, every 'at land time', 'when it lands',
> 'before PR N lands' or 'the records commit' sentence in its plan, and
> any other held PR's plan step prescribed at this PR's landing) and
> checks each against section 2's subsection for the PR, D-LAND-4's moved
> steps, D-LAND-20 and Appendix B.1's items 14 to 17, reporting each step
> as MAPPED (where), MOVED (to which follow-on, where) or UNMAPPED, with the
> cite; (2) the fixer folds every UNMAPPED step into rev 6 with a text or a
> rule and a dated mark, records this ruling verbatim, and restates PR
> 53's gate: SAFE-3 stopped at its plan rev 12 (14c1ac8ac, 2026-11-01)
> under its re-think ruling's break condition (RT1-B1 and RT2-B1, C++ code
> reaching from an address it receives a Carbon place that the carrier
> closure does not name), so D-LAND-12's G-53, section 3's G-53 paragraph,
> Appendix B.1's item 14 and every 'SAFE-3 completes' phrase read 'the
> realignment of PR 53's branch completed under the orchestrator's
> re-ruling of the C++ boundary question (fork/safe/safe3-plan.md
> D-SAFE3-13 and its rev 11 and rev 12 fold records)', the stop itself
> being stamped on trunk by the orchestrator from safe3-plan.md Appendix
> D's stop path after B.1's stamp, PR 53's pushed head staying 2407efa74
> and W-365 and W-366 staying reserved and unfiled; (3) rounds 4 and 5
> follow, each a fresh focused re-review and a fixer, under the same
> sign-off rule: a round with no BLOCKER and no MAJOR signs off, its fixer
> setting the Status line and the Sign-off section. Break condition: a
> BLOCKER, or a MAJOR left after round 5, stops LAND-1's planning; the
> orchestrator then re-plans section 2's mapping as a separate audited
> document before any landing.

<!-- google-doc-style-resume -->

## Review fold record (rev 2, 2026-11-01)

Reviews A and B of rev 1 (both REJECT) returned 25 findings: 2 BLOCKER, 11
MAJOR, 12 MINOR. All are folded; none is rejected. Each was reproduced first:
the dry run was re-run in /dev/shm/land1-fixer (removed after the commit) with
the rev-2 rules, DD-1's checker was run on every scratch commit, and the
sources each finding cites were read at their shas.

| Id | Severity | Disposition | Where |
| --- | --- | --- | --- |
| A-B1 | BLOCKER | Folded. Reproduced: rev 1's md3.py took trunk's side for row regions whose word merge failed, dropping DR-1b's row 79 (DONE, W-326, W-340), DD-1's rows 54 and 91 and SV-1's row 68 text; the gap-row check finds 8 missing segments at rev 1's PR 65 and 16 at its PR 58. GA-2 is limited to the header and prose; GA-1b composes rows in the merge and GA-1c names the rows a plan recomposes; the run is redone; the tally is 36/16/3/1 from PR 65; step 9 runs `rowcheck.py` | Summary, conventions, 0.5, 0.7, D-LAND-5, D-LAND-6, D-LAND-9, 2.6, 2.8, 2.11, 4, 5, B.2 |
| A-M1 | MAJOR | Folded. Reproduced: OR-4 dropped PR 52's W-128 item, PR 54's W-152 item and PR 55's items 5 and 6 (and PR 58's correction note). OR-5 carries or discharges each by name; item 6 goes to item 14 by B.1; the ST-1 paragraph's item numbers get a dated mark | 0.5, D-LAND-5, 2.3 to 2.6, C.4 to C.7, B.1 |
| A-M2 | MAJOR | Folded with B-B1. Reproduced: 1 error at the PR 58 merge. The PR 55 state-L split and the section 2.14 evidence amendments are given verbatim; both checker modes run at every landing from PR 58 on | 0.5, D-LAND-6 step 8, D-LAND-14, 2.6, C.7 |
| A-M3 | MAJOR | Folded with B-M3: D-LAND-18's stop rule, with section 4's expected values and deltas | D-LAND-18, 4 |
| A-M4 | MAJOR | Folded. The run's limit is stated; step 2 re-runs the remaining merges and step 3 records every difference; the rev-2 run includes the two land-time commits a later merge sees, and finds the predicted row-68 conflict at PR 63 (GA-1b); PL-1 and DL-4 are predicted for PR 65 | 0.5, D-LAND-5, D-LAND-6, 2.10, 2.11, 5 |
| A-m1 | MINOR | Folded: DL-3's order is DR-0, DR-1, RG-1, LD-0; the reference has DR-1's entry directly after DR-0's | D-LAND-5, 0.5, 2.10 |
| A-m2 | MINOR | Folded: section W11's state C text is in 2.4 | 2.4 |
| A-m3 | MINOR | Folded with B-m2: the skipped hooks and BUILD-dependency correctness are listed as not covered; prek runs before each commit and the build, and a prek change to a PR's unconflicted file stops the landing | 0.9, D-LAND-6, 6, hand-off note 6 |
| A-m4 | MINOR | Folded: W-341's notes (C.13) and item 6 (B.1) | B.1, C.13 |
| B-B1 | BLOCKER | Folded with A-M2; the dry run's state-L commit 94dba6b21 brings the checker to 0 errors and stays at 0 through PR 68 | 0.5, D-LAND-14, 2.6, C.7, hand-off note 7 |
| B-M1 | MAJOR | Folded: D.7's texts and OV-4's messages are adapted verbatim, each naming what it replaces | 2.12, C.13 |
| B-M2 | MAJOR | Folded: the measured failures at 68569d234 are recorded; D-LAND-19 fixes the tip as the landing day's and files failures under W-355 | 0.13, D-LAND-19, 2.1, 2.2, C.2, C.3, C.13 |
| B-M3 | MAJOR | Folded with A-M3: FAIL above 0, by-name PASS checks, the delta, bullets and DONE rows' bullets | 0.7, D-LAND-18, 4 |
| B-M4 | MAJOR | Folded: two phases; the records commit follows `merged: true` and records `merged_at` and the merge sha | D-LAND-6 steps 9 to 12, D-LAND-11, A.3 to A.7 |
| B-M5 | MAJOR | Folded: one placeholder table; Appendix C gives every field, target and text, with text anchors | conventions, A, C |
| B-M6 | MAJOR | Folded: SV-1's, TP-1's, EV-1's and DR-1's lists are mapped item by item; the nine DR-1 probes are a step with paths and expected outputs | 0.3, D-LAND-4, 2.4, 2.7, 2.8, 2.11, C.8, C.9 |
| B-M7 | MAJOR | Folded: B.1 rewrites the lead and the stale clauses of items 2, 6 and 13; PR 67's records mark rg1-plan.md section 5 and W-343 | B.1, C.2 |
| B-m1 | MINOR | Folded: the three lines rewrapped; the R31 scan below covers `[0-9]+[.)]` at every line start | 0.1, D-LAND-12 |
| B-m2 | MINOR | Folded with A-m3 | D-LAND-6, 0.9 |
| B-m3 | MINOR | Folded: R33 (b) quoted; "not of record" removed from LAND-1's own labels | D-LAND-7, A |
| B-m4 | MINOR | Folded: one actor per step, and the API fields recorded | 3, D-LAND-11, D-LAND-16 |
| B-m5 | MINOR | Folded: D-LAND-17 | 0.8, D-LAND-17 |
| B-m6 | MINOR | Folded: B.2's tally is `<tally>`; `<hh:mm>` is defined; the plan reaches trunk before stage 0 | conventions, D-LAND-16, B.2 |
| B-m7 | MINOR | Folded: C-b removes the later `index_type_id` declaration | 2.11 |
| B-m8 | MINOR | Folded: G-59/66's owner is VA-1's workstream; W-367 is filed in PR 59's branch's ledger | D-LAND-2, D-LAND-12, D-LAND-13, B.1 |

Checks of this revision: prek to a fixpoint with the SKIP set of hand-off
note 6, `uvx rumdl check`, R31's counts before and after each prek run, a scan
for lines that start with `#` and a digit, `+`, or digits and `.` or `)` outside
the lists, and the model-identifier grep, all recorded in the commit message.

## Focused re-review fold record (rev 3, 2026-11-01)

The focused re-review of rev 2 (adaf45757) returned REJECT with six findings:
1 BLOCKER, 1 MAJOR, 4 MINOR. It confirmed rev 2's 25 folds against the
scratch commits (rowcheck 0 missing at f2110e0fd and d3eb55f7a; DD-1's
checker 1 error at a33d05cae and 0 at 94dba6b21 and 5cf7406f1; the decision
log ordered DR-0, DR-1, RG-1, LD-0; the eighteen heads unchanged; W-367 to
W-370 filed nowhere). RR1-n is its finding Nn. All six are folded; none is
rejected. Each was reproduced first in `$F1` (a scratch worktree under
/dev/shm/land1-fixer1, removed after the commit).

| Id | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR1-1 | BLOCKER | Folded. Reproduced: the split's shape fails on the TP-1 install (eafca5cb9) with "cannot convert type `S(<...TemplateInst...>)` into type implementing `Core.DefaultOrUnformed`" and compiles on the CT-1 install (224ee2f8f); file_test_base.cpp:131-160 reports a failing split without `fail_` as a problem autoupdate cannot fix. F6 keeps the name and refills CHECK lines only; C.8 gives W-127's discharge without the F6 clause and a sentence for A.5 and A.6; PR 64's L-F renames the split by C.10's texts under C-2's own rule, not section 1.16's fallback; hand-off note 8 stops a landing whose gate disagrees | 0.7, D-LAND-8, 2.2, 2.7, 2.9, 4, hand-off note 8, C.1, C.8, C.10 |
| RR1-2 | MAJOR | Folded. Reproduced: TP-1's diff fails `git apply --check` on d03be4456 at templates.md:361 and `patch` takes hunk 9 with fuzz 1; CT-1's anchor occurs nowhere on e21480b05. C.8 gives hunk 9 with state L's context and X20's and X23's comments without "held PR 51"; C.10 gives the anchor "(fork work item W-043, and W-127)."; both L texts applied in scratch (9e0ccecdb; f0d62063d and 6f6e2f388), DD-1's checker 70 and 71 fixtures, 0 errors | 0.5, 2.7, 2.9, hand-off note 8, C.8, C.10 |
| RR1-3 | MINOR | Folded: both PR 61 reviewers review L as its document review, by TP-1's section 2.9 ("two reviewers, R29(c)") | D-LAND-10, 2.7 |
| RR1-4 | MINOR | Folded: C.9 gains OR-5 for PR 62's item 5, discharged, with M-VA and W-284 to item 17 and Doc-M, C.5, C.8 and F-M's PR 57 part to item 16, and the id-list step mapped to the decision-log entry's clauses (fork/decision-log.md:7002-7005) and A.3's row | C.1, C.9 |
| RR1-5 | MINOR | Folded: B.1 marks the six waiting PRs' rows after their merge-position clauses (each anchor unique at bb9fbba9c) and says the ready rows are rewritten at landing; A.8 gives the gap header's first sentence with the container-measured scoreboard at every landing; A.9 gives ORCHESTRATION's Scoreboard paragraph; A.10 marks the "not of record" labels of the eight landed rows that carry one | 0.7, D-LAND-9, hand-off note 2, A.8 to A.10, B.1 |
| RR1-6 | MINOR | Folded: A.1 reports the merge's gate as `<g0>` of `<gn>` before any refill and cites A.2; `<base>` is defined and read at step 1 | conventions, D-LAND-6 step 1, A.1 |

Checks of this revision: as rev 2's, with the R31 counts of every edit and
prek run, recorded in the commit message.

## Focused re-review fold record, round 2 (rev 4, 2026-11-01)

The focused re-review's round 2 of rev 3 (a8fa4d68b) returned
APPROVE-WITH-AMENDMENTS. It found N1 to N6 resolved: the split's shape fails
on the TP-1 install (eafca5cb9) and compiles on the CT-1 install
(224ee2f8f); TP-1's L with C.8's state-L context and CT-1's L with C.10's
anchor apply, DD-1's checker reporting 70 and 71 fixtures and 0 errors;
D-LAND-10, section 2.7 and section 3 agree; C.9's OR-5 matches
fork/decision-log.md:7002-7005; the six B.1 anchors occur once at bb9fbba9c;
the gate.log formats match `<g0>` and `<gn>`; the eighteen heads are
unchanged; R31's counts were 1/14/50 headings, 68 bullets, 20 numbered, 173
rows and 47 blocks, 0 unguarded. It found 1 MAJOR and 3 MINOR, RR2-1 to
RR2-4. All four are folded; none is rejected. Each was reproduced first in
`$F2`; no scratch worktree was needed, because the dry run's scratch commits
d03be4456 and e21480b05 were read with `git show` and `git diff`.

| Id | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR2-1 | MAJOR | Folded. Reproduced: CT-1's landed notes' items (c) to (g) (551a03328 fork/cpp-templates/plan.md:4809-4868) and its branch's item 6 (fork/ORCHESTRATION.md:1220-1267) name A.2's comment reword, the gate, conformance and mutants on the merged build, R27 and R31 at L, R32's V-3 comparison and the held-state paragraph, which rev 3 did not map; TP-1's item (c) (66aa13132 fork/templates/plan.md:7927-7928) names mutants. D-LAND-20 re-runs, by both plans' own rule (TP-1's :6389-6390 and :7121, CT-1's :3871-3872), each named mutant whose edited file the landing changes or whose killer it refills or renames: measured, none of TP-1's at PR 61 (its 32 non-testdata files and the merge's two non-testdata changes are disjoint) and CT-1's M6, M7, M23, M24, M75 and M75r at PR 64 (PR 62's convert.cpp; each edit applies to e21480b05's file by `patch --dry-run`); the others keep their head records, listed in section 6 and in A.5's sentences. Section 2.9 maps items (a) to (g); C.10 gives the comment reword (after the refill, in CT-1's order), L's message with R27's spelling diff and R31's counts, A.5's sentences (the checker runs, the mutants, R32's result), the held-state sentence by C.7's fallback (one CT-1 entry at e21480b05) and OR-5 step by step; R32's procedure was measured at upstream 68569d234 (the four quotes at appendix-witness.md:154, overview.md:376, p002200-template-generics.md:1095 and call.cpp:388; eight commits, none a rule for a checked generic's C++ calls) | Status, contents, conventions, 0.3, D-LAND-4, D-LAND-6 step 7, D-LAND-19, D-LAND-20, 2.7, 2.9, 3, 6, B.1, C.1, C.8, C.10 |
| RR2-2 | MINOR | Folded. Reproduced: bb9fbba9c fork/ORCHESTRATION.md:1123-1124 states 126/23/0 over 149 at PR 48's head, while trunk's scoreboard.json is 128/0/22 over 150 (generated 2026-10-06 02:26 UTC). A.9's last sentence is the review's text, with a dated note under it | A.9 |
| RR2-3 | MINOR | Folded. Reproduced: fork/cpp-templates/plan.md is absent at bb9fbba9c and d03be4456, present at e21480b05; PR 51's split header (f96fe8a7a) says "W-127 carries the limit and its removal condition". C.8's F6 sentence cites 551a03328's file as held PR 64's and gains the sentence on L's state-L departures (R27), and W-127's notes gain the split's sentence | 2.7, C.8 |
| RR2-4 | MINOR | Folded. Reproduced: file_test_base.cpp:131-160 reports a `fail_` split that succeeds as a problem autoupdate cannot fix; DR-1 measured "1962 passed and 1 failed, L-b's rename 1/1" (fee0ef31c fork/direction/plan.md:2756-2758). Step 4 expects that report for the split section 2 renames at PR 64 and at PR 65, counted in `<g0>` and `<gn>`; step 7's stop applies to the gate after step 6's commits; hand-off note 8, sections 2.9 and 2.11 and A.1 say so | D-LAND-6 steps 4 and 7, 2.9, 2.11, hand-off note 8, A.1 |

Checks of this revision: as rev 3's, with R31's counts before the edits,
after them and after each prek run, recorded in the commit message.

## Focused re-review fold record, round 3 (rev 5, 2026-11-01)

The focused re-review's round 3 of rev 4 (81699e9c4) returned
APPROVE-WITH-AMENDMENTS. It found RR2-1 to RR2-4 resolved: CT-1's items (a)
to (g) and its branch's item 6 mapped; lines 260 and 261 of
template_symbolic_arg.carbon matching on 551a03328 and e21480b05; in
e21480b05's non-testdata diff only convert.cpp is CT-1's, edited by M6, M7,
M23, M24, M75 and M75r alone; TP-1's 32 files disjoint from string.carbon
and export.cpp; the cites of TP-1's :6389-6390 and :7121 and CT-1's
:3871-3872, :3906-3911, :4793-4799 and :4809-4868 checked; the four quotes
and the eight commits reproduced at 68569d234; the held-state anchor once;
A.9 agreeing with D-LAND-17 and section 0.8; the F6 sentence and W-127's
split note; file_test_base.cpp:131-160 and DR-1's :2730-2758. All eighteen
heads matched `git ls-remote`, trunk was bb9fbba9c and upstream 68569d234;
prek was clean with no changes; R31's counts were 1/15/50 headings, 69
bullets, 20 numbered, 183 rows and 54 blocks, 0 unguarded; the
model-identifier grep found nothing. It found 2 MAJOR and 4 MINOR, N-1 to
N-6, here RR3-1 to RR3-6. All six are folded; none is rejected. Each was
reproduced first in `$F3`; no scratch worktree was needed, because the heads
and the dry run's scratch commits were read with `git show`, `git diff` and
`git log`.

| Id | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR3-1 | MAJOR | Folded. Reproduced: DR-1's L-b renames the split and rewords its comment, "its comment says that the choice is made per specific" (fee0ef31c fork/direction/plan.md:3066-3067; also :1586-1590, :2451, :4821-4823, :5463-5466), and gives no text; write_through.carbon, identical at fee0ef31c and d3eb55f7a, holds the six-line comment "The current behavior, pinned: ... so `G(V)` is rejected" at :121-126, false once the split succeeds. Section 2.11 maps L-b as a rename commit with its own message, then the refill; C.12 gives the six replacement lines (the same line count, 831 lines kept, seven lines changed on a copy) and amends the W-340 note's last clause; the refill's diff of the file must be the seven STDERR lines removed and nothing else (the split has no SemIR dump); D-LAND-8 puts a plan's comment edit in its rename commit | 0.7, D-LAND-8, 2.11, C.12, 6 |
| RR3-2 | MAJOR | Folded. Reproduced: rev 4's log over call.cpp, cpp/call.cpp, generics/ and p002200 read 8 commits at 68569d234; CT-1's section 0.10 (551a03328 fork/cpp-templates/plan.md:891-935) gives a verdict per upstream commit to each file CT-1 changes; type_mapping.cpp:461 and :464 declare and emit `CppCallArgTypeNotSupported` at 68569d234; 57bf903ef (2026-10-26) touches generic.cpp, generic.h and cpp/generate_ast.cpp and adds bidirectional_generic_call.carbon. Section 2.9's log is widened to CT-1's sixteen files, its three testdata paths, toolchain/check/cpp/, docs/design/ and proposals/, with E-ARG's grep, a verdict per commit saved as `r32.txt`, and E-ARG absent as a stop; measured at 68569d234: 59 commits, 29 keeping section 0.10's verdicts and 30 judged now, none a rule for a checked generic's C++ calls; 57bf903ef is adjacent, its `var unused w: Cpp.Wrapper(T);` passing under min_prelude/int.carbon's unconstrained `DefaultOrUnformed` impl (parts/default.carbon:19) while core/prelude/default.carbon:50 still requires `T: UnformedInit`. `<v3>` and `<v3n>` are redefined over the set, and A.5's R32 sentence names it | conventions, 2.9, 6, C.10 |
| RR3-3 | MINOR | Folded: D-LAND-6 says section 2's order governs where it interleaves steps 6 and 7 (PR 64's rename, refill, comment commit and L; PR 65's C-b, probes, rename and refill); step 7's stop applies to the gate after the landing's last rename commit, and a gate before it (step 4's, C-b's at PR 65) may report only the allowed `fail_`-prefix problem | D-LAND-6 |
| RR3-4 | MINOR | Folded. Reproduced: TP-1's landed notes' Ledger re-cites (66aa13132 fork/templates/plan.md:7905-7914) re-cite W-250, W-251, W-253, W-256, W-264, W-265 and W-014's lower/handle.cpp cite at land time; rev 4 cited only :7919-7936. Section 0.3 cites :7905-7914; section 2.7 item 13 maps the re-cites; C.8 gives the rule (line numbers only, a cite not found a stop). The same notes' item (c) counts ten F6 refills (:7923-7925), where section 3 item 8 still says seven; sections 0.7 and 2.7 now say ten | 0.3, 0.7, 2.7, C.8 |
| RR3-5 | MINOR | Folded. Reproduced: TP-1's mutant scratch includes scratchpad/tp1-impl/stage4/ (bin/mutate.py, bin/allmut.sh) and scratchpad/tp1-fixer/ (bin/relink.sh); CT-1's driver scratchpad/ct1-impl/fixer/bin/mutrun.sh runs the gate, the programs and the 250 probes of logs/list_r1.tsv, and for M75 and M75r the 403 of stage4/list403.tsv (551a03328 fork/cpp-templates/plan.md:3866-3875, :3891-3892). D-LAND-20 names all four TP-1 directories, runs every probe set a record ran against the landing's unmutated install or names the set not run in `<mut>`, and describes CT-1's rule as by function, the file rule its superset | conventions, D-LAND-20 |
| RR3-6 | MINOR | Folded: the autoupdate no-op check runs after the comment commit, `$CB/autoupdate.sh` on the golden then `git status --porcelain --` on it | 2.9 |

Checks of this revision: as rev 4's, with R31's counts before the edits,
after them and after each prek run, recorded in the commit message.

## Review fold record (rev 6, 2026-11-01)

The orchestrator's ruling under R29 after round 3 (recorded verbatim above)
ordered a completeness audit before round 4. Twelve fresh agents, one per ready
PR, enumerated 381 land-time steps from each PR's own records and the other held
plans, against rev 5 (01f17f2ad): 202 MAPPED, 32 MOVED, 72 UNMAPPED and 75
NOT-A-STEP. Every UNMAPPED step was reproduced first, its cite opened on the
PR's head (section 6 lists what the rev-6 fixer measured), and folded with a
text or a rule and a dated mark "(amended 2026-11-01, ruling fold: AUD-67-P11)"
and the like: "AUD-", the PR number, a hyphen and the audit's step id, with a
prefix of the id that repeats the PR number dropped (AUD-52-02 is P52-02). No
UNMAPPED step is rejected; three are folded as "not owed" or "already made" with
the evidence that shows it, each named in section 2 (AUD-58-U5, AUD-63-13,
AUD-65-A1), and AUD-58-U1, which the audit measured as a no-op on the heads, is
folded as a step, because EV-1's state C commit meets D-DD-6's condition.
MAPPED, MOVED and NOT-A-STEP are as the audit found them, by id; the audit's
notes on steps it did not count UNMAPPED are folded where they named a defect.
The ruling's items: item 1, this audit; item 2, every UNMAPPED step folded, the
ruling recorded, and PR 53's gate restated in D-LAND-12, section 3's G-53, B.1's
dated paragraph, its safe-row mark, its Next actions lead and item 14,
section 0.2, the Summary, R-4, C.2's marks and W-343's note; item 3, rounds
4 and 5 (the Status line). D-LAND-13: W-371 onward stays PR 53's
realignment's next id;
nothing is minted, no F id is minted, and W-357 to W-359, W-364, W-365 and W-366
are untouched.

| PR | Audit ids | Status | Disposition | Where |
| --- | --- | --- | --- | --- |
| 67 | P1 to P10, P13, P15 to P19, P23, P24, P27, P30, P31 | MAPPED | As found; P7's and P9's texts restated by the ruling's item 2 | C.2 |
| 67 | P14, P20, P21, P22, P26 | MOVED | As found; P26's gate restated | D-LAND-4, D-LAND-12, B.1 |
| 67 | P32 to P38 | NOT-A-STEP | Accepted: a cite form that stays true, triggers unmet (W-346, UA-3), RG-1's own commits, done at R2 | none |
| 67 | P11 | UNMAPPED | Folded: the same dated mark on the six lines that restate the superseded order, each anchor once on 56e2e5bbd | 2.1, C.2 |
| 67 | P12 | UNMAPPED | Folded: a dated mark recording section 6's break condition met and its renumbering commit moot (2f4ebbf6e); the mark says "superseded" since 2026-11-01 (review fold: RR4-3), that condition not being met | 2.1, C.2 |
| 67 | P25 | UNMAPPED | Folded: RG-1's date rule makes every "2026-10-27" of the notes read "2026-10-28", the lead naming trunk's heading | D-LAND-15, C.3, C.5, C.7, B.1 items 16 and 17 |
| 67 | P28 | UNMAPPED | Folded: C.2's W-355 note keeps W-355's own L-check rule and says the landing edits no row or count | 2.1, C.2 |
| 67 | P29 | UNMAPPED | Folded: G-53's PR 67 note commit spans the ledger, the two TSVs, rg1-plan.md and RG-1's entry, owned by the realignment | D-LAND-12, 3, B.1 item 14 |
| 51 | E02, E09 to E15, E17, E18, E21 to E24 | MAPPED | As found | 2.2 |
| 51 | E01, E03 to E08, E19, E25, E26 | NOT-A-STEP | Accepted: branch-side and done, conditional, or other PRs' steps; E07's stale Toolchains list is the orchestrator's | none |
| 51 | E16 | UNMAPPED | Folded with P25: the note is :2534-2542, without its locator, with the date rule | 2.2, D-LAND-15, C.3 |
| 51 | E20 | UNMAPPED | Moved: OP-2's W-197 fold into W-126 is G-56/57's, W-197 being on PR 57 only | 2.2, D-LAND-4, 3, B.1 item 16, C.1 |
| 52 | P52-01, 05, 06, 09 to 17 | MAPPED | As found | 2.3 |
| 52 | P52-04, 18 to 22 | NOT-A-STEP | Accepted; P52-22's "not of record" notes take A.10's widened mark | A.10, C.4 |
| 52 | P52-02 | UNMAPPED | Folded: CM-1's delta rule is section 4's PR 52 cell; section 0.3 corrected | 0.3, 2.3, 4 |
| 52 | P52-03 | UNMAPPED | Folded: step 9 counts duplicate ids, W-126 to W-133 once each (5b6cc69ed measured) | 2.3 |
| 52 | P52-07, P52-08 | UNMAPPED | Folded: the Option B trigger and the rows' revert stop the landing, the fix CM-1's on its branch; host tools recorded | 2.3 |
| 54 | EV54-01 to 06, 13 to 15, 19 to 28 | MAPPED | As found | 2.4 |
| 54 | EV54-29 to 31 | NOT-A-STEP | Accepted; EV54-30 is PR 58's U1, folded there | 2.6 |
| 54 | EV54-07 | UNMAPPED | Folded: section W11's state C text with `<date>`, its label taking A.10's widened mark | 2.4, C.5, A.10 |
| 54 | EV54-08, EV54-09 | UNMAPPED | Folded: W-131's, W-133's and W-002's state C texts | 2.4, C.5 |
| 54 | EV54-10 | UNMAPPED | Folded: the state C commit regenerates the README table | 2.4 |
| 54 | EV54-11 | UNMAPPED | Folded: R-8's re-pin of the entry's runner.py cites by C.8's rule | 2.4 |
| 54 | EV54-12 | UNMAPPED | Folded: DL-2, the landed region newest first | D-LAND-5, 2.4 |
| 54 | EV54-16 to 18 | UNMAPPED | Folded: check_faq.py with both toolchains and the nightly runner pass, a difference stopping the landing | 2.4 |
| 55 | S55-01, 03, 04, 06 to 08, 10, 13, 14, 19 to 21, 23 | MAPPED | As found; S55-01's "refused" merge recorded in A.5, S55-07's id order and S55-19's "discharged" made accurate | D-LAND-5 LG-1, 2.5, C.6 |
| 55 | S55-15 to 18 | MOVED | As found | B.1 item 14 |
| 55 | S55-24 to 32 | NOT-A-STEP | Accepted: other PRs' steps, done on the branch, or upstream merges | none |
| 55 | S55-02 | UNMAPPED | Folded: DL-2 | D-LAND-5, 2.5 |
| 55 | S55-05 | UNMAPPED | Folded: row 77's floor of record re-read to PR 51's run 37413300832 | 2.5, C.6 |
| 55 | S55-09 | UNMAPPED | Folded: the re-stamp commit's eight texts; A.6's anchor follows | 2.5, C.1, C.6 |
| 55 | S55-11 | UNMAPPED | Folded: the W-148 commit (the title, measured counts), G-53 restoring the id | 2.5, C.6, B.1 item 14 |
| 55 | S55-12 | UNMAPPED | Folded: D-LAND-21 (measured: only refs on ST-1's own line) | D-LAND-21, 2.5 |
| 55 | S55-22 | UNMAPPED | Moved: the re-reads SAFE-1's pages need (arithmetic.md :190 to :199 measured) | D-LAND-4, 2.5, B.1 item 14 |
| 58 | M1 to M18 | MAPPED | As found; M3's placement is DL-2's | D-LAND-5 |
| 58 | MV1 to MV6 | MOVED | As found; MV2's anchor, MV4's X12 deletion and MV5's templates.md rule now named | B.1 items 14 and 15 |
| 58 | N1 to N6 | NOT-A-STEP | Accepted; N6's phantom error_handling.md credit corrected to DR-1's rule | 3, B.1 item 16 |
| 58 | U1 | UNMAPPED | Folded: EV-1's state C commit meets D-DD-6's condition, so DD-1's checker joins `--self-test` | 2.6, C.7 |
| 58 | U2, U3 | UNMAPPED | Folded: step 6's R31 rule and the state-L message with DD-1's checks; `<ddn>` and `<r31>` defined | D-LAND-6, 2.6, C.7, conventions |
| 58 | U4 | UNMAPPED | Folded: D-DD-9 fired; W-187 stays unused, A.5 and A.6 say so | D-LAND-14, 2.6, C.7 |
| 58 | U5 | UNMAPPED | Folded as already made: trunk's paragraph (bb9fbba9c :183-190) records it | 2.6 |
| 58 | U6 | UNMAPPED | Folded: F-016's re-read sentence in A.5 and A.6 | 2.6, C.7 |
| 58 | U7 | UNMAPPED | Folded: the ledger source's OP-2 range made W-196..W-201 | 2.6, C.7 |
| 58 | U8 | UNMAPPED | Folded with P25: lead, `<tip>` and dates | D-LAND-15, C.7 |
| 61 | T01 to T03, T09 to T14, T16, T17, T19, T22 to T24, T27, T31 | MAPPED | As found; T03's id order recorded | D-LAND-5 LG-1 |
| 61 | T07, T08 | MOVED | As found | D-LAND-4 |
| 61 | T32 to T34 | NOT-A-STEP | Accepted | none |
| 61 | T04 | UNMAPPED | Folded: DL-2 with step 9's check | D-LAND-5, D-LAND-6, 2.7 |
| 61 | T05 | UNMAPPED | Folded: OR-2 replaces both rows by A.3's | D-LAND-5, 2.7 |
| 61 | T06 | UNMAPPED | Moved: M's rules for SC-1's hunks to G-60 | D-LAND-4, 2.7, 3, B.1 item 15 |
| 61 | T15 | UNMAPPED | Folded: D-LAND-21's reading and its collision stop | D-LAND-21, 2.7 |
| 61 | T18 | UNMAPPED | Folded: step 6's R31 rule | D-LAND-6, 2.7 |
| 61 | T20, T21 | UNMAPPED | Folded: R's marker text (lower/handle.cpp :513 to :524 measured) and its message rule | 2.7, C.8 |
| 61 | T25 | UNMAPPED | Folded: A.3 and A.4 replace Appendix E's stamp | 2.7, A.4 |
| 61 | T26 | UNMAPPED | Folded: `<rescan>` in A.4 to A.6 and C.8's checker sentence | conventions, A.4 to A.6, C.8 |
| 61 | T28 | UNMAPPED | Folded: A.10's mark widened to ledger notes and prose | A.10, 2.7 |
| 61 | T29 | UNMAPPED | Folded: D-TP-16's upstream log at `<tip>` with verdicts (44 commits measured, not judged) | 2.7 |
| 61 | T30 | UNMAPPED | Folded: DR-1's note in PR 61's and PR 64's A.5, and the review's literal-form check, an abort where trunk diagnoses stopping the landing; since 2026-11-01 (review fold: RR4-1) D-LAND-22 decides the outcome: the abort is W-259's, and only a result other than D-LAND-22's stops the landing (marked 2026-11-02, review fold: RR5-3) | 2.7, 2.9, C.8, C.10, D-LAND-22 |
| 62 | S01 to S03, S07, S13 to S17, S19, S20, S27 to S30 | MAPPED | As found; S15's and S16's departures recorded | C.9 |
| 62 | S05, S08, S11, S22, S24 to S26 | MOVED | As found; S24 is C.5's evidence only | D-LAND-4 |
| 62 | S10, S31 to S34 | NOT-A-STEP | Accepted; S10's withdrawal named in OR-5's message | 2.8 |
| 62 | S04 | UNMAPPED | Folded: the landing replaces the mirrors; the probe sets run or named not run | 2.8, C.9 |
| 62 | S06 | UNMAPPED | Moved: M19 and M21 with M-VA | D-LAND-4, 3, B.1 item 17, 6 |
| 62 | S09 | UNMAPPED | Moved: the nested-pointer leg and the conditional refill | D-LAND-4, 3, B.1 item 16 |
| 62 | S12 | UNMAPPED | Moved: Doc-M re-derived under SV-1's section 1.14 review; C.5's note withdrawn | D-LAND-4, B.1 item 16 |
| 62 | S18 | UNMAPPED | Folded: x19's path and expected output | 2.8 |
| 62 | S21 | UNMAPPED | Folded: C.8's re-cite rule, two cites measured unmoved | 2.8 |
| 62 | S23 | UNMAPPED | Moved: W-284's clauses with M-VA | D-LAND-4, B.1 item 17 |
| 64 | a1, a3, a4, a7 to a9, c2 to c5, d1, d2, e1, f1 to f6, g1, o1, o2 | MAPPED | As found | 2.9 |
| 64 | b1, b2, c1 | MOVED | As found | D-LAND-4 |
| 64 | a2, x1 to x6 | NOT-A-STEP | Accepted; x1 is folded with T30 | 2.9 |
| 64 | a5, a6 | UNMAPPED | Moved: CT-1's PR 60 and PR 57 compositions | D-LAND-4, 2.9, 3, B.1 items 15 and 16 |
| 63 | 1, 2, 4 to 6, 10, 14, 16 to 19, 22, 23 | MAPPED | As found | 2.10 |
| 63 | 3, 8 | MOVED | As found | D-LAND-4 |
| 63 | 9, 24 to 28 | NOT-A-STEP | Accepted | none |
| 63 | 7 | UNMAPPED | Folded: numstats in `<refilled>`, 12/17 and 137/137 required | conventions, 2.10 |
| 63 | 11, 12, 21 | UNMAPPED | Moved: error_handling.md's date-order rule, row 78's sentence, W-323's note | D-LAND-4, 2.10, 3, B.1 item 16 |
| 63 | 13 | UNMAPPED | Folded as not owed: item 9's own rule, the diffs measured empty | 2.10 |
| 63 | 15 | UNMAPPED | Folded: D-LAND-21 | D-LAND-21, 2.10 |
| 63 | 20 | UNMAPPED | Folded: W-322's, W-324's and W-326's notes in the records commit; the (i) stamp made by the merge | 2.10, C.11 |
| 65 | A2 to A9, A12 to A14, B1, B4, D1, D2, E1, G1 | MAPPED | As found; A3's message aligned to DR-1's | 2.11 |
| 65 | B5, E2, F1, F3, X1 | NOT-A-STEP | Accepted | none |
| 65 | A1 | UNMAPPED | Folded as not owed: item 9's rule, as at PR 63 | 2.11 |
| 65 | A10 | UNMAPPED | Folded: D-LAND-21 | D-LAND-21, 2.11 |
| 65 | A11 | UNMAPPED | Folded: C-b's mutant in D-LAND-20 | D-LAND-20, 2.11, C.12, 6 |
| 65 | A15 | UNMAPPED | Moved: DR-1's call.cpp and convert.cpp test to G-59 and G-60 | D-LAND-4, 2.11, 3, B.1 items 15 and 17 |
| 65 | B2, B3 | UNMAPPED | Folded: the sha slots and row 79's past tense with its marks | 2.11, C.12 |
| 65 | F2 | UNMAPPED | Moved: SAFE-2's DR-1 note to G-53, recorded in PR 65's A.5 | D-LAND-4, 2.11, B.1 item 14, C.12 |
| 68 | PR68-01, 02, 05, 06, 08 to 11, 13, 14, 16, 18, 20, 21, 23 to 26, 28 to 30 | MAPPED | As found; PR68-08's C.13 wording corrected | C.13 |
| 68 | PR68-03, 04, 22 | MOVED | As found | D-LAND-4 |
| 68 | PR68-07, 12, 27, 31 to 35 | NOT-A-STEP | Accepted | none |
| 68 | PR68-15 | UNMAPPED | Folded: W-355's note per landing and the rows' own failure clause (two T2.8 quotes fail at 68569d234) | D-LAND-19, 2.12, C.2, C.13 |
| 68 | PR68-17 | UNMAPPED | Folded: D-LAND-20's PR 68 part, M1, M2 and M8 predicted | D-LAND-20, 2.12, C.13, 6 |
| 68 | PR68-19 | UNMAPPED | Folded: step 9's ORCHESTRATION re-read at every landing | D-LAND-6, 2.12 |

Section 4's counts hold: the folded steps at the ready landings change no
program, SKIP or golden (the note under section 4's table). Appendix C
gives every text a newly mapped records step writes; where a step is a
rule over measured values (C.8's re-cite rule, A.10's mark, D-LAND-21's
`<rescan>`), its form is given and its values are measured at the
landing. R-7 records the risk this audit closes.

Checks of this revision: prek to a fixpoint with the SKIP set of hand-off
note 6, `uvx rumdl@0.2.58 check`, R31's counts before the edits, after
them and after each prek run, the scan for forbidden line starts, and the
model-identifier grep, recorded in the commit message.

## Focused re-review fold record, round 4 (rev 7, 2026-11-01)

The focused re-review's round 4 of rev 6 (7cc793057), the first under the
orchestrator's ruling, returned APPROVE-WITH-AMENDMENTS. It found all
eighteen heads, claude/carbon-fork-0-1-safe-wip (14c1ac8ac) and trunk
(bb9fbba9c) matching `git ls-remote`; round 3's N-1 and N-2 resolved
(C.12's six lines replace fee0ef31c write_through.carbon:121-126, 831
lines kept; section 2.9's sixteen-file set holds generic.cpp and generic.h
and its log covers 57bf903ef) and its N-3 to N-6 folded; the completeness
audit's MAJORs resolved but AUD-63-20 (RR4-2); and its spot checks
holding: C.2's eight anchors once each on 56e2e5bbd, ST-1's re-stamp texts
once each on 8beb5d7d5, W-148's counts (2/1/6) and title on 2407efa74,
DL-2 on all five heads, handle.cpp :513 becoming :524, OP-2's source
string and README lines :657 and :981 on 94dba6b21, D-DD-6 supporting U1,
the D-SAFE3-13, rev 11, rev 12 and Appendix D cites, the ruling recorded
verbatim, and section 4's table agreeing with D-LAND-4 and B.1's items 14
to 17. As the ruling's test it enumerated the land-time steps of PR 52, PR
68 and DR-1's PR 63 and PR 65: CM-1's and OV-4's map fully (OV-4's M7 is
not a plan mutant, 097c76473 fork/overload/ov4-plan.md:2413-2414), and
DR-1 has one unmapped step, RR4-2. It found no BLOCKER, 2 MAJOR and 5
MINOR, RR4-1 to RR4-7. All seven are folded; none is rejected. Each was
reproduced first in `$F5` (the probes in `$F5/probe/`, the (i) stamp's
merge in `$F5/rr4-2/`); no scratch worktree was needed, because the heads
and the dry run's scratch commits were read with `git show` and
`git diff`, the merge was made with `git merge-file` on copies, and the
probes ran on the existing installs, no build.

| Id | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR4-1 | MAJOR | Folded by a decision under R29, the review's option 2 with W-259 in place of W-369. Reproduced: the review's lit.carbon is rejected on trunk's install (0bdce60a5, rc 1, "unable to monomorphize specific `G(V)`") and stops at lower.cpp:48 on TP-1's and CT-1's (rc 134). Measured further: its variable form stops there on trunk, UA-2, ST-1, SV-1, DR-1a, OV-4, TP-1, CT-1 and the 2026.10.12 nightly; the same assignment outside a template is "expression is not assignable" on every fork install; a template's literal read is rejected on trunk and compiles on TP-1 and CT-1; handle_operator.cpp:110-118 skips a `Dependent` left operand at bb9fbba9c, 66aa13132 and upstream 68569d234, TP-1's two hunks there being the `&` and prefix `*` handlers; that unchecked path is W-259, TP-1's TR-21, out of its scope (66aa13132 fork/templates/plan.md:1743-1745). D-LAND-22 decides that the abort is W-259's, a trunk defect, not PR 61's; D-LAND-2 states its class (a root in the PR's own scope, as X-1's D-TP-11 and item 13's packs); C.8 gives W-259's note with its widened break condition; W-369 stays unused, a second item for one root duplicating W-259; sections 2.7, 2.9 and 2.11 check the measured results at PR 61, PR 64 and PR 65; option 1 is recorded rejected with its cost | Summary, D-LAND-1, D-LAND-2, D-LAND-22, 2.7, 2.9, 2.11, 5, C.8, C.12 |
| RR4-2 | MAJOR | Folded. Reproduced: on f2110e0fd, DR-0's block (:242-255) gives (i) as "(W-322, retired by DR-1 slice 1)" with no sha while (iii) carries its own, and on 5cf7406f1 it carries (ii) and (iii) only; trunk routes "(i) resolved 2026-10-21 by W-322's 22fe50ff8 and its fill f4660e409 on PR 62" to DR-1 (bb9fbba9c fork/decision-log.md:6908-6909) and its weekly table calls it a records gap. C.11 gives the two lines PR 63's records commit writes for the line "fill c1cc72a09." (once on f2110e0fd); a merge of that copy against fee0ef31c's log over 89aabd125's gives one conflict, this region, which DL-5 resolves into C.12's four lines, equal to the dry run's block with the (i) sentence added; section 2.10's sentence is corrected | D-LAND-5, 2.10, 2.11, C.11, C.12 |
| RR4-3 | MINOR | Folded. Reproduced: the condition at 56e2e5bbd rg1-plan.md:1704-1707, "every other PR before PR 66 is otherwise ready to land", is not met. C.2's mark reads "Superseded ... without this break condition being met"; section 2.1's sentence and the rev-6 fold record's P12 row are amended with dated marks | 2.1, C.2, rev-6 fold record |
| RR4-4 | MINOR | Folded. Reproduced: on 61458bc92 the ledger's runner.py line cites are W-002's :652, :597, :413 and :1665 and W-060's :597 (the review's :1148 is W-060's line), the cited functions there and unmoved through 5cf7406f1, which lacks state C and the join; no gap row cites a runner.py line. The state C commit at PR 54 and the join commit at PR 58 re-pin them by C.8's rule | 2.4, 2.6, C.7 |
| RR4-5 | MINOR | Folded. Reproduced: `$Y` and `$W` are SV-1's (0ef8a0334 fork/sumtype-interop/plan.md:172-173 and :181-183); the table is :5367-5372; the C3 run's log is scratchpad/sv1-impl/stage3/probes-c3-y.txt, 44 lines with the six W-263 stops. The conventions define both; section 2.8 names the log and the table's PR 61 row | conventions, 2.8 |
| RR4-6 | MINOR | Folded: "Five plans (six landings)" | D-LAND-21 |
| RR4-7 | MINOR | Folded by running it. Reproduced: DR-1's item 6 (fee0ef31c fork/direction/plan.md:2683-2694) ran clang-tidy on DR-1b's own handle_index.cpp, and mct-b checked C-b with clang-format only (:2733, :2757). Section 2.11 runs item 6's command after C-b's build over the compile database `ninja -t compdb` writes from carbon-trunk's build file (323 entries, handle_index.cpp among them), with /home/user/llvm/bin/clang-tidy 21.1.8; a user warning stops the landing; C.12's A.5 sentence records the result; section 6 names the exception | 2.11, 6, C.12 |

Checks of this revision: as rev 6's, prek to a fixpoint with the SKIP set
of hand-off note 6, `uvx rumdl@0.2.58 check`, R31's counts before the
edits, after them and after each prek run, the scan for forbidden line
starts, and the model-identifier grep, recorded in the commit message.

## Focused re-review fold record, round 5 (rev 8, 2026-11-02)

The focused re-review's round 5 of rev 7 (e2420b1c6), the second under the
orchestrator's ruling, returned APPROVE-WITH-AMENDMENTS. It found trunk
(bb9fbba9c), all eighteen heads and claude/carbon-fork-0-1-safe-wip
(14c1ac8ac) matching `git ls-remote`. It found RR4-1 resolved: lit, var,
nt_lit and rd_lit, re-run on trunk's, TP-1's and CT-1's installs, give
D-LAND-22's results; handle_operator.cpp:110-118 is the same at bb9fbba9c,
66aa13132 and 68569d234, TP-1's two hunks there being the `&` (:270) and
prefix `*` (:378) handlers and the assignment's handler (:97) untouched;
W-259's title, TR-21, its break condition and the W-014 quote hold on
66aa13132; and each install named differs from its PR's head under
testdata only. It found RR4-2 resolved: the merge redone on copies gives
one conflict, :255-276, whose resolution by C.12's four lines and trunk's
re-check paragraph equals the dry run's d3eb55f7a log but for the (i)
sentence. RR4-3 to RR4-7 are folded (SV-1's probe runner over the 44
programs on the SV-1 install, 4a9c18b07, prints the C3 log's output once
paths are normalized). Section 4, D-LAND-4 and B.1's items 14 to 17 were
not touched by rev 7; R31's counts were 1/19/50 headings, 75 bullets, 20
numbered, 297 rows and 82 blocks, none unguarded; the model-identifier
grep was clean. As the ruling's test it enumerated the land-time steps of
PR 51 (UA-2), PR 54 (EV-1) and PR 55 (ST-1) from their heads: each is
MAPPED or MOVED with a cite, none UNMAPPED. It found no BLOCKER, no MAJOR
and 3 MINOR, RR5-1 to RR5-3, dependent lines rev 7 left stale. All three
are folded; none is rejected. Each was reproduced first in `$F6`
(`$F6/rr5-greps.txt` on rev 7's text, and RR5-1's merge redone on copies
in `$F6/rr5-1/`: one conflict at :255-276 with C.11's two lines, none
without them); no scratch worktree was needed and nothing was built.

| Id | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR5-1 | MINOR | Folded. Reproduced (the lines cited in this table are e2420b1c6's): rev 7's section 0.5 (:421-424) counted two predicted land-time conflicts, PL-1 and DL-4, while D-LAND-5's DL-5 (:840-848) and section 2.11 (:2007-2013) predict a third at PR 65's merge, on DR-0's register block, which PR 63's records commit edits by C.11; a copy of f2110e0fd's log with C.11's two lines, merged against fee0ef31c's over 89aabd125's, gives one conflict (:255-276), and none without them. Section 0.5 counts three, all at PR 65's merge, DL-5 among them, citing `$F5/rr4-2/` | 0.5 |
| RR5-2 | MINOR | Folded. Reproduced: D-LAND-13 (:1106-1108) filed W-369 only in trunk's ledger by a landing's records commit, while D-LAND-22's break condition (:1422-1424) files it beside a fix on TP-1's branch "as D-LAND-13 files W-367". D-LAND-13 names both places: under D-LAND-22's break condition, W-369 in TP-1's branch's ledger (fork/inventory/work-items.json on claude/carbon-fork-0-1-tp, present at 66aa13132) by a records commit beside the fix. B.1's "W-367 to W-370 are reserved to LAND-1", section 0.10, R-4 and D-LAND-13's break condition hold unchanged | D-LAND-13 |
| RR5-3 | MINOR | Folded. Reproduced: the rev-6 fold record's T30 row (:4039) still read "an abort where trunk diagnoses stopping the landing", the rule D-LAND-22 replaced, while the P12 row (:3986) carries RR4-3's mark. The row's disposition gains the review's sentence, dated by RR4-1, with an RR5-3 mark, and its Where cell names D-LAND-22; section 2.7, C.8 and C.10 already state D-LAND-22's rule | rev-6 fold record |

The orchestrator's sign-off checks, made by this fixer (added 2026-11-02,
sign-off check). Every placeholder in Appendices A to C is in the
conventions table or is a C.1 field but one,
`<the FAIL rows' ids>` (C.2, C.3 and C.13), which C.2 had defined in
place: the table now defines it, C.2's longer spelling of it is made the
same, and C.1 now says that each column fills the placeholder of its
name, `<N>` the PR column's; the other angle-bracket forms there are
C++ text (`<...>`, `<T>`, `<Ts...>`, `<long>`, `<short>`) or the slots of
TP-1's, CT-1's and DR-1's own texts that Appendix C cites, which the
conventions now say are set where Appendix C cites them (`$F6/bin/ph.py`,
`$F6/phcheck.txt`).
Section 4's row for each of the twelve PRs equals section 2's expected
gate, PASS, FAIL, SKIP, programs and tally (`$F6/bin/s4check.py`,
`$F6/s4check.txt`: 0 mismatches). The scan for forbidden line starts,
run over every line outside the code blocks, found five prose lines that
rev 6 (7cc793057) had left beginning with a digit and a period: "5.4's"
in section 0.3, "2.10;" in section 2.11, "2026.10.12," in A.10, and
"0.2" in C.5 and in the rev-6 fold record; each is rewrapped so that its
number follows the word before it.

Checks of this revision: as rev 7's, prek to a fixpoint with the SKIP set
of hand-off note 6, `uvx rumdl@0.2.58 check`, R31's counts before the
edits, after them and after each prek run, the scan for forbidden line
starts, and the model-identifier grep, recorded in the commit message.

## Sign-off

Signed off for implementation 2026-11-02 at rev 8, by the orchestrator's
ruling's item 3 (recorded verbatim above): round 5 of the focused
re-review found no BLOCKER and no MAJOR, and its three MINORs are folded
in this revision. The reviews of this plan, each folded with none
rejected:

| Review | Of | Verdict | BLOCKER | MAJOR | MINOR | Folded in |
| --- | --- | --- | --- | --- | --- | --- |
| Review A | rev 1 (e2691e3e1) | REJECT | 1 | 4 | 4 | rev 2 (adaf45757) |
| Review B | rev 1 (e2691e3e1) | REJECT | 1 | 7 | 8 | rev 2 (adaf45757) |
| Focused re-review, round 1 | rev 2 (adaf45757) | REJECT | 1 | 1 | 4 | rev 3 (a8fa4d68b) |
| Focused re-review, round 2 | rev 3 (a8fa4d68b) | APPROVE-WITH-AMENDMENTS | 0 | 1 | 3 | rev 4 (81699e9c4) |
| Focused re-review, round 3 | rev 4 (81699e9c4) | APPROVE-WITH-AMENDMENTS | 0 | 2 | 4 | rev 5 (01f17f2ad) |
| Completeness audit (the ruling's item 1, twelve agents) | rev 5 (01f17f2ad) | 381 land-time steps: 202 MAPPED, 32 MOVED, 72 UNMAPPED, 75 NOT-A-STEP | -- | -- | -- | rev 6 (7cc793057), all 72 UNMAPPED steps |
| Focused re-review, round 4 | rev 6 (7cc793057) | APPROVE-WITH-AMENDMENTS | 0 | 2 | 5 | rev 7 (e2420b1c6) |
| Focused re-review, round 5 | rev 7 (e2420b1c6) | APPROVE-WITH-AMENDMENTS | 0 | 0 | 3 | rev 8 (this revision) |

The seven reviews returned 51 findings, 3 BLOCKER, 17 MAJOR and 31 MINOR;
the audit's 72 UNMAPPED steps are graded by status, not severity. What
follows sign-off is D-LAND-16's: the orchestrator pushes land-prep's
commits and Appendix B.1's stamp, with `<r>` 8, to trunk and the mirror
by fast-forward before stage 0.

## Landing-time rulings

Rulings of the orchestrator under R29 during the landing, each recorded by the
landing's records commit (D-LAND-9 as amended by the first):

<!-- google-doc-style-ignore -->

> (1) FC1-1 / RV67-1: a file:line cite inside a records text names the lines of
> the tree the records commit produces, so a cite that the landing's own records
> edit moves is written at its moved lines; the implementer's W-355 note, citing
> fork/register/rg1-plan.md:1398-1401 (the L-check rule after this landing's
> four-line mark at :867), is the correct application, and the plan is amended
> to say so by three exact edits of fork/land/land1-plan.md, made in the landing
> worktree beside the records edits and committed by this landing's records
> commit (D-LAND-9's list is extended by this ruling: the orchestrator's
> landing-time rulings and their plan amendments go in the landing's records
> commit): (a) D-LAND-9's break condition gains, after "never the stale text.",
> the sentence: "A file:line cite inside a records text names the lines of the
> tree the records commit produces, so a cite that the landing's own records
> edit moves is written at its moved lines, and the orchestrator's landing-time
> rulings with their plan amendments go in the landing's records commit (amended
> 2026-11-02, fold check FC1-1 at PR 67, the orchestrator's ruling under R29).";
> (b) in Appendix C.2's W-355 text block,
> "(fork/register/rg1-plan.md:1394-1397)" becomes
> "(fork/register/rg1-plan.md:1398-1401)", and the paragraph that follows the
> block ("The last placeholder is the scripts' own output ...") gains, after its
> first sentence, the sentence: "The cite names the L-check rule's lines in the
> tree the records commit produces: :1394-1397 at the merge, :1398-1401 once
> PR 67's records edit adds its four lines at :867, re-measured at each later
> landing that edits rg1-plan.md above the rule (amended 2026-11-02, fold check
> FC1-1 at PR 67, by D-LAND-9's break condition as the ruling states it).";
> (c) a new section "## Landing-time rulings" after the Sign-off section, with
> one paragraph per ruling: this ruling's items (1) to (3) verbatim under the
> heading's lead sentence "Rulings of the orchestrator under R29 during the
> landing, each recorded by the landing's records commit (D-LAND-9 as amended
> by the first):".
>
> (2) RV67-2 / FC1-2's second half: the records' `<date>` and `<hh:mm>` are the
> values measured when the records edits were written at step 9; step 12's
> two-value check governs, so they are not re-measured at the commit, and the
> records commit's message states "records written <date> <hh:mm> UTC,
> committed <now> UTC"; the conventions table's row for `<date>`, `<hh:mm>`
> gains, after its "Measured by" text, " (step 9's values, kept at step 12;
> amended 2026-11-02, RV67-2, the orchestrator's ruling under R29)".
>
> (3) RV67-3 / FC1-2: Appendix A.4's "<landed> PRs landed" stands as the plan's
> text at this landing ("1 PRs landed"); no amendment, the texts of later
> landings reading 2 or more.
>
> (4) Before PR 51's landing (stage 2), on PR 67's fold check 2: (1) FC2-1 and
> FC2-3: in the conventions table, the row whose first cell is `<date>`,
> `<hh:mm>` is replaced whole by this row: "| `<date>`, `<hh:mm>` | the UTC date
> and time the records edits were written at step 9, kept at step 12 |
> `date -u +%F` and `date -u +%H:%M` when the records edits are written at
> step 9 (reworded 2026-11-02, FC2-3, from the commit-time rule that RV67-2's
> ruling superseded; the records commit's message states 'records written <date>
> <hh:mm> UTC, committed <now> UTC') |", and directly after it this new row is
> inserted: "| `<now>` | the records commit's UTC date and time, written in the
> records commit's message only, never in a records text | `date -u +%F` and
> `date -u +%H:%M` when the records commit is made (added 2026-11-02, FC2-1, the
> orchestrator's ruling under R29) |"; and D-LAND-6's step 12 gains, after
> "mirror as in step 11.", the sentence: "The records commit's message states
> 'records written <date> <hh:mm> UTC, committed <now> UTC' (added 2026-11-02,
> RV67-2 and FC2-3, the orchestrator's ruling under R29)." (2) FC2-2: the
> Contents list gains, after its last bullet "- Sign-off", the bullet
> "- Landing-time rulings (the orchestrator's rulings under R29 during the
> landing)".
>
> (5) At PR 54's landing (stage 4), on the implementer's stop at step 9 and two
> notes of its report: (1) The gap-row check: section 2.4 prescribes the state C
> commit's rewrite of row 90 (EV-1's section 5.3 state C text, over the PR's row
> that the merge took by GA-1) but its check names no row, because the dry run
> did not simulate the state C commit ($F/checkers.txt: "state C not
> simulated"), so the check at the landing reports the PR's replaced words as
> missing; rowcheck.py's own rule ("Rows named as ROW_KEY arguments (a plan
> rewrites them, section 2) are reported but not failed") governs, and row 90 is
> named: (a) in section 2.4, "(static 142/0/17 at the merge). Gap-row check: no
> row named. Deferred: none." becomes "(static 142/0/17 at the merge). Gap-row
> check: row 90 named (the state C commit writes EV-1's section 5.3 state C text
> over the PR's row, which the merge took by GA-1; amended 2026-11-02, the
> implementer's stop at step 9, the orchestrator's ruling under R29). Deferred:
> none."; (b) in section 0.5, after "($F/checkers.txt has the checker runs).",
> the sentence: "The dry run did not simulate PR 54's state C commit
> ($F/checkers.txt: 'state C not simulated'), so its check at PR 54 was the
> merge's, 0 missing with no row named; at the landing the state C rewrite of
> row 90 makes row 90 a named row (section 2.4 as amended 2026-11-02, the
> orchestrator's ruling under R29)."; (c) the check is re-run in the landing
> worktree as `python3 -I $F/bin/rowcheck.py d1a6506b0 cb3ef2e74 WORKTREE
> "Project: basic evaluator documentation (getting started to FAQs)"`, logged as
> logs/step9-rowcheck-ruled.log, and must print the row as "named in section 2"
> and `rowcheck: 0 missing` with exit 0; the records edits themselves stand as
> written (the worktree's row 90 is section 5.3's state C text with the PR's own
> date 2026-10-13 and A.10's mark, verified by the orchestrator word for word).
> (2) The nightly: section 2.4's fallback reads "when the fetch fails"; at this
> landing the 2026.11.01 nightly was fetched
> (carbon_toolchain-0.0.0-0.nightly.2026.11.01.tar.gz,
> sha256 7d0c2f8f04c59af4a7f9b57ede0dc4df199fa8e88deb76536d607dab8f410b9e,
> logs/step8-nightly-fetch.log) and running it was refused by the session's
> permission policy, so it was deleted unexecuted and the installed 2026.10.12
> nightly ran (check_faq.py --which nightly: 17 reproducers run, 0 errors; the
> runner with its busybox and --filter project/evaluator: 9 PASS, 2
> COMPILE-FAIL, D-EV-2's expectation); a fetched nightly that cannot be run is,
> for the fallback's purpose, a failed fetch: in section 2.4, "(the
> installed 2026.10.12 nightly when the fetch fails, named in the records
> commit's message as the reason)" becomes "(the installed 2026.10.12 nightly
> when the fetch fails or the fetched nightly cannot be run under the session's
> permission policy, named in the records commit's message as the reason with
> the fetched nightly's version and sha256; amended 2026-11-02, the
> orchestrator's ruling under R29, on the 2026.11.01 nightly fetched and refused
> at this landing)", and this landing's records commit message names the fetched
> nightly's version and sha256, the refusal, the fallback
> nightly 0.0.0-0.nightly.2026.10.12+62f1cc6 and both results. (3) The header:
> EV-1's section 2.F.1 state C clause "the expected scoreboard the parenthetical
> quotes becomes the §5.1 state C figure" (cb3ef2e74
> fork/evaluator/plan.md:1648-1652) has no object on the merged trunk, whose
> header parenthetical at d1a6506b0 is Appendix A.8's measured sentence from
> PR 52's landing, so the state C commit did not write it and the records commit
> writes the header's first sentence from this landing's measurements by A.8,
> D-LAND-9's break condition applied as the implementer applied it: in
> section 2.4, "(sections 2.F.1 and 5.3; the tally 33/19/3/1)" becomes
> "(sections 2.F.1 and 5.3; the tally 33/19/3/1; 2.F.1's clause on 'the expected
> scoreboard the parenthetical quotes' has no object on the merged trunk, whose
> header parenthetical is A.8's measured sentence from PR 52's landing, so it is
> not written and A.8's sentence from this landing's measurements governs,
> D-LAND-9's break condition; recorded 2026-11-02, the orchestrator's ruling
> under R29)".
>
> (6) At PR 54's landing (stage 4), on review round 1's R54-1, R54-2 and R54-3:
> (1) R54-1: the state C commit filled EV-1 section 2.F.1's header clause
> "row 90 PARTIAL → DONE 2026-10-DD" with the PR's own state T value 2026-10-13
> (cb3ef2e74 fork/gap-analysis.md:19), and Appendix A.8's sentence replaces the
> clause in the records commit; the fill is confirmed and no tree changes: in
> section 2.4, "measurements governs, D-LAND-9's break condition;
> recorded 2026-11-02, the orchestrator's ruling under R29), W-131's and W-133's
> notes" becomes "measurements governs, D-LAND-9's break condition;
> recorded 2026-11-02, the orchestrator's ruling under R29; the header clause's
> '2026-10-DD' takes the PR's own state T value 2026-10-13, cb3ef2e74
> fork/gap-analysis.md:19, and A.8's sentence replaces the clause in the records
> commit, recorded 2026-11-02, R54-1, the orchestrator's ruling under R29),
> W-131's and W-133's notes". (2) R54-2: the state C commit re-pinned EV-1's
> decision-log cite of `run_cmd` to the merged runner's :564-575, where
> `run_cmd` is PR 52's, with `cwd` and `env` parameters
> (fork/conformance/runner.py:564, :573-574) that the compile, link and run
> calls at :700, :727 and :748 leave unset, so the entry's state T words stand
> and the records edit states what the cited lines now hold: in
> fork/decision-log.md's EV-1 entry, "runs without a `cwd` (:564-575), so the
> program SKIPs" becomes "runs without a `cwd` (:564-575; re-pinned at the
> landing, 2026-11-02, LAND-1: the merged runner's `run_cmd` is PR 52's, with
> `cwd` and `env` parameters that the compile, link and run calls at :700, :727
> and :748 leave unset), so the program SKIPs"; and Appendix C.5 gains, between
> its W-002 block and its "OR-5:" paragraph, the paragraph: "Re-pin note
> (added 2026-11-02, R54-2, the orchestrator's ruling under R29): in EV-1's
> decision-log entry, inside the parenthetical "(:564-575)" that the state C
> commit re-pinned, the records commit appends after the cite "; re-pinned at
> the landing, 2026-11-02, LAND-1: the merged runner's `run_cmd` is PR 52's,
> with `cwd` and `env` parameters that the compile, link and run calls
> at :700, :727 and :748 leave unset"." (3) R54-3: W-062's two
> fork/gap-analysis.md cites (the PR's evidence, merged by LG-1) and W-060's W11
> cite name lines that this landing's header rewrite, state C text and A.10
> marks moved, so by C.8's re-cite rule they are re-pinned to the records tree,
> measured there: row 90 at :91, section W11 at :262-290, its paragraph
> at :266-276 and its arbiter paragraph at :278-290: in
> fork/inventory/work-items.json, W-062's evidence "fork/gap-analysis.md:93
> (row 90, DONE on transcription plus document review; the header's three added
> lines moved it from :90)" becomes "fork/gap-analysis.md:91 (row 90, DONE on
> transcription plus document review; the header's three added lines moved it
> from :90, and LAND-1's header rewrites to :91, re-pinned 2026-11-02 at PR 54's
> landing)", its "fork/gap-analysis.md:264-281 (the W11 paragraph and arbiter,
> with the EV-1 notes)" becomes "fork/gap-analysis.md:266-290 (the W11 paragraph
> and arbiter, with the EV-1 notes; re-pinned 2026-11-02 at PR 54's landing)",
> and W-060's "fork/gap-analysis.md:262-283 (§W11 rewritten)" becomes
> "fork/gap-analysis.md:262-290 (§W11 rewritten; re-pinned 2026-11-02 at PR 54's
> landing, whose state C text and A.10 marks extended the section)", `json.load`
> passing; and Appendix C.5 gains, directly after the paragraph of item (2), the
> paragraph: "Ledger re-cites (added 2026-11-02, R54-3, the orchestrator's
> ruling under R29), by C.8's re-cite rule, measured on the records tree:
> W-062's evidence "fork/gap-analysis.md:93 (row 90, DONE on transcription plus
> document review; the header's three added lines moved it from :90)" becomes
> "fork/gap-analysis.md:91 (row 90, DONE on transcription plus document review;
> the header's three added lines moved it from :90, and LAND-1's header rewrites
> to :91, re-pinned 2026-11-02 at PR 54's landing)", its
> "fork/gap-analysis.md:264-281 (the W11 paragraph and arbiter, with the EV-1
> notes)" becomes "fork/gap-analysis.md:266-290 (the W11 paragraph and arbiter,
> with the EV-1 notes; re-pinned 2026-11-02 at PR 54's landing)", and W-060's
> "fork/gap-analysis.md:262-283 (§W11 rewritten)" becomes
> "fork/gap-analysis.md:262-290 (§W11 rewritten; re-pinned 2026-11-02 at PR 54's
> landing, whose state C text and A.10 marks extended the section)"."
>
> (7) At PR 55's landing (stage 5), on the implementer's stop at step 9: (1)
> Section 2.5's gap-row check names no row, yet three texts the plan itself
> prescribes rewrite words of the PR's row 77 ("Stdlib: String and
> string-literal types", fork/gap-analysis.md:78 at the stop, :79 after
> ruling (8)'s header clause): C.6's re-stamp commit ("W-057
> DISCHARGED 2026-10-13" to "W-057 DISCHARGED <date>"), C.6's W-148 commit (the
> id replaced by W-148's title) and C.6's floor-of-record re-read in the records
> edit ("floor of record 128/0/22 over 150, run 37402970811" to the 131/0/19
> text); the dry run did not simulate the two land-time commits rev 6 added, so
> the check reports the replaced words as missing (logs/step9-rowcheck.log: 3
> missing, all of row 77; on the merge d7a3c13bb, 0 missing), the same class as
> PR 54's stop, ruled there by paragraph (5); rowcheck.py's own rule ("Rows
> named as ROW_KEY arguments (a plan rewrites them, section 2) are reported but
> not failed") governs, and row 77 is named: (a) in section 2.5,
> "148/0/15 over 163. Gap-row check: no row named." becomes
> "148/0/15 over 163. Gap-row check: row 77 named (C.6's re-stamp commit, its
> W-148 commit and its floor-of-record re-read rewrite words of the PR's row;
> amended 2026-11-02, the implementer's stop at step 9, the orchestrator's
> ruling under R29)."; (b) the check is re-run in the landing worktree as
> `python3 -I $F/bin/rowcheck.py 732179150 c3cdecc5d WORKTREE "Stdlib: String
> and string-literal types"`, logged as logs/step9-rowcheck-ruled.log, and must
> print the row's three segments as "named in section 2" and `rowcheck: 0
> missing` with exit 0; the records edits themselves stand as written (the
> worktree's row 77 is the PR's row with C.6's three rewrites and A.10's mark,
> verified by the orchestrator word for word). (2) The class is closed for the
> later landings by a rule in D-LAND-6 step 9: after "with the rows section 2
> names, which must report 0 missing;" the text "the rows named being also, by
> rowcheck.py's own rule (a row a plan rewrites, section 2), every row that a
> land-time commit section 2 prescribes or a records text Appendix C gives
> rewrites, each listed in the implementer's report with the commit or text that
> rewrites it and verified by the review against the plan's text, a missing
> segment of any other row stopping the landing (amended 2026-11-02, the
> orchestrator's ruling under R29 at PR 55's stop, the second of the class after
> PR 54's paragraph (5));" is inserted.
>
> (8) At PR 55's landing (stage 5), on review round 1's RV55-1 and RV55-2: (1)
> RV55-1: GA-2 kept trunk's header in the merge and says the records commit
> writes the PR's header text as section 2 says, but section 2.5 names only the
> tally, so the header's landed list lacks ST-1's clause although row 77 is
> DONE; the PR's clause is written: in fork/gap-analysis.md's header paragraph,
> "and CMake build-system integration with Make documentation have since landed"
> becomes "and CMake build-system integration with Make documentation, and
> string comparison, the owning `Core.StringBuf` and concatenation have since
> landed" (the PR's words, c3cdecc5d fork/gap-analysis.md:31-32); in
> section 2.5, "records with the header `<tally>` (34/18/3/1 expected)" becomes
> "records with the header `<tally>` (34/18/3/1 expected) and the header's
> landed list gaining ST-1's clause by C.6 (added 2026-11-02, RV55-1, the
> orchestrator's ruling under R29)"; and Appendix C.6 gains, after its A.5
> sentence block and before "### C.7 PR 58's own texts", the paragraph: "Header
> clause (added 2026-11-02, RV55-1, the orchestrator's ruling under R29; GA-2's
> PR text for the header): in the gap header's paragraph, "and CMake
> build-system integration with Make documentation have since landed" becomes
> "and CMake build-system integration with Make documentation, and string
> comparison, the owning `Core.StringBuf` and concatenation have since landed",
> the PR's clause (c3cdecc5d fork/gap-analysis.md:31-32), written by the records
> commit; it moves every row down one line." (2) RV55-2: ST-1's item 5 asks that
> row 77's and row 41's lines be re-read at the rebase (c3cdecc5d
> fork/ORCHESTRATION.md:533-534); on the records tree row 77 is at
> fork/gap-analysis.md:79 and row 41 at :43, so the three ST-1 records that cite
> the branch's lines are re-pinned by C.8's re-cite rule: in
> fork/decision-log.md's ST-1 entry, "fork/gap-analysis.md row 77, now line 81,
> reads" becomes "fork/gap-analysis.md row 77, now line 79 (line 81 on the
> branch; re-read 2026-11-02 at PR 55's landing, LAND-1), reads"; in
> fork/inventory/work-items.json, W-057's evidence "(line 81 on this branch
> after the header edit)" becomes "(line 81 on this branch after the header
> edit; line 79 on trunk, re-read 2026-11-02 at PR 55's landing, LAND-1)" and
> W-167's evidence "line 45 on this branch)" becomes "line 45 on this branch,
> line 43 on trunk, re-read 2026-11-02 at PR 55's landing, LAND-1)", `json.load`
> passing; fork/string/plan.md:3113's "so row 77 is line 81 and row 41 line 45
> on this branch" stands as the landed notes' record of the branch; in
> section 2.5, "D-LAND-17; AUD-55-05)" becomes "D-LAND-17; AUD-55-05) and
> item 5's re-read of row 77's and row 41's lines (C.6's three re-pins to the
> records tree's :79 and :43; added 2026-11-02, RV55-2, the orchestrator's
> ruling under R29)"; in paragraph (7) of the section "## Landing-time rulings",
> "fork/gap-analysis.md:78)" becomes "fork/gap-analysis.md:78 at the stop, :79
> after ruling (8)'s header clause)"; and Appendix C.6 gains, directly after the
> paragraph of item (1), the paragraph: "Line re-pins (added 2026-11-02, RV55-2,
> the orchestrator's ruling under R29), by C.8's re-cite rule, row 77 at :79 and
> row 41 at :43 on the records tree: in the ST-1 decision-log entry,
> "fork/gap-analysis.md row 77, now line 81, reads" becomes
> "fork/gap-analysis.md row 77, now line 79 (line 81 on the branch;
> re-read 2026-11-02 at PR 55's landing, LAND-1), reads"; W-057's evidence
> "(line 81 on this branch after the header edit)" becomes "(line 81 on this
> branch after the header edit; line 79 on trunk, re-read 2026-11-02 at PR 55's
> landing, LAND-1)"; W-167's evidence "line 45 on this branch)" becomes "line 45
> on this branch, line 43 on trunk, re-read 2026-11-02 at PR 55's landing,
> LAND-1)"."
>
> (9) Before PR 58's review (stage 6), on PR 55's fold check FC55-1 and FC55-2:
> (1) FC55-1, the class closed: a fork/gap-analysis.md line cite in
> fork/inventory/work-items.json or fork/decision-log.md names the tree of the
> date it carries (its entry's date or its mark's), the rows being named by
> their bullet text (R7); a later landing whose merge, land-time commits or
> records edits move the lines does not re-pin it; a landing re-pins only the
> cites its own texts write or that its own section names, measured on its
> records tree; so PR 52's and PR 54's cites (W-060's :88 and :262-290, W-061's
> :85, W-062's :91 and :266-290, CM-1's "now line 88" and "now line 85"), moved
> one line by PR 55's header clause and four by its W9 hunk, stand with their
> dates: in D-LAND-9 (its break condition's last sentence, not paragraph (1)'s
> quotation of it), after "fold check FC1-1 at PR 67, the orchestrator's ruling
> under R29)." the sentence: "A fork/gap-analysis.md line cite in the ledger or
> the decision log names the tree of the date it carries (its entry's or its
> mark's), the rows being named by their bullet text (R7); a later landing that
> moves the lines does not re-pin it, and a landing re-pins only the cites its
> own texts write or its own section names, measured on its records tree
> (amended 2026-11-02, fold check FC55-1 at PR 55, the orchestrator's ruling
> under R29)." (2) FC55-2: the ST-1 decision-log entry, re-stamped 2026-11-02 by
> PR 55's landing, carries in its D-ST-16 paragraph the branch-era cite
> "(gap-analysis.md:241-244)" for section W9's Arbiter paragraph, which PR 55's
> landing did not re-pin because the plan gave no text; it is re-pinned here,
> measured on PR 58's records tree after this landing's edits of
> fork/gap-analysis.md (the folder measures section W9's Arbiter paragraph, from
> its "**Arbiter:** A core/ test suite" line to its "round-tripping with C++."
> line, with `grep -n`; expected :246-249, the lines on PR 55's records tree, if
> this landing moves nothing above them; the measured values govern, are written
> in the two texts below and in paragraph (9), and are reported): in
> fork/decision-log.md's ST-1 entry, "(gap-analysis.md:241-244)" becomes
> "(gap-analysis.md:246-249, re-pinned 2026-11-02 at PR 58's landing, LAND-1;
> :241-244 on ST-1's branch)"; fork/string/plan.md:729's same cite stands as the
> plan's record of the branch; and Appendix C.7 gains, before "### C.8 PR 61's
> own texts", the paragraph: "Re-pin (added 2026-11-02, FC55-2 at PR 55, the
> orchestrator's ruling under R29): in the ST-1 decision-log entry's D-ST-16
> paragraph, "(gap-analysis.md:241-244)" becomes "(gap-analysis.md:246-249,
> re-pinned 2026-11-02 at PR 58's landing, LAND-1; :241-244 on ST-1's branch)",
> the lines of section W9's Arbiter paragraph measured on this landing's records
> tree."
>
> (10) At PR 58's landing (stage 6), on the implementer's stop at step 6,
> the --self-test join: (1) in fork/designdocs/check_samples.py, "def main() ->
> int:" becomes "def main(argv: list[str] | None = None) -> int:" and "args =
> parser.parse_args()" becomes "args = parser.parse_args(argv)" (standalone
> use is unchanged: `argv=None` parses `sys.argv[1:]`; `--self-check` and
> `--toolchain` unchanged; the `if __name__ == "__main__": sys.exit(main())`
> lines unchanged); (2) in fork/conformance/runner.py,
> `designdocs_samples_self_check()` is EV-1's hook with
> fork/designdocs/check_samples.py for the path,
> `designdocs-samples self-check` for the label, a docstring naming DD-1's
> checker and fork/designdocs/plan.md D-DD-6, and `module.main([])` for the
> call (the empty argv: the toolchain-free checks, as D-DD-6 says), placed
> directly after `evaluator_samples_self_check()`, called right after it under
> the same `not filter_substr` condition and failing `self_test` the same way,
> with a comment of the same form as EV-1's; (3) the join commit's message
> states the stop and the fix in these words: "Written as the same code as
> EV-1's hook, the join exited 2: DD-1's main() parsed the runner's own
> sys.argv ('unrecognized arguments: --self-test'). DD-1's main() gains the
> argv parameter an in-process caller needs (def main(argv: list[str] | None =
> None) -> int, parser.parse_args(argv); standalone use unchanged) and the
> hook calls module.main([]) (the orchestrator's ruling under R29, 2026-11-02,
> at the implementer's stop at step 6)", and records the measured
> `--self-test` output after the join ("designdocs-samples self-check: OK"
> right after "evaluator-samples self-check: OK", then "self-test: 182
> programs parsed, 56 bullets in table, OK", exit 0, with the wall time), the
> standalone checker's line (`python3 -I fork/designdocs/check_samples.py`,
> "... 0 errors") and its `--self-check` and `--toolchain` runs with the
> landing's install (both exit 0), and C.7's R-8 re-pins against the runner
> the commit leaves, as C.7 says; (4) the plan: in Appendix C.7, "a function
> `designdocs_samples_self_check()` that is the same code with
> fork/designdocs/check_samples.py for EV-1's path and
> `designdocs-samples self-check` for its label, called right after it,"
> becomes "a function `designdocs_samples_self_check()` that is the same code
> with fork/designdocs/check_samples.py for EV-1's path,
> `designdocs-samples self-check` for its label and `module.main([])` for its
> call, DD-1's `main()` gaining in the same commit the `argv` parameter an
> in-process caller needs (`def main(argv: list[str] | None = None) -> int:`,
> `parser.parse_args(argv)`; standalone use unchanged), because written as the
> same code the hook exits 2 under `runner.py --self-test`, argparse reading
> the runner's `sys.argv` (amended 2026-11-02, the implementer's stop at
> step 6, the orchestrator's ruling under R29), called right after it,"; and the
> section "## Landing-time rulings" gains, inside its blockquote after
> paragraph (8), a paragraph "(10)" holding this ruling's items (1) to (4)
> verbatim, introduced by "At PR 58's landing (stage 6), on the implementer's
> stop at step 6, the --self-test join:" (paragraph (9), this stage's
> pre-review ruling, is inserted between (8) and (10) by its ruling folder
> after this implementer); these plan edits are made with the records edits at
> step 9, fork/land/land1-plan.md among the records files.
>
> (11) At PR 61's landing (stage 7), on the implementer's stop at step 6, the id
> re-scan before L: (1) in D-LAND-21, "one that contains the PR's head or that
> the head contains (either way by `git merge-base --is-ancestor`: its branch, a
> lagging local copy, a stacked child's branch, the landing's trunk)" becomes
> "one that contains the PR's head or that the head contains, or that descends
> from a commit the head contains which already files those ids and is an
> ancestor of a ref that contains the head (each by
> `git merge-base --is-ancestor`: its branch, a lagging local copy, a stacked
> child's branch or that child's lagging copy, the landing's trunk;
> amended 2026-11-02, the implementer's stop at PR 61's re-scan before L, where
> CT-1's lagging local copy 4a3220c11, a descendant of 5661a35c8 and an ancestor
> of 551a03328, filed TP-1's ids; the orchestrator's ruling under R29)"; (2) the
> re-scan before L is re-run with the same commands under the widened test
> (bin/tp1_rescan.sh, its collision test extended to the third case: a ref off
> both directions is a stacked child's lagging copy when some commit the head
> contains that files the ids is its ancestor and some ref that contains the
> head is its descendant), logged as logs/step6-rescan-beforeL-ruled.log, and
> must report the three places as a stacked child's lagging copy,
> naming 5661a35c8 and 551a03328, with no collision; its `<rescan>` outcome
> names them so; the second re-scan, before the records commit's ledger edit,
> runs under the same test.
>
> (12) At PR 61's landing (stage 7), on review round 1's MINOR findings RV61A-1,
> RV61A-2, RB61-1, RB61-2 and RB61-3: (1) RV61A-1. TP-1's §2.8 full-row block
> (66aa13132 fork/templates/plan.md:4993) never took two clauses that its
> held-state sentence gained later (66aa13132 fork/gap-analysis.md:54), so the
> land-time row says less than TP-1 delivers; the row carries both clauses,
> verbatim from the held-state sentence but for the closing parenthetical. (1a)
> In the records edit of fork/gap-analysis.md (row 54, "Generics: Integrated
> templates"), the TP-1 sentence's text "(proposal 2200; W-183, discharged), and
> `var y: T;` resolves its default on instantiation (W-127, discharged); status
> unchanged." becomes "(proposal 2200; W-183, discharged), a class template's
> literal whose field has a template-dependent array bound or a produced type
> such as `T.Item` converts on instantiation, taking the defaults of the fields
> it omits, and `var y: T;` resolves its default on instantiation (W-127,
> discharged), and a `match`, a pattern condition or `let` ... `else` on a
> template-dependent choice value (a generic choice applied to a template
> parameter, or a choice declared in a class template) or on `Core.Int(N)` for a
> template `N` is checked in the definition and runs (round 10 of the focused
> re-review of the fold; this clause and the class template literal's are the
> held-state sentence's, carried into the land-time sentence at LAND-1's
> landing, 2026-11-02, fork/land/land1-plan.md ruling (12)); status unchanged."
> (1b) In fork/land/land1-plan.md, Appendix C.8, directly before the paragraph
> that begins "PR 61's A.5 Landed paragraph and A.6 sentence then end with this
> sentence", a new paragraph: "R's TP-1 sentence (section 2.8's full-row
> block, 66aa13132 fork/templates/plan.md:4993) carries two clauses of the
> held-state sentence (66aa13132 fork/gap-analysis.md:54) that the full-row
> block never took (added 2026-11-02, PR 61's landing, review round 1: RV61A-1;
> ruling (12)): after "(proposal 2200; W-183, discharged)," the clause "a class
> template's literal whose field has a template-dependent array bound or a
> produced type such as `T.Item` converts on instantiation, taking the defaults
> of the fields it omits," and, before "; status unchanged", the clause ", and a
> `match`, a pattern condition or `let` ... `else` on a template-dependent
> choice value (a generic choice applied to a template parameter, or a choice
> declared in a class template) or on `Core.Int(N)` for a template `N` is
> checked in the definition and runs (round 10 of the focused re-review of the
> fold; this clause and the class template literal's are the held-state
> sentence's, carried into the land-time sentence at LAND-1's
> landing, 2026-11-02, fork/land/land1-plan.md ruling (12))"." (1c) In
> fork/templates/plan.md, §2.8, directly after the paragraph that ends "a
> generic; and W-271 at the end of the residue.", a new paragraph: "At the
> landing (amended 2026-11-02, LAND-1, PR 61's landing, review round 1:
> RV61A-1), the full-row block's TP-1 sentence carries the two clauses the
> held-state sentence gained after the block was written and the block never
> took, a class template's literal whose field has a template-dependent array
> bound or a produced type such as `T.Item` converting on instantiation, taking
> the defaults of the fields it omits, and a `match`, a pattern condition or
> `let` ... `else` on a template-dependent choice value or on `Core.Int(N)` for
> a template `N` checked in the definition and running, verbatim from the
> held-state sentence, by the orchestrator's ruling under R29
> (fork/land/land1-plan.md, Landing-time rulings, paragraph (12))." (2) RV61A-2
> and RB61-1's first part. A.10's operative rule is step 9's search of the added
> text; its list of targets is a measurement on the dry run's merge, which did
> not simulate D. At PR 61, section 2.7 item 13's D replaces W-014's notes by
> Appendix E's land-time text before the search, which then finds no label, so
> no mark is written, and TP-1's item (h) is made by that replacement. (2a) In
> fork/land/land1-plan.md, A.10, "at PR 61 W-014's notes;" becomes "at PR 61
> W-014's notes, which take no mark (amended 2026-11-02, PR 61's landing, review
> round 1: RV61A-2, RB61-1; ruling (12)): section 2.7 item 13's D replaces them
> by Appendix E's land-time text before step 9's search, which then finds no
> label (`git diff d13f47ea7 -- fork/inventory/work-items.json
> fork/gap-analysis.md | grep '^+' | grep -ciE 'not\s+of\s+record'` gives 0 on
> the records tree), and TP-1's item (h) is made by that replacement;". (2b) In
> fork/land/land1-plan.md, section 2.7, "is A.10's mark at this landing, R33 (b)
> making the container scoreboard R9's record now (AUD-61-T28);" becomes "is
> A.10's mark at this landing, which section 2.7 item 13's D makes by replacing
> the notes, so that the search finds no label and no mark is written
> (amended 2026-11-02, review round 1: RV61A-2, RB61-1; ruling (12)), R33 (b)
> making the container scoreboard R9's record now (AUD-61-T28);". (2c) The
> records commit's message states that A.10's PR 61 entry takes no mark, for
> this reason, and quotes the zero-count command above with its output. (3)
> RB61-1's second part. The merge brings TP-1's paragraph "Expected at TP-1, NOT
> of record: 138 PASS / 22 SKIP / 0 FAIL over 160, 48/56 bullets ..." into
> fork/ORCHESTRATION.md's Scoreboard section, under A.9's paragraph, and neither
> A.9 nor A.10 covers it; it takes A.10's prose mark. (3a) In the records edit
> of fork/ORCHESTRATION.md, directly after that paragraph's first sentence,
> which ends "(the hosted conformance run 37402970811 on 606a99c5a).", the text
> " (LAND-1, 2026-11-02: the "not of record" label above is superseded by
> PR 61's landing's container-measured scoreboard, R33 (b), 177/0/15 over 192
> with 49/56 bullets.)" is inserted, so that the paragraph continues "...
> on 606a99c5a). (LAND-1, 2026-11-02: the "not of record" label above is
> superseded by PR 61's landing's container-measured scoreboard, R33
> (b), 177/0/15 over 192 with 49/56 bullets.) TP-1 is measured on trunk alone;
> ...". (3b) In fork/land/land1-plan.md, A.10, "into a ledger item's `notes` or
> a prose section of fork/gap-analysis.md, found by `git diff <trunk before>
> HEAD -- fork/inventory/work-items.json fork/gap-analysis.md` and a search of
> the added text" becomes "into a ledger item's `notes`, a prose section of
> fork/gap-analysis.md or fork/ORCHESTRATION.md's Scoreboard section
> (amended 2026-11-02, PR 61's landing, review round 1: RB61-1; ruling (12):
> TP-1's "Expected at TP-1, NOT of record" paragraph, which the merge places
> under the Scoreboard heading below A.9's paragraph, takes the mark after its
> first sentence), found by `git diff <trunk before> HEAD --
> fork/inventory/work-items.json fork/gap-analysis.md fork/ORCHESTRATION.md` and
> a search of the added text". (4) RB61-2. L's text for templates.md's W-259
> limit is TP-1's Appendix C verbatim, which predates D-LAND-22, so the page and
> C.8's W-259 note disagree (R27); TP-1 §2.9 makes a fold of L's document review
> a fix commit of L that re-runs the checker. (4a) A fold commit of L, made
> before this ruling's records edits: in docs/design/templates.md, the W-259
> bullet's text "is accepted (fork work item W-259; pinned as `todo_fail` by
> `generic/template/operator.carbon`)." gains, after it, the sentence " A value
> left operand is not checked either and stops lowering: in `fn G[template T:
> type](v: T) { v[0] = 5; }`, and with `v[i] = 5` for `i: i64`, called with a
> class that implements only `Core.IndexWith(i64)`, the assignment is accepted
> and the compiler stops at lower.cpp:48 ("Store operand must be a pointer")
> (LAND-1, 2026-11-02, measured on PR 61's landing's
> install, 0.0.0-0.dev+3f229ecdf; fork/land/land1-plan.md D-LAND-22; W-259).";
> the bullet is then prek'd (rumdl's reflow stands),
> fork/designdocs/check_samples.py is run in both modes (0 errors each; any
> error is STOPPED), r31.py counts templates.md's bullets before and after (31
> and 31), and the commit, touching docs/design/templates.md only, is titled
> "Land PR 61: templates.md states W-259's lowering stop, review fold", with the
> landing's author, committer and trailers, its message naming TP-1 §2.9 ("a
> fold of that review is a fix commit of L and re-runs the checker"), RB61-2,
> both checker outputs, the R31 counts, prek's fixpoint, and that no code,
> golden, program or prelude file changed, so the install 0.0.0-0.dev+3f229ecdf,
> the gate and the conformance values stand and D-LAND-18 is unchanged. (4b) In
> the records edits, each text reading "land-time commits 2288e99f6, 3f229ecdf"
> (two: fork/ORCHESTRATION.md's A.3 row and fork/templates/plan.md's A.5
> paragraph) becomes "land-time commits 2288e99f6, 3f229ecdf, <fold>"
> with <fold> the fold commit's 9-character sha, the field being `git
> log --reverse --format=%h 35fb2aca9..HEAD`; the sentences reading "trunk
> at 3f229ecdf" stand, the re-scans having run on that tree. (4c) The fold
> commit is reviewed again (D-LAND-10) by review round 2. (5) RB61-3. OR-3's
> words and the dry run's placement disagree; the dry run's placement is the
> rule. In fork/land/land1-plan.md, OR-3's "OR-3: dated paragraphs inserted on
> both sides are both kept, in date order, the PR's first on the same date (it
> predates trunk's stamp of it)." becomes "OR-3: dated paragraphs inserted on
> both sides are both kept, in date order, the PR's first on the same date (it
> predates trunk's stamp of it); each side's inserted block of dated paragraphs
> is kept whole and placed by its first paragraph's date, the PR's block first
> on the same date, as the dry run's merges place them (amended 2026-11-02,
> PR 61's landing, review round 1: RB61-3; ruling (12): PR 61's block, first
> dated 2026-10-14, precedes trunk's paragraphs of 2026-10-15 to 2026-10-21, and
> PR 64's and PR 65's blocks are placed the same way)." No change to the tree's
> fork/ORCHESTRATION.md for this item. Cite corrected on the ruling folder's
> check (R10, 2026-11-02): the ruling's ":4995", taken from RV61A-1's citation,
> is ":4993", the line of the full-row block's row, in items (1) and (1b) above
> and in C.8's paragraph; the folder had applied items (1) to (6) and made the
> fold commit a11a5ea2f before it stopped on the cite.
>
> (13) At PR 61's landing (stage 7), on review round 2's MINOR findings RB61R2-1
> (review B), RV61A2-1 and RV61A2-2 (review A): (1) RB61R2-1. TP-1's records
> list L's departures from its Appendix C (the F6 sentence of C.8) without the
> fold commit a11a5ea2f's added W-259 sentence, and the landed notes' item (e)
> (66aa13132 fork/templates/plan.md:7919-7936) asks for the checker runs on L's
> fold commits too. (1a) PR 61's A.5 Landed paragraph (fork/templates/plan.md)
> and A.6 sentence (fork/decision-log.md) each gain, as their last sentence,
> this text, verbatim: "L's document-review fold a11a5ea2f (review round 1's
> finding RB61-2; TP-1's section 2.9, which makes a fold of that review a fix
> commit of L; fork/land/land1-plan.md, Landing-time rulings, paragraph (12),
> item (4a)) adds to templates.md's W-259 bullet the sentence C.8's W-259 note
> states, which TP-1's Appendix C predates (D-LAND-22), so the landed page
> differs from Appendix C there as well as where the sentence on L above says;
> check_samples.py, with and without --toolchain, reported on it the two outputs
> quoted above." In fork/templates/plan.md it follows A.5's last sentence,
> DR-1's note, which ends "trunk rejected the literal form only because it
> rejected every literal subscript of such a type in a template, the read
> included.", separated by one space; in fork/decision-log.md it follows A.6's
> last sentence, which ends "W-299 and F-019 at both: none (F-019 named only as
> plan text).", separated by one space. (1b) In fork/land/land1-plan.md,
> Appendix C.8, directly after the fenced text block that follows the paragraph
> beginning "PR 61's and PR 64's A.5 Landed paragraphs end with DR-1's note"
> (the block ending "the read included."), a new paragraph and fenced text
> block: the paragraph "PR 61's A.5 Landed paragraph and A.6 sentence then end
> with this sentence (added 2026-11-02, review round 2: RB61R2-1; ruling (13)),
> the landed notes' item (e) (66aa13132 fork/templates/plan.md:7919-7936) asking
> for the checker runs on L's fold commits too:" and, in a ```text block, item
> (1a)'s sentence verbatim. (2) RV61A2-1. C.8's re-cite list was measured on
> TP-1's branch, so two present-tense cites into toolchain/lower/handle.cpp, a
> file TP-1 changes, state the lines of the tree before the landing: the merged
> row 54's DD-1 cite "toolchain/lower/handle.cpp:494-505 lowers SpliceInst
> within a file", whose code (the SpliceInst handler from its head through its
> same-file branch) is at :500-516 on the landing's tree, and W-014's `evidence`
> cite "toolchain/lower/handle.cpp:513", whose `CARBON_FATAL` is at :524. (2a)
> In the records edit of fork/inventory/work-items.json, W-014's `evidence`
> entry "toolchain/lower/handle.cpp:513 (`CARBON_FATAL("Cross-file template
> lowering not implemented yet")`, the one template fatal left after upstream
> PR 7727; was :359-364 `Template lowering not implemented yet` at the cut)"
> reads ":524" for ":513", its path and words kept (C.8's re-cite rule). (2b) In
> the records edit of fork/gap-analysis.md, row 54, directly after DD-1's
> parenthetical ending "which no longer occurs under toolchain/)." and before "
> templates.md no longer self-describes as a placeholder", the marker "
> (TP-1, 2026-11-02: the same-file SpliceInst lowering cited above as
> toolchain/lower/handle.cpp:494-505 is toolchain/lower/handle.cpp:500-516 on
> this tree.)" is inserted, in R's marker's form, a row's text being kept
> verbatim. (2c) In fork/land/land1-plan.md, Appendix C.8, the re-cite
> paragraph's last sentence "A cite whose code is not found on that tree stops
> the landing (D-LAND-9's break condition), and evidence in a file TP-1 does not
> change keeps its lines, as the landed notes say." gains, after it, this
> sentence: "The rule extends (added 2026-11-02, review round 2: RV61A2-1;
> ruling (13)) to every other present-tense cite in W-014's `evidence` and in
> the merged row 54 that points into a file the landing changes outside testdata
> (`git diff --name-only d13f47ea7 HEAD -- toolchain core ':!*/testdata/*'`):
> W-014's evidence cite toolchain/lower/handle.cpp:513 is :524 on the landing's
> tree; the merged row's DD-1 cite toolchain/lower/handle.cpp:494-505, a row's
> text being kept verbatim, takes a marker in R's marker's form after DD-1's
> parenthetical, "(TP-1, 2026-11-02: the same-file SpliceInst lowering cited
> above as toolchain/lower/handle.cpp:494-505 is
> toolchain/lower/handle.cpp:500-516 on this tree.)"; a dated measurement
> records the tree it names and stays as measured: W-014's evidence cites
> import_ref.cpp:5087 with the nightly's :4875, lower/aggregate.cpp:67,
> inst.h:249 and function_context.cpp:223 (DD-1's probes of 2026-10-13
> and 2026-10-14) and the UA-2 entry of 2026-10-06 in W-014's `notes`, re-cited
> to upstream c1e83b0b7, with lower/handle.cpp:513." Row 54's other cites
> (lower/handle.cpp:513 marked by R's marker, lower/handle.cpp:524,
> pattern_match.cpp:2174-2180 in a file TP-1 does not change) and W-014's
> evidence cites into files TP-1 does not change (return.cpp,
> handle_binding_pattern.cpp, pattern_match.cpp, the testdata splits) are
> unchanged. (3) RV61A2-2. L's commit message (2288e99f6) reports the checker's
> install as 0.0.0-0.dev+35fb2aca9 while logs/step6-L-install.log prints "Carbon
> Language toolchain version: 0.0.0-0.dev+35fb2aca9.dirty", the install built
> while L's edits were uncommitted; L changes no toolchain file, so that build's
> toolchain sources are 35fb2aca9's and the checker's two summary lines in the
> records are exact. The message stands (a submitted commit's history is never
> rewritten) and the records commit's message states, verbatim: "L's message
> reports the checker's install as 0.0.0-0.dev+35fb2aca9;
> logs/step6-L-install.log prints "Carbon Language toolchain
> version: 0.0.0-0.dev+35fb2aca9.dirty", the install built while L's edits were
> uncommitted; L changes no toolchain file, so that build's toolchain sources
> are 35fb2aca9's (RV61A2-2; fork/land/land1-plan.md, Landing-time rulings,
> paragraph (13))." No tree edit.
>
> (14) At PR 62's landing (stage 8), before its review, on the fold check of
> PR 61's review round 2 (FC61-2-1): (1) In fork/land/land1-plan.md, Appendix
> C.8, the sentence "The note's last sentence is amended 2026-11-01 (review
> fold: RR4-1)." becomes "DR-1's note's last sentence is amended 2026-11-01
> (review fold: RR4-1; the antecedent named 2026-11-02, the fold check of
> PR 61's review round 2: FC61-2-1, ruling (14))."; no other word changes.
>
> (15) At PR 64's landing (stage 9), on the implementer's stop at step 9, C.2's
> undefined slots and placeholders: (1) The slots. C.2's sentence "Measured in
> the container (EXPECTED, not of record, R9): <gate N of N>, conformance
> <P / F / S over N>." is written with the landing's final gate and conformance
> in the slots' own forms, stage 9's step 8 values on the install of 940b67215:
> "Measured in the container (EXPECTED, not of record, R9): 1978 of 1978,
> conformance 189 / 0 / 15 over 204." In fork/land/land1-plan.md, the
> conventions paragraph's "TP-1's `<merged ...>` values to the landing's
> measurements (C.8), and DR-1's three `<sha>` slots" becomes "TP-1's
> `<merged ...>` values to the landing's measurements (C.8), CT-1's
> `<gate N of N>` and `<P / F / S over N>` to the landing's final gate and
> conformance in the slots' own forms (C.10; amended 2026-11-02, PR 64's
> landing, the implementer's stop at step 9: ruling (15)), and DR-1's three
> `<sha>` slots". (2) The placeholders. C.2's
> "<the original seven entries, kept, then DD-1's at land time>" stands for the
> merged tree's W-043 `evidence` entries, verbatim and in their order (seven on
> this tree: PR 51's six rewritten entries and DD-1's X09 entry), with C.2's six
> entries following them; C.2's
> "<the original notes, kept, then DD-1's at land time>" stands for the merged
> tree's W-043 `notes` verbatim (DD-1's sentence and C.7's LAND-1 note
> included), whose final period is the template's, so that C.2's text follows
> after one space from "DISCHARGED at CT-1 (2026-11-02,
> fork/cpp-templates/plan.md):"; C.2's title replaces the entry's title,
> with 2026-11-02 for `<YYYY-MM-DD>`; the branch's held-state sentence of
> W-043's notes ("Held state (2026-10-21): PR 51 to PR 62 are held, so this
> branch's entry keeps the original seven evidence entries and notes, and the
> land-time records commit reapplies this text over the entry that M takes whole
> from DD-1 (PR 58), DD-1's evidence after the original seven and DD-1's notes
> after the original notes (fork/cpp-templates/plan.md Appendix C.2, §2.11).")
> is not carried, this records commit being the event it announces, and the
> branch's round sentence ("Focused re-review, round 1 (2026-10-22): two reviews
> of the fold and these records at 118fc1bc8 both returned APPROVE-WITH-FIXES
> with no BLOCKER or MAJOR and twelve MINOR records findings, all folded and
> none rejected, with no fix commit and no residue filed, so the round is dry
> and the loop ends (fork/cpp-templates/plan.md, 'Focused re-review of the fold,
> round 1 (2026-10-22)').") is kept after C.2's text, separated by one space, as
> C.2's intro says (551a03328 fork/cpp-templates/plan.md:6771-6774). In
> fork/land/land1-plan.md, Appendix C.10, directly after "C.10 (W-127), with
> `<YYYY-MM-DD>` the landing date." this sentence is added: "C.2's
> `<the original seven entries, kept, then DD-1's at land time>` stands for the
> merged tree's W-043 `evidence` entries, verbatim and in their order (seven on
> this tree: PR 51's six rewritten entries and DD-1's X09 entry, PR 51 having
> rewritten the original seven before PR 58 landed), C.2's six entries following
> them; its `<the original notes, kept, then DD-1's at land time>` stands for
> the merged tree's W-043 `notes` verbatim (DD-1's sentence and C.7's LAND-1
> note included), whose final period is the template's, C.2's text following
> after one space from "DISCHARGED at CT-1"; the branch's held-state sentence
> ("Held state (2026-10-21): ...") is not carried, this records commit being the
> event it announces, and the branch's round sentence ("Focused re-review,
> round 1 (2026-10-22): ...") is kept after C.2's text, as C.2's intro says;
> C.2's `<gate N of N>` and `<P / F / S over N>` are the landing's final gate
> and conformance in the slots' own forms, "1978 of 1978" and "189 / 0 / 15
> over 204" at this landing (added 2026-11-02, PR 64's landing, the
> implementer's stop at step 9: ruling (15))." (3) A.10. C.2's sentence brings
> the label "EXPECTED, not of record" into W-043's `notes`, so step 9's search
> finds it and the mark is written, appended to the notes with a leading space
> in A.10's form: " (LAND-1, 2026-11-02: the "not of record" label above is
> superseded by PR 64's landing's container-measured scoreboard, R33
> (b), 189/0/15 over 204 with 49/56 bullets.)". In fork/land/land1-plan.md,
> A.10, "none at PR 67, 51, 64, 63 and 68, and trunk's own W-321 label is not a
> landing's." becomes "none at PR 67, 51, 63 and 68, and at PR 64 W-043's notes,
> where C.2's "Measured in the container (EXPECTED, not of record, R9)" sentence
> brings the label, found by step 9's search (amended 2026-11-02, PR 64's
> landing, the implementer's stop at step 9: ruling (15)), and trunk's own W-321
> label is not a landing's."
>
> (16) At PR 64's landing (stage 9), on review round 1's MINOR finding RV64-1:
> (1) In fork/land/land1-plan.md, A.10 (the list itself, not paragraph (15)'s
> quotation of it), the text "found by step 9's search (amended 2026-11-02,
> PR 64's landing, the implementer's stop at step 9: ruling (15)), and trunk's
> own W-321 label is not a landing's." becomes "found by step 9's search
> (amended 2026-11-02, PR 64's landing, the implementer's stop at step 9:
> ruling (15)), and CT-1's "Expected at CT-1, NOT of record" paragraph, which
> the merge places in fork/ORCHESTRATION.md's Scoreboard section and which
> takes the prose mark after its first sentence, the one ending "both rows
> PARTIAL." (A.10's prose rule as ruling (12) item (3b) widened it; the heads
> of PR 63, PR 65 and PR 68 bring no such label; amended 2026-11-02, PR 64's
> landing, review round 1: RV64-1, ruling (16)), and trunk's own W-321 label
> is not a landing's." No other file changes: the mark itself stands as
> written. (2) The records commit's message names both A.10 marks of this
> landing, W-043's notes (ruling (15)) and CT-1's Scoreboard paragraph (A.10's
> prose rule as ruling (12) item (3b) widened it).

<!-- google-doc-style-resume -->
