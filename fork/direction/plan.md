<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# DR-1: direction realignment (plan, rev 4)

Workstream DR-1 of decision-log entry DR-0 (D-DR-1..D-DR-4) under rulebook R32
and decision-log V-3b: `Core.Iterate.Next`'s `ref cursor` (W-321),
`Core.Slice`'s element access through `IndirectIndexWith` (W-109), the
retirement of PR 62's D-SV-7 view (W-322), the corrections owed on PR 56's
branch (W-323), and `Core.Optional` matchable by sum_types.md's `Match` (W-320),
which this revision stops at the plan (§1.4). Branch claude/carbon-fork-0-1-dr,
cut from trunk f68681114 (toolchain state 0bdce60a5). Upstream's recorded
direction is read at upstream/trunk ac31fd198 (fetched 2026-10-21 by `git fetch
upstream trunk`; FETCH_HEAD and upstream/trunk both name
ac31fd198582a29347ded6155b0d03d562d6fb01, "Give IdentifiedFacetType a more
foolproof API (PR 8008)", 2026-10-21 18:32 UTC); rev 1 read fb7eff130, and the
three commits since (c3877cf70, its revert 70c696e78, and ac31fd198) change no
design page, proposal or prelude file (§0.10). Rev 3, the signed-off revision,
read upstream/trunk bc45989b2 (fetched 2026-10-21 by `git fetch upstream
trunk`; FETCH_HEAD and upstream/trunk both name
bc45989b28cfa53131d140c37fb01ae541df45e3, "Reply to document requests for
unknown Carbon files (#7853)", 2026-10-21 19:10 UTC), whose one commit since
ac31fd198 changes toolchain/language_server only, so every quote taken at
ac31fd198 is the text at bc45989b2 (§0.10; amended 2026-10-21, review fold:
RR1-m4). Every measurement below is
container-local and EXPECTED, not of record (R9); the arbiter is the carbonbuild
scripts (R28), never the owner's runner, and the upstream nightly 2026.10.12 is
an oracle only (R30).

Rev 1, 2026-10-21. Rev 2, 2026-10-21: reviews A and B folded (31 findings).
Rev 3, 2026-10-21: the focused re-review of rev 2 folded
(APPROVE-WITH-AMENDMENTS, 6 findings: 1 MAJOR, 5 MINOR) and the plan signed
off; the records are "Review fold record" and "Sign-off" at the end.
Rev 4, 2026-10-22: a stop-and-amend at DR-1b's mirrors (amended 2026-10-22,
implementation: stop-and-amend: the m51 and m57 red sets), recorded in
"Stop-and-amend record (rev 4, 2026-10-22)" before the Sign-off. Decisions
D-DR-5..D-DR-22 are DR-1's (D-DR-1..D-DR-4 are DR-0's); they are auto-adopted
under R29(a), recorded in the decision log by the plan's records commit, and
each carries a break condition.

Status: rev 3, 2026-10-21 -- SIGNED OFF FOR IMPLEMENTATION. DR-1a is
implemented and held, 2026-10-21: its records are "Implementation review fold
record, DR-1a (2026-10-21)" and "Landed notes (DR-1a, 2026-10-21)" at the end.
Rev 4, 2026-10-22 (amended 2026-10-22, implementation: stop-and-amend): DR-1b
is implemented through B-P (cdaa15710 to 4c358f94b on
claude/carbon-fork-0-1-dr-idx, pushed) and stopped before B-R at the mirrors
of §8 item 9; rev 4 amends merge-time predictions only, and DR-1b resumes at
B-R after rev 4's focused re-review, as its Stop-and-amend record instructs.
DR-1b resumed on 2026-10-22 and is implemented through B-R (45294ea90) and its
implementation-review fold (amended 2026-10-22, implementation-review fold:
DR1B-m6): the records are "Implementation review fold record, DR-1b
(2026-10-22)" before the Sign-off and the landed notes that DR-1b's discharge D
writes on claude/carbon-fork-0-1-dr-idx. DR-1b's discharge is f774ee836, and
round 1 of the focused re-review of its fold read it (amended 2026-10-22,
re-review round 1): two reviews, no BLOCKER or MAJOR, eight MINOR findings
each, six of review 1's being rev 4's still-open RR4-m1..m6; two of review 2's
need a comment-only toolchain or golden edit, so round 1 is not dry and round 2
is owed. The record is "Focused re-review of the fold, DR-1b, round 1
(2026-10-22)" before the Sign-off, which also folds RR4-m1..m6. Round 2's
fixer made both edits, with RR1-1-F1's comment, in 8deb75262, DR-1b's fix
commit 2 of 3, comments only and with no fill commit, since autoupdate changed
nothing (amended 2026-10-22, re-review round 2); the record is "Focused
re-review of the fold, DR-1b, round 2 (2026-10-22)" before the Sign-off, and
round 2's reviews follow.

What rev 4 changes (amended 2026-10-22, implementation: stop-and-amend: the
m51 and m57 red sets). DR-1b's mirrors of §8 item 9 found two merge-time
predictions wrong. PR 51's buf_field goldens do not move with DR-1b: they dump
only functions that call `Make` and `Get`, never a `Buf` subscript. PR 57's
merge moves three of DR-1a's lower goldens (array/iterate, for/break_continue
and for/for), whose `!dbg` lines PR 57's own refill and DR-1a's fill both
renumbered, while PR 57's check/slice/basic auto-merges and passes. §0.8,
§0.8.1, §1.13, §1.16, §3, §4, §5, §6, §7.1, §8, §8.1, Appendix B.2 and the
Landed notes now carry the measured sets and stage B's errata; no D-DR
decision, no §2 code block and no measured row of DR-1b's own tree changes.

What rev 3 changes (amended 2026-10-21, review fold: RR1-M1 / RR1-m1 / RR1-m2 /
RR1-m3 / RR1-m4 / RR1-m5). W-322's commit on PR 62's branch writes no ledger
entry that branch lacks: it withdraws PR 62's own land-time W-177 narrowing
record (its plan's §1.16 paragraph and Appendix C.5) and the land-time items
that name the deleted golden, and marks W-280's `Core.Optional` half moot,
while W-177's correction moves to PR 56's ledger in W-323's commit (§1.11, C.6,
C.7). §0.8 records PR 59's and PR 60's call.cpp and convert.cpp overlap, the
dry runs of 230227264's hunks and CT-1's moved head; W-328 stays reserved for
W-320 alone (§3 item 9); a focused review of W-322's commit and the re-posting
of PR 62's, PR 56's and PR 57's texts are scheduled (§1.16, §3 item 2, C.5);
§8 item 9 re-runs the composition on CT-1's final head with DR-1a alone and
with both PRs before M-a.

What rev 2 changes (amended 2026-10-21, review fold: A-B1 / B-B1). Upstream's
own pages disagree on how `Match` declares its continuation:
docs/design/sum_types.md:113 writes `let template Continuation: type;`, while
docs/design/README.md:1076-1078 and :3064-3067 and
docs/design/generics/terminology.md:100-103 state that an associated constant is
always a checked generic binding and cannot be made `template`, and upstream's
parser refuses the keyword. Rev 1's slice 1 rested on implementing the template
associated constant (L1) and on impl members giving an associated constant its
value (L2, which accepted proposal p001013 removed). Both are new drifts under
R32, so rev 2 implements neither: D-DR-22's stop rule fires at the plan, slice 1
(W-320) waits on upstream's resolution (W-324 watches it), and DR-1 is two PRs,
DR-1a (slice 2) and DR-1b (slice 3). W-322's view is still a drift and is still
removed before PR 62 merges (R32 (e)), by a removal-only commit measured on a PR
62 mirror (§1.11). F-022 is not minted: DR-1 adopts no fork design (§1.17).

## Contents

-   §0 Audit: measurements with file:line evidence
-   §1 Design: decisions D-DR-5..D-DR-22
-   §2 Spec, file by file
-   §3 Commits and PRs
-   §4 Testdata matrix
-   §5 Conformance delta
-   §6 Churn and collisions
-   §7 Risks and rejected alternatives
-   §8 Verification
-   Hand-off notes
-   Appendix A: golden sources
-   Appendix B: programs and oracles
-   Appendix C: records texts
-   Review fold record (rev 2 and rev 3)
-   Stop-and-amend record (rev 4)
-   Implementation review fold records (DR-1a, DR-1b)
-   Focused re-review of the fold, DR-1b, round 1 (with RR4's fold)
-   Sign-off

## §0 Audit: measurements with file:line evidence

### §0.1 Toolchains, scratch and result codes

`$X` below is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/dr1/planner
(rev 1's probes, logs and diffs), `$Y` is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/dr1/fixer
(rev 2's) and `$Z` is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/dr1/fixer1
(rev 3's ledger reads and dry runs; amended 2026-10-21, review fold: RR1-M1 /
RR1-m1 / RR1-m4); all three are deleted with the session. Every probe was
compiled, linked and run by `runprobe.sh <carbon> <file> <outdir>` (`$X/bin`,
`$Y/bin`), which prints COMPILE-FAIL with the first `error:` text, LINK-FAIL, or
RUN with the program's standard output; `XDG_CACHE_HOME` was `$X/xdg` or
`$Y/xdg` throughout.

| Name | What | Version string | State |
| --- | --- | --- | --- |
| trunk | /home/user/carbon-build/carbon-trunk/install | 0.0.0-0.dev+0bdce60a5 | read-only; file_test 1942 of 1942, conformance 128/0/22 over 150 (carbonbuild README's validation record) |
| nightly | /home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12 | 0.0.0-0.nightly.2026.10.12+62f1cc6 | upstream 62f1cc6a3, contains df3cf9294 (the `ref` cursor) and not 6d80ceb58 or 309d3d63c |
| op, op2 | PR 56 and PR 57 installs | +5d9edb3e0, +9f9ccd768 | install sha to head 379f20f67 and 628273444: testdata only (`git diff --shortstat` over toolchain and core) |
| sv | PR 62 install | +a4d979619 | to head 3a6531157: four goldens only |
| tp | PR 61 install | +eafca5cb9 | to head 5661a35c8: two goldens only |
| st | PR 55 install | +84ff63560 | to head 21307851a: ten goldens only |
| v2 | slice 2's prototype: trunk plus §2.1's files | relinked over trunk's objects into /dev/shm/dr1-planner/carbon-dr (handle_loop_statement.cpp the one translation unit) | gate and conformance in §0.6 |
| v3 | rev 1's slices 2 and 3: trunk plus §2.1's and §2.2's files | full build.sh/install.sh of this worktree into /home/user/carbon-build/carbon-dr (core_identifier.def is an X-macro: every includer of context.h recompiles) | gate and conformance in §0.6.1 |
| v4 | rev 2's slices 2 and 3 (amended 2026-10-21, review fold: A-M5 / B-M13 / A-m2 / B-M7) | v3's objects (the six C++ files restored byte-identical to v3's sources with their pre-build mtimes, so ninja rebuilt only the file_test manifest and the version stamp), then install.sh: 0.0.0-0.dev+1e46ffd94.dirty | gate and conformance in §0.6.2 |
| mct | the composition mirror: CT-1's head 79740957a (stacked on PR 61) plus v4's diff, merged as §2.1 and §2.2 resolve it (amended 2026-10-21, review fold: B-M6 / B-M2) | full build into /dev/shm/dr1-fixer/mct, a `git worktree` at `$Y/mct` | §0.8.1 |
| m62 | PR 62's head 3a6531157 plus W-322's removal-only commit (amended 2026-10-21, review fold: A-M3 / B-B2) | full build into /dev/shm/dr1-fixer/m62, a `git worktree` at `$Y/m62` | §0.8.2 |

The relink of v2 was produced by `$X/bin/relink.py`, which rewrites trunk's
build.ninja so that the changed translation units compile from this worktree
with trunk's flags (this worktree's include root first) and the three binaries
link over trunk's read-only objects (absolute paths), then
`CB_BUILD_ROOT=/dev/shm/dr1-planner` install.sh. No build directory was copied;
the mirrors are git worktrees of their heads in `$Y`, removed after measuring.

### §0.2 The directive and the work items

DR-0, R32 and V-3b are read in full (fork/decision-log.md:22-243 as committed;
fork/rulebook.md:383-408), as are the research's research_final.md,
research_verdicts.json and research_evidence.json; this plan does not restate
them. The five work items, on trunk's fork/inventory/work-items.json: W-320
(`Core.Optional` matchable by `Match`, XL), W-321 (the `ref` cursor at 11 sites,
M), W-322 (PR 62's D-SV-7 view, a V-3a divergence, S, blocked by W-320), W-323
(records corrections on PR 56's branch, S) and W-109 (SL-1's residue, L, its
notes dated by DR-0). DR-1 reserves W-324..W-329 (all unused on every ref at
DR-0's re-scan) and may mint F-022 (§1.17 decides not to). Rev 2 (amended
2026-10-21, review fold: A-B1 / B-B1 / A-M3): W-322 loses its `blocked_by` on
W-320, because the view is a drift that R32 (e) removes before PR 62 lands
whether or not W-320 can land (§1.11); W-320 gains `blocked_by` W-324 (§1.4).

### §0.3 The probe matrix (audit item 1)

Sources: `$X/a1/*.carbon` (Appendix B.0 lists each body). The `match` probes
write `case .None()` because the prelude's `None` is a function (§1.4);
`m_match_bare_none` writes `case .None`. `c_exh_return` is a two-alternative
`choice` whose two arms both `return`, the control for the "missing `return`"
row.

| Probe | trunk | nightly | PR 62 (sv) | PR 61 (tp) | PR 57 (op2) | PR 55 (st) |
| --- | --- | --- | --- | --- | --- | --- |
| m_match: `match (o) { case .Some(x: i32) ... case .None() ... }` | TODO `match on unsupported scrutinee type` | TODO `HandleMatchIntroducer` | `` alternative `None` is declared without a parameter list, so its pattern cannot have parentheses `` | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| m_match_bare_none (`case .None`, both arms `return`) | TODO scrutinee | TODO `HandleMatchIntroducer` | `` missing `return` at end of function with declared return type `` | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| m_iflet: `if (let .Some(x: i32) = o)` | TODO `refutable pattern binding on unsupported scrutinee type` | `expected expression` | RUN `7` | TODO refutable | TODO refutable | TODO refutable |
| m_whilelet over `Next(n) -> Core.Optional(i32)` | TODO refutable | `expected expression` | RUN `1 2 3` | TODO refutable | TODO refutable | TODO refutable |
| m_letelse: `let .Some(x: i32) = o else { return -1; }` | TODO refutable | `` name `.Self` not found `` | RUN `9 -1` | TODO refutable | TODO refutable | TODO refutable |
| f_range: `for (i: i32 in Core.Range(4))` | RUN `6` | RUN `6` | RUN `6` | RUN `6` | RUN `6` | RUN `6` |
| f_array: `for` over `array(i32, 3)` | RUN `6` | RUN `6` | RUN `6` | RUN `6` | RUN `6` | RUN `6` |
| f_slice: `for` over `Core.Slice(i32).FromArray(&a)` | RUN `15` | `` member name `Slice` not found in `Core` `` | RUN `15` | RUN `15` | RUN `15` | RUN `15` |
| f_cpprange2: the conformance program interop/cpp_range_member_begin_end_iterate.carbon | RUN `7 11 13 31` | RUN `7 11 13 31` | not run | not run | not run | not run |
| f_cpprange: `for` over `std::vector<int>` | `` facet type `Core.CppRange where .(Core.CppRangeForIterate.Iterator).(Core.CppUnsafeDeref.Result) impls Core.Copy` can not be identified `` | the same | the same | the same | the same | the same |
| o_ptr_null: `Optional(i32*)` Some and None through `HasValue`/`Get` | RUN `3 -1` | RUN `3 -1` | RUN `3 -1` | RUN `3 -1` | RUN `3 -1` | RUN `3 -1` |
| o_ptr_match: `match` on `Optional(i32*)` | TODO scrutinee | TODO `HandleMatchIntroducer` | the `None` parentheses error | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| o_string: `match` on `Optional(Core.String)` | TODO scrutinee | TODO `HandleMatchIntroducer` | `` cannot match `Core.Optional(str as Core.OptionalStorage)` in 0.1: its payload type is not a choice payload type `` | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| o_try: `Half(n)?` twice | RUN `2 -1` | `` `let` declarations must end with a `;` `` | RUN `2 -1` | RUN `2 -1` | RUN `2 -1` | RUN `2 -1` |
| o_nested: `case .Some(.Some(x: i32))` | TODO scrutinee | TODO `HandleMatchIntroducer` | `` cannot match `Core.Optional(Core.Optional(i32 as Core.OptionalStorage) as Core.OptionalStorage)` in 0.1: its payload type is not a choice payload type `` | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| o_generic: `F[T: Core.Copy & Core.Destroy]` matching `Optional(T)` | TODO scrutinee | TODO `HandleMatchIntroducer` | `` cannot match `Core.Optional(T as Core.OptionalStorage)` in 0.1: its payload type is symbolic `` | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| o_template: `F[template T: type]` matching `Optional(T)` | TODO scrutinee | TODO `HandleMatchIntroducer` | TODO scrutinee | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| sv_view: a `std::optional<int>` converted to `Core.Optional(i32)` and matched | TODO scrutinee | TODO `HandleMatchIntroducer` | the `None` parentheses error | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| sv_std_match: `match (Cpp.Maybe(true))` on the `std::optional` itself | TODO scrutinee | TODO `HandleMatchIntroducer` | the `None` parentheses error (`StdOptional`'s `None` is a constant) | TODO scrutinee | TODO scrutinee | TODO scrutinee |
| c_exh_return: an exhaustive `choice` match whose arms both `return` | `` missing `return` at end of function with declared return type `` (test.carbon:8:1) | not run | not run | not run | not run | not run |

Readings. (a) No toolchain matches `Core.Optional` by `.Some(<pattern>)` except
PR 62, through its D-SV-7 view, which spells the empty alternative `.None` (the
view's `StdOptional` is a choice whose `None` is a constant) and refuses
symbolic, aggregate, string and nested payloads. (b) Upstream's nightly parses
none of the forms (`HandleMatchIntroducer` is a TODO, upstream
handle_match.cpp:11-76) and has no `?` on `Optional`. (c) Iteration over a
range, an array, a slice and a hand-written C++ range runs on every toolchain;
`std::vector` iteration fails on every toolchain including the nightly, with the
same facet-identification message: an upstream limitation, outside DR-1. (d) The
PR 62 `m_match_bare_none` failure is not D-SV-7's: `c_exh_return` reproduces it
on trunk with a plain choice, so reachability after an exhaustive `match` whose
arms all diverge is a fork gap of its own (filed W-329, §1.17). The `.None()`
spelling of these probes is §1.4's reading for W-320's resumption (amended
2026-10-21, review fold: A-m3 / B-M8).

### §0.4 The match path on trunk and where a `Match` class enters (audit item 2)

Slice 1's audit, kept as the starting point of W-320's resumption (§1.4); rev 2
implements none of the right-hand column (amended 2026-10-21, review fold: A-B1
/ B-B1).

The refutable engine is one driver for four forms
(toolchain/check/handle_match.cpp:32-46). Its steps, the SemIR each emits today,
and where a scrutinee whose type implements `Core.Match` enters:

| Step | Trunk code | SemIR emitted today | A `Match` class |
| --- | --- | --- | --- |
| Scrutinee gate | refutable_binding.cpp:137-208 `CheckRefutableScrutinee`: `ConvertToValueOrRefExpr`, `RequireCompleteType`, `IsSupportedScrutineeType` (:83-135: int, bool, matchable choice, tuples and structs of those), else `context.TODO(node_id, todo_string)`, the strings `match on unsupported scrutinee type` and `refutable pattern binding on unsupported scrutinee type` | the scrutinee's conversion insts; `RequireCompleteType`'s `require_complete_type` witness when symbolic | enters here: a type that is none of the five shapes and implements `Core.Match` (impl lookup) is admitted, and the continuation and the `Op` call are emitted once (rev 1 §1.5) |
| Alternative pattern | handle_match.cpp:248-470 `AlternativePattern`: `ResolvePendingAlternative` (refutable_binding.cpp:210-293) refuses a non-choice scrutinee with the W4 TODO `` match `case` pattern other than an integer literal, or a case guard `` (:216-224), looks the name up in `Class::choice_alternatives` (pattern_match.cpp:512-528), applies the parens rule (`MatchAlternativeUnexpectedParens` :236, `MatchAlternativeMissingParens` :252, `MatchAlternativeArgCountMismatch` :275), and wraps the payload subpatterns in a synthesized `TuplePattern` | `TuplePattern` (synthesized), `ExprPattern` for the bare constant spelling; a pending alternative for `if let`, `while let`, `let`-`else` (resolved by `ResolveDeferredAlternative`, :296-337) | the name resolves against the methods of the impl's `Continuation` interface instead of `choice_alternatives`; the parens rule reads the class's factory member (rev 1 §1.6) |
| Test pass | refutable_binding.cpp:339-487 `EmitRefutableBindingTest` classifies the arm; `MatchCaseAlternativePatternMatch` (pattern_match.cpp:597-694) tests the discriminant (`EmitChoiceDiscriminantTest`, :573-595) and, dominated by it, the payload's refutable subpatterns | `NameBindingDecl`; `ClassElementAccess` (element 0, the `.discriminant`), an `EqWith(disc).Equal` call through `BuildBinaryOperator`, `BranchIf`, `BranchWithArg`, `BlockArg` | the discriminant read becomes the `Op` call's result (an `i32` value) and the payload read becomes the continuation's slot; the same `EqWith` test and the same dominance structure |
| Bind pass | refutable_binding.cpp:489-603 `EmitRefutableBindingBind`; `EmitChoicePayloadFieldAccess` (pattern_match.cpp:1048-1078) reads the payload tuple out of field 1's `CustomLayoutType` region | `ClassElementAccess` (field 1), the payload tuple's element reads, binding insts (`ValueBinding`, `RefBinding`, `VarStorage` for `var`) | the payload tuple is the slot's tuple, read through `ClassElementAccess` on the continuation object and an `AsCompatible` from `MaybeUnformed(P)` to `P` |
| Exhaustiveness and usefulness | handle_match.cpp:122-174 and the key machinery (pattern_match.cpp:762-971) | none (diagnostics) | the alternatives are a closed set (sum_types.md:99-101), keyed by the `Continuation` method index |
| `for` | handle_loop_statement.cpp:204-295: `NewCursor`, an `AddrOf` of the cursor (:255-259), `Next`, then `CallOptionalAccessor` `HasValue` (:280) and `Get` (:290) under upstream's TODO (:269-272) | `VarStorage`, `AddrOf`, two `Call`s per iteration through `PerformMemberAccess` | slice 2 removes the `AddrOf` (§1.2); W-320's resumption replaces the two accessor calls by matching `Next`'s result against `.Some(<pattern>)` (§1.4) |
| Lowering | no lower/handle_match*.cpp exists: `match` lowers through the branch instructions above | n/a | nothing new: the continuation class, its impls and functions are ordinary SemIR, lowered per specific |

Upstream's handle_match.cpp at ac31fd198 (as at fb7eff130) checks nothing: every
handler at :11-76 is `context.TODO(...)` (for example `HandleMatchIntroducer`),
and its loop checker keeps the `.Some(pattern_id)` TODO (upstream
handle_loop_statement.cpp:235-238). So the fork's engine is the only code to
extend, and the mechanism follows sum_types.md and p000157 (§0.10).

### §0.5 `ref`, the thunk failure, and `IndirectIndexWith` (audit item 3)

`ref` parameters and returns work on trunk, on user interfaces and impls:
`$X/probes/ref_return.carbon` (a method `fn Ref(ref self, i: i32) -> ref i32`
assigned through) prints `20` on trunk and the nightly; `ref_return_ptr.carbon`
(`fn At(p: i32*) -> ref i32`, `At(&x) = 5`) prints `5` on both;
`iiw_iface.carbon` (a user interface `IIW(Sub)` with `fn Ref(self, subscript:
Sub) -> ref ElementType` and an impl whose `Ref` returns `*self.p`, assigned
through `v.(IIW(i32).Ref)(0) = 7`) prints `7` on both. The research's
`ref_iface` probe (a user interface with a `ref cursor` method) compiles on
trunk too.

The thunk failure, root cause. `$X/probes/ref_cursor_for.carbon` (a class whose
`impl as Core.Iterate` declares `fn Next(self, ref cursor: i32)`) on trunk:

<!-- google-doc-style-ignore -->

```text
ref_cursor_for.carbon: error: cannot implicitly convert expression of type `i32*` to `i32`
ref_cursor_for.carbon: note: type `i32*` does not implement interface `Core.ImplicitAs(i32)`
ref_cursor_for.carbon:6:19: note: initializing function parameter
    fn Next(self, ref cursor: i32) -> Core.Optional(i32) {
                  ^~~~~~~~~~~~~~~
.../core/prelude/iterate.carbon:17:3: note: while building thunk to match the signature of this function
  fn Next(self, cursor: CursorType*) -> Optional(ElementType);
```

<!-- google-doc-style-resume -->

The thunk builder is asked to adapt an impl function whose second parameter is
`ref i32` to an interface function whose second parameter is `i32*`, and it
reports, correctly, that the interface's argument (a pointer) does not convert
to the impl's parameter type. The defect is not in thunk.cpp: it is the fork's
`Core.Iterate.Next` declaration (core/prelude/iterate.carbon:17), which still
takes a pointer where upstream adopted `ref` (df3cf9294). The root fix (R17) is
slice 2's interface change, measured: on v2 the same probe compiles with no
error (only the two unused-`self` warnings, as on the nightly), and `for (x: i32
in t)` over it runs. The file-only location of the first line (no line number)
is the thunk's canonical-inst location; upstream 7beb29f8b ("Use a fallback loc
for diagnostics generated on canonical insts", 2026-10-15) addresses that class
and is UA-3's, not DR-1's.

`IndirectIndexWith`. Upstream's prelude at ac31fd198 (as at fb7eff130),
core/prelude/operators/index.carbon:7-28:

<!-- google-doc-style-ignore -->

```carbon
export import library "prelude/copy";

interface IndexWith(SubscriptType: type) {
  let ElementType: type;
  fn At(self, subscript: SubscriptType) -> ElementType;
}

interface IndirectIndexWith(SubscriptType: type) {
  let ElementType: type;
  fn Ref(self, subscript: SubscriptType) -> ref ElementType;
}

final impl forall [
        SubscriptType: type,
        T: IndirectIndexWith(SubscriptType)
        where .ElementType impls Copy
    ] T as IndexWith(SubscriptType)
        where .ElementType = T.ElementType {
  fn At(self, subscript: SubscriptType) -> ElementType {
    return self.Ref(subscript);
  }
}
```

<!-- google-doc-style-resume -->

6d80ceb58 added it ("Matching the API as described in the update in PR 5434,
with a `Ref` rather than `Addr` function (and `ref` rather than pointer return
form). Also added a blanket `final` impl of `IndexWith` when the element type
impls `Copy` ... which differs slightly from the design wording"), and 309d3d63c
made subscripting prefer it: upstream handle_index.cpp tries
`IndirectIndexWith(I).Ref` with `diagnose=false` and falls back to
`IndexWith(I).At` with `diagnose=true`, under `` // TODO: Use `IndexWith.Ref`
when the operand is a durable reference. ``, and adds `IndirectIndexWith` and
`Ref` to core_identifier.def and a `case CoreIdentifier::IndirectIndexWith:
return std::nullopt;` to cpp/operators.cpp ("C++ `operator[]` is found through
`IndexWith`, which subscripting falls back to"). The fork has neither
(core/prelude/operators/index.carbon:7-10 is `IndexWith` alone;
handle_index.cpp:37-47 `PerformIndexWith` calls `At`), and its `default:` arm
differs from upstream's because upstream's handle_index.cpp also carries
947c1eb52 (`Core.Array`, 2026-10-06), which the fork does not. The fork's slice
impls: core/prelude/types/slice.carbon:74-77 (`final impl ... Slice(T) as
IndexWith(i64)`, `At` returns `self.Get(subscript)` by value) and
core/prelude/types/buf.carbon:72-75 (the same for `Buf`); `Buf.Set`
(buf.carbon:48-53) is the only write path (D-SL-6), and `s[i] = v` is pinned
failing by toolchain/check/testdata/slice/fail_basic.carbon's
`fail_write_through` split (D-SL-3, fork/slices/plan.md:221-237).

### §0.6 Prototypes and their gates (audit item 4)

v2 (slice 2). The diff of §2.1 (the prelude's four `Next` impls and its
interface, range.carbon, min_prelude's interface, the loop checker, four test
sources and one conformance program): before the test sources were edited, the
gate on v2 was 1933 passed, 9 failed, the failures exactly the nine goldens
listed below (the four test sources whose `Next` impls still took pointers
failed to compile against the `ref` interface, through the thunk diagnostic
above); after the four sources and the program took `ref`, `autoupdate.sh` on
the nine goldens (`!!!!!!.!!`, eight rewritten) and the full gate: 1942 passed,
0 failed (68 s); conformance: PASS 128, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0,
OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 of 150, bullets 48/0/8 of 56 (98.3
s; `$X/out/conf-s2`). The nine goldens and their churn (numstat, CHECK lines
from autoupdate):

| Golden | +/- | Against df3cf9294's own hunks |
| --- | --- | --- |
| check/testdata/for/actual.carbon | 114/124 | same shape; differs only in context names the fork already renamed (`%N.fe9` for upstream's `%N`, the SL-1 `final` import) |
| check/testdata/for/basic.carbon | 3/5 | byte-identical changed lines |
| check/testdata/for/pattern.carbon | 11/19 | byte-identical changed lines |
| check/testdata/interop/cpp/range_for.carbon | 17/69 | byte-identical changed lines |
| check/testdata/slice/basic.carbon | 1/3 | fork-only (SL-1): the `%ptr.643` constant and the `addr_of` leave, the call takes `%var` |
| lower/testdata/array/iterate.carbon | 137/137 | same shape; `!dbg` numbering offset by the fork's existing metadata |
| lower/testdata/for/bindings.carbon | 1/1 | byte-identical changed lines |
| lower/testdata/for/break_continue.carbon | 134/134 | same shape; `!dbg` offset |
| lower/testdata/for/for.carbon | 136/136 | same shape; `!dbg` offset |

The probes on v2: f_range `6`, f_array `6`, f_slice `15`, f_cpprange2 `7 11 13
31`, o_try `2 -1`, ref_cursor_for compiles clean. SL-1's slice iteration
(iterate.carbon:86-98) and SL-2's C++ range iteration (iterate.carbon:66-82) are
covered by check/testdata/slice/basic.carbon, range_for.carbon and the five
interop conformance programs that iterate C++ ranges, all passing.

v3 (slices 2 and 3). §0.6.1 below records its build, gate and conformance.

p1 (slice 1's central mechanism, by hand). The mechanism cannot be prototyped in
the compiler before its language prerequisites exist (§0.7), so its generated
code was written out in Carbon, as sum_types.md:167-187 writes
`__MatchStatementImpl`, and measured on trunk (`$X/proto1`): a continuation
interface with one method per alternative (`fn Some(ref self, value: T) -> i32;
fn None(ref self) -> i32;`), a generic `Op[T, C: OptionalContinuation(T)](o:
Core.Optional(T), continuation: C*) -> i32` whose body is sum_types.md:153-159's
over `HasValue`/`Get`, a continuation class whose methods store the parameter
into a `Core.MaybeUnformed(T)` slot and return the alternative's index
(sum_types.md:224-227), and the dispatch on the index:

| Prototype | Shape | trunk |
| --- | --- | --- |
| desugar_i32.carbon | concrete `i32`, a file-scope continuation class | RUN `5 -1` |
| desugar_string.carbon | `Core.String` slot in `MaybeUnformed`, `UnformedInit` continuation | RUN `4 -1` |
| desugar_generic.carbon | `Cont(T)` generic class; `G[T]` instantiated at `i32` and `i32*` | RUN `4 7 9` |
| local_class_generic.carbon | the continuation as a LOCAL class inside the generic `G[T]`, a `MaybeUnformed(T)` slot of symbolic type, its `impl as OC(T)` | RUN `4 7` |
| v2.carbon (`$X/probes`) | a class with a nested-free continuation interface and `Op[C: OptCont]` as a class member | compiles and runs |

The last row matters most: the per-statement continuation (sum_types.md:167-187:
"the compiler-generated implementation of `Optional.(Match.Continuation)` for
the `match` statement") can be a local class of the enclosing function even when
that function is generic, and trunk's per-specific lowering monomorphizes it.
The LLVM IR of desugar_i32 (`$X/out/desugar_i32.semir` and the `--dump-llvm-ir`
listing) has the continuation's methods as ordinary `define i32
@"_CSome.MatchStatementImpl.Main:OptionalContinuation..."(ptr %self, i32
%value)` and `_CNone...`, called from the `Op` specific.

#### §0.6.1 v3: slices 2 and 3, a full build

`build.sh /home/user/carbon-dr` (322 steps, no warnings, under -Werror, with
CT-1's mutant relinks competing for the four cores; `pgrep -fa ninja` showed no
other ninja before it started) and `install.sh` produced
`0.0.0-0.dev+f68681114.dirty`. Three measured facts shaped slice 3:

1.  **A crash, root-caused to a missing upstream commit.** With upstream's
    index.carbon as written, every program importing the prelude CHECK-failed
    while checking the blanket impl's `return self.Ref(subscript);`
    (index.carbon:26): `CHECK failure at toolchain/check/pattern_match.cpp:2207:
    std::holds_alternative<CalleeState*>(state)`, reached from
    `CallerPatternMatch` by way of `ConvertCallArgs` and
    `PerformCallToFunction`. A call to a function with a `ref` return form whose
    type might be initialized in place (here the symbolic `ElementType`) was
    given temporary return storage, and caller pattern matching then matched
    that storage against the callee's `ref_return_pattern`, which only the
    callee side supports. Upstream fixed exactly this in 230227264 ("Only
    allocate return storage when the callee has a return parameter", PR 7886,
    2026-10-09, after the cut and before 6d80ceb58): call.cpp gates the
    temporary on `callee.call_param_ranges.return_size() > 0` and convert.cpp's
    `ConvertCallArgs` asserts the same property. Its two code hunks apply to
    trunk with `git apply` unchanged (call.cpp +4/-1, convert.cpp +4) and remove
    the crash; slice 3 therefore takes 230227264's code, which is the root fix
    (R17), not a guard in pattern_match.cpp. Its two goldens are not new files:
    the fork already has check and lower testdata/function/call/form.carbon,
    `git apply --check` of the whole commit fails at the check file's :262 and
    the lower file's :86, and v3 never ran upstream's three new splits; §0.6.2
    measures them (amended 2026-10-21, review fold: A-M5 / B-M13).
2.  **Private members.** The fork's `Slice` and `Buf` impls are declared outside
    their classes, so a `Ref` body cannot read the private `ptr` and `size` (``
    cannot access private member `size` of type `Buf(T)` ``); the bodies use the
    public `Size()`, `Data()` and `AsSlice()` instead (§2.2).
3.  **The fill.** Before refill, the gate was 1931 passed, 11 failed:
    index/fail_invalid_base, index/fail_non_tuple_access,
    operators/overloaded/index, operators/overloaded/index_with_prelude,
    operators/overloaded/string_indexing, slice/basic, slice/buf,
    slice/fail_basic (check), and interop/cpp/span, slice/basic, slice/buf
    (lower). `fail_basic.carbon`'s `fail_write_through` split, D-SL-3's pin, now
    compiles, so it was deleted as D-SL-3's break condition says ("the pin is
    deleted"); one autoupdate pass rewrote the eleven (`!!!!!.!!!!!`), a second
    pass moved one `.loc23` to `.loc27` in operators/overloaded/index.carbon
    (R26's two-pass convergence: the new STDERR lines shift `[[@LINE]]`), and
    the gate is then 1942 passed, 0 failed (49 s). Conformance on v3: PASS 128,
    COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0,
    SKIP 22 of 150 (83.4 s; `$X/out/conf-s3`).

Against upstream's own hunks: the four lines index/fail_invalid_base.carbon
gains are byte-identical to 309d3d63c's; operators/overloaded/index.carbon gains
three `` name `Core.IndirectIndexWith` implicitly referenced here, but not found
[CoreNameNotFound] `` diagnostics in its fake-`Core` splits, the behavior
upstream's golden at 309d3d63c also shows (one occurrence there, because
upstream's commit removed 630 lines of that file's other splits). The slice-3
probes (`$X/s3`), trunk then v3:

| Probe | trunk | v3 |
| --- | --- | --- |
| s_write: `s[1] = 20; s[i] = s[0] + s[1];` over `FromArray(&a)` | `expression is not assignable` | RUN `1 20 21` |
| s_buf_write: `b[0] = 7; b.Set(1, 8); b[2] = b[0] + b[1];` | `expression is not assignable` | RUN `15` |
| s_const: `s[0] = 1` on `Core.Slice(const i32)` | `expression is not assignable` | `expression is not assignable` |
| s_generic_write: `Fill[T](s: Core.Slice(T), v: T)` writing `s[i] = v` | `expression is not assignable` | RUN `27` |
| s_generic_const2: that `Fill` called with `T = const i32` | `expression is not assignable` (at the definition) | RUN `2`: the generic body writes through `Slice(const i32)` |
| s_ptr_const_write: `Set[T](p: T*, v: T) { *p = v; }` called with `T = const i32` | RUN `7` | (unchanged; not a slice program) |
| s_oob_write: `s[2] = 5` on a two-element slice | `expression is not assignable` | `carbon: Core.Slice index out of bounds; terminating` on stderr, SIGABRT |
| s_read: reads `s[0] + s[2]`, a generic `s[0]` | RUN `10 4` | RUN `10 4` |
| s_span_write: `s[0] = 10;` then C++ `Bump(std::span<int>)` and `Sum` | `expression is not assignable` | RUN `18` |

s_ptr_const_write also prints `7` on the nightly: a generic assignment whose
specific's target is `const` is accepted by upstream's toolchain today, through
a pointer. D-SL-3's other reason ("a `Slice(const T)` over C++ read-only memory
would compile its store against the unqualified symbolic `T`") is therefore a
property of the language's current implementation, not of slices; slice 3
reaches it through `s[i] = v` as `*p = v` already does, and it is filed as W-327
(§1.17), not kept as a reason for a read-only `Slice`. Separately, `"abc"[1]` on
a `str` crashes trunk's lowering (`GEP indexes must be integers`), unchanged by
slice 3 and outside DR-1 (ST-1's string indexing is PR 55's).

#### §0.6.2 v4: rev 2's re-measure of slices 2 and 3

(Amended 2026-10-21, review fold: A-M5 / B-M13 / A-m2 / B-M7 / B-m4.) v4 is v3
plus: upstream 230227264's three new split sources added to the fork's two
existing function/call/form.carbon goldens (check: `ref_return_class`,
`val_return_class`, `ref_return_class_generic`, before
`fail_return_form_not_form`; lower: the same three after `val_return_form`;
Appendix A.0); upstream's two `IndirectIndexWith` tests from 6d80ceb58 and
309d3d63c as of ac31fd198, their CHECK lines removed by `$Y/bin/strip_checks.py`
and refilled by this tree's autoupdate
(check/testdata/operators/overloaded/indirect_index_with.carbon and
lower/testdata/index/indirect_index_with.carbon); A.1 and A.2 as rev 2 writes
them (with the W-327 pin split); and programs B.1 and B.2. The C++ sources are
v3's byte for byte, so v4 is v3's binaries with a relinked file_test (1946
manifest entries).

| Step | Result |
| --- | --- |
| gate before refill | 1938 passed, 8 failed: the two form.carbon goldens, the two upstream tests, check and lower slice/buf (reset to trunk's text for the `Buf` measurement below), and A.1, A.2 |
| autoupdate, pass 1 | `!!!!!!!!` (all 8 rewritten) |
| autoupdate, pass 2 | `........` (fixpoint; md5 of the 8 files unchanged) |
| gate | 1946 passed, 0 failed (41 s) |
| conformance | PASS 130, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 of 152; bullets 48/0/8 of 56 (63.6 s; `$Y/out/conf-v4`) |

The fill against upstream's own lines. check/testdata/function/call/form.carbon
gains 172 lines, as 230227264's hunk does; 169 of them are byte-identical to
upstream's, and the 3 that differ are the `-> ref C` return pattern, where the
fork emits `ref_tag` then `ref_form` and upstream emits `ref_form` then
`type_component_of`: upstream 059ee7b9e ("Parse `-> ref T` as a primitive
return form", 2026-10-07), which the fork does not have (§0.10). The lower
file gains 103 lines (upstream's hunk is 158 because upstream's file has a
preceding split the fork lacks). Corrected 2026-10-22 (implementation-review
fold: DR1B-m1): the fork lacked no preceding split. v4 and B0 left out the
last 11 lines of upstream's third lower split, `class D` with its `impl as I`
and `fn H(d: D) { G(d); }`, so no specific of `G` was lowered; restored, the
golden gains 158 lines, as upstream's hunk does, its lines upstream's but for
the metadata numbers. The upstream `IndirectIndexWith` tests fill
to 620 and 164 lines (upstream's 618 and 164): the differences are the
prelude-dependent hash suffixes and one diagnostic rendered with a source
snippet instead of upstream's column range (upstream 2c9739799, UA-3's). Their
`ref_non_copyable` and `subscript_non_copyable` splits check a `ref` return of
a non-`Copy` element and `subscript_assign` writes through `c[s]`.

`Buf` and `IndexWith` (B-M7), measured on v4's binaries with prelude-only
changes and `install.sh`:

| `Buf(T)`'s impl | Result |
| --- | --- |
| `final impl ... Buf(T) as IndexWith(i64)` (trunk's, kept beside upstream's index.carbon) | every program importing the prelude fails: `` `final impl` overlaps with `final impl` from another file [FinalImplOverlapsDifferentFile] `` at buf.carbon:72, the note at index.carbon:19 (the blanket `final impl forall [..., T: IndirectIndexWith(SubscriptType) where .ElementType impls Copy] T as IndexWith(SubscriptType)`); gate 1615 of 1946 |
| the same without `final` | the prelude compiles; `buf_generic_read` (`fn First[T: Core.Copy & Core.Destroy](b: Core.Buf(T)) -> T { return b[0]; }`) regresses from trunk's RUN `6` to `` cannot implicitly convert expression of type `Core.Buf(T).(Core.IndexWith(i64).ElementType)` to `T` `` (D-SL-18's reason for `final`) |
| `final impl ... Buf(T) as IndirectIndexWith(i64)` (rev 1's, kept) | `buf_generic_read` RUN `6`; `buf_let_write` (`fn W(b: Core.Buf(i32)) { b[1] = 5; }` through a by-value `Buf`) RUN `5`, as `Set(self, ...)` already writes through a by-value `Buf` (buf.carbon:46-53) |

The slice-3 probes on v4 (`$X/s3` and `$Y/probes`):

| Probe | trunk | v4 |
| --- | --- | --- |
| s_write | `expression is not assignable` | RUN `1 20 21` |
| s_buf_write | `expression is not assignable` | RUN `15` |
| s_const | `expression is not assignable` | `expression is not assignable` |
| s_generic_write | `expression is not assignable` | RUN `27` |
| s_generic_const2 (`Fill(c, c[1])` with `c: Core.Slice(const i32)`) | `expression is not assignable` (at the definition) | RUN `2` (W-327) |
| s_generic_assign_const (`Set[T](p: T*, v: T)` at `T = const i32`) | RUN `1` | RUN `1` |
| s_generic_const (`Fill(c, 5 as const i32)`) | `expression is not assignable` (at the definition) | lowering FATAL `Missing constant value for call to comptime-only function` (toolchain/lower/handle_call.cpp:638), from `5 as const i32` |
| const_literal_plain (`let x: const i32 = 5 as const i32;`) | the same FATAL | the same FATAL; the nightly FATALs at its handle_call.cpp:598 |
| s_oob_write | `expression is not assignable` | `carbon: Core.Slice index out of bounds; terminating`, SIGABRT |
| s_read | RUN `10 4` | RUN `10 4` |
| s_span_write | `expression is not assignable` | RUN `18` |
| buf_generic_read, buf_let_write | RUN `6`; `expression is not assignable` | RUN `6`; RUN `5` |
| B.1 slices_write_through.carbon, B.2 cpp_span_write_through_diff.carbon | not run | PASS (`1 20 21 15 27`; `18`, its C++17 oracle agreeing) |

`5 as const i32` aborts lowering on trunk and on upstream's nightly with no
slice involved, so it is a pre-existing crash that slice 3 only makes reachable
in s_generic_const (trunk refuses the generic body earlier); it is filed W-325
(§1.17), found by this audit, not caused by it.

### §0.7 The language prerequisites of sum_types.md's `Match`, measured

sum_types.md at ac31fd198 (unchanged since the cut) declares the interface
(:107-117) and the class example (:137-165). Each construct, probed alone on
trunk and on the nightly (`$X/probes`):

| Construct (sum_types.md) | Probe | trunk | nightly |
| --- | --- | --- | --- |
| an interface nested in an interface (`interface BaseContinuation` in `Match`, :109-111) | nested_iface.carbon | accepted | accepted |
| a template associated constant (`let template Continuation: type;`, :113) | template_assoc.carbon | `phase keyword is not allowed on an associated constant` (toolchain/parse/handle_let.cpp:37-42, the comment "The binding is a checked generic by context, so no phase keyword is used.") | the same |
| a deduced binding of the constant's facet type (`fn Op[C: Continuation](self, continuation: C*)`, :114) with a NON-template `let Continuation: type` | v1.carbon | `` cannot implicitly convert non-type value of type `Continuation` to `type` `` and `` ... into type implementing `BaseContinuation` `` | not run |
| an interface declared in an impl (`impl as Match { interface Continuation {...} }`, :146-151) giving the constant its value | iface_in_impl.carbon, iface_in_impl2.carbon | `associated constant Continuation not given a value in impl of interface M` | the same |
| an impl-scope `let R: type = i32;` giving a constant its value (indexing.md:105-109's form) | impl_let.carbon | `associated constant R not given a value in impl of interface I` | the same |
| `extend Match.BaseContinuation;` in an interface (:148) | ext_iface.carbon | `unrecognized declaration introducer` | the same |
| its current spelling `extend require impls Base;` (details.md:1485-1497, p5337) with `-> R` naming the extended interface's constant | ext_req.carbon, ext_req2.carbon (`Self.(Base.R)` spelled out) | `` cannot convert type `Self` that implements `Cont` into type implementing `Base` `` | the same |
| `impl as M where .Continuation = OptCont {}` with `OptCont` an interface declared in the class (review A's where_cont.carbon, re-run by rev 2) | where_cont.carbon | accepted, runs | accepted, runs |
| a slot store of a non-`Copy` generic payload (`self.slot0 unsafe as T = value;` with `T: Core.Destroy`; review A's copy_slot.carbon) | copy_slot.carbon | `` cannot copy value of type `T` `` | not run |

So the class example cannot be written on either toolchain today. Rev 1 read
that as three missing language features and planned them (L1 template
associated constants, L2 impl members that give an associated constant its
value, L3 member access through `extend require impls`). Rev 2 reads upstream's
pages at ac31fd198 on each, quoting them (amended 2026-10-21, review fold: A-B1
/ B-B1):

-   **L1 is ruled out by upstream's explicit text elsewhere.**
    docs/design/README.md:1076-1078: "Associated constants are always checked
    generic bindings. This is not a contextual default: no other phase is
    possible for an associated constant, and so no phase keyword is allowed
    there." :3064-3067: "Since an interface is a compile-time entity, the
    binding is a checked generic binding by context; no phase keyword is
    allowed, so an associated constant cannot be made `template`."
    docs/design/generics/terminology.md:100-103 repeats it ("always checked
    generic bindings ... no other phase is possible for an associated constant,
    and so no phase keyword is allowed there"), in the section that ends "The
    syntax for checked and template parameters was decided in leads issue 6932"
    (:105-106; the link text, with its number). Upstream's parser implements
    exactly this: toolchain/parse/handle_let.cpp's `HandleAssociatedConstant`
    ("The binding is a checked generic by context, so no phase keyword is
    used.") diagnoses `generic`, `runtime` and `template` alike with
    `PhaseKeywordInAssociatedConstant`. Only sum_types.md:113 writes `let
    template Continuation: type;`, in a section transcribed from proposal
    p000157 (2020), whose own example passes the continuation interface as an
    interface parameter, `impl Matchable(MatchContinuation)`
    (p000157-design-direction-for-sum-types.md:408), under syntax it calls
    "**placeholder**" (:452-457: "This proposal assumes that Carbon will have
    support for defining and implementing generic interfaces, including
    interfaces that take interface parameters, and uses `interface`, `impl`,
    `method` etc. as **placeholder** syntax"). Rev 1's grep covered only the
    string "let template" and so missed README.md and terminology.md; and the
    details.md:4341-4354 text rev 1 cited for L1 ("Uses of `T` are then template
    constants") describes a function-scope `let template`, not an associated
    constant.
-   **L2 is a second spelling of a removed mechanism.** Accepted proposal
    p001013 ("Generics: Set associated constants using `where` constraints"),
    :79-82: "use a `where` clause as part of an `impl` declaration to specify
    associated constants and types instead of `let` declarations inside of the
    `impl` definition. In effect, it removes `let` declarations from `impl`
    blocks". details.md:2412-2413 spells it `extend impl as StackAssociatedFacet
    where .ElementType = T {`, and sum_types.md's own compiler-generated
    continuation does too (`extend impl as Optional.(Match.Continuation) where
    .ReturnType = ()`, :173). indexing.md:103-109's `let ElementType: type = T;`
    inside an impl, which rev 1 cited for L2, is the form p001013 removed, in an
    example the page has not rewritten (it also spells `like i64` and `bound
    self`, neither implemented). L2 is also unnecessary: where_cont.carbon
    (an interface declared in the class, `impl as M where .Continuation =
    OptCont {}`) runs on trunk and on the nightly. Rev 1's
    `ImplAssociatedConstantSetTwice` would also have duplicated upstream
    2b5f90cd7's `AssociatedConstantGivenDifferentValues` (2026-10-19).
-   **Without L1 the interface cannot be declared.** With a checked `let
    Continuation: type;`, `Continuation` names a type, not a facet type, so `fn
    Op[C: Continuation](self, continuation: C*)` makes `C` a value of an unknown
    type: v1.carbon's two errors. No spelling of `Match` satisfies both
    sum_types.md:113 and README.md:3064-3067 at ac31fd198, so upstream's own
    recorded direction for matching a class is, today, internally inconsistent.
    §1.4 decides what DR-1 does about it (stop, D-DR-22) and §1.17 why that is
    not an F-022 fork design.
-   **L3 is unaffected but moot.** `extend require impls` (details.md:1485-1497,
    p5337) is current syntax; with L1 out, nothing in DR-1 needs it.

### §0.8 Collisions with the held PRs (audit item 5)

Each held PR's own diff (merge-base with trunk to its head) over the files DR-1
changes, from `git diff --numstat`; then the source hunks of v3, which v4 keeps
byte for byte (prelude, the six toolchain files, min_prelude, the program;
`$X/dry_src.diff`), dry-run with `git apply --cached --check` into a temporary
index of each head. Rev 2 re-checked the heads on 2026-10-21 (CT-1's was then
79740957a) and the new test and program paths of v4, which no held PR has
(amended 2026-10-21, review fold: B-M6 / B-M10 / B-M12). Rev 3 re-checked them
(amended 2026-10-21, review fold: RR1-m1 / RR1-m4): CT-1's head is now
5c78c4086, past the mirror's 79740957a by 224ee2f8f and its fill (by `git
diff --numstat 79740957a 5c78c4086`, convert.cpp +20/-2, in `PerformAction` and
`Convert`, for a deferred `ref` argument and a temporary's specific type;
impl_lookup.cpp +15; sem_ir/expr_info.cpp +22; two goldens), and 230227264's
call.cpp and convert.cpp hunks (`$Z/c230_src.diff`, byte-identical in their
changed lines to v4's) dry-run clean with `git apply --cached --check` onto
b0822a744, 40a76ab81, 5661a35c8, 79740957a, 5c78c4086 and 3a6531157
(`$Z/logs/rr1_m1_m4_dryrun.txt`):

| Held PR (head) | DR-1 files it touches (numstat) | v4's source hunks onto it | Rule at DR-1's merge |
| --- | --- | --- | --- |
| PR 51 UA-2 (f96fe8a7a) | docs/design/slices.md +14/-6; records; new goldens check and lower slice/buf_field.carbon, which dump `Core.Buf` | apply | slices.md: both sides' text, the 0.1-limits bullet D-DR-7 replaces is UA-2-independent; the two buf_field goldens are not refilled: on m51 the gate was 1949 of 1949 before any refill, because they dump only `F` and `G`, which call `Make`, `Get` and the destroy witness and never subscript a `Buf` (amended 2026-10-22, implementation: stop-and-amend: the m51 red set; rev 3 predicted a refill, `Buf`'s impl changing); records keep both sides |
| PR 52 CM-1 (ea573f672), PR 54 EV-1 | records only | apply | none |
| PR 53 SAFE-1 (adaae4e35) | docs/design/slices.md +7; records | apply | slices.md both sides |
| PR 55 ST-1 (21307851a) | records; its operators/overloaded/string_indexing.carbon refill (+112 on its branch) | apply | string_indexing.carbon refilled at DR-1b's merge (both moved it): at M-b its two conflict blocks, CHECK lines only (`git merge-tree` of f774ee836 with 21307851a), take trunk's side, which is PR 55's text, and L-b refills it 2/2 (m55; amended 2026-10-22, re-review round 1: R1R2-m5) |
| PR 56 OP-1 (379f20f67) | core/prelude/types/optional.carbon +73/-2, docs/design/control_flow/loops.md +4 (the F-015 amendment after the cut's desugaring block, :116-118), docs/design/error_handling.md +8, docs/design/optional.md +582 | apply | W-323's new commit lands on PR 56's branch now (C.7, C.8); at DR-1a's merge, loops.md takes DR-1a's restored upstream subsections and C.9's amendment, and drops PR 56's amendment as C.7 corrected it, whose "The desugaring above is the text this page had at the fork's cut" is then false (§1.16); error_handling.md keeps both sides' amendments in date order |
| PR 57 OP-2 (628273444), stacked on PR 56 | optional.carbon +111/-8, loops.md +4, error_handling.md +8, optional.md +614 (PR 56's plus OP-2's), its check/testdata/slice/basic.carbon refill; gap row 78 moved to DONE; and (amended 2026-10-22, implementation: stop-and-amend: the m57 red set; rev 3 named slice/basic alone) convert.cpp +5/-2 and, in its refill 189baa262, six of DR-1a's nine goldens: check interop/cpp/range_for 583/1983, check slice/basic 49/224, lower array/iterate 237/240, for/bindings 161/164, for/break_continue 252/254 and for/for 254/256 | apply | PR 57's branch takes W-323's commit by a merge of PR 56's branch (a new merge commit, R32 (e)); at M-a, lower array/iterate, for/break_continue and for/for conflict in CHECK lines only, take trunk's side and are refilled at L-a, while check slice/basic, interop/cpp/range_for and lower for/bindings auto-merge and pass (measured on m57 and m57a, §1.16; amended 2026-10-22, implementation: stop-and-amend: the m57 red set); row 78's DONE text keeps trunk's DR-0 sentence as C.3 amends it (§1.16) |
| PR 58 DD-1 (fcee90d9b) | docs/design/pattern_matching.md +258/-4 | n/a | none: rev 2 edits no pattern_matching.md text (rev 1's amendment belonged to the stopped slice 1) |
| PR 59 VA-1 (b0822a744) | check/pattern_match.cpp +25, context.h +41, handle_binding_pattern.cpp +76, kind.def +19; call.cpp +194 and convert.cpp +114 (merge-base 3eb7f36f0 to the head; amended 2026-10-21, review fold: RR1-m1: rev 2 omitted these two) | apply; 230227264's call.cpp and convert.cpp hunks dry-run clean | call.cpp and convert.cpp: a three-way merge with no semantic interaction: VA-1's added lines create no `TemporaryStorage` return argument, pass no `return_arg_id` and add no `ConvertCallArgs` call, so 230227264's `return_size() > 0` test and its new `CARBON_CHECK` see no new caller; the other four files: none, DR-1 touches none of them |
| PR 60 SC-1 (40a76ab81) | context.h +17, handle_binding_pattern.cpp +27/-3, handle_let_and_var.cpp +14, kind.def +13; call.cpp +14 and convert.cpp +94/-7 (merge-base 8068151ed to the head; amended 2026-10-21, review fold: RR1-m1) | apply; 230227264's hunks dry-run clean | call.cpp and convert.cpp: a three-way merge with no semantic interaction, by the same test of SC-1's added lines; the other four files: none; fork/conformance/README.md's generated table conflicts in one block and is regenerated with `runner.py --update-readme-table` after the merge (amended 2026-10-22, re-review round 1: R1R2-m5) |
| PR 61 TP-1 (5661a35c8) and CT-1 (79740957a at the mirror, 5c78c4086 at rev 3, stacked on it) | handle_index.cpp +42/-13 (`PerformIndex` on a `LocId`, the `IndexAction` deferral), handle_loop_statement.cpp +10/-2 (a `RequireCompleteType` on the cursor's POINTER type for a template-dependent cursor), call.cpp and convert.cpp (TP-1's deferred conversions, in other functions than 230227264's), handle_match.cpp +2/-5, refutable_binding.{h,cpp} +35/-5, context.h +20, kind.def +1; goldens generic/template/for_range.carbon, generic/template/index.carbon (check), template/for_range.carbon (lower), interop/cpp/range_for.carbon | handle_index.cpp and handle_loop_statement.cpp conflict (both regions rewritten by TP-1); call.cpp and convert.cpp apply clean onto 5661a35c8, 79740957a and 5c78c4086 (rev 3's dry runs; rev 2's "with a three-way fallback" overstated it; CT-1's 224ee2f8f changes other functions of convert.cpp than 230227264's `ConvertCallArgs`) | resolved in DR-1a's and DR-1b's merge commits exactly as §2.1 and §2.2 spell them, then one composition commit (the template-dependent index deferral, §2.2) and the refill commits; measured on the mct mirror (§0.8.1) |
| PR 62 SV-1 (3a6531157) | refutable_binding.cpp +38 (the `std::optional`/`std::variant` conversion and the D-SV-7 `GetCoreOptionalView` branch), cpp/sum_type.{h,cpp} +1128, kind.def +8 (`CppSumType*` and `CoreOptionalNotMatchable`), core/prelude/types.carbon +1 (`prelude/types/cpp/sum`), docs/design/sum_types.md +91, convert.cpp elsewhere than 230227264's hunk | apply | W-322's removal-only commit lands on PR 62's branch now (§1.11, measured on the m62 mirror, §0.8.2); convert.cpp (23/7 on PR 62 at 0ef8a0334, the re-sweep below): a three-way merge with no semantic interaction, by PR 59's test of SV-1's added lines, which, in `ConvertAggregateElement`'s `diagnose` and `PerformBuiltinConversion`'s sum-type branch, create no `TemporaryStorage` return argument, pass no `return_arg_id` and add no `ConvertCallArgs` call (`git merge-tree` of f774ee836 with 0ef8a0334 merges the file clean); fork/conformance/README.md regenerated as for PR 60; the other files: none (amended 2026-10-22, re-review round 1: RR4-m5 / R1R2-m5; rev 3 read "DR-1's own diff touches none of PR 62's files") |

No held PR touches core/prelude/iterate.carbon, range.carbon,
operators/index.carbon, types/slice.carbon, types/buf.carbon,
core_identifier.def or cpp/operators.cpp, and none has a file at v4's new paths
(the two upstream `IndirectIndexWith` tests, A.1, A.2, B.1, B.2).

The overlap re-swept at DR-1b's stop (amended 2026-10-22, implementation:
stop-and-amend: the m51 and m57 red sets; amend4/logs/overlap_sweep.txt): the
44 paths DR-1a and DR-1b change (`git diff --name-only f68681114 4c358f94b`
over toolchain, core, docs and the programs), against each held head's own
diff from its merge-base with origin/trunk, fetched 2026-10-22. PR 57 touches
eight of them (loops.md, error_handling.md, convert.cpp and the six goldens of
its row above), PR 55 one (string_indexing), PR 51 and PR 53 slices.md, PR 56
at 894139b34 loops.md and error_handling.md, PR 59 and PR 60 call.cpp and
convert.cpp, PR 62 at 0ef8a0334 convert.cpp, PR 61 and CT-1 at 4a3220c11 the
files of their row, and PR 52, PR 54 and PR 58 none; PR 51's buf_field
goldens are new files outside the 44.

#### §0.8.1 The composition mirror on CT-1's head, measured

(Amended 2026-10-21, review fold: B-M6 / B-M2 / A-B3; rewrapped, RR1-m3.) The
mirror is `git worktree add --detach $Y/mct 79740957a` then `git apply --3way
$Y/v4_full.diff`: three files conflicted. handle_loop_statement.cpp and
handle_index.cpp were resolved as §2.1 and §2.2 spell it;
interop/cpp/range_for.carbon's 25 conflict blocks were all
CHECK lines (no source line in a block) and took CT-1's side for the refill.
A full build (CB_BUILD_ROOT=/dev/shm/dr1-fixer, 322 steps, -Werror, no other
ninja running at its start) and install.sh gave 0.0.0-0.dev+79740957a.dirty.

| Step | Result |
| --- | --- |
| gate before refill | 1959 passed, 4 failed: check generic/template/for_range, generic/template/index, interop/cpp/range_for, lower template/for_range |
| autoupdate | `generic/template/index.carbon` split `index_class_with_index_with` FAILED: `` unable to monomorphize specific `Get(bool)` `` with the note `` cannot access member of interface `Core.IndirectIndexWith(i32)` in type `Vec(bool)` that does not implement that interface `` |
| root cause | `fn Get[template T: type](v: Vec(T), i: i32) -> i32 { return v[i]; }`: `Vec(T)` is not opaque, so TP-1 indexes it at the definition, where the `IndirectIndexWith(i32)` lookup depends on the template parameter and is deferred to monomorphization; there, the probe's failure is an error, not the fallback to `IndexWith`. The choice between the two interfaces is per specific. |
| root fix (§2.2, the composition commit) | in the non-array arm, an operand or subscript of template-dependent type is indexed when the template is instantiated, through TP-1's own `AddDependentActionSplice<SemIR::IndexAction>`, as an opaque operand already is; one translation unit rebuilt |
| gate before refill, again | 1960 passed, 3 failed (the three goldens above but range_for) |
| autoupdate, pass 1 and pass 2 | `!!!`, then fixpoint |
| gate | 1963 passed, 0 failed (CT-1's head has 1959 manifest entries; plus v4's 4) |
| conformance | PASS 149, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 20 of 169 (115.2 s; CT-1's head has 167 programs, 20 SKIP); generics/templates_for_dependent_range and templates_dependent_index PASS |

The refills (numstat against CT-1's head): check generic/template/for_range
12/17 and lower template/for_range 137/137 (TP-1's pointer type and its
`require_complete_type` leave with the `AddrOf`, as rev 1 predicted), check
generic/template/index 16/41 (`v[i]` becomes an `IndexAction` splice resolved
to `Vec.as.IndexWith.impl.At(bool)` per specific), check interop/cpp/range_for
17/103. Probes on the mirror: tmpl_for (review A's) RUN `6`; tmpl_index_vec
(the split above as a program) RUN `7`, as on PR 61's install; tmpl_index_slice
(`fn First[template T: type](s: Core.Slice(T)) -> T { return s[0]; }`) RUN `4`,
where PR 61's install fails at monomorphization (`` cannot access member of
interface `Core.IndexWith(Core.IntLiteral)` `` in `Core.Slice(i32)`): with the
choice made per specific, the literal-subscript rule sees the concrete type.
Trunk and v4 cannot deduce `T` from `Vec(T)` or `Core.Slice(T)` at all
(`` cannot deduce value for generic parameter `T` ``), so the deferral exists
only on TP-1's base and lands with DR-1b's merge.

What the mirror does not show (amended 2026-10-21, review fold: RR1-m4). It is
CT-1's head of rev 2, 79740957a; CT-1 has since moved to 5c78c4086, in
convert.cpp among other files (§0.8), and 230227264's hunks still apply there.
It merged DR-1a and DR-1b at once, so L-a's refills above are the two PRs'
joint result, and DR-1a's merge onto CT-1 alone, the tree trunk has between
M-a and M-b, is unmeasured. §8 item 9 measures both shapes on CT-1's final head
before M-a.

Re-measured at implementation (amended 2026-10-22, implementation:
stop-and-amend: the mirrors' red sets). DR-1a alone on CT-1's 118fc1bc8, at
stage A: the gate 1956 passed and 3 failed, then 1959 of 1959; conformance
147/0/20 over 167. mct-b, DR-1b's 4c358f94b (which contains DR-1a) on CT-1's
4a3220c11 (records only over 118fc1bc8): handle_index.cpp resolved onto
`PerformIndex`, handle_loop_statement.cpp to DR-1a's side and range_for's
CHECK-only blocks to CT-1's; the gate 1959 passed and 4 failed, the four
goldens of the table's first row, since no autoupdate ran before C-b (the
table's 1960 and 3 came after an autoupdate had refilled range_for); C-b as
§2.2's block (+19/-1, `index_type_id` hoisted) left the same four;
autoupdate `!!!!`, then a fixpoint; the refills 12/17, 16/41, 17/103 and
137/137 as above; the gate 1963 of 1963; conformance 149/0/20 over 169,
bullets 48/0/8; the probes tmpl_index_vec `7`, tmpl_index_slice `4`, tmpl_for
`6` and f_slice `15` (stageB/logs). The pairwise mirrors on PR 51, PR 55 and
PR 57 are in §1.16 and §5.

#### §0.8.2 W-322's removal-only commit on a PR 62 mirror, measured

(Amended 2026-10-21, review fold: A-M3 / B-B2.) `git worktree add --detach
$Y/m62 3a6531157`, then `$Y/bin/w322_removal.py` and the test and program edits
of §2.5 (`$Y/m62_w322.diff`, numstat: refutable_binding.cpp 0/19,
cpp/sum_type.cpp 33/21, cpp/sum_type.h 2/33, kind.def 0/1,
match/core_optional_view.carbon 0/681 deleted,
match/fail_todo_core_optional.carbon 51 new, the SKIPped program 4/3,
conformance README 1/1). A full build (-j3, 323 steps, no warnings) and
install.sh gave 0.0.0-0.dev+3a6531157.dirty.

| Step | Result |
| --- | --- |
| gate before refill | 1949 passed, 1 failed: the new match/fail_todo_core_optional.carbon only; every std golden (interop/cpp/stdlib/optional, variant, fail_sum_types, sum_type_overload, lower interop/cpp/std_sum_types) passes unchanged, so F-020's bridge is intact |
| autoupdate, two passes | `!`, then fixpoint: its two splits pin `` semantics TODO: `match on unsupported scrutinee type` `` and `` semantics TODO: `refutable pattern binding on unsupported scrutinee type` `` |
| gate | 1950 passed, 0 failed (PR 62's head has 1950: one golden deleted, one added) |
| conformance | PASS 133, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 of 155 (70.3 s): PR 62's 134/0/21 with control_flow/match_core_optional_diff moved from PASS to a SKIP whose reason cites the removal (R16 (b)) |
| probes | sv_view (a `std::optional<int>` converted to `Core.Optional(i32)` and matched) and m_iflet now give the scrutinee TODOs, as on trunk; a `std::optional` scrutinee matched with `.Some(x: i32)` and `.None` (StdOptional's constant) RUN `5`, as on PR 62's install |

### §0.9 Conformance programs touched (audit item 6)

`grep -rlE "^\s*for \("` over fork/conformance/programs finds 13 programs
(control_flow/loops, control_flow/range_iter_diff,
interop/cpp_iterate_generic_adl_range, cpp_iterate_generic_member_range,
cpp_iterate_sentinel_range_for, cpp_range_adl_begin_end_iterate,
cpp_range_member_begin_end_iterate, string_view_str_to_cpp,
project/most_features_language_matrix, stdlib/iterate_interface, slices_basic,
slices_heap_buf, tuples_arrays_structs); `grep -rlE "Optional|HasValue"` finds 8
(control_flow/choice_generic_roundtrip_diff, match_sum_type_payload,
error_handling/optional_try, stdlib/iterate_interface, optional_basic,
optional_missing_ops, optional_pointer_niche, types/choice_generic_roundtrip);
the slice programs are 5 (interop/cpp_span_roundtrip_diff, cpp_span_view,
stdlib/slices_basic, slices_bounds_fail_stop, slices_heap_buf). Of these, only
stdlib/iterate_interface.carbon declares a `Next` (pointer cursor, :34) and
changes in slice 2 (§2.1); every other program passed unchanged on v2 and v3
(128/0/22 over 150 both), and on v4 (130/0/22 over 152, with B.1 and B.2).
The new programs and their oracles are in §1.14 and Appendix B; W-322's commit
on PR 62's branch SKIPs that branch's control_flow/match_core_optional_diff with
a cited reason (§1.11, B.3), and nothing else changes an existing program
(amended 2026-10-21, review fold: B-B2).

### §0.10 Upstream's direction register and the V-3 check (audit item 7, R32)

(Amended 2026-10-21, review fold: A-m1 / B-m2 / A-B1 / B-B1 / B-M7.) Upstream's
tip was ac31fd198 (2026-10-21 18:32 UTC) at rev 2 and is bc45989b2 (2026-10-21
19:10 UTC) at rev 3, the signed-off revision, which names it (amended
2026-10-21, review fold: RR1-m4). bc45989b2 changes toolchain/language_server
only (5 files, 35 lines added), and the command `git diff --shortstat
ac31fd198 bc45989b2 -- docs proposals core toolchain/check toolchain/parse
toolchain/lower toolchain/sem_ir` prints nothing, so every quote below, taken
at ac31fd198, is the text at bc45989b2. DR-1's implementation re-reads the tip
at each PR's opening. The register is selected by design page, as R32 (c)
asks: first every upstream
commit in c1e83b0b7..ac31fd198 that touches docs/design/, proposals/ or
core/prelude/ (`git log --format='%h %ad %s' c1e83b0b7..ac31fd198 -- docs/design
proposals core`, eight commits, all listed), then every commit touching a
toolchain file DR-1 changes or follows (handle_loop_statement.cpp,
handle_index.cpp, call.cpp, convert.cpp, core_identifier.def, cpp/operators.cpp,
refutable_binding.cpp, handle_match.cpp, pattern_match.cpp, thunk.cpp,
parse/handle_let.cpp and min_prelude), then the rest by subject. 98 commits are
in the range.

| Commit | Date | Subject | Mechanism change for DR-1 |
| --- | --- | --- | --- |
| df3cf9294 | 2026-10-07 | Adopt `ref` in `Core.Iterate.Next` (PR 7381) | design (loops.md), proposal p007381, prelude (iterate.carbon, range.carbon), loop checker, min_prelude: `Next(self, ref cursor: CursorType)` and loops.md's desugaring through `match ... case .Some(<pattern>)`; slice 2, and the `match` half is W-320's |
| 6d80ceb58 | 2026-10-16 | Add the `IndirectIndexWith` interface to the prelude (PR 7974) | prelude (index.carbon) and tests: slice 3 |
| 947c1eb52 | 2026-10-06 | Add a `Core.Array` class type, and make `array` refer to it. (PR 7892) | prelude and handle_index.cpp's array arm; UA-3's, not DR-1's (§1.3) |
| db87a84b6 | 2026-10-20 | Improve tests and clarify design for observe equivalence chains (PR 7987) | design (generics/details.md:3337-3349, `observe` inside an interface); no DR-1 mechanism: DR-1 declares no `observe` |
| f21c62524 | 2026-10-19 | Interface as base class use case supported (PR 8002) | design (classes.md, two lines); none for DR-1 |
| a045da8e6 | 2026-10-13 | Document the discrepancy between checking and execution for variadics (PR 7963) | design (variadics.md); none for DR-1 (VA-1's) |
| 59d53ab0a | 2026-10-09 | Use ASCII quotes in character literal examples in p1964 (PR 7938) | proposal text; none |
| a50feb64c | 2026-10-06 | Simplify proposal labels and fix GitHub label workflows (PR 7904) | proposal metadata; none |
| 309d3d63c | 2026-10-17 | Use `IndirectIndexWith.Ref` for subscripting when available (PR 7975) | handle_index.cpp, core_identifier.def, cpp/operators.cpp: slice 3 |
| 230227264 | 2026-10-09 | Only allocate return storage when the callee has a return parameter (PR 7886) | call.cpp, convert.cpp: calls to `ref`-return functions whose type might be initialized in place (§0.6.1 item 1); slice 3's B0 |
| 059ee7b9e | 2026-10-07 | Parse `-> ref T` as a primitive return form (PR 7911) | parse and convert.cpp: a `-> ref T` return is a primitive form, so its SemIR is `ref_form` then `type_component_of` where the fork emits `ref_tag` then `ref_form`; slice 3's `Ref` returns and 230227264's splits show the fork's form (§0.6.2), and behave the same; UA-3's |
| 0d3b606a5 | 2026-10-16 | Support calls to generic functions with deduced return types. (PR 7981) | call.cpp, sem_ir/expr_info.cpp; `-> auto` only, which DR-1 does not use; UA-3's |
| 4a8993af2 | 2026-10-07 | Fix "<unexpected>" inst when creating an InitializeAction (PR 7900) | formatter and typed_insts.h for template actions; no DR-1 mechanism; UA-3's |
| 3af25cc1b, bf5d2a2ac | 2026-10-15 | `-> auto` and `-> ref/var/val auto` deduced return types (PRs 7931, 7977) | none for DR-1 |
| 2c9739799, 7beb29f8b | 2026-10-15 | Render diagnostics through the terminal library; fallback loc for diagnostics on canonical insts (PRs 7683, 7967) | rendering only (the snippet difference of §0.6.2; the thunk's file-only location of §0.5); UA-3's |
| 62f1cc6a3 | 2026-10-11 | Rename `GenericClassType` to `ParameterizedClassType` (PR 7953) | a rename UA-3 takes |
| 1b0a5709e | 2026-10-06 | Initial support for fn expressions. (PR 7893) | none |
| 2b5f90cd7 | 2026-10-19 | Diagnose a witness table entry being set to multiple different values (PR 7996) | impl witness checking; rev 1's L2 would have duplicated it (§0.7); none for rev 2 |
| 6a0a1f3e8, b1de0e037, 24766e213, f0bae9637, e41862d55, fb7eff130, ac31fd198 | 2026-10-13..21 | the `IdentifiedFacetType` and impl-checking series (PRs 7924, 7926, 7930, 7937, 7943, 8004, 8008) | facet identification; none for rev 2 (rev 1's L3 lived here) |
| c3877cf70, 70c696e78 | 2026-10-21 | Extend plan-based definition synthesis with class-typed locals and destructuring (PR 8001), and its revert (PR 8009) | net zero |
| d87891f3a | 2026-10-15 | style (PR 7982) | none |

The texts that bear on `Match` and that rev 1's register missed are not in the
range: docs/design/README.md:1076-1078 and :3064-3067 and
generics/terminology.md:100-106 were in the tree before the cut (they blame to
7134e23f2, 2026-09-29, the boundary commit of this repository's history, which
also carries the parser rule), so a file-and-range filter could not find them;
R32 (a) asks for the page's current text at the tip, which §0.7 now quotes.
sum_types.md, pattern_matching.md, indexing.md, README.md,
generics/terminology.md and core/prelude/types/optional.carbon are unchanged
from the cut to ac31fd198 (`git diff --shortstat c1e83b0b7 ac31fd198` empty for
each); loops.md changed only in df3cf9294, details.md only in db87a84b6. The
V-3 check of R32 (a), with each page's current text quoted at ac31fd198:

-   **`Match` for classes.** sum_types.md:119-130: "`Continuation` must itself
    be an interface that extends `Match.BaseContinuation`, and its definition
    specifies the set of possible alternatives: each alternative is represented
    as a method of that interface. When compiling a proper pattern (or set of
    patterns that includes a proper pattern, as with the cases of a `match`)
    whose type is a sum type, the compiler generates an implementation of
    `Continuation` and passes it to `Match.Op`. ... The `Match.Op`
    implementation is required to call exactly one such method exactly once
    before returning. The compiler populates the `Continuation` method bodies
    with whatever code should be executed when the corresponding alternatives
    match." :224-227: "the compiler-generated continuation method bodies are not
    required to contain the code in the `case` body (or whatever code is in the
    scope of the pattern). For example, they might only store the parameter
    values and then return an index that identifies the `case` body to be
    executed." :132-133: "**TODO:** if Carbon has explicit support for tail
    calls, we should probably require that `Match.Op` invoke the continuation as
    a tail call." p000157:496-502 adds: "`Match`'s continuation parameter type
    must be generic rather than templated" (amended 2026-10-21, review fold:
    B-m1). And :107-117 declares the interface with `let template
    Continuation: type;`, which README.md:3064-3067 rules out (§0.7). DR-1
    implements none of this section: §1.4.
-   **Alternative patterns and expression patterns.** sum_types.md:189-199: "An
    expression pattern of type `T` has the form of an alternative pattern if `T`
    implements `Match`, and the expression consists of an optional expression
    that names `T`, followed by a designator that names a method of
    `T.(Match.Continuation)`, optionally followed by a tuple expression. If an
    expression pattern has that form, it may be matched using the mechanism
    above ... Both possible implementations must be well-formed (and this is
    enforced by the compiler), but it is unspecified which implementation is
    used to generate code." :214-222: "if an alternative takes no arguments, its
    pattern syntax is the same as its expression syntax ... If we had defined
    `Optional.None` as a factory function instead of a constant, `case
    Optional(i32).None() => ...` would be well-formed but `case
    Optional(i32).None => ...` would not be." For `Core.Optional`, whose
    factory is the function `fn None() -> Self` (upstream
    core/prelude/types/optional.carbon:30-32 at ac31fd198; the fork's :31-33),
    the empty alternative's pattern is therefore `.None()`, the reading §1.4
    records for W-320's resumption (amended 2026-10-21, review fold: B-m1 /
    A-m3).
-   **The `for` desugaring.** loops.md:109-122: "is desugared to a loop that
    manages the cursor and checks the optional return values:" followed by
    `while (true) { match (range.(Iterate.Next)(cursor)) { case .Some(<pattern>)
    => { <statements> } default => { break; } } }`, and :83 `fn Next(self, ref
    cursor: CursorType) -> Optional(ElementType);`. §1.2 follows the `ref`
    cursor; the `match` desugaring is W-320's and waits with it (§1.4), as
    upstream's own checker still calls `HasValue`/`Get` under its TODO (upstream
    toolchain/check/handle_loop_statement.cpp:237-238 at ac31fd198).
-   **Indexing.** indexing.md:36-41: "`IndirectIndexWith` is a subtype of
    `IndexWith`, and subscript expressions are rewritten to method calls on
    `IndirectIndexWith` if the type is known to implement that interface, or to
    method calls on `IndexWith` otherwise. `IndirectIndexWith` provides a final
    blanket `impl` of `IndexWith`, so a type can implement at most one of those
    two interfaces." :113-121's `Span` implements `IndirectIndexWith(like i64)`
    with `fn Ref(bound ref self, subscript: i64) -> ref T;`. Where indexing.md
    (an `IndexWith` with `At` and `Ref`; `IndirectIndexWith` requiring
    `IndexWith`) and upstream's prelude (index.carbon:9-28: `IndexWith` with
    `At` only, `IndirectIndexWith` with its own `ElementType`, a blanket impl
    restricted to `Copy` elements) differ, DR-1 follows the prelude and the
    checker at ac31fd198, which are later (6d80ceb58's message: "differs
    slightly from the design wording, which doesn't account for the copyability
    requirement"), carrying upstream's TODO "Use `IndexWith.Ref` when the
    operand is a durable reference" verbatim. indexing.md:29-34 sorts types by
    what subscripting a value expression yields: "If subscripting a value
    expression produces a value expression, as with an array, the type should
    implement `IndexWith`. If subscripting a value expression produces a
    durable reference expression, as with C++'s `std::span`, the type should
    implement `IndirectIndexWith`." `Core.Slice` is the second kind. So is
    `Core.Buf` as D-SL-6 already defines it: its storage is the heap block, not
    the `Buf` value, and `Set(self, i, v)` writes through a by-value `Buf`
    (buf.carbon:46-53); and with upstream's blanket `final` impl in the
    prelude, a `final` `IndexWith` impl for `Buf` no longer compiles while a
    non-`final` one regresses generic `b[i]` (§0.6.2). §1.3 keeps `Buf` on
    `IndirectIndexWith` (amended 2026-10-21, review fold: B-M7).
-   **Where upstream's design pages disagree among themselves on `Optional`.**
    loops.md:117-118 names neither a choice nor `Match`; sum_types.md:52-55
    declares `choice Optional(T: type)` and :135-165 shows "how `Optional` can
    be defined as a class" with `impl as Match`; pattern_matching.md:500-503
    declares `choice Optional(T: Type) { None, Some(T) }` and :526-527 says "a
    pattern of the form `Optional(T).None` is an expression pattern and is
    compared using `==`". DR-1 follows sum_types.md's class route, because it is
    the only text that keeps upstream's prelude identity at ac31fd198 (`class
    Optional(T: OptionalStorage)`, the placeholder, unchanged since the cut)
    while making `.Some(<pattern>)` work as loops.md requires; the two choice
    declarations are examples of `choice` (sum_types.md:46-56 introduces its
    example as "a sum type named `OptionalI32`", generalized "like class
    types"), and converting the prelude's class to a choice would be a second
    identity (DR-0's option (b), rejected there). pattern_matching.md:526-527's
    `==` sentence is the expression-pattern half of sum_types.md:197-199's "both
    possible implementations must be well-formed". The class route is still the
    one DR-1 follows; rev 2 records that the route cannot be expressed today
    (§0.7) and waits for upstream's resolution (§1.4).
-   **The V-3a register state.** Entering DR-1: (i) D-SV-7, (ii) D-SL-3, (iii)
    the pointer cursor (DR-0's block). Leaving it: (i) is resolved by W-322's
    removal-only commit on PR 62's branch (§1.11), (ii) and (iii) by DR-1b and
    DR-1a; two entries are added (amended 2026-10-21, review fold: A-B1 / B-B1 /
    B-M8): (iv) `Core.Optional` is not matchable, because upstream's own pages
    conflict on `Match.Continuation` (sum_types.md:113 against
    README.md:1076-1078 and :3064-3067, terminology.md:100-103 and upstream's
    parser, toolchain/parse/handle_let.cpp:27-46), work items W-320 (blocked)
    and W-324 (watching upstream's resolution at each weekly check); and (v)
    D-SL-17's literal-subscript rule, a fork spelling of indexing.md's `like
    i64` subscript (:103-121), work item W-326, blocked on `like` (§1.3). Rev
    1's (iv), "the fork accepts `let template`", is not added: rev 2 does not
    accept it.

### §0.11 Ids

The trunk ledger's highest id is W-125 plus W-320..W-323 (DR-0). DR-1 allocates
from the W-324..W-329 reservation DR-0 recorded (§1.17): rev 2 files W-324,
W-325, W-326, W-327 and W-329, and leaves W-328 reserved and unused for W-320's
resumption (amended 2026-10-21, review fold: A-B1 / B-B1 / B-M8). The re-scan
of every origin ref's and worktree's ledger for `W-32[4-9]` is repeated at the
records commit, the CT-1 §0.11 command widened to that pattern, and recorded
there. F-022 is not minted (§1.17).

## §1 Design

Each decision is auto-adopted under R29(a), recorded by the plan's records
commit in the decision-log entry "DR-1" (Appendix C.1), and veto-able after the
fact; each states the upstream text it follows and its break condition.

### §1.1 Slice order and PR shape (D-DR-5)

(Amended 2026-10-21, review fold: A-M4 / B-M5 / A-B1 / B-B1.) Two PRs, each
one milestone feature (R29(b)), each on its own branch with one base:

| PR | Slice | Work items | Branch and base | Size, measured |
| --- | --- | --- | --- | --- |
| DR-1a | slice 2: the `ref` cursor | W-321 | claude/carbon-fork-0-1-dr (this branch), cut from trunk f68681114; PR base trunk | v2: 5 source files, 4 test sources, 1 program, 9 goldens |
| DR-1b | slice 3: element access through `IndirectIndexWith` | W-109 | claude/carbon-fork-0-1-dr-idx, cut from DR-1a's branch head after its records commit A-R; PR base claude/carbon-fork-0-1-dr (stacked, as PR 57 is on PR 56) | v4: 230227264's code (2 files), 6 prelude and toolchain files, 13 refills, 4 new goldens, 2 programs |

Both are on trunk's base, as D-DR-1 says. Slice 2 goes first because it is the
smaller, fully measured change and DR-1b's fill was measured on top of it (v4
contains both; check/testdata/slice/basic.carbon moves in both). DR-1b is
stacked rather than cut from trunk so that the shared golden is filled once,
in order. W-322's and W-323's commits are not DR-1 PRs: they are new commits on
PR 62's and PR 56's branches, made now (§1.11, §1.16). Slice 1 (W-320) has no
PR: §1.4. Rev 1's DR-1c and DR-1d, and its branch
claude/carbon-fork-0-1-dr-match, are withdrawn with it. Break condition: a
review finds DR-1b needs a change to DR-1a's files; DR-1b is then re-cut from
trunk with DR-1a merged into it by a merge commit, never a rebase.

### §1.2 Slice 2: the `ref` cursor (D-DR-6)

`Core.Iterate.Next` becomes `fn Next(self, ref cursor: CursorType) ->
Optional(ElementType);` (upstream core/prelude/iterate.carbon:17 at ac31fd198),
its nine impls take `ref cursor` with `*cursor` read as `cursor` and `cursor->0`
as `cursor.0` (upstream :24-31, :74-81, range.carbon:20-28), min_prelude's
declaration likewise (upstream
toolchain/testing/testdata/min_prelude/parts/iterate.carbon:19), and the loop
checker passes `cursor_var_id` itself instead of an `AddrOf` (upstream
handle_loop_statement.cpp:225-234). Re-expressed, not cherry-picked: df3cf9294's
iterate.carbon hunk lacks the fork's `Slice(T) as Iterate` impl
(iterate.carbon:86-98, SL-1) and its handle_loop_statement.cpp hunk deletes a
fork comment the fork's text differs in, and its goldens are upstream's, whose
context the fork has already renamed (§0.6's table); the toolchain lines are
upstream's byte for byte. The thunk failure of §0.5 needs no thunk.cpp change:
it is the interface/impl mismatch this slice removes. Break condition: upstream
changes `Core.Iterate.Next`'s signature again (proposal 5389's extended-type
rework, loops.md:96-97's TODO); the slice follows it. At DR-1a's merge after
CT-1, handle_loop_statement.cpp takes this side: TP-1's `RequireCompleteType`
on the cursor's pointer type, and its `type_completion.h` include, leave with
the `AddrOf` they served, since the cursor variable itself is what `Next` now
binds; measured on the mct mirror (§0.8.1: TP-1's template `for` goldens
refill, its template `for` programs pass, review A's tmpl_for prints `6`;
amended 2026-10-21, review fold: B-M6 / A-B3).

### §1.3 Slice 3: `IndirectIndexWith` and `Slice`/`Buf` (D-DR-7)

The prelude's index.carbon becomes upstream's at ac31fd198 verbatim (§0.5;
unchanged since 6d80ceb58); subscripting tries `IndirectIndexWith(I).Ref`
without diagnosing and falls back to `IndexWith(I).At` with diagnostics, under
upstream's TODO "Use `IndexWith.Ref` when the operand is a durable reference"
(309d3d63c, re-expressed in the fork's `default:` arm, because upstream's
handle_index.cpp also carries 947c1eb52's `Core.Array` arm, which UA-3 brings);
`IndirectIndexWith` and `Ref` join core_identifier.def and cpp/operators.cpp
maps `IndirectIndexWith` to no C++ operator (309d3d63c verbatim).

230227264 (amended 2026-10-21, review fold: A-M5 / B-M13). Its code is taken by
`git cherry-pick -x -n 230227264`, after which its two goldens are restored to
the fork's (`git checkout HEAD --` on check and lower
testdata/function/call/form.carbon), upstream's three new split sources are
added to each (Appendix A.0) and autoupdate refills them; no CHECK line is
resolved by hand (R16). The commit keeps upstream's subject and body and the
`(cherry picked from commit 2302272643c11437c56e27d74ab06739ebb03c78)` line,
names upstream's author in its body ("Upstream author: David Blaikie, PR
7886"), and is authored and committed under the fork's rule (author jmann345,
committer Claude, the session trailers). Measured fill: §0.6.2.

Upstream's tests come with the mechanism (amended 2026-10-21, review fold:
A-m2): check/testdata/operators/overloaded/indirect_index_with.carbon and
lower/testdata/index/indirect_index_with.carbon, their sources taken from
ac31fd198 and their CHECK lines this tree's autoupdate's (§0.6.2), including
the `ref` return of a non-`Copy` element.

`Core.Slice(T)` and `Core.Buf(T)` implement `final ... as IndirectIndexWith(i64)
where .ElementType = T` with a bounds-checked `Ref` returning `ref T`
(indexing.md:113-121's `Span` shape), and their `IndexWith(i64)` comes from the
blanket `final` impl (their `T` is `Copy`), so `s[i]` and `b[i]` are durable
references: `s[i] = v` and `b[i] = v` write through (W-109), reads are
unchanged (`s_read`: `10 4`), and a C++ `std::span` sees the write
(`s_span_write`: `18`). `Buf` takes `IndirectIndexWith`, not `IndexWith`
(amended 2026-10-21, review fold: B-M7), because indexing.md:29-34 sorts a type
by what subscripting a VALUE expression of it yields, and D-SL-6 already makes a
`Buf` value name storage outside itself: `Set(self, i, v)` writes through a
by-value `Buf` (buf.carbon:46-53, "`self` is by value: the storage is the heap
block, not the `Buf` object"), which is indexing.md's `std::span` category, not
its array category. The array category's write path, `IndexWith.Ref` on a
durable reference, is upstream's TODO, and the alternatives were measured
(§0.6.2): a `final` `IndexWith` impl for `Buf` beside upstream's blanket
`final` impl fails every prelude compile with `FinalImplOverlapsDifferentFile`,
and a non-`final` one regresses generic `b[i]`, which D-SL-18 made `final` for.
`Buf.Set` (buf.carbon:48-53) stays: a method, not a second spelling of an
upstream mechanism, and existing programs call it.

A behavior change inherited from upstream (amended 2026-10-22,
implementation-review fold: DR1B-m3). Under upstream's index.carbon a user's
`final impl X as Core.IndexWith(...)`, which trunk 0bdce60a5 accepts (the DR-1b
implementation review's p15 prints `6`), is rejected with
`FinalImplOverlapsDifferentFile` and the note at index.carbon:19: the blanket
`final` impl's type structure overlaps every other `final` `IndexWith` impl,
`Buf`'s above being one instance. Upstream rejects it the same way and
index.carbon is upstream's byte for byte, so it is not a drift, and the
toolchain does not work around it (R32); a non-`final` user impl is unaffected
(that review's p09 runs). A.1's `fail_final_index_with_overlap` split pins it,
and §7.1's R-7 records it.

The fork's literal-subscript rule (D-SL-17, handle_index.cpp:108-189 at the
round 2 fix 8deb75262; the cite read :107-157, written at rev 1, until
corrected 2026-10-22, re-review round 2) probes `IndirectIndexWith(i64)`
before `IndexWith(i64)`, so a type with only `IndirectIndexWith(i64)` and a
non-`Copy` element still converts a literal subscript. It also leaves a
literal as written for an operand with its own
`IndirectIndexWith(Core.IntLiteral)` impl, which the blanket `IndexWith` impl
does not cover for a non-`Copy` element, so the impl a literal subscript calls
no longer depends on whether the element is `Copy` (amended 2026-10-22,
implementation-review fold: DR1B-M1; handle_index.cpp:155-166 at the fold,
:163-174 at 8deb75262, the probe placed after the `Core.Int` lookup so that no
existing golden moves).
Two consequences, recorded by round 1 of the fold's focused re-review (amended
2026-10-22, re-review round 1: RR1-1-F1 / R1R2-m1). A blanket `impl forall [U:
Core.ImplicitAs(i64)] X as Core.IndirectIndexWith(U)` now answers the literal
probe, so `h[0]` dispatches its `U = Core.IntLiteral` specific as written, as
upstream's dispatch, which has no literal rule, does; a `Ref` that converts its
subscript at run time then aborts lowering with W-325's FATAL, "Missing
constant value for call to comptime-only function" at lower/handle_call.cpp:638
(that round's q08, a non-`Copy` element, and its `Copy` twin q08b). No
reference toolchain accepts the program: trunk and the nightly have no
`IndirectIndexWith`, and they abort the same way on the `IndexWith(U)` analog
q07, as DR-1a does, and on q09, a generic call deduced at `Core.IntLiteral`. And
an operand whose only literal impl is `IndirectIndexWith(Core.IntLiteral)`
dispatches as written and succeeds, while its file's SemIR gains the
`Core.IndexWith` and `Core.Int` import_refs that the rule's first probe and its
`Core.Int` lookup load (that round's fp.carbon, which has neither without the
subscript); upstream loads neither. The rule's comment at
handle_index.cpp:141-150, which said the dispatch then still diagnoses, was
reworded by round 2's fixer: at 8deb75262 it says (:146-158) that the file
gains both import_refs whether the dispatch then diagnoses or succeeds as
written, and the rule's statement (:114-125) names the blanket
`IndirectIndexWith(U)` case and its abort (amended 2026-10-22, re-review
round 2: R1R2-m1 / RR1-1-F1).
D-SL-17 is itself a fork spelling of indexing.md's `like i64`
subscript (`impl as IndirectIndexWith(like i64)`, indexing.md:113-121), which
upstream's toolchain does not implement (no `like`, PR 56's W-178). W-109's
notes said it "yields to the specified rewrite" when W-109 lands; it cannot
yield before `like` exists, so rev 2 files it as V-3a register entry (v) with
work item W-326, blocked on `like`, before W-109 is discharged (amended
2026-10-21, review fold: B-M8). D-SL-3 is retired by its own break condition
("`IndirectIndexWith`/`ref`-returning methods land in the toolchain;
`Core.Slice` then switches to indexing.md's `Span` shape and the pin is
deleted"; fork/slices/plan.md:233-236), its pin `fail_write_through` deleted
(measured). `Slice(const T)` stays non-writable where the element type is known
(`s_const`: `expression is not assignable`); a generic body writing `s[i] = v`
instantiated at a `const` element writes (`s_generic_const2`), as a generic `*p
= v` does through `const T*` on trunk and on upstream's nightly
(`s_ptr_const_write`: `7` on both): the root is the per-specific `const` check
that the language's implementation lacks, filed W-327 and pinned by A.1's
`generic_write_const_element` split (amended 2026-10-21, review fold: B-m4), and
it is not a reason to keep `Slice` read-only (R32 (d) names "a read-only index
where upstream added IndirectIndexWith" as a drift).

At DR-1b's merge after CT-1 (amended 2026-10-21, review fold: B-M6):
handle_index.cpp's conflict is resolved onto TP-1's `PerformIndex(context,
loc_id, ...)` (`PerformIndexOperator` takes a `SemIR::LocId`, and the default
arm returns its result instead of pushing it), and one composition commit then
makes the IndirectIndexWith-or-IndexWith choice per specific for an operand or
subscript of template-dependent type, through TP-1's `IndexAction`: a lookup
that depends on a template parameter is resolved at monomorphization, where a
failed `IndirectIndexWith` probe is an error, not the fallback (§0.8.1, the
root cause of PR 61's `index_class_with_index_with` failing on the mirror). §2.2
spells both. Break condition: upstream's `Core.Slice` proposal (PR 7536) or
proposal 5389 reworks these interfaces, or upstream implements `IndexWith.Ref`
for durable operands; slice 3 follows, and `Buf` moves to whichever category
upstream's own owning buffer takes.

### §1.4 Slice 1: stopped at the plan (D-DR-8, D-DR-22)

(Rewritten 2026-10-21, review fold: A-B1 / B-B1.) Rev 1's D-DR-8 planned three
language features so that sum_types.md's `Match` could be written: L1 template
associated constants, L2 impl members that give an associated constant its
value, L3 member access through `extend require impls`. §0.7 reads upstream at
ac31fd198 on each. L1 contradicts docs/design/README.md:1076-1078 and
:3064-3067, generics/terminology.md:100-103 and upstream's parser; L2 is the
mechanism accepted proposal p001013 removed, and is not needed (`where
.Continuation = ...` works today). Implementing either would be a new drift
under R32: the V-3a register is a queue of drifts to fix, not a licence for new
ones, and V-3 (as amended by V-3a) already vetoes a decision that contradicts
upstream's accepted proposals or recorded leads' direction. Without L1,
sum_types.md:107-117's interface cannot be declared at all (§0.7, v1.carbon),
and no spelling satisfies both sum_types.md:113 and README.md:3064-3067: on
`Match`, upstream's recorded direction is internally inconsistent today.

D-DR-8 (rev 2): DR-1 implements none of L1, L2, L3. D-DR-22's stop rule ("if L1,
L2 or L3 cannot land, slice 1 stops and is never re-spelled") fires at the plan,
before any slice-1 code: W-320 is blocked on W-324, which watches upstream's
resolution of the conflict and is checked at each weekly upstream check (R32
(b)); `Core.Optional` stays as trunk has it, unmatchable, with `HasValue`/`Get`
and `?`; the `for` loop keeps calling `HasValue`/`Get`, which is also what
upstream's own checker does under its `.Some(pattern_id)` TODO (upstream
handle_loop_statement.cpp:237-238 at ac31fd198), so the fork's toolchain is
not a second spelling there. What the stop does not leave in place is the
fork-local spelling that already exists: PR 62's D-SV-7 view is still removed
before PR 62 merges (§1.11), and PR 56's records are still corrected (§1.16).
Not implementing upstream's design is not a drift under R32 (d); a fork
mechanism that respells it is, and DR-1 adds none. Break condition (the
resumption): upstream resolves the conflict, by changing sum_types.md's `Match`
declaration, by admitting a template associated constant (README.md,
terminology.md or the parser), or by implementing `Match` or its loop TODO by
any mechanism; W-320 is then re-planned from upstream's resolution, starting
from rev 1's §1.5-§1.12 (commit 1e46ffd94) under the constraints RC-1..RC-12
below, which carry the reviews' slice-1 findings so that the re-plan does not
repeat them.

-   **RC-1 (A-B1, B-B1).** No `let template` on an associated constant and no
    impl member that sets one; an impl sets `Match.Continuation` by `where`
    (where_cont.carbon, §0.7). F-022 is minted only if upstream's resolution
    leaves a surface rule open.
-   **RC-2 (A-B2, B-M3).** A continuation that stores an alternative's parameter
    by copy needs `Copy`: copy_slot.carbon on trunk gives `` cannot copy value
    of type `T` `` for `T: Core.Destroy`, and the `Try` impl's bound `T:
    Destroy & OptionalStorage` (optional.carbon:69) does not imply `Copy`. A
    `match`-bodied `Try` must bind without a copy or change that bound, and a
    bound change amends DR-0's "signature kept" by a dated record. D-DR-13 is
    withdrawn now: DR-1 does not rewrite the `Try` body, since the sketch it
    followed is the fork's own page (docs/design/error_handling.md has no
    upstream copy at ac31fd198), not upstream direction.
-   **RC-3 (A-B3, B-M2).** Routing `for` through `Match` must keep TP-1's
    template `for` loops: a `Next` result of opaque template-dependent type
    needs a dependent refutable form. Measured: review A's tmpl_for prints `6`
    on PR 61's install and on the mct mirror, while tmpl_match_dep gives the
    scrutinee TODO on both; PR 61's generic/template/for_range goldens and
    generics/templates_for_dependent_range are the regression set, and §5
    counts from CT-1's head (167 programs, §0.8.1).
-   **RC-4 (A-M1, B-M1).** The min_prelude has no `Match` and its `Optional`
    (toolchain/testing/testdata/min_prelude/parts/optional.carbon:19) no `impl
    as Match`; a `for` desugaring through `Match` first gives the min_prelude
    both, and the eight min_prelude `for` goldens (check for/basic and pattern,
    interop/cpp/range_for, slice/basic; lower array/iterate, for/for,
    break_continue, bindings) are its predicted refills.
-   **RC-5 (A-M2, B-M4).** A nested alternative pattern on a `Match` payload
    (`case .Some(.Some(x: i32))`) needs a continuation per sub-scrutinee, built
    in the dominated payload block, and its own exhaustiveness keys; trunk has
    no lane for an alternative pattern on a payload (review A's
    nested_choice.carbon: `` semantics TODO: `choice alternative payload that is
    not trivially copyable and destructible` ``). Unspecified, it is OUT with a
    residue.
-   **RC-6 (A-m3, B-M8).** The empty alternative's pattern is `.None()` while
    the prelude's `None` is the function `fn None() -> Self`
    (sum_types.md:214-222; upstream optional.carbon:30-32); D-DR-1's and W-320's
    "`.None`" carry a dated amendment saying so (C.1, C.2).
-   **RC-7 (A-m4).** The continuation's slot is destroyed per evaluation,
    including on `break` and `continue` out of a `for` or `while let`; the extra
    copy per iteration is measured; rev 1's "a class with no member of that
    name" parens case is dropped: sum_types.md:197-198 has the compiler enforce
    that the expression half is well-formed, which it is not without the
    member, and :210-212 says such a type's expression patterns "will fail to
    compile".
-   **RC-8 (B-m3).** Qualified alternative patterns
    (`Core.Optional(i32).Some(x: i32)`, pattern_matching.md:518-523) are decided
    IN or OUT.
-   **RC-9 (B-M11).** Every program is written out in full, with a counting
    `Copy` program for the slot copy and a null-pointer call, and every new
    mechanism has a mutant that a named golden or program catches.
-   **RC-10 (B-M12).** The doc texts are written out: sum_types.md's
    amendment, error_handling.md's `case .None` and "applies verbatim once W-058
    makes `Optional` a choice" (C.11 corrects the latter now), optional.md's
    `.None` passages (C.8 now).
-   **RC-11 (B-B2).** Land-time commits assume nothing about whether PR 56 or
    PR 62 has merged; they target whichever branch holds the text.
-   **RC-12 (A-M4, B-M5).** One branch and one base per PR; a language
    prerequisite lands with its first consumer (R29(b)); a base other than
    trunk's is recorded as an amendment to D-DR-1.

### §1.5 The `Match` mechanism and its SemIR (D-DR-9)

Withdrawn with slice 1 (§1.4); rev 1's text (commit 1e46ffd94) is the
resumption's starting point, under RC-1, RC-2, RC-5 and RC-7.

### §1.6 `Core.Optional`'s `impl as Match` and the `.None()` spelling (D-DR-10)

Withdrawn with slice 1 (§1.4), except the reading RC-6 records: `.None()` while
`None` is a function.

### §1.7 Refutable forms on a `Match` class (D-DR-11)

Withdrawn with slice 1 (§1.4); RC-5 and RC-8 bind its resumption.

### §1.8 The `for` desugaring through `Match` (D-DR-12)

Withdrawn with slice 1 (§1.4); RC-3 and RC-4 bind its resumption. DR-1's `for`
change is slice 2's alone.

### §1.9 The `Try` body (D-DR-13)

Withdrawn (§1.4, RC-2): the `Try` body keeps `HasValue()`/`Get()`.

### §1.10 Templates and generics (D-DR-14)

Withdrawn with slice 1 (§1.4); RC-3 binds its resumption.

### §1.11 C++ interop and D-SV-7's retirement (D-DR-15)

(Rewritten 2026-10-21, review fold: A-M3 / B-B2.) The `std::optional` and
`std::variant` mapping (F-020: `Core.CppCompat.StdOptional(T)` and
`StdVariant<N>` choices, converted by value through the C++ accessors, and the
one-step conversions between a C++ `std::optional<T>` and `Core.Optional(T')`)
is not the drift and stays: a `std::optional` scrutinee is still converted to
`StdOptional` and matched as that choice, with `.None` (its constant). D-SV-7,
the view that matches a `Core.Optional(T)` scrutinee as `StdOptional(T)`, is a
second spelling of the `Match` route (R32 (d)) and is removed by a new commit
on PR 62's branch, made now and before PR 62 merges (R32 (e)); with slice 1
stopped, nothing replaces it, so a `Core.Optional(T)` scrutinee gets the
scrutinee TODOs, as on trunk. This amends DR-0's D-DR-2 ("retired by DR-1 slice
1 ... matches `Core.Optional(T)` through it and removes the view"): the removal
no longer waits for a replacement, because R32 (e) does not let PR 62 land
carrying the drift. The commit, measured on the m62 mirror (§0.8.2):

-   **Removed.** `CheckRefutableScrutinee`'s `else if (auto view =
    GetCoreOptionalView(...))` branch (refutable_binding.cpp, 19 lines);
    `DiagnoseCoreOptionalNotMatchable` (cpp/sum_type.cpp and its declaration);
    `CARBON_DIAGNOSTIC_KIND(CoreOptionalNotMatchable)` (kind.def); and
    match/core_optional_view.carbon, replaced by
    match/fail_todo_core_optional.carbon (Appendix A.3), whose two splits pin
    the scrutinee TODOs for `match` and `if let` on `Core.Optional` until W-320.
-   **Kept for F-020's bridge.** `GetCoreOptionalPayload`,
    `ClassifyCoreOptional`, the `CoreOptionalView` struct and
    `GetCoreOptionalView`, which `TryConvertCppSumType` (PR 62's
    cpp/sum_type.cpp:854, :874, :908-911) and `MapCarbonSumTypeToCpp` (:937)
    call. They move from cpp/sum_type.h into cpp/sum_type.cpp (no other file
    uses them once the branch is gone), `GetCoreOptionalView` becomes `static`,
    and the status `Matchable` is renamed `Mapped`, with the comments that said
    "matchable" saying "mapped".
-   **The `std::optional` mapping gate, re-derived.** It is unchanged in
    substance: a `Core.Optional(T)` converts to and from a C++
    `std::optional<T'>`, and is offered to C++ overload resolution as one,
    exactly when `T` is concrete, complete and an SF-6 choice payload type (so
    that `StdOptional(T)` can be formed) and, for the Carbon-to-C++ direction,
    not a pointer (a `Core.Optional(T*)` keeps the nullable-pointer mapping).
    That was D-SV-7's "matchable" condition because the view and the bridge
    shared one type; it is now named for the bridge alone. Every std golden
    passes unchanged on the mirror.
-   **PR 62's program.** control_flow/match_core_optional_diff.carbon, written
    against the view, gets a `// SKIP:` line citing the removal and W-320
    (Appendix B.3, R16 (b)), and its three empty arms are respelled `case
    .None()` for the `Match` route (RC-6); the conformance README's generated
    table follows (`runner.py --update-readme-table`). PR 62's conformance moves
    from 134/0/21 to 133/0/22 over 155 (§0.8.2).
-   **Records on PR 62's branch, in the same commit (amended 2026-10-21,
    review fold: RR1-M1).** PR 62's sum_types.md section on the view gains
    Appendix C.6's dated amendment; its gap row 68 text, its plan's §1.7 and the
    decision log's SV-1 entry gain the dated notes of C.6. PR 62's ledger has no
    W-177 and no W-320..W-323 (its branch predates DR-0: fd290b6e6 is not an
    ancestor of 3a6531157), so the commit writes neither there: W-322 is
    discharged in trunk's ledger only (C.2), and W-177's correction is made in
    PR 56's ledger by W-323's commit (C.7). What it amends instead are PR 62's
    own records that would land false: its plan's §1.16 W-177 paragraph and
    Appendix C.5, the land-time narrowing note that would append the view to
    W-177 with the deleted golden and the SKIPped program as evidence; its §3
    item 8 land-time F-M items that refill the deleted golden and add a `bool`
    payload to it and a `bool` leg to the SKIPped program; and W-280, whose
    `Core.Optional` half is moot and whose evidence names the deleted golden
    (C.6).

Break condition: D-DR-2's (upstream designs a view-based route for matching
`Core.Optional`); or PR 62 is closed without merging, and the removal then
applies to wherever D-SV-7 lands.

### §1.12 Diagnostics (D-DR-16)

(Amended 2026-10-21, review fold: A-B1 / B-B1.) DR-1 adds no diagnostic kind:
rev 1's five new kinds, three reused texts and the narrowed
`PhaseKeywordInAssociatedConstant` belonged to slice 1 and are withdrawn with it
(rev 1's `ImplAssociatedConstantSetTwice` would have duplicated upstream
2b5f90cd7's `AssociatedConstantGivenDifferentValues`). W-322's commit removes
PR 62's `CoreOptionalNotMatchable`. Slices 2 and 3 change no diagnostic text;
the existing `MissingImplInMemberAccess` and `AssignmentToNonAssignable` cover
their failure splits. Break condition: none.

### §1.13 Goldens (D-DR-17)

(Amended 2026-10-21, review fold: A-M5 / B-M13 / A-m2 / B-m4 / A-M4.) All CHECK
lines come from autoupdate (R16); the sources are Appendix A. DR-1a: the nine
refills of §0.6 and no new file. DR-1b: B0F refills the two existing
function/call/form.carbon goldens after their three new splits are added (+172
and +103 lines measured on v4; not "2 new" as rev 1 said); B1F refills the
eleven of §0.6.1 with check and lower slice/buf (25/22 and 402/341), deletes
`fail_write_through`, and fills four new files: upstream's two
`IndirectIndexWith` tests and A.1 (with the W-327 pin split) and A.2. Each
golden is added in the commit whose code makes it pass (rev 1's A.3, which
needed later commits, is withdrawn with slice 1). At the merges after CT-1: the
refill commits of §1.16 (check generic/template/for_range and index,
interop/cpp/range_for, lower template/for_range, measured on the mct mirror;
PR 55's string_indexing and PR 57's lower array/iterate, for/break_continue
and for/for, measured on the pairwise mirrors at DR-1b's stop, where PR 51's
buf_field goldens and PR 57's check/slice/basic did not move; amended
2026-10-22, implementation: stop-and-amend: the m51 and m57 red sets). Break
condition: a fill that does not reach a fixpoint in two
passes, or that changes a golden this section does not name; the plan is
amended with the measured set before the commit.

### §1.14 Programs (D-DR-18)

(Amended 2026-10-21, review fold: B-M11 / A-m4.) Hand-derived EXPECTs, Appendix
B. DR-1a: stdlib/iterate_interface.carbon rewritten (§0.9). DR-1b:
stdlib/slices_write_through.carbon (B.1: slice writes, a `Buf` write through
`b[i]` and through `Set`, a generic fill; the bounds fail-stop is already pinned
by slices_bounds_fail_stop) and interop/cpp_span_write_through_diff.carbon with
its `.diff.cpp` (B.2, DIFF-1), both PASS on v4 and on the mct mirror. No SKIP
moves on trunk; on PR 62's branch W-322's commit turns one PASS into a cited
SKIP (B.3). Rev 1's `Match` programs (its B.3 to B.5) are withdrawn with
slice 1. Break condition: a program whose output differs from its hand-derived
EXPECT; the EXPECT is re-derived from the design, never from the toolchain (R16
(d)).

### §1.15 Docs and records (D-DR-19)

(Rewritten 2026-10-21, review fold: B-M9 / B-M10 / B-M12 / A-m3 / B-M8.)
Design pages, each edit a dated amendment block, never a rewrite of upstream
text. docs/design/control_flow/loops.md at DR-1a: upstream's ac31fd198 page,
df3cf9294's whole edit with the "`Iterate` interface" and "Loop desugaring"
subsections in place of the fork's "Ranged-for for user-defined types"
subsection (§2.1), keeping the fork's `while let` amendment, and C.9's
amendment follows the desugaring block (amended 2026-10-21,
implementation-review fold: DR1A-m1).
docs/design/slices.md at DR-1b: C.10 replaces the read-only 0.1-limits bullet.
The page's own interface listings, indexing paragraph and bounds and iteration
sentences are rewritten to the same design, and the amendment block says so in
a dated sentence (amended 2026-10-22, implementation-review fold: DR1B-m2).
Round 1 of the fold's focused re-review found two more lines (amended
2026-10-22, re-review round 1: R1R2-m3): the Heap buffers bullet on `Set`
(slices.md:241-244 at f774ee836) and the rejected alternative "A `Slice.Set`"
(:434); both are rewritten and the dated sentence names them (C.10).
docs/design/error_handling.md at the records commit R0: C.11's dated amendment
corrects the EH-A amendment's "the `match` body above applies verbatim once
W-058 makes `Optional` a choice" (DR-0 rejected the choice route; the route is
W-320's `Match`, with `.None()`). On other branches (§1.16): PR 56's
loops.md, fork/optional/plan.md and W-177's ledger note (C.7) and optional.md
(C.8), PR 62's sum_types.md, plan and W-280 (C.6; amended 2026-10-21, review
fold: RR1-M1). Records: the decision-log entry "DR-1" (C.1, which records
the amendments to D-DR-1 and D-DR-2), the ledger (C.2: W-321 and W-109
discharged by the PRs; W-322 and W-323 by their commits; W-320's and W-322's
dated notes; W-324..W-327 and W-329 filed), the gap rows (C.3), the V-3a
register (C.4), ORCHESTRATION's Next actions (C.5). Gap rows, each moved only
as its own text says: Control flow: loops (:66) keeps DONE, its DR-0 sentence
rewritten at DR-1a; Stdlib: Slices (:79) moves to DONE at DR-1b, because its
text says it "stays PARTIAL until write-through indexing lands (W-109)" and
names no other condition, its remaining 0.1 limits staying listed as filed
items; Control flow: matching sum-type consumption (:68) keeps PARTIAL, its
DR-0 sentence rewritten at R0; Stdlib: Optional (:78) keeps its status
(PARTIAL on trunk, DONE on PR 57, whose merge decides it), its DR-0 sentence
rewritten at R0 and carried by PR 57's merge (§1.16). Break condition: a gap row
whose own criterion this section misreads; the row follows its text.

### §1.16 Merge position and the held state (D-DR-20)

(Rewritten 2026-10-21, review fold: B-B2 / B-M6 / B-M10 / B-M9.) DR-1a and then
DR-1b merge after CT-1 (ORCHESTRATION's order: PR 53, 51, 52, 60, 54, 55, 56,
57, 58, 59, 61, 62, CT-1). At each one's merge, a merge commit brings trunk
(with those PRs merged) into the PR's branch, never a rebase, and the names
are distinct: M-a on DR-1a's branch, M-b on DR-1b's.

-   **M-a.** handle_loop_statement.cpp takes DR-1a's side and drops TP-1's
    pointer completeness requirement and its include (§1.2, §2.1). loops.md
    takes DR-1a's restored upstream subsections and C.9, and drops PR 56's
    F-015 amendment in the corrected form C.7 gives it: once the subsection it
    follows is upstream's `match` desugaring, its first sentence ("The
    desugaring above is the text this page had at the fork's cut") is false, and
    C.9 says the rest. Measured with `git merge-file` against trunk's page and
    PR 56's and PR 57's heads 894139b34 and a080c7886 (amended 2026-10-21,
    implementation-review fold: DR1A-m1): the page conflicts in one block, the
    desugaring region, before and after the fold took the rest of df3cf9294's
    edit, and DR-1a's side of that block gives DR-1a's page. Records keep both
    sides. Then L-a, the refill commit:
    check generic/template/for_range, lower template/for_range,
    interop/cpp/range_for (measured on the mct mirror, which merged both PRs
    at once; DR-1a alone onto CT-1's final head is measured before M-a, §8 item
    9, amended 2026-10-21, review fold: RR1-m4), and lower array/iterate,
    for/break_continue and for/for (amended 2026-10-22, implementation:
    stop-and-amend: the m57 red set; rev 3 named PR 57's slice/basic). Their
    M-a conflict blocks are CHECK lines only, three in each, because DR-1a's
    A1F and PR 57's refill 189baa262 renumber the same `!dbg` lines; they take
    trunk's side, and the refill is that renumbering again: 186/186, 183/183
    and 185/185 against PR 57's a080c7886 text, the same changed lines on m57
    (with DR-1b) and on m57a (DR-1a alone). PR 57's check/slice/basic,
    interop/cpp/range_for and lower for/bindings auto-merge with DR-1a and
    pass, so none is refilled for PR 57; a golden that several merged PRs
    change (range_for: PR 57, PR 61 and CT-1) is refilled against trunk's
    merged text (§7.1, R-6), so range_for's L-a count is recorded at L-a, not
    predicted (amended 2026-10-22, re-review round 1: RR4-m1).
-   **M-b.** handle_index.cpp resolves onto TP-1's `PerformIndex` (§2.2), then
    C-b, the composition commit that indexes a template-dependent operand per
    specific (§1.3, §2.2), then L-b: check generic/template/index (16/41,
    measured on mct and mct-b) and PR 55's string_indexing (2/2, measured on
    m55), whose two conflict blocks at M-b are CHECK lines only and take
    trunk's side, PR 55's text, before the refill; fork/conformance/README.md,
    whose generated table conflicts with PR 60's and PR 62's, is regenerated
    with `runner.py --update-readme-table` (amended 2026-10-22, re-review
    round 1: R1R2-m5). PR 51's buf_field goldens are not refilled (amended
    2026-10-22, implementation: stop-and-amend: the m51 red set; rev 3
    predicted it): on m51 the gate was 1949 of 1949 before any refill,
    because both dump only `F` and `G`, which call `Core.Buf(i32).Make`,
    `.Get(0)` and the destroy witness and never subscript a `Buf`, and the
    one trace of the prelude change in their dumps, buf.carbon's shifted
    `import_ref` instruction ids, is matched as `inst{{[0-9A-F]+}}`.
-   **Commits on other PRs' branches, each new, never a rewrite (R32 (e)), made
    now, at the records commit R0, independent of DR-1's code.** W-322's on PR
    62's branch (§1.11, C.6), measured on the m62 mirror. W-323's on PR 56's
    branch (C.7), which also carries C.8's optional.md amendment (records and
    docs only). PR 57, stacked on PR 56, takes that commit by merging PR 56's
    branch into its own (a new merge commit): optional.md and loops.md take
    both sides, PR 57's text plus the amendments, and the ledger carries
    W-177's correction (C.7; amended 2026-10-21, review fold: RR1-M1). Then
    (amended 2026-10-21, review fold: RR1-m5): W-322's commit changes
    toolchain code on a PR whose review loop was dry, so it gets one focused
    review once its run (build, autoupdate fixpoint, gate and conformance on
    PR 62's head with the commit, §0.8.2's rows) is green (R29(c)), its
    findings folded by new commits on PR 62's branch. After that review, and
    after W-323's commit and PR 57's merge of it, the descriptions and first
    comments of PR 62 (which advertise D-SV-7's matching of `Core.Optional`),
    PR 56 and PR 57 (where they state the loops.md amendment, W-177's scope or
    `.Some`/`.None` matchability) are refreshed and re-posted, each verified
    through the API, and ORCHESTRATION's rows for the three PRs are stamped,
    as was done for PR 61.
-   **Gap row 78.** Trunk's row 78 (PARTIAL) carries DR-0's drift sentence;
    PR 57's row 78 (DONE) does not. PR 57's merge into trunk keeps trunk's
    sentence, as C.3 rewrites it at R0, appended to PR 57's DONE text; DR-1 does
    not move row 78's status (D-OP-13 as PR 57 amends it decides it).

Break condition: ORCHESTRATION's merge order changes; the rules follow the new
order, and a commit on another PR's branch targets whichever branch holds the
text at that time (RC-11).

### §1.17 Residues and F-022 (D-DR-21)

(Amended 2026-10-21, review fold: A-B1 / B-B1 / B-M8 / B-m4.)

| Id | Title |
| --- | --- |
| W-324 | V-3a register entry (iv): upstream's pages conflict on how `Match` declares `Continuation` (sum_types.md:113's `let template Continuation: type;` against README.md:1076-1078 and :3064-3067, generics/terminology.md:100-103 and upstream's parser, toolchain/parse/handle_let.cpp:27-46); W-320 waits on upstream's resolution; checked at each weekly upstream check |
| W-325 | `5 as const i32` (an integer literal converted to a `const` integer type) aborts lowering: `Missing constant value for call to comptime-only function` (toolchain/lower/handle_call.cpp:638 on trunk; :598 on the upstream nightly) |
| W-326 | V-3a register entry (v): D-SL-17's literal-subscript rule (check/handle_index.cpp) is a fork spelling of indexing.md's `like i64` subscript; retire it when `like` lands (PR 56's W-178), declaring the impls `IndirectIndexWith(like i64)` |
| W-327 | A generic assignment whose specific's target is `const` writes: `*p = v` through `const T*` (trunk and the nightly print `7`) and `s[i] = v` through `Slice(const T)` (v4 prints `2`); the per-specific `const` check; pinned by A.1's `generic_write_const_element` split |
| W-329 | Reachability after an exhaustive `match` whose arms all diverge (`c_exh_return`: "missing `return`" on trunk with a choice) |

W-328 stays reserved and unused, for W-320's resumption. F-022 is not minted:
DR-1 adopts no fork design. The one point where upstream's sources conflict
(`Match.Continuation`) is not decided by the fork in either direction; it is a
register entry with a work item (W-324) and a blocked work item (W-320), and
choosing sum_types.md:113 over README.md would contradict upstream's explicit,
leads-cited text (§1.4). Break condition: a review finds a surface rule here
that no upstream text determines; F-022 is minted for it.

### §1.18 Decision index

| Id | Decision | Section |
| --- | --- | --- |
| D-DR-5 | two PRs on two branches: DR-1a (slice 2) on trunk's base, DR-1b (slice 3) stacked on it | §1.1 |
| D-DR-6 | `ref cursor` as df3cf9294, re-expressed; TP-1's pointer requirement dropped at M-a | §1.2 |
| D-DR-7 | `IndirectIndexWith` as 6d80ceb58 and 309d3d63c, re-expressed, with 230227264's code and upstream's tests; `Slice` and `Buf` writable through `Ref`; D-SL-3 retired; D-SL-17 filed as W-326; per-specific choice for template-dependent operands at M-b | §1.3 |
| D-DR-8 | L1, L2 and L3 not implemented: L1 and L2 contradict upstream (README.md, terminology.md, the parser; p001013) | §1.4 |
| D-DR-9..D-DR-14 | withdrawn with slice 1; RC-1..RC-12 bind the resumption; D-DR-13 withdrawn outright (the `Try` body keeps `HasValue`/`Get`) | §1.4..§1.10 |
| D-DR-15 | D-SV-7's view removed now by a removal-only commit on PR 62; F-020's bridge kept; amends DR-0's D-DR-2 | §1.11 |
| D-DR-16 | no new diagnostic kind | §1.12 |
| D-DR-17 | goldens | §1.13 |
| D-DR-18 | programs | §1.14 |
| D-DR-19 | docs and records | §1.15 |
| D-DR-20 | merge after CT-1 by merge commits M-a and M-b, with refill commits; commits on PR 62, PR 56 and PR 57 now | §1.16 |
| D-DR-21 | W-324..W-327 and W-329 filed; W-328 reserved; no F-022 | §1.17 |
| D-DR-22 | the stop rule fires at the plan for slice 1; the fix budget for DR-1a and DR-1b | §1.4, §3 |

## §2 Spec, file by file

### §2.0 Conventions

Diffs are against trunk f68681114. "Measured" means the hunk is the one built
and gated in v2, v3, v4 or a mirror (§0.6, §0.8); nothing in rev 2's two PRs is
only specified. CHECK lines are never written by hand (R16): goldens appear here
only by name, their sources in Appendix A. The full measured diff, goldens
included, is kept at `$Y/v4_full.diff` (`$X/v3_full.diff` for rev 1's v3; 2337
lines for slice 2 alone at `$X/slice2_full.diff`); the mirrors' resolutions at
`$Y/logs/mct_resolution.diff` and `$Y/m62_w322.diff` (amended 2026-10-21,
review fold: B-M6 / A-M3).

### §2.1 Slice 2 (DR-1a): measured

core/prelude/iterate.carbon, core/prelude/range.carbon and min_prelude's
interface:

<!-- google-doc-style-ignore -->

```diff
diff --git a/core/prelude/iterate.carbon b/core/prelude/iterate.carbon
--- a/core/prelude/iterate.carbon
+++ b/core/prelude/iterate.carbon
@@ -14,17 +14,17 @@ interface Iterate {
   let ElementType: Copy & Destroy;
   let CursorType: Destroy;
   fn NewCursor(self) -> CursorType;
-  fn Next(self, cursor: CursorType*) -> Optional(ElementType);
+  fn Next(self, ref cursor: CursorType) -> Optional(ElementType);
 }

 impl forall [T: Copy & Destroy, N: IntLiteral]
     array(T, N) as Iterate
     where .ElementType = T and .CursorType = i32 {
   fn NewCursor(unused self) -> i32 { return 0; }
-  fn Next(self, cursor: i32*) -> Optional(T) {
-    if (*cursor < N) {
-      ++*cursor;
-      return Optional(T).Some(self[*cursor - 1]);
+  fn Next(self, ref cursor: i32) -> Optional(T) {
+    if (cursor < N) {
+      ++cursor;
+      return Optional(T).Some(self[cursor - 1]);
     } else {
       return Optional(T).None();
     }
@@ -71,10 +71,10 @@ impl forall [T: CppRange where .ValueType impls Copy]
     return (self.Begin(), self.End());
   }

-  fn Next(unused self, cursor: CursorType*) -> Optional(ElementType) {
-    if (cursor->0 != cursor->1) {
-      returned var result: Optional(ElementType) = cursor->0.(CppUnsafeDeref.Op)();
-      ++cursor->0;
+  fn Next(unused self, ref cursor: CursorType) -> Optional(ElementType) {
+    if (cursor.0 != cursor.1) {
+      returned var result: Optional(ElementType) = cursor.0.(CppUnsafeDeref.Op)();
+      ++cursor.0;
       return var;
     }
     return Optional(ElementType).None();
@@ -87,10 +87,10 @@ final impl forall [T: Copy & Destroy]
     Slice(T) as Iterate
     where .ElementType = T and .CursorType = i64 {
   fn NewCursor(unused self) -> i64 { return 0; }
-  fn Next(self, cursor: i64*) -> Optional(T) {
-    if (*cursor < self.Size()) {
-      ++*cursor;
-      return Optional(T).Some(self.Get(*cursor - 1));
+  fn Next(self, ref cursor: i64) -> Optional(T) {
+    if (cursor < self.Size()) {
+      ++cursor;
+      return Optional(T).Some(self.Get(cursor - 1));
     } else {
       return Optional(T).None();
     }
diff --git a/core/prelude/range.carbon b/core/prelude/range.carbon
--- a/core/prelude/range.carbon
+++ b/core/prelude/range.carbon
@@ -17,10 +17,10 @@ class IntRange(N: IntLiteral) {

   impl as Iterate where .CursorType = Int(N) and .ElementType = Int(N) {
     fn NewCursor(self) -> Int(N) { return self.start; }
-    fn Next(self, cursor: Int(N)*) -> Optional(Int(N)) {
-      var value: Int(N) = *cursor;
+    fn Next(self, ref cursor: Int(N)) -> Optional(Int(N)) {
+      var value: Int(N) = cursor;
       if (value < self.end) {
-        ++*cursor;
+        ++cursor;
         return Optional(Int(N)).Some(value);
       } else {
         return Optional(Int(N)).None();
diff --git a/toolchain/testing/testdata/min_prelude/parts/iterate.carbon b/toolchain/testing/testdata/min_prelude/parts/iterate.carbon
--- a/toolchain/testing/testdata/min_prelude/parts/iterate.carbon
+++ b/toolchain/testing/testdata/min_prelude/parts/iterate.carbon
@@ -16,5 +16,5 @@ interface Iterate {
   let ElementType: Copy;
   let CursorType: type;
   fn NewCursor(self) -> CursorType;
-  fn Next(self, cursor: CursorType*) -> Optional(ElementType);
+  fn Next(self, ref cursor: CursorType) -> Optional(ElementType);
 }
```

<!-- google-doc-style-resume -->

toolchain/check/handle_loop_statement.cpp (the invariant: the cursor variable is
a durable reference expression, so `BuildBinaryOperator` binds it to `Next`'s
`ref` parameter without a conversion; upstream df3cf9294's lines):

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/handle_loop_statement.cpp b/toolchain/check/handle_loop_statement.cpp
--- a/toolchain/check/handle_loop_statement.cpp
+++ b/toolchain/check/handle_loop_statement.cpp
@@ -251,20 +251,15 @@ auto HandleParseNode(Context& context, Parse::ForHeaderId node_id) -> bool {
   auto loop_header_id = StartLoopHeader(context, start_node_id);
   auto continue_depth = context.scope_stack().ambient_cleanup_scope_depth();

-  // Call `<range>.(Iterate.Next)(&cursor)`.
-  auto cursor_type_inst_id = context.types().GetTypeInstId(cursor_type_id);
-  auto cursor_addr_id = AddInst<SemIR::AddrOf>(
-      context, node_id,
-      {.type_id = GetPointerType(context, cursor_type_inst_id),
-       .lvalue_id = cursor_var_id});
-  // A range that implements neither fails both lookups; reporting the second
-  // would say the same thing about the same expression a second time.
+  // Call `<range>.(Iterate.Next)(ref cursor)`.
+  // Don't diagnose if the call to `Iterate.NewCursor` failed, since this call
+  // will likely also fail for the same reason.
   // TODO: We should only perform the impl lookup once.
   auto element_id =
       BuildBinaryOperator(context, node_id,
                           {.interface_name = CoreIdentifier::Iterate,
                            .op_name = CoreIdentifier::Next},
-                          range_id, cursor_addr_id,
+                          range_id, cursor_var_id,
                           /*diagnose=*/cursor_id != SemIR::ErrorInst::InstId);
   // We need to convert away from an initializing expression in order to call
   // `HasValue` and then separately pattern-match against the element.
```

<!-- google-doc-style-resume -->

The four test sources (check/testdata/for/actual.carbon:25-33, basic.carbon:34,
pattern.carbon:24, lower/testdata/for/bindings.carbon:18) take df3cf9294's
source lines verbatim, and
fork/conformance/programs/stdlib/iterate_interface.carbon:34-37 becomes:

<!-- google-doc-style-ignore -->

```carbon
    fn Next(unused self, ref cursor: i32) -> Core.Optional(i32) {
      var value: i32 = cursor;
      if (value > 0) {
        cursor -= 1;
```

<!-- google-doc-style-resume -->

docs/design/control_flow/loops.md: upstream's ac31fd198 page (the same text
at bc45989b2 and 503f09037, df3cf9294 being its last change) with the fork's
`while let` amendment (:38-44), the fork's only own text on the page, and,
after the desugaring block, the amendment of Appendix C.9. That is the whole of
df3cf9294's page edit: the table of contents; the note on value bindings and
the `Core.Iterate` paragraph in place of the pattern-default sentence, the
`var` example and the temporaries paragraph (the fork's :64-65 and :75-84);
the "`Iterate` interface" and "Loop desugaring" subsections (upstream's
:74-131) in place of the "Ranged-for for user-defined types" subsection (the
fork's :86-114); and the References entry for proposal p007381 (amended
2026-10-21, implementation-review fold: DR1A-m1 / DR1A-m3). Rev 3 called the
sentence at :64-65 the fork's pattern-default text and cited upstream's :75-131
and the fork's :87-114; `git show df3cf9294~1:docs/design/control_flow/loops.md`
has the sentence verbatim (its :57-58), so it is upstream's text before
df3cf9294, and the two headings are at upstream's :74 and the fork's :86 (line
numbers at a9943e467). A1 took the two subsections and the table of contents
only; the first DR-1a fix commit takes the rest.

M-a's resolution of handle_loop_statement.cpp on CT-1's head (measured on the
mct mirror, §0.8.1; amended 2026-10-21, review fold: B-M6): the conflict block
takes DR-1a's side above, which drops TP-1's lines

<!-- google-doc-style-ignore -->

```cpp
  auto cursor_ptr_type_id = GetPointerType(context, cursor_type_inst_id);
  // The code that forms an instruction enforces its type's completeness
  // (type_completion.h): for a template-dependent cursor type, this records
  // the requirement, so that each specific completes the pointer type its
  // `Next` call passes. A pointer type is always complete, so the
  // diagnostic context adds nothing.
  RequireCompleteType(context, cursor_ptr_type_id, SemIR::LocId(node_id),
                      [](auto& /*builder*/) {});
```

<!-- google-doc-style-resume -->

with the `AddrOf` they completed, and the `#include
"toolchain/check/type_completion.h"` TP-1 added, which nothing else in the file
uses. The cursor variable, whose own type TP-1 completes where the `VarStorage`
is formed, is what `Next` binds.

### §2.2 Slice 3 (DR-1b): measured

core/prelude/operators/index.carbon becomes upstream's ac31fd198 file (§0.5's
listing, byte-identical; the license header and `package` line unchanged).
core/prelude/types/slice.carbon and buf.carbon (the invariant: `Ref` returns a
durable reference to the element storage the view or buffer owns or names, after
the same bounds check `Get` performs; `Data()`/`AsSlice()` because the impls are
outside the classes):

<!-- google-doc-style-ignore -->

```diff
diff --git a/core/prelude/types/buf.carbon b/core/prelude/types/buf.carbon
--- a/core/prelude/types/buf.carbon
+++ b/core/prelude/types/buf.carbon
@@ -69,7 +69,12 @@ class Buf(T: Copy & Destroy) {
 // `i64` subscripts, as for `Slice` (an integer literal converts at the index
 // expression, check/handle_index.cpp); `final` for the same reason — `b[i]`
 // on a `Buf(T)` in a generic body has type `T`.
-final impl forall [T: Copy & Destroy] Buf(T) as IndexWith(i64)
+final impl forall [T: Copy & Destroy] Buf(T) as IndirectIndexWith(i64)
     where .ElementType = T {
-  fn At(self, subscript: i64) -> T { return self.Get(subscript); }
+  fn Ref(self, subscript: i64) -> ref T {
+    if (subscript < 0 or subscript >= self.Size()) {
+      FailStop("carbon: Core.Buf index out of bounds; terminating\n");
+    }
+    return *PointerOffset(self.AsSlice().Data(), subscript);
+  }
 }
diff --git a/core/prelude/types/slice.carbon b/core/prelude/types/slice.carbon
--- a/core/prelude/types/slice.carbon
+++ b/core/prelude/types/slice.carbon
@@ -71,9 +71,14 @@ impl forall [T: Copy & Destroy] Slice(T) as UnformedInit {}
 // `T` — a symbolic query resolves only final impls, and through a non-final
 // impl `.ElementType` stays the abstract
 // `Slice(T).(IndexWith(i64).ElementType)` (the `Optional(T) as Try` pattern).
-final impl forall [T: Copy & Destroy] Slice(T) as IndexWith(i64)
+final impl forall [T: Copy & Destroy] Slice(T) as IndirectIndexWith(i64)
     where .ElementType = T {
-  fn At(self, subscript: i64) -> T { return self.Get(subscript); }
+  fn Ref(self, subscript: i64) -> ref T {
+    if (subscript < 0 or subscript >= self.Size()) {
+      FailStop("carbon: Core.Slice index out of bounds; terminating\n");
+    }
+    return *PointerOffset(self.Data(), subscript);
+  }
 }

 // `const` can be added to the element type (D-SL-10).
```

<!-- google-doc-style-resume -->

The comments above both impls (slice.carbon:64-73, buf.carbon:69-71) are
rewritten at implementation to name `IndirectIndexWith` and D-DR-7 instead of
`IndexWith`; iterate.carbon:84-85's comment ("`final`, as `Slice(T)`'s
`IndexWith(i64)` impl is") is updated likewise. toolchain/check/handle_index.cpp
(the invariant: an operand whose type implements `IndirectIndexWith(I)` is
indexed by `Ref`, any other by `At`, and only the fallback diagnoses; the
literal rule sees a type that implements either `(i64)` interface):

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/handle_index.cpp b/toolchain/check/handle_index.cpp
--- a/toolchain/check/handle_index.cpp
+++ b/toolchain/check/handle_index.cpp
@@ -30,20 +30,22 @@ auto HandleParseNode(Context& /*context*/, Parse::IndexExprStartId /*node_id*/)
   return true;
 }

-// Performs an index with base expression `operand_inst_id` and
-// `operand_type_id` for types that are not an array. This checks if
-// the base expression implements the `IndexWith` interface; if so, uses the
-// `At` associative method, otherwise prints a diagnostic.
-static auto PerformIndexWith(Context& context, Parse::NodeId node_id,
-                             SemIR::InstId operand_inst_id,
-                             SemIR::InstId index_inst_id) -> SemIR::InstId {
+// Performs an index with base expression `operand_inst_id` for types that are
+// not an array, using the `op_name` method of the interface `interface_name`.
+// On failure, returns an `ErrorInst`, and diagnoses unless `diagnose` is false.
+static auto PerformIndexOperator(Context& context, Parse::NodeId node_id,
+                                 CoreIdentifier interface_name,
+                                 CoreIdentifier op_name,
+                                 SemIR::InstId operand_inst_id,
+                                 SemIR::InstId index_inst_id, bool diagnose)
+    -> SemIR::InstId {
   SemIR::InstId args[] = {context.types().GetTypeInstId(
       context.insts().Get(index_inst_id).type_id())};
-  Operator op{.interface_name = CoreIdentifier::IndexWith,
+  Operator op{.interface_name = interface_name,
               .interface_args_ref = args,
-              .op_name = CoreIdentifier::At};
+              .op_name = op_name};
   return BuildBinaryOperator(context, node_id, op, operand_inst_id,
-                             index_inst_id);
+                             index_inst_id, diagnose);
 }

 // Fork (SL-1, fork/slices/plan.md R-5, amended 2026-10-05). Returns whether
@@ -61,11 +63,12 @@ static auto PerformIndexWith(Context& context, Parse::NodeId node_id,
 // up (never for an erroneous operand, which `BuildBinaryOperator` rejects
 // before any lookup).
 static auto HasIndexWithImpl(Context& context, SemIR::LocId loc_id,
+                             CoreIdentifier interface_name,
                              SemIR::TypeId operand_type_id,
                              SemIR::TypeId subscript_type_id)
     -> std::optional<bool> {
   auto interface_inst_id =
-      TryLookupNameInCore(context, loc_id, CoreIdentifier::IndexWith);
+      TryLookupNameInCore(context, loc_id, interface_name);
   if (!interface_inst_id.has_value()) {
     return std::nullopt;
   }
@@ -122,8 +125,9 @@ static auto LiteralSubscriptTargetType(Context& context, Parse::NodeId node_id,
                                        SemIR::TypeId literal_type_id)
     -> std::optional<SemIR::TypeId> {
   auto loc_id = SemIR::LocId(node_id);
-  auto has_literal_impl =
-      HasIndexWithImpl(context, loc_id, operand_type_id, literal_type_id);
+  auto has_literal_impl = HasIndexWithImpl(
+      context, loc_id, CoreIdentifier::IndexWith, operand_type_id,
+      literal_type_id);
   if (!has_literal_impl || *has_literal_impl) {
     return std::nullopt;
   }
@@ -146,8 +150,16 @@ static auto LiteralSubscriptTargetType(Context& context, Parse::NodeId node_id,
   auto i64_type_id = MakeIntType(context, node_id, SemIR::IntKind::Signed,
                                  context.ints().Add(64));
   context.inst_block_stack().PopAndDiscard();
-  auto has_i64_impl =
-      HasIndexWithImpl(context, loc_id, operand_type_id, i64_type_id);
+  // `IndexWith(i64)` is also implemented by `IndirectIndexWith`'s blanket
+  // `final` impl when the element is `Copy`; probe `IndirectIndexWith(i64)`
+  // first so that a non-`Copy` element is admitted too.
+  auto has_i64_impl = HasIndexWithImpl(
+      context, loc_id, CoreIdentifier::IndirectIndexWith, operand_type_id,
+      i64_type_id);
+  if (has_i64_impl && !*has_i64_impl) {
+    has_i64_impl = HasIndexWithImpl(context, loc_id, CoreIdentifier::IndexWith,
+                                    operand_type_id, i64_type_id);
+  }
   if (!has_i64_impl || !*has_i64_impl) {
     return std::nullopt;
   }
@@ -212,8 +224,18 @@ auto HandleParseNode(Context& context, Parse::IndexExprId node_id) -> bool {
                                    index_inst_id, *target_type_id);
         }
       }
-      auto elem_id =
-          PerformIndexWith(context, node_id, operand_inst_id, index_inst_id);
+      // Per the design, prefer `IndirectIndexWith` if the type implements it,
+      // otherwise fall back to `IndexWith`.
+      // TODO: Use `IndexWith.Ref` when the operand is a durable reference.
+      auto elem_id = PerformIndexOperator(
+          context, node_id, CoreIdentifier::IndirectIndexWith,
+          CoreIdentifier::Ref, operand_inst_id, index_inst_id,
+          /*diagnose=*/false);
+      if (elem_id == SemIR::ErrorInst::InstId) {
+        elem_id = PerformIndexOperator(
+            context, node_id, CoreIdentifier::IndexWith, CoreIdentifier::At,
+            operand_inst_id, index_inst_id, /*diagnose=*/true);
+      }
       context.node_stack().Push(node_id, elem_id);
       return true;
     }
```

<!-- google-doc-style-resume -->

As committed at B1 (3c54754bc; amended 2026-10-22, implementation:
stop-and-amend: stage B errata), clang-format 21.1.8 wraps three of the
block's statements differently, with the same tokens: handle_index.cpp is
37/16 against the block's 39/17. The implementation-review fold's fix commit
(amended 2026-10-22, implementation-review fold: DR1B-M1 / DR1B-m4) adds the
`IndirectIndexWith(Core.IntLiteral)` probe of §1.3 after the `Core.Int` lookup
and rewords three comments (`HasIndexWithImpl`'s, the rule's statement and the
`default:` arm's), making handle_index.cpp 80/43 against f68681114; C-b's 19
added lines are unchanged, their context at merge the reworded comment
(measured on mct-b at the fold). Round 2's fixer (8deb75262; amended
2026-10-22, re-review round 2: R1R2-m1 / RR1-1-F1) rewords the rule's
statement and its `Core.Int` footprint comment, comments only, making
handle_index.cpp 95/50 against f68681114; both lie outside the three conflict
blocks of a merge with CT-1's 4a3220c11, so M-b's resolution takes them
unchanged and C-b's context is unchanged (`git merge-tree`, measured).

toolchain/check/core_identifier.def, toolchain/check/cpp/operators.cpp
(309d3d63c's lines) and 230227264's call.cpp and convert.cpp hunks (applied
unchanged; at implementation they come by `git cherry-pick -x -n 230227264`,
the commit's two goldens are then restored to the fork's and receive the three
split sources of Appendix A.0, and autoupdate refills them, §1.3; amended
2026-10-21, review fold: A-M5 / B-M13):

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/call.cpp b/toolchain/check/call.cpp
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -337,10 +337,13 @@ auto PerformCallToFunction(Context& context, SemIR::LocId loc_id,
         context, loc_id, callee.return_pattern_id, *callee_specific_id);
     if (arg_type_id == SemIR::ErrorInst::TypeId) {
       return_type_id = SemIR::ErrorInst::TypeId;
-    } else if (SemIR::InitRepr::ForType(context.sem_ir(), arg_type_id)
+    } else if (callee.call_param_ranges.return_size() > 0 &&
+               SemIR::InitRepr::ForType(context.sem_ir(), arg_type_id)
                    .MightBeInPlace()) {
       // Tentatively use storage for a temporary as the return argument.
       // This will be replaced if necessary when we perform initialization.
+      // Only do this if the callee has a return parameter to receive it;
+      // functions that return by reference or by value don't.
       return_arg_id = AddInst<SemIR::TemporaryStorage>(
           context, loc_id, {.type_id = arg_type_id});
     }
diff --git a/toolchain/check/convert.cpp b/toolchain/check/convert.cpp
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -2832,6 +2832,10 @@ auto ConvertCallArgs(Context& context, SemIR::InstId self_id,
   CARBON_CHECK(
       (self_id.has_value() ? 1 : 0) + arg_refs.size() <=
       context.inst_blocks().GetOrEmpty(callee.param_patterns_id).size());
+  // A return argument can only be matched against a return parameter.
+  CARBON_CHECK(
+      !return_arg_id.has_value() || callee.call_param_ranges.return_size() > 0,
+      "Return argument provided for a callee with no return parameter");

   return CallerPatternMatch(context, callee_specific_id, callee.self_param_id,
                             callee.param_patterns_id, callee.return_pattern_id,
diff --git a/toolchain/check/core_identifier.def b/toolchain/check/core_identifier.def
--- a/toolchain/check/core_identifier.def
+++ b/toolchain/check/core_identifier.def
@@ -56,6 +56,7 @@ CARBON_CORE_IDENTIFIER(HasValue)
 CARBON_CORE_IDENTIFIER(ImplicitAs)
 CARBON_CORE_IDENTIFIER(Inc)
 CARBON_CORE_IDENTIFIER(IndexWith)
+CARBON_CORE_IDENTIFIER(IndirectIndexWith)
 CARBON_CORE_IDENTIFIER(Int)
 CARBON_CORE_IDENTIFIER(IntFitsIn)
 CARBON_CORE_IDENTIFIER(Iterate)
@@ -78,6 +79,7 @@ CARBON_CORE_IDENTIFIER(NullptrT)
 CARBON_CORE_IDENTIFIER(Op)
 CARBON_CORE_IDENTIFIER(Optional)
 CARBON_CORE_IDENTIFIER(OrderedWith)
+CARBON_CORE_IDENTIFIER(Ref)
 CARBON_CORE_IDENTIFIER(Result)
 CARBON_CORE_IDENTIFIER(RightShiftAssignWith)
 CARBON_CORE_IDENTIFIER(RightShiftWith)
diff --git a/toolchain/check/cpp/operators.cpp b/toolchain/check/cpp/operators.cpp
--- a/toolchain/check/cpp/operators.cpp
+++ b/toolchain/check/cpp/operators.cpp
@@ -200,6 +200,12 @@ static auto GetClangOperatorKind(Context& context, SemIR::LocId loc_id,
       return clang::OO_Subscript;
     }

+    // C++ `operator[]` is found through `IndexWith`, which subscripting falls
+    // back to.
+    case CoreIdentifier::IndirectIndexWith: {
+      return std::nullopt;
+    }
+
     default: {
       context.TODO(loc_id, llvm::formatv("Unsupported operator interface `{0}`",
                                          interface_name));
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/slice/fail_basic.carbon: the `fail_write_through` split
(:16-30) is deleted. Upstream's two `IndirectIndexWith` tests are added with
their ac31fd198 sources (Appendix A.0b). docs/design/slices.md: Appendix C.10's
amendment replaces the 0.1-limits bullet. A known edge, not changed: when `Core`
lacks `IndirectIndexWith` (the fake-`Core` splits of
operators/overloaded/index.carbon), `HasIndexWithImpl` returns `nullopt` for it
and the literal rule does not fall back to `IndexWith(i64)`; only fake-`Core`
tests reach it, and the measured fill pins their output. Two more edges
(amended 2026-10-22, re-review round 1: RR1-1-F1 / R1R2-m1; §1.3): a blanket
`IndirectIndexWith(U)` impl with `U: ImplicitAs(i64)` answers the literal
probe, so a literal subscript reaches its `U = Core.IntLiteral` specific as
upstream's dispatch does, and a `Ref` that converts the subscript at run time
aborts lowering at lower/handle_call.cpp:638 (W-325's FATAL; q07, q08, q08b and
q09); and an operand whose only literal impl is
`IndirectIndexWith(Core.IntLiteral)` dispatches as written while its file gains
the `Core.IndexWith` and `Core.Int` import_refs (fp.carbon). Since round 2's
fix 8deb75262 the rule's comments say both (handle_index.cpp:114-125 and
:146-158; amended 2026-10-22, re-review round 2).

M-b's resolution of handle_index.cpp on CT-1's head, and the composition commit
C-b after it (measured on the mct mirror, §0.8.1; amended 2026-10-21, review
fold: B-M6). The resolution is mechanical: TP-1 renamed the parse-node
parameters of the helpers to `SemIR::LocId loc_id` and made the default arm
return its result from `PerformIndex`, so `PerformIndexOperator` takes `loc_id`
and passes it to `BuildBinaryOperator`, and the arm ends in `return elem_id;`
where trunk's pushed it. C-b then adds, at the head of `PerformIndex`'s default
arm (before the literal-subscript probe, whose `index_type_id` it hoists):

<!-- google-doc-style-ignore -->

```cpp
    default: {
      // Fork (DR-1 D-DR-7, composed with TP-1): whether a template-dependent
      // operand implements `IndirectIndexWith(I)`, and so which interface
      // subscripting uses, is known only per specific. An impl lookup that
      // depends on a template parameter is resolved at monomorphization, where
      // a failed `IndirectIndexWith` probe is an error rather than a fallback,
      // so such an index is performed when the template is instantiated, as an
      // opaque operand's is.
      auto index_type_id = context.insts().Get(index_inst_id).type_id();
      if (OperandDependence(context, operand_type_id) ==
              SemIR::ConstantDependence::Template ||
          OperandDependence(context, index_type_id) ==
              SemIR::ConstantDependence::Template) {
        return AddDependentActionSplice<SemIR::IndexAction>(
            context, loc_id,
            {.type_id = SemIR::InstType::TypeId,
             .operand_id = operand_inst_id,
             .index_id = index_inst_id},
            SemIR::TypeInstId::None);
      }
```

<!-- google-doc-style-resume -->

Invariant: an operand and subscript of non-template-dependent type are indexed
exactly as DR-1b indexes them on trunk; a template-dependent one makes the
choice in its specific, where `PerformAction` calls `PerformIndex` with
concrete types. The predicate is TP-1's own `OperandDependence` (action.h), the
action TP-1's `IndexAction`; no new instruction kind. C-b has no trunk
counterpart: trunk cannot deduce a template parameter from `Vec(T)` at all
(§0.8.1), so it lands with M-b.

### §2.3 Slice 1a (DR-1c) and §2.4 Slice 1b (DR-1d)

Withdrawn with slice 1 (§1.4); rev 1's §2.3 and §2.4 (commit 1e46ffd94) are
the resumption's starting point under RC-1..RC-12 (amended 2026-10-21, review
fold: A-B1 / B-B1).

### §2.5 Commits on other PRs' branches

(Rewritten 2026-10-21, review fold: A-M3 / B-B2 / B-M10 / B-M12.) PR 62's commit
(W-322, D-DR-15), as measured on the m62 mirror (`$Y/m62_w322.diff`):
refutable_binding.cpp loses the D-SV-7 branch; cpp/sum_type.h loses the
`CoreOptionalView` struct and the declarations of `GetCoreOptionalView` and
`DiagnoseCoreOptionalNotMatchable`, and its two comments that said "matchable"
say "mapped"; cpp/sum_type.cpp gains the struct (status `Mapped` for
`Matchable`) before `GetCoreOptionalPayload`, makes `GetCoreOptionalView`
`static`, and loses `DiagnoseCoreOptionalNotMatchable`; kind.def loses
`CoreOptionalNotMatchable`; match/core_optional_view.carbon is deleted and
match/fail_todo_core_optional.carbon (Appendix A.3) added and filled; the
program of Appendix B.3 is SKIPped and the conformance README table
regenerated; PR 62's sum_types.md section, gap row 68, plan (§1.7, §1.16, §3
item 8 and Appendix C.5), decision-log SV-1 entry and ledger entry W-280 take
C.6's texts, and its ledger gains no W-177 or W-322 entry (amended 2026-10-21,
review fold: RR1-M1). PR 56's commit (W-323): loops.md:116-118,
fork/optional/plan.md:192-214 and W-177's ledger note as C.7, and
docs/design/optional.md as C.8. PR 57's merge of PR 56's branch: optional.md,
loops.md, the gap table and the ledger keep both sides.

## §3 Commits and PRs

(Rewritten 2026-10-21, review fold: A-M4 / B-M5 / A-M5 / B-M13 / B-M6 / A-m4 /
B-m4.) Author `jmann345 <jerrymannstan@gmail.com>`, committer Claude, each
message ending with the session's two trailers after a blank line; explicit
paths only (R20); dates the commit's UTC date. Fill commits come from
`autoupdate.sh` to a fixpoint (R26: a second pass that changes nothing).

1.  **P0, P1, P2** "DR-1 plan (rev 1)", "DR-1 plan (rev 2): reviews A and B
    folded" and "DR-1 plan (rev 3): focused re-review folded, sign-off" (this
    file); implementation starts at P2, the signed-off revision (amended
    2026-10-21, review fold: RR1-m4). P3 f551057ea "DR-1 plan (rev 4):
    stop-and-amend: the m51 and m57 mirrors' red sets"; then, on the same
    branch, 2a4264056 "DR-1 plan: implementation-review fold, DR-1b" and "DR-1
    plan: focused re-review of DR-1b's fold, round 1 recorded" (c1b19da06) and
    "DR-1 plan: focused re-review of DR-1b's fold, round 2 recorded", each
    merged into claude/carbon-fork-0-1-dr-idx by a merge commit: 1b2ddcb87
    (rev 4, between B-P and B-R), adec21b5e (the fold's, between its fill and
    D), a0ea3347e (round 1's) and round 2's. None of them is a fix commit
    under D-DR-22 (item 9); each changes the plan, and round 1's also the
    decision log (amended 2026-10-22, re-review round 1: RR4-m4; round 2's
    added 2026-10-22, re-review round 2).
2.  **R0** "DR-1 records: plan decisions" on claude/carbon-fork-0-1-dr: the
    decision-log entry DR-1 at its plan state (C.1), the V-3a register's (iv)
    and (v) (C.4), W-324..W-327 and W-329 filed and W-320's and W-322's dated
    notes (C.2), gap rows :68 and :78's DR-0 sentences (C.3),
    error_handling.md's amendment (C.11), ORCHESTRATION's Next actions (C.5).
    With it, on the other branches, made now (§1.16): W-323's commit on PR 56's
    branch (C.7, C.8), PR 57's merge of it, and W-322's commit on PR 62's branch
    (§1.11, C.6, A.3, B.3), each measured or records-only. Then one focused
    review of W-322's commit once its run is green (R29(c)), and the refreshed
    descriptions and first comments of PR 62, PR 56 and PR 57 re-posted, with
    ORCHESTRATION stamped (§1.16; amended 2026-10-21, review fold: RR1-m5).
3.  **A1** "DR-1a: `Core.Iterate.Next` takes `ref cursor`" (§2.1's source files,
    the four test sources, the program, loops.md with C.9). A1F "DR-1a fill":
    the nine goldens of §0.6, predicted exactly as measured on v2.
4.  **A-R** "DR-1a records": W-321 discharged, gap row :66 (C.3), the register's
    (iii) resolved. One implementation review once the run is green (R29(c));
    DR-1a is opened held.
5.  **B0** on claude/carbon-fork-0-1-dr-idx (cut from A-R): the command `git
    cherry-pick -x -n 230227264`, the two form.carbon goldens restored to the
    fork's and given Appendix A.0's split sources, committed with upstream's
    subject and body, the `-x` line and "Upstream author: David Blaikie,
    PR 7886" (§1.3; rewrapped, RR1-m3). B0F: the two goldens refilled (+172
    and +103 lines on v4).
6.  **B1** "DR-1b: subscripting prefers `IndirectIndexWith`; `Core.Slice` and
    `Core.Buf` write through `Ref`" (§2.2's files, `fail_write_through` deleted,
    upstream's two tests, A.1, A.2, slices.md C.10). B1F "DR-1b fill": the
    eleven goldens of §0.6.1 and the four new files, two passes, measured on v4.
7.  **B-P** "DR-1b programs": B.1, B.2 and the `.diff.cpp`, the README table
    regenerated; 130 / 0 / 22 over 152, measured on v4.
8.  **B-R** "DR-1b records": W-109 discharged, gap row :79 to DONE (C.3), the
    register's (ii) resolved; its decision-log note also records the mirror
    runs of §5 and corrects DR-1a's land-time items as rev 4's Stop-and-amend
    record says (amended 2026-10-22, implementation: stop-and-amend). One
    implementation review once green (R29(c)); DR-1b is opened held, stacked
    on DR-1a.
9.  **Fix commits**: at most three per PR, each with its fill. The shrink line
    (D-DR-22): a finding that needs a fourth shrinks the PR instead, the shape
    at issue going OUT with a residue in the next free id after the re-scan
    (W-328 stays reserved for W-320's resumption, §1.17; amended 2026-10-21,
    review fold: RR1-m2), its split renamed `fail_todo_`, never a guard that
    hides an IN form (R17). Break condition: a finding that no shrink can
    answer without breaking a measured row of §0.6.2; the PR stops and the plan
    is amended. DR-1a used two and DR-1b one with its fill. Round 1 of DR-1b's
    focused re-review (2026-10-22) is not dry: R1R2-m1 and R1R2-m2 need
    comment-only edits of handle_index.cpp and of check
    slice/write_through.carbon's source, owed to round 2's fixer as DR-1b's
    fix commit 2 of 3, with RR1-1-F1's comment and A.1's line, an autoupdate
    run expected to change nothing, and a gate (amended 2026-10-22, re-review
    round 1). Round 2's fixer made them in 8deb75262, DR-1b's fix commit 2 of
    the three, comments only; autoupdate changed nothing, so it has no fill
    commit, and one fix commit remains for the loop (amended 2026-10-22,
    re-review round 2).
10. **At merge, after CT-1** (§1.16): M-a then L-a on DR-1a's branch; M-b, C-b
    "DR-1b: index a template-dependent operand per specific (TP-1's
    `IndexAction`)" and L-b on DR-1b's. Their resolution and fills were measured
    together on the mct mirror (§0.8.1), again on mct-b, and pairwise with
    PR 51, PR 55 and PR 57 at DR-1b's stop (§1.16, §4; amended 2026-10-22,
    implementation: stop-and-amend: the mirrors' red sets).
11. **D** "DR-1 discharge" (each PR's own, last on its branch): the ledger, the
    gap rows, the decision log's dated notes, ORCHESTRATION, the id re-scan.

## §4 Testdata matrix (autoupdate fills; the fill must reproduce these lines)

(Rewritten 2026-10-21, review fold: A-M5 / B-M13 / A-m2 / B-m4 / B-M6.)

| Golden | PR | Kind | Measured |
| --- | --- | --- | --- |
| check/for/actual, basic, pattern; check/interop/cpp/range_for; check/slice/basic; lower/array/iterate; lower/for/bindings, break_continue, for | DR-1a | refill | §0.6's numstat (v2) |
| check/function/call/form.carbon, lower/function/call/form.carbon | DR-1b (B0F) | three splits added from 230227264, refill | +172/0 and +103/0 (v4); 169 of the 172 check lines byte-identical to upstream's; the lower golden +158/0 after the implementation-review fold restored upstream's `D` and `H` (amended 2026-10-22, implementation-review fold: DR1B-m1) |
| check/index/fail_invalid_base, fail_non_tuple_access; check/operators/overloaded/index, index_with_prelude, string_indexing; check/slice/basic, buf, fail_basic; lower/interop/cpp/span; lower/slice/basic, buf | DR-1b (B1F) | refill | `$Y/v4_numstat.txt` (v4; overloaded/index.carbon converges on the second pass) |
| check/operators/overloaded/indirect_index_with.carbon, lower/index/indirect_index_with.carbon | DR-1b (B1F) | new, upstream's sources | 620 and 164 lines (v4) |
| check/slice/write_through.carbon (A.1), lower/slice/write_through.carbon (A.2) | DR-1b (B1F) | new | 692 and 166 lines (v4); the check golden 799 lines after the implementation-review fold's two splits (amended 2026-10-22, implementation-review fold: DR1B-M1 / DR1B-m3) |
| check/generic/template/for_range, lower/template/for_range, check/interop/cpp/range_for | L-a | refill, range_for's CHECK-only blocks on trunk's side first | 12/17 and 137/137 (mct; the same on mct-b at CT-1's 4a3220c11 and with DR-1a alone at 118fc1bc8; amended 2026-10-22, implementation: stop-and-amend: the mirrors' red sets); range_for's count is recorded at L-a against trunk's merged text, not predicted (R-6): 17/103 is its count against CT-1's text on those mirrors (amended 2026-10-22, re-review round 1: RR4-m1) |
| check/generic/template/index | L-b, after C-b | refill | 16/41 (mct; the same on mct-b) |
| lower/array/iterate, lower/for/break_continue, lower/for/for (PR 57's text) | L-a | the CHECK-only conflict blocks (three in each) take trunk's side, then refill | 186/186, 183/183, 185/185 against a080c7886, `!dbg` renumbering only (m57 with DR-1b and m57a with DR-1a alone, the same changed lines; amended 2026-10-22, implementation: stop-and-amend: the m57 red set) |
| PR 55's check/operators/overloaded/string_indexing | L-b | refill | 2/2 against 21307851a (m55) |
| PR 51's check and lower slice/buf_field; PR 57's check/slice/basic, check/interop/cpp/range_for, lower/for/bindings | none | unchanged: buf_field dumps no `Buf` subscript; PR 57's three auto-merge and pass | m51: 1949 of 1949 before any refill; m57 and m57a: not in the red set (amended 2026-10-22, implementation: stop-and-amend: the m51 and m57 red sets; rev 3 predicted refills of buf_field and slice/basic) |
| match/core_optional_view.carbon (deleted), match/fail_todo_core_optional.carbon (A.3) | PR 62's W-322 commit | delete, new | 0/681 and 51 lines (m62) |

## §5 Conformance delta

(Rewritten 2026-10-21, review fold: B-M2 / A-m4.)

| After | PASS | FAIL | SKIP | Total | Change |
| --- | --- | --- | --- | --- | --- |
| trunk | 128 | 0 | 22 | 150 | |
| DR-1a | 128 | 0 | 22 | 150 | measured on v2: iterate_interface rewritten, same output |
| DR-1b | 130 | 0 | 22 | 152 | measured on v4: B.1 and B.2 PASS |
| CT-1's head with DR-1a and DR-1b merged | 149 | 0 | 20 | 169 | measured on mct: CT-1's 167 programs (20 SKIP) and B.1, B.2; templates_for_dependent_range and templates_dependent_index PASS |
| CT-1's 4a3220c11 with DR-1b (mct-b) | 149 | 0 | 20 | 169 | measured at DR-1b's stop, after C-b and the refills (amended 2026-10-22, implementation: stop-and-amend: the mirrors' red sets; the rows below likewise) |
| CT-1's 118fc1bc8 with DR-1a alone | 147 | 0 | 20 | 167 | measured at DR-1a's stage A, after L-a's three CT-1 refills |
| PR 51's f96fe8a7a with DR-1b (m51) | 133 | 0 | 19 | 152 | measured, no refill; 19 SKIPs, not trunk's 22, because PR 51 un-SKIPs three programs (amended 2026-10-22, re-review round 1: RR4-m6; rev 4 read "PR 51's own programs carry 19 SKIPs") |
| PR 55's 21307851a with DR-1b (m55) | 135 | 0 | 21 | 156 | measured, after the string_indexing refill |
| PR 57's a080c7886 with DR-1b (m57) | 141 | 0 | 22 | 163 | measured, after the three lower refills; B.1 and B.2 PASS |
| PR 57's a080c7886 with DR-1a alone (m57a) | 139 | 0 | 22 | 161 | measured by rev 4's amender (a relink over PR 57's build), after the same three refills |
| PR 62 with W-322's commit | 133 | 0 | 22 | 155 | measured on m62: PR 62's 134/0/21 with match_core_optional_diff SKIPped |

Bullets: no bullet changes status (48 PASS / 0 FAIL / 8 SKIP of 56 on v4,
and on each mirror row of rev 4, amended 2026-10-22, implementation:
stop-and-amend): Stdlib: Slices is already PASS by its existing programs, and
the new programs add evidence. On PR 62's branch the sum-type consumption
bullet stays PASS by its other ten programs.

The mct-b, m51, m55 and m57 rows were re-measured at DR-1b's
implementation-review fold on the same heads, because its fix commit changes
handle_index.cpp: each red set, refill, gate and total as above, the refills'
changed lines identical to stage B's (amended 2026-10-22, implementation-review
fold: DR1B-M1; the fold record before the Sign-off). They were re-measured
again at re-review round 2 on 8deb75262, whose fix commit changes comments
only, in handle_index.cpp and in a golden's source: each red set, refill,
gate and total as above (amended 2026-10-22, re-review round 2; the round 2
record before the Sign-off).

## §6 Churn and collisions

(Rewritten 2026-10-21, review fold: A-M5 / B-M13.)

| PR | Toolchain and prelude (+/-) | Goldens | Programs | Records and docs |
| --- | --- | --- | --- | --- |
| DR-1a | iterate.carbon 13/13, range.carbon 3/3, handle_loop_statement.cpp 4/9, min_prelude 1/1 | 9 refills, 554/628 lines (amended 2026-10-21, implementation-review fold: DR1A-m3; rev 3 read 569/628) | 1 (3/3) | loops.md, ledger, row :66 |
| DR-1b | index.carbon 18/0, slice.carbon 17/12, buf.carbon 10/5 and iterate.carbon 2/2 (with the comments §2.2 has rewritten), handle_index.cpp 37/16 (clang-format's wrapping of §2.2's block), measured at B1 (amended 2026-10-22, implementation: stop-and-amend: stage B errata; rev 3 read v4's 7/2, 7/2 and 39/17), core_identifier.def 2/0, cpp/operators.cpp 6/0, call.cpp 4/1, convert.cpp 4/0 | 13 refills (275 lines added to the two form goldens; 948/709 in the eleven), 4 new (1642 lines); after the implementation-review fold 330 and 1749 lines, and handle_index.cpp 80/43 (amended 2026-10-22, implementation-review fold: DR1B-m1 / DR1B-M1) | 2 and an oracle | slices.md, ledger, row :79 |
| M-a, M-b, C-b at merge | handle_loop_statement.cpp (TP-1's 10 lines dropped), handle_index.cpp (C-b +19/-1 on mct-b; rev 3 read +16) | 8 refills, each measured on a pairwise mirror (L-a six, L-b two); PR 51's buf_field and PR 57's slice/basic not refilled (amended 2026-10-22, implementation: stop-and-amend: the mirrors' red sets) | none | merge records |
| PR 62's W-322 commit | refutable_binding.cpp 0/19, cpp/sum_type.cpp 33/21, cpp/sum_type.h 2/33, kind.def 0/1 | 1 deleted (681), 1 new (51) | 1 SKIPped | sum_types.md, row 68, plan (§1.7, §1.16, §3 item 8, C.5), decision log, ledger entry W-280 (amended 2026-10-21, review fold: RR1-M1) |

Collisions: §0.8. The rules at merge: §1.16.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

(Rewritten 2026-10-21, review fold: A-B1 / B-B1 / B-M6 / B-M7.)

-   **R-1, the stop leaves the owner's question open.** `Core.Optional` stays
    unmatchable until upstream resolves its conflict. Mitigation: W-324 is
    checked at each weekly upstream check and W-320 is re-planned the week the
    conflict resolves, from rev 1's design and RC-1..RC-12. Falsified when the
    weekly check after a resolving upstream commit schedules W-320.
-   **R-2, the composition at M-b moves more template goldens than the mirror
    showed.** C-b defers every template-dependent index, not only class types.
    Measured on CT-1's head: one golden moved (check generic/template/index);
    falsified if a later held PR's template test moves at L-b.
-   **R-3, `Buf` on `IndirectIndexWith` disagrees with upstream's owning
    buffer.** If upstream gives an owning buffer `IndexWith` with `Ref` on
    durable operands, `Buf` follows (D-DR-7's break condition). Falsified by
    upstream's first owning-buffer type in the prelude.
-   **R-4, 059ee7b9e's return form.** Upstream's `-> ref T` SemIR differs
    (§0.6.2); UA-3 refills the two form goldens and slice 3's `Ref` dumps.
    Falsified when UA-3's fill moves only those lines.
-   **R-5, W-322's removal surprises a PR 62 user.** A `Core.Optional` scrutinee
    that matched on PR 62's install no longer does. This is the measured cost
    of R32 (e) and is recorded in PR 62's sum_types.md amendment and SKIP
    reason. Falsified if a program other than match_core_optional_diff on PR
    62's branch depended on the view: none did (m62: 133/0/22).
-   **R-6, a golden that several held PRs change is refilled against trunk's
    merged text.** (Added 2026-10-22, implementation: stop-and-amend: the m57
    red set.) The mirrors are pairwise: check interop/cpp/range_for is changed
    by PR 57 (583/1983), PR 61 (34/0), CT-1 (8/8 over PR 61) and DR-1a
    (17/69), and only its mct and m57 pairs are measured; at M-a its CHECK-only
    blocks take trunk's side and autoupdate refills it, so its L-a numstat is
    against trunk's text, not mct's 17/103. Falsified if the gate after L-a's
    or L-b's fill has a red golden that no pairwise mirror named, or a conflict
    block in a golden holds a source line.
-   **R-7, a user's `final` `IndexWith` impl that trunk accepts is rejected.**
    (Added 2026-10-22, implementation-review fold: DR1B-m3.) Upstream's
    blanket `final` impl in index.carbon overlaps every other `final`
    `IndexWith` impl, so such a program fails with
    `FinalImplOverlapsDifferentFile` (the note at index.carbon:19) as it does
    on upstream, while trunk 0bdce60a5 runs it (§1.3). The cost is upstream's
    and is recorded, not worked around (R32). Falsified if a held PR's program
    or golden declares a `final` `IndexWith` impl outside the prelude: none
    does on the mirrors of §5, whose gates are green.

### §7.2 Rejected alternatives

-   **Implementing L1 and following sum_types.md:113 over README.md, with
    F-022.** Rejected (amended 2026-10-21, review fold: A-B1 / B-B1): it accepts
    syntax upstream's README.md, terminology.md and parser explicitly refuse,
    a contradiction V-3 vetoes and R32 forbids; F-022 cannot license it.
    Falsifiable claim: upstream's pages at the sign-off tip still say "an
    associated constant cannot be made `template`".
-   **L2, or a fork-local `Match` without `let template`.** Rejected: L2 is
    what p001013 removed; a fork `Match` declared another way is a second
    spelling of sum_types.md's interface (R32 (d)). v1.carbon shows a checked
    constant cannot type `Op[C: Continuation]`.
-   **The choice conversion** (`Core.Optional` as `choice Optional(T)`,
    sum_types.md:52-55). Rejected by DR-0 option (b): it changes the prelude's
    identity at ac31fd198 and loses the `T*` niche and `HasValue`/`Get`.
-   **The toolchain special case** (accept `Core.Optional` at the gate and
    lower `.Some`/`.None` to `HasValue`/`Get`). Rejected by DR-0 option (c): a
    second spelling of `Match`, R32 (d).
-   **Keeping D-SV-7's view until W-320 lands.** Rejected: R32 (e) amends a
    held PR that carries a drift before it lands, and W-320 has no date.
-   **`Buf` on `IndexWith` (review B's M7 primary fix).** Rejected with
    measurement (§0.6.2): a `final` impl does not compile beside upstream's
    blanket impl, a non-`final` one regresses generic `b[i]`, and D-SL-6
    already places `Buf` in indexing.md's `std::span` category.
-   **A pointer-cursor shim** (keeping `cursor: CursorType*` beside `ref`).
    Rejected: two signatures of one upstream interface; the thunk failure
    shows the interface admits one form.
-   **Copying upstream's handle_index.cpp wholesale.** Rejected: it carries
    947c1eb52's `Core.Array` arm, an advance's worth of prerequisites (UA-3's).
    The re-expression keeps 309d3d63c's lines exactly.
-   **Resolving 230227264's golden conflicts by hand.** Rejected (R16): the
    fork's goldens are kept and refilled (§1.3).

## §8 Verification

(Rewritten 2026-10-21, review fold: B-M11 / A-m4 / B-M6.)

1.  `build.sh` and `install.sh` of each PR's head, after `pgrep -fa ninja` shows
    no other build; a header or X-macro change (core_identifier.def, kind.def,
    context.h) means a full build, never a relink.
2.  `autoupdate.sh` to a fixpoint: the fill's second pass changes nothing (R26).
3.  `gate.sh`: every golden passes (1942 on DR-1a, 1946 on DR-1b).
4.  `conformance.sh <wt> <out>` with `XDG_CACHE_HOME` set under the scratch:
    §5's measured rows exactly.
5.  Mutants, each relinked over the PR's build with one translation unit
    changed, each expected to fail named goldens: DR-1a: the loop checker
    passing `AddrOf` again (measured on DR-1a's build: 1934 passed and 8
    failed, the eight of the nine goldens that hold a `for`, check
    for/actual.carbon having none, its lines moving with `Next`'s signature;
    and every `for` over a range whose `Next` takes `ref` fails to compile at
    the argument conversion, "cannot implicitly convert expression of type
    `i32*` to `i32`" with the note "initializing function parameter" at the
    impl's `ref cursor`, and no thunk note; rev 3 predicted the nine goldens
    and a failure through the thunk; amended 2026-10-21, implementation-review
    fold: DR1A-m3); DR-1b:
    `diagnose=true` on the `IndirectIndexWith` probe, the fallback to
    `IndexWith` removed, and 230227264's call.cpp line reverted, measured on
    DR-1b's build (amended 2026-10-22, implementation: stop-and-amend: stage B
    errata; rev 3 predicted operators/overloaded/index diagnosing twice and the
    crash of §0.6.1): the first gives 1916 passed and 30 failed, among them
    index_with_prelude, string_indexing, fail_invalid_base and
    fail_non_tuple_access, each golden that imports io failing at
    core/io.impl.carbon:14:15 (a `str` subscript), while
    operators/overloaded/index does not catch it (its fake-`Core` splits
    already report `CoreNameNotFound`); the second aborts the full gate, and
    one file at a time gives 1937 passed, 8 failed (string_indexing and
    index_with_prelude among them) and lower operators/string_indexing crashed
    at lower/handle.cpp:405; the third gives 331 crashed and 1615 passed, each
    at 230227264's own `CARBON_CHECK` in convert.cpp:2838, which now fires
    before §0.6.1's pattern_match.cpp:2207; C-b at
    merge: the dependence check removed (generic/template/index's
    `index_class_with_index_with` fails as on the mirror before C-b). Each
    mutant names its catching golden, so none is vacuous. Re-run on the
    implementation-review fold's build (amended 2026-10-22,
    implementation-review fold: DR1B-M1): the first gives 1916 passed and 30
    failed, the same 30; the second, one file at a time, 1937 passed, the
    same 8 failed and the same crash; the third, on the two form goldens and
    check slice/write_through, crashes in each at convert.cpp:2838; and a
    fourth, the fold's `IndirectIndexWith(Core.IntLiteral)` probe removed,
    gives 1945 passed and 1 failed, check slice/write_through, whose
    `literal_subscript_literal_impl` split catches it. Re-run at re-review
    round 2 on 8deb75262's build (amended 2026-10-22, re-review round 2), the
    three whose translation unit round 2 changes, handle_index.cpp: the first
    gives 1916 passed and 30 failed, the same 30; the second, its abort
    isolated, 1937 passed and the same 8 failed, lower
    operators/string_indexing alone aborting at lower/handle.cpp:405; the
    fourth 1945 passed and 1 failed, check slice/write_through. The third
    reverts a call.cpp line, a file round 2 leaves untouched, and is not
    re-run.
6.  clang-tidy on the changed translation units, as CT-1 ran it. Over the
    build's compile database one check, `modernize-use-trailing-return-type`,
    stops clang-tidy 21.1.8 at `missing '(' after '__has_feature'`; with it
    excluded and named (`--checks=-modernize-use-trailing-return-type`, the
    repository's .clang-tidy otherwise), handle_index.cpp at f774ee836
    returns rc 0 with no user warning (amended 2026-10-22, re-review round 1:
    R1R2-m7).
7.  prek:
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <paths>` to a fixpoint with `XDG_CACHE_HOME` under the
    scratch, and the R31 counts before and after every markdown edit.
8.  `python3 fork/conformance/runner.py --self-test` after the programs are
    added.
9.  The composition mirrors were built at planning (§0.8.1, §0.8.2); at
    implementation each PR re-runs them on the then-current heads before it is
    opened, and DR-1b also on PR 51 (no golden moves), PR 55 (string_indexing)
    and PR 57 (lower array/iterate, for/break_continue and for/for), all
    measured at DR-1b's stop (§5; amended 2026-10-22, implementation:
    stop-and-amend: the m51 and m57 red sets; rev 3 named buf_field and
    slice/basic). A mirror whose two heads have not moved in toolchain/,
    core/ or fork/conformance/ since it was measured is not re-run (amended
    2026-10-22, re-review round 1: RR4-m2). The mct mirror was built on
    CT-1's 79740957a, which CT-1 has since passed (5c78c4086 at rev 3, §0.8):
    before M-a, the composition is re-run on CT-1's final head twice, once
    with DR-1a alone (M-a and L-a, the tree trunk has between DR-1a's merge
    and DR-1b's) and once with both PRs (M-b, C-b and L-b), each to a gate
    with 0 failed and a conformance run recorded beside §5's mct row
    (amended 2026-10-21, review fold: RR1-m4). At re-review round 2 the four
    mirrors were rebuilt in full on 8deb75262, whose change under toolchain/
    is comments only, on the unchanged heads, each as §5's rows state
    (amended 2026-10-22, re-review round 2).
10. The id re-scan for `W-32[4-9]` across every origin ref and worktree at the
    records commit.

### §8.1 What this plan measured and what it did not

Measured (container-local, EXPECTED, not of record): the probe matrix of §0.3
on seven toolchains; slice 2 relinked and gated (1942 of 1942) with conformance
128/0/22; v3 and v4 built and gated (v4: 1946 of 1946 after a two-pass fill,
conformance 130/0/22 over 152) with the slice-3 and `Buf` probes; 230227264's
splits and upstream's `IndirectIndexWith` tests filled; the composition on
CT-1's head (1963 of 1963, 149/0/20 over 169) after its root-caused template
fix; W-322's removal on PR 62's head (1950 of 1950, 133/0/22 over 155); the
root causes of the thunk failure, the slice-3 crash and the template index
failure; the `5 as const i32` crash on trunk and the nightly; review A's
probes (where_cont, copy_slot, nested_choice, tmpl_for, tmpl_match_dep).

Not measured, and why: the mutants of §8 item 5 (each is a relink of one
translation unit at implementation, against goldens §4 names); clang-tidy;
the joint merge of every held PR with DR-1a or DR-1b, of which the mirrors
measure each pair (R-6; rev 3 listed PR 51's, PR 55's and PR 57's predicted
refills here, measured at DR-1b's stop, amended 2026-10-22, implementation:
stop-and-amend: the m51 and m57 red sets); DR-1a merged onto CT-1 without
DR-1b, and any composition on a CT-1 head after 79740957a (§8 item 9 runs
both before M-a; amended 2026-10-21, review fold: RR1-m4); an optimized build
(the carbonbuild scripts build fastbuild only); the nightly on slice 3 (it
predates 6d80ceb58).

## Hand-off notes

-   Restore before measuring: rev 2's v4 state was made in this worktree and
    reverted after (`$Y/v4_full.diff` and `$Y/v4_numstat.txt` kept); DR-1a's
    implementer re-applies §2.1 from the plan, not from the scratch diff.
-   /home/user/carbon-build/carbon-dr holds v3's objects with v4's relinked
    file_test (0.0.0-0.dev+1e46ffd94.dirty); DR-1a's first `build.sh` rebuilds
    incrementally from it.
-   The mirrors (`$Y/mct`, `$Y/m62`) and /dev/shm/dr1-fixer are removed with
    this revision's commit.
-   B0 comes before B1, so B1's fill does not run into the crash of §0.6.1.
-   W-322's and W-323's commits do not wait for DR-1's code: they are made at
    R0 (§1.16).
-   Never write `.None` for `Core.Optional` in a fork page or program: RC-6.
    `StdOptional`'s `.None` stays.

## Appendix A: golden sources

(Amended 2026-10-21, review fold: A-M5 / B-M13 / A-m2 / B-m4 / A-M3.) Each file
starts with the license header, `// INCLUDE-FILE:
toolchain/testing/testdata/min_prelude/full.carbon` (which selects the full
production prelude, as every slice golden on trunk does; rev 1 had this
backwards), `// AUTOUPDATE` and the two `// TIP:` lines. Splits are `// ---
name.carbon`; `//@dump-sem-ir-begin`/`-end` bracket the dumped region; no CHECK
line is written here. Every source below was filled and gated on v4 or m62.

### A.0 230227264's three splits (DR-1b, B0)

Added to check/testdata/function/call/form.carbon before its
`fail_return_form_not_form` split, verbatim from 230227264:

<!-- google-doc-style-ignore -->

```carbon
// --- ref_return_class.carbon
library "[[@TEST_NAME]]";

class C {}

//@dump-sem-ir-begin
fn F() -> ref C;
//@dump-sem-ir-end

fn G() {
  //@dump-sem-ir-begin
  F();
  //@dump-sem-ir-end
}

// --- val_return_class.carbon
library "[[@TEST_NAME]]";

class C {}

//@dump-sem-ir-begin
fn F() ->? form(val C);
//@dump-sem-ir-end

fn G() {
  //@dump-sem-ir-begin
  F();
  //@dump-sem-ir-end
}

// --- ref_return_class_generic.carbon
library "[[@TEST_NAME]]";

class C {}

interface I {
  fn F(self) -> ref C;
}

fn G[T: I](x: T) {
  //@dump-sem-ir-begin
  x.F();
  //@dump-sem-ir-end
}
```

<!-- google-doc-style-resume -->

and to lower/testdata/function/call/form.carbon after its `val_return_form`
split, the same three without the dump markers (230227264's lower hunk),
the third followed, as upstream's is, by `class D` (a `C*` field and an
`impl as I` whose `F` returns `*self.p`) and `fn H(d: D) { G(d); }`, which
B0 left out and the implementation-review fold restored (amended 2026-10-22,
implementation-review fold: DR1B-m1).

### A.0b Upstream's `IndirectIndexWith` tests (DR-1b, B1)

check/testdata/operators/overloaded/indirect_index_with.carbon is upstream's
file at ac31fd198 with its CHECK lines removed by `$Y/bin/strip_checks.py`
(splits `types`, `ref_copyable`, `ref_non_copyable`, `at_from_blanket_impl`,
`fail_at_non_copyable`, `subscript_copyable`, `subscript_non_copyable`,
`subscript_assign`). lower/testdata/index/indirect_index_with.carbon likewise:

<!-- google-doc-style-ignore -->

```carbon
class Span {
  var ptr: i32*;
}

impl Span as Core.IndirectIndexWith(i32) where .ElementType = i32 {
  fn Ref(self, unused subscript: i32) -> ref i32 {
    return *self.ptr;
  }
}

fn Store(s: Span, v: i32) {
  s.(Core.IndirectIndexWith(i32).Ref)(0) = v;
}

fn Load(s: Span) -> i32 {
  return s.(Core.IndirectIndexWith(i32).Ref)(0);
}

fn LoadViaAt(s: Span) -> i32 {
  return s.(Core.IndexWith(i32).At)(0);
}

fn StoreSubscript(s: Span, i: i32, v: i32) {
  s[i] = v;
}

fn LoadSubscript(s: Span, i: i32) -> i32 {
  return s[i];
}
```

<!-- google-doc-style-resume -->

### A.1 toolchain/check/testdata/slice/write_through.carbon (DR-1b)

<!-- google-doc-style-ignore -->

```carbon
// --- write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Write(s: Core.Slice(i32), i: i64) {
  s[i] = s[0] + 1;
}
//@dump-sem-ir-end

// --- generic_write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  s[0] = v;
}
//@dump-sem-ir-end

// --- generic_write_const_element.carbon
library "[[@TEST_NAME]]";

// The generic const-element write's current behavior, pinned: the body
// writes through `Slice(T)`; the specific at `T = const i32` is not diagnosed.
fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  s[0] = v;
}

fn G(c: Core.Slice(const i32)) {
  Fill(c, c[1]);
}

// --- fail_const_element.carbon
library "[[@TEST_NAME]]";

fn W(s: Core.Slice(const i32)) {
  s[0] = 1;
}

// --- buf_write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn BufWrite(b: Core.Buf(i32)) {
  b[0] = 7;
}
//@dump-sem-ir-end

// --- literal_subscript_literal_impl.carbon
library "[[@TEST_NAME]]";

// The literal-subscript rule converts a literal to `i64` only for an operand
// with no impl for the literal itself. `H` has its own
// `IndirectIndexWith(Core.IntLiteral)` impl, and its element is not `Copy`, so
// the blanket `IndexWith` impl does not cover it: `h[0]` calls that impl's
// `Ref`, as written, not the `i64` impl's.
class NC {
  var v: i32;
}

class H {
  var p: NC*;
  var q: NC*;
}

impl H as Core.IndirectIndexWith(Core.IntLiteral) where .ElementType = NC {
  fn Ref(self, unused i: Core.IntLiteral) -> ref NC { return *self.p; }
}

impl H as Core.IndirectIndexWith(i64) where .ElementType = NC {
  fn Ref(self, unused i: i64) -> ref NC { return *self.q; }
}

fn F(h: H) -> i32 {
  //@dump-sem-ir-begin
  return h[0].v;
  //@dump-sem-ir-end
}

// --- fail_final_index_with_overlap.carbon
library "[[@TEST_NAME]]";

// The prelude's index.carbon is upstream's: its blanket `final` impl
// implements `IndexWith` for every `IndirectIndexWith` type with a `Copy`
// element, and its type structure overlaps any other `final` impl of
// `IndexWith` in another file. So this impl, which the prelude accepted before
// it took upstream's `IndirectIndexWith`, is rejected, as upstream rejects it.
class V {
  var x: i32;
}

final impl V as Core.IndexWith(i64) where .ElementType = i32 {
  fn At(self, i: i64) -> i32 { return self.x + (i as i32); }
}
```

<!-- google-doc-style-resume -->

The implementation-review fold added the last two splits (DR1B-M1 and DR1B-m3,
amended 2026-10-22); the fill gives the first a dump whose call is the
`Core.IntLiteral` impl's `Ref` with the literal as written, and the second
`FinalImplOverlapsDifferentFile` with the note at index.carbon:19. The
generic_write_const_element split's comment names no ledger id since round 2's
fix 8deb75262 (amended 2026-10-22, re-review round 2: R1R2-m2); it read "W-327's
current behavior, pinned: the generic body writes through `Slice(T)`, and the
specific at `T = const i32` is not diagnosed.", and its two lines are
rewrapped within themselves, so no line of the golden moves.

### A.2 toolchain/lower/testdata/slice/write_through.carbon (DR-1b)

<!-- google-doc-style-ignore -->

```carbon
fn Write(s: Core.Slice(i32), i: i64) {
  s[i] = 5;
}

fn Read(s: Core.Slice(i32)) -> i32 {
  return s[1];
}
```

<!-- google-doc-style-resume -->

### A.3 toolchain/check/testdata/match/fail_todo_core_optional.carbon (PR 62's W-322 commit)

<!-- google-doc-style-ignore -->

```carbon
// Fork (DR-1 D-DR-15, W-322): `Core.Optional(T)` is not matched until it
// implements `Core.Match` as docs/design/sum_types.md designs it for classes
// (W-320, which waits on W-324). D-SV-7's `StdOptional` view, a second
// spelling of that route, is retired (R32 (d)).

// --- fail_todo_match.carbon

library "[[@TEST_NAME]]";

fn F(o: Core.Optional(i32)) -> i32 {
  match (o) {
    case .Some(value: i32) => {
      return value;
    }
    default => {
      return -1;
    }
  }
  return -2;
}

// --- fail_todo_if_let.carbon

library "[[@TEST_NAME]]";

fn G(p: Core.Optional(i32*)) -> i32 {
  if (let .Some(q: i32*) = p) {
    return *q;
  }
  return 0;
}
```

<!-- google-doc-style-resume -->

## Appendix B: programs and oracles

(Amended 2026-10-21, review fold: B-M11 / B-B2.) Each program starts with the
license header. B.1 and B.2 PASS on v4 and on the mct mirror (§0.6.2, §0.8.1);
their EXPECTs are hand-derived in their comments, and B.1's `Buf` lines now
write both through `b[i]` and through `Set` (rev 1's text, unchanged in
output). Rev 1's B.0 and B.3 to B.5 belonged to slice 1 and are withdrawn.

### B.1 fork/conformance/programs/stdlib/slices_write_through.carbon (DR-1b)

<!-- google-doc-style-ignore -->

```carbon
// CONFORMANCE-BULLET: Stdlib: Slices
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   20
//   21
//   15
//   27
//
// Writes through `Core.Slice` and `Core.Buf` subscripts (DR-1 D-DR-7: `Ref`
// returns `ref T`, upstream 6d80ceb58 and 309d3d63c). Hand-derived: `a` is
// (1, 2, 3); `s[1] = 20` makes it (1, 20, 3); `s[2] = s[0] + s[1]` makes it
// (1, 20, 21); the `Buf` gets 7 at 0 by `b[0] = 7` and 8 at 1 by `Set`, and
// `b[2] = b[0] + b[1]` stores 15; `Fill` writes 9 into all three elements of
// `c`, whose sum is 27.

import Core library "io";

fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  var i: i64 = 0;
  while (i < s.Size()) {
    s[i] = v;
    ++i;
  }
}

fn Run() -> i32 {
  var a: array(i32, 3) = (1, 2, 3);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  s[1] = 20;
  let i: i64 = 2;
  s[i] = s[0] + s[1];
  Core.Print(a[0]);
  Core.Print(a[1]);
  Core.Print(a[2]);
  var b: Core.Buf(i32) = Core.Buf(i32).Make(3, 0);
  b[0] = 7;
  b.Set(1, 8);
  b[2] = b[0] + b[1];
  Core.Print(b[2]);
  var c: array(i32, 3) = (1, 2, 3);
  Fill(Core.Slice(i32).FromArray(&c), 9 as i32);
  Core.Print(c[0] + c[1] + c[2]);
  return 0;
}
```

<!-- google-doc-style-resume -->

### B.2 fork/conformance/programs/interop/cpp_span_write_through_diff.carbon and .diff.cpp (DR-1b)

(Amended 2026-10-22, implementation: stop-and-amend: stage B errata.) The
`.diff.cpp` below is the file as committed at B-P (4c358f94b) without its
license header: prek's clang-format 21.1.8 (`InsertBraces`) braced the two
one-line `for` bodies rev 3 wrote, so the file is 30 lines.

<!-- google-doc-style-ignore -->

```carbon
// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view)
// COMPILE-ARGS: --clang-arg=-std=c++20
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   18
//
// A write through `s[0]` is seen by C++ through the `std::span<int>` the
// slice maps to (DR-1 D-DR-7, SL-2's mapping). Hand-derived: (1, 2, 3)
// becomes (10, 2, 3); `Bump` adds one to each element, (11, 3, 4); `Sum` is
// 18. Differential pair: cpp_span_write_through_diff.diff.cpp (DIFF-1).

import Core library "io";
import Cpp inline '''
#include <span>
inline auto Sum(std::span<int> s) -> int {
  int t = 0;
  for (int x : s) t += x;
  return t;
}
inline auto Bump(std::span<int> s) -> void {
  for (int& x : s) x += 1;
}
''';

fn Run() -> i32 {
  var a: array(i32, 3) = (1, 2, 3);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  s[0] = 10;
  Cpp.Bump(s);
  Core.Print(Cpp.Sum(s));
  return 0;
}
```

```cpp
// Differential C++17 equivalent of cpp_span_write_through_diff.carbon: the
// span is a pointer and a size (no <span> under -std=c++17).

#include <cstdio>

auto Sum(int* p, long long n) -> int {
  int t = 0;
  for (long long i = 0; i < n; ++i) {
    t += p[i];
  }
  return t;
}

auto Bump(int* p, long long n) -> void {
  for (long long i = 0; i < n; ++i) {
    p[i] += 1;
  }
}

auto main() -> int {
  int a[3] = {1, 2, 3};
  a[0] = 10;
  Bump(a, 3);
  std::printf("%d\n", Sum(a, 3));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B.3 PR 62's control_flow/match_core_optional_diff.carbon (W-322's commit)

The SKIP line and the respelled empty arms, measured on m62 (the program then
SKIPs with this reason; its `.diff.cpp` is unchanged):

<!-- google-doc-style-ignore -->

```diff
diff --git a/fork/conformance/programs/control_flow/match_core_optional_diff.carbon b/fork/conformance/programs/control_flow/match_core_optional_diff.carbon
index ddd5de264..384f6d57c 100644
--- a/fork/conformance/programs/control_flow/match_core_optional_diff.carbon
+++ b/fork/conformance/programs/control_flow/match_core_optional_diff.carbon
@@ -3,6 +3,7 @@
 // SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

 // CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
+// SKIP: W-320 (blocked on W-324): `Core.Optional` is matchable only once it implements `Core.Match` as docs/design/sum_types.md designs it for classes; PR 62's D-SV-7 `StdOptional` view, which this program was written against, is retired as a second spelling of that route (fork/rulebook.md R32 (d), DR-1 D-DR-15, W-322), so the toolchain refuses the scrutinee with `semantics TODO: match on unsupported scrutinee type`. The empty arms are spelled `.None()` for the `Match` route (`None` is a function, docs/design/sum_types.md:214-222). Un-SKIP when W-320 lands.
 // EXPECT-EXIT: 0

 // SV-1 (fork/sumtype-interop/plan.md D-SV-7, W-177): a `Core.Optional(T)`
@@ -33,7 +34,7 @@ fn Show(o: Core.Optional(i32)) {
     case .Some(value: i32) => {
       Core.Print(value);
     }
-    case .None => {
+    case .None() => {
       Core.Print(-1);
     }
   }
@@ -44,7 +45,7 @@ fn ShowPointer(p: Core.Optional(i32*)) {
     case .Some(q: i32*) => {
       Core.Print(*q);
     }
-    case .None => {
+    case .None() => {
       Core.Print(0);
     }
   }
@@ -62,7 +63,7 @@ fn CountSome(o: Core.Optional(i64)) -> i32 {
     case .Some(unused value: i64) => {
       return 1;
     }
-    case .None => {
+    case .None() => {
       return 0;
     }
   }
```

<!-- google-doc-style-resume -->

## Appendix C: records texts

Placeholders are `<...>`; every date is the commit's UTC date. Each block below
is pasted as written, then R31's counts are taken on the file it lands in.
(Rewritten 2026-10-21, review fold: A-B1 / B-B1 / A-m3 / B-M8 / B-M9 / B-M10 /
B-M12 / A-M3 / B-B2.)

### C.1 Decision-log entry (R0, then completed at each discharge)

Placed after DR-0 in "Decided":

<!-- google-doc-style-ignore -->

```markdown
### DR-1: direction realignment: the ref cursor, IndirectIndexWith, D-SV-7 retired, Match stopped on upstream's conflict (<date>)

The workstream D-DR-1 scheduled (fork/direction/plan.md, rev 3, signed off
2026-10-21). Upstream's direction was read at upstream/trunk bc45989b2, the
tip at sign-off (rev 2 read ac31fd198). Decisions D-DR-5..D-DR-22,
auto-adopted under R29(a), each with its break condition in the plan: two PRs,
DR-1a (the `ref` cursor)
on trunk's base and DR-1b (`IndirectIndexWith`) stacked on it (D-DR-5); the
`ref` cursor as df3cf9294 (D-DR-6); `IndirectIndexWith` as 6d80ceb58 and
309d3d63c with 230227264's code and upstream's tests, `Core.Slice` and
`Core.Buf` writable through `Ref` (indexing.md's `std::span` category, D-SL-6's
by-value writes), D-SL-3 retired by its own break condition, D-SL-17 filed as a
drift (W-326) (D-DR-7); none of rev 1's language prerequisites for
sum_types.md's `Match` (D-DR-8): a template associated constant contradicts
docs/design/README.md:1076-1078 and :3064-3067, generics/terminology.md:100-103
and upstream's parser, and an impl member giving an associated constant its
value is what accepted proposal p001013 removed, so D-DR-22's stop rule fired at
the plan and W-320 waits on upstream's resolution (W-324); D-DR-9..D-DR-14
withdrawn with slice 1, their resumption bound by the plan's RC-1..RC-12, and
the `Try` body kept on `HasValue()`/`Get()` (D-DR-13 withdrawn: its sketch is
the fork's own page); D-SV-7's view removed now by a removal-only commit on PR
62's branch, F-020's bridge kept (D-DR-15); no new diagnostic kind (D-DR-16);
goldens, programs, docs and records (D-DR-17..D-DR-19); merge after CT-1 by
merge commits with a composition commit that indexes a template-dependent
operand per specific (D-DR-20); W-324..W-327 and W-329 filed, W-328 reserved, no
F-022 (D-DR-21).

Amendments of DR-0, dated <date>: D-DR-1's slice 1 is stopped at DR-1's plan by
D-DR-22, not re-spelled; its "`.Some(<pattern>)` and `.None` patterns" reads
`.None()` for `Core.Optional` while the prelude's `None` is a function
(docs/design/sum_types.md:214-222), and its "the `Try` body rewritten" is
withdrawn (D-DR-13); its "on trunk's base" holds for both PRs. D-DR-2's
retirement of the view no longer waits for W-320: R32 (e) removes it before PR
62 lands (D-DR-15).

V-3a register: (ii) D-SL-3 resolved by DR-1b (<sha>); (iii) the pointer cursor
resolved by DR-1a (<sha>); (i) D-SV-7 resolved by PR 62's commit <sha>; (iv)
added: `Core.Optional` not matchable because upstream's pages conflict on
`Match.Continuation`, W-320 (blocked) and W-324; (v) added: D-SL-17's
literal-subscript rule, a fork spelling of `like i64`, W-326.

Measured at planning (container-local, EXPECTED, not of record): slice 2 gate
1942 of 1942 and conformance 128/0/22 over 150; slices 2 and 3 gate 1946 of
1946 and conformance 130/0/22 over 152; composed on CT-1's head 1963 of 1963
and 149/0/20 over 169; PR 62 with W-322's commit 1950 of 1950 and 133/0/22 over
155; at discharge: <the PR's own runs>.
```

<!-- google-doc-style-resume -->

### C.2 Ledger (fork/inventory/work-items.json)

New items, R0 (each with `"blocked_by": []` unless stated; `"bullet"` as named):

<!-- google-doc-style-ignore -->

```json
{"id": "W-324", "kind": "todo-stub", "size": "S", "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
 "title": "V-3a register entry (iv): upstream's pages conflict on how `Match` declares `Continuation` -- docs/design/sum_types.md:113 writes `let template Continuation: type;`, while docs/design/README.md:1076-1078 and :3064-3067 and docs/design/generics/terminology.md:100-103 say an associated constant is always a checked generic binding and cannot be made `template`, as upstream's parser enforces (toolchain/parse/handle_let.cpp:27-46); W-320 waits on upstream's resolution",
 "subsystem": "upstream design (docs/design/sum_types.md, README.md, generics/terminology.md) + toolchain/parse",
 "evidence": ["upstream docs/design/sum_types.md:107-117 at ac31fd198", "upstream docs/design/README.md:1076-1078, :3064-3067 at ac31fd198", "upstream docs/design/generics/terminology.md:100-106 at ac31fd198 (leads issue 6932)", "upstream proposals/p001013-generics-set-associated-constants-using-where-constraints.md:79-82", "fork/direction/plan.md §0.7, §1.4"],
 "notes": "Filed <date> by DR-1 (D-DR-8, D-DR-21). Checked at each weekly upstream check (R32 (b)). Break condition: upstream changes sum_types.md's `Match` declaration, admits template associated constants, or implements `Match` or its loop TODO; W-320 is then re-planned from fork/direction/plan.md §1.4's RC-1..RC-12."}
{"id": "W-325", "kind": "missing-feature", "size": "S", "bullet": "none",
 "title": "`5 as const i32` (an integer literal converted to a `const` integer type) aborts lowering: `Missing constant value for call to comptime-only function` (toolchain/lower/handle_call.cpp:638; upstream's nightly 2026.10.12 at its :598)",
 "subsystem": "toolchain/lower (handle_call.cpp) + toolchain/check (as conversion of a literal)",
 "evidence": ["fork/direction/plan.md §0.6.2 (const_literal_plain, s_generic_const)"], "notes": "Filed <date> by DR-1; found by its audit, not caused by it: it reproduces on trunk and on upstream's nightly with no slice involved."}
{"id": "W-326", "kind": "todo-stub", "size": "S", "bullet": "Stdlib: Slices",
 "title": "V-3a register entry (v): D-SL-17's literal-subscript rule (toolchain/check/handle_index.cpp: an integer literal subscript converts to `i64` when the operand implements `IndirectIndexWith(i64)` or `IndexWith(i64)` and has no `IndirectIndexWith(Core.IntLiteral)` or `IndexWith(Core.IntLiteral)` impl) is a fork spelling of indexing.md's `like i64` subscript; retire it when `like` lands, declaring the impls `IndirectIndexWith(like i64)`",
 "subsystem": "toolchain/check (handle_index.cpp) + core/prelude (types/slice.carbon, types/buf.carbon)",
 "evidence": ["upstream docs/design/expressions/indexing.md:103-121 at ac31fd198", "fork/slices/plan.md D-SL-17", "fork/direction/plan.md §1.3"],
 "notes": "Filed <date> by DR-1 (D-DR-7) before W-109's discharge: W-109's notes said D-SL-17 yields to the specified rewrite, which needs `like`; blocked on `like` (W-178, OP-1's ledger on PR 56, not yet on trunk, so not a `blocked_by` id here). Title amended 2026-10-22 (DR-1b implementation-review fold, DR1B-M1): the rule also leaves a literal as written when the operand has its own `IndirectIndexWith(Core.IntLiteral)` impl, which a non-`Copy` element's blanket `IndexWith` does not cover (toolchain/check/handle_index.cpp:155-166, pinned by toolchain/check/testdata/slice/write_through.carbon's literal_subscript_literal_impl split)."}
{"id": "W-327", "kind": "missing-feature", "size": "M", "bullet": "none",
 "title": "A generic assignment whose specific's target is `const` writes: `*p = v` through `const T*` (trunk and the upstream nightly print 7) and `s[i] = v` through `Core.Slice(const T)` (DR-1b prints 2); the per-specific `const` check",
 "subsystem": "toolchain/check (handle_operator.cpp assignment, specific checking)",
 "evidence": ["fork/direction/plan.md §0.6.1, §0.6.2 (s_ptr_const_write, s_generic_const2)", "toolchain/check/testdata/slice/write_through.carbon generic_write_const_element"], "notes": "Filed <date> by DR-1 (D-DR-7). Not a reason for a read-only Slice (R32 (d))."}
{"id": "W-329", "kind": "missing-feature", "size": "S", "bullet": "Control flow: matching — good switch equivalents",
 "title": "Reachability after an exhaustive `match` whose arms all diverge: \"missing `return` at end of function with declared return type\" (a two-alternative choice on trunk)",
 "subsystem": "toolchain/check (handle_match.cpp, control_flow.cpp)", "evidence": ["fork/direction/plan.md §0.3 (c_exh_return)"], "notes": "Filed <date> by DR-1; found by its audit, not caused by it."}
```

<!-- google-doc-style-resume -->

Dated notes at R0. W-320: `"blocked_by": ["W-324"]`, and appended to `notes`:
"Stopped <date> at DR-1's plan (fork/direction/plan.md rev <n>, §1.4, D-DR-22):
sum_types.md's `Match` needs a template associated constant, which upstream's
README.md and generics/terminology.md rule out and its parser refuses, and
implementing it would be a new drift (R32); W-324 watches upstream's resolution.
Amended reading: the empty alternative's pattern is `.None()` while the
prelude's `None` is a function (sum_types.md:214-222); the `Try` body is not
rewritten (D-DR-13 withdrawn)." W-322: `"blocked_by": []`, and "Amended <date>
by DR-1 (D-DR-15): removed now by a removal-only commit on PR 62's branch (R32
(e)), not when W-320 lands; F-020's bridge kept." Discharge notes, each appended
at the PR's D commit: W-321 "DISCHARGED <date> by DR-1a (<sha>):
`Core.Iterate.Next` takes `ref cursor` at the 11 sites, the loop checker passes
the cursor variable (upstream df3cf9294 re-expressed); the thunk failure was the
interface/impl signature mismatch and needed no thunk change; gate <n> of <n>,
conformance <p>/<f>/<s> over <t>." W-109 "DISCHARGED <date> by DR-1b (<sha>):
subscripting prefers `IndirectIndexWith(I).Ref` (309d3d63c), the prelude
interface and its blanket `IndexWith` impl (6d80ceb58), 230227264's code with
upstream's tests; `Core.Slice` and `Core.Buf` write through `Ref`; D-SL-3's pin
deleted; D-SL-17's rule does not yield yet and is filed W-326; the generic const
write filed W-327." W-322 "DISCHARGED <date> by PR 62's commit <sha> (C.6)."
W-323 "DISCHARGED <date> by PR 56's commit <sha> (C.7, C.8)."

### C.3 Gap rows (fork/gap-analysis.md)

Each row keeps its status unless its own text says otherwise; only the
sentences quoted are replaced.

-   **Control flow: loops (:66), DONE.** Current sentence: "Direction drift
    (R32, DR-0, 2026-10-21): upstream's `Core.Iterate.Next` takes `ref cursor`
    (df3cf9294, proposal p007381) where the fork's prelude, tests and one
    program take a pointer at 11 sites, and upstream's loops.md desugars `for`
    through `case .Some(<pattern>)`; W-321 (DR-1 slice 2) owns the signature and
    W-320 the desugaring." At DR-1a: "`Core.Iterate.Next` takes `ref cursor` as
    upstream does (DR-1a, <date>, W-321 discharged). The `for` desugaring
    through `case .Some(<pattern>)` is W-320's, which waits on upstream's own
    conflict over `Match` (W-324); until then the toolchain calls `HasValue()`
    and `Get()`, as upstream's checker does under its TODO."
-   **Control flow: matching sum-type consumption (:68), PARTIAL.** Current
    sentence: "Direction drift (R32, DR-0, 2026-10-21): `.Some`/`.None` patterns
    over `Core.Optional` are upstream's designed route (sum_types.md's `Match`
    for classes; loops.md since df3cf9294), and the held PR 62's D-SV-7
    scrutinee view is a second spelling, recorded as a V-3a divergence; W-320
    (DR-1 slice 1) owns the route and W-322 the view's retirement." At R0:
    "Direction drift (R32, DR-0): matching `Core.Optional` is upstream's
    `Match` route (sum_types.md), which upstream's own pages cannot currently
    express (a template associated constant that README.md and
    generics/terminology.md rule out); W-320 waits on W-324, and the held PR
    62's D-SV-7 view, a second spelling, is removed by a commit on its branch
    (W-322, <date>)." On PR 62's branch, C.6 edits the SV-1 sentence of the same
    row.
-   **Stdlib: Optional (:78), PARTIAL on trunk, DONE on PR 57.** Current
    sentence: "Direction drift (R32, DR-0, 2026-10-21): the class KEPT by D-EH-1
    and by the held PR 56's D-OP-7 is not matchable, while upstream's loops.md
    matches it by `case .Some(<pattern>)` (df3cf9294) and sum_types.md designs a
    class with `impl as Match`; W-320 (DR-1 slice 1) owns it, keeping the class,
    the niche and the `Try` signature." At R0: "Direction drift (R32, DR-0): the
    class KEPT by D-EH-1 and D-OP-7 is not matchable, while upstream's loops.md
    matches it by `case .Some(<pattern>)` and sum_types.md designs a class with
    `impl as Match`, a design upstream's own README.md and
    generics/terminology.md cannot currently admit; W-320 waits on W-324, and
    the pattern for the empty alternative will be `.None()`." The status is not
    DR-1's to move; PR 57's merge keeps this sentence beside its DONE text
    (§1.16).
-   **Stdlib: Slices (:79), PARTIAL to DONE at DR-1b.** Its own criterion: "this
    row stays PARTIAL until write-through indexing lands (W-109)". At DR-1b the
    status becomes DONE; "`s[i]` reads by value through a `final impl ... as
    IndexWith(i64)`" becomes "`s[i]` and `b[i]` are durable references through
    `final` impls of `IndirectIndexWith(i64)` whose `Ref` returns `ref T`
    (DR-1b, W-109 discharged; upstream 6d80ceb58 and 309d3d63c), so `s[i] = v`
    writes through"; the 0.1-limits entry "slices are read-only (`s[i] = v`
    diagnoses; no `IndirectIndexWith`/`ref` returns, W-109);" is deleted and
    "the literal-subscript rule is a fork spelling of `like i64` (W-326);"
    added; "this row stays PARTIAL until write-through indexing lands (W-109)"
    becomes "write-through indexing landed at DR-1b, which was this row's
    remaining condition; the 0.1 limits above stay filed items"; the DR-0 drift
    sentence is replaced by "DR-1b resolved the drift DR-0 recorded (V-3a
    (ii))." The conformance figures are the PR's own.

### C.4 The V-3a register (decision log, DR-0's block)

At R0, appended to DR-0's register paragraph as dated lines: "(iv)
`Core.Optional` is not matchable because upstream's pages conflict on
`Match.Continuation` (docs/design/sum_types.md:113 against README.md:1076-1078
and :3064-3067, generics/terminology.md:100-103 and the parser at ac31fd198);
work items W-320 (blocked) and W-324, owner DR-1, checked at each weekly
upstream check (added <date>, DR-1 plan)." "(v) D-SL-17's literal-subscript
rule, a fork spelling of indexing.md's `like i64`; work item W-326, blocked on
`like` (added <date>, DR-1 plan)." At each discharge: "(<n>) resolved <date>
by <PR, sha>."

### C.5 ORCHESTRATION (Next actions)

"DR-1 (fork/direction/plan.md, rev <n>): two PRs after CT-1, DR-1a the `ref`
cursor (W-321) and DR-1b `IndirectIndexWith` (W-109, stacked on DR-1a); now,
W-322's removal-only commit on PR 62's branch and W-323's records commit on PR
56's branch, merged into PR 57's; W-320 (`Core.Optional` matchable by `Match`)
stopped at the plan on upstream's own conflict, watched by W-324 at each weekly
upstream check. W-322's commit gets one focused review once its run is green
(R29(c)); after it and W-323's commit, PR 62's, PR 56's and PR 57's
descriptions and first comments are refreshed and re-posted, and their rows
stamped." (Amended 2026-10-21, review fold: RR1-m5: the last sentence.)

### C.6 PR 62's commit (W-322)

Message: "SV-1: retire the D-SV-7 `Core.Optional` view (R32 (d), (e); DR-1
D-DR-15, W-322)". sum_types.md amendment, after PR 62's section on
`std::optional`:

<!-- google-doc-style-ignore -->

```markdown
> **Fork amendment (<date>, DR-1 D-DR-15).** The view described above, which
> matched a `Core.Optional(T)` scrutinee as `Core.CppCompat.StdOptional(T)`,
> is retired: it was a second spelling of the `Match` route this page
> designs for classes (fork/rulebook.md R32 (d)). A `Core.Optional(T)`
> scrutinee is not matched until `Core.Optional` implements `Match` (W-320),
> which waits on a conflict in upstream's own pages over how `Match` declares
> `Continuation` (W-324). A `std::optional` scrutinee is still matched as
> `StdOptional(T)` (`.Some(<pattern>)`, `.None`), and a `Core.Optional(T)`
> still converts to and from a C++ `std::optional<T'>` as described above.
```

<!-- google-doc-style-resume -->

On PR 62's branch, in the same commit (amended 2026-10-21, review fold:
RR1-M1): gap row 68's "Still PARTIAL on W-177, narrowed: `Core.Optional(T)` is
matched for a concrete scalar or pointer `T` only, by value; generic and
aggregate payloads, `ref` bindings and copy-free matching stay open." becomes
"`Core.Optional(T)` itself is not matched: D-SV-7's view was retired (W-322,
R32 (d)), and W-320 waits on W-324."; its "11 conformance programs PASS (...
match_core_optional_diff ...)" becomes 10, with match_core_optional_diff named
as SKIP, and its "SV-1: container-built, 134/0/21 over 155" becomes "133/0/22
over 155" (§0.8.2); its plan's §1.7 and the decision log's SV-1 entry gain
"Retired <date> by W-322's commit (DR-1 D-DR-15, R32 (d), (e)); F-020's bridge
kept."

PR 62's ledger holds no W-177 and no W-320..W-323: fd290b6e6, which filed
W-320..W-323, is not an ancestor of 3a6531157, and W-177 is OP-1's, on PR 56's
and PR 57's branches only (`$Z/logs/rr1_m1.txt`; PR 62's own ledger header
calls W-177's narrowing note a land-time record "because those items are not
in this ledger"). The commit therefore adds no entry to that ledger: W-322 is
discharged in trunk's ledger alone (C.2), and W-177's correction is W-323's
commit's, in PR 56's ledger (C.7). It amends instead PR 62's own records that
the retirement makes false, each by a dated note:

-   **PR 62's plan §1.16, the W-177 paragraph** ("**W-177 (OP-1's, on row
    68's bullet) stays OPEN** with a dated narrowing note (Appendix C.5 ..."),
    gains: "Amended <date> (DR-1 D-DR-15, W-322): not narrowed. The view is
    retired, so no `.Some`/`.None` pattern matches a `Core.Optional(T)`; W-177
    stays OPEN, unnarrowed, closes with W-320 and still bounds row 68, and its
    evidence gains match/fail_todo_core_optional.carbon."
-   **PR 62's plan Appendix C.5** ("W-177: the narrowing note (OPEN)"), which
    PR 62's land-time records commit appends to W-177 on the merged trunk (its
    §3 item 8 list: "C.5's W-177 note and evidence"), gains under its heading:
    "Amended <date> (DR-1 D-DR-15, W-322): withdrawn. The note below is not
    appended at land time, and neither evidence path is added
    (match/core_optional_view.carbon is deleted, match_core_optional_diff is
    SKIPped); at land time W-177's `evidence` gains
    toolchain/check/testdata/match/fail_todo_core_optional.carbon only, and its
    `notes` keep W-323's correction (fork/direction/plan.md C.7)."
-   **PR 62's plan §3 item 8, F-M, and §1.7's paragraph that repeats it.** The
    refill of match/core_optional_view.carbon, the `bool` payload added to its
    `concrete` split and the `bool` leg added to match_core_optional_diff and
    its oracle are withdrawn by a dated note, the golden being deleted and the
    program SKIPped; F-M refills match/fail_todo_core_optional.carbon in their
    place only if PR 57's merge changes it, as autoupdate decides (R16), and
    stdlib/optional.carbon's refill is unchanged.
-   **W-280, in PR 62's ledger and in its plan's §1.16 table.** Its
    `Core.Optional` half is moot: no `Core.Optional` scrutinee is matched, so
    none reaches a `ref` payload binding. Its title loses " or a
    `Core.Optional`"; its first evidence string's "sum type or view" becomes
    "sum type"; its third loses "and match/core_optional_view.carbon"; its
    `notes` gain "Amended <date> (DR-1 D-DR-15, W-322): the `Core.Optional`
    half is moot, the view being retired; a `ref` payload binding on
    `Core.Optional` is W-177's scope, which closes with W-320."; and the plan
    row's "for `Core.Optional` it is part of W-177's remaining scope (below)"
    and §1.6's citation of match/core_optional_view.carbon for W-280 gain
    "(moot since W-322's commit, <date>: the view is retired)".

### C.7 PR 56's records commit (W-323, D-DR-3), verbatim

Message: "OP-1 records: correct the loops.md amendment, the V-3 paragraph,
optional.md's matchability text and W-177's route (R32 (a), (e); DR-0 D-DR-3,
W-323; DR-1)" (amended 2026-10-21, review fold: RR1-M1).
docs/design/control_flow/loops.md:116-118 on PR 56's branch, the block

<!-- google-doc-style-ignore -->

```markdown
> **Fork amendment (2026-10-13, F-015).** In the fork, `Core.Optional`'s API is
> designed in [Optional](../optional.md): `HasValue()` and `Get()` above are
> that API, and the toolchain's `for` calls them by name.
```

<!-- google-doc-style-resume -->

is replaced by

<!-- google-doc-style-ignore -->

```markdown
> **Fork amendment (2026-10-13, F-015; corrected <date>, DR-0 D-DR-3).** The
> desugaring above is the text this page had at the fork's cut. Upstream's
> page, since df3cf9294 (2026-10-07, proposal p007381), desugars `for` to
> `match (range.(Iterate.Next)(cursor)) { case .Some(<pattern>) => { ... }
> default => { break; } }` with a `ref` cursor (upstream loops.md:116-120 at
> ac31fd198). The fork's toolchain calls `Core.Optional`'s `HasValue()` and
> `Get()` (designed in [Optional](../optional.md)), as upstream's checker does
> under its TODO, until `Core.Optional` is matchable (W-320); those calls are
> an implementation stage, not the design.
```

<!-- google-doc-style-resume -->

fork/optional/plan.md on PR 56's branch, after the V-3 paragraph (its :192-214),
a new paragraph:

<!-- google-doc-style-ignore -->

```markdown
Correction (<date>, DR-0 D-DR-3, W-323): the sentence "p006357's ABI constraint
and loops.md's `HasValue()`/`Get()` are kept" compared against the fork's copy
of loops.md, not upstream's. At upstream-trunk 62f1cc6a3, which the paragraph
names and which contains df3cf9294 (2026-10-07, proposal p007381), loops.md
reads "is desugared to a loop that manages the cursor and checks the optional
return values:" followed by `match (range.(Iterate.Next)(cursor)) { case
.Some(<pattern>) => { <statements> } default => { break; } }` (upstream
loops.md:109-122), so `HasValue()`/`Get()` were no longer upstream's text when
this check was made. The fork's `for` keeps calling them until W-320 lands;
under R32 the comparison is made against upstream's tip by sha, quoting the
page.
```

<!-- google-doc-style-resume -->

fork/inventory/work-items.json on PR 56's branch, in the same commit (amended
2026-10-21, review fold: RR1-M1): W-177's `notes` gain, after its break
condition, the text below, and its `evidence` gains "fork/direction/plan.md
§1.4, §1.11". PR 57's ledger takes both by its merge of PR 56's branch.

<!-- google-doc-style-ignore -->

```text
Amended <date> by DR-1 (W-323; R32, DR-0 D-DR-1): this item closes with W-320,
`Core.Optional` implementing docs/design/sum_types.md's `Match` for classes;
the break condition's `choice` alternative is withdrawn, DR-0 having rejected
the `choice` conversion. The patterns are `.Some(<pattern>)` and `.None()`,
`None` being a function (sum_types.md:214-222). W-320 waits on W-324, a
conflict in upstream's own pages over how `Match` declares `Continuation`.
PR 62's D-SV-7 view does not narrow this item: it is retired before PR 62
lands (W-322), whose commit withdraws PR 62's land-time narrowing note.
```

<!-- google-doc-style-resume -->

### C.8 optional.md on PR 56's branch (in W-323's commit)

(Amended 2026-10-21, review fold: B-M12 / B-B2 / A-m3.) After the "Pattern
matching" section's second paragraph (PR 56's docs/design/optional.md:425-441;
PR 57's :444-458 after its merge of PR 56's branch), one amendment that covers
each passage naming `.Some` and `.None` patterns (PR 56's :98, :182, :427-430,
:495-497; PR 57's :101, :187, :444-447, :501-503):

<!-- google-doc-style-ignore -->

```markdown
> **Fork amendment (<date>, DR-0 D-DR-1, DR-1).** Under fork/rulebook.md R32,
> matchability is not a fork limit chosen here: upstream designs `Optional`'s
> matching as a class implementing `Match` (docs/design/sum_types.md), and the
> fork takes that route, not a `choice` (DR-0 rejected the `choice`
> conversion). Its patterns are `.Some(<pattern>)` and, because `None` is a
> function here, `.None()` (sum_types.md:214-222); where this page says "`.Some`
> and `.None` patterns" it means those. W-177 closes with W-320, which waits on a
> conflict in upstream's own pages over how `Match` declares `Continuation`
> (W-324), and the examples that match on `Optional` wait with it.
```

<!-- google-doc-style-resume -->

PR 57's merge of PR 56's branch keeps this block and PR 57's text on both sides.

### C.9 loops.md (DR-1a)

After the restored desugaring block: "> **Fork amendment (<date>, DR-1a).** The
fork's `Core.Iterate.Next` takes `ref cursor` as above (W-321). Its `for` calls
`Core.Optional`'s `HasValue()` and `Get()` in place of the `match`, as
upstream's own checker does under its TODO
(toolchain/check/handle_loop_statement.cpp), until `Core.Optional` is matchable
(W-320, waiting on W-324)." At M-a, PR 56's F-015 amendment (in C.7's corrected
form) is dropped: its first sentence describes the cut's desugaring block, which
DR-1a replaced, and this amendment says the rest (§1.16).

### C.10 slices.md (DR-1b)

The 0.1-limits bullet "**Slices are read-only; `s[i] = v` is an error.** ..." is
replaced by: "> **Fork amendment (<date>, DR-1b, D-DR-7).** Slices are writable:
`Core.Slice(T)` implements `IndirectIndexWith(i64)`, whose `Ref` returns `ref T`
(upstream core/prelude/operators/index.carbon:14-16;
docs/design/expressions/indexing.md), so `s[i]` is a durable reference and `s[i]
= v` writes through; `Core.Buf(T)` likewise, its storage being the heap block a
by-value `Buf` names (D-SL-6). A `Slice(const T)` is not writable where `T` is
known; a generic body's write instantiated at a `const` element is W-327's. The
literal-subscript rule stands in for `like i64` until `like` lands (W-326)."

Amended 2026-10-22 (implementation-review fold: DR1B-m2). C.10 named the
limits bullet only, which left the page's `final impl ... as IndexWith(i64)`
listings for `Slice` and `Buf`, the paragraph calling `s[i]` a value
expression, the bounds sentence and the iteration sentence stating the
read-only design. The fold rewrites those lines, the page's own, to
`IndirectIndexWith(i64)` with `Ref` returning `ref T`, `s[i]` a durable
reference, and `IndexWith(i64)` from the blanket impl, and appends to the
amendment: "The interface listings, the indexing paragraph and the bounds and
iteration sentences above state this design (rewritten on 2026-10-22, DR-1b
implementation-review fold: DR1B-m2)."

Amended 2026-10-22 (re-review round 1: R1R2-m3). Two more lines stated the
read-only design: the Heap buffers bullet "Writes to owned storage go through
`Set`; `Core.Slice(T)` has no `Set`" (slices.md:241-244 at f774ee836) and the
rejected alternative "A `Slice.Set`: the `const` element hazard above" (:434),
whose hazard text the page no longer has. Both are rewritten, writes going
through `b[i] = v` or `Set` and, for a `Core.Slice(T)`, through `s[i] = v`, and
a `Slice.Set` being unneeded beside `IndirectIndexWith.Ref` (the generic
`const`-element write is W-327's); the dated sentence names them.

### C.11 error_handling.md (R0)

After the paragraph that follows the EH-A amendment (trunk's
docs/design/error_handling.md:414-435 and :437-444), a dated paragraph:

<!-- google-doc-style-ignore -->

```markdown
> **Amendment (<date>, DR-1; R32, DR-0).** "The `match` body above applies
> verbatim once W-058 makes `Optional` a choice", and the paragraph above's
> "Rebuilding `Core.Optional` as a choice type", no longer hold: W-058 kept
> the class (F-015), and DR-0 rejected the `choice` conversion. The route is
> `Core.Optional` implementing `Match` (W-320), under which the empty arm is
> `case .None()`, because the prelude's `None` is a function
> (docs/design/sum_types.md:214-222). W-320 waits on a conflict in upstream's
> own pages over how `Match` declares `Continuation` (W-324); until then the
> `Optional` impl's body keeps `HasValue()`/`Get()`, and this page, which has no
> upstream copy, is the fork's.
```

<!-- google-doc-style-resume -->

## Review fold record

### Rev 2: reviews A and B of rev 1 (2026-10-21)

Reviews A and B of rev 1 (commit 1e46ffd94), both REJECT, read upstream at
70c696e78; rev 2 read ac31fd198, whose only commit since 70c696e78 touches no
DR-1 page or prelude file. Every finding was reproduced in `$Y` where it is a
measurement (where_cont, copy_slot, nested_choice, tmpl_for, tmpl_match_dep;
230227264's `git apply --check`; the `Buf` alternatives; the merge onto CT-1's
head; W-322's removal on PR 62's head) and folded; none is rejected. 31
findings: review A 12 (3 BLOCKER, 5 MAJOR, 4 MINOR), review B 19 (2 BLOCKER, 13
MAJOR, 4 MINOR).

| Finding | Disposition | Where |
| --- | --- | --- |
| A-B1 L1 and L2 contradict upstream; register; F-022 | Folded: README.md, terminology.md, p001013, details.md and the parser quoted; L1, L2, L3 not implemented; slice 1 stopped by D-DR-22; rev 1's register (iv) replaced by the conflict entry with W-320 and W-324; F-022 not minted, because DR-1 adopts no design on the conflict | §0.7, §0.10, §1.4, §1.17, §7.2, C.1, C.2, C.4 |
| A-B2 `Try` body against the Copy rule | Folded: reproduced (copy_slot); D-DR-13 withdrawn, the `Try` body keeps `HasValue`/`Get`; the constraint recorded for the resumption | §1.4 RC-2, §1.9, C.1 |
| A-B3 `for` through `Match` regresses template `for` | Folded: reproduced (tmpl_for `6`, tmpl_match_dep TODO on PR 61 and on the mct mirror); no `for` change beyond slice 2, measured on CT-1's head; RC-3 | §0.8.1, §1.2, §1.4 RC-3 |
| A-M1 min_prelude `for` goldens | Folded: moot for rev 2 (no `Match` `for`); RC-4 names the eight goldens | §1.4 RC-4 |
| A-M2 nested `Match` alternatives | Folded: reproduced (nested_choice); RC-5 | §1.4 RC-5 |
| A-M3 W-322 list breaks F-020's bridge | Folded: the kept and removed pieces listed, the mapping gate re-derived, measured on the m62 mirror (std goldens unchanged, 1950 of 1950) | §0.8.2, §1.11, §2.5 |
| A-M4 commit and PR slicing | Folded: two PRs, two named branches, each golden in the commit that makes it pass | §1.1, §1.13, §3 |
| A-M5 230227264's goldens and conflicts | Folded: code by `cherry-pick -x -n`, fork goldens kept, three splits added and refilled (+172, +103; 169 of 172 lines upstream's) | §0.6.1, §0.6.2, §1.3, §3 item 5, A.0 |
| A-m1 register incomplete | Folded: 059ee7b9e, 0d3b606a5, 4a8993af2, db87a84b6 added with their impact; tip ac31fd198 | §0.10 |
| A-m2 upstream's `IndirectIndexWith` tests | Folded: both brought, filled by this tree's autoupdate | §0.6.2, §1.3, A.0b |
| A-m3 `.None()` amends D-DR-1; error_handling.md is fork-only | Folded: dated amendments of D-DR-1 and W-320 written; the sketch called the fork's page | §1.4 RC-2, RC-6, C.1, C.2, C.11 |
| A-m4 spec gaps (cleanup scope, missing member, extra copy, counts, review count) | Folded: the first three into RC-7; §5's counts are measured rows; one implementation review once green (R29(c)) | §1.4 RC-7, §3 items 4 and 8, §5 |
| B-B1 L1 contradicts README.md | Folded with A-B1 | as A-B1 |
| B-B2 W-322 and C.8 cannot run in merge order | Folded: both commits made now, independent of DR-1's code; PR 62's program SKIPped with a cited reason and respelled; B.4 withdrawn; PR 57 takes C.8 by a merge | §1.11, §1.16, §2.5, B.3, C.6, C.8 |
| B-M1 min_prelude without `Match` | Folded with A-M1 | §1.4 RC-4 |
| B-M2 regressions on CT-1's base | Folded: the composition measured on CT-1's head (1963 of 1963; 149/0/20 over 169, the template programs PASS); §5 has a CT-1 row | §0.8.1, §5 |
| B-M3 `Try` body against the Copy rule | Folded with A-B2 | §1.4 RC-2 |
| B-M4 nested alternatives | Folded with A-M2 | §1.4 RC-5 |
| B-M5 PR and branch shape | Folded with A-M4; DR-1c removed with slice 1; both PRs on trunk's base as D-DR-1 says | §1.1 |
| B-M6 merge M conflicts in code | Folded: the resolution spelled out and measured on the mct mirror, which found a real template defect (`index_class_with_index_with`), root-caused and fixed by the composition commit C-b; refill commits L-a, L-b | §0.8.1, §1.3, §1.16, §2.1, §2.2, §3 item 10 |
| B-M7 `Buf` by way of `IndirectIndexWith` | Folded by the finding's second fix (quote and justify): indexing.md:29-34 quoted; D-SL-6 puts `Buf` in the `std::span` category; the first fix measured infeasible (`FinalImplOverlapsDifferentFile` for `final`, a generic `b[i]` regression without) | §0.6.2, §0.10, §1.3, §7.1 R-3 |
| B-M8 W-320 and W-109 discharge text | Folded: `.None()` amendments of W-320 and D-DR-1; D-SL-17 filed as register (v) and W-326 before W-109's discharge | §1.3, §1.4 RC-6, C.1, C.2, C.4 |
| B-M9 gap rows 79 and 78 | Folded: row 79 to DONE by its own criterion; row 78's merge rule with PR 57 | §1.15, §1.16, C.3 |
| B-M10 loops.md collision | Folded: M-a drops PR 56's corrected amendment and keeps C.9 | §0.8, §1.16, C.9 |
| B-M11 vacuous verification, placeholders | Folded: the slice-1 placeholders withdrawn with it (RC-9 for the resumption); every mutant of §8 names its catching golden; B.1 and B.2 run | §1.4 RC-9, §8 item 5, Appendix B |
| B-M12 doc texts missing or stale | Folded: error_handling.md (C.11), optional.md's `.None` passages on PR 56 and PR 57 (C.8), PR 62's sum_types.md (C.6); no pattern_matching.md edit remains | §1.15, C.6, C.8, C.11 |
| B-M13 230227264's goldens unmeasured; authorship | Folded with A-M5; authorship stated | §1.3, §3 item 5 |
| B-m1 citations | Folded: upstream optional.carbon:30-32, p000157:496-502; rev 1's A.3 withdrawn | §0.10 |
| B-m2 register selection rule | Folded: selected by design page, then by file, all 98 commits accounted; db87a84b6 listed; the sign-off names its tip | §0.10 |
| B-m3 third parens case, qualified patterns | Folded: RC-7 drops the case, RC-8 decides the qualified forms at resumption | §1.4 RC-7, RC-8 |
| B-m4 break conditions; W-327 pin | Folded: D-DR-17..D-DR-19 and D-DR-22 have break conditions; A.1's `generic_write_const_element` pins W-327 (filled on v4) | §1.13..§1.15, §3 item 9, A.1 |

Found by the fixer while folding: (1) the template index defect of B-M6 and
its root fix C-b, which also makes PR 61's failing template `s[0]` on
`Core.Slice(T)` work (§0.8.1); (2) `5 as const i32` aborts lowering on trunk and
the nightly, filed W-325 (§0.6.2); (3) Appendix A's header said full-prelude
goldens carry no `INCLUDE-FILE`, while min_prelude/full.carbon is how they ask
for the full prelude (corrected); (4) PR 61 and CT-1 touch call.cpp and
convert.cpp too, where 230227264's hunks apply with a three-way fallback (§0.8);
(5) PR 51's buf_field goldens and PR 57's slice/basic refill at DR-1's merges
(§0.8, §1.13).

### Rev 3: the focused re-review of rev 2 (2026-10-21)

The focused re-review RR1 read rev 2 (35fa2f0ef) against upstream/trunk
bc45989b2 and returned APPROVE-WITH-AMENDMENTS: every BLOCKER and MAJOR of
reviews A and B RESOLVED, every MINOR folded, its slice-3 probes on the v4
install as predicted, and 6 new findings (0 BLOCKER, 1 MAJOR, 5 MINOR). Each
was reproduced in `$Z` where it is a measurement, and folded; none is
rejected.

| Finding | Disposition | Where |
| --- | --- | --- |
| RR1-M1 W-322's records half targets ledger entries PR 62 lacks, and PR 62's land-time W-177 narrowing note would land false | Folded: reproduced (`$Z/logs/rr1_m1.txt`: fd290b6e6 is not an ancestor of 3a6531157; PR 62's ledger has W-280 and no W-177 or W-320..W-323; PR 56's and PR 57's have W-177); "its ledger's W-322 is discharged" dropped, C.2 alone discharging it; PR 62's plan §1.16 W-177 paragraph and Appendix C.5 withdrawn by dated notes, W-177's land-time evidence re-pointed to match/fail_todo_core_optional.carbon; W-280's `Core.Optional` half marked moot and its evidence re-cited; W-177's correction moved to PR 56's ledger in W-323's commit, carried to PR 57 by its merge | §1.11, §1.15, §1.16, §2.5, §6, C.6, C.7 |
| RR1-m1 §0.8 omits PR 59's and PR 60's call.cpp and convert.cpp | Folded: numstat added (VA-1 +194 and +114; SC-1 +14 and +94/-7) with the dry runs onto both heads (`$Z/logs/rr1_m1_m4_dryrun.txt`); rule: a three-way merge with no semantic interaction, by a test of each PR's added lines (no `TemporaryStorage` return argument, no `return_arg_id`, no `ConvertCallArgs` call) | §0.8 |
| RR1-m2 W-328 reserved for two purposes | Folded: §3 item 9's shrink residue takes the next free id after the re-scan; W-328 stays W-320's | §3 item 9 |
| RR1-m3 two prose lines start with '-' | Folded: both rewrapped by hand; a lint of every line outside code blocks (`$Z/bin/hazard.py`) finds no prose line starting with `#`, `*`, `+`, `-` or a digit-period; R31 counts taken before and after | §0.8.1, §3 item 5 |
| RR1-m4 the tip and CT-1's head moved | Folded: bc45989b2 named at sign-off (the header, §0.10, C.1), its delta read (toolchain/language_server only); CT-1's 5c78c4086 recorded with 224ee2f8f's numstat (convert.cpp measured +20/-2, where the finding said +22/-5) and 230227264's hunks dry-run onto it; §0.8.1 states what the mirror does not show; §8 item 9 re-runs the composition on CT-1's final head with DR-1a alone and with both PRs before M-a | header, §0.8, §0.8.1, §0.10, §1.16, §8 item 9, §8.1, C.1 |
| RR1-m5 no review and no description refresh for the commits on PR 62 and PR 56 | Folded: one focused review of W-322's commit once its run is green (R29(c)); PR 62's, PR 56's and PR 57's descriptions and first comments refreshed and re-posted after the commits, ORCHESTRATION stamped | §1.16, §3 item 2, C.5 |

Found by the fixer while folding: (1) PR 62's land-time F-M also names the
deleted golden (its refill and a `bool` payload for its `concrete` split) and
a `bool` leg for the SKIPped program, the class RR1-M1 describes; C.6
withdraws them. (2) PR 62's row 68 quotes 134/0/21 over 155, which W-322's
commit makes 133/0/22 (§0.8.2); C.6 rewrites it. (3) §0.8's PR 61 and CT-1 row
said 230227264's call.cpp and convert.cpp hunks apply "with a three-way
fallback"; they apply clean with `git apply --cached --check` onto every held
head that has those files, corrected.

## Implementation review fold record, DR-1a (2026-10-21)

DR-1a's implementation review (§3 item 4, R29(c)) read the head after A-R,
0ac137d9d, against upstream/trunk 503f09037 and returned APPROVE-WITH-FIXES:
no BLOCKER, no MAJOR and three MINOR findings, all records only. Its probes
and logs are in scratchpad/dr1-impl/revA. The fixer reproduced each finding
against the tree, upstream/trunk 503f09037 (fetched 2026-10-21, unchanged
since the review) and the stage logs before folding it (its scratch
scratchpad/dr1-impl/fixA; EXPECTED, not of record, R9), and folded all
three; none is rejected. Two fix commits, within §3 item 9's budget of three,
and nothing is shrunk: 2481ed8f2 "DR-1a fix: loops.md takes the rest of
df3cf9294's page edit" (DR1A-m1 and DR1A-m3's §2.1 cites) and "DR-1a fix:
W-321's landed-site evidence and the plan's errata" (DR1A-m2, the rest of
DR1A-m3 and this record). Neither changes a toolchain, golden or program file,
so no fill commit is owed and stage A's build, fill, mutant and mirror stand;
on the fold's tree, with the install at 0.0.0-0.dev+d0cfe8082: "file_test
test mode on /home/user/carbon-dr: 1942 passed, 0 failed (exit 0, 44s)";
conformance "PASS 128, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0,
OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 (of 150)", bullets 48 PASS, 0
FAIL, 8 SKIP of 56; `runner.py --self-test`: 150 programs parsed, OK.

<!-- google-doc-style-ignore -->

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| DR1A-m1 loops.md realigns only the two subsections | MINOR | yes: `git diff df3cf9294~1 a9943e467 -- docs/design/control_flow/loops.md` is the 7-line `while let` amendment alone, so the sentence at the plan state's :64-65, the `var` example and the temporaries paragraph (:75-84) were upstream's pre-df3cf9294 text, and the References list lacked proposal p007381 | Folded by the first fix commit: the page is upstream/trunk 503f09037's (unchanged since df3cf9294) with the `while let` amendment and C.9, 13 lines added against upstream and none removed; M-a's loops.md conflict is still one block, and DR-1a's side of it gives DR-1a's page (`git merge-file` against PR 56's and PR 57's heads, before and after the fold) | §1.15; §1.16 M-a; §2.1 |
| DR1A-m2 W-321's evidence quotes the pointer-form sites after its discharge | MINOR | yes: the entries cite `fn Next(self, cursor: CursorType*)` at iterate.carbon:17 and the `AddrOf` at handle_loop_statement.cpp:256 and :267, while the tree has `ref cursor` at :17 and the call at :254-263 | Folded by the second fix commit: three landed-site entries appended (the 11 sites, the checker's call with `cursor_var_id` at :262, and loops.md:90) and a dated note marking the first ten entries as the sites at filing (toolchain 0bdce60a5) | C.2's W-321 as committed |
| DR1A-m3 plan errata in §6, §8 item 5 and §2.1 | MINOR | yes: §0.6's numstat sums to 554/628; the mutant's log (stageA/logs/mut_a_nine.log) ran 9 tests with 1 passed, check for/actual.carbon, which has no `for` statement; the headings are at upstream's :74 and the fork's :86 at a9943e467 | Folded: §6 reads 554/628; §8 item 5 states the measured mutant (8 of 9 goldens, failing at the argument conversion with no thunk note); §2.1's cites corrected in the first fix commit, where rev 3's :64-65 is kept, being the plan state's line numbers | §2.1; §6; §8 item 5 |

<!-- google-doc-style-resume -->

Also recorded by the fold, outside the findings: A1's own gate was 1934
passed and 8 failed, not §0.6's 1933 and 9 of v2, because A1 carries the four
test sources (§3 item 3) and lower for/bindings changes only its source line;
the four sources at f14ec0d3b fail on A1's build, bindings among them
(stageA/logs/gate_preedit.log), which is §0.6's state before the sources were
edited.

## Stop-and-amend record (rev 4, 2026-10-22)

The stop. DR-1b's implementer stopped at stage B's step 5, the mirrors of §8
item 9, with B0 cdaa15710, B0F 06b6479d0 "DR-1b: cherry-pick fill", B1
3c54754bc, B1F cf4904138 "DR-1b fill" and B-P 4c358f94b "DR-1b programs"
committed and pushed on claude/carbon-fork-0-1-dr-idx (cut from DR-1a's D,
18a7e8934), and B-R not made. Every fill, gate and conformance total of
DR-1b's own tree was as predicted: B0's gate 1940 passed and 2 failed, B0F's
fills +172/0 and +103/0, B1's gate 1932 passed and 14 failed, B1F's numstat
equal to `$Y/v4_numstat.txt` line for line, the four new files 620, 164, 692
and 166 lines, the final gate 1946 of 1946, conformance 130/0/22 over 152 with
bullets 48/0/8 of 56, and `runner.py --self-test` OK over 152 programs; mct-b
and m55 matched §0.8.1 and §1.16. Two mirrors' red sets did not. The
implementer's logs are scratchpad/dr1-impl/stageB/logs and this amendment's
scratchpad/dr1-impl/amend4, both under
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b;
every figure is container-local, EXPECTED, not of record (R9).

<!-- google-doc-style-ignore -->

| Mirror | Predicted (rev 3) | Measured |
| --- | --- | --- |
| m51: 4c358f94b merged with PR 51's f96fe8a7a (merge 363562322; conflicts in gap-analysis.md and the ledger only) | check and lower slice/buf_field.carbon refilled at L-b (§0.8, §1.13, §1.16 M-b, §4, §8 item 9) | gate 1949 passed, 0 failed before any refill: neither golden moves; conformance 133/0/19 over 152, bullets 48/0/8 (m51_merge.log, gate_m51_1.log, conf_m51.log) |
| m57: 4c358f94b merged with PR 57's a080c7886 (merge ce44f2a1e) | PR 57's check/slice/basic refilled at L-a (§0.8, §1.13, §1.16 M-a, §4, §8 item 9) | check/slice/basic auto-merges and passes; lower array/iterate, for/break_continue and for/for conflict in CHECK lines only and, on PR 57's side, are the gate's three failures (1951 passed, 3 failed); autoupdate `!!!`, then a fixpoint; refills 186/186, 183/183 and 185/185 against PR 57's text; gate 1954 of 1954; conformance 141/0/22 over 163, bullets 48/0/8, B.1 and B.2 PASS (m57_merge.log, gate_m57_1.log, m57_refill.diff, gate_m57_2.log, conf_m57.log) |

<!-- google-doc-style-resume -->

Reproduced by the amender (amend4/logs). The heads, fetched 2026-10-22:
PR 51 f96fe8a7a, PR 55 21307851a, PR 57 a080c7886, CT-1 4a3220c11, DR-1a
18a7e8934, DR-1b 4c358f94b; upstream/trunk 9319bb036 (`git fetch upstream
trunk`; FETCH_HEAD and upstream/trunk both name
9319bb0369b714529d80fb6fde4e9680ebf5db5e, "Add more complex function
definition generation and an `impl`-file benchmark (PR 7998)", 2026-10-21 23:02
UTC), whose three commits since bc45989b2 change no file under docs,
proposals or core and none of DR-1's toolchain files.

-   **m51.** `git merge-tree --write-tree` of 4c358f94b, and of 18a7e8934,
    with f96fe8a7a conflicts in fork/gap-analysis.md and the ledger only
    (m51_mergetree.txt). PR 51's two buf_field sources, split and compiled
    by trunk's install (0bdce60a5), DR-1b's (3c54754bc) and PR 51's
    (carbon-ua2) with `--dump-sem-ir-ranges=only` and `--dump-llvm-ir`
    (amend4/m51dump): DR-1b's check dumps differ from trunk's only in the
    instruction id of `import_ref` lines of `Core//prelude/types/buf` (three
    in synthesized_owner, one in declared_owner: `inst6200039B` against
    `inst6200039C`), which the goldens match as `inst{{[0-9A-F]+}}`; the LLVM
    IR differs only in the install path of `DIFile` lines, which the goldens
    match as `{{.*}}/prelude/...`; PR 51's check dumps equal trunk's.
-   **m57 and m57a.** `git merge-tree` of 18a7e8934, DR-1a alone, with
    a080c7886 gives the same three golden conflicts, three blocks in each
    and no source line in any block, and auto-merges check/slice/basic. m57a,
    DR-1a alone on PR 57's head: that merge with the three goldens taken from
    PR 57's side; handle_loop_statement.cpp compiled from it and relinked over
    PR 57's build objects (/home/user/carbon-build/carbon-op2, whose toolchain
    state is a080c7886's: `git diff --shortstat 9f9ccd768 a080c7886 --
    toolchain core ':!toolchain/*/testdata/*'` prints nothing) into
    /dev/shm/dr1-amend, the install built from the merged tree's core/. The
    gate gave 1947 passed and 3 failed, the same three; autoupdate `!!!`, then
    `...` twice (a fixpoint); the refill's changed lines are byte-identical to
    m57's, 186/186, 183/183 and 185/185, and with `!N` normalized each removed
    line equals an added one (m57a_refill.diff); the gate 1950 of 1950;
    conformance 139/0/22 over 161, bullets 48/0/8 (gate_m57a_1.log,
    gate_m57a_2.log, conf_m57a.log). The worktree and /dev/shm/dr1-amend were
    removed after measuring.

Root causes:

-   **m51: the prediction read the goldens' subject, not their dump ranges.**
    Both buf_field.carbon files bracket only `F` and `G` with
    `//@dump-sem-ir-begin` and `-end`; both bodies call
    `Core.Buf(i32).Make(n, 7)` and `o.b.Get(0)` and end in the owner's
    destroy, and neither subscripts a `Buf`. DR-1b turns `Buf`'s
    `IndexWith(i64)` impl into `IndirectIndexWith(i64)` with a `Ref` (§2.2),
    which only a subscript reaches: nothing in the dumped region changes,
    lowering emits only the functions reached, so `Ref` is never emitted, and
    the instruction ids the prelude edit shifts are matched by pattern.
-   **m57: §0.8's PR 57 row was transcribed from DR-1b's golden list.** PR
    57's refill commit 189baa262 (2026-10-14, already in the 628273444 rev 3
    read) changes six of DR-1a's nine goldens, not one: check
    interop/cpp/range_for 583/1983, check slice/basic 49/224, lower
    array/iterate 237/240, for/bindings 161/164, for/break_continue 252/254
    and for/for 254/256; the row named slice/basic alone, the golden DR-1b
    also refills. PR 57's `Optional` ownership changes (optional.carbon,
    lower/handle.cpp, convert.cpp) move the lowering of every `for` loop over
    the full prelude. The two kinds of golden compose differently. A check
    golden names a constant by a content-derived suffix (`%ptr.643`), so
    DR-1's and PR 57's edits touch disjoint lines, merge cleanly and stay
    true together (slice/basic; range_for; bindings, whose DR-1a change is
    its one source line). A lower golden numbers its metadata in order
    (`!54`), so DR-1a's A1F, which renumbered the `!dbg` lines of
    array/iterate, for/break_continue and for/for (137/137, 134/134 and
    136/136, no instruction changed), and PR 57's refill rewrite the same
    lines; the three-way merge conflicts though no instruction differs, and a
    refill against PR 57's text renumbers them again.

Neither needs a toolchain, prelude, test-source or program change: both are
merge-time predictions, and both measured outcomes are correct composed
outputs. Rev 4 changes no §2 code block and no measured row of DR-1b's own
tree, and no D-DR decision: D-DR-17's and D-DR-20's refill lists are their
content, now measured, and their break conditions are kept; D-DR-17's own
break condition ("changes a golden this section does not name; the plan is
amended with the measured set before the commit") is the rule this record
follows.

The amendment. Each place carries "amended 2026-10-22, implementation:
stop-and-amend": the header, the status line and the contents; §0.8 (the PR 51
and PR 57 rows, the overlap re-sweep); §0.8.1 (the re-measures); §1.13; §1.16
(M-a's L-a, M-b's L-b); §2.2 (a note after the handle_index.cpp block); §3
items 8 and 10; §4 (the merge-time rows); §5 (the mirror rows); §6; §7.1
(R-6); §8 items 5 and 9; §8.1; Appendix B.2's `.diff.cpp`; the Landed notes'
L-a item; the Sign-off. Rev 2's fold record keeps its finding (5) as it was
written; rev 4 corrects it here.

Stage B errata, folded with it. None is a fill, gate or conformance
difference (the implementer's deviations 1 to 6): clang-format wraps three
statements of §2.2's handle_index.cpp block differently, with the same tokens
(a whitespace-free comparison of the block applied to f68681114 with
3c54754bc's file), 37/16 against 39/17; the prelude comments §2.2 asks to
rewrite make slice.carbon 17/12, buf.carbon 10/5 and iterate.carbon 2/2,
where §6 read v4's 7/2 and 7/2; prek's clang-format (`InsertBraces`) braces
B.2's `.diff.cpp` loop bodies, 30 lines as committed; §8 item 5's DR-1b
mutants are restated as measured (stageB/logs mut_b_* and mut2_b_*); C-b's
count is +19/-1, not +16; and mct-b ran no autoupdate before C-b, so four
goldens were red after it, not §0.8.1's three, with the same final refills.

Instructions to the implementer (stage B, re-run from step 5):

1.  Reset nothing. B0 to B-P are pushed and correct: `git -C
    /home/user/carbon-dr-idx branch -r --contains 4c358f94b` lists
    origin/claude/carbon-fork-0-1-dr-idx; no fill is redone and no commit is
    rewritten.
2.  Rev 4 is the commit "DR-1 plan (rev 4): stop-and-amend: the m51 and m57
    mirrors' red sets" on claude/carbon-fork-0-1-dr (/home/user/carbon-dr),
    the plan file only, not pushed. After its focused re-review, and any fold
    commit on the same branch, push it: `git -C /home/user/carbon-dr push
    origin claude/carbon-fork-0-1-dr`.
3.  In /home/user/carbon-dr-idx, merge that branch by a new merge commit,
    never a rebase: `git -C /home/user/carbon-dr-idx merge --no-ff
    claude/carbon-fork-0-1-dr`, titled "DR-1b: merge the plan's rev 4 from
    claude/carbon-fork-0-1-dr", with the session trailers; `git diff --stat
    HEAD^1 HEAD` must name fork/direction/plan.md alone. No file under
    toolchain/ or core/ changes, so the build and the install
    (0.0.0-0.dev+3c54754bc) stand and no build, fill or gate is owed for it;
    push the branch.
4.  Fetch, then compare the heads. If PR 51, PR 55, PR 57 and CT-1 are still
    f96fe8a7a, 21307851a, a080c7886 and 4a3220c11, step 5's mirrors stand as
    measured (stageB/logs; amend4/logs for m57a) and are not re-run. For a
    head that moved with `git diff --shortstat <measured> <new> -- toolchain
    core fork/conformance` not empty, re-run that mirror (§8 item 9) against
    rev 4's §4 and §5; a difference there is a new stop (fork/conformance
    added 2026-10-22, re-review round 1: RR4-m2).
5.  Then B-R as §3 item 8 says, its decision-log note in entry DR-1 also
    recording the mirror runs of §5's rev 4 rows (mct-b, m51, m55, m57, m57a)
    and a dated correction of the DR-1a discharge note's land-time items: L-a
    refills check generic/template/for_range, lower template/for_range, check
    interop/cpp/range_for and lower array/iterate, for/break_continue and
    for/for; L-b refills check generic/template/index and PR 55's
    string_indexing; PR 57's check/slice/basic and PR 51's buf_field goldens
    are not refilled (plan rev 4). Then the implementation review (R29(c)),
    the fix commits of §3 item 9, D and the held PR as §3 says.

The new predictions (§4, §5, each measured). At M-a, the CHECK-only
conflict blocks of lower array/iterate, for/break_continue and for/for take
trunk's side, and L-a refills them with the `!dbg` renumbering, 186/186,
183/183 and 185/185 against PR 57's text, beside mct's three refills; at M-b,
L-b refills generic/template/index (16/41) and string_indexing (2/2); PR 51's
buf_field goldens and PR 57's slice/basic are not refilled; a golden that
several merged PRs change is refilled against trunk's merged text (R-6). Break
condition: a gate after L-a or L-b with a red golden that no row names, a
conflict block in a golden that holds a source line, or a mirror head that
moves in toolchain/, core/ or fork/conformance/ before its PR opens; the stage
stops again and the plan is amended. Not a difference: range_for's L-a
numstat, which is recorded at L-a against trunk's merged text, not predicted
(R-6; amended 2026-10-22, re-review round 1: RR4-m1 / RR4-m2).

## Implementation review fold record, DR-1b (2026-10-22)

DR-1b's implementation review (§3 item 8, R29(c)) read the head after
B-R, 45294ea90, against upstream/trunk 9319bb036 and returned
APPROVE-WITH-FIXES: no BLOCKER, one MAJOR (DR1B-M1, a wrong result from the
literal-subscript rule DR-1b extended) and six MINOR findings, three of them
records only. Its probes and logs are in scratchpad/dr1-impl/revB. The fixer
reproduced each finding against the tree, the stage logs and upstream/trunk
ebc155734 (fetched 2026-10-22 by `git fetch upstream trunk`; FETCH_HEAD and
upstream/trunk both name ebc1557345468cf3a37e0c2e616550c79ad5ae8c, "Switch the
field types to a separate type pool (PR 7999)", 2026-10-22 02:07 UTC, whose one
commit since 9319bb036 changes no file under docs, proposals or core and none of
DR-1's toolchain files) before folding it (its scratch scratchpad/dr1-impl/fixB;
EXPECTED, not of record, R9), and folded all seven; none is rejected. One fix
commit of §3 item 9's three, with its fill, and nothing is shrunk: the budget is
shared with the focused re-review loop that follows, so the records ride in the
same commit. The fix commit is fddfcf42a "DR-1b fix: literal subscripts honour
an `IndirectIndexWith(Core.IntLiteral)` impl; the review's splits and records"
and its fill bcd9ba06f "DR-1b fix fill"; this record and the plan's amendments
are the commit "DR-1 plan: implementation-review fold, DR-1b" on
claude/carbon-fork-0-1-dr, merged into claude/carbon-fork-0-1-dr-idx by a merge
commit; D follows.

<!-- google-doc-style-ignore -->

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| DR1B-M1 the literal-subscript rule ignores an `IndirectIndexWith(Core.IntLiteral)` impl | MAJOR | yes: on DR-1b's install (3c54754bc) revB's p17 (non-`Copy` element, `IndirectIndexWith(Core.IntLiteral)` and `IndirectIndexWith(i64)` impls) prints 2, the `i64` impl's element, while p17b (an `i32` element) and p17c (the literal impl alone) print 1; trunk 0bdce60a5 and the nightly have no `IndirectIndexWith` (`member name IndirectIndexWith not found in Core`), and upstream's 309d3d63c dispatch, which has no literal rule, calls the literal impl (hand-derived: 1). Root cause: `LiteralSubscriptTargetType` asked only `IndexWith(Core.IntLiteral)`, which the blanket impl supplies only for a `Copy` element | Folded by the fix commit: the rule also asks `IndirectIndexWith(Core.IntLiteral)` (handle_index.cpp:155-166), after the `Core.Int` lookup, so that the names the rule loads keep their order and no existing golden moves. Measured: the reviewer's order, `IndirectIndexWith` first, reorders the `imports` lines of six goldens (index/fail_invalid_base and fail_non_tuple_access, operators/overloaded/index and index_with_prelude, slice/basic and buf), and asking it right after `IndexWith(Core.IntLiteral)` reorders three; the placed probe changes only the new split. Pinned by A.1's `literal_subscript_literal_impl` split (the call is the literal impl's `Ref` with the literal as written). p17 prints 1 on the fix, as p17b and p17c do; of revB's other 30 probes, 29 give 45294ea90's outcome (the same output, or the same first error for a refused program), and rrcg, compile-only, compiles where trunk and DR-1a CHECK-fail at pattern_match.cpp:2207 (corrected 2026-10-22, re-review round 1: RR1-1-F8 / R1R2-m8: the fold's log names no 45294ea90 binary for 20 of the 30, and round 1's relink of B-R's rule measures the 29). W-326's title, row :79's parenthetical, slices.md's indexing paragraph and the rule's comment updated | §1.3; §2.2; §8 item 5; A.1; C.2; handle_index.cpp:108-181 |
| DR1B-m1 lower form.carbon drops upstream's instantiation of `ref_return_class_generic` | MINOR | yes: 230227264's lower hunk adds `class D` and `fn H(d: D) { G(d); }` (11 lines) after `G`; B0 and v4 left them out, so no specific of `G` was lowered; the full split compiles on DR-1b and CHECK-fails at pattern_match.cpp:2207 on trunk (0bdce60a5) and on DR-1a (d0cfe8082) | Folded by the fix commit and its fill: the 11 lines restored, the split's source byte-identical to upstream's; the fill adds 55 lines, the golden +158/0 against DR-1a as upstream's hunk is, its lines upstream's with the metadata numbers normalized (two `!DIFile` and `!DICompileUnit` lines sort differently by their numbers). §0.6.2's "a preceding split the fork lacks" was wrong and is corrected | §0.6.2; §4; §6; A.0 |
| DR1B-m2 slices.md still states the read-only `IndexWith` design | MINOR | yes: slices.md:114-115, :120-136, :161-162, :190 and :271-272 at 45294ea90 | Folded by the fix commit: those lines, the page's own, rewritten to `IndirectIndexWith(i64)` impls whose `Ref` returns `ref T`, `s[i]` a durable reference, `IndexWith(i64)` from the blanket impl, and the amendment block gains a dated sentence; the scope change is noted in §1.15 and C.10 | §1.15; C.10 |
| DR1B-m3 a user's `final impl X as Core.IndexWith(...)` that trunk accepts is now rejected | MINOR | yes: revB's p15 prints 6 on trunk and fails on DR-1b with `FinalImplOverlapsDifferentFile` and the note at index.carbon:19; index.carbon is upstream's byte for byte, so upstream rejects it the same way and it is not a drift | Folded: recorded as a behavior change inherited from upstream (§1.3, §7.1's R-7, the decision log's DR-1b discharge note, the PR body) and pinned by A.1's `fail_final_index_with_overlap` split. The split is in the fork's own check/slice/write_through.carbon, not a new file in upstream's operators/overloaded directory, so the manifest stays at 1946 and every merge-time total rev 4 measured stands (R29: decided and recorded; break condition: a reviewer requires a file of its own, which then moves the gate counts, recorded) | §1.3; §7.1; A.1 |
| DR1B-m4 stale comments in handle_index.cpp | MINOR | yes: :50-56, :105-110 and :211-212 at 45294ea90 | Folded by the fix commit, comment-only: `HasIndexWithImpl` names `Core.<interface_name>` (:51-65), the rule's statement names both literal impls and both `i64` impls (:108-124) and its footprint sentence the `IndexWith` literal impl, and the `default:` arm's comment names `PerformIndexOperator` and both interfaces (:226-231) | §2.2 |
| DR1B-m5 gap row :82 omits B.2 | MINOR, records only | yes: row :82 reads "2/2 programs PASS" while cpp_span_write_through_diff carries its bullet | Folded by D: a dated sentence, 3/3 programs PASS with B.2 and its C++17 oracle, on DR-1b's own 130/0/22 over 152 | gap row :82 |
| DR1B-m6 the plan's status line and Sign-off are stale after B-R | MINOR, records only | yes: the status line said DR-1b stopped before B-R; the Sign-off had no row for rev 4's focused re-review | Folded: the status line, the Sign-off's rev 4 sentence and row, and this record; D writes the landed notes | header; Sign-off |

<!-- google-doc-style-resume -->

Measured on the fold's tree (the fix commit and its fill), with the install
built from it and printing 0.0.0-0.dev+fddfcf42a (container-local, EXPECTED, not
of record): the build incremental, handle_index.cpp alone; autoupdate `!!` and
then a fixpoint; "file_test test mode on /home/user/carbon-dr-idx: 1946
passed, 0 failed"; conformance "PASS 130, COMPILE-FAIL 0, LINK-FAIL 0,
RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 (of 152)", bullets 48
PASS, 0 FAIL, 8 SKIP of 56; `runner.py --self-test` OK over 152 programs. The
mutants of §8 item 5, relinked over that build and deleted after: as §8 item 5
states, the fold's own fourth catching the removal of its probe. The mirrors of
§8 item 9, re-measured because the fix commit touches handle_index.cpp, on the
heads stage B measured (fetched 2026-10-22: PR 51 f96fe8a7a, PR 55 21307851a,
PR 57 a080c7886, CT-1 4a3220c11), each a worktree of the held head with the
fold's tree merged, built in full in /dev/shm and deleted after: mct-b, its
conflicts and their resolution stage B's (handle_index.cpp equal to stage B's
resolution before the fix's hunks, which apply with offsets only), 1959 passed
and 4 failed before and after C-b, C-b +19/-1 with its added lines
byte-identical to stage B's and its context the fold's reworded comment, the
refills 12/17, 16/41, 17/103 and 137/137 with their changed lines identical to
stage B's, then 1963 of 1963, conformance 149/0/20 over 169, bullets 48/0/8, and
tmpl_index_vec 7, tmpl_index_slice 4, tmpl_for 6, f_slice 15 and p17 1;
m55, 1953 passed and 1 failed (string_indexing), the refill 2/2 identical to
stage B's, then 1954 of 1954 and 135/0/21 over 156, bullets 48/0/8; m51,
conflicts in the gap analysis and the ledger only, 1949 of 1949 with no refill
and 133/0/19 over 152, bullets 48/0/8; and m57, check/slice/basic auto-merged,
lower array/iterate, for/break_continue and for/for conflicting in CHECK lines
only and the gate's three failures (1951 passed), refilled 186/186, 183/183
and 185/185 with the changed lines identical to stage B's, then 1954 of 1954
and 141/0/22 over 163, bullets 48/0/8, B.1 and B.2 passing. Every mirror row of
§5 stands. Not run by the fold: clang-tidy (§8 item 6), which stops at a
frontend error with no location, `missing '(' after '__has_feature'`, on
handle_index.cpp and on the untouched cpp/operators.cpp alike over the build's
compile database, so the failure is the environment's, not the change's; stage
B's run (rc 0) predates it. Round 1 of the focused re-review ran it with that
check, `modernize-use-trailing-return-type`, excluded and named: rc 0 on
handle_index.cpp, no user warning (§8 item 6; amended 2026-10-22, re-review
round 1: R1R2-m7).

## Focused re-review of the fold, DR-1b, round 1 (2026-10-22)

Round 1 of §3 item 9's focused re-review loop read the implementation-review
fold and the discharge, 45294ea90..f774ee836 (the fix commit fddfcf42a and its
fill bcd9ba06f, the fold's plan commit 2a4264056 with its merge adec21b5e, and
D f774ee836; nine files), at the head f774ee836, whose toolchain is
fddfcf42a's, with upstream's direction at upstream/trunk ebc155734 (re-fetched
by this record at 2026-10-22T04:41Z; unchanged). Two fresh reviews, each in its
own scratch (scratchpad/dr1b-rr/rev1-r1 and rev2-r1), and this record's
reproductions (scratchpad/dr1b-rr/rec-r1), all under
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b;
every figure is container-local, EXPECTED, not of record (R9).

-   **Review 1: APPROVE-WITH-FIXES, judged dry.** No BLOCKER or MAJOR; eight
    MINOR findings, all records only: RR1-1-F1, RR1-1-F8 and rev 4's
    RR4-m1..m6, restated as still open. Its runs: gate 1946 of 1946;
    conformance 130/0/22 over 152, bullets 48/0/8, no program changing status
    against B-P; `--self-test` OK over 152; a full autoupdate on a `git
    archive` copy changing no file; the four mutants of §8 item 5, relinked
    and deleted (1916/30 with the same red set; the second aborting the full
    gate at lower/handle.cpp:405, and 1937/8 with that test excluded; the
    third at convert.cpp:2838 on both form goldens and write_through; the
    fourth 1945/1), and two placement mutants that confirm the fold record
    (`IndirectIndexWith` asked first, 1939/7: the six goldens it names and
    write_through; the probe right after the `IndexWith` literal probe,
    1942/4: the three and write_through); mct-b rebuilt in full on CT-1's
    4a3220c11 (the same five conflicts and handle_index.cpp resolution,
    1959/4 before and after C-b, C-b +19/-1, the refills 12/17, 16/41, 17/103
    and 137/137 line for line the fixer's, then 1963 of 1963 and 149/0/20
    over 169, bullets 48/0/8; tmpl_index_vec 7, tmpl_index_slice 4, tmpl_for
    6, f_slice 15, p17 1); and 52 probes on the head, DR-1a, trunk, the
    nightly and a relink of B-R's rule, the head differing from the relink
    only on p17 (2 to 1) and q03 (`2 2` to `1 2`), the intended fix, and on
    q08 (RR1-1-F1). Upstream fidelity: index.carbon identical to ac31fd198's
    and ebc155734's; 309d3d63c's lines present in the `default:` arm; the
    three lower form split sources byte-identical to 230227264's, check +172
    and lower +158 as upstream's hunks. Outside DR-1b's scope, for PR 61 and
    PR 64: a template `v[0] = 5` on a by-value type with only `IndexWith`
    stops at a CHECK at lower.cpp:48 on CT-1's install and on the mirror,
    where trunk reports that it cannot monomorphize.
-   **Review 2: APPROVE-WITH-FIXES, judged not dry.** No BLOCKER or MAJOR;
    eight MINOR findings, R1R2-m1..m8, of which R1R2-m1 (a comment in
    handle_index.cpp) and R1R2-m2 (a comment line in a golden's source) are
    not records only. Its runs, on the install 0.0.0-0.dev+fddfcf42a: a full
    autoupdate on a clone ran 1946 tests and rewrote nothing; conformance
    130/0/22 over 152, bullets 48/0/8, the two new programs PASS and nothing
    else differing from the scoreboard of record; `--self-test` OK over 152
    programs and the regenerated README table without a diff; prek
    `--all-files` twice on a clone, rc 0 and no change; clang-format clean;
    the R31 counts of D's message; the id re-scan (70 origin refs, 20 heads,
    19 worktrees) agreeing with the decision log; every figure of the PR body
    exact. p17 prints `1 10 2` (trunk and DR-1a: `IndirectIndexWith` not
    found in `Core`); a relink without the probe, 1945/1;
    `ref_return_class_generic` byte-identical to upstream's in both form
    goldens, compiling on the head and the nightly and CHECK-failing at
    pattern_match.cpp:2207 on trunk and DR-1a; DR1B-m3's probe
    `FinalImplOverlapsDifferentFile` on the head where trunk prints 6, and no
    held head declaring a `final` `IndexWith` impl in its tests or programs
    (R-7 holds); `git merge-tree` of f774ee836 against trunk and each held
    head, which this record re-ran (the PR body's Conflicts table).

The dry judgment. A round is dry when no finding is MAJOR or BLOCKER and none
needs a toolchain, golden or program change. R1R2-m1 rewords a comment in
toolchain/check/handle_index.cpp and R1R2-m2 a comment line in the source of
toolchain/check/testdata/slice/write_through.carbon, so round 1 is NOT DRY and
round 2 is owed: its fixer makes both edits, with RR1-1-F1's comment, which
that finding defers to whichever fix commit another finding forces, as DR-1b's
fix commit 2 of §3 item 9's three, comment only, then an autoupdate run
expected to change nothing and a gate. Nothing is shrunk, no residue is filed
and no id is minted. Every other finding is records only and is folded here,
each reproduced against the tree first; none is rejected.

<!-- google-doc-style-ignore -->

| Finding | Review | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- | --- |
| RR1-1-F1 the fold routes a blanket `IndirectIndexWith(U)` literal subscript into the known comptime-only lowering FATAL, unrecorded | 1 | MINOR, records only | yes: q08 (`impl forall [U: Core.ImplicitAs(i64)] H as Core.IndirectIndexWith(U)`, a `Ref` that converts `i` at run time, a non-`Copy` element) aborts on the head with "FATAL failure at .../lower/handle_call.cpp:638: Missing constant value for call to comptime-only function", and its `Copy` twin q08b likewise; trunk and the nightly refuse both (`IndirectIndexWith` not in `Core`) and abort the same way on the `IndexWith(U)` analog q07 (the nightly at its :598, DR-1a at :638) and on q09, a plain generic call deduced at `Core.IntLiteral` | Folded: §1.3's DR1B-M1 paragraph and §2.2's known-edge paragraph name the blanket case and the FATAL with q07, q08, q08b and q09; W-325 gains a dated note (the same FATAL, a new trigger). No reference toolchain accepts q08, so it is not a regression. The two comments it names (handle_index.cpp:114-124 and :145-150) are reworded with R1R2-m1 by round 2's fixer | §1.3; §2.2; W-325 (dr-idx) |
| RR1-1-F8, and R1R2-m8 the same, the fold record's probe claim | 1 and 2 | MINOR, records only | yes: dr1-impl/fixB/logs/probes_revB_rerun.txt has "no old bin" on 20 of its 31 lines, all among the 30 probes other than p17 | Folded: the DR1B-M1 row states the measured figures with a dated mark (29 give 45294ea90's outcome, p17 changed, rrcg compile-only), as the PR body did | fold record, DR1B-M1 row |
| R1R2-m1 the footprint comment says the dispatch still diagnoses, false for an `IndirectIndexWith(Core.IntLiteral)`-only operand | 2 | MINOR | yes: fp.carbon (a non-`Copy` `NC`, only an `IndirectIndexWith(Core.IntLiteral)` impl, `return h[0].v;`) checked on the head with the prelude excluded from the dump: `%Core.IndexWith` and `%Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded` appear, neither without the subscript (fp_nosub), and the dispatch succeeds through `Ref` | To round 2's fixer (a toolchain file): handle_index.cpp:141-150 reworded, comment only. Its records half is folded here: §1.3, §2.2 and W-326's notes disclose the case (the rule's first probe and its `Core.Int` lookup load the two names; upstream, with no literal rule, loads neither) | handle_index.cpp:141-150 (round 2); §1.3; §2.2; W-326 (dr-idx) |
| R1R2-m2 ledger id W-327 in a golden's source comment | 2 | MINOR | yes: write_through.carbon:34, "// W-327's current behavior, pinned: ...", since B1 3c54754bc, and A.1's same line. Neither the rulebook (R1..R32) nor this plan forbids a W-id in a golden (112 files under toolchain/ and core/ name one), so the edit is the reviewer's wording choice; it is still a golden file | To round 2's fixer: the line reworded on the same single line, as the review gives it, so no `[[@LINE]]` offset or CHECK line moves (an autoupdate no-op), and A.1's line with it on claude/carbon-fork-0-1-dr | write_through.carbon:34; A.1 (round 2) |
| R1R2-m3 slices.md still states the read-only design at :241-244 and :434 | 2 | MINOR, records only | yes, at f774ee836: "Writes to owned storage go through `Set`; `Core.Slice(T)` has no `Set`" and "A `Slice.Set`: the `const` element hazard above", with no hazard text above | Folded on claude/carbon-fork-0-1-dr-idx: both rewritten to the write-through design, the amendment's dated sentence names them; §1.15 and C.10 record it | slices.md; §1.15; C.10 |
| R1R2-m4 RR4-m1..m6 still open; RR4's verdict recorded as "not REJECT" | 2 | MINOR, records only | yes: each RR4 cite below at f774ee836; the Sign-off and the PR body read "not REJECT" where RR4 returned APPROVE-WITH-AMENDMENTS | Folded: the RR4 table below, with each finding's text; the verdict in the Sign-off and the PR body; §3 item 1 names f551057ea, 1b2ddcb87, 2a4264056 and adec21b5e and this round's commits; decision-log.md's DR-1a parenthetical resolved to one dated correction at the merge into dr-idx | Sign-off; §3 item 1; decision log |
| R1R2-m5 no Conflicts table in the PR body; M-b omits string_indexing's CHECK-only conflict | 2 | MINOR, records only | yes: `git merge-tree --write-tree --name-only` of f774ee836 against origin/trunk and each held head after `git fetch -q origin` at 2026-10-22T04:32Z gives review 2's list path for path; string_indexing's two blocks hold CHECK lines only; fork/conformance/README.md conflicts with PR 60 and PR 62 in one block of the generated table each | Folded: the PR body's Conflicts table; M-b, §0.8's PR 55, PR 60 and PR 62 rows and the DR-1b landed notes give string_indexing trunk's side, PR 55's text, before L-b's 2/2 refill, and README.md regenerated with `runner.py --update-readme-table` | §0.8; §1.16; landed notes (dr-idx); PR body |
| R1R2-m6 PR 63's description stale after f551057ea and 2a4264056 | 2 | MINOR, records only | yes: review 2's copy of the description (updated 2026-10-22T03:44:21Z) ends its commit table at 18a7e8934, and its L-a item and NOT-run bullet name PR 57's check/slice/basic as predicted | Folded as text, not posted (the review says report only): a dated amendment of PR 63's description in scratchpad/pr_dr1a_amended.md (the plan commits after 18a7e8934; the L-a item and the NOT-run bullet as rev 4 measured them); posting it and stamping trunk's ORCHESTRATION dr row are the orchestrator's | scratchpad/pr_dr1a_amended.md |
| R1R2-m7 clang-tidy runs with one check excluded | 2 | MINOR, records only | yes: over review 2's compile database, `clang-tidy -p <db> --checks=-modernize-use-trailing-return-type` on handle_index.cpp at f774ee836 returns rc 0 (91580 warnings in non-user code and 150 NOLINT suppressed), and with every check, rc 1 at `missing '(' after '__has_feature'` (clang-tidy 21.1.8) | Folded: §8 item 6, the DR-1b fold record and the PR body record the run with the check named; clang-tidy leaves NOT run | §8 item 6; fold record; PR body |

<!-- google-doc-style-resume -->

### RR4's fold (rev 4's focused re-review)

RR4, the focused re-review of rev 4 (f551057ea, read against upstream/trunk
9319bb036), returned APPROVE-WITH-AMENDMENTS with six MINOR findings, which the
Sign-off left open for this loop's first records commit. Both reviews of round
1 found them still open at f774ee836, review 1 restating each and review 2 as
R1R2-m4. They are folded here, each reproduced against the tree first; none is
rejected.

<!-- google-doc-style-ignore -->

| Finding, as RR4 gave it | Reproduced | Disposition | Where |
| --- | --- | --- | --- |
| RR4-m1 range_for's L-a count is still given as 17/103 while R-6 says it will differ; fix: §4, §1.16's L-a and the Landed notes state it as recorded at L-a against trunk's merged text, not predicted, and the Stop-and-amend record's break condition lists it among the non-differences | yes: §4's L-a row and the DR-1a landed notes' L-a item gave 17/103 for range_for; R-6 says its L-a numstat is against trunk's text | Folded: the three places state it as recorded at L-a, 17/103 being its count against CT-1's text on mct and mct-b; the break condition lists it as not a difference | §4; §1.16; Stop-and-amend record; Landed notes (DR-1a) |
| RR4-m2 the no-re-run test ignores fork/conformance: a held head that adds or edits a conformance program or runner.py changes a mirror's conformance prediction without a re-run; fix: add fork/conformance to the pathspec of instruction 4 and of §8 item 9 | yes: both read toolchain and core only | Folded: both, and the break condition that repeats the test, add fork/conformance | Stop-and-amend record; §8 item 9 |
| RR4-m3 DR-1a's own decision-log note stays wrong on DR-1a's branch ("and PR 57's check/slice/basic (predicted)"), the dated correction being only on DR-1b's branch while DR-1a merges first; fix: carry it on claude/carbon-fork-0-1-dr in a new plan or records commit, merged into dr-idx | yes: fork/decision-log.md:365 at 2a4264056 | Folded by this commit on claude/carbon-fork-0-1-dr: the parenthetical points to a dated correction after the DR-1a discharge note, B-R's text. At the merge into dr-idx, where B-R had rewritten the parenthetical in place and written the same correction in its records note, the resolution keeps dr-idx's text, one correction, and drops the dr side's copy | decision log (both branches) |
| RR4-m4 §3 lists neither rev 4's commit nor the dr-idx merge commit (item 1 names P0..P2 only); fix: add P3, the merge between B-P and B-R, not a fix commit under D-DR-22, and 2a4264056 and adec21b5e | yes: §3 item 1 at f774ee836 | Folded: item 1 names P3 f551057ea, 2a4264056 and this round's plan commit, and their merges 1b2ddcb87, adec21b5e and this round's, none a fix commit under D-DR-22 | §3 item 1 |
| RR4-m5 PR 62's row contradicts the overlap re-sweep on convert.cpp ("DR-1's own diff touches none of PR 62's files" against overlap_sweep.txt's 0ef8a0334 convert.cpp 23/7, a file 230227264's hunk also changes); fix: the rule as PR 59's and PR 60's rows give it, without "touches none" | yes: `git diff --numstat` from PR 62's merge-base gives convert.cpp 23/7; none of its added lines creates a `TemporaryStorage` return argument, passes a `return_arg_id` or calls `ConvertCallArgs`; `git merge-tree` merges it clean | Folded: the row's rule is PR 59's, by that test | §0.8 |
| RR4-m6 two wording errors: f551057ea's message and the Sign-off's rev 4 paragraph say no code block or no code changed, while Appendix B.2's `.diff.cpp` block did (§2's did not); and §5's m51 row says "PR 51's own programs carry 19 SKIPs" where PR 51 un-SKIPs three programs, 22 to 19; fix: "no §2 code block" in the Sign-off and in this fold, the commit message noted here, the m51 note rephrased | yes: f551057ea's message ends "No code block, D-DR decision or measured row of DR-1b's own tree changes"; the Sign-off read "it changes no code"; PR 51's diff removes three `// SKIP:` headers (templates_dependent_member, cpp_template_on_carbon_generic and cpp_template_symbolic_arg) | Folded: the Sign-off reads "no §2 code block" and names B.2's block; f551057ea's message is pushed and is never rewritten, so this record states that its "No code block" means no §2 code block, Appendix B.2's `.diff.cpp` block having changed to prek's braces (the Stop-and-amend record's errata); §5's m51 note rephrased | Sign-off; §5 |

<!-- google-doc-style-resume -->

Also recorded by the round, outside the findings: review 1's out-of-scope
crash (a template `v[0] = 5` on a by-value type with only `IndexWith`, CHECK at
lower.cpp:48 on CT-1's install, where trunk diagnoses) belongs to PR 61's and
CT-1's records and is passed to them; DR-1b changes neither the shape's
lowering nor its check. This record's commits are "DR-1 plan: focused re-review
of DR-1b's fold, round 1 recorded" on claude/carbon-fork-0-1-dr (this plan and
the decision log), its merge into claude/carbon-fork-0-1-dr-idx, and "DR-1b
records: re-review round 1 recorded" there (the decision log's DR-1 entry, the
ledger, slices.md, the DR-1b landed notes and ORCHESTRATION); no toolchain,
golden or program file changes.

## Focused re-review of the fold, DR-1b, round 2 (2026-10-22)

Round 2 of §3 item 9's loop begins with its fixer: round 1 found no BLOCKER or
MAJOR, but two of its findings change a toolchain or golden file, so it was
not dry ("Focused re-review of the fold, DR-1b, round 1 (2026-10-22)" above).
The fixer worked from round 1's records head efdf6a823, whose toolchain is
fddfcf42a's, with upstream's direction at upstream/trunk ebc155734 (re-fetched
at 2026-10-22T05:05Z; unchanged) and the held heads as at the fold (after
`git fetch -q origin` at 05:05Z: PR 51 f96fe8a7a, PR 55 21307851a, PR 57
a080c7886, CT-1 4a3220c11, trunk 563135b40). Its scratch is
scratchpad/dr1b-rr/fix-r2 under
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b;
every figure is container-local, EXPECTED, not of record (R9). Each finding
was reproduced first on the install 0.0.0-0.dev+fddfcf42a, trunk's
0bdce60a5, DR-1a's d0cfe8082 and the nightly 2026.10.12.

<!-- google-doc-style-ignore -->

| Finding | Reproduced | Disposition | Where |
| --- | --- | --- | --- |
| R1R2-m1 the footprint comment says the dispatch still diagnoses | yes: fp.carbon (a non-`Copy` element, only an `IndirectIndexWith(Core.IntLiteral)` impl, `return h[0].v;`) checks with no error on the head, and its dump, the prelude excluded, holds the `Core.IndexWith` and `Core.Int` import_refs (`import_ref Core//prelude/types/int, Int, loaded`), which fp_nosub, the same file without the subscript, lacks; trunk and DR-1a reject fp at `IndirectIndexWith` not found in `Core` and load both names too (the rule exists there), the nightly rejects it and loads no `Core.Int` | Folded in 8deb75262, comment only: the footprint comment (handle_index.cpp:146-158; :142-150 at f774ee836) says the file gains both import_refs whether the dispatch then diagnoses `Core.IndexWith(Core.IntLiteral)` or succeeds as written through the `IndirectIndexWith(Core.IntLiteral)` impl the next probe finds, and cites §1.3 and §2.2, where round 1's records disclose the second case | handle_index.cpp:146-158; §1.3; §2.2 |
| RR1-1-F1's comment, deferred by round 1 to this commit | yes: q07 (a blanket `IndexWith(U)`) aborts at lower/handle_call.cpp:638 on the head, trunk and DR-1a and at :598 on the nightly; q08 and q08b (a blanket `IndirectIndexWith(U)`, non-`Copy` and `Copy` elements) abort at :638 on the head and are refused on trunk, DR-1a and the nightly; a type with no index impl diagnoses `Core.IndexWith(Core.IntLiteral)` on all four | Folded in 8deb75262, comment only: the rule's statement (handle_index.cpp:108-128; :108-124 at f774ee836) names a blanket `IndirectIndexWith(U)` beside `IndexWith(U)` as unable to serve literals, and says such an impl answers one of the literal probes, so the literal reaches its `U = IntLiteral` specific as upstream's dispatch sends it and a run-time `At` or `Ref` aborts lowering there | handle_index.cpp:114-125; §1.3 |
| R1R2-m2 ledger id W-327 in a golden's source comment | yes: check slice/write_through.carbon:34, "// W-327's current behavior, pinned: the generic body writes through", and A.1's copy | Folded in 8deb75262: :34-35 read "The generic const-element write's current behavior, pinned: the body" and "writes through `Slice(T)`; the specific at `T = const i32` is not diagnosed.", the review's words on :34, the two lines rewrapped within themselves to stay inside 80 columns, so no line is added or removed; the split has no diagnostic, so no `[[@LINE]]` offset or CHECK line can move; A.1 with it | write_through.carbon:34-35; A.1 |

<!-- google-doc-style-resume -->

The runs, on 8deb75262's build (incremental: handle_index.cpp, the version
stamp and the two links; the install prints 0.0.0-0.dev+8deb75262). A full
autoupdate (1946 tests) rewrote nothing and marked no file, a fixpoint at its
first pass (R26), so the fix commit has no fill commit: a fill holds
autoupdate's CHECK lines (§3), and there are none. The gate: "file_test test
mode on /home/user/carbon-dr-idx: 1946 passed, 0 failed". Conformance into a
private out dir: PASS 130, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0,
OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 of 152, bullets 48/0/8 of 56.
clang-format 21.1.8 is clean on handle_index.cpp, and clang-tidy 21.1.8 as §8
item 6 runs it returns rc 0 with no user warning. The mutants of §8 item 5
whose translation unit round 2 changes, relinked over that build and deleted
after: `diagnose=true` on the `IndirectIndexWith` attempt, 1916 passed and 30
failed, the stage-B set; the fallback removed, lower operators/string_indexing
aborting alone at lower/handle.cpp:405 and the other 1945 giving 1937 passed
and the same 8 failed; the `IndirectIndexWith(Core.IntLiteral)` probe
removed, 1945 passed and 1 failed (check slice/write_through). The third
mutant reverts a call.cpp line, which round 2 leaves alone, and is not re-run.
The mirrors of §8 item 9, which the no-re-run test calls for because the fix
changes toolchain/: each a `git clone --shared` of this worktree at the held
head with 8deb75262 merged (records and CHECK-only golden blocks on the held
head's side; on CT-1's head handle_loop_statement.cpp on DR-1a's side and
handle_index.cpp M-b's resolution of the fold, with the fix's comment lines),
built in full under /dev/shm and deleted after. First, `git merge-tree` of
f774ee836 and of 8deb75262 against each of the four heads gives the same
conflicted paths and merged trees that differ under toolchain/, core/ and
fork/conformance/ only in the fix's comment lines and the conflict markers'
labels; on CT-1's head the three handle_index.cpp conflict blocks are the
fold's. Then: mct-b on CT-1's 4a3220c11, the same five conflicts, 1959 passed
and 4 failed before and after C-b (+19/-1, clang-format clean), the refills
12/17, 16/41, 17/103 and 137/137, then 1963 of 1963 and 149/0/20 over 169,
bullets 48/0/8, and its fourteen probes printing what round 1's mct-b printed
(tmpl_index_vec 7, tmpl_index_slice 4, tmpl_for 6, f_slice 15, p17 1, and q08
W-325's abort); m51 on PR 51's f96fe8a7a, conflicts in records only, 1949 of
1949 with no refill and 133/0/19 over 152; m55 on PR 55's 21307851a, 1953
passed and 1 failed (string_indexing), the refill 2/2, then 1954 of 1954 and
135/0/21 over 156; m57 on PR 57's a080c7886, three lower goldens conflicting
in CHECK lines only and failing (1951 passed), the refills 186/186, 183/183 and
185/185, then 1954 of 1954 and 141/0/22 over 163, B.1 and B.2 passing. Each
matches §5's row and the fold's runs, and every mirror's bullets are 48/0/8.

The budget and the judgment. DR-1b has used two of §3 item 9's three fix
commits, fddfcf42a and 8deb75262, each folding findings; one remains for the
loop, and nothing is shrunk. No residue is filed and no id is minted; no D-DR
decision, no §2 code block and no measured row changes, and the design
statements that change carry dated marks (§1.3 and §2.2 on the comments, A.1's
two lines, §3 items 1 and 9, §5, §8 items 5 and 9). This round's commits:
8deb75262 "DR-1b re-review fix: the literal rule's footprint and blanket-impl
comments; the const-element split's comment without a ledger id" on
claude/carbon-fork-0-1-dr-idx; "DR-1 plan: focused re-review of DR-1b's fold,
round 2 recorded" on claude/carbon-fork-0-1-dr (this record); its merge into
claude/carbon-fork-0-1-dr-idx; and "DR-1b re-review fix: round 2 folded into
the records" there (the decision log's DR-1 entry, W-109's re-pinned
handle_index.cpp cites and W-326's note, the DR-1b landed notes,
ORCHESTRATION and the PR body). Round 2's reviews read 8deb75262 and these
records next; DR-1b stays held and opens when a round is dry.

## Sign-off

Rev 3, 2026-10-21, is SIGNED OFF FOR IMPLEMENTATION: the focused re-review's
verdict is not REJECT, every finding of every review is folded and none is
rejected, and upstream's direction is read at bc45989b2 (R32 (a)).
Implementation starts from this revision's commit with R0 (§3 item 2) and
follows §3; a measurement that contradicts a measured row of this plan stops
the PR and amends the plan (D-DR-22). Every figure in this plan is
container-local, EXPECTED, not of record (R9); the arbiter at implementation is
the carbonbuild scripts (R28).

Rev 4, 2026-10-22 (amended 2026-10-22, implementation: stop-and-amend), is a
stop-and-amend of merge-time predictions, recorded in its own section above;
it changes no §2 code block (Appendix B.2's `.diff.cpp` block alone changed, to
prek's braces; corrected 2026-10-22, re-review round 1: RR4-m6), no decision
and no measured row of DR-1b's own tree, so this
sign-off still covers DR-1b's code, and rev 4's amendments stand once their
focused re-review returns a verdict other than REJECT, recorded here. Recorded
on 2026-10-22 (implementation-review fold: DR1B-m6): rev 4's focused re-review
returned APPROVE-WITH-AMENDMENTS (so recorded 2026-10-22, re-review round 1:
R1R2-m4; this paragraph read "a verdict other than REJECT"), with six findings,
RR4-m1..m6, all MINOR, which it left to the focused re-review loop of DR-1b's
implementation-review fold, whose first records commit folds them; stage B
resumed at B-R on that verdict. Recorded on 2026-10-22 (re-review round 1):
that commit, "DR-1 plan: focused re-review of DR-1b's fold, round 1 recorded",
folds RR4-m1..m6 ("RR4's fold" above); round 1's two reviews and their
findings are in "Focused re-review of the fold, DR-1b, round 1 (2026-10-22)";
round 1 is not dry and round 2 is owed. Recorded on 2026-10-22 (re-review
round 2): round 2's fixer folded R1R2-m1 and R1R2-m2, with RR1-1-F1's
comment, in 8deb75262, comments only, in "Focused re-review of the fold,
DR-1b, round 2 (2026-10-22)"; round 2's reviews follow.

| Review | Of | Upstream read | Verdict | Findings (BLOCKER / MAJOR / MINOR) | Folded | Rejected | Folded in |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Review A | rev 1 (1e46ffd94) | 70c696e78 | REJECT | 12 (3 / 5 / 4) | 12 | 0 | rev 2 (35fa2f0ef) |
| Review B | rev 1 (1e46ffd94) | 70c696e78 | REJECT | 19 (2 / 13 / 4) | 19 | 0 | rev 2 (35fa2f0ef) |
| Focused re-review RR1 | rev 2 (35fa2f0ef) | bc45989b2 | APPROVE-WITH-AMENDMENTS | 6 (0 / 1 / 5) | 6 | 0 | rev 3 (this commit) |
| Focused re-review RR4 | rev 4 (f551057ea) | 9319bb036 | APPROVE-WITH-AMENDMENTS | 6 (0 / 0 / 6) | 6 | 0 | the first records commit of DR-1b's focused re-review loop, round 1 (added 2026-10-22, implementation-review fold: DR1B-m6; folded and the verdict corrected 2026-10-22, re-review round 1: R1R2-m4) |
| Fold re-review, round 1, review 1 | DR-1b's fold and D (f774ee836) | ebc155734 | APPROVE-WITH-FIXES | 8 (0 / 0 / 8), six of them RR4-m1..m6 restated and counted on RR4's row | 2 | 0 | round 1's records (added 2026-10-22, re-review round 1) |
| Fold re-review, round 1, review 2 | DR-1b's fold and D (f774ee836) | ebc155734 | APPROVE-WITH-FIXES | 8 (0 / 0 / 8) | 8 | 0 | round 1's records; R1R2-m1 and R1R2-m2 in round 2's 8deb75262 (added 2026-10-22, re-review round 1; folded 2026-10-22, re-review round 2) |
| Total | | | | 53 (5 / 19 / 29) | 53 | 0 | |

## Landed notes (DR-1a, 2026-10-21)

Written by DR-1a's discharge commit D, "DR-1 discharge (DR-1a)" (§3 item 11),
dated 2026-10-21, the UTC date of its commit, on claude/carbon-fork-0-1-dr,
whose PR base is trunk. In the held state none of PR 51 to PR 62 is on trunk
(GitHub Actions is disabled, R28; trunk e0769c178 at D, records only after this
branch's cut f68681114) and CT-1 is not merged, so these notes record what D
wrote, the commits, the ids, the measurements and their heads, and the land-time
items in order; the merge records add the merged tree's runs here. Everything
measured is container-local, EXPECTED and not of record (R9). The scratch is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/dr1-impl`
(stage0, stageA, revA and fixA, each with its `logs/`).

-   **What D writes.** fork/decision-log.md: the dated note "_DR-1a discharge
    (2026-10-21)._" in entry DR-1, after the A-R note (the review and its fold,
    the runs on the fold's tree, the re-scan, the held state and the land-time
    items). fork/inventory/work-items.json: one dated sentence on the ledger's
    `source`; no item changes (W-321 was discharged at A-R and re-pinned by the
    fold). fork/ORCHESTRATION.md: the dr row of the Branches table in the held
    wording. This plan: the status line and these notes. Gap row 66 stays as
    A-R wrote it (DONE, C.3's DR-1a sentence); the V-3a register's (iii) stays
    as A-R resolved it.
-   **The commits.** R0 f14ec0d3b "DR-1 records: plan decisions" (shared by
    DR-1a and DR-1b); A1 d0cfe8082 "DR-1a: `Core.Iterate.Next` takes `ref
    cursor`"; A1F c1cc72a09 "DR-1a fill"; A-R 0ac137d9d "DR-1a records"; the
    fold's 2481ed8f2 "DR-1a fix: loops.md takes the rest of df3cf9294's page
    edit" and 851bd5d03 "DR-1a fix: W-321's landed-site evidence and the
    plan's errata"; then D. Two fix commits of §3 item 9's three; no fill
    commit after A1F, because no fix changes a toolchain, golden or program
    file.
-   **The id re-scan before D** (§8 item 10; CT-1's §0.11 command widened to
    `W-3[2-9][0-9]`, after `git fetch -q origin` at 2026-10-21T23:22Z;
    fixA/logs/rescan.log). Over 69 origin refs, 18 local heads and the ledgers
    of 17 worktrees: W-320..W-323 in nine ledgers (trunk's, this branch's and
    claude/carbon-fork-0-1-7mwfb7's, each as its local head and its origin
    ref, and the worktrees carbon-lang, carbon-dr and carbon-trunk),
    W-324..W-327 and W-329 in this branch's three (its local head, its origin
    ref and /home/user/carbon-dr) and nowhere else, W-328 nowhere, and no id
    from W-330 to W-399. Other trees name W-32x only in text: the W-177 notes
    of PR 56 and PR 57, PR 62's W-280 notes and its SKIPped program, and
    CT-1's ledger `source`.
-   **Ids.** Filed at R0: W-324..W-327 and W-329. Discharged: W-321 (A-R).
    Reserved and unused: W-328, for W-320's resumption. Blocked: W-320 on
    W-324. No id is filed by the fold or by D.
-   **Measurement heads.** Upstream's direction read at upstream/trunk
    503f09037 (fetched at the fold; its two commits since bc45989b2 touch no
    file of DR-1a's). DR-1a's build /home/user/carbon-build/carbon-dr, rebuilt
    incrementally at A1 d0cfe8082 from the planner's prototype objects (110
    steps, no warning), its install printing 0.0.0-0.dev+d0cfe8082, which is
    still the toolchain state at D. Gates: A1 1934 passed and 8 failed (the
    red set §0.6 implies once A1 carries the four sources); A1F and the fold's
    tree 1942 of 1942. Conformance on A1F and on the fold's tree: PASS 128,
    COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0,
    DIFF-MISMATCH 0, SKIP 22 of 150, bullets 48/0/8 of 56
    (fixA/conf/scoreboard.json). The mutant of §8 item 5, relinked over that
    build: 1934 passed and 8 failed. The mirror of §8 item 9 with DR-1a alone,
    on CT-1's 118fc1bc8 (still CT-1's head at D): before refill 1956 passed
    and 3 failed, refilled 1959 of 1959, conformance 147/0/20 over 167
    (stageA/logs). The held heads at D: PR 56 at 894139b34, PR 57 at
    a080c7886, PR 62 at 0ef8a0334 (W-322's commit and its review's fixes)
    and PR 61 at 5661a35c8.
-   **At land time, in order (§1.16, §3 item 10).** Before M-a, §8 item 9's
    composition is re-run on CT-1's final head if it has moved from
    118fc1bc8, with DR-1a alone, and with both PRs once DR-1b exists. M-a,
    the merge of trunk (with PR 51 to PR 62 and CT-1) into this branch, never
    a rebase: handle_loop_statement.cpp takes DR-1a's side and drops TP-1's
    pointer `RequireCompleteType` and its type_completion.h include (§2.1);
    loops.md takes DR-1a's page, which drops PR 56's F-015 amendment in C.7's
    form (one conflict block, measured by the fold, §1.16); records keep both
    sides. Then L-a, the refill commit: check generic/template/for_range
    (12/17), lower template/for_range (137/137) and check
    interop/cpp/range_for (17/103), measured on the mct mirror and again with
    DR-1a alone (range_for's 17/103 is against CT-1's text: at L-a its count
    is recorded against trunk's merged text, not predicted, R-6; amended
    2026-10-22, re-review round 1: RR4-m1); and lower array/iterate,
    for/break_continue and for/for
    (186/186, 183/183 and 185/185 against PR 57's text, once their CHECK-only
    conflict blocks take trunk's side), measured on m57 and m57a, while PR
    57's check/slice/basic is not refilled (amended 2026-10-22,
    implementation: stop-and-amend: the m57 red set; this note predicted its
    refill). Then the gate and
    conformance on the merged tree, a second id re-scan, and the merged runs
    recorded here.
-   **DR-1b.** Stacked on this branch (§3 items 5 to 8, B0 first on
    claude/carbon-fork-0-1-dr-idx); it merges after DR-1a through M-b, C-b
    and L-b.

## Landed notes (DR-1b, 2026-10-22)

Written by DR-1b's discharge commit D, "DR-1 discharge (DR-1b)" (§3 item 11),
dated 2026-10-22, the UTC date of its commit, on claude/carbon-fork-0-1-dr-idx,
whose PR base is claude/carbon-fork-0-1-dr (DR-1a, PR 63). In the held state
none of PR 51 to PR 64 is on trunk (GitHub Actions is disabled, R28; trunk at D
is 563135b40, records only after f68681114), and CT-1 (PR 64) and DR-1a are not
merged, so these notes record what D wrote, the commits, the ids, the
measurements and their heads, and the land-time items in order; the merge
records add the merged tree's runs here. Everything measured is container-local,
EXPECTED and not of record (R9). The scratch is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/dr1-impl`
(stageB, amend4, stageBR, revB and fixB, each with its `logs/`). The records of
the fold's focused re-review, round 1 (amended 2026-10-22; their scratch is
scratchpad/dr1b-rr), add the bullet "Re-review round 1" and amend the commits
and the land-time items; round 2's records add the bullet "Re-review round 2"
and amend the commits and the measurement heads (amended 2026-10-22, re-review
round 2).

-   **What D writes.** fork/decision-log.md: the dated note "_DR-1b discharge
    (2026-10-22)._" in entry DR-1, after the DR-1b records note (the review and
    its fold, the runs on the fold's tree, the behavior change DR1B-m3 records,
    the re-scan, the held state and the land-time items).
    fork/inventory/work-items.json: one dated sentence on the ledger's `source`;
    no item changes. fork/gap-analysis.md: row 82's dated conformance sentence
    (DR1B-m5). fork/ORCHESTRATION.md: the dr-idx row of the Branches table in
    the held wording. This plan: these notes. Row 79 stays DONE as B-R and the
    fold wrote it; the V-3a register's (ii) stays as B-R resolved it.
-   **The commits.** B0 cdaa15710 (230227264 cherry-picked with `-x`, PR 7886,
    by David Blaikie); B0F 06b6479d0 "DR-1b: cherry-pick fill"; B1 3c54754bc
    "DR-1b: subscripting prefers `IndirectIndexWith`; `Core.Slice` and
    `Core.Buf` write through `Ref`"; B1F cf4904138 "DR-1b fill"; B-P 4c358f94b
    "DR-1b programs"; 1b2ddcb87, the merge of rev 4; B-R 45294ea90 "DR-1b
    records"; the fold's fddfcf42a "DR-1b fix: literal subscripts honour an
    `IndirectIndexWith(Core.IntLiteral)` impl; the review's splits and records"
    and its fill bcd9ba06f "DR-1b fix fill"; 2a4264056 "DR-1 plan:
    implementation-review fold, DR-1b" on claude/carbon-fork-0-1-dr and its
    merge adec21b5e; then D. One fix commit of §3 item 9's three, shared with
    the focused re-review loop that follows. Then round 1's records
    (amended 2026-10-22, re-review round 1): c1b19da06 "DR-1 plan: focused
    re-review of DR-1b's fold, round 1 recorded" on
    claude/carbon-fork-0-1-dr, its merge a0ea3347e, and "DR-1b records:
    re-review round 1 recorded". Then round 2's (amended 2026-10-22,
    re-review round 2): 8deb75262 "DR-1b re-review fix: the literal rule's
    footprint and blanket-impl comments; the const-element split's comment
    without a ledger id", fix commit 2 of the three, with no fill commit
    because autoupdate changed nothing; 1c8cc5e38 "DR-1 plan: focused re-review
    of DR-1b's fold, round 2 recorded" on claude/carbon-fork-0-1-dr; its merge
    53ff93c60; and "DR-1b re-review fix: round 2 folded into the records".
-   **The id re-scan before D** (§8 item 10; widened to `W-3[2-9][0-9]`, after
    `git fetch -q origin` at 2026-10-22T03:44Z; fixB/logs/rescan.log). Over 90
    refs (70 origin refs and 20 local heads) and 19 worktrees' ledgers:
    W-320..W-323 in twelve ledgers (trunk's, claude/carbon-fork-0-1-7mwfb7's,
    DR-1a's and this branch's, each as its local head and its origin ref, and
    the worktrees carbon-lang, carbon-dr, carbon-dr-idx and carbon-trunk),
    W-324..W-327 and W-329 in DR-1a's and this branch's six (local head, origin
    ref and worktree each) and nowhere else, W-328 nowhere, and no id from W-330
    to W-399.
-   **Ids.** Discharged: W-109 (B-R). Filed by DR-1 at R0 and unchanged here:
    W-324..W-327 and W-329; W-326's title amended by the fold (DR1B-M1).
    Reserved and unused: W-328, for W-320's resumption. No id is filed by the
    fold or by D.
-   **Measurement heads.** Upstream's direction read at upstream/trunk ebc155734
    (fetched at the fold; its one commit since 9319bb036 touches no file of
    DR-1b's). DR-1b's build /home/user/carbon-build/carbon-dr-idx, its install
    printing 0.0.0-0.dev+fddfcf42a after the fold's rebuild
    (0.0.0-0.dev+8deb75262 after round 2's; amended 2026-10-22, re-review
    round 2). Gates: B0 1940
    passed and 2 failed, 1942 of 1942 after B0F; B1 1932 passed and 14
    failed, 1946 of 1946 after B1F; the fold's tree 1946 of 1946. Conformance on
    B-P and on the fold's tree: PASS 130, COMPILE-FAIL 0, LINK-FAIL 0,
    RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 of 152,
    bullets 48/0/8 of 56 (fixB/conf/scoreboard.json). The mutants of §8 item 5,
    as that item states. The mirrors of §8 item 9, re-measured at the fold on
    the heads fetched 2026-10-22: mct-b on CT-1's 4a3220c11, m51 on PR 51's
    f96fe8a7a, m55 on PR 55's 21307851a and m57 on PR 57's a080c7886, each as
    §5's rows state. The held heads at D: PR 56 at 894139b34, PR 57 at
    a080c7886, PR 62 at 0ef8a0334, PR 61 at 5661a35c8, CT-1 (PR 64)
    at 4a3220c11, DR-1a (PR 63) at 2a4264056.
-   **Re-review round 1 (2026-10-22).** Two reviews of f774ee836 (toolchain
    fddfcf42a, upstream/trunk ebc155734), both APPROVE-WITH-FIXES with no
    BLOCKER or MAJOR: review 1 eight MINOR findings, six of them rev 4's
    RR4-m1..m6 still open, review 2 eight. Not dry: R1R2-m1 (the footprint
    comment at handle_index.cpp:141-150) and R1R2-m2 (the W-327 comment line
    at check slice/write_through.carbon:34) are owed to round 2's fixer as fix
    commit 2 of 3, with RR1-1-F1's comment and A.1's line. Folded by the
    records: RR4-m1..m6, RR1-1-F1's and R1R2-m1's disclosures (§1.3, §2.2,
    W-325 and W-326), RR1-1-F8 and R1R2-m8, R1R2-m3 (slices.md:241-244 and
    :434), R1R2-m4, R1R2-m5 (the PR body's Conflicts table, M-b), R1R2-m6 (a
    dated amendment of PR 63's description, as text for the orchestrator)
    and R1R2-m7 (clang-tidy rc 0 with `modernize-use-trailing-return-type`
    excluded). Runs of the round, on the head: gate 1946 of 1946; conformance
    130/0/22 over 152, bullets 48/0/8; `--self-test` OK over 152; a full
    autoupdate on a copy changing nothing; the four mutants as §8 item 5
    states; mct-b on CT-1's 4a3220c11 as §5 states. DR-1a (PR 63) is at
    c1b19da06 after this round's plan commit, the other held heads as at D.
-   **Re-review round 2 (2026-10-22).** Its fixer made the two edits round 1
    left to it, comments only, in 8deb75262, each reproduced first on the head,
    trunk, DR-1a and the nightly: handle_index.cpp's footprint comment
    (:146-158) names the case where the dispatch succeeds as written through an
    `IndirectIndexWith(Core.IntLiteral)` impl (R1R2-m1), the rule's statement
    (:108-128) the blanket `IndirectIndexWith(U)` case and its lowering abort
    (RR1-1-F1), and check slice/write_through.carbon:34-35 reads "The generic
    const-element write's current behavior, pinned: ...", its two lines
    rewrapped within themselves (R1R2-m2), with A.1's copy on
    claude/carbon-fork-0-1-dr. W-109's landed handle_index.cpp cites are
    re-pinned (:250-261, :175-184, :163-174), which the comments moved by 8
    lines. Runs on 8deb75262's install: a full autoupdate rewriting nothing (no
    fill commit); gate 1946 of 1946; conformance 130/0/22 over 152,
    bullets 48/0/8; clang-format clean; the three mutants of §8 item 5 in
    handle_index.cpp, 1916/30, 1937/8 with string_indexing's abort isolated,
    and 1945/1, each set as before; the four mirrors rebuilt in full on the
    unchanged heads, mct-b 1959/4 before and after C-b (+19/-1), its
    refills 12/17, 16/41, 17/103 and 137/137, then 1963 of 1963 and 149/0/20
    over 169; m51 1949 of 1949, no refill, 133/0/19 over 152; m55 the 2/2
    refill, then 1954 of 1954 and 135/0/21 over 156; m57 the
    refills 186/186, 183/183 and 185/185, then 1954 of 1954 and 141/0/22
    over 163. Round 2's reviews follow; DR-1a (PR 63) is at 1c8cc5e38 after
    round 2's plan commit, the other held heads as at D.
-   **At land time, in order (§1.16, §3 item 10).** After DR-1a has merged
    through M-a and L-a, and before M-b, §8 item 9's composition is re-run on
    CT-1's final head if it has moved from 4a3220c11. M-b, the merge of trunk
    (with PR 51 to PR 62, CT-1 and DR-1a) into this branch, never a rebase:
    handle_index.cpp resolves onto TP-1's `PerformIndex(context, loc_id, ...)`
    (§2.2, as measured on mct-b); PR 55's string_indexing takes trunk's side,
    PR 55's text, in its two CHECK-only conflict blocks;
    fork/conformance/README.md is regenerated with `runner.py
    --update-readme-table` (its table conflicts with PR 60's and PR 62's);
    records keep both sides (amended 2026-10-22, re-review round 1: R1R2-m5).
    C-b, "DR-1b: index a
    template-dependent operand per specific (TP-1's `IndexAction`)", +19/-1, its
    added lines measured on mct-b at the fold. L-b, the refill commit: check
    generic/template/index (16/41, after C-b) and PR 55's
    check/operators/overloaded/string_indexing (2/2), measured on mct-b and m55;
    PR 51's buf_field goldens and PR 57's check/slice/basic are not refilled, as
    measured. Then the gate and conformance on the merged tree, a second id
    re-scan, and the merged runs recorded here.
