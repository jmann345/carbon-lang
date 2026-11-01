<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# LAND-1 plan: landing the held PRs into trunk under R33

**Status:** rev 1, 2026-11-01 -- the planner's draft, for review. Records only:
this plan changes no toolchain, prelude, golden, program or workflow file. It
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
over trunk bb9fbba9c resolves every conflict by a recorded rule; the
non-records conflicts are three, each anticipated by the plan of the PR that
lands second: two conformance programs at PR 64 (CT-1's C.6 rule), and
toolchain/check/handle_loop_statement.cpp with a golden at PR 63 and
toolchain/check/handle_index.cpp with a golden at PR 65 (DR-1's M-a and M-b
rules). No toolchain or golden conflict between two ready PRs is
unanticipated; the gated PRs' later merges carry seven toolchain-file
conflicts, measured in section 0.6, which their follow-ons own. Each landing
is one merge commit, an optional refill commit and a records commit, verified
by the carbonbuild arbiter in /home/user/carbon-trunk, reviewed by one fresh
agent and pushed by fast-forward; the static scoreboard goes from 128 PASS / 0
FAIL / 22 SKIP over 150 to 193 / 0 / 15 over 208 (section 4).

## Contents

-   Section 0: audit (the held state, owed items, conflicts, the dry run,
    goldens, scoreboards, the arbiter, ids, stacked PRs, disk)
-   Section 1: decisions D-LAND-1 to D-LAND-16
-   Section 2: spec, one subsection per landing in land order
-   Section 3: the process and the follow-ons
-   Section 4: the scoreboard progression
-   Section 5: risks and rejected alternatives
-   Section 6: verification and what is not run
-   Hand-off notes
-   Appendix A: the per-landing record templates
-   Appendix B: the ORCHESTRATION stamps

Conventions. `trunk` is origin/trunk bb9fbba9c unless a section says otherwise.
A file:line cite names the sha it was read at. `$P` is the planner's scratch
directory
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/land1/planner,
`$CB` the arbiter's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild,
and `$X` the expected trees, `$P/expected`. Placeholders are written `<merge
sha>`, `<date>` (the commit's UTC date, `date -u +%F`), `<g>` (the gate's
passing count), `<p>/<f>/<s> over <n>` (conformance PASS, FAIL, SKIP and
programs), `<b>` (bullets PASS of 56) and `<trailers>` (the session's two
attribution trailers, written by the implementer and never into a repository
file). No placeholder survives into a commit.

## §0 Audit

### §0.1 The held state

`git ls-remote origin` (2026-11-01, after `git fetch origin`) gives trunk and
the mirror claude/carbon-fork-0-1-7mwfb7 both at bb9fbba9c, and every held
head equal to the task's list; the GitHub API (`list_pull_requests`, state
open) gives all eighteen open, `merged: false`, with the bases below. No head
moved.

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
58. Prelude changes: PR 55, 56, 57, 62, 63, 65 and 66. Toolchain changes: PR
55 (one file), 57, 59, 60, 61, 62, 63, 64, 65, 66 and 68.

Two Branches rows cite a sha that is not the head: PR 51's row
(ORCHESTRATION.md:1093) names 05a5c30f7, and the head f96fe8a7a is its child,
"Autoupdate testdata goldens on the container arbiter" (2026-10-12 20:56 UTC),
after which /home/user/carbon-build/carbon-ua2/logs/gate.log records "Ran 1945
tests ... [ PASSED ] 1945 tests"; PR 63's row (:1107) names 18a7e8934, and the
head 89aabd125 is nine records commits later (`git log 18a7e8934..89aabd125`,
the last "DR-1 plan: focused re-review of DR-1b's fold, round 4 recorded",
2026-10-26). Neither is a moved head: the rows were not restamped, and each
landing's records commit rewrites its row (section 2). Nine local worktree
branches lag their pushed heads (carbon-cmake ea573f672, -ct 4a3220c11, -op
894139b34, -op2 a080c7886, -sc 40a76ab81, -st 21307851a, -tp 5661a35c8, and
carbon-safe 547fb6220, which is SAFE-3's unpushed work ahead of 2407efa74);
LAND-1 merges the pushed heads only, from origin.

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
states none.

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

Each plan specifies its land-time steps as commits on its own branch: a merge
of trunk into the branch (M or an integration commit), compositions, refills
and a records commit. Section 2 maps each to the trunk-side commits of
D-LAND-3 and names the steps that wait for a gated PR (D-LAND-4). The sources:
RG-1 56e2e5bbd fork/register/rg1-plan.md section 5 (:1607-1640) and Appendix
A.4's land-time notes (:2526-2587); UA-2 none of its own (its fill is the head);
CM-1 none (e6bc32a6d fork/cmake/plan.md names no land-time step); EV-1
cb3ef2e74 fork/evaluator/plan.md section 3 item 6 (:1830-1842) and states
T and C (:296-311); ST-1 c3cdecc5d fork/string/plan.md landed notes'
conditional items (:3103-3110); DD-1 fcee90d9b fork/designdocs/plan.md
section 2.13 (:4180-4266) and its merge position (:6658); TP-1 66aa13132
fork/templates/plan.md section 1.12 (:2924-2957) and section 3 items 7 to 13
(:5192-5310); SV-1 0ef8a0334 fork/sumtype-interop/plan.md section 1.15
(:2392-2399) and section 3 item 8 (:4606-4752); CT-1 551a03328
fork/cpp-templates/plan.md section 2.11 items 1 to 5 (:2730-2760) with
Appendix C.1 to C.11; DR-1 89aabd125 and fee0ef31c fork/direction/plan.md
section 1.16 (:1547-1620) and section 2.2 (:2190-2245); OV-4 097c76473
fork/overload/ov4-plan.md section 3's land-time commits (:1749-1803),
section 6.2 (:1901) and Appendix D.6 and D.7 (:4042, :4108).

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

A detached worktree /dev/shm/land1-planner/wt at bb9fbba9c merged the twelve
heads in D-LAND-1's order, each by `git merge --no-ff --no-commit`, resolved
by D-LAND-5's rules with the scripts $P/bin/trymerge.sh, ledger3.py, md3.py and
resolve65.py, and committed in the scratch (never pushed). Each landing's
resolved files are saved in `$X/pr<N>/files/`, with the three stages and a
region report in `$X/pr<N>/stages/`, the scratch merge's sha and tree in
`merge_sha.txt` and `tree.txt`, and `runner.py --self-test` in `selftest.txt`.

| Step | Scratch merge | Conflicted files (regions) | Rules applied |
| --- | --- | --- | --- |
| PR 67 | 460883f87 | ORCHESTRATION (5), decision-log (1) | OR-1, OR-2 (2), OR-3, OR-4; DL-3 (RG-1's entry before LD-0) |
| PR 51 | 287be2201 | gap-analysis (1), work-items | GA-1 (Slices row: both edits kept); LG-1 (14 items) |
| PR 52 | 4bb7be644 | ORCHESTRATION (3), decision-log (1), work-items | OR-1, OR-2, OR-4; DL-1; LG-1 (11) |
| PR 54 | 87d3ff399 | ORCHESTRATION (4), decision-log (1), gap-analysis (4), work-items | OR-1 to OR-4; DL-1; GA-1, GA-2 (3: header, prose, section W11); LG-1, LG-3 (W-002, W-003) |
| PR 55 | d32b9f47e | ORCHESTRATION (4), decision-log (1), gap-analysis (3), work-items | OR-1, OR-2, OR-4 (2); DL-1; GA-1 (2), GA-2 (header); LG-1 |
| PR 58 | 8de91ba75 | ORCHESTRATION (4), conformance/README.md (1), decision-log (1), gap-analysis (4), work-items | OR-1 to OR-4; README-1; DL-1; GA-1, GA-2 (3); LG-1, LG-2, LG-3, LG-5, LG-6 (W-043, W-065) |
| PR 61 | f7d317ffe | ORCHESTRATION (2), conformance/README.md, gap-analysis (1), work-items | OR-3, OR-4; README-1; GA-2; LG-1 |
| PR 62 | 132b42631 | ORCHESTRATION (4), gap-analysis (1), work-items | OR-1 to OR-4; GA-2; LG-1 |
| PR 64 | 307e8b617 | ORCHESTRATION (2), conformance/README.md, two programs (2 each), decision-log (1), gap-analysis (2), work-items | OR-3, OR-4; README-1; PROG-1; DL-1; GA-2 (2); LG-1, LG-7 (W-043) |
| PR 63 | 06be6898a | ORCHESTRATION (2), decision-log (1), gap-analysis (2), work-items, handle_loop_statement.cpp (1), interop/cpp/range_for.carbon (25) | OR-2, OR-4; DL-1; GA-1 (2); LG-1; TC-1; GOLD-1 |
| PR 65 | e8890e15d | ORCHESTRATION (1), conformance/README.md, gap-analysis (1), work-items, handle_index.cpp (3), operators/overloaded/string_indexing.carbon (2) | OR-2; README-1; GA-2; LG-1, LG-6 (the source header); TC-2; GOLD-1 |
| PR 68 | d4119d2f3 | ORCHESTRATION (4), work-items | OR-1 to OR-4; LG-1 |

Every scratch merge passes `runner.py --self-test` ("N programs parsed, 56
bullets in table, OK") and `json.load` of the ledger (232 items at the end).
The model-identifier grep of `git diff bb9fbba9c..d4119d2f3`, with the
patterns kept in $P/model_ids.txt, finds nothing.

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
only (counted). No conflict between two ready PRs is unanticipated.

Records interactions the dry run found that no plan names (each is a records
correction in the named landing's records commit, not a merge rule): at PR 58,
W-043's notes keep DD-1's appended sentence that the SKIP reason of
cpp_template_symbolic_arg.carbon "is stale", while PR 51, landed before it,
un-SKIPped that program; at PR 54, PR 55 and PR 58 the gap-analysis header's
tally is taken from trunk's side (GA-2), so each records commit recomputes it
from the rows (section 0.7); at PR 67, trunk's LD-0 and RG-1's entry share an
insertion point that D-RG-14 predates.

### §0.6 The follow-ons' merges, measured now

`git merge-tree --write-tree --name-only d4119d2f3 <head>` (the gated heads
onto the dry run's last scratch merge):

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
corrected form C.7 gives it".

### §0.7 Goldens, prelude and refills

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
landings where they apply: TP-1's F6 (PR 51's `fail_todo_unformed_dependent_var`
split renamed `unformed_dependent_var` and refilled, and TP-1's seven refills
recomputed on the merged tree), SV-1's F-M (its own three goldens; the PR 57
part waits), CT-1's L-F (C.11's split waits with S-VA; the PR 51 split's
rename is TP-1's, so CT-1 takes §1.16's fallback), DR-1's L-a (check and lower
generic/template/for_range and interop/cpp/range_for; the m57 three wait),
L-b (check generic/template/index, slice/write_through's renamed split,
string_indexing 2/2) and OV-4's F-M (predicted none). Prelude changes (PR 55,
62, 63, 65) can move full-prelude dumps; the gate finds any such golden and
D-LAND-8 refills it. The gap-analysis status tally of each scratch merge's
rows ($P/bin/gaptally.py) is 30/21/4/1 at trunk, PR 67 and PR 51; 32/20/3/1
at PR 52; 33/19/3/1 at PR 54; 34/18/3/1 at PR 55; and 35/17/3/1 from PR 58 to
PR 68, while the header the merges keep says 32/20/3/1 from PR 52 on, so the
records commits of PR 54, 55 and 58 rewrite it.

### §0.8 Scoreboards, measured statically

`runner.py --self-test` on each scratch merge counts the programs and the
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
/home/user/carbon-build/carbon-trunk with bin/carbon-busybox, file_test and
make-installation-digest (2026-10-12; `carbon version` prints the version
`0.0.0-0.dev+0bdce60a5`; `git diff --stat 0bdce60a5 bb9fbba9c` changes five
files, all under fork/, so the build is trunk's toolchain); the LLVM build
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
`NDEBUG`), every file_test golden, the conformance runner's programs, prek.
Not covered (README "Does not reproduce"): LLVM's own assertions (the CMake
LLVM is Release), gtest unit tests, lit tests, fuzzers, install_test.py,
clang_runtimes_test and every other Bazel-only target, the opt-mode
conformance toolchain, clang-tidy, macOS, Windows, ASan and other platforms.
R33 (b) owes R21's hosted gate on everything landed under R33 when Actions
returns.

### §0.10 The id re-scan

`git grep -E 'W-3[6-9][0-9]'` over fork/ of 168 refs (every origin ref and
local branch, after `git fetch origin`) and `grep -r` over the fork/ of the 23
worktrees: W-360 to W-366 are in use (W-364 reserved unused by OV-4; W-365 and
W-366 SAFE-3's); W-367 appears only as plan text on
claude/carbon-fork-0-1-safe and claude/carbon-fork-0-1-safe-wip
(fork/safe/safe3-plan.md, "so W-367 stays free"), never as an item; W-398 and
W-399 appear only as range bounds in five plans' text; W-368 to W-397 appear
nowhere. W-357 to W-359 are RG-1's and W-364 OV-4's, reserved unused. The next
free id is W-367 (D-LAND-13).

### §0.11 Stacked PRs and GitHub's merged state

GitHub marks a PR merged when a push to its base branch makes the PR's head
commit reachable from that branch; a merge commit of the head into trunk does
so for a PR whose base is trunk. PR 64's base is claude/carbon-fork-0-1-tp and
PR 65's claude/carbon-fork-0-1-dr (section 0.1), so a push of trunk that
contains their heads does not reach their bases. The safe order, which holds
whichever way GitHub treats a later retarget: the parent lands and is pushed
and the API shows it merged; the child's base is then changed to trunk
(`update_pull_request` with `base: trunk`), so its diff shows its own commits;
the child lands and is pushed; the API shows it merged. Not measured: whether
GitHub marks a PR merged when it is retargeted to a base that already contains
its head; the order above never relies on it, and the first landing (PR 67,
base trunk) measures the plain case (D-LAND-11).

### §0.12 Disk

`df -h /home/user`: 3.7 GB available; /dev/shm: 16 GB tmpfs, 0 used before the
dry run. The landing build directory is 159 MB and builds in place; a
conformance output directory is about 2 MB (the mall's 1.8 MB) and the
runtimes cache 8.7 MB. No build directory is copied. The dry run's worktree
(74 MB) is removed after the plan's commit.

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
again here. _Break condition:_ a landing whose gate or conformance fails
because a gated PR is absent, or a review that finds a ready PR incorrect
without a gated PR; that landing stops (D-LAND-10) and the order is re-planned.

**D-LAND-2, PR 59 and PR 66 are gated.** R33 (c): "a PR that is not yet
correct, one with an owed fix ... is not merged until it is". Trunk's Next
actions item 13 owes PR 59 a fix "under its own review" for an abort where
trunk diagnoses, and note 7's defect A is a second abort on VA-1's own forms
awaiting a ruling (section 0.2); the fork has treated such an abort as a defect
fixed at the root before a PR is held (TP-1's X-1, row :1104). PR 66 contains
PR 59's commits and carries both. _Break condition:_ the orchestrator rules,
with the evidence on record, that item 13 is not a defect of PR 59 (for
example, that upstream's own toolchain at its tip aborts the same way), and
records why in ORCHESTRATION; PR 59 then lands as G-59 describes without the
fix.

**D-LAND-3, land-time commits are made on trunk.** Each plan's land-time
merge of trunk into its branch (M, M-a, M-b, the integration commits) becomes
the trunk-side merge commit of the PR's head, whose tree is the same; its
compositions, refills and records become trunk-side commits after the merge,
with the plan's texts. No commit is added to a ready PR's branch, so no held
branch is pushed by LAND-1 and every PR's history is untouched (AGENTS.md).
_Break condition:_ a plan step that only its branch can carry (none found).

**D-LAND-4, steps that compose with a gated PR move to its follow-on.** A
ready PR's land-time step whose object is a gated PR's code, page or golden is
not made at the ready PR's landing; it becomes a land-time step of the gated
PR's follow-on, with the same text (section 3, G-53 to G-59/66). The moved
steps: TP-1's S (over SC-1) to G-60; OV-4's SC-1 arguments in M to G-60 and
its VA-1 gate rule to G-59; SV-1's M-VA and W-284 to G-59, its Doc-M
(optional.md) and the PR 57 part of F-M to G-56/57; CT-1's S-VA with C.11's
split to G-59; DR-1's loops.md rule in M-a to G-56 and L-a's m57 refills to
G-57; DD-1's state-L texts for PR 53, PR 56 and SC-1 to their follow-ons; ST-1's
SAFE-1 reconciliation edits to G-53; RG-1's land-time notes for PR 57 and PR 59
to G-57 and G-59, with W-343's discharge (D-LAND-15). _Break condition:_ a
moved step whose absence makes a ready landing's gate fail (D-LAND-1's).

**D-LAND-5, the merge rules.** Measured on the dry run and applied by the
implementer by hand, the saved files in `$X` being the reference:

-   OR-1: ORCHESTRATION's header region takes trunk's side; the records commit
    restamps the header.
-   OR-2: Branches rows are merged row by row by their first cell; a row both
    sides changed takes trunk's; the records commit rewrites the landed row.
-   OR-3: dated paragraphs inserted on both sides are both kept, in date
    order, the PR's first on the same date (it predates trunk's stamp of it).
-   OR-4: a region both sides edited takes trunk's side (the newer
    orchestrator text); the region report lists the PR side's words trunk
    lacks, and the records commit carries any that still hold.
-   DL-1: decision-log entries inserted at one point are both kept, trunk's
    first, in the log's workstream grouping. DL-3: RG-1's entry goes before
    LD-0 (D-RG-14 places it after DR-0 and DR-1; LD-0 is the newest), and
    DR-1's, at PR 63, goes directly after DR-0's.
-   GA-1: gap rows merge row by row; a row both sides changed keeps both
    edits when they are disjoint. GA-2: header and prose edited on both sides
    take trunk's side in the merge, and the records commit writes the PR's
    sentence and the tally recomputed from the rows ($P/bin/gaptally.py).
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
with head H (section 2's subsection gives N's specifics):

1.  `git fetch origin`; confirm `git ls-remote origin` shows H for PR N's
    branch (a moved head stops the landing) and trunk where the last push
    left it.
2.  `git checkout trunk && git pull --ff-only`.
3.  `git merge --no-ff --no-commit H`; resolve each conflicted file by
    D-LAND-5, comparing with `$X/pr<N>/files/`; then
    `git diff --name-only --diff-filter=U` is empty; `git add` each resolved
    path by name (R20).
4.  `$CB/build.sh /home/user/carbon-trunk` and `$CB/install.sh
    /home/user/carbon-trunk`; `$CB/gate.sh /home/user/carbon-trunk`;
    `XDG_CACHE_HOME=/home/user/carbon-build/carbon-trunk/cache
    $CB/conformance.sh /home/user/carbon-trunk <out>` with `<out>` under
    `scratchpad/land1/impl/pr<N>/`.
5.  Commit the merge with Appendix A.1's message, the results of step 4 in it.
6.  The plan's land-time code commits, if section 2 lists any, each built and
    gated.
7.  Refill: if the gate reports "Autoupdate would make changes", run
    `$CB/autoupdate.sh /home/user/carbon-trunk <files>` on exactly those
    files, gate again (every golden passes) and commit Appendix A.2's refill
    commit (D-LAND-8). A gate failure of any other kind stops the landing.
8.  Conformance again if steps 6 or 7 changed a program or the toolchain;
    compare `scoreboard.json` with the previous landing's: no program leaves
    PASS, and every new PASS is recorded.
9.  The records commit (D-LAND-9), then prek on every file the landing changed
    to a fixpoint, the model-identifier grep of `git diff <trunk before>..HEAD`,
    `json.load` of the ledger, `runner.py --self-test`, and R31's counts of each
    markdown file the records commit edits, before and after.
10. The review (D-LAND-10); then the push (D-LAND-11).

Every commit: `--author='jmann345 <jerrymannstan@gmail.com>'`,
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`, a new
commit (never an amend, rebase or force-push), explicit paths only, the
message ending after a blank line with the session's two trailers. _Break
condition:_ none; the procedure is the rule's.

**D-LAND-7, verification and the baseline.** Before PR 67, stage 0 runs step
4 on trunk bb9fbba9c itself: expected 1942 of 1942 and 128/0/22 over 150 with
48 bullets, as the README's validation measured on 0bdce60a5, whose toolchain
is trunk's (section 0.9). Every landing then runs the whole arbiter, records-
only ones included (about 5 minutes), so every record has the same form.
Results are labelled container-measured, not of record (R33 (b), R9). _Break
condition:_ the baseline differs from that expectation; LAND-1 stops before PR
67 and the difference is the first finding.

**D-LAND-8, refills.** Only `autoupdate.sh` writes CHECK lines (R16), on the
files the gate names, to its fixpoint, in a commit of its own whose message
names each file and which PRs' changes combined in it; a refill that changes a
line other than a CHECK line, or a golden no merged PR or plan explains, stops
the landing. _Break condition:_ none.

**D-LAND-9, the records commit** ("Land PR N: records") writes Appendix A.3's
row, A.4's dated paragraph and header, A.5's Landed paragraph in the PR's plan,
A.6's decision-log sentence, the plan's own land-time records texts that
apply (section 2), the gap header recomputed when GA-2 kept trunk's, and, for
every step moved to a follow-on, one sentence in the follow-on's Next actions
item naming it. _Break condition:_ a plan's land-time text that contradicts
the merged trunk; the records commit states the measured fact and cites the
plan's line (R17), never the stale text.

**D-LAND-10, the review and stop-and-amend.** One fresh agent reviews each
landing before its push: the merge commit's diff against both parents (which
is only the conflict resolution against the PR's side), the code commits, the
gate and conformance logs, the refill commit and the records commit, against
this plan and the PR's plan. A BLOCKER or MAJOR, a gate failure, a conformance
regression, an unanticipated conflict or a moved head stops the landing before
the push: the implementer returns the difference and the orchestrator rules. A
defect in the landing's own commits is fixed by a new commit on top, reviewed
again; a defect in the PR itself is fixed on the PR's branch by a new commit
under its own review, the unpushed landing is discarded (`git reset --hard
origin/trunk` in the landing worktree only, nothing pushed), and the merge is
redone on the new head. A landing once pushed is undone only by a revert
commit. _Break condition:_ none.

**D-LAND-11, the push and GitHub.** After a review with no BLOCKER or MAJOR:
`git push origin trunk` and `git push origin
trunk:claude/carbon-fork-0-1-7mwfb7`, both fast-forwards; then the API
(`pull_request_read`) must show PR N `merged: true`, else the landing's record
states the API's answer and the orchestrator rules. For PR 64 and PR 65, after
PR 61's and PR 63's pushes respectively, the orchestrator changes their base
to trunk before their landings (section 0.11). _Break condition:_ GitHub does
not mark PR 67 merged after its push; then every later landing re-measures the
rule before relying on it.

**D-LAND-12, the follow-ons.** Each gated PR lands by its own follow-on when
its gate is met, by LAND-1's procedure, in this order of preference: G-53 (PR
53) when SAFE-3 has completed (its realignment commits and reviews dry, PR 53's
head pushed) and the realignment notes SAFE-3 owes PR 67 are on trunk's
ledger, since PR 67 has landed; G-60 (PR 60) when W-139's fix commit is on PR
60's branch under SC-1's reviews and item 10 is decided; G-56/57 (PR 56, then
PR 57) when W-352's commit is on PR 56's branch, merged into PR 57's, under
OP-1's reviews, and item 10 is decided; G-59/66 (PR 59, then PR 66) when item
13's fix (W-367) and note 7's ruling are on PR 59's branch under VA-1's review
and VA-2's item 2 preconditions hold. A follow-on whose merge carries code
compositions (G-60, G-56/57, G-59/66) first merges trunk into its own branch (a
new merge commit, never a rebase) with the moved steps, fills and gates them
under its own reviews and pushes, so its trunk landing is records-only. No
follow-on waits on another except PR 57 on PR 56 and PR 66 on PR 59. _Break
condition:_ a follow-on's plan that requires a different order; the
orchestrator rules and this plan is amended.

**D-LAND-13, ids.** LAND-1 takes W-367 to W-370 from the re-scan: W-367 for
item 13's abort (filed by G-59 with PR 59's fix, owner VA-1's follow-on),
W-368 for note 7's defect A if the ruling makes it a PR 59 fix (otherwise
unused), W-369 and W-370 for a residue a landing finds (otherwise unused). The
orchestrator's stamp of this plan records the reservation, so SAFE-3, whose
plan text keeps W-367 free, takes W-371 onward. _Break condition:_ any of
W-367 to W-370 filed elsewhere first; LAND-1 then takes the next free id after
a re-scan.

**D-LAND-14, DD-1's state L in part.** DD-1's section 2.13 applies "after
merging trunk with every held PR on it". At PR 58's landing the state-L texts
for PR 51, PR 54 and PR 55 are made ("on held PR 54" and the rest lose their
"held"), and those for PR 53 (assignment.md, threads_and_atomics.md), PR 56
(the interop pointer to optional.md) and SC-1 (template_constraints.md) are
made by G-53, G-56 and G-60; until then their state-T texts, which name the
held PRs, stay true, and row 91 stays PARTIAL. _Break condition:_ a state-L
text that cannot be split by PR; it then waits whole for the last follow-on.

**D-LAND-15, W-343.** RG-1 narrowed W-343 to five land-time notes, discharged
by the last (rg1-plan.md:500-504). PR 51's, PR 54's and PR 58's are made now;
PR 57's and PR 59's by G-57 and G-59, and whichever lands last discharges
W-343. _Break condition:_ a follow-on abandoned; the orchestrator's stamp then
discharges W-343 by RG-1's own break condition (:504-506).

**D-LAND-16, the orchestrator's steps.** Before stage 0: sign-off of this
plan by its reviews, then the stamp of Appendix B.1. Per landing: the API
checks and retargets of D-LAND-11, the PR's description given a "Landed" line
from the records commit's texts, and ORCHESTRATION's header naming the count.
After the twelfth: Appendix B.2's stamp, "12 PRs landed, 6 held". _Break
condition:_ none.

## §2 Spec, per landing

Each subsection gives the head, the base, the files, the conflicts and rules
from the dry run, the steps, the expected scoreboard after the landing and the
texts' fields for Appendix A. "Static" counts are section 0.8's.

### §2.1 PR 67, RG-1

Head 56e2e5bbd, base trunk; 8 records files. Conflicts: ORCHESTRATION (OR-1,
OR-2 twice, OR-3, OR-4) and decision-log (DL-3: RG-1's entry, then LD-0).
Steps: merge; no land-time step of its own (RG-1's A.4 notes are the later
PRs'). Expected: 1942 of 1942; 128/0/22 over 150. Title "Land PR 67: RG-1,
the V-3a register classified against upstream". Row: RG-1, "records only;
W-342 and W-344 discharged, W-343 narrowed to the land-time notes (D-LAND-15),
W-346 to W-356 filed". Deferred: none. Next: PR 64's and PR 65's bases are
unaffected.

### §2.2 PR 51, UA-2

Head f96fe8a7a (the container fill), base trunk. Conflicts: gap-analysis
(GA-1, the Slices row keeps trunk's DR-0 sentence and UA-2's W-108 narrowing),
ledger (LG-1, 14 decisions). Steps: merge; records with RG-1's UA-2 land-time
note after its decision-log block (rg1-plan.md:2533-2542, `<tip>` the upstream
tip at which `fork/register/check_quotes.sh` and `check_greps.sh` pass on the
landing day). Expected: 1945 of 1945 (its own gate); 131/0/19 over 150. Title
"Land PR 51: UA-2, upstream reconciliation". Deferred: none (TP-1's rename of
its split is PR 61's F6).

### §2.3 PR 52, CM-1

Head e6bc32a6d, base trunk; cmake/ and examples/cmake/ (19 files). Conflicts:
ORCHESTRATION (OR-1, OR-2, OR-4), decision-log (DL-1), ledger (LG-1). Steps:
merge; the gate runs unchanged goldens; conformance runs the BUILD-SCRIPT
programs (examples/cmake/test.sh). Expected: 1945 of 1945 (trunk's 1942 and
PR 51's three); 133/0/17 over 150;
gap tally 32/20/3/1. Title "Land PR 52: CM-1, CMake language modules,
examples/cmake and Make documentation". Deferred: none.

### §2.4 PR 54, EV-1

Head cb3ef2e74, base trunk. Conflicts: ORCHESTRATION (OR-1 to OR-4),
decision-log (DL-1), gap-analysis (GA-1 on row 90, GA-2 on the header, the
back-half sentence and section W11), ledger (LG-1, LG-3 on W-002 and W-003:
CM-1's note then EV-1's). Steps: merge; then EV-1's state C commit "Land PR
54: EV-1 integration with PR 52 (state C)" with the content of
fork/evaluator/plan.md section 3 item 6 (:1830-1842): the C++-library
program's two-line un-SKIP, `evaluator_samples_self_check()` in runner.py's
`--self-test`, the build_systems.md links and the W-131 and W-133 citations,
row 90 and the header in their state C texts (the tally 33/19/3/1), W-131's and
W-133's notes; then records with RG-1's EV-1 note (rg1-plan.md:2544-2550).
Expected: 1945 of 1945; 143/0/16 over 159 after state C (static 142/0/17 at the
merge). Title "Land PR 54: EV-1, evaluator documentation". Deferred: none.

### §2.5 PR 55, ST-1

Head c3cdecc5d, base trunk; one toolchain file and one prelude file.
Conflicts: ORCHESTRATION (OR-1, OR-2, OR-4 twice), decision-log (DL-1),
gap-analysis (GA-1 twice, GA-2 on the header), ledger (LG-1). Steps: merge;
build, gate (a prelude change); refill only what the gate names; records with
the header tally 34/18/3/1 and W-126 cited by id (PR 51 has landed, as ST-1's
landed notes assumed, :3107-3109). Expected: 1950 of 1950 on its branch plus
any merged goldens; 148/0/15 over 163. Title "Land PR 55: ST-1, str
comparison, Core.StringBuf and concatenation". Deferred to G-53: W-144's
additions and the seven SAFE-1 reconciliation edits (:3103-3106).

### §2.6 PR 58, DD-1

Head fcee90d9b, base trunk; 20 programs, 11 pages, 74 records and sample
files. Conflicts: ORCHESTRATION (OR-1 to OR-4), fork/conformance/README.md
(README-1, 182 programs), decision-log (DL-1), gap-analysis (GA-1, GA-2
three times), ledger (LG-1 to LG-6; W-043 and W-065 both edited). Steps:
merge; the state-L commit "Land PR 58: DD-1 state L for PR 51, PR 54 and PR
55" with section 2.13's held-PR citation edits for those three and the EV-1
sentences (:4185-4192 and the EV-1 items), checked by
fork/designdocs/check_samples.py; records with RG-1's DD-1 note
(rg1-plan.md:2562-2570), the header tally 35/17/3/1, and a dated note on
W-043 that the SKIP its DD-1 sentence calls stale was removed by PR 51.
Expected: 1942 of 1942 plus merged goldens; 167/0/15 over 182. Title "Land PR
58: DD-1, design docs without placeholders". Deferred: state L for PR 53, PR
56 and SC-1 (D-LAND-14).

### §2.7 PR 61, TP-1

Head 66aa13132, base trunk; 32 toolchain files, 25 goldens. Conflicts:
ORCHESTRATION (OR-3, OR-4), README-1 (192 programs), gap-analysis (GA-2),
ledger (LG-1, W-014 both edited). Steps: merge (TP-1's M, "M resolves
conflicts only", fork/templates/plan.md:5192-5205); F6 as the refill: PR 51's
`fail_todo_unformed_dependent_var` split renamed `unformed_dependent_var` (a
rename commit before the autoupdate, the only non-CHECK edit, as F6 specifies)
and every golden the gate names; L "TP-1: integration with PR 58" with
Appendix C's texts (:16086 on) over PR 58's pages, as "Land PR 61: TP-1
integration with PR 58"; records with R's row and D's ledger texts that apply
(:5302-5312). Expected: 1957 of 1957 on its branch plus merged goldens;
177/0/15 over 192. Title "Land PR 61: TP-1, integrated templates". Deferred
to G-60: S (member_access.cpp, :5206-5212); to G-59: the VA-1 compositions F6
measured as none.

### §2.8 PR 62, SV-1

Head 0ef8a0334, base trunk; 12 toolchain files, 2 prelude files. Conflicts:
ORCHESTRATION (OR-1 to OR-4), gap-analysis (GA-2), ledger (LG-1). Steps:
merge (SV-1's M, records "take trunk's text"); F-M for its own goldens
(stdlib/optional.carbon, choice/optional_pointer_payload.carbon,
match/core_optional_view.carbon if the gate names them); records with W-282's
check: x19 compiled on the merged trunk, W-282 filed with Appendix C.4's text
only if it stops there (predicted unused: TP-1's round-10 fix is on trunk).
Expected: 1950 of 1950 plus merged goldens; 182/0/15 over 197. Title "Land PR
62: SV-1, std::optional and std::variant interop mapping". Deferred to G-59:
M-VA and W-284's filing; to G-56/57: Doc-M (optional.md) and F-M's PR 57 part.

### §2.9 PR 64, CT-1

Head 551a03328, base claude/carbon-fork-0-1-tp, retargeted to trunk after PR
61's push. Conflicts: ORCHESTRATION (OR-3, OR-4), README-1 (204 programs),
PROG-1 on the two programs (PR 51's header with C.6's paragraph appended,
`<YYYY-MM-DD>` the landing date, and CT-1's body, `var b: Cpp.Box(T);`),
decision-log (DL-1), gap-analysis (GA-2 twice), ledger (LG-7: W-043 "taken
from DD-1's side whole", CT-1's discharge reapplied by the records commit,
fork/cpp-templates/plan.md:2730-2737). Steps: merge; L-F refills (C-2's
fallback: the rename is PR 61's); L "Land PR 64: CT-1 interoperability page
and fixture X37 over PR 58" (C.1, checked by check_samples.py with
`--toolchain`); records: rows 56 and 42 by bullet text (C.4), C.2's discharge
over DD-1's W-043, W-127's sentence (C.10), the id re-scan. Expected: 1959 of
1959 plus merged goldens; 189/0/15 over 204. Title "Land PR 64: CT-1, C++
templates on symbolic Carbon type arguments". Deferred to G-59: S-VA and
C.11's split.

### §2.10 PR 63, DR-1a

Head 89aabd125, base trunk. Conflicts: ORCHESTRATION (OR-2, OR-4), decision-log
(DL-3: DR-1's entry directly after DR-0's), gap-analysis (GA-1), ledger (LG-1),
TC-1 (handle_loop_statement.cpp: DR-1a's side, TP-1's `RequireCompleteType`
block and its `#include "toolchain/check/type_completion.h"` dropped; the result
equals 89aabd125's file), GOLD-1 (range_for.carbon, 25 CHECK regions). Steps:
merge (M-a); L-a as the refill: check generic/template/for_range, lower
template/for_range and interop/cpp/range_for, its count recorded at L-a
(fork/direction/plan.md:1555-1582); records. Expected: 1942 of 1942 on its
branch plus merged goldens; 189/0/15 over 204. Title "Land PR 63: DR-1a,
Core.Iterate.Next takes a ref cursor". Deferred to G-56: loops.md's rule; to
G-57: the m57 refills (lower array/iterate, for/break_continue, for/for).

### §2.11 PR 65, DR-1b

Head fee0ef31c, base claude/carbon-fork-0-1-dr, retargeted to trunk after PR
63's push. Conflicts: ORCHESTRATION (OR-2), README-1 (206 programs),
gap-analysis (GA-2), ledger (LG-1, LG-6 on the source header), TC-2
(handle_index.cpp: DR-1b's side with TP-1's `SemIR::LocId loc_id` parameter
and the default arm's `return elem_id;`, by $P/bin/resolve65.py), GOLD-1
(string_indexing.carbon, trunk's side). Steps: merge (M-b); C-b, "Land PR 65:
DR-1b composition with TP-1: a template-dependent index chooses its interface
per specific", the block of fork/direction/plan.md:2204-2225 at the head of
`PerformIndex`'s default arm; L-b refills (check generic/template/index,
slice/write_through with `fail_todo_template_index_with_only` renamed
`template_index_with_only`, string_indexing 2/2); records discharging W-340
with M-b's, C-b's and L-b's shas (C.2), gap row 79's W-340 sentence in the
past tense (C.3), and the DR-1 entry's dated note. The probes t10, t15, t16,
t18 print 7, 8, 9 and 6, and n06, n15, n32, n13 and a4 print 8, 5, 7, "3 7"
and 9 (:1602-1612). Expected: 1946 of 1946 plus merged goldens; 191/0/15 over
206. Title "Land PR 65: DR-1b, subscripting prefers IndirectIndexWith".
Deferred: none.

### §2.12 PR 68, OV-4

Head 097c76473, base trunk. Conflicts: ORCHESTRATION (OR-1 to OR-4), ledger
(LG-1). Steps: merge (M; with PR 59, PR 60 and PR 66 not landed, the message's
handle_function.cpp and merge.cpp sentences do not apply and the merge has no
toolchain conflict); F-M if the gate names an OV-4 golden (predicted none);
L-R: Appendix D.6's rows T2.8 and T2.9 inserted after T2.7 in
fork/register/rg1-plan.md, its checks and quotes appended to rg1-checks.tsv
and rg1-quotes.tsv, checked at upstream's tip by check_greps.sh and
check_quotes.sh (`<tip>`, `<n>` and `<m>` measured), R31's counts of
rg1-plan.md showing two table rows more; L: D.7's texts. Expected: 1946 of
1946 plus merged goldens; 193/0/15 over 208. Title "Land PR 68: OV-4,
`overload fn` members with default parameter values". Deferred to G-60: SC-1's
two arguments in `CheckOverloadMemberParamsMatch`; to G-59: the pack gate
order in handle_function.cpp.

## §3 The process

The implementation workflow runs one stage per landing, in order, each
stopping on D-LAND-10: stage 0 (the baseline, D-LAND-7), stages 1 to 12 (PR
67, 51, 52, 54, 55, 58, 61, 62, 64, 63, 65, 68), each: the procedure of
D-LAND-6, one fresh reviewer, a fixer only for the landing's own commits
(never for a PR's code, which goes back to its branch), the push, the API
check, and for stages 9 and 11 the retarget first. The implementer writes no
ORCHESTRATION stamp beyond each records commit's row, paragraph and header.

The follow-ons, each its own workstream with its own reviews, entered when
D-LAND-12's gate holds:

-   G-53 (PR 53): records-only merge (section 0.6); land-time: ST-1's SAFE-1
    edits, DD-1's state L for PR 53, RG-1's H53 notes already on the head,
    SAFE-3's notes on trunk's ledger.
-   G-60 (PR 60): merge of trunk into PR 60's branch resolving convert.cpp,
    member_access.cpp, merge.cpp and templates.md, with TP-1's S, OV-4's two
    arguments, DD-1's state L for SC-1, item 10's decided commit, fills, gate,
    its review; then the trunk landing.
-   G-56/57 (PR 56, then PR 57 retargeted to trunk): W-352; loops.md by M-a's
    rule and C.7; error_handling.md by DD-1's and OP-1's texts; DR-1a's m57
    refills; SV-1's Doc-M and F-M part; DD-1's state L for PR 56; RG-1's OP-2
    note.
-   G-59/66 (PR 59, then PR 66 retargeted to trunk): W-367's fix and note 7's
    ruling on PR 59; handle_function.cpp by OV-4's rule; SV-1's M-VA and
    W-284; CT-1's S-VA and C.11's split; RG-1's VA-1 note and W-343's
    discharge if it is the last; then VA-2's own M, S-CT, F-M, L-F and L
    (va2-plan.md section 3 item 15) over convert.cpp, eval.cpp and
    handle_function.cpp.

## §4 Scoreboard progression

Static expectation (section 0.8), PASS / FAIL / SKIP over programs, after each
landing's land-time commits. The gate column is the merged tree's golden count:
the `.carbon` files under the eight testdata directories gate.sh runs, plus two
(`git ls-tree` of each scratch merge; the rule reproduces the logged gate counts
of trunk 1942, PR 51 1945, PR 61 1957, PR 64 1959, PR 63 1942, PR 65 1946 and PR
68 1946 on their own heads). Every one of them must pass.

| After | Programs | PASS / FAIL / SKIP | Gap tally | Gate (merged) |
| --- | --- | --- | --- | --- |
| trunk (baseline) | 150 | 128 / 0 / 22 | 30/21/4/1 | 1942 |
| PR 67 | 150 | 128 / 0 / 22 | 30/21/4/1 | 1942 |
| PR 51 | 150 | 131 / 0 / 19 | 30/21/4/1 | 1945 |
| PR 52 | 150 | 133 / 0 / 17 | 32/20/3/1 | 1945 |
| PR 54 | 159 | 143 / 0 / 16 | 33/19/3/1 | 1945 |
| PR 55 | 163 | 148 / 0 / 15 | 34/18/3/1 | 1953 |
| PR 58 | 182 | 167 / 0 / 15 | 35/17/3/1 | 1953 |
| PR 61 | 192 | 177 / 0 / 15 | 35/17/3/1 | 1968 |
| PR 62 | 197 | 182 / 0 / 15 | 35/17/3/1 | 1976 |
| PR 64 | 204 | 189 / 0 / 15 | 35/17/3/1 | 1978 |
| PR 63 | 204 | 189 / 0 / 15 | 35/17/3/1 | 1978 |
| PR 65 | 206 | 191 / 0 / 15 | 35/17/3/1 | 1982 |
| PR 68 | 208 | 193 / 0 / 15 | 35/17/3/1 | 1986 |

The arbiter's counts replace these in each record; a PASS that turns FAIL is a
regression and stops the landing. The merged gate count is the number of
testdata files on the merged trunk, measured by `gate.sh`.

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
-   R-5, the scratch references go stale. A head that moves after this plan
    invalidates `$X/pr<N>`. Falsifier: step 1's head check; the landing is
    re-dry-run.
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

## §6 Verification and what is not run

Planner, measured: `git ls-remote origin` and the API listing; every
merge-tree of section 0.4; the twelve-step dry run with `--self-test`,
`json.load` and the model-identifier grep at every step; the follow-on
merge-trees; the id re-scan; the arbiter's paths and logs; `df`. Not run by
the planner, by rule: any build, gate, autoupdate or conformance run; the
merged trees' compilation (the TC-1 and TC-2 files are mechanical references,
built first by stage 10 and stage 11). Not run by LAND-1 at all: clang-tidy,
the Bazel-only tests, LLVM with assertions, macOS, Windows and other
platforms, and R21's hosted gate, which R33 (b) owes when Actions returns.

## Hand-off notes

1.  The saved files in `$X/pr<N>/files/` are references for the resolution,
    not inputs to copy blindly: the PR 64 ledger's W-043 is set to trunk's
    side by LG-7, and PR 63's range_for and PR 65's string_indexing hold
    trunk's CHECK lines until the refill.
2.  Run `$P/bin/gaptally.py fork/gap-analysis.md` in each records commit and
    write the header from it.
3.  The google-doc-style hook rewrites some words inside code spans; check
    every records text after prek and restore code by hand (SAFE-1's hand-off
    note 4).
4.  Keep the model-identifier patterns in $P/model_ids.txt, never in the
    repository.
5.  /home/user/carbon-trunk's local trunk is behind origin by records-only
    commits; stage 0's `git pull --ff-only` brings it to bb9fbba9c or later.

## Appendix A: the per-landing record templates

Fields come from section 2 and the landing's measurements.

### A.1 The merge commit's message

<!-- google-doc-style-ignore -->

```text
Land PR <N>: <workstream>, <title from section 2>

Merges claude/carbon-fork-0-1-<suffix> at <head> (PR <N>, base <base>)
into trunk <trunk before> under R33, as fork/land/land1-plan.md section
2.<k> specifies.

Conflicts and rules: <file> (<regions>, <rule>); ... (none outside the
records files | <the plan's rule for each non-records file>).

Container-measured on the merge's tree (R33 (b)): build <ok>; gate <g>
of <total> (<the files autoupdate would change, for the refill commit>);
conformance <p>/<f>/<s> over <n>, bullets <b> of 56.

<trailers>
```

### A.2 The refill commit's message

```text
Land PR <N>: goldens refilled after the merge

Autoupdate (carbonbuild autoupdate.sh, R16) on <k> files the merged
toolchain changes: <file> (<PRs whose changes combine>); ... CHECK lines
only. Gate after: <g> of <g>.

<trailers>
```

### A.3 The Branches row

```text
| `claude/carbon-fork-0-1-<suffix>` | LANDED as PR <N> by merge <merge sha> (<date>, LAND-1, R33) — <workstream summary from the old row>; land-time commits <shas or none>; container-measured, not of record: gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; moved to <G-xx>: <steps or none>; R21's hosted gate owed when Actions returns. |
```

### A.4 The dated paragraph and the header

```text
<date> (<hh:mm> UTC): PR <N> (<workstream>) LANDED on trunk by merge
<merge sha> under R33 (fork/land/land1-plan.md section 2.<k>), verified in
the container: gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56
bullets; <landed count> PRs landed, <held count> held. Next: <next PR or
follow-on>.
```

The header's first clause becomes "Last updated: <date> (PR <N> landed by
LAND-1; <landed count> PRs landed, <held count> held; see the paragraph dated
<date> (<hh:mm> UTC) below; the earlier <date> text follows)."

### A.5 The Landed paragraph in the PR's plan

```text
Landed on trunk (LAND-1, <date>): merged as PR <N> by <merge sha> (head
<head>, trunk before <trunk before>) under R33, fork/land/land1-plan.md
section 2.<k>; land-time commits <shas>; refill <sha or none>;
container-measured, not of record (R33 (b)): gate <g> of <g>, conformance
<p> PASS, <f> FAIL, <s> SKIP over <n>, <b> of 56 bullets; moved to
<G-xx>: <steps or none>.
```

It is appended to the plan's "Landed notes" section; PR 67's and PR 68's
plans take it after their last section.

### A.6 The decision-log sentence

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR <N> by
<merge sha>; container-measured: gate <g> of <g>, conformance
<p>/<f>/<s> over <n>; <moved steps, or "no step moved">.
```

It is the last paragraph of the PR's decision-log entry.

<!-- google-doc-style-resume -->

## Appendix B: the ORCHESTRATION stamps

<!-- google-doc-style-ignore -->

### B.1 At sign-off, before stage 0

```text
<date> (<hh:mm> UTC): LAND-1's plan (fork/land/land1-plan.md, rev <r>) is
signed off. Twelve PRs land in this order, each verified in the container
and reviewed before its push: PR 67, 51, 52, 54, 55, 58, 61, 62, 64, 63, 65
and 68. Six wait: PR 53 (SAFE-3), PR 60 (W-139 and item 10), PR 56 and PR 57
(W-352 and item 10), and PR 59 with PR 66 (item 13's fix, W-367, and note
7's ruling, D-LAND-2). W-367 to W-370 are reserved to LAND-1. Eighteen PRs
are held open; none is merged yet.
```

### B.2 After the twelfth landing

```text
<date> (<hh:mm> UTC): LAND-1 stages 1 to 12 are done: 12 PRs landed, 6
held. Trunk <trunk sha> holds PR 67, 51, 52, 54, 55, 58, 61, 62, 64, 63, 65
and 68, verified in the container at each landing (final: gate <g> of <g>,
conformance <p>/<f>/<s> over <n>, <b>/56 bullets; gap tally 35/17/3/1);
R21's hosted gate is owed on all twelve when Actions returns (R33 (b)).
Held: PR 53 (G-53), PR 60 (G-60), PR 56 and PR 57 (G-56/57), PR 59 and PR
66 (G-59/66), each landing by LAND-1's procedure when its gate holds.
```

<!-- google-doc-style-resume -->
