<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# EH-C plan: `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346)

**Status:** rev 1, written 2026-11-09 for two adversarial plan reviews.
Branch `claude/carbon-fork-0-1-ehc` (worktree /home/user/carbon-ehc), cut from
trunk aee70185c (2026-11-09, "Weekly upstream check 2026-11-09: review fold";
pushed; no commits of its own before this plan). Trunk's toolchain, prelude and
testdata equal the merge a725dddca's: `git diff --stat a725dddca aee70185c --
toolchain core` is empty, so the container arbiter's install
/home/user/arb/install/cb726a230/bin/carbon (built from cb726a230, whose
toolchain sources equal trunk's; `carbon version` prints
0.0.0-0.dev+unknown, the Bazel-equivalent build being unstamped) is the
baseline for every probe below. Baseline, container-measured on 2026-11-09:
**gate 2047 passed, 0 failed** (/home/user/arb/logs/gate-cb726a230-
20261109T163748Z.log, with the arbiter's check.cpp source patch applied, see
§0.1) and **conformance PASS 228 / FAIL 0 / SKIP 13 over 241, 51 of 56
bullets** (/home/user/arb/logs/conformance-cb726a230.log). This is the
error-handling workstream's third slice; fork/eh/plan.md (EH-A and EH-B,
2026-09-27) is its parent, as fork/overload/ov4-plan.md sits beside
fork/overload/plan.md. **The spec is W-346** (fork/inventory/work-items.json):
rename `Core.Result(T, E)`'s alternatives `Ok`/`Err` to upstream's
`Success`/`Failure`, with every use, after the held PRs land and before UA-3.
Size S. This plan was written once before (2026-11-06, cc2d3a623 on the
previous container, lost before it was pushed); §0.8 says what this rev keeps
of it and where it differs.

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
notes. Appendix A the goldens' source edits; B the programs and their EXPECTs;
C the docs amendments verbatim; D the records texts verbatim; E the PR text;
F the land-time texts with `<...>` placeholders.

## §0 Audit

Every number below was measured on 2026-11-09 in the container: the baseline
install above, the upstream nightly
/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon
(a differential oracle only, R30; it has no `Core.Result`), and a prototype of
the rename built by the arbiter under the label `ehc-planner` from the detached
worktree /home/user/carbon-ehc-planner at aee70185c (removed when the plan was
committed, with the label's directories). The arbiter compiles a patched copy
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
| Golden sources | 35 | 342 | 22 check, 11 lower, 2 parse (Appendix A); 328 whole-word lines plus 14 lowercase skeleton lines in the two export goldens |
| Golden CHECK lines | 32 | 2858 rewritten by the fill | the files of §4; three of the 35 have no CHECK line that moves |
| Program sources | 18 | 159 | 11 .carbon and 5 .diff.cpp under error_handling/, project/evaluator_tutorial_errors.carbon, control_flow/choice_payload_roundtrip_diff.carbon (Appendix B) |
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
| Files changed by the rename | 72: 35 goldens (342 source lines), 18 programs (159 lines), 13 toolchain, prelude and header files (112 lines), 5 docs (38 lines), check_faq.py (3 lines); prek then reflowed 7 long lines in three docs, wrapped the C++ at clang-format's width and asked for check_faq.py:229 to be split (a second pass is clean) |
| Whole-tree grep after the rename, outside CHECK lines and fork/ | exactly common/raw_hashtable.h:1314 |
| `runner.py --self-test` (both sample checkers) | "check_samples: 14 samples, 0 errors", "check_samples: 19 program blocks, 70 fixtures, 2 W2 hits (1 allowlisted, 1 qualified); 0 errors", "self-test: 241 programs parsed, 56 bullets in table, OK" |
| The same with the tutorial reverted and the programs renamed (the A-M1 state) | "check_samples: 14 samples, 1 errors" (the self-test is red), restored to 0 by the tutorial's eight lines |
| Gate before any refill | 2015 passed, 32 FAILED, every failure "Autoupdate would make changes" (32 of 32), no crash, no `fail_`-prefix problem: the 32 files of §4 |
| Autoupdate | pass 1 rewrites the 32; pass 2 changes nothing (the gate after it is the proof, R28 (d)) |
| Gate after the fill | **2047 passed, 0 failed** (the new split is a split, not a file, so the count stays 2047) |
| The fill's non-CHECK lines | exactly the rename's 342 lines twice plus the 20 lines of the new split; the 32 refilled files have 2858 CHECK lines rewritten (5716 `+`/`-` lines), classified in §4 |
| Conformance | **PASS 228 / FAIL 0 / SKIP 13 over 241, 51 of 56 bullets**, byte for byte trunk's (/home/user/arb/conformance/ehc-planner/scoreboard.json before the mutants) |
| check_faq.py with the prototype | "13 reproducers run, 0 errors" (the renamed line :229 matches the new stderr) |
| fork/designdocs/check_samples.py --toolchain (the prototype) | "19 program blocks, 70 fixtures (compiled), 2 W2 hits (1 allowlisted, 1 qualified); 0 errors" |
| p2, p3, p4 with the new spelling on the prototype | `1`/`-7`; `1` and stderr ``carbon: `Main.Run` returned `.Failure` of type `i32`; exiting with code 1`` with exit 1; `11`/`-3`: the baseline's outputs with the one printed name changed |
| The old spelling on the prototype (p6, p7, p2 unchanged) | ``error: member name `Ok` not found in `Core.Result(i32, i32)` `` for `Core.Result(i32, i32).Ok(1)`; ``member name `Err` not found in `Core.Result(i32, i32)` `` for `.Err(7)`, for `case .Err(e: i32)` and for `if (let .Err(e: i32) = ...)`; in the golden the kind is `[MemberNameNotFoundInSpecificScope]`; no note |
| prek (R25) on the 72 files | pass 1: rumdl reflowed docs/design/README.md:4047-4048, error_handling.md :112, :736, :864, :949 and tutorial.md:409 (MD013; R31's heading, bullet, numbered and row counts unchanged for all three files), ruff E501 on check_faq.py:229 (fixed by splitting the literal), clang-format wrapped thunk.cpp, lower/handle.cpp, function_context.h and expected.h; pass 2 clean, no file modified |
| M1, the order swapped (`Failure` first, `Success` second; the prelude only, re-installed) | gate 2040 passed, 7 FAILED: check interop/cpp/exceptions/catching_thunk.carbon, main_run/return_result.carbon, operators/question_result.carbon; lower interop/cpp/exceptions/catching_thunk.carbon, interop/cpp/function/export/result_expected.carbon, main_run/return_result.carbon, operators/question_result.carbon (every golden whose dumps print a `Core.Result` discriminant or alternative index); conformance PASS 224 / FAIL 4 / SKIP 13: run_result_ok.carbon exit 1 for 3 (the success value read as a failure), run_result_err.carbon exit 0 for 1 (the failure's discriminant is now 0), cpp_expected_export.carbon stdout mismatch (`<carbon/expected.h>` reads `disc_ == 0` as a value), cpp_exception_rethrow_export.carbon exit -11 (the header rethrows a null primary); the differential and user-choice programs stay green because they construct by name |
| M2, the thunk's two minted identifiers left as `"Ok"`/`"Err"` (toolchain rebuilt) | gate over `--filter interop/cpp`: 228 passed, 4 FAILED: check interop/cpp/exceptions/catching_thunk.carbon and fail_catching.carbon, lower interop/cpp/exceptions/catching_thunk.carbon and interop/cpp/function/export/result_expected.carbon, each with ``member name `Ok` not found in `Core.Result(i32, Cpp.Exception)` `` and the `Err` twin at every `?`-selected C++ call (28 occurrences); the identifiers are the root (D-EHC-4) |
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
error_handling.md, optional.md or the guides. PR 53 carries one line with the
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
-   proposals/p000157-design-direction-for-sum-types.md:228-229 "so their
    detailed design will be addressed in future proposals, and the details
    discussed here should be considered provisional."; :690-693 `choice
    Result(Type:$$ T, Type:$$ Error) {` / `Success(T: value),` / `Failure(Error:
    error),` / `Cancelled`. It is the only proposal that spells any of the four
    names: `git grep -cE 'Success\(|Failure\(|\bOk\b|\bErr\b' upstream/trunk --
    proposals` lists p000157 alone (27 lines, all `Success`/`Failure`, at :120,
    :124, :141, :146, :266-281, :345-374, :403-416, :428, :691-692, :868-879,
    :981-1005); provisional by its :228-229, corroborating only (D-RG-5).
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
(no `Result`, no `Try`, no header upstream; `git grep -c expected.h
upstream/trunk -- toolchain` is 0). DR-0's block is untouched (it names no
W-346 entry). W-355's weekly check reads T2.1 afterwards as an ALIGNED row: its
quotes are rg1-quotes.tsv's README.md 3858, 3860, 3164-3166, 2176-2177, 3856,
2167, 3159 and p000157 691, 229 rows (already present, re-anchored on
2026-11-09), and its new silence check (Appendix D.6) fires if upstream ever
spells `Ok(` or `Err(` in docs/design or proposals, the upstream-side break
condition.

### §0.7 The id re-scan

After `git fetch origin`: 82 refs (`git for-each-ref refs/remotes/origin
refs/heads`), `git branch -a` lists 83 lines, `git worktree list` 7 worktrees
(carbon-lang, carbon-arb2, carbon-ehc, carbon-ehc-planner, carbon-safe,
carbon-trunk, carbon-weekly). `git grep -oE 'W-3[7-9][0-9]|W-4[0-9][0-9]'
<every ref> -- fork` and `grep -r` over each worktree's fork/ directory find:
W-370 to W-377 filed on trunk (W-377 the highest, 309 items); W-378 on trunk
and on claude/carbon-fork-0-1-arb2 (6de18c1f7, worktree /home/user/carbon-arb2)
only as the 2026-11-09 weekly entry's text (decision-log.md:19596-19598,
ORCHESTRATION.md:2153), not as a ledger item at scan time, which changes
nothing because the task names it TAKEN by ARB-2's ledger item and EH-C
reserves from W-380 regardless; W-379, W-389, W-396 and W-397 as range bounds
or reserved text (fo1-plan.md:937, land1-plan.md:668-669, decision-log
:19595); W-380, W-385 and W-388 only in the weekly entry's sentence "no W-378
and no W-380 to W-388 appears anywhere" (:19596); W-398 and W-399 as range
bounds in six plans; no W-381 to W-384, W-386, W-387 or W-390 to W-395
anywhere; no W-4xx anywhere; the SAFE worktree (14c1ac8ac) names only W-397 to
W-399. Decision D-EHC-11: W-380 to W-385 reserved, W-380 filed, re-scanned at
D (§8.9).

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
for PR 53's rust_interop.md row; W-378 and W-379 are taken, so EH-C reserves
W-380 to W-385 and files W-380 (D-EHC-11); (b) the partial-thunk mutant turns
4 goldens red, not 3 (lower result_expected.carbon's `exception_error` split
goes with the three); (c) 342 golden source lines, not 328: the lost rev
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
item" is not visible at the branch head scanned (§0.7) but is honored.

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
-   **D-EHC-2 — no alias, no deprecation period, no compatibility spelling.**
    A second spelling IS the drift (R32 (d)); keeping `Ok`/`Err` reachable
    anywhere in the prelude or the toolchain would leave the register entry a
    DRIFT. Measured: an alias of an alternative cannot be written inside a
    choice at all (`alias Ok = Success;` inside `choice R` is "error: expected
    choice alternative name", §0.2 p8), and a file-scope alias of a
    specific's alternative (`alias ResultOk = Core.Result(i32, i32).Ok;`)
    compiles (p9), so a user program CAN spell its own alias, and the prelude
    ships none. The guard against a kept alias is textual, not a toolchain
    check: the whole-tree grep of §8.7 (0 hits outside closed plans and dated
    history) at D and at land time, recorded in the decision-log entry as
    EH-B's §8.4 greps were, and the new register silence check of D-EHC-7
    (upstream adopting `Ok`/`Err` fires it). No register check greps the
    fork's tree (check_greps.sh greps upstream's tip), which is why the
    discharge grep is the guard. _Break condition:_ the user vetoes (D-EHC-1's
    veto route; then the old spelling returns wholesale, never as an alias).
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
    and lower/constant.cpp:450. The IR names are user-visible under
    `--dump-llvm-ir` and in every lower golden, so they are part of the
    spelling the fork shows. NOT renamed: thunk.cpp's `err_param_type_id`,
    `err_pointee_type_id` and `err_storage_id`, which name the C++ thunk's
    error out-pointer parameter `err` (an error object, not an alternative;
    the thunk's C++ parameter is `void** err`), the differential oracles'
    `bool ok` struct flag (a C++ oracle's own field), and
    common/raw_hashtable.h:1314's English "Ok,". The partial-rename mutant
    (§0.3 M2: the two minted identifiers left as `"Ok"`/`"Err"`) turns the
    catching-thunk goldens red, which proves the identifiers are the root the
    thunk depends on. _Break condition:_ a review finds another identifier
    that denotes an alternative (then it joins C1, no new decision).
-   **D-EHC-5 — `<carbon/expected.h>` renames what mirrors the alternatives
    and keeps the `std::expected` vocabulary.** The payload union's members
    `ok`/`err` become `success`/`failure` (both `Payload` specializations, their
    constructors and every `payload_.ok`/`payload_.err` use), and the
    `expected<void, E>::ok()` factory becomes `success()`; `has_value()`,
    `operator bool`, `value()`, `operator*`, `error()`, `value_or()`,
    `operator==`, `unexpected<E>`, `has_exception()` and the `std::expected`
    conversions keep their names (they are `std::expected`'s vocabulary, D8's
    API, not a spelling of the alternatives). The header's comments that say
    "0 for `Ok` and 1 for `Err`" and "`Ok(value)`", "`Err(error)`" follow the
    choice. The goldens' inline skeletons (check and lower
    interop/cpp/function/export/result_expected.carbon) rename their `T ok; E
    err;` members and the `ok(value)` initializer and the `r.ok : r.err` read
    the same way so that the fork shows one spelling; the mapping is by the
    template's NAME (`Carbon::expected`), so the member names are not
    load-bearing for the toolchain (the check golden's CHECK lines do not
    change, §4). Measured: cpp_expected_export.carbon and
    cpp_exception_rethrow_export.carbon PASS with the renamed header (its C++
    uses only `has_value()`, `value()`, `error()` and `rethrow()`), and no file
    in the tree calls `.ok()` (`git grep -nE '\.ok\(\)'` over the tree is 0
    before and after). _Break condition:_ an external C++ consumer of the
    header exists (none: the header is installed by the fork only and no
    program outside fork/conformance includes it); the user vetoes.
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
-   **D-EHC-7 — the records.** W-346 is DISCHARGED (kind `implemented`, title
    prefixed "EH-C (DISCHARGED at EH-C, <date>): ...", the ledger's convention,
    W-341's form) with the evidence of Appendix D.1; the decision-log entry
    "EH-C: `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346)
    (<date>)" is placed directly before the EH-B entry (the log groups by
    workstream, newest first: EH-B precedes EH-A today), carrying D-EHC-1 to
    D-EHC-12, the V-3 check of §0.6 with the quotes, the §0 measurements and
    the reconciliation greps; the F-006 entry's sub-decision F-006a gains the
    dated reversal note of Appendix D.3 (the user's 2026-07-19 decision
    reversed under the owner directive of 2026-10-21, veto-able), a note, not a
    renumbering, so no F id is minted; the V-3a register: rg1-plan.md's T2.1
    row turns ALIGNED (the quote already in the row), T11.1's and H3.2's notes
    are updated, one silence check row is appended to rg1-checks.tsv (the
    upstream-side break condition "the README's examples change to `Ok`/`Err`"
    becomes a grep that fires) and one comment line to rg1-quotes.tsv naming
    the rows T2.1 keeps (Appendix D.6; W-355's weekly check then reads T2.1 as
    an ALIGNED row with a quote check and a silence check, as every other
    ALIGNED row); the RG-1 entry, the EH-A entry's register paragraph, the
    UA-1 entry's RG-1 paragraph, V-3's paragraph and the 2026-11-09 weekly
    entry gain dated "resolved by EH-C" notes where they name W-346 (Appendix
    D.4, D.5); fork/gap-analysis.md's row "Error handling: dedicated control
    flow constructs" stays DONE with its evidence cell refreshed and row 70's
    example `case .Ok(v: i32)` becomes `case .Success(v: i32)` (no row flips,
    the tally stays 37/17/2/0); fork/ORCHESTRATION.md's header, a dated
    paragraph, a Branches row, Next actions item 6's W-346 words and the F.3
    paragraph's "Next:"; fork/eh/plan.md's Status paragraph gains the pointer
    to this plan; fork/README.md:50's checklist line gains the rename in
    parentheses. Closed plans (fork/w5-choice, b1, b2, w066, w072, w078a,
    sumtype-interop, match-replatform, optional, w008, w5-s3, designdocs,
    evaluator, design-sprint, register's prose, and this plan's own history)
    keep their text. _Break condition:_ a records check of D-LAND-6 step 9
    (rowcheck.py, R31 counts, the model-identifier grep) fails (fix at the
    text, never by dropping a record).
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
    whole-tree grep of §8.7 then has a clean answer. Not renamed: the oracles'
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
    toolchain; D-LAND-6 step 8 runs it at landing). Measured (§0.3): with the
    programs renamed and the tutorial not, the evaluator checker reports
    "check_samples: 14 samples, 1 errors" and the self-test is red; with both
    renamed, "0 errors". So C1 = the prelude, the toolchain, the header, the
    goldens' sources, the programs' sources, the tutorial's code block, the
    FAQ's quoted line and check_faq.py's reproducer, and every other docs
    code block or code span that spells an alternative (they are claims the
    toolchain now contradicts); P = Appendix C's prose amendments only. Every
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
    stderr (run_result_err's message lands in logs/), and the differential
    pairs compare stdout bytes that do not contain names. Each EXPECT is
    re-derived by hand in Appendix B from the program's arithmetic and the
    design (R16 (d)); re-measured: 228/0/13 over 241 on the prototype, byte
    for byte trunk's. The new `fail_` split (D-EHC-3) is a golden, not a
    program, because the old spelling's rejection is a compile-time property
    with no runtime oracle. _Break condition:_ a program prints a name through
    a match (none does); then its EXPECT changes and the reason is the name.
-   **D-EHC-11 — ids: W-380 to W-385 reserved; W-380 filed; no F id.** §0.7's
    re-scan at every origin ref, local branch and worktree with the widened
    command finds W-377 the highest filed id; W-378 and W-379 are named by the
    task as taken (ARB-2's ledger item; reserved text), and W-380, W-385 and
    W-388 appear on trunk only inside the 2026-11-09 weekly entry's sentence
    "no W-378 and no W-380 to W-388 appears anywhere", W-389 and W-396 to
    W-399 only as range bounds. EH-C reserves W-380 to W-385 and files W-380:
    "PR 53 (SAFE-1): docs/design/safety/rust_interop.md:223 names `Ok`/`Err`
    as `Core.Result`'s variants; a rename commit on PR 53's branch before it
    lands (D-RG-8's break condition, fired by EH-C landing first)" (Appendix
    D.1), owner PR 53's landing (ORCHESTRATION Next actions item 14, SAFE-4).
    W-381 to W-385 stay unused unless the reviews need one. No F id: R32 makes
    upstream's spelling the design's, and F-006a is reversed by a dated note.
    _Break condition:_ the id re-scan at D (§8.9) finds W-380 used (then the
    next free id, re-scanned, and every cross-reference in this plan's D texts
    renumbered in the same commit).
-   **D-EHC-12 — one PR with base trunk, two implementation reviews, a fix
    budget of two, and LAND-1's D-LAND-6 landing.** The PR "EH-C:
    `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346)"
    (Appendix E) opens with base trunk after its two implementation reviews
    are dry (R29 (c): two until the container verification is green, then one;
    EH-C keeps two because the rename spans 72 files) and lands by LAND-1's
    procedure (fork/land/land1-plan.md D-LAND-6, one landing reviewer, the
    records commit with Appendix A's texts, specified in Appendix F with
    `<...>` placeholders). If trunk moved after the branch was cut, a merge of
    trunk into the branch comes first, as FO-1's stage 17 did (never a rebase,
    AGENTS.md), with the refill, the gate and conformance re-quoted. The one
    held PR, PR 53 (claude/carbon-fork-0-1-safe at 2407efa74), conflicts with
    trunk aee70185c only in the four records files (§0.4) and carries one
    line with the old spelling (rust_interop.md:223): the rule is D-RG-8's
    break condition, W-380 (D-EHC-11), and the records conflicts are LAND-1's
    region rules at PR 53's own landing; EH-C amends no held PR (R32 (e) does
    not apply: PR 53's line is a use of trunk's spelling, not a drift of its
    own). _Break condition:_ trunk's toolchain or prelude moves before EH-C
    lands (then the merge of trunk is followed by a full re-measure, §8.8, and
    any new use site found by the §8.7 grep joins a fix commit).

## §2 Spec, file by file

Line numbers are trunk aee70185c's. Every C++ hunk is given in the form
clang-format 21.1.8 leaves it (R18; the prototype's prek fixpoint), so the
implementer's diff equals the prototype's; a hunk that differs only by
wrapping is not a finding. The rename is whole-word (`\bOk\b`, `\bErr\b`) on
every non-CHECK line of the files named, plus the lowercase names D-EHC-4 and
D-EHC-5 list; nothing else is edited in C1.

### §2.1 core/prelude/types/result.carbon (C1)

The file's line count and the positions of :28 (`choice Result`) and :51
(`fn FromBreak`) MUST NOT move: goldens quote `result.carbon:28` (check
operators/question_result.carbon's `fail_class_payload` note) and
`result.carbon:51` (two conversion notes), the lower goldens embed the file's
function lines in `DISubprogram` entries (six lower goldens name the file:
§4's four plus interop/cpp/template_symbolic_arg.carbon and
variadics/tuple_segment_destroy.carbon), and twelve more check goldens name the
file in their import lists. The prototype renamed in place and no golden
outside §4's 35 moved; this spec keeps that property. So lines 20-27 (the
eight comment lines) become the eight lines below, :29-30 become
`Success(value: T),` and `Failure(error: E)`, :33-34's comment reads "`expr?`
continues with the `Success` payload and propagates a `Failure` payload" (a,
not an), :44-45 become `case .Success(v: T) => ...` and `case .Failure(e: E)
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

The trailing block, after the impl's closing brace (:52), preceded by one
blank line:

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

thunk.cpp:1380 "0 = Success, 1 = Failure"; :1461-1462 "then branch: the
Success block is the taken edge, the Failure block the fall-through."; :1502-
1541 (the measured form):

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
22 files), A.2 (lower, 11), A.4 (parse, 2); the new split `fail_old_names` of
check/testdata/operators/question_result.carbon is A.3, inserted after the
`fail_class_payload` split's last source line (:149 `fn Use(unused r:
Core.Result(SomeClass, i32)) {}`) and before the file's trailing
`// CHECK:STDOUT:` block, CHECK-free in C1. No CHECK line is edited by hand
(R16 (a)); F1 is `autoupdate.sh` to its fixpoint and nothing else.

### §2.7 Programs (C1)

The 18 files and every line are Appendix B, with each EXPECT re-derived. The
`.diff.cpp` oracles rename their `static auto Ok(...)` / `Err(...)` helpers and
their comments; their `bool ok` fields stay. `runner.py --self-test` before the
commit (R7): "241 programs parsed, 56 bullets in table, OK".

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
(W-346 discharged, W-380 filed); D.2 the decision-log entry; D.3 the F-006a
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

1.  **Plan**: fork/eh/ehc-plan.md, this rev 1; later revisions are commits on
    the same file, each a fold record. Message: "EH-C plan (rev 1):
    Core.Result alternatives renamed to Success/Failure (W-346)".
2.  **C1, the rename with every checker-visible line**: §2.1 to §2.5, the 35
    goldens' sources with the new split (Appendix A, no CHECK line touched),
    the 18 programs (Appendix B), the docs' code blocks and code spans of
    Appendix C (the tutorial's block, the FAQ's ```text line,
    error_handling.md's blocks and code-span items, optional.md:434, README's
    code spans), and check_faq.py (§2.9); upstream re-fetched and the tip
    named in the message body. Gate on C1 alone: 2015 passed and exactly the
    32 goldens of §4 failing with "Autoupdate would make changes", no crash,
    no `fail_`-prefix problem (measured shape, §0.3); `runner.py --self-test`
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
7.  **R, the records that claim no discharge**: the decision-log entry EH-C
    (D.2, its discharge sentence reading "discharged at D"), the F-006a
    reversal note (D.3), the RG-1 and other dated notes (D.4, D.5), the
    register rows and files (D.6, checked at the re-fetched tip with
    check_greps.sh and check_quotes.sh, every count and quote re-read), gap
    row 70's example (D.7 second item), fork/eh/plan.md's pointer (D.9),
    fork/README.md's note (D.10). Message: "EH-C records: decision-log entry
    EH-C, F-006a's reversal note, register row T2.1 ALIGNED, dated notes".
8.  **D, the discharge**: the ledger (W-346 DISCHARGED, W-380 filed; D.1),
    gap row 73's evidence (D.7), ORCHESTRATION's header, dated paragraph,
    Branches row and Next actions item 6 and the F.3 paragraph (D.8), every
    `<...>` filled from the commits and runs it names, after the reviews and
    their fixes; `json.load` of the ledger, `runner.py --self-test`, the
    model-identifier grep of the branch's diff, the id re-scan (§8.9), the
    whole-tree grep (§8.7). Message: "EH-C discharge: W-346 DISCHARGED;
    W-380 filed; gap row evidence and ORCHESTRATION".
9.  **The focused re-review**, OV-4's: one fresh agent per round over the fix
    commits, R and D; dry when no BLOCKER, no MAJOR and only records-only
    MINORs, folded by one records commit; at most three rounds.

**The PR** (Appendix E) opens with base trunk after a dry round, held until
the orchestrator lands it (R33). **Land-time steps** (D-LAND-6, one landing
reviewer, Appendix F's texts): (M) if trunk moved since aee70185c, `git merge
--no-ff` of trunk into the branch, conflicts resolved by §6.2's rules, never a
rebase, as FO-1's stage 17 did; (F-M) the refill on the merged branch, if
autoupdate changes anything, CHECK lines only; (L) the arbiter re-run on the
branch's head (build, install, gate 2047 of 2047, conformance 228/0/13 over
241, the three checkers, prek) quoted into Appendix F's records; the landing
reviewer's report; the merge into trunk by the orchestrator, the two pushes,
`merged: true`, then the records commit with F.3 to F.9 filled.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

Hand-traced predictions, then the prototype's measured fill (§0.3; the
numbers are the fill's rewritten CHECK lines per file: "name" lines spell
`Success` or `Failure`, "stderr" lines are `CHECK:STDERR` diagnostics, "loc"
lines change only a `locLL_CC` or `[[@LINE+N]]:CC` column). Prediction, then
measured, for every refilled file:

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
| check/choice/payload_construct.carbon | `%Ok`/`%Err` names, `IntResult.Err` ref, columns on :28 | 14 / 0 / 14 of 56 |
| check/interop/cpp/exceptions/catching_thunk.carbon | every `?`-selected call's two constructor accesses by name, the convergence's columns on seven `return` lines | 209 / 0 / 458 of 679 |
| check/interop/cpp/exceptions/fail_catching.carbon | seven diagnostics' quoted lines, carets and columns (`:45` to `:50`) | 12 / 31 / 9 of 31 |
| check/interop/cpp/exceptions/fail_catching_none_mode.carbon | one diagnostic's line and caret | 2 / 6 / 2 of 6 |
| check/interop/cpp/stdlib/optional.carbon | one `case .Ok` quoted in a diagnostic | 2 / 3 / 0 of 3 |
| check/main_run/return_result.carbon | the six `return` lines' constructor names and columns in four positive splits | 34 / 0 / 16 of 73 |
| check/match/choice_payload_guard.carbon | the user choice's names, columns on three `case` lines | 12 / 0 / 125 of 143 |
| check/match/choice_payload_pattern.carbon | the same, two `case` lines | 12 / 0 / 65 of 83 |
| check/match/exhaustive_choice.carbon | two user choices, five `case` lines | 24 / 0 / 190 of 226 |
| check/match/fail_case_never_matches_alternative.carbon | four diagnostics quoting `.Ok(42)` arms | 4 / 4 / 0 of 4 |
| check/match/fail_choice_alternative_pattern.carbon | seven diagnostics (`.Ok`, `.Err()`, `.Ok(.Err)`, `IntResult.Err`) | 7 / 12 / 1 of 12 |
| check/match/payload_subpattern.carbon | the names and three `case` lines' columns | 2 / 0 / 134 of 136 |
| check/match/usefulness_no_false_positive.carbon | six diagnostics quoting arms | 4 / 6 / 0 of 6 |
| check/operators/fail_question.carbon | diagnostics quoting `MyResult(...).Ok(...)` lines | 4 / 6 / 1 of 6 |
| check/operators/fail_question_generic.carbon | the `var unused mr: ... .Err(0)` diagnostic | 3 / 4 / 0 of 4 |
| check/operators/question.carbon | five user choices' names across the splits, every `return ... .Ok(...)` column | 107 / 0 / 178 of 331 |
| check/operators/question_final.carbon | four user choices' names (its dumps print names only) | 38 / 0 / 0 of 38 |
| check/operators/question_optional.carbon | three diagnostics quoting `.Ok(o?)` | 4 / 7 / 1 of 7 |
| check/operators/question_result.carbon | `Core.Result`'s `%Success`/`%Failure` names in four positive splits, their columns, plus the new split's two diagnostics (quoted in §4's note below) | 63 / 8 / 45 of 183 |
| lower/interop/cpp/exceptions/catching_thunk.carbon | `@Result.Success...`/`@Result.Failure...` callees, the `?` columns in `!dbg` lines | 44 / 0 / 43 of 125 |
| lower/interop/cpp/function/export/result_expected.carbon | the constructor callees (`@Result.Success.<hash>`) | 12 / 0 / 0 of 17 |
| lower/main_run/return_result.carbon | `@main.result.failure.message` as `[75 x i8]` with the new text and `i64 74`, `%run.result.is_success`, `run.result.success:` and `run.result.failure:` labels, both splits | 25 / 0 / 5 of 63 |
| lower/match/choice_payload.carbon | `@IntResult.Success` callee, `case` columns | 6 / 0 / 12 of 21 |
| lower/match/payload_subpattern.carbon | the same | 8 / 0 / 25 of 37 |
| lower/operators/question.carbon | `@MyResult.Success...` callees, `return` columns | 38 / 0 / 46 of 117 |
| lower/operators/question_generic.carbon | the same | 20 / 0 / 32 of 60 |
| lower/operators/question_generic_crossfile.carbon | the same, and three `CHECK:STDERR` lines (the file's expected unused-binding warnings quote a `.Err` line) | 65 / 3 / 34 of 157 |
| lower/operators/question_generic_final.carbon | the same | 20 / 0 / 20 of 55 |
| lower/operators/question_generic_mixed.carbon | the same, three warnings | 26 / 3 / 46 of 83 |
| lower/operators/question_result.carbon | `@Result.Success.<hash>`/`@Result.Failure.<hash>` callees | 39 / 0 / 5 of 84 |
| parse/match/alternative_pattern.carbon | `IdentifierNameNotBeforeSignature 'Success'` and `'Failure'` | 3 / 0 / 0 of 3 |
| parse/match/fail_alternative_pattern_unclosed.carbon | the unclosed `case .Ok(value: i32 =>` diagnostic's line, caret and columns | 5 / 12 / 4 of 13 |

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
identifiers. The README table is unchanged (241 programs, 56 bullets).

## §6 Churn and collisions

### §6.1 Churn

Seventy-two files: 35 goldens (342 source lines; 32 of them refilled, 2858
CHECK lines) and one new split (20 lines), 18 programs (159 lines), 13
toolchain, prelude and header files (112 lines plus clang-format's wraps), 5
docs (38 lines plus Appendix C's amendments) and check_faq.py (3 lines); the
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
LAND-1's region rules at PR 53's landing; rust_interop.md:223 by W-380's
rename commit on PR 53's branch before it lands. ARB-2's branch
(claude/carbon-fork-0-1-arb2, 6de18c1f7 at scan time; the check.cpp fix) touches
toolchain/check/check.cpp and the arbiter's files, none of EH-C's; if it lands
on trunk first, M (the merge of trunk) takes it clean and the gate's
`src-patches.applied` line then prints `landed`. If trunk moves in any other
file EH-C touches, the rule is: the toolchain and prelude keep trunk's side
plus the rename (a conflict in a renamed line is re-renamed by hand and
re-measured); goldens take trunk's side and are refilled (F-M), never merged
by hand (R16); records keep both sides by LAND-1's region rules.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1 — a use site the inventory missed.** Falsifier: §8.7's whole-tree
    grep at D or L finds `Ok`/`Err` outside closed plans, dated history and
    common/raw_hashtable.h. Response: a fix commit (budget) renames it at the
    root; never an allowlist.
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
    a C++ file in the tree names `.ok()`, `.ok` or `.err` of an `expected`.
    Response: measured 0 (D-EHC-5); an external consumer would be a veto
    route, not a code change.
-   **R-6 — rumdl's reflow manufactures a heading or list item (R31).**
    Falsifier: r31.py's counts differ before and after prek on any markdown
    file beyond the headings, items and rows the commit adds. Response:
    rephrase, never revert the reflow. Measured: the prototype's three
    reflowed pages keep their counts.
-   **R-7 — trunk moves before the landing.** Falsifier: `git ls-remote
    origin trunk` differs from aee70185c at land time. Response: M, F-M and a
    full re-measure (§8.8); a new use site joins a fix commit.
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
passes), the mutants M1 and M2, the whole-tree grep, the id re-scan, R31's
counts on the reflowed pages; the worktree and the label's directories
(/home/user/arb/build/ehc-planner, install/ehc-planner,
conformance/ehc-planner, cache-ehc-planner) removed afterwards.

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

`gate.sh --threads 4`: C1 alone red on exactly the 32 (and nothing else);
after F1 and after every fix commit's fill, `GATE <label>: 2047 passed, 0
failed`.

### §8.4 Conformance

`CACHE_HOME=/home/user/arb/cache-<label> conformance.sh --background`, waited
with `until [ -f /home/user/arb/conformance/<label>/.done ]` loops; expected
`PASS 228 / FAIL 0 / SKIP 13 over 241 programs; bullets 51 PASS`; any other
figure is a §5 miss. The runner's `--self-test` (both sample checkers) runs
first; check_faq.py `--which fork --toolchain <install>/bin/carbon` and
`--which nightly` separately (0 errors each); fork/designdocs/check_samples.py
`--toolchain` (0 errors).

### §8.5 Mutants (the implementer re-runs M1; M2 if thunk.cpp was touched by a fix)

M1: swap result.carbon's two alternatives, `install.py`, `gate.sh`: exactly
the 7 goldens of §0.3 red; conformance exactly the 4 programs red; restore.
M2: the two minted identifiers back to `"Ok"`/`"Err"`, rebuild, `gate.sh
--filter interop/cpp`: exactly the 4 goldens of §0.3 red; restore, rebuild.
Each mutant's output goes in the review hand-off, never in a commit.

### §8.6 prek, R27 and R31 (every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
XDG_CACHE_HOME=<scratch>/prek-cache uvx prek run --files <paths>` to a
fixpoint (the prototype needed two passes: rumdl's reflow, ruff E501, clang-
format), the cache directory deleted afterwards by its literal path; R27: the
prelude impl diffed against error_handling.md's sketch after both are renamed
(byte-equal modulo the `Core.` qualification, as EH-A left it); R31: r31.py on
every markdown file before the edit, after it and after prek, in the commit
message, with the headings, items and rows the commit adds named.

### §8.7 The whole-tree grep (at C1, at D, at L)

`git grep -nE '\bOk\b|\bErr\b' -- . ':!fork/'` must list exactly
common/raw_hashtable.h:1314; over fork/, every hit is a closed plan, a dated
history note, the ledger's own W-346 text, a register prose paragraph or this
plan (the list of §0.1's last two rows), and no conformance program, checker,
living page or golden source line. The result is recorded in the decision-log
entry (D.2) as EH-B's reconciliation greps were.

### §8.8 The composition mirror and the land-time re-run

Before the implementation reviews: `git merge-tree --write-tree
<origin/trunk> <branch head>` (exit 0 expected while trunk is aee70185c; with a
moved trunk, only records conflicts by §6.2). At land time: §8.1 to §8.4 on
the branch's head after M and F-M, the figures quoted into Appendix F's texts.

### §8.9 The id re-scan (before D)

§0.7's commands after `git fetch origin` over every origin ref, local branch
and worktree, widened to `W-3[7-9][0-9]|W-4[0-9][0-9]`: W-380 must appear
nowhere but this plan and its reserved-text mentions; otherwise the next free
id, and every cross-reference in D.1, D.2, D.8 and this plan renumbered in the
same commit.

### §8.10 Not run, and why

clang-tidy: the container's kept clang 21 subset has no clang-tidy binary
(the arbiter's compile_commands.json exists under the build directory, so a
future run needs only the binary); R21's hosted gate (Actions disabled, owed
when it returns, R33 (b)); Bazel-only tests (no Bazel, never installed); the
owner's runner (R28); the nightly on the fork's programs (it has no
`Core.Result`); a Darwin build (V-1's macOS half, the same bound as EH-B's).

## Hand-off notes for the implementer

-   Rename on NON-CHECK lines only (the prototype's script matched
    `^\s*// CHECK`, indented ones included); never touch a CHECK line (R16);
    autoupdate fills them. Whole-word `\bOk\b|\bErr\b` leaves `ErrA`, `ErrB`
    and `ToErrB` alone, as it must.
-   Write Appendix C's sentences by hand: a mechanical rename produces "an
    `Success` value" and "an `Failure` payload" (measured).
-   check_faq.py:229 must be two literals (ruff E501); clang-format re-wraps
    four C++ files; rumdl reflows seven long lines in three pages: run prek
    twice and compare r31.py before and after.
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
-   The arbiter's GATE line prints `src-patches.applied`; the number to
    quote is "2047 passed, 0 failed" with that line beside it, as every
    container-measured record since ARB-2 does.

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

#### A.1.7 toolchain/check/testdata/main_run/return_result.carbon (6 lines)

| Line | Before | After |
| --- | --- | --- |
| :28 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
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

#### A.1.22 toolchain/check/testdata/operators/question_result.carbon (14 lines)

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

#### A.2.3 toolchain/lower/testdata/main_run/return_result.carbon (4 lines)

| Line | Before | After |
| --- | --- | --- |
| :19 | `` // (`ret i32 0` for `Ok(())`, the `i32` payload load for `Ok(code)`) or `` | `` // (`ret i32 0` for `Success(())`, the `i32` payload load for `Success(code)`) or `` |
| :28 | `return Core.Result((), i32).Err(n);` | `return Core.Result((), i32).Failure(n);` |
| :33 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
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

#### B.1.15 fork/conformance/programs/error_handling/run_result_err.carbon (7 lines)

| Line | Before | After |
| --- | --- | --- |
| :12 | `` // `fn Run() -> Core.Result((), i32)` is a valid entry point, and an `.Err` `` | `` // `fn Run() -> Core.Result((), i32)` is a valid entry point, and an `.Failure` `` |
| :15 | `` // ("carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1" — `` | `` // ("carbon: `Main.Run` returned `.Failure` of type `i32`; exiting with code 1" — `` |
| :18 | `` // `.Err(7)` on the runtime-computed input `RuntimeSeed(-20)` = 0 (R16d), so `` | `` // `.Failure(7)` on the runtime-computed input `RuntimeSeed(-20)` = 0 (R16d), so `` |
| :20 | `` // the `?` must NOT run and the trailing `.Ok(())` must NOT exit 0 — a `?` `` | `` // the `?` must NOT run and the trailing `.Success(())` must NOT exit 0 — a `?` `` |
| :26 | `if (n == 0) { return Core.Result((), i32).Err(n + 7); }` | `if (n == 0) { return Core.Result((), i32).Failure(n + 7); }` |
| :27 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |
| :36 | `return Core.Result((), i32).Ok(());` | `return Core.Result((), i32).Success(());` |

#### B.1.16 fork/conformance/programs/error_handling/run_result_ok.carbon (6 lines)

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
10. run_result_err.carbon — EXPECT-EXIT 1, EXPECT-STDOUT `1`. Prints 1;
    `Fails(RuntimeSeed(-20))` = `Fails(0)` = `Failure(7)`, `?` returns it from
    `Run`; the D10 epilogue writes the stderr line (now naming `.Failure`,
    not asserted by the runner) and exits 1; `2` is never printed.
11. run_result_ok.carbon — EXPECT-EXIT 3, EXPECT-STDOUT `21`, `20`.
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
by construction and was measured.

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
> are represented using [choice types](#choice-types) like `Result` and
> `Optional`.", :3858-3860 at ca1898506) and the section it links spells the
> result choice `Success`/`Failure`; EH-C renamed every use. No alias remains:
> the former spelling is an ordinary unknown member
> (`MemberNameNotFoundInSpecificScope`). The user may veto the reversal (R29).
```

<!-- google-doc-style-resume -->

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

The block :360-391 (C1): the eight lines of Appendix B.1.17's program, byte
for byte (the checker compares them). The prose :408-409 (P): "What to notice:
`Core.Result(T, E)` is a `choice` in the prelude, with the alternatives
`Success` and `Failure` (this fork spelled them `Ok`/`Err` until <date>, EH-C,
W-346; a program written then gets ``member name `Ok` not found in
`Core.Result(i32, i32)` ``). The postfix `?` returns the error to the caller,
or unwraps the value." The rest of the paragraph unchanged.

### C.5 docs/guides/evaluator_faq.md:356

The ```text line (C1): ``carbon: `Main.Run` returned `.Failure` of type `i32`;
exiting with code 1``. After the block (P), one sentence: "Until <date> (EH-C,
W-346) the line named `.Err`, the alternative's former spelling."

## Appendix D: the records texts, verbatim

`<date>` is each commit's UTC date; `<C1>`, `<F1>`, `<P>`, `<R>`, `<D>` the
commit shas; `<tip>` upstream's sha at D's re-fetch.

### D.1 fork/inventory/work-items.json

W-346: `"kind": "implemented"`; the title prefixed "EH-C (DISCHARGED at EH-C,
<date>): " before its current text; `evidence` gains, first: "core/prelude/
types/result.carbon:28-31 at <C1> (`Success(value: T)`, `Failure(error: E)`);
toolchain/check/cpp/thunk.cpp:1506-1509 (the minted identifiers);
toolchain/lower/handle.cpp:421 (the stderr line); toolchain/install/include/
carbon/expected.h:154-155 and :291; the 35 goldens of fork/eh/ehc-plan.md
Appendix A with the `fail_old_names` split of check/testdata/operators/
question_result.carbon; the 18 programs of Appendix B; docs/design/README.md,
error_handling.md, optional.md, docs/guides/tutorial.md and evaluator_faq.md's
dated amendments (Appendix C); container-measured (R33 (b)): gate 2047 of
2047 after the fill <F1>, conformance 228/0/13 over 241, 51/56 bullets; the
whole-tree grep `git grep -nE '\bOk\b|\bErr\b' -- . ':!fork/'` at <D> lists
common/raw_hashtable.h:1314 only". `notes` gains, appended: " DISCHARGED
<date> by EH-C (fork/eh/ehc-plan.md, D-EHC-1 to D-EHC-12): renamed at the
root with every use; no alias; the former spelling diagnoses
`MemberNameNotFoundInSpecificScope`; register row T2.1 ALIGNED; F-006a
reversed by a dated note under the owner directive of 2026-10-21, veto-able
(R29). Break condition of the discharge: the user's veto (then the rename is
reverted by a new commit and this item reopens with the veto recorded against
R32)."

W-380, new, after W-377: `"kind": "doc-gap"`, `"title": "PR 53 (SAFE-1; EH-C,
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
[]`, `"notes": "Filed <date> by EH-C at its discharge: EH-C landed before PR
53 (which waits on SAFE-4, fork/ORCHESTRATION.md Next actions item 14), so
D-RG-8's break condition fired for PR 53's one line. Work: one commit on
claude/carbon-fork-0-1-safe that spells the row `Success`/`Failure`, before
PR 53 lands (R32 (e): a new commit, never a rewrite). Owner: PR 53's landing.
Break condition: the user vetoes EH-C's reversal (then this item is withdrawn
with it)."`.

The `generated` and `source` fields: `source` gains the sentence "EH-C
(<date>) discharged W-346 and filed W-380."

### D.2 fork/decision-log.md: the entry

Placed directly before "### EH-B: catching thunks, Cpp.Exception,
Carbon::expected export (2026-09-27)":

<!-- google-doc-style-ignore -->

```markdown
### EH-C: `Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346) (<date>)

Placed here, before EH-B's entry, because the log groups entries by workstream
and EH-C is the error-handling workstream's third slice (fork/eh/ehc-plan.md,
beside fork/eh/plan.md's EH-A and EH-B). Line cites are to trunk aee70185c
unless a sha is named. Branch claude/carbon-fork-0-1-ehc, commits <plan>
(the plan), <C1>, <F1>, <P>, the reviews' fix commits <fixes>, <R> and <D>;
PR <N>, base trunk.

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
alternative renamed: thunk.cpp's minted `"Success"`/`"Failure"` identifiers
and its `success_*`/`failure_*` locals, lower/handle.cpp's `run.result.success`
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
fix budget of two, LAND-1's landing.

_Measured (container, R33 (b); the plan's §0.3 and §8)._ Gate on C1 alone:
2015 passed, the 32 goldens of the plan's §4 failing with "Autoupdate would
make changes"; after <F1>: 2047 passed, 0 failed; conformance 228/0/13 over
241, 51/56 bullets, byte for byte trunk's; `runner.py --self-test` 0 errors
on both sample checkers; check_faq.py 13 reproducers, 0 errors (fork) and 17
(nightly); fork/designdocs/check_samples.py --toolchain 0 errors; prek clean
at a fixpoint on every commit. _Reconciliation greps at <D>:_ `git grep -nE
'\bOk\b|\bErr\b' -- . ':!fork/'` lists common/raw_hashtable.h:1314 only;
over fork/ every hit is a closed plan, a dated history note, W-346's own
ledger text, RG-1's prose or fork/eh/ehc-plan.md (<count> files, listed in
the plan's §0.1); `git grep -nE '\.ok\(\)'` is empty; `grep -rn
'identifiers().Add("' toolchain/check/cpp/thunk.cpp` shows `"Success"` and
`"Failure"` only.

_V-3a register (RG-1's vocabulary, re-read at <tip>):_ T2.1 (F-006a's
alternatives) ALIGNED with README.md:2176-2177 and :3165-3166, break
condition D-EHC-1's (upstream renames or reorders; the user vetoes); T11.1
ALIGNED, its alternatives no longer a drift; T11.3 ALIGNED (the order);
T11.2, T11.4, T1.1 to T1.3 NONE, unchanged, W-355; a new silence check T2.1
in fork/register/rg1-checks.tsv (`Ok(`/`Err(` in upstream's docs/design and
proposals, expected 0) fires the upstream-side break condition.

_Ids._ W-380 to W-385 reserved by the plan's §0.7 re-scan (<n> refs, <w>
worktrees, after a fetch at D); W-380 filed; W-381 to W-385 unused.

_Not run._ clang-tidy (no binary in the container's clang 21 subset), R21's
hosted gate (Actions disabled; owed when it returns), Bazel-only tests (no
Bazel), the owner's runner (R28).

_Discharged at <D>: W-346 (EH-C)._
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
decision-log.md:1008-1011):

<!-- google-doc-style-ignore -->

```markdown
_W-346 resolved (<date>, EH-C):_ D-RG-5's rename landed as PR <N>; register
row T2.1 is ALIGNED; F-006a carries its reversal note; PR 53's one line is
W-380. See the entry "EH-C: ..." under the EH entries.
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
    lands and after EH-C (W-346)" (:19570-19571) insert " (EH-C landed <date>
    as PR <N>)"; after "W-378 is the next free id, and this check files none."
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
<date>)" and its Item cell "W-355". Row H3.2's Item cell: "the tutorial's 18
`Ok`/`Err` lines were renamed by EH-C, <date> (D-RG-8)". No other row and no
prose paragraph changes (D-RG-5 and D-RG-8 are history). R31's counts: rows
unchanged, headings unchanged.

fork/register/rg1-checks.tsv, appended after the last data row, preceded by
one comment line:

<!-- google-doc-style-ignore -->

```text
# T2.1 ALIGNED since EH-C (<date>, W-346): the upstream-side break condition as a silence check (D-RG-5: the README's examples change to Ok/Err)
T2.1	G	-E	\bOk\(|\bErr\(	docs/design proposals	0
```

<!-- google-doc-style-resume -->

fork/register/rg1-quotes.tsv, one comment line appended: "# T2.1 ALIGNED
since EH-C (<date>, W-346): its quotes are the docs/design/README.md 3858,
3860, 3164, 3165, 3166, 2176, 2177, 3856, 2167, 3159 and p000157 691, 229
rows above". Both scripts, run from the worktree root at <tip> before and
after: "checked 289 quotes, 0 failed" and "checked 95 silence checks, 0
failed" (one more check).

### D.7 fork/gap-analysis.md

Row "Error handling: dedicated control flow constructs" (:73) stays DONE; its
evidence cell gains, before the final sentence "The scalar-payload bound ...":
"EH-C (<date>, W-346, PR <N>): the alternatives are spelled
`Success`/`Failure`, upstream's README's (D-RG-5 resolved, register row
T2.1 ALIGNED); 8/8 programs PASS unchanged, container-measured 228/0/13 over
241 (R33 (b))." Row 70's example "`case .Ok(v: i32)`" becomes "`case
.Success(v: i32)`" (R). The header's tally 37/17/2/0 is unchanged by EH-C;
the landing's A.8 sentence restates it with PR <N>'s figures.

### D.8 fork/ORCHESTRATION.md

Before the landing (D): the Branches table gains, directly after the
`claude/carbon-fork-0-1-va2` row's position (the table's last workstream
row): "| `claude/carbon-fork-0-1-ehc` | OPEN as PR <N>, base trunk — EH-C:
`Core.Result`'s alternatives renamed to `Success`/`Failure` (W-346, R32;
F-006a reversed, veto-able); commits <C1>, <F1>, <P>, <fixes>, <R>, <D>;
container-measured (R33 (b), EXPECTED, not of record): gate 2047 of 2047,
conformance 228/0/13 over 241, 51/56 bullets; lands by LAND-1's D-LAND-6
after its reviews are dry. |". Next actions item 6's sentence "After the
held PRs land and before UA-3: W-346 (EH-C: `Core.Result`'s
`Success`/`Failure`, on trunk's base, beside W-341)." becomes "W-346 (EH-C:
`Core.Result`'s `Success`/`Failure`, on trunk's base) is open as PR <N> after
its reviews (<date>); it lands by LAND-1's procedure before UA-3, then PR
53's W-380 rename commit before PR 53 lands." and ":2725 "UA-3 follows W-341
and W-346." becomes "UA-3 follows W-341 (landed) and W-346 (PR <N>)." The
header gains the clause "Last updated: <date> (EH-C's PR <N> opened, W-346's
rename; 17 PRs landed, 1 held, 1 open; see the Branches row; the earlier
<prev> text follows)." before the current first clause. At the landing:
Appendix F's texts replace these.

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
programs (every EXPECT unchanged), the five pages that teach it (dated
amendments quoting upstream by sha) and the records. It reverses the user's
sub-decision F-006a (2026-07-19) under the owner directive of 2026-10-21;
the user may veto it (fork/eh/ehc-plan.md D-EHC-1).

Plan: fork/eh/ehc-plan.md (rev <n>, two adversarial reviews, <folds>).
Commits: <C1> rename, <F1> fill, <P> prose, <fixes>, <R> records, <D>
discharge. Container-measured (R33 (b)): gate 2047 of 2047 (after the fill;
2015 with 32 "Autoupdate would make changes" before it), conformance
228/0/13 over 241, 51/56 bullets, byte for byte trunk's; both sample
checkers and check_faq.py 0 errors; mutants: the order swapped turns 7
goldens and 4 programs red, the thunk's identifiers left as `Ok`/`Err` turn 4
goldens red. Records: W-346 DISCHARGED, W-380 filed (PR 53's
rust_interop.md:223 rename before it lands), decision-log entry EH-C, F-006a's
reversal note, register row T2.1 ALIGNED with a new silence check, gap row
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
shas>` M and F-M when trunk moved, else "none".

### F.1 M, the merge of trunk into the branch (only if trunk moved)

<!-- google-doc-style-ignore -->

```text
EH-C land (M): merge trunk <trunk before> into claude/carbon-fork-0-1-ehc

Trunk <trunk before> holds <what landed since aee70185c>. Resolved by
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
<rescan>; 18 PRs landed, 1 held. Next: PR 53's W-380 rename commit before it
lands (item 14), then UA-3.
```

<!-- google-doc-style-resume -->

Header clause: "Last updated: <date> (PR <N> landed by LAND-1; 18 PRs landed,
1 held; see the paragraph dated <date> (<hh:mm> UTC) below; the earlier
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
whole-tree grep re-run on the merge's tree lists common/raw_hashtable.h:1314
only."

### F.9 The gap header's first sentence (A.8) and ORCHESTRATION's Scoreboard paragraph (A.9)

As LAND-1's templates, with `<t1> DONE / <t2> PARTIAL / <t3> MISSING / <t4>
DESIGN-ONLY` = 37 / 17 / 2 / 0 (unchanged) and PR <N>'s figures; row 73
takes no "not of record" mark (D.7's text carries none).
