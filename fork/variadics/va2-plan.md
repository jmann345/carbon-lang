# Variadics plan: definition-checked variadics, slice 2 (VA-2)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 1, 2026-10-22, the planner's draft, for the two plan reviews of
R29(c). Nothing in it is implemented on this branch. Branch
`claude/carbon-fork-0-1-va2`, worktree /home/user/carbon-va2, cut from PR 59's
head b0822a744 (`claude/carbon-fork-0-1-va`, VA-1, held open, never merged),
whose toolchain is the carbonbuild toolchain of 88b1b5bd2. Every line number
below is against b0822a744 unless a commit or a ref is named; on this branch
docs/design/variadics.md, docs/design/tuples.md, core/prelude/copy.carbon and
core/prelude/operators/comparison.carbon are byte-identical to upstream's tip
ebc155734 (M-1), so their line numbers are upstream's too.

Every measurement is container-local, EXPECTED, not of record (R9), taken by the
planner with the planner's build of this worktree under /dev/shm/va2-planner
(deleted when the plan was written, §8.9), the installs named in §0.2, a private
`XDG_CACHE_HOME`, and the scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2/planner`
(`$Q` below). The prototype that §2 quotes is the uncommitted diff
`$Q/va2_prototype.patch` (26 files, 892 insertions, 105 deletions against
b0822a744), also reachable as the dangling commit 74a8f47b4 of an earlier state
(`$Q/proto_commit.txt`, used only for §0.6's `git merge-tree`); the worktree was
restored to b0822a744 before this plan was committed.

**Items.** W-212 (generic and heterogeneous packs), W-213 (tuples with pack
segments) and W-225 (variadic impls), all filed by VA-1 on PR 59's ledger;
W-013 ("W6: implement definition-checked variadics") stays open. Of the items
the brief left to this plan, W-214 (pack expansion patterns in `let`) and the
`if` part of W-218 and W-219 (a statement expansion whose body is an `if`
statement) are taken IN because the prelude impls need them; W-215, W-216,
W-217, W-220, W-221 and the rest of W-218 and W-219 stay filed; W-222 is
narrowed (§1.11).

**Rows** (records refer to them by bullet text, R7): "Generics:
Definition-checked variadics", PARTIAL on PR 59 (fork/gap-analysis.md:59 on
this branch), and "Stdlib: tuple/array library parts", PARTIAL
(fork/gap-analysis.md:80), whose text is "array Iterate impl works; tuple Copy
hand-written only for arities 0-3 with 'TODO: Implement tuple copy as a
variadic generic impl'; no tuple Eq/Ordered — blocked on variadics."

**Outcome this plan commits to.** Packs of different types: a function or an
impl may declare a compile-time pack in its implicit parameter list, `[... each
T: I]`, and a function may take a value pack whose binding's type is that
pack's each-name, `... each x: each T`; a call deduces the pack of argument
types and its arity, each element's `I` requirement is checked by impl lookup
at the call, the body is checked once with `each x` of the symbolic type `each
T`, and each specific is lowered once per element with that element's type and
callees. Tuples with pack segments: `(... each T)` is a tuple type of one pack
segment (in a parameter's type, a return type and an impl's self type), a
tuple type with a segment of known arity is the tuple of its elements, a tuple
type with one segment deduces the segment's pack from a tuple argument, `let
(... each x: each T) = t;` binds a pack from a tuple, and `(... each x)`
initializes a tuple element by element. Variadic impls: core/prelude/copy.carbon
:50-71's four hand-written tuple `Copy` impls are replaced by one `impl forall
[... each T: Copy] (... each T) as Copy`, and tuple `EqWith(Self)` and
`OrderedWith(Self)` are added in core/prelude/operators/comparison.carbon in
the same shape, their bodies statement expansions of `if` statements. The
row "Stdlib: tuple/array library parts" stays PARTIAL with only W-334's
mixed-operand comparisons open (§1.9), and "Generics: Definition-checked
variadics" stays PARTIAL with a narrower Not-yet list.

**Id allocation.** VA-2 reserves W-330..W-339 and mints no fork design id
(D-VA2-17). Re-scanned for this plan on 2026-10-22 over the 89 refs
`refs/heads/claude/carbon-fork-0-1-*`,
`refs/remotes/origin/claude/carbon-fork-0-1-*`, `refs/heads/trunk` and
`refs/remotes/origin/trunk` of /home/user/carbon-lang (after `git fetch origin`)
and the `fork/` trees of every /home/user/carbon-* worktree, with VA-1's three
commands widened to `W-3[3-9][0-9]`: W-330 and W-399 are named only as the text
"no id from W-330 to W-399" in DR-1's fork/direction/plan.md:3903 and :4000-4001
(dr and dr-idx refs and worktrees); no id of W-330..W-339 is filed anywhere.
W-320..W-329 are DR-1's (W-328 reserved for W-320's resumption). The discharge
re-runs the scan (§8.10) and re-allocates from the maximum plus one, skipping
reserved blocks, if any of W-330..W-339 is taken by then.

**Design authority**, read at upstream's tip ebc155734 (`git fetch upstream
trunk`, 2026-10-22; "Switch the field types to a separate type pool", 2026-10-22
02:07:50 UTC), each quoted where used (R32(a)):

-   docs/design/variadics.md (p002240): "Packs and each-names" (:84-102), "Pack
    expansions" (:104-158), "Pack expansion expressions and statements"
    (:160-203), "Pack expansion patterns" (:205-237), "Additional examples"
    (:239-293: SumInts, StrCat, Min, Apply, MiddleVariadic, TupleConcat),
    "Execution Semantics" (:295-345), "Tuples, packs, segments, and shapes"
    (:349-449), "Iterative typechecking of pack expansions" (:451-493), "Type
    versus execution semantics" (:495-528, upstream's a045da8e6), "Typechecking
    patterns" (:530-623), "Typechecking pattern matches" (:625-677), the
    appendix (:679-973), "Alternatives considered" (:975-995).
-   docs/design/tuples.md "Operations performed field-wise" (:106-121) and
    docs/design/expressions/comparison_operators.md "Default implementations
    for basic types" (:479-505).
-   proposals/p002240-variadics.md ("Generalize `expand`" :504, "Omit
    each-names" :555, "Allow multiple pack expansions in a tuple pattern"
    :735); p002687 (:186-193, :210-215 variadic count keys); p002875
    (`Core.Call` variadic, :227, :531); p002274 (:250-257, indexing interfaces
    deferred until variadics).
-   core/prelude/copy.carbon (:50-71) and
    core/prelude/operators/comparison.carbon (:11-60) at ebc155734.
-   toolchain/check/handle_pack_expansion.cpp at ebc155734 (:10-23, three
    `context.TODO` handlers) and toolchain/check/impl_lookup.cpp at ebc155734
    (:199, "TODO: Implement the termination rule").

**V-3 check (R32).** Every mechanism this plan adds is the design's, spelled
as the page spells it at ebc155734, with the page quoted in §1: implicit
parameter list packs (:113-114, "An implicit parameter list element of the
form `...` _pattern_"), binding types that use an each-name (:219-221), the
pack index as a per-iteration constant (:300-303), tuple segments and shapes
(:357-421), the tuple indexing and pack splitting reductions (:765-818),
expansion of a pack segment in a tuple type (:490-491), `let` with a pack
expansion pattern (:110-111 and :870-873), statement expansions of any
statement (:108, :305-306), and the prelude's own tuple impls in upstream's
file layout (copy.carbon keeps `Copy`, comparison.carbon gains the tuple
comparisons beside `bool` and `IntLiteral`). No mechanism is a second spelling
of one upstream designed: `...expand` (:121-133), whose typechecking the
design leaves as "**TODO:** Discuss typechecking `...expand`." (:493), is not
implemented and gets a V-3a register entry (§1.12), so the design's Apply and
TupleConcat stop at the design's text; the bare pack name stays VA-1's
`semantics TODO` (W-230, p002240 "Omit each-names" :555); `each x: auto`
(:732-734) is blocked by `auto` parameters, which upstream's toolchain has not
implemented either (`HandleAutoTypeLiteral`, check/handle_literal.cpp:177 at
ebc155734; §0.2 p11 and p13). The fork's SemIR (a symbolic `PackIndex`,
per-iteration value blocks of a specific, pack-typed tuple elements) is
internal representation where upstream has none
(handle_pack_expansion.cpp:10-23 at ebc155734 are TODOs), so it decides no
language rule; §6.3 says how the next advance takes upstream's shapes where
they differ. One narrowing is recorded as a register entry with a work item,
not as a drift: the tuple comparison impls compare tuples of the same type
only, where comparison_operators.md :504-505 says "Comparisons between tuples
permit implicit conversions for either operand, but not both" (W-334, §1.12).

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Upstream at the tip, and every commit since the cut (R32(c))

M-1. `git rev-list --count c1e83b0b7..ebc155734` is 103. `git diff b0822a744
ebc155734 -- docs/design/variadics.md docs/design/tuples.md
proposals/p002240-variadics.md
proposals/p002687-termination-algorithm-for-impl-selection.md
proposals/p002875-functions-function-types-and-function-calls.md
proposals/p002274-subscripts-and-indexing.md core/prelude/copy.carbon
core/prelude/operators/comparison.carbon` is empty; the only design-page
difference under docs/design/generics is db87a84b6's `observe` wording
(details.md:3337-3349), which no variadics rule touches. The commits since the
cut that touch variadics, packs, tuples, the prelude or the files this plan
changes, by subject (`git log c1e83b0b7..ebc155734` over those paths and over
the subjects):

| Commit | Subject | Bearing on VA-2 |
| --- | --- | --- |
| 2ec4bab59 | Lex and parse support for `...` statements and `expand`. | VA-1's C1, cherry-picked |
| a045da8e6 | Document the discrepancy between checking and execution for variadics | VA-1's C2, cherry-picked; :495-528 |
| 947c1eb52 | Add a `Core.Array` class type, and make `array` refer to it. | the row's array half, UA-3's (§1.9) |
| df3cf9294 | Adopt `ref` in `Core.Iterate.Next` | DR-1a's (PR 63); no tuple impl |
| 6d80ceb58 | Add the `IndirectIndexWith` interface to the prelude | DR-1b's; index.carbon only |
| 503f09037 | Add support for default values for non-generic parameters of generic functions. | W-215's defaults beside a pack: watch item (§1.12 (iii)) |
| 505c4ae30 | Fix crash building impl witness thunks for constrained generic methods | thunk.cpp; a variadic impl's functions take no pack (§1.6) |
| 831a2aee9, 5402b4c56, 46e7eacba, 6a0a1f3e8, f0b030f2c, e39bdb7af, 77fc0a3ef, fb7eff130, ac31fd198 | impl lookup and `IdentifiedFacetType` plumbing | the next advance's conflicts in impl_lookup.cpp; VA-2 changes no line of it (§6.2) |
| 4441c5340 | Simplify `GetConstantValue` | eval.cpp; VA-2's `EvalContext` edit collides textually (§6.3) |
| 72e425fe5 | Clean up some leftover references to the old `:!` syntax. | the brief's `:!` is stale (§0.8) |

No upstream commit since the cut changes a rule of docs/design/variadics.md or
a tuple impl of the prelude; upstream's check of pack expansions is still the
three TODO handlers:

<!-- google-doc-style-ignore -->

```cpp
// toolchain/check/handle_pack_expansion.cpp at ebc155734, :10-23
auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
    -> bool {
  return context.TODO(node_id, "HandlePackExpansionStart");
}

auto HandleParseNode(Context& context, Parse::PackExpansionStatementId node_id)
    -> bool {
  return context.TODO(node_id, "HandlePackExpansionStatement");
}

auto HandleParseNode(Context& context, Parse::PrefixOperatorExpandId node_id)
    -> bool {
  return context.TODO(node_id, "HandlePrefixOperatorExpand");
}
```

<!-- google-doc-style-resume -->

Upstream's prelude has tuple impls only in core/prelude/copy.carbon:50-71 (the
four `Copy` impls under "TODO: Implement tuple copy as a variadic generic
impl.") and core/prelude/default.carbon:31-33 (`impl () as UnformedInit {}`
under "TODO: Generalize these to apply to tuples and structs containing only
..."), found with a loop of `git show ebc155734:<file> | grep` over every
prelude file. comparison.carbon at ebc155734 declares `EqWith`, `Eq`,
`OrderedWith` and `Ordered` (:11-36) and implements them for `bool` (:41-44)
and `IntLiteral` (:49-60) only, with the comment "this must be provided in this
library as `bool` doesn't have any associated libraries of its own" (:38-40):
there is no tuple comparison impl upstream, so VA-2's tuple comparison impls
implement the design's "Default implementations for basic types"
(comparison_operators.md :479-505) where upstream has not yet (§1.6).

M-2. Impl selection's termination: the fork's toolchain/check/impl_lookup.cpp
:183-194 implements only the acyclic rule ("We look for violations of the
acyclic rule by seeing if a previous lookup had all the same type inputs") and
says "TODO: Implement the termination rule, which requires looking at the
complexity of the types on the top of (or throughout?) the stack"; upstream's
:199 at ebc155734 carries the same TODO. p002687's variadic count keys
(:210-215, "A `tuple` key in this namespace is used to track the total number of
components of tuple values") are therefore implemented nowhere, upstream or in
the fork (§1.6, D-VA2-10).

### §0.2 Measurements (probes `$Q/probes/p*.carbon`, logs `$Q/logs`)

Toolchains: PR 59's install /home/user/carbon-build/carbon-va
(`0.0.0-0.dev+88b1b5bd2`, "va"), trunk's /home/user/carbon-build/carbon-trunk
(`0.0.0-0.dev+0bdce60a5`), the nightly 2026.10.12 (`+62f1cc6`, an oracle only,
R30), TP-1's /home/user/carbon-build/carbon-tp (`+eafca5cb9`; round 11 changed
no toolchain file), and the prototype ("proto", the planner's build of
b0822a744 plus `$Q/va2_prototype.patch`). `run_probe.sh` compiles, and links
and runs a probe that defines `Run`. Outcomes, verbatim but shortened:

| Probe | va (PR 59) | trunk | nightly | proto |
| --- | --- | --- | --- | --- |
| p01 StrCat verbatim (:250-260) | TODO `pack expansion pattern outside an explicit parameter list` | parse error `expected identifier or Self after .` | `expected pattern` | name `ConvertibleToString` not found (the design's names do not exist in Core) |
| p02 StrCat over a local `Digit` interface | same TODO | parse error | `expected pattern` | runs: 1 20 1 4 0 |
| p03 Zip verbatim (:67-82) | same TODO, then `expected expression` at `...and` | parse error | `expected pattern` | name `Vector` not found |
| p04 Apply verbatim (:273-279) | same TODO | parse error | `expected pattern` | name `Call` not found, then TODO `HandleAutoTypeLiteral` |
| p05 TupleConcat verbatim (:287-293) | same TODO | parse error | `expected pattern` | error `parameter list can contain at most one pack expansion pattern` (§0.8 F-3) |
| p06 Min with `Core.Ordered & Core.Copy` (:262-271) | TODO `pack expansion of a statement other than an expression statement` | parse error | `expected pattern` | same TODO |
| p07 Type versus execution (:512-518) | TODO `pack expansion pattern declaring more than one each-name`, then `expected ( after if` | parse error | `expected pattern` | same |
| p08 4-tuple `var u = t;` | runs: 4 | runs: 4 | runs: 4 | runs: 4 |
| p20 4-tuple through `Dup[T: Core.Copy]` | `cannot convert type (i32, i32, i32, i32) into type implementing Core.Copy` | same | same | same (the prelude is unchanged in the prototype) |
| p20b 3-tuple through `Dup` | runs: 3 | runs: 3 | runs: 3 | runs: 3 |
| p20c 4-tuple `.(Core.Copy.Op)()` | `cannot access member of interface Core.Copy in type (i32, i32, i32, i32) that does not implement that interface` | same | same | same |
| p22 4-tuple and 2-tuple of a class whose `Copy` prints, `var u = t;` | runs: 101 101 101 101 1 101 101 1 | not run | not run | same |
| p09 tuple `==` | `cannot access member of interface Core.EqWith((i32, i32)) in type (i32, i32) that does not implement that interface` | same | same | same |
| p10 tuple `<` | same with `Core.OrderedWith((i32, i32))` | same | same | same |
| p23 `(i32, i32) == (1, 2)` | same with `Core.EqWith((Core.IntLiteral, Core.IntLiteral))` | same | same | same |
| p11 `let t: auto = (... each x);` | TODO `HandleAutoTypeLiteral` | parse error | `expected pattern` | same TODO |
| p12 `[... each T: type](... each x: each T)` called with `(1 as i32, true)` | TODO `pack expansion pattern outside an explicit parameter list` | parse error | `expected pattern` | compiles |
| p13 `each x: auto` | TODO `HandleAutoTypeLiteral` | parse error | `expected pattern` | same |
| p14 `[... each T: Core.ImplicitAs(i32)]`, `... Core.Print(each x as i32)`, `(1 as i32, 2 as i16)` | TODO (implicit list) | parse error | `expected pattern` | runs: 1 2 |
| p15 empty heterogeneous pack, `Count()` | TODO (implicit list) | parse error | `expected pattern` | runs: 0 |
| p16 `class C(T: type) { fn Sum(... each x: i32) }` | runs: 6 | parse error | `expected pattern` | runs: 6 |
| p17 `fn Sum[template T: type](... each x: T)` | runs: 3 | parse error | `expected pattern` | runs: 3 |
| p18 `[... template each T: type]` | TODO (implicit list) | parse error | `expected pattern` | TODO `each-name binding that is not a value binding` |
| p19 `impl forall [... each T: I] (... each T) as I` | TODO (implicit list) | parse error | `expected pattern` | compiles |
| p24 that impl's `N()` on `(i32, bool)`, a 4-tuple and `()` | TODO | parse error | `expected pattern` | runs: 7 7 7 |
| p24b `Use[V: Count](v: V)` on `(1 as i32, 2 as i64)` | TODO | parse error | `expected pattern` | runs: 8 |
| p25 that impl shape for a local `I`, queried on the symbolic `(... each T)` in a generic function's body | not run | not run | not run | compiles |
| p26 the same beside `impl i32 as I`, queried on `i32` and on `(i32, i32)` | not run | not run | not run | runs: 5 1 (also after M-9's correction) |

p02 and p14 are the cores of §A.1's `variadics_hetero_digits`, p15 of §A.3,
and p24 and p24b of §A.9's `tuple_impl_generic`. "A pack in a
template" was measured on TP-1's install too: p16, p17 and p18 fail to parse
there ("expected identifier or `Self` after `.`"), because PR 61 is cut from
trunk, not from PR 59, so it has no pack syntax; the composition of TP-1's
templates with packs exists only on the PR 59 plus PR 61 mirror of §8.7, and
on PR 59 alone a homogeneous pack under a template element type runs (p17: 3)
while a template pack of types is VA-1's TODO (p18). Trunk has no `each`
keyword and the nightly no pack expansion patterns (VA-1 M-3), so their column
is the parse failure throughout and only the tuple rows compare.

M-3. Tuple copies today. A tuple is copied element by element by conversion,
whatever its arity (p08, p22: `var u: (Loud, Loud, Loud, Loud) = t;` runs each
element's `Copy.Op` once, printing 101 four times), on all three toolchains;
the prelude's tuple `Copy` impls are reached only where `Core.Copy` itself is
required, as `Dup[T: Core.Copy]` (p20) or `.(Core.Copy.Op)()` (p20c), and
there the 4-tuple is rejected on all three toolchains. So the brief's break
condition "a 4-tuple copies" is restated as: a 4-tuple and a 5-tuple satisfy
`Core.Copy` (p20 and p20c compile and run) with each element's `Copy.Op` run
exactly once (§A.8).

M-4. Tuple comparisons today: none, anywhere (p09, p10, p23 on all three
toolchains; no tuple impl in comparison.carbon at ebc155734, M-1).

M-5. Baseline on the planner's build of b0822a744 (`build.sh` and
`install.sh` with `CB_BUILD_ROOT=/dev/shm/va2-planner/builds`, 6 minutes, 318
translation units, `carbon version` `0.0.0-0.dev+b0822a744`): `gate.sh`
"file_test test mode on /home/user/carbon-va2: 1960 passed, 0 failed (exit 0,
25s)"; `conformance.sh` with a private cache: "PASS 137, COMPILE-FAIL 0,
LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 21 (of
158)", bullets 49 PASS, 0 FAIL, 7 SKIP of 56 (`$Q/logs/conf_baseline.log`).
This equals PR 59's recorded 1960 and 137/0/21 over 158.

M-6. The prototype (`$Q/va2_prototype.patch`; §0.5): gate "1955 passed, 5
failed" with no crash, the five being VA-1's goldens
toolchain/check/testdata/variadics/each_param.carbon, fail_todo_slice.carbon,
forward.carbon, import.carbon and toolchain/lower/testdata/variadics/
pack_expansion.carbon, whose autoupdate (`$Q/proto_golden_churn.diff`, 125
insertions and 145 deletions, then reverted) shows exactly three classes:
`pack_index` gains `[symbolic]` and an eval-block entry; a `pack_value` of
constants gains `[concrete]` and, in the lower golden, becomes a global
constant instead of a stack array (so `llvm.lifetime.start` declarations and
the per-call stores disappear); and fail_todo_slice's split
`fail_todo_generic_pack` now checks ("succeeded; if success is expected, remove
the `fail_` prefix"). Conformance with a private cache: PASS 137, 0 failures,
SKIP 21 of 158, bullets 49/0/7: unchanged (`$Q/logs/conf_proto4.log`).

M-7. C++ interop of tuples: toolchain/check/cpp/type_mapping.cpp:167-171 maps
only the empty tuple to `void` (`MapResultArgToCppType`), and no other tuple
type has a C++ mapping, so a Carbon tuple with `Copy` is neither exported nor
mapped; the variadic `Copy` impl changes nothing C++ sees (D-VA2-12).

M-8. The prototype's build measurements: incremental builds of 40 seconds to 9
minutes (typed_insts.h and generic.h are included by most objects), 0
warnings, on 4 cores while DR-1b's mirrors were building; one full build
of 6 minutes before any change (M-5).

M-9. The prototype with C4's declarations (`$Q/m9`, scripts `m9*.sh`). The
real impl bodies need C2's tuple values and C3's `... if`, so the prelude was
given C4's three impl declarations with bodies the prototype can check
(proxies), installed, and probed, gated and run through conformance:

-   With `fn Op(self) -> Self { return self; }` (`m9_prelude.py`), every
    compile that imports the prelude crashed: `CHECK failure at
    toolchain/base/value_store.h:370: index < size_` in
    `DeductionWorklist::AddAll` under `DeduceImplArguments`, first at
    core/prelude/copy.carbon:51 (`return self;`), then, with a second proxy,
    in core/prelude/types/char.carbon, which imports copy.carbon; file_test
    aborted (exit 134) and all 137 runnable programs were COMPILE-FAIL. The
    cause, read from the prototype's deduce.cpp: its `TupleType` case walks a
    non-tuple argument's first operand as a tuple's element block, and the
    type-structure hole (D-VA2-8) makes the variadic impl a candidate for
    every `Copy` query. p26 runs only because the misread `ClassId` of
    `i32` happens to be a valid block index.
-   With §2.3's one-branch correction (`deduce_fix.py`, rebuilt): p02, p14,
    p24, p24b, p25 and p26 run or compile as before; `return self;` is
    rejected, "cannot copy value of type `«T; <pack arity>»`" (A-7); with the
    body `return TupleCopyProxy(self);` over a defined generic helper
    (`m9_prelude_v4.py`), p08, p22, p09 and p10 compile (the variadic impls
    are selected for `==`, `<` and the copies), p23 is still rejected
    (W-334), and conformance is PASS 137, COMPILE-FAIL 0, LINK-FAIL 0,
    RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 21 (of 158), bullets
    49/0/7: no existing program changes with C4's declarations. But p20,
    p20b, p20c and §A.6 crash in lowering (`HandleInst` of a `Call` in a
    variadic impl function's specific), §A.7 and §A.8 fail LLVM's verifier
    ("Global variable initializer type does not match global variable
    type!"), and the gate crashes on full-prelude lower goldens that lower a
    tuple copy: the prototype selects the variadic impls but does not lower
    their functions' specifics, which C2 owns (§2.4 item 7, R-7).
-   Churn, with that body's helper parameter renamed so that it collides
    with no golden's names (`m9_prelude_v5.py`, `$Q/m9/churn7.diff`): the
    gate, with the one crashing golden toolchain/lower/testdata/for/
    bindings.carbon excluded by `--gtest_filter` (it lowers a copy of an
    `(i32, i32)` through the variadic impl, the lowering defect above), is
    1911 passed and 48 failed of 1959: VA-1's five goldens (M-6) and 43
    full-prelude check goldens (25 under match/, 4 under interop/, 3 under
    operators/, 2 each under builtins/, choice/ and function/, 1 each under
    generic/, if/, let/, slice/ and union/), whose autoupdate is 338 lines
    changed each way, every one a renumbered disambiguating suffix of a
    SemIR name (`%EqWith.impl_witness_table`, `%Core.import_ref`, `%T`):
    42 files verified mechanically as pure renames after stripping the
    suffixes, the 43rd (interop/cpp/operators/ordered_with.carbon) by
    reading. No lower golden other than for/bindings.carbon changes.

M-10. The three C++ oracles (§A.1, §A.7, §A.8), compiled with LLVM 21.1.8's
`clang++ -std=c++17 -Wall -Wextra -Werror -stdlib=libc++` and run
(`$Q/oracles`), print exactly the hand-derived lines of §5.

M-11. The nine programs parse on PR 59's install; the four stdlib programs,
which use no pack syntax, check there with errors only at their tuple impl
lookups (`cannot convert type ... into type implementing Core.Copy`, `Core.Eq`
or `Core.Ordered`, or `cannot access member of interface Core.EqWith(...)`);
the five generics programs stop at VA-1's TODO, as §0.2 predicts. The twelve
golden sources' 52 splits parse there too.

### §0.3 Where a heterogeneous pack enters VA-1's path

VA-1's §1.4 built one path for a pack of one element type `«E; N»`
(`PackType{element_type_inst_id, arity_id}`, `PackElement`, `PackIndex`,
`PackValue`, `PackLiteral`, `PackExpansionExpr`, `PackExpansionStatement`,
`PackExpansionPattern`). A heterogeneous pack enters it at six places, each
generalized in place by the prototype rather than forked:

1.  The implicit parameter list (handle_pack_expansion.cpp:56-67 refused it
    with `pack expansion pattern outside an explicit parameter list`): VA-2
    accepts `...` at `ImplicitParamListStart` under
    `FullPatternStack::Kind::ImplicitParamList`.
2.  The each-name binding (handle_binding_pattern.cpp:369-377 refused a
    compile-time `each T: I` with `each-name binding that is not a value
    binding`): VA-2 accepts a `CompileTimeBindingPattern`, whose binding `T`
    has the type `«I; N»`, a pack of facets.
3.  The binding's type (handle_binding_pattern.cpp:384-394 always wrapped the
    declared type `E` in `«E; N»`): VA-2 recognizes `each T` and types the
    value pack `⟬each T⟭`, `PackType{element = T, arity = T's arity}`.
4.  The arity (handle_pack_expansion.cpp:102-116 added `<pack arity>` at every
    pattern `...`): VA-2 adds it only when the binding's type names no pack,
    the design's "If this does not introduce any usages of `__N`, we remove its
    declaration" (:697-698).
5.  The element's type (handle_pack_expansion.cpp:381-387 used the pack's one
    element type): VA-2 gives `each x` the type `each T`, the symbolic
    `PackElement(T, PackIndex)` as a type.
6.  Lowering (lower/handle_pack_expansion.cpp, function_context.cpp): VA-1
    lowered the body once per element against one specific; VA-2 looks up
    every constant of the body in the specific's values for the current
    iteration (D-VA2-2), and lays out `⟬A, B⟭` as a tuple.

Deduction (deduce.cpp:443-470), the call's grouping (call.cpp:343-441) and the
conversions (convert.cpp:513-602) keep VA-1's code and gain one branch each
for a heterogeneous pack type (§2.3).

### §0.4 Impl lookup, specialization and thunks for a variadic impl

Impl lookup (impl_lookup.cpp) builds a `TypeStructure` of the query and of each
impl's self type (type_structure.cpp:166-338, from `SemIR::TypeIterator`) and
deduces each candidate's arguments (`DeduceImplArguments`, deduce.cpp). Today
`TypeIterator::ProcessType` (sem_ir/type_iterator.cpp:303-310) aborts on a
`PackType` ("Unhandled type instruction"), and a tuple type's structure is its
elements one by one (:233-245), so a self type `(... each T)` could match only
a 1-tuple. VA-2 makes a pack type and a tuple type with a pack segment a
symbolic hole of the structure (it matches any type at its position), and
deduction matches the segment against the run of the query's elements
(D-VA2-9). `VerifyAllGenericBindingsUsed` (impl.cpp:209-247) deduces an impl
against its own self type, so a self type with a segment must deduce against
itself (p19 failed with "`impl` with unused generic binding" until it did).
The thunk builder (toolchain/check/thunk.cpp `ClonePattern`, VA-1's W-229)
is not reached: `Copy.Op`, `EqWith.Equal` and the `OrderedWith` functions take
`self` and one `Self` parameter, no pack, so the impl's functions match the
interface's without a thunk; W-229 (a pack in an interface function) stays
filed. SC-1 (PR 60) changes impl lookup and requirement checking in files
VA-2 also touches (§0.6) but adds no case for pack types; TP-1 (PR 61) defers
template-dependent operands in call.cpp, deduce.cpp and convert.cpp, and its
seam with packs is W-224, unchanged.

### §0.5 The prototype

`$Q/va2_prototype.patch` implements the central mechanism and was built,
gated and run (M-6, §0.2's proto column):

-   heterogeneous packs end to end: `[... each T: I]`, `... each x: each T`,
    deduction of the pack of types, per-element impl lookup, the body checked
    once, lowering per element (p02, p12, p14, p15);
-   tuple types with one pack segment, their flattening, their deduction
    against a tuple, and a variadic impl selected for tuples of arity 0, 2 and
    4 and through a generic's requirement (p19, p24, p24b);
-   import of the new constants (VA-1's import.carbon passes after autoupdate).

Its measured defects are M-9's: the `TupleType` deduction's fallback reads a
non-tuple argument's first operand as an element block, which is undefined
(p26 happened to run) and crashed every program once the prelude had a
variadic impl (§2.3 gives the correction, measured); and the lowering of a
variadic impl's functions' specifics crashes or emits invalid IR, which C2's
lowering must cover.

It does not implement, and so §8.9 lists as unmeasured: tuple values with a
runtime pack segment (`(... each x)` as an initializer), `let` with a pack
expansion pattern, statement expansions of `if`, the prelude rewrite, the new
TODO diagnostics and goldens, and the programs of Appendix A.

### §0.6 Collisions with the held PRs (numstat, then `git merge-tree`)

For each held head, the files changed since its merge base with b0822a744
intersected with VA-2's planned files (§2), then `git merge-tree
--write-tree --name-only` of the prototype commit 74a8f47b4 against the head,
minus the conflicts b0822a744 already has with that head (VA-1's §6.2 method):

| PR (branch, head) | Shared files | Conflicts b0822a744 has | Conflicts with the prototype | New |
| --- | --- | --- | --- | --- |
| PR 51 ua2 (f96fe8a7a) | records only | not measured | not measured | records only |
| PR 52 cmake (ea573f672) | records, README.md | " | " | " |
| PR 53 safe (adaae4e35) | records | " | " | " |
| PR 54 ev (cb3ef2e74) | records, README.md | " | " | " |
| PR 55 st (21307851a) | records, README.md | " | " | " |
| PR 56 op (894139b34) | records, README.md | " | " | " |
| PR 57 op2 (a080c7886) | check/convert.cpp | 4 | 4 | 0 |
| PR 58 dd (fcee90d9b) | records, README.md | not measured | not measured | records only |
| PR 60 sc (40a76ab81) | check/context.h, convert.cpp, handle_binding_pattern.cpp, import_ref.cpp, merge.cpp, type.cpp, type.h, type_completion.cpp, impl_lookup.cpp, call.cpp; lower/type.cpp; sem_ir/stringify.cpp, typed_insts.h, type_iterator.cpp; diagnostics/kind.def | 3 | 3 | 0 |
| PR 61 tp (5661a35c8) | check/context.h, convert.cpp, eval.cpp, import_ref.cpp, impl_lookup.cpp, call.cpp; lower/function_context.cpp; sem_ir/stringify.cpp, typed_insts.h; diagnostics/kind.def | 4 | 6 | convert.cpp, eval.cpp |
| PR 62 sv (0ef8a0334) | check/convert.cpp, type.cpp; lower/constant.cpp; diagnostics/kind.def | 3 | 3 | 0 |
| PR 64 ct (4a3220c11) | as PR 61, plus check/eval.h, generic.cpp | 4 | 6 | convert.cpp, eval.cpp |
| PR 63 dr (2a4264056) | records | not measured | not measured | records only |
| DR-1b dr-idx (f774ee836) | check/convert.cpp, call.cpp | 3 | 3 | 0 |

"Records" is fork/gap-analysis.md, fork/inventory/work-items.json,
fork/decision-log.md and fork/ORCHESTRATION.md, and README.md is
fork/conformance/README.md; their conflicts are the land-time records commit's
(§3), regenerated or rewritten from the merged trunk, never merged by hand. The
two new conflicts with PR 61 (and so PR 64, stacked on it) are adjacent
insertions: in `ConvertTupleToType` (convert.cpp:700-750) PR 61 redirects a
`SpliceInst` element and VA-2 turns a pack-typed element into a segment, and
in `EvalContext`'s members (eval.cpp:251) PR 61 adds
`diagnosed_non_constant_ids_` and VA-2 adds `pack_index_`. Each resolves by
keeping both, PR 61's line first (§6.2's merge rule). No held PR touches
core/prelude/copy.carbon or core/prelude/operators/comparison.carbon (the
shared-file column has neither), so PR 55's and PR 56's prelude programs are
not affected textually; §5 runs them on the mirrors.

### §0.7 Conformance programs touched

VA-1's nine programs under generics/ (variadics_each, variadics_fixed_params,
variadics_forward, variadics_empty_pack, variadics_expansion_args,
variadics_sum_diff, variadics_arg_order, variadics_no_copy,
variadics_generic_element) PASS on the prototype unchanged (M-6). The tuple
programs of other bullets (stdlib/tuples_arrays_structs.carbon, bullet "Stdlib:
tuple/array library parts", and every program that copies a tuple) run against
the new `Copy` impl only where `Core.Copy` of a tuple is required, which no
existing program does (M-3); the full conformance run of §8.4 is the check.
New programs: Appendix A, nine, three of them differential pairs (§1.8).

### §0.8 Stale or contradicted claims found

-   F-1. The brief spells the compile-time binding `:!` (`[... each T:! type]`,
    `impl forall [... each T:! Copy]`). Upstream removed that syntax
    (72e425fe5, "Clean up some leftover references to the old `:!` syntax.")
    and the design spells `[... each T: type]` (:71, :252, :275, :289); this
    plan and every source it specifies use `:`.
-   F-2. "a 4-tuple copies" is already true by value (M-3); the break condition
    is about `Core.Copy` (M-3's restatement).
-   F-3. VA-1's `MultiplePackExpansionPatterns` ("parameter list can contain at
    most one pack expansion pattern", handle_pack_expansion.cpp:89-99) becomes
    reachable in an implicit parameter list once the list accepts `...`, and
    there it contradicts the design: TupleConcat's `[... each T1: type, ...
    each T2: type]` (:289) has two. The rule the design gives is "A tuple
    pattern can contain no more than one subpattern of the form `...` operand"
    (:333-334), and the implicit parameter list is not a tuple pattern; a
    second pack expansion in an implicit list is therefore a `semantics TODO`
    (W-222), not that error (D-VA2-4). The prototype still reports the error
    (p05), which C1 corrects.
-   F-4. The brief's "impl selection terminating by p002687's variadic count
    keys" describes a rule neither toolchain implements (M-2); D-VA2-10 says
    why VA-2's impls terminate without it.
-   F-5. PR 59's gap row lists "variadic impls (the tuple `Copy` rewrite)" and
    W-225 lists tuple `Eq`; the design's comparison page names `EqWith` and
    `OrderedWith` with `Eq` and `Ordered` as constraints (comparison.carbon
    :11-36), so VA-2's impls are `EqWith(Self)` and `OrderedWith(Self)` with
    `each T: Eq` and `each T: Ordered` requirements.

## §1 Design

Every decision auto-adopts the design's text under V-2, V-3b and R32 (R29(a))
and is recorded for after-the-fact veto in the decision-log entry "VA-2"
(§A.11), each with a one-sentence break condition.

### §1.1 The slice (D-VA2-1)

**D-VA2-1.** VA-2 implements, beyond VA-1's homogeneous value packs:

-   a compile-time pack in an implicit parameter list, `[... each T: I]`
    (:113-114), of a function or an impl, at most one per implicit list;
-   a value pack whose binding's type is that pack's each-name, `... each x:
    each T` (:219-221), sharing the compile-time pack's arity;
-   tuple types with one pack segment, `(... each T)`, as a parameter's type,
    a return type and an impl's self type (:357-361, :490-491), and tuple
    values with one pack segment, `(... each x)`, as initializers (:200-203);
-   `let` whose pattern is a tuple pattern of one pack expansion pattern,
    `let (... each x: each T) = t;` (:110-111, W-214 narrowed to `let`);
-   statement expansions whose body is an `if` statement, with `else if`
    chains and `return` in its branches (:108, :266-268, W-218 and W-219
    narrowed);
-   variadic impls, and with them core/prelude/copy.carbon's tuple `Copy` as
    one impl and tuple `EqWith(Self)` and `OrderedWith(Self)` in
    core/prelude/operators/comparison.carbon (W-225).

That is everything the design's StrCat (:250-260, over an interface the fork
has, §A.1), Min (:262-271, §A.5), Apply's and TupleConcat's signatures
(:273-293, the tuple-typed parameters and returns, §A.4) and the prelude's
tuple impls need, except `...expand` (D-VA2-13). It is one deduced arity per
full pattern: every pack of a function or impl has the arity of its first
pack expansion pattern, so the same-arity rule ("All each-names in a given
expansion must refer to packs with the same arity", :147-148) holds by
construction and W-222's independent arities stay filed (D-VA2-4). _Break
condition:_ a form inside this boundary is mis-checked or lowered with
another iteration's type or callee, or an arbiter of §1.8 needs a form outside
it.

### §1.2 The design's rules, VA-1's DR-1..DR-42 table extended

Numbered as in VA-1's §1.2 (variadics.md lines at ebc155734, this branch's
copy). Only the rules whose status changes are listed; every other rule keeps
VA-1's status and label.

| Rule | VA-1 | VA-2 | Label or evidence |
| --- | --- | --- | --- |
| DR-4 packs of different types (:86-90) | OUT | IN: a pack of the types of `[... each T: I]` and the value pack `... each x: each T` | §A.1, §A.2, golden `hetero_pack` |
| DR-8 statement expansions (:108) | IN for expression statements | IN also for an `if` statement; declarations, loops, `break`, `continue` stay OUT | W-218 narrowed, `fail_todo_statement_kind` |
| DR-9 tuple element `... expression` (:108-110) | IN in call arguments | IN in a tuple literal that initializes or is converted to a tuple with the same pack segment | VA-1's `fail_todo_tuple_literal` (a segment converted to `(i64, i64)`) keeps a TODO, now W-215's `tuple pack segment matched with other segments` |
| DR-10 tuple pattern `... pattern` (:110-111) | IN in explicit parameter lists | IN also as the whole tuple pattern of a `let` whose expansion has fixed arity (its binding's type is an enclosing pack's each-name, :532-534); a deduced-arity `let` (VA-1's `fail_todo_tuple_pattern`), `var`, `match` and nested tuple patterns stay OUT | W-214 narrowed |
| DR-11 implicit parameter list `... pattern` (:113-114) | OUT | IN, one per implicit list | W-222 for a second |
| DR-14 `(... x)` is a tuple (:137-140) | parser only | IN | §A.4 |
| DR-16 same arity (:147-148) | IN, one pack | IN for packs that share one arity | W-222 |
| DR-17 expansion without each-names in the type position (:149-150) | OUT | IN for `(... each T)` in a type, whose each-name is `T` | golden `tuple_segment` |
| DR-24 binding type with an each-name (:219-221) | OUT | IN when the type is exactly `each T` of a deduced pack; a type computed from an each-name (`Optional(each T)`) OUT | W-330 |
| DR-31 segments, pack literals, shapes (:357-449) | one segment | IN for tuples of one pack segment and for packs of different types; a tuple or a pack literal with more than one segment OUT | W-215, W-222 |
| DR-32 iterative typechecking (:451-481) | one segment of one type | IN for one segment of a pack of types: `each x` has the scalar component `each T` | D-VA2-6 |
| DR-33 tuple element expansion's segments become the tuple's (:490-491) | OUT | IN | D-VA2-8 |
| DR-35 fixed and deduced arity (:532-546) | deduced only | IN also for a fixed-arity `let` expansion over an enclosing pack; a fixed-arity class parameter pack OUT | W-222 |
| DR-37 typechecking a match by splitting and merging (:627-668) | one segment | IN for a tuple type of one segment against a tuple of elements; merging a segment with other elements OUT | W-215 |
| DR-40 typing rules (:730-748) | `each x: auto` OUT | `each x: auto` still OUT: `auto` parameters are `HandleAutoTypeLiteral` on every toolchain (§0.2 p13) | W-212 narrowed |
| DR-41 expansion convertibility (:835-837) | one segment | IN for a heterogeneous pack converted element by element at its iteration's types | D-VA2-5 |
| DR-13 `...expand` (:121-133) | OUT | OUT, and a V-3a register entry for the design's own TODO (:493) | W-217, §1.12 (i) |

New rules from the design that VA-1's table did not list:

| Rule | Status | Label or evidence |
| --- | --- | --- |
| DR-43 "Tuple indexing" reduction, `(X, Ys).(I)` reduces to `E` for `X` of the form `...⟬«E; S»⟭` (:811-818) | IN for the pack index into a tuple of one segment (`let` destructuring and initialization, D-VA2-9) | golden `tuple_segment` |
| DR-44 "Pack expansion splitting" and "Singular expansion removal" (:765-771) | IN at evaluation: a tuple type or value whose segment has a known arity is the tuple of its elements | D-VA2-8 |
| DR-45 "The type of `each x: auto` is `each __X`" (:732-734) | OUT (DR-40) | W-212 |
| DR-46 canonical form of a full pattern (:845-973) | OUT (VA-1's DR-36) | W-215 |

### §1.3 Compile-time packs and the pack index (D-VA2-2, D-VA2-3, D-VA2-4)

**D-VA2-2 (the pack index is a per-iteration constant).** "These semantics are
implemented at monomorphization time, so the value of N is a known integer
constant. Although the value of `$I` can vary during execution, it is
nevertheless treated as a constant." (:300-303) and "the expansion body is
implicitly parameterized by an integer value called the _pack index_"
(:163-165). VA-1's `PackIndex` was a run-time value (`InstConstantKind::Never`);
VA-2 makes it a symbolic constant (`SymbolicOnly`, evaluated by a dedicated
`TryEvalTypedInst<SemIR::PackIndex>`): in a generic and in a specific it is
symbolic, so every constant computed from it (the type `each T`, an impl
witness for `each T`, a callee) is an eval-block entry of the generic; within
iteration `k` of a specific it is the `IntValue` `k`. A specific whose generic's
eval blocks contain a `PackIndex` and whose pack arities are known gets, when
its definition is resolved (`ResolveSpecificDefinition`, check/generic.cpp),
its declaration and definition eval blocks evaluated once per iteration `k` in
`[0, N)` (`TryEvalPackIterationsForSpecific`, check/eval.cpp), where `N` is the
largest of its `<pack arity>` arguments; the values are stored on the
`SemIR::Specific` (`pack_iteration_block_id`, `pack_iteration_count`), and
`SemIR::GetConstantValueInSpecific` and `GetTypeOfInstInSpecific` take an
optional pack index that selects them. Evaluating an iteration also resolves
the definitions of the specifics its `RequireSpecificDefinition` entries name,
so each element's callee is lowered. `PackIndex` is a symbolic leaf like a
binding (the eval-block rebuild accepts it, check/generic.cpp:160-170), and
an imported `PackIndex` is symbolic too (`AddImportedConstant`, eval.cpp).
_Break condition:_ upstream represents the pack index or per-element
monomorphization otherwise (the advance then takes upstream's representation,
§6.3), or a measured file's check time rises beyond the gate's run-to-run
noise, since a specific evaluates its eval blocks `N + 1` times.

**D-VA2-3 (one pack type for packs of one and of different types).** VA-1's
`PackType{element_type_inst_id, arity_id}` is `«E; N»`. VA-2 renames the
operand `element_id` and lets it be either a type, for `«E; N»`, or a
compile-time pack of types or facets of arity `N`, for `⟬each T⟭`: "the type of
`... each x` is `... Optional(each T)`, because `Optional(each T)` is the
declared type of `each x`" (:375-378) and "if `T` does not contain an
each-name, the binding pattern is rewritten as `each X: «T; __N»`" (:696-697).
In a specific the pack is a `PackValue` of types or facets (now
`WheneverPossible`), so `⟬each T⟭` is concrete as `PackType{⟬A, B⟭, 2}`, whose
element `k` has the type `GetPackElementTypeId(pack_type, k)`
(sem_ir/generic.cpp) and whose layout and value representation are a tuple's
(type_completion.cpp, lower/type.cpp `BuildStructType`). One instruction kind,
one helper per question (`IsHeterogeneousPackType`, `GetPackElementType` for the
symbolic element type, `GetPackElementTypeId` for a concrete one); every VA-1
site that read `element_type_inst_id` goes through them (§2.2), so homogeneous
and heterogeneous packs share one checking and lowering path (R17). _Break
condition:_ a pack type whose element type is computed from an each-name
(`... each x: Optional(each T)`, Zip's `Vector(each ElementType)`) becomes
needed, which needs the design's "Pack expanding" reduction (:773-797) at
evaluation (W-330).

**D-VA2-4 (implicit parameter list packs and the arity).** A `...` that starts
an element of an implicit parameter list starts a pattern expansion; its
operand is one each-name binding, value (`each x: E`) or compile-time (`each
T: I`), the compile-time one typed `«I; N»`, a pack of facets. The arity
binding `<pack arity>` is now added by the each-name binding, after its type
is checked and before its own binding, and only when the type names no pack:
for `... each x: each T` the pattern takes `T`'s arity (the design's "If this
does not introduce any usages of `__N`, we remove its declaration", :697-698),
so a function or impl has one deduced arity, shared by its packs. A second pack
expansion pattern in one implicit parameter list is the `semantics TODO: more
than one pack expansion pattern in an implicit parameter list` (W-222), not
VA-1's `MultiplePackExpansionPatterns`, because the rule "A tuple pattern can
contain no more than one subpattern of the form `...` _operand_" (:333-334)
does not govern the implicit list and the design's own TupleConcat has two
there (:289; F-3). A template or `ref` each-name binding stays a `semantics
TODO` (W-221), relabeled `each-name binding that is ref, var or template`.
_Break condition:_ upstream allows several deduced arities per full pattern
before W-222 lands, or reads `[... each T1, ... each T2]` otherwise.

### §1.4 Deduction, checking and lowering of a pack of types (D-VA2-5..D-VA2-7)

**D-VA2-5 (deduction).** Deducing `⟬each T⟭` against a call's pack literal of
argument types `(A1, ..., Ak)` deduces the arity as `k` (VA-1) and `T` as the
constant `PackValue` `⟬A1, ..., Ak⟭` of type `«type; k»`; deduction then
converts it to `T`'s type, `«I; k»`, element by element (a new branch of
`PerformBuiltinConversion` for a `PackValue` of known arity), each element by
the ordinary type-to-facet conversion, which is the impl lookup of `Ai` as `I`
and diagnoses a missing impl at the call with the existing diagnostics.
Forwarding `... each x` deduces as VA-1's forwarding does (arity from arity,
element from element). Converting a call's pack literal to `⟬A1, ..., Ak⟭`
converts the `i`th argument to `Ai` (`ConvertPackLiteralToPack`), and VA-1's
`ConvertPackToPack` converts a forwarded pack element by element at each
iteration's types (DR-41). _Break condition:_ a call deduces a pack of types
in another order than the arguments', or accepts an argument whose type does
not satisfy `I`.

**D-VA2-6 (definition checking).** "Within a given iteration, typechecking
follows the usual rules of non-variadic typechecking, except that when we need
the type of an each-name, we use the scalar component of the current segment
of its type" (:477-479). The scalar component of `⟬each T⟭` is `each T`:
`GetPackElementType` builds `PackElement(T, PackIndex)`, a symbolic facet of
type `I`, and its `FacetAccessType`, so `each x.F()` is member access on a
value of a symbolic type with facet type `I`, checked once at the definition
as a function with `[U: I](x: U)` is. `PackElement` is a symbolic constant
when its pack is compile-time (`SymbolicOnly`, `is_type = Maybe`, evaluated by
`EvalConstantInst(Context&, SemIR::PackElement)`: the pack's `k`th element once
the pack is a `PackValue` and the index is `k`) and a run-time value otherwise,
as in VA-1; the type iterator treats it as a symbolic type like a symbolic
`TupleAccess`. _Break condition:_ a body that uses a member `I` does not have
is accepted, or one that uses only `I`'s members is rejected.

**D-VA2-7 (lowering).** Each iteration of an expansion is lowered with the
specific's per-iteration values: `FunctionContext` passes its `pack_index_` to
every constant and type lookup (`GetValue`, `IsConstant`, `GetTypeIdOfInst`,
the callee lookup of handle_call.cpp), so iteration `k` of `... each x.F()`
calls the `k`th element type's `F`. A pack of different types is stored as a
tuple of the elements' value representations; `PackElement` addresses the
element at the current pack index with a constant GEP (valid for the array of
`«E; N»` and the struct of `⟬A, B⟭`), and a constant `PackValue` of types or
facets lowers to a null constant (no run-time content). VA-1's per-iteration
erasure of locals is unchanged. _Break condition:_ a specific runs an
iteration with another iteration's type or callee, which §8.5's mutants MV-1
and MV-2 are built to detect.

### §1.5 Tuples with pack segments (D-VA2-8, D-VA2-9)

**D-VA2-8 (tuple types).** "The type of a tuple literal is a tuple literal of
the types of its segments" (:365) and "For a `...` tuple element expression or
pattern, the segments of the operand's type pack become segments of the type
of the enclosing tuple" (:490-491). A `TupleType` element may be a `PackType`,
a segment; `TupleType` becomes `InstConstantKind::Conditional`, its
`EvalConstantInst` replacing a segment of known arity and known element types
by its elements ("Pack expansion splitting", "Singular expansion removal",
:765-771), so `(... each T)` in a specific with `T = ⟬i32, bool⟭` is the
canonical `(i32, bool)`; `TupleValue` likewise splices a `PackValue` element.
`... each T` whose body is exactly the each-name of a compile-time pack is that
pack (its constant), so `(... each T)` converts to the type `(⟬each T⟭)`
(`ConvertTupleToType`). Deducing a tuple type with one segment against a tuple
type matches the elements before and after the segment one by one and the
segment against the remaining run as a pack literal of those types; against a
tuple type with a segment in the same place, segment against segment ("The
search for this rewrite processes each pattern segment to the left of the
segment with deduced arity, in order from left to right", :651-658, for one
segment). The impl-lookup type structure treats a pack type and a tuple type
with a segment as a symbolic hole. A tuple type with more than one segment is
the `semantics TODO: tuple with more than one pack segment` (W-222, W-215).
_Break condition:_ upstream canonicalizes tuple types with segments otherwise,
or a query matches an impl whose self type's segment cannot cover its run.

**D-VA2-9 (tuple values, `let`, initialization).** Three forms, each the
design's, specified in §2.4 and not prototyped (§0.5):

-   `let (... each x: each T) = t;` with `t` a tuple of one segment
    `⟬each T⟭` binds `x` to `t`'s elements: a fixed-arity pack expansion
    (:532-546; its each-name `T` is not a parameter of the `let`'s pattern),
    whose value is `t`'s value representation reinterpreted as the pack's
    (both are the address of the elements' value representations, D-VA2-3),
    with no copy, as VA-1's value binding of a pack (DR-30).
-   `(... each x)` converted to initialize a tuple of one segment: the
    conversion emits a statement expansion whose body copy-initializes the
    target's element at the pack index from `each x` ("`...` in a tuple
    literal behaves like a series of comma-separated tuple elements",
    :200-201), the element addressed by `PackElement` on the tuple (the design's
    tuple indexing, :811-818, DR-43), so each element is copied once, by its
    own `Copy`.
-   `(... each x)` used as a value of the tuple type: VA-1's pack storage of
    the elements' values is the tuple's value representation.

An expansion element of a tuple literal whose body is an initializing
expression (`(... each x.Op())` initializing a tuple) would have to initialize
the target's element in place through the body's return slot; VA-2 diagnoses it
as the `semantics TODO: pack expansion of initializing expressions in a tuple
literal` (W-331) rather than copy each element twice. _Break condition:_ a
`let` pack binding or a tuple initialized from a pack copies an element more or
fewer times than once per element, or reads another element.

### §1.6 Variadic impls and the prelude (D-VA2-10, D-VA2-11, D-VA2-12)

**D-VA2-10 (impl selection and termination).** A variadic impl is an impl
whose implicit parameter list has a compile-time pack and whose self type has
a pack segment. Its selection is the impl lookup of today plus D-VA2-8's
deduction and type-structure hole; `VerifyAllGenericBindingsUsed` deduces the
impl against its own self type, which D-VA2-8's segment-against-segment rule
covers (p19). Termination: impl lookup implements only the acyclic rule, and
upstream's p002687 termination rule, with its variadic count keys ("A `tuple`
key in this namespace is used to track the total number of components of tuple
values", :210-215), is a TODO upstream as in the fork (M-2). VA-2's impls
terminate without it, because each requirement they add (`each T: Copy`,
`each T: Eq`, `each T: Ordered`) is a lookup on an element of the query's
tuple, a strict subterm of the query's self type, so every chain of nested
lookups is finite by the size of the type. Implementing p002687 is filed as
W-332 (an accepted design and upstream's own TODO, owned by no workstream yet,
§1.12 (iv)). _Break condition:_ a prelude or program impl whose requirement is
on a type not smaller than its self type needs termination checking.

**D-VA2-11 (statement expansions of `if`).** The design gives `... if`
(Min, :266-268) and executes "_statement_ N times" (:305-306). VA-2 checks a
statement expansion whose body is an `if` statement (with `else if` and
`else` branches whose statements are expression statements, `if` statements or
`return` statements) once, as VA-1 checks an expression statement, with the
body's blocks collected separately from the function's (a body region), and
lowers the region once per iteration with fresh LLVM blocks, the iteration's
exit block falling through to the next iteration's entry. `return` in a branch
returns from the function. Declarations, `while`, `for`, `break`, `continue`
and `match` in a body stay the `semantics TODO: pack expansion of a statement
other than an expression or if statement` (W-218), and control flow in an
expression body (`and`, `or`, `if` expressions) stays VA-1's `control flow in a
pack expansion` (W-219). _Break condition:_ a branch's block is lowered once for
all iterations, or an iteration falls through to a block of another.

**D-VA2-12 (the prelude, verbatim in §2.6).** core/prelude/copy.carbon:50-71
(the TODO and four impls) becomes one impl, in place:

<!-- google-doc-style-ignore -->

```carbon
impl forall [... each T: Copy] (... each T) as Copy {
  fn Op(self) -> Self {
    let (... each x: each T) = self;
    return (... each x);
  }
}
```

<!-- google-doc-style-resume -->

and core/prelude/operators/comparison.carbon gains, after the `IntLiteral`
impls, `impl forall [... each T: Eq] (... each T) as EqWith(Self)` and `impl
forall [... each T: Ordered] (... each T) as OrderedWith(Self)`, comparing
"field-wise" (tuples.md :106-121) with "a lexicographical ordering" in which
"the comparison is only available if it is supported by all element types"
(comparison_operators.md :488-490). The tuple impls live where upstream keeps
its tuple `Copy` impls (copy.carbon) and its builtin-type comparisons
(comparison.carbon, "this must be provided in this library as `bool` doesn't
have any associated libraries of its own", :38-40; tuples have no library of
their own either). `Copy.Op` copies each element once, by the element's own
`Copy` (D-VA2-9), as upstream's `(self.0.Op(), self.1.Op())` does; the
`(... each x.Op())` spelling would need W-331 and is the impl's text once W-331
lands. The test-only toolchain/testing/testdata/min_prelude/parts/copy.carbon
(upstream's fixture, with its own `()`, 2- and 3-tuple impls) is not changed,
so no golden built on it churns; the 312 goldens on the production prelude
(`min_prelude/full.carbon`) churn as M-9 measures, 43 by renamed SemIR names
and toolchain/lower/testdata/for/bindings.carbon by its lowered tuple copy,
all refilled by F4. The impls compare tuples of one type only
(W-334, §1.12 (ii)). _Break condition:_ upstream lands its own variadic tuple
impls (the advance takes upstream's text), or a tuple of more than three
elements does not satisfy `Core.Copy`, `Core.Eq` or `Core.Ordered` when its
elements do.

### §1.7 Diagnostics, templates and C++ interop (D-VA2-13, D-VA2-14)

**D-VA2-13 (what stays a TODO, with its text).** Each a `semantics TODO` with a
golden split (§4), each in check, each filed:

| Form | Text after `semantics TODO:` | Item |
| --- | --- | --- |
| a second pack expansion pattern in an implicit list | `more than one pack expansion pattern in an implicit parameter list` | W-222 |
| a pack expansion pattern in a `var`, `match` or nested tuple pattern | `pack expansion pattern in a pattern other than a parameter list or let` (VA-1's `pack expansion pattern outside an explicit parameter list`, relabeled) | W-214 |
| a `let` pack expansion pattern with deduced arity | `pack expansion pattern with deduced arity outside a parameter list` | W-214 |
| a binding type computed from an each-name | `pack expansion pattern whose binding type is computed from an each-name` | W-330 |
| a tuple with more than one pack segment | `tuple with more than one pack segment` | W-222 |
| a segment merged with other elements in a deduction | `tuple pack segment matched with other segments` | W-215 |
| an initializing expansion element in a tuple literal | `pack expansion of initializing expressions in a tuple literal` | W-331 |
| a statement other than an expression or `if` statement | `pack expansion of a statement other than an expression or if statement` (relabeled) | W-218 |
| a `ref`, `var` or `template` each-name binding | `each-name binding that is ref, var or template` (relabeled) | W-221 |
| `...expand` | upstream's `HandlePrefixOperatorExpand` (unchanged) | W-217 |
| `each x: auto` | `HandleAutoTypeLiteral` (unchanged, upstream's) | W-212 |

VA-1's `pack expansion pattern outside an explicit parameter list` split
`fail_todo_generic_pack` (fail_todo_slice.carbon) now checks, and C1 renames it
`generic_pack` in a new golden (M-6). `...expand` is a V-3a register entry, not
a fork spelling: the design gives its execution (:121-126) but "**TODO:**
Discuss typechecking `...expand`." (:493) and "**TODO:** address `...expand`,
`...and` and `...or`." (:750), and upstream is trying "an approach supporting
expanding a statement across elements of a tuple without building real
variadics" (2ec4bab59), so the fork stops at the text (R32(d)). _Break
condition:_ one of these forms is reached by an arbiter of §1.8, or upstream
settles `...expand`'s typechecking (W-217 then implements upstream's text).

**D-VA2-14 (templates and C++ interop).** Templates: PR 61 is not stacked on
PR 59, so no install composes templates with packs (§0.2); VA-1's
`pack expansion argument in a template-dependent call` (W-224) and VA-2's
template each-name TODO (W-221) keep packs and templates apart, and the PR 59
plus PR 61 mirror (§8.7) is the composition's check. C++: no tuple other than
`()` maps to C++ (M-7), and VA-1's `exporting a variadic function to C++`
(W-228) also covers a heterogeneous one, so VA-2 changes nothing C++ sees;
the differential pairs of §1.8 compare Carbon with C++ programs, not across
the boundary. _Break condition:_ a held PR maps Carbon tuples to `std::tuple`
before VA-2 lands, which would make the tuple impls reachable from C++.

### §1.8 Goldens and programs (D-VA2-15, D-VA2-16)

**D-VA2-15 (goldens).** New goldens, each a source with `// AUTOUPDATE` and no
CHECK line (R15, R16(a)), built on `min_prelude` with local interfaces, so
none depends on the changed prelude: toolchain/check/testdata/variadics/
`hetero_pack.carbon`, `fail_hetero_pack.carbon`, `generic_pack.carbon`,
`tuple_segment.carbon`, `fail_todo_tuple_segment.carbon`, `impl.carbon`,
`fail_impl.carbon`, `expansion_if.carbon`, `fail_todo_va2.carbon`;
toolchain/lower/testdata/variadics/`hetero_pack.carbon`,
`tuple_segment.carbon`, `expansion_if.carbon`. Refilled: VA-1's
each_param.carbon, forward.carbon, import.carbon, fail_todo_slice.carbon (the
`fail_todo_generic_pack` split moved, relabeled TODOs) and the lower
pack_expansion.carbon (M-6's three classes), and, by C4, M-9's 44 goldens on
the production prelude. Sources in §A.10. _Break condition:_ a fill changes a
golden outside this list (§6.1).

**D-VA2-16 (programs).** Nine new conformance programs (§A.1 to §A.9), EXPECT
derived by hand in §A (R16(d)), three with a C++ oracle (DIFF-1): bullet
"Generics: Definition-checked variadics": `variadics_hetero_digits` (StrCat's
shape) with `variadics_hetero_digits.diff.cpp` (a C++17 fold over a template
parameter pack), `variadics_hetero_forward`, `variadics_hetero_empty`,
`variadics_tuple_param` (Apply's and TupleConcat's signatures without
`...expand`), `variadics_min` (the design's Min); bullet "Stdlib: tuple/array
library parts": `tuple_copy_variadic`, `tuple_eq` with `tuple_eq.diff.cpp`
(`std::tuple`'s `operator==`), `tuple_ordered` with `tuple_ordered.diff.cpp`
(`std::tuple`'s `operator<` and `std::tie`), `tuple_impl_generic` (the tuple
impls through generic requirements). The variadic sum against a C++ parameter
pack is `variadics_hetero_digits`'s second half. _Break condition:_ a program
passes against a mutant of §8.5.

### §1.9 Docs and records (D-VA2-17)

**D-VA2-17.** docs/design/variadics.md is not edited: every rule VA-2
implements is spelled as the page spells it, and no fork amendment is due (no
F id; R32). The records, written by commits R and D (§3, §A.11):

-   W-212 DISCHARGED for implicit-list packs, each-name binding types and
    packs of different types, with `each x: auto` moved to W-333 (blocked on
    `auto` parameters); W-213 DISCHARGED for tuples of one pack segment, with
    several segments in W-222 and `...expand` in W-217; W-225 DISCHARGED (the
    four impls replaced, a 4-tuple and a 5-tuple satisfy `Core.Copy`, tuple
    `EqWith(Self)` and `OrderedWith(Self)`), with mixed-type comparisons in
    W-334. W-214, W-218 and W-219 narrowed by their notes; W-222 narrowed to
    independent arities and class parameter packs; W-013 stays open, its note
    naming slice 2 and the next slice (W-330, W-222, W-217).
-   "Generics: Definition-checked variadics" stays PARTIAL; its evidence text
    gains slice 2 and its "Not yet" list loses "packs of several or deduced
    types (`[... each T: type]`)", "expansions in tuple literals ... outside
    calls" (one segment) and "variadic impls (the tuple `Copy` rewrite)".
-   "Stdlib: tuple/array library parts" stays PARTIAL: its text "tuple Copy
    hand-written only for arities 0-3 with 'TODO: Implement tuple copy as a
    variadic generic impl'; no tuple Eq/Ordered — blocked on variadics." is
    replaced by the variadic impls' evidence, and its open text becomes
    W-334's comparisons that convert one operand (comparison_operators.md
    :504-505), which the design requires and VA-2 does not implement; the
    array half ("array Iterate impl works") is kept as written, its
    absorption of upstream's `Core.Array` (947c1eb52) being UA-3's. The row
    moves to DONE when W-334 lands. The header's counts do not move.
-   fork/decision-log.md gains "VA-2: definition-checked variadics, slice 2
    (<date>)" with D-VA2-1..D-VA2-19, the options of §7.2, the V-3 check and the
    V-3a register entries (§1.12); fork/ORCHESTRATION.md, fork/conformance/
    README.md (regenerated table) and fork/gap-analysis.md §W6 are updated.

_Break condition:_ a review shows VA-2 deciding a rule the design leaves open,
which would need a dated design amendment and an F id.

### §1.10 Merge position (D-VA2-18)

**D-VA2-18.** VA-2 is one PR, stacked on PR 59 (R29(b)), merging last: after
DR-1b, in the order of trunk's fork/ORCHESTRATION.md (PR 53, 51, 52, 60, 54,
55, 56, 57, 58 through state L, 59, 61 through its land-time commits, 62, 64,
63 through M-a and L-a, DR-1b through M-b, C-b and L-b, then VA-2). Its
land-time commits (§3): M (merge of the trunk that holds every PR before it,
a merge commit), F-M (the fill M's merged toolchain needs), L-F (programs and
README table regenerated on the merged trunk), and L (the land-time records
commit, re-quoting §8.8's run). _Break condition:_ a PR ahead of VA-2 gains an
unresolvable conflict with it at the land-time re-measurement.

### §1.11 Residues and narrowed items

Filed by commit D from W-330 (bullet "Generics: Definition-checked variadics"
unless named), each with its evidence and "follows VA-2 slice 2" in its notes:

1.  W-330: pack types whose element type is computed from an each-name
    (`... each x: Optional(each T)`, Zip's `... each vector: Vector(each
    ElementType)`), the design's "Pack expanding" reduction at evaluation
    (:773-797). Evidence: `fail_todo_va2` split
    `fail_todo_computed_element_type`.
2.  W-331: pack expansions of initializing expressions in a tuple literal,
    initialized in place (`return (... each x.Op());`). Evidence:
    `fail_todo_va2` split `fail_todo_initializing_element`.
3.  W-332: p002687's termination rule with variadic count keys (:186-193,
    :210-215), upstream's own TODO (impl_lookup.cpp:199 at ebc155734).
    Bullet "Generics: Checked generics". Evidence: M-2.
4.  W-333: `each x: auto` (:732-734), blocked by `auto` parameters
    (`HandleAutoTypeLiteral`). Evidence: p13.
5.  W-334: tuple comparisons that convert one operand (comparison_operators.md
    :504-505), needing `EqWith((... each U))` over two packs of one arity and a
    per-element requirement. Bullet "Stdlib: tuple/array library parts".
    Evidence: p23 after C4.
6.  W-335..W-339: reserved, unused unless the reviews or the implementation
    need them.

Narrowed by notes, no new id: W-214 (only `var`, `match` and nested tuple
patterns remain), W-218 (only declarations, loops, `break`, `continue` and
`match` remain), W-219 (only control flow in expression bodies and the "Type
versus execution semantics" example remain), W-222 (only independent arities,
a second implicit-list pack, tuples of several segments and class parameter
packs remain), W-229 (its note gains p002274's variadic indexing interfaces,
:250-257, which W-212's note named: the proposal defers them "once we have a
design for variadics" as an alternative, not a rule, and they need packs in
interface functions, which is W-229); W-212, W-213 and W-225 discharged
(§1.9), W-212's `each x: auto` moving to W-333.

### §1.12 The V-3a register (DR-0) and decision index

Register entries VA-2 adds, each a work item under V-3b, each reviewed at the
weekly upstream check:

-   (i) `...expand`'s typechecking is the design's TODO (:493, :750);
    upstream's 2ec4bab59 parses a prefix `expand`; the fork implements neither
    (W-217), so Apply and TupleConcat (:273-293) stop at the text.
-   (ii) Tuple comparisons convert neither operand (W-334), a narrowing of
    comparison_operators.md :504-505, not a second spelling.
-   (iii) Default values beside a pack stay VA-1's TODO (W-215); upstream's
    503f09037 adds defaults for non-generic parameters of generic functions,
    which W-215's implementation follows.
-   (iv) p002687's termination rule is upstream's TODO too (W-332).

| Decision | Summary | Break condition |
| --- | --- | --- |
| D-VA2-1 | the slice: implicit-list packs, packs of different types, tuples of one segment, `let` destructuring, `... if`, variadic impls | a form inside it is mis-checked or mis-lowered, or an arbiter needs one outside |
| D-VA2-2 | symbolic pack index; per-iteration value blocks of a specific | upstream represents it otherwise, or check time rises beyond noise |
| D-VA2-3 | one `PackType` with `element_id` a type or a pack of types | a computed element type is needed (W-330) |
| D-VA2-4 | `[... each T: I]`; arity added by the binding; a second implicit-list pack is a TODO | upstream allows several arities, or reads the form otherwise |
| D-VA2-5 | deduce the pack of types, convert element by element | wrong order or a missing impl accepted |
| D-VA2-6 | `each x` has the symbolic type `each T` | a body is accepted or rejected against the facet's members wrongly |
| D-VA2-7 | lowering with per-iteration constants; tuple layout | an iteration uses another's type or callee |
| D-VA2-8 | tuple types with one segment; flattening; deduction; type-structure hole | upstream canonicalizes otherwise, or a match covers a wrong run |
| D-VA2-9 | `let` destructuring, initialization element by element, W-331 TODO | an element copied other than once |
| D-VA2-10 | variadic impl selection; termination by subterm requirements | a requirement on a non-smaller type is needed |
| D-VA2-11 | statement expansions of `if` with per-iteration blocks | a branch block shared by iterations |
| D-VA2-12 | the prelude impls, min_prelude unchanged | upstream lands its own, or a tuple of more than three elements fails |
| D-VA2-13 | TODO texts and the `...expand` register entry | an arbiter reaches a TODO, or upstream settles `...expand` |
| D-VA2-14 | templates and C++ unchanged | a held PR maps tuples to C++ first |
| D-VA2-15 | twelve new goldens, five VA-1 refills, C4's 44 full-prelude refills (M-9) | a fill changes another golden |
| D-VA2-16 | nine programs, three differential | a program passes a mutant |
| D-VA2-17 | records; no design edit; both rows stay PARTIAL with narrower open text | VA-2 decides an open rule |
| D-VA2-18 | one PR on PR 59, merging last, land-time M, F-M, L-F, L | an unresolvable conflict at land time |
| D-VA2-19 | five implementation commits with fills, fix budget three, shrink line (§3) | a commit cannot build without a later one |

## §2 Spec, file by file

### §2.0 Conventions

The built part of the spec is Appendix B, the prototype's diff verbatim
(`$Q/va2_prototype.patch`), measured as §0.2 and M-6 say; §2.1 to §2.3 say,
file by file, what each hunk does and the invariant it keeps, and name the
changes C1 makes beyond the prototype (the review-facing corrections F-3 and
the TODO labels). §2.4 to §2.6 specify the unbuilt part (C2's tuple values,
C3's `... if`, C4's prelude) with the code to write; each is a prediction, and
§8.9 lists it as unmeasured. Fork comments name the decision (`// Fork (VA-2,
D-VA2-n): ...`), quote the design page they implement, and name no work item
(VA-1's convention: ids live in records only).

### §2.1 C1, SemIR (built)

-   toolchain/sem_ir/typed_insts.h: `PackElement` becomes `SymbolicOnly` with
    `is_type = Maybe` (D-VA2-6); `PackIndex` becomes `SymbolicOnly`
    (D-VA2-2); `PackType`'s `element_type_inst_id` becomes `InstId element_id`
    (D-VA2-3); `PackValue` becomes `WheneverPossible` (D-VA2-3). Invariant: a
    `PackElement` or `PackIndex` is a run-time value only inside a body whose
    pack is a run-time value; a symbolic one is never concrete (its
    `EvalConstantInst` returns `NotConstant` for a concrete operand pair that is
    not a `PackValue` and an `IntValue`).
-   toolchain/sem_ir/generic.h, generic.cpp: `Specific::pack_iteration_block_id`
    and `pack_iteration_count` (not printed, so no golden prints them);
    `GetConstantValueInSpecific` and `GetTypeOfInstInSpecific` overloads taking
    `std::optional<uint64_t> pack_index`, reading entry `k * size + offset`
    where `offset` adds the declaration block's size for a definition-region
    constant; `GetPackElementTypeId`. Invariant: without a pack index, or for a
    specific without per-iteration values, a lookup is VA-1's.
-   toolchain/sem_ir/type_iterator.cpp: `PackElement` is a symbolic type like a
    symbolic `TupleAccess` (C1); a `PackType`, and a `TupleType` with a
    `PackType` element, is a `SymbolicType` hole (C2, D-VA2-8).
-   toolchain/sem_ir/stringify.cpp: `PackType` prints its `element_id`. C1 adds
    a `PackElement` case printing `each <pack>`, so a diagnostic names `each
    T`; the prototype has no such case, so it would print stringify.cpp's
    fallback for an unhandled instruction (predicted, not run: §4's
    `fail_convert_element`).

### §2.2 C1, check and lower of packs of different types (built)

-   check/eval.cpp: `EvalContext::pack_index_` with `set_pack_index`, used by
    `GetConstantValue` and `GetTypeOfInst`; `TryEvalTypedInst<SemIR::PackIndex>`
    (concrete `IntValue` in an iteration, else `CheckedSymbolic`);
    `AddImportedConstant` keeps an imported `PackIndex` symbolic;
    `TryEvalPackIterationsForSpecific` (declaration and definition eval blocks,
    once per iteration, `N` the largest `<pack arity>` argument, only when an
    eval block holds a `PackIndex`). check/eval.h declares it.
-   check/eval_inst.cpp: `EvalConstantInst(Context&, SemIR::PackElement)`.
-   check/generic.cpp: `ResolveSpecificDefinition` calls
    `TryEvalPackIterationsForSpecific` after the definition block; the eval
    block rebuild accepts a `PackIndex` leaf.
-   check/type.h, type.cpp: `GetPackType(context, InstId element_id, arity)`,
    `IsHeterogeneousPackType`, `GetEachNameTypePack`,
    `GetPackTypeForElementType`, `GetPackElementType`.
-   check/context.h: `PackExpansionScope::pack_type_id` replaces
    `element_type_inst_id`.
-   check/handle_pack_expansion.cpp: a pattern `...` in an implicit list
    (D-VA2-4); no arity at the `...`; the each-name of a pack in a pattern's
    type position; the element type through `GetPackElementType`; an
    expansion whose body is the each-name of a compile-time pack is the pack
    (C2's use); the expression expansion's pack type through
    `GetPackTypeForElementType`. C1 adds: in an implicit list, a second
    `PackExpansionPattern` is `context.TODO(node_id, "more than one pack
    expansion pattern in an implicit parameter list")` instead of
    `MultiplePackExpansionPatterns` (F-3), and the relabeled TODOs of
    D-VA2-13.
-   check/handle_binding_pattern.cpp: compile-time each-name bindings; the
    arity added by the binding; `⟬each T⟭` for an each-name type; the pack's
    arity registered for the binding and for its constant; an invalid element
    type keeps VA-1's `pack_type invalid, %arity` (the prototype's last fix,
    VA-1's `fail_invalid_element_type`).
-   check/deduce.cpp: the heterogeneous branch of the `PackType` case
    (D-VA2-5); the `TupleType` case of D-VA2-8 (C2's, built).
-   check/convert.cpp: per-element target types in `ConvertPackLiteralToPack`;
    per-iteration types in `ConvertPackToPack`; the `PackValue` element-wise
    branch; `ConvertTupleToType`'s pack segment (C2's, built).
-   check/type_completion.cpp: nested types and value representation of a
    heterogeneous pack, a tuple's (with its object layout).
-   check/import_ref.cpp: `PackIndex`, `PackElement`, `PackValue`, and
    `PackType`'s renamed operand.
-   check/merge.cpp, pattern_match.cpp: a `PackExpansionPattern` without an
    arity pattern.
-   lower/function_context.h, .cpp: `current_pack_index()`; the pack index
    passed to `GetValue`, `IsConstant` and `GetTypeIdOfInst`.
-   lower/handle_call.cpp: the callee looked up in the iteration.
-   lower/handle_pack_expansion.cpp: constant GEP at the current pack index.
-   lower/type.cpp: `⟬A, B⟭` laid out by `BuildStructType`.
-   lower/constant.cpp: `EmitAsConstant(PackValue)` (null for a pack of types
    or facets).

### §2.3 C2, tuple types with pack segments (built)

-   sem_ir/typed_insts.h: `TupleType` and `TupleValue` become `Conditional`.
-   check/eval_inst.cpp: `EvalConstantInst(Context&, SemIR::TupleType)` (a
    segment of known arity and element types replaced by its elements) and
    `EvalConstantInst(Context&, SemIR::TupleValue)` (a `PackValue` element
    spliced). Invariant: a tuple type without a segment evaluates exactly as
    before (`NewSamePhase`), so no golden outside the variadics directory
    changes (M-6: none did).
-   check/deduce.cpp: the `TupleType` case: one segment against a tuple of
    elements (elements before and after one by one, the run as a tuple type
    deduced by the `PackType` case), or segment against segment in the same
    place, else `false`. C2 corrects the prototype's fallback (M-9): an
    argument that is not a `TupleType` breaks to the constant path, as the
    default case does for a kind mismatch, instead of having its first
    operand walked as a tuple's element block. The correction, as measured:

<!-- google-doc-style-ignore -->

```cpp
        if (!arg_tuple) {
          break;
        }
        if (segment == param_elements.end()) {
          // Deduce through the tuple's operands as before.
          worklist_.AddInstArg(param_inst.arg0_and_kind(),
                               context().insts().Get(arg_id).arg0(),
                               want_value);
          continue;
        }
```

<!-- google-doc-style-resume -->

-   check/convert.cpp, `ConvertTupleToType`: a pack-typed element becomes the
    segment `GetPackType(element, arity)`.

### §2.4 C2, tuple values with a pack segment and `let` (specified, not built)

1.  check/handle_tuple_literal.cpp: VA-1's TODO for a `PackExpansionExpr`
    element (`pack expansion in a tuple literal outside a call's argument
    list`) is removed; a tuple literal may hold one pack segment, which is a
    pack-typed element (an expansion, or after `HandleParseNode(
    PackExpansionExprId)`'s collapse the pack itself); a second segment is
    `context.TODO(inst, "tuple with more than one pack segment")`. An
    expansion element whose body result is an initializing expression is
    `context.TODO(inst, "pack expansion of initializing expressions in a tuple
    literal")` (W-331), raised in the expansion's handler when its context is
    `TupleLiteralStart` and the body result's category is initializing;
    VA-1's `ConvertToValueExpr` in the body then makes every other element a
    value, as in a call.
2.  check/handle_pack_expansion.cpp: VA-2's collapse of `... each P` to `P`
    applies to a run-time pack too (the expansion of exactly an each-name is
    the pack, :200-202), so `(... each x)` is the tuple literal `(x)` of one
    pack-typed element.
3.  sem_ir/typed_insts.h: a new instruction, listed in inst_kind.def, named,
    formatted and lowered like VA-1's:

<!-- google-doc-style-ignore -->

```cpp
// Fork (VA-2): initializes the elements of a tuple of one pack segment at
// `dest_id` by running `body_block_id` once per element, whose instructions
// initialize the element at the pack index (docs/design/variadics.md,
// "Pack expansion expressions and statements": "`...` in a tuple literal
// behaves like a series of comma-separated tuple elements").
struct PackSegmentInit {
  static constexpr auto Kind =
      InstKind::PackSegmentInit.Define<Parse::NodeId>(
          {.ir_name = "pack_segment_init",
           .expr_category = ExprCategory::ReprInitializing,
           .constant_kind = InstConstantKind::Never});

  // A `TupleType` whose only element is a `PackType`.
  TypeId type_id;
  AbsoluteInstBlockId body_block_id;
  DestInstId dest_id;
};
```

<!-- google-doc-style-resume -->

4.  sem_ir/typed_insts.h, `PackElement`: `.expr_category =
    ComputedExprCategory::SameAsFirstOperand`, and its `pack_id` may be a
    tuple of one pack segment, value or reference, whose element at the pack
    index it is (DR-43). Lowering reads it as `TupleAccess` reads an element,
    with the pack index as the constant index (the tuple's value
    representation, including the by-copy representation of a 1-tuple, is the
    tuple's, not a pack's).
5.  check/convert.cpp: converting a tuple literal (or a tuple value) whose
    only element is a value of pack type `⟬each T⟭` (or `«E; N»`) to
    initialize a tuple of the same one segment: push a block; add `PackIndex`,
    `PackElement(dest, index)` (a reference), `PackElement(source, index)` (a
    value) and the ordinary initialization of the first from the second
    (`Initialize`, which copies through the element type's `Copy`); require
    the block straight-line and without cleanups (VA-1's
    `FinishPackExpansionBody` rules, its TODOs reused); pop; add
    `PackSegmentInit{type, body, dest}`. Converting it to a value of the tuple
    type is the source's pack value (a pack value and a tuple value of the
    same element types have the same value representation, D-VA2-3, except a
    1-tuple's by-copy one, for which the conversion loads element 0). Any other
    pairing of a segment with elements is `context.TODO(loc_id, "tuple pack
    segment matched with other segments")` (W-215).
6.  check/pattern_match.cpp and check/handle_let.cpp (the `let`'s pattern): a
    `TuplePattern` whose only element is a `PackExpansionPattern` with fixed
    arity, matched against a scrutinee of a tuple type of one segment of the
    same pack type, binds the each-name to the value of `PackExpansionExpr{
    body: PackElement(scrutinee, PackIndex)}` (VA-1's expansion, whose storage
    holds each element's value, no copy); a pack expansion pattern of deduced
    arity in a `let` is `context.TODO(node_id, "pack expansion pattern with
    deduced arity outside a parameter list")` (W-214).
7.  lower/handle_pack_expansion.cpp: `HandleInst(PackSegmentInit)` gets the
    arity from the tuple type's segment in the specific, lowers the body once
    per element through `LowerPackExpansionBody`, and sets the result to the
    destination, as `TupleInit` does for in-place elements.

### §2.5 C3, statement expansions of `if` (specified, not built)

1.  check/handle_pack_expansion.cpp: at a statement `...`, after pushing the
    body block, `context.region_stack().PushRegion(body_block_id)`, so the
    blocks an `if` adds (control_flow.cpp:67, :87 `AddToRegion`) are the
    body's region, not the function's; at the end,
    `PopRegion()` returns them. The body's last block (the `if`'s merge block)
    ends with a new terminator `PackExpansionNext` (no operands, `Never`,
    "the end of one iteration"). `PackExpansionStatement{arity_id,
    body_block_id}` keeps its fields; `body_block_id` is the region's entry,
    and lowering finds the other blocks through the branches.
2.  `FinishPackExpansionBody`'s straight-line check accepts a body whose
    statement is an `if` statement (the parse tree's
    `PackExpansionStatement`'s body is an `IfStatement`), whose branches hold
    expression statements, `if` statements and `return` statements; a
    declaration, loop, `break`, `continue` or `match` anywhere in the body is
    the relabeled `pack expansion of a statement other than an expression or
    if statement`; control flow in an expression body keeps VA-1's `control
    flow in a pack expansion`; a cleanup keeps VA-1's cleanup TODO.
3.  lower/function_context.h, .cpp: `LowerPackExpansionBody` lowers iteration
    `k` by creating a fresh LLVM block for each SemIR block it reaches from the
    entry (a per-iteration block map, erased after the iteration like
    `pack_iteration_locals_`), and lowers `PackExpansionNext` as a branch to
    iteration `k + 1`'s entry, or, after the last iteration, to a fresh block
    in which the enclosing block's lowering continues. `return` in a branch is
    the function's return.
4.  The dominance verifier (sem_ir/dominance.cpp, VA-1's expansion scopes)
    treats the body region as nested in the expansion.

### §2.6 C4, the prelude (specified, not built)

core/prelude/copy.carbon, lines 50-71 replaced (the rest unchanged):

<!-- google-doc-style-ignore -->

```carbon
impl forall [... each T: Copy] (... each T) as Copy {
  fn Op(self) -> Self {
    let (... each x: each T) = self;
    return (... each x);
  }
}
```

<!-- google-doc-style-resume -->

core/prelude/operators/comparison.carbon, appended after the `IntLiteral`
impls (:54-60), with the comment that names the design:

<!-- google-doc-style-ignore -->

```carbon
// Equality and relational comparison for tuples, field-wise, with relational
// comparison lexicographical (docs/design/tuples.md, "Operations performed
// field-wise"; docs/design/expressions/comparison_operators.md, "Default
// implementations for basic types"). These must be provided in this library
// as tuples don't have any associated library of their own.
impl forall [... each T: Eq] (... each T) as EqWith(Self) {
  fn Equal(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each a != each b) {
      return false;
    }
    return true;
  }
  fn NotEqual(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each a != each b) {
      return true;
    }
    return false;
  }
}

impl forall [... each T: Ordered] (... each T) as OrderedWith(Self) {
  fn Less(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each a < each b) {
      return true;
    } else if (each b < each a) {
      return false;
    }
    return false;
  }
  fn LessOrEquivalent(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each a < each b) {
      return true;
    } else if (each b < each a) {
      return false;
    }
    return true;
  }
  fn Greater(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each b < each a) {
      return true;
    } else if (each a < each b) {
      return false;
    }
    return false;
  }
  fn GreaterOrEquivalent(self, other: Self) -> bool {
    let (... each a: each T) = self;
    let (... each b: each T) = other;
    ... if (each b < each a) {
      return true;
    } else if (each a < each b) {
      return false;
    }
    return true;
  }
}
```

<!-- google-doc-style-resume -->

Each element's comparison runs in order and stops at the first element that
decides (the statement executes "N times, with `$I` ranging from 0 to N - 1",
:305-306, and `return` leaves the function), as C++'s `std::tuple` comparisons
do (§A.7, §A.8): the four relational functions call only the elements' `<`,
`std::tuple`'s own rule ("`operator>` is `rhs < lhs`"), so a type whose `<`
and `>` disagree compares tuples by its `<` alone, and `Equal` and `NotEqual`
call only the elements' `!=`. Each function is written out, as OP-1 wrote
`Optional`'s (core/prelude/types/optional.carbon on PR 56), rather than
calling the impl's own `Less` through `OrderedWith(Self)` inside the impl's
definition. `Eq` and `Ordered` are the constraints of comparison.carbon :19-21
and :34-36. The empty tuple is equal to itself and not less than itself.

## §3 Commits (one PR, "VA-2: definition-checked variadics, slice 2", R29(b))

**D-VA2-19.** Five implementation commits, C1 to C5, each followed, when it
adds or changes goldens, by its own fill commit, then the row commit R and,
after the two implementation reviews and their fix commits, the discharge D;
at land time the commits M, F-M, L-F and L (D-VA2-18). Each implementation
commit builds on its own, and its gate is judged on the commit plus its fill,
the fork's practice since ST-1: an implementation commit alone is red on
exactly its new goldens and its listed refills, with no crash, and on nothing
else. The split of the prototype's one diff into C1 and C2 is by file and by
function, as §2.1 to §2.3 assign each hunk; the implementer checks that C1
builds without C2's hunks before writing C2 (§8.1). _Break condition:_ a
commit cannot build without a later commit's files, which merges the two and
is recorded in the landed notes.

**Fix commits and the shrink line.** The prototype, which is C1 and the built
half of C2, is 26 non-test toolchain files, +892/-105; VA-1's non-test
toolchain change from its C2 to its head is 43 files, +1682/-41 (`git diff
--shortstat 663a29df6 b0822a744 -- toolchain ':!toolchain/*/testdata/*'`).
VA-2 adds two instruction kinds (`PackSegmentInit`, `PackExpansionNext`)
against VA-1's eight, and about half of it has been built (§0.5). VA-1 used
three fix commits.
VA-2 budgets three fix commits after the first builds and the implementation
reviews, each its own commit with its own fill, never an amend. If C3 cannot
be made to pass §8.3 and §8.4 within that budget, the shrink line drops C3:
statement expansions of `if` stay VA-1's `pack expansion of a statement other
than an expression statement` (W-218 and W-219 keep their titles); the tuple
`EqWith` and `OrderedWith` impls, `variadics_min`, `tuple_eq`,
`tuple_ordered` and the comparison half of `tuple_impl_generic` move to a
residue from the reserved W-335 ("tuple `Eq` and `Ordered` as variadic impls,
needing statement expansions of `if`"); C4 lands the `Copy` impl alone; the
row "Stdlib: tuple/array library parts" keeps "no tuple Eq/Ordered" and W-225
is narrowed, not discharged. If C2's tuple values cannot be made to work
within the budget, the second shrink drops the `Copy` rewrite too (W-336,
"tuple `Copy` as a variadic impl, needing tuple values with a pack segment"),
C4 is not committed, and the stdlib row and W-225 stay as they are. Either
shrink is a plan revision the reviews see before it lands.

0.  **P, the plan.** Rev 1 (this commit), "VA-2 plan (rev 1): generic and
    heterogeneous packs, tuples with pack segments, variadic impls with the
    prelude tuple Copy, Eq and Ordered"; rev 2 folds the two plan reviews of
    R29(c), and a sign-off revision follows a dry re-review; each later
    revision is a new commit, each amended sentence marked "(amended <date>,
    review fold: <finding>)".
1.  **C1, packs of different types** (§2.1, §2.2: Appendix B's hunks in
    sem_ir/typed_insts.h, generic.h, generic.cpp, stringify.cpp,
    type_iterator.cpp's `PackElement` case; check/eval.cpp, eval.h,
    eval_inst.cpp's `PackElement` case, generic.cpp, type.h, type.cpp,
    context.h, handle_pack_expansion.cpp, handle_binding_pattern.cpp,
    deduce.cpp's `PackType` branch, convert.cpp's pack conversions,
    type_completion.cpp, import_ref.cpp, merge.cpp, pattern_match.cpp; the
    lower files), plus C1's own changes: the implicit-list TODO of F-3, the
    relabeled each-name binding TODO, the computed-element-type TODO, the
    `PackElement` stringify case. New goldens: check `hetero_pack`,
    `fail_hetero_pack`, `generic_pack`, `fail_todo_va2` (its C1 splits), lower
    `hetero_pack`; refilled: each_param, forward, import, fail_todo_slice
    (`fail_todo_generic_pack` removed, `fail_todo_ref_pack` relabeled) and the
    lower pack_expansion. Expected gate: red on exactly these 10 files.
2.  **F1.** Autoupdate of those 10 files to the fixpoint.
3.  **C2, tuples with a pack segment** (§2.3 built, §2.4 specified):
    `TupleType` and `TupleValue` conditional, the tuple deduction and
    type-structure hole, `ConvertTupleToType`, tuple literals with one
    segment, `PackSegmentInit`, `let` with a fixed-arity pack expansion
    pattern, the tuple TODOs. New goldens: check `tuple_segment`,
    `fail_todo_tuple_segment`, `impl`, `fail_impl`, lower `tuple_segment`;
    `fail_todo_va2` gains `fail_todo_initializing_element` and
    `fail_todo_var_pattern`; fail_todo_slice refilled (`fail_todo_tuple_pattern`
    and `fail_todo_tuple_literal` relabeled). Expected gate: red on exactly 7
    files.
4.  **F2.** Autoupdate of those 7 files.
5.  **C3, statement expansions of `if`** (§2.5): the body region,
    `PackExpansionNext`, per-iteration blocks. New goldens: check
    `expansion_if`, lower `expansion_if`; `fail_todo_va2` gains
    `fail_todo_if_with_declaration` and `fail_todo_while`; fail_todo_slice
    refilled (`fail_todo_statement_kind` relabeled). Expected gate: red on
    exactly 4 files.
6.  **F3.** Autoupdate of those 4 files.
7.  **C4, the prelude** (§2.6): core/prelude/copy.carbon :50-71 and
    core/prelude/operators/comparison.carbon. Expected gate: red on exactly
    M-9's 44 full-prelude goldens (43 check goldens by renamed SemIR names,
    toolchain/lower/testdata/for/bindings.carbon by its lowered tuple copy)
    and on nothing that includes a `min_prelude` other than `full.carbon`.
8.  **F4.** Autoupdate of those 44 files; a 45th is a finding (R-5).
9.  **C5, programs** (Appendix A): the nine programs and three `.diff.cpp`
    files, and fork/conformance/README.md's table regenerated by
    `runner.py --update-readme-table`. Expected: §8.4's totals.
10. **Implementation reviews** (two, R29(c)), then at most three fix commits
    by a separate fixer, each with its own fill, each named "VA-2 fix <n>:
    <subject>".
11. **R, the rows.** §A.11's text for "Generics: Definition-checked variadics"
    and "Stdlib: tuple/array library parts", quoting §8.4's container run,
    EXPECTED, not of record; both stay PARTIAL, so the header's counts do not
    move (§1.9).
12. **D, discharge** (§A.11): the ledger (W-212, W-213, W-225 discharged;
    W-214, W-218, W-219, W-222 narrowed; W-330 to W-334 filed; W-013's note),
    the decision-log entry, fork/ORCHESTRATION.md, the W6 sentence of
    fork/gap-analysis.md, after §8.10's id re-scan.
13. **Land time, when VA-2 is next** (D-VA2-18): M, the merge of trunk (a
    merge commit, `git merge --no-ff`, conflicts resolved by §6.2's rules);
    F-M, the fill the merged toolchain needs (autoupdate only); L-F, the
    README table and any program header that names a count, regenerated on
    the merged tree; L, the land-time records commit, re-quoting §8.8's run
    on the merge commit in the rows, the ledger and ORCHESTRATION.

Every commit uses explicit paths (R20, never `git add -A`), runs `SKIP=
fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
uvx prek run --files <its files>` to a fixpoint first, with R31's heading and
list-item counts before and after for each `.md`, and uses the author
`jmann345 <jerrymannstan@gmail.com>`, the committer `Claude
<noreply@anthropic.com>` (`GIT_COMMITTER_NAME=Claude
GIT_COMMITTER_EMAIL=noreply@anthropic.com`) and the session's attribution
trailers after a blank line, which this plan does not spell out because a
repository file names no model. A problem found after a commit exists is fixed
by a new commit (AGENTS.md). Fill commits are "Autoupdate testdata goldens on
the container arbiter". The other messages, verbatim but for `<...>` fields:

<!-- google-doc-style-ignore -->

```text
VA-2 C1: packs of different types in implicit parameter lists

A function or impl may declare `[... each T: I]` in its implicit
parameter list and take `... each x: each T`; a call deduces the pack of
argument types and their arity, checks each element's `I` by impl lookup,
and the body is checked once with `each x` of the symbolic type `each T`.
The pack index is a symbolic constant, so a specific of a variadic generic
evaluates its eval blocks once per element and lowers each iteration with
that element's types and callees; a pack of different types is laid out
as a tuple. A second implicit-list pack, a computed element type and a
template each-name are semantics TODOs. VA-1's goldens are refilled by the
next commit.

fork/variadics/va2-plan.md §2.1, §2.2, D-VA2-2 to D-VA2-7, D-VA2-13.
```

```text
VA-2 C2: tuples with one pack segment, `let` pack bindings, variadic impls

`(... each T)` is a tuple type of one pack segment, flattened once the
segment's arity is known, and deduced from a tuple argument; impl lookup
treats the segment as a hole, so `impl forall [... each T: I] (... each T)
as I` is selected for tuples of every arity. `(... each x)` initializes a
tuple element by element, and `let (... each x: each T) = t;` binds a pack
to a tuple's elements without copying. More than one segment, a segment
beside other elements and initializing expansion elements are semantics
TODOs.

fork/variadics/va2-plan.md §2.3, §2.4, D-VA2-8 to D-VA2-10.
```

```text
VA-2 C3: statement expansions of `if` statements

`... if (...) { ... } else ...` is checked once and lowered once per
element, each iteration with its own blocks, falling through to the next
iteration; `return` in a branch returns from the function. Declarations,
loops, `break`, `continue` and `match` in an expansion body stay semantics
TODOs.

fork/variadics/va2-plan.md §2.5, D-VA2-11.
```

```text
VA-2 C4: the prelude's tuple Copy, EqWith and OrderedWith as variadic impls

core/prelude/copy.carbon's four tuple Copy impls (arities 0 to 3, under
"TODO: Implement tuple copy as a variadic generic impl.") become one
`impl forall [... each T: Copy] (... each T) as Copy`, which copies each
element once by its own Copy. core/prelude/operators/comparison.carbon
gains tuple EqWith(Self) and OrderedWith(Self), field-wise and
lexicographical (docs/design/tuples.md; comparison_operators.md "Default
implementations for basic types"), for tuples whose elements are Eq or
Ordered.

fork/variadics/va2-plan.md §2.6, D-VA2-12.
```

```text
VA-2 C5: conformance programs for packs of different types and tuple impls

Nine programs: five for "Generics: Definition-checked variadics" (the
design's StrCat shape with a C++17 oracle, forwarding, the empty pack,
tuple-typed parameters and returns, the design's Min) and four for "Stdlib:
tuple/array library parts" (tuple Copy at arities 1, 2, 4 and 5 and nested,
equality and ordering against std::tuple, the impls through generic
requirements). The README table is regenerated.

fork/variadics/va2-plan.md Appendix A, D-VA2-16.
```

```text
VA-2 R: gap rows for slice 2, expected, not of record

"Generics: Definition-checked variadics" stays PARTIAL with slice 2 in its
evidence and a shorter "Not yet" list; "Stdlib: tuple/array library parts"
stays PARTIAL with the variadic tuple impls in its evidence and only
mixed-operand comparisons open, on the container run <run>
(fork/variadics/va2-plan.md §8.4), expected, not of record; the header's
counts do not move.
```

```text
VA-2 discharge: W-212, W-213 and W-225 discharged, W-330 to W-334 filed

W-013 stays open with slice 2 in its notes; W-214, W-218, W-219 and W-222
are narrowed; W-330 to W-334 are filed from fork/variadics/va2-plan.md
§1.11 and W-335 to W-339 stay unused. The decision-log entry "VA-2"
records D-VA2-1 to D-VA2-19, the rejected alternatives and the V-3a
register entries; ORCHESTRATION records the PR.
```

```text
VA-2 L: land-time records on the merge of trunk <sha>

The rows, the ledger's evidence and ORCHESTRATION re-quote the gate and
conformance run on the merge commit <sha> (<counts>), expected, not of
record.
```

<!-- google-doc-style-resume -->

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

Every line below is a prediction from the code of §2 and Appendix B and the
diagnostic strings in them, not a run, except where M-6 is cited; columns,
SemIR names and diagnostic kinds in brackets are the fill's to decide, and a
fill that contradicts a prediction is a finding for the implementation review,
never a reason to edit a golden (R16(a)). Sources are §A.10's. Directory
prefixes: `check/` is toolchain/check/testdata/variadics/, `lower/` is
toolchain/lower/testdata/variadics/.

| File (commit) | Split | Predicted key output |
| --- | --- | --- |
| check/hetero_pack.carbon (C1) | `call` | `ForEach`'s `fn_decl` with a `symbolic_binding_pattern T` of type `«%Code.type; %<pack arity>»` (a pack of facets), no second arity binding, and a value pack `x` of pattern type `⟬%T⟭` (printed by stringify as the pack type of `%T`); the body's `pack_expansion_statement` block holds `pack_index` (`[symbolic]`), `pack_element %T, %pack_index`, the facet access and the `Get` call through `%Code.lookup_impl_witness`; in `Call`, `ForEach(a, b, a)` passes a `pack_literal` of three converted to `⟬%A, %B, %A⟭`, and `ForEach()` an empty one; two specifics, `T` = `⟬%A, %B, %A⟭` (a `pack_value [concrete]`) and `⟬⟭` |
| (same) | `type_pack` | `Count(1 as i64, true)` deduces `T` = `⟬%i64, bool⟭` and the arity 2; no diagnostic |
| (same) | `forward` | `ForEach(... each y)`: a `pack_expansion_expr` of type `⟬%U⟭`, deducing `T` = `%U` and the arity from `U`'s; no `require_complete_type` diagnostic |
| (same) | `method` | `c.F(a, a)` with the bound `self` first and a 2-element `pack_literal`; `T` = `⟬%A, %A⟭` |
| (same) | `qualified_member` | as `call`'s body, with `.(Code.Get)` as the compound member access on the symbolic `each T` |
| check/fail_hetero_pack.carbon (C1) | `fail_missing_impl` | `error: cannot convert type `C` into type implementing `Code` [ConversionFailureTypeToFacet]` at `ForEach(a, c)`, with the generic parameter note; nothing else |
| (same) | `fail_missing_member` | `error: member name `Missing` not found in `Code`` at `each x.Missing`, at the definition (no call exists) |
| (same) | `fail_convert_element` | `error: cannot implicitly convert expression of type `each T` to `i64` [ConversionFailure]`, naming `each T` by C1's stringify case (§2.1) |
| (same) | `fail_each_type_not_pack` | `error: `each T` does not name a pack [EachNameNotPack]` (VA-1's diagnostic, unchanged) |
| (same) | `fail_two_explicit_packs` | `error: parameter list can contain at most one pack expansion pattern [MultiplePackExpansionPatterns]` with the `previous pack expansion pattern is here` note: the explicit list is a tuple pattern (:333-334) |
| check/generic_pack.carbon (C1) | `declaration` | VA-1's `fail_todo_generic_pack` source, now without a diagnostic (M-6: "succeeded; if success is expected, remove the `fail_` prefix") |
| (same) | `call` | `F(1 as i64, true, 2 as i32)` deduces `T` = `⟬%i64, bool, %i32⟭`; no diagnostic |
| check/fail_todo_va2.carbon (C1) | `fail_todo_two_implicit_packs` | `semantics TODO: `more than one pack expansion pattern in an implicit parameter list`` at the second `...`, and nothing for `U` |
| (same) | `fail_todo_computed_element_type` | `semantics TODO: `pack expansion pattern whose binding type is computed from an each-name`` at `Box(each T)` |
| (same) | `fail_todo_template_each` | `semantics TODO: `each-name binding that is ref, var or template`` |
| (same) | `fail_todo_each_auto` | `semantics TODO: `HandleAutoTypeLiteral`` (upstream's, unchanged) |
| (same, C2) | `fail_todo_initializing_element` | `semantics TODO: `pack expansion of initializing expressions in a tuple literal`` at the `...` of `(... each x.(Core.Copy.Op)())` |
| (same, C2) | `fail_todo_var_pattern` | `semantics TODO: `pack expansion pattern in a pattern other than a parameter list or let`` |
| (same, C3) | `fail_todo_if_with_declaration` | `semantics TODO: `pack expansion of a statement other than an expression or if statement`` at the `...`, and no UnusedBinding warning |
| (same, C3) | `fail_todo_while` | the same TODO |
| check/each_param.carbon (C1, refill) | every split | M-6's classes: `pack_index` gains `[symbolic]` and an eval-block entry; the pack type prints its renamed operand; no diagnostic |
| check/forward.carbon (C1, refill) | every split | as each_param |
| check/import.carbon (C1, refill) | `lib`, `use` | as each_param, and the imported `PackIndex` symbolic |
| check/fail_todo_slice.carbon (C1, refill) | `fail_todo_generic_pack` | removed (moved to generic_pack) |
| (same, C1) | `fail_todo_ref_pack` | `semantics TODO: `each-name binding that is ref, var or template`` |
| (same, C2) | `fail_todo_tuple_pattern` | `semantics TODO: `pack expansion pattern with deduced arity outside a parameter list`` |
| (same, C2) | `fail_todo_tuple_literal` | `semantics TODO: `tuple pack segment matched with other segments`` at the conversion of `(... each n)` to `(i64, i64)` |
| (same, C3) | `fail_todo_statement_kind` | `semantics TODO: `pack expansion of a statement other than an expression or if statement`` |
| (same) | every other split | unchanged |
| lower/hetero_pack.carbon (C1) | `call` | `ForEach`'s specific for `⟬A, B, A⟭` calls `A`'s `Get`, then `B`'s, then `A`'s, each on a constant GEP of a `{ ptr, ptr, ptr }` pack; the empty specific has no call |
| (same) | `layout` | `Count(1 as i64, true, 2 as i32)`'s caller stores an `i64`, an `i1` and an `i32` into a `{ i64, i1, i32 }` alloca and passes its address; the specific calls `One`'s three specifics (`i64`, `bool`, `i32`) in order |
| (same) | `forward` | `Forward`'s `⟬A, B⟭` specific passes its own pack's address to `ForEach`'s `⟬A, B⟭` specific |
| lower/pack_expansion.carbon (C1, refill) | `sum`, `generic_element`, `class_element`, `arg_order`, `forward_converted_field`, `lib`, `use` | M-6's classes: a `pack_value` of constants becomes a global constant (the `llvm.lifetime.start` declarations and per-call stores of constant packs disappear); every call and every iteration as before |
| check/tuple_segment.carbon (C2) | `param` | `F`'s parameter of type `(⟬%T⟭)`, a `tuple_type` whose one element is a pack type; `F((1 as i64, true))` deduces `T` = `⟬%i64, bool⟭`, and the specific's parameter type is `(%i64, bool)` |
| (same) | `return` | `MakeTuple`'s `return (... each x)` is a `pack_segment_init` into the return slot whose block holds `pack_index`, two `pack_element`s and the element's `Copy` initialization; `Call` returns the specific's result of type `(%i64, bool)` with no conversion |
| (same) | `let` | `let (... each x: each T) = t;` binds a `pack_expansion_expr` of `pack_element %t, %pack_index`, no copy, no arity binding; the statement expansion calls `Get` |
| (same) | `tuple_value` | `Take((... each x))` passes the pack value as a value of `(⟬%T⟭)`, deducing `U` = `%T` |
| (same) | `elements_around_segment` | `F((1 as i64, 2 as i32, false, true))` deduces `T` = `⟬%i32, bool⟭` (the run between `i64` and the last `bool`), and `F((1 as i64, true))` deduces `T` = `⟬⟭` |
| check/fail_todo_tuple_segment.carbon (C2) | `fail_todo_two_segments` | `semantics TODO: `tuple with more than one pack segment`` |
| (same) | `fail_todo_elements_beside_segment` | `semantics TODO: `tuple pack segment matched with other segments`` at the `return` |
| (same) | `fail_todo_segment_to_elements` | the same TODO at the `let` |
| check/impl.carbon (C2) | `select` | one `impl_decl` whose self type is `(⟬%T⟭)`; `t.(Count.N)()` and `e.(Count.N)()` find it, with `T` = `⟬%i64, bool⟭` and `⟬⟭`; no `ImplUnusedBinding` |
| (same) | `requirement` | `t.(Code.Get)()` on `(i64, (i64, i64))` finds the impl with `T` = `⟬%i64, (%i64, %i64)⟭`, whose second element's `Code` is the same impl with `T` = `⟬%i64, %i64⟭` |
| (same) | `generic_use` | `Use(t)` converts `(i64, bool)` to a facet of `Count` through the variadic impl's witness |
| (same) | `non_tuple_query` | `x.(Count.N)()` on `i64` selects `impl i64 as Count`; the variadic impl is a candidate by the type-structure hole and fails to deduce (M-9's correction, R-4); no diagnostic |
| (same) | `symbolic_query` | `t.(Count.N)()` on the symbolic `(⟬%T⟭)` in `H`'s body finds the variadic impl with `T` = `%T` (§0.2 p25) |
| (same) | `self_query` | `self.(Count.N)()` inside the impl's own `Twice` finds the impl being defined, as for any impl; no crash (M-9's first crash was this path) |
| (same) | `lib`, `use` | `use.carbon` imports the variadic impl and selects it for `(i64, bool, i64)`, its self type imported with its pack segment (R-7) |
| check/fail_impl.carbon (C2) | `fail_missing_element_impl` | `error: cannot access member of interface `Code` in type `(i64, bool)` that does not implement that interface [MissingImplInMemberAccess]` |
| (same) | `fail_not_a_tuple` | the same diagnostic for `Count` in type `i64`: the hole matches only a tuple's elements |
| (same) | `fail_unused_pack` | `error: `impl` with unused generic binding [ImplUnusedBinding]` |
| lower/tuple_segment.carbon (C2) | `make_tuple` | `MakeTuple`'s `⟬i64, bool, i32⟭` specific stores each element into the return slot's field 0, 1 and 2 in order, through each element type's `Copy` (a load and a store, the primitive copy) |
| (same) | `let` | `Sum`'s specific reads `t`'s three fields at constant indices, no alloca for the pack |
| (same) | `impl` | the impl's `Get` lowered for `⟬i64, (i64, i64)⟭` and for `⟬i64, i64⟭`, the first calling the second for its second element |
| (same) | `one_tuple` | `MakeTuple`'s `⟬i64⟭` specific returns the 1-tuple by its value representation, with the single element at index 0 |
| check/expansion_if.carbon (C3) | `if_else` | `pack_expansion_statement` whose body region holds the condition block, both branches and the merge block ending in `pack_expansion_next` |
| (same) | `else_if_return` | the region holds the `return` block, the `else if` blocks and the merge; the function's final `return 0` is outside it |
| (same) | `generic` | `AnyLess`'s body checked once against `T`; `each next.Lt(first)` through `Less`'s witness |
| (same) | `nested` | the inner `if`'s blocks are in the same region |
| lower/expansion_if.carbon (C3) | `first` | `First`'s arity-3 specific has three copies of the condition, branch and merge blocks, each iteration's merge branching to the next iteration's condition, the `return 1` block of each returning; the last merge branches to `return 0` |
| (same) | `min` | `Min`'s arity-2 specific compares and stores twice, in order |

Totals: 12 new files (9 check, 3 lower) and 5 refills; fail_todo_va2 and
fail_todo_slice change in C1, C2 and C3; C4 changes M-9's 44 full-prelude
goldens, 43 of them only by renamed SemIR names; no other golden changes
(§6.1).

## §5 Conformance delta (from PR 59's 137 PASS / 0 FAIL / 21 SKIP over 158, re-measured as M-5)

| Program | Before | After (stdout, §A) | Commit |
| --- | --- | --- | --- |
| generics/variadics_hetero_digits.carbon (+ .diff.cpp) | absent | PASS, C++ oracle agrees (6, 742074, 3, 422, 0, 0, 40293, 5) | C5 |
| generics/variadics_hetero_forward.carbon | absent | PASS (3, 1, 50, 0, 3, 0) | C5 |
| generics/variadics_hetero_empty.carbon | absent | PASS (0, 7, 3, 12, 33) | C5 |
| generics/variadics_tuple_param.carbon | absent | PASS (112, 4, 71, 0) | C5 |
| generics/variadics_min.carbon | absent | PASS (1, 5, 2, 2, 0, 0) | C5 |
| stdlib/tuple_copy_variadic.carbon | absent | PASS (4, 8, 101, 102, 2, 101, 1, 6, 13, 0) | C5 |
| stdlib/tuple_eq.carbon (+ .diff.cpp) | absent | PASS, C++ oracle agrees (1, 0, 1, 1, 0, 0, 1) | C5 |
| stdlib/tuple_ordered.carbon (+ .diff.cpp) | absent | PASS, C++ oracle agrees (1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0) | C5 |
| stdlib/tuple_impl_generic.carbon | absent | PASS (21, 22, 0, 21, 22, 23, 1, 1, 10) | C5 |

VA-2's own delta: PASS +9, programs +9, so 146 / 0 / 21 over 167 on this
branch. Both bullets are PASS already ("Generics: Definition-checked
variadics" by VA-1's nine programs, "Stdlib: tuple/array library parts" by
stdlib/tuples_arrays_structs.carbon; `$Q/conf_baseline/scoreboard.json`), so
the bullet count stays 49 PASS, 0 FAIL, 7 SKIP of 56. No existing program is
predicted to move: none requires `Core.Copy`, `Core.EqWith` or
`Core.OrderedWith` of a tuple (M-3, M-4), and M-9 runs the whole set against
the prototype with C4's declarations. The held PRs ahead of VA-2 move the
totals before it lands (each states its own expected count), so commit R
quotes §8.4's run on this branch and commit L quotes §8.8's run on the merge
commit, not this table's arithmetic.

## §6 Churn and collisions

### §6.1 Golden churn

Existing goldens that change, by commit:

-   C1 (F1): VA-1's each_param.carbon, forward.carbon, import.carbon,
    fail_todo_slice.carbon and the lower pack_expansion.carbon, in exactly
    M-6's three classes (measured: the prototype's autoupdate,
    `$Q/proto_golden_churn.diff`, 125 insertions and 145 deletions), plus
    fail_todo_slice's moved split and relabeled TODO.
-   C2 (F2) and C3 (F3): fail_todo_slice.carbon (two and one relabeled
    splits) and C1's new fail_todo_va2.carbon (two splits each).
-   C4 (F4): M-9's 44 full-prelude goldens (43 by renamed SemIR names,
    toolchain/lower/testdata/for/bindings.carbon by its lowered copy of an
    `(i32, i32)`), measured with C4's declarations and proxy bodies, so the
    real bodies may rename a few more names in the same files; no golden that
    includes another `min_prelude`
    file reads core/prelude (toolchain/testing/file_test.cpp:175-203: check
    and lower tests get `--no-include-carbon-core` unless a prelude include
    asks for the production prelude, which only min_prelude/full.carbon's
    `--expect-full-prelude` does, in 312 goldens).
-   Nothing else. M-6: the prototype, which holds every shared-code change of
    C1 and C2's built half, failed only VA-1's five goldens, because a
    `TupleType` or `TupleValue` without a pack element evaluates exactly as
    before (§2.3's invariant), pack types and pack indexes appear only beside
    a pack, and the new instruction kinds print only where a pack is. The new
    kinds of C2 and C3 (`PackSegmentInit`, `PackExpansionNext`) sit in VA-1's
    alphabetical block of sem_ir/inst_kind.def (:131-138), where dumps print
    names, not indexes.

A golden that changes anyway is refilled by the fill of the commit that
changed it and listed, with its cause, in the implementation review (§7 R-5).

### §6.2 Collisions with the held PRs and the merge rules

§0.6's table is the measurement for the prototype's files. The files C2 to C4
add beyond the prototype (check/handle_tuple_literal.cpp, pattern_match.cpp,
handle_let.cpp, control_flow.cpp, sem_ir/dominance.cpp, inst_kind.def,
inst_namer.cpp, formatter.cpp, lower/function_context.*,
lower/handle_pack_expansion.cpp, core/prelude/copy.carbon,
core/prelude/operators/comparison.carbon) were intersected with every held
head's changes since its merge base with b0822a744 (`git diff --name-only`):
only sem_ir/inst_kind.def (PR 60, PR 61, PR 64), inst_namer.cpp (PR 60) and
lower/function_context.cpp (PR 61, PR 64) are shared. inst_kind.def is
alphabetical and their kinds (`StructuralRequirementType`, `AddrOfAction`,
`IndexAction`, `PointerDereferenceAction`, `TupleIndexAction`) are not
adjacent to `PackExpansionNext` (after :132) or `PackSegmentInit` (after
:136); function_context.cpp merged cleanly with the prototype's hunks (§0.6),
and C3's hunk is inside VA-1's `LowerPackExpansionBody`, which no held PR
touches. Merge rules, applied by commit M and by every mirror (§8.7):

1.  convert.cpp, `ConvertTupleToType` (PR 61, PR 64): keep both changes,
    PR 61's `SpliceInst` redirect first, then VA-2's pack segment, since a
    spliced element is resolved before its type is examined.
2.  eval.cpp, `EvalContext`'s members (PR 61, PR 64): keep both members,
    PR 61's `diagnosed_non_constant_ids_` first.
3.  Records (fork/gap-analysis.md, fork/inventory/work-items.json,
    fork/decision-log.md, fork/ORCHESTRATION.md) and
    fork/conformance/README.md's table: regenerated or rewritten from the
    merged tree (`runner.py --update-readme-table`), never merged by hand.
4.  Any other conflict is a stop: the merge is redone on a scratch branch and
    reported, never resolved by taking one side of a toolchain file.

The semantic touch points, which no textual merge shows: SC-1 (PR 60) rewrites
requirement checking and impl lookup that the variadic impls go through
(impl_lookup.cpp, `TryGetSpecificWitnessIdForImpl`); TP-1 (PR 61) and CT-1
(PR 64) defer template-dependent operands in call.cpp, deduce.cpp and
convert.cpp beside VA-2's pack branches (W-224 keeps packs and templates
apart); OP-1 and OP-2 (PR 56, PR 57) add `Optional` comparisons that a tuple
of `Optional`s would use through the variadic impls; DR-1b's
`IndirectIndexWith` changes call.cpp's argument grouping beside VA-1's. Each
is covered by a mirror (§8.7).

### §6.3 The next upstream advance

VA-2 adds no file to the conflicted set the next advance already has beyond
VA-1's (VA-1 M-16: handle_pack_expansion.cpp, node_kind.def, typed_nodes.h and
upstream's pack_expansion.carbon), plus core/prelude/copy.carbon :50-71 if
upstream edits its tuple impls before then (it has not since the cut, M-1),
and the files of §2 that upstream changes for other reasons (eval.cpp,
deduce.cpp, impl_lookup.cpp's neighbors; M-1's table). The rule is VA-1's:
where upstream lands a representation of its own (a pack index, segmented
tuple types, its own variadic tuple impls), the advance takes upstream's
shapes and re-expresses VA-2's tests over them (D-VA2-2, D-VA2-8 and
D-VA2-12's break conditions); VA-2's goldens are refilled, never merged.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1. Per-iteration evaluation cost.** A specific whose eval blocks hold
    a `PackIndex` evaluates its declaration and definition blocks once per
    element (D-VA2-2), and each prelude tuple impl's specific does so for its
    tuple's arity. Falsified if the gate's wall time on this branch (M-5: 25
    seconds for 1960 files, 4 threads) rises by more than its run-to-run
    noise at §8.3, or a conformance program's compile time at §8.4 rises by
    more than a second against M-5's run.
-   **R-2. A symbolic pack index leaks into a concrete context.** A
    `PackIndex` that reaches lowering without an iteration (a constant looked
    up with no pack index) is a CARBON_CHECK in
    `GetConstantValueInSpecific`, never a silent wrong value; `PackElement`
    is `NotConstant` for a concrete operand pair that is not a `PackValue`
    and an `IntValue` (§2.1's invariant). Detected by the lower goldens and
    §8.4 on the fastbuild-like flags (checks on); falsified by any crash
    there.
-   **R-3. `TupleType` becomes conditional.** Every tuple type now goes
    through `EvalConstantInst(TupleType)`. M-6 measured no golden change and
    no conformance change on the prototype; a regression would show as
    churn outside §6.1 or a changed program, and is then a finding.
-   **R-4. The type-structure hole matches every query** (M-9). A tuple type
    with a segment is a symbolic hole of impl lookup's type structure
    (D-VA2-8), so once the prelude has variadic tuple impls, every lookup of
    `Copy`, `EqWith` or `OrderedWith` for any type deduces against them, and
    the prototype's deduction crashed on a non-tuple argument (M-9). C2
    corrects the deduction (a non-tuple argument fails to deduce, §2.3) and
    adds the goldens that exercise it (`fail_impl`'s `fail_not_a_tuple`,
    `impl`'s `non_tuple_query` and `import` splits); the cost of the extra
    candidate is R-1's. Falsified by a crash or a changed impl selection in
    §8.3 or §8.4.
-   **R-5. Unexpected golden churn.** A golden outside §6.1 changes. Detected
    by each fill's diff; listed with its cause in the implementation review
    before it is accepted.
-   **R-6. Impl ranking.** A user impl for one tuple type (`impl (A, B) as
    Copy`) beside the prelude's variadic impl: the concrete self type ranks
    above the hole, so the user's impl is selected, as for any more specific
    impl; a user impl `impl forall [T: type] T as Copy` overlaps every impl
    and is rejected as it is today. No program or golden of VA-2 defines a
    tuple impl beside the prelude's; the risk is recorded, not tested, and
    falsified by a selection the type structure does not predict.
-   **R-7. An imported variadic impl.** Every program imports the prelude's
    variadic impls from another library; M-9's second crash surfaced in such
    an importing library (char.carbon), from the deduction defect, and M-9
    measured the lowering of an imported variadic impl's functions failing.
    C2's `impl` golden gains `lib` and `use` splits (an impl defined in one
    library, selected in another) and C4's programs all exercise the import;
    falsified by any failure of those.
-   **R-8. `... if` lowering.** Per-iteration blocks are VA-2's first
    expansion body with control flow; an iteration that branches into a block
    of another iteration, or a block shared between iterations, is either a
    verifier failure (LLVM's, at lowering) or a wrong answer. The lower
    golden `expansion_if` and the programs `variadics_min`, `tuple_eq` and
    `tuple_ordered` (whose answers depend on which element decides) detect
    both; MV-6 (§8.5) proves they do.
-   **R-9. The 1-tuple's value representation.** A tuple of one element may
    be passed by copy where a pack of one is passed by address; D-VA2-9
    loads element 0 in that case, and the lower split `one_tuple` and
    `tuple_copy_variadic`'s `(Loud,)` case detect a mismatch.
-   **R-10. A prelude defect breaks every program.** C4 changes files every
    program compiles. Mitigated by C4's being the last toolchain-facing
    commit, by M-9's run of the whole conformance set against the prelude's
    declarations, and by §8.4; falsified by any existing program that
    changes status after C4.

### §7.2 Rejected alternatives

-   **A-1. A second checking path for packs of different types** (rejected,
    R17). Checking `⟬each T⟭` by its own instruction kinds and handlers
    beside VA-1's would duplicate deduction, conversion and lowering; the
    prototype generalizes VA-1's six entry points in place (§0.3) with one
    `PackType`. Falsified if a homogeneous and a heterogeneous pack need
    different code for the same operation, which the review checks.
-   **A-2. Hand-written tuple impls to a larger fixed arity** (rejected).
    Writing the `Copy`, `EqWith` and `OrderedWith` impls for arities 0 to 12
    would make 4- and 5-tuples work without variadics, leave the TODO in
    copy.carbon, implement no design rule, and fail at 13 elements;
    `tuple_copy_variadic` would pass, so the falsifier is a 13-tuple, which
    the hand-written set rejects and the variadic impl accepts (§8.5, MV-8).
-   **A-3. A pack-to-tuple shim** (rejected). Representing `... each x: each
    T` as one tuple parameter `x: (each T...)` and expanding by tuple
    indexing would make every element access a tuple projection and every
    call build a tuple, which copies elements that a value pack binds
    without copying (VA-1's D-VA-3); `variadics_no_copy`'s heterogeneous
    analogue would print the copies, which is its falsifier.
-   **A-4. Two packs now** (rejected for this slice). Independent arities
    (W-222) need per-pack arity bindings, the design's merge of segments and
    the same-arity check across packs; nothing in the prelude impls or
    StrCat needs them, and TupleConcat needs `...expand` too (W-217). Their
    TODO stays; falsified if an arbiter of §1.8 needs two packs.
-   **A-5. A specific per element** (rejected). Giving each iteration its own
    specific (a hidden generic per element) would make each element's
    callees ordinary specifics but multiply the specifics of every variadic
    call by its arity and give the pack index no constant value, against the
    design's "treated as a constant" (:300-303).
-   **A-6. Constant packs everywhere** (rejected). Making every `PackValue` a
    constant would make a run-time pack of values a constant too, which it is
    not; `WheneverPossible` is constant only when every element is.
-   **A-7. `return self;` as the tuple `Copy.Op`** (rejected, a spelling
    choice). On the corrected prototype it is rejected, "cannot copy value of
    type `«T; <pack arity>»`" (M-9): copying a tuple decomposes it into its
    elements, here one pack-typed element, which has no `Copy`. With C2 the
    same initialization becomes a `PackSegmentInit` (§2.4 item 5), so it
    would make exactly the chosen body's copies; the chosen body names each
    element's copy, as upstream's hand-written impls do, and exercises the
    `let` binding the slice adds. Falsified as a rejection if a review
    prefers the shorter spelling once C2 exists: the body may then change
    with no program output changing, which `tuple_copy_variadic` checks.
-   **A-8. `...and` for the equality impl** (rejected for this slice). `return
    ...and (each a == each b);` is the design's spelling (:307-312), but
    `...and` is VA-1's TODO (W-216, with `...or`), whose short-circuit is
    control flow inside an expression body (W-219); the `... if` statement
    form needs only D-VA2-11 and has the same semantics. When W-216 lands,
    the impl may be respelled; the programs pin the semantics either way.

## §8 Verification and discharge

Scripts are the carbonbuild set
(`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild`,
`$CB` below; its README describes each). Every build lives under
`/dev/shm/va2-<role>/` (`CB_BUILD_ROOT=/dev/shm/va2-<role>/builds`), is never
copied, and is deleted when its agent is done; before a full build, `pgrep -fa
'ninja|file_test'` is checked and a running build or gate of another workstream
is waited for, never competed with. No Bazel, no hosted CI, no workflow
dispatch, no owner runner (R28). Every run's command, exit status and log path
go into the implementation review's evidence and the landed notes.

### §8.0 The planner's measurements (done)

M-5 (the baseline), M-6 (the prototype's gate, churn and conformance), M-8
(build times) and M-9 (the prototype with C4's declarations) are the
planner's, on the planner's build of b0822a744 plus `$Q/va2_prototype.patch`;
M-10 (the C++ oracles) and M-11 (the programs and golden sources parsed and
checked on PR 59's install) need no build of this branch. The probes and
their outputs are `$Q/probes` and `$Q/logs`, M-9's are `$Q/m9`, the
programs, oracles and golden sources as written are `$Q/programs`,
`$Q/oracles` and `$Q/goldens`.

### §8.1 Build (implementer)

After C1, C2 and C3: `$CB/build.sh /home/user/carbon-va2` then
`$CB/install.sh /home/user/carbon-va2`, with `CB_BUILD_ROOT` as above. Each of
the three edits sem_ir/typed_insts.h or inst_kind.def, which most objects
include, so each is a full build (M-8: about 6 minutes on 4 cores when the
machine is otherwise idle); C4 and C5 change no C++ and need only
`install.sh`, which copies core/ into the install (install.py :100-110).
Before C2 is written, C1's tree alone is built (§3's split check); 0
warnings with the build's `-Werror` set.

### §8.2 Autoupdate to its fixpoint (implementer)

After each build with new or changed goldens: `$CB/autoupdate.sh
/home/user/carbon-va2 <the commit's goldens>`, then the same command again,
which must change nothing but `.loc` numbers (R26; a second run that changes
more is a stop, diagnosed before a third). Each fill's diff is reviewed
against §4 before the fill commit; a contradiction is a finding, never an
edit.

### §8.3 Gate (implementer)

`$CB/gate.sh /home/user/carbon-va2`. Expected, all passing: 1960 (M-5) before
C1; 1965 after F1 (five new files); 1970 after F2 (five more); 1972 after F3
(two more); 1972 after C4 and F4 (44 refills) and after C5. Each
implementation commit alone is red on exactly §3's listed files and nothing
else, with no crash. The gate's wall time is compared with M-5's 25 seconds
(R-1).

### §8.4 Conformance (implementer)

`XDG_CACHE_HOME=<a private directory> $CB/conformance.sh
/home/user/carbon-va2 <a private output directory>` after C5: expected PASS
146, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0,
DIFF-MISMATCH 0, SKIP 21 (of 167), bullets 49 PASS, 0 FAIL, 7 SKIP of 56, the
nine programs of §5 PASS with §A's outputs, and the three `.diff.cpp` oracles
compile with the toolchain's own clang++ and agree. Also after C4 alone (before
C5): 137 / 0 / 21 over 158, unchanged (R-10). Commit R quotes the C5 run,
EXPECTED, not of record.

### §8.5 Mutants that prove the programs are not vacuous (implementer)

One mutant per decision that a program can see, each applied to the C5 tree
in the worktree, rebuilt incrementally in the same build directory (never a
copied one), run against the nine programs and VA-1's nine, then reverted and
rebuilt; MV-7 and MV-8 change only the prelude and need only `install.sh`.
Each must turn at least the listed programs red, and the result is recorded
per program.

| Mutant | Decision | Change | Predicted to fail |
| --- | --- | --- | --- |
| MV-1 | D-VA2-7 | lower/function_context.cpp: `GetValue` looks up constants without the pack index (`std::nullopt` for `current_pack_index()`) | variadics_hetero_digits, variadics_hetero_forward, tuple_impl_generic (a lowering CHECK or a wrong callee) |
| MV-2 | D-VA2-2 | check/eval.cpp: `TryEvalPackIterationsForSpecific` evaluates every iteration with pack index 0 | variadics_hetero_digits (first line 8, not 6), variadics_hetero_forward |
| MV-3 | D-VA2-5 | check/deduce.cpp: the deduced `PackValue` of argument types built from `llvm::reverse(element_ids)` | variadics_hetero_digits and variadics_hetero_forward (COMPILE-FAIL: an argument converted to another's type) |
| MV-4 | D-VA2-8 | check/deduce.cpp, the `TupleType` case: the run drops its last element | variadics_tuple_param, tuple_copy_variadic, tuple_eq (COMPILE-FAIL) |
| MV-5 | D-VA2-9 | lower/handle_pack_expansion.cpp: `PackSegmentInit` lowers its body for iteration 0 only | tuple_copy_variadic (101 without 102), variadics_tuple_param (71) |
| MV-6 | D-VA2-11 | lower: `PackExpansionNext` of every iteration branches past the last iteration | variadics_min (`Min(4, 9, 2, 2, 7)` prints 4), tuple_eq (`a == c` prints 1), tuple_ordered |
| MV-7 | D-VA2-12 | comparison.carbon: `Less`'s final `return false;` becomes `return true;` | tuple_ordered (`a < c` prints 1), tuple_impl_generic is unaffected |
| MV-8 | A-2 | copy.carbon: the variadic impl replaced by hand-written impls for arities 0 to 12 | tuple_copy_variadic (COMPILE-FAIL at the 13-tuple) |

### §8.6 prek, clang-tidy and R31 (every agent, every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
uvx prek run --files <the commit's files>` to a fixpoint with a private
`XDG_CACHE_HOME`; for each `.md`, R31's heading and list-item counts before and
after (`python3 -I
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5/bin/r31.py
<file>`) and the diff grepped for manufactured headings. clang-tidy, for every
implementation and fix commit (R21, R22), as VA-1's §8.6: LLVM 21.1.8's
`/home/user/llvm/bin/clang-tidy` over every changed `.cpp` with the build's
flags, once with `--checks='-*,misc-no-recursion' --warnings-as-errors='*'`
unfiltered and once with the repository's .clang-tidy minus `modernize-*`,
line-filtered to the commit's lines; every diagnostic is fixed in the next fix
commit, none suppressed by a new `NOLINT`. Before C5's commit and before each
fix commit that touches programs: `python3 fork/conformance/runner.py
--self-test`, expected "167 programs parsed, 56 bullets in table, OK" (158 on
this branch before C5).

### §8.7 Composition mirrors (implementer, before the implementation reviews)

Each mirror is a scratch worktree under `/dev/shm/va2-<role>/mirror-<pr>`
(`git worktree add --detach` of the held head, then `git merge --no-ff` of
VA-2's head, conflicts resolved by §6.2's rules), built, gated and run
through conformance with a private cache, then removed with `git worktree
remove` and its build deleted:

-   PR 59 plus PR 61 (tp, 5661a35c8): templates with packs. Expected: every
    golden of both passes after the mirror's own fill; p16, p17 and p18 of
    §0.2 as on PR 59 (p18 the template each-name TODO, now relabeled); TP-1's
    and VA-2's programs all PASS.
-   PR 60 (sc, 40a76ab81): requirement checking and impl lookup beside the
    variadic impls. Expected: both sets of goldens and programs pass.
-   PR 62 (sv, 0ef8a0334) and PR 64 (ct, 4a3220c11, stacked on PR 61):
    convert.cpp and eval.cpp beside VA-2's. Expected as above.

A mirror is evidence for the implementation review, not a commit; a failure
in one is a finding against whichever side the review assigns it to.

### §8.8 Re-verification on the merge commit (land time)

After commit M (D-VA2-18): §8.1 to §8.4 again on the merge commit, with the
refills the merged branches cause committed as F-M; the totals become trunk's
floor plus §5's delta, and commit L quotes that run, EXPECTED, not of record.

### §8.9 Not run, and why

-   The unbuilt half of the slice: tuple values with a run-time pack segment
    (`PackSegmentInit`), `let` with a pack expansion pattern, statement
    expansions of `if` (`PackExpansionNext`, the per-iteration blocks), the
    prelude's real bodies, the twelve new goldens and their TODO texts, and
    every program of Appendix A. §0.2's proto column and M-9 measure what the
    prototype does; every other output in this plan is a prediction (§4) or
    a hand derivation (§A).
-   Forwarding a pack of different types (`ShowAll(... each y)`), which
    §A.2 and §A.3 need: the prototype's deduction branch exists (§2.2), but
    no probe ran it.
-   Lowering a variadic impl's functions: M-9 measured that the prototype
    selects the impls but crashes or emits invalid IR lowering their
    specifics; C2's lowering is unbuilt, so every runtime output of §A.6 to
    §A.9 is a derivation.
-   The mutants of §8.5 and the mirrors of §8.7: they need C5's tree.
-   clang-tidy: the planner's prototype was built with `-Werror` (0
    warnings, M-8) but not run through clang-tidy.
-   Bazel-only tests (gtest unit tests, the diagnostics coverage test, lit
    tests, fuzzers): not part of the container gate; they run only on hosted
    CI, which is disabled on the fork.
-   Hosted CI and an optimized build: the container builds the fastbuild-like
    configuration only.
-   The planner's build (`/dev/shm/va2-planner`) was deleted when this plan
    was written; the prototype is reproducible from
    `$Q/va2_prototype.patch` on b0822a744.

### §8.10 Id re-scan (before commit D)

Over every ref of /home/user/carbon-lang after `git fetch origin`, and the
`fork/` trees of every /home/user/carbon-* worktree:

<!-- google-doc-style-ignore -->

```sh
cd /home/user/carbon-lang
refs=$(git for-each-ref --format='%(refname)' \
  'refs/heads/claude/carbon-fork-0-1-*' \
  'refs/remotes/origin/claude/carbon-fork-0-1-*' \
  refs/heads/trunk refs/remotes/origin/trunk)
for r in $refs; do git grep -hoE 'W-[0-9]{3}' $r -- fork; done | sort -u | tail -3
for r in $refs; do git grep -lE 'W-3[3-9][0-9]\b' $r -- fork; done
for d in /home/user/carbon-*/fork; do grep -rlE 'W-3[3-9][0-9]\b' "$d"; done
```

<!-- google-doc-style-resume -->

Expected: W-330..W-339 named only by this plan and by DR-1's "no id from
W-330 to W-399" (header); if another workstream has filed one of them, D
re-allocates from the maximum plus one, skipping reserved blocks, and §A.11's
ids are renumbered in D's commit, never in source.

## Hand-off notes for the implementer

1.  **Start from the prototype.** `git apply $Q/va2_prototype.patch` on
    b0822a744 reproduces §0.5's tree; split it into C1 and C2's built half by
    §2.1 to §2.3, then add C1's own changes (F-3's TODO, the relabels, the
    stringify case) before C1's fill, and in C2 M-9's deduction correction
    (§2.3) with the `fail_impl` and `impl` splits that exercise it.
2.  **What to run first after each build:** C1: §0.2's p02, p12, p14, p15;
    C2: p19, p24, p24b, p25, p26 and the `tuple_segment` golden; C3: the
    design's Min (§A.5); C4: p20, p20c, p09, p10 (now compiling and running)
    and p23 (still an error, W-334); then every program of Appendix A.
3.  **Fills are separate commits**, to their fixpoint, reviewed against §4.
4.  **Watch-outs.** The type-structure hole makes the prelude's variadic
    impls candidates for every query (R-4); a non-tuple argument must fail
    deduction, never walk a tuple's operands; a symbolic `PackIndex` must
    never reach lowering without an iteration (R-2); `PackSegmentInit` and
    `PackExpansionNext` sit in VA-1's alphabetical block of inst_kind.def;
    the prelude's tuple impls ask only for their elements' impls, never for
    `Self`'s (A-7); min_prelude's copy.carbon is not touched.
5.  **Records only in R and D.** No W-id appears in source, goldens or
    program headers; fork comments name decisions (`D-VA2-n`).
6.  **R31.** Code in this plan and in any record text sits between
    `<!-- google-doc-style-ignore -->` and `<!-- google-doc-style-resume -->`
    lines.

## Appendix A. Conformance programs, golden sources and records

Every program is written to `fork/conformance/programs/<path>` by C5, verbatim.
Each was parsed by the planner with PR 59's install (`carbon
compile --phase=parse`, all nine parse), and the four stdlib programs, which use
no pack syntax, were checked there too (M-11); none was run, since none can
compile before C4. EXPECT lines are derived from the program text and the design
(R16(d)), never from a run.

### §A.1 `generics/variadics_hetero_digits.carbon`

Derived from the program text (DIFF-1, no EXPECT-STDOUT): `Cat(a, b, c, d)` has
`T` = `⟬Two, One, Two, One⟭`, prints the width 2 + 1 + 2 + 1 = 6 and returns
((((0 · 100 + 74) · 10 + 2) · 100 + 7) · 10 + 4) = 742074; `Cat(d, e)` prints
1 + 2 = 3 and returns 4 · 100 + 22 = 422; `Cat()` prints 0 and returns 0; `Sum`
of -7, 300 and 40000 is 40293; `Sum(5 as i32)` is 5. Stdout: 6, 742074, 3, 422,
0, 0, 40293, 5. The oracle, compiled by the planner with LLVM 21.1.8's
`clang++ -std=c++17 -Wall -Wextra -Werror -stdlib=libc++` and run (M-10), prints
exactly these lines.

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
//
// Differential pair: variadics_hetero_digits.diff.cpp computes the same
// values with C++17 function templates over parameter packs of different
// types, whose comma folds evaluate left to right as Carbon's statement
// expansions execute their bodies once per element in order
// (docs/design/variadics.md, "Execution Semantics"), so C++ is the oracle for
// every printed line (no EXPECT-STDOUT). Cat has the shape of the design's
// StrCat ("Additional examples"): a pack of different types that each
// implement a local interface, one expansion summing the elements' widths and
// a second appending each element's digits, so the elements' order is visible
// in the digits. Sum takes integers of three widths, each converted to i64 by
// its own type's conversion.

import Core library "io";

interface Digits {
  fn Width(self) -> i64;
  fn Value(self) -> i64;
}

class One {
  var v: i64;
}

impl One as Digits {
  fn Width(unused self) -> i64 { return 1; }
  fn Value(self) -> i64 { return self.v; }
}

class Two {
  var v: i64;
}

impl Two as Digits {
  fn Width(unused self) -> i64 { return 2; }
  fn Value(self) -> i64 { return self.v; }
}

fn Pow10(n: i64) -> i64 {
  var result: i64 = 1;
  var i: i64 = 0;
  while (i < n) {
    result = result * 10;
    i = i + 1;
  }
  return result;
}

fn Cat[... each T: Digits](... each d: each T) -> i64 {
  var width: i64 = 0;
  ... width += each d.Width();
  Core.Print(width as i32);
  var result: i64 = 0;
  ... result = result * Pow10(each d.Width()) + each d.Value();
  return result;
}

fn Sum[... each T: Core.ImplicitAs(i64)](... each x: each T) -> i64 {
  var total: i64 = 0;
  ... total += each x as i64;
  return total;
}

fn Run() -> i32 {
  let a: Two = {.v = 74};
  let b: One = {.v = 2};
  let c: Two = {.v = 7};
  let d: One = {.v = 4};
  let e: Two = {.v = 22};
  Core.Print(Cat(a, b, c, d) as i32);
  Core.Print(Cat(d, e) as i32);
  Core.Print(Cat() as i32);
  Core.Print(Sum(-7 as i8, 300 as i16, 40000 as i32) as i32);
  Core.Print(Sum(5 as i32) as i32);
  return 0;
}
```

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of variadics_hetero_digits.carbon: each Carbon
// function over a pack of different types is a function template over a
// parameter pack, each statement expansion `... body;` is a comma fold
// `((body), ...)`, whose operands are evaluated left to right, and each
// interface implementation is a member function of the struct.
// printf("%d\n", ...) mirrors Core.Print's lowering.

#include <cstdint>
#include <cstdio>

struct One {
  int64_t v;
  auto Width() const -> int64_t { return 1; }
  auto Value() const -> int64_t { return v; }
};

struct Two {
  int64_t v;
  auto Width() const -> int64_t { return 2; }
  auto Value() const -> int64_t { return v; }
};

static auto Pow10(int64_t n) -> int64_t {
  int64_t result = 1;
  for (int64_t i = 0; i < n; ++i) {
    result *= 10;
  }
  return result;
}

template <typename... T>
static auto Cat(T... d) -> int64_t {
  int64_t width = 0;
  ((width += d.Width()), ...);
  std::printf("%d\n", static_cast<int>(width));
  int64_t result = 0;
  ((result = result * Pow10(d.Width()) + d.Value()), ...);
  return result;
}

template <typename... T>
static auto Sum(T... x) -> int64_t {
  int64_t total = 0;
  ((total += static_cast<int64_t>(x)), ...);
  return total;
}

auto main() -> int {
  Two a{74};
  One b{2};
  Two c{7};
  One d{4};
  Two e{22};
  std::printf("%d\n", static_cast<int>(Cat(a, b, c, d)));
  std::printf("%d\n", static_cast<int>(Cat(d, e)));
  std::printf("%d\n", static_cast<int>(Cat()));
  std::printf("%d\n", static_cast<int>(Sum(static_cast<int8_t>(-7),
                                           static_cast<int16_t>(300),
                                           static_cast<int32_t>(40000))));
  std::printf("%d\n", static_cast<int>(Sum(static_cast<int32_t>(5))));
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.2 `generics/variadics_hetero_forward.carbon`

EXPECT, derived in the header: 3, 1, 50, 0 (the forwarded pack's codes in
order), nothing for `Forward()`, then 3 and 0.

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   1
//   50
//   0
//   3
//   0
//
// A pack of different types is forwarded with `... each y`, which deduces the
// callee's pack of types from the caller's (docs/design/variadics.md,
// "Typechecking pattern matches"): Forward(3 as i32, true, 50 as i32, false)
// passes its four elements to ShowAll, whose statement expansion prints each
// element's code in order, i32's code being its value and bool's 1 or 0: 3,
// 1, 50, 0. Forward() forwards an empty pack and prints nothing. Count adds
// One's result once per element, each call a specific of One for that
// element's type: Count(true, 2 as i32, false) is 3 and Count() is 0.

import Core library "io";

interface Show {
  fn Code(self) -> i32;
}

impl i32 as Show {
  fn Code(self) -> i32 { return self; }
}

impl bool as Show {
  fn Code(self) -> i32 {
    if (self) {
      return 1;
    }
    return 0;
  }
}

fn ShowAll[... each T: Show](... each x: each T) {
  ... Core.Print(each x.Code());
}

fn Forward[... each U: Show](... each y: each U) {
  ShowAll(... each y);
}

fn One[V: type](unused v: V) -> i32 {
  return 1;
}

fn Count[... each T: type](... each x: each T) -> i32 {
  var n: i32 = 0;
  ... n += One(each x);
  return n;
}

fn Run() -> i32 {
  Forward(3 as i32, true, 50 as i32, false);
  Forward();
  Core.Print(Count(true, 2 as i32, false));
  Core.Print(Count());
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.3 `generics/variadics_hetero_empty.carbon`

EXPECT, derived in the header: 0, 7, 3, 12, 33.

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   7
//   3
//   12
//   33
//
// An empty pack of types has arity 0 and runs no iteration
// (docs/design/variadics.md, "Execution Semantics"): Count() is 0, printed
// before the 7 printed between the calls, and Count(true, 1 as i64, false)
// counts three elements of two types. Around's fixed parameters take the
// first and the last argument and its pack the run between them ("Pattern
// matching"): Around(1, 2) has an empty pack, so (1 + 0) * 10 + 2 is 12;
// Around(1, true, 2 as i64, 3) has the pack (true, 2 as i64), forwarded to
// Count, so (1 + 2) * 10 + 3 is 33.

import Core library "io";

fn One[V: type](unused v: V) -> i32 {
  return 1;
}

fn Count[... each T: type](... each x: each T) -> i32 {
  var n: i32 = 0;
  ... n += One(each x);
  return n;
}

fn Around[... each T: type](first: i32, ... each x: each T, last: i32) -> i32 {
  return (first + Count(... each x)) * 10 + last;
}

fn Run() -> i32 {
  Core.Print(Count());
  Core.Print(7);
  Core.Print(Count(true, 1 as i64, false));
  Core.Print(Around(1, 2));
  Core.Print(Around(1, true, 2 as i64, 3));
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.4 `generics/variadics_tuple_param.carbon`

EXPECT, derived in the header: 112, 4, 71, 0.

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   112
//   4
//   71
//   0
//
// A tuple type of one pack segment, `(... each T)`, is a parameter's type and
// a return type (docs/design/variadics.md, "Tuples, packs, segments, and
// shapes"), as in the signatures of the design's Apply and TupleConcat, here
// without `...expand`. SumTuple deduces its pack of types from its argument's
// tuple type and binds the elements with `let (... each x: each T) = t;`
// ("Pack expansion patterns"): (100, 10, 2) of types (i32, i64, i16) sums to
// 112. MakeTuple returns `(... each x)`, the tuple of its arguments ("`...` in
// a tuple literal behaves like a series of comma-separated tuple elements"):
// SumTuple(MakeTuple(1 as i32, 3 as i64)) is 4, and MakeTuple(70 as i32,
// true, 1 as i32) is an (i32, bool, i32) whose elements 0 and 2 sum to 71. The
// empty tuple has an empty pack: SumTuple(()) is 0.

import Core library "io";

fn SumTuple[... each T: Core.ImplicitAs(i64)](t: (... each T)) -> i64 {
  let (... each x: each T) = t;
  var total: i64 = 0;
  ... total += each x as i64;
  return total;
}

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Run() -> i32 {
  let t: (i32, i64, i16) = (100, 10, 2);
  Core.Print(SumTuple(t) as i32);
  Core.Print(SumTuple(MakeTuple(1 as i32, 3 as i64)) as i32);
  let u: (i32, bool, i32) = MakeTuple(70 as i32, true, 1 as i32);
  Core.Print(u.0 + u.2);
  Core.Print(SumTuple(()) as i32);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.5 `generics/variadics_min.carbon`

EXPECT, derived in the header: 1, 5, 2, 2, 0, 0. `Core.Destroy` is in `Min`'s
bound because `var result: T` is destroyed at the end of the function, as the
fork's generic programs bound such a `T`
(error_handling/question_generic_thread_diff.carbon :121).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   5
//   2
//   2
//   0
//   0
//
// The design's Min (docs/design/variadics.md, "Additional examples"), with
// the prelude's `Core.Ordered & Core.Copy & Core.Destroy` for the design's
// `Comparable & Value`: a statement expansion whose body is an `if`
// statement, executed once per element in order ("A statement of the form
// `...` statement is evaluated by executing statement N times"). Min(3, 1, 2)
// is 1, Min(5) is 5 with no iteration, and Min(4, 9, 2, 2, 7) is 2. Find
// returns the 1-based position of the first element equal to its target,
// leaving the function from an iteration's branch, and counts in the `else`
// branch: Find(2, 5, 2, 2) is 2 (the third element is never compared), and
// Find(9, 1, 2) and Find(1) are 0.

import Core library "io";

fn Min[T: Core.Ordered & Core.Copy & Core.Destroy](first: T, ... each next: T)
    -> T {
  var result: T = first;
  ... if (each next < result) {
    result = each next;
  }
  return result;
}

fn Find(target: i32, ... each x: i32) -> i32 {
  var pos: i32 = 0;
  ... if (each x == target) {
    return pos + 1;
  } else {
    pos = pos + 1;
  }
  return 0;
}

fn Run() -> i32 {
  Core.Print(Min(3 as i32, 1 as i32, 2 as i32));
  Core.Print(Min(5 as i32));
  Core.Print(Min(4 as i32, 9 as i32, 2 as i32, 2 as i32, 7 as i32));
  Core.Print(Find(2, 5, 2, 2));
  Core.Print(Find(9, 1, 2));
  Core.Print(Find(1));
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.6 `stdlib/tuple_copy_variadic.carbon`

EXPECT, derived in the header: 4, 8, 101, 102, 2, 101, 1, 6, 13, 0. That `let p:
(Loud, Loud) = (l1, l2);` copies nothing is measured (§0.2 p22: binding a tuple
of `Loud` values with `let` printed no copy on all three toolchains); every
printed copy is the impl's. On PR 59's install the program fails exactly at the
four `Dup` calls of tuples of arity 4, 5, 13 and of the nested tuple (`cannot
convert type ... into type implementing Core.Copy`), and nowhere else (M-11).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   8
//   101
//   102
//   2
//   101
//   1
//   6
//   13
//   0
//
// A tuple whose element types are all `Core.Copy` is `Core.Copy` itself, by
// the prelude's variadic impl (core/prelude/copy.carbon), whatever its arity,
// and its `Op` copies each element once, in order, by the element's own
// `Copy` (docs/design/tuples.md, "Operations performed field-wise"). Dup
// requires `Core.Copy` and calls `Op`; binding a tuple with `let` copies
// nothing. A 4-tuple and a 5-tuple of mixed element types copy (4, then 8);
// a (Loud, Loud) copies each element once, printing 101 and 102, then its
// copy's second field, 2; a (Loud,) prints 101, then 1; a tuple of tuples
// copies through the same impl at each level (6); a 13-tuple copies (13),
// beyond any fixed set of hand-written impls; the empty tuple copies with no
// output, and then 0 is printed.

import Core library "io";

class Loud {
  var a: i32;
}

impl Loud as Core.Copy {
  fn Op(self) -> Self {
    Core.Print(100 + self.a);
    return {.a = self.a};
  }
}

fn Dup[T: Core.Copy](x: T) -> T {
  return x.(Core.Copy.Op)();
}

fn Run() -> i32 {
  let t: (i32, i32, i32, i32) = (1, 2, 3, 4);
  Core.Print(Dup(t).3);
  let f: (i32, i64, bool, i32, i32) = (5, 6, true, 7, 8);
  Core.Print(Dup(f).4);
  let l1: Loud = {.a = 1};
  let l2: Loud = {.a = 2};
  let p: (Loud, Loud) = (l1, l2);
  let q: (Loud, Loud) = Dup(p);
  Core.Print(q.1.a);
  let one: (Loud,) = (l1,);
  Core.Print(Dup(one).0.a);
  let n: ((i32, i32), (i32, i32, i32, i32)) = ((1, 2), (3, 4, 5, 6));
  Core.Print(Dup(n).1.3);
  let big: (i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32) =
      (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
  Core.Print(Dup(big).12);
  let e: () = ();
  Dup(e);
  Core.Print(0);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.7 `stdlib/tuple_eq.carbon`

Derived (DIFF-1): `a == b` 1, `a == c` 0 (the middle element), `a != c` 1, `e1
== e2` 1, `n == m` 0 (the inner tuple's second element), `n != n2` 0, `w ==
w2` 1. Stdout: 1, 0, 1, 1, 0, 0, 1; the oracle prints exactly these (M-10). On
PR 59's install the program fails exactly at its seven comparisons (M-11).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
//
// Differential pair: tuple_eq.diff.cpp compares the same values with
// std::tuple's operator== and operator!=, which compare element by element,
// as Carbon's tuple equality does (docs/design/tuples.md, "Operations
// performed field-wise"; docs/design/expressions/comparison_operators.md,
// "Default implementations for basic types"), so C++ is the oracle for every
// printed line (no EXPECT-STDOUT). The prelude's variadic impl makes a tuple
// `EqWith` itself when every element type is `Eq`: elements of three types, a
// tuple that differs in its middle element, the empty tuple, a tuple of
// tuples (the impl used again for the inner tuple) and a 5-tuple.

import Core library "io";

fn Show(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Run() -> i32 {
  let a: (i32, i64, bool) = (1, 2, true);
  let b: (i32, i64, bool) = (1, 2, true);
  let c: (i32, i64, bool) = (1, 3, true);
  Show(a == b);
  Show(a == c);
  Show(a != c);
  let e1: () = ();
  let e2: () = ();
  Show(e1 == e2);
  let n: ((i32, i32), i32) = ((1, 2), 3);
  let m: ((i32, i32), i32) = ((1, 4), 3);
  Show(n == m);
  let n2: ((i32, i32), i32) = ((1, 2), 3);
  Show(n != n2);
  let w: (i32, i32, i32, i32, i32) = (1, 2, 3, 4, 5);
  let w2: (i32, i32, i32, i32, i32) = (1, 2, 3, 4, 5);
  Show(w == w2);
  return 0;
}
```

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of tuple_eq.carbon: each Carbon tuple is a
// std::tuple of the same element types, and `==` and `!=` are std::tuple's,
// which compare element by element. printf("%d\n", ...) mirrors Core.Print's
// lowering.

#include <cstdint>
#include <cstdio>
#include <tuple>

static auto Show(bool b) -> void { std::printf("%d\n", b ? 1 : 0); }

using Pair = std::tuple<int32_t, int32_t>;
using Five = std::tuple<int32_t, int32_t, int32_t, int32_t, int32_t>;

auto main() -> int {
  std::tuple<int32_t, int64_t, bool> a{1, 2, true};
  std::tuple<int32_t, int64_t, bool> b{1, 2, true};
  std::tuple<int32_t, int64_t, bool> c{1, 3, true};
  Show(a == b);
  Show(a == c);
  Show(a != c);
  std::tuple<> e1;
  std::tuple<> e2;
  Show(e1 == e2);
  std::tuple<Pair, int32_t> n{Pair{1, 2}, 3};
  std::tuple<Pair, int32_t> m{Pair{1, 4}, 3};
  Show(n == m);
  std::tuple<Pair, int32_t> n2{Pair{1, 2}, 3};
  Show(n != n2);
  Five w{1, 2, 3, 4, 5};
  Five w2{1, 2, 3, 4, 5};
  Show(w == w2);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.8 `stdlib/tuple_ordered.carbon`

Derived (DIFF-1): `a` = (1, 2, 3) against `b` = (1, 3, 0) is decided by the
second element: `<` 1, `<=` 1, `>` 0, `>=` 0; against the equal `c`: `<` 0, `>`
0, `<=` 1, `>=` 1; the empty tuples: `<` 0, `<=` 1; `n` = ((2, 1), 0) against
`m` = ((1, 9), 5) is decided by the inner tuples' first elements: `>` 1, `<` 0.
Stdout: 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0; the oracle prints exactly these
(M-10).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
//
// Differential pair: tuple_ordered.diff.cpp compares the same values with
// std::tuple's operator<, operator<=, operator> and operator>=, which compare
// lexicographically using only the elements' `<`, as Carbon's tuple ordering
// does (docs/design/expressions/comparison_operators.md, "Default
// implementations for basic types"), so C++ is the oracle for every printed
// line (no EXPECT-STDOUT). The prelude's variadic impl makes a tuple
// `OrderedWith` itself when every element type is `Ordered`: tuples decided
// by their second element, equal tuples, the empty tuple, and a tuple of a
// tuple and an i64 decided by the inner tuple's first element.

import Core library "io";

fn Show(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Run() -> i32 {
  let a: (i32, i32, i32) = (1, 2, 3);
  let b: (i32, i32, i32) = (1, 3, 0);
  Show(a < b);
  Show(a <= b);
  Show(a > b);
  Show(a >= b);
  let c: (i32, i32, i32) = (1, 2, 3);
  Show(a < c);
  Show(a > c);
  Show(a <= c);
  Show(a >= c);
  let e1: () = ();
  let e2: () = ();
  Show(e1 < e2);
  Show(e1 <= e2);
  let n: ((i32, i32), i64) = ((2, 1), 0);
  let m: ((i32, i32), i64) = ((1, 9), 5);
  Show(n > m);
  Show(n < m);
  return 0;
}
```

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of tuple_ordered.carbon: each Carbon tuple is
// a std::tuple of the same element types, and `<`, `<=`, `>` and `>=` are
// std::tuple's, which compare lexicographically using only the elements'
// `<`. printf("%d\n", ...) mirrors Core.Print's lowering.

#include <cstdint>
#include <cstdio>
#include <tuple>

static auto Show(bool b) -> void { std::printf("%d\n", b ? 1 : 0); }

using Three = std::tuple<int32_t, int32_t, int32_t>;
using Pair = std::tuple<int32_t, int32_t>;

auto main() -> int {
  Three a{1, 2, 3};
  Three b{1, 3, 0};
  Show(a < b);
  Show(a <= b);
  Show(a > b);
  Show(a >= b);
  Three c{1, 2, 3};
  Show(a < c);
  Show(a > c);
  Show(a <= c);
  Show(a >= c);
  std::tuple<> e1;
  std::tuple<> e2;
  Show(e1 < e2);
  Show(e1 <= e2);
  std::tuple<Pair, int64_t> n{Pair{2, 1}, 0};
  std::tuple<Pair, int64_t> m{Pair{1, 9}, 5};
  Show(n > m);
  Show(n < m);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.9 `stdlib/tuple_impl_generic.carbon`

EXPECT, derived in the header: 21, 22, 0, 21, 22, 23, 1, 1, 10. On PR 59's
install the program fails exactly at the four generic calls whose requirement is
a tuple's (`cannot convert type ... into type implementing Core.Eq`,
`Core.Ordered`, `Core.Copy`), and nowhere else (M-11).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   21
//   22
//   0
//   21
//   22
//   23
//   1
//   1
//   10
//
// The prelude's tuple impls are found through a generic function's
// requirement, where the tuple is a specific's type argument. Counted's
// `NotEqual` prints 20 plus its field, and the tuple impl calls it once per
// element, in order, stopping at the first element that differs (tuples
// compare field-wise, docs/design/tuples.md, "Operations performed
// field-wise"): Same(a, b) compares the first two elements, printing 21 and
// 22, and is false (0); Same(a, a) compares all three, printing 21, 22 and
// 23, and is true (1). Less through `Core.Ordered` is true for (1, 2) < (1, 3)
// (1), and Copies through `Core.Copy` copies a 4-tuple whose last element is
// 10.

import Core library "io";

class Counted {
  var v: i32;
}

impl Counted as Core.EqWith(Counted) {
  fn Equal(self, other: Counted) -> bool {
    Core.Print(10 + self.v);
    return self.v == other.v;
  }
  fn NotEqual(self, other: Counted) -> bool {
    Core.Print(20 + self.v);
    return self.v != other.v;
  }
}

fn Show(b: bool) {
  if (b) {
    Core.Print(1);
  } else {
    Core.Print(0);
  }
}

fn Same[T: Core.Eq](x: T, y: T) -> bool {
  return x == y;
}

fn Less[T: Core.Ordered](x: T, y: T) -> bool {
  return x < y;
}

fn Copies[T: Core.Copy](x: T) -> T {
  return x.(Core.Copy.Op)();
}

fn Run() -> i32 {
  let c1: Counted = {.v = 1};
  let c2: Counted = {.v = 2};
  let c3: Counted = {.v = 3};
  let c5: Counted = {.v = 5};
  let a: (Counted, Counted, Counted) = (c1, c2, c3);
  let b: (Counted, Counted, Counted) = (c1, c5, c3);
  Show(Same(a, b));
  Show(Same(a, a));
  Show(Less((1 as i32, 2 as i32), (1 as i32, 3 as i32)));
  Core.Print(Copies((7 as i32, 8 as i32, 9 as i32, 10 as i32)).3);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.10 Golden sources (AUTOUPDATE, no CHECK lines; R15, R16(a))

Each file is written by the commit named, verbatim, and filled only by
autoupdate; `fail_todo_va2.carbon` is written by C1 with its first four splits,
and C2 and C3 append theirs (two each) before their fills. Every split was
parsed by the planner with PR 59's install (`carbon compile --phase=parse` on
each split as its own file: 52 splits, all parse); none was checked, since each
needs C1 to C3. The refills of VA-1's goldens change no source except
fail_todo_slice.carbon, whose `fail_todo_generic_pack` split is deleted by C1
(its source is `generic_pack.carbon`'s `declaration` split).

toolchain/check/testdata/variadics/hetero_pack.carbon (C1):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/hetero_pack.carbon

// --- call.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}
//@dump-sem-ir-end

fn Call(a: A, b: B) {
  //@dump-sem-ir-begin
  ForEach(a, b, a);
  ForEach();
  //@dump-sem-ir-end
}

// --- type_pack.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Count[... each T: type](... each x: each T);
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  Count(1 as i64, true);
  Count();
  //@dump-sem-ir-end
}

// --- forward.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn ForEach[... each T: Code](... each x: each T);

//@dump-sem-ir-begin
fn Forward[... each U: Code](... each y: each U) {
  ForEach(... each y);
}
//@dump-sem-ir-end

// --- method.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class C {
  fn F[... each T: Code](self, ... each x: each T);
}

fn Call(c: C, a: A) {
  //@dump-sem-ir-begin
  c.F(a, a);
  //@dump-sem-ir-end
}

// --- qualified_member.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.(Code.Get)());
}
//@dump-sem-ir-end
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/fail_hetero_pack.carbon (C1):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_hetero_pack.carbon

// --- fail_missing_impl.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class C {}

fn ForEach[... each T: Code](... each x: each T);

fn Call(a: A, c: C) {
  ForEach(a, c);
}

// --- fail_missing_member.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

fn ForEach[... each T: Code](... each x: each T) {
  ... each x.Missing();
}

// --- fail_convert_element.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach[... each T: type](... each x: each T) {
  ... Consume(each x);
}

// --- fail_each_type_not_pack.carbon
library "[[@TEST_NAME]]";

fn F[T: type](... each x: each T);

// --- fail_two_explicit_packs.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each x: each T, ... each y: each T);
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/generic_pack.carbon (C1):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/generic_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/generic_pack.carbon

// --- declaration.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each x: each T);

// --- call.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each x: each T);

fn G() {
  F(1 as i64, true, 2 as i32);
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/fail_todo_va2.carbon (C1, C2, C3):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_va2.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_va2.carbon

// --- fail_todo_two_implicit_packs.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type, ... each U: type](... each x: each T);

// --- fail_todo_computed_element_type.carbon
library "[[@TEST_NAME]]";

class Box(T: type) {}

fn F[... each T: type](... each b: Box(each T));

// --- fail_todo_template_each.carbon
library "[[@TEST_NAME]]";

fn F[... template each T: type](... each x: each T);

// --- fail_todo_each_auto.carbon
library "[[@TEST_NAME]]";

fn F(... each x: auto);

// --- fail_todo_initializing_element.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x.(Core.Copy.Op)());
}

// --- fail_todo_var_pattern.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](t: (... each T)) {
  var (... each x: each T) = t;
}

// --- fail_todo_if_with_declaration.carbon
library "[[@TEST_NAME]]";

fn F(... each b: bool) {
  ... if (each b) {
    let unused y: i64 = 0;
  }
}

// --- fail_todo_while.carbon
library "[[@TEST_NAME]]";

fn F(... each b: bool) {
  ... while (each b) {}
}
```

<!-- google-doc-style-resume -->

toolchain/lower/testdata/variadics/hetero_pack.carbon (C1):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/hetero_pack.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/hetero_pack.carbon

// --- call.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Call(a: A, b: B) {
  ForEach(a, b, a);
  ForEach();
}

// --- layout.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn One[V: type](unused v: V) -> i64 { return 1; }

fn Count[... each T: type](... each x: each T) -> i64 {
  var n: i64 = 0;
  ... n = Add(n, One(each x));
  return n;
}

fn Call() -> i64 {
  return Count(1 as i64, true, 2 as i32);
}

// --- forward.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

class A {}
impl A as Code {
  fn Get(unused self) -> i64 { return 1; }
}

class B {}
impl B as Code {
  fn Get(unused self) -> i64 { return 2; }
}

fn Consume(x: i64);

fn ForEach[... each T: Code](... each x: each T) {
  ... Consume(each x.Get());
}

fn Forward[... each U: Code](... each y: each U) {
  ForEach(... each y);
}

fn Call(a: A, b: B) {
  Forward(a, b);
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/tuple_segment.carbon (C2):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/tuple_segment.carbon

// --- param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[... each T: type](t: (... each T));
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i64, true));
  F(());
  //@dump-sem-ir-end
}

// --- return.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}
//@dump-sem-ir-end

fn Call() -> (i64, bool) {
  //@dump-sem-ir-begin
  return MakeTuple(1 as i64, true);
  //@dump-sem-ir-end
}

// --- let.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

interface Code {
  fn Get(self) -> i64;
}

//@dump-sem-ir-begin
fn ForEach[... each T: Code](t: (... each T)) {
  let (... each x: each T) = t;
  ... Consume(each x.Get());
}
//@dump-sem-ir-end

// --- tuple_value.carbon
library "[[@TEST_NAME]]";

fn Take[... each U: type](t: (... each U));

//@dump-sem-ir-begin
fn Pass[... each T: type](... each x: each T) {
  Take((... each x));
}
//@dump-sem-ir-end

// --- elements_around_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](t: (i64, ... each T, bool));

fn Call() {
  //@dump-sem-ir-begin
  F((1 as i64, 2 as i32, false, true));
  F((1 as i64, true));
  //@dump-sem-ir-end
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/fail_todo_tuple_segment.carbon (C2):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_tuple_segment.carbon

// --- fail_todo_two_segments.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](t: (... each T, ... each T));

// --- fail_todo_elements_beside_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](... each x: each T) -> (i64, ... each T) {
  return (0, ... each x);
}

// --- fail_todo_segment_to_elements.carbon
library "[[@TEST_NAME]]";

fn F[... each T: Core.Copy](... each x: each T) {
  let unused t: (i64, i64) = (... each x);
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/impl.carbon (C2):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/impl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/impl.carbon

// --- select.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

//@dump-sem-ir-begin
impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}
//@dump-sem-ir-end

fn Call(t: (i64, bool), e: ()) -> i64 {
  //@dump-sem-ir-begin
  t.(Count.N)();
  return e.(Count.N)();
  //@dump-sem-ir-end
}

// --- requirement.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

//@dump-sem-ir-begin
impl forall [... each T: Code] (... each T) as Code {
  fn Get(self) -> i64 {
    let (... each x: each T) = self;
    var total: i64 = 0;
    ... total = Add(total, each x.Get());
    return total;
  }
}
//@dump-sem-ir-end

fn Call(t: (i64, (i64, i64))) -> i64 {
  //@dump-sem-ir-begin
  return t.(Code.Get)();
  //@dump-sem-ir-end
}

// --- generic_use.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

fn Use[V: Count](v: V) -> i64 { return v.N(); }

fn Call(t: (i64, bool)) -> i64 {
  //@dump-sem-ir-begin
  return Use(t);
  //@dump-sem-ir-end
}

// --- non_tuple_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

impl i64 as Count {
  fn N(self) -> i64 { return self; }
}

fn Call(x: i64) -> i64 {
  //@dump-sem-ir-begin
  return x.(Count.N)();
  //@dump-sem-ir-end
}

// --- symbolic_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

//@dump-sem-ir-begin
fn H[... each T: type](t: (... each T)) -> i64 {
  return t.(Count.N)();
}
//@dump-sem-ir-end

// --- self_query.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
  fn Twice(self) -> i64;
}

//@dump-sem-ir-begin
impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
  fn Twice(self) -> i64 { return self.(Count.N)(); }
}
//@dump-sem-ir-end

// --- lib.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call(t: (i64, bool, i64)) -> i64 {
  //@dump-sem-ir-begin
  return t.(Count.N)();
  //@dump-sem-ir-end
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/fail_impl.carbon (C2):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_impl.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_impl.carbon

// --- fail_missing_element_impl.carbon
library "[[@TEST_NAME]]";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

impl forall [... each T: Code] (... each T) as Code {
  fn Get(unused self) -> i64 { return 0; }
}

fn Call(t: (i64, bool)) -> i64 {
  return t.(Code.Get)();
}

// --- fail_not_a_tuple.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 7; }
}

fn Call(x: i64) -> i64 {
  return x.(Count.N)();
}

// --- fail_unused_pack.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] i64 as Count {
  fn N(unused self) -> i64 { return 7; }
}
```

<!-- google-doc-style-resume -->

toolchain/lower/testdata/variadics/tuple_segment.carbon (C2):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/tuple_segment.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/tuple_segment.carbon

// --- make_tuple.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Call() -> (i64, bool, i32) {
  return MakeTuple(1 as i64, true, 2 as i32);
}

// --- let.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

fn Sum[... each T: Code](t: (... each T)) -> i64 {
  let (... each x: each T) = t;
  var total: i64 = 0;
  ... total = Add(total, each x.Get());
  return total;
}

fn Call(t: (i64, i64, i64)) -> i64 {
  return Sum(t);
}

// --- impl.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

interface Code {
  fn Get(self) -> i64;
}

impl i64 as Code {
  fn Get(self) -> i64 { return self; }
}

impl forall [... each T: Code] (... each T) as Code {
  fn Get(self) -> i64 {
    let (... each x: each T) = self;
    var total: i64 = 0;
    ... total = Add(total, each x.Get());
    return total;
  }
}

fn Call(t: (i64, (i64, i64))) -> i64 {
  return t.(Code.Get)();
}

// --- one_tuple.carbon
library "[[@TEST_NAME]]";

fn MakeTuple[... each T: Core.Copy](... each x: each T) -> (... each T) {
  return (... each x);
}

fn Call() -> (i64,) {
  return MakeTuple(5 as i64);
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/expansion_if.carbon (C3):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/expansion_if.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/expansion_if.carbon

// --- if_else.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn F(... each b: bool) {
  ... if (each b) {
    Consume(1);
  } else {
    Consume(0);
  }
}
//@dump-sem-ir-end

// --- else_if_return.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn First(... each b: bool) -> i64 {
  ... if (each b) {
    return 1;
  } else if (true) {
    Consume(2);
  }
  return 0;
}
//@dump-sem-ir-end

// --- generic.carbon
library "[[@TEST_NAME]]";

interface Less {
  fn Lt(self, other: Self) -> bool;
}

//@dump-sem-ir-begin
fn AnyLess[T: Less](first: T, ... each next: T) -> bool {
  ... if (each next.Lt(first)) {
    return true;
  }
  return false;
}
//@dump-sem-ir-end

// --- nested.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each b: bool) {
  ... if (each b) {
    if (each b) {
      Consume(1);
    }
  }
}
```

<!-- google-doc-style-resume -->

toolchain/lower/testdata/variadics/expansion_if.carbon (C3):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/expansion_if.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/expansion_if.carbon

// --- first.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn First(... each b: bool) -> i64 {
  ... if (each b) {
    return 1;
  } else {
    Consume(0);
  }
  return 0;
}

fn Call() -> i64 {
  return First(false, true, false);
}

// --- min.carbon
library "[[@TEST_NAME]]";

fn Less(a: i64, b: i64) -> bool = "int.less";

fn Min(first: i64, ... each next: i64) -> i64 {
  var result: i64 = first;
  ... if (Less(each next, result)) {
    result = each next;
  }
  return result;
}

fn Call() -> i64 {
  return Min(3, 1, 2);
}
```

<!-- google-doc-style-resume -->

### §A.11 Records, verbatim but for `<...>` fields

Commit R writes the two rows of fork/gap-analysis.md (lines 59 and 80 on this
branch; records refer to rows by bullet text, R7); commit D writes the rest.
`<date>` is the UTC date of the commit (`date -u +%F`), `<run>` the container
run's scoreboard time and log path, `<counts>` its totals, and `<C1>` to `<F4>`,
`<fixes>` and `<R>` the commits' short hashes.

Row "Generics: Definition-checked variadics" (replaces line 59):

<!-- google-doc-style-ignore -->

```text
| Generics: Definition-checked variadics | PARTIAL | Slice 1 landed by VA-1 (fork/variadics/plan.md) and slice 2 by VA-2 (fork/variadics/va2-plan.md; W-013 stays open), EXPECTED, not of record: `...` (upstream's 2ec4bab59, cherry-picked) and `each` lex and parse; a function may take one pack `... each x: T` of one element type or, with a compile-time pack `[... each T: I]` in its implicit parameter list, a pack `... each x: each T` of different types, binding its arguments' values without copying them, expand them in expression statements and `if` statements and pass them on as call arguments (`... e`, evaluated where written); a tuple type of one pack segment, `(... each T)`, is a parameter, return or impl self type, `(... each x)` is a tuple, and `let (... each x: each T) = t;` binds a tuple's elements; the arity and the pack of types are deduced at each call, the body is checked once against the element type or the symbolic `each T`, and each specific is lowered once per element with that element's types and callees; a variadic impl is selected for tuples of every arity. generics/variadics_each.carbon and thirteen more programs PASS in the container run <run> (<counts>). Not yet (W-214..W-230, W-330..W-334): several packs of independent arity and class parameter packs, element types computed from an each-name, tuples of several segments, `...and`/`...or`/`...expand`, declarations and loops inside expansions, control flow inside expression bodies, default values beside a pack, variadic interface functions, `each x: auto`, the termination rule of impl selection, C++ variadic templates. |
```

<!-- google-doc-style-resume -->

Row "Stdlib: tuple/array library parts" (replaces line 80):

<!-- google-doc-style-ignore -->

```text
| Stdlib: tuple/array library parts | PARTIAL | array Iterate impl works; tuple `Copy` is one variadic impl for every arity (core/prelude/copy.carbon), and tuples compare with `==`, `!=` and lexicographic `<`, `<=`, `>`, `>=` when their element types do (core/prelude/operators/comparison.carbon), by VA-2 (fork/variadics/va2-plan.md), EXPECTED, not of record: stdlib/tuple_copy_variadic.carbon, tuple_eq.carbon, tuple_ordered.carbon and tuple_impl_generic.carbon PASS in the container run <run>. Not yet: comparisons between tuples that convert one operand (W-334). |
```

<!-- google-doc-style-resume -->

fork/inventory/work-items.json, commit D: W-212, W-213 and W-225 are replaced by
these entries; W-214, W-218, W-219, W-222, W-229 and W-013 gain the sentences
below at the end of their `notes`; W-330 to W-334 are appended after W-230, in
id order. The file's `source` string gains "Updated <date> by the VA-2
discharge: W-212, W-213 and W-225 discharged; W-214, W-218, W-219, W-222, W-229
and W-013 noted; W-330 to W-334 added."

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-212",
  "kind": "implemented",
  "title": "VA-2 (LANDED <date>): VA-1 residue: generic and heterogeneous packs (`[... each T: type]`, `... each x: each T`, `each x: auto`) and multi-segment pack typechecking",
  "subsystem": "toolchain/check + toolchain/lower",
  "size": "XL",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "toolchain/check/testdata/variadics/hetero_pack.carbon, fail_hetero_pack.carbon, generic_pack.carbon and toolchain/lower/testdata/variadics/hetero_pack.carbon (new in <C1>, filled in <F1>)",
    "fork/conformance/programs/generics/variadics_hetero_digits.carbon (+ .diff.cpp), variadics_hetero_forward.carbon, variadics_hetero_empty.carbon: PASS in the container run <run>, expected, not of record",
    "fork/variadics/va2-plan.md D-VA2-2 to D-VA2-7"
  ],
  "blocked_by": [],
  "notes": "DISCHARGED (fork/variadics/va2-plan.md, VA-2, <date>; branch claude/carbon-fork-0-1-va2 stacked on PR 59; <C1> to <C5>, fills <F1> to <F4>, fix commits <fixes>, R <R>, then D; decision-log \"VA-2: definition-checked variadics, slice 2 (<date>)\"). A function or impl declares one compile-time pack `[... each T: I]` in its implicit parameter list and takes `... each x: each T`; each call deduces the pack of argument types and its arity and checks each element's `I`; the body is checked once with `each x` of the symbolic type `each T` and lowered once per element. Moved: `each x: auto` to W-333 (blocked on `auto` parameters), computed element types to W-330, a second implicit-list pack to W-222, p002274's variadic indexing interfaces to W-229's note. Follows VA-1 slice 1."
}
```

```json
{
  "id": "W-213",
  "kind": "implemented",
  "title": "VA-2 (LANDED <date>): VA-1 residue: tuples with pack segments (`(... each x)` outside a call's argument list, tuple types `(... each T)`)",
  "subsystem": "toolchain/check + toolchain/lower",
  "size": "L",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "toolchain/check/testdata/variadics/tuple_segment.carbon, fail_todo_tuple_segment.carbon, impl.carbon, fail_impl.carbon and toolchain/lower/testdata/variadics/tuple_segment.carbon (new in <C2>, filled in <F2>)",
    "fork/conformance/programs/generics/variadics_tuple_param.carbon: PASS in the container run <run>, expected, not of record",
    "fork/variadics/va2-plan.md D-VA2-8, D-VA2-9"
  ],
  "blocked_by": [],
  "notes": "DISCHARGED (fork/variadics/va2-plan.md, VA-2, <date>; commits as W-212's). `(... each T)` is a tuple type of one pack segment, flattened once its arity is known, deduced from a tuple argument (with elements before and after the segment) and a hole of impl lookup's type structure; `(... each x)` initializes a tuple element by element and is a value of the tuple type; `let (... each x: each T) = t;` binds a pack to a tuple's elements. Break condition met: `(... each x)` is a value of a tuple type in a variadic function. Remaining: several segments in W-222, a segment merged with other elements in W-215, initializing expansion elements in W-331, `...expand` in W-217. Follows VA-1 slice 1."
}
```

```json
{
  "id": "W-225",
  "kind": "implemented",
  "title": "VA-2 (LANDED <date>): VA-1 residue: variadic impls; the prelude tuple `Copy` as one variadic impl, and tuple `Eq`/`Ordered`",
  "subsystem": "core/prelude + toolchain/check",
  "size": "L",
  "bullet": "Stdlib: tuple/array library parts",
  "evidence": [
    "core/prelude/copy.carbon: the TODO and the four tuple impls of :50-71 replaced by `impl forall [... each T: Copy] (... each T) as Copy` (<C4>)",
    "core/prelude/operators/comparison.carbon: `impl forall [... each T: Eq] (... each T) as EqWith(Self)` and `impl forall [... each T: Ordered] (... each T) as OrderedWith(Self)` appended (<C4>)",
    "fork/conformance/programs/stdlib/tuple_copy_variadic.carbon, tuple_eq.carbon (+ .diff.cpp), tuple_ordered.carbon (+ .diff.cpp), tuple_impl_generic.carbon and generics/variadics_min.carbon: PASS in the container run <run>, expected, not of record",
    "fork/variadics/va2-plan.md D-VA2-10 to D-VA2-12"
  ],
  "blocked_by": [],
  "notes": "DISCHARGED (fork/variadics/va2-plan.md, VA-2, <date>; commits as W-212's). Break condition met: the four hand-written impls are replaced, and a 4-tuple, a 5-tuple and a 13-tuple satisfy `Core.Copy`, each element copied once by its own `Copy`; tuples whose element types are `Eq` or `Ordered` compare field-wise and lexicographically. Impl selection terminates because each impl's requirements are on strict subterms of its self type; p002687's termination rule is W-332. Remaining: comparisons that convert one operand, W-334. Follows VA-1 slice 1."
}
```

<!-- google-doc-style-resume -->

Sentences appended to `notes` (each preceded by a space):

<!-- google-doc-style-ignore -->

```text
W-214: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-9): `let (... each x: each T) = t;` of fixed arity binds a pack; only `var`, `match` and nested tuple patterns, and a `let` expansion of deduced arity (`pack expansion pattern with deduced arity outside a parameter list`), remain.
W-218: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-11): statement expansions whose body is an `if` statement, with `else if`, `else` and `return`, are checked and lowered; only declarations, `while`, `for`, `break`, `continue` and `match` in a body remain (`pack expansion of a statement other than an expression or if statement`).
W-219: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-11): control flow at the statement level (`... if`) is implemented; only control flow inside an expression body and the "Type versus execution semantics" example remain.
W-222: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-4): every pack of a function or impl shares one deduced arity; independent arities, a second implicit-list pack (`more than one pack expansion pattern in an implicit parameter list`), tuples of more than one segment and class parameter packs remain.
W-229: VA-2 (<date>): p002274's variadic indexing interfaces (:250-257), named by W-212's note, are deferred by that proposal "once we have a design for variadics" as an alternative, not a rule, and need packs in interface functions; they are tracked here.
W-013: VA-2 slice 2 (<date>, fork/variadics/va2-plan.md): packs of different types in implicit parameter lists, tuples with one pack segment, `let` pack bindings, statement expansions of `if`, variadic impls, and the prelude's tuple `Copy`, `EqWith` and `OrderedWith` as variadic impls (W-212, W-213 and W-225 discharged; W-330 to W-334 filed). Next: W-330 (computed element types), W-222 (several packs), W-217 (`...expand`).
```

```json
{
  "id": "W-330",
  "kind": "missing-feature",
  "title": "VA-2 residue: pack types whose element type is computed from an each-name (`... each x: Optional(each T)`, Zip's `Vector(each ElementType)`)",
  "subsystem": "toolchain/check + toolchain/lower",
  "size": "L",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "docs/design/variadics.md \"Pack expanding\" reduction (:773-797), Zip (:67-82); DR-24",
    "toolchain/check/testdata/variadics/fail_todo_va2.carbon split `fail_todo_computed_element_type` (`semantics TODO: pack expansion pattern whose binding type is computed from an each-name`)"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11). VA-2's pack type holds a type or a compile-time pack of types (D-VA2-3); a type computed per element needs the design's pack-expanding reduction at evaluation. Break condition: Zip's signature checks and `... each x: Optional(each T)` binds. Follows VA-2 slice 2."
}
```

```json
{
  "id": "W-331",
  "kind": "missing-feature",
  "title": "VA-2 residue: pack expansions of initializing expressions in a tuple literal, initialized in place",
  "subsystem": "toolchain/check + toolchain/lower",
  "size": "M",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "docs/design/variadics.md :200-203; DR-9",
    "toolchain/check/testdata/variadics/fail_todo_va2.carbon split `fail_todo_initializing_element` (`semantics TODO: pack expansion of initializing expressions in a tuple literal`)"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11). `return (... each x.Op());` would initialize each element through the body's return slot; VA-2 initializes elements only from values (D-VA2-9), so the prelude's tuple `Copy` binds the elements with `let` first. Break condition: the split checks, and the tuple `Copy` impl may be respelled `return (... each x.Op());` with the same copies. Follows VA-2 slice 2."
}
```

```json
{
  "id": "W-332",
  "kind": "missing-feature",
  "title": "VA-2 residue: p002687's termination rule for impl selection, with its variadic count keys",
  "subsystem": "toolchain/check",
  "size": "L",
  "bullet": "Generics: Checked generics",
  "evidence": [
    "proposals/p002687-termination-algorithm-for-impl-selection.md :186-193, :210-215",
    "toolchain/check/impl_lookup.cpp:183-194 (\"TODO: Implement the termination rule\"); the same TODO upstream at ebc155734, :199"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11, D-VA2-10). Impl lookup implements only the acyclic rule, upstream as in the fork; VA-2's variadic impls terminate because their requirements are on strict subterms of their self types. Take upstream's implementation at the advance if it lands first. Break condition: an impl whose requirement is on a type not smaller than its self type is rejected by the rule."
}
```

```json
{
  "id": "W-333",
  "kind": "missing-feature",
  "title": "VA-2 residue: `each x: auto` (a pack binding whose element types are deduced from `auto`)",
  "subsystem": "toolchain/check",
  "size": "S",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "docs/design/variadics.md :732-734 (\"The type of `each x: auto` is `each __X`\"); DR-40, DR-45",
    "toolchain/check/testdata/variadics/fail_todo_va2.carbon split `fail_todo_each_auto` (`semantics TODO: HandleAutoTypeLiteral`)"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11), moved from W-212. Blocked by `auto` parameters, which neither the fork nor upstream implements (`HandleAutoTypeLiteral`); once they exist, `each x: auto` is `... each x: each __X` over VA-2's packs of types. Break condition: `fn F(... each x: auto)` checks and deduces its pack of types. Follows VA-2 slice 2."
}
```

```json
{
  "id": "W-334",
  "kind": "missing-feature",
  "title": "VA-2 residue: tuple comparisons that convert one operand (`(i32, i32) == (1, 2)`)",
  "subsystem": "core/prelude + toolchain/check",
  "size": "M",
  "bullet": "Stdlib: tuple/array library parts",
  "evidence": [
    "docs/design/expressions/comparison_operators.md :504-505 (\"Comparisons between tuples permit implicit conversions for either operand, but not both\")",
    "fork/variadics/va2-plan.md §0.2 p23 (`cannot access member of interface Core.EqWith((Core.IntLiteral, Core.IntLiteral))`), unchanged by C4"
  ],
  "blocked_by": ["W-222"],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11, §1.12 (ii)). VA-2's tuple impls are `EqWith(Self)` and `OrderedWith(Self)`; the design's conversions need `EqWith((... each U))` over a second pack of the same arity and a per-element conversion requirement. Break condition: p23 compiles and prints 1. Follows VA-2 slice 2."
}
```

<!-- google-doc-style-resume -->

fork/gap-analysis.md §W6, commit D, after the "Slice 1" paragraph:

<!-- google-doc-style-ignore -->

```text
**Slice 2 (VA-2, fork/variadics/va2-plan.md):** packs of different types in
implicit parameter lists, tuples with one pack segment, `let` pack bindings,
statement expansions of `if`, and variadic impls, with which the prelude's
tuple `Copy`, `EqWith` and `OrderedWith` are single variadic impls, as this
section's arbiter asks. Next: W-330 (computed element types), W-222 (several
packs) and W-217 (`...expand`), which the design's Zip, Apply and
TupleConcat need.
```

<!-- google-doc-style-resume -->

fork/decision-log.md, commit D, appended after the last entry:

<!-- google-doc-style-ignore -->

```text
### VA-2: definition-checked variadics, slice 2 (<date>)

Context: W-212, W-213 and W-225 (VA-1's residues; gap rows "Generics:
Definition-checked variadics" and "Stdlib: tuple/array library parts", both
PARTIAL); fork/variadics/va2-plan.md, rev <n> after two plan reviews, all
folded; branch claude/carbon-fork-0-1-va2, one PR stacked on PR 59. Every
decision auto-adopted under V-2/V-3 (R29(a)) and open to veto.

Decisions (plan §1, each with its break condition): D-VA2-1 the slice;
D-VA2-2 a symbolic pack index and per-iteration values of a specific;
D-VA2-3 one pack type whose element is a type or a pack of types; D-VA2-4
`[... each T: I]` with one deduced arity per full pattern; D-VA2-5 to
D-VA2-7 deduction, definition checking against `each T`, and lowering per
element; D-VA2-8 and D-VA2-9 tuples of one pack segment, `let` bindings and
element-wise initialization; D-VA2-10 variadic impl selection, terminating
by subterm requirements; D-VA2-11 statement expansions of `if`; D-VA2-12
the prelude's tuple impls; D-VA2-13 and D-VA2-14 the TODO texts, templates
and C++ unchanged; D-VA2-15 to D-VA2-19 goldens, programs, records, merge
position and commits.

Options considered (plan §7.2): a second checking path (A-1); hand-written
impls to a larger fixed arity (A-2); a pack-to-tuple shim (A-3); two packs
now (A-4); a specific per element (A-5); constant packs everywhere (A-6);
`return self;` as the tuple `Copy.Op` (A-7); `...and` for equality (A-8).

V-3 check: every mechanism is the design's (docs/design/variadics.md at
upstream's ebc155734), the fork's SemIR is internal representation, and no
design page is edited. V-3a register entries: `...expand`'s typechecking is
the design's TODO (W-217); tuple comparisons convert neither operand
(W-334); defaults beside a pack follow upstream's 503f09037 (W-215); the
termination rule is upstream's TODO too (W-332).

Records: W-212, W-213 and W-225 discharged; W-214, W-218, W-219, W-222,
W-229 and W-013 noted; W-330 to W-334 filed, W-335 to W-339 unused. Both
rows stay PARTIAL with narrower open text, expected, not of record, on the
container run <run>.
```

<!-- google-doc-style-resume -->

fork/ORCHESTRATION.md, commit D, appended to the paragraph that records VA-1
(and its row in the PR table updated by commit L at land time):

<!-- google-doc-style-ignore -->

```text
VA-2 (claude/carbon-fork-0-1-va2, stacked on PR 59, fork/variadics/va2-plan.md)
implements packs of different types, tuples with one pack segment, statement
expansions of `if` and variadic impls, and makes the prelude's tuple Copy,
EqWith and OrderedWith single variadic impls; W-212, W-213 and W-225
discharged, W-330 to W-334 filed (W-335 to W-339 reserved and unused);
expected <counts> over <programs> on the container run <run>. It merges
last, after DR-1b (fork/variadics/va2-plan.md D-VA2-18), held open.
```

<!-- google-doc-style-resume -->

## Appendix B. The prototype, verbatim

`$Q/va2_prototype.patch`, the diff of the prototype against b0822a744 (26 files,
892 insertions, 105 deletions), which §2.1 to §2.3 describe hunk by hunk and C1
and C2 split. M-9's correction to its `TupleType` deduction (§2.3, R-4) is not
in it: the hunk below at the `TupleType` case walks a non-tuple argument's
operands, and C2 replaces that branch by `if (!arg_tuple) { break; }` before the
segment test.
The repository's trailing-whitespace hook strips the single space of the
diff's blank context lines, so this copy is for reading; `git apply` takes
`$Q/va2_prototype.patch`.

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/context.h b/toolchain/check/context.h
index 2787071e8..9afeeb7ff 100644
--- a/toolchain/check/context.h
+++ b/toolchain/check/context.h
@@ -537,12 +537,14 @@ class Context {
         ScopeStack::CleanupScopeDepth::None;
     SemIR::InstId arity_id = SemIR::InstId::None;
     // For a pattern: the binding pattern and binding of the pack's deduced
-    // arity, and the each-name binding pattern that the body declares with its
-    // element type, once checked.
+    // arity, and the each-name binding pattern that the body declares with the
+    // pack's type, once checked. Fork (VA-2): a pattern whose binding's type
+    // is an each-name has that pack's arity and no arity binding of its own
+    // (docs/design/variadics.md, "Explicit deduced arities").
     SemIR::InstId arity_pattern_id = SemIR::InstId::None;
     SemIR::InstId arity_binding_id = SemIR::InstId::None;
     SemIR::InstId each_binding_pattern_id = SemIR::InstId::None;
-    SemIR::TypeInstId element_type_inst_id = SemIR::TypeInstId::None;
+    SemIR::TypeId pack_type_id = SemIR::TypeId::None;
   };
   auto pack_expansion_stack() -> llvm::SmallVector<PackExpansionScope>& {
     return pack_expansion_stack_;
diff --git a/toolchain/check/convert.cpp b/toolchain/check/convert.cpp
index 5d6dc9141..dee4b5bc8 100644
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -521,11 +521,13 @@ static auto ConvertPackLiteralToPack(Context& context,
       context.sem_ir().GetZExtIntValue(pack_type.arity_id) == elements.size(),
       "Pack literal of {0} elements converted to {1}", elements.size(),
       target.type_id);
-  auto element_type_id =
-      context.types().GetTypeIdForTypeInstId(pack_type.element_type_inst_id);
   llvm::SmallVector<SemIR::InstId> value_ids;
   value_ids.reserve(elements.size());
-  for (auto element_id : elements) {
+  for (auto [index, element_id] : llvm::enumerate(elements)) {
+    // Fork (VA-2): the `index`th element of a pack of different types has the
+    // `index`th type of its pack of types.
+    auto element_type_id =
+        SemIR::GetPackElementTypeId(context.sem_ir(), pack_type, index);
     auto converted_id = Convert(context, SemIR::LocId(element_id), element_id,
                                 {.kind = ConversionTarget::Value,
                                  .type_id = element_type_id,
@@ -566,17 +568,18 @@ static auto ConvertPackToPack(Context& context, SemIR::PackType src_type,
       context, value_loc_id,
       {.type_id =
            GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
+  // Fork (VA-2): the element types of a pack of different types depend on
+  // the pack index.
   auto element_id = AddInst<SemIR::PackElement>(
       context, value_loc_id,
-      {.type_id = context.types().GetTypeIdForTypeInstId(
-           src_type.element_type_inst_id),
+      {.type_id = GetPackElementType(context, value_loc_id, src_type),
        .pack_id = value_id,
        .index_id = index_id});
-  auto result_id = Convert(context, value_loc_id, element_id,
-                           {.kind = ConversionTarget::Value,
-                            .type_id = context.types().GetTypeIdForTypeInstId(
-                                target_type.element_type_inst_id),
-                            .diagnose = target.diagnose});
+  auto result_id = Convert(
+      context, value_loc_id, element_id,
+      {.kind = ConversionTarget::Value,
+       .type_id = GetPackElementType(context, value_loc_id, target_type),
+       .diagnose = target.diagnose});
   CARBON_CHECK(context.inst_block_stack().is_current_block_reachable() &&
                    context.inst_block_stack().PeekOrAdd() == body_block_id,
                "Control flow in a pack element conversion");
@@ -718,6 +721,14 @@ static auto ConvertTupleToType(Context& context, SemIR::LocId loc_id,
               value_const_id)) {
     for (auto tuple_inst_id :
          context.inst_blocks().Get(tuple_value->elements_id)) {
+      // Fork (VA-2): a segment that is a compile-time pack of types or
+      // facets, `... each T`, is the type segment `...⟬each T⟭`.
+      if (auto pack_type = context.types().TryGetAs<SemIR::PackType>(
+              context.insts().Get(tuple_inst_id).type_id())) {
+        type_inst_ids.push_back(context.types().GetTypeInstId(
+            GetPackType(context, tuple_inst_id, pack_type->arity_id)));
+        continue;
+      }
       // TODO: This call recurses back into conversion. Switch to an
       // iterative approach.
       type_inst_ids.push_back(
@@ -1891,6 +1902,31 @@ static auto PerformBuiltinConversion(Context& context, SemIR::LocId loc_id,
       return ConvertPackLiteralToPack(context, *literal, *target_pack_type,
                                       value_id, target);
     }
+    // Fork (VA-2): a pack value of known arity, such as a compile-time pack of
+    // types deduced for `T` in `[... each T: I]`, converts element by
+    // element, so that a pack of constants converts to a pack of constants.
+    if (auto pack_value = value.TryAs<SemIR::PackValue>();
+        pack_value && sem_ir.GetZExtIntValue(target_pack_type->arity_id)) {
+      auto elements = sem_ir.inst_blocks().Get(pack_value->elements_id);
+      llvm::SmallVector<SemIR::InstId> converted_ids;
+      converted_ids.reserve(elements.size());
+      for (auto [index, element_id] : llvm::enumerate(elements)) {
+        auto converted_id = Convert(
+            context, loc_id, element_id,
+            {.kind = ConversionTarget::Value,
+             .type_id = SemIR::GetPackElementTypeId(sem_ir, *target_pack_type,
+                                                    index),
+             .diagnose = target.diagnose});
+        if (converted_id == SemIR::ErrorInst::InstId) {
+          return SemIR::ErrorInst::InstId;
+        }
+        converted_ids.push_back(converted_id);
+      }
+      return AddInst<SemIR::PackValue>(
+          context, loc_id,
+          {.type_id = target.type_id,
+           .elements_id = context.inst_blocks().Add(converted_ids)});
+    }
     if (auto src_pack_type =
             sem_ir.types().TryGetAs<SemIR::PackType>(value_type_id)) {
       return ConvertPackToPack(context, *src_pack_type, *target_pack_type,
diff --git a/toolchain/check/deduce.cpp b/toolchain/check/deduce.cpp
index 805ba2beb..c2811672a 100644
--- a/toolchain/check/deduce.cpp
+++ b/toolchain/check/deduce.cpp
@@ -445,8 +445,8 @@ auto DeductionContext::Deduce() -> bool {
                 context().insts().TryGetAs<SemIR::PackType>(arg_id)) {
           Add(pack_type.arity_id, arg_pack_type->arity_id,
               /*want_value=*/true);
-          Add(pack_type.element_type_inst_id,
-              arg_pack_type->element_type_inst_id, /*want_value=*/true);
+          Add(pack_type.element_id, arg_pack_type->element_id,
+              /*want_value=*/true);
           continue;
         }
         auto arg_tuple_type =
@@ -463,9 +463,88 @@ auto DeductionContext::Deduce() -> bool {
              .int_id = context().ints().Add(
                  static_cast<int64_t>(element_ids.size()))});
         Add(pack_type.arity_id, arity_id, /*want_value=*/true);
+        // Fork (VA-2): for `⟬each T⟭`, the pack of types `T` is deduced as the
+        // pack of the arguments' types, `⟬A1, ..., Ak⟭`, which deduction then
+        // converts to `T`'s type, such as `«I; k»`.
+        if (IsHeterogeneousPackType(context(), pack_type)) {
+          auto types_type_id = GetPackType(context(), SemIR::TypeType::TypeInstId,
+                                           arity_id);
+          auto types_id = GetOrAddInst<SemIR::PackValue>(
+              context(), loc_id_,
+              {.type_id = types_type_id,
+               .elements_id = context().inst_blocks().AddCanonical(
+                   llvm::SmallVector<SemIR::InstId>(element_ids))});
+          Add(pack_type.element_id, types_id, /*want_value=*/true);
+          continue;
+        }
         for (auto element_id : llvm::reverse(element_ids)) {
-          Add(pack_type.element_type_inst_id, element_id, /*want_value=*/true);
+          Add(pack_type.element_id, element_id, /*want_value=*/true);
+        }
+        continue;
+      }
+
+      // Fork (VA-2): a tuple type with one pack segment, such as the
+      // `(... each T)` of an impl, matches a tuple type whose elements before
+      // and after the segment match the elements around it, and whose
+      // remaining run of elements the segment matches as a pack literal of
+      // those types (docs/design/variadics.md, "Typechecking pattern
+      // matches").
+      case CARBON_KIND(SemIR::TupleType param_tuple): {
+        auto param_elements =
+            context().inst_blocks().Get(param_tuple.type_elements_id);
+        const auto* segment = llvm::find_if(param_elements, [&](auto id) {
+          return context().insts().Is<SemIR::PackType>(id);
+        });
+        auto arg_tuple = context().insts().TryGetAs<SemIR::TupleType>(arg_id);
+        if (segment == param_elements.end() || !arg_tuple) {
+          // Deduce through the tuple's operands as before.
+          worklist_.AddInstArg(param_inst.arg0_and_kind(),
+                               context().insts().Get(arg_id).arg0(),
+                               want_value);
+          if (arg_tuple) {
+            continue;
+          }
+          break;
+        }
+        auto arg_elements =
+            context().inst_blocks().Get(arg_tuple->type_elements_id);
+        size_t num_before = segment - param_elements.begin();
+        size_t num_after = param_elements.end() - segment - 1;
+        if (llvm::any_of(arg_elements, [&](auto id) {
+              return context().insts().Is<SemIR::PackType>(id);
+            })) {
+          // A tuple type with a pack segment in the same position, such as the
+          // impl's own self type, matches segment by segment; merging a pack
+          // segment with other elements is not supported (DR-37, W-215).
+          if (arg_elements.size() != param_elements.size() ||
+              !context().insts().Is<SemIR::PackType>(
+                  arg_elements[num_before])) {
+            return false;
+          }
+          for (auto [param_element_id, arg_element_id] :
+               llvm::zip(param_elements, arg_elements)) {
+            Add(param_element_id, arg_element_id, want_value);
+          }
+          continue;
+        }
+        if (arg_elements.size() < num_before + num_after) {
+          return false;
+        }
+        for (auto [param_element_id, arg_element_id] :
+             llvm::zip(param_elements.take_front(num_before),
+                       arg_elements.take_front(num_before))) {
+          Add(param_element_id, arg_element_id, want_value);
+        }
+        for (auto [param_element_id, arg_element_id] :
+             llvm::zip(param_elements.take_back(num_after),
+                       arg_elements.take_back(num_after))) {
+          Add(param_element_id, arg_element_id, want_value);
         }
+        auto run = arg_elements.drop_front(num_before).drop_back(num_after);
+        llvm::SmallVector<SemIR::InstId> run_ids(run.begin(), run.end());
+        Add(*segment,
+            context().types().GetTypeInstId(GetTupleType(context(), run_ids)),
+            want_value);
         continue;
       }

diff --git a/toolchain/check/eval.cpp b/toolchain/check/eval.cpp
index d632afebd..545b213a1 100644
--- a/toolchain/check/eval.cpp
+++ b/toolchain/check/eval.cpp
@@ -169,14 +169,32 @@ class EvalContext {
       return const_id;
     }

+    if (pack_index_) {
+      return GetConstantValueInSpecific(sem_ir(), specific_id_, sem_ir(),
+                                        inst_id, pack_index_)
+          .second;
+    }
     return GetConstantValueInSpecific(sem_ir(), specific_id_, inst_id);
   }

   // Gets the type of the specified instruction in this context.
   auto GetTypeOfInst(SemIR::InstId inst_id) -> SemIR::TypeId {
+    if (pack_index_) {
+      return GetTypeOfInstInSpecific(sem_ir(), specific_id_, sem_ir(), inst_id,
+                                     pack_index_)
+          .second;
+    }
     return GetTypeOfInstInSpecific(sem_ir(), specific_id_, inst_id);
   }

+  // Fork (VA-2): the pack index of the iteration being evaluated, when the
+  // eval block of a specific's definition is evaluated once per iteration of
+  // its pack expansions.
+  auto pack_index() const -> std::optional<uint64_t> { return pack_index_; }
+  auto set_pack_index(std::optional<uint64_t> pack_index) -> void {
+    pack_index_ = pack_index;
+  }
+
   auto ints() -> SharedValueStores::IntStore& { return sem_ir().ints(); }
   auto floats() -> SharedValueStores::FloatStore& { return sem_ir().floats(); }
   auto entity_names() -> SemIR::EntityNameStore& {
@@ -249,6 +267,8 @@ class EvalContext {
   // instructions that have already been evaluated. This is here rather than in
   // `FunctionEvalContext` so we can reference it from `GetConstantValue`.
   std::optional<LocalEvalInfo> local_eval_info_;
+  // Fork (VA-2): see `pack_index()`.
+  std::optional<uint64_t> pack_index_;
 };
 }  // namespace

@@ -1072,6 +1092,10 @@ auto AddImportedConstant(Context& context, SemIR::Inst inst)
   // We ignore the return value of ReplaceAllFieldsWithConstantValues and just
   // propagate runtime and error constant values into the resulting ConstantId.
   ReplaceAllFieldsWithConstantValues(eval_context, &inst, &phase);
+  // Fork (VA-2): the pack index is symbolic without symbolic operands.
+  if (inst.Is<SemIR::PackIndex>()) {
+    phase = LatestPhase(phase, Phase::CheckedSymbolic);
+  }
   return MakeConstantResult(context, inst, phase);
 }

@@ -3280,6 +3304,27 @@ auto TryEvalTypedInst<SemIR::SymbolicBinding>(EvalContext& eval_context,
   return MakeConstantResult(eval_context.context(), bind, phase);
 }

+// Fork (VA-2): the pack index `$I` is a constant within one iteration of a
+// pack expansion, and otherwise a symbolic constant that depends only on the
+// iteration (docs/design/variadics.md, "Execution Semantics": "Although the
+// value of `$I` can vary during execution, it is nevertheless treated as a
+// constant").
+template <>
+auto TryEvalTypedInst<SemIR::PackIndex>(EvalContext& eval_context,
+                                        SemIR::InstId /*inst_id*/,
+                                        SemIR::Inst inst) -> SemIR::ConstantId {
+  if (auto pack_index = eval_context.pack_index()) {
+    return MakeConstantResult(
+        eval_context.context(),
+        SemIR::IntValue{.type_id = inst.type_id(),
+                        .int_id = eval_context.ints().Add(
+                            static_cast<int64_t>(*pack_index))},
+        Phase::Concrete);
+  }
+  return MakeConstantResult(eval_context.context(), inst,
+                            Phase::CheckedSymbolic);
+}
+
 template <>
 auto TryEvalTypedInst<SemIR::Temporary>(EvalContext& eval_context,
                                         SemIR::InstId inst_id, SemIR::Inst inst)
@@ -3592,6 +3637,77 @@ auto TryEvalBlockForSpecific(Context& context, SemIR::LocId loc_id,
   }
 }

+auto TryEvalPackIterationsForSpecific(Context& context, SemIR::LocId loc_id,
+                                      SemIR::SpecificId specific_id) -> void {
+  auto& specific = context.specifics().Get(specific_id);
+  if (specific.pack_iteration_block_id.has_value()) {
+    return;
+  }
+  const auto& generic = context.generics().Get(specific.generic_id);
+  auto decl_block = context.inst_blocks().Get(generic.decl_block_id);
+  auto definition_block =
+      context.inst_blocks().Get(generic.definition_block_id);
+  // Only a generic that depends on the pack index has values that differ
+  // between iterations.
+  auto is_pack_index = [&](SemIR::InstId inst_id) {
+    return context.insts().Is<SemIR::PackIndex>(inst_id);
+  };
+  if (!llvm::any_of(decl_block, is_pack_index) &&
+      !llvm::any_of(definition_block, is_pack_index)) {
+    return;
+  }
+  llvm::SmallVector<SemIR::InstId> eval_block(decl_block.begin(),
+                                              decl_block.end());
+  eval_block.append(definition_block.begin(), definition_block.end());
+  // Each pack expansion of the definition iterates over the elements of a pack
+  // of the generic, whose arity is one of the specific's arguments.
+  int64_t count = 0;
+  auto bindings = context.inst_blocks().Get(generic.bindings_id);
+  auto args = context.inst_blocks().Get(specific.args_id);
+  for (auto [binding_id, arg_id] : llvm::zip(bindings, args)) {
+    auto binding =
+        context.insts().TryGetAs<SemIR::SymbolicBinding>(binding_id);
+    if (!binding || context.entity_names().Get(binding->entity_name_id).name_id !=
+                        SemIR::NameId::PackArity) {
+      continue;
+    }
+    auto arity = context.sem_ir().GetZExtIntValue(arg_id);
+    if (!arity) {
+      // A symbolic specific is not lowered.
+      return;
+    }
+    count = std::max(count, static_cast<int64_t>(*arity));
+  }
+  if (count == 0) {
+    return;
+  }
+
+  auto size = eval_block.size();
+  auto value_block_id = context.inst_blocks().AddUninitialized(size * count);
+  for (auto& inst_id : context.inst_blocks().GetMutable(value_block_id)) {
+    inst_id = SemIR::InstId::None;
+  }
+  specific.pack_iteration_block_id = value_block_id;
+  specific.pack_iteration_count = count;
+
+  llvm::SaveAndRestore access_context(context.access_context());
+  SetAccessContext(context, generic);
+  EvalContext eval_context(&context, loc_id, specific_id);
+  for (auto index : llvm::seq(count)) {
+    eval_context.set_pack_index(index);
+    for (auto [i, inst_id] : llvm::enumerate(eval_block)) {
+      auto const_id = TryEvalInstInContext(eval_context, inst_id,
+                                           context.insts().Get(inst_id));
+      if (const_id == SemIR::ErrorInst::ConstantId) {
+        context.specifics().Get(specific_id).SetHasError(
+            SemIR::GenericInstIndex::Definition);
+      }
+      context.inst_blocks().GetMutable(value_block_id)[index * size + i] =
+          context.constant_values().GetInstId(const_id);
+    }
+  }
+}
+
 // Information about the function call we are currently executing. Unlike
 // evaluation, execution sequentially interprets instructions, and can handle
 // control flow and (eventually) side effects and mutable state.
diff --git a/toolchain/check/eval.h b/toolchain/check/eval.h
index 459482a98..4935add20 100644
--- a/toolchain/check/eval.h
+++ b/toolchain/check/eval.h
@@ -77,6 +77,13 @@ auto TryEvalBlockForSpecific(Context& context, SemIR::LocId loc_id,
                              SemIR::SpecificId specific_id,
                              SemIR::GenericInstIndex::Region region) -> void;

+// Fork (VA-2): evaluates the eval block for the definition of a specific once
+// per iteration of its pack expansions, when the definition depends on the
+// pack index and the specific's pack arities are known. Writes the
+// per-iteration values to the specific.
+auto TryEvalPackIterationsForSpecific(Context& context, SemIR::LocId loc_id,
+                                      SemIR::SpecificId specific_id) -> void;
+
 }  // namespace Carbon::Check

 #endif  // CARBON_TOOLCHAIN_CHECK_EVAL_H_
diff --git a/toolchain/check/eval_inst.cpp b/toolchain/check/eval_inst.cpp
index 80d36e11c..7a05674c8 100644
--- a/toolchain/check/eval_inst.cpp
+++ b/toolchain/check/eval_inst.cpp
@@ -823,6 +823,89 @@ auto EvalConstantInst(Context& context, SemIR::InstId inst_id,
   return ConstantEvalResult::NewSamePhase(inst);
 }

+// Fork (VA-2): a tuple type's pack segment of known arity is replaced by the
+// pack's element types: `(A, ... «B; 2», ... ⟬C, D⟭)` is `(A, B, B, C, D)`
+// (docs/design/variadics.md, "Reduction rules": "Pack expansion splitting",
+// "Singular expansion removal").
+auto EvalConstantInst(Context& context, SemIR::TupleType inst)
+    -> ConstantEvalResult {
+  auto elements = context.inst_blocks().Get(inst.type_elements_id);
+  bool has_known_segment = false;
+  for (auto element_id : elements) {
+    if (auto pack = context.insts().TryGetAs<SemIR::PackType>(element_id);
+        pack && context.sem_ir().GetZExtIntValue(pack->arity_id) &&
+        (!IsHeterogeneousPackType(context, *pack) ||
+         context.insts().Is<SemIR::PackValue>(pack->element_id))) {
+      has_known_segment = true;
+    }
+  }
+  if (!has_known_segment) {
+    return ConstantEvalResult::NewSamePhase(inst);
+  }
+  llvm::SmallVector<SemIR::InstId> flat_ids;
+  for (auto element_id : elements) {
+    auto pack = context.insts().TryGetAs<SemIR::PackType>(element_id);
+    auto arity =
+        pack ? context.sem_ir().GetZExtIntValue(pack->arity_id) : std::nullopt;
+    if (!arity || (IsHeterogeneousPackType(context, *pack) &&
+                   !context.insts().Is<SemIR::PackValue>(pack->element_id))) {
+      flat_ids.push_back(element_id);
+      continue;
+    }
+    for (auto index : llvm::seq(*arity)) {
+      flat_ids.push_back(context.types().GetTypeInstId(
+          SemIR::GetPackElementTypeId(context.sem_ir(), *pack, index)));
+    }
+  }
+  return ConstantEvalResult::Existing(context.types().GetConstantId(
+      GetTupleType(context, flat_ids)));
+}
+
+// Fork (VA-2): a tuple value's pack segment that is a known pack value is
+// replaced by the pack's elements, as its type's segment is.
+auto EvalConstantInst(Context& context, SemIR::TupleValue inst)
+    -> ConstantEvalResult {
+  auto elements = context.inst_blocks().Get(inst.elements_id);
+  if (!llvm::any_of(elements, [&](SemIR::InstId id) {
+        return context.insts().Is<SemIR::PackValue>(id);
+      })) {
+    return ConstantEvalResult::NewSamePhase(inst);
+  }
+  llvm::SmallVector<SemIR::InstId> flat_ids;
+  for (auto element_id : elements) {
+    if (auto pack = context.insts().TryGetAs<SemIR::PackValue>(element_id)) {
+      auto pack_elements = context.inst_blocks().Get(pack->elements_id);
+      flat_ids.append(pack_elements.begin(), pack_elements.end());
+    } else {
+      flat_ids.push_back(element_id);
+    }
+  }
+  inst.elements_id = context.inst_blocks().AddCanonical(flat_ids);
+  return ConstantEvalResult::NewSamePhase(inst);
+}
+
+// Fork (VA-2): an each-name of a compile-time pack, such as `each T` of
+// `[... each T: I]`, is the `$I`th element of the pack once the pack and the
+// pack index are known (docs/design/variadics.md, "Execution Semantics": "An
+// each-name evaluates to the `$I`th value of the pack it refers to").
+auto EvalConstantInst(Context& context, SemIR::PackElement inst)
+    -> ConstantEvalResult {
+  if (auto pack = context.insts().TryGetAs<SemIR::PackValue>(inst.pack_id)) {
+    if (auto index = context.sem_ir().GetZExtIntValue(inst.index_id)) {
+      auto elements = context.inst_blocks().Get(pack->elements_id);
+      CARBON_CHECK(*index < elements.size(), "Pack index {0} out of range",
+                   *index);
+      return ConstantEvalResult::Existing(
+          context.constant_values().Get(elements[*index]));
+    }
+  }
+  if (context.constant_values().Get(inst.pack_id).is_concrete() &&
+      context.constant_values().Get(inst.index_id).is_concrete()) {
+    return ConstantEvalResult::NotConstant;
+  }
+  return ConstantEvalResult::NewSamePhase(inst);
+}
+
 auto EvalConstantInst(Context& context, SemIR::RequireSpecificDefinition inst)
     -> ConstantEvalResult {
   // This can return false, we just need to try it.
diff --git a/toolchain/check/generic.cpp b/toolchain/check/generic.cpp
index 8112df8b2..b1b08aed6 100644
--- a/toolchain/check/generic.cpp
+++ b/toolchain/check/generic.cpp
@@ -159,9 +159,12 @@ class RebuildGenericConstantInEvalBlockCallbacks : public SubstInstCallbacks {
     bool is_template =
         symbolic.dependence == SemIR::ConstantDependence::Template;

+    // Fork (VA-2): the pack index is symbolic without symbolic operands, like
+    // a binding.
     CARBON_CHECK(
-        is_template || (inst.IsOneOf<SemIR::SymbolicBinding,
-                                     SemIR::SymbolicBindingPattern>()),
+        is_template ||
+            (inst.IsOneOf<SemIR::SymbolicBinding, SemIR::SymbolicBindingPattern,
+                          SemIR::PackIndex>()),
         "Instruction {0} has symbolic constant value but no symbolic operands",
         inst);

@@ -758,6 +761,9 @@ auto ResolveSpecificDefinition(Context& context, SemIR::LocId loc_id,
     }
     TryEvalBlockForSpecific(context, loc_id, specific_id,
                             SemIR::GenericInstIndex::Definition);
+    // Fork (VA-2): a pack expansion over a heterogeneous pack has types and
+    // callees that differ between iterations.
+    TryEvalPackIterationsForSpecific(context, loc_id, specific_id);
   }
   return true;
 }
diff --git a/toolchain/check/handle_binding_pattern.cpp b/toolchain/check/handle_binding_pattern.cpp
index 8a2f4cb9a..1971fbd66 100644
--- a/toolchain/check/handle_binding_pattern.cpp
+++ b/toolchain/check/handle_binding_pattern.cpp
@@ -366,9 +366,12 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
     context.emitter().Emit(name_node, PackExpansionBindingWithoutEach, name_id);
     return false;
   } else if (is_each) {
-    // Fork (VA-1, D-VA-5): a pack's elements are values of a type that does
-    // not depend on the pack, and the operand declares one each-name.
-    if (node_kind != Parse::NodeKind::LetBindingPattern || is_ref) {
+    // Fork (VA-1, D-VA-5; VA-2): a pack's elements are values or compile-time
+    // bindings, such as `... each T: I` in an implicit parameter list, and the
+    // operand declares one each-name.
+    if ((node_kind != Parse::NodeKind::LetBindingPattern &&
+         node_kind != Parse::NodeKind::CompileTimeBindingPattern) ||
+        is_ref || is_template) {
       return context.TODO(name_node,
                           "each-name binding that is not a value binding");
     }
@@ -382,15 +385,52 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
   // element type `E` and the pack's deduced arity `N`: "each X: T" becomes
   // "each X: «T; __N»" (docs/design/variadics.md, "Explicit deduced
   // arities"). A value of that type holds the elements' values (fork VA-1,
-  // D-VA-3).
-  auto element_type_inst_id = SemIR::TypeInstId::None;
-  if (is_each && type_expr.type_component_id != SemIR::ErrorInst::TypeId) {
-    element_type_inst_id = type_expr.type_component_inst_id;
-    auto pack_type_id = GetPackType(context, element_type_inst_id,
-                                    pack_scope->arity_binding_id);
-    type_expr.type_component_id = pack_type_id;
-    type_expr.type_component_inst_id =
-        context.types().GetTypeInstId(pack_type_id);
+  // D-VA-3). Fork (VA-2): "if `T` does not contain an each-name"; when `T` is
+  // the each-name `each U` of a compile-time pack, the binding's type is the
+  // pack `⟬each U⟭` and its arity is `U`'s, so no arity is introduced ("If this
+  // does not introduce any usages of `__N`, we remove its declaration").
+  if (is_each) {
+    bool is_error = type_expr.type_component_id == SemIR::ErrorInst::TypeId;
+    SemIR::TypeId pack_type_id = SemIR::TypeId::None;
+    if (auto each_pack =
+            is_error ? std::nullopt
+                     : GetEachNameTypePack(context,
+                                           type_expr.type_component_inst_id)) {
+      pack_type_id = GetPackType(context, each_pack->first, each_pack->second);
+      // The each-name's pack is a binding of this generic, whose arity binding
+      // the pack's expansions use.
+      pack_scope->arity_binding_id = each_pack->second;
+      if (auto arity = context.pack_binding_arities().Lookup(each_pack->first)) {
+        pack_scope->arity_binding_id = arity.value();
+      }
+    } else {
+      auto arity_type_id =
+          GetSingletonType(context, SemIR::IntLiteralType::TypeInstId);
+      auto arity_entity_name_id = AddBindingEntityName(
+          context, SemIR::NameId::PackArity, SemIR::TypeInstId::None,
+          SemIR::InstId::None, /*is_unused=*/false, BindingPhase::Symbolic);
+      auto arity = AddBindingPattern(
+          context, pack_scope->start_node_id, SemIR::ExprRegionId::None,
+          arity_type_id,
+          {.kind = SemIR::SymbolicBindingPattern::Kind,
+           .type_id = GetPatternType(context, arity_type_id),
+           .entity_name_id = arity_entity_name_id,
+           .subpattern_id = SemIR::InstId::None});
+      pack_scope->arity_pattern_id = arity.pattern_id;
+      pack_scope->arity_binding_id = arity.bind_id;
+      // An invalid element type was diagnosed; the pack keeps its arity, as
+      // in VA-1, and the binding its error type.
+      pack_type_id = GetPackType(context,
+                                 is_error ? SemIR::InstId::None
+                                          : type_expr.type_component_inst_id,
+                                 arity.bind_id);
+    }
+    pack_scope->pack_type_id = pack_type_id;
+    if (!is_error) {
+      type_expr.type_component_id = pack_type_id;
+      type_expr.type_component_inst_id =
+          context.types().GetTypeInstId(pack_type_id);
+    }
   }

   const DeclIntroducerState& introducer =
@@ -568,7 +608,6 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
             // Record the pack for its pack expansion pattern, and for name
             // lookup of its each-name.
             pack_scope->each_binding_pattern_id = result_inst_id;
-            pack_scope->element_type_inst_id = element_type_inst_id;
             context.pack_binding_arities().Insert(context.bind_name_map()
                                                       .Lookup(result_inst_id)
                                                       .value()
@@ -583,6 +622,19 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
         case Parse::NodeKind::CompileTimeBindingPattern:
           result_inst_id =
               make_binding_pattern(SemIR::SymbolicBindingPattern::Kind);
+          if (is_each) {
+            // Fork (VA-2): a compile-time pack, such as the pack of types
+            // `T` of `[... each T: I]`, which the types of later bindings
+            // name by its constant value.
+            pack_scope->each_binding_pattern_id = result_inst_id;
+            auto bind_id =
+                context.bind_name_map().Lookup(result_inst_id).value().bind_name_id;
+            context.pack_binding_arities().Insert(bind_id,
+                                                  pack_scope->arity_binding_id);
+            context.pack_binding_arities().Insert(
+                context.constant_values().GetConstantInstId(bind_id),
+                pack_scope->arity_binding_id);
+          }
           break;
         default:
           CARBON_FATAL("Unexpected node kind {0}", node_kind);
diff --git a/toolchain/check/handle_pack_expansion.cpp b/toolchain/check/handle_pack_expansion.cpp
index e10f50a06..a049a5d7d 100644
--- a/toolchain/check/handle_pack_expansion.cpp
+++ b/toolchain/check/handle_pack_expansion.cpp
@@ -55,12 +55,21 @@ auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
                               .start_node_id = node_id};
   switch (scope.kind) {
     case PackExpansionScope::Kind::Pattern: {
-      // Fork (VA-1, D-VA-5): a pack expansion pattern is supported directly
-      // in a function's explicit parameter list.
-      if (!context.node_stack().PeekIs(
-              Parse::NodeKind::ExplicitParamListStart) ||
-          context.full_pattern_stack().CurrentKind() !=
-              FullPatternStack::Kind::ExplicitParamList) {
+      // Fork (VA-1, D-VA-5; VA-2): a pack expansion pattern is supported
+      // directly in a function's explicit parameter list and in an implicit
+      // parameter list ("An implicit parameter list element of the form `...`
+      // pattern", docs/design/variadics.md, "Pack expansions").
+      bool in_explicit_list =
+          context.node_stack().PeekIs(
+              Parse::NodeKind::ExplicitParamListStart) &&
+          context.full_pattern_stack().CurrentKind() ==
+              FullPatternStack::Kind::ExplicitParamList;
+      bool in_implicit_list =
+          context.node_stack().PeekIs(
+              Parse::NodeKind::ImplicitParamListStart) &&
+          context.full_pattern_stack().CurrentKind() ==
+              FullPatternStack::Kind::ImplicitParamList;
+      if (!in_explicit_list && !in_implicit_list) {
         return context.TODO(node_id,
                             "pack expansion pattern outside an explicit "
                             "parameter list");
@@ -99,21 +108,10 @@ auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
           return false;
         }
       }
-      // The arity of the pack is a deduced parameter of the enclosing full
-      // pattern (docs/design/variadics.md, "Explicit deduced arities").
-      auto arity_type_id =
-          GetSingletonType(context, SemIR::IntLiteralType::TypeInstId);
-      auto entity_name_id = AddBindingEntityName(
-          context, SemIR::NameId::PackArity, SemIR::TypeInstId::None,
-          SemIR::InstId::None, /*is_unused=*/false, BindingPhase::Symbolic);
-      auto arity = AddBindingPattern(
-          context, node_id, SemIR::ExprRegionId::None, arity_type_id,
-          {.kind = SemIR::SymbolicBindingPattern::Kind,
-           .type_id = GetPatternType(context, arity_type_id),
-           .entity_name_id = entity_name_id,
-           .subpattern_id = SemIR::InstId::None});
-      scope.arity_pattern_id = arity.pattern_id;
-      scope.arity_binding_id = arity.bind_id;
+      // Fork (VA-2): the arity of the pack, a deduced parameter of the
+      // enclosing full pattern, is added by the operand's each-name binding,
+      // once its type shows whether it is an arity coercion
+      // (docs/design/variadics.md, "Explicit deduced arities").
       break;
     }
     case PackExpansionScope::Kind::Statement:
@@ -221,6 +219,25 @@ auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
   auto& stack = context.pack_expansion_stack();
   CARBON_CHECK(stack.back().kind == PackExpansionScope::Kind::Expr);

+  // Fork (VA-2): `... each T` for a compile-time pack `T` is a segment whose
+  // elements are `T`'s: its value is the pack `T` itself, as in the tuple
+  // type `(... each T)` (docs/design/variadics.md, "Tuples, packs, segments,
+  // and shapes").
+  if (auto element = context.insts().TryGetAs<SemIR::PackElement>(result_id)) {
+    auto pack_const_id = context.constant_values().Get(element->pack_id);
+    if (pack_const_id.is_constant() &&
+        context.types().Is<SemIR::PackType>(
+            context.insts().Get(element->pack_id).type_id())) {
+      auto scope = stack.pop_back_val();
+      if (!FinishPackExpansionBody(context, node_id, scope)) {
+        return false;
+      }
+      context.node_stack().Push(
+          node_id, context.constant_values().GetInstId(pack_const_id));
+      return true;
+    }
+  }
+
   // Each iteration's element is a value: a pack holds its elements' values
   // (fork VA-1, D-VA-3). The conversion is part of the body, so that an
   // element whose value needs a temporary gets one per iteration.
@@ -243,7 +260,7 @@ auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
   // "The type of a pack expansion expression or pattern is `...B`, where `B`
   // is the type of its body" (docs/design/variadics.md, "Typing and shaping
   // rules"): a pack of the body's type, with the arity of its each-names.
-  auto pack_type_id = GetPackType(
+  auto pack_type_id = GetPackTypeForElementType(
       context, context.types().GetTypeInstId(result_type_id), scope.arity_id);
   // Lowering reads the pack type's value representation in every specific, so
   // each specific's pack type must be complete, even when nothing else requires
@@ -296,9 +313,9 @@ auto HandleParseNode(Context& context, Parse::PackExpansionPatternId node_id)

   // The scrutinee of the pattern is the run of arguments that it matches, of
   // type `«E; N»` for the element type `E` and the deduced arity `N`
-  // (docs/design/variadics.md, "Explicit deduced arities").
-  auto pack_type_id =
-      GetPackType(context, scope.element_type_inst_id, scope.arity_binding_id);
+  // (docs/design/variadics.md, "Explicit deduced arities"), or of type
+  // `⟬each T⟭` when the operand's type is the each-name `each T`.
+  auto pack_type_id = scope.pack_type_id;
   context.node_stack().Push(
       node_id, AddInst<SemIR::PackExpansionPattern>(
                    context, node_id,
@@ -338,7 +355,12 @@ auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
     return true;
   }
   auto& stack = context.pack_expansion_stack();
-  if (stack.empty() || stack.back().kind == PackExpansionScope::Kind::Pattern) {
+  // "The binding pattern's type expression may contain an each-name"
+  // (docs/design/variadics.md, "Pack expansion patterns"): an each-name in a
+  // pattern expansion is in the type of the binding it declares.
+  bool in_pattern =
+      !stack.empty() && stack.back().kind == PackExpansionScope::Kind::Pattern;
+  if (stack.empty()) {
     CARBON_DIAGNOSTIC(EachNameOutsidePackExpansion, Error,
                       "each-name `each {0}` is not inside a pack expansion",
                       SemIR::NameId);
@@ -352,7 +374,9 @@ auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
   // D-VA-5): a function has at most one pack, so this only fails for an
   // each-name of an enclosing function's pack.
   auto& scope = stack.back();
-  if (!scope.arity_id.has_value()) {
+  if (in_pattern) {
+    // The pattern's arity is the pack's, set by its binding.
+  } else if (!scope.arity_id.has_value()) {
     scope.arity_id = arity.value();
   } else if (scope.arity_id != arity.value() &&
              scope.arity_id != SemIR::ErrorInst::InstId) {
@@ -378,13 +402,14 @@ auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
       context, node_id,
       {.type_id =
            GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
+  // Fork (VA-2): for a pack of different types, the element's type is the
+  // each-name of the pack of types, which depends on the pack index.
+  auto element_type_id = GetPackElementType(context, node_id, *pack_type);
   context.node_stack().Push(
-      node_id, AddInst<SemIR::PackElement>(
-                   context, node_id,
-                   {.type_id = context.types().GetTypeIdForTypeInstId(
-                        pack_type->element_type_inst_id),
-                    .pack_id = pack_ref_id,
-                    .index_id = index_id}));
+      node_id, AddInst<SemIR::PackElement>(context, node_id,
+                                           {.type_id = element_type_id,
+                                            .pack_id = pack_ref_id,
+                                            .index_id = index_id}));
   return true;
 }

diff --git a/toolchain/check/import_ref.cpp b/toolchain/check/import_ref.cpp
index 156853427..468ee7e7d 100644
--- a/toolchain/check/import_ref.cpp
+++ b/toolchain/check/import_ref.cpp
@@ -2492,11 +2492,52 @@ static auto TryResolveTypedInst(ImportRefResolver& resolver,
        .arity_pattern_id = AddLoadedImportRef(resolver, arity_pattern)});
 }

+// Fork (VA-2): the pack index, an each-name of a compile-time pack and a pack
+// of constants appear in an imported variadic generic's eval blocks.
+static auto TryResolveTypedInst(ImportRefResolver& resolver,
+                                SemIR::PackIndex inst) -> ResolveResult {
+  auto type_id = GetLocalConstantId(resolver, inst.type_id);
+  if (resolver.HasNewWork()) {
+    return ResolveResult::Retry();
+  }
+  return ResolveResult::Deduplicated<SemIR::PackIndex>(
+      resolver,
+      {.type_id = resolver.local_types().GetTypeIdForTypeConstantId(type_id)});
+}
+
+static auto TryResolveTypedInst(ImportRefResolver& resolver,
+                                SemIR::PackElement inst) -> ResolveResult {
+  auto type_id = GetLocalConstantId(resolver, inst.type_id);
+  auto pack_id = GetLocalConstantInstId(resolver, inst.pack_id);
+  auto index_id = GetLocalConstantInstId(resolver, inst.index_id);
+  if (resolver.HasNewWork()) {
+    return ResolveResult::Retry();
+  }
+  return ResolveResult::Deduplicated<SemIR::PackElement>(
+      resolver,
+      {.type_id = resolver.local_types().GetTypeIdForTypeConstantId(type_id),
+       .pack_id = pack_id,
+       .index_id = index_id});
+}
+
+static auto TryResolveTypedInst(ImportRefResolver& resolver,
+                                SemIR::PackValue inst) -> ResolveResult {
+  auto type_id = GetLocalConstantId(resolver, inst.type_id);
+  auto elems = GetLocalInstBlockContents(resolver, inst.elements_id);
+  if (resolver.HasNewWork()) {
+    return ResolveResult::Retry();
+  }
+  return ResolveResult::Deduplicated<SemIR::PackValue>(
+      resolver,
+      {.type_id = resolver.local_types().GetTypeIdForTypeConstantId(type_id),
+       .elements_id =
+           GetLocalCanonicalInstBlockId(resolver, inst.elements_id, elems)});
+}
+
 static auto TryResolveTypedInst(ImportRefResolver& resolver,
                                 SemIR::PackType inst) -> ResolveResult {
   CARBON_CHECK(inst.type_id == SemIR::TypeType::TypeId);
-  auto element_type_inst_id =
-      GetLocalTypeInstId(resolver, inst.element_type_inst_id);
+  auto element_id = GetLocalConstantInstId(resolver, inst.element_id);
   auto arity_id = GetLocalConstantInstId(resolver, inst.arity_id);
   if (resolver.HasNewWork()) {
     return ResolveResult::Retry();
@@ -2504,7 +2545,7 @@ static auto TryResolveTypedInst(ImportRefResolver& resolver,

   return ResolveResult::Deduplicated<SemIR::PackType>(
       resolver, {.type_id = SemIR::TypeType::TypeId,
-                 .element_type_inst_id = element_type_inst_id,
+                 .element_id = element_id,
                  .arity_id = arity_id});
 }

@@ -5018,9 +5059,18 @@ static auto TryResolveInstCanonical(ImportRefResolver& resolver,
     case CARBON_KIND(SemIR::PackExpansionPattern inst): {
       return TryResolveTypedInst(resolver, inst);
     }
+    case CARBON_KIND(SemIR::PackElement inst): {
+      return TryResolveTypedInst(resolver, inst);
+    }
+    case CARBON_KIND(SemIR::PackIndex inst): {
+      return TryResolveTypedInst(resolver, inst);
+    }
     case CARBON_KIND(SemIR::PackType inst): {
       return TryResolveTypedInst(resolver, inst);
     }
+    case CARBON_KIND(SemIR::PackValue inst): {
+      return TryResolveTypedInst(resolver, inst);
+    }
     case CARBON_KIND(SemIR::PartialType inst): {
       return TryResolveTypedInst(resolver, inst);
     }
diff --git a/toolchain/check/merge.cpp b/toolchain/check/merge.cpp
index b7105e86d..0583aac43 100644
--- a/toolchain/check/merge.cpp
+++ b/toolchain/check/merge.cpp
@@ -340,8 +340,12 @@ static auto CheckRedeclParam(Context& context, bool is_implicit_param,
             prev_param_pattern.As<SemIR::PackExpansionPattern>();
         pattern_stack.push_back({.prev_id = prev_pack_pattern.subpattern_id,
                                  .new_id = new_pack_pattern.subpattern_id});
-        pattern_stack.push_back({.prev_id = prev_pack_pattern.arity_pattern_id,
-                                 .new_id = new_pack_pattern.arity_pattern_id});
+        if (prev_pack_pattern.arity_pattern_id.has_value() &&
+            new_pack_pattern.arity_pattern_id.has_value()) {
+          pattern_stack.push_back(
+              {.prev_id = prev_pack_pattern.arity_pattern_id,
+               .new_id = new_pack_pattern.arity_pattern_id});
+        }
         break;
       }
       case CARBON_KIND(SemIR::DefaultValuePattern new_default_value_pattern): {
diff --git a/toolchain/check/pattern_match.cpp b/toolchain/check/pattern_match.cpp
index a94380280..ee0e09431 100644
--- a/toolchain/check/pattern_match.cpp
+++ b/toolchain/check/pattern_match.cpp
@@ -2314,7 +2314,9 @@ auto MatchContext::DoPreWork(State state,
   AddWork({.pattern_id = pack_pattern.subpattern_id,
            .work = PreWork{.scrutinee_id = scrutinee_id},
            .allow_unmarked_ref = entry.allow_unmarked_ref});
-  if (std::holds_alternative<CalleeState*>(state)) {
+  // Fork (VA-2): a pack whose type is an each-name has no arity of its own.
+  if (std::holds_alternative<CalleeState*>(state) &&
+      pack_pattern.arity_pattern_id.has_value()) {
     AddWork({.pattern_id = pack_pattern.arity_pattern_id,
              .work = PreWork{.scrutinee_id = SemIR::InstId::None}});
   }
diff --git a/toolchain/check/type.cpp b/toolchain/check/type.cpp
index d922091cd..a06b88904 100644
--- a/toolchain/check/type.cpp
+++ b/toolchain/check/type.cpp
@@ -5,6 +5,7 @@
 #include "toolchain/check/type.h"

 #include "toolchain/check/control_flow.h"
+#include "toolchain/check/convert.h"
 #include "toolchain/check/eval.h"
 #include "toolchain/check/facet_type.h"
 #include "toolchain/check/inst.h"
@@ -116,9 +117,77 @@ static auto GetCompleteTypeImpl(Context& context, EachArgT... each_arg)
   return type_id;
 }

-auto GetPackType(Context& context, SemIR::TypeInstId element_type_id,
+auto GetPackType(Context& context, SemIR::InstId element_id,
                  SemIR::InstId arity_id) -> SemIR::TypeId {
-  return GetTypeImpl<SemIR::PackType>(context, element_type_id, arity_id);
+  return GetTypeImpl<SemIR::PackType>(context, element_id, arity_id);
+}
+
+auto IsHeterogeneousPackType(Context& context, SemIR::PackType pack_type)
+    -> bool {
+  return context.types().Is<SemIR::PackType>(
+      context.insts().Get(pack_type.element_id).type_id());
+}
+
+auto GetEachNameTypePack(Context& context, SemIR::TypeInstId type_inst_id)
+    -> std::optional<std::pair<SemIR::InstId, SemIR::InstId>> {
+  auto inst_id = context.constant_values().GetConstantInstId(type_inst_id);
+  if (!inst_id.has_value()) {
+    return std::nullopt;
+  }
+  if (auto access = context.insts().TryGetAs<SemIR::FacetAccessType>(inst_id)) {
+    inst_id = context.constant_values().GetConstantInstId(
+        access->facet_value_inst_id);
+  }
+  auto element = context.insts().TryGetAs<SemIR::PackElement>(inst_id);
+  if (!element ||
+      !context.insts().Is<SemIR::PackIndex>(
+          context.constant_values().GetConstantInstId(element->index_id))) {
+    return std::nullopt;
+  }
+  auto pack_id = context.constant_values().GetConstantInstId(element->pack_id);
+  auto pack_type = context.types().TryGetAs<SemIR::PackType>(
+      context.insts().Get(pack_id).type_id());
+  if (!pack_type) {
+    return std::nullopt;
+  }
+  return std::pair{pack_id, pack_type->arity_id};
+}
+
+auto GetPackTypeForElementType(Context& context,
+                               SemIR::TypeInstId element_type_inst_id,
+                               SemIR::InstId arity_id) -> SemIR::TypeId {
+  if (auto each_pack = GetEachNameTypePack(context, element_type_inst_id)) {
+    return GetPackType(context, each_pack->first, each_pack->second);
+  }
+  return GetPackType(context, element_type_inst_id, arity_id);
+}
+
+auto GetPackElementType(Context& context, SemIR::LocId loc_id,
+                        SemIR::PackType pack_type) -> SemIR::TypeId {
+  auto element_type_id = context.insts().Get(pack_type.element_id).type_id();
+  auto element_pack_type =
+      context.types().TryGetAs<SemIR::PackType>(element_type_id);
+  if (!element_pack_type) {
+    return context.types().GetTypeIdForTypeInstId(
+        context.constant_values().GetConstantTypeInstId(
+            SemIR::TypeInstId::UnsafeMake(pack_type.element_id)));
+  }
+  // The element's type is the each-name of the pack of types: the pack's
+  // element at the pack index, as a type.
+  auto index_id = AddInst<SemIR::PackIndex>(
+      context, loc_id,
+      {.type_id =
+           GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
+  auto element_id = AddInst<SemIR::PackElement>(
+      context, loc_id,
+      {.type_id = context.types().GetTypeIdForTypeInstId(
+           context.constant_values().GetConstantTypeInstId(
+               element_pack_type->element_id.has_value()
+                   ? SemIR::TypeInstId::UnsafeMake(element_pack_type->element_id)
+                   : SemIR::TypeInstId::None)),
+       .pack_id = pack_type.element_id,
+       .index_id = index_id});
+  return ExprAsType(context, loc_id, element_id).type_id;
 }

 auto GetStructType(Context& context, SemIR::StructTypeFieldsId fields_id)
diff --git a/toolchain/check/type.h b/toolchain/check/type.h
index 1507bff35..1cd13fb5b 100644
--- a/toolchain/check/type.h
+++ b/toolchain/check/type.h
@@ -129,10 +129,38 @@ auto GetArrayType(Context& context, SemIR::InstId bound_id,
                   SemIR::TypeInstId element_type_inst_id) -> SemIR::TypeId;

 // Gets the pack type `«element_type; arity»`: the type of a pack expansion
-// segment of `arity` elements of type `element_type`.
-auto GetPackType(Context& context, SemIR::TypeInstId element_type_id,
+// segment of `arity` elements of type `element_type`. Fork (VA-2):
+// `element_id` can instead be a compile-time pack of types or facets of arity
+// `arity_id`, for the pack type `⟬each T⟭`.
+auto GetPackType(Context& context, SemIR::InstId element_id,
                  SemIR::InstId arity_id) -> SemIR::TypeId;

+// Fork (VA-2): returns whether `pack_type` is the type of a pack whose
+// elements' types are the elements of a compile-time pack, `⟬each T⟭`.
+auto IsHeterogeneousPackType(Context& context, SemIR::PackType pack_type)
+    -> bool;
+
+// Fork (VA-2): if `type_inst_id` is an each-name of a compile-time pack of
+// types or facets, `each T`, returns that pack and its arity.
+auto GetEachNameTypePack(Context& context, SemIR::TypeInstId type_inst_id)
+    -> std::optional<std::pair<SemIR::InstId, SemIR::InstId>>;
+
+// Fork (VA-2): gets the type of a pack of `arity_id` elements of type
+// `element_type_inst_id`: `«E; N»`, or `⟬each T⟭` when the element type is the
+// each-name `each T`, whose arity is then `T`'s (docs/design/variadics.md,
+// "Explicit deduced arities": a binding whose type contains an each-name is
+// not rewritten to an arity coercion).
+auto GetPackTypeForElementType(Context& context,
+                               SemIR::TypeInstId element_type_inst_id,
+                               SemIR::InstId arity_id) -> SemIR::TypeId;
+
+// Fork (VA-2): gets the type of an element of a value of `pack_type` on the
+// current iteration of the enclosing pack expansion: the type of `each x`.
+// For `⟬each T⟭`, this is `each T`, a type that depends on the pack index
+// (docs/design/variadics.md, "Iterative typechecking of pack expansions").
+auto GetPackElementType(Context& context, SemIR::LocId loc_id,
+                        SemIR::PackType pack_type) -> SemIR::TypeId;
+
 // Returns a struct type with the given fields.
 auto GetStructType(Context& context, SemIR::StructTypeFieldsId fields_id)
     -> SemIR::TypeId;
diff --git a/toolchain/check/type_completion.cpp b/toolchain/check/type_completion.cpp
index 3fc909b01..0c8361d7c 100644
--- a/toolchain/check/type_completion.cpp
+++ b/toolchain/check/type_completion.cpp
@@ -454,7 +454,18 @@ auto TypeCompleter::AddNestedIncompleteTypes(SemIR::Inst type_inst) -> bool {
       break;
     }
     case CARBON_KIND(SemIR::PackType inst): {
-      Push(context_->types().GetTypeIdForTypeInstId(inst.element_type_inst_id));
+      // Fork (VA-2): a pack of different types needs each of its types.
+      if (IsHeterogeneousPackType(*context_, inst)) {
+        if (auto arity = context_->sem_ir().GetZExtIntValue(inst.arity_id)) {
+          for (auto index : llvm::seq(*arity)) {
+            Push(SemIR::GetPackElementTypeId(context_->sem_ir(), inst, index));
+          }
+        }
+        break;
+      }
+      Push(context_->types().GetTypeIdForTypeInstId(
+          context_->constant_values().GetConstantTypeInstId(
+              SemIR::TypeInstId::UnsafeMake(inst.element_id))));
       break;
     }
     case CARBON_KIND(SemIR::StructType inst): {
@@ -715,8 +726,45 @@ auto TypeCompleter::BuildInfoForInst(SemIR::TypeId type_id,
 auto TypeCompleter::BuildInfoForInst(SemIR::TypeId type_id,
                                      SemIR::PackType pack_type) const
     -> SemIR::CompleteTypeInfo {
-  auto element_type_id =
-      context_->types().GetTypeIdForTypeInstId(pack_type.element_type_inst_id);
+  // Fork (VA-2): a pack of different types holds each element's value
+  // representation, as a tuple value does.
+  if (IsHeterogeneousPackType(*context_, pack_type)) {
+    auto arity = context_->sem_ir().GetZExtIntValue(pack_type.arity_id);
+    bool same_as_object_rep = true;
+    llvm::SmallVector<SemIR::InstId> value_rep_type_ids;
+    SemIR::ObjectLayout layout;
+    if (arity) {
+      layout = SemIR::ObjectLayout::Empty();
+      for (auto index : llvm::seq(*arity)) {
+        auto element_type_id =
+            SemIR::GetPackElementTypeId(context_->sem_ir(), pack_type, index);
+        auto element_info = GetNestedInfo(element_type_id);
+        same_as_object_rep &= element_info.value_repr.IsCopyOfObjectRepr(
+            context_->sem_ir(), element_type_id);
+        value_rep_type_ids.push_back(
+            context_->types().GetTypeInstId(element_info.value_repr.type_id));
+        layout.TryAppendField(element_info.object_layout);
+      }
+    }
+    auto value_rep_id = type_id;
+    if (arity && !same_as_object_rep) {
+      auto types_id = GetOrAddInst<SemIR::PackValue>(
+          *context_, loc_id_,
+          {.type_id = GetPackType(*context_, SemIR::TypeType::TypeInstId,
+                                  pack_type.arity_id),
+           .elements_id = context_->inst_blocks().AddCanonical(
+               value_rep_type_ids)});
+      value_rep_id = GetPackType(*context_, types_id, pack_type.arity_id);
+    }
+    return {.value_repr = MakePointerValueRepr(
+                value_rep_id, same_as_object_rep
+                                  ? SemIR::ValueRepr::ValueAndObjectAggregate
+                                  : SemIR::ValueRepr::ValueAggregate),
+            .object_layout = layout};
+  }
+  auto element_type_id = context_->types().GetTypeIdForTypeInstId(
+      context_->constant_values().GetConstantTypeInstId(
+          SemIR::TypeInstId::UnsafeMake(pack_type.element_id)));
   auto element_info = GetNestedInfo(element_type_id);
   bool same_as_object_rep = element_info.value_repr.IsCopyOfObjectRepr(
       context_->sem_ir(), element_type_id);
diff --git a/toolchain/lower/constant.cpp b/toolchain/lower/constant.cpp
index 8052f72f6..67cd05789 100644
--- a/toolchain/lower/constant.cpp
+++ b/toolchain/lower/constant.cpp
@@ -223,6 +223,28 @@ static auto EmitAsConstant(ConstantContext& context, SemIR::TupleValue inst)
       cast<llvm::StructType>(context.GetType(inst.type_id)));
 }

+// Fork (VA-2): a constant pack value, such as a specific's pack of types, is
+// laid out as its pack type is.
+static auto EmitAsConstant(ConstantContext& context, SemIR::PackValue inst)
+    -> llvm::Constant* {
+  auto* llvm_type = context.GetType(inst.type_id);
+  // A compile-time pack of types or facets has no run-time content.
+  auto elements = context.sem_ir().inst_blocks().Get(inst.elements_id);
+  if (llvm::all_of(elements, [&](SemIR::InstId element_id) {
+        auto type_id = context.sem_ir().insts().Get(element_id).type_id();
+        return type_id == SemIR::TypeType::TypeId ||
+               context.sem_ir().types().Is<SemIR::FacetType>(type_id);
+      })) {
+    return llvm::Constant::getNullValue(llvm_type);
+  }
+  if (auto* array_type = dyn_cast<llvm::ArrayType>(llvm_type)) {
+    return EmitAggregateConstant<llvm::ConstantArray>(context, inst.elements_id,
+                                                      array_type);
+  }
+  return EmitAggregateConstant<llvm::ConstantStruct>(
+      context, inst.elements_id, cast<llvm::StructType>(llvm_type));
+}
+
 static auto EmitAsConstant(ConstantContext& context, SemIR::AddrOf inst)
     -> llvm::Constant* {
   // A constant reference expression is lowered as a pointer, so `AddrOf` is a
diff --git a/toolchain/lower/function_context.cpp b/toolchain/lower/function_context.cpp
index c19fafaa9..e326ab479 100644
--- a/toolchain/lower/function_context.cpp
+++ b/toolchain/lower/function_context.cpp
@@ -206,7 +206,7 @@ auto FunctionContext::GetBlockArg(SemIR::InstBlockId block_id, TypeInFile type)

 auto FunctionContext::IsConstant(SemIR::InstId inst_id) -> bool {
   return GetConstantValueInSpecific(specific_sem_ir(), specific_id_, sem_ir(),
-                                    inst_id)
+                                    inst_id, pack_index_)
       .second.is_constant();
 }

@@ -228,7 +228,7 @@ auto FunctionContext::GetValue(SemIR::InstId inst_id, bool require_value)
   }

   auto [const_ir, const_id] = GetConstantValueInSpecific(
-      specific_sem_ir(), specific_id_, sem_ir(), inst_id);
+      specific_sem_ir(), specific_id_, sem_ir(), inst_id, pack_index_);
   CARBON_CHECK(const_ir == &sem_ir() || const_ir == &specific_sem_ir());
   if (!const_id.is_concrete()) {
     // A file-scope `let` bound to a runtime value has no constant and no
@@ -339,7 +339,7 @@ auto FunctionContext::GetValueServesConstantValueRep(SemIR::InstId inst_id)
     return false;
   }
   auto [const_ir, const_id] = GetConstantValueInSpecific(
-      specific_sem_ir(), specific_id_, sem_ir(), inst_id);
+      specific_sem_ir(), specific_id_, sem_ir(), inst_id, pack_index_);
   if (!const_id.is_concrete()) {
     // The promoted file-scope `let` path (W-069) serves an address-derived
     // value per its disposition, never a folded constant.
@@ -465,8 +465,10 @@ auto FunctionContext::InitializeStorage(SemIR::InstId init_id) -> void {
 }

 auto FunctionContext::GetTypeIdOfInst(SemIR::InstId inst_id) -> TypeInFile {
+  // Fork (VA-2): within an iteration of a pack expansion, an instruction has
+  // its type in that iteration.
   auto [file, type_id] = SemIR::GetTypeOfInstInSpecific(
-      specific_sem_ir(), specific_id(), sem_ir(), inst_id);
+      specific_sem_ir(), specific_id(), sem_ir(), inst_id, pack_index_);
   return {.file = file, .type_id = type_id};
 }

diff --git a/toolchain/lower/function_context.h b/toolchain/lower/function_context.h
index 9436dd706..bee96735b 100644
--- a/toolchain/lower/function_context.h
+++ b/toolchain/lower/function_context.h
@@ -118,6 +118,12 @@ class FunctionContext {
       llvm::function_ref<auto(uint64_t index)->void> finish_iteration = {})
       -> void;

+  // Fork (VA-2): returns the pack index of the current iteration of the pack
+  // expansion being lowered, if any.
+  auto current_pack_index() const -> std::optional<uint64_t> {
+    return pack_index_;
+  }
+
   // Returns the pack index of the current iteration of the pack expansion
   // being lowered.
   auto pack_index() const -> uint64_t {
diff --git a/toolchain/lower/handle_call.cpp b/toolchain/lower/handle_call.cpp
index 91387285b..e681fad76 100644
--- a/toolchain/lower/handle_call.cpp
+++ b/toolchain/lower/handle_call.cpp
@@ -888,9 +888,11 @@ auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
   // Map to the callee in the specific. This might be in a different file than
   // the one we're currently lowering.
   if (context.specific_id().has_value()) {
+    // Fork (VA-2): within an iteration of a pack expansion, the callee is the
+    // one of that iteration.
     auto [const_file, const_id] = GetConstantValueInSpecific(
         context.specific_sem_ir(), context.specific_id(), context.sem_ir(),
-        callee.inst_id);
+        callee.inst_id, context.current_pack_index());
     callee.file = const_file;
     callee.inst_id = const_file->constant_values().GetInstIdIfValid(const_id);
     CARBON_CHECK(callee.inst_id.has_value(),
diff --git a/toolchain/lower/handle_pack_expansion.cpp b/toolchain/lower/handle_pack_expansion.cpp
index f355b2064..9eacc174c 100644
--- a/toolchain/lower/handle_pack_expansion.cpp
+++ b/toolchain/lower/handle_pack_expansion.cpp
@@ -22,15 +22,16 @@ namespace Carbon::Lower {
 // of type `pack_type`.
 static auto GetPackElementAddr(FunctionContext& context,
                                FunctionContext::TypeInFile pack_type,
-                               llvm::Value* storage, llvm::Value* index)
+                               llvm::Value* storage, uint64_t index)
     -> llvm::Value* {
   auto value_repr = context.GetValueRepr(pack_type);
   CARBON_CHECK(value_repr.repr.kind == SemIR::ValueRepr::Pointer,
                "Pack value not passed by address");
-  auto* zero = llvm::ConstantInt::get(index->getType(), 0);
-  return context.builder().CreateInBoundsGEP(
-      context.GetType(value_repr.type().GetPointeeType()), storage,
-      {zero, index}, "pack.elem");
+  // Fork (VA-2): the index is a constant in each iteration, so this also
+  // indexes the tuple-like storage of a pack of different types.
+  return context.builder().CreateConstInBoundsGEP2_32(
+      context.GetType(value_repr.type().GetPointeeType()), storage, 0, index,
+      "pack.elem");
 }

 // Allocates the storage of a value of the pack type `pack_type`.
@@ -50,15 +51,15 @@ static auto StorePackElement(FunctionContext& context,
   context.StoreObject(
       context.GetValueRepr(context.GetTypeIdOfInst(value_id)).type(),
       context.GetValue(value_id),
-      GetPackElementAddr(context, pack_type, storage,
-                         context.builder().getInt64(index)));
+      GetPackElementAddr(context, pack_type, storage, index));
 }

 auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                 SemIR::PackElement inst) -> void {
+  // The element is always the one at the current pack index.
   auto* addr = GetPackElementAddr(
       context, context.GetTypeIdOfInst(inst.pack_id),
-      context.GetValue(inst.pack_id), context.GetValue(inst.index_id));
+      context.GetValue(inst.pack_id), context.pack_index());
   context.SetLocal(
       inst_id,
       context.LoadObject(
diff --git a/toolchain/lower/type.cpp b/toolchain/lower/type.cpp
index c87f5dc76..1d4caafde 100644
--- a/toolchain/lower/type.cpp
+++ b/toolchain/lower/type.cpp
@@ -732,6 +732,11 @@ static auto BuildTypeForInst(FileContext& context, SemIR::PointerType /*inst*/)
           nullptr};
 }

+static auto BuildStructType(FileContext& context,
+                            llvm::MutableArrayRef<llvm::Type*> subtypes,
+                            llvm::ArrayRef<SemIR::ObjectLayout> layouts)
+    -> LoweredTypes;
+
 // Fork (VA-1, D-VA-3): a pack type `«E; N»` is laid out as `N` objects of type
 // `E`. A value of a pack type is the address of a pack of its elements' value
 // representations, whose type is lowered the same way.
@@ -739,9 +744,23 @@ static auto BuildTypeForInst(FileContext& context, SemIR::PackType inst)
     -> LoweredTypes {
   auto arity = context.sem_ir().GetZExtIntValue(inst.arity_id);
   CARBON_CHECK(arity, "Lowering pack type of unknown arity");
+  // Fork (VA-2): a pack of different types is laid out as a tuple of them.
+  if (context.sem_ir().types().Is<SemIR::PackType>(
+          context.sem_ir().insts().Get(inst.element_id).type_id())) {
+    llvm::SmallVector<llvm::Type*> subtypes;
+    llvm::SmallVector<SemIR::ObjectLayout> layouts;
+    for (auto index : llvm::seq(*arity)) {
+      auto type_id = SemIR::GetPackElementTypeId(context.sem_ir(), inst, index);
+      subtypes.push_back(context.GetType(type_id));
+      layouts.push_back(
+          context.sem_ir().types().GetCompleteTypeInfo(type_id).object_layout);
+    }
+    return BuildStructType(context, subtypes, layouts);
+  }
   return {llvm::ArrayType::get(
               context.GetType(context.sem_ir().types().GetTypeIdForTypeInstId(
-                  inst.element_type_inst_id)),
+                  context.sem_ir().constant_values().GetConstantTypeInstId(
+                      SemIR::TypeInstId::UnsafeMake(inst.element_id)))),
               *arity),
           nullptr};
 }
diff --git a/toolchain/sem_ir/generic.cpp b/toolchain/sem_ir/generic.cpp
index 39916801e..489e715ab 100644
--- a/toolchain/sem_ir/generic.cpp
+++ b/toolchain/sem_ir/generic.cpp
@@ -52,9 +52,9 @@ auto SpecificStore::CollectMemUsage(MemUsage& mem_usage,
                     lookup_table_, KeyContext(&specifics_));
 }

-static auto GetConstantInSpecific(const File& specific_ir,
-                                  SpecificId specific_id, const File& const_ir,
-                                  ConstantId const_id)
+static auto GetConstantInSpecific(
+    const File& specific_ir, SpecificId specific_id, const File& const_ir,
+    ConstantId const_id, std::optional<uint64_t> pack_index = std::nullopt)
     -> std::pair<const File*, ConstantId> {
   if (!const_id.is_symbolic()) {
     // The constant does not depend on a generic parameter.
@@ -99,6 +99,27 @@ static auto GetConstantInSpecific(const File& specific_ir,
     // specific.
     return {&const_ir, const_ir.constant_values().Get(symbolic.inst_id)};
   }
+  // Fork (VA-2): within an iteration of a pack expansion, a constant of the
+  // definition region has the value it has in that iteration.
+  if (pack_index && specific.pack_iteration_block_id.has_value() &&
+      *pack_index < static_cast<uint64_t>(specific.pack_iteration_count)) {
+    auto iteration_values =
+        specific_ir.inst_blocks().Get(specific.pack_iteration_block_id);
+    auto size = iteration_values.size() / specific.pack_iteration_count;
+    auto offset = symbolic.index.index();
+    if (symbolic.index.region() == GenericInstIndex::Definition) {
+      offset += specific_ir.inst_blocks()
+                    .Get(specific_ir.generics()
+                             .Get(specific.generic_id)
+                             .decl_block_id)
+                    .size();
+    }
+    auto value_id = iteration_values[*pack_index * size + offset];
+    return {&specific_ir, value_id.has_value()
+                              ? specific_ir.constant_values().Get(value_id)
+                              : SemIR::ConstantId::NotConstant};
+  }
+
   // TODO: Distinguish between parts of the instruction block that we've not
   // reached yet during eval and values that evaluated successfully to
   // ConstantId::NotConstant.
@@ -123,6 +144,45 @@ auto GetConstantValueInSpecific(const File& specific_ir, SpecificId specific_id,
                                inst_ir.constant_values().GetAttached(inst_id));
 }

+auto GetConstantValueInSpecific(const File& specific_ir, SpecificId specific_id,
+                                const File& inst_ir, InstId inst_id,
+                                std::optional<uint64_t> pack_index)
+    -> std::pair<const File*, ConstantId> {
+  return GetConstantInSpecific(specific_ir, specific_id, inst_ir,
+                               inst_ir.constant_values().GetAttached(inst_id),
+                               pack_index);
+}
+
+auto GetTypeOfInstInSpecific(const File& specific_ir, SpecificId specific_id,
+                             const File& inst_ir, InstId inst_id,
+                             std::optional<uint64_t> pack_index)
+    -> std::pair<const File*, TypeId> {
+  auto type_id = inst_ir.insts().GetAttachedType(inst_id);
+  auto const_id = inst_ir.types().GetConstantId(type_id);
+  auto [result_ir, result_const_id] = GetConstantInSpecific(
+      specific_ir, specific_id, inst_ir, const_id, pack_index);
+  return {result_ir, TypeId::ForTypeConstant(result_const_id)};
+}
+
+auto GetPackElementTypeId(const File& sem_ir, PackType pack_type,
+                          uint64_t index) -> TypeId {
+  auto element_inst = sem_ir.insts().Get(pack_type.element_id);
+  if (auto pack_value = element_inst.TryAs<PackValue>()) {
+    // A pack of types or of facets: the element's type is the type that the
+    // pack's element at `index` is, or wraps.
+    auto element_id = sem_ir.inst_blocks().Get(pack_value->elements_id)[index];
+    if (auto facet = sem_ir.insts().TryGetAs<FacetValue>(element_id)) {
+      element_id = facet->type_inst_id;
+    }
+    return sem_ir.types().GetTypeIdForTypeInstId(
+        sem_ir.constant_values().GetConstantTypeInstId(
+            TypeInstId::UnsafeMake(element_id)));
+  }
+  return sem_ir.types().GetTypeIdForTypeInstId(
+      sem_ir.constant_values().GetConstantTypeInstId(
+          TypeInstId::UnsafeMake(pack_type.element_id)));
+}
+
 auto GetTypeOfInstInSpecific(const File& sem_ir, SpecificId specific_id,
                              InstId inst_id) -> TypeId {
   auto type_id = sem_ir.insts().GetAttachedType(inst_id);
diff --git a/toolchain/sem_ir/generic.h b/toolchain/sem_ir/generic.h
index cf5aa9cf6..8e85546e5 100644
--- a/toolchain/sem_ir/generic.h
+++ b/toolchain/sem_ir/generic.h
@@ -140,6 +140,15 @@ struct Specific : Printable<Specific> {
   // directly on Specific so that they pack together.
   bool decl_block_has_error = false;
   bool definition_block_has_error = false;
+
+  // Fork (VA-2): the values of the declaration and definition regions once
+  // per iteration of the pack expansions in the definition, when the generic
+  // depends on the pack index (docs/design/variadics.md, "Execution
+  // Semantics": "Although the value of `$I` can vary during execution, it is
+  // nevertheless treated as a constant"). Each iteration's values are the
+  // declaration block's entries followed by the definition block's.
+  InstBlockId pack_iteration_block_id = InstBlockId::None;
+  int32_t pack_iteration_count = 0;
 };

 // Provides storage for deduplicated specifics, which represent generics plus
@@ -215,6 +224,24 @@ auto GetConstantValueInSpecific(const File& specific_ir, SpecificId specific_id,
                                 const File& inst_ir, InstId inst_id)
     -> std::pair<const File*, ConstantId>;

+// Fork (VA-2): as above, within iteration `pack_index` of the pack expansions
+// of the specific's definition, when the specific has per-iteration values.
+auto GetConstantValueInSpecific(const File& specific_ir, SpecificId specific_id,
+                                const File& inst_ir, InstId inst_id,
+                                std::optional<uint64_t> pack_index)
+    -> std::pair<const File*, ConstantId>;
+auto GetTypeOfInstInSpecific(const File& specific_ir, SpecificId specific_id,
+                             const File& inst_ir, InstId inst_id,
+                             std::optional<uint64_t> pack_index)
+    -> std::pair<const File*, TypeId>;
+
+struct PackType;
+
+// Fork (VA-2): returns the type of the element at `index` of a value of the
+// concrete pack type `pack_type`.
+auto GetPackElementTypeId(const File& sem_ir, PackType pack_type,
+                          uint64_t index) -> TypeId;
+
 // Gets the substituted type of an instruction within a specific. Note that this
 // does not perform substitution, and will return `None` if the substituted type
 // is not yet known.
diff --git a/toolchain/sem_ir/stringify.cpp b/toolchain/sem_ir/stringify.cpp
index 450d36921..3a088432a 100644
--- a/toolchain/sem_ir/stringify.cpp
+++ b/toolchain/sem_ir/stringify.cpp
@@ -877,7 +877,7 @@ class Stringifier {

   auto StringifyInst(InstId /*inst_id*/, PackType inst) -> void {
     *out_ << "«";
-    step_stack_->Push(inst.element_type_inst_id, "; ", inst.arity_id, "»");
+    step_stack_->Push(inst.element_id, "; ", inst.arity_id, "»");
   }

   auto StringifyInst(InstId /*inst_id*/, PartialType inst) -> void {
diff --git a/toolchain/sem_ir/type_iterator.cpp b/toolchain/sem_ir/type_iterator.cpp
index a0ca5337e..55ea137e7 100644
--- a/toolchain/sem_ir/type_iterator.cpp
+++ b/toolchain/sem_ir/type_iterator.cpp
@@ -119,6 +119,9 @@ auto TypeIterator::ProcessType(InstId inst_id) -> std::optional<Step> {
       return Step::TemplateType();
     }

+    // Fork (VA-2): an each-name of a compile-time pack, `each T`, is symbolic
+    // until the pack and the pack index are known, like a tuple access.
+    case PackElement::Kind:
     case TupleAccess::Kind: {
       // Tuple access of a concrete value would have evaluated to the accessed
       // value, so we only see TupleAccess in a type when it's a symbolic value.
@@ -230,9 +233,21 @@ auto TypeIterator::ProcessType(InstId inst_id) -> std::optional<Step> {
       PushInstId(pointer_type.pointee_id);
       return Step::PointerStart();
     }
+    // Fork (VA-2): a pack type, and a tuple type with a pack segment, match
+    // any number of elements, so their structure is a symbolic hole.
+    case PackType::Kind: {
+      return Step::SymbolicType{.entity_name_id = EntityNameId::None,
+                                .facet = inst_id};
+    }
     case CARBON_KIND(TupleType tuple_type): {
       auto inner_types =
           sem_ir_->inst_blocks().Get(tuple_type.type_elements_id);
+      if (llvm::any_of(inner_types, [&](InstId inner_id) {
+            return sem_ir_->insts().Is<PackType>(inner_id);
+          })) {
+        return Step::SymbolicType{.entity_name_id = EntityNameId::None,
+                                  .facet = inst_id};
+      }
       if (inner_types.empty()) {
         return Step::TupleStartOnly{
             {.type_id = sem_ir_->types().GetTypeIdForTypeInstId(inst_id)}};
diff --git a/toolchain/sem_ir/typed_insts.h b/toolchain/sem_ir/typed_insts.h
index 078ad388b..c5a45ac39 100644
--- a/toolchain/sem_ir/typed_insts.h
+++ b/toolchain/sem_ir/typed_insts.h
@@ -1639,9 +1639,15 @@ struct OverloadSetValue {
 // "An each-name evaluates to the `$I`th value of the pack it refers to").
 // `pack_id` is a value of a `PackType`, which holds its elements' values, so
 // the element is read without copying it.
+//
+// Fork (VA-2): when `pack_id` is a compile-time pack, such as the pack `T` of
+// `[... each T: I]`, the element is a symbolic constant that depends on the
+// pack index, and is the `$I`th element of the pack once both are known.
 struct PackElement {
   static constexpr auto Kind = InstKind::PackElement.Define<Parse::NodeId>(
-      {.ir_name = "pack_element", .constant_kind = InstConstantKind::Never});
+      {.ir_name = "pack_element",
+       .is_type = InstIsType::Maybe,
+       .constant_kind = InstConstantKind::SymbolicOnly});

   TypeId type_id;
   InstId pack_id;
@@ -1706,9 +1712,14 @@ struct PackExpansionStatement {
 // `$I` can vary during execution, it is nevertheless treated as a
 // constant"). Its type is `Core.IntLiteral`; lowering supplies its value as a
 // constant on each iteration.
+//
+// Fork (VA-2): the pack index is a symbolic constant, so that anything
+// computed from it inside an expansion body, such as the type of an each-name
+// of a heterogeneous pack, is evaluated once per iteration of each specific.
 struct PackIndex {
   static constexpr auto Kind = InstKind::PackIndex.Define<Parse::NodeId>(
-      {.ir_name = "pack_index", .constant_kind = InstConstantKind::Never});
+      {.ir_name = "pack_index",
+       .constant_kind = InstConstantKind::SymbolicOnly});

   TypeId type_id;
 };
@@ -1729,10 +1740,15 @@ struct PackLiteral {
 };

 // The type `«E; N»` of a pack expansion segment: `arity_id` repetitions of
-// `element_type_inst_id` (docs/design/variadics.md, "Tuples, packs, segments,
-// and shapes"). A pack is a sequence of values, so a value of a pack type
-// holds the value representations of its elements, as a tuple value does,
-// and binding a pack never copies an element.
+// `element_id` (docs/design/variadics.md, "Tuples, packs, segments, and
+// shapes"). A pack is a sequence of values, so a value of a pack type holds
+// the value representations of its elements, as a tuple value does, and
+// binding a pack never copies an element.
+//
+// Fork (VA-2): `element_id` is either a type, for `«E; N»`, or a compile-time
+// pack of types or facets of arity `arity_id`, for the pack `⟬each T⟭` whose
+// `$I`th element has the `$I`th type of that pack, as the type of
+// `... each x: each T`.
 struct PackType {
   static constexpr auto Kind = InstKind::PackType.Define<Parse::NodeId>(
       {.ir_name = "pack_type",
@@ -1741,7 +1757,7 @@ struct PackType {
        .deduce_through = true});

   TypeId type_id;
-  TypeInstId element_type_inst_id;
+  InstId element_id;
   InstId arity_id;
 };

@@ -1750,9 +1766,13 @@ struct PackType {
 // initializes (docs/design/variadics.md, "Pattern matching": "the Nth
 // iteration of the pack expansion will initialize the Nth element of the
 // named pack from the Nth scrutinee").
+//
+// Fork (VA-2): a pack value whose elements are constants is a constant, such
+// as the value that a specific gives the pack `T` of `[... each T: I]`.
 struct PackValue {
   static constexpr auto Kind = InstKind::PackValue.Define<Parse::NodeId>(
-      {.ir_name = "pack_value", .constant_kind = InstConstantKind::Never});
+      {.ir_name = "pack_value",
+       .constant_kind = InstConstantKind::WheneverPossible});

   TypeId type_id;
   InstBlockId elements_id;
@@ -2477,9 +2497,13 @@ struct TupleType {
   static constexpr auto Kind = InstKind::TupleType.Define<Parse::NoneNodeId>(
       {.ir_name = "tuple_type",
        .is_type = InstIsType::Always,
-       .constant_kind = InstConstantKind::WheneverPossible,
+       .constant_kind = InstConstantKind::Conditional,
        .deduce_through = true});

+  // Fork (VA-2): an element may be a pack type, `...«E; N»` or `...⟬each T⟭`,
+  // a segment of the tuple whose elements are the pack's
+  // (docs/design/variadics.md, "Tuples, packs, segments, and shapes"); a
+  // segment of known arity is replaced by its elements when evaluated.
   TypeId type_id;
   InstBlockId type_elements_id;
 };
@@ -2488,9 +2512,11 @@ struct TupleType {
 struct TupleValue {
   static constexpr auto Kind = InstKind::TupleValue.Define<Parse::NodeId>(
       {.ir_name = "tuple_value",
-       .constant_kind = InstConstantKind::WheneverPossible,
+       .constant_kind = InstConstantKind::Conditional,
        .deduce_through = true});

+  // Fork (VA-2): an element may be a pack value of a pack segment, whose
+  // elements are spliced in when the pack is known.
   TypeId type_id;
   InstBlockId elements_id;
 };
```

<!-- google-doc-style-resume -->
