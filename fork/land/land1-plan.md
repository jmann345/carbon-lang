<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# LAND-1 plan: landing the held PRs into trunk under R33

**Status:** rev 3 -- NOT signed off: RR1-1 (BLOCKER) and RR1-2 (MAJOR), the
focused re-review's N1 and N2, folded here with its four MINORs, RR1-3 to
RR1-6 (see the focused re-review fold record at the end); the next re-review
decides. Rev 2 (2026-11-01) folded reviews A and B of rev 1, 25 findings, none
rejected (the review fold record); rev 1 was the planner's draft of the same
day. Records only: this plan changes no toolchain, prelude, golden, program or
workflow file. It
carries out fork/rulebook.md R33 and decision-log entry LD-0 (the owner,
2026-11-01: "Go ahead and merge changes that are correct"), scheduled by
fork/ORCHESTRATION.md's Next actions lead (trunk bb9fbba9c :1171-1175) and its
paragraph dated 2026-11-01 (17:42 UTC) (:745-760).

**Summary.** Eighteen PRs are held open, PR 51 to PR 68; none is merged, and
every pushed head equals the head the task names (section 0.1). Twelve are
correct now and land in the recorded relative order: PR 67, 51, 52, 54, 55,
58, 61, 62, 64, 63, 65 and 68 (D-LAND-1). Six wait behind named gates: PR 53
(SAFE-3), PR 60 (W-139), PR 56 and PR 57 (W-352), and, a finding of this
audit, PR 59 and its stacked PR 66, because trunk's Next actions item 13 owes
PR 59 a crash fix (a pack in a choice alternative's parameter list aborts in
lowering where trunk rejects it at parse) and VA-2's hand-off note 7 owes it a
ruling on a second abort (D-LAND-2). A sequential dry run of the twelve merges
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
-   Section 1: decisions D-LAND-1 to D-LAND-19
-   Section 2: spec, one subsection per landing in land order
-   Section 3: the process, the actors and the follow-ons
-   Section 4: the scoreboard progression and its stop values
-   Section 5: risks and rejected alternatives
-   Section 6: verification and what is not run
-   Hand-off notes
-   Appendix A: the per-landing record templates
-   Appendix B: the ORCHESTRATION stamps
-   Appendix C: each landing's fields, targets and own texts
-   Review fold record (rev 2, 2026-11-01)
-   Focused re-review fold record (rev 3, 2026-11-01)

Conventions. `trunk` is origin/trunk bb9fbba9c unless a section says otherwise.
A file:line cite names the sha it was read at. `$P` is the planner's scratch
directory
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/planner,
`$F` the rev-2 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer,
`$F1` the rev-3 fixer's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/fixer1,
`$CB` the arbiter's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild,
and `$X` the expected trees, `$F/expected` (rev 1's `$P/expected` is superseded
from PR 58 on, section 0.5; amended 2026-11-01, review fold: A-B1 / A-M4). The
placeholders are exactly those of the table below; each is measured as its row
says, and no other placeholder appears in a text this plan gives. No placeholder
survives into a commit (amended 2026-11-01, review fold: B-M5 / B-m6).

| Placeholder | Value | Measured by |
| --- | --- | --- |
| `<date>`, `<hh:mm>` | the commit's UTC date and time | `date -u +%F` and `date -u +%H:%M` when the commit is made |
| `<prev>` | the date in the current ORCHESTRATION header's first clause | that clause, read before the records edit |
| `<trunk before>` | origin/trunk before the landing | `git rev-parse --short=9 origin/trunk` at step 1 |
| `<head>` | the PR's pushed head | `git ls-remote origin` at step 1 (section 0.1's value) |
| `<base>` | the PR's base branch, which is `trunk` at every landing (PR 64 and PR 65 after their retargets) | `pull_request_read`'s `base` at step 1 (added 2026-11-01, review fold: RR1-6) |
| `<merge sha>` | the landing's merge commit | `git rev-parse --short=9 HEAD` after step 5 |
| `<land-time shas>` | the commits after the merge, oldest first, comma-separated, or `none` | `git log --reverse --format=%h <merge sha>..HEAD` before the records commit |
| `<conflicts>` | each conflicted file as `<path> (<regions>, <rule>)`, in `git diff --name-only --diff-filter=U` order, a file or region not in `$X` marked `not in the dry run` | step 3 |
| `<refilled>` | each refilled golden as `<path> (<PRs whose changes combine>)` | step 7 |
| `<g0>`, `<gn>` | the merge's gate at step 4, before any refill: tests passed and tests run | step 4's `gate.log`: `[  PASSED  ] <g0> tests` and `[==========] <gn> tests from 1 test suite ran` (added 2026-11-01, review fold: RR1-6) |
| `<g>` | the landing's final gate (after step 7's refill, or step 4's when nothing is refilled): tests passed, which equals tests run | that gate's `gate.log`, `[  PASSED  ] <g> tests` |
| `<p>`, `<f>`, `<s>`, `<n>` | conformance PASS, FAIL (the five failure kinds summed), SKIP and programs | the landing's `scoreboard.json` `totals` |
| `<b>` | bullets PASS of 56 | the landing's `scoreboard.json` `bullets` |
| `<tally>` | the gap tally as DONE/PARTIAL/MISSING/DESIGN-ONLY | `python3 -I $F/bin/gaptally.py fork/gap-analysis.md` after the records edits |
| `<t1>`, `<t2>`, `<t3>`, `<t4>` | `<tally>`'s four numbers, DONE, PARTIAL, MISSING and DESIGN-ONLY | as `<tally>` (added 2026-11-01, review fold: RR1-5) |
| `<tip>` | upstream trunk's head | `git fetch upstream` then `git ls-remote upstream refs/heads/trunk`, 9 characters, at the check |
| `<q>`, `<qf>`, `<c>`, `<cf>` | quotes checked and failed, silence checks checked and failed | check_quotes.sh and check_greps.sh output at `<tip>` (D-LAND-19) |
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

-   PR 53: SAFE-2 stopped at its plan rev 14 and SAFE-3 is being planned on the
    branch (row :1095; the 2026-10-29 paragraph :706-743); the pushed head
    2407efa74 carries SAFE-1's six filed drifts W-347 to W-351 and W-353, which
    live in PR 67's ledger.
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
land-time notes (:2526-2587); UA-2 none of its own (its fill is the head); CM-1
none (e6bc32a6d fork/cmake/plan.md names no land-time step); EV-1 cb3ef2e74
fork/evaluator/plan.md section 3 item 6 (:1830-1842) and states T and C
(:296-311); ST-1 c3cdecc5d fork/string/plan.md landed notes' conditional items
(:3103-3110); DD-1 fcee90d9b fork/designdocs/plan.md §2.13 and §2.14
(:4180-4276), §8.5's integration-commit texts (:5665-5678, :5783-5810) and its
merge position (:6658); TP-1 66aa13132 fork/templates/plan.md §1.12
(:2924-2957), §3 items 7 to 13 (:5192-5316) and Appendix E's land-time texts
(:17744 on); SV-1 0ef8a0334 fork/sumtype-interop/plan.md §1.15 (:2392-2399), §3
item 8 (:4606-4830), Appendix C.6 and C.7 (:9351-9420) and the landed notes'
Next actions text (:9566-9576); CT-1 551a03328 fork/cpp-templates/plan.md §2.11
items 1 to 5 (:2725-2760) with Appendix C.1 to C.11; DR-1 89aabd125 and
fee0ef31c fork/direction/plan.md §1.16 (:1547-1620), §2.2 (:2190-2245) and §8
item 9 (:2755-2775); OV-4 097c76473 fork/overload/ov4-plan.md §3's land-time
commits (:1749-1803), §6.2 (:1901) and Appendix D.6 and D.7 (:4042, :4108).

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
and 16 at PR 58 ($F/checkers.txt has the checker runs).

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
2026-11-01, review fold: RR1-2). A later merge can conflict with those: two are
predicted from the heads (PR 65's merge against PR 63's Landed paragraph in
fork/direction/plan.md and its decision-log sentence in DR-1's entry, PL-1 and
DL-4), and a refill or a records text may meet a later PR's edit (PR 63's
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
landings where they apply: TP-1's F6 (TP-1's seven refills recomputed on the
merged tree, and PR 51's split `fail_todo_unformed_dependent_var` refilled
under its own name, CHECK lines only: the split's shape still fails on TP-1's
toolchain, so F6 does not rename it), SV-1's F-M (its own goldens; the PR 57
part waits), CT-1's L-F (C-2's rename of that split to `unformed_dependent_var`
and its refill, the shape compiling on CT-1's toolchain; C.11's split waits
with S-VA), DR-1's L-a (check and lower
generic/template/for_range and interop/cpp/range_for; the m57 three wait), L-b
(check generic/template/index, slice/write_through's renamed split,
string_indexing 2/2) and OV-4's F-M (predicted none). Prelude changes (PR 55,
62, 63, 65) can move full-prelude dumps; the gate finds any such golden and
D-LAND-8 refills it.

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
landing (section 2), and its merged trunk is verified before the push. The
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
9 as its spec (amended 2026-11-01, review fold: B-m8). _Break condition:_ the
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
TP-1's S (over SC-1) to G-60 and its VA-1 compositions (F6's, measured none)
to G-59; OV-4's SC-1 arguments in M to G-60 and its VA-1 gate order to G-59;
SV-1's M-VA and W-284 (with its `blocked_by` W-219) to G-59, and its Doc-M
(optional.md and the F-015 paragraph), C.5's W-177 note and evidence, C.8's
F-015 references, the W-177 cite in match_core_optional_diff.carbon's header
and F-M's PR 57 part to G-56/57; CT-1's S-VA with C.11's split to G-59; DR-1's
loops.md rule in M-a to G-56 and L-a's m57 refills to G-57; DD-1's state-L
texts for PR 53, PR 56 and SC-1 to their follow-ons; ST-1's SAFE-1
reconciliation edits to G-53; RG-1's land-time notes for PR 57 and PR 59 to
G-57 and G-59, with W-343's discharge (D-LAND-15). (Amended 2026-11-01, review
fold: B-M6.) _Break condition:_ a moved step whose absence makes a ready
landing's gate fail (D-LAND-1's).

**D-LAND-5, the merge rules.** Measured on the dry run and applied by the
implementer by hand, the saved files in `$X` being the reference (amended
2026-11-01, review fold: A-B1 / A-M1 / A-m1):

-   OR-1: ORCHESTRATION's header region takes trunk's side; the records commit
    restamps the header.
-   OR-2: Branches rows are merged row by row by their first cell; a row both
    sides changed takes trunk's; the records commit rewrites the landed row.
-   OR-3: dated paragraphs inserted on both sides are both kept, in date
    order, the PR's first on the same date (it predates trunk's stamp of it).
-   OR-4: a region both sides edited takes trunk's side (the newer
    orchestrator text); the region report lists the PR side's words trunk
    lacks.
-   OR-5: in an OR-4 region of the Next actions, each item the PR side added
    is either carried by the records commit, verbatim with a dated carry mark,
    or named in the records commit's message as discharged by the landing (a
    PR's own "at land time" item, whose steps the landing makes or D-LAND-4
    moves); section 2 and Appendix C list which, landing by landing.
-   DL-1: decision-log entries inserted at one point are both kept, trunk's
    first, in the log's workstream grouping. DL-3: the order at the DR-0 group
    is DR-0, DR-1, RG-1, LD-0, as D-RG-14 implies (RG-1's after DR-0's and
    DR-1's; LD-0 the newest): at PR 67 RG-1's entry goes before LD-0, and at PR
    63 DR-1's goes directly after DR-0's, before RG-1's (`$F/bin/dlorder.py`).
    DL-4: where a PR's head appends paragraphs to an entry whose end trunk has
    given a Landed sentence (A.6), the PR's paragraphs go first and the Landed
    sentences stay last, in landing order (predicted at PR 65 for DR-1's entry).
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
    `json.load` must pass. LG-2 to LG-6: an item both sides changed keeps
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
amended 2026-11-01, review fold: A-M2 / A-M4 / A-m3 / B-B1 / B-M4 / B-m2):

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
    `scratchpad/land1/impl/pr<N>/`, outside the repository.
5.  Commit the merge with Appendix A.1's message, the results of step 4 in it.
6.  The plan's land-time code, page and program commits, if section 2 lists
    any, each brought to a prek fixpoint before its commit, then built, gated
    and committed with section 2's message.
7.  Refill: if the gate reports "Autoupdate would make changes", run
    `$CB/autoupdate.sh /home/user/carbon-trunk <files>` on exactly those
    files, gate again (every golden passes) and commit Appendix A.2's refill
    commit (D-LAND-8). A gate failure of any other kind stops the landing.
    Then prek on every other file the landing changed
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
    rows section 2 names, which must report 0 missing; the edits saved as
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
    mirror as in step 11.

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
L-F, DR-1's L-b) is its own commit before the autoupdate; TP-1's F6 renames
nothing (section 0.7; amended 2026-11-01, review fold: RR1-1). _Break
condition:_ none.

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
the stale text.

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
when SAFE-3 has completed (its realignment commits and reviews dry, PR 53's head
pushed) and the realignment notes SAFE-3 owes PR 67 are on trunk's ledger, since
PR 67 has landed; G-60 (PR 60) when W-139's fix commit is on PR 60's branch
under SC-1's reviews and item 10 is decided; G-56/57 (PR 56, then PR 57) when
W-352's commit is on PR 56's branch, merged into PR 57's, under OP-1's reviews,
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
records commit (otherwise unused). Appendix B.1 records the reservation, so
SAFE-3, whose plan text keeps W-367 free, takes W-371 onward (amended
2026-11-01, review fold: B-m8). _Break condition:_ any of W-367 to W-370 filed
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
step 8). (Amended 2026-11-01, review fold: A-M2 / B-B1.) _Break condition:_ a
state-L text that cannot be split by PR; it then waits whole for the last
follow-on, and the checker's `ALLOWLIST` keeps its entry until then.

**D-LAND-15, W-343.** RG-1 narrowed W-343 to five land-time notes, discharged
by the last (rg1-plan.md:500-504). PR 51's, PR 54's and PR 58's are made now,
each after the text anchor Appendix C names (amended 2026-11-01, review fold:
B-M5); PR 57's and PR 59's by G-57 and G-59, and whichever lands last
discharges W-343. _Break condition:_ a follow-on abandoned; the orchestrator's
stamp then discharges W-343 by RG-1's own break condition (:504-506).

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
PR 54 and PR 58, PR 67's W-355 note, OV-4's L-R), `<tip>` is upstream trunk's
head on the landing day, fetched at the check, never a tip chosen because the
checks pass at it. Both scripts run over the whole tables there:
`fork/register/check_quotes.sh /home/user/carbon-lang <tip>
fork/register/rg1-quotes.tsv` and `fork/register/check_greps.sh
/home/user/carbon-lang <tip> fork/register/rg1-checks.tsv`, their counts
quoted in the records commit's message and each FAIL row appended by id to
W-355's notes (Appendix C.2's text); a note whose own entries fail says so in
its lead (Appendix C.3). _Break condition:_ none.

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
2026-11-01, review fold: B-M7 / B-M2). Expected: 1942 of 1942; 128/0/22 over
150; tally 30/21/4/1. Gap-row check: no row named. Next: PR 64's and PR 65's
bases are unaffected.

### §2.2 PR 51, UA-2

Head f96fe8a7a (the container fill), base trunk. Conflicts: gap-analysis
(GA-1, the Slices row keeps trunk's DR-0 sentence and UA-2's W-108 narrowing),
ledger (LG-1, 14 decisions). Steps: merge; D-LAND-19's checks; records with
RG-1's UA-2 land-time note after its register block (Appendix C.3; amended
2026-11-01, review fold: B-M2 / B-M5). Expected: 1945 of 1945 (its own gate);
131/0/19 over 150. Gap-row check: no row named. Deferred: none (its split
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
no row named. Deferred: none.

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
their state C texts (sections 2.F.1 and 5.3; the tally 33/19/3/1), W-131's and
W-133's notes, its message recording section 8.2's state C verification line
and the R31 counts re-run (amended 2026-11-01, review fold: A-m2 / B-M6); then
records with RG-1's EV-1 note and the W-152 carry (Appendix C.5). Expected:
1945 of 1945; 143/0/16 over 159 after state C (static 142/0/17 at the merge).
Gap-row check: no row named. Deferred: none.

### §2.5 PR 55, ST-1

Head c3cdecc5d, base trunk; one toolchain file and one prelude file.
Conflicts: ORCHESTRATION (OR-1, OR-2, OR-4 twice, OR-5), decision-log (DL-1),
gap-analysis (GA-1 twice, GA-2 on the header), ledger (LG-1). Steps: merge;
build, gate (a prelude change); refill only what the gate names; records with
the header `<tally>` (34/18/3/1 expected) and W-126 cited by id (PR 51 has
landed, as ST-1's landed notes assumed, :3107-3109), and OR-5: item 5 (ST-1's
merge steps) discharged by the landing, item 6 (the SAFE-1 reconciliation)
carried as G-53's item by Appendix B.1, and the ST-1 dated paragraph's item
numbers marked (Appendix C.6; amended 2026-11-01, review fold: A-M1).
Expected: 1953 of 1953 (section 4); 148/0/15 over 163. Gap-row check: no row
named. Deferred to G-53: W-144's additions, the seven SAFE-1 reconciliation
edits and the cross-branch re-cites (:3103-3106, fork/string/plan.md
section 2.6).

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
errors; the dry run's 94dba6b21 is the reference); then records with DD-1's
section 2.14 evidence amendments for W-014, W-127, W-155 and W-167, row 91's
dated mark, RG-1's DD-1 note (rg1-plan.md:2562-2570), the header `<tally>`
(35/17/3/1 expected), a dated note on W-043, and OR-5's carry of DD-1's
correction note under item 3 (Appendix C.7). Expected: 1953 of 1953;
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
TP-1's seven refills recomputed and PR 51's split refilled under its name
`fail_todo_unformed_dependent_var`, CHECK lines only: F6 drops TP-1's rename
of that split (:5212-5214 and Appendix A's F6 line, :15210-15212), because the
split's shape still fails on TP-1's toolchain and file_test rejects a failing
split without the `fail_` prefix (section 0.7; CT-1's C-2 and H-1), and PR
64's L-F renames it (section 2.9; amended 2026-11-01, review fold: RR1-1);
item 9's implementation reviews A and B on the merged head are D-LAND-10's
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
of W-127, W-183, W-192 and W-193, W-127's as Appendix C.8 gives it, the
held-state sentences replaced by the merged tree's values), the landed notes
with both id re-scans' outcomes (the one before L and one before the records
commit), and C.8's F6 sentence at the end of A.5 and A.6 (amended 2026-11-01,
review fold: RR1-1). Expected: 1968 of 1968, the split passing as a `fail_`
split;
177/0/15 over 192. Gap-row check: row 54 named (R writes it). Deferred to
G-60: S (member_access.cpp, :5206-5212); to G-59: the VA-1 compositions F6
measured as none.

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

### §2.9 PR 64, CT-1

Head 551a03328, base claude/carbon-fork-0-1-tp, retargeted to trunk after PR
61's phase 2. Conflicts: ORCHESTRATION (OR-3, OR-4, OR-5), README-1 (204
programs), PROG-1 on the two programs (PR 51's header with C.6's paragraph
appended, `<YYYY-MM-DD>` the landing date, and CT-1's body, `var b:
Cpp.Box(T);`), decision-log (DL-1), gap-analysis (GA-1c on rows 42 and 56),
ledger (LG-7: W-043 "taken from DD-1's side whole", CT-1's discharge reapplied
by the records commit, fork/cpp-templates/plan.md:2730-2737). Steps: merge; S-VA
moves to G-59; L-F, by C-2's own rule (fork/cpp-templates/plan.md:864-878 and
section 2.11 item 3; not section 1.16's fallback, since PR 61's F6 keeps the
name): first a rename commit, "Land PR 64: PR 51's split renamed for CT-1's L-F
(C-2)", whose only edits are this plan's Appendix C.10 texts for
toolchain/check/testdata/interop/cpp/template/dependent_var_full_prelude.carbon
(the split line, as TP-1's Appendix A F6 line gives it, and a dated header
note); then the refill of every golden the gate names, that split among them,
which CT-1's toolchain compiles (section 0.7; amended 2026-11-01, review fold:
RR1-1); L "Land PR 64: CT-1 interoperability page and fixture X37 over PR 58"
(C.1, with this plan's Appendix C.10 anchor; X37 with its `SAMPLES` entry after
X09's and X09's limit comment, checked with `--toolchain`; the dry run's checker
result is section 0.5's; amended 2026-11-01, review fold: RR1-2); records: rows
56 and 42 by C.4, found by bullet text, with the interop golden counts measured
on the landing's tree, C.2's discharge over DD-1's W-043 (including the PR 58
note of section 2.6), W-127's sentence (C.10), the id re-scan. Expected: 1978 of
1978; 189/0/15 over 204. Gap-row check: rows 42 and 56 named (C.4 replaces
them). Deferred to G-59: S-VA and C.11's split.

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
its count recorded at L-a (fork/direction/plan.md:1555-1582); records with the
row-68 mark and item 1's mark (Appendix C.11). Expected: 1978 of 1978;
189/0/15 over 204. Gap-row check: no row named. Deferred to G-56: loops.md's
rule; to G-57: the m57 refills (lower array/iterate, for/break_continue,
for/for).

### §2.11 PR 65, DR-1b

Head fee0ef31c, base claude/carbon-fork-0-1-dr, retargeted to trunk after PR
63's phase 2. Conflicts: ORCHESTRATION (OR-2), README-1 (206 programs),
gap-analysis (GA-1b on row 79), ledger (LG-1, LG-6 on the source header), TC-2
(handle_index.cpp: DR-1b's side with TP-1's `SemIR::LocId loc_id` parameter
and the default arm's `return elem_id;`, by $P/bin/resolve65.py), GOLD-1
(string_indexing.carbon, trunk's side), and, predicted from the heads, PL-1 on
fork/direction/plan.md and DL-4 on DR-1's decision-log entry (section 0.5's
limit). GA-1b (amended 2026-11-01, review fold: A-B1): row 79 ("Stdlib:
Slices") is DR-1b's row with its clause "a `Buf` held in a field is not freed —
aggregate destroy ops are still the member-destruction placeholder (W-108)"
replaced by trunk's clause verbatim, "a `Buf` held in a field of an owner that
declares its own `impl as Destroy`, or in a choice payload, is not freed (W-108
narrowed at UA-2, 2026-10-06: ... W-125 for payloads)" (the full clause is
`$F/expected/pr65/row79_clause.txt`); its status is DONE, so the tally is
36/16/3/1 from here on. Steps: merge (M-b); C-b, "Land PR 65: DR-1b
composition with TP-1: a template-dependent index chooses its interface per
specific", the block of fork/direction/plan.md:2204-2225 at the head of
`PerformIndex`'s default arm, removing the arm's later
`auto index_type_id = context.insts().Get(index_inst_id).type_id();` (the
hoist section 2.2 names; :271 on the dry run's tree; amended 2026-11-01,
review fold: B-m7); the nine probes on the landing's install, by
`TCS="trunk:/home/user/carbon-build/carbon-trunk/install/bin/carbon"
<S>/dr1b-rr/rev1-r4/bin/run4.sh <probe>` with `<S>` the scratchpad, over
rev1-r4/probes_mct's t10_tmpl_iw_var, t15_tmpl_iw_i32var, t16_tmpl_dep_sub,
t18_tmpl_member_iw, n06_tmpl_ptr, n15_tmpl_iwlit, n32_tmpl_vec_generic_iw and
n13_tmpl_mixed and rec-r4/p/a4_tmpl_constrained, expected `7`, `8`, `9`, `6`,
`8`, `5`, `7`, `3 7` and `9` (:1602-1612; a different output stops the
landing; added 2026-11-01, review fold: B-M6); L-b refills (check
generic/template/index, slice/write_through with
`fail_todo_template_index_with_only` renamed `template_index_with_only` in a
commit before the autoupdate, string_indexing 2/2); records discharging W-340
with M-b's, C-b's and L-b's shas (C.2), row 79's W-340 sentence in the past
tense (C.3), the DR-1 entry's dated note, the header `<tally>` and item 1's
mark (Appendix C.12). Expected: 1982 of 1982; 191/0/15 over 206; row 79 DONE
with its bullet PASS. Gap-row check: no row named. Deferred: none.

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
handle_function.cpp.

## §3 The process

The implementation workflow runs one stage per landing, in order, each
stopping on D-LAND-10 (amended 2026-11-01, review fold: B-m4 / B-m6). Before
stage 0 the orchestrator pushes the signed-off plan with Appendix B.1's stamp
(D-LAND-16). Stage 0 is the baseline (D-LAND-7); stages 1 to 12 are PR 67, 51,
52, 54, 55, 58, 61, 62, 64, 63, 65 and 68. The actors:

| Step | Actor |
| --- | --- |
| D-LAND-6 steps 1 to 9, the land-time commits, prek, R31, the checks | the implementer |
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

-   G-53 (PR 53): records-only merge (section 0.6); land-time: ST-1's SAFE-1
    edits, DD-1's state L for PR 53, RG-1's H53 notes already on the head,
    SAFE-3's notes on trunk's ledger.
-   G-60 (PR 60): merge of trunk into PR 60's branch resolving convert.cpp,
    member_access.cpp, merge.cpp and templates.md, with TP-1's S, OV-4's two
    arguments, DD-1's state L for SC-1, item 10's decided commit, fills, gate,
    its review; then the trunk landing.
-   G-56/57 (PR 56, then PR 57 retargeted to trunk): W-352; loops.md by M-a's
    rule and C.7; error_handling.md by DD-1's and OP-1's texts; DR-1a's m57
    refills; SV-1's Doc-M, C.5, C.8, the W-177 header cite and F-M's PR 57
    part; DD-1's state L for PR 56; RG-1's OP-2 note.
-   G-59/66 (PR 59, then PR 66 retargeted to trunk), owned by VA-1's
    workstream: W-367's fix and note 7's ruling on PR 59, W-367 (and W-368 if
    the ruling makes a fix) filed in PR 59's branch's ledger;
    handle_function.cpp by OV-4's rule; SV-1's M-VA and W-284; CT-1's S-VA and
    C.11's split; RG-1's VA-1 note and W-343's discharge if it is the last;
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
| PR 52 | 150 | 133 / 0 / 17 | 2 | none stated | 32/20/3/1 | 1945 |
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
-   R-4, id collision with SAFE-3. Falsifier: W-367 to W-370 found filed by
    another workstream at the stamp; D-LAND-13's break condition.
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
Not run by the planner or the fixers, by rule: any build, gate,
autoupdate or conformance run; the checkers' `--toolchain` mode; the merged
trees' compilation (the TC-1 and TC-2 files are mechanical references, built
first by stage 10 and stage 11); the register checks at a tip. Not run by
LAND-1 at all: clang-tidy, the Bazel-only tests, the BUILD-dependency hooks
prek skips, LLVM with assertions, macOS, Windows and other platforms, and R21's
hosted gate, which R33 (b) owes when Actions returns.

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
    before the autoupdate. If PR 61's gate reports that split as succeeded ("if
    success is expected, remove the `fail_` prefix"), or PR 64's as failed, the
    toolchain is not the one section 0.7 measured: the landing stops
    (D-LAND-10). The L texts are `$F1/bin/extract_l61.py`'s output with
    `--state-l` and `$F1/bin/apply_l64.py` with Appendix C.10's anchor, as
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
of <gn> before any refill (each golden that fails is refilled by this
landing's refill commit, fork/land/land1-plan.md Appendix A.2, which
states the gate after it); conformance <p>/<f>/<s> over <n>, bullets <b>
of 56. prek clean on the resolved files (SKIP=fix-cc-deps,
check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest).

<trailers>
```

The merge's `<g0>` and `<gn>` are step 4's; `<g0>` equals `<gn>` when
nothing fails, and then no refill commit follows. The conformance values of
A.1 are the merge's too; A.3 to A.7 carry the landing's final ones (amended
2026-11-01, review fold: RR1-6).

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
<landed> PRs landed, <held> held. Next: <next>.
```

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
bullets; moved to follow-ons: <moved>.
```

It goes at the target Appendix C.1's "Plan file and anchor" column names.

### A.6 The decision-log sentence

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR <N> by
<merge sha> (GitHub merged_at <merged_at>); container-measured (R33 (b)):
gate <g> of <g>, conformance <p>/<f>/<s> over <n>; moved to follow-ons:
<moved>.
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
below is the last hosted record.
```

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
its follow-on (Next actions items 14 to 17): PR 53 (SAFE-3), PR 60 (W-139
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
 (superseded <date> by LAND-1, fork/land/land1-plan.md D-LAND-12: waits for SAFE-3 and lands by Next actions item 14)
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
gates, each landing by its follow-on (items 14 to 17): PR 53 after SAFE-3
completes, PR 60 after W-139 and item 10, PR 56 and PR 57 after W-352
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
    procedure once SAFE-3 has completed on PR 53's branch and SAFE-3's
    realignment notes on PR 67's items are on trunk's ledger. Its
    land-time steps: ST-1's SAFE-1 reconciliation (W-144's additions, the
    seven edits and the cross-branch re-cites of fork/string/plan.md
    section 2.6 and its landed notes' conditional items, on trunk from PR
    55's landing); DD-1's state L for PR 53 (fork/designdocs/plan.md
    section 2.13: assignment.md, threads_and_atomics.md,
    safety/mutation_safety.md, README.md's state-L sentence and its "held
    PR" definition dropped once no page cites a held PR, the ALLOWLIST's
    PR 53 entry removed, W-188's notes, row 91 DONE if section 5's
    condition holds); RG-1's H53 notes, already on the head.
15. G-60, PR 60 (D-LAND-12): once W-139's fix commit is on PR 60's branch
    under SC-1's reviews and item 10 is decided, a merge of trunk into PR
    60's branch (never a rebase) resolving convert.cpp, member_access.cpp,
    merge.cpp and templates.md, with TP-1's S (fork/templates/plan.md
    section 3 item 8), OV-4's two SC-1 arguments in
    CheckOverloadMemberParamsMatch (fork/overload/ov4-plan.md section 3,
    M's message), DD-1's state L for SC-1 (template_constraints.md),
    item 10's decided commit, fills, gate and review; then the trunk
    landing.
16. G-56/57, PR 56 then PR 57 retargeted to trunk (D-LAND-12): once
    W-352's commit is on PR 56's branch, merged into PR 57's, under OP-1's
    reviews, and item 10 is decided. Steps: loops.md by DR-1's M-a rule
    (fork/direction/plan.md section 1.16) and C.7; error_handling.md by
    DD-1's and OP-1's texts; DR-1a's m57 refills (lower array/iterate,
    for/break_continue, for/for); SV-1's Doc-M (optional.md and the F-015
    paragraph), C.5's W-177 note and evidence, C.8's F-015 references,
    the W-177 cite in match_core_optional_diff.carbon's header and F-M's
    PR 57 part (fork/sumtype-interop/plan.md section 3 item 8); DD-1's
    state L for PR 56; RG-1's OP-2 note (W-343).
17. G-59/66, PR 59 then PR 66 retargeted to trunk (D-LAND-12), owned by
    VA-1's workstream: once item 13's fix and W-367 and note 7's ruling
    (W-368 if it makes a fix) are on PR 59's branch under VA-1's review
    and item 2's preconditions hold. Steps: handle_function.cpp by OV-4's
    rule (VA-1's pack gate before OV-4's default look-through); SV-1's
    M-VA and W-284 with its blocked_by W-219; CT-1's S-VA and C.11's split;
    TP-1's VA-1 compositions (measured none); RG-1's VA-1 note and W-343's
    discharge if it is the last; then VA-2's own M, S-CT, F-M, L-F and L
    (fork/variadics/va2-plan.md section 3 item 15) over convert.cpp,
    eval.cpp and handle_function.cpp.
```

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

The fields of Appendix A, by landing (`<moved>` is "none" where the column is
empty):

| PR | Suffix | Spec | Workstream | Title | Summary | Moved | Next |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 67 | rg1 | 2.1 | RG-1 | RG-1, the V-3a register classified against upstream | records only: the V-3a register classified at upstream f27a977d8; W-342 and W-344 discharged, W-343 narrowed to the land-time notes, W-346 to W-356 filed | none | PR 51 (UA-2) |
| 51 | ua2 | 2.2 | UA-2 | UA-2, upstream reconciliation | the reconciliation of the 2026-10 upstream advance, with the container fill f96fe8a7a (1945 of 1945) and hosted conformance 37413300832 (131/0/19 over 150) | none | PR 52 (CM-1) |
| 52 | cmake | 2.3 | CM-1 | CM-1, CMake language modules, examples/cmake and Make documentation | CMake language modules, examples/cmake and the Make documentation; gap rows 84 and 87 DONE; W-060 and W-061 discharged, W-128 to W-133 filed | none | PR 54 (EV-1) |
| 54 | ev | 2.4 | EV-1 | EV-1, evaluator documentation | the evaluator guides and transcribed programs, in state C with PR 52; gap row 90 DONE; W-062 discharged, W-152, W-153 and W-155 filed | none | PR 55 (ST-1) |
| 55 | st | 2.5 | ST-1 | ST-1, str comparison, Core.StringBuf and concatenation | F-014: str comparison, Core.StringBuf and concatenation; gap row 77 DONE; W-057 discharged, W-160 to W-167 filed | to Next actions item 14: W-144's additions, the seven SAFE-1 reconciliation edits and the cross-branch re-cites | PR 58 (DD-1) |
| 58 | dd | 2.6 | DD-1 | DD-1, design docs without placeholders | design docs without placeholders, with state L for PR 51, PR 54 and PR 55; gap row 70 DONE, row 91 PARTIAL until state L for PR 53, PR 56 and SC-1; W-065 discharged | to items 14, 15 and 16: state L for PR 53, SC-1 and PR 56 | PR 61 (TP-1) |
| 61 | tp | 2.7 | TP-1 | TP-1, integrated templates | integrated templates with F6's refills (PR 51's split refilled under its fail_todo_ name, which PR 64's L-F renames) and L over PR 58; W-127 for the template shape, W-183, W-192 and W-193 discharged; gap row 54 PARTIAL | to item 15: S; to item 17: the VA-1 compositions | PR 62 (SV-1) |
| 62 | sv | 2.8 | SV-1 | SV-1, std::optional and std::variant interop mapping | F-020: std::optional and std::variant interop mapping; W-011 DISCHARGED; W-284 held until M-VA lands (item 17); gap row 68 PARTIAL | to item 17: M-VA and W-284; to item 16: Doc-M, C.5, C.8, the W-177 header cite and F-M's PR 57 part | PR 64 (CT-1), after the orchestrator retargets it to trunk |
| 64 | ct | 2.9 | CT-1 | CT-1, C++ templates on symbolic Carbon type arguments | F-021: C++ templates on symbolic Carbon type arguments, instantiated per specific; PR 51's split renamed unformed_dependent_var by L-F (C-2); W-043 DISCHARGED; gap rows 56 and 42 PARTIAL | to item 17: S-VA and C.11's split | PR 63 (DR-1a) |
| 63 | dr | 2.10 | DR-1a | DR-1a, Core.Iterate.Next takes a ref cursor | R32: Core.Iterate.Next takes a ref cursor; W-321 discharged | to item 16: loops.md's M-a rule and the m57 refills | PR 65 (DR-1b), after the orchestrator retargets it to trunk |
| 65 | dr-idx | 2.11 | DR-1b | DR-1b, subscripting prefers IndirectIndexWith | R32: subscripting prefers IndirectIndexWith and Core.Slice and Core.Buf write through Ref, with C-b over TP-1; W-109 and W-340 discharged; gap row 79 DONE | none | PR 68 (OV-4) |
| 68 | ov4 | 2.12 | OV-4 | OV-4, `overload fn` members with default parameter values | W-341 DISCHARGED: `overload fn` members with upstream's default parameter values; W-360 to W-363 to UA-3 | to item 15: SC-1's two arguments; to item 17: VA-1's pack gate order | Appendix B.2's stamp, then the follow-ons |

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
waits for SAFE-3 by its follow-on while the ready PRs land past it, the
dry run of that plan's section 0.5 having measured that their records and
merge-trees hold without the waiting PRs.)
```

Appended to W-343's `notes`:

```text
 LAND-1 (<date>, fork/land/land1-plan.md, R33): landings resume; PR 53 waits for SAFE-3 (Next actions item 14) while the ready PRs land; the land-time notes of PR 51, PR 54 and PR 58 are made by their landings and those of PR 57 and PR 59 by items 16 and 17, the last of them discharging this item (D-LAND-15).
```

Appended to W-355's `notes` (D-LAND-19):

```text
 LAND-1 (<date>): at upstream <tip>, check_quotes.sh reports <q> quotes with <qf> failed and check_greps.sh <c> silence checks with <cf> failed over the tables as landed by PR 67 (at 68569d234, 2026-11-01: 273 with 8 failed and 89 with 2 failed); the failing rows, <the FAIL rows' ids as the scripts print them, or "none">, are this item's to re-read, never an edit of an expected count.
```

The last placeholder is the scripts' own output, listed as printed. In Next
actions item 6, "is held open as PR 67, first in the land sequence" becomes
"landed on trunk <date> as PR 67 by merge <merge sha> (LAND-1)".

### C.3 PR 51's own texts

RG-1's note "[UA-2, PR 51, after its :6232]" of rg1-plan.md Appendix A.4
(:2533-2542), verbatim with `<tip>` D-LAND-19's, inserted as a paragraph after
the paragraph of UA-2's decision-log entry that ends "with block 9's SL-1
trigger met for fields, as just recorded." If a FAIL row of D-LAND-19 is one of
the note's own quotes or checks, "re-checked at <tip>" is followed by "(<the
FAIL rows' ids> fail there; W-355)". OR-5: no item.

### C.4 PR 52's own texts

OR-5: appended as the last Next actions item (numbered next):

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

RG-1's note "[EV-1, PR 54, after its :3549]" (rg1-plan.md:2544-2550, with the
UA-2 lead in place of "...", as A.4 says), after the paragraph of EV-1's entry
that ends "the pointers are re-placed in that merge. Veto-able." OR-5:
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

RG-1's note "[DD-1, PR 58, after its :4129]" (rg1-plan.md:2562-2570), after
the paragraph of DD-1's entry that ends "DR4b-8), the page states both.
Veto-able." OR-5: DD-1's note, verbatim after item 3's text:

```text
    (Corrected 2026-10-14 at the DD-1 discharge: the gate dissolved under
    R29; F-009's and F-011's pages have landed, F-010's page is SC-1's, and
    F-008's page is docs/design/interoperability/threads_and_atomics.md,
    DD-1, so the stranded branch's F-008 draft is not ported; see its
    Branches row.)
```

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
TP-1's decision-log entry (66aa13132 fork/decision-log.md:4147-4149) and its
plan (:5212-5214) state F6's rename as planned; PR 61's A.5 Landed paragraph
and A.6 sentence each end with this sentence, which records what the landing
did instead:

```text
F6 kept PR 51's split's name, fail_todo_unformed_dependent_var, because its shape still fails on TP-1's toolchain (fork/cpp-templates/plan.md C-2 and H-1); PR 64's L-F renames it.
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

### C.10 PR 64's own texts

CT-1's: C.1 (L), C.2 (W-043's discharge over DD-1's entry, including C.7's
LAND-1 note), C.4 (rows 42 and 56, with the interop golden counts measured on
the landing's tree in place of 164 and 56), C.6 (the two programs, in the
merge), C.10 (W-127), with `<YYYY-MM-DD>` the landing date. C.1's replaced
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

OR-5: the
branch's "TP-1 at land time" and "CT-1 at land time" items are discharged by
PR 61's and this landing (the message lists S-VA as item 17's).

### C.11 PR 63's own texts

In row 68, after "is removed by a commit on its branch (W-322, 2026-10-21).":

```text
 (PR 62 landed on trunk with the view removed, LAND-1 stage 8.)
```

In Next actions item 1, "is held open as PR 63 and DR-1b, `IndirectIndexWith`
(W-109, stacked on DR-1a), as PR 65;" becomes "landed on trunk <date> as PR 63
(LAND-1), and DR-1b, `IndirectIndexWith` (W-109, stacked on DR-1a), is held
open as PR 65;".

### C.12 PR 65's own texts

DR-1's: Appendix C.2's W-340 discharge note (fee0ef31c
fork/direction/plan.md:3463-3469) with M-b's sha `<merge sha>` and C-b's and
L-b's from `<land-time shas>`, and C.3's past tense for row 79's W-340
sentence. DR-1's plan names the DR-1 entry's dated note without its text
(:1612-1615); it is this, before PR 65's A.6 sentence:

```text
_W-340 discharged (<date>, LAND-1):_ M-b <merge sha>, then C-b and L-b
(<land-time shas>) on trunk, by fork/direction/plan.md section 1.16: t10,
t15, t16 and t18 print 7, 8, 9 and 6, n06, n15, n32 and n13 print 8, 5, 7
and `3 7`, and a4 prints 9 on the landing's toolchain; check
slice/write_through.carbon's split is `template_index_with_only`.
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

Appended to W-341's `notes`, replacing D.7's ledger text:

```text
 Landed <date>: merged into trunk as PR 68 by merge <merge sha> (LAND-1, fork/land/land1-plan.md section 2.12), trunk before <trunk before> holding PR 67, 51, 52, 54, 55, 58, 61, 62, 64, 63 and 65, with PR 53, 56, 57, 59, 60 and 66 held; land-time commits <land-time shas> (L-R: register rows T2.8 and T2.9, checked at upstream <tip>); container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over <n>. It landed before PR 59, PR 60 and PR 66 (D-LAND-1), not after VA-2 as the owner line above says; SC-1's two arguments in CheckOverloadMemberParamsMatch go to Next actions item 15 and VA-1's pack gate order in handle_function.cpp to item 17.
```

The decision-log paragraph, the last of OV-4's entry:

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR 68 by
<merge sha> (GitHub merged_at <merged_at>), trunk before <trunk before>
holding PR 67, 51, 52, 54, 55, 58, 61, 62, 64, 63 and 65, by
fork/overload/ov4-plan.md section 6.2's rules; land-time commits
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
