<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# EH-C plan: `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346)

**Status:** rev 3, 2026-11-09 -- SIGNED OFF FOR IMPLEMENTATION. Rev 3 folds the
focused re-review RR1 of rev 2 (51013a4a6; APPROVE-WITH-AMENDMENTS: no BLOCKER,
two MAJORs, five MINORs, all seven folded, none rejected; see "Review fold
record (rev 3, 2026-11-09)" and the "Sign-off" section, both before Appendix A).
Rev 2 (2026-11-09) folded reviews A and B, 17 findings (the section "Review fold
record (rev 2, 2026-11-09)"). Rev 1 was written 2026-11-09 for two adversarial
plan reviews. Branch `claude/carbon-fork-0-1-ehc` (worktree
/home/user/carbon-ehc), cut from trunk aee70185c (2026-11-09, "Weekly upstream
check 2026-11-09: review fold"; pushed; no commits of its own before this plan);
trunk moved to fca1e9e2f while the reviews ran (the paragraph after this one).
Trunk's toolchain, prelude and testdata equal the merge a725dddca's: `git diff
--stat a725dddca aee70185c -- toolchain core` is empty, so the container
arbiter's install /home/user/arb/install/cb726a230/bin/carbon (built from
cb726a230, whose toolchain sources equal trunk's; `carbon version` prints
0.0.0-0.dev+unknown, the Bazel-equivalent build being unstamped) is the baseline
for every probe below. Baseline, container-measured on 2026-11-09: **gate 2047
passed, 0 failed** (/home/user/arb/logs/gate-cb726a230- 20261109T163748Z.log,
with the arbiter's check.cpp source patch applied, see §0.1) and **conformance
PASS 228 / FAIL 0 / SKIP 13 over 241, 51 of 56 bullets**
(/home/user/arb/logs/conformance-cb726a230.log). This is the error-handling
workstream's third slice; fork/eh/plan.md (EH-A and EH-B, 2026-09-27) is its
parent, as fork/overload/ov4-plan.md sits beside fork/overload/plan.md. **The
spec is W-346** (fork/inventory/work-items.json): rename `Core.Result(T, E)`'s
alternatives `Ok`/`Err` to upstream's `Success`/`Failure`, with every use, after
the held PRs land and before UA-3. Size: the ledger's M (RG-1's estimate; a
mechanical rename with a fix budget of two would be S by this plan's count, but
the ledger's field is kept unchanged, D.1; amended 2026-11-09, review fold: A-m3
(d) / B-m5). This plan was written once before (2026-11-06, cc2d3a623 on the
previous container, lost before it was pushed); §0.8 says what this rev keeps of
it and where it differs.

**Trunk moved while the reviews ran (amended 2026-11-09, review fold: B-m4 /
A-m3 (e)).** Trunk is fca1e9e2f ("Land PR 69: ARB-2, construct UnitAndImports in
place (its emitter points into itself)", the merge of
claude/carbon-fork-0-1-arb2 at b87f130b2 into aee70185c, committed
2026-11-09T18:14Z; `git ls-remote origin trunk`, origin/trunk and
/home/user/carbon-trunk agree). Against aee70185c PR 69 changes four files:
toolchain/check/check.cpp (the fix the arbiter's source patch carries; trunk's
file equals aee70185c's plus the patch but for a five-line comment, so the
arbiter's `patch --forward` reports the patch `landed` on that tree, as its
builds of 6de18c1f7 and b87f130b2 did, and compiles the repository's file),
fork/inventory/work-items.json (W-378, ARB-2's item, inserted after W-377; 310
items), fork/decision-log.md (the entry "ARB-2 (2026-11-09): ..." appended at
:20650 after CT-1's; no line before :20646 moves) and fork/ORCHESTRATION.md (the
header :10-17 and a dated paragraph of 2026-11-09 (17:41 UTC) at :2167; the
Branches table has no PR 69 row yet and the header still counts "17 PRs landed":
LAND-1's records commit for PR 69 is pending). No use site of this plan moves:
`git diff --stat a725dddca fca1e9e2f -- toolchain core` lists check.cpp only, so
cb726a230 plus the patch is still trunk's toolchain and every baseline figure
here stands. `git merge-tree --write-tree fca1e9e2f 7ea4ff096` (the rev 1
commit) exits 0 (tree 2a1e75aa9): the branch merges trunk clean. The rule
(D-EHC-12 and §3's M-0 paragraph): the implementation starts with M-0, `git
merge --no-ff origin/trunk` into the branch before C1, so that C1 to D sit on
trunk's records (W-380 after W-378) and on trunk's check.cpp (the gate's
src-patches line then prints `landed`); a land-time M (Appendix F.1) follows
only if trunk moves again.

**Item:** W-346 (R32 (d); RG-1, D-RG-5). **Reserved ids:** W-380 to W-385
(§0.7); W-380 filed, W-381 to W-385 unused. **No F id** (R32 makes upstream's
spelling the design's; F-006a is reversed by a dated note).

**Design authority:** fork/rulebook.md R32 (no direction drift; (d) a second
spelling of an upstream-designed mechanism is a drift) and R33 (the merge
directive); fork/decision-log.md DR-0 and V-3b (the override clause
withdrawn), RG-1's D-RG-5 (F-006a classified DRIFT at f27a977d8, re-checked at
e6fddcf97, with its break condition), the F-006 entry's sub-decision F-006a
(user, 2026-07-19, which this plan reverses under the owner directive of
2026-10-21, veto-able), and fork/eh/plan.md's D-EH-1 to D-EH-6, which stand.

## Sections

§0 Audit (measurements with evidence): 0.1 the use-site inventory at
aee70185c; 0.2 the baseline and nightly probes; 0.3 the prototype and its
mutants; 0.4 collisions with PR 53; 0.5 the conformance programs touched; 0.6
upstream's direction sources at ca1898506 and the register; 0.7 the id
re-scan; 0.8 the lost rev 1 and the task text, confirmed and corrected. §1
Design (D-EHC-1 to D-EHC-12). §2 Spec, file by file. §3 Commits, the PR and
the landing. §4 Testdata matrix. §5 Conformance delta. §6 Churn and
collisions. §7 Risks and rejected alternatives. §8 Verification. Hand-off
notes. The review fold records (rev 2, rev 3, the implementation reviews) and
the Sign-off. Appendix A the goldens' source edits; B the programs and their
EXPECTs; C the docs amendments verbatim; D the records texts verbatim; E the
PR text; F the land-time texts with `<...>` placeholders.

## §0 Audit

Every number below was measured on 2026-11-09 in the container: the baseline
install above, the upstream nightly
/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon
(a differential oracle only, R30; it has no `Core.Result`), and a prototype of
the rename built by the arbiter under the label `ehc-planner` from the detached
worktree /home/user/carbon-ehc-planner at aee70185c (removed when the plan was
committed, with the label's directories), re-run by the fold of 2026-11-09 as
the label `ehc-fixer` from /home/user/carbon-ehc-fixer at aee70185c with
D-EHC-13's renames and A-m1's lines (removed the same way); where a figure
below is the fixer's it says so. The arbiter compiles a patched copy
of toolchain/check/check.cpp (carbonbuild/src-patches/0001-check-unit-infos-
in-place.diff, ARB-2's R1-B1, unrelated to EH-C; every GATE line prints
`src-patches.applied`), so every gate figure here is "the tree at SHA plus
that patch", the same footing as the baseline's 2047. Probes and logs:
scratchpad/ehc/planner/ of this session (not in the repository).

### §0.1 The use-site inventory at aee70185c

The grep: `git grep -nE '\bOk\b|\bErr\b' aee70185c -- .` over the whole tree,
which matches `Ok(`, `.Ok`, `"Ok"`, `` `Ok` `` and the bare words, split by
whether the line is a golden CHECK line (`^\s*// CHECK`, indented ones
included) and classified by file. Unrelated words are excluded by the word
boundary (`ErrA`, `ErrB`, `ToErrB`, `ErrorInst`, `OkT` do not match) and by
reading each non-golden hit: the only English hit is
common/raw_hashtable.h:1314 ("// Ok, we've finished probing"), excluded.
Lowercase `ok`/`err` were grepped separately (`\b(ok|err)\b`) and classified
in D-EHC-4 and D-EHC-5.

| Class | Files | Lines | Where |
| --- | --- | --- | --- |
| Prelude | 1 | 9 | core/prelude/types/result.carbon :21-23 (the F-006a comment), :29-30 (the alternatives), :34, :44-45, :51 |
| Toolchain identifiers | 1 | 2 | toolchain/check/cpp/thunk.cpp:1506 `identifiers().Add("Ok")`, :1508 `("Err")` |
| Toolchain comments and names | 12 | 41 | thunk.cpp :1380, :1461-1462, :1510, :1525, :1538 (comments) and its `ok_*`/`err_*` locals :1502-1541; thunk.h:201; handle_choice.cpp:373, :376; handle_match.cpp:60, :62; pattern_match.cpp:1441; refutable_binding.cpp:564; lower/handle.cpp :356-363, :402, :413 (comments), :394-400 (IR names), :421 (the stderr message); lower/constant.cpp:450; lower/context.h :147-153, :214-216; lower/file_context.h :246-250; lower/function_context.h :374-381 (the `main.result.err.message` global) |
| Install header | 1 | 10 comment lines, 23 code lines | toolchain/install/include/carbon/expected.h :27, :46, :131, :145, :199, :201, :271, :276, :290, :296 (comments); `T ok; E err;` :154-155, :162, the `Payload` constructors :152-153, :161, `payload_.ok`/`.err` :214-254, :309-333, `static expected ok()` :291 |
| Golden sources | 35 | 350 | 22 check, 11 lower, 2 parse (Appendix A); 328 whole-word lines, 14 lowercase skeleton lines in the two export goldens, and 8 lines the fold added: the five split-name headers `unit_ok`/`i32_ok` and lower main_run/return_result.carbon's three comment lines that name the IR blocks, the message global and the split (amended 2026-11-09, review fold: A-m1 / B-M1) |
| Golden CHECK lines | 32 | 2871 written, 2863 removed by the fill | the files of §4; three of the 35 have no CHECK line that moves (the fixer's fill; the planner's 2862 written counted the same files before B-M1's split renames, which add 9 to each figure, and its "2858" followed a convention the plan did not state; amended 2026-11-09, review fold: A-m3 (f) / B-M1) |
| Program sources | 18 | 159 | 11 .carbon and 5 .diff.cpp under error_handling/, project/evaluator_tutorial_errors.carbon, control_flow/choice_payload_roundtrip_diff.carbon (Appendix B); two of them renamed with fork/conformance/README.md's two rows (D-EHC-13) |
| File and split names | 5 | 7 | fork/conformance/programs/error_handling/run_result_ok.carbon and run_result_err.carbon (§8.7's grep 2 over `git ls-files` lists exactly these two; the pattern is spelled once, in §8.7's list, because rumdl's MD011 rewrites it inside a table cell into rev 2's form with `[_.]` before the name, which lists nothing: the hook honors code spans in a list item, not in a cell; corrected 2026-11-09, review fold: RR1-m2) and the split names `unit_ok` (check main_run/return_result.carbon:23, check operators/question_result.carbon:98, lower main_run/return_result.carbon:24) and `i32_ok` (check main_run/return_result.carbon:32, lower main_run/return_result.carbon:36), which no whole-word grep sees; D-EHC-13 (row added 2026-11-09, review fold: B-M1) |
| Program EXPECTs | 0 | 0 | no EXPECT line names an alternative (§0.5) |
| Living docs | 5 | 38 | docs/design/README.md :4047-4048; docs/design/error_handling.md 26 lines (:103-104, :112, :118, :133-136, :153, :156, :173-174, :178, :185, :209, :382-383, :389, :562-563, :695, :697, :736, :864, :949, :953, :1002); docs/design/optional.md:434; docs/guides/tutorial.md :366-390 (the block) and :409; docs/guides/evaluator_faq.md:356 |
| Living checker | 1 | 3 | fork/evaluator/check_faq.py :167, :226, :229 (the FAQ's reproducers) |
| Living records | 6 | 13 | fork/decision-log.md (:39, :844-869, :1486-1488, :1534-1542, :18196-18211, :19198-19209, :19570-19571, :19597-19598), fork/ORCHESTRATION.md (:1516, :1550, :2421 history), fork/gap-analysis.md:70, fork/README.md:50, fork/register/rg1-plan.md (rows T2.1, T11.1, H3.2; D-RG-5's prose is history), fork/inventory/work-items.json (W-346's own text, 15 hits) |
| Closed plans (history, not edited) | 16 | 125 | fork/w5-choice/plan.md 38, fork/register/rg1-plan.md's prose, fork/eh/plan.md 26, fork/evaluator/plan.md 11, fork/b2/mixed-width-diagnosis.md 11, fork/w066/plan.md 8, fork/sumtype-interop/plan.md 8, fork/b1/plan.md 8, fork/w078a/plan.md 7, fork/w072/plan.md 6, fork/designdocs/plan.md 3, fork/b2/plan.md 3, fork/w5-s3/plan.md 2, fork/w008/plan.md 2, fork/match-replatform/plan.md 2, fork/optional/plan.md 1, fork/design-sprint/error-handling.md 1, fork/conformance/out/scoreboard.json 1 (the committed hosted scoreboard of 2026-10-06) |

The task's file list said 34 goldens; the grep gives 33 under check and lower
and 2 more under parse
(toolchain/parse/testdata/match/alternative_pattern.carbon and
fail_alternative_pattern_unclosed.carbon), 35 in all, as the lost rev 1 had
found. The task's "six conformance program files" are 18 (§0.5).

### §0.2 Baseline and nightly probes

Each probe is compiled as the conformance runner compiles (`carbon compile
--output=p.o --output-last-input-only p.carbon`, then `carbon link` and a run),
with its own `XDG_CACHE_HOME` (never the baseline's cache).

| Probe | Baseline cb726a230 | Nightly 2026.10.12 |
| --- | --- | --- |
| p1: `Core.Result(i32, String).Ok(1)` matched (the task's shape) | ``error: name `String` not found`` twice, then "semantics TODO: `match on unsupported scrutinee type`" (there is no `String` type in this tree; the type is `str`, and a `str` payload would fail SF-6 anyway) | ``member name `Result` not found in `Core` `` four times, ``name `String` not found`` twice, then "semantics TODO: `HandleMatchIntroducer`" |
| p2: `Core.Result(i32, i32).Ok(1)` and `.Err(7)` matched | compiles, links, prints `1` then `-7`, exit 0 | ``member name `Result` not found in `Core` `` at every use |
| p3: `fn Run() -> Core.Result((), i32)` propagating `.Err(7)` through `?` (main_run/return_result.carbon's shape) | prints `1`, stderr ``carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1``, exit 1 | as p2 |
| p4: `?` on a `Core.Result(i32, i32)` chain (operators/question_result.carbon's shape) | prints `11` then `-3`, exit 0 | as p2 |
| p7: the NEW spelling on the baseline (`.Success(1)`, `case .Failure`) | ``error: member name `Success` not found in `Core.Result(i32, i32)` ``, ``member name `Failure` not found in `Core.Result(i32, i32)` `` (the mirror of D-EHC-3) | not run |
| p8: `alias Ok = Success;` inside a user choice | "error: expected choice alternative name", then "semantics TODO: handle invalid parse trees in check" | not run |
| p9: file-scope `alias Ok = R.Success;` and `alias ResultOk = Core.Result(i32, i32).Ok;` | compiles (two unused-binding warnings) | not run |
| The `Carbon::expected` export and the catching thunk | fork/conformance/programs/error_handling/cpp_expected_export.carbon prints `10`, `3`, `1`, `9` and cpp_exception_rethrow_export.carbon prints `7`, `110`, both PASS in the baseline's scoreboard (/home/user/arb/conformance/cb726a230/scoreboard.json); the check golden interop/cpp/exceptions/catching_thunk.carbon's `imports` block shows the `may_throw_int__carbon_catching_thunk` decl and the two constructor calls `%Ok.ref`/`%Err.ref` by name; interop/cpp/function/export/result_expected.carbon's CHECK lines show the thunk's return type `Carbon::expected<int, int>` and never an alternative's name | no `Core.Result`: every program is a compile failure on the nightly, as its SKIP-free scoreboard rows already record for the fork-only features |

The baseline's fork/evaluator/check_faq.py passes with the baseline install
("check_faq: 13 reproducers run, 0 errors") and with the nightly ("17
reproducers run, 0 errors"), so the FAQ's quoted stderr line is pinned by a
running reproducer today, which is why C1 changes check_faq.py:229 with
lower/handle.cpp:421.

### §0.3 The prototype and its mutants

The rename of §2 was applied to /home/user/carbon-ehc-planner by a script
(whole-word `Ok`/`Err` on every non-CHECK line of the files §0.1 lists, plus
D-EHC-4's and D-EHC-5's lowercase names), then the new `fail_old_names` split
of D-EHC-3 was added, the prelude and toolchain were built
(the arbiter's `build.sh` with its worktree and label variables set to the
planner worktree and `ehc-planner`, 12 minutes while ARB-2's build of
aee70185c ran beside it), installed, gated, refilled and measured. Results:

| Step | Result |
| --- | --- |
| Files changed by the rename | 73 (the fixer's prototype; the planner's 72 lacked fork/conformance/README.md): 35 goldens (350 source lines), 18 programs (159 lines; run_result_ok.carbon and run_result_err.carbon renamed, D-EHC-13), fork/conformance/README.md (its two rows), 13 toolchain, prelude and header files (`git diff --numstat` before prek: 128 lines replaced and 10 added, result.carbon's history block; the planner's 112 lacked thunk.cpp's six `return_ok`/`return_err` lines and counted result.carbon's rewrite differently), 5 docs (38 lines), check_faq.py (3 lines); prek then reflowed long lines in the docs, wrapped the C++ at clang-format's width and asked for check_faq.py:229 to be split (a second pass is clean) (amended 2026-11-09, review fold: A-m1 / B-M1) |
| Whole-tree grep after the rename, outside CHECK lines and fork/ | five lines, all dated history (amended 2026-11-09, review fold: A-M1): common/raw_hashtable.h:1314 (English), core/prelude/types/result.carbon:56 (the history comment's "spelled `Ok`/`Err`"), check/testdata/operators/question_result.carbon:156, :160, :166 (the `fail_old_names` split's comment and its two deliberate source lines; :164 and :174 after the fill moves them); after P, twelve more, the amendment lines of Appendix C (§8.7's list); §8.7's grep 2 (over `git ls-files`; its pattern spelled there, not in this cell: RR1-m2) and its grep 3, the split-header grep, are empty after D-EHC-13 |
| `runner.py --self-test` (both sample checkers) | "check_samples: 14 samples, 0 errors", "check_samples: 19 program blocks, 70 fixtures, 2 W2 hits (1 allowlisted, 1 qualified); 0 errors", "self-test: 241 programs parsed, 56 bullets in table, OK" |
| The same with the tutorial reverted and the programs renamed (the lost rev's A-M1 state) | "check_samples: 14 samples, 1 errors" (the self-test is red), restored to 0 by the tutorial's seven block lines (B.1.17; amended 2026-11-09, review fold: B-m7) |
| Gate before any refill | `[  PASSED  ] 2015 tests.` and exactly 32 per-test `[  FAILED  ] ToolchainFileTest...` lines, the 32 files of §4, every failure "Autoupdate would make changes" (32 of 32), no crash, no `fail_`-prefix problem. The arbiter's summary line reads `GATE ehc-fixer: 2015 passed, 0 failed` and gate.sh exits 1: gate.sh:121-134 takes its failed count from a gtest "[  FAILED  ] N tests, listed below" summary that file_test does not print, and its exit code from the binary's, so the GATE line alone would read as green; the criterion is the per-test lines (amended 2026-11-09, review fold: A-m2; a note for ARB-2's landing of the scripts, not a change here) |
| Autoupdate | pass 1 rewrites the 32; pass 2 changes nothing (the gate after it is the proof, R28 (d)) |
| Gate after the fill | **2047 passed, 0 failed** (the new split is a split, not a file, so the count stays 2047) |
| The fill's non-CHECK lines | exactly the rename's 350 lines twice plus the 20 lines of the new split (the fixer's `git diff -U0`: 370 `+` and 350 `-` non-CHECK lines over the 35 goldens); the 32 refilled files have 2871 CHECK lines written and 2863 removed (the difference is the split's 8), classified in §4 (amended 2026-11-09, review fold: A-m3 (f) / B-M1) |
| Conformance | **PASS 228 / FAIL 0 / SKIP 13 over 241, 51 of 56 bullets**, byte for byte trunk's (/home/user/arb/conformance/ehc-planner/scoreboard.json before the mutants); the fixer's run (/home/user/arb/conformance/ehc-fixer/scoreboard.json, its own cache /home/user/arb/cache-ehc-fixer) the same totals, every row's status and detail equal to cb726a230's with the two renamed programs mapped by name (D-EHC-13) |
| check_faq.py with the prototype | "13 reproducers run, 0 errors" (the renamed line :229 matches the new stderr) |
| fork/designdocs/check_samples.py --toolchain (the prototype) | "19 program blocks, 70 fixtures (compiled), 2 W2 hits (1 allowlisted, 1 qualified); 0 errors" |
| p2, p3, p4 with the new spelling on the prototype | `1`/`-7`; `1` and stderr ``carbon: `Main.Run` returned `.Failure` of type `i32`; exiting with code 1`` with exit 1; `11`/`-3`: the baseline's outputs with the one printed name changed |
| The old spelling on the prototype (p6, p7, p2 unchanged) | ``error: member name `Ok` not found in `Core.Result(i32, i32)` `` for `Core.Result(i32, i32).Ok(1)`; ``member name `Err` not found in `Core.Result(i32, i32)` `` for `.Err(7)`, for `case .Err(e: i32)` and for `if (let .Err(e: i32) = ...)`; in the golden the kind is `[MemberNameNotFoundInSpecificScope]`; no note |
| prek (R25) on the 72 files | pass 1: rumdl reflowed docs/design/README.md:4047-4048, error_handling.md :112, :736, :864, :949 and tutorial.md:409 (MD013; R31's heading, bullet, numbered and row counts unchanged for all three files), ruff E501 on check_faq.py:229 (fixed by splitting the literal), clang-format wrapped thunk.cpp, lower/handle.cpp, function_context.h and expected.h; pass 2 clean, no file modified |
| M1, the order swapped (`Failure` first, `Success` second; the prelude only, re-installed) | gate 2040 passed, 7 FAILED: check interop/cpp/exceptions/catching_thunk.carbon, main_run/return_result.carbon, operators/question_result.carbon; lower interop/cpp/exceptions/catching_thunk.carbon, interop/cpp/function/export/result_expected.carbon, main_run/return_result.carbon, operators/question_result.carbon (every golden whose dumps print a `Core.Result` discriminant or alternative index; the fixer's re-run gives the same seven); conformance PASS 224 / FAIL 4 / SKIP 13: run_result_success.carbon (run_result_ok.carbon before D-EHC-13) exit 1 for 3 (the success value read as a failure), run_result_failure.carbon (run_result_err.carbon) exit 0 for 1 (the failure's discriminant is now 0), cpp_expected_export.carbon stdout mismatch (`<carbon/expected.h>` reads `disc_ == 0` as a value), cpp_exception_rethrow_export.carbon exit -11 (the header rethrows a null primary); the differential and user-choice programs stay green because they construct by name |
| M2, the thunk's two minted identifiers left as `"Ok"`/`"Err"` (toolchain rebuilt, the prelude restored and re-installed first) | gate over `--filter interop/cpp`: 229 passed, 3 FAILED: check interop/cpp/exceptions/catching_thunk.carbon and fail_catching.carbon, lower interop/cpp/exceptions/catching_thunk.carbon, each with ``member name `Ok` not found in `Core.Result(i32, Cpp.Exception)` `` and the `Err` twin at every `?`-selected C++ call (14 and 14, the 28 occurrences); lower interop/cpp/function/export/result_expected.carbon stays green (its one split constructs `.Success(1)` and has no `?` on a C++ call; its `exception_error` split is the check golden's). The planner's "4" ran M2 with M1's prelude swap still installed and counted that golden, one of M1's seven (228 + 4 = 229 + 3 = 232 is the union); the lost rev's 3 was right. The identifiers are the root (D-EHC-4) (amended 2026-11-09, review fold: A-M2) |
| M3, a kept alias | not buildable in the prelude: p8's parse error; a user-side alias (p9) is caught by no toolchain check and by the §8.7 grep only, which is D-EHC-2's guard |
| Restored prototype | full gate 2047 passed, 0 failed again after M2's rebuild |

### §0.4 Collisions: PR 53

`git merge-tree --write-tree aee70185c 2407efa74` (PR 53's head, SAFE-1,
docs and records only) exits 1 with tree 225772d5f and conflicts in
fork/ORCHESTRATION.md, fork/decision-log.md, fork/gap-analysis.md and
fork/inventory/work-items.json (the four records files every landing
conflicts in; LAND-1's D-LAND-5 region rules resolve them at PR 53's landing);
docs/design/README.md, expressions/arithmetic.md, slices.md, unions.md and
fork/rulebook.md auto-merge. No file EH-C's C1, F1 or P touches conflicts: PR
53 does not touch core/, toolchain/, the goldens, the programs,
error_handling.md, optional.md or the guides. It does touch
docs/design/README.md, which P edits too: PR 53's hunks are at :2148, :2168
and :3900 (`git diff aee70185c...2407efa74 -- docs/design/README.md`), P's at
:4046-4050, so the page auto-merges; the fixer's prototype commit (C1, F1 and P
applied) merge-trees against 2407efa74 with conflicts in the same four
records files only (§8.8 re-measures it on the branch's head) (amended
2026-11-09, review fold: B-m11). PR 53 carries one line with the
old spelling, docs/design/safety/rust_interop.md:223 ("with `Ok`/`Err` as the
variants"), a use of trunk's spelling (D-RG-8); EH-C lands first (W-346's
schedule puts it before UA-3 and PR 53 waits on SAFE-4), so D-RG-8's break
condition fires: PR 53 gains a rename commit before it lands, W-380 (D-EHC-11),
owner PR 53's landing (Next actions item 14). The merge-time rule: EH-C's
records edits are appended paragraphs, a new table row, a new ledger item and
one-line notes, each in a region LAND-1's rules keep from both sides; the
landing of PR 53 after EH-C resolves them as every landing since PR 67 has.

### §0.5 The conformance programs touched

Eighteen files (R16 (d): every EXPECT re-derived by hand in Appendix B, none
changes): error_handling/control_flow_constructs.carbon (14 lines, a user
`MyResult`), cpp_exception_catch_diff.carbon (4) and its .diff.cpp (1 comment),
cpp_exception_interop.carbon (9), cpp_exception_rethrow_export.carbon (1),
cpp_expected_export.carbon (8), question_generic_diff.carbon (16) and its
.diff.cpp (9: the `Ok`/`Err` oracle helpers),
question_generic_thread_diff.carbon (18) and its .diff.cpp (9),
question_propagation_diff.carbon (14) and its .diff.cpp (10),
result_prelude_diff.carbon (9) and its .diff.cpp (11), run_result_err.carbon
(7), run_result_ok.carbon (6); project/evaluator_tutorial_errors.carbon (7, the
tutorial's block); control_flow/choice_payload_roundtrip_diff.carbon (6, a user
`IntResult`). No program prints an alternative's name, so no EXPECT changes and
no new program is owed (D-EHC-10); the old spelling's rejection is pinned by the
new golden split (D-EHC-3). The README table of fork/conformance/programs
(bullets and counts) is unchanged: `runner.py --self-test` reports 241 programs
and 56 bullets before and after.

### §0.6 Upstream's direction at ca1898506 and the register (R32 (a), (c))

`git -C /home/user/carbon-lang fetch -q upstream trunk` on 2026-11-09 left
upstream/trunk at ca1898506 (2026-11-06T20:09:14Z, "Fix C++ access to Carbon
friend members from an unrelated class", PR 8097), the tip the weekly check of
2026-11-09 read; a second fetch while this plan was written changed nothing.
Read by sha with `git show upstream/trunk:<path>`:

-   docs/design/README.md:2167 "### Choice types"; :2175-2179 ``choice
    IntResult {`` / `Success(value: i32),` / `Failure(error: String),` /
    `Cancelled` / `}`; :2191-2192 ``// Equivalent to `IntResult.Failure(...)` ``
    / `return .Failure("Invalid character");`; :2196 `return .Success(r);`;
    :2204 `case .Success(value: i32) => {`; :2207 `case .Failure(error:
    String) => {`; :3159 "#### Generic choice types"; :3164-3167 `choice
    Result(T: type, Error: type) {` / `Success(value: T),` / `Failure(error:
    Error)` / `}`; :3856 "### Error handling"; :3858-3860 "For now, Carbon does
    not have language features dedicated to error handling, but we would
    consider adding some in the future. At this point, errors are represented
    using `[choice types](#choice-types)` like `Result` and `Optional`." (the
    link markup set in a code span)
    (`git log --oneline c1e83b0b7..upstream/trunk -- docs/design/README.md` is
    empty: the page is byte-identical from the cut to the tip, so RG-1's lines
    of 2026-10-28 are the tip's).
-   proposals/p000157-design-direction-for-sum-types.md:227-229 "so their
    detailed design will be addressed in future proposals, and the details
    discussed here should be considered provisional." (the sentence begins at
    :227, "separable, although there are some dependencies between them, so
    their detailed"; amended 2026-11-09, review fold: A-m3 (b)); :690-693
    `choice Result(Type:$$ T, Type:$$ Error) {` / `Success(T: value),` /
    `Failure(Error: error),` / `Cancelled`. It is the only proposal that spells
    any of the four names: `git grep -cE 'Success\(|Failure\(|\bOk\b|\bErr\b'
    upstream/trunk -- proposals` lists p000157 alone (27 lines, all
    `Success`/`Failure`, at :120, :124, :141, :146, :266-281, :345-374,
    :403-416, :428, :691-692, :868-879, :981-1005); provisional by its :228-229,
    corroborating only (D-RG-5).
-   No upstream text spells `Ok` or `Err`: `git grep -nE '\bOk\b|\bErr\b'
    upstream/trunk -- docs/design core proposals` is empty.
-   Upstream's prelude has no `Result` and no `Try`: `git ls-tree -r
    --name-only upstream/trunk -- core | grep -iE 'result|try'` is empty, and
    `git grep -cE 'interface Try\b|FromBreak|PostfixOperatorQuestion|
    HandleQuestion' upstream/trunk -- toolchain core` is empty; the lexer has
    the `Question` token (toolchain/lex/token_kind.def:107) and
    toolchain/parse has no handler for it (`git grep -n Question upstream/trunk
    -- toolchain/parse` finds only `->?` and `:?`), so there is no `?` postfix
    operator upstream.
-   Commits since the cut c1e83b0b7 (176 to the tip) touching
    docs/design/README.md, proposals or core/prelude: nine (0b7059a36 pre-commit
    bumps, 45ed77af3 and 28d15a6e7 formatting markers in p002665, 05a7ecbd3
    `SubobjectDestroy`/`SelfDestruct` moved out of `Destroy`, 6d80ceb58
    `IndirectIndexWith`, 59d53ab0a ASCII quotes in p1964, df3cf9294 `ref` in
    `Core.Iterate.Next`, 947c1eb52 `Core.Array`, a50feb64c proposal labels);
    none touches the README's error-handling or choice-types text or sum
    types, and the subject grep for "error", "result", "choice", "sum type" or
    "alternative" over the 176 finds four unrelated toolchain fixes (fea77fe59
    `ErrorInst` as self, 2b2a78ca1 import error recovery, 51e2c76a8
    `HasError`, f396762e2 destroying choice-typed `var`s). So W-346's premise
    holds at the tip and D-RG-5's break condition has not fired.

The register after EH-C (RG-1's vocabulary; every row's quote is the text
above): T2.1 (F-006a's alternatives) becomes **ALIGNED** with the quote and
D-EHC-1's break condition; T11.1 (`Core.Result` as a choice) stays ALIGNED, its
note "its alternatives are T2.1's drift" resolved; T11.3 (the success-first
order) stays ALIGNED (README.md:3165-3166); T11.2 (the library name
"prelude/types/result") stays NONE with check T11.2 (0 at the tip); T11.4 (the
`()` payload) stays NONE with check T11.4; T1.1 to T1.3 (`Core.ControlFlow`,
its order, the `Try` member spellings: the `?` desugar) stay NONE with checks
T1.1 to T1.3 (0 at the tip, the toolchain/parse silence above); the entry
point's exit code from a `Result` and the `Carbon::expected` export are not
register rows of their own (EH-A's and EH-B's blocks name them under the
`Try`-desugar and `Core.Result` entries) and stay NONE under the same silence
(no `Result`, no `Try`, no header upstream; `git grep -n expected.h
upstream/trunk -- toolchain` lists one unrelated line,
toolchain/lex/tokenized_buffer_test.cpp:774 `expected.has_leading_space`, and
no `expected.h` file exists upstream; amended 2026-11-09, review fold: A-m3
(a)). DR-0's block is untouched (it names no
W-346 entry). W-355's weekly check reads T2.1 afterwards as an ALIGNED row: its
quotes are rg1-quotes.tsv's README.md 3858, 3860, 3164-3166, 2176-2177, 3856,
2167, 3159 and p000157 691, 229 rows (already present, re-anchored on
2026-11-09), and its two new silence checks (Appendix D.6) fire if upstream
ever spells `Ok(` or `Err(` in docs/design or proposals, or declares a `choice
Result` or `class Result` under core, the two upstream-side break conditions
(both 0 at ca1898506: check_greps.sh over the tip reports "checked 94 silence
checks, 0 failed" with trunk's rows and "checked 96 silence checks, 0 failed"
with the two rows appended; check_quotes.sh "checked 289 quotes, 0 failed";
amended 2026-11-09, review fold: A-m3 (c) / B-m9).

### §0.7 The id re-scan

After `git fetch origin`: 82 refs (`git for-each-ref refs/remotes/origin
refs/heads`), `git branch -a` lists 83 lines, `git worktree list` 7 worktrees
(carbon-lang, carbon-arb2, carbon-ehc, carbon-ehc-planner, carbon-safe,
carbon-trunk, carbon-weekly). `git grep -oE 'W-3[7-9][0-9]|W-4[0-9][0-9]'
<every ref> -- fork` and `grep -r` over each worktree's fork/ directory find:
W-370 to W-377 filed on trunk aee70185c (W-377 the highest, 309 items); W-378
at that scan on trunk and on claude/carbon-fork-0-1-arb2 (6de18c1f7, worktree
/home/user/carbon-arb2) only as the 2026-11-09 weekly entry's text
(decision-log.md:19596-19598, ORCHESTRATION.md:2153). _Re-scanned by the fold
(2026-11-09, after `git fetch origin`; 84 refs, 77 distinct heads, 7
worktrees, the widened pattern; amended 2026-11-09, review fold: A-m3 (e) /
B-m4):_ W-378 is now a ledger item, ARB-2's, on claude/carbon-fork-0-1-arb2
at b87f130b2 and on trunk fca1e9e2f (PR 69; 310 items, W-378 last, size S),
and its notes name this plan's reservation ("the EH-C re-plan reserves W-380
to W-385 (its D-EHC-11)"); W-380 appears only as reserved text, in four
places at fca1e9e2f: the weekly entry's sentence (decision-log.md:19596),
W-378's notes (work-items.json:5161), ARB-2's entry (decision-log.md:20829
and :20831, "W-379, W-380, W-385, W-388, W-389 and W-396 to W-399 appear
only in prose" and "the EH-C re-plan reserves W-380 to W-385 (its
D-EHC-11)") and this plan, and `"id": "W-380"` is in no ledger on any ref or
worktree, W-378 being the highest id (amended 2026-11-09, review fold:
RR1-M2); W-381, W-384, W-386, W-387, W-390 and W-395 only in this plan's own
sentence below; so D-EHC-11 stands and W-380 is the next free id: W-379 is
skipped because W-378's notes and ARB-2's entry already name W-380 as EH-C's
(W-379 itself is a range bound only, fo1-plan.md:937, which would not bar
it: RG-1 filed W-346 despite such a mention; amended 2026-11-09, review
fold: RR1-m5). Of the first
scan: W-379, W-389, W-396 and W-397 as range bounds
or reserved text (fo1-plan.md:937, land1-plan.md:668-669, decision-log
:19595); W-380, W-385 and W-388 only in the weekly entry's sentence "no W-378
and no W-380 to W-388 appears anywhere" (:19596); W-398 and W-399 as range
bounds in six plans; no W-381 to W-384, W-386, W-387 or W-390 to W-395
anywhere; no W-4xx anywhere; the SAFE worktree (14c1ac8ac) names W-370 once
and W-371 twice (safe3-plan.md:1688-1692, filed items it cites) and W-397 to
W-399 as range bounds (amended 2026-11-09, review fold: RR1-m5). Decision
D-EHC-11: W-380 to W-385 reserved, W-380 filed, re-scanned at D (§8.9).

### §0.8 The lost rev 1 and the task text: confirmed, corrected

The 2026-11-06 plan's decisions D-EHC-1 to D-EHC-11 and its measured facts
(scratchpad/recovered/line694.txt) were re-derived and re-measured here. Kept,
confirmed: no alias (D-EHC-2, the parse error re-measured); the old spelling's
diagnostic and its `fail_old_names` split (D-EHC-3; the text re-measured,
identical); the catching thunk's identifiers, the stderr line, the locals and
IR names (D-EHC-4, now measured on the prototype, which the lost rev 1 had not
done); the header's `ok`/`err` members and `ok()` (D-EHC-5); dated amendments
(D-EHC-6); the records (D-EHC-7); user test choices renamed (D-EHC-8); one PR
landed by LAND-1 (D-EHC-9 there, D-EHC-12 here); no new program, EXPECTs
unchanged (D-EHC-10); 35 goldens not 34, 18 program files not 6; gate 2015 of
2047 before the fill and 2047 after one pass; 32 refilled; conformance
228/0/13; the order-swap mutant's 7 goldens and 4 programs; the checkers at 0
errors. Differs: (a) ids: the lost rev reserved W-378 to W-385 and filed W-378
for PR 53's rust_interop.md row; W-378 is taken (ARB-2's item, PR 69) and
W-379 is skipped because W-378's notes and ARB-2's entry already name W-380
as EH-C's (W-379 is a range bound only, fo1-plan.md:937; amended 2026-11-09,
review fold: RR1-m5), so EH-C reserves W-380 to W-385 and files W-380
(D-EHC-11); (b) the partial-thunk mutant turns
3 goldens red, as the lost rev had it: rev 1 said 4 because the planner ran
M2 with M1's prelude swap still installed and counted lower
result_expected.carbon, one of M1's seven (corrected 2026-11-09, review fold:
A-M2); (c) 350 golden source lines, not 328: the lost rev
counted whole-word lines only and the skeletons' lowercase members are
renamed too (D-EHC-5); (d) the lost rev's A-M1 (its one MAJOR: the docs sample
checkers go red at C1 until P) is folded as D-EHC-9 with the checkers named
(they are scripts run by the runner's self-test, not prek hooks, and
check_faq.py is a third one the lost rev did not name) and with the red and
green states measured; (e) fork/README.md:50 gains a note (the lost rev's
D-EHC-7 named it; kept); (f) the eight lost MINORs are re-found as far as this
rev can see them and folded: the lowercase IR names and locals (§1 D-EHC-4),
the FAQ reproducer in check_faq.py, the grammar of a mechanical rename ("an
`Success`"), the `E` parameter question (D-EHC-1), the order's proof by mutant
(D-EHC-1), the three goldens with no CHECK change named (§4), the R31 counts
after rumdl's reflow (§0.3), and clang-tidy's absence stated with the reason
(§8.10). Of the task text: its "34 goldens" are 35, its "six program files" 18,
its "thunk.cpp:1506-1508" is :1506 and :1508 (two identifiers, the lines
between them being the `NameId` wrappers), its `Core.Result(i32, String)` probe
has no `String` type to name (p1), and its "W-378 TAKEN by ARB-2's ledger
item" was not visible at the branch head first scanned but is now on trunk
fca1e9e2f (§0.7, PR 69).

## §1 Design

Every decision below is auto-adopted under R29 (a) and veto-able after the
fact; each states its break condition. R32 (a): every statement about the
mechanism is checked against upstream's tip ca1898506 (2026-11-06T20:09:14Z,
"Fix C++ access to Carbon friend members from an unrelated class", PR 8097,
fetched 2026-11-09 16:5x UTC and re-fetched at 17:0x UTC with the same sha),
with the page's text quoted in §0.6. Where upstream is silent (the `Try`
desugar, the entry point's exit code, the `Carbon::expected` export, the
library name, the `()` payload), the fork's D-EH-1 to D-EH-6 stand and this
plan changes only the spelling; where upstream's text decides (the names and
their order), the plan follows it to the letter. The plan STOPS at the design's
text (R32 (d)): it does not rename the payload fields, the parameter names or
the library, because no upstream statement about the error-handling mechanism
decides them (§0.6).

-   **D-EHC-1 — the names are `Success` and `Failure`, in that order, and
    nothing else about `Core.Result` changes.**
    `core/prelude/types/result.carbon` declares `choice Result(T: type, E: type)
    { Success(value: T), Failure(error: E) }`. The names are upstream's: the
    README's error-handling section says errors "are represented using `[choice
    types](#choice-types)` like `Result` and `Optional`."
    (docs/design/README.md:3858-3860 at ca1898506), the choice-types section it
    links spells `Success(value: i32),` and `Failure(error: String),`
    (:2176-2177) and uses them as `.Failure(...)`, `.Success(r)`, `case
    .Success(value: i32)` and `case .Failure(error: String)` (:2191-2207), and
    the generic `Result` under "Generic choice types" spells `Success(value:
    T),` and `Failure(error: Error)` (:3165-3166). The order is upstream's order
    and MUST NOT change: the discriminant is the declaration index, so
    `Success` = 0 and `Failure` = 1 is what the entry point's epilogue tests (`icmp
    eq i8 %disc, 0` at toolchain/lower/handle.cpp:394-400, printed as the
    `run.result.*` blocks of lower/testdata/main_run/return_result.carbon), what
    the `Try` impl's `match` arms dispatch on (result.carbon:44-45), what the
    catching thunk's `int` discriminant encodes (thunk.cpp:1380 "0 = Success,
    1 = Failure"; the C++ side returns 0 from the `try` body and 1 from `catch
    (...)`) and what `<carbon/expected.h>`'s `disc_` mirrors (`0` in the `T`
    constructor, `1` in the `unexpected` one). The order-swap mutant (§0.3 M1)
    turns seven goldens and four programs red, which is the measured proof. The
    payload names `value` and `error` already match upstream's (:2176-2177,
    :3165-3166). The second type parameter stays `E` (upstream's generic example
    writes `Error`): W-346's own notes say "the type parameter `E` may stay",
    D-RG-5 rests on the error-handling statement and the choice-types section,
    which spell no parameter at all, and the generic example "has
    parameterization as its subject and so only corroborates"
    (fork/register/rg1-plan.md D-RG-5); a parameter name is never written by a
    user program (specifics are positional), so it is not a second spelling of a
    user-facing mechanism under R32 (d). _Break condition:_ upstream lands a
    prelude `Result` or accepts an error-handling proposal (take its names, its
    order and its parameter names too); upstream changes the README's examples
    to `Ok`/`Err` (W-346 withdrawn as ALIGNED, D-RG-5's); the user vetoes the
    reversal (the rename is reverted by a new commit, F-006a restored by a dated
    note, the veto recorded against R32). A weekly check that classifies the
    parameter spelling `E` a drift files it as its own item (R32 (b)); nothing
    in this plan depends on it.
-   **D-EHC-2 — no alias, no deprecation period, no compatibility spelling.** A
    second spelling IS the drift (R32 (d)); keeping `Ok`/`Err` reachable
    anywhere in the prelude or the toolchain would leave the register entry a
    DRIFT. Measured: an alias of an alternative cannot be written inside a
    choice at all (`alias Ok = Success;` inside `choice R` is "error: expected
    choice alternative name", §0.2 p8), and a file-scope alias of a specific's
    alternative (`alias ResultOk = Core.Result(i32, i32).Ok;`) compiles (p9), so
    a user program CAN spell its own alias, and the prelude ships none. The
    guard against a kept alias is textual, not a toolchain check: the greps of
    §8.7 (whose answer is the explicit list of dated history lines named there
    and nothing else; amended 2026-11-09, review fold: A-M1 / B-M1) at C1, D and
    at land time, recorded in the decision-log entry as EH-B's §8.4 greps were,
    and the new register silence checks of D-EHC-7 (upstream adopting `Ok`/`Err`
    fires one). No register check greps the fork's tree (check_greps.sh greps
    upstream's tip), which is why the discharge grep is the guard. _Break
    condition:_ the user vetoes (D-EHC-1's veto route; then the old spelling
    returns wholesale, never as an alias).
-   **D-EHC-3 — a program that still spells `.Ok` or `.Err` gets the ordinary
    unknown-member diagnostic, with no note, pinned by a new `fail_` split.**
    Measured on the prototype (§0.3): ``error: member name `Ok` not found in
    `Core.Result(i32, i32)` `` for the constructor form and ``error: member
    name `Err` not found in `Core.Result(i32, i32)` `` for the `case .Err(e:
    i32)` and `if (let .Err(e: i32) = ...)` pattern forms, kind
    `MemberNameNotFoundInSpecificScope`, no note; the mirror image is the
    baseline's diagnostic for `.Success` today (p7 on cb726a230). No diagnostic
    text and no note names the former spelling: a note that said "renamed to
    `Success`" would keep the old name in the toolchain (R32 (d)) and would be
    a recognizable-input special case (R16 (c)). The new split
    `fail_old_names.carbon` in check/testdata/operators/question_result.carbon
    (Appendix A.3) pins both forms, CHECK-free in C1 and filled by F1 (its fill
    is quoted in §4). _Break condition:_ an owner ruling asks for a migration
    note (then it is a diagnostic of its own, not a note on this one, and the
    note names the design, not the drift).
-   **D-EHC-4 — every toolchain identifier that spells an alternative is
    renamed; names that spell "error" generically are not.** Renamed:
    thunk.cpp's two minted identifiers (`identifiers().Add("Success")` and
    `("Failure")`, :1506-1509 on trunk), its locals `ok_block_id`,
    `err_block_id`, `ok_name_id`, `err_name_id`, `ok_arg_id`, `ok_ctor_id`,
    `err_ctor_id`, `ok_initialized`, `err_initialized` (to `success_*` and
    `failure_*`), and its comments at :1380, :1461-1462, :1510, :1525, :1538;
    thunk.h:201's comment; lower/handle.cpp's `is_ok`, `ok_block`, `err_block`
    and the IR names `run.result.is_ok`, `run.result.ok`, `run.result.err` (to
    `run.result.is_success`, `run.result.success`, `run.result.failure`), its
    stderr message (``carbon: `Main.Run` returned `.Failure` of type `E`;
    exiting with code 1``) and comments; the message-global accessor
    `entry_point_result_err_message` / `SetEntryPointResultErrMessage` in
    lower/context.h, file_context.h and function_context.h (to
    `entry_point_result_failure_message` / `SetEntryPointResultFailureMessage`)
    and the global's IR name `main.result.err.message` (to
    `main.result.failure.message`); the comments of handle_choice.cpp:373-376,
    handle_match.cpp:60-62, pattern_match.cpp:1441, refutable_binding.cpp:564
    and lower/constant.cpp:450; and, joined by the review fold under this
    decision's own break condition (amended 2026-11-09, review fold: A-m1),
    thunk.cpp's `return_ok` (:982-987, the `try` body's `return 0`, the
    `Success` discriminant) and `return_err` (:1018-1023, the handler's `return
    1`) to `return_success`/`return_failure`, and lower
    main_run/return_result.carbon's prose :18-20, which names the blocks
    `run.result.ok`/`run.result.err` and the global `main.result.err.message`
    beside CHECK lines that print the new names (Appendix A.2.3). The IR names
    are user-visible under `--dump-llvm-ir` and in every lower golden, so they
    are part of the spelling the fork shows. NOT renamed: thunk.cpp's
    `err_param_type_id`, `err_pointee_type_id` and `err_storage_id`, which name
    the C++ thunk's error out-pointer parameter `err` (an error object, not an
    alternative; the thunk's C++ parameter is `void** err`), the differential
    oracles' `bool ok` struct flag (a C++ oracle's own field), and
    common/raw_hashtable.h:1314's English "Ok,". The partial-rename mutant (§0.3
    M2: the two minted identifiers left as `"Ok"`/`"Err"`) turns the three
    catching-thunk goldens red, which proves the identifiers are the root the
    thunk depends on. _Break condition:_ a review finds another identifier that
    denotes an alternative (then it joins C1, no new decision).
-   **D-EHC-5 — `<carbon/expected.h>` renames what mirrors the alternatives and
    keeps the `std::expected` vocabulary.** The payload union's members `ok`/`err`
    become `success`/`failure` (both `Payload` specializations, their
    constructors and every `payload_.ok`/`payload_.err` use), and the
    `expected<void, E>::ok()` factory becomes `success()`; `has_value()`,
    `operator bool`, `value()`, `operator*`, `error()`, `value_or()`,
    `operator==`, `unexpected<E>`, `has_exception()` and the `std::expected`
    conversions keep their names (they are `std::expected`'s vocabulary, D8's
    API, not a spelling of the alternatives). The header's comments that say "0
    for `Ok` and 1 for `Err`" and "`Ok(value)`", "`Err(error)`" follow the
    choice. The goldens' inline skeletons (check and lower
    interop/cpp/function/export/result_expected.carbon) rename their `T ok; E
    err;` members and the `ok(value)` initializer and the `r.ok : r.err` read
    the same way so that the fork shows one spelling; the mapping is by the
    template's NAME (`Carbon::expected`), so the member names are not
    load-bearing for the toolchain (the check golden's CHECK lines do not
    change, §4). Measured: cpp_expected_export.carbon and
    cpp_exception_rethrow_export.carbon PASS with the renamed header (its C++
    uses only `has_value()`, `value()`, `error()` and `rethrow()`), and no
    consumer of the header calls `.ok()`: `git grep -nE '\.ok\(\)' --
    toolchain/install/include fork/conformance docs
    toolchain/check/testdata/interop/cpp/function/export
    toolchain/lower/testdata/interop/cpp/function/export` is 0 before and after,
    and `git grep -nE 'expected<[^>]*>::ok\('` over the tree is 0. (Rev 1
    claimed the unscoped `git grep -nE '\.ok\(\)'` over the tree is 0; it lists
    180 lines in 43 files at aee70185c, `ErrorOr::ok()` and its kin in common/,
    toolchain/driver, toolchain/testing and elsewhere, none an `expected`;
    corrected 2026-11-09, review fold: A-M3 / B-M2.) _Break condition:_ an
    external C++ consumer of the header exists (none: the header is installed by
    the fork only and no program outside fork/conformance includes it); the user
    vetoes.
-   **D-EHC-6 — the five living docs are rewritten as dated fork amendments
    that keep the page's history, with upstream quoted by sha beside each.**
    Code blocks and code spans that spell the alternatives are renamed IN
    PLACE (a block is the page's current claim; a sample checker compares the
    tutorial's blocks byte for byte with the programs, so they cannot lag), and
    the prose that explained the former spelling is replaced by a blockquote
    `> **Fork amendment (<date>, EH-C, W-346).**` in DR-1's form
    (docs/design/control_flow/loops.md:140-144, docs/design/optional.md:473-482)
    that quotes the superseded sentence, names F-006a and D-RG-5, and quotes
    upstream's README lines by sha. error_handling.md's D1 is rewritten as the
    decision it now is (EH-C's, under R32, formerly the user's F-006a), the
    history inside it. The texts are Appendix C, verbatim. Two grammar artifacts
    of a mechanical rename ("an `Success` value", "an `Failure` payload") are
    excluded by the verbatim texts: the implementer writes Appendix C's
    sentences, not a sed. _Break condition:_ a review shows an amendment that
    drops a claim the page made before (then the claim is restored as quoted
    history).
-   **D-EHC-7 — the records.** W-346 is DISCHARGED (kind `implemented`, its
    title's leading tag replaced by "EH-C (DISCHARGED at EH-C, <date>; R32 (d);
    RG-1, D-RG-5): ...", W-341's form, the size field kept at M; amended
    2026-11-09, review fold: B-m5) with the evidence of Appendix D.1; the
    decision-log entry "EH-C: `Core.Result`'s alternatives renamed to `Success`/`Failure`
    (W-346) (<date>)" is placed directly before the EH-B entry (the log groups
    by workstream, newest first: EH-B precedes EH-A today), carrying D-EHC-1 to
    D-EHC-13, the V-3 check of §0.6 with the quotes and the §0 measurements in
    R, and its three D-time paragraphs (the reconciliation greps, the id
    re-scan, the discharge) appended by D (B-M3, §3 items 7 and 8); the F-006
    entry's sub-decision F-006a gains the dated reversal note of Appendix D.3
    (the user's 2026-07-19 decision reversed under the owner directive of
    2026-10-21, veto-able), a note, not a renumbering, so no F id is minted; the
    V-3a register: rg1-plan.md's T2.1 row turns ALIGNED (the quote already in
    the row), T11.1's and H3.2's notes are updated, two silence check rows are
    appended to rg1-checks.tsv (the upstream-side break conditions "the README's
    examples change to `Ok`/`Err`" and "upstream adds a prelude `Result`" become
    greps that fire; amended 2026-11-09, review fold: B-m9) and one comment line
    to rg1-quotes.tsv naming the rows T2.1 keeps (Appendix D.6; W-355's weekly
    check then reads T2.1 as an ALIGNED row with a quote check and two silence
    checks, as every other ALIGNED row); the RG-1 entry, the EH-A entry's
    register paragraph, the UA-1 entry's RG-1 paragraph, V-3's paragraph and the
    2026-11-09 weekly entry gain dated "resolved by EH-C" notes where they name
    W-346 (Appendix D.4, D.5); fork/gap-analysis.md's row "Error handling:
    dedicated control flow constructs" stays DONE with its evidence cell
    refreshed and row 70's example `case .Ok(v: i32)` becomes `case .Success(v:
    i32)` (no row flips, the tally stays 37/17/2/0); fork/ORCHESTRATION.md's
    header, a dated paragraph, a Branches row, Next actions item 6's W-346 words
    and the F.3 paragraph's "Next:"; fork/eh/plan.md's Status paragraph gains
    the pointer to this plan; fork/README.md:50's checklist line gains the
    rename in parentheses. Closed plans (fork/w5-choice, b1, b2, w066, w072,
    w078a, sumtype-interop, match-replatform, optional, w008, w5-s3, designdocs,
    evaluator, design-sprint, register's prose, and this plan's own history)
    keep their text. _Break condition:_ a records check of D-LAND-6 step 9
    (rowcheck.py, R31 counts, the model-identifier grep) fails (fix at the text,
    never by dropping a record).
-   **D-EHC-8 — user test choices and oracle helpers that spell `Ok`/`Err`
    are renamed too.** The goldens' `MyResult`/`IntResult` choices (question*,
    fail_question*, match/*, choice/payload_construct, lower/match/*, the two
    parse goldens), the programs' `MyResult` and `IntResult`, and the
    differential oracles' `static auto Ok(...)` / `Err(...)` helpers become
    `Success`/`Failure`. Reason: R3 makes testdata and programs the fork's
    teaching material ("derive syntax from working code"), so a user choice
    spelled `Ok`/`Err` there keeps showing the drift's spelling as the result
    idiom, and the task's own inventory names them; the names are incidental
    to every one of these tests (they pin `?`, `match`, payload patterns and
    layouts, never the identifier text), so no test loses its purpose; and the
    greps of §8.7 then have a clean answer. Not renamed: the oracles'
    `bool ok` flag and local bindings such as payload_construct.carbon:24's
    `let err: IntResult = IntResult.Failure;` (a binding named for an error
    value, not an alternative; its SemIR name `%err` stays). _Break
    condition:_ a review shows a golden whose purpose is the identifier text
    itself (none found).
-   **D-EHC-9 — commit slicing: C1 carries every checker-visible line, P
    carries the prose.** The sample checkers are not prek hooks: they are
    fork/evaluator/check_samples.py (the tutorial's ```carbon and ```text
    blocks byte for byte against fork/conformance/programs/project/*) and
    fork/designdocs/check_samples.py (DD-1's pages and fixtures, plus the W2
    placeholder rule over docs/design), both run by `runner.py --self-test`,
    which conformance.sh runs before every conformance run, and
    fork/evaluator/check_faq.py (the FAQ's quoted diagnostics re-run with a
    toolchain; LAND-1 runs it after D-LAND-6 step 8 as EV-1's land sequence,
    fork/land/land1-plan.md:1640-1648, `--which fork` and `--which nightly`;
    amended 2026-11-09, review fold: B-m8). Measured (§0.3): with the
    programs renamed and the tutorial not, the evaluator checker reports
    "check_samples: 14 samples, 1 errors" and the self-test is red; with both
    renamed, "0 errors". So C1 = the prelude, the toolchain, the header, the
    goldens' sources, the programs' sources (with D-EHC-13's two file
    renames and fork/conformance/README.md's two rows, which `runner.py
    --self-test` checks against the programs; amended 2026-11-09, review
    fold: B-M1), the tutorial's code block, the FAQ's quoted line and
    check_faq.py's reproducer, and every other docs code block or code span
    that spells an alternative (they are claims the toolchain now
    contradicts); P = Appendix C's prose amendments only. Every
    commit is green on its own: C1's gate is red on exactly the 32 goldens of
    §0.3 and nothing else ("Autoupdate would make changes", no crash), its
    self-test green; F1 makes the gate 2047 of 2047; P changes no code. The
    designdocs checker maps no block of error_handling.md or optional.md to a
    program or fixture (its SAMPLES table names neither page), so the design
    pages' blocks are not checker-visible, but they are still renamed in C1
    because they are code. _Shrink line:_ if the docs amendments grow beyond
    Appendix C (a review asks for more prose), the toolchain and prelude
    rename (C1 with its checker-visible lines, F1) lands first and the prose
    follows in the same PR as its own commit, P split as P1 (the pages'
    amendments) and P2 (what the review added); the rename itself never
    shrinks (R17: the rename is total or it is the drift). _Break condition:_
    a checker goes red on C1 after F1 (then C1 missed a visible line; fixed at
    the root in a fix commit, never by a checker allowlist).
-   **D-EHC-10 — no new conformance program; every EXPECT is unchanged.** The
    eighteen touched programs print numbers through `Core.Print` and exit
    codes; none prints an alternative's name, the runner does not assert
    stderr (run_result_failure's message lands in logs/), and the differential
    pairs compare stdout bytes that do not contain names. Each EXPECT is
    re-derived by hand in Appendix B from the program's arithmetic and the
    design (R16 (d)); re-measured: 228/0/13 over 241 on the prototype, byte
    for byte trunk's. The new `fail_` split (D-EHC-3) is a golden, not a
    program, because the old spelling's rejection is a compile-time property
    with no runtime oracle. _Break condition:_ a program prints a name through
    a match (none does); then its EXPECT changes and the reason is the name.
-   **D-EHC-11 — ids: W-380 to W-385 reserved; W-380 filed; no F id.** §0.7's
    re-scan at every origin ref, local branch and worktree with the widened
    command finds W-378 the highest filed id since PR 69 landed (ARB-2's
    item on trunk fca1e9e2f, whose notes name this reservation; W-377 at the
    first scan; amended 2026-11-09, review fold: A-m3 (e) / B-m4); W-379 is
    a range bound only (fo1-plan.md:937) and is skipped because W-378's notes
    and ARB-2's entry already name W-380 as EH-C's (amended 2026-11-09,
    review fold: RR1-m5); W-380, W-385 and W-388 appear on trunk only as
    reserved text, inside the 2026-11-09 weekly entry's sentence "no W-378
    and no W-380 to W-388 appears anywhere", W-378's notes and ARB-2's entry
    (decision-log.md:20829 and :20831 at fca1e9e2f; amended 2026-11-09,
    review fold: RR1-M2), W-389 and W-396 to W-399 only as range bounds. EH-C
    reserves W-380 to W-385 and files W-380:
    "PR 53 (SAFE-1): docs/design/safety/rust_interop.md:223 names `Ok`/`Err`
    as `Core.Result`'s variants; a rename commit on PR 53's branch before it
    lands (D-RG-8's break condition, fired by EH-C landing first)" (Appendix
    D.1), owner PR 53's landing (ORCHESTRATION Next actions item 14, SAFE-4).
    W-381 to W-385 stay unused unless the reviews need one. No F id: R32 makes
    upstream's spelling the design's, and F-006a is reversed by a dated note.
    _Break condition:_ the id re-scan at D (§8.9) finds W-380 used, which
    means a ledger item with that `id` on any ref or worktree, or a prose
    text that files it for other work; a prose mention that reserves it for
    EH-C (W-378's notes, ARB-2's entry, the weekly entry's sentence) is not a
    use (amended 2026-11-09, review fold: RR1-M2); then the next free id,
    re-scanned, and every cross-reference in this plan's D texts renumbered
    in the same commit.
-   **D-EHC-12 — one PR with base trunk, two implementation reviews, a fix
    budget of two, and LAND-1's D-LAND-6 landing.** The PR "EH-C:
    `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346)"
    (Appendix E) opens with base trunk after its two implementation reviews are
    dry (R29 (c): two until the container verification is green, then one; EH-C
    keeps two because the rename spans 73 files) and lands by LAND-1's procedure
    (fork/land/land1-plan.md D-LAND-6, one landing reviewer, the records commit
    with Appendix A's texts, specified in Appendix F with `<...>` placeholders).
    Trunk moved after the branch was cut (fca1e9e2f, PR 69, the Status
    paragraph), so a merge of trunk into the branch comes FIRST, M-0 before C1
    (§3's M-0 paragraph), as FO-1's stage 17 did (never a rebase, AGENTS.md); it
    merges clean (merge-tree exit 0 against the rev 1 commit), and if trunk
    moves again before the landing, a land-time M follows with the refill, the
    gate and conformance re-quoted (amended 2026-11-09, review fold: B-m4). The
    one held PR, PR 53 (claude/carbon-fork-0-1-safe at 2407efa74), conflicts
    with trunk aee70185c only in the four records files (§0.4) and carries one
    line with the old spelling (rust_interop.md:223): the rule is D-RG-8's break
    condition, W-380 (D-EHC-11), and the records conflicts are LAND-1's region
    rules at PR 53's own landing; EH-C amends no held PR (R32 (e) does not
    apply: PR 53's line is a use of trunk's spelling, not a drift of its own).
    _Break condition:_ trunk's toolchain or prelude moves again before EH-C
    lands (then the merge of trunk is followed by a full re-measure, §8.8, and
    any new use site found by §8.7's greps joins a fix commit); PR 69's move
    touched check.cpp only, no use site, and M-0 takes it.
-   **D-EHC-13 — file names and split names that spell an alternative are
    renamed too (added 2026-11-09, review fold: B-M1).** The two conformance
    programs fork/conformance/programs/error_handling/run_result_ok.carbon
    and run_result_err.carbon become run_result_success.carbon and
    run_result_failure.carbon (`git mv`, with fork/conformance/README.md's
    two table rows, which keep their position: the table is sorted by path
    and `result_prelude_diff` < `run_result_failure` < `run_result_success`),
    and the golden splits `unit_ok` (check main_run/return_result.carbon:23,
    check operators/question_result.carbon:98, lower
    main_run/return_result.carbon:24, with its comment :22) and `i32_ok`
    (check main_run/return_result.carbon:32, lower
    main_run/return_result.carbon:36) become `unit_success` and
    `i32_success`; F1 refills the `--- unit_success.carbon` headers, the
    `unit_success.carbon:` diagnostic prefixes, the lower dumps' `ModuleID`,
    `source_filename` and `DIFile` lines (the three goldens gain 2, 1 and 6
    rewritten CHECK lines over the planner's totals, §4). Reason: W-346 reads
    "with every use", D-EHC-4 and D-EHC-8 rename lowercase names on the
    ground that they spell an alternative (`run.result.ok`, `ok_block_id`,
    the oracles' `Ok(...)` helpers), and a file or split name that spells one
    is the same case; no grep of the whole-word kind sees an
    underscore-joined name, so §8.7 gains two name greps. Not renamed:
    `fail_old_names` (it names the test's subject, not an alternative),
    `exception_error` (an error object), and the committed hosted scoreboard
    fork/conformance/out/scoreboard.json (2026-10-06, history), fork/eh/plan.md
    (history) and the ledger's evidence strings that cite the old file names
    at a sha (history; the fixer's grep lists them, §8.7). Measured (the
    fixer's prototype): gate 2047 of 2047 after the fill, conformance
    228/0/13 over 241 with every row's status equal to the baseline's under
    the mapped names, `runner.py --self-test` "241 programs parsed, 56
    bullets in table, OK". _Break condition:_ a review shows a name whose
    purpose is the old text (none: both programs test the discriminant
    paths, both splits the `Success` payload shapes).

## §2 Spec, file by file

Line numbers are trunk aee70185c's. Every C++ hunk is given in the form
clang-format 21.1.8 leaves it (R18; the prototype's prek fixpoint), so the
implementer's diff equals the prototype's; a hunk that differs only by
wrapping is not a finding. The rename is whole-word (`\bOk\b`, `\bErr\b`) on
every non-CHECK line of the files named, plus the lowercase names D-EHC-4 and
D-EHC-5 list; nothing else is edited in C1.

### §2.1 core/prelude/types/result.carbon (C1)

The positions of :28 (`choice Result`) and :51 (`fn FromBreak`), and of every
line before :52, MUST NOT move (the trailing history block below adds ten lines
after :52: 52 lines at M-0, 62 at C1; amended 2026-11-09, review fold: RA-m1):
goldens quote `result.carbon:28` (check
operators/question_result.carbon's `fail_class_payload` note) and
`result.carbon:51` (two conversion notes), the lower goldens embed the file's
function lines in `DISubprogram` entries (six lower goldens name the file:
§4's four plus interop/cpp/template_symbolic_arg.carbon and
variadics/tuple_segment_destroy.carbon), and twelve more check goldens name the
file in their import lists. The prototype renamed in place and no golden
outside §4's 35 moved; this spec keeps that property. So lines 20-27 (the
eight comment lines) become the eight lines below, :29-30 become
`Success(value: T),` and `Failure(error: E)`, :33-39 (the `Try` comment,
seven lines) become the seven lines quoted after the choice, re-flowed at 80
columns because the in-place rename makes :34 86 columns wide and no .carbon
line-length hook would catch it (verbatim; amended 2026-11-09, review fold:
B-m6), :44-45 become `case .Success(v: T) => ...` and `case .Failure(e: E)
=> ...`, :51 becomes `fn FromBreak(b: E) -> Self { return Result(T,
E).Failure(b); }`, and the dated history goes AFTER :52 as a trailing comment
block (no golden quotes a line past 51). The import lines, the `Try` impl's
signature and its trailing return are untouched (R27: the impl is diffed
against docs/design/error_handling.md's sketch after Appendix C.2 renames the
sketch).

<!-- google-doc-style-ignore -->

```carbon
// The vocabulary type for fallible operations (docs/design/error_handling.md,
// "The `Core.Result` type"): `Success` carries the success value, `Failure`
// the error value, upstream's spellings (docs/design/README.md, the
// choice-types section and "Generic choice types"; the history is at the end
// of this file). The alternative order fixes the discriminants — `Success` =
// 0, `Failure` = 1 — which the entry point's exit-code epilogue
// (toolchain/lower/handle.cpp) and the C++ `Carbon::expected` layout mirror
// rely on. `E` is unconstrained in 0.1; `Result((), E)` is the unit shape.
choice Result(T: type, E: type) {
  Success(value: T),
  Failure(error: E)
}
```

<!-- google-doc-style-resume -->

The `Try` comment, :33-39, seven lines, each at most 80 columns (B-m6):

<!-- google-doc-style-ignore -->

```carbon
// `Result` is a `Try` operand and a `Try` return type: `expr?` continues with
// the `Success` payload and propagates a `Failure` payload through
// `FromBreak` on the enclosing function's return type (the `ImplicitAs` error
// conversion is the ordinary argument conversion of that call). The sketch is
// the design's (docs/design/error_handling.md, "The `Core.Try` interface");
// `final` licenses impl lookup to apply the `where` rewrites under a symbolic
// query, so `r?` on a `Result(T, E)` operand in a generic body has type `T`.
```

<!-- google-doc-style-resume -->

The trailing block, after the impl's closing brace (:52), preceded by one
blank line (its third line, :56 of the written file, is the one `Ok`/`Err`
the prelude keeps: dated history, §8.7's list):

<!-- google-doc-style-ignore -->

```carbon

// History (EH-C, W-346, <date>; fork/eh/ehc-plan.md D-EHC-1): from fork
// decision F-006a (user, 2026-07-19) until EH-C the alternatives were spelled
// `Ok`/`Err`, chosen over the README's `Success`/`Failure` as illustrative.
// RG-1 (2026-10-28, D-RG-5) classified that a second spelling of upstream's
// mechanism under fork/rulebook.md R32 (d): upstream's docs/design/README.md
// (ca1898506) names `Result` as the error representation (:3858-3860) and
// spells the result choice `Success(value: i32)` / `Failure(error: String)`
// (:2176-2177) and `Success(value: T)` / `Failure(error: Error)`
// (:3165-3166). No alias remains; the user may veto the reversal (R29).
```

<!-- google-doc-style-resume -->

### §2.2 toolchain/check/cpp/thunk.cpp and thunk.h (C1)

thunk.cpp:982-987 `return_success` (`clang::StmtResult return_success =
sema.BuildReturnStmt(` / `if (!return_success.isUsable()) {` /
`try_stmts.push_back(return_success.get());`) and :1018-1023 `return_failure`
the same way (the `try` body's `return 0` and the handler's `return 1`, the
discriminant's two values; added 2026-11-09, review fold: A-m1); :1380 "0 =
Success, 1 = Failure"; :1461-1462 "then branch: the Success block is the taken
edge, the Failure block the fall-through."; :1502-1541 (the measured form):

<!-- google-doc-style-ignore -->

```cpp
  auto success_block_id =
      AddDominatedBlockAndBranchIf(context, node_id, cond_id);
  auto failure_block_id = AddDominatedBlockAndBranch(context, node_id);

  auto success_name_id =
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Success"));
  auto failure_name_id =
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Failure"));

  // Success block: `Core.Result(S, Cpp.Exception).Success(<ret>)` into the
  // storage.
  context.inst_block_stack().Push(success_block_id);
  context.region_stack().AddToRegion(success_block_id, node_id);
  SemIR::InstId success_arg_id =
      ...
  auto success_ctor_id = PerformMemberAccess(
      context, loc_id, result_type.inst_id, success_name_id);
  bool success_initialized =
      initialize_result(PerformCall(context, loc_id, success_ctor_id,
                                    {success_arg_id}, /*is_desugared=*/true));

  // Failure block: `Core.Result(S, Cpp.Exception).Failure(err as
  // Cpp.Exception)` into the storage. The `as` is the prelude adapter's
  // conversion from `VoidBase*`.
  context.inst_block_stack().Push(failure_block_id);
  context.region_stack().AddToRegion(failure_block_id, node_id);
      ...
  auto failure_ctor_id = PerformMemberAccess(
      context, loc_id, result_type.inst_id, failure_name_id);
  bool failure_initialized = initialize_result(
      PerformCall(context, loc_id, failure_ctor_id, {exception_value_id},
      ...
  // Converge (the Failure block is on top), then the initialized storage is the
      ...
  if (!success_initialized || !failure_initialized) {
```

<!-- google-doc-style-resume -->

The `...` lines are unchanged code. `err_param_type_id`, `err_pointee_type_id`
and `err_storage_id` (:1442-1452) stay (D-EHC-4). thunk.h:201-202: "returning
the `int` discriminant 0 (Success) or 1 (Failure). Returns" / "`nullptr` on
failure." (one re-wrap).

### §2.3 toolchain/lower (C1)

lower/handle.cpp:356-363 (the comment) names `.Success(())`, `.Success(code)`,
`.Failure(e)`, "`Success` = 0, `Failure` = 1" and "the `Success(i32)` payload";
:394-416:

<!-- google-doc-style-ignore -->

```cpp
  auto* is_success =
      builder.CreateICmpEQ(discriminant, llvm::ConstantInt::get(i8_type, 0),
                           "run.result.is_success");
  auto* success_block = llvm::BasicBlock::Create(
      context.llvm_context(), "run.result.success", &context.llvm_function());
  auto* failure_block = llvm::BasicBlock::Create(
      context.llvm_context(), "run.result.failure", &context.llvm_function());
  builder.CreateCondBr(is_success, success_block, failure_block);

  // `.Success(())` exits 0; `.Success(code)` exits `code`. The checker admits
  // exactly these two success types (`IsValidEntryPointReturnType`).
  builder.SetInsertPoint(success_block);
      ...
  // `.Failure(e)`: `write(2, message, length)` — stderr is unbuffered, and no
      ...
  builder.SetInsertPoint(failure_block);
      ...
      "carbon: `Main.Run` returned `.Failure` of type `" +
      ...
  builder.CreateCall(
      write,
      {builder.getInt32(2), context.entry_point_result_failure_message(message),
       llvm::ConstantInt::get(i64_type, message.size())});
```

<!-- google-doc-style-resume -->

lower/context.h:147-153 and :214-216: `entry_point_result_failure_message()`,
`SetEntryPointResultFailureMessage(llvm::Value* message)` with the CHECK text
"`Main.Run` `.Failure` message already generated", the member
`entry_point_result_failure_message_` and its comment ("returns `.Failure`
(the handle.cpp `ReturnExpr` epilogue). There is one entry point per
compilation, so one message." re-wrapped). lower/file_context.h:246-250: the
two forwarding accessors renamed the same way. lower/function_context.h:374-
381: the comment ("`.Failure` (the handle.cpp `ReturnExpr` epilogue): a private
global created on first use ..."), `entry_point_result_failure_message(
llvm::StringRef message) -> llvm::Value*` (clang-format wraps the return type
to its own line), `file_context_->entry_point_result_failure_message()`,
`builder().CreateGlobalString(message, "main.result.failure.message")` and
`file_context_->SetEntryPointResultFailureMessage(global)`.
lower/constant.cpp:450: "to replace a stored Failure payload with an unrelated
value at any".

### §2.4 toolchain/check comments (C1)

handle_choice.cpp:373-376: "For `choice C { Success(value: i32), ... }` the" /
"function behaves like:" and "// fn Success(value: i32) -> C;";
handle_match.cpp:60-63: "payload-free (`case .Failure`), whose" and
"payload-destructuring (`case .Success(value: i32)`, `case .Success(42)`)," /
"whose payload subpatterns mix bindings, constant integer expressions, and";
pattern_match.cpp:1441: "For example `case IntResult.Failure`: only the
leading-dot spelling is"; refutable_binding.cpp:564: "(`case .Success(42)`)
has no bind-pass work, so nothing is extracted. An".

### §2.5 toolchain/install/include/carbon/expected.h (C1)

Comments :27 "discriminant, 0 for `Success` and 1 for `Failure` (the
declaration order in", :46 "discriminant is `Failure` regardless).", :131 "in
its `Failure` alternative from", :145 "The payload region: `Success` and
`Failure` payloads at offset zero, sized and", :199 "`Success(value)`.", :201
"`Failure(error)`.", :271 "0 = Success, 1 = Failure: Carbon's alternative
declaration order.", :276 "no `Success` payload.", :290 "`Success(())`.",
:296 "`Failure(error)`.". Code (D-EHC-5): `Payload<T, E>` :152-155 becomes
`constexpr explicit Payload(T value) : success(value) {}` /
`constexpr Payload(unexpected<E> error, int /*tag*/)` / `:
failure(error.error()) {}` (clang-format's wrap) / `T success;` / `E failure;`;
`Payload<void, E>` :161-162 the same two lines and `E failure;`; every
`payload_.ok` becomes `payload_.success` and every `payload_.err`
`payload_.failure` (:214-217, :220-221, :225, :233-234, :245, :247, :252, :254,
:309-310, :316, :326, :333); :291 `static expected success() {`. The
`static_assert`s, `has_value()`, `value()`, `error()`, `value_or()`,
`operator==`, `unexpected`, `Exception` and the `std::expected` conversions
are untouched.

### §2.6 Goldens (C1 the sources, F1 the fill)

The 35 files and every source line, before and after, are Appendix A.1 (check,
22 files), A.2 (lower, 11), A.4 (parse, 2), the split renames of D-EHC-13
among them (A.1.7, A.1.22, A.2.3; added 2026-11-09, review fold: B-M1); the
new split `fail_old_names` of
check/testdata/operators/question_result.carbon is A.3, inserted after the
`fail_class_payload` split's last source line (:149 `fn Use(unused r:
Core.Result(SomeClass, i32)) {}`) and before the file's trailing
`// CHECK:STDOUT:` block, CHECK-free in C1. No CHECK line is edited by hand
(R16 (a)); F1 is `autoupdate.sh` to its fixpoint and nothing else.

### §2.7 Programs (C1)

The 18 files and every line are Appendix B, with each EXPECT re-derived. Two
files are renamed by `git mv` (D-EHC-13; added 2026-11-09, review fold:
B-M1): run_result_ok.carbon to run_result_success.carbon and
run_result_err.carbon to run_result_failure.carbon, with
fork/conformance/README.md's two rows (:345-346 at trunk) spelling the new
paths in place. The `.diff.cpp` oracles rename their `static auto Ok(...)` /
`Err(...)` helpers and their comments; their `bool ok` fields stay. `runner.py
--self-test` before the commit (R7): "241 programs parsed, 56 bullets in
table, OK" (the fixer's prototype prints the same line).

### §2.8 Docs (C1 the code, P the prose)

Appendix C gives each page's text verbatim: C.1 docs/design/README.md
:4046-4050; C.2 docs/design/error_handling.md (the block :100-105, the
paragraph :112-118, the sketch lines :133-136, :153, :156, :173-174, :178,
:185, :209, :382-383, :389, the list item :562-563, the sketch :695-697, the
amendment line :736, the layout note :864, D1 :949-956, D10 :1002); C.3
docs/design/optional.md:434; C.4 docs/guides/tutorial.md :360-391 (the block)
and :408-409; C.5 docs/guides/evaluator_faq.md:356. C1 takes every code block
and code span of C (the block lines, :562-563, :736, :864, :1002, optional.md's
`.Failure(())`, the tutorial's block, the FAQ's ```text line); P takes the
amendment paragraphs (README's, error_handling.md's :112-118 and D1, the
tutorial's and the FAQ's one-sentence notes). Line counts after rumdl's reflow
(prek pass 1 of §0.3) are the implementer's to re-measure with r31.py before
and after each commit (R31 (b)).

### §2.9 fork/evaluator/check_faq.py (C1)

:167 `"return Core.Result((), i32).Success(()); }"`, :226 `"return
Core.Result((), i32).Failure(7); }"`, :229 split in two literals (ruff E501):
``"carbon: `Main.Run` returned `.Failure` of type `i32`; "`` and
`"exiting with code 1",` on the next line.

### §2.10 Records (R and D)

Appendix D gives every text verbatim with `<...>` placeholders: D.1 the ledger
(W-346 discharged, W-380 filed); D.2 the decision-log entry (R writes it
without its three D-time paragraphs, which D appends: B-M3); D.3 the F-006a
reversal note; D.4 the RG-1 entry's note; D.5 the EH-A, UA-1, V-3 and
2026-11-09 weekly notes; D.6 the register (rg1-plan.md's three rows,
rg1-checks.tsv's new row, rg1-quotes.tsv's comment line); D.7 the gap rows; D.8
ORCHESTRATION; D.9 fork/eh/plan.md; D.10 fork/README.md.

## §3 Commits (one PR, "EH-C: `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346)", R29 (b))

Every commit: `--author='jmann345 <jerrymannstan@gmail.com>'`,
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`,
explicit paths only (R20), a new commit (never an amend), the message ending
after a blank line with the session's attribution trailers; prek (R25, the
command of §8.6) to a fixpoint before each; R31's counts in the message of
every commit that edits markdown. Nothing is pushed and no PR is opened by the
implementer; the orchestrator opens the PR after the reviews are dry
(D-EHC-12). The shape is OV-4's and VA-2's (fork/overload/ov4-plan.md §3,
fork/variadics/va2-plan.md §3): records that claim the discharge go in the
last commit, after the reviews (OV-4's B-M5).

**M-0, before item 2 (added 2026-11-09, review fold: B-m4):** trunk moved to
fca1e9e2f (PR 69) after the branch was cut, so the implementer's first commit
is `git merge --no-ff origin/trunk` into the branch (the Status paragraph;
merge-tree exit 0 against the rev 1 commit, so no conflict is expected; one
in a records file is resolved by §6.2's rules), message "EH-C (M-0): merge
trunk <sha> (PR 69, ARB-2) into claude/carbon-fork-0-1-ehc before C1". The
gate's `src-patches.applied` line prints `landed` from here on, and every
figure of §8 is measured on this base.

1.  **Plan**: fork/eh/ehc-plan.md, rev 1 and its revisions, commits on the
    same file, each a fold record. Messages: "EH-C plan (rev 1): Core.Result
    alternatives renamed to Success/Failure (W-346)", "EH-C plan (rev 2):
    reviews A and B folded, 17 findings", "EH-C plan (rev 3): focused
    re-review folded, sign-off".
2.  **C1, the rename with every checker-visible line**: §2.1 to §2.5, the 35
    goldens' sources with the new split (Appendix A, no CHECK line touched),
    the 18 programs (Appendix B; two renamed by `git mv` with
    fork/conformance/README.md's two rows, D-EHC-13), the docs' code blocks
    and code spans of Appendix C (the tutorial's block, the FAQ's ```text
    line, error_handling.md's blocks and code-span items, optional.md:434,
    README's code spans), and check_faq.py (§2.9); upstream re-fetched and
    the tip named in the message body. Gate on C1 alone: `[  PASSED  ] 2015
    tests.` and exactly the 32 per-test FAILED lines of §4, each "Autoupdate
    would make changes", no crash, no `fail_`-prefix problem (measured shape,
    §0.3; the GATE summary line reads "2015 passed, 0 failed" and the script
    exits 1, A-m2, §8.3); `runner.py --self-test`
    green ("14 samples, 0 errors"; "19 program blocks, 70 fixtures ... 0
    errors"); check_faq.py with the new install green. Message: "EH-C (1/3):
    rename Core.Result's alternatives to Success/Failure: prelude, thunk
    identifiers, entry-point epilogue, expected.h, golden sources, programs
    and the pages' code (W-346)".
3.  **F1, the fill**: `autoupdate.sh` to its fixpoint (one pass, a second that
    changes nothing, R26/R28 (d)); only CHECK lines change, verified by `git
    diff F1^ F1 | grep -E '^[-+]' | grep -vE '^(\+\+\+|---)|^[-+]\s*// CHECK:'`
    being empty; the 32 files of §4 and no other. Gate after: 2047 of 2047.
    Message: "EH-C (2/3): fill C1's goldens (autoupdate)", its body naming the
    32 files.
4.  **P, the prose**: Appendix C's amendment paragraphs and D1's rewrite,
    nothing else (no code, no record that claims a discharge). r31.py before
    and after; the designdocs checker's W2 rule still 0 errors (an amendment
    is a blockquote, not a heading). Message: "EH-C (3/3): the error-handling
    pages' dated amendments for Success/Failure, upstream quoted at
    <tip>".
5.  **Two implementation reviews** (R11: separate agents; R29 (c)), against
    C1 to P, each with the composition mirror of §8.8 measured before it
    starts.
6.  **Fix commits, at most two**, each with its own fill when it changes a
    golden (the fill is not counted); a records-only commit is not a fix
    commit (VA-2's rule). _Break condition:_ a third defect that needs a
    toolchain, golden or program change stops the PR at a plan revision (rev
    2) that re-plans it at its root; the shrink line is D-EHC-9's (the prose
    may split or follow; the rename never shrinks).
7.  **R, the records that claim no discharge**: the decision-log entry EH-C (D.2
    without its three D-time paragraphs, the reconciliation greps, the id
    re-scan and the discharge line, which D appends; amended 2026-11-09, review
    fold: B-M3), the F-006a reversal note (D.3), the RG-1 and other dated notes
    (D.4, D.5), the register rows and files (D.6, checked at the re-fetched tip
    with check_greps.sh and check_quotes.sh, every count and quote re-read), gap
    row 70's example (D.7 second item), fork/eh/plan.md's pointer (D.9),
    fork/README.md's note (D.10). Message: "EH-C records: decision-log entry
    EH-C, F-006a's reversal note, register row T2.1 ALIGNED, dated notes".
8.  **D, the discharge**: the ledger (W-346 DISCHARGED, W-380 filed; D.1), gap
    row 73's evidence (D.7), ORCHESTRATION's header, dated paragraph, Branches
    row and Next actions item 6 and the F.3 paragraph (D.8), and
    fork/decision-log.md: the three paragraphs D.2 marks "appended by D" (the
    greps, run on the tree at <R> and written "the tree at <R>"; the id
    re-scan's `<n>` refs and `<w>` worktrees; the discharge line, written "_Discharged
    by this commit: W-346 (EH-C)._" because a commit cannot carry its own sha,
    OV-4's "and this one"); the placeholders D fills are `<R>`, `<count>`,
    `<n>`, `<w>`, `<date>` and, in D.8, `<C1>`, `<F1>`, `<P>`, `<fixes>`,
    `<landed>` and `<prev>` (amended 2026-11-09, review fold: B-M3 / RR1-M1); no
    text R or D writes names a PR number or its own commit's sha: `<N>` exists
    only after item 10, `<k>` after item 9's round, and D's own sha is "this
    commit" or "this one" (RR1-M1); every other `<...>` filled from the commits
    and runs it names, after the reviews and their fixes; `json.load` of the
    ledger, `runner.py --self-test`, the model-identifier grep of the branch's
    diff, the id re-scan (§8.9), the reconciliation greps (§8.7). Message: "EH-C
    discharge: W-346 DISCHARGED; W-380 filed; gap row evidence and
    ORCHESTRATION".
9.  **The focused re-review**, OV-4's: one fresh agent per round over the fix
    commits, R and D; dry when no BLOCKER, no MAJOR and only records-only
    MINORs, folded by one records commit; at most three rounds. The dry
    round's records commit changes D.8's Branches row's leading phrase to
    "IMPLEMENTED AND REVIEWED; RE-REVIEW ROUND <k> DRY (base trunk
    725570464)" and gives D.8's dated paragraph one sentence naming the
    round, its verdict and D's sha, as OV-4's did (ov4-plan.md D.8; added
    2026-11-09, review fold: RR1-M1).
10. **The PR's records, the orchestrator's (added 2026-11-09, review fold:
    RR1-M1):** the PR number exists only once the orchestrator opens the PR
    after the dry round, so no commit of items 2 to 9 names it. The texts
    that name it are the orchestrator's, written once `<N>` exists:
    fork/ORCHESTRATION.md's dated paragraph "<date> (<hh:mm> UTC): EH-C is
    IMPLEMENTED, REVIEWED AND HELD OPEN as PR <N> (claude/carbon-fork-0-1-ehc
    at <head>, base trunk; commits <plan revisions>, <M-0>, <C1>, <F1>, <P>,
    <fixes>, <R>, <D> and the round's records commit)", the header clause
    "Last updated: <date> (EH-C's PR <N> opened, W-346's rename; <landed>
    PRs landed, 1 held, 1 open; see the Branches row; the earlier <prev>
    text follows)", Next actions item 6's "is open as PR <N> (<date>)" and
    ":2725"'s "W-346 (PR <N>)". When the landing follows the opening in the
    same session (R33: landed when correct), they are omitted and Appendix
    F's texts alone name the PR; a held PR gets them in trunk's worktree,
    where they reach trunk with the next records commit, LAND-1's for this
    PR at the latest, as OV-4's paragraph of 2026-10-28 (13:28 UTC) reached
    trunk in PR 68's records commit fe0957d54. The Branches row keeps the
    round's phrase until F.4 replaces it.

**The PR** (Appendix E) opens with base trunk after a dry round, held until
the orchestrator lands it (R33). **Land-time steps** (D-LAND-6, one landing
reviewer, Appendix F's texts): (M) if trunk moved since M-0's merge base
(725570464; trunk's first moves, PR 69 and the arbiter scripts' records
commit, are M-0's; amended 2026-11-09, review fold: B1), `git merge --no-ff` of
trunk into the branch, conflicts resolved by §6.2's rules, never a rebase, as
FO-1's stage 17 did; (F-M) the refill on the merged branch, if
autoupdate changes anything, CHECK lines only; (L) the arbiter re-run on the
branch's head (build, install, gate 2047 of 2047, conformance 228/0/13 over
241, the three checkers, prek) quoted into Appendix F's records; the landing
reviewer's report; the merge into trunk by the orchestrator, the two pushes,
`merged: true`, then the records commit with F.3 to F.9 filled.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

Hand-traced predictions, then the measured fill (the fixer's prototype, §0.3;
the numbers are the new CHECK lines the fill writes per file, classified by
one rule so that an implementer reproduces them from `git diff -U0`: "name" =
a new CHECK line containing `Success`, `Failure`, `success` or `failure`;
"stderr" = a `CHECK:STDERR` line without one; "loc" = every other new CHECK
line, which moves only a `locLL_CC` or `[[@LINE+N]]:CC` column or is
reprinted for its position; the three sum to the total. Rev 1's "loc" column
followed a narrower rule the plan did not state and is replaced; the totals
are rev 1's except the three goldens D-EHC-13 touches, which gain the
`unit_success`/`i32_success` header, `ModuleID`, `source_filename` and
`DIFile` lines; amended 2026-11-09, review fold: B-M1 / A-m3 (f) / the fixer's
F-2). Prediction, then measured, for every refilled file:

-   Why columns move: SemIR instruction names embed line and column
    (`%.loc28_30`), and `Success`/`Failure` are 5 and 4 characters longer than
    `Ok`/`Err`, so every instruction to the right of a renamed token on the
    same line gets a new column; a diagnostic's `[[@LINE+N]]:CC`, its quoted
    source line and its caret line move the same way. No line number moves
    (the rename is in-line) except in the new split's own file.
-   Why names move: SemIR names the alternatives' constructors and patterns
    (`%Ok.ref`, `%Ok.decl`, `@Ok`, `%Ok.type`, `%Ok.patt`, `Ok.specific_fn`,
    `%Err.call`); lowered IR names the functions `@MyResult.Ok`,
    `@Result.Success.<hash>` and the entry point's blocks and message global;
    parse dumps print identifiers (`IdentifierNameNotBeforeSignature 'Ok'`).
-   Three edited goldens have no CHECK line that moves (measured, as
    predicted from their CHECK lines containing no name and no column right of
    a rename): check interop/cpp/function/export/result_expected.carbon (its
    CHECK lines show the thunk's C++ return type and the `imports` block,
    never an alternative), match/fail_case_never_matches_full_coverage.carbon
    (its diagnostics quote arms with no alternative on the line) and
    operators/fail_question_final.carbon (its diagnostics point at `?`
    operands left of any rename).

| Golden | Predicted | Measured (name / stderr / loc-only of total new CHECK lines) |
| --- | --- | --- |
| check/choice/payload_construct.carbon | `%Ok`/`%Err` names, `IntResult.Err` ref, columns on :28 | 14 / 0 / 42 of 56 |
| check/interop/cpp/exceptions/catching_thunk.carbon | every `?`-selected call's two constructor accesses by name, the convergence's columns on seven `return` lines | 209 / 0 / 470 of 679 |
| check/interop/cpp/exceptions/fail_catching.carbon | seven diagnostics' quoted lines, carets and columns (`:45` to `:50`) | 12 / 19 / 0 of 31 |
| check/interop/cpp/exceptions/fail_catching_none_mode.carbon | one diagnostic's line and caret | 2 / 4 / 0 of 6 |
| check/interop/cpp/stdlib/optional.carbon | one `case .Ok` quoted in a diagnostic | 2 / 1 / 0 of 3 |
| check/main_run/return_result.carbon | the six `return` lines' constructor names and columns in four positive splits, and the `--- unit_success.carbon` / `--- i32_success.carbon` headers (D-EHC-13) | 36 / 0 / 39 of 75 |
| check/match/choice_payload_guard.carbon | the user choice's names, columns on three `case` lines | 12 / 0 / 131 of 143 |
| check/match/choice_payload_pattern.carbon | the same, two `case` lines | 12 / 0 / 71 of 83 |
| check/match/exhaustive_choice.carbon | two user choices, five `case` lines | 24 / 0 / 202 of 226 |
| check/match/fail_case_never_matches_alternative.carbon | four diagnostics quoting `.Ok(42)` arms | 4 / 0 / 0 of 4 |
| check/match/fail_choice_alternative_pattern.carbon | seven diagnostics (`.Ok`, `.Err()`, `.Ok(.Err)`, `IntResult.Err`) | 7 / 5 / 0 of 12 |
| check/match/payload_subpattern.carbon | the names and three `case` lines' columns | 2 / 0 / 134 of 136 |
| check/match/usefulness_no_false_positive.carbon | six diagnostics quoting arms | 4 / 2 / 0 of 6 |
| check/operators/fail_question.carbon | diagnostics quoting `MyResult(...).Ok(...)` lines | 4 / 2 / 0 of 6 |
| check/operators/fail_question_generic.carbon | the `var unused mr: ... .Err(0)` diagnostic | 3 / 1 / 0 of 4 |
| check/operators/question.carbon | five user choices' names across the splits, every `return ... .Ok(...)` column | 107 / 0 / 224 of 331 |
| check/operators/question_final.carbon | four user choices' names (its dumps print names only) | 38 / 0 / 0 of 38 |
| check/operators/question_optional.carbon | three diagnostics quoting `.Ok(o?)` | 4 / 3 / 0 of 7 |
| check/operators/question_result.carbon | `Core.Result`'s `%Success`/`%Failure` names in four positive splits, their columns, the `--- unit_success.carbon` header (D-EHC-13), plus the new split's two diagnostics (quoted in §4's note below) | 64 / 8 / 112 of 184 |
| lower/interop/cpp/exceptions/catching_thunk.carbon | `@Result.Success...`/`@Result.Failure...` callees, the `?` columns in `!dbg` lines | 44 / 0 / 81 of 125 |
| lower/interop/cpp/function/export/result_expected.carbon | the constructor callees (`@Result.Success.<hash>`) | 12 / 0 / 5 of 17 |
| lower/main_run/return_result.carbon | `@main.result.failure.message` as `[75 x i8]` with the new text and `i64 74`, `%run.result.is_success`, `run.result.success:` and `run.result.failure:` labels, both splits, and their `unit_success.carbon` / `i32_success.carbon` names in the `---` headers, `ModuleID`, `source_filename` and `DIFile` lines (D-EHC-13) | 46 / 0 / 23 of 69 |
| lower/match/choice_payload.carbon | `@IntResult.Success` callee, `case` columns | 6 / 0 / 15 of 21 |
| lower/match/payload_subpattern.carbon | the same | 8 / 0 / 29 of 37 |
| lower/operators/question.carbon | `@MyResult.Success...` callees, `return` columns | 38 / 0 / 79 of 117 |
| lower/operators/question_generic.carbon | the same | 20 / 0 / 40 of 60 |
| lower/operators/question_generic_crossfile.carbon | the same, and three `CHECK:STDERR` lines (the file's expected unused-binding warnings quote a `.Err` line) | 65 / 2 / 90 of 157 |
| lower/operators/question_generic_final.carbon | the same | 20 / 0 / 35 of 55 |
| lower/operators/question_generic_mixed.carbon | the same, three warnings | 26 / 2 / 55 of 83 |
| lower/operators/question_result.carbon | `@Result.Success.<hash>`/`@Result.Failure.<hash>` callees | 39 / 0 / 45 of 84 |
| parse/match/alternative_pattern.carbon | `IdentifierNameNotBeforeSignature 'Success'` and `'Failure'` | 3 / 0 / 0 of 3 |
| parse/match/fail_alternative_pattern_unclosed.carbon | the unclosed `case .Ok(value: i32 =>` diagnostic's line, caret and columns | 5 / 8 / 0 of 13 |

The new split's fill, measured (the implementer's F1 must reproduce it; the
`[[@LINE+4]]` offsets are autoupdate's):

<!-- google-doc-style-ignore -->

```text
  // CHECK:STDERR: fail_old_names.carbon:[[@LINE+4]]:10: error: member name `Ok` not found in `Core.Result(i32, i32)` [MemberNameNotFoundInSpecificScope]
  // CHECK:STDERR:   return Core.Result(i32, i32).Ok(1);
  // CHECK:STDERR:          ^~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
    // CHECK:STDERR: fail_old_names.carbon:[[@LINE+4]]:10: error: member name `Err` not found in `Core.Result(i32, i32)` [MemberNameNotFoundInSpecificScope]
    // CHECK:STDERR:     case .Err(e: i32) => { return e; }
    // CHECK:STDERR:          ^~~~~~~~~~~~
    // CHECK:STDERR:
```

<!-- google-doc-style-resume -->

Lower main_run/return_result.carbon's message line, measured:
``@main.result.failure.message = private unnamed_addr constant [75 x i8]
c"carbon: `Main.Run` returned `.Failure` of type `i32`; exiting with code
1\0A\00", align 1`` (was `[71 x i8]` with `.Err`), and its `call i64
@write(i32 2, ptr @main.result.failure.message, i64 74)` (was `i64 70`).

## §5 Conformance delta (from trunk's 228 PASS / 0 FAIL / 13 SKIP over 241, re-measured)

Zero: the prototype's scoreboard is PASS 228 / FAIL 0 / SKIP 13 over 241, 51 of
56 bullets, every program's status and every bullet byte for byte trunk's
(§0.3). No program is added, removed, SKIPped or un-SKIPped; no EXPECT moves
(Appendix B). The order-swap mutant's four red programs (§0.3 M1) are the
proof that the programs exercise the discriminant order and the header; the
partial-thunk mutant's red goldens (M2) that the catching thunk exercises the
identifiers. The README table keeps 241 programs and 56 bullets; its two rows
for the renamed programs spell the new paths (D-EHC-13), and `runner.py
--self-test` prints "241 programs parsed, 56 bullets in table, OK" on the
fixer's prototype.

## §6 Churn and collisions

### §6.1 Churn

Seventy-three files (amended 2026-11-09, review fold: A-m1 / B-M1): 35
goldens (350 source lines; 32 of them refilled, 2871 CHECK lines written) and
one new split (20 lines), 18 programs (159 lines; two renamed) with
fork/conformance/README.md's two rows, 13 toolchain, prelude and header files
(128 lines replaced and 10 added, before clang-format's wraps), 5 docs (38
lines plus Appendix C's amendments) and check_faq.py (3 lines); the
records of Appendix D in R and D (fork/decision-log.md, the ledger,
fork/register/rg1-plan.md, rg1-checks.tsv, rg1-quotes.tsv, fork/gap-analysis.md,
fork/ORCHESTRATION.md, fork/eh/plan.md, fork/README.md, this plan). No BUILD
file, no diagnostic kind, no new golden file, no new program. Prelude line
numbers do not move: §2.1 keeps result.carbon's comment at eight lines, the
choice at :28 and `FromBreak` at :51, and puts the history after :52, because
goldens quote `result.carbon:28` and `:51`, six lower goldens embed the file's
function lines in `DISubprogram` entries (the four of §4 plus
interop/cpp/template_symbolic_arg.carbon and
variadics/tuple_segment_destroy.carbon, measured with `git grep -l
result.carbon toolchain/lower/testdata` at aee70185c) and twelve check
goldens name the file (EH-A's optional.carbon lesson: a shifted prelude line
moves every golden that embeds it). Measured: the prototype renamed in place,
kept the line count, and no golden outside §4's 35 moved.

### §6.2 Collisions and the merge rules

PR 53 (§0.4): none in EH-C's code, docs or goldens; the four records files by
LAND-1's region rules at PR 53's landing; rust_interop.md:223 by W-380's rename
commit on PR 53's branch before it lands. ARB-2 LANDED on trunk as PR 69
(fca1e9e2f, 2026-11-09; the Status paragraph): it touches
toolchain/check/check.cpp (no use site) and three records files that EH-C's R
and D edit too (amended 2026-11-09, review fold: B-m4): the ledger, where both
insert after W-377 (M-0 merges trunk first, so W-380 is inserted after W-378 and
no conflict arises; were the order ever reversed, the rule is both items kept in
id order, W-378 then W-380); fork/decision-log.md, where ARB-2's entry is
appended at the end (:20650) and EH-C's goes before EH-B's (:17707), disjoint
regions; fork/ORCHESTRATION.md, where PR 69's pending LAND-1 records commit (the
header's count, a Branches row, a dated paragraph) and EH-C's D.8 edit the same
regions, resolved by LAND-1's region rules (every row, paragraph and item once;
the header's landed count read at the time of writing: 18 after PR 69's records,
19 after EH-C's landing), EH-C's Branches row placed after PR 69's once it
exists (D.8). After M-0 the gate's `src-patches.applied` line prints `landed`
(the arbiter compiles trunk's check.cpp, whose only difference from the patch is
a five-line comment). If trunk moves again in any other file EH-C touches, the
rule is: the toolchain and prelude keep trunk's side plus the rename (a conflict
in a renamed line is re-renamed by hand and re-measured); goldens take trunk's
side and are refilled (F-M), never merged by hand (R16); records keep both sides
by LAND-1's region rules.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1 — a use site the inventory missed.** Falsifier: one of §8.7's four
    greps, at C1, D or L, answers anything but its listed lines (amended
    2026-11-09, review fold: A-M1 / B-M1). Response: a fix commit (budget)
    renames it at the root; never an allowlist.
-   **R-2 — a golden's purpose was the old name.** Falsifier: a review shows a
    test whose CHECK lines or comments assert the identifier text `Ok`
    itself. Response: that golden keeps a user choice named `Ok` with a
    comment saying why (D-EHC-8's break condition). Measured: none of the 35.
-   **R-3 — the sample checkers go red on a commit.** Falsifier: `runner.py
    --self-test` or check_faq.py red on C1, F1 or P. Response: the missing
    line joins C1 by a fix commit (D-EHC-9's break condition); measured green
    on the C1 state.
-   **R-4 — the fill moves a golden §4 does not list (a prelude line
    moved).** Falsifier: F1 rewrites a file outside the 32. Response: if every
    changed line is a `DISubprogram`/`DILocation` line or a `result.carbon:NN`
    note, result.carbon's line count or the position of :28 or :51 moved
    (§2.1 forbids both): restore the eight-line comment and the trailing
    history, refill, and the file reverts; any other change is a §4 miss,
    stop and reconcile.
-   **R-5 — `<carbon/expected.h>`'s rename breaks a consumer.** Falsifier:
    a consumer of the header names `.ok()`, `.ok` or `.err` of an `expected`:
    §8.7's grep 4 (the scoped `\.ok\(\)` grep over the header's consumers
    and `expected<[^>]*>::ok\(` over the tree). Response: measured 0 for
    both at aee70185c and on the prototype (D-EHC-5; the unscoped grep's 180
    `ErrorOr::ok()`-family lines are not consumers; amended 2026-11-09,
    review fold: A-M3 / B-M2); an external consumer would be a veto route,
    not a code change.
-   **R-6 — rumdl's reflow manufactures a heading or list item (R31).**
    Falsifier: r31.py's counts differ before and after prek on any markdown
    file beyond the headings, items and rows the commit adds. Response:
    rephrase, never revert the reflow. Measured: the prototype's three
    reflowed pages keep their counts.
-   **R-7 — trunk moves before the landing.** Fired once already: trunk
    moved to fca1e9e2f (PR 69) while the reviews ran, taken by M-0 before C1
    (amended 2026-11-09, review fold: B-m4). Falsifier: `git ls-remote origin
    trunk` differs from M-0's merged trunk at land time. Response: M, F-M and
    a full re-measure (§8.8); a new use site joins a fix commit.
-   **R-8 — the user vetoes the reversal.** Falsifier: a veto. Response:
    D-EHC-1's veto route: a revert commit of C1, F1 and P with a refill, the
    F-006a note amended, the veto recorded against R32, W-346 withdrawn; the
    register row returns to DRIFT with the veto as its break condition.

### §7.2 Rejected alternatives (each with its falsifier)

-   **An alias or a deprecation period** (`alias Ok = Success` or a second
    constructor). Rejected: a second spelling is the drift (R32 (d)); the
    prelude cannot even declare an alternative alias (p8). Falsifier: an
    owner ruling that asks for a migration window (then it is a dated
    exception recorded against R32, not an alias in the prelude).
-   **Keeping `Ok`/`Err` in the docs as "also spelled".** Rejected: the pages
    are the fork's design statements and would then state two spellings;
    history is kept by the dated amendments instead (D-EHC-6). Falsifier:
    a review shows a reader need the amendments do not meet.
-   **Renaming the payload fields** (`value`/`error`) or **the parameter `E`**
    to `Error`. Rejected: the fields already match upstream (:2176-2177,
    :3165-3166); the parameter name is outside D-RG-5's ground and never
    user-visible (D-EHC-1). Falsifier: an upstream prelude `Result` (take its
    names) or a weekly-check classification of `E` as a drift (its own item).
-   **Changing the order to match some other text** (p000157's `Success`
    first is the same order; Rust's `Ok`/`Err` is not upstream). Rejected:
    the order is upstream's README's and the measured M1 shows what moving it
    breaks. Falsifier: upstream reorders (D-EHC-1's break condition).
-   **Deferring to UA-3.** Rejected: W-346 is scheduled before UA-3 by RG-1
    and ORCHESTRATION item 6, the rename needs no advance, and landing it
    first keeps UA-3's conflict set free of a spelling it would otherwise
    carry through every golden. Falsifier: UA-3 starting before this PR lands
    (then EH-C re-measures on the advanced trunk, §6.2).
-   **A migration note on the diagnostic** ("did you mean `Success`?").
    Rejected: it would keep the old name in the toolchain and special-case a
    recognizable input (D-EHC-3). Falsifier: an owner ruling.
-   **Leaving user test choices as `Ok`/`Err`.** Rejected: D-EHC-8 (the
    teaching-material argument and the clean grep). Falsifier: R-2.
-   **One commit for everything.** Rejected: F1 must be separable from C1 so
    the fill is verifiably CHECK-only (R16 (a)), and P from C1 so the prose is
    reviewable apart from the mechanical rename; D-EHC-9 keeps each green.
    Falsifier: a commit that cannot build or pass its checkers without a later
    one (then they merge, recorded in the landed notes).

## §8 Verification

### §8.0 The planner's measurements (done, §0.3)

Build, install, gate before the fill (2015 of 2047, 32 "Autoupdate would make
changes"), autoupdate to its fixpoint, gate after (2047 of 2047), conformance
(228/0/13 over 241), the three checkers, the probes, prek to a fixpoint (two
passes), the mutants M1 and M2, the reconciliation grep, the id re-scan, R31's
counts on the reflowed pages; the worktree and the label's directories
(/home/user/arb/build/ehc-planner, install/ehc-planner,
conformance/ehc-planner, cache-ehc-planner) removed afterwards. The fold of
2026-11-09 re-ran all of it as `ehc-fixer` with D-EHC-13's and A-m1's
changes (M2 with the prelude restored and re-installed first, then M1's gate
again), applied Appendix C's prose for the after-P grep, ran prek to a
fixpoint, measured the merge-trees of §8.8 on a local commit of the
prototype, and removed its worktree and the label's four directories the
same way.

### §8.1 Build (implementer)

The arbiter's `build.sh` with its worktree and label variables (paths.sh)
set to the implementer's worktree and label, in the background (about 9 to
12 minutes at -j4; `pgrep -fa 'ninja -C|file_test|runner.py'` first: wait for
another workflow's build), then `install.py` the same way; the command form:

<!-- google-doc-style-ignore -->

```sh
REPO=/home/user/carbon-ehc-<role> SHA=ehc-<role> /home/user/arb/carbonbuild/build.sh
```

<!-- google-doc-style-resume -->
The implementer's prototypes never happen in /home/user/carbon-ehc: a detached
worktree /home/user/carbon-ehc-<role> at the branch's head, removed when done.

### §8.2 Autoupdate to its fixpoint

`autoupdate.sh` after C1; `git status --porcelain` lists the 32 files of §4
and no other (R-4's rule otherwise); a second pass changes nothing; the gate
proves it (R28 (d)). The non-CHECK diff of F1 is empty (§3 item 3).

### §8.3 Gate

`gate.sh --threads 4`: on C1 alone, `[  PASSED  ] 2015 tests.` and exactly
the 32 per-test `[  FAILED  ] ToolchainFileTest...` lines of §4 (and nothing
else), each "Autoupdate would make changes"; the summary line then reads
`GATE <label>: 2015 passed, 0 failed` and the script exits 1, because
gate.sh:121-134 takes its failed count from a gtest "[ FAILED ] N tests,
listed below" summary that file_test does not print and its exit code from
the binary's: the per-test lines are the criterion, never the summary's
second number (amended 2026-11-09, review fold: A-m2; a note for ARB-2's
landing of the scripts, whose files this plan does not touch). After F1 and
after every fix commit's fill, `[  PASSED  ] 2047 tests.` and `GATE <label>:
2047 passed, 0 failed`, exit 0.

### §8.4 Conformance

`CACHE_HOME=/home/user/arb/cache-<label> conformance.sh --background`, waited
with `until [ -f /home/user/arb/conformance/<label>/.done ]` loops; expected
`PASS 228 / FAIL 0 / SKIP 13 over 241 programs; bullets 51 PASS`; any other
figure is a §5 miss. The runner's `--self-test` (both sample checkers) runs
first; check_faq.py `--which fork --toolchain <install>/bin/carbon` and
`--which nightly` separately (0 errors each); fork/designdocs/check_samples.py
`--toolchain` (0 errors).

### §8.5 Mutants (the implementer re-runs M1; M2 if thunk.cpp was touched by a fix)

M1: swap result.carbon's two alternatives, `install.py`, `gate.sh`: `[  PASSED
] 2040 tests.` and exactly the 7 goldens of §0.3 red; conformance exactly the
4 programs red; restore result.carbon and re-install (`gate.sh` 2047 again)
BEFORE M2. M2: the two minted identifiers back to `"Ok"`/`"Err"`, rebuild,
`install.py`, `gate.sh --filter interop/cpp`: `[  PASSED  ] 229 tests.` and
exactly the 3 goldens of §0.3 red (check interop/cpp/exceptions/
catching_thunk.carbon and fail_catching.carbon, lower
interop/cpp/exceptions/catching_thunk.carbon; 14 `Ok` and 14 `Err`
diagnostics); restore, rebuild, re-install, full gate 2047 (amended
2026-11-09, review fold: A-M2: rev 1's "4" was measured with M1's prelude
still installed). Each mutant's output goes in the review hand-off, never in
a commit.

### §8.6 prek, R27 and R31 (every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
XDG_CACHE_HOME=<scratch>/prek-cache uvx prek run --files <paths>` to a
fixpoint (the prototype needed two passes: rumdl's reflow, ruff E501, clang-
format), the cache directory deleted afterwards by its literal path; R27: the
prelude impl diffed against error_handling.md's sketch after both are renamed
(byte-equal modulo the `Core.` qualification, as EH-A left it); R31: r31.py on
every markdown file before the edit, after it and after prek, in the commit
message, with the headings, items and rows the commit adds named.

### §8.7 The reconciliation greps (at C1, at D, at L)

Re-specified 2026-11-09 (review fold: A-M1 / B-M1 / A-M3 / B-M2): four
greps, each with its expected answer as an explicit list. "Only" and
"exactly" mean these lists, which are the dated history D-EHC-2 permits;
anything else is a miss (R-1), and the record never says "only
common/raw_hashtable.h:1314".

1.  `git grep -nE '\bOk\b|\bErr\b' -- . ':!fork/'` on non-CHECK lines
    (piped through `grep -vE '^\S+:[0-9]+:\s*// CHECK'`): at C1 exactly five
    lines, common/raw_hashtable.h:1314 (English), core/prelude/types/
    result.carbon:56 (the history comment), check/testdata/operators/
    question_result.carbon:156, :160 and :166 (the `fail_old_names` split's
    comment and its two deliberate source lines; :164 and :174 after F1);
    from P on, twelve more, the amendment lines of Appendix C:
    docs/design/README.md:4052-4053, docs/design/error_handling.md:119-120,
    :125, :963, :966-967, docs/design/optional.md:434,
    docs/guides/tutorial.md:409 and :411 (:410 between them names neither;
    measured at P, amended 2026-11-09, review fold: RA-m2 / B2) and
    docs/guides/evaluator_faq.md:359
    (the fixer's prototype after prek; before it error_handling.md's D1
    lines were :964, :967-968; the texts are the anchors): seventeen lines
    in all, every one dated history.
    Over fork/, every hit is a closed plan, a dated history note, the
    ledger's own W-346 and W-380 text, a register prose paragraph or this
    plan (§0.1's last two rows), and no conformance program, checker, living
    page or golden source line.
2.  `git ls-files | grep -E '(^|[_/])(ok|err)[_.]'`: empty (D-EHC-13; two
    program files at trunk).
3.  `grep -rnE '^// --- .*_(ok|err)\.' toolchain/check/testdata
    toolchain/lower/testdata toolchain/parse/testdata`: empty (five split
    headers at trunk); and `git grep -nE 'run_result_(ok|err)|unit_ok|i32_ok'
    -- .` lists history only from F1 on (at C1, before the fill, nine CHECK
    lines of the three split-renamed goldens too, which F1 rewrites; measured,
    amended 2026-11-09, review fold: RA-m2 / B2): fork/conformance/out/
    scoreboard.json (4 lines,
    the hosted scoreboard of 2026-10-06), fork/eh/plan.md (5), fork/inventory/
    work-items.json:345 (a discharged item's evidence string at a sha), this
    plan, and fork/gap-analysis.md:73 until D.7 refreshes it (0 there after
    D).
4.  `git grep -nE '\.ok\(\)' -- toolchain/install/include fork/conformance
    docs toolchain/check/testdata/interop/cpp/function/export
    toolchain/lower/testdata/interop/cpp/function/export` and `git grep -nE
    'expected<[^>]*>::ok\('` over the tree: 0 and 1, the
    one line being this plan's own D-EHC-5 sentence, 0 elsewhere (measured at
    C1 and at the head; amended 2026-11-09, review fold: RA-m2 / B2). The
    unscoped
    `\.ok\(\)` grep lists 180 lines in 43 files at aee70185c
    (`ErrorOr::ok()` and its kin) and is not a criterion.

The four answers are recorded verbatim, as the lists above with their counts,
in the paragraph D appends to the decision-log entry (D.2), in D.1 and in F.8.

### §8.8 The composition mirror and the land-time re-run

Before the implementation reviews: `git merge-tree --write-tree
<origin/trunk> <branch head>` (exit 0 expected while trunk is M-0's
fca1e9e2f; with a moved trunk, only records conflicts by §6.2) and `git
merge-tree --write-tree 2407efa74 <branch head>` (PR 53's head: conflicts in
the four records files only, docs/design/README.md auto-merging, as the
fixer's local prototype commit measured, §0.4; amended 2026-11-09, review
fold: B-m11 / B-m4). At land time: §8.1 to §8.4 on the branch's head after M
and F-M, the figures quoted into Appendix F's texts.

### §8.9 The id re-scan (before D)

§0.7's commands after `git fetch origin` over every origin ref, local branch
and worktree, widened to `W-3[7-9][0-9]|W-4[0-9][0-9]`. The criterion
(re-stated 2026-11-09, review fold: RR1-M2, because the rule as first written
named three places and fired on trunk's own fourth, ARB-2's entry): W-380 is
no ledger item's id, `grep -c '"id": "W-380"'` over every ref's and
worktree's fork/inventory/work-items.json giving 0, and every prose
occurrence reserves it for EH-C or lists it as unused; at fca1e9e2f those
are this plan, W-378's notes (work-items.json:5161), the weekly entry's
sentence (decision-log.md:19596) and ARB-2's entry (decision-log.md:20829
and :20831), and a further mention of the same kind on a newer ref is not a
use. A ledger item with the id, or a prose text that files it for other
work, is a use: then the next free id, and every cross-reference in D.1,
D.2, D.8 and this plan renumbered in the same commit. The counts (`<n>`
refs, `<w>` worktrees, the ledger count 0, the prose occurrences listed) go
in D.2's _Ids_ paragraph.

### §8.10 Not run, and why

clang-tidy: the container's kept clang 21 subset has no clang-tidy binary
(the arbiter's compile_commands.json exists under the build directory, so a
future run needs only the binary); R21's hosted gate (Actions disabled, owed
when it returns, R33 (b)); Bazel-only tests (no Bazel, never installed); the
owner's runner (R28); the nightly on the fork's programs (it has no
`Core.Result`); a Darwin build (V-1's macOS half, the same bound as EH-B's).

### §8.11 Command forms for this container (added 2026-11-09, review fold: B-m8)

D-LAND-6's steps were written for the previous container (a scratch worktree
under /dev/shm, `$CB/build.sh /home/user/carbon-trunk`); this landing maps them
to the arbiter as it stands (/home/user/arb/carbonbuild until ARB-2's scripts
land under fork/tools/carbonbuild), with the arbiter's two variables set on
every command as the block below spells them (paths.sh:15 and :17; §8.1's
form) and nothing under /dev/shm. The worktree variable's name is spelled
only inside guarded blocks, because the Google-style hook expands it in prose
and in code spans, which is how rev 2 came to misspell it; a misspelt name
silently builds paths.sh's default, this worktree at land time and wrong
anywhere else (corrected 2026-11-09, review fold: RR1-m1):

<!-- google-doc-style-ignore -->

```sh
REPO=/home/user/carbon-trunk SHA=<label> /home/user/arb/carbonbuild/build.sh
REPO=/home/user/carbon-trunk SHA=<label> python3 -I /home/user/arb/carbonbuild/install.py
REPO=/home/user/carbon-trunk SHA=<label> /home/user/arb/carbonbuild/gate.sh --threads 4
REPO=/home/user/carbon-trunk SHA=<label> /home/user/arb/carbonbuild/autoupdate.sh
REPO=/home/user/carbon-trunk SHA=<label> CACHE_HOME=/home/user/arb/cache-<label> /home/user/arb/carbonbuild/conformance.sh --background
```

<!-- google-doc-style-resume -->

-   step 2: the merge-trees run in a detached worktree under /home/user
    (`git -C /home/user/carbon-lang worktree add --detach
    /home/user/carbon-land-<role> <sha>`), removed by its literal path;
-   step 4: the block's `build.sh` line in the
    background (a timeout of 7200000 ms; waited with `until [ -f <marker> ];
    do sleep 20; done` loops of at most nine minutes), then `python3 -I
    install.py`, `gate.sh --threads 4` (its per-test lines read, §8.3), and
    `CACHE_HOME=/home/user/arb/cache-<label> conformance.sh --background`
    waited on /home/user/arb/conformance/<label>/.done; the label's four
    directories deleted by their literal paths afterwards;
-   step 7: `autoupdate.sh` over the whole manifest (`--filter` for a subset)
    to a fixpoint, `git status --porcelain` read after each pass;
-   step 8: the two sample checkers as D-LAND-6 writes them (`python3 -I
    fork/designdocs/check_samples.py`, also with `--toolchain
    /home/user/arb/install/<label>/bin/carbon`, and `python3 -I
    fork/evaluator/check_samples.py`), then EV-1's land sequence
    (land1-plan.md:1640-1648): `python3 -I fork/evaluator/check_faq.py --which
    fork --toolchain /home/user/arb/install/<label>/bin/carbon` and `--which
    nightly --toolchain /home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.
    2026.10.12/bin/carbon`, 13 and 17 reproducers, 0 errors each;
-   the FORM rules for every commit, merge and push (the container's
    permission check holds what breaks them, and a held command never
    completes): the message written to a file with the Write tool or in its
    own command, then `git commit -F <file>` in a separate command; never a
    heredoc or an inline file write in the same command as a git commit,
    merge or push; never `$(git ...)`; never a git command inside a `for` or
    `while` body (lists go to files first, then `xargs -a`); `rm -rf` on
    literal paths only; every date from `date -u +%F`; commits with
    `--author='jmann345 <jerrymannstan@gmail.com>'`, `GIT_COMMITTER_NAME=Claude
    GIT_COMMITTER_EMAIL=noreply@anthropic.com` and the session's attribution
    trailers after a blank line.

## Hand-off notes for the implementer

-   Start with M-0 (§3): merge origin/trunk (fca1e9e2f or later) into the
    branch before C1; the gate's src-patches line then prints `landed`.
-   Rename on NON-CHECK lines only (the prototype's script matched
    `^\s*// CHECK`, indented ones included); never touch a CHECK line (R16);
    autoupdate fills them. Whole-word `\bOk\b|\bErr\b` leaves `ErrA`, `ErrB`
    and `ToErrB` alone, as it must. Then D-EHC-13's names: `git mv` the two
    programs and edit fork/conformance/README.md's two rows in C1; rename the
    five split headers (and the lower golden's `unit_ok` comment); and A-m1's
    lines: thunk.cpp's `return_ok`/`return_err` and the lower golden's
    :18-20.
-   result.carbon:33-39 is verbatim in §2.1 (seven lines, 80 columns): copy
    it, as the eight-line comment and the trailing history block.
-   The C1 gate's summary line reads "2015 passed, 0 failed" with exit 1:
    read the 32 per-test FAILED lines (§8.3), not the summary.
-   The FORM rules and the container's command forms are §8.11.
-   Two prek hooks rewrite this plan's own text: rumdl's MD011 turns the
    file-name grep's `(ok|err)` group followed by its bracket class into the
    reversed, empty pattern inside a table cell (code spans are honored in
    list items, not in cells), and the Google-style hook expands the
    arbiter's worktree variable's name in prose and in code spans. The
    pattern is spelled once, in §8.7's list; the variables once, in §8.11's
    guarded block (§8.1's form): re-read both after every prek pass (rev 2's
    RR1-m1 and RR1-m2 were the hooks' doing; added 2026-11-09, review fold:
    RR1-m1 / RR1-m2).
-   Write Appendix C's sentences by hand: a mechanical rename produces "an
    `Success` value" and "an `Failure` payload" (measured).
-   check_faq.py:229 must be two literals (ruff E501); clang-format re-wraps
    four C++ files; rumdl reflows the long lines in the pages (rev 1's seven
    in three pages at C1; more after P's amendments): run prek twice and
    compare r31.py before and after.
-   The new split goes after `fn Use(unused r: Core.Result(SomeClass, i32))
    {}` and before the trailing `// CHECK:STDOUT:` block, CHECK-free; its
    fill must equal §4's quoted lines.
-   Keep result.carbon's amendment comment at the §2.1 text; then measure
    whether any lower golden outside §4 moves (R-4, §6.1) and act by that
    rule.
-   The tutorial's block and project/evaluator_tutorial_errors.carbon must
    stay byte-identical (the checker compares after the program's leading
    comment block); rename both in C1.
-   The thunk's `err_*` out-pointer locals, the oracles' `bool ok` and
    raw_hashtable.h's "Ok," stay (D-EHC-4); payload_construct.carbon's `let
    err` binding stays (D-EHC-8).
-   The mutants (M1, M2) are measurements for the review hand-off; restore
    before every commit and re-run the full gate once after M2's rebuild.
-   The arbiter's GATE line prints `src-patches.applied` (`landed` on the
    branch after M-0, `applied` on a tree without PR 69's check.cpp); the
    number to quote is "2047 passed, 0 failed" with that line beside it, as
    every container-measured record since ARB-2 does.

## Review fold record (rev 2, 2026-11-09)

Reviews A and B (both APPROVE-WITH-AMENDMENTS; six and eleven findings, three
MAJOR each, B-M2 the same defect as A-M3) are folded above, each amendment
marked "(amended 2026-11-09, review fold: <id>)". Every measurement a finding
rests on was reproduced by the fixer on its own prototype
(/home/user/carbon-ehc-fixer at aee70185c, label `ehc-fixer`, the rename
re-applied by its own script with D-EHC-13's and A-m1's changes; worktree and
the label's four directories removed afterwards, as were the scratch caches):
build 9 minutes; gate before the fill `[  PASSED  ] 2015 tests.`, 32 per-test
FAILED lines, summary "2015 passed, 0 failed", exit 1; autoupdate twice
(identical status after each); gate 2047 of 2047; conformance 228/0/13 over
241, 51 bullets, every row's status and detail equal to cb726a230's with the
two renamed programs mapped; `runner.py --self-test` OK; the evaluator and
designdocs checkers 0 errors (the latter also `--toolchain`); check_faq.py 13
(fork) and 17 (nightly), 0 errors; M2 with the prelude restored and
re-installed first: 229 passed, 3 red, 14 `Ok` and 14 `Err` diagnostics;
restored 2047; M1: 2040 passed, the same seven goldens; restored 2047;
Appendix C's prose applied for the after-P grep (17 lines); prek to a
fixpoint (five passes: pass 1 reflowed the pages and wrapped the C++, the
fixpoint held from pass 4 after F-3 and §2.9's split); the register scripts
at ca1898506 (289 quotes, 94 then 96 checks, 0 failed); the id re-scan (84
refs, 7 worktrees); merge-trees of the prototype's local commit against
2407efa74 (the four records files) and fca1e9e2f (exit 0); R31's counts of
the five pages unchanged before and after prek. Nothing is rejected.

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| A-M1 | MAJOR | folded, reproduced (5 lines at C1, 17 from P) | §8.7 re-specified as four greps with explicit lists; §0.3, D-EHC-2, D.1, D.2 (D's appended paragraph), F.8 |
| A-M2 | MAJOR | folded, reproduced (229 passed, 3 red) | §0.3 M2, §0.8 (b), §8.5 (the prelude restored before M2), D-EHC-4, D.2, Appendix E |
| A-M3 | MAJOR | folded, reproduced (180 lines in 43 files unscoped at aee70185c, 182 on the rev 1 commit from this plan's own text; 0 scoped) | D-EHC-5, R-5, §8.7 grep 4, D.2 |
| A-m1 | MINOR | folded, in the prototype | D-EHC-4, §2.2 (`return_success`/`return_failure`), A.2.3 (:18, :20), §0.1, §0.3 |
| A-m2 | MINOR | folded, reproduced (the GATE line and gate.sh:121-134) | §0.3, §3 item 2, §8.3, hand-off |
| A-m3 | MINOR | folded: (a) one unrelated line, (b) :227-229, (c) 94 and 96, (d) size M kept, (e) W-378 on trunk, §0.7 re-scanned, (f) 2871 written and 2863 removed with the rule stated | §0.6, §0.7, header, D.1, D.6, §0.1, §0.3, §4 |
| B-M1 | MAJOR | folded: D-EHC-13 renames both program files and the five split headers; measured (gate, conformance, self-test, greps 2 and 3 empty) | D-EHC-13, §0.1 (a row), §0.3, §2.6, §2.7, §4 (three rows re-measured), §5, §6.1, §8.7, A.1.7, A.1.22, A.2.3, B.1.15, B.1.16, B.2, D.7, hand-off |
| B-M2 | MAJOR | folded with A-M3 | the same |
| B-M3 | MAJOR | folded | §2.10, §3 items 7 and 8, D.1 ("the tree at <R>"), D.2 (the three paragraphs D appends; "this commit") |
| B-m4 | MINOR | folded and widened: ARB-2 landed on trunk as PR 69 while the reviews ran | the Status paragraph, §3's M-0, §6.2, §8.8 (merge-tree against trunk: exit 0), D-EHC-11, D-EHC-12, R-7, D.1, D.8, Appendix E, F.1 |
| B-m5 | MINOR | folded | D.1's title form; size M, header |
| B-m6 | MINOR | folded, the seven lines measured at 80 columns or less | §2.1, hand-off |
| B-m7 | MINOR | folded | C.4, §0.3 |
| B-m8 | MINOR | folded | §8.11; D-EHC-9's check_faq.py step (EV-1's sequence after step 8); hand-off |
| B-m9 | MINOR | folded, measured (0 at ca1898506, 96 checks) | D.6, §0.6, D-EHC-7, D.2 |
| B-m10 | MINOR | folded (with PR 69's row) | D.8 |
| B-m11 | MINOR | folded, measured (the three hunks; the prototype's merge-tree) | §0.4, §8.8 |

The fixer's own findings, folded the same way: F-1 B.1.15's :12 After cell
read "an `.Failure`" (now "a `.Failure`"); F-2 §4's "loc" column followed a
rule the plan did not state, so the matrix now states one rule and carries
the fixer's triples for all 32 goldens (the totals are rev 1's but for
D-EHC-13's three); F-3 C.2's amendment quoted upstream's link live, which
fails rumdl's MD051 and the check-links hook in error_handling.md (no
`#choice-types` anchor there), so the quote sets the markup in a code span as
§0.6 does; F-4 the prototype's mechanical rename does not split
check_faq.py:229 (§2.9 already says so; ruff's E501 fails until it is split,
a hand-off reminder). R31's counts of this file: rev 1 headings 1/17/63/53,
bullets 50, numbered 22, rows 685; rev 2 before prek and after it in the
commit message (the added headings are D-EHC-13's none, §8.11 and this
section; the added items are D-EHC-13, §8.7's four greps, §8.11's five
bullets and the hand-off's four; the added rows are §0.1's one and this
table's eighteen).

## Review fold record (rev 3, 2026-11-09)

The focused re-review RR1 of rev 2 (51013a4a6; APPROVE-WITH-AMENDMENTS: no
BLOCKER, two MAJORs, five MINORs, every one a plan-text amendment; its own
prototype `ehc-rr1` reproduced rev 2's figures, gate 2047 of 2047, conformance
228/0/13 over 241 with 51 bullets, grep 1's five and seventeen lines, M1's seven
goldens and four programs, M2's three goldens) is folded above, each amendment
marked "(amended 2026-11-09, review fold: RR1-<id>)". Every measurement a
finding rests on was re-measured by the fixer in the container
(scratchpad/ehc/fixer1/ of this session, not in the repository): W-380 on trunk
fca1e9e2f at fork/decision-log.md:19596, :20829 and :20831 and
fork/inventory/work-items.json:5161 (W-378's notes), and `"id": "W-380"` in no
ledger, W-378 the highest id; the ls-files pattern of rev 2's §0.1 and §0.3
listing nothing at aee70185c and §8.7's listing exactly run_result_ok.carbon and
run_result_err.carbon; check/testdata/operators/question_result.carbon:101 at
aee70185c reading "on the `Ok` side"; `git grep doc-gap -- fork` empty on trunk,
the README's kinds `todo-stub | fail-test | missing-feature | design-needed |
infra` and eight kinds in use in the ledger; paths.sh:15 and :17 reading the two
variables that §8.11's block spells, the worktree one defaulting to
/home/user/carbon-trunk; RG-1's _Landed_ paragraph at decision-log.md :1010-1013
at aee70185c and at fca1e9e2f (neither rev 2's ":1008-1011" nor the review's
":1011-1013"); the SAFE worktree (14c1ac8ac) naming W-370 once and W-371 twice
(safe3-plan.md:1688-1692) and W-397 to W-399; the tutorial's 8 `Ok`/`Err` lines
(9 occurrences) at aee70185c against rg1-plan.md:925's "18"; OV-4's row form at
097c76473 (ORCHESTRATION.md:1020, "IMPLEMENTED AND REVIEWED; RE-REVIEW ROUND 1
DRY (base trunk 66bd2ba90)", no PR number; its D.8 wrote "IMPLEMENTED AND
REVIEWED (base trunk 66bd2ba90)" at D) and its "HELD OPEN as PR 68" paragraph
reaching trunk in PR 68's records commit fe0957d54; trunk still fca1e9e2f and
upstream's tip still ca1898506 after a fetch. A prototype of the rename
(/home/user/carbon-ehc-fixer1 at aee70185c, label `ehc-fixer1`, the re-review's
own script re-run over the same 73 files; worktree and the label's four
directories removed afterwards) was built (6.5 minutes at -j4), installed and
measured, because the sign-off re-quotes its figures: gate before the fill
`[  PASSED  ] 2015 tests.`, 32 per-test FAILED lines, 32 "Autoupdate would make
changes", the summary "2015 passed, 0 failed" with exit 1 (§8.3); autoupdate to
its fixpoint in one pass (the second changes nothing); gate 2047 passed, 0
failed; §8.7's grep 1 exactly the five lines (common/raw_hashtable.h:1314,
core/prelude/types/result.carbon:56,
check/testdata/operators/question_result.carbon:156, :164 and :174), greps 2 and
3 empty; conformance PASS 228 / FAIL 0 / SKIP 13 over 241, 51 of 56 bullets,
every row's status and detail equal to cb726a230's with the two renamed programs
mapped by name. Rev 3 changes no code, golden, program or page text: every
amendment is plan text or a records template. Nothing is rejected.

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR1-M1 | MAJOR | folded: no R or D text names the PR number, its own sha or a landing; the Branches row in OV-4's form; §3 gains item 10 (the orchestrator's texts); the same tense in D.1's W-380 notes ("EH-C landed before PR 53"), which the review did not cite, is amended with it | D.2's first paragraph and intro, D.4, D.5, D.7, D.8, Appendix D's header, §3 items 8, 9 and 10, D.1's W-380 notes |
| RR1-M2 | MAJOR | folded, reproduced (W-380 in four places on trunk, none a ledger id) | §8.9's criterion, §0.7, D-EHC-11 and its break condition, D.2's _Ids_ paragraph |
| RR1-m1 | MINOR | folded, reproduced (paths.sh:15); the misspelling was the Google-style hook's, which expands the name in prose and code spans (seen again at this fold's first prek pass), so the commands moved into a guarded block | §8.11 (a guarded block; step 4), hand-off |
| RR1-m2 | MINOR | folded, reproduced (nothing, then the two files); the wrong pattern was rumdl's MD011 rewriting the right one inside the two table cells (seen again at this fold's first prek pass), so the cells now point at §8.7's list, where code spans are honored | §0.1, §0.3, hand-off |
| RR1-m3 | MINOR | folded, reproduced (:101 reads `Ok`) | A.1.22 |
| RR1-m4 | MINOR | folded: `missing-feature`, W-346's own kind; no new kind minted | D.1 |
| RR1-m5 | MINOR | folded, each re-measured (:1010-1013, not the review's :1011-1013) | Appendix E, F's fields and F.5, D.4, §0.7, §0.8 (a), D-EHC-11, D.6 |

The fixer's own, folded the same way: F-5 D.8 named no text for the dated
paragraph that §3 item 8 lists among D's edits, so one is given, without a
PR number. R31's counts of this file: rev 2 headings 1/18/64/53, bullets 60,
numbered 26, rows 713; rev 3 before prek and after it in the commit message
(the added headings are this section and the Sign-off; the added item is §3's
item 10; the added bullet is the hand-off's note on the two hooks; the added
rows are this table's nine and the Sign-off's five).

## Review fold record (implementation reviews A and B, 2026-11-09)

The two implementation reviews of C1 2e9b55399, F1 45f5b9b16 and P 93b0ac263
(both APPROVE-WITH-AMENDMENTS; A three MINORs, B four; no BLOCKER, no MAJOR)
and the fixer's pass over them (zero fix commits: RA-m3 rejected as a fix with
its facts confirmed, the other six deferred to the records) are folded by the
records commit R, each amendment marked "(amended 2026-11-09, review fold:
<id>)"; every finding is plan text or records-only, and C1, F1 and P stand
unchanged, so the head's figures stand: gate 2047 of 2047 (the reviews' and
the fixer's own builds, labels ehc-reviewA, ehc-revb and ehc-fix); conformance
228/0/13 over 241, 51/56 bullets, every row equal to cb726a230's with the two
renamed programs mapped; autoupdate on the head 0 files changed, and C1's
goldens refilled reproduce F1 byte for byte; M1 2040 passed with the seven
goldens and the four programs red, M2 229 over interop/cpp with the three
goldens red and 14 `Ok` and 14 `Err` diagnostics; prek two passes over the 73
files, nothing rewritten; §8.8's mirror: origin/trunk 725570464 exit 0 (tree
1b20195f2), 2407efa74 exit 1 (tree 92fe42f66, the four records files only).

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RA-m1 | MINOR | folded: the sentence corrected (result.carbon 52 lines at M-0, 62 at C1; :28 and :51 unmoved; the history block is the plan's own) | §2.1 |
| RA-m2 | MINOR | folded, each re-measured by the fixer: tutorial.md:409 and :411; grep 3 history only from F1 on; grep 4 scoped 0, tree-wide 1 (this plan's own D-EHC-5 sentence) | §8.7, D.2's appended template, F.8 |
| RA-m3 | MINOR | rejected as a fix by the fixer (four comment lines of lower main_run/return_result.carbon over 80 columns, Appendix A.2.3's cells; no hook bounds .carbon lines; a re-wrap moves CHECK lines and costs a fill); re-wrapped by whichever later commit touches the file | none |
| B1 | MINOR | folded: M-0 merged trunk 725570464, not fca1e9e2f (trunk moved on to the arbiter scripts' records commit, no use site); every template that printed M-0's base amended | §3 item 9 and the land-time paragraph, Appendix D's intro, D.2, D.8, Appendix E, F.1 |
| B2 | MINOR | folded with RA-m2 | the same |
| B3 | MINOR | folded: one clause in the decision-log entry (C1's pages carried the mechanically renamed prose until P, as §2.8 slices it) | D.2's entry as R writes it |
| B4 | MINOR | folded: the entry quotes the pages as they stand (README.md:4063 its own paragraph after the blank :4062; optional.md:434-435 unreflowed) | D.2's entry as R writes it (D-EHC-6) |

## Sign-off

Every review of this plan, with its verdict and its counts (added 2026-11-09,
review fold: RR1):

| review | read | verdict | BLOCKER | MAJOR | MINOR | folded | rejected | fold |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A: measurements, mutants and the reconciliation greps | rev 1, 7ea4ff096 | APPROVE-WITH-AMENDMENTS | 0 | 3 | 3 | 6 | none | rev 2, "Review fold record (rev 2, 2026-11-09)" |
| B: names, records, process and the merge | rev 1, 7ea4ff096 | APPROVE-WITH-AMENDMENTS | 0 | 3 | 8 | 11 (B-M2 with A-M3) | none | rev 2, the same |
| RR1: the focused re-review | rev 2, 51013a4a6 | APPROVE-WITH-AMENDMENTS | 0 | 2 | 5 | 7 | none | rev 3, "Review fold record (rev 3, 2026-11-09)" |

Rev 3 is SIGNED OFF FOR IMPLEMENTATION: the last review's verdict is
APPROVE-WITH-AMENDMENTS, not REJECT; every finding of the three reviews is
folded and none rejected; rev 3 changes no code, golden, program or page
text, so rev 2's container figures stand (gate 2047 of 2047, conformance
228/0/13 over 241, 51 of 56 bullets, re-measured by the re-review's `ehc-rr1`
and the fixer's `ehc-fixer1` prototypes). The implementation starts from this
plan's commit with §3's M-0, then C1.

## Appendix A: every golden's source edit

Trunk aee70185c line numbers; CHECK lines are not listed (F1 refills them). A.3
is the new split, verbatim.

### A.1 Check goldens

#### A.1.1 toolchain/check/testdata/choice/payload_construct.carbon (4 lines)

| Line | Before | After |
| --- | --- | --- |
| :18 | `Ok(value: i32),` | `Success(value: i32),` |
| :19 | `Err` | `Failure` |
| :24 | `let err: IntResult = IntResult.Err;` | `let err: IntResult = IntResult.Failure;` |
| :28 | `return IntResult.Ok(n);` | `return IntResult.Success(n);` |

#### A.1.2 toolchain/check/testdata/interop/cpp/exceptions/catching_thunk.carbon (7 lines)

| Line | Before | After |
| --- | --- | --- |
| :41 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.may_throw_int()?);` |
| :60 | `return Core.Result((), Cpp.Exception).Ok(());` | `return Core.Result((), Cpp.Exception).Success(());` |
| :80 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.f(Cpp.g())?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.f(Cpp.g())?);` |
| :101 | `return Core.Result(i32, Cpp.Exception).Ok(plain + caught);` | `return Core.Result(i32, Cpp.Exception).Success(plain + caught);` |
| :121 | `return Core.Result(i32, Cpp.Exception).Ok(one + two);` | `return Core.Result(i32, Cpp.Exception).Success(one + two);` |
| :150 | `return Core.Result(i32, Cpp.Exception).Ok(a + b);` | `return Core.Result(i32, Cpp.Exception).Success(a + b);` |
| :179 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.may_throw_int()?);` |

#### A.1.3 toolchain/check/testdata/interop/cpp/exceptions/fail_catching.carbon (7 lines)

| Line | Before | After |
| --- | --- | --- |
| :46 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.cannot_throw()?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.cannot_throw()?);` |
| :73 | `return Core.Result(i32, i32).Ok(Cpp.may_throw_int()?);` | `return Core.Result(i32, i32).Success(Cpp.may_throw_int()?);` |
| :95 | `return Core.Result(i32, Cpp.Exception).Ok(x?);` | `return Core.Result(i32, Cpp.Exception).Success(x?);` |
| :117 | `return Core.Result(i32, Cpp.Exception).Ok(0);` | `return Core.Result(i32, Cpp.Exception).Success(0);` |
| :139 | `return Core.Result(i32, Cpp.Exception).Ok(0);` | `return Core.Result(i32, Cpp.Exception).Success(0);` |
| :170 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.get_fn_ptr()()?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.get_fn_ptr()()?);` |
| :192 | `return Core.Result(i32, Cpp.Exception).Ok(0);` | `return Core.Result(i32, Cpp.Exception).Success(0);` |

#### A.1.4 toolchain/check/testdata/interop/cpp/exceptions/fail_catching_none_mode.carbon (1 lines)

| Line | Before | After |
| --- | --- | --- |
| :35 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.may_throw_int()?);` |

#### A.1.5 toolchain/check/testdata/interop/cpp/function/export/result_expected.carbon (17 lines)

| Line | Before | After |
| --- | --- | --- |
| :35 | `if (n < 0) { return Core.Result(i32, i32).Err(n); }` | `if (n < 0) { return Core.Result(i32, i32).Failure(n); }` |
| :36 | `return Core.Result(i32, i32).Ok(n);` | `return Core.Result(i32, i32).Success(n);` |
| :45 | `T ok;` | `T success;` |
| :46 | `E err;` | `E failure;` |
| :50 | `expected(T value) : disc(0), ok(value) {}` | `expected(T value) : disc(0), success(value) {}` |
| :56 | `E err;` | `E failure;` |
| :80 | `if (n < 0) { return Core.Result((), i32).Err(n); }` | `if (n < 0) { return Core.Result((), i32).Failure(n); }` |
| :81 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
| :90 | `T ok;` | `T success;` |
| :91 | `E err;` | `E failure;` |
| :95 | `expected(T value) : disc(0), ok(value) {}` | `expected(T value) : disc(0), success(value) {}` |
| :101 | `E err;` | `E failure;` |
| :122 | `return Core.Result(i32, Cpp.Exception).Ok(1);` | `return Core.Result(i32, Cpp.Exception).Success(1);` |
| :131 | `T ok;` | `T success;` |
| :132 | `E err;` | `E failure;` |
| :136 | `expected(T value) : disc(0), ok(value) {}` | `expected(T value) : disc(0), success(value) {}` |
| :164 | `return Core.Result(i32, i32).Ok(n);` | `return Core.Result(i32, i32).Success(n);` |

#### A.1.6 toolchain/check/testdata/interop/cpp/stdlib/optional.carbon (1 lines)

| Line | Before | After |
| --- | --- | --- |
| :363 | `case .Ok(v: i32) => {` | `case .Success(v: i32) => {` |

#### A.1.7 toolchain/check/testdata/main_run/return_result.carbon (8 lines; the two split headers added 2026-11-09, review fold: B-M1)

| Line | Before | After |
| --- | --- | --- |
| :23 | `// --- unit_ok.carbon` | `// --- unit_success.carbon` |
| :28 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
| :32 | `// --- i32_ok.carbon` | `// --- i32_success.carbon` |
| :37 | `return Core.Result(i32, i32).Ok(3);` | `return Core.Result(i32, i32).Success(3);` |
| :45 | `return Core.Result((), i32).Err(n);` | `return Core.Result((), i32).Failure(n);` |
| :51 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
| :64 | `return Core.Result(i64, i32).Ok(0);` | `return Core.Result(i64, i32).Success(0);` |
| :97 | `return Core.Result(Code, i32).Err(1);` | `return Core.Result(Code, i32).Failure(1);` |

#### A.1.8 toolchain/check/testdata/match/choice_payload_guard.carbon (7 lines)

| Line | Before | After |
| --- | --- | --- |
| :19 | `` // guarded, once unguarded — so `.Ok` values split on the guard while `` | `` // guarded, once unguarded — so `.Success` values split on the guard while `` |
| :20 | `` // `.Err` stays reachable, and the unguarded arms cover both alternatives `` | `` // `.Failure` stays reachable, and the unguarded arms cover both alternatives `` |
| :26 | `Ok(value: i32),` | `Success(value: i32),` |
| :27 | `Err` | `Failure` |
| :32 | `case .Ok(v: i32) if (v > 0) => { return v; }` | `case .Success(v: i32) if (v > 0) => { return v; }` |
| :33 | `case .Ok(w: i32) => { return w - 1; }` | `case .Success(w: i32) => { return w - 1; }` |
| :34 | `case .Err => { return -10; }` | `case .Failure => { return -10; }` |

#### A.1.9 toolchain/check/testdata/match/choice_payload_pattern.carbon (4 lines)

| Line | Before | After |
| --- | --- | --- |
| :22 | `Ok(value: i32),` | `Success(value: i32),` |
| :23 | `Err` | `Failure` |
| :28 | `case .Ok(value: i32) => { return value; }` | `case .Success(value: i32) => { return value; }` |
| :29 | `case .Err => { return -1; }` | `case .Failure => { return -1; }` |

#### A.1.10 toolchain/check/testdata/match/exhaustive_choice.carbon (10 lines)

| Line | Before | After |
| --- | --- | --- |
| :44 | `Ok(value: i32),` | `Success(value: i32),` |
| :45 | `Err` | `Failure` |
| :53 | `case .Ok(value: i32) => { return value; }` | `case .Success(value: i32) => { return value; }` |
| :54 | `case .Err => { return -1; }` | `case .Failure => { return -1; }` |
| :65 | `Ok(value: i32),` | `Success(value: i32),` |
| :66 | `Err` | `Failure` |
| :70 | `` // covered again by an unguarded arm does: `.Ok` values split on the guard, `` | `` // covered again by an unguarded arm does: `.Success` values split on the guard, `` |
| :74 | `case .Ok(v: i32) if (v > 0) => { return v; }` | `case .Success(v: i32) if (v > 0) => { return v; }` |
| :75 | `case .Ok(w: i32) => { return w - 1; }` | `case .Success(w: i32) => { return w - 1; }` |
| :76 | `case .Err => { return -10; }` | `case .Failure => { return -10; }` |

#### A.1.11 toolchain/check/testdata/match/fail_case_never_matches_alternative.carbon (11 lines)

| Line | Before | After |
| --- | --- | --- |
| :47 | `Ok(value: i32),` | `Success(value: i32),` |
| :48 | `Err` | `Failure` |
| :54 | `case .Ok(42) => { return 1; }` | `case .Success(42) => { return 1; }` |
| :62 | `case .Ok(42) => { return 2; }` | `case .Success(42) => { return 2; }` |
| :72 | `Ok(value: i32),` | `Success(value: i32),` |
| :73 | `Err` | `Failure` |
| :76 | `` // Payload subsumption: `.Ok(v: i32)` matches every `.Ok` value, so `` | `` // Payload subsumption: `.Success(v: i32)` matches every `.Success` value, so `` |
| :77 | `` // `.Ok(42)` can never match. The unguarded `.Ok` and `.Err` arms cover the `` | `` // `.Success(42)` can never match. The unguarded `.Success` and `.Failure` arms cover the `` |
| :81 | `case .Ok(v: i32) => { return v; }` | `case .Success(v: i32) => { return v; }` |
| :89 | `case .Ok(42) => { return 1; }` | `case .Success(42) => { return 1; }` |
| :90 | `case .Err => { return 0; }` | `case .Failure => { return 0; }` |

#### A.1.12 toolchain/check/testdata/match/fail_case_never_matches_full_coverage.carbon (7 lines)

| Line | Before | After |
| --- | --- | --- |
| :75 | `Ok(value: i32),` | `Success(value: i32),` |
| :76 | `Err` | `Failure` |
| :79 | `` // Irrefutable-payload coverage completes the union: `.Ok(v: i32)` covers `` | `` // Irrefutable-payload coverage completes the union: `.Success(v: i32)` covers `` |
| :80 | `` // `.Ok` (a wholly-irrefutable payload counts, exactly as for `` | `` // `.Success` (a wholly-irrefutable payload counts, exactly as for `` |
| :81 | `` // exhaustiveness), `.Err` covers the rest, and the binding arm is dead. `` | `` // exhaustiveness), `.Failure` covers the rest, and the binding arm is dead. `` |
| :84 | `case .Ok(v: i32) => { return v; }` | `case .Success(v: i32) => { return v; }` |
| :85 | `case .Err => { return 0; }` | `case .Failure => { return 0; }` |

#### A.1.13 toolchain/check/testdata/match/fail_choice_alternative_pattern.carbon (17 lines)

| Line | Before | After |
| --- | --- | --- |
| :17 | `Ok(value: i32),` | `Success(value: i32),` |
| :18 | `Err` | `Failure` |
| :22 | `` // alternative declares a parameter list (p2188), so bare `.Ok` is an error. `` | `` // alternative declares a parameter list (p2188), so bare `.Success` is an error. `` |
| :29 | `case .Ok => { return 1; }` | `case .Success => { return 1; }` |
| :39 | `Ok(value: i32),` | `Success(value: i32),` |
| :40 | `Err` | `Failure` |
| :43 | `` // The other direction of the parens-iff-parameter-list rule: `Err` declares `` | `` // The other direction of the parens-iff-parameter-list rule: `Failure` declares `` |
| :44 | `` // no parameter list, so `.Err()` is an error. `` | `` // no parameter list, so `.Failure()` is an error. `` |
| :51 | `case .Err() => { return 1; }` | `case .Failure() => { return 1; }` |
| :87 | `Ok(value: i32),` | `Success(value: i32),` |
| :88 | `Err` | `Failure` |
| :113 | `Ok(value: i32),` | `Success(value: i32),` |
| :114 | `Err` | `Failure` |
| :133 | `case .Ok(.Err) => { return 1; }` | `case .Success(.Failure) => { return 1; }` |
| :143 | `Ok(value: i32),` | `Success(value: i32),` |
| :144 | `Err` | `Failure` |
| :155 | `case IntResult.Err => { return 1; }` | `case IntResult.Failure => { return 1; }` |

#### A.1.14 toolchain/check/testdata/match/payload_subpattern.carbon (7 lines)

| Line | Before | After |
| --- | --- | --- |
| :24 | `Ok(value: i32),` | `Success(value: i32),` |
| :25 | `Err` | `Failure` |
| :31 | `case .Ok(42) => { return 1; }` | `case .Success(42) => { return 1; }` |
| :81 | `Ok(value: i32),` | `Success(value: i32),` |
| :82 | `Err` | `Failure` |
| :90 | `case .Ok(42) if (b) => { return 1; }` | `case .Success(42) if (b) => { return 1; }` |
| :91 | `case .Ok(value: i32) => { return value; }` | `case .Success(value: i32) => { return value; }` |

#### A.1.15 toolchain/check/testdata/match/usefulness_no_false_positive.carbon (17 lines)

| Line | Before | After |
| --- | --- | --- |
| :58 | `Ok(value: i32),` | `Success(value: i32),` |
| :59 | `Err` | `Failure` |
| :65 | `case .Ok(42) if (g) => { return 1; }` | `case .Success(42) if (g) => { return 1; }` |
| :66 | `case .Ok(42) if (h) => { return 2; }` | `case .Success(42) if (h) => { return 2; }` |
| :146 | `Ok(value: i32),` | `Success(value: i32),` |
| :147 | `Err` | `Failure` |
| :168 | `case .Ok(1) => { return 1; }` | `case .Success(1) => { return 1; }` |
| :169 | `case .Ok(2) => { return 2; }` | `case .Success(2) => { return 2; }` |
| :261 | `Ok(value: i32),` | `Success(value: i32),` |
| :262 | `Err` | `Failure` |
| :265 | `` // Full alternative coverage plus a prior ERROR arm (`.Err()` — parens on `` | `` // Full alternative coverage plus a prior ERROR arm (`.Failure()` — parens on `` |
| :272 | `case .Ok(v: i32) => { return v; }` | `case .Success(v: i32) => { return v; }` |
| :273 | `case .Err => { return 0; }` | `case .Failure => { return 0; }` |
| :278 | `case .Err() => { return 1; }` | `case .Failure() => { return 1; }` |
| :288 | `Ok(value: i32),` | `Success(value: i32),` |
| :289 | `Err` | `Failure` |
| :305 | `case .Err() => { return 1; }` | `case .Failure() => { return 1; }` |

#### A.1.16 toolchain/check/testdata/operators/fail_question.carbon (28 lines)

| Line | Before | After |
| --- | --- | --- |
| :26 | `Ok(v: T),` | `Success(v: T),` |
| :27 | `Err(e: E)` | `Failure(e: E)` |
| :41 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :42 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :52 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :64 | `return MyResult(i32, i32).Ok(x);` | `return MyResult(i32, i32).Success(x);` |
| :81 | `return MyResult(i32, i32).Ok(0);` | `return MyResult(i32, i32).Success(0);` |
| :88 | `Ok(v: T),` | `Success(v: T),` |
| :89 | `Err(e: E)` | `Failure(e: E)` |
| :103 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :104 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :114 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :117 | `fn H(n: i32) -> MyResult(i32, i32) { return MyResult(i32, i32).Ok(n); }` | `fn H(n: i32) -> MyResult(i32, i32) { return MyResult(i32, i32).Success(n); }` |
| :131 | `case .Ok(v: i32) if (H(v)? > 0) => { return MyResult(i32, i32).Ok(v); }` | `case .Success(v: i32) if (H(v)? > 0) => { return MyResult(i32, i32).Success(v); }` |
| :132 | `case .Ok(w: i32) => { return MyResult(i32, i32).Ok(w); }` | `case .Success(w: i32) => { return MyResult(i32, i32).Success(w); }` |
| :133 | `case .Err(e: i32) => { return MyResult(i32, i32).Err(e); }` | `case .Failure(e: i32) => { return MyResult(i32, i32).Failure(e); }` |
| :137 | `return MyResult(i32, i32).Err(0);` | `return MyResult(i32, i32).Failure(0);` |
| :146 | `return MyResult(i32, i32).Ok(y);` | `return MyResult(i32, i32).Success(y);` |
| :161 | `return MyResult(i32, i32).Ok(p);` | `return MyResult(i32, i32).Success(p);` |
| :179 | `case H(0)? => { return MyResult(i32, i32).Ok(n); }` | `case H(0)? => { return MyResult(i32, i32).Success(n); }` |
| :180 | `default => { return MyResult(i32, i32).Err(n); }` | `default => { return MyResult(i32, i32).Failure(n); }` |
| :188 | `Ok(v: T),` | `Success(v: T),` |
| :189 | `Err(e: E)` | `Failure(e: E)` |
| :203 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :204 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :214 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :230 | `return MyResult(i32, ErrA).Err(n as ErrA);` | `return MyResult(i32, ErrA).Failure(n as ErrA);` |
| :245 | `return MyResult(i32, ErrC).Ok(v);` | `return MyResult(i32, ErrC).Success(v);` |

#### A.1.17 toolchain/check/testdata/operators/fail_question_final.carbon (13 lines)

| Line | Before | After |
| --- | --- | --- |
| :30 | `Ok(v: T),` | `Success(v: T),` |
| :31 | `Err(e: E)` | `Failure(e: E)` |
| :45 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :46 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :51 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :80 | `case .Ok(v: i32) => { return Core.ControlFlow(bool, i32).Break(v); }` | `case .Success(v: i32) => { return Core.ControlFlow(bool, i32).Break(v); }` |
| :81 | `case .Err(e: i32) => { return Core.ControlFlow(bool, i32).Break(e); }` | `case .Failure(e: i32) => { return Core.ControlFlow(bool, i32).Break(e); }` |
| :86 | `fn FromBreak(e: i32) -> Self { return MyResult(i32, i32).Err(e); }` | `fn FromBreak(e: i32) -> Self { return MyResult(i32, i32).Failure(e); }` |
| :93 | `Ok(v: T),` | `Success(v: T),` |
| :94 | `Err(e: E)` | `Failure(e: E)` |
| :123 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :124 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :129 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |

#### A.1.18 toolchain/check/testdata/operators/fail_question_generic.carbon (3 lines)

| Line | Before | After |
| --- | --- | --- |
| :108 | `Ok(v: T),` | `Success(v: T),` |
| :109 | `Err(e: E)` | `Failure(e: E)` |
| :116 | `var unused mr: MyResult(T, i32) = MyResult(T, i32).Err(0);` | `var unused mr: MyResult(T, i32) = MyResult(T, i32).Failure(0);` |

#### A.1.19 toolchain/check/testdata/operators/question.carbon (43 lines)

| Line | Before | After |
| --- | --- | --- |
| :27 | `Ok(v: T),` | `Success(v: T),` |
| :28 | `Err(e: E)` | `Failure(e: E)` |
| :42 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :43 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :53 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :57 | `if (n > 0) { return MyResult(i32, i32).Ok(n); }` | `if (n > 0) { return MyResult(i32, i32).Success(n); }` |
| :58 | `return MyResult(i32, i32).Err(n);` | `return MyResult(i32, i32).Failure(n);` |
| :69 | `return MyResult(i32, i32).Ok(f + 1);` | `return MyResult(i32, i32).Success(f + 1);` |
| :75 | `return MyResult(i32, i32).Ok(n);` | `return MyResult(i32, i32).Success(n);` |
| :83 | `return MyResult(i32, i32).Ok(t);` | `return MyResult(i32, i32).Success(t);` |
| :90 | `return MyResult(i32, i32).Ok(v);` | `return MyResult(i32, i32).Success(v);` |
| :99 | `case .Ok(v: i32) => {` | `case .Success(v: i32) => {` |
| :101 | `return MyResult(i32, i32).Ok(w);` | `return MyResult(i32, i32).Success(w);` |
| :103 | `case .Err(e: i32) => { return MyResult(i32, i32).Err(e); }` | `case .Failure(e: i32) => { return MyResult(i32, i32).Failure(e); }` |
| :107 | `return MyResult(i32, i32).Err(0);` | `return MyResult(i32, i32).Failure(0);` |
| :118 | `return MyResult(i32, i32).Ok(v);` | `return MyResult(i32, i32).Success(v);` |
| :128 | `return MyResult(i32, i32).Ok(if v then 1 else 0);` | `return MyResult(i32, i32).Success(if v then 1 else 0);` |
| :136 | `Ok(v: T),` | `Success(v: T),` |
| :137 | `Err(e: E)` | `Failure(e: E)` |
| :151 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :152 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :162 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :173 | `return MyResult(i64, i32).Ok(y + (x as i64));` | `return MyResult(i64, i32).Success(y + (x as i64));` |
| :241 | `Ok(v: T),` | `Success(v: T),` |
| :242 | `Err(e: E)` | `Failure(e: E)` |
| :256 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :257 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :267 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :276 | `return MyResult(T2, E2).Ok(x);` | `return MyResult(T2, E2).Success(x);` |
| :312 | `return MyResult(T, E).Err(e);` | `return MyResult(T, E).Failure(e);` |
| :320 | `var unused mr: MyResult(T, E) = MyResult(T, E).Ok(t);` | `var unused mr: MyResult(T, E) = MyResult(T, E).Success(t);` |
| :332 | `case .Ok(v: T) => {` | `case .Success(v: T) => {` |
| :336 | `case .Err(e: i32) => { return e; }` | `case .Failure(e: i32) => { return e; }` |
| :348 | `Ok(v: T),` | `Success(v: T),` |
| :349 | `Err(e: E)` | `Failure(e: E)` |
| :363 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :364 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :374 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :400 | `if (n > 0) { return MyResult(i32, ErrA).Ok(n); }` | `if (n > 0) { return MyResult(i32, ErrA).Success(n); }` |
| :401 | `return MyResult(i32, ErrA).Err(n as ErrA);` | `return MyResult(i32, ErrA).Failure(n as ErrA);` |
| :407 | `return MyResult(i32, ErrB).Ok(v);` | `return MyResult(i32, ErrB).Success(v);` |
| :415 | `Ok(v: T),` | `Success(v: T),` |
| :416 | `Err(e: E)` | `Failure(e: E)` |

#### A.1.20 toolchain/check/testdata/operators/question_final.carbon (24 lines)

| Line | Before | After |
| --- | --- | --- |
| :37 | `Ok(v: T),` | `Success(v: T),` |
| :38 | `Err(e: E)` | `Failure(e: E)` |
| :56 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :57 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :66 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :84 | `` // sink) and wraps back through `Ok` — the full threading round trip. `` | `` // sink) and wraps back through `Success` — the full threading round trip. `` |
| :88 | `return MyResult(T, E).Ok(v);` | `return MyResult(T, E).Success(v);` |
| :96 | `Ok(v: T),` | `Success(v: T),` |
| :97 | `Err(e: E)` | `Failure(e: E)` |
| :111 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :112 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :117 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :131 | `return MyResult(T, i32).Ok(v);` | `return MyResult(T, i32).Success(v);` |
| :139 | `Ok(v: T),` | `Success(v: T),` |
| :140 | `Err(e: E)` | `Failure(e: E)` |
| :157 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :158 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :163 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :178 | `return MyResult(T, E).Ok(v);` | `return MyResult(T, E).Success(v);` |
| :186 | `Ok(v: T),` | `Success(v: T),` |
| :187 | `Err(e: E)` | `Failure(e: E)` |
| :215 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :216 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :222 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |

#### A.1.21 toolchain/check/testdata/operators/question_optional.carbon (1 lines)

| Line | Before | After |
| --- | --- | --- |
| :60 | `return Core.Result(i32, i32).Ok(o?);` | `return Core.Result(i32, i32).Success(o?);` |

#### A.1.22 toolchain/check/testdata/operators/question_result.carbon (15 lines; the split header added 2026-11-09, review fold: B-M1; :101's Before cell corrected 2026-11-09, review fold: RR1-m3)

| Line | Before | After |
| --- | --- | --- |
| :28 | `if (n > 0) { return Core.Result(i32, i32).Ok(n); }` | `if (n > 0) { return Core.Result(i32, i32).Success(n); }` |
| :29 | `return Core.Result(i32, i32).Err(n);` | `return Core.Result(i32, i32).Failure(n);` |
| :38 | `return Core.Result(i32, i32).Ok(f + 1);` | `return Core.Result(i32, i32).Success(f + 1);` |
| :44 | `return Core.Result(i32, i32).Ok(n);` | `return Core.Result(i32, i32).Success(n);` |
| :51 | `return Core.Result(i32, i32).Ok(t);` | `return Core.Result(i32, i32).Success(t);` |
| :57 | `return Core.Result(i32, i32).Ok(v);` | `return Core.Result(i32, i32).Success(v);` |
| :87 | `if (n > 0) { return Core.Result(i32, ErrA).Ok(n); }` | `if (n > 0) { return Core.Result(i32, ErrA).Success(n); }` |
| :88 | `return Core.Result(i32, ErrA).Err(n as ErrA);` | `return Core.Result(i32, ErrA).Failure(n as ErrA);` |
| :94 | `return Core.Result(i32, ErrB).Ok(v);` | `return Core.Result(i32, ErrB).Success(v);` |
| :98 | `// --- unit_ok.carbon` | `// --- unit_success.carbon` |
| :101 | `` // `Core.Result((), E)`: the `()` payload on the `Ok` side (D-EH-2's `` | `` // `Core.Result((), E)`: the `()` payload on the `Success` side (D-EH-2's `` |
| :105 | `if (n > 0) { return Core.Result((), i32).Ok(()); }` | `if (n > 0) { return Core.Result((), i32).Success(()); }` |
| :106 | `return Core.Result((), i32).Err(n);` | `return Core.Result((), i32).Failure(n);` |
| :113 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
| :127 | `return Core.Result(T, E).Ok(v);` | `return Core.Result(T, E).Success(v);` |

Inserted after trunk line 149: the `fail_old_names` split (20 lines with its
blank line; A.3).

### A.2 Lower goldens

#### A.2.1 toolchain/lower/testdata/interop/cpp/exceptions/catching_thunk.carbon (4 lines)

| Line | Before | After |
| --- | --- | --- |
| :19 | `` // the discriminant with 0 (`icmp`/`br`) and constructs the `Ok` or `Err` `` | `` // the discriminant with 0 (`icmp`/`br`) and constructs the `Success` or `Failure` `` |
| :43 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.may_throw_int()?);` |
| :48 | `return Core.Result((), Cpp.Exception).Ok(());` | `return Core.Result((), Cpp.Exception).Success(());` |
| :54 | `return Core.Result(i32, Cpp.Exception).Ok(a + b);` | `return Core.Result(i32, Cpp.Exception).Success(a + b);` |

#### A.2.2 toolchain/lower/testdata/interop/cpp/function/export/result_expected.carbon (5 lines)

| Line | Before | After |
| --- | --- | --- |
| :29 | `if (n < 0) { return Core.Result(i32, i32).Err(n); }` | `if (n < 0) { return Core.Result(i32, i32).Failure(n); }` |
| :30 | `return Core.Result(i32, i32).Ok(n);` | `return Core.Result(i32, i32).Success(n);` |
| :39 | `T ok;` | `T success;` |
| :40 | `E err;` | `E failure;` |
| :47 | `return r.disc == 0 ? r.ok : r.err;` | `return r.disc == 0 ? r.success : r.failure;` |

#### A.2.3 toolchain/lower/testdata/main_run/return_result.carbon (9 lines; :18, :20 added 2026-11-09, review fold: A-m1; :22, :24, :36 review fold: B-M1)

| Line | Before | After |
| --- | --- | --- |
| :18 | `` // `load i8` of the discriminant, `icmp eq ... 0`, a branch to `run.result.ok` `` | `` // `load i8` of the discriminant, `icmp eq ... 0`, a branch to `run.result.success` `` |
| :19 | `` // (`ret i32 0` for `Ok(())`, the `i32` payload load for `Ok(code)`) or `` | `` // (`ret i32 0` for `Success(())`, the `i32` payload load for `Success(code)`) or `` |
| :20 | `` // `run.result.err` (`call i64 @write(i32 2, ptr @main.result.err.message, `` | `` // `run.result.failure` (`call i64 @write(i32 2, ptr @main.result.failure.message, `` |
| :22 | `` // `?` in `unit_ok` adds a second `return` sharing the one message global. `` | `` // `?` in `unit_success` adds a second `return` sharing the one message global. `` |
| :24 | `// --- unit_ok.carbon` | `// --- unit_success.carbon` |
| :28 | `return Core.Result((), i32).Err(n);` | `return Core.Result((), i32).Failure(n);` |
| :33 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
| :36 | `// --- i32_ok.carbon` | `// --- i32_success.carbon` |
| :40 | `return Core.Result(i32, i32).Ok(3);` | `return Core.Result(i32, i32).Success(3);` |

#### A.2.4 toolchain/lower/testdata/match/choice_payload.carbon (4 lines)

| Line | Before | After |
| --- | --- | --- |
| :20 | `Ok(value: i32),` | `Success(value: i32),` |
| :21 | `Err` | `Failure` |
| :26 | `case .Ok(value: i32) => { return value; }` | `case .Success(value: i32) => { return value; }` |
| :27 | `case .Err => { return -1; }` | `case .Failure => { return -1; }` |

#### A.2.5 toolchain/lower/testdata/match/payload_subpattern.carbon (6 lines)

| Line | Before | After |
| --- | --- | --- |
| :14 | `` // payload-literal arm (`case .Ok(42)`) must sit in a block reached only `` | `` // payload-literal arm (`case .Success(42)`) must sit in a block reached only `` |
| :20 | `Ok(value: i32),` | `Success(value: i32),` |
| :21 | `Err` | `Failure` |
| :26 | `case .Ok(42) => { return 1; }` | `case .Success(42) => { return 1; }` |
| :27 | `case .Ok(value: i32) => { return value; }` | `case .Success(value: i32) => { return value; }` |
| :28 | `case .Err => { return -1; }` | `case .Failure => { return -1; }` |

#### A.2.6 toolchain/lower/testdata/operators/question.carbon (11 lines)

| Line | Before | After |
| --- | --- | --- |
| :30 | `Ok(v: T),` | `Success(v: T),` |
| :31 | `Err(e: E)` | `Failure(e: E)` |
| :45 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :46 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :56 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :60 | `if (n > 0) { return MyResult(i32, i32).Ok(n); }` | `if (n > 0) { return MyResult(i32, i32).Success(n); }` |
| :61 | `return MyResult(i32, i32).Err(n);` | `return MyResult(i32, i32).Failure(n);` |
| :65 | `if (n > 0) { return MyResult(i64, i32).Ok(n); }` | `if (n > 0) { return MyResult(i64, i32).Success(n); }` |
| :66 | `return MyResult(i64, i32).Err(0);` | `return MyResult(i64, i32).Failure(0);` |
| :71 | `return MyResult(i32, i32).Ok(f + 1);` | `return MyResult(i32, i32).Success(f + 1);` |
| :77 | `return MyResult(i64, i32).Ok(y + (x as i64));` | `return MyResult(i64, i32).Success(y + (x as i64));` |

#### A.2.7 toolchain/lower/testdata/operators/question_generic.carbon (10 lines)

| Line | Before | After |
| --- | --- | --- |
| :38 | `Ok(v: T),` | `Success(v: T),` |
| :39 | `Err(e: E)` | `Failure(e: E)` |
| :53 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :54 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :64 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :87 | `Ok(v: T),` | `Success(v: T),` |
| :88 | `Err(e: E)` | `Failure(e: E)` |
| :100 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :101 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :107 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |

#### A.2.8 toolchain/lower/testdata/operators/question_generic_crossfile.carbon (13 lines)

| Line | Before | After |
| --- | --- | --- |
| :21 | `// Branch/FromBreak, the Err/Ok constructors, the ControlFlow constructors)` | `// Branch/FromBreak, the Failure/Success constructors, the ControlFlow constructors)` |
| :40 | `Ok(v: T),` | `Success(v: T),` |
| :41 | `Err(e: E)` | `Failure(e: E)` |
| :53 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :54 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :60 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :66 | `if (fail) { return MyResult(T, i32).Err(tag); }` | `if (fail) { return MyResult(T, i32).Failure(tag); }` |
| :67 | `return MyResult(T, i32).Ok(x);` | `return MyResult(T, i32).Success(x);` |
| :80 | `return MyResult(T, i32).Ok(x);` | `return MyResult(T, i32).Success(x);` |
| :105 | `` // Concrete narrow-alternative writer for the wide specific: the `Err` `` | `` // Concrete narrow-alternative writer for the wide specific: the `Failure` `` |
| :109 | `return MyResult(i64, i32).Err(tag);` | `return MyResult(i64, i32).Failure(tag);` |
| :120 | `case .Ok(v: i64) => { return 0; }` | `case .Success(v: i64) => { return 0; }` |
| :121 | `case .Err(e: i32) => { return e; }` | `case .Failure(e: i32) => { return e; }` |

#### A.2.9 toolchain/lower/testdata/operators/question_generic_final.carbon (10 lines)

| Line | Before | After |
| --- | --- | --- |
| :17 | `` // `Step` call's argument, and the second's is the final `Ok` `` | `` // `Step` call's argument, and the second's is the final `Success` `` |
| :32 | `Ok(v: T),` | `Success(v: T),` |
| :33 | `Err(e: E)` | `Failure(e: E)` |
| :48 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :49 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :54 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :59 | `if (fail) { return MyResult(T, i32).Err(tag); }` | `if (fail) { return MyResult(T, i32).Failure(tag); }` |
| :60 | `return MyResult(T, i32).Ok(x);` | `return MyResult(T, i32).Success(x);` |
| :70 | `return MyResult(T, i32).Ok(b);` | `return MyResult(T, i32).Success(b);` |
| :75 | `` // and the `Ok` construction, `FromBreak` calls and early `ret`s on the `` | `` // and the `Success` construction, `FromBreak` calls and early `ret`s on the `` |

#### A.2.10 toolchain/lower/testdata/operators/question_generic_mixed.carbon (13 lines)

| Line | Before | After |
| --- | --- | --- |
| :16 | `` // in one module, so the narrow (i32) `Err` payload lowers inside the WIDE `` | `` // in one module, so the narrow (i32) `Failure` payload lowers inside the WIDE `` |
| :18 | `` // every writer and reader of `MyResult(i64, i32)`'s `Err` payload — the `` | `` // every writer and reader of `MyResult(i64, i32)`'s `Failure` payload — the `` |
| :19 | `` // `Err` constructor's whole-object covering copy plus element stores, the `` | `` // `Failure` constructor's whole-object covering copy plus element stores, the `` |
| :23 | `// Err-path store or load through a NARROW object shape (the round-1 W2` | `// Failure-path store or load through a NARROW object shape (the round-1 W2` |
| :41 | `Ok(v: T),` | `Success(v: T),` |
| :42 | `Err(e: E)` | `Failure(e: E)` |
| :54 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :55 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :61 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :82 | `` // Concrete narrow-alternative writer for the wide specific: the `Err` `` | `` // Concrete narrow-alternative writer for the wide specific: the `Failure` `` |
| :86 | `return MyResult(i64, i32).Err(tag);` | `return MyResult(i64, i32).Failure(tag);` |
| :97 | `case .Ok(v: i64) => { return 0; }` | `case .Success(v: i64) => { return 0; }` |
| :98 | `case .Err(e: i32) => { return e; }` | `case .Failure(e: i32) => { return e; }` |

#### A.2.11 toolchain/lower/testdata/operators/question_result.carbon (8 lines)

| Line | Before | After |
| --- | --- | --- |
| :21 | `` // `Core.Result((), i32)` — the zero-sized `Ok(())` payload (D-EH-2). `` | `` // `Core.Result((), i32)` — the zero-sized `Success(())` payload (D-EH-2). `` |
| :27 | `if (n > 0) { return Core.Result(i32, i32).Ok(n); }` | `if (n > 0) { return Core.Result(i32, i32).Success(n); }` |
| :28 | `return Core.Result(i32, i32).Err(n);` | `return Core.Result(i32, i32).Failure(n);` |
| :33 | `return Core.Result(i32, i32).Ok(f + 1);` | `return Core.Result(i32, i32).Success(f + 1);` |
| :38 | `return Core.Result(i32, i32).Ok(t);` | `return Core.Result(i32, i32).Success(t);` |
| :45 | `if (n > 0) { return Core.Result((), i32).Ok(()); }` | `if (n > 0) { return Core.Result((), i32).Success(()); }` |
| :46 | `return Core.Result((), i32).Err(n);` | `return Core.Result((), i32).Failure(n);` |
| :51 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |

### A.3 The new split, check/testdata/operators/question_result.carbon

Inserted after trunk line 149 (`fn Use(unused r: Core.Result(SomeClass, i32))
{}`) and before the trailing `// CHECK:STDOUT:` block, preceded by one blank
line, CHECK-free in C1 (its fill is quoted in §4):

<!-- google-doc-style-ignore -->

```carbon
// --- fail_old_names.carbon
library "[[@TEST_NAME]]";

// EH-C (W-346; fork/eh/ehc-plan.md D-EHC-3): the alternatives are spelled
// `Success` and `Failure`, as upstream's docs/design/README.md spells a result
// choice's; the former spelling `Ok`/`Err` is an ordinary unknown member, with
// no alias and no note. The constructor form and the pattern form both get
// `MemberNameNotFoundInSpecificScope`.
fn Make() -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(1);
}

fn Read(r: Core.Result(i32, i32)) -> i32 {
  match (r) {
    case .Success(v: i32) => { return v; }
    case .Err(e: i32) => { return e; }
  }
  return 0;
}
```

<!-- google-doc-style-resume -->

### A.4 Parse goldens

#### A.4.1 toolchain/parse/testdata/match/alternative_pattern.carbon (4 lines)

| Line | Before | After |
| --- | --- | --- |
| :15 | `` // pattern at the case root; `.Err` inside parentheses stays an ordinary `` | `` // pattern at the case root; `.Failure` inside parentheses stays an ordinary `` |
| :19 | `case .Err => { return 0; }` | `case .Failure => { return 0; }` |
| :20 | `case .Ok(value: i32) => { return 1; }` | `case .Success(value: i32) => { return 1; }` |
| :24 | `case (.Err) => { return 5; }` | `case (.Failure) => { return 5; }` |

#### A.4.2 toolchain/parse/testdata/match/fail_alternative_pattern_unclosed.carbon (1 lines)

| Line | Before | After |
| --- | --- | --- |
| :31 | `case .Ok(value: i32 => { return 1; }` | `case .Success(value: i32 => { return 1; }` |

## Appendix B: every program and its EXPECT

### B.1 The source edits (trunk aee70185c line numbers)

#### B.1.1 fork/conformance/programs/error_handling/control_flow_constructs.carbon (14 lines)

| Line | Before | After |
| --- | --- | --- |
| :16 | `` // prints 42) and the break path (a negative input's `Err` propagates out of `` | `` // prints 42) and the break path (a negative input's `Failure` propagates out of `` |
| :30 | `Ok(v: T),` | `Success(v: T),` |
| :31 | `Err(e: E)` | `Failure(e: E)` |
| :45 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :46 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :57 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :61 | `if (n < 0) { return MyResult(i32, i32).Err(-1); }` | `if (n < 0) { return MyResult(i32, i32).Failure(-1); }` |
| :62 | `return MyResult(i32, i32).Ok(n);` | `return MyResult(i32, i32).Success(n);` |
| :66 | `` // The dedicated propagation construct: on `Err`, `?` rebuilds it through `` | `` // The dedicated propagation construct: on `Failure`, `?` rebuilds it through `` |
| :69 | `return MyResult(i32, i32).Ok(v * 2);` | `return MyResult(i32, i32).Success(v * 2);` |
| :76 | `case .Ok(v: i32) => { Core.Print(v); }` | `case .Success(v: i32) => { Core.Print(v); }` |
| :77 | `case .Err(e: i32) => { return e; }` | `case .Failure(e: i32) => { return e; }` |
| :80 | `case .Ok(v: i32) => { return v; }` | `case .Success(v: i32) => { return v; }` |
| :81 | `case .Err(e: i32) => { Core.Print(e); }` | `case .Failure(e: i32) => { Core.Print(e); }` |

#### B.1.2 fork/conformance/programs/error_handling/cpp_exception_catch_diff.carbon (4 lines)

| Line | Before | After |
| --- | --- | --- |
| :37 | `` // into `.Err(Cpp.Exception)`. `` | `` // into `.Failure(Cpp.Exception)`. `` |
| :39 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.CheckedScale(value, factor)?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.CheckedScale(value, factor)?);` |
| :44 | `case .Ok(v: i32) => {` | `case .Success(v: i32) => {` |
| :48 | `case .Err(e: Cpp.Exception) => {` | `case .Failure(e: Cpp.Exception) => {` |

#### B.1.3 fork/conformance/programs/error_handling/cpp_exception_catch_diff.diff.cpp (1 lines)

| Line | Before | After |
| --- | --- | --- |
| :9 | `` // output pins that a thrown C++ exception becomes the `.Err` alternative `` | `` // output pins that a thrown C++ exception becomes the `.Failure` alternative `` |

#### B.1.4 fork/conformance/programs/error_handling/cpp_exception_interop.carbon (9 lines)

| Line | Before | After |
| --- | --- | --- |
| :17 | `` // exception into the `.Err` alternative, which `match` observes (prints `-1`). `` | `` // exception into the `.Failure` alternative, which `match` observes (prints `-1`). `` |
| :18 | `` // Exit-code belt: the `.Ok` arm returns 1, so a `?` that wrongly continued `` | `` // Exit-code belt: the `.Success` arm returns 1, so a `?` that wrongly continued `` |
| :28 | `` // leading-period `.Ok(...)` shorthand of the stub is spelled `` | `` // leading-period `.Success(...)` shorthand of the stub is spelled `` |
| :29 | `` // `Core.Result(T, E).Ok(...)` as in every EH-A program. `` | `` // `Core.Result(T, E).Success(...)` as in every EH-A program. `` |
| :42 | `` // becomes `.Err(Cpp.Exception)` and propagates; a returned value continues. `` | `` // becomes `.Failure(Cpp.Exception)` and propagates; a returned value continues. `` |
| :44 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.PositiveOrThrow(n)?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.PositiveOrThrow(n)?);` |
| :52 | `` // Failure path: -2 throws; the exception is caught into `.Err`. `` | `` // Failure path: -2 throws; the exception is caught into `.Failure`. `` |
| :54 | `case .Ok(v: i32) => { v; return 1; }` | `case .Success(v: i32) => { v; return 1; }` |
| :55 | `case .Err(e: Cpp.Exception) => { e; Core.Print(-1); }  // caught C++ exception` | `case .Failure(e: Cpp.Exception) => { e; Core.Print(-1); }  // caught C++ exception` |

#### B.1.5 fork/conformance/programs/error_handling/cpp_exception_rethrow_export.carbon (1 lines)

| Line | Before | After |
| --- | --- | --- |
| :59 | `return Core.Result(i32, Cpp.Exception).Ok(Cpp.Throws(n)?);` | `return Core.Result(i32, Cpp.Exception).Success(Cpp.Throws(n)?);` |

#### B.1.6 fork/conformance/programs/error_handling/cpp_expected_export.carbon (8 lines)

| Line | Before | After |
| --- | --- | --- |
| :25 | `` // hand-derived: `Parse(5)` = Ok(5) → 10; `Parse(-3)` = Err(3) → 3; `` | `` // hand-derived: `Parse(5)` = Success(5) → 10; `Parse(-3)` = Failure(3) → 3; `` |
| :26 | `` // `Check(4)` = Ok(()) → 1; `Check(9)` = Err(9) → 9. Export shape from `` | `` // `Check(4)` = Success(()) → 1; `Check(9)` = Failure(9) → 9. Export shape from `` |
| :32 | `` // `.Err(-n)` for a negative input. `` | `` // `.Failure(-n)` for a negative input. `` |
| :34 | `if (n < 0) { return Core.Result(i32, i32).Err(0 - n); }` | `if (n < 0) { return Core.Result(i32, i32).Failure(0 - n); }` |
| :35 | `return Core.Result(i32, i32).Ok(n);` | `return Core.Result(i32, i32).Success(n);` |
| :38 | `` // `.Ok(())` for an even input, `.Err(n)` for an odd one. `` | `` // `.Success(())` for an even input, `.Failure(n)` for an odd one. `` |
| :40 | `if ((n / 2) * 2 == n) { return Core.Result((), i32).Ok(()); }` | `if ((n / 2) * 2 == n) { return Core.Result((), i32).Success(()); }` |
| :41 | `return Core.Result((), i32).Err(n);` | `return Core.Result((), i32).Failure(n);` |

#### B.1.7 fork/conformance/programs/error_handling/question_generic_diff.carbon (16 lines)

| Line | Before | After |
| --- | --- | --- |
| :20 | `// the break payload was. The i64 leg additionally compares the Ok` | `// the break payload was. The i64 leg additionally compares the Success` |
| :44 | `// (toolchain/check/testdata/operators/question_final.carbon). The Ok` | `// (toolchain/check/testdata/operators/question_final.carbon). The Success` |
| :54 | `Ok(v: T),` | `Success(v: T),` |
| :55 | `Err(e: E)` | `Failure(e: E)` |
| :69 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :70 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :80 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :85 | `if (fail) { return MyResult(T, i32).Err(tag); }` | `if (fail) { return MyResult(T, i32).Failure(tag); }` |
| :86 | `return MyResult(T, i32).Ok(x);` | `return MyResult(T, i32).Success(x);` |
| :106 | `return MyResult(T, i32).Ok(x);` | `return MyResult(T, i32).Success(x);` |
| :109 | `// Prints the outcome tag (0 = Ok, 1 = Err) and the payload.` | `// Prints the outcome tag (0 = Success, 1 = Failure) and the payload.` |
| :112 | `case .Ok(v: i32) => {` | `case .Success(v: i32) => {` |
| :116 | `case .Err(e: i32) => {` | `case .Failure(e: i32) => {` |
| :124 | `// Ok payload matches the runtime-computed expectation (Core.Print takes` | `// Success payload matches the runtime-computed expectation (Core.Print takes` |
| :128 | `case .Ok(v: i64) => {` | `case .Success(v: i64) => {` |
| :136 | `case .Err(e: i32) => {` | `case .Failure(e: i32) => {` |

#### B.1.8 fork/conformance/programs/error_handling/question_generic_diff.diff.cpp (9 lines)

| Line | Before | After |
| --- | --- | --- |
| :13 | `// Ok payload against the same runtime-computed expectation the` | `// Success payload against the same runtime-computed expectation the` |
| :28 | `static auto Ok(T v) -> Result<T> {` | `static auto Success(T v) -> Result<T> {` |
| :33 | `static auto Err(int e) -> Result<T> {` | `static auto Failure(int e) -> Result<T> {` |
| :40 | `return Err<T>(tag);` | `return Failure<T>(tag);` |
| :42 | `return Ok(x);` | `return Success(x);` |
| :49 | `` // value is discarded and the Ok payload is reconstructed from `x` (the `` | `` // value is discarded and the Success payload is reconstructed from `x` (the `` |
| :56 | `return Err<T>(r1.e);` | `return Failure<T>(r1.e);` |
| :61 | `return Err<T>(r2.e);` | `return Failure<T>(r2.e);` |
| :63 | `return Ok(x);` | `return Success(x);` |

#### B.1.9 fork/conformance/programs/error_handling/question_generic_thread_diff.carbon (18 lines)

| Line | Before | After |
| --- | --- | --- |
| :19 | `` // `let b: T = Step(a.Combine(), ..., 202)?;` and `Ok(b)` — the plan's `` | `` // `let b: T = Step(a.Combine(), ..., 202)?;` and `Success(b)` — the plan's `` |
| :52 | `Ok(v: T),` | `Success(v: T),` |
| :53 | `Err(e: E)` | `Failure(e: E)` |
| :65 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :66 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :79 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :85 | `// witness in the generic body). Combine(x) = x + x, so the chain's Ok` | `// witness in the generic body). Combine(x) = x + x, so the chain's Success` |
| :102 | `if (fail) { return MyResult(T, i32).Err(tag); }` | `if (fail) { return MyResult(T, i32).Failure(tag); }` |
| :103 | `return MyResult(T, i32).Ok(x);` | `return MyResult(T, i32).Success(x);` |
| :110 | `// IS the returned Ok payload. Operand and return type are the SAME` | `// IS the returned Success payload. Operand and return type are the SAME` |
| :124 | `return MyResult(T, i32).Ok(b);` | `return MyResult(T, i32).Success(b);` |
| :127 | `// Prints the outcome tag (0 = Ok, 1 = Err) and the payload.` | `// Prints the outcome tag (0 = Success, 1 = Failure) and the payload.` |
| :130 | `case .Ok(v: i32) => {` | `case .Success(v: i32) => {` |
| :134 | `case .Err(e: i32) => {` | `case .Failure(e: i32) => {` |
| :142 | `// Ok payload matches the independently runtime-computed expectation` | `// Success payload matches the independently runtime-computed expectation` |
| :153 | `case .Ok(v: i64) => {` | `case .Success(v: i64) => {` |
| :161 | `case .Err(e: i32) => {` | `case .Failure(e: i32) => {` |
| :177 | `// RuntimeSeedL(8589934660) = 2^33 + 88 is the i64 Ok expectation` | `// RuntimeSeedL(8589934660) = 2^33 + 88 is the i64 Success expectation` |

#### B.1.10 fork/conformance/programs/error_handling/question_generic_thread_diff.diff.cpp (9 lines)

| Line | Before | After |
| --- | --- | --- |
| :10 | `` // final Ok payload IS the last threaded value (`b`, = 2 * seed on `` | `` // final Success payload IS the last threaded value (`b`, = 2 * seed on `` |
| :17 | `// compares the Ok payload against the same independently runtime-computed` | `// compares the Success payload against the same independently runtime-computed` |
| :32 | `static auto Ok(T v) -> Result<T> {` | `static auto Success(T v) -> Result<T> {` |
| :37 | `static auto Err(int e) -> Result<T> {` | `static auto Failure(int e) -> Result<T> {` |
| :51 | `return Err<T>(tag);` | `return Failure<T>(tag);` |
| :53 | `return Ok(x);` | `return Success(x);` |
| :63 | `return Err<T>(r1.e);` | `return Failure<T>(r1.e);` |
| :71 | `return Err<T>(r2.e);` | `return Failure<T>(r2.e);` |
| :76 | `return Ok(b);` | `return Success(b);` |

#### B.1.11 fork/conformance/programs/error_handling/question_propagation_diff.carbon (14 lines)

| Line | Before | After |
| --- | --- | --- |
| :24 | `Ok(v: T),` | `Success(v: T),` |
| :25 | `Err(e: E)` | `Failure(e: E)` |
| :39 | `case .Ok(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` | `case .Success(v: T) => { return Core.ControlFlow(T, E).Continue(v); }` |
| :40 | `case .Err(e: E) => { return Core.ControlFlow(T, E).Break(e); }` | `case .Failure(e: E) => { return Core.ControlFlow(T, E).Break(e); }` |
| :51 | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Err(e); }` | `fn FromBreak(e: E) -> Self { return MyResult(T, E).Failure(e); }` |
| :55 | `if (fail_at == 3) { return MyResult(i32, i32).Err(30 + n); }` | `if (fail_at == 3) { return MyResult(i32, i32).Failure(30 + n); }` |
| :56 | `return MyResult(i32, i32).Ok(n + 1);` | `return MyResult(i32, i32).Success(n + 1);` |
| :61 | `if (fail_at == 2) { return MyResult(i32, i32).Err(20 + v); }` | `if (fail_at == 2) { return MyResult(i32, i32).Failure(20 + v); }` |
| :62 | `return MyResult(i32, i32).Ok(v + 1);` | `return MyResult(i32, i32).Success(v + 1);` |
| :67 | `if (fail_at == 1) { return MyResult(i32, i32).Err(10 + v); }` | `if (fail_at == 1) { return MyResult(i32, i32).Failure(10 + v); }` |
| :68 | `return MyResult(i32, i32).Ok(v + 1);` | `return MyResult(i32, i32).Success(v + 1);` |
| :71 | `// Prints the outcome tag (0 = Ok, 1 = Err) and the payload.` | `// Prints the outcome tag (0 = Success, 1 = Failure) and the payload.` |
| :74 | `case .Ok(v: i32) => {` | `case .Success(v: i32) => {` |
| :78 | `case .Err(e: i32) => {` | `case .Failure(e: i32) => {` |

#### B.1.12 fork/conformance/programs/error_handling/question_propagation_diff.diff.cpp (10 lines)

| Line | Before | After |
| --- | --- | --- |
| :22 | `static auto Ok(int v) -> Result { return {true, v}; }` | `static auto Success(int v) -> Result { return {true, v}; }` |
| :23 | `static auto Err(int e) -> Result { return {false, e}; }` | `static auto Failure(int e) -> Result { return {false, e}; }` |
| :27 | `return Err(30 + n);` | `return Failure(30 + n);` |
| :29 | `return Ok(n + 1);` | `return Success(n + 1);` |
| :36 | `return Err(r.v);` | `return Failure(r.v);` |
| :40 | `return Err(20 + v);` | `return Failure(20 + v);` |
| :42 | `return Ok(v + 1);` | `return Success(v + 1);` |
| :48 | `return Err(r.v);` | `return Failure(r.v);` |
| :52 | `return Err(10 + v);` | `return Failure(10 + v);` |
| :54 | `return Ok(v + 1);` | `return Success(v + 1);` |

#### B.1.13 fork/conformance/programs/error_handling/result_prelude_diff.carbon (9 lines)

| Line | Before | After |
| --- | --- | --- |
| :49 | `return Core.Result(i32, ErrA).Err(code as ErrA);` | `return Core.Result(i32, ErrA).Failure(code as ErrA);` |
| :53 | `if (fail_at == 3) { return Core.Result(i32, ErrA).Err((303 as i32) as ErrA); }` | `if (fail_at == 3) { return Core.Result(i32, ErrA).Failure((303 as i32) as ErrA); }` |
| :54 | `return Core.Result(i32, ErrA).Ok(n * 2);` | `return Core.Result(i32, ErrA).Success(n * 2);` |
| :60 | `if (fail_at == 2) { return Core.Result(i32, ErrA).Err((202 as i32) as ErrA); }` | `if (fail_at == 2) { return Core.Result(i32, ErrA).Failure((202 as i32) as ErrA); }` |
| :61 | `return Core.Result(i32, ErrA).Ok(v);` | `return Core.Result(i32, ErrA).Success(v);` |
| :68 | `return Core.Result(i32, ErrB).Ok(v);` | `return Core.Result(i32, ErrB).Success(v);` |
| :71 | `// Prints the outcome tag (0 = Ok, 1 = Err) and the payload.` | `// Prints the outcome tag (0 = Success, 1 = Failure) and the payload.` |
| :74 | `case .Ok(v: i32) => {` | `case .Success(v: i32) => {` |
| :78 | `case .Err(e: ErrB) => {` | `case .Failure(e: ErrB) => {` |

#### B.1.14 fork/conformance/programs/error_handling/result_prelude_diff.diff.cpp (11 lines)

| Line | Before | After |
| --- | --- | --- |
| :21 | `static auto Ok(int v) -> Result { return {true, v}; }` | `static auto Success(int v) -> Result { return {true, v}; }` |
| :22 | `static auto Err(int e) -> Result { return {false, e}; }` | `static auto Failure(int e) -> Result { return {false, e}; }` |
| :27 | `static auto Fail(int code) -> Result { return Err(code); }` | `static auto Fail(int code) -> Result { return Failure(code); }` |
| :31 | `return Err(303);` | `return Failure(303);` |
| :33 | `return Ok(n * 2);` | `return Success(n * 2);` |
| :40 | `return Err(r.v);` | `return Failure(r.v);` |
| :44 | `return Err(202);` | `return Failure(202);` |
| :46 | `return Ok(v);` | `return Success(v);` |
| :53 | `return Err(ToErrB(r.v));` | `return Failure(ToErrB(r.v));` |
| :60 | `return Err(ToErrB(f.v));` | `return Failure(ToErrB(f.v));` |
| :63 | `return Ok(v);` | `return Success(v);` |

#### B.1.15 fork/conformance/programs/error_handling/run_result_err.carbon, renamed run_result_failure.carbon by `git mv` (7 lines; D-EHC-13, review fold: B-M1)

| Line | Before | After |
| --- | --- | --- |
| :12 | `` // `fn Run() -> Core.Result((), i32)` is a valid entry point, and an `.Err` `` | `` // `fn Run() -> Core.Result((), i32)` is a valid entry point, and a `.Failure` `` |
| :15 | `` // ("carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1" — `` | `` // ("carbon: `Main.Run` returned `.Failure` of type `i32`; exiting with code 1" — `` |
| :18 | `` // `.Err(7)` on the runtime-computed input `RuntimeSeed(-20)` = 0 (R16d), so `` | `` // `.Failure(7)` on the runtime-computed input `RuntimeSeed(-20)` = 0 (R16d), so `` |
| :20 | `` // the `?` must NOT run and the trailing `.Ok(())` must NOT exit 0 — a `?` `` | `` // the `?` must NOT run and the trailing `.Success(())` must NOT exit 0 — a `?` `` |
| :26 | `if (n == 0) { return Core.Result((), i32).Err(n + 7); }` | `if (n == 0) { return Core.Result((), i32).Failure(n + 7); }` |
| :27 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
| :36 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |

#### B.1.16 fork/conformance/programs/error_handling/run_result_ok.carbon, renamed run_result_success.carbon by `git mv` (6 lines; D-EHC-13, review fold: B-M1)

| Line | Before | After |
| --- | --- | --- |
| :14 | `` // inside `Run` itself, and `.Ok(code)` makes `code` the process exit code — `` | `` // inside `Run` itself, and `.Success(code)` makes `code` the process exit code — `` |
| :18 | `` // and Half(40) = 20 are printed, then `.Ok(RuntimeSeed(-17))` = `.Ok(3)` `` | `` // and Half(40) = 20 are printed, then `.Success(RuntimeSeed(-17))` = `.Success(3)` `` |
| :20 | `` // `.Err` epilogue) with a shorter stdout. `` | `` // `.Failure` epilogue) with a shorter stdout. `` |
| :25 | `if ((n / 2) * 2 == n) { return Core.Result(i32, i32).Ok(n / 2); }` | `if ((n / 2) * 2 == n) { return Core.Result(i32, i32).Success(n / 2); }` |
| :26 | `return Core.Result(i32, i32).Err(n);` | `return Core.Result(i32, i32).Failure(n);` |
| :36 | `return Core.Result(i32, i32).Ok(RuntimeSeed(-17));` | `return Core.Result(i32, i32).Success(RuntimeSeed(-17));` |

#### B.1.17 fork/conformance/programs/project/evaluator_tutorial_errors.carbon (7 lines)

| Line | Before | After |
| --- | --- | --- |
| :24 | `return Core.Result(i32, i32).Err(a);` | `return Core.Result(i32, i32).Failure(a);` |
| :26 | `return Core.Result(i32, i32).Ok(a / b);` | `return Core.Result(i32, i32).Success(a / b);` |
| :32 | `return Core.Result(i32, i32).Ok(mean);` | `return Core.Result(i32, i32).Success(mean);` |
| :37 | `case .Ok(v: i32) => { Core.Print(v); }` | `case .Success(v: i32) => { Core.Print(v); }` |
| :38 | `case .Err(e: i32) => { Core.Print(-e); }` | `case .Failure(e: i32) => { Core.Print(-e); }` |
| :45 | `if (let .Ok(v: i32) = Divide(9, 3)) {` | `if (let .Success(v: i32) = Divide(9, 3)) {` |
| :48 | `if (let .Ok(v: i32) = Divide(1, 0)) {` | `if (let .Success(v: i32) = Divide(1, 0)) {` |

#### B.1.18 fork/conformance/programs/control_flow/choice_payload_roundtrip_diff.carbon (6 lines)

| Line | Before | After |
| --- | --- | --- |
| :22 | `Ok(value: i32),` | `Success(value: i32),` |
| :23 | `Err` | `Failure` |
| :28 | `case .Ok(value: i32) => { return value; }` | `case .Success(value: i32) => { return value; }` |
| :29 | `case .Err => { return -1; }` | `case .Failure => { return -1; }` |
| :36 | `Core.Print(Consume(IntResult.Ok(seed + 2)));` | `Core.Print(Consume(IntResult.Success(seed + 2)));` |
| :37 | `Core.Print(Consume(IntResult.Err));` | `Core.Print(Consume(IntResult.Failure));` |

### B.2 Each program's EXPECT, re-derived by hand (R16 (d))

`RuntimeSeed(x) = x + 20` in every program. No printed byte depends on an
alternative's name; every value below is arithmetic over the seed and the
design's rules (D10 for exit codes, the catching thunk's discriminant for the
C++ programs). Each EXPECT is therefore UNCHANGED; the prototype's scoreboard
confirms every row PASS.

1.  error_handling/control_flow_constructs.carbon — EXPECT-EXIT 0,
    EXPECT-STDOUT `42`, `-1`. `Doubled(RuntimeSeed(1))` = `Doubled(21)`:
    `ParsePositive(21)` is `Success(21)`, `?` continues, `Success(42)`, the
    first match prints 42; `Doubled(RuntimeSeed(-50))` = `Doubled(-30)`:
    `ParsePositive(-30)` is `Failure(-1)`, `?` propagates, the second match's
    failure arm prints -1; `return 0`.
2.  cpp_exception_catch_diff.carbon (+ .diff.cpp) — EXPECT-EXIT 0, DIFF-1 (no
    EXPECT-STDOUT). `Probe(21, 3)`: `CheckedScale` returns 63, the thunk's
    discriminant 0 builds `Success(63)`, prints `1`, `63`; `Probe(21, 0)`:
    `throw`, discriminant 1 builds `Failure(exception)`, prints `0`, `-1`;
    `Probe(-7, 5)`: -35, prints `1`, `-35`. The oracle's `try`/`catch` prints
    the same six lines; the comparison is byte equality, unchanged.
3.  cpp_exception_interop.carbon — EXPECT-EXIT 0, EXPECT-STDOUT `7`, `-1`.
    `PositiveOrThrow(7)` prints 7 directly; `Checked(-2)` throws, the thunk's
    discriminant 1 builds the failure alternative, the failure arm prints -1;
    the success arm's `return 1` belt is not taken; `return 0`.
4.  cpp_exception_rethrow_export.carbon — EXPECT-EXIT 0, EXPECT-STDOUT `7`,
    `110`. `Recover(7)`: `Catching(7)` is a value, `r.value()` = 7;
    `Recover(-5)`: `Throws(-5)` throws, `Catching` returns the failure
    alternative with the primary exception, `r` is false, `rethrow()` throws
    the original `std::runtime_error("negative")`, `e.what()[0]` = 'n' = 110.
    The header's renamed members are internal to `value()`/`error()`.
5.  cpp_expected_export.carbon — EXPECT-EXIT 0, EXPECT-STDOUT `10`, `3`, `1`,
    `9`. `Consume(5)`: `Parse(5)` = `Success(5)`, `has_value()`, 5*2 = 10;
    `Consume(-3)`: `Failure(3)`, `error()` = 3; `ConsumeUnit(4)`: even,
    `Success(())`, `r` true, 1; `ConsumeUnit(9)`: odd, `Failure(9)`, 9. The
    header reads `disc_ == 0` as a value (D-EHC-1's order).
6.  question_generic_diff.carbon (+ .diff.cpp) — EXPECT-EXIT 0, DIFF-1. Each
    probe prints the tag (0 success, 1 failure) and the payload computed from
    the seed through the generic `?` chain; the oracle computes the same
    numbers with its renamed `Success<T>`/`Failure<T>` helpers; names are
    never printed.
7.  question_generic_thread_diff.carbon (+ .diff.cpp) — EXPECT-EXIT 0,
    DIFF-1. As item 6 with the threaded `b` payload (2 * seed on the success
    path, the i64 leg's 2^33 + 88 expectation); unchanged.
8.  question_propagation_diff.carbon (+ .diff.cpp) — EXPECT-EXIT 0, DIFF-1.
    The 3-deep chain with a runtime-selected failure depth prints `0` and
    the chained value, or `1` and `30 + n`, `20 + v` or `10 + v`; the oracle's
    struct-shaped early returns print the same; unchanged.
9.  result_prelude_diff.carbon (+ .diff.cpp) — EXPECT-EXIT 0, DIFF-1. The
    fork/eh/plan.md §5.A.1 table (depth 0: `0` and `2*seed`; depth 1: `1`,
    `1101`; depth 2: `1`, `1202`; depth 3: `1`, `1303`, the `ErrA` to `ErrB`
    conversion adding 1000); `ErrA`/`ErrB` are not renamed (whole-word
    `Err` does not match them); unchanged.
10. run_result_failure.carbon (run_result_err.carbon at trunk, D-EHC-13) —
    EXPECT-EXIT 1, EXPECT-STDOUT `1`. Prints 1;
    `Fails(RuntimeSeed(-20))` = `Fails(0)` = `Failure(7)`, `?` returns it from
    `Run`; the D10 epilogue writes the stderr line (now naming `.Failure`,
    not asserted by the runner) and exits 1; `2` is never printed.
11. run_result_success.carbon (run_result_ok.carbon at trunk, D-EHC-13) —
    EXPECT-EXIT 3, EXPECT-STDOUT `21`, `20`.
    `Half(42)` = `Success(21)`, prints 21; `Half(40)` = `Success(20)`, prints
    20; `return Success(RuntimeSeed(-17))` = `Success(3)`, the epilogue's
    discriminant 0 returns the payload: exit 3.
12. project/evaluator_tutorial_errors.carbon — EXPECT-EXIT 0, EXPECT-STDOUT
    `3`, `-7`, `3`, `0`. `Average(12, 4)`: 12/4 = 3, printed; `Average(7, 0)`:
    `Divide(7, 0)` = `Failure(7)`, `?` propagates, `Report` prints -7;
    `if (let .Success(v: i32) = Divide(9, 3))` matches, prints 3; `Divide(1,
    0)` = `Failure(1)` does not match `.Success`, the `else` prints 0 (the
    tutorial's "Output" block says the same four lines, and the evaluator
    checker compares both).
13. control_flow/choice_payload_roundtrip_diff.carbon — EXPECT-EXIT 0,
    DIFF-1. `Consume(IntResult.Success(42))` = 42, `Consume(IntResult.Failure)`
    = -1, the oracle's `std::variant` round trip prints the same; unchanged.

The five `.diff.cpp` oracles rename only their helper functions and comments
(`static auto Success(...)`, `static auto Failure(...)`); their `bool ok`
fields, control flow and arithmetic are untouched, so DIFF-1's equality holds
by construction and was measured. The two renamed programs keep their text
but for the lines above; fork/conformance/README.md's rows
`error_handling/run_result_err.carbon` and `error_handling/run_result_ok.carbon`
(:345-346 at trunk) become `error_handling/run_result_failure.carbon` and
`error_handling/run_result_success.carbon` in place (C1; the runner's
self-test checks the table against the programs). In the After cell of
B.1.15's :12, "a `.Failure`", not the mechanical "an `.Failure`" (the fixer's
F-1, 2026-11-09).

## Appendix C: the docs amendments, verbatim

`<date>` is the UTC date of commit P (`date -u +%F`). Code blocks and code
spans go in C1; the amendment paragraphs in P (D-EHC-9). Each amendment
quotes upstream at ca1898506 (§0.6).

### C.1 docs/design/README.md:4046-4050

Replace the paragraph "Errors are values: ... is not `Core.Result`.)" (five
lines at trunk) with:

<!-- google-doc-style-ignore -->

```markdown
Errors are values: a fallible function returns the [choice type](#choice-types)
`Core.Result(T, E)`, holding either a `Success` value or a `Failure` error,
the alternative names of the `IntResult` example [above](#choice-types) and of
upstream's generic `Result` under "Generic choice types".

> **Fork amendment (<date>, EH-C, W-346).** Until this date the alternatives
> were spelled `Ok`/`Err` (sub-decision F-006a, user, 2026-07-19), and this
> paragraph read "(The alternative names `Ok`/`Err` were decided by the user —
> sub-decision F-006a; the illustrative `IntResult` example above uses
> `Success`/`Failure` and is not `Core.Result`.)". Under fork/rulebook.md R32
> that was a second spelling of upstream's mechanism (RG-1, D-RG-5): upstream's
> docs/design/README.md at ca1898506 says "At this point, errors are
> represented using [choice types](#choice-types) like `Result` and
> `Optional`." (:3858-3860) and spells the result choice `Success(value: i32),`
> / `Failure(error: String),` (:2176-2177) and `Success(value: T),` /
> `Failure(error: Error)` (:3165-3166). The user may veto the reversal (R29).
```

<!-- google-doc-style-resume -->

The sentence that follows at trunk ("Results are consumed with `match` ...")
is unchanged.

### C.2 docs/design/error_handling.md

The block :100-105: `Success(value: T),` and `Failure(error: E)` (C1). The
paragraph :112-118 ("The alternative names are `Ok` and `Err`, decided ... are
`Ok` and `Err`.") becomes:

<!-- google-doc-style-ignore -->

```markdown
The alternative names are `Success` and `Failure`, the spellings of upstream's
result choices: the `IntResult` example in the
[language overview](README.md#choice-types) and the generic `Result` under
"Generic choice types" (upstream docs/design/README.md:2176-2177 and
:3165-3166 at ca1898506). See [decision D1](#decisions-within-this-design).

> **Fork amendment (<date>, EH-C, W-346).** From F-006a (user, 2026-07-19)
> until this date the alternatives were spelled `Ok`/`Err`, and this paragraph
> read: "The alternative names are `Ok` and `Err`, decided by the user as part
> of the F-006 review (sub-decision F-006a); see decision D1. The illustrative
> `IntResult` example in the language overview spells its alternatives
> `Success`/`Failure`; that example predates this decision, is not
> `Core.Result`, and does not set the naming — the normative alternative names
> for `Core.Result` are `Ok` and `Err`." RG-1 (D-RG-5, 2026-10-28) classified
> that spelling a drift under fork/rulebook.md R32 (d), because upstream's
> README names `Result` as the error representation ("At this point, errors
> are represented using `[choice types](#choice-types)` like `Result` and
> `Optional`.", :3858-3860 at ca1898506) and the section it links spells the
> result choice `Success`/`Failure`; EH-C renamed every use. No alias remains:
> the former spelling is an ordinary unknown member
> (`MemberNameNotFoundInSpecificScope`). The user may veto the reversal (R29).
```

<!-- google-doc-style-resume -->

The quoted link markup in the blockquote is set in a code span, as §0.6 and
D.2 set it: error_handling.md has no `#choice-types` anchor, and a live link
there fails rumdl's MD051 and the check-links hook (measured by the fold's
prek run on the prototype; the fixer's F-3, 2026-11-09). C.1 keeps the live
link, README.md's anchor being its own.

The sketch lines :133 "// Equivalent to `Core.Result(File,
IoError).Failure(...)`.", :134 `return .Failure(IoError.NotFound);`, :136
`return .Success(OpenExisting(name));`, :153 `case .Success(f: File) => {`, :156
`case .Failure(e: IoError) => {`, :173 `let .Success(f: File) = Open(from) else
{`, :174 `return .Failure(IoError.NotFound);`, :178 `return .Success(());`, :185
`if (let .Success(f: File) = Open(name)) {`, :209 `return .Success(c);`,
:382-383 the `Try` impl's two `case` arms, :389 `fn FromBreak(b: E) -> Self {
return Result(T, E).Failure(b); }`, :695 "a thrown exception becomes the
`.Failure` alternative and propagates.", :697 `return .Success(n);`, :736 the
quoted workaround `.Success(Cpp.f(x)?); }` (C1). The list item :562-563: "`Result`
forms, on `.Success(())`: exit code 0; on `.Success(code)`: the returned code;
on `.Failure(e)`: the runtime writes a diagnostic to" (C1; the rest of the item
unchanged). The layout note :864: "(a discriminant byte, `Success` = 0 and
`Failure` = 1, then the payload union" (C1). D10's :1002 "`.Failure` maps to a
stderr diagnostic and exit code 1." (C1). D1 :949-956 becomes (P):

<!-- google-doc-style-ignore -->

```markdown
-   **D1 — Alternative names are `Success`/`Failure` (EH-C, <date>, W-346,
    under fork/rulebook.md R32; from 2026-07-19 until then `Ok`/`Err`, the
    user's sub-decision F-006a).** The option paper left the naming open
    between `Success`/`Failure` (the spelling of the `IntResult` example in
    the [language overview](README.md#choice-types)) and `Ok`/`Err`; the user
    ratified `Ok`/`Err` on 2026-07-19, reading the overview's example as
    illustrative of choice types generally. V-3b (2026-10-21) withdrew that
    override ground, RG-1 (D-RG-5, 2026-10-28) classified the spelling a
    drift (upstream's README names `Result` as the error representation,
    :3858-3860 at ca1898506, and the choice-types section it links spells
    `Success`/`Failure`, :2176-2177), and EH-C realigned the fork: the
    prelude, the toolchain, every golden, program and page spell
    `Success`/`Failure`, the order (`Success` = 0) and the payload names
    (`value`, `error`) unchanged. The user may veto the reversal (R29); a veto
    restores F-006a by a dated note here and in fork/decision-log.md.
```

<!-- google-doc-style-resume -->

### C.3 docs/design/optional.md:434

"For `E = ()`, absence propagates as `.Failure(())` (spelled `.Err(())` until
EH-C, <date>, W-346); for any other `E` it is a" (C1 for the code span, P for
the parenthetical; rumdl reflows the paragraph).

### C.4 docs/guides/tutorial.md

The block :360-391 (C1): the seven renamed lines of Appendix B.1.17's program
(:366, :368, :374, :379, :380, :387, :390), byte for byte with the program (the
checker compares them); the page's eighth hit, :409, is prose and goes in P
(amended 2026-11-09, review fold: B-m7). The prose :408-409 (P): "What to
notice: `Core.Result(T, E)` is a `choice` in the prelude, with the alternatives
`Success` and `Failure` (this fork spelled them `Ok`/`Err` until <date>, EH-C,
W-346; a program written then gets ``member name `Ok` not found in
`Core.Result(i32, i32)` ``). The postfix `?` returns the error to the caller, or
unwraps the value." The rest of the paragraph unchanged.

### C.5 docs/guides/evaluator_faq.md:356

The ```text line (C1): ``carbon: `Main.Run` returned `.Failure` of type `i32`;
exiting with code 1``. After the block (P), one sentence: "Until <date> (EH-C,
W-346) the line named `.Err`, the alternative's former spelling."

## Appendix D: the records texts, verbatim

`<date>` is each commit's UTC date; `<C1>`, `<F1>`, `<P>`, `<R>` the commit
shas; `<tip>` upstream's sha at D's re-fetch. No text below names a PR number
or the sha of the commit that writes it: `<N>` exists only after the PR opens
(§3 item 10) and a commit's own sha is "this commit" or "this one", OV-4's
form (amended 2026-11-09, review fold: RR1-M1). M-0 merged trunk 725570464
(PR 69 plus the fork/tools/carbonbuild records commit, 7663e7a8d..725570464,
no use site), not the fca1e9e2f the Status paragraph names, so every text
below and in Appendices E and F that prints M-0's merge base reads 725570464
(amended 2026-11-09, review fold: B1).

### D.1 fork/inventory/work-items.json

W-346: `"kind": "implemented"`; `"size"` stays `"M"` (RG-1's estimate, not
re-sized); the title's leading tag "EH-C (R32 (d); RG-1, D-RG-5): " replaced
by "EH-C (DISCHARGED at EH-C, <date>; R32 (d); RG-1, D-RG-5): ", W-341's form
(amended 2026-11-09, review fold: B-m5); `evidence` gains, first: "core/prelude/
types/result.carbon:28-31 at <C1> (`Success(value: T)`, `Failure(error: E)`);
toolchain/check/cpp/thunk.cpp:1506-1509 (the minted identifiers);
toolchain/lower/handle.cpp:421 (the stderr line); toolchain/install/include/
carbon/expected.h:154-155 and :291; the 35 goldens of fork/eh/ehc-plan.md
Appendix A with the `fail_old_names` split of check/testdata/operators/
question_result.carbon; the 18 programs of Appendix B; docs/design/README.md,
error_handling.md, optional.md, docs/guides/tutorial.md and evaluator_faq.md's
dated amendments (Appendix C); container-measured (R33 (b)): gate 2047 of
2047 after the fill <F1>, conformance 228/0/13 over 241, 51/56 bullets; the
reconciliation greps of fork/eh/ehc-plan.md §8.7 on the tree at <R>: grep 1
lists 17 lines, all dated history (common/raw_hashtable.h:1314;
core/prelude/types/result.carbon:56; the `fail_old_names` split's three
lines; the twelve amendment lines of docs/design/README.md,
error_handling.md, optional.md, docs/guides/tutorial.md and
evaluator_faq.md), greps 2 and 3 (file and split names) are empty, grep 4
(the header's consumers' `.ok()`) is 0" (amended 2026-11-09, review fold:
A-M1 / B-M1 / B-M3). `notes` gains, appended: " DISCHARGED
<date> by EH-C (fork/eh/ehc-plan.md, D-EHC-1 to D-EHC-12): renamed at the
root with every use; no alias; the former spelling diagnoses
`MemberNameNotFoundInSpecificScope`; register row T2.1 ALIGNED; F-006a
reversed by a dated note under the owner directive of 2026-10-21, veto-able
(R29). Break condition of the discharge: the user's veto (then the rename is
reverted by a new commit and this item reopens with the veto recorded against
R32)."

W-380, new, after W-378 (ARB-2's item, on trunk since PR 69, so the ledger
ends W-377, W-378, W-380; amended 2026-11-09, review fold: B-m4): `"kind":
"missing-feature"` (W-346's own kind; the ledger's README lists no docs kind
and rev 2's `doc-gap` existed nowhere, so no new kind is minted; amended
2026-11-09, review fold: RR1-m4), `"title": "PR 53 (SAFE-1; EH-C,
D-RG-8's break condition): docs/design/safety/rust_interop.md:223 names
`Ok`/`Err` as `Core.Result`'s variants where trunk now spells
`Success`/`Failure` -- a rename commit on PR 53's branch before it lands"`,
`"subsystem": "docs/design/safety (PR 53: rust_interop.md)"`, `"size": "S"`,
`"bullet": "none"`, `"evidence": ["docs/design/safety/rust_interop.md:223 at
2407efa74 (PR 53's head): \"with `Ok`/`Err` as the variants\"",
"fork/register/rg1-plan.md D-RG-8 (a held PR that only uses a trunk spelling
does not carry the drift; break condition: W-346 is scheduled before a held PR
that uses the spelling lands; that PR then gains a rename commit before it
lands)", "fork/eh/ehc-plan.md §0.4, D-EHC-11, D-EHC-12"]`, `"blocked_by":
[]`, `"notes": "Filed <date> by EH-C at its discharge: EH-C lands before PR
53 (W-346's schedule puts it before UA-3; PR 53 waits on SAFE-4,
fork/ORCHESTRATION.md Next actions item 14), so D-RG-8's break condition
fires for PR 53's one line. Work: one commit on
claude/carbon-fork-0-1-safe that spells the row `Success`/`Failure`, before
PR 53 lands (R32 (e): a new commit, never a rewrite). Owner: PR 53's landing.
Break condition: the user vetoes EH-C's reversal (then this item is withdrawn
with it)."` (the notes' tense amended 2026-11-09, review fold: RR1-M1: D
cannot claim a landing).

The `generated` and `source` fields: `source` gains the sentence "EH-C
(<date>) discharged W-346 and filed W-380."

### D.2 fork/decision-log.md: the entry

Placed directly before "### EH-B: catching thunks, Cpp.Exception,
Carbon::expected export (2026-09-27)". R writes the first block; D appends
the second block's three paragraphs to the entry (amended 2026-11-09, review
fold: B-M3); neither names a PR number or its own sha (RR1-M1):

<!-- google-doc-style-ignore -->

```markdown
### EH-C: `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346) (<date>)

Placed here, before EH-B's entry, because the log groups entries by workstream
and EH-C is the error-handling workstream's third slice (fork/eh/ehc-plan.md,
beside fork/eh/plan.md's EH-A and EH-B). Line cites are to trunk aee70185c
unless a sha is named. Branch claude/carbon-fork-0-1-ehc, commits <plan>
(the plan's revisions), <M-0> (the merge of trunk 725570464, PR 69 and the
arbiter scripts' records commit; amended 2026-11-09, review fold: B1), <C1>,
<F1>, <P>, the reviews' fix commits <fixes> and this one; the discharge
commit appends the last three paragraphs.

_The item and the rule._ W-346, filed by RG-1 (D-RG-5, 2026-10-28), classified
the user's sub-decision F-006a (`Ok`/`Err`, 2026-07-19) a DRIFT under R32 (d):
upstream's docs/design/README.md names `Result` as Carbon's error
representation ("At this point, errors are represented using [choice
types](#choice-types) like `Result` and `Optional`.", :3858-3860 at
ca1898506, re-read at <tip>) and the choice-types section it links spells the
result choice `Success(value: i32),` / `Failure(error: String),` (:2176-2177),
its uses `.Failure(...)`, `.Success(r)`, `case .Success(value: i32)`, `case
.Failure(error: String)` (:2191-2207), and the generic `Result` under
"Generic choice types" `Success(value: T),` / `Failure(error: Error)`
(:3165-3166); no upstream text spells `Ok` or `Err` (`git grep` over
docs/design, core and proposals is empty); p000157:690-693 spells the same
and is provisional by its :228-229. Upstream's prelude has no `Result` and no
`Try`, and its parser has no `?` handler (silence checks T1.1 to T1.3, T11.2,
T11.4 at <tip>), so D-EH-1 to D-EH-6 stand and only the spelling changes.
This entry reverses F-006a under the owner directive of 2026-10-21
("Direction drifts are not permitted", R32, V-3b); the user may veto it
(R29), the veto route being D-EHC-1's.

_The decisions_ (fork/eh/ehc-plan.md §1, auto-adopted under R29 (a), each
with its break condition there): D-EHC-1 the names `Success`/`Failure` in
upstream's order, `Success` = 0 and `Failure` = 1, which the entry point's
epilogue, the `Try` impl's arms, the catching thunk's `int` discriminant and
`<carbon/expected.h>` rely on (the order-swap mutant: 7 goldens and 4
programs red); the payload names and the parameter `E` unchanged. D-EHC-2 no
alias, no deprecation period (an alternative alias is a parse error inside a
choice; a user-side alias is caught by the discharge grep only). D-EHC-3 the
former spelling is an ordinary unknown member, ``member name `Ok` not found in
`Core.Result(i32, i32)` `` [MemberNameNotFoundInSpecificScope], no note,
pinned by the `fail_old_names` split of check/testdata/operators/
question_result.carbon. D-EHC-4 every toolchain identifier that spells an
alternative renamed: thunk.cpp's minted `"Success"`/`"Failure"` identifiers,
its `success_*`/`failure_*` locals and `return_success`/`return_failure`,
lower/handle.cpp's `run.result.success`
/`run.result.failure`/`run.result.is_success` IR names and the stderr line
``carbon: `Main.Run` returned `.Failure` of type `E`; exiting with code 1``,
the `main.result.failure.message` global and its accessors, comments; the
thunk's `err` out-pointer locals, the oracles' `bool ok` and
raw_hashtable.h's English "Ok," stay. D-EHC-5 `<carbon/expected.h>`'s payload
members `success`/`failure` and `expected<void, E>::success()`; the
`std::expected` vocabulary unchanged. D-EHC-6 the five pages' dated
amendments, upstream quoted by sha (Appendix C of the plan). D-EHC-7 these
records. D-EHC-8 user test choices and oracle helpers renamed too. D-EHC-9
C1 carries every checker-visible line (the tutorial's block, the FAQ's line,
check_faq.py), P the prose. D-EHC-10 no new program; every EXPECT unchanged.
D-EHC-11 W-380 to W-385 reserved, W-380 filed for PR 53's
rust_interop.md:223, no F id. D-EHC-12 one PR, two implementation reviews, a
fix budget of two, LAND-1's landing, M-0 first because trunk moved to
fca1e9e2f (PR 69) during the plan's reviews. D-EHC-13 the two program files
(run_result_success.carbon, run_result_failure.carbon) and the five split
headers (`unit_success`, `i32_success`) renamed too.

_Measured (container, R33 (b); the plan's §0.3 and §8)._ Gate on C1 alone:
`[  PASSED  ] 2015 tests.` with the 32 goldens of the plan's §4 failing with
"Autoupdate would make changes" (the arbiter's summary line reads "2015
passed, 0 failed", the per-test lines being the criterion); after <F1>: 2047
passed, 0 failed; conformance 228/0/13 over 241, 51/56 bullets, byte for byte
trunk's; `runner.py --self-test` 0 errors on both sample checkers;
check_faq.py 13 reproducers, 0 errors (fork) and 17 (nightly);
fork/designdocs/check_samples.py --toolchain 0 errors; prek clean at a
fixpoint on every commit; the mutants: the order swapped turns 7 goldens and
4 programs red, the thunk's identifiers left as `Ok`/`Err` turn 3 goldens
red.

_V-3a register (RG-1's vocabulary, re-read at <tip>):_ T2.1 (F-006a's
alternatives) ALIGNED with README.md:2176-2177 and :3165-3166, break
condition D-EHC-1's (upstream renames or reorders; the user vetoes); T11.1
ALIGNED, its alternatives no longer a drift; T11.3 ALIGNED (the order);
T11.2, T11.4, T1.1 to T1.3 NONE, unchanged, W-355; two new silence checks
T2.1 in fork/register/rg1-checks.tsv (`Ok(`/`Err(` in upstream's docs/design
and proposals; `choice Result`/`class Result` under upstream's core; both 0,
96 checks in all) fire the upstream-side break conditions.

_Not run._ clang-tidy (no binary in the container's clang 21 subset), R21's
hosted gate (Actions disabled; owed when it returns), Bazel-only tests (no
Bazel), the owner's runner (R28).
```

<!-- google-doc-style-resume -->

Appended by D, after the _Not run_ paragraph (`<R>` is R's sha, the tree the
greps ran on; D's own sha is "this commit", as OV-4's entry wrote "and this
one"; `<count>`, `<n>`, `<w>` and `<line>` are D's measurements):

<!-- google-doc-style-ignore -->

```markdown
_Reconciliation greps (fork/eh/ehc-plan.md §8.7, on the tree at <R>)._ Grep
1, `git grep -nE '\bOk\b|\bErr\b' -- . ':!fork/'` on non-CHECK lines: 17
lines, all dated history: common/raw_hashtable.h:1314 (English),
core/prelude/types/result.carbon:56 (the history comment), the
`fail_old_names` split's three lines in check/testdata/operators/
question_result.carbon, and the twelve amendment lines of
docs/design/README.md, docs/design/error_handling.md, docs/design/optional.md,
docs/guides/tutorial.md and docs/guides/evaluator_faq.md; over fork/ every hit
is a closed plan, a dated history note, W-346's and W-380's own ledger text,
RG-1's prose or fork/eh/ehc-plan.md (<count> files, listed in the plan's
§0.1). Grep 2, `git ls-files | grep -E '(^|[_/])(ok|err)[_.]'`: empty. Grep
3, the split-header grep: empty; the old file names survive only in
fork/conformance/out/scoreboard.json, fork/eh/plan.md and a ledger evidence
string at a sha (history). Grep 4, `.ok()` over the header's consumers and
`expected<[^>]*>::ok\(` over the tree: 0 and 1, the one line being this
plan's own D-EHC-5 sentence (fork/eh/ehc-plan.md:<line>), 0 elsewhere (amended
2026-11-09, review fold: B2). `grep -rn
'identifiers().Add("' toolchain/check/cpp/thunk.cpp` shows `"Success"` and
`"Failure"` only.

_Ids._ W-380 to W-385 reserved by the plan's §0.7 re-scan (<n> refs, <w>
worktrees, after a fetch at D): W-380 was no ledger item's id on any ref or
worktree (0 by the plan's §8.9 count) and appeared only as reserved text, in
W-378's notes, the weekly entry of 2026-11-09, ARB-2's entry and the plan;
W-380 filed after W-378; W-381 to W-385 unused.

_Discharged by this commit: W-346 (EH-C)._
```

<!-- google-doc-style-resume -->

### D.3 The F-006a reversal note

Appended to the F-006 entry's first paragraph (after "... with alternatives
`Ok(T)` / `Err(E)`.", decision-log.md:1486-1488):

<!-- google-doc-style-ignore -->

```markdown
_Reversed (<date>, EH-C, W-346; fork/eh/ehc-plan.md D-EHC-1):_ the
alternatives are `Success(value: T)` and `Failure(error: E)`, upstream's
spellings (docs/design/README.md:2176-2177 and :3165-3166 at ca1898506),
under the owner directive of 2026-10-21 ("Direction drifts are not
permitted", R32, V-3b) after RG-1 classified this sub-decision a DRIFT
(D-RG-5, 2026-10-28); the user's decision of 2026-07-19 is reversed, not
renumbered, and the user may veto the reversal (R29; the veto route is
D-EHC-1's). See the entry "EH-C: `Core.Result`'s alternatives renamed to
`Success`/`Failure` (W-346) (<date>)".
```

<!-- google-doc-style-resume -->

### D.4 The RG-1 entry's note

Appended as the entry's last paragraph (after its _Landed_ paragraph,
decision-log.md:1010-1013 at aee70185c and at fca1e9e2f; the cite corrected
2026-11-09, review fold: RR1-m5, by measurement, the review's ":1011-1013"
being off by one too; the text without a PR number or a landing claim, R
knowing neither: RR1-M1):

<!-- google-doc-style-ignore -->

```markdown
_W-346 resolved (<date>, EH-C):_ D-RG-5's rename is implemented on
claude/carbon-fork-0-1-ehc (its PR lands by LAND-1); register row T2.1 is
ALIGNED; F-006a carries its reversal note; PR 53's one line is W-380. See
the entry "EH-C: ..." under the EH entries.
```

<!-- google-doc-style-resume -->

### D.5 The other dated notes

-   V-3's paragraph (decision-log.md:38-41, "... (for example F-006a Ok/Err
    vs the README's illustrative Success/Failure) enter a divergence-risk
    register ..."): append "(F-006a's spelling was realigned by EH-C,
    <date>, W-346.)" after the paragraph's last sentence.
-   The F-006 entry's B1 landing note (:1534-1542, "... (with F-006a's
    `Ok`/`Err` already on the register). ... F-006a DRIFT, W-346._"): after
    "F-006a DRIFT, W-346." insert " (resolved <date>, EH-C: T2.1 ALIGNED)".
-   The EH-A entry's RG-1 paragraph (:18204-18211, "... its alternatives are
    W-346's), ..."): after "its alternatives are W-346's" insert ", renamed
    `Success`/`Failure` by EH-C, <date>".
-   The UA-1 entry's RG-1 paragraph (:19204-19209, "F-006a's `Ok`/`Err`
    (classified 2026-10-28, RG-1: DRIFT, W-346, ...)"): after "veto-able;"
    insert "resolved <date> by EH-C (ALIGNED);".
-   The 2026-11-09 weekly entry: after "UA-3 stays scheduled after PR 53
    lands and after EH-C (W-346)" (:19570-19571) insert " (EH-C: W-346
    discharged on its branch <date>; PR by LAND-1)" (amended 2026-11-09,
    review fold: RR1-M1); after "W-378 is the next free id, and this check
    files none."
    (:19598) insert " (EH-C, <date>: W-380 to W-385 reserved, W-380 filed;
    the plan's §0.7.)".

### D.6 The register

fork/register/rg1-plan.md §2.T2, row T2.1, its Verdict cell: "**ALIGNED**
(EH-C, <date>, W-346 DISCHARGED: `Success(value: T)` / `Failure(error: E)`,
core/prelude/types/result.carbon:28-31 at <C1>; was DRIFT, R29, D-RG-5,
amended 2026-10-28, review fold: A-m1, B-m4)"; its Break condition cell:
"D-EHC-1's: upstream renames or reorders the alternatives (take them), or
the user vetoes the reversal (W-346 reopens)"; its Item cell: "W-355 (the
quote rows and the silence check T2.1); W-380 for PR 53's line". Row T11.1's
Verdict cell: "ALIGNED (a choice; its alternatives ALIGNED since EH-C,
<date>)" and its Item cell "W-355". Row H3.2's Item cell: "the tutorial's 8
`Ok`/`Err` lines (9 occurrences; RG-1 counted 18) were renamed by EH-C,
<date> (D-RG-8)" (the count §0.1 measured; amended 2026-11-09, review fold:
RR1-m5). No other row and no
prose paragraph changes (D-RG-5 and D-RG-8 are history). R31's counts: rows
unchanged, headings unchanged.

fork/register/rg1-checks.tsv, appended after the last data row, preceded by
one comment line (the second row added 2026-11-09, review fold: B-m9: the
break condition "upstream adds a prelude `Result`" had no silence check):

<!-- google-doc-style-ignore -->

```text
# T2.1 ALIGNED since EH-C (<date>, W-346): the upstream-side break conditions as silence checks (D-RG-5: the README's examples change to Ok/Err; upstream adds a prelude Result)
T2.1	G	-E	\bOk\(|\bErr\(	docs/design proposals	0
T2.1	G	-E	choice Result\b|class Result\b	core	0
```

<!-- google-doc-style-resume -->

fork/register/rg1-quotes.tsv, one comment line appended: "# T2.1 ALIGNED
since EH-C (<date>, W-346): its quotes are the docs/design/README.md 3858,
3860, 3164, 3165, 3166, 2176, 2177, 3856, 2167, 3159 and p000157 691, 229
rows above". Both scripts, run from the worktree root at <tip> before and
after: "checked 289 quotes, 0 failed" both times; "checked 94 silence
checks, 0 failed" before and "checked 96 silence checks, 0 failed" after
(two more checks; the fold measured all four at ca1898506; amended
2026-11-09, review fold: A-m3 (c) / B-m9).

### D.7 fork/gap-analysis.md

Row "Error handling: dedicated control flow constructs" (:73) stays DONE; its
evidence cell gains, before the final sentence "The scalar-payload bound ...":
"EH-C (<date>, W-346): the alternatives are spelled `Success`/`Failure`,
upstream's README's (D-RG-5 resolved, register row T2.1 ALIGNED); 8/8 programs
PASS unchanged, container-measured 228/0/13 over 241 (R33 (b))."; the cell's own
mention of run_result_ok.carbon and run_result_err.carbon is rewritten to
run_result_success.carbon and run_result_failure.carbon (D-EHC-13; amended
2026-11-09, review fold: B-M1). Row 70's example "`case .Ok(v: i32)`" becomes "`case
.Success(v: i32)`" (R). The header's tally 37/17/2/0 is unchanged by EH-C; the
landing's A.8 sentence restates it with PR <N>'s figures (the PR number appears
there first; amended 2026-11-09, review fold: RR1-M1).

### D.8 fork/ORCHESTRATION.md

Before the landing (D): the Branches table gains, directly after the
`claude/carbon-fork-0-1-ov4` row (PR 68, :2508 at aee70185c, the table's
last landed-PR row, before `claude/carbon-fork-0-1-upstream-advance`) or,
once LAND-1's records for PR 69 add a `claude/carbon-fork-0-1-arb2` row
there, directly after that row (amended 2026-11-09, review fold: B-m10 /
B-m4; the row in OV-4's form, without a PR number, amended 2026-11-09,
review fold: RR1-M1): "| `claude/carbon-fork-0-1-ehc` | IMPLEMENTED AND
REVIEWED (base trunk 725570464) — EH-C: `Core.Result`'s alternatives renamed
to `Success`/`Failure` (W-346 DISCHARGED, R32; F-006a reversed, veto-able;
W-380 filed for PR 53's line, W-381 to W-385 unused); commits <C1>, <F1>,
<P>, <fixes>, <R> and this one; container-measured (R33 (b), EXPECTED, not
of record): gate 2047 of 2047, conformance 228/0/13 over 241, 51/56 bullets;
the PR opens with base trunk after the focused re-review is dry and lands by
LAND-1's D-LAND-6. |". After a dry round, that round's records commit
changes the row's leading phrase to "IMPLEMENTED AND REVIEWED; RE-REVIEW
ROUND <k> DRY (base trunk 725570464)" (§3 item 9). Next actions item 6's
sentence "After the held PRs land and before UA-3: W-346 (EH-C:
`Core.Result`'s `Success`/`Failure`, on trunk's base, beside W-341)."
becomes "W-346 (EH-C: `Core.Result`'s `Success`/`Failure`, on trunk's base)
is implemented and reviewed on claude/carbon-fork-0-1-ehc (<date>); its PR
opens after the focused re-review is dry and lands by LAND-1's procedure
before UA-3, then PR 53's W-380 rename commit before PR 53 lands." and
":2725 "UA-3 follows W-341 and W-346." becomes "UA-3 follows W-341 (landed)
and W-346 (implemented; its PR pending)." The header gains the clause "Last
updated: <date> (EH-C implemented and reviewed on claude/carbon-fork-0-1-ehc,
W-346 discharged at its records commit; <landed> PRs landed, 1 held; see the
Branches row; the earlier <prev> text follows)." before the current first
clause, `<landed>` being the header's count at the time of writing (17 at
aee70185c, 18 once PR 69's records land; B-m4). The dated paragraph D adds
(§3 item 8 names it; rev 2 gave it no text: the fixer's F-5) reads "<date>
(<hh:mm> UTC): EH-C is IMPLEMENTED AND REVIEWED on claude/carbon-fork-0-1-ehc
(base trunk 725570464; commits <plan revisions>, <M-0>, <C1>, <F1>, <P>,
<fixes>, <R> and this one): `Core.Result`'s alternatives are
`Success`/`Failure` (W-346 DISCHARGED under R32 (d); F-006a reversed,
veto-able; W-380 filed for PR 53's line); container-measured (R33 (b)): gate
2047 of 2047, conformance 228/0/13 over 241, 51/56 bullets; the focused
re-review follows, then the PR with base trunk, landed by LAND-1." The PR
number is written by the orchestrator's texts of §3 item 10 and by the
landing's Appendix F, whose texts replace these.

### D.9 fork/eh/plan.md

After the Status paragraph's first sentence block (":7-20"), a new
paragraph: "**EH-C (W-346, <date>): the third slice, `Core.Result`'s
alternatives renamed to `Success`/`Failure` under R32, has its own plan,
fork/eh/ehc-plan.md; every `Ok`/`Err` in this file is history.**"

### D.10 fork/README.md:50

"error handling (F-006, Ok/Err; renamed Success/Failure by EH-C, <date>)".

## Appendix E: the PR text

Title: `EH-C: Core.Result's alternatives renamed to Success/Failure (W-346)`.
Base: trunk. Body:

<!-- google-doc-style-ignore -->

```markdown
W-346 (R32 (d); RG-1, D-RG-5): `Core.Result(T, E)`'s alternatives were
spelled `Ok`/`Err` where upstream's docs/design/README.md spells a result
choice's `Success`/`Failure` (:2176-2177, :3165-3166 at ca1898506; the
error-handling section :3858-3860 names `Result` as the error
representation). This PR renames them at the root with every use, no alias:
the prelude (`Success(value: T)`, `Failure(error: E)`, the order and payload
names unchanged), the catching thunk's minted identifiers, the entry point's
stderr line (``returned `.Failure` of type ...``), `<carbon/expected.h>`'s
payload members and `success()` factory, 35 goldens (sources renamed,
CHECK lines refilled by autoupdate; a new `fail_old_names` split pins
``member name `Ok` not found in `Core.Result(i32, i32)` ``), 18 conformance
programs (every EXPECT unchanged; run_result_ok/err.carbon renamed
run_result_success/failure.carbon with the README's rows), the five pages that teach it (dated
amendments quoting upstream by sha) and the records. It reverses the user's
sub-decision F-006a (2026-07-19) under the owner directive of 2026-10-21;
the user may veto it (fork/eh/ehc-plan.md D-EHC-1).

Plan: fork/eh/ehc-plan.md (rev <n>, two adversarial reviews, <folds>).
Commits: <M-0> merge of trunk 725570464 (PR 69 and the arbiter scripts' records commit), <C1> rename, <F1> fill, <P>
prose, <fixes>, <R> records, <D> discharge. Container-measured (R33 (b)): gate 2047 of 2047 (after the fill;
2015 with 32 "Autoupdate would make changes" before it), conformance
228/0/13 over 241, 51/56 bullets, byte for byte trunk's; both sample
checkers and check_faq.py 0 errors; mutants: the order swapped turns 7
goldens and 4 programs red, the thunk's identifiers left as `Ok`/`Err` turn 3
goldens red. Records: W-346 DISCHARGED, W-380 filed (PR 53's
rust_interop.md:223 rename before it lands), decision-log entry EH-C, F-006a's
reversal note, register row T2.1 ALIGNED with two new silence checks, gap row
evidence, ORCHESTRATION. Not run: clang-tidy (no binary), the hosted gate
(Actions disabled, owed), Bazel.

Lands by LAND-1's D-LAND-6 (fork/land/land1-plan.md) when correct (R33).

<the harness's two attribution lines for pull-request descriptions>
```

<!-- google-doc-style-resume -->

## Appendix F: the land-time texts (LAND-1 Appendix A, with `<...>`)

The fields: `<N>` the PR number; `<head>` the branch's head; `<trunk
before>` trunk at the landing; `<merge sha>`, `<merged_at>`, `<api sha>`
from `pull_request_read`; `<g>` the gate (2047 of 2047 expected), `<p>/<f>/
<s>` over `<n>` (228/0/13 over 241 expected), `<b>` (51 expected), `<tally>`
(37/17/2/0); `<spec>` "fork/eh/ehc-plan.md §3 and Appendix F"; `<land-time
shas>` M and F-M when trunk moved, else "none"; `<landed>` the header's count
of landed PRs after this landing (19 when PR 69's records and this PR are the
only landings after aee70185c's 17, §6.2; added 2026-11-09, review fold:
RR1-m5, replacing rev 2's "18" in F.5).

### F.1 M, the merge of trunk into the branch (only if trunk moved again after M-0's 725570464)

<!-- google-doc-style-ignore -->

```text
EH-C land (M): merge trunk <trunk before> into claude/carbon-fork-0-1-ehc

Trunk <trunk before> holds <what landed since 725570464>. Resolved by
fork/eh/ehc-plan.md §6.2: the toolchain and prelude keep trunk's side plus
the rename; goldens take trunk's side and are refilled by F-M; records keep
both sides by LAND-1's region rules. No golden is edited by hand.

<trailers>
```

<!-- google-doc-style-resume -->

### F.2 F-M, the refill on the merged branch (only if autoupdate changes a file)

<!-- google-doc-style-ignore -->

```text
EH-C land (F-M): refill the goldens on the merged branch (autoupdate)

Autoupdate (carbonbuild autoupdate.sh, R16) on: <files>. CHECK lines only.
Gate after: <g> of <g>.

<trailers>
```

<!-- google-doc-style-resume -->

### F.3 The merge commit's message (LAND-1 A.1)

<!-- google-doc-style-ignore -->

```text
Land PR <N>: EH-C: Core.Result's alternatives renamed to Success/Failure (W-346)

Merges claude/carbon-fork-0-1-ehc at <head> (PR <N>, base trunk) into trunk
<trunk before> under R33, as fork/eh/ehc-plan.md §3 and Appendix F specify.

Conflicts and rules: <conflicts, or "none">.

Container-measured on the merge's tree (R33 (b)): build ok; gate <g0> of
<gn> before any refill (each golden that fails is refilled by this landing's
refill commit, fork/land/land1-plan.md Appendix A.2, which states the gate
after it); conformance <p>/<f>/<s> over <n>, bullets <b> of 56. prek clean on
the resolved files (SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,
forbid-llvm-googletest).

<trailers>
```

<!-- google-doc-style-resume -->

### F.4 The Branches row (A.3; replaces D.8's OPEN row)

<!-- google-doc-style-ignore -->

```text
| `claude/carbon-fork-0-1-ehc` | LANDED as PR <N> by merge <merge sha> (<date>, LAND-1, R33; GitHub merged_at <merged_at>, merge_commit_sha <api sha>) — EH-C: `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346, R32; F-006a reversed, veto-able); W-346 discharged, W-380 filed; land-time commits <land-time shas>; container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; moved to follow-ons: W-380 to Next actions item 14 (PR 53's rename commit); R21's hosted gate owed when Actions returns (R33 (b)). |
```

<!-- google-doc-style-resume -->

### F.5 The dated paragraph and the header (A.4)

<!-- google-doc-style-ignore -->

```text
<date> (<hh:mm> UTC): PR <N> (EH-C) LANDED on trunk by merge <merge sha>
under R33 (fork/eh/ehc-plan.md §3 and Appendix F), GitHub merged_at
<merged_at>; container-measured (R33 (b)): gate <g> of <g>, conformance
<p>/<f>/<s> over <n>, <b>/56 bullets, gap tally <tally>; id re-scans:
<rescan>; <landed> PRs landed, 1 held. Next: PR 53's W-380 rename commit
before it lands (item 14), then UA-3.
```

<!-- google-doc-style-resume -->

Header clause: "Last updated: <date> (PR <N> landed by LAND-1; <landed> PRs
landed, 1 held; see the paragraph dated <date> (<hh:mm> UTC) below; the earlier
<prev> text follows)." The F.3 paragraph of 2026-11-06 (05:44 UTC) gets, after
"Next: EH-C (W-346) on trunk's base, then UA-3.", the parenthetical "(EH-C
landed <date> as PR <N>; next UA-3.)". Next actions item 6: "W-346 (EH-C)
landed on trunk <date> as PR <N> by merge <merge sha> (LAND-1); PR 53's
rename commit is W-380 (item 14)."; ":2725" "UA-3 follows W-341 and W-346
(both landed)."

### F.6 The Landed paragraph in this plan (A.5)

<!-- google-doc-style-ignore -->

```text
EH-C landed on trunk (LAND-1, <date>): merged as PR <N> by <merge sha> (head
<head>, trunk before <trunk before>; GitHub merged_at <merged_at>) under R33,
fork/eh/ehc-plan.md §3 and Appendix F; land-time commits <land-time shas>;
container-measured (R33 (b)): gate <g> of <g>, conformance <p> PASS, <f> FAIL,
<s> SKIP over <n>, <b> of 56 bullets; id re-scans: <rescan>; moved to
follow-ons: W-380 to Next actions item 14.
```

<!-- google-doc-style-resume -->

It goes after this plan's Status paragraph.

### F.7 The decision-log sentence (A.6)

<!-- google-doc-style-ignore -->

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR <N> by <merge sha>
(GitHub merged_at <merged_at>); container-measured (R33 (b)): gate <g> of <g>,
conformance <p>/<f>/<s> over <n>; id re-scans: <rescan>; moved to
follow-ons: W-380 to Next actions item 14.
```

<!-- google-doc-style-resume -->

The last paragraph of the EH-C entry (D.2).

### F.8 The PR description's Landed line (A.7) and W-346's discharge evidence

<!-- google-doc-style-ignore -->

```text
**Landed** on trunk <date> by merge <merge sha> (LAND-1, R33; GitHub
merged_at <merged_at>): container-measured gate <g> of <g>, conformance
<p>/<f>/<s> over <n>, <b>/56 bullets; moved to follow-ons: W-380 to Next
actions item 14. Record: fork/ORCHESTRATION.md's paragraph dated <date>
(<hh:mm> UTC).
```

<!-- google-doc-style-resume -->

W-346's `notes` gain, appended: " LAND-1 (<date>, PR <N>'s landing): merged
by <merge sha> (GitHub merged_at <merged_at>); container-measured (R33 (b)):
gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; the
reconciliation greps of fork/eh/ehc-plan.md §8.7 re-run on the merge's tree
give the answers recorded at <R>: grep 1's 17 dated-history lines, greps 2 and
3 empty, grep 4 zero over the header's consumers and one tree-wide, this
plan's own D-EHC-5 sentence." (amended 2026-11-09, review fold: A-M1; the
tree-wide hit added 2026-11-09, review fold: B2)

### F.9 The gap header's first sentence (A.8) and ORCHESTRATION's Scoreboard paragraph (A.9)

As LAND-1's templates, with `<t1> DONE / <t2> PARTIAL / <t3> MISSING / <t4>
DESIGN-ONLY` = 37 / 17 / 2 / 0 (unchanged) and PR <N>'s figures; row 73
takes no "not of record" mark (D.7's text carries none).
