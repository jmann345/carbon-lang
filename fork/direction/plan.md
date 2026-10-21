<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# DR-1: direction realignment (plan, rev 1)

Workstream DR-1 of decision-log entry DR-0 (D-DR-1..D-DR-4) under rulebook R32
and decision-log V-3b: `Match` for classes and `Core.Optional`'s `impl as Match`
(W-320, with W-322's retirement of PR 62's D-SV-7 view and W-323's corrections
on PR 56's branch), `Core.Iterate.Next`'s `ref cursor` (W-321), and
`Core.Slice`'s element access through `IndirectIndexWith` (W-109). Branch
claude/carbon-fork-0-1-dr, cut from trunk f68681114 (toolchain state 0bdce60a5).
Upstream's recorded direction is read at upstream/trunk fb7eff130 (fetched
2026-10-21 by `git fetch upstream trunk`; FETCH_HEAD and upstream/trunk both
name fb7eff130db358269913e1003ae39d259d3d1f55, "Move IdentifiedFacetType to
check (PR 8004)", 2026-10-21 13:20 UTC). Every measurement below is
container-local and EXPECTED, not of record (R9); the arbiter is the carbonbuild
scripts (R28), never the owner's runner, and the upstream nightly 2026.10.12 is
an oracle only (R30).

Rev 1, 2026-10-21. Decisions D-DR-5..D-DR-22 are new here (D-DR-1..D-DR-4 are
DR-0's); they are auto-adopted under R29(a), recorded in the decision log by the
plan's records commit, and each carries a break condition.

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

## §0 Audit: measurements with file:line evidence

### §0.1 Toolchains, scratch and result codes

`$X` below is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/dr1/planner
(probes, logs and diffs; deleted with the session). Every probe was compiled,
linked and run by `$X/bin/runprobe.sh <carbon> <file> <outdir>`, which prints
COMPILE-FAIL with the first `error:` text, LINK-FAIL, or RUN with the program's
standard output; `XDG_CACHE_HOME` was `$X/xdg` throughout.

| Name | What | Version string | State |
| --- | --- | --- | --- |
| trunk | /home/user/carbon-build/carbon-trunk/install | 0.0.0-0.dev+0bdce60a5 | read-only; file_test 1942 of 1942, conformance 128/0/22 over 150 (carbonbuild README's validation record) |
| nightly | /home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12 | 0.0.0-0.nightly.2026.10.12+62f1cc6 | upstream 62f1cc6a3, contains df3cf9294 (the `ref` cursor) and not 6d80ceb58 or 309d3d63c |
| op, op2 | PR 56 and PR 57 installs | +5d9edb3e0, +9f9ccd768 | install sha to head 379f20f67 and 628273444: testdata only (`git diff --shortstat` over toolchain and core) |
| sv | PR 62 install | +a4d979619 | to head 3a6531157: four goldens only |
| tp | PR 61 install | +eafca5cb9 | to head 5661a35c8: two goldens only |
| st | PR 55 install | +84ff63560 | to head 21307851a: ten goldens only |
| v2 | slice 2's prototype: trunk plus §2.1's files | relinked over trunk's objects into /dev/shm/dr1-planner/carbon-dr (handle_loop_statement.cpp the one translation unit) | gate and conformance in §0.6 |
| v3 | slices 2 and 3: trunk plus §2.1's and §2.2's files | full build.sh/install.sh of this worktree into /home/user/carbon-build/carbon-dr (core_identifier.def is an X-macro: every includer of context.h recompiles) | gate and conformance in §0.6 |

The relink of v2 was produced by `$X/bin/relink.py`, which rewrites trunk's
build.ninja so that the changed translation units compile from this worktree
with trunk's flags (this worktree's include root first) and the three binaries
link over trunk's read-only objects (absolute paths), then
`CB_BUILD_ROOT=/dev/shm/dr1-planner` install.sh. No build directory was copied.

### §0.2 The directive and the work items

DR-0, R32 and V-3b are read in full (fork/decision-log.md:22-243 as committed;
fork/rulebook.md:383-408), as are the research's research_final.md,
research_verdicts.json and research_evidence.json; this plan does not restate
them. The five work items, on trunk's fork/inventory/work-items.json: W-320
(`Core.Optional` matchable by `Match`, XL), W-321 (the `ref` cursor at 11 sites,
M), W-322 (PR 62's D-SV-7 view, a V-3a divergence, S, blocked by W-320), W-323
(records corrections on PR 56's branch, S) and W-109 (SL-1's write-through
residue, L, its notes dated by DR-0). DR-1 reserves W-324..W-329 (all unused on
every ref at DR-0's re-scan) and may mint F-022 (§1.17 decides not to).

### §0.3 The probe matrix (audit item 1)

Sources: `$X/a1/*.carbon` (Appendix B.0 lists each body). The `match` probes
write `case .None()` because the prelude's `None` is a function (§1.6);
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
arms all diverge is a fork gap of its own (filed W-329, §1.17); DR-1's programs
keep a statement after such a `match`.

### §0.4 The match path on trunk and where a `Match` class enters (audit item 2)

The refutable engine is one driver for four forms
(toolchain/check/handle_match.cpp:32-46). Its steps, the SemIR each emits today,
and where a scrutinee whose type implements `Core.Match` enters:

| Step | Trunk code | SemIR emitted today | A `Match` class |
| --- | --- | --- | --- |
| Scrutinee gate | refutable_binding.cpp:137-208 `CheckRefutableScrutinee`: `ConvertToValueOrRefExpr`, `RequireCompleteType`, `IsSupportedScrutineeType` (:83-135: int, bool, matchable choice, tuples and structs of those), else `context.TODO(node_id, todo_string)`, the strings `match on unsupported scrutinee type` and `refutable pattern binding on unsupported scrutinee type` | the scrutinee's conversion insts; `RequireCompleteType`'s `require_complete_type` witness when symbolic | enters here: a type that is none of the five shapes and implements `Core.Match` (impl lookup) is admitted, and the continuation and the `Op` call are emitted once (§1.5) |
| Alternative pattern | handle_match.cpp:248-470 `AlternativePattern`: `ResolvePendingAlternative` (refutable_binding.cpp:210-293) refuses a non-choice scrutinee with the W4 TODO `` match `case` pattern other than an integer literal, or a case guard `` (:216-224), looks the name up in `Class::choice_alternatives` (pattern_match.cpp:512-528), applies the parens rule (`MatchAlternativeUnexpectedParens` :236, `MatchAlternativeMissingParens` :252, `MatchAlternativeArgCountMismatch` :275), and wraps the payload subpatterns in a synthesized `TuplePattern` | `TuplePattern` (synthesized), `ExprPattern` for the bare constant spelling; a pending alternative for `if let`, `while let`, `let`-`else` (resolved by `ResolveDeferredAlternative`, :296-337) | the name resolves against the methods of the impl's `Continuation` interface instead of `choice_alternatives`; the parens rule reads the class's factory member (§1.6) |
| Test pass | refutable_binding.cpp:339-487 `EmitRefutableBindingTest` classifies the arm; `MatchCaseAlternativePatternMatch` (pattern_match.cpp:597-694) tests the discriminant (`EmitChoiceDiscriminantTest`, :573-595) and, dominated by it, the payload's refutable subpatterns | `NameBindingDecl`; `ClassElementAccess` (element 0, the `.discriminant`), an `EqWith(disc).Equal` call through `BuildBinaryOperator`, `BranchIf`, `BranchWithArg`, `BlockArg` | the discriminant read becomes the `Op` call's result (an `i32` value) and the payload read becomes the continuation's slot; the same `EqWith` test and the same dominance structure |
| Bind pass | refutable_binding.cpp:489-603 `EmitRefutableBindingBind`; `EmitChoicePayloadFieldAccess` (pattern_match.cpp:1048-1078) reads the payload tuple out of field 1's `CustomLayoutType` region | `ClassElementAccess` (field 1), the payload tuple's element reads, binding insts (`ValueBinding`, `RefBinding`, `VarStorage` for `var`) | the payload tuple is the slot's tuple, read through `ClassElementAccess` on the continuation object and an `AsCompatible` from `MaybeUnformed(P)` to `P` |
| Exhaustiveness and usefulness | handle_match.cpp:122-174 and the key machinery (pattern_match.cpp:762-971) | none (diagnostics) | the alternatives are a closed set (sum_types.md:99-101), keyed by the `Continuation` method index |
| `for` | handle_loop_statement.cpp:204-295: `NewCursor`, an `AddrOf` of the cursor (:255-259), `Next`, then `CallOptionalAccessor` `HasValue` (:280) and `Get` (:290) under upstream's TODO (:269-272) | `VarStorage`, `AddrOf`, two `Call`s per iteration through `PerformMemberAccess` | slice 2 removes the `AddrOf` (§1.2); slice 1 replaces the two accessor calls by the while-let engine on `Next`'s result with the root `.Some(<pattern>)` (§1.8) |
| Lowering | no lower/handle_match*.cpp exists: `match` lowers through the branch instructions above | n/a | nothing new: the continuation class, its impls and functions are ordinary SemIR, lowered per specific |

Upstream's handle_match.cpp at fb7eff130 checks nothing: every handler at :11-76
is `context.TODO(...)` (for example `HandleMatchIntroducer`), and its loop
checker keeps the `.Some(pattern_id)` TODO (upstream
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

`IndirectIndexWith`. Upstream's prelude at fb7eff130,
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
    the crash; slice 3 therefore cherry-picks 230227264's code with its two
    goldens (check and lower testdata/function/call/form.carbon), which is the
    root fix (R17), not a guard in pattern_match.cpp.
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

### §0.7 The language prerequisites of sum_types.md's `Match`, measured

sum_types.md at fb7eff130 declares the interface (:107-117) and the class
example (:137-165). Each construct, probed alone on trunk and on the nightly
(`$X/probes`):

| Construct (sum_types.md) | Probe | trunk | nightly |
| --- | --- | --- | --- |
| an interface nested in an interface (`interface BaseContinuation` in `Match`, :109-111) | nested_iface.carbon | accepted | accepted |
| a template associated constant (`let template Continuation: type;`, :113) | template_assoc.carbon | `phase keyword is not allowed on an associated constant` (toolchain/parse/handle_let.cpp:37-42, the comment "The binding is a checked generic by context, so no phase keyword is used.") | the same |
| a deduced binding of the constant's facet type (`fn Op[C: Continuation](self, continuation: C*)`, :114) with a NON-template `let Continuation: type` | v1.carbon | `` cannot implicitly convert non-type value of type `Continuation` to `type` `` and `` ... into type implementing `BaseContinuation` `` | not run |
| an interface declared in an impl (`impl as Match { interface Continuation {...} }`, :146-151) giving the constant its value | iface_in_impl.carbon, iface_in_impl2.carbon | `associated constant Continuation not given a value in impl of interface M` | the same |
| an impl-scope `let R: type = i32;` giving a constant its value (indexing.md:105-109's form) | impl_let.carbon | `associated constant R not given a value in impl of interface I` | the same |
| `extend Match.BaseContinuation;` in an interface (:148) | ext_iface.carbon | `unrecognized declaration introducer` | the same |
| its current spelling `extend require impls Base;` (details.md:1485-1497, p5337) with `-> R` naming the extended interface's constant | ext_req.carbon, ext_req2.carbon (`Self.(Base.R)` spelled out) | `` cannot convert type `Self` that implements `Cont` into type implementing `Base` `` | the same |
| an interface nested in a class, the continuation class implementing it, a class member `Op[C: OptCont](self, continuation: C*) -> i32` calling `continuation->Some(...)` | iface_in_class.carbon, v2.carbon | accepted; v2 runs | accepted |

So the class example cannot be written on either toolchain today, for three
reasons that are each a language feature upstream's design states and upstream's
toolchain does not implement: L1 template associated constants
(sum_types.md:113, with details.md:4341-4354's `let template` semantics, "Uses
of `T` are then template constants"), L2 an impl member that gives an associated
constant its value (the nested `interface Continuation` of :146-151;
indexing.md:105-109's `let ElementType: type = T;`), and L3 member access
through `extend require impls` to the extended interface's associated constants
(details.md:1452-1545; the `ReturnType` of :149-150 and the `C.ReturnType` of
:153). The mechanism itself (L4: the compiler-generated continuation, its `Op`
call and the dispatch) is ordinary SemIR, as p1 measured (§0.6). Upstream's
sources disagree on L1: sum_types.md:113 writes `let template` and upstream's
parser refuses any phase keyword on an associated constant; no accepted proposal
speaks to template associated constants (a `git grep "let template"` over
proposals/ and docs/design/ at fb7eff130 finds sum_types.md:113 as the only
interface member; the others are function- or class-scope `let template`,
p002200 among them). §1.4 decides.

### §0.8 Collisions with the held PRs (audit item 5)

Each held PR's own diff (merge-base with trunk to its head) over the files DR-1
changes, from `git diff --numstat`; then the source hunks of v3 (prelude, the
six toolchain files, min_prelude, the program; `$X/dry_src.diff`) dry-run with
`git apply --cached --check` into a temporary index of each head:

| Held PR (head) | DR-1 files it touches (numstat) | v3's source hunks onto it | Rule at DR-1's merge |
| --- | --- | --- | --- |
| PR 51 UA-2 (f96fe8a7a) | docs/design/slices.md +14/-6; records | apply | slices.md: both sides' text, the 0.1-limits bullet D-DR-7 removes is UA-2-independent; records keep both sides |
| PR 52 CM-1 (ea573f672), PR 54 EV-1 | records only | apply | none |
| PR 53 SAFE-1 (adaae4e35) | docs/design/slices.md +7; records | apply | slices.md both sides |
| PR 55 ST-1 (21307851a) | records; its operators/overloaded/string_indexing.carbon refill (+112 on its branch) | apply | string_indexing.carbon refilled at DR-1's merge (both moved it) |
| PR 56 OP-1 (379f20f67) | core/prelude/types/optional.carbon +73/-2, docs/design/control_flow/loops.md +4, docs/design/error_handling.md +8, docs/design/optional.md +582 | apply | slice 1's optional.carbon hunk is a different region (the `impl as Match` block and the `Try` body); W-323's new commit lands on PR 56's branch first (D-DR-3) |
| PR 57 OP-2 (628273444) | optional.carbon +111/-8 (Destroy, checked `Get`, the `MaybeUnformed` fix), loops.md +4, error_handling.md +8, optional.md +614 | apply | slice 1 composes with OP-2's `Destroy` (the continuation's slot destroy uses it) on a PR 57 mirror |
| PR 58 DD-1 (fcee90d9b) | docs/design/pattern_matching.md +258/-4 | n/a | pattern_matching.md's amendment (§1.15) is taken onto DD-1's text at merge: the land-time rule D-DR-20 |
| PR 59 VA-1 (b0822a744) | check/pattern_match.cpp +25, context.h +41, handle_binding_pattern.cpp +76, kind.def +19 | apply | slice 1's pattern_match.cpp hunks and VA-1's touch different functions (VA-1's pack bindings); composed on a mirror at slice 1 |
| PR 60 SC-1 (40a76ab81) | context.h +17, handle_binding_pattern.cpp +27/-3, handle_let_and_var.cpp +14, kind.def +13 | apply | L1's handle_let_and_var.cpp hunk (associated constants) and SC-1's (template constraints) are in different functions; measured on a mirror at slice 1 |
| PR 61 TP-1 (5661a35c8) and CT-1 (65fc0d394, stacked on it) | handle_index.cpp +42/-13 (`PerformIndex` on a `LocId`, the `IndexAction` deferral), handle_loop_statement.cpp +10/-2 (a `RequireCompleteType` on the cursor's POINTER type for a template-dependent cursor), handle_match.cpp +2/-5, refutable_binding.{h,cpp} +35/-5 (`PerformAlternativeAccess`), context.h +20, kind.def +1; goldens generic/template/for_range.carbon (check), template/for_range.carbon (lower), interop/cpp/range_for.carbon | handle_index.cpp and handle_loop_statement.cpp FAIL to apply (both regions rewritten by TP-1) | resolved by hand in DR-1's merge commit M (D-DR-20): slice 2 removes the `AddrOf`, so TP-1's pointer completeness requirement has no pointer to complete and is dropped, keeping TP-1's include only if still used; slice 3's `PerformIndexOperator` pair is re-expressed inside TP-1's `PerformIndex(context, loc_id, ...)` (its `node_id` parameter becomes `loc_id`); then the three TP-1 `for` goldens and the index goldens are refilled |
| PR 62 SV-1 (3a6531157) | refutable_binding.cpp +38 (the `std::optional`/`std::variant` conversion and the D-SV-7 `GetCoreOptionalView` branch), cpp/sum_type.{h,cpp} +1128, kind.def +8 (`CppSumType*` and `CoreOptionalNotMatchable`), core/prelude/types.carbon +1 (`prelude/types/cpp/sum`), docs/design/sum_types.md +91 | apply | W-322's new commit on PR 62's branch removes the D-SV-7 branch (D-DR-15); DR-1's `CheckRefutableScrutinee` hunk is placed after SV-1's `GetCppSumType` conversion, so a `std::optional` scrutinee still becomes `StdOptional` and a `Core.Optional` scrutinee reaches the `Match` lane |

No held PR touches core/prelude/iterate.carbon, range.carbon,
operators/index.carbon, types/slice.carbon, types/buf.carbon, call.cpp's or
convert.cpp's 230227264 lines (PR 59 and PR 62 touch convert.cpp elsewhere; the
hunk applies to both), core_identifier.def or cpp/operators.cpp. PR 61's own
`for` goldens are the composition's red set for slice 2, predicted, not measured
(no PR 61 mirror was built for this revision; §8 item 9).

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
(128/0/22 over 150 both). Slice 1 changes no existing program's text:
`HasValue`/`Get` stay, and the programs' `for` loops are desugared differently
but print the same. The new programs and their oracles are in §1.14 and Appendix
B.

### §0.10 Upstream's direction register and the V-3 check (audit item 7, R32)

Every upstream commit in c1e83b0b7..fb7eff130 that touches the pages and files
DR-1 changes or follows (`git log --format='%h %ad %s' c1e83b0b7..fb7eff130 --
<the files>`, the files being the three design pages, indexing.md, slices.md,
the loop, match, index and pattern checkers, thunk.cpp, impl.cpp, the iterate,
range, index and optional prelude files and proposals/):

| Commit | Date | Subject | Mechanism change for DR-1 |
| --- | --- | --- | --- |
| df3cf9294 | 2026-10-07 | Adopt `ref` in `Core.Iterate.Next` (PR 7381) | yes: `Next(self, ref cursor: CursorType)`, the loop checker passes the cursor variable, loops.md's desugaring through `match ... case .Some(<pattern>)`, proposal p007381; slice 2 and §1.8 |
| 230227264 | 2026-10-09 | Only allocate return storage when the callee has a return parameter (PR 7886) | yes, for slice 3: calls to `ref`-return functions in generic code (§0.6.1 item 1) |
| 6d80ceb58 | 2026-10-16 | Add the `IndirectIndexWith` interface to the prelude (PR 7974) | yes: slice 3 |
| 309d3d63c | 2026-10-17 | Use `IndirectIndexWith.Ref` for subscripting when available (PR 7975) | yes: slice 3 |
| 947c1eb52 | 2026-10-06 | Add a `Core.Array` class type, and make `array` refer to it. (PR 7892) | no for DR-1 (handle_index.cpp's array arm; UA-3's) |
| 1b0a5709e | 2026-10-06 | Initial support for fn expressions. (PR 7893) | no |
| a50feb64c | 2026-10-06 | Simplify proposal labels and fix GitHub label workflows (PR 7904) | no |
| 59d53ab0a | 2026-10-09 | Use ASCII quotes in character literal examples in p1964 (PR 7938) | no |
| 62f1cc6a3 | 2026-10-11 | Rename `GenericClassType` to `ParameterizedClassType` (PR 7953) | no (a rename UA-3 takes) |
| 6a0a1f3e8, b1de0e037, 24766e213, f0bae9637, e41862d55, 2b5f90cd7, fb7eff130 | 2026-10-13..21 | the `IdentifiedFacetType` and impl-checking series (PRs 7924, 7926, 7930, 7937, 7943, 7996, 8004) | no direction change; L3 (`extend require impls` lookup, §1.4) lives in this machinery and is the area of highest merge risk at UA-3 (§7) |
| bf5d2a2ac, 3af25cc1b | 2026-10-15 | `-> auto` deduced return types (PRs 7931, 7977) | no |
| 2c9739799, 7beb29f8b, d87891f3a | 2026-10-15 | diagnostics rendering, fallback locs, style (PRs 7683, 7967, 7982) | no |

sum_types.md, pattern_matching.md, indexing.md and
core/prelude/types/optional.carbon are unchanged from the cut to fb7eff130 (`git
diff --shortstat c1e83b0b7 fb7eff130` empty for each); loops.md changed only in
df3cf9294. The V-3 check of R32 (a), with each page's current text quoted at
fb7eff130:

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
    a tail call." (Carbon has no tail calls; DR-1 states no tail-call rule,
    §1.5.) p000157:497-503 adds: "`Match`'s continuation parameter type must be
    generic rather than templated". DR-1 follows these: §1.5.
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
    Optional(i32).None => ...` would not be." §1.6 follows this for
    `Core.Optional`, whose factory is the function `fn None() -> Self` (upstream
    core/prelude/types/optional.carbon:31-33 at fb7eff130).
-   **The `for` desugaring.** loops.md:109-122: "is desugared to a loop that
    manages the cursor and checks the optional return values:" followed by
    `while (true) { match (range.(Iterate.Next)(cursor)) { case .Some(<pattern>)
    => { <statements> } default => { break; } } }`, and :83 `fn Next(self, ref
    cursor: CursorType) -> Optional(ElementType);`. §1.2 and §1.8 follow these.
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
    checker at fb7eff130, which are later (6d80ceb58's message: "differs
    slightly from the design wording, which doesn't account for the copyability
    requirement"), carrying upstream's TODO "Use `IndexWith.Ref` when the
    operand is a durable reference" verbatim.
-   **Where upstream's design pages disagree among themselves on `Optional`.**
    loops.md:117-118 names neither a choice nor `Match`; sum_types.md:52-55
    declares `choice Optional(T: type)` and :135-165 shows "how `Optional` can
    be defined as a class" with `impl as Match`; pattern_matching.md:500-503
    declares `choice Optional(T: Type) { None, Some(T) }` and :526-527 says "a
    pattern of the form `Optional(T).None` is an expression pattern and is
    compared using `==`". DR-1 follows sum_types.md's class route, because it is
    the only text that keeps upstream's prelude identity at fb7eff130 (`class
    Optional(T: OptionalStorage)`, the placeholder, unchanged since the cut)
    while making `.Some(<pattern>)` work as loops.md requires; the two choice
    declarations are examples of `choice` (sum_types.md:46-56 introduces its
    example as "a sum type named `OptionalI32`", generalized "like class
    types"), and converting the prelude's class to a choice would be a second
    identity (DR-0's option (b), rejected there). pattern_matching.md:526-527's
    `==` sentence is the expression-pattern half of sum_types.md:197-199's "both
    possible implementations must be well-formed"; §1.6 records which half DR-1
    enforces.
-   **The V-3a register state.** Entering DR-1: (i) D-SV-7, (ii) D-SL-3, (iii)
    the pointer cursor (DR-0's block). Leaving it: (ii) and (iii) are resolved
    by slices 3 and 2; (i) by slice 1's land-time commit on PR 62; and one entry
    is added, (iv) template associated constants (L1): the fork accepts `let
    template` on an associated constant, which sum_types.md:113 uses and
    upstream's parser refuses (handle_let.cpp:37-42), work item W-324 (§1.4,
    §1.17).

### §0.11 Ids

The trunk ledger's highest id is W-125 plus W-320..W-323 (DR-0). DR-1 allocates
W-324..W-329 below (§1.17) on the reservation DR-0 recorded; the re-scan of
every origin ref's and worktree's ledger for `W-32[4-9]` is repeated at the
records commit, the CT-1 §0.11 command widened to that pattern, and recorded
there. F-022 is not minted (§1.17).

## §1 Design

Each decision is auto-adopted under R29(a), recorded by the plan's records
commit in the decision-log entry "DR-1" (Appendix C.1), and veto-able after the
fact; each states the upstream text it follows and its break condition.

### §1.1 Slice order and PR shape (D-DR-5)

Four PRs, in this order, each one milestone feature (R29(b)):

| PR | Slice | Work items | Branch and base | Size, measured or estimated |
| --- | --- | --- | --- | --- |
| DR-1a | slice 2: the `ref` cursor | W-321 | claude/carbon-fork-0-1-dr from trunk f68681114 | measured (v2): 5 source files, 4 test sources, 1 program, 9 goldens |
| DR-1b | slice 3: element access through `IndirectIndexWith` | W-109 | the same branch, after DR-1a | measured (v3): 6 toolchain and prelude files plus 230227264's two, 11 goldens plus 2 new from 230227264 |
| DR-1c | slice 1a: the language prerequisites of `Match` (L1, L2, L3 of §0.7) | W-324 (filed by this plan) | claude/carbon-fork-0-1-dr-match, cut from this branch's head after DR-1b, then a merge commit M of CT-1's head (records-only resolution in the CT-1/TP-1 shape) | estimated: parse/handle_let.cpp, check handle_let_and_var.cpp, impl.cpp, member_access.cpp, facet/impl lookup; not prototyped (§8.1) |
| DR-1d | slice 1b: `Match` for classes, `Core.Optional`'s impl, the refutable forms, the `for` desugaring, the `Try` body | W-320; W-322 and W-323 by land-time commits on PR 62 and PR 56 | the same branch as DR-1c, after it | estimated; the generated code's shape measured by hand (p1) |

The order follows dependency and risk: slice 2 is the base slice 1's `for`
desugaring stands on (loops.md:83 and :117 come from one upstream commit,
df3cf9294) and is fully measured; slice 3 is independent and fully measured;
slice 1 is XL and starts with its prerequisites, the step most likely to stop
(§3's shrink line). DR-1a and DR-1b are cut from trunk as the worktree is; DR-1c
and DR-1d sit on CT-1's head because L1 makes uses of a template associated
constant template-dependent, which is TP-1's machinery
(`IsOpaqueTemplateDependentType`, `AddDependentActionSplice`, the dependent
actions; PR 61's toolchain/check/action.cpp), absent from trunk, and because
DR-1 merges after CT-1 in ORCHESTRATION's order anyway. Break condition: if
DR-1c's first prototype (§3 item 9) shows L1 needs no TP-1 machinery, DR-1c and
DR-1d are re-cut onto DR-1b alone and the merge commit M moves to land time; if
any of L1..L3 cannot land within slice 1's fix budget, DR-1d does not start and
W-320 is narrowed (§3's shrink line), never respelled.

### §1.2 Slice 2: the `ref` cursor (D-DR-6)

`Core.Iterate.Next` becomes `fn Next(self, ref cursor: CursorType) ->
Optional(ElementType);` (upstream core/prelude/iterate.carbon:17 at fb7eff130),
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
rework, loops.md:96-97's TODO); the slice follows it.

### §1.3 Slice 3: `IndirectIndexWith` and `Slice`/`Buf` (D-DR-7)

The prelude's index.carbon becomes upstream's at fb7eff130 verbatim (§0.5);
subscripting tries `IndirectIndexWith(I).Ref` without diagnosing and falls back
to `IndexWith(I).At` with diagnostics, under upstream's TODO "Use
`IndexWith.Ref` when the operand is a durable reference" (309d3d63c,
re-expressed in the fork's `default:` arm, because upstream's handle_index.cpp
also carries 947c1eb52's `Core.Array` arm, which UA-3 brings);
`IndirectIndexWith` and `Ref` join core_identifier.def and cpp/operators.cpp
maps `IndirectIndexWith` to no C++ operator (309d3d63c verbatim). 230227264 is
cherry-picked with its goldens (§0.6.1 item 1). `Core.Slice(T)` and
`Core.Buf(T)` implement `final ... as IndirectIndexWith(i64) where .ElementType
= T` with a bounds-checked `Ref` returning `ref T` (indexing.md:113-121's `Span`
shape), and their `IndexWith(i64)` comes from the blanket `final` impl (their
`T` is `Copy`), so `s[i]` and `b[i]` are durable references: `s[i] = v` writes
through (W-109), reads are unchanged (`s_read`: `10 4`), and a C++ `std::span`
sees the write (`s_span_write`: `18`). The fork's literal-subscript rule
(D-SL-17, handle_index.cpp:107-157) probes `IndirectIndexWith(i64)` before
`IndexWith(i64)`, so a type with only `IndirectIndexWith(i64)` and a non-`Copy`
element still converts a literal subscript. `Buf.Set` (buf.carbon:48-53) stays:
it is a method, not a second spelling of an upstream mechanism, and existing
programs call it. D-SL-3 is retired by its own break condition
("`IndirectIndexWith`/`ref`-returning methods land in the toolchain;
`Core.Slice` then switches to indexing.md's `Span` shape and the pin is
deleted"; fork/slices/plan.md:233-236), its pin `fail_write_through` deleted
(measured). `Slice(const T)` stays non-writable where the element type is known
(`s_const`: `expression is not assignable`); a generic body writing `s[i] = v`
instantiated at a `const` element writes (`s_generic_const2`), as a generic `*p
= v` does through `const T*` on trunk and on upstream's nightly
(`s_ptr_const_write`: `7` on both): the root is the per-specific `const` check
that the language's implementation lacks, filed W-327, and it is not a reason to
keep `Slice` read-only (R32 (d) names "a read-only index where upstream added
IndirectIndexWith" as a drift). Break condition: upstream's `Core.Slice`
proposal (PR 7536) or proposal 5389 reworks these interfaces; slice 3 follows.

### §1.4 Slice 1a: the language prerequisites (D-DR-8)

The three features of §0.7, each implemented as upstream's design text states it
and nowhere else used by DR-1 than sum_types.md requires:

-   **L1, template associated constants.** `let template N: T;` in an interface
    body declares an associated constant whose uses inside the interface are
    template constants (details.md:4341-4354: "Uses of `T` are then template
    constants"), so `fn Op[C: Continuation](self, continuation: C*) ->
    C.(BaseContinuation.ReturnType);` (sum_types.md:114-115) declares `Op` with
    a template-dependent deduced binding: its signature is checked per impl,
    after the impl's value for `Continuation` is substituted, the way TP-1
    checks a template-dependent signature per specific. Parse:
    toolchain/parse/handle_let.cpp:37-42 accepts the `template` keyword before
    an associated constant's name (`generic` and `runtime` stay refused with the
    same diagnostic). Check: handle_let_and_var.cpp's associated-constant path
    records the binding as a template binding (`is_template` on the
    `SymbolicBinding`, the flag function-scope template bindings already carry),
    and impl.cpp's signature matching substitutes the impl's constant value
    before matching a member whose declaration is template-dependent. This
    contradicts upstream's parser (handle_let.cpp's comment "The binding is a
    checked generic by context, so no phase keyword is used.") and follows
    upstream's design page; DR-1 records the conflict as V-3a register entry
    (iv) with W-324 and the break condition: if upstream decides associated
    constants are never templates (a proposal, or a change to sum_types.md:113),
    DR-1's `Match` follows upstream's revised declaration and L1 is removed.
-   **L2, impl members that give an associated constant its value.** In `impl as
    I { ... }`, a member declaration whose name is an associated constant of `I`
    and which declares a value of that constant's type (an `interface`
    declaration for a `type` constant, sum_types.md:146-151; a `let N: T = v;`,
    indexing.md:105-109) sets the impl witness's entry for the constant, as
    `where .N = v` does today, and is diagnosed as a conflict if a `where`
    clause sets it too. Check: impl.cpp (witness completion, where `associated
    constant ... not given a value in impl of interface` is diagnosed) and the
    nested-declaration scope of an impl.
-   **L3, `extend require impls` member access.** In an interface `J { extend
    require impls I; ... }`, the names of `I`'s members are found in `J`
    (details.md:1489-1497's equivalence with `alias`), and a facet of type `J`
    converts to a facet of type `I` through the requirement, so `fn Some(ref
    self, value: T) -> ReturnType;` (sum_types.md:149) and `C.ReturnType` (:153)
    resolve. The design page's `extend Match.BaseContinuation;` (:148) is
    spelled `extend require impls Match.BaseContinuation;`, the spelling p5337
    adopted (details.md:1485-1488 records the TODO to update older text): the
    same mechanism in current syntax, not a second spelling. Check:
    name_lookup.cpp's extended-scope lookup for interfaces, facet conversion
    (facet_type.cpp, impl_lookup.cpp) for the require. This is the machinery
    upstream's `IdentifiedFacetType` series (PRs 7924 to 8004) is reworking; §7
    R-3 carries the merge risk.

Break condition for D-DR-8 as a whole: any of L1..L3 lands upstream first (DR-1
takes upstream's code at UA-3 and drops its own), or is decided against upstream
(DR-1 follows the decision).

### §1.5 The `Match` mechanism and its SemIR (D-DR-9)

The prelude gains library `prelude/match` (core/prelude/match.carbon, exported
by core/prelude.carbon beside `prelude/iterate` and imported by
core/prelude/types/optional.carbon) with sum_types.md:108-116 verbatim:

<!-- google-doc-style-ignore -->

```carbon
interface Match {
  interface BaseContinuation {
    let ReturnType: type;
  }

  let template Continuation: type;
  fn Op[C: Continuation](self, continuation: C*)
    -> C.(BaseContinuation.ReturnType);
}
```

<!-- google-doc-style-resume -->

A refutable form (a `match` statement, `if let`, `while let`, `let`-`else`, and
the `for` desugaring of §1.8) whose scrutinee type `S` is none of the five
existing shapes and implements `Core.Match` is matched through `S`'s `Match`
impl, exactly once per evaluation of the scrutinee (once per `while let` and
`for` iteration), in these steps:

1.  **Admission** (refutable_binding.cpp `CheckRefutableScrutinee`, after SV-1's
    `std::optional` conversion when PR 62 is composed): `LookupImplWitness(S,
    Core.Match)` succeeds without diagnosing. The impl's `Continuation` value,
    read from the witness (`ImplWitnessAccess` of the `Continuation` element,
    then `GetConstantValueInSpecific`), must be a facet type naming one
    interface `K`; its methods, in declaration order, are the alternatives,
    method k's explicit parameters after `ref self` its parameter types `P_k`,
    all with `S`'s specific substituted. A `Continuation` that is not an
    interface, or a `K` with a method that is not of the form `fn Name(ref self,
    params...) -> ReturnType`, is diagnosed at the scrutinee
    (`MatchContinuationNotInterface`, `MatchContinuationMethodShape`; §1.12) and
    the form is aborted, as the scrutinee TODO aborts today.
2.  **The continuation class** (new file toolchain/check/match_continuation.cpp,
    `BuildMatchContinuation`): an anonymous local class in the current
    function's scope (the measured `local_class_generic` shape: generic exactly
    when the function is), declared through the same entity path
    handle_choice.cpp uses to synthesize a choice's class (`ClassDecl`,
    `ClassType`, a `CompleteTypeWitness`), with fields `.index: i32` and one
    `.slot<k>: MaybeUnformed((P_k...))` per alternative with parameters; an
    `impl as Match.BaseContinuation where .ReturnType = i32`; an `impl as K`
    whose method k is a synthesized `FunctionDecl` with a body that initializes
    `self.slot<k> unsafe as (P_k...)` from its parameters (a copy: each `P_k`
    must be `Copy`, else `MatchContinuationParamNotCopy` at the alternative's
    use, W-328), assigns `self.index = k` and returns `k`; and an `impl as
    Destroy` whose `Op` destroys `slot<index>` when `index >= 0` (one `if` per
    alternative with parameters, each `BuildSelfDestructCall` on the slot's
    `unsafe as` view), so a `Core.String` payload is destroyed once, at the
    owning scope's end. The class, its impls and functions are created once per
    refutable form, as sum_types.md:171-187's `__MatchStatementImpl` is ("the
    actual generated class will be anonymous", :186-187).
3.  **The call** (the same function): a `VarStorage` of the continuation class
    with `.index` initialized to `-1` and the slots unformed (`UnformedInit`),
    then `Op` called once: `ImplWitnessAccess` of `Op` in `S`'s `Match` witness,
    a `SpecificImplFunction` with `C` deduced as the continuation class's facet
    `FacetValue` (its witness for `K`), the scrutinee as `self`, and an `AddrOf`
    of the storage as `continuation`, through `PerformCall`. The call's `i32`
    result is the form's discriminant value. `Op` is required to call exactly
    one method exactly once (sum_types.md:127-129); the compiler does not verify
    it (as the `Try` laws are documented, not verified); a misbehaving `Op`
    leaves `.index` at `-1` or a slot reassigned, and the dispatch takes no arm
    (W-325 records the unchecked contract, §1.17).
4.  **The arms** (pattern_match.cpp, through the choice lane's code with two
    hooks): an alternative pattern's name resolves against the alternatives of
    step 1 (a new `LookupMatchAlternative` beside `LookupChoiceAlternative`),
    its parens rule against the class's factory member (§1.6), its arity against
    `P_k`; its test is `EqWith(i32).Equal` of the discriminant value and `k`
    (`EmitChoiceDiscriminantTest`'s body with the value in place of the
    `.discriminant` field read), and its payload tuple, read only under that
    test (the W-008 dominance rule, pattern_match.cpp:639-648), is
    `ClassElementAccess` of `.slot<k>` on the storage converted `unsafe as
    (P_k...)` (an `AsCompatible`); the payload subpatterns then go through the
    existing payload machinery unchanged (`MatchCasePatternMatch`,
    `MatchCaseBindPatternMatch`, `LocalPatternMatch`).
5.  **Exhaustiveness and usefulness** reuse SF-7's choice machinery with the
    alternative count of step 1: the alternatives "are a closed set" because
    "the compiler can ... determine whether any `case`s are missing"
    (sum_types.md:99-101).

SemIR: no new instruction kind. Reused: `LookupImplWitness`,
`ImplWitnessAccess`, `FacetValue`, `SpecificImplFunction`, `ClassDecl`,
`ClassType`, `FieldDecl`, `ImplDecl`, `ImplWitness`, `ImplWitnessTable`,
`FunctionDecl`, `StructValue`, `VarStorage`, `AddrOf`, `Call`,
`ClassElementAccess`, `AsCompatible`, `Assign`, `ReturnExpr`, `IntValue`
(through `MakeIntLiteral` and conversion), the `EqWith` call, `BranchIf`,
`Branch`, `BranchWithArg`, `BlockArg`, `NameBindingDecl` and the binding
instructions. Lowering: nothing new; the continuation's functions are lowered
per specific like any local class's, as `desugar_*` and `local_class_generic`
measured. Break condition: upstream implements `Match` (DR-1 takes its mechanism
at UA-3), or adds tail calls and the TODO at sum_types.md:132-133 becomes a
requirement (the store-and-index continuation is unaffected: its methods do not
call back).

### §1.6 `Core.Optional`'s `impl as Match` and the `.None()` spelling (D-DR-10)

core/prelude/types/optional.carbon keeps the class `Optional(T:
OptionalStorage)`, its `adapt T.Type` storage with the `T*` null niche
(p006357's pointer ABI; optional.carbon:186-204), `None()`, `Some(value: T)`,
`HasValue()`, `Get()`, the conversions and the `Try` signature, and gains,
inside the class, sum_types.md:146-160 with only the storage reads changed (the
example's `self.has_value` and `self.value` are its own illustrative fields; the
prelude's are behind `OptionalStorage`):

<!-- google-doc-style-ignore -->

```carbon
  impl as Match {
    interface Continuation {
      extend require impls Match.BaseContinuation;
      fn Some(ref self, value: T) -> ReturnType;
      fn None(ref self) -> ReturnType;
    }

    fn Op[C: Continuation](self, continuation: C*) -> C.ReturnType {
      if (self.HasValue()) {
        return continuation->Some(self.Get());
      } else {
        return continuation->None();
      }
    }
  }
```

<!-- google-doc-style-resume -->

`argv: Core.Optional(char*)*` (the entry signature) is untouched: the class and
its layout do not change, and no `match` is involved in passing it. The empty
alternative's pattern is `.None()`, not `.None`: sum_types.md:214-222 makes an
alternative pattern without arguments take its expression's syntax, and
`Optional(T).None` is the function `fn None() -> Self` in upstream's prelude at
fb7eff130 (optional.carbon:31-33, the placeholder unchanged since the cut) and
in the fork's; PR 56's F-015 froze the same function (its
fork/optional/plan.md:212-214). The parens rule therefore reads the scrutinee
class's member named like the alternative: a function member requires
parentheses (`MatchAlternativeMissingParens` reused, its text unchanged:
"alternative `None` is declared with a parameter list, so its pattern requires
parentheses"), a non-function member forbids them
(`MatchAlternativeUnexpectedParens`), and a class with no member of that name
takes parentheses iff the `Continuation` method has parameters. "Both possible
implementations must be well-formed (and this is enforced by the compiler)"
(sum_types.md:197-198) is enforced for the expression half's well-formedness of
the factory call or constant (the expression `S.Name(args)` or `S.Name` must
check and convert to `S`, in a discarded block) and not for the `==` half, which
the fork's choice lane does not enforce either (pattern_matching.md:526-527):
W-326. Break condition: upstream's prelude makes `None` a constant (`let None:
Self`), and the pattern becomes `.None`; or upstream makes `Optional` a choice
(D-DR-1's break condition).

### §1.7 Refutable forms on a `Match` class (D-DR-11)

`match`, `if let`, `while let` and `let`-`else` share the engine, so the four
admit and gate the same shapes (handle_match.cpp:41-46): `.Some(<subpatterns>)`
with bindings (value and `var`), constant expressions and nested tuples, struct
patterns and nested alternative patterns on `Match` or choice payloads (`case
.Some(.Some(x: i32))`, o_nested), guards, and `default`. `ref` subpatterns on a
`Match` alternative are OUT: the alternative's parameter is a value (`value: T`,
sum_types.md:149) and the slot is the continuation's copy, so a `ref` binding
would alias the copy, not the scrutinee; diagnosed `MatchAlternativeRefBinding`
(§1.12), W-328. A pattern condition's or `let`-`else`'s deferred alternative
(refutable_binding.cpp:296-337) resolves against the `Match` alternatives once
its scrutinee is checked, as for a choice. The irrefutable-pattern warning fires
for a `Match` alternative only when the `Continuation` has exactly one method
(the single-alternative choice rule, refutable_binding.cpp:470-480). Break
condition: upstream specifies `ref` bindings into a continuation parameter.

### §1.8 The `for` desugaring through `Match` (D-DR-12)

handle_loop_statement.cpp's `ForHeader` keeps the range conversion, `NewCursor`
and the cursor `VarStorage`, calls `Next` with the cursor by `ref` (slice 2),
and then, in place of
`CallOptionalAccessor(HasValue)`/`CallOptionalAccessor(Get)` (:269-291), runs
the while-let engine on the `Next` call's result with a root alternative
`.Some(<pattern>)` built from the loop's pattern (the `Some` alternative of
`Core.Optional`'s `Continuation`, resolved by name through
`LookupMatchAlternative`), the loop's body entered when that arm's test holds
and the loop exited otherwise: loops.md:116-120's `match
(range.(Iterate.Next)(cursor)) { case .Some(<pattern>) => { <statements> }
default => { break; } }` (the `default => break` is the exit edge of
`BranchAndStartLoopBody`). Upstream's TODO (:235-238 there, :269-272 here) is
removed by this change, its comment replaced by the loops.md citation.
`CallOptionalAccessor` (:191-202) is deleted with its two calls. The thirteen
programs that use `for` (§0.9) are the regression set; they print the same.
Break condition: upstream implements its TODO by another mechanism.

### §1.9 The `Try` body (D-DR-13)

`final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try where
.ContinueType = T and .BreakType = ()` (optional.carbon:69-70) keeps its
signature; `Branch`'s body becomes error_handling.md's sketch
(docs/design/error_handling.md:392-405), with `.None()` for §1.6's reason and
the sketch's own unreachable trailing return, which §0.3's `c_exh_return` shows
is still needed:

<!-- google-doc-style-ignore -->

```carbon
  fn Branch(self) -> ControlFlow(T, ()) {
    match (self) {
      case .Some(v: T) => { return ControlFlow(T, ()).Continue(v); }
      case .None() => { return ControlFlow(T, ()).Break(()); }
    }
    // Unreachable trailing return: reachability doesn't consult match
    // exhaustiveness; under `final` the recursive call type-collapses.
    return self.(Try.Branch)();
  }
```

<!-- google-doc-style-resume -->

The `impl as Match` block precedes the `Try` impl in the file so that the
`match` finds it. The comment block at optional.carbon:56-68 is rewritten to
cite D-DR-13. `o_try` (`2 -1`) and
fork/conformance/programs/error_handling/optional_try.carbon are the regression
set. Break condition: none beyond D-DR-1's; this is the new decision D-DR-1
names.

### §1.10 Templates and generics (D-DR-14)

A `Core.Optional(T)` scrutinee with `T` a checked generic binding (o_generic) is
matched in the generic's definition: its `Match` impl is found for the symbolic
specific, the alternatives' parameter types are symbolic, and the continuation
is a local class of the generic function, monomorphized per specific (the
measured `local_class_generic` and `desugar_generic` shapes, `4 7` and `4 7 9`).
A scrutinee `Core.Optional(T)` with `T` a template binding (o_template) is the
same case: the scrutinee's type is a specific of `Optional`, not an opaque
template-dependent type, and p000157:497-503 requires the continuation to be
generic, not templated. A scrutinee whose own type is opaque and
template-dependent (a `template U: type` value matched directly) keeps TP-1's
disposition, the scrutinee TODO measured on PR 61's install (`match on
unsupported scrutinee type`), because the alternatives and the `Match` impl are
unknown until instantiation and the refutable form has no deferred action: part
of W-325 (§1.17). A scrutinee of a facet type `U: Core.Match` (a generic binding
constrained by `Match` alone) is OUT: its `Continuation` is a template
associated constant of an unknown impl, so its alternatives are unknown in the
definition; diagnosed `MatchScrutineeSymbolicMatch` (§1.12), part of W-325.
Break condition: upstream specifies matching on a symbolic `Match` type.

### §1.11 C++ interop and D-SV-7's retirement (D-DR-15)

The `std::optional` and `std::variant` mapping (F-020:
`Core.CppCompat.StdOptional(T)` and `StdVariant<N>` choices, converted by value
through the C++ accessors, and the conversions between `StdOptional(T)` and
`Core.Optional(T)`) is not the drift and stays: a `std::optional` scrutinee is
still converted to `StdOptional` and matched as that choice, with `.None` (its
constant). A `Core.Optional(T)` scrutinee, including one converted from a
`std::optional` argument (sv_view), is matched through `Match` directly, with
`.None()`. W-322's land-time commit on PR 62's branch (§3 item 15) removes, from
PR 62's head: the `else if (auto view = GetCoreOptionalView(...))` branch of
`CheckRefutableScrutinee` (its refutable_binding.cpp hunk's second half, 21
lines); `GetCoreOptionalPayload`, `ClassifyCoreOptional`, `GetCoreOptionalView`,
`DiagnoseCoreOptionalNotMatchable` and the `CoreOptionalView` struct from
cpp/sum_type.cpp (its :653-758 region, the functions at :680, :714, :732, :749)
and cpp/sum_type.h; `CARBON_DIAGNOSTIC_KIND(CoreOptionalNotMatchable)` from
kind.def; and toolchain/check/testdata/match/core_optional_view.carbon, whose
four splits are re-sourced under match/core_optional.carbon's Match-route splits
(`concrete`, `pointer`, the generic split now succeeding, the aggregate split
now succeeding). It keeps `GetCppSumType`, `ConvertCppSumToCarbon`,
`ConvertCarbonSumToCpp`, the `CppSumType*` diagnostics and every std goldens.
The measured size of the removal on a PR 62 mirror is §8 item 9's; the composed
probes sv_view and sv_std_match are predicted to print `5 -1` each with
`.None()` and `.None` respectively. PR 62's sum_types.md section that describes
the view gains a dated amendment (Appendix C.6). Break condition: D-DR-2's.

### §1.12 Diagnostics for the OUT shapes (D-DR-16)

| Kind (new unless marked) | Text | Where |
| --- | --- | --- |
| `MatchContinuationNotInterface` | "`Match.Continuation` of {0} is not an interface, so {0} cannot be matched" | scrutinee |
| `MatchContinuationMethodShape` | "method `{1}` of {0}'s `Match.Continuation` is not an alternative: it must take `ref self` and return `ReturnType`" | scrutinee, note at the method |
| `MatchContinuationParamNotCopy` | "alternative `{0}`'s parameter of type {1} is not copyable; matching it is not supported in 0.1" | the alternative pattern |
| `MatchAlternativeRefBinding` | "a `ref` binding cannot bind a parameter of alternative `{0}`, which is passed by value" | the `ref` binding |
| `MatchScrutineeSymbolicMatch` | "cannot match a value of type {0} in its generic definition: its `Match` alternatives are not known" | scrutinee |
| `MatchAlternativeMissingParens`, `MatchAlternativeUnexpectedParens`, `MatchAlternativeArgCountMismatch` (reused, texts unchanged) | as refutable_binding.cpp:236-279 | the alternative pattern |
| `PhaseKeywordInAssociatedConstant` (narrowed, text unchanged) | "phase keyword is not allowed on an associated constant", now for `generic` and `runtime` only | parse |
| the scrutinee TODOs (unchanged) | `match on unsupported scrutinee type`, `refutable pattern binding on unsupported scrutinee type` | an opaque template-dependent scrutinee, and every type that is none of the six shapes |

Break condition: an implementation review finds a text that misdescribes its
rule; the text is corrected, the kind kept.

### §1.13 Goldens (D-DR-17)

All CHECK lines come from autoupdate (R16); the sources are Appendix A. DR-1a:
the nine refills of §0.6 and no new file. DR-1b: the eleven refills of §0.6.1,
`fail_write_through` deleted, 230227264's
check/testdata/function/call/form.carbon and
lower/testdata/function/call/form.carbon added as upstream wrote them (the CHECK
lines then refilled by this tree's autoupdate), and new:
check/testdata/slice/write_through.carbon (A.1) and
lower/testdata/slice/write_through.carbon (A.2). DR-1c:
check/testdata/interface/template_assoc_const.carbon (A.3),
impl/assoc_const_member.carbon (A.4), interface/extend_require_member.carbon
(A.5), parse/testdata/let/template_assoc_const.carbon (A.6). DR-1d:
check/testdata/match/core_optional.carbon (A.7), match/user_sum_type.carbon
(A.8), match/fail_match_class.carbon (A.9, the OUT rows of §1.12),
if/if_let_optional.carbon, while/while_let_optional.carbon,
let/let_else_optional.carbon (A.10), lower/testdata/match/core_optional.carbon
(A.11); predicted refills: the nine `for` goldens again (the accessor calls
become the `Op` call, the continuation class and the arm), every golden that
dumps `Core.Optional`'s imports (the class scope gains the `Match` impl; at most
the 36 files that mention `Optional` or `HasValue`), and every golden that dumps
the prelude's library list (the new `prelude/match` library). The predicted set
is measured at DR-1d's first fill and recorded then (§3 item 11).

### §1.14 Programs (D-DR-18)

Hand-derived EXPECTs, Appendix B. DR-1a: stdlib/iterate_interface.carbon
rewritten (§0.9). DR-1b: stdlib/slices_write_through.carbon (B.1: write, read
back, a generic fill, a `Buf` write, the bounds fail-stop in a separate program
is not added: slices_bounds_fail_stop already pins the message) and
interop/cpp_span_write_through_diff.carbon with its `.diff.cpp` (B.2, DIFF-1:
the C++ twin writes through `std::span<int>` and prints the same lines). DR-1d:
control_flow/match_core_optional.carbon (B.3: `match`, `if let`, `while let`,
`let`-`else` over `Optional(i32)`, `Optional(i32*)` with a null,
`Optional(Core.String)`, nested `Optional`, a generic),
control_flow/match_core_optional_diff.carbon with its `.diff.cpp` (B.4: the C++
twin is the same logic over `std::optional`),
control_flow/match_user_sum_type.carbon (B.5: a user class with `impl as Match`
and three alternatives, sum_types.md:135-165's shape), and
error_handling/optional_try_match.carbon is not added: optional_try.carbon
already covers the `Try` body's behavior. No SKIP moves: the 22 SKIPs' reasons
are unrelated (§5).

### §1.15 Docs and records (D-DR-19)

Design pages, each edit a dated amendment block, never a rewrite of upstream
text: docs/design/control_flow/loops.md takes upstream's fb7eff130 text for the
`Iterate` interface and the loop desugaring (it is the fork's copy of an
upstream page; DR-1a restores the two sections df3cf9294 rewrote, keeping the
fork's `while let` amendment), plus an amendment at DR-1a that the fork's `for`
calls `HasValue()`/`Get()` until DR-1d (W-320), removed by DR-1d's amendment;
docs/design/sum_types.md gains an amendment at DR-1d recording that the
toolchain implements `Match` as specified, the `extend require impls` spelling
(§1.4 L3), the store-and-index continuation (:224-227) and the 0.1 limits
(W-325, W-326, W-328); docs/design/slices.md's 0.1-limits bullet "Slices are
read-only; `s[i] = v` is an error." is replaced at DR-1b by a dated amendment
stating `IndirectIndexWith`; docs/design/error_handling.md's EH-A amendment
(:416-435) gains a dated paragraph at DR-1d; docs/design/optional.md exists only
on PR 56's branch, so its edit (D-OP-7's "not matchable" paragraph, W-177) is a
land-time commit (§3 item 16). Records: the decision-log entry "DR-1" (Appendix
C.1), the ledger (W-320 and W-321 discharged, W-109 discharged, W-322 and W-323
by their land-time commits, W-324..W-329 filed; C.2), the gap rows (C.3), the
V-3a register (C.4), ORCHESTRATION's Next actions (C.5). Gap rows, with their
current text quoted in C.3 and moved only as that text justifies: Control flow:
loops (:66) keeps DONE and loses its DR-0 drift sentence at DR-1a and DR-1d;
Stdlib: Slices (:79) stays PARTIAL (its other limits remain) and loses the
read-only sentence at DR-1b; Control flow: matching sum-type consumption (:68)
stays PARTIAL (std::variant/std::optional interop is PR 62's) and gains the
`Match` sentence at DR-1d; Stdlib: Optional (:78) stays PARTIAL on trunk
(OP-1/OP-2 decide DONE) and loses its DR-0 drift sentence at DR-1d.

### §1.16 Merge position and the held state (D-DR-20)

DR-1a and DR-1b merge after CT-1 (ORCHESTRATION's order: PR 53, 51, 52, 60, 54,
55, 56, 57, 58, 59, 61, 62, CT-1), then DR-1c and DR-1d. At each DR-1 PR's
merge, a merge commit M brings trunk (with those PRs merged) into the DR-1
branch, never a rebase: conflicts in records keep both sides; handle_index.cpp
and handle_loop_statement.cpp are resolved as §0.8's PR 61 row states; the
refill commit L-F after M refills every golden M's resolution moves (the three
TP-1 `for` goldens, PR 55's string_indexing.carbon, the index goldens).
Land-time commits on other PRs' branches, each a new commit, never a rewrite
(R32 (e)): W-323's on PR 56's branch, before PR 56 merges (now, at DR-1's plan
sign-off, since it corrects records only; Appendix C.7); W-322's on PR 62's
branch, after DR-1d is implemented and before PR 62 merges, or, if PR 62 has
merged first, as a commit on DR-1d's branch (Appendix C.6); the optional.md
amendment on PR 56's branch when DR-1d is implemented (C.8). Break condition:
ORCHESTRATION's merge order changes; the rules follow the new order.

### §1.17 Residues and F-022 (D-DR-21)

| Id | Title |
| --- | --- |
| W-324 | V-3a register entry (iv): template associated constants (`let template` on an associated constant) are accepted by the fork for sum_types.md:113's `Match` and refused by upstream's parser (toolchain/parse/handle_let.cpp:37-42); follow upstream's resolution |
| W-325 | `Match` scrutinees outside 0.1: an opaque template-dependent scrutinee (needs a deferred refutable form), a symbolic facet scrutinee `U: Core.Match`, and the unchecked "exactly one method exactly once" contract of `Match.Op` (sum_types.md:127-129) |
| W-326 | "Both possible implementations must be well-formed" (sum_types.md:197-198): the `==` half is not enforced for expression-form alternative patterns, on `Match` classes or choices (pattern_matching.md:526-527) |
| W-327 | A generic assignment whose specific's target is `const` writes: `*p = v` through `const T*` (trunk and the nightly print `7`) and `s[i] = v` through `Slice(const T)` (v3 prints `2`); the per-specific `const` check |
| W-328 | `Match` alternatives with a non-`Copy` parameter (the continuation's slot is a copy) and `ref` subpatterns on an alternative's parameter |
| W-329 | Reachability after an exhaustive `match` whose arms all diverge (`c_exh_return`: "missing `return`" on trunk with a choice; the `Try` body's trailing return) |

F-022 is not minted: every surface rule DR-1 adopts is upstream text
(sum_types.md, loops.md, indexing.md, index.carbon) or its implementation
latitude (sum_types.md:224-227), and the one point where upstream's sources
conflict (L1) is a register entry, not a fork design. Break condition: a review
finds a surface rule here that no upstream text determines; F-022 is minted for
it.

### §1.18 Decision index

| Id | Decision | Section |
| --- | --- | --- |
| D-DR-5 | four PRs, slice 2, slice 3, slice 1a, slice 1b; 1a and 1b on CT-1's head | §1.1 |
| D-DR-6 | `ref cursor` as df3cf9294, re-expressed | §1.2 |
| D-DR-7 | `IndirectIndexWith` as 6d80ceb58 and 309d3d63c, re-expressed, with 230227264 cherry-picked; `Slice` and `Buf` writable; D-SL-3 retired | §1.3 |
| D-DR-8 | L1 template associated constants, L2 impl members giving constants, L3 `extend require impls` lookup | §1.4 |
| D-DR-9 | the per-form local continuation class, store and index, one `Op` call, the choice lane keyed by the index; no new SemIR kind | §1.5 |
| D-DR-10 | `Core.Optional`'s `impl as Match` (sum_types.md:146-160 over `HasValue`/`Get`); `.None()` by sum_types.md:214-222 | §1.6 |
| D-DR-11 | the four refutable forms; `ref` subpatterns OUT | §1.7 |
| D-DR-12 | `for` through the while-let engine with root `.Some(<pattern>)` | §1.8 |
| D-DR-13 | the `Try` body as error_handling.md's sketch with `.None()` | §1.9 |
| D-DR-14 | generic and template-argument `Optional(T)` matched in the definition; opaque template-dependent and `U: Core.Match` scrutinees OUT | §1.10 |
| D-DR-15 | D-SV-7's view removed by a commit on PR 62; F-020's mapping kept | §1.11 |
| D-DR-16 | five new diagnostic kinds, three reused, one narrowed | §1.12 |
| D-DR-17 | goldens | §1.13 |
| D-DR-18 | programs | §1.14 |
| D-DR-19 | docs and records | §1.15 |
| D-DR-20 | merge after CT-1 by merge commits; land-time commits on PR 56 and PR 62 | §1.16 |
| D-DR-21 | W-324..W-329; no F-022 | §1.17 |
| D-DR-22 | the shrink line and the stop rule for slice 1 | §3 |

## §2 Spec, file by file

### §2.0 Conventions

Diffs are against trunk f68681114. "Measured" means the hunk is the one built
and gated in v2 or v3 (§0.6); "specified" means it is this plan's code, not yet
compiled, with the invariant it must keep stated. CHECK lines are never written
by hand (R16): goldens appear here only by name, their sources in Appendix A.
The full measured diff, goldens included, is kept at `$X/v3_full.diff` (2337
lines for slice 2 alone at `$X/slice2_full.diff`).

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

docs/design/control_flow/loops.md: the "`Iterate` interface" and "Loop
desugaring" subsections of upstream's fb7eff130 page (its :75-131) replace the
fork's "Ranged-for for user-defined types" subsection (the fork's :87-114), the
table of contents follows, and the fork's `while let` amendment (:38-44) and
`for` pattern-default text (:64-65) stay; after the desugaring block, the
amendment of Appendix C.9.

### §2.2 Slice 3 (DR-1b): measured

core/prelude/operators/index.carbon becomes upstream's fb7eff130 file (§0.5's
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

toolchain/check/core_identifier.def, toolchain/check/cpp/operators.cpp
(309d3d63c's lines) and 230227264's call.cpp and convert.cpp hunks (applied
unchanged by `git apply`; at implementation 230227264 is cherry-picked whole,
its message kept by the `-x` form, its two goldens refilled):

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
(:16-30) is deleted. docs/design/slices.md: Appendix C.10's amendment replaces
the 0.1-limits bullet. A known edge, not changed: when `Core` lacks
`IndirectIndexWith` (the fake-`Core` splits of
operators/overloaded/index.carbon), `HasIndexWithImpl` returns `nullopt` for it
and the literal rule does not fall back to `IndexWith(i64)`; only fake-`Core`
tests reach it, and the measured fill pins their output.

### §2.3 Slice 1a (DR-1c): specified

1.  **toolchain/parse/handle_let.cpp** `HandleAssociatedConstant`: before the
    identifier, consume an optional `Lex::TokenKind::Template` and record it on
    the node (a new parse node kind `AssociatedConstantTemplate`, mirroring how
    `TemplateBindingName` marks a `template` binding in parameter lists, added
    to parse/node_kind.def and typed_nodes.h); `generic` and `runtime` keep
    `PhaseKeywordInAssociatedConstant`. Invariant: a tree without the keyword is
    unchanged (every existing parse golden byte-identical).
2.  **toolchain/check/handle_let_and_var.cpp** (associated-constant path,
    :88-460): a `template` associated constant's `SymbolicBinding` carries
    `is_template = true`; its `AssociatedConstantDecl` is otherwise unchanged.
    In the interface's later member declarations, a name reference to it is a
    template constant (TP-1's `IsOpaqueTemplateDependentType` is true for a type
    expression naming it), so `fn Op[C: Continuation]` declares a binding whose
    type is template-dependent and `C.(BaseContinuation.ReturnType)` is a
    dependent member access (TP-1's `AccessMemberAction`).
3.  **toolchain/check/impl.cpp** (member matching against the interface): for an
    interface member whose signature is template-dependent on a template
    associated constant, substitute the impl's value for that constant (from the
    witness, after L2 has set it) into the interface member's signature before
    `CheckFunctionTypeMatches` and the thunk machinery compare it with the
    impl's member. Invariant: an interface with no template associated constant
    checks byte-identically.
4.  **toolchain/check/impl.cpp and the impl scope** (L2): when an impl's body
    declares a member whose name is an associated constant of the implemented
    interface (an `InterfaceDecl` for a `type` constant; a `let` with an
    initializer), the impl witness's entry for that constant is set to the
    member's constant value at the impl's definition completion, before the
    `ImplAssociatedConstantNeedsValue` check (the diagnostic "associated
    constant ... not given a value in impl of interface ..."); a constant set
    both by `where` and by a member is diagnosed
    `ImplAssociatedConstantSetTwice` (new, "associated constant `{0}` is given a
    value both by the `where` clause and by a member").
5.  **toolchain/check/name_lookup.cpp and facet conversion** (L3): lookup in an
    interface scope continues into the interfaces its `extend require impls`
    declarations name (the alias equivalence of details.md:1489-1497);
    `ConvertToFacet` (facet_type.cpp) of a facet whose type requires `I` through
    `extend require impls` to `I`'s facet type uses the requirement's witness.
    Invariant: an interface without `extend require impls` looks up and converts
    as before.
6.  Goldens A.3 to A.6. Measured at implementation by the §0.7 probes, which
    must then compile: template_assoc, iface_in_impl (with `extend require
    impls`), impl_let, ext_req and ext_req2; and by sum_types.md:137-165 written
    verbatim modulo `extend require impls` (a positive split in A.3).

### §2.4 Slice 1b (DR-1d): specified

core/prelude/match.carbon (new; §1.5's listing after the license header and
`package Core library "prelude/match";`); core/prelude.carbon gains `export
import library "prelude/match";`; core/prelude/types/optional.carbon gains
`import library "prelude/match";`, §1.6's `impl as Match` block inside the class
after `Get`, and §1.9's `Branch` body.
toolchain/check/match_continuation.{h,cpp} (new; BUILD's `check` library lists
them):

<!-- google-doc-style-ignore -->

```cpp
// The alternatives of a scrutinee type that implements `Core.Match`
// (docs/design/sum_types.md:119-130): one per method of the impl's
// `Continuation` interface, in declaration order.
struct MatchAlternative {
  SemIR::NameId name_id;
  // The method's explicit parameter types after `ref self`, in the
  // scrutinee's specific.
  llvm::SmallVector<SemIR::TypeId> param_type_ids;
};

struct MatchScrutineeInfo {
  SemIR::InstId witness_id;        // `S as Core.Match`
  SemIR::InterfaceId continuation_interface_id;
  SemIR::SpecificId continuation_specific_id;
  llvm::SmallVector<MatchAlternative> alternatives;
};

// Returns the alternatives when `type_id` implements `Core.Match` and its
// `Continuation` is an interface whose methods are alternatives; nullopt,
// without diagnosing, when it does not implement `Core.Match`; diagnoses and
// returns an error marker for a malformed `Continuation` (§1.12).
auto GetMatchScrutineeInfo(Context& context, SemIR::LocId loc_id,
                           SemIR::TypeId type_id)
    -> std::optional<MatchScrutineeInfo>;

// Emits, at the scrutinee: the anonymous continuation class (fields
// `.index: i32` and `.slot<k>: MaybeUnformed((P_k...))`), its impls of
// `Match.BaseContinuation` (`.ReturnType = i32`), of the `Continuation`
// interface and of `Destroy`, its `VarStorage` with `.index = -1`, and the
// one `Op` call. Returns the storage and the call's `i32` result.
struct MatchContinuationResult {
  SemIR::InstId storage_id;
  SemIR::InstId index_id;
};
auto BuildMatchContinuation(Context& context, SemIR::LocId loc_id,
                            SemIR::InstId scrutinee_id,
                            const MatchScrutineeInfo& info)
    -> MatchContinuationResult;

// The payload tuple of alternative `k`: `.slot<k>` of the storage viewed
// `unsafe as (P_k...)`. Only valid where `index == k` has been tested.
auto EmitMatchSlotAccess(Context& context, SemIR::LocId loc_id,
                         const MatchContinuationResult& cont, int32_t k,
                         const MatchScrutineeInfo& info) -> SemIR::InstId;
```

<!-- google-doc-style-resume -->

Invariants: `BuildMatchContinuation` runs once per evaluation of the scrutinee
(once per `while let` and `for` iteration, in the loop header block), so `Op` is
called exactly once per evaluation; every slot read is dominated by the `index
== k` test of the arm reading it (the W-008 dominance rule); the storage's
`Destroy` runs once, at the owning scope's end, and destroys only the slot `Op`
filled.

toolchain/check/context.h, `MatchCaseContext`: `scrutinee_type_id` is joined by
an optional `MatchScrutineeInfo` (set at the scrutinee gate) and the
`MatchContinuationResult` (set after the call); `Alternative` gains
`match_param_count` beside `payload_field_index`.
toolchain/check/refutable_binding.cpp:

-   `IsSupportedScrutineeType` (:83-135) is unchanged; `CheckRefutableScrutinee`
    (:137-208), after `RequireCompleteType` and, with PR 62 composed, after
    `GetCppSumType`'s conversion, tries `GetMatchScrutineeInfo` when
    `IsSupportedScrutineeType` fails; on success it calls
    `BuildMatchContinuation`, records both on the case context and returns the
    scrutinee; on `nullopt` the existing TODO stands.
-   `ResolvePendingAlternative` (:210-293): a scrutinee with a
    `MatchScrutineeInfo` resolves the name against `info.alternatives`
    (`LookupMatchAlternative`), the parens rule against the class's member of
    that name (§1.6), and the arity against `param_type_ids.size()`; a choice
    resolves as now; anything else keeps the W4 TODO.
-   `EmitRefutableBindingTest` (:339-487) and `EmitRefutableBindingBind`
    (:489-603): `is_alternative_payload_arm` on a `Match` scrutinee calls
    `MatchCaseAlternativePatternMatch` and `EmitMatchSlotAccess` where the
    choice lane calls `EmitChoicePayloadFieldAccess`; the `is_irrefutable`
    predicate uses `info.alternatives.size() == 1`.

toolchain/check/pattern_match.cpp: `MatchCaseAlternativePatternMatch` (:597-694)
takes its discriminant value and payload access from the case context's
`MatchContinuationResult` when present (a 30-line branch at its head; the
dominated payload block below is shared). toolchain/check/handle_match.cpp:
`AlternativePattern` (:283-470) resolves against `Match` alternatives through
`ResolvePendingAlternative` as above; exhaustiveness (`MatchStatement`, the SF-7
analysis) reads the alternative count from the context.
toolchain/check/handle_loop_statement.cpp: §1.8 (the `CallOptionalAccessor`
function and its two calls deleted; the while-let driver's test and bind with a
synthesized `.Some` root; the TODO at :269-272 deleted).
toolchain/diagnostics/kind.def: the five kinds of §1.12. Lowering: no file.

### §2.5 Land-time files

PR 62's commit (W-322, D-DR-15): refutable_binding.cpp (the
`GetCoreOptionalView` branch), cpp/sum_type.cpp and cpp/sum_type.h (the
`CoreOptionalView` machinery), kind.def (`CoreOptionalNotMatchable`),
match/core_optional_view.carbon deleted, PR 62's sum_types.md section amended
(C.6), its plan's §1.7 and the decision log's SV-1 entry gaining a dated note.
PR 56's commits: W-323's (loops.md:116-118 and fork/optional/plan.md:192-214,
C.7) and, at DR-1d, optional.md's (C.8).

## §3 Commits and PRs

Author `jmann345 <jerrymannstan@gmail.com>`, committer Claude, each message
ending with the session's two trailers after a blank line; explicit paths only
(R20); dates the commit's UTC date. Fill commits come from `autoupdate.sh` to a
fixpoint (R26: a second pass, as §0.6.1 needed).

1.  **P0** "DR-1 plan (rev 1): direction realignment: Match for classes and
    Core.Optional, the ref cursor, slice element access through
    IndirectIndexWith" (this file); later revisions each their own commit;
    implementation starts at the signed-off revision.
2.  **R0** "DR-1 records: plan decisions" (decision-log entry DR-1 as Appendix
    C.1 at its plan state, the V-3a register (iv), W-324..W-329 filed,
    ORCHESTRATION's Next actions; C.2, C.4, C.5). With it, W-323's commit on PR
    56's branch (C.7), records only: it does not wait for any code (D-DR-3).
3.  **A1** "DR-1a: `Core.Iterate.Next` takes `ref cursor`" (§2.1's source files,
    the four test sources, the program, loops.md, C.9's first amendment). A1F
    "DR-1a fill": the nine goldens of §0.6 (predicted exactly as measured on v2:
    the table's numstat).
4.  **A-R** "DR-1a records": W-321 discharged, gap row :66's first half (C.2,
    C.3), the register's (iii) resolved. DR-1a is reviewed (two implementation
    reviews, R29(c)) and opened held.
5.  **B1** "DR-1b: subscripting prefers `IndirectIndexWith`; `Core.Slice` and
    `Core.Buf` write through `Ref`" (§2.2, A.1 and A.2's sources,
    `fail_write_through` deleted, slices.md C.10) with B0 before it: `git
    cherry-pick -x 230227264` (its own commit, upstream's message kept, the
    trailers added). B1F "DR-1b fill": the eleven goldens of §0.6.1 plus
    230227264's two and A.1, A.2 (two passes).
6.  **B-P** "DR-1b programs": B.1, B.2 and the `.diff.cpp`; predicted 130 / 0 /
    22 over 152.
7.  **B-R** "DR-1b records": W-109 discharged, gap row :79, the register's (ii)
    resolved, W-327 evidence. Reviews, held.
8.  **M** (DR-1c's branch) merge of CT-1's head into
    claude/carbon-fork-0-1-dr-match, records-only conflicts; then the
    composition gate.
9.  **C1** "DR-1c (1): template associated constants" (§2.3 items 1-3, A.3,
    A.6), C1F; C2 "DR-1c (2): impl members give associated constants their
    values" (item 4, A.4), C2F; C3 "DR-1c (3): `extend require impls` member
    access" (item 5, A.5), C3F. Stop-and-amend after C1's first build: if L1
    needs a change outside §2.3's files, the plan is amended before C2.
10. **C-R** "DR-1c records": W-324's evidence, the register's (iv). Reviews,
    held.
11. **D1** "DR-1d (1): `Core.Match`, the continuation, and alternative patterns
    on a `Match` class" (match.carbon, match_continuation.{h,cpp}, context.h,
    refutable_binding.cpp, pattern_match.cpp, handle_match.cpp, kind.def, A.7 to
    A.10), D1F (predicted set of §1.13, measured and recorded here); D2 "DR-1d
    (2): `Core.Optional` implements `Match`; `Try` matches" (optional.carbon),
    D2F; D3 "DR-1d (3): `for` matches `.Some(<pattern>)`"
    (handle_loop_statement.cpp, A.11), D3F.
12. **D-P** "DR-1d programs": B.3 to B.5; predicted 134 / 0 / 22 over 156 on
    DR-1d's base (DR-1b's 130 / 0 / 22 over 152, plus four).
13. **Implementation reviews A and B** on each PR's head (R29(c)); not commits.
14. **Fix commits**: at most three per PR, each with its fill. The shrink line
    (D-DR-22): a finding that needs a fourth fix commit shrinks the PR instead:
    the form at issue goes OUT with a residue in the remaining W-32x reservation
    (or the next free id after the re-scan), its split renamed `fail_todo_`,
    never a guard that hides an IN form (R17). For DR-1c, a prerequisite (L1, L2
    or L3) that cannot be made to work within the budget stops slice 1: DR-1c
    lands only the prerequisites that work, DR-1d does not start, W-320 is
    narrowed with the measured blocker, and no fork-local respelling of `Match`
    is introduced (R32 (d)).
15. **Land-time commits**, each new, on the other PR's branch (R32 (e)): W-322's
    on PR 62 (§2.5, C.6), after DR-1d's reviews; optional.md's on PR 56 (C.8),
    after DR-1d's reviews.
16. **R** "DR-1 records" and D "DR-1 discharge" (each PR's own, last on its
branch): the ledger, the gap rows, the decision log's dated notes,
ORCHESTRATION, the id re-scan's result.

## §4 Testdata matrix (autoupdate fills; the fill must reproduce these lines)

| Golden | PR | Kind | Predicted |
| --- | --- | --- | --- |
| check/for/actual, basic, pattern; check/interop/cpp/range_for; check/slice/basic; lower/array/iterate; lower/for/bindings, break_continue, for | DR-1a | refill | §0.6's numstat exactly (measured on v2) |
| check/index/fail_invalid_base, fail_non_tuple_access; check/operators/overloaded/index, index_with_prelude, string_indexing; check/slice/basic, buf, fail_basic; lower/interop/cpp/span; lower/slice/basic, buf | DR-1b | refill | `$X/v3_numstat.txt` exactly (measured on v3; overloaded/index.carbon converges on the second pass) |
| check/function/call/form.carbon, lower/function/call/form.carbon | DR-1b | new (230227264) | upstream's sources; this tree's fill |
| check/slice/write_through.carbon, lower/slice/write_through.carbon | DR-1b | new | A.1, A.2: writes through a slice, a `Buf`, a generic `Fill`, a `Slice(const i32)` failure split, a `std::span` mock write |
| check/interface/template_assoc_const.carbon; check/impl/assoc_const_member.carbon; check/interface/extend_require_member.carbon; parse/let/template_assoc_const.carbon | DR-1c | new | A.3 to A.6 |
| check/match/core_optional.carbon, user_sum_type.carbon, fail_match_class.carbon; check/if/if_let_optional.carbon; check/while/while_let_optional.carbon; check/let/let_else_optional.carbon; lower/match/core_optional.carbon | DR-1d | new | A.7 to A.11 |
| the nine `for` goldens; the files dumping `Core.Optional`'s imports or the prelude's library list | DR-1d | refill | predicted, measured at D1F and D3F |
| check/generic/template/for_range.carbon, lower/template/for_range.carbon (PR 61's) | M at DR-1's merge | refill | predicted: the `AddrOf` and the pointer completeness requirement leave |

## §5 Conformance delta (from trunk's 128 / 0 / 22 over 150)

| After | PASS | FAIL | SKIP | Total | Change |
| --- | --- | --- | --- | --- | --- |
| DR-1a | 128 | 0 | 22 | 150 | measured on v2: iterate_interface rewritten, same output |
| DR-1b | 130 | 0 | 22 | 152 | measured base (v3: 128/0/22 over 150) plus B.1 and B.2, predicted PASS |
| DR-1c | 130 | 0 | 22 | 152 | no program |
| DR-1d | 134 | 0 | 22 | 156 | B.3, B.4 (with its `.diff.cpp`), B.5 and the `if let` program of B.3's sibling, predicted PASS |

Bullets: no bullet changes status (48 PASS / 0 FAIL / 8 SKIP of 56): Stdlib:
Slices and Control flow: matching sum-type consumption are already PASS by their
existing programs; the new programs add evidence, not status. No SKIP moves:
optional_missing_ops is OP-1's (comparisons), match_sum_type_payload's interop
SKIP is PR 62's.

## §6 Churn and collisions

| PR | Toolchain and prelude (+/-) | Goldens | Programs | Records and docs |
| --- | --- | --- | --- | --- |
| DR-1a | iterate.carbon 13/13, range.carbon 3/3, handle_loop_statement.cpp 4/9, min_prelude 1/1 (measured) | 9 refills, 569/628 lines | 1 (3/3) | loops.md, ledger, row :66 |
| DR-1b | index.carbon 18/0, slice.carbon 7/2, buf.carbon 7/2, handle_index.cpp 39/17, core_identifier.def 2/0, cpp/operators.cpp 6/0, call.cpp 4/1, convert.cpp 4/0 (measured) | 11 refills (948/709 lines measured), 4 new | 2 and an oracle | slices.md, ledger, row :79 |
| DR-1c | estimated 400 to 900 lines over parse/handle_let.cpp, parse node kinds, check handle_let_and_var.cpp, impl.cpp, name_lookup.cpp, facet_type.cpp, kind.def | 4 new | none | ledger |
| DR-1d | estimated 900 to 1500: match_continuation.{h,cpp} new (500 to 800), refutable_binding.cpp, pattern_match.cpp, handle_match.cpp, handle_loop_statement.cpp, context.h, kind.def, match.carbon, optional.carbon | 7 new, predicted refills | 3 and an oracle | sum_types.md, error_handling.md, loops.md, ledger, rows :68 :78 :66 |

Collisions: §0.8. The rules at merge: §1.16.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1, L1 needs more than TP-1's machinery.** If a template-dependent
    deduced binding in an interface function (`fn Op[C: Continuation]`) cannot
    be checked by TP-1's dependent forms, DR-1c's C1 stops at its stop-and-amend
    point. Falsified by C1's first build compiling A.3's positive split.
-   **R-2, the continuation's copy semantics observably differ from the
    design.** sum_types.md:149's `value: T` is a value parameter; the slot
    copies it once. A `Copy` impl with side effects runs once more than a
    by-reference design would. Falsified by B.3's counting `Copy` (Appendix B.3
    prints the copy count; the EXPECT is the hand-derived count with the slot
    copy).
-   **R-3, UA-3 conflict in L3's machinery.** Upstream's `IdentifiedFacetType`
    series (PRs 7924 to 8004) reworks facet identification; DR-1c's
    facet-conversion hunk will conflict at the next advance. Mitigation: the
    hunk is confined to one function; UA-3 takes upstream's code and re-measures
    A.5. Falsified when UA-3's merge is clean.
-   **R-4, golden churn in DR-1d is larger than §1.13 predicts.** The new
    prelude library and `Optional`'s impl move every full-prelude golden that
    dumps imports. Measured at D1F; the prediction is replaced by the
    measurement there.
-   **R-5, the `Op` call adds per-iteration cost to `for`.** One `Op` call, one
    continuation method call and one slot copy per iteration where
    `HasValue`/`Get` made two calls and one copy. The fastbuild arbiter does not
    optimize, so the cost is not measured; lower/match/core_optional.carbon
    (A.11) pins the unoptimized call shape, and an optimized comparison is
    recorded as not run (§8.1).

### §7.2 Rejected alternatives

-   **The choice conversion** (`Core.Optional` as `choice Optional(T)`,
    sum_types.md:52-55). Rejected by DR-0 option (b): it changes the prelude's
    identity at fb7eff130 and loses the `T*` niche and `HasValue`/`Get`.
    Falsifiable claim: no upstream text after fb7eff130 makes `Optional` a
    choice (D-DR-1's break condition watches it).
-   **The toolchain special case** (accept `Core.Optional` at the gate and lower
    `.Some`/`.None` to `HasValue`/`Get`). Rejected by DR-0 option (c): a second
    spelling of `Match`, R32 (d). Falsifiable claim: §1.5's mechanism handles a
    user class (B.5), which the special case could not.
-   **Keeping D-SV-7's view.** A scrutinee view where upstream designs `Match`
    (R32 (d)'s own example) that refuses symbolic, aggregate, string and nested
    payloads (§0.3: o_generic, o_string, o_nested on PR 62's install). Falsified
    if the `Match` route fails any shape the view matched: B.4 composes both on
    a PR 62 mirror.
-   **A pointer-cursor shim** (keeping `cursor: CursorType*` beside `ref`, or an
    adapter impl). Rejected: two signatures of one upstream interface; the thunk
    failure shows the interface admits one form. Falsified if a user `ref` impl
    compiles against a pointer interface (it does not on trunk, §0.5).
-   **A fork-local `Match` without `let template`** (`let Continuation: type;`
    with the impl naming its interface in a `where` clause). Rejected: a second
    spelling of sum_types.md's interface; v1.carbon also shows the non-template
    constant cannot type `Op[C: Continuation]`. Falsifiable claim: the probe's
    two errors (§0.7).
-   **Copying upstream's handle_index.cpp wholesale.** Rejected: it carries
    947c1eb52's `Core.Array` arm, an advance's worth of prerequisites (UA-3's).
    The re-expression keeps 309d3d63c's lines exactly.

## §8 Verification

1.  `build.sh` and `install.sh` of each PR's head, after `pgrep -fa ninja` shows
    no other build; a header or X-macro change (core_identifier.def, kind.def,
    context.h, typed_insts.h, node_kind.def) means a full build, never a relink.
2.  `autoupdate.sh` to a fixpoint: the fill's second pass changes nothing (R26).
3.  `gate.sh`: every golden passes (1942 on DR-1a's base; 1942 plus the new
    files after).
4.  `conformance.sh <wt> <out>` with `XDG_CACHE_HOME` set under the scratch:
    §5's predictions exactly.
5.  Mutants, each relinked over the PR's build with one translation unit
    changed, each expected to fail named goldens: DR-1a: the loop checker
    passing `AddrOf` again (the nine goldens and every `for` program fail to
    compile); DR-1b: `diagnose=true` on the `IndirectIndexWith` probe
    (operators/overloaded/index and every type without `IndirectIndexWith`
    diagnose twice), the fallback removed (string_indexing, index_with_prelude
    fail), 230227264's call.cpp line reverted (every program importing the
    prelude CHECK-fails, §0.6.1); DR-1d: the `index == k` test made constant
    `true` (match/core_optional's runtime splits print the wrong alternative),
    the slot destroy removed (B.3's `Core.String` counting program's EXPECT
    fails), the parens rule inverted (fail_match_class's `.None` split stops
    failing).
6.  clang-tidy on the changed translation units, as CT-1 ran it.
7.  prek:
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <paths>` to a fixpoint with `XDG_CACHE_HOME` under the
    scratch, and the R31 counts before and after every markdown edit.
8.  `python3 fork/conformance/runner.py --self-test` after the programs are
    added: every program parses, names a bullet in the gap table and has its
    oracle sibling.
9.  The composition mirrors, full builds on scratch mirrors, never on the held
    branches: DR-1a and DR-1b over PR 61 and CT-1 (the M resolution of §0.8; the
    three TP-1 `for` goldens and the index goldens refilled and gated), over PR
    55 (string_indexing), over PR 62 (convert.cpp); DR-1d over PR 62 (W-322's
    commit applied: sv_view and sv_std_match run, `CoreOptionalNotMatchable`
    gone, the std goldens unchanged), over PR 56 and PR 57 (optional.carbon's
    three regions compose; OP-2's `Destroy` runs for the slot), over PR 59 and
    PR 60 (pattern_match.cpp and handle_let_and_var.cpp).
10. The id re-scan for `W-32[4-9]` across every origin ref and worktree at the
    records commit.

### §8.1 What this plan measured and what it did not

Measured (container-local, EXPECTED, not of record): the probe matrix of §0.3 on
seven toolchains; slice 2 relinked and gated (1942 of 1942 after the fill) with
conformance 128/0/22; slices 2 and 3 fully built and gated (1942 of 1942 after a
two-pass fill) with conformance 128/0/22 and the nine slice-3 probes; the root
cause of the thunk failure (the interface signature) and of the slice-3 crash
(230227264); the hand-desugared `Match` continuation on trunk in four shapes;
the language gaps L1..L3 on trunk and the nightly; the dry-run of v3's source
hunks onto all twelve held heads and CT-1's.

Not measured, and why: DR-1c and DR-1d's toolchain code (its prerequisites do
not exist, and a prototype of L1..L3 plus the mechanism is the XL work this plan
schedules, not a planning step); the goldens DR-1d moves (they depend on that
code); any composition mirror (each is a full build of a held PR plus DR-1's
diff, 10 to 25 minutes each on this machine shared with CT-1's mutants; §8 item
9 runs them at implementation); B.1 to B.5 (written in Appendix B, not run:
B.1's and B.2's bodies were run as the probes s_write, s_buf_write,
s_generic_write and s_span_write, whose outputs their EXPECTs reproduce);
clang-tidy; the nightly's behavior on slice 3 (it predates 6d80ceb58).

## Hand-off notes

-   Restore before measuring: this plan's prototypes were made in this worktree
    and reverted after (`git checkout --` of every file in `$X/v3_numstat.txt`,
    `$X/v3_full.diff` kept); DR-1a's implementer re-applies §2.1 from the plan,
    not from the scratch diff.
-   The full build of v3 left /home/user/carbon-build/carbon-dr at the
    prototype's state (`0.0.0-0.dev+f68681114.dirty`); DR-1a's first `build.sh`
    rebuilds incrementally from it.
-   /dev/shm/dr1-planner (v2) is deleted with this plan's commit.
-   DR-1b's cherry-pick B0 comes before B1, so B1's fill does not run into the
    crash of §0.6.1.
-   W-323's commit on PR 56's branch is records only and lands with R0, before
    PR 56's merge.
-   Never write `.None` for `Core.Optional` in a fork page or program after
    DR-1d: §1.6. `StdOptional`'s `.None` stays.

## Appendix A: golden sources

Each file starts with the license header and `// AUTOUPDATE` and the two `//
TIP:` lines file_test writes; the full-prelude goldens carry no `INCLUDE-FILE`,
the min_prelude ones `// INCLUDE-FILE:
toolchain/testing/testdata/min_prelude/full.carbon`. Splits are `// ---
name.carbon`; `//@dump-sem-ir-begin`/`-end` bracket the dumped region; no CHECK
line is written here.

### A.1 toolchain/check/testdata/slice/write_through.carbon (DR-1b, full prelude)

<!-- google-doc-style-ignore -->

```carbon
// --- write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Write(s: Core.Slice(i32), i: i64) {
  s[i] = s[0] + 1;
}
//@dump-sem-ir-end

// --- buf_write.carbon
library "[[@TEST_NAME]]";

fn BufWrite(b: Core.Buf(i32)) {
  b[0] = 7;
}

// --- generic_write.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Fill[T: Core.Copy & Core.Destroy](s: Core.Slice(T), v: T) {
  s[0] = v;
}
//@dump-sem-ir-end

// --- fail_const_element.carbon
library "[[@TEST_NAME]]";

fn W(s: Core.Slice(const i32)) {
  s[0] = 1;
}
```

<!-- google-doc-style-resume -->

### A.2 toolchain/lower/testdata/slice/write_through.carbon (DR-1b, full prelude)

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

### A.3 toolchain/check/testdata/interface/template_assoc_const.carbon (DR-1c, min_prelude)

<!-- google-doc-style-ignore -->

```carbon
// --- template_constant.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
interface Match {
  interface BaseContinuation {
    let ReturnType: type;
  }
  let template Continuation: type;
  fn Op[C: Continuation](self, continuation: C*)
    -> C.(BaseContinuation.ReturnType);
}
//@dump-sem-ir-end

// --- sum_types_optional.carbon
library "[[@TEST_NAME]]";

// docs/design/sum_types.md:137-165, with `extend require impls` for :148's
// `extend` (p5337) and i32 for `T`.
interface Match {
  interface BaseContinuation {
    let ReturnType: type;
  }
  let template Continuation: type;
  fn Op[C: Continuation](self, continuation: C*)
    -> C.(BaseContinuation.ReturnType);
}

class OptionalI32 {
  private var has_value: bool;
  private var value: i32;

  impl as Match {
    interface Continuation {
      extend require impls Match.BaseContinuation;
      fn Some(ref self, value: i32) -> ReturnType;
      fn None(ref self) -> ReturnType;
    }

    fn Op[C: Continuation](self, continuation: C*) -> C.ReturnType {
      if (self.has_value) {
        return continuation->Some(self.value);
      } else {
        return continuation->None();
      }
    }
  }
}

// --- fail_generic_assoc_const.carbon
library "[[@TEST_NAME]]";

interface I {
  let generic N: type;
}
```

<!-- google-doc-style-resume -->

### A.4 toolchain/check/testdata/impl/assoc_const_member.carbon (DR-1c, min_prelude)

<!-- google-doc-style-ignore -->

```carbon
// --- let_member.carbon
library "[[@TEST_NAME]]";

interface I { let R: type; fn F() -> R; }
class C {
  impl as I {
    let R: type = i32;
    fn F() -> i32 { return 1; }
  }
}

// --- interface_member.carbon
library "[[@TEST_NAME]]";

interface M { let Continuation: type; }
class C {
  impl as M {
    interface Continuation {
      fn Some(ref self, v: i32) -> i32;
    }
  }
}

// --- fail_set_twice.carbon
library "[[@TEST_NAME]]";

interface I { let R: type; }
class C {
  impl as I where .R = i32 {
    let R: type = bool;
  }
}
```

<!-- google-doc-style-resume -->

### A.5 toolchain/check/testdata/interface/extend_require_member.carbon (DR-1c, min_prelude)

<!-- google-doc-style-ignore -->

```carbon
// --- unqualified.carbon
library "[[@TEST_NAME]]";

interface Base { let R: type; }
interface Cont {
  extend require impls Base;
  fn Some(ref self, v: i32) -> R;
}

// --- qualified.carbon
library "[[@TEST_NAME]]";

interface Base { let R: type; }
interface Cont {
  extend require impls Base;
  fn Some(ref self, v: i32) -> Self.(Base.R);
}

// --- facet_member.carbon
library "[[@TEST_NAME]]";

interface Base { let R: type; }
interface Cont {
  extend require impls Base;
}
fn F[C: Cont](unused c: C*) -> C.R;
```

<!-- google-doc-style-resume -->

### A.6 toolchain/parse/testdata/let/template_assoc_const.carbon (DR-1c)

<!-- google-doc-style-ignore -->

```carbon
// --- template.carbon
interface I {
  let template C: type;
}

// --- fail_generic.carbon
interface I {
  let generic C: type;
}
```

<!-- google-doc-style-resume -->

### A.7 toolchain/check/testdata/match/core_optional.carbon (DR-1d, full prelude)

<!-- google-doc-style-ignore -->

```carbon
// --- match.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(o: Core.Optional(i32)) -> i32 {
  var result: i32 = -1;
  match (o) {
    case .Some(x: i32) => { result = x; }
    case .None() => { result = 0; }
  }
  return result;
}
//@dump-sem-ir-end

// --- pointer.carbon
library "[[@TEST_NAME]]";

fn G(p: Core.Optional(i32*)) -> i32 {
  if (let .Some(q: i32*) = p) {
    return *q;
  }
  return 0;
}

// --- string.carbon
library "[[@TEST_NAME]]";

fn S(o: Core.Optional(Core.String)) -> i64 {
  let .Some(s: Core.String) = o else { return -1; }
  return s.Size();
}

// --- nested.carbon
library "[[@TEST_NAME]]";

fn N(o: Core.Optional(Core.Optional(i32))) -> i32 {
  var result: i32 = -1;
  match (o) {
    case .Some(.Some(x: i32)) => { result = x; }
    case .Some(.None()) => { result = -2; }
    case .None() => {}
  }
  return result;
}

// --- generic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn H[T: Core.Copy & Core.Destroy](o: Core.Optional(T), d: T) -> T {
  if (let .Some(x: T) = o) {
    return x;
  }
  return d;
}
//@dump-sem-ir-end

// --- exhaustive.carbon
library "[[@TEST_NAME]]";

fn E(o: Core.Optional(i32)) -> bool {
  var b: bool = false;
  match (o) {
    case .Some(_: i32) => { b = true; }
    case .None() => {}
  }
  return b;
}
```

<!-- google-doc-style-resume -->

### A.8 toolchain/check/testdata/match/user_sum_type.carbon (DR-1d, full prelude)

<!-- google-doc-style-ignore -->

```carbon
// --- three.carbon
library "[[@TEST_NAME]]";

// A user class with three alternatives (docs/design/sum_types.md:135-165's
// shape): `Ok(i32)`, `Err(bool)` and `Cancelled()`.
class Status {
  fn Ok(v: i32) -> Self { return {.tag = 0, .v = v, .e = false}; }
  fn Err(e: bool) -> Self { return {.tag = 1, .v = 0, .e = e}; }
  fn Cancelled() -> Self { return {.tag = 2, .v = 0, .e = false}; }

  impl as Core.Match {
    interface Continuation {
      extend require impls Core.Match.BaseContinuation;
      fn Ok(ref self, v: i32) -> ReturnType;
      fn Err(ref self, e: bool) -> ReturnType;
      fn Cancelled(ref self) -> ReturnType;
    }
    fn Op[C: Continuation](self, continuation: C*) -> C.ReturnType {
      if (self.tag == 0) { return continuation->Ok(self.v); }
      if (self.tag == 1) { return continuation->Err(self.e); }
      return continuation->Cancelled();
    }
  }

  private var tag: i32;
  private var v: i32;
  private var e: bool;
}

//@dump-sem-ir-begin
fn F(s: Status) -> i32 {
  var r: i32 = 0;
  match (s) {
    case .Ok(v: i32) => { r = v; }
    case .Err(true) => { r = -1; }
    case .Err(false) => { r = -2; }
    case .Cancelled() => { r = -3; }
  }
  return r;
}
//@dump-sem-ir-end

// --- fail_missing.carbon
library "[[@TEST_NAME]]";
// (Status as above, then a match with no `.Cancelled()` arm and no default:
// MatchNonexhaustive names the missing alternative.)
```

<!-- google-doc-style-resume -->

### A.9 toolchain/check/testdata/match/fail_match_class.carbon (DR-1d, full prelude)

<!-- google-doc-style-ignore -->

```carbon
// --- fail_bare_none.carbon
library "[[@TEST_NAME]]";
fn F(o: Core.Optional(i32)) {
  match (o) {
    case .None => {}
    default => {}
  }
}

// --- fail_ref_binding.carbon
library "[[@TEST_NAME]]";
fn F(o: Core.Optional(i32)) {
  if (let .Some(ref x: i32) = o) {}
}

// --- fail_unknown_alternative.carbon
library "[[@TEST_NAME]]";
fn F(o: Core.Optional(i32)) {
  match (o) {
    case .Other() => {}
    default => {}
  }
}

// --- fail_arity.carbon
library "[[@TEST_NAME]]";
fn F(o: Core.Optional(i32)) {
  match (o) {
    case .Some(a: i32, b: i32) => {}
    default => {}
  }
}

// --- fail_symbolic_match.carbon
library "[[@TEST_NAME]]";
fn F[U: Core.Match](u: U) {
  match (u) {
    default => {}
  }
}

// --- fail_not_copy.carbon
library "[[@TEST_NAME]]";
class NoCopy {}
// (A class with `impl as Core.Match` whose alternative takes a `NoCopy`.)
```

<!-- google-doc-style-resume -->

### A.10 the pattern-condition goldens (DR-1d, full prelude)

toolchain/check/testdata/if/if_let_optional.carbon,
while/while_let_optional.carbon and let/let_else_optional.carbon each hold the
m_iflet, m_whilelet and m_letelse probes of §0.3 (Appendix B.0) as one split
with a `//@dump-sem-ir` region around the form, and a `fail_` split with `.None`
(the parens rule).

### A.11 toolchain/lower/testdata/match/core_optional.carbon (DR-1d, full prelude)

<!-- google-doc-style-ignore -->

```carbon
fn F(o: Core.Optional(i32)) -> i32 {
  var result: i32 = -1;
  match (o) {
    case .Some(x: i32) => { result = x; }
    case .None() => { result = 0; }
  }
  return result;
}

fn Loop(a: array(i32, 3)) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) { s += x; }
  return s;
}
```

<!-- google-doc-style-resume -->

## Appendix B: programs and oracles

### B.0 the audit probes

`$X/a1` holds the probe bodies of §0.3 verbatim; m_match is:

<!-- google-doc-style-ignore -->

```carbon
import Core library "io";
fn F(o: Core.Optional(i32)) -> i32 {
  match (o) {
    case .Some(x: i32) => { return x; }
    case .None() => { return -1; }
  }
}
fn Run() -> i32 {
  Core.Print(F(Core.Optional(i32).Some(5)));
  Core.Print(F(Core.Optional(i32).None()));
  return 0;
}
```

<!-- google-doc-style-resume -->

(Its arms both return, so after DR-1d it still needs W-329's reachability or a
trailing statement; A.7 and B.3 use a result variable.)

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
// Writes through `Core.Slice` and `Core.Buf` subscripts (D-DR-7: `Ref`
// returns `ref T`, upstream 6d80ceb58 and 309d3d63c). Hand-derived: `a` is
// (1, 2, 3); `s[1] = 20` makes it (1, 20, 3); `s[2] = s[0] + s[1]` makes it
// (1, 20, 21); the `Buf` gets 7 at 0 and 8 at 1, and `b[2] = 7 + 8` = 15;
// `Fill` writes 9 into all three elements of `c`, whose sum is 27.

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

<!-- google-doc-style-ignore -->

```carbon
// CONFORMANCE-BULLET: Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view)
// COMPILE-ARGS: --clang-arg=-std=c++20
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   18
//
// A write through `s[0]` is seen by C++ through the `std::span<int>` the
// slice maps to (D-DR-7, SL-2's mapping). Hand-derived: (1, 2, 3) becomes
// (10, 2, 3); `Bump` adds one to each element, (11, 3, 4); `Sum` is 18.

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
  for (long long i = 0; i < n; ++i) t += p[i];
  return t;
}
auto Bump(int* p, long long n) -> void {
  for (long long i = 0; i < n; ++i) p[i] += 1;
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

### B.3 fork/conformance/programs/control_flow/match_core_optional.carbon (DR-1d)

<!-- google-doc-style-ignore -->

```carbon
// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   0
//   7
//   1
//   2
//   3
//   9
//   -1
//   3
//   4
//   4
//   -2
//   4
//   7
//
// `Core.Optional` matched through `Match` (D-DR-9, D-DR-10): `match`,
// `if let`, `while let`, `let`-`else`, a null pointer, a string, a nested
// `Optional` and a generic. Hand-derived line by line in the comments of
// `Run`.

import Core library "io";

fn M(o: Core.Optional(i32)) -> i32 {
  var r: i32 = -1;
  match (o) {
    case .Some(x: i32) => { r = x; }
    case .None() => { r = 0; }
  }
  return r;
}

fn Next(n: i32) -> Core.Optional(i32) {
  if (n < 3) { return Core.Optional(i32).Some(n + 1); }
  return Core.Optional(i32).None();
}

fn LetElse(o: Core.Optional(i32)) -> i32 {
  let .Some(x: i32) = o else { return -1; }
  return x;
}

fn Deref(p: Core.Optional(i32*)) -> i32 {
  if (let .Some(q: i32*) = p) { return *q; }
  return -2;
}

fn Len(o: Core.Optional(Core.String)) -> i64 {
  let .Some(s: Core.String) = o else { return -1; }
  return s.Size();
}

fn Nested(o: Core.Optional(Core.Optional(i32))) -> i32 {
  var r: i32 = -1;
  match (o) {
    case .Some(.Some(x: i32)) => { r = x; }
    case .Some(.None()) => { r = -2; }
    case .None() => {}
  }
  return r;
}

fn Or[T: Core.Copy & Core.Destroy](o: Core.Optional(T), d: T) -> T {
  if (let .Some(x: T) = o) { return x; }
  return d;
}

fn Run() -> i32 {
  Core.Print(M(Core.Optional(i32).Some(5)));            // 5
  Core.Print(M(Core.Optional(i32).None()));             // 0
  if (let .Some(x: i32) = Core.Optional(i32).Some(7)) { // 7
    Core.Print(x);
  }
  var n: i32 = 0;
  while (let .Some(m: i32) = Next(n)) {                 // 1 2 3
    Core.Print(m);
    n = m;
  }
  Core.Print(LetElse(Core.Optional(i32).Some(9)));      // 9
  Core.Print(LetElse(Core.Optional(i32).None()));       // -1
  var v: i32 = 3;
  Core.Print(Deref(Core.Optional(i32*).Some(&v)));      // 3
  Core.Print(Len(Core.Optional(Core.String).Some("abcd")) as i32);  // 4
  Core.Print(Nested(Core.Optional(Core.Optional(i32)).Some(
      Core.Optional(i32).Some(4))));                    // 4
  Core.Print(Nested(Core.Optional(Core.Optional(i32)).Some(
      Core.Optional(i32).None())));                     // -2
  Core.Print(Or(Core.Optional(i32).Some(4), 0 as i32)); // 4
  Core.Print(Or(Core.Optional(i32).None(), 7 as i32));  // 7
  return 0;
}
```

<!-- google-doc-style-resume -->

### B.4 fork/conformance/programs/control_flow/match_core_optional_diff.carbon and .diff.cpp (DR-1d)

The Carbon side is B.3's `M`, `LetElse` and `Or` over the inputs 5, none, 9,
none, 4 and none-with-7 (EXPECT `5 0 9 -1 4 7`, one per line); the C++17 twin is
the same logic over `std::optional<int>`:

<!-- google-doc-style-ignore -->

```cpp
#include <cstdio>
#include <optional>

auto M(std::optional<int> o) -> int { return o ? *o : 0; }
auto LetElse(std::optional<int> o) -> int { return o ? *o : -1; }
auto Or(std::optional<int> o, int d) -> int { return o.value_or(d); }

auto main() -> int {
  std::printf("%d\n", M(5));
  std::printf("%d\n", M(std::nullopt));
  std::printf("%d\n", LetElse(9));
  std::printf("%d\n", LetElse(std::nullopt));
  std::printf("%d\n", Or(4, 0));
  std::printf("%d\n", Or(std::nullopt, 7));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B.5 fork/conformance/programs/control_flow/match_user_sum_type.carbon (DR-1d)

A.8's `Status` and `F`, run over `Status.Ok(4)`, `Status.Err(true)`,
`Status.Err(false)` and `Status.Cancelled()`: EXPECT `4 -1 -2 -3`, one per line
(hand-derived from `F`'s four arms).

## Appendix C: records texts

Placeholders are `<...>`; every date is the commit's UTC date. Each block below
is pasted as written, then R31's counts are taken on the file it lands in.

### C.1 Decision-log entry (R0, then completed at each discharge)

Placed after DR-0 in "Decided":

<!-- google-doc-style-ignore -->

```markdown
### DR-1: direction realignment: Match for classes, the ref cursor, IndirectIndexWith (<date>)

The workstream D-DR-1 scheduled (fork/direction/plan.md, rev <n>, signed off
<date>). Upstream's direction was read at upstream/trunk fb7eff130. Decisions
D-DR-5..D-DR-22, auto-adopted under R29(a), each with its break condition in the
plan: four PRs in the order slice 2, slice 3, slice 1a, slice 1b (D-DR-5); the
`ref` cursor as df3cf9294 (D-DR-6); `IndirectIndexWith` as 6d80ceb58 and
309d3d63c with 230227264 cherry-picked, `Core.Slice` and `Core.Buf` writable
through `Ref`, D-SL-3 retired by its own break condition (D-DR-7); template
associated constants, impl members that give associated constants their values,
and `extend require impls` member access, the language sum_types.md's `Match`
needs (D-DR-8); a per-form local continuation class that stores the
alternative's parameters and returns its index (sum_types.md:224-227), one
`Op` call, the choice lane keyed by the index, no new SemIR kind (D-DR-9);
`Core.Optional`'s `impl as Match`, with `.None()` because the prelude's `None`
is a function (sum_types.md:214-222) (D-DR-10); the four refutable forms, `ref`
subpatterns OUT (D-DR-11); `for` through the while-let engine with the root
`.Some(<pattern>)` (D-DR-12); the `Try` body as error_handling.md's sketch
(D-DR-13); generic and template-argument `Optional(T)` matched in the
definition (D-DR-14); D-SV-7's view removed by a new commit on PR 62, F-020's
mapping kept (D-DR-15); diagnostics (D-DR-16); goldens, programs, docs and
records (D-DR-17..D-DR-19); merge after CT-1 by merge commits, land-time
commits on PR 56 and PR 62 (D-DR-20); residues W-324..W-329, no F-022
(D-DR-21); the shrink line and the stop rule for slice 1 (D-DR-22).

V-3a register: (ii) D-SL-3 resolved by DR-1b (<sha>); (iii) the pointer cursor
resolved by DR-1a (<sha>); (i) D-SV-7 resolved by PR 62's commit <sha>; (iv)
added: template associated constants (W-324), accepted by the fork for
sum_types.md:113 and refused by upstream's parser
(toolchain/parse/handle_let.cpp:37-42 at fb7eff130).

Measured at planning (container-local, EXPECTED, not of record): slice 2 gate
1942 of 1942 and conformance 128/0/22 over 150; slices 2 and 3 gate 1942 of
1942 and conformance 128/0/22 over 150; at discharge: <the PR's own runs>.
```

<!-- google-doc-style-resume -->

### C.2 Ledger (fork/inventory/work-items.json)

New items, R0 (each with `"blocked_by": []` unless stated; `"bullet"` as named):

<!-- google-doc-style-ignore -->

```json
{"id": "W-324", "kind": "todo-stub", "size": "S", "bullet": "none",
 "title": "V-3a register entry (iv): template associated constants (`let template` on an associated constant) are accepted by the fork for sum_types.md:113's `Match` and refused by upstream's parser (toolchain/parse/handle_let.cpp:37-42 at fb7eff130); follow upstream's resolution",
 "subsystem": "toolchain/parse (handle_let.cpp) + toolchain/check (handle_let_and_var.cpp, impl.cpp)",
 "evidence": ["upstream docs/design/sum_types.md:113 at fb7eff130", "upstream toolchain/parse/handle_let.cpp:37-42 at fb7eff130", "fork/direction/plan.md §0.7, §1.4"],
 "notes": "Filed <date> by DR-1 (D-DR-8, D-DR-21). Break condition: upstream decides template associated constants (a proposal, or a change to sum_types.md:113 or to the parser); the fork follows."}
{"id": "W-325", "kind": "missing-feature", "size": "M", "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
 "title": "DR-1 residue: `Match` scrutinees outside 0.1 -- an opaque template-dependent scrutinee (a deferred refutable form), a symbolic facet scrutinee `U: Core.Match`, and the unchecked \"exactly one method exactly once\" contract of `Match.Op` (sum_types.md:127-129)",
 "subsystem": "toolchain/check (refutable_binding.cpp, match_continuation.cpp)",
 "evidence": ["fork/direction/plan.md §1.5 step 3, §1.10", "check/testdata/match/fail_match_class.carbon fail_symbolic_match"], "notes": "Filed <date> by DR-1."}
{"id": "W-326", "kind": "missing-feature", "size": "S", "bullet": "Control flow: matching — good switch equivalents",
 "title": "DR-1 residue: \"both possible implementations must be well-formed\" (sum_types.md:197-198) -- the `==` half is not enforced for expression-form alternative patterns, on `Match` classes or choices (pattern_matching.md:526-527)",
 "subsystem": "toolchain/check (refutable_binding.cpp)", "evidence": ["fork/direction/plan.md §1.6"], "notes": "Filed <date> by DR-1."}
{"id": "W-327", "kind": "missing-feature", "size": "M", "bullet": "none",
 "title": "A generic assignment whose specific's target is `const` writes: `*p = v` through `const T*` (trunk and the upstream nightly print 7) and `s[i] = v` through `Core.Slice(const T)` (DR-1b prints 2); the per-specific `const` check",
 "subsystem": "toolchain/check (handle_operator.cpp assignment, specific checking)",
 "evidence": ["fork/direction/plan.md §0.6.1 (s_ptr_const_write, s_generic_const2)"], "notes": "Filed <date> by DR-1 (D-DR-7). Not a reason for a read-only Slice (R32 (d))."}
{"id": "W-328", "kind": "missing-feature", "size": "S", "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
 "title": "DR-1 residue: `Match` alternatives with a non-`Copy` parameter (the continuation's slot is a copy) and `ref` subpatterns on an alternative's parameter",
 "subsystem": "toolchain/check (match_continuation.cpp)", "evidence": ["fork/direction/plan.md §1.5 step 2, §1.7"], "notes": "Filed <date> by DR-1."}
{"id": "W-329", "kind": "missing-feature", "size": "S", "bullet": "Control flow: matching — good switch equivalents",
 "title": "Reachability after an exhaustive `match` whose arms all diverge: \"missing `return` at end of function with declared return type\" (a two-alternative choice on trunk; the `Try` body's trailing return)",
 "subsystem": "toolchain/check (handle_match.cpp, control_flow.cpp)", "evidence": ["fork/direction/plan.md §0.3 (c_exh_return)"], "notes": "Filed <date> by DR-1; found by its audit, not caused by it."}
```

<!-- google-doc-style-resume -->

Discharge notes, each appended to the item's `notes` at the PR's D commit: W-321
"DISCHARGED <date> by DR-1a (<sha>): `Core.Iterate.Next` takes `ref cursor` at
the 11 sites, the loop checker passes the cursor variable (upstream df3cf9294
re-expressed); the thunk failure was the interface/impl signature mismatch and
needed no thunk change; gate <n> of <n>, conformance <p>/<f>/<s> over <t>."
W-109 "DISCHARGED <date> by DR-1b (<sha>): subscripting prefers
`IndirectIndexWith(I).Ref` (309d3d63c), the prelude interface and its blanket
`IndexWith` impl (6d80ceb58), 230227264 cherry-picked; `Core.Slice` and
`Core.Buf` write through `Ref`; D-SL-3's pin deleted; the generic const write
filed W-327." W-320 "DISCHARGED <date> by DR-1d (<sha>) on DR-1c's prerequisites
(<sha>): `Core.Match` as sum_types.md:108-116, `Core.Optional`'s `impl as
Match`, `.Some(<pattern>)` and `.None()` in `match`, `if let`, `while let`,
`let`-`else` and the `for` desugaring; the `Try` body matches; closes PR 56's
W-177 at PR 56's land-time commit (C.8)." W-322 "DISCHARGED <date> by PR 62's
commit <sha> (C.6)." W-323 "DISCHARGED <date> by PR 56's commit <sha> (C.7)."

### C.3 Gap rows (fork/gap-analysis.md)

Each row keeps its status; only the DR-0 sentence quoted is replaced.

-   **Control flow: loops (:66), DONE.** Current sentence: "Direction drift
    (R32, DR-0, 2026-10-21): upstream's `Core.Iterate.Next` takes `ref cursor`
    (df3cf9294, proposal p007381) where the fork's prelude, tests and one
    program take a pointer at 11 sites, and upstream's loops.md desugars `for`
    through `case .Some(<pattern>)`; W-321 (DR-1 slice 2) owns the signature and
    W-320 the desugaring." At DR-1a: "`Core.Iterate.Next` takes `ref cursor` as
    upstream does (DR-1a, <date>, W-321 discharged); the `for` desugaring
    through `case .Some(<pattern>)` is W-320's (DR-1d)." At DR-1d:
    "`Core.Iterate.Next` takes `ref cursor` and `for` is desugared through
    `match` with `case .Some(<pattern>)` as upstream's loops.md specifies (DR-1a
    and DR-1d, W-321 and W-320 discharged)."
-   **Control flow: matching sum-type consumption (:68), PARTIAL.** Current
    sentence: "Direction drift (R32, DR-0, 2026-10-21): `.Some`/`.None` patterns
    over `Core.Optional` are upstream's designed route (sum_types.md's `Match`
    for classes; loops.md since df3cf9294), and the held PR 62's D-SV-7
    scrutinee view is a second spelling, recorded as a V-3a divergence; W-320
    (DR-1 slice 1) owns the route and W-322 the view's retirement." At DR-1d:
    "User-defined sum types: a class implementing `Core.Match` (sum_types.md) is
    matched by `.Alternative(<pattern>)` in every refutable form (DR-1d, W-320);
    `Core.Optional` implements it (`.Some(<pattern>)`, `.None()`); 0.1 limits
    W-325, W-326, W-328."
-   **Stdlib: Optional (:78), PARTIAL.** Current sentence: "Direction drift
    (R32, DR-0, 2026-10-21): the class KEPT by D-EH-1 and by the held PR 56's
    D-OP-7 is not matchable, while upstream's loops.md matches it by `case
    .Some(<pattern>)` (df3cf9294) and sum_types.md designs a class with `impl as
    Match`; W-320 (DR-1 slice 1) owns it, keeping the class, the niche and the
    `Try` signature." At DR-1d: "`Core.Optional` is matchable through
    `Core.Match` (DR-1d, W-320): the class, the `T*` niche, `HasValue`/`Get` and
    the `Try` signature kept; `Try`'s body matches."
-   **Stdlib: Slices (:79), PARTIAL.** Current sentences: "Direction drift (R32,
    DR-0, 2026-10-21): upstream added `IndirectIndexWith` with a `ref`-returning
    `Ref` (6d80ceb58, PR 7974) and prefers it for subscripting (309d3d63c, PR
    7975), which D-SL-3's break condition names; W-109 owns it as D-DR-1
    slice 3." and, in its 0.1-limits list, "slices are read-only (`s[i] = v`
    diagnoses; no `IndirectIndexWith`/`ref` returns, W-109);". At DR-1b: the
    first replaced by "`s[i]` and `b[i]` are durable references through
    `IndirectIndexWith(i64).Ref` (DR-1b, W-109 discharged; upstream 6d80ceb58
    and 309d3d63c), so `s[i] = v` writes through;" and the limits entry deleted.

### C.4 The V-3a register (decision log, DR-0's block)

At R0, appended to DR-0's register paragraph as a dated line: "(iv) template
associated constants for sum_types.md:113's `Match`, which upstream's parser
refuses (toolchain/parse/handle_let.cpp:37-42 at fb7eff130); work item W-324,
owner DR-1 (DR-1c) (added <date>, DR-1 plan)." At each discharge: "(<n>)
resolved <date> by <PR, sha>."

### C.5 ORCHESTRATION (Next actions)

"DR-1 (fork/direction/plan.md, rev <n>): four PRs after CT-1: DR-1a the `ref`
cursor (W-321), DR-1b `IndirectIndexWith` (W-109), DR-1c the language
prerequisites of `Match` (W-324), DR-1d `Match` for classes and `Core.Optional`
(W-320); W-323's records commit on PR 56's branch now; W-322's commit on PR 62's
branch after DR-1d."

### C.6 PR 62's land-time commit (W-322)

Message: "SV-1: retire the D-SV-7 `Core.Optional` view; `Core.Optional` is
matched through `Match` (R32 (e), DR-1 D-DR-15, W-322)". sum_types.md amendment,
after PR 62's section on `std::optional`:

<!-- google-doc-style-ignore -->

```markdown
> **Fork amendment (<date>, DR-1 D-DR-15).** The view described above, which
> matched a `Core.Optional(T)` scrutinee as `Core.CppCompat.StdOptional(T)`,
> is retired: it was a second spelling of the `Match` route this page
> designs for classes (fork/rulebook.md R32 (d)). A `Core.Optional(T)`
> scrutinee is matched through its `impl as Match` (`.Some(<pattern>)`,
> `.None()`); a `std::optional` scrutinee is still matched as
> `StdOptional(T)` (`.Some(<pattern>)`, `.None`).
```

<!-- google-doc-style-resume -->

### C.7 PR 56's records commit (W-323, D-DR-3), verbatim

Message: "OP-1 records: correct the loops.md amendment and the V-3 paragraph
(R32 (a), (e); DR-0 D-DR-3, W-323)". docs/design/control_flow/loops.md:116-118
on PR 56's branch, the block

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
> fb7eff130). The fork's toolchain calls `Core.Optional`'s `HasValue()` and
> `Get()` (designed in [Optional](../optional.md)) until DR-1 lands the
> `Match` route (W-320); those calls are an implementation stage, not the
> design.
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
this check was made. The fork's `for` keeps calling them until W-320 (DR-1)
lands `Match` for classes; under R32 the comparison is made against upstream's
tip by sha, quoting the page.
```

<!-- google-doc-style-resume -->

### C.8 optional.md on PR 56's branch (at DR-1d)

After D-OP-7's paragraph (PR 56's docs/design/optional.md:179-200) and in its
"Not matchable" limit (:425-441):

<!-- google-doc-style-ignore -->

```markdown
> **Fork amendment (<date>, DR-1 D-DR-10).** `Core.Optional` is matchable: it
> implements `Core.Match` as docs/design/sum_types.md designs it for classes,
> with the alternatives `Some(value: T)` and `None()` (`None` is a function,
> so its pattern takes parentheses, sum_types.md:214-222). W-177 is closed by
> W-320.
```

<!-- google-doc-style-resume -->

### C.9 loops.md (this branch)

At DR-1a, after the restored desugaring block: "> **Fork amendment (<date>,
DR-1a).** The fork's `Core.Iterate.Next` takes `ref cursor` as above (W-321).
Its `for` still calls `Core.Optional`'s `HasValue()` and `Get()` in place of the
`match` until W-320 lands." At DR-1d, that amendment's second sentence is
replaced by "Its `for` is desugared as above (DR-1d, W-320)."

### C.10 slices.md (DR-1b)

The 0.1-limits bullet "**Slices are read-only; `s[i] = v` is an error.** ..." is
replaced by: "> **Fork amendment (<date>, DR-1b, D-DR-7).** Slices are writable:
`Core.Slice(T)` implements `IndirectIndexWith(i64)`, whose `Ref` returns `ref T`
(upstream core/prelude/operators/index.carbon:14-16;
docs/design/expressions/indexing.md), so `s[i]` is a durable reference and `s[i]
= v` writes through; `Core.Buf(T)` likewise. A `Slice(const T)` is not writable
where `T` is known; a generic body's write instantiated at a `const` element is
W-327's."
