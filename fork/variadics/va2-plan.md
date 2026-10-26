# Variadics plan: definition-checked variadics, slice 2 (VA-2)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 7, 2026-10-26 -- the implementation's second stop-and-amend, at
stage 2 (C1 and F1), which the "Stop-and-amend record (rev 7, 2026-10-26)"
before the Sign-off section records. C1, split from Appendix B as §2.1 and §2.2
assigned its hunks, made `... each T` of a compile-time pack the pack itself but
left in C2 the two hunks that take such a pack as a tuple's element, so C1's
gate aborted in `TypeIterator` on the first `(... each T)` in a type position;
four of C1's golden splits called a generic function that has only a
declaration, which upstream rejects with `use of undefined generic function`;
and two lower rows of §4 described lowerings that VA-1's code does not perform.
Two hunks of Appendix B, type_iterator.cpp's `PackType` case and
`ConvertTupleToType`'s pack segment, move from C2 to C1 (§2.2's block); those
four splits, and three of C2's of the same form, define their functions; §4's
rows are the measured fill's; Appendix B's code is unchanged, and the one
decision that changes is D-VA2-19's split (M-21) (amended 2026-10-26,
implementation: stop-and-amend: C1's split and golden sources). Rev 6
(4d5388af2, 2026-10-26) is the fold of the focused re-review of rev 5
(ef58cf5dd, on C0 d92a9c709), whose verdict was APPROVE-WITH-AMENDMENTS on one
MAJOR, RR5-M1: rev 5 said that upstream's defect in a one-element aggregate
whose element initializes in place is reached by no form or program of this
slice, but §A.6's `Dup(one)` reaches it today, through PR 59's hand-written
`(T,)` impl, and aborts in lowering on PR 59, trunk, the nightly, C0 and C0b,
and from C4 on it reaches C2's unbuilt `PackSegmentInit` for a by-copy
`(Loud,)`; so C4's stage decides, the re-review's probes d01 to d03, with the
control d04, join the probes every stage re-runs after its build, and a d probe
that fails at C4 is a stop at C4. Three MINORs give C0b's commit title C0's
form, `VA-2 C0b:`, record the rejected alternative to C0b's copy (§7.2's A-11)
and re-read upstream's tip, 56d9bbc40, which changes none of the directories R32
covers. Every finding is folded and none is rejected (the rev 6 part of the
"Stop-and-amend record (rev 5, 2026-10-26)"); C0b's block, Appendix B and every
count of rev 5 stand (amended 2026-10-26, review fold: RR5-M1 / RR5-m1 / RR5-m2
/ RR5-m3). Rev 5 (ef58cf5dd, 2026-10-26): rev 4's sign-off for implementation
stands, amended by the implementation's first stop-and-amend, at stage 1 (C0 and
F0), which the "Stop-and-amend record (rev 5, 2026-10-26)" before the Sign-off
section records. C0's fill showed that a nested aggregate constant copied into
storage (a `var`, an in-place `return`, an assignment, a file-scope `var`, a
constant element of a run-time tuple) is copied from its value representation as
if that were its object, and the amender found that a one-element aggregate of
such a value, which PR 59 and trunk copy correctly, aborts on C0, and that C0's
two functions form a recursive call chain that clang-tidy rejects. A new commit
C0b, built and measured on C0 and on the rev 4 prototype, copies such a constant
into storage element by element and builds C0's elementwise values with a
worklist; nothing else in the slice changes, and a focused re-review of the
amendment decides before stage 1 re-runs (amended 2026-10-26, implementation:
stop-and-amend: nested constant initialization). Rev 4 (7188540ca) is the
fixer's fold of the second focused re-review, of rev 3 (8d377a06d), whose
verdict was APPROVE-WITH-AMENDMENTS on one MAJOR, RR2-M1 (a compile-time
each-name was accepted in every parameter list, so packs among a class's, an
interface's or explicit `generic` parameters, OUT in this slice, compiled or
failed with arity errors where PR 59 reports a TODO), and three MINORs. Every
finding is folded and none is rejected (the "Review fold record (rev 4,
2026-10-26)" after rev 3's); the verdict is not REJECT, so rev 4 is signed off,
and the "Sign-off" section tables every review of this plan. Rev 3
(8d377a06d, 2026-10-26) folded the focused re-review of rev 2 (78524522b),
whose verdict was REJECT on one new BLOCKER, NB-1 (a generic with a pack of
different types, used from another library, crashed in lowering, and C4's
prelude impls have that shape), with the MAJOR B-M5 still open and three
MINORs, recorded in the "Review fold record (rev 3, 2026-10-26)". Rev 2
(78524522b) folded the two plan reviews of R29(c) (review A and review B, both
REJECT on rev 1), recorded in the "Review fold record (rev 2, 2026-10-22)";
rev 1 (51c6cfb10) was the planner's draft. Nothing in it is implemented on
this branch. Branch
`claude/carbon-fork-0-1-va2`, worktree /home/user/carbon-va2, cut from PR 59's
head b0822a744 (`claude/carbon-fork-0-1-va`, VA-1, held open, never merged),
whose toolchain is the carbonbuild toolchain of 88b1b5bd2. Every line number
below is against b0822a744 unless a commit or a ref is named; on this branch
docs/design/variadics.md, docs/design/tuples.md, core/prelude/copy.carbon and
core/prelude/operators/comparison.carbon are byte-identical to upstream's
57ba07a97 and to its tip 21c825a3f (M-1), so their line numbers are upstream's
too.

Every measurement is container-local, EXPECTED, not of record (R9). Rev 1's were
taken by the planner with the planner's build of this worktree under
/dev/shm/va2-planner (deleted when rev 1 was written, §8.9), the installs named
in §0.2, a private `XDG_CACHE_HOME`, and the scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2/planner`
(`$Q` below). Rev 2's were taken by the fixer with the fixer's builds under
/dev/shm/va2-fixer (the prototype at its rev 1 and rev 2 states, and the PR 64
mirror of §8.7; deleted when the fold was committed) and the scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2/fixer`
(`$F` below). The prototype that §2 quotes is, since rev 2,
`$F/r3/va2_prototype_rev2.patch` (30 files, 1242 insertions, 121 deletions
against b0822a744): the planner's `$Q/va2_prototype.patch` (26 files, 892
insertions and 105 deletions), M-9's deduction correction
(`$Q/m9/deduce_fix.py`), and the rev 2 corrections of §2
(`$F/r3/rev2_fixes.patch`, made by `$F/rev2_fixes.py`, and
`$F/r3/rank_fix.patch`). It is reachable as the dangling scratch commit
413968218 (on 68e629c97, rev 1 plus the deduction correction, which reproduces
the reviews' measurements of rev 1), used for §0.6's `git merge-tree`; Appendix
B is its diff verbatim and applies with `git apply` (§2.0). The worktree is
b0822a744 plus this plan (amended 2026-10-22, review fold: A-B-1 / A-B-2 / A-B-3
/ A-M-1 / B-m5). Rev 3's were taken by the fixer of the re-review with builds
under /dev/shm/va2-fixer1 (the rev 2 prototype rebuilt from 413968218, its rev 3
state, and the PR 64 mirror with each; deleted when rev 3 was committed) and the
scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2/fixer1`
(`$G` below), whose subdirectory `$G/r` holds every rev 3 number (§8.0). Since
rev 3 the prototype is `$G/r/va2_prototype_rev3.patch` (31 files, 1368
insertions, 122 deletions against b0822a744): rev 2's and the rev 3 corrections
of §2 (`$G/r/rev3_fixes.patch`, 4 files, 150 insertions and 25 deletions against
413968218: check/eval.cpp, handle_pack_expansion.cpp, action.cpp and
convert.cpp, clang-format's re-wrapping of rev 2's lines in those files
included). It is reachable as the dangling scratch commit 80f1ec825 (tree
91dd88f60; its parent a9ba91569, an interrupted attempt's state that named the
arity by a `name_ref`, is superseded), which §0.6's `git merge-tree` and the PR
64 mirror use; Appendix B is its diff verbatim (amended 2026-10-26, review fold:
RR1-NB-1 / RR1-B-M5 / RR1-Nm-3). Rev 4's were taken by the fixer of the second
re-review with builds under /dev/shm/va2-fixer2 (the rev 3 prototype rebuilt
from 80f1ec825, its rev 4 state, and the PR 64 mirror with it; deleted when rev
4 was committed) and the scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2/fixer2`
(`$H` below), whose subdirectory `$H/r` holds every rev 4 number (§8.0). Since
rev 4 the prototype is `$H/r/va2_prototype_rev4.patch` (31 files, 1399
insertions, 122 deletions against b0822a744): rev 3's and the rev 4 corrections
of §2 (`$H/r/rev4_fixes.patch`, 3 files, 60 insertions and 29 deletions against
80f1ec825: check/handle_binding_pattern.cpp, sem_ir/stringify.cpp and
check/eval.cpp, clang-format's re-wrapping of rev 3's lines in those files
included). It is reachable as the dangling scratch commit ca939ee19 (tree
f023437c2, on 80f1ec825), which §0.6's `git merge-tree` and the PR 64 mirror
use; Appendix B is its diff verbatim (amended 2026-10-26, review fold: RR2-M1 /
RR2-m1). Rev 5's were taken by the plan amender of the implementation's
stop-and-amend with the implementer's C0 install, binaries relinked over its
objects under /dev/shm/va2-amend/c0b, the rev 4 prototype with C0b built in full
under /dev/shm/va2-amend/builds (all deleted when rev 5 was committed), and the
scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2-impl/amend5`
(`$J` below), beside the implementer's stage 1 directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2-impl/stage1`
(`$L`). C0b is not part of the prototype: its block is in §2.7, measured against
C0's commit d92a9c709, and Appendix B stays rev 4's (M-20) (amended 2026-10-26,
implementation: stop-and-amend: nested constant initialization). Rev 6's were
taken by the plan amender of the re-review with the implementer's C0 install,
C0b relinked over its objects under /dev/shm/va2-impl/c0b, the rev 4 prototype
with C0b (the scratch commit 90c34dbaa) built in full under
/dev/shm/va2-impl/builds (all deleted when rev 6 was committed), and the scratch
directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2-impl/amend6`
(`$K` below) (amended 2026-10-26, review fold: RR5-M1). Rev 7's were taken by
the plan amender of the implementation's second stop-and-amend with the
implementer's C1 install (/home/user/carbon-build/carbon-va2, built from
8a7395cf1 with the uncommitted split), §2.2's rev 7 block relinked over its
objects under /dev/shm/va2-amend/v1b, C1 with C2's built half built in full
under /dev/shm/va2-amend/builds (all deleted when rev 7 was committed), beside
the implementer's stage 2 directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2-impl/stage2`
(`$N`), and the scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2-impl/amend7`
(`$M` below) (amended 2026-10-26, implementation: stop-and-amend: C1's split and
golden sources).

**Items.** W-212 (generic and heterogeneous packs) and W-225 (variadic impls)
are discharged, and W-213 (tuples with pack segments) is narrowed, not
discharged: its arbiters (Zip's return type, Apply and TupleConcat, W-213's
own notes) need W-330, W-216, W-226, W-217 and W-222, which this slice does
not take (§1.1) (amended 2026-10-22, review fold: B-B1). All three were filed
by VA-1 on PR 59's ledger; W-013 ("W6: implement definition-checked
variadics") stays open. Of the items the brief left to this plan, W-214 (pack
expansion patterns in `let`) and the `if` part of W-218 and W-219 (a statement
expansion whose body is an `if` statement) are taken IN because the prelude
impls need them; W-215, W-216, W-217, W-220, W-221 and the rest of W-218 and
W-219 stay filed; W-222 is narrowed (§1.11).

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
callees; a generic has one pack arity, and a second is a `semantics TODO`
(amended 2026-10-22, review fold: A-B-1). Tuples with pack segments: `(...
each T)` is a tuple type of one pack segment (in a parameter's type, a return
type and an impl's self type), whose value and initializing representations
depend on the specific until the segment's arity is known (amended 2026-10-22,
review fold: A-B-2), a tuple type with a segment of known arity is the tuple
of its elements, a tuple type with one segment deduces the segment's pack from
a tuple argument, `let (... each x: each T) = t;` binds a pack from a tuple,
and `(... each x)` initializes a tuple element by element. Variadic impls:
core/prelude/copy.carbon :50-71's four hand-written tuple `Copy` impls are
replaced by one `impl forall [... each T: Copy] (... each T) as Copy`, and
tuple `EqWith(Self)` and `OrderedWith(Self)` are added in
core/prelude/operators/comparison.carbon in the same shape, their bodies
statement expansions of `if` statements; impl lookup's type structure keeps
the tuple, `(...?)`, as the design's rule does (amended 2026-10-22, review
fold: A-M-1 / B-B2). Two prerequisite commits, C0 and C0b, fix the lowering of
nested aggregate constants, an upstream defect that three of the programs reach
(amended 2026-10-22, review fold: A-B-3), the second added by rev 5 (amended
2026-10-26, implementation: stop-and-amend: nested constant initialization). The
row "Stdlib: tuple/array library parts" stays PARTIAL with W-334's mixed-operand
comparisons and W-339's
comparison semantics for orderings that are not total open (§1.9), and
"Generics: Definition-checked variadics" stays PARTIAL with a narrower Not-yet
list.

**Id allocation.** VA-2 reserves W-330..W-339 and mints no fork design id
(D-VA2-17); since rev 2 it files all ten (§1.11) (amended 2026-10-22, review
fold: A-B-3 / B-M2 / B-M8). Re-scanned for rev 1 on 2026-10-22 over the 89
refs `refs/heads/claude/carbon-fork-0-1-*`,
`refs/remotes/origin/claude/carbon-fork-0-1-*`, `refs/heads/trunk` and
`refs/remotes/origin/trunk` of /home/user/carbon-lang (after `git fetch origin`)
and the `fork/` trees of every /home/user/carbon-* worktree, with VA-1's three
commands widened to `W-3[3-9][0-9]`, and again for rev 2 on 2026-10-22 with
§8.10's commands (89 refs): W-330 and W-399 are named only as the text "no id
from W-330 to W-399" in DR-1's fork/direction/plan.md (:4238 on the dr and
dr-idx refs and worktrees, and :4348 on dr-idx), and no id of W-330..W-339 is
filed anywhere. W-320..W-329 are DR-1's (W-328 reserved for W-320's
resumption). Re-scanned for rev 4 on 2026-10-26 with §8.10's commands (89
refs, after `git fetch origin`; the highest id filed is W-344): the new hits
name W-330..W-339 only as VA-2's reservation, in DR-1b's records (which file
W-340) and in the weekly upstream check's entry of 2026-10-26 (which files
W-341 to W-344) (amended 2026-10-26, review fold: RR2-m3). The discharge
re-runs the scan (§8.10) and re-allocates from the maximum plus one, skipping
reserved blocks, if any of W-330..W-339 is taken by then.

**Design authority**, read at upstream's tip 57ba07a97 (`git fetch upstream
trunk`, by the fixer on 2026-10-22; "Switch inline function definition
synthesis to use plans", 2026-10-22 07:25:01 UTC), one commit past rev 1's
ebc155734, and that commit changes only toolchain/benchmarking, so `git diff
ebc155734 57ba07a97 -- docs proposals core toolchain/check toolchain/lower
toolchain/sem_ir` is empty and every line number below holds at both (amended
2026-10-22, review fold: B-m1), and again by the fixer of the re-review at
21c825a3f on 2026-10-26, whose 13 further commits change none of these pages
and none of the toolchain files quoted (M-1) (amended 2026-10-26, review fold:
RR1-Nm-3), and by the fixer of the second re-review on 2026-10-26, for whom
`git fetch upstream trunk` and `git ls-remote upstream refs/heads/trunk` gave
21c825a3f again, with check/handle_binding_pattern.cpp, check/eval.cpp and
sem_ir/stringify.cpp, rev 4's files, unchanged there since 57ba07a97 (amended
2026-10-26, review fold: RR2-m3), each quoted where used (R32(a)):

-   docs/design/variadics.md (p002240): "Packs and each-names" (:84-102), "Pack
    expansions" (:104-158), "Pack expansion expressions and statements"
    (:160-203), "Pack expansion patterns" (:205-237), "Additional examples"
    (:239-293: SumInts, StrCat, Min, Apply, MiddleVariadic, TupleConcat),
    "Execution Semantics" (:295-345), "Tuples, packs, segments, and shapes"
    (:349-449), "Iterative typechecking of pack expansions" (:451-493), "Type
    versus execution semantics" (:495-528, upstream's a045da8e6), "Typechecking
    patterns" (:530-623), "Typechecking pattern matches" (:625-677), the
    appendix (:679-973), "Alternatives considered" (:975-995).
-   docs/design/generics/details.md "Type structure of an impl declaration"
    (:4686-4699) and "Overlap rule" (:4906-4929) (amended 2026-10-22, review
    fold: A-M-1 / B-B2).
-   docs/design/tuples.md "Operations performed field-wise" (:106-121) and
    docs/design/expressions/comparison_operators.md "Default implementations
    for basic types" (:479-505), with its `EqWith` and `OrderedWith` contracts
    (:311-316, :457-464) (amended 2026-10-22, review fold: A-m-1 / A-m-2).
-   proposals/p002240-variadics.md ("Generalize `expand`" :504, "Omit
    each-names" :555, "Allow multiple pack expansions in a tuple pattern"
    :735); p002687 (:186-193, :210-215 variadic count keys); p002875
    (`Core.Call` variadic, :227, :531); p002274 (proposals/
    p002274-subscript-syntax-and-semantics.md :250-257, indexing interfaces
    deferred until variadics).
-   core/prelude/copy.carbon (:50-71) and
    core/prelude/operators/comparison.carbon (:11-60, `EqWith`'s `default fn
    NotEqual` at :14-16) at 57ba07a97.
-   toolchain/check/handle_pack_expansion.cpp at 57ba07a97 (:10-23, three
    `context.TODO` handlers), toolchain/check/impl_lookup.cpp at 57ba07a97
    (:199, "TODO: Implement the termination rule") and
    toolchain/lower/file_context.cpp at 57ba07a97 (`GetConstant`, which still
    builds a pointer value representation's global from the object
    representation, M-12).

**V-3 check (R32).** Every mechanism this plan adds is the design's, spelled as
the page spells it at 57ba07a97, with the page quoted in §1: implicit parameter
list packs (:113-114, "An implicit parameter list element of the form `...`
_pattern_"), binding types that use an each-name (:219-221, read with :532-534,
register entry (iv)), the pack index as a per-iteration constant (:300-303),
tuple segments and shapes (:357-421), the tuple indexing and pack splitting
reductions (:765-818), expansion of a pack segment in a tuple type (:490-491),
`let` with a pack expansion pattern (:110-111 and :870-873), statement
expansions of any statement (:108, :305-306), impl lookup's type structure
("find the type structure by deleting deduced parameters and replacing type
parameters by a `?`", details.md :4688-4689, so `(... each T)` is `(...?)`) and
its overlap rule (:4921-4929), and the prelude's own tuple impls in upstream's
file layout (copy.carbon keeps `Copy`, comparison.carbon gains the tuple
comparisons beside `bool` and `IntLiteral`), whose `!=` is field-wise with the
elements' `!=`, because docs/design/tuples.md lists "equality and inequality
comparison" among the operations "defined for tuples field-wise" (:108-114; rev
2 used `EqWith`'s default, `not Equal`) (amended 2026-10-26, review fold:
RR1-Nm-2). Rev 1 claimed no second spelling, but its type-structure hole
replaced the whole tuple `(... each T)` by one `?`, deleting the tuple
constructor the design's rule keeps: a second spelling of upstream's
type-structure rule (R32(d)), which made a blanket `impl forall [T: type] T as
I` beside a variadic tuple impl an error (§0.2 M-15). Rev 2 realigns: the tuple
is kept and its segment is a run inside it (D-VA2-8) (amended 2026-10-22, review
fold: A-M-1 / B-B2). `...expand` (:121-133), whose typechecking the design
leaves as "**TODO:** Discuss typechecking `...expand`." (:493), is not
implemented and gets a V-3a register entry (§1.12), so the design's Apply and
TupleConcat stop at the design's text; the bare pack name stays VA-1's
`semantics TODO` (W-230, p002240 "Omit each-names" :555), also a register entry
since rev 2 (amended 2026-10-22, review fold: B-M8); `each x: auto` (:732-734)
is blocked by `auto` parameters, which upstream's toolchain has not implemented
either (`HandleAutoTypeLiteral`, check/handle_literal.cpp:177 at 57ba07a97; §0.2
p11 and p13). The fork's SemIR (a symbolic `PackIndex`, per-iteration value
blocks of a specific, pack-typed tuple elements, a run entry in the type
structure) is internal representation where upstream has none
(handle_pack_expansion.cpp:10-23 at 57ba07a97 are TODOs, and upstream's
TypeIterator has no pack type); §6.3 says how the next advance takes upstream's
shapes where they differ. Rev 3's two mechanisms are upstream's too: an
expansion over a pack of an enclosing generic names the arity by a
`specific_constant` of that generic's self specific, as upstream's e1c8c1f85
makes every reference to a name of an enclosing generic (D-VA2-4), and a
dependent action on an element of a pack of different types is refused in
upstream's `AddDependentActionInst`, the function every dependent action already
passes through, not in a second deferral path (D-VA2-14) (amended 2026-10-26,
review fold: RR1-NB-1 / RR1-B-M5). Where the design is silent and the slice
still has to behave somehow, the plan reads the design's nearest text, records
the reading as a V-3a register entry with its work item, owner and next action,
and pins it with a golden or a program (§1.12): how a segment ranks against a
`?` in the overlap rule (W-338), tuple comparisons over elements whose orderings
are not total (W-339), and the fixed-arity `let` binding type (:219-221 against
:532-534, W-214) (amended 2026-10-22, review fold: A-m-2 / A-m-3 / B-B2 / B-M8).
One narrowing is recorded as a register entry with a work item, not as a drift:
the tuple comparison impls compare tuples of the same type only, where
comparison_operators.md :504-505 says "Comparisons between tuples permit
implicit conversions for either operand, but not both" (W-334, §1.12).

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Upstream at the tip, and every commit since the cut (R32(c))

M-1. `git rev-list --count c1e83b0b7..ebc155734` is 103, and 104 to
57ba07a97, whose one further commit changes only toolchain/benchmarking (4
files) (amended 2026-10-22, review fold: B-m1). Rev 3 read upstream again at
21c825a3f (`git fetch upstream trunk` on 2026-10-26; "Hot-path optimizations
for `(Canonical)ValueStore::Add`", 2026-10-26 06:38:17 UTC), 117 commits past
the cut: its 13 commits past 57ba07a97 change no design page, no proposal, no
prelude file and nothing under toolchain/lower or toolchain/sem_ir, and under
toolchain/check only cpp/export.cpp, cpp/import.cpp, name_lookup.cpp and
goldens, none of them a file this plan changes, so every line number below
holds at 21c825a3f too (amended 2026-10-26, review fold: RR1-Nm-3). `git diff
b0822a744 57ba07a97 -- docs/design/variadics.md docs/design/tuples.md
docs/design/expressions/comparison_operators.md
proposals/p002240-variadics.md
proposals/p002687-termination-algorithm-for-impl-selection.md
proposals/p002875-functions-function-types-and-function-calls.md
proposals/p002274-subscript-syntax-and-semantics.md core/prelude/copy.carbon
core/prelude/operators/comparison.carbon` is empty, and so is the same diff
to 21c825a3f; rev 1 named the p002274
file `p002274-subscripts-and-indexing.md`, which does not exist, so its check
of that proposal was vacuous; the path above is the file's, and the re-run is
empty (amended 2026-10-22, review fold: B-m1). The only design-page
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
| 503f09037 | Add support for default values for non-generic parameters of generic functions. | W-215's defaults beside a pack: a watch noted in W-215 (rev 1's register entry (iii), not an open question, amended 2026-10-22, review fold: B-M8) |
| 505c4ae30 | Fix crash building impl witness thunks for constrained generic methods | thunk.cpp; a variadic impl's functions take no pack (§1.6) |
| 831a2aee9, 5402b4c56, 46e7eacba, 6a0a1f3e8, f0b030f2c, e39bdb7af, 77fc0a3ef, fb7eff130, ac31fd198 | impl lookup and `IdentifiedFacetType` plumbing | the next advance's conflicts in impl_lookup.cpp; VA-2 changes no line of it (§6.2) |
| 4441c5340 | Simplify `GetConstantValue` | eval.cpp; VA-2's `EvalContext` edit collides textually (§6.3) |
| 72e425fe5 | Clean up some leftover references to the old `:!` syntax. | the brief's `:!` is stale (§0.8) |
| bf5d2a2ac | Add support for `-> auto` deduced return types. | Apply's `-> auto` (:276) arrives with the next advance; it changes check/call.cpp (+24) and check/control_flow.cpp and .h, which C3 also edits (§6.3) (amended 2026-10-22, review fold: A-m-4 / B-m1) |
| 24766e213 | Defer evaluation of witnesses substituted while identifying a facet type | impl lookup and facet types (609 files, mostly goldens); the next advance's conflicts with SC-1 and with VA-2's impl_lookup.cpp ranking hunk (§6.3) (amended 2026-10-22, review fold: A-m-4 / B-m1) |
| 6c1d2a86e | Fix crashes on impl lookup for bound method types | impl_lookup.cpp beside VA-2's ranking hunk (§6.3) (amended 2026-10-22, review fold: B-m1) |
| b1de0e037 | Give the facet type as a TypeId to IdentifyFacetType functions | facet-type plumbing that VA-2's per-element requirement checks call; no rule (amended 2026-10-22, review fold: B-m1) |
| 1b0a5709e | Initial support for fn expressions. | a new callee kind beside the call grouping VA-1 changed; no rule (amended 2026-10-22, review fold: B-m1) |
| 57ba07a97 | Switch inline function definition synthesis to use plans | toolchain/benchmarking only; none (amended 2026-10-22, review fold: B-m1) |

Rev 2's table was built from the subjects and missed commits that touch the
files this plan changes without touching a rule; the re-review named eight of
them. `git log --format=%h c1e83b0b7..21c825a3f --` over the rev 3
prototype's 31 files, the files C2 to C4 add (§6.2), core/prelude,
docs/design/variadics.md, docs/design/tuples.md and
docs/design/expressions/comparison_operators.md lists 49 commits
(`$G/r/m1_all.txt`): 20 are in the table above and the other 29 are below,
with the files of this plan each touches. Five bear on rev 3's mechanisms, as
their rows say; the rest change other functions of those files, and `git
merge-tree --write-tree --name-only` of 21c825a3f gives the same 104
conflicted paths against b0822a744 as against the rev 3 prototype (§6.3), so
none adds a conflicted path (amended 2026-10-26, review fold: RR1-Nm-3):

| Commit | Subject | Files of this plan | Bearing on VA-2 |
| --- | --- | --- | --- |
| eb66bebc3 | New specifics formed during identify need to be marked `identified` (#8003) | check/eval.cpp, check/generic.cpp, check/type_completion.cpp, sem_ir/formatter.cpp | other functions of those files; no rule |
| 2e2125585 | Partial support for a generic class inheriting from a virtual C++ class (#8007) | lower/file_context.cpp | other functions of those files; no rule |
| 9799a2326 | Export function default values to C++ (#7988) | check/context.h, lower/file_context.cpp | other functions of those files; no rule |
| b766aa4d1 | Support for terse `=>` function bodies (#7895) | check/eval.cpp, sem_ir/formatter.cpp | other functions of those files; no rule |
| 0d3b606a5 | Support calls to generic functions with deduced return types. (#7981) | check/action.cpp, check/eval.cpp | action.cpp and eval.cpp beside rev 3's refusal and `TryEvalPackIterationsForSpecific`; no rule |
| 14a3de9ff | Fix import of `val` and `ref` return forms. (#7989) | check/import_ref.cpp | other functions of those files; no rule |
| 3af25cc1b | Support for `-> ref/var/val auto`. (#7977) | check/import_ref.cpp, check/merge.cpp, sem_ir/formatter.cpp, sem_ir/typed_insts.h | other functions of those files; no rule |
| d87891f3a | Fix diagnostic style issues (#7982) | check/eval.cpp | other functions of those files; no rule |
| 7beb29f8b | Use a fallback loc for diagnostics generated on canonical insts (#7967) | check/convert.cpp, check/pattern_match.cpp, sem_ir/typed_insts.h | other functions of those files; no rule |
| 2c9739799 | Render diagnostics through the terminal library (#7683) | check/convert.cpp, check/deduce.cpp, check/eval.cpp, check/eval_inst.cpp, check/handle_binding_pattern.cpp, check/impl_lookup.cpp, check/merge.cpp, check/pattern_match.cpp, lower/file_context.cpp, lower/function_context.cpp | other functions of those files; no rule |
| e1c8c1f85 | Use `specific_constant` when referring to name in enclosing generic (#7936) | sem_ir/dominance.cpp, sem_ir/typed_insts.h | the mechanism of rev 3's arity reference (D-VA2-4, M-17); the fork's name lookup does not wrap yet, and the advance makes it wrap every name of an enclosing generic, each-names included (§6.3) |
| 2b2a78ca1 | Recover from errors while importing a generic (#7932) | check/generic.cpp | generic.cpp's import of a generic, beside the `ResolveSpecificDefinition` hook; no rule |
| 51e2c76a8 | Add a HasError helper to SpecificStore (#7970) | check/type_completion.cpp, sem_ir/generic.h | other functions of those files; no rule |
| e41862d55 | Handle ImplSelfWitness appearing in the RHS of a rewrite constraint in impl decl (#7943) | check/eval_inst.cpp | other functions of those files; no rule |
| f0bae9637 | Verify non-extend require constraints are satisfied at `impl as` definition (#7937) | check/type_completion.cpp, sem_ir/stringify.cpp | other functions of those files; no rule |
| 66a250ad9 | Support importing `CustomLayoutType` (#7958) | check/import_ref.cpp | other functions of those files; no rule |
| d4f1ec203 | Introduce a CheckedSaveAndRestore like llvm::SaveAndRestore (#7965) | check/context.h, check/eval.cpp | other functions of those files; no rule |
| 71af20740 | Disable global state that modifies eval while resolving a specific (#7923) | check/eval.cpp | `TryEvalBlockForSpecific` clears `declaring_impl_decls` while it resolves a specific; the fork has no such state yet, and when the advance brings it `TryEvalPackIterationsForSpecific`, which evaluates the same blocks once per iteration, takes the same exchange (§6.3) |
| df4ef552a | Add missing case for non-parameterized generic classes. (#7952) | check/import_ref.cpp | other functions of those files; no rule |
| 9a4d4b332 | Roll llvm to b08e005 (2026-10-08) (#7960) | lower/constant.cpp, lower/function_context.h | other functions of those files; no rule |
| 62f1cc6a3 | Rename `GenericClassType` to `ParameterizedClassType` (#7953) | check/import_ref.cpp, check/merge.cpp, check/type.cpp, check/type.h, check/type_completion.cpp, lower/type.cpp, sem_ir/inst_kind.def, sem_ir/inst_namer.cpp, sem_ir/stringify.cpp, sem_ir/type_iterator.cpp, sem_ir/typed_insts.h | other functions of those files; no rule |
| 230227264 | Only allocate return storage when the callee has a return parameter (#7886) | check/convert.cpp | other functions of those files; no rule |
| 9fd28f730 | Lower `return expr;` for value return forms of class type (#7908) | lower/file_context.cpp, lower/type.cpp | other functions of those files; no rule |
| 73c247f1e | Fix crash when importing a generic non-parameterized class (#7925) | check/import_ref.cpp | other functions of those files; no rule |
| 059ee7b9e | Parse `-> ref T` as a primitive return form (#7911) | check/convert.cpp | other functions of those files; no rule |
| 5b587a885 | List function name not NameId in dominance failure. (#7916) | sem_ir/dominance.cpp | other functions of those files; no rule |
| 4a8993af2 | Fix "<unexpected>" inst when creating an InitializeAction (#7900) | check/action.cpp, check/convert.cpp, check/eval.cpp, sem_ir/typed_insts.h | action.cpp and convert.cpp's `InitializeAction` site, beside rev 3's refusal (D-VA2-14); no rule |
| bf91a8b4d | Canonicalize the self in ImplSelfWitness (#7898) | check/eval_inst.cpp, sem_ir/typed_insts.h | other functions of those files; no rule |
| 5fed32a9a | Check support for simple `friend` declarations (#7890) | check/context.h | other functions of those files; no rule |

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
(`0.0.0-0.dev+0bdce60a5`), the nightly 2026.10.12 (`+62f1cc6`, a differential
oracle only, never a measurement of record; rev 1 cited R30 for this, which is
the rule on bidirectional assertions, amended 2026-10-22, review fold: B-m3),
TP-1's /home/user/carbon-build/carbon-tp (`+eafca5cb9`; round 11 changed
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

The rev 2 prototype (`proto2`, Appendix B) gives the proto column's outcome
on every row above (`$F/r3/probes_rank.txt`), so the table stands for both;
the rows that rev 2 changes are M-12 to M-15's (amended 2026-10-22, review
fold: A-B-1 / A-B-2 / A-B-3 / A-M-1).

p02 and p14 are the cores of §A.1's `variadics_hetero_digits_diff`, p15 of §A.3,
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
exactly once (§A.6; rev 1 cited §A.8, amended 2026-10-22, review fold: B-m5).

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
SKIP 21 of 158, bullets 49/0/7: unchanged (`$Q/logs/conf_proto4.log`). The
rev 2 prototype measures the same: gate 1955 passed and 5 failed, the same
five, whose autoupdate is again 125 insertions and 145 deletions in the same
three classes (`$F/r3/va1_churn_stat.txt`), and conformance PASS 137, 0
failures, SKIP 21 of 158, bullets 49/0/7 (`$F/r3/conf_rank.log`) (amended
2026-10-22, review fold: A-B-1 / A-B-2 / A-M-1).

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
    non-tuple argument's first operand as a tuple's element block, and rev 1's
    type-structure hole (D-VA2-8 before rev 2) made the variadic impl a
    candidate for every `Copy` query. p26 runs only because the misread
    `ClassId` of `i32` happens to be a valid block index.
-   With §2.3's one-branch correction (`deduce_fix.py`, rebuilt): p02, p14,
    p24, p24b, p25 and p26 run or compile as before; `return self;` is
    rejected, "cannot copy value of type `«T; <pack arity>»`" (A-7); with the
    body `return TupleCopyProxy(self);` over a defined generic helper
    (`m9_prelude_v4.py`; the helper calls itself, so a run that reaches it
    does not return), p08, p22, p09 and p10 compile (the variadic impls are
    selected for `==`, `<` and the copies), p23 is still rejected (W-334),
    and conformance is PASS 137, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0,
    OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 21 (of 158), bullets 49/0/7: no
    existing program changes with C4's declarations. But p20, p20b, p20c and
    §A.6 crashed in lowering (`HandleInst` of a `Call` in a variadic impl
    function's specific), §A.7 and §A.8 failed LLVM's verifier ("Global
    variable initializer type does not match global variable type!"), and the
    gate crashed on full-prelude lower goldens that lower a tuple copy. Rev 1
    attributed all three to C2's unbuilt lowering of `PackSegmentInit`; that
    was wrong (amended 2026-10-22, review fold: A-B-2 / A-B-3 / B-M6). The
    `Call` crash is the generic's representation of `(⟬each T⟭)`: rev 1
    computed it from the one pack element, a concrete 1-tuple representation
    returned by copy, while each specific returns in place, so the call in the
    specific had no return slot (M-13, A-B-2). The verifier failure is an
    upstream lowering defect of nested aggregate constants that every
    toolchain has, with no variadics involved (M-12, A-B-3); §A.7 and §A.8 hold
    such constants.
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
-   Re-measured on the rev 2 prototype with the same v5 proxies
    (`$F/r3/m9r.sh`; amended 2026-10-22, review fold: A-B-2 / A-B-3 / A-m-4 /
    B-M6 / B-m4): nothing crashes and nothing fails LLVM's verifier. The gate
    is 1911 passed and 49 failed of 1960, with no golden excluded: VA-1's five
    and 44 full-prelude goldens, the same 43 check goldens and
    toolchain/lower/testdata/for/bindings.carbon, whose autoupdate is 394
    insertions and 392 deletions and reaches its fixpoint on the second pass
    (`$F/r3/churn_v5.diff`); all 43 check goldens are pure renames after
    normalizing the `.loc` and hexadecimal suffixes (checked mechanically,
    all 43), and bindings.carbon changes its specifics' mangled hashes and
    lowers the `(i32, i32)` copy through the variadic impl's `Op`, which
    returns in place (`ptr sret({ i32, i32 }) %return`) through the proxy
    helper. Conformance is PASS 137, 0 failures, SKIP 21 of 158, bullets
    49/0/7. p09, p10, p22, §A.7 and §A.8 (the rev 1 sources) compile, link and
    run (p22 prints 101 four times, 1, 101 twice, 1; the comparison proxies
    print their constants); p20, p20b, p20c, p21, r17, §A.6 and §A.9 compile
    and link and are not run, because the proxy helper calls itself; p23 is
    still rejected (W-334). This count of 44 is a lower bound, not the
    refill's exact size: the proxies add a helper and its parameter and
    return constants, and C2 to C4's real bodies (`let` destructuring,
    `PackSegmentInit`, `... if`) can rename more SemIR names in the same
    files, so D-VA2-15 predicts the set and C4's fill measures it (amended
    2026-10-22, review fold: A-m-4 / B-m4).
-   Re-measured on the rev 3 prototype with proxy bodies that hold a
    statement expansion over the impl's pack, since v5's held none and so
    could not see M-17 (`$G/r/m9.sh` with `$G/r/m9_prelude_v7.py`: every
    proxy body first runs `... TupleProxyTouch(each T);`, one call of an
    explicit-generic helper per element, then returns v5's result) (amended
    2026-10-26, review fold: RR1-NB-1): the gate is 1911 passed and 49 failed
    of 1960, VA-1's five and the same 44 full-prelude goldens
    (`$G/r/gate_v7.log`), whose autoupdate reaches its fixpoint on the second
    pass with 405 insertions and 392 deletions (`$G/r/churn_v7_stat.txt`): the
    43 check goldens are renames (42 equal once the suffixes are normalized,
    checked mechanically, and interop/cpp/operators/ordered_with.carbon's
    `@Ordered` becomes `@Ordered.2`), and toolchain/lower/testdata/for/
    bindings.carbon lowers the `(i32, i32)` copy through the imported
    variadic impl's `Op`, which calls `TupleProxyTouch`'s specific twice, once
    per element, before the proxy helper: M-17's path, through the real
    prelude's import. Conformance is PASS 137, 0 failures, SKIP 21 of 158
    (`$G/r/conf_v7.log`); p09, p10, p22, p24, p24b, p26, x04, x05, x05b, r09,
    r09c to r09e and the rev 2 sources of §A.7 and §A.8 run, and p20, p20b,
    p20c, p21, r17 and the rev 2 sources of §A.6 and §A.9 compile and link
    (`$G/r/probes_v7.txt`); p23 is still rejected (W-334). On the rev 2
    prototype, pl1, a body of the same shape appended to the prelude,
    aborts (M-17).

M-10. The three C++ oracles (§A.1, §A.7, §A.8), compiled with LLVM 21.1.8's
`clang++ -std=c++17 -Wall -Wextra -Werror -stdlib=libc++` and run
(`$Q/oracles`), print exactly the hand-derived lines of §5.

M-11. The nine rev 1 programs parse on PR 59's install; the four stdlib
programs, which use no pack syntax, check there with errors only at their
tuple impl lookups (`cannot convert type ... into type implementing Core.Copy`,
`Core.Eq` or `Core.Ordered`, or `cannot access member of interface
Core.EqWith(...)`); the five generics programs stop at VA-1's TODO, as §0.2
predicts. The twelve golden sources' 52 splits parse there too. That check ran
only the check phase, so it could not see M-12's lowering defect in three of
them (amended 2026-10-22, review fold: A-B-3). Rev 2's new and changed
sources (§A.7 to §A.10, `$F/r3/programs`) parse on PR 59's install, and its
three changed stdlib programs check there with errors only at their tuple impl
lookups, as before (amended 2026-10-22, review fold: A-m-1 / A-m-2 / B-M1 /
B-M3). Nor could it see R-13's class: §A.6's `Dup(one)` checks on PR 59 and
aborts in its lowering there, on trunk, on the nightly, on C0 and on C0b (M-20's
d01) (amended 2026-10-26, review fold: RR5-M1).

M-12. Nested aggregate constants (amended 2026-10-22, review fold: A-B-3).
`let t: ((i32, i32), i32) = ((1, 2), 3);` followed by any use (reviewer A's
r16, r16g passing it to a function, r16h with `var`) aborts at lowering with
"Global variable initializer type does not match global variable type!" on
PR 59, trunk and the nightly 2026.10.12 (reviewer A's measurement, reproduced
by the fixer on PR 59 and on the rev 1 prototype, `$F/r3/probes_rev1.txt`), and
so does a nested struct constant (`$F/r3/probes/x07_nested_const_struct.carbon`
on PR 59: the same abort). The cause, read from
toolchain/lower/file_context.cpp `GetConstant` (unchanged at 57ba07a97): for a
constant whose value representation is a pointer, it makes a global of the
value representation's pointee type and initializes it with the lowered
constant, which is the object representation; for `((i32, i32), i32)` the
value representation is elementwise, `{ ptr, i32 }`, the inner tuple's value
held by pointer, while the object is `{ { i32, i32 }, i32 }`. The rev 2
prototype builds the elementwise value representation of a constant tuple or
struct value from its elements' constants (§2.0's C0): r16 prints 3 2, r16g 3,
r16h 3 and x07 2 5 9, and no existing golden or program changes (M-6's rev 2
line). A run-time nested tuple was never affected (r16c).
Those probes lower values only: none copies the constant into storage (r16h's
`var` reads `.1`, at offset 8 in both layouts), and C0 alone copies a nested
constant into storage wrong, which C0b corrects (M-20) (amended 2026-10-26,
implementation: stop-and-amend: nested constant initialization).

M-13. A tuple type with a pack segment returned in place (amended 2026-10-22,
review fold: A-B-2). Reviewer A's r17, a variadic impl's `fn Op(self) -> Self
{ return Id(self); }` over a generic `Id`, aborted in `Lower::HandleInst(Call)`
with an `ArrayRef` index assertion on the rev 1 prototype (reproduced,
`$F/r3/out_rev1/r17_self_return.compile.txt`), the stack of M-9's p20 and
p20c, while r17b (`Self` as a parameter) ran. The generic declared `Op` with a
return slot of the concrete 1-tuple representation of `(⟬each T⟭)`, and its
call `Id(self)` and `return` used none. With rev 2's dependent representation
(§2.3, type_completion.cpp) r17 compiles and links, and M-9's re-measure
lowers every variadic impl function it reaches.

M-14. Two pack arities in one generic (amended 2026-10-22, review fold:
A-B-1). Reviewer A's r02, `fn F[... each T: HasN](unused t: (... each T), ...
each n: i32)` called as `F((1 as i32, true), 100, 200, 300)`, and r02b abort on
the rev 1 prototype with "CHECK failure at toolchain/check/eval_inst.cpp:897:
*index < elements.size(): Pack index 2 out of range" (reproduced), because the
arity binding is added per each-name binding whose type names no pack, the
specific has one symbolic `PackIndex`, and its iteration count is the largest
arity. The fixer's f04, a pack in a function of a variadic impl (a second arity
through the enclosing generic), compiles silently on rev 1. On rev 2 all three
are `semantics TODO: more than one pack arity in a generic` (§2.2), and VA-1's
D-VA-5 invariant, one pack arity per generic, is enforced instead of assumed.

M-15. Impl ranking (amended 2026-10-22, review fold: A-M-1 / B-B2). On the rev
1 prototype a blanket `impl forall [T: type] T as I` beside `impl forall [...
each T: type] (... each T) as I` is "found non-final `impl` with the same type
structure as another non-final `impl`" in either order (reviewer A's r01 and
r01b, reproduced), as are `(i32, ... each T)` beside `(... each T)` (r14), the
three-impl `x05` (blanket, variadic, `(T, U)`) and `x06` (`(... each T, bool)`
beside `(... each T)`), where PR 59 and the nightly run a blanket beside a
fixed `(T, U)` (r01c: 2). On rev 2 (`$F/r3/probes_rank.txt`): r01 and r01b
print 2 1 (the variadic impl for `(i32, i32)`, the blanket for `i32`), r14
prints 1 2 and its reversal x14 1 2, x05 and its reversal x05b print 1 3 2 2
(blanket for `i32`, `(T, U)` for a 2-tuple, the variadic impl for a 3-tuple
and for `()`), x06 and its reversal x06b print 1 2 1 (`(... each T, bool)`
for `(i32, bool)` and `(bool,)`, the variadic impl for `(bool, i32)`), x11 and
x11b print 1 (`(U, ... each T)` over `(... each T, U)` for `(i32, bool)`), r05
prints 1 2 2, and x12, two variadic impls of one structure, is the existing
same-type-structure error. An intermediate rev 2 state that keyed ranking by
the impl's own structure picked x06b's `(bool,)` by declaration order; the
ranking against the query (§2.3) removed that.

M-16. The rest of rev 2's probes (`$F/r3/probes_rank.txt`, amended 2026-10-22,
review fold: A-m-5 / B-M3 / B-M5 / A-M-2): the design's StrCat with Core's
missing names declared locally stops at VA-1's `pack expansion element that
needs a cleanup` (W-220) when `ToString` returns a class (x01) or a struct
(x13), and runs with an `i64` result (x13b: 3 4 41107 0; the program of §A.10:
4 3 41107 0 0); forwarding a pack of different types to a pack of one type is
`semantics TODO: forwarding a pack of different types to a pack of one type,
or the reverse` (f06, f07, x08), where rev 1 said "cannot implicitly convert
non-type value of type `«Core.ImplicitAs(i64); <pack arity>»` to `type`"; a
diagnostic names `each T` (f01) and `(... each T)` (f03), where rev 1 printed
"<cannot stringify inst...: {kind: PackElement, ...}>" and `(«T; <pack
arity>»,)`; DR-17's `fn F(unused t: (... i32))` is VA-1's "pack expansion does
not use any each-name" on PR 59 and both prototypes (x03); binding a tuple of
`Loud` with `let` prints no copy on PR 59 and rev 2, and a `var` copy of it
prints each element's copy once (x15: 0 1 2 101 102 3); an `overload fn` set
with a heterogeneous-pack member, or a heterogeneous pack forwarded to one, is
VA-1's `variadic member of an overload set` or `pack expansion argument in a
call to an overload set` (x16, x17; W-223), so OV-1's `GetExplicitArityRange`
(call.cpp:578, exact arity) is never reached with a pack; EqWith's default
`NotEqual` runs on PR 59 (x04: 11 1); and f64's `nan <= nan` is false where
`not (nan < nan)` is true (x10: 0 1).

M-17. Generics with packs of different types used from another library, and
statement expansions in a variadic impl's functions (amended 2026-10-26,
review fold: RR1-NB-1). The fixer of the re-review rebuilt the rev 2
prototype (413968218, whose tree 5b9a5c2ec is the re-review's) under
/dev/shm/va2-fixer1 and reproduced every case of the re-review with
`$G/r/run_set.sh` (`$G/r/set_rev2.txt`; `$G/r/run_imp.sh` compiles the
library alone, then the library and its user in one invocation, links and
runs). i1 (an imported `Sum[... each T: HasV]` and an imported variadic
impl), i2 (`Sum`), i5 (`Count[... each T: type]` calling a generic `One`) and
the fixer's i8 (an imported variadic function forwarding its pack to another)
abort with "CHECK failure at toolchain/lower/file_context.h:185:
type_id.has_value(): Should not be called with `None`" in
`HandleInst(PackElement)` under `LowerPackExpansionBody`; i3 (an imported
`impl forall [... each T: HasN] (... each T) as K` whose `Get` runs `... s +=
(each T).N;`) and pl1 (`$G/imp/pl1_proxy.txt`, an impl of that shape whose
body runs `... TupleProbeTouch(each T);`, appended to the install's
comparison.carbon and used from a one-file program) abort with
"handle_pack_expansion.cpp:96: arity: Pack arity ... is not an integer" in
`HandleInst(PackExpansionStatement)`; the homogeneous control i6 prints 8 2,
pl0 (a program that does not use the proxy) 5 and same5 (i5 in one file) 3.
Checking alone passes in every case. There are two root causes, which the
scratch commit 48edb5127 (rev 2 plus rev 3's check/eval.cpp alone) separates:
on it i1, i2, i5 and i8 run and i3, same3, f10 and pl1 still abort
(`$G/r/set_evalonly.txt`).

-   An imported generic's bindings are import references (`AddLoadedImportRef`
    in import_ref.cpp's `SetGenericDataForResolveResult`) whose constant
    values are the bindings, and `TryEvalPackIterationsForSpecific` read them
    as `SymbolicBinding` instructions, found no `<pack arity>`, and gave no
    specific of an imported generic per-iteration values, so each
    iteration's `PackElement` had no type (i1, i2, i5, i8). Rev 3 reads each
    binding through its constant value (C1, check/eval.cpp).
-   A statement expansion over a pack of an enclosing generic, in i3 and pl1
    a variadic impl's pack in the impl's function, named the impl's
    `<pack arity>` binding as its arity, whose constant is attached to the
    impl's generic, and lowering looked it up in the function's specific. The
    fixer's same3 (i3 in one file) and f10 (an impl body calling `Size(each
    T)`, an explicit generic, once per element) abort in one file with
    "CHECK failure at toolchain/sem_ir/generic.cpp:84: ... Given a specific
    for the wrong generic", so the defect is not the import's; across
    libraries that check is skipped (generic.cpp:80-81, "TODO: Enforce this
    check even if the generic and specific are in different IRs") and the
    lookup reads an entry of the function's specific that is not an integer.
    No rev 2 probe lowered such a body: M-9's proxies held no expansion, and
    the re-review's v13 stops at the second-arity TODO first. Rev 3 names the
    arity by a `specific_constant` of the enclosing generic's self specific,
    upstream's mechanism of e1c8c1f85 (D-VA2-4; C2,
    check/handle_pack_expansion.cpp).

On the rev 3 prototype (80f1ec825, `$G/r/set_rev3.txt`): i1 prints 16 9,
i2 16, i3 46, i5 3, i6 8 2, i8 116 0, same3 46, same5 3, f10 3 0, pl0 5 and
pl1 1. The 131 earlier probes and programs that `$G/r/probes_all.sh` runs (the
planner's, reviewer A's, the rev 2 fixer's and the re-review's probes and the
rev 2 programs) give their rev 2 outcomes on rev 3 except f10, which now runs
(`$G/r/probesall_rev2.txt` against `probesall_rev3.txt`). The new splits of
§A.11 check and lower as §4 says (`$G/r/goldens_rev3.txt`, compiled with
`--optimize=none` where §4 describes lowered calls): lower `use` lowers the
imported `ForEach` specific's three `Get` calls in order and the imported
`Count` specific's calls of `One`'s three specifics, `impl_body` and
`impl_use` add 3, 40 and 3, `body_expansion`'s `pack_expansion_statement`
takes its arity from `specific_constant @tuple.type.as.Sum.impl.%arity...,
@tuple.type.as.Sum.impl(constants.%arity, constants.%T...)`, and
`cpp_template_outer` checks with no diagnostic. The gate is 1955 passed and 5
failed (VA-1's five, M-6), whose autoupdate is rev 2's 125 insertions and 145
deletions line for line (`$G/r/va1_churn_rev3.diff`), and conformance is PASS
137, 0 failures, SKIP 21 of 158 (`$G/r/gate_rev3.log`, `conf_rev3.log`).

M-18. Dependent actions inside an expansion over a pack of different types
(amended 2026-10-26, review fold: RR1-B-M5). On the PR 64 mirror with rev 2's
S-CT hunk (0084da002: 4a3220c11 merged with 413968218 by §6.2's rules 1 and
2, plus `$F/r3/s_ct.patch`; `$G/r/set_m64r2.txt`) the re-review's finding
reproduces: ct1, ct2, ct4 and ct8 report S-CT's `C++ call on an element of a
pack of different types` and ct3 prints 7, but ct5 (`Cpp.SizeOfFn(each T)`,
`each T: type`), ct6 (`Cpp.Traits(each T).size`, a C++ class template), ct7
(ct5 with `each T: I`) and the fixer's ctD (`Cpp.Traits((each T)*).size`)
pass check and abort in lowering with "CHECK failure at
toolchain/sem_ir/inst.h:249: Is<TypedInst>(): Casting inst {kind:
CallAction, ...} to wrong kind InstValue"; the controls ctA (8 8 1 1), ctB
(`Cpp.Traits(T).size` for a non-pack `T`: 8 1), ctC (a pack of one type: 19)
and ctE (`Cpp.Traits(U).size + (each x as i32)` in an expansion over a pack
of different types, an action whose operands do not depend on the pack
index: 19) run. The defect is VA-2's own, not only the composition's: on the
rev 2 prototype alone (`$G/r/set_rev2.txt`) ct6 and ctD abort the same way,
because upstream's `PerformCallToNonFunction` (check/call.cpp:903, its
`AddDependentActionSplice` at :933) defers a C++ template applied to a
symbolic argument as a `CallAction` that each specific performs once; there
ct1, ct2, ct4 and ct8 stop at upstream's "call argument of type `each T` is
not supported" and ct5 and ct7 at "no matching function for call to
'SizeOfFn'" (no C++ function call is deferred without CT-1), and ctB, ctC
and ctE run as above. On the rev 3 prototype (`$G/r/set_rev3.txt`) ct6 and
ctD report `semantics TODO: C++ or template-dependent action on an element
of a pack of different types` at the template's call, once each, and the
rest are unchanged. On PR 64 merged with rev 3 and nothing else (4234cdb6f:
4a3220c11 merged with 80f1ec825 by the same two rules, no land-time code;
`$G/r/set_m64r3.txt`) ct1, ct2, ct4, ct5, ct6, ct7, ct8 and ctD report that
TODO, ct3 prints 7, ctA 8 8 1 1, ctB 8 1, ctC 19 and ctE 19, ct9 (a pack of
one type used only as a type argument) is VA-1's "pack expansion does not
use any each-name", every import and proxy probe of M-17 prints its rev 3
output, S-CT's three splits (§A.11) each report the TODO once
(`$G/r/goldens_m64r3.txt`), the gate is 1972 passed and 5 failed (VA-1's
five, M-6; `$G/r/gate_m64r3.log`), and conformance is PASS 156, 0 failures,
SKIP 19 of 175 (`$G/r/conf_m64r3.log`): every program that passes on PR 64's
own install (147 of 167, `$G/r/conf_ct.log`) or on the rev 3 prototype passes,
and VA-1's `variadics_each`, a SKIP on PR 64, passes.

M-19. Compile-time packs outside a function's or an impl's implicit list, the
pack of types in a specific's name, and template actions on elements of packs
of different types (amended 2026-10-26, review fold: RR2-M1 / RR2-m1 /
RR2-m2). The fixer of the second re-review rebuilt the rev 3 prototype
(80f1ec825) under /dev/shm/va2-fixer2 and reproduced the re-review's cases
with `$H/r/run_rr2.sh` over the re-review's probes (`$S/rr2/probes`) and the
fixer's (`$H/probes`): `$H/r/rr2set_rev3.txt`, with PR 59's outcomes in
`rr2set_va.txt`. On rev 3, `class Tup(... each T: type) {}` (v3) compiles,
`Tup(i32, bool)` (v7) reports `2 arguments passed to generic class expecting
1 argument`, `Tup(i32)` (v8) `cannot deduce value for generic parameter
<pack arity>`, `interface I(... each T: type)` (v6, vA, vF) and `class C(...
each n: i32)` (vC) the same arity errors, and `fn Count(... generic each T:
type)` (vB, vD, vH) `cannot deduce value for generic parameter T`, where PR
59 reports `semantics TODO: each-name binding that is not a value binding` at
`each T` for each; the fixer's k1, k2 and k6, a pack in a class's or an
interface's implicit list, compile on rev 3. ctF (`return
Cpp.Traits((... each T)).size;`) reports `unable to monomorphize specific
F(<cannot stringify inst...: {kind: PackValue, ...}>)` with PR 59's note
`semantics TODO: unsupported type used as template argument` (ctF0, without
packs, reports `F(i32)` and the note once), and then that TODO three more
times without a location, once per element: `TryEvalPackIterationsForSpecific`
evaluated the failed definition block again in each iteration, outside
`TryEvalBlockForSpecific`'s monomorphization context. The re-review's tp1,
tp3, tp4 and tp5 (upstream's `[template U: type, ... each T: I]` with
`u.Get(each x)`, `u[each x]`, `u as each T` and `Sink(each x, u)`) report
C1's `C++ or template-dependent action on an element of a pack of different
types`, and tp2 (`u.n + each x.V()`) prints 211.

Rev 4's three corrections (`$H/r/rev4_fixes.patch`, the scratch commit
ca939ee19): check/handle_binding_pattern.cpp accepts a compile-time each-name
only when the full pattern is an implicit parameter list and the
declaration's introducer is `fn` or `impl`, and otherwise reports `semantics
TODO: each-name binding of a class, interface or explicit compile-time
parameter` before any arity binding is added (D-VA2-4); sem_ir/stringify.cpp
prints a `PackValue` as its pack literal, which the concrete pack type now
reuses (§2.1); and `TryEvalPackIterationsForSpecific` returns at once for a
specific whose eval blocks have an error (§2.2). On rev 4
(`$H/r/rr2set_rev4.txt`), v2, v3, v5 to vH and the fixer's k1, k2, k4
(`... generic each T: type` before a value pack), k5 (a variadic method of a
variadic class) and k6 report the new TODO at the each-name, each with PR
59's count of diagnostics; v4 (`... each T: type`, a value pack in an explicit
list) keeps `argument for generic parameter is not a compile-time constant`,
as on PR 59 and rev 3, and k3 (a template each-name of a class) keeps
`each-name binding that is not a value binding`, the text C1 relabels. ctF
reports `unable to monomorphize specific F(⟬i32, i64, bool⟭)` with the note,
once, and the fixer's ctF2 `F(⟬i32⟭)`. tp1, tp3, tp4, tp5 and ctG to ctJ are
unchanged and tp2 prints 211, tp6 5, a1 46 0, a2 46, b1 4046, b2 4046 10346
10300, c1 1014 1010, c2 1014, d1 1046 1080, and the fixer's k7 (an impl's and
a function's implicit packs, the control) 46 43. The fixer's tpG (a template
callee that fails for one element's type) reports, on rev 3 and rev 4 alike,
`unable to monomorphize specific G(each T)` and `G(i32)`, as upstream reports
`G(T)` and `G(i32)` for tpG0 without packs, and `G(each ⟬Has, i32⟭)` (rev 3:
`each <cannot stringify ...>`) for the specific's symbolic iteration, the
same upstream report of a template specific of a symbolic argument once more;
no golden pins tpG. The six new splits of §A.11 check as §4 says
(`$H/r/goldens_rev4.txt`; on rev 3, `goldens_rev3.txt`, the class, interface
and `generic` splits check without a diagnostic and the C++ split prints the
`<cannot stringify ...>` name and the three repeats). The re-review's other
sets give rev 3's outcomes line for line on rev 4, and rev 3's are the
re-review's own: `$H/r/run_set.sh` (i1 16 9, i2 16, i3 46, i5 3, i6 8 2, i8
116 0, same3 46, f10 3 0, pl1 1, ct1 to ctE) and the 131 probes and programs
of `$H/r/probes_all.sh` (`set_rev3.txt` against `set_rev4.txt`,
`probesall_rev3.txt` against `probesall_rev4.txt`). The gate is 1955 passed
and 5 failed (VA-1's five, M-6), whose autoupdate is rev 3's 125 insertions
and 145 deletions line for line (`$H/r/va1_churn_rev4.diff`), and conformance
is PASS 137, 0 failures, SKIP 21 of 158 (`$H/r/gate_rev4_raw.log`,
`conf_rev4.log`). On PR 64 merged with rev 4 (5499d8dd9: rev 3's mirror
4234cdb6f merged with ca939ee19, which merges without a conflict; no
land-time code; `$H/r/set_m64r4.txt`, `rr2set_m64r4.txt` and
`goldens_m64r4.txt`), every case of the re-review's mirror set prints the
re-review's mirror outcome (ct1, ct2, ct4 to ct8 and ctD the TODO, ct3 7, ctA
8 8 1 1, ctB 8 1, ctC and ctE 19, and M-17's probes as above), the second
re-review's probes print rev 4's outcomes but ctH (VA-1's `pack expansion
does not use any each-name`) and ctJ (333), which CT-1's deferral changes as
the re-review measured, S-CT's three splits report the TODO once each, the
gate is 1972 passed and 5 failed (VA-1's five; `$H/r/gate_m64r4_raw.log`),
and conformance is PASS 156, 0 failures, SKIP 19 of 175
(`$H/r/conf_m64r4.log`), rev 3's mirror's counts.

M-20. Copies of nested aggregate constants into storage (amended 2026-10-26,
implementation: stop-and-amend: nested constant initialization). The implementer
built C0 (d92a9c709, on this branch, not pushed) and filled its golden
(`$L/nc_pass1.carbon`, not committed), and the fill contradicted §4's `var` row:
`var v: ((i32, i32), i32) = ((4, 5), 6);` lowers to a 12-byte memcpy into
`%v.var` from `@tuple.c42.loc4_3 = internal constant <{ ptr, i32 }> <{ ptr
@tuple.8a1.loc4_3, i32 6 }>`, the value representation, so `v.0` receives the
inner tuple's address; and the value splits hold a packed `<{ ptr, i32 }>` where
§4 wrote `{ ptr, i32 }`, because the Carbon layout of `(ptr, i32)` has no tail
padding and lower/type.cpp's `BuildStructType` packs every such type. The gate
was red on that golden alone, with no crash (`$L/gate1.log`), and conformance
was unchanged, 137/0/21 of 158 (`$L/conf-c0.log`). The amender reproduced it
with 36 probes, `$J/probes` (a01 to a20) and `$J/probes_impl` (the implementer's
v01 to v04, reviewer A's r16, r16g and r16h, the rev 2 fixer's x07 and RR1's c01
to c08), each compiled, linked and run by `$H/r/run_probe.sh` through
`$J/run_set.sh`: a01 to a20 on PR 59, trunk and the nightly 2026.10.12
(`$J/set_va_probes.txt`, `set_trunk.txt`, `set_nightly.txt`), the other 16 on PR
59 (`set_va.txt`), all 36 on C0's install (`set_c0_probes.txt`, `set_c0.txt`)
and on C0 with C0b relinked over its objects (`set_c0b2.txt`). "Indeterminate"
is a value that changes from run to run:

| Probe | PR 59, trunk and the nightly | C0 | C0 and C0b |
| --- | --- | --- | --- |
| v01, `var v: ((i32, i32), i32) = ((4, 5), 6);` printing every element (PR 59 only) | verifier abort ("Global variable initializer type does not match global variable type!") | two indeterminate values, then 6 | 4 5 6 |
| v02, a nested struct constant in a `var` (PR 59 only) | the same abort | two indeterminate values, then 3 | 1 2 3 |
| v04, `return ((4, 5), 6);` into the return slot (PR 59 only) | the same abort | two indeterminate values, then 6 | 4 5 6 |
| a04, `(((1, 2), 3), Id(4))` into a `var`: a constant element of a run-time tuple, initialized in place | the same abort | two indeterminate values, then 3 4 | 1 2 3 4 |
| a05, `v = ((7, 8), 9);` | the same abort | two indeterminate values, then 9 | 7 8 9 |
| a07, `((i64, i32), i64)` with tail padding, in a `var` and passed as a value | the same abort | the `var`'s three elements wrong, two of them indeterminate; the value's 5 6 right | 1 2 3 5 6 |
| a08, a file-scope `var g: ((i32, i32), i32) = ((1, 2), 3);` | the same abort | two indeterminate values, then 3 | 1 2 3 |
| a10, a11, a12, a14, a15 and a17: a struct of a tuple, `bool`, `i8` beside `i64`, an array element, a class element and three levels, each in a `var` | the same abort | wrong: a11 prints 1 and skips its 7, the others print wrong values, most of them indeterminate | 4 5 6; 7 1; 1 2 3; 1 2 3 4; 1 2 3; 1 2 3 4 |
| a18, a nested constant returned by two specifics of a generic | the same abort | indeterminate values | 1 2 3 1 3 |
| a01, `var v: ((i32, i32),) = ((1, 2),);`, and a16, `var s: {.a: (i32, i32)} = {.a = (1, 2)};` | 1 2 | `CHECK failure` at lower/function_context.cpp:522, `value->getType() == llvm_type` in `StoreObject` | 1 2 |
| a02, that 1-tuple bound by `let` and passed | `CHECK failure` at lower/handle_call.cpp:984 (the nightly :783), an argument mismatch | 1 2 | 1 2 |
| a06, a09 and a13: a class field, an array of tuples, an empty inner tuple | 1 2 3 4; 1 2 3 4; 5 6 7 | the same | the same |
| v03, r16, r16g, r16h, x07 and c01 to c08 (PR 59 only) | the verifier abort, but c04 (5 6 7) | 7 8 9; 3 2; 3; 3; 2 5 9; RR1's outputs (7 1, 2 3, 2 3 4, 5 6 7, 1 2 4 5, 2 4, 1 3, 5 3) | the same |
| a03, `var v: ((i32, i32),) = ((Id(1), Id(2)),);`, and a19 and a20, a function returning such a 1-tuple | 1 and an indeterminate value; `CHECK failure` at check/convert.cpp:2313, `new_storage_id.has_value()` (trunk :2199, the nightly :2066) | the same | the same |
| d01 (rev 6), §A.6's `Loud`, `Dup` and `let one: (Loud,) = (l1,); Core.Print(Dup(one).0.a);` verbatim: the `(Loud,)` is copied by PR 59's hand-written `(T,)` impl, whose `Op` returns `(self.0.Op(),)` by copy | `CHECK failure` at lower/lower.cpp:48, the verifier's "Invalid InsertValueInst operands!" for `%tuple.init = insertvalue { { i32 } } poison, void <badref>, 0` | the same | the same |
| d02 (rev 6), `Dup` of a run-time `((Id(1), Id(2)),)` | the same abort, for `{ { i32, i32 } }` | the same | the same |
| d03 (rev 6), `Dup` of the constant `((1, 2),)` | `CHECK failure` at lower/handle_call.cpp:984 (the nightly :783), an argument mismatch, as a02 | d02's abort | the same |
| d04 (rev 6), `Dup` of the constant `((1, 2), 3)`, §A.6's `Dup(n)` shape, copied by the hand-written `(T, U)` impl | v01's verifier abort | 1 2 3 | 1 2 3 |

The four d rows are rev 6's (amended 2026-10-26, review fold: RR5-M1): the
re-review's probes, copied from its directory `amendrr5/probes2` beside `$J` to
`$K/probes_d`, and run by `$K/bin/run_set.sh` on PR 59, trunk, the nightly, C0's
install and C0 with C0b relinked over its objects (`$K/set_va_d.txt`,
`set_trunk_d.txt`, `set_nightly_d.txt`, `set_c0_d.txt`, `set_c0b_d.txt`; the
re-review's outcomes line for line), and on the rev 4 prototype with C0b,
90c34dbaa, built in full (`$K/set_wt6_d.txt`): there too d01, d02 and d03 stop
at the verifier with the same `insertvalue` and d04 prints 1 2 3
(`$K/verifier_msgs.txt`). On the same relinked C0b and on that prototype, M-20's
36 probes print the last column again, but for a03's indeterminate value and
a19's and a20's CHECK line, :2313 on C0b and :2361 on the prototype
(`$K/set_c0b_probes.txt`, `set_c0b_impl.txt`, `set_wt6_probes.txt`,
`set_wt6_impl.txt`).

Root cause, read from lower/function_context.cpp, lower/aggregate.cpp and
sem_ir/type_info.cpp at d92a9c709. `InitializeStorage` (:433-459) copies a
constant source with `CopyValue`, in its in-place arm (`if
(IsConstant(source_id))`) and in its by-copy arm (always). `CopyValue`'s
contract is upstream's (function_context.h:318-320 at 8779d15e1: "`source_id`
must produce a value representation for `type`, and `dest_id` must be a pointer
to a `type` object"), but its arms assume that value representation is the
object representation (`Copy`: `StoreObject`) or its address (`Pointer`:
`CopyObject`, a memcpy of the object's size), and for a type whose value
representation holds its elements' value representations
(`ValueRepr::ValueAggregate`: a tuple or struct with a tuple, struct, array or
class element) neither holds. Before C0, `GetConstant` served such a constant's
object representation, in a global of the value representation's type for a
pointer representation (the verifier's abort) and as the value itself for a
one-element aggregate (so a01 and a16 ran and a02 aborted); C0 serves the value
representation, as upstream's comment says it must (file_context.cpp:213-215 at
8779d15e1: "the value produced by a constant instruction is a value
representation of the constant. For initializing expressions, `FinishInit` will
perform a copy if needed"), which made every value use right and every copy into
storage wrong. An initializing expression that is not a constant never reaches
it: an in-place one initializes its storage itself, and a by-copy one produces
the object representation by value (type_info.h:253-254 at 8779d15e1: "An
initializing expression produces an object representation by value, which is
copied into the initialized object"). So it is a defect of the measured diff,
not a header the relink missed (C0 changes one .cpp file), not a golden the
manifest missed (no existing golden copies such a constant), and not a design
rule misread (R32: lowering is internal, and the mechanism is upstream's
contract above); rev 2's probes lowered values only, and §4's `var` row
described the right result without a run.

A second defect of C0's diff, found by the amender: its
`BuildElementwiseConstantValueRepr` lowers each element through `GetConstant`,
which calls it back, so clang-tidy 21.1.8's `misc-no-recursion`, which §8.6's
first pass runs with warnings as errors and the repository's .clang-tidy enables
(`misc-*`), reports both functions "within a recursive call chain" (two errors;
`$J/tidy_norec_c0_file_context.log`, `tidy_repo_c0_file_context.log`); §8.6 runs
it on implementation and fix commits, and C0 was neither, so no step before the
implementation reviews would have caught it.

C0b, §2.7's block, measured on the scratch worktree /dev/shm/va2-amend/wt at
d92a9c709 with the block applied and the binaries relinked over the C0 build's
objects with C0b's two .cpp files (`$J/bin/relink.sh`):

-   The gate before the fill: "1960 passed, 1 failed", the golden alone, with no
    crash (`$J/gate_c0b2_unfilled.log`). Autoupdate reaches its fixpoint after
    one pass (the second changes nothing) and adds 415 lines to the 68-line
    source, 483 in all (`$J/nested_constant_c0b2_filled.carbon`); the gate after
    it: "1961 passed, 0 failed" (`$J/gate_c0b2_filled.log`). The fill's `tuple`,
    `pass`, `struct` and `struct_of_tuple` splits are the implementer's C0 fill
    line for line; `var`'s 12-byte memcpy becomes six lines (a load of the inner
    tuple's address, a GEP, a load of `6`, a GEP, an 8-byte memcpy into `v.0`
    and a store into `v.1`); `return` and `one_element` are new (§4).
-   Conformance: PASS 137, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0,
    OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 21 (of 158), bullets 49 PASS, 0
    FAIL, 7 SKIP, 0 NOT-WRITTEN of 56 (`$J/conf-c0b2.log`).
-   The probes: the last column of the table above.
-   clang-tidy: both §8.6 passes over C0b's file_context.cpp and
    function_context.cpp, the second line-filtered to the lines changed since
    b0822a744, which are C0's and C0b's, exit 0 with no diagnostic
    (`$J/tidy_norec_c0b_*.log`, `tidy_repo_c0b_*.log`); `misc-no-recursion` over
    the prototype's other 22 .cpp files, on the composition tree below and on
    b0822a744, exits 0 for every file (`$J/tidy_proto.txt`).
-   With the rev 4 prototype: the scratch worktree /dev/shm/va2-amend/wt5 at
    d92a9c709 with C0b's block, C0b's fill and Appendix B without its
    file_context.cpp hunk, which is C0's (that remainder applies with `git
    apply --check` on C0 plus C0b), committed as the dangling scratch commit
    90c34dbaa (tree ec0d23d6c, on ca939ee19; 32 files, 1623 insertions and 120
    deletions against b0822a744, lower/file_context.h the new one) and built in
    full under /dev/shm/va2-amend/builds (0 warnings). Its gate is 1956 passed
    and 5 failed, VA-1's five (M-6), so C1's and C2's built hunks leave F0's
    fill as it is (`$J/gate_wt5.log`); VA-1's churn is rev 4's 125 insertions
    and 145 deletions line for line (`$J/va1_churn_c0b.diff`); conformance is
    PASS 137, 0 failures, SKIP 21 of 158 (`$J/conf-wt5.log`); and
    `$H/r/run_set.sh`, `run_rr2.sh` and `probes_all.sh` (M-17 to M-19's sets
    with the proxy prelude, and the 131 earlier probes and programs) print rev
    4's outputs line for line (`$J/sets`, against `$H/r/set_rev4.txt`,
    `rr2set_rev4.txt` and `probesall_rev4.txt`); M-20's 36 probes print the
    last column of the table above, but for a03's indeterminate value and a19's
    and a20's CHECK failure, at check/convert.cpp:2361 there, moved by C1's and
    C2's convert.cpp hunks (`$J/set_wt5.txt`).
-   §0.6's collisions with 90c34dbaa are rev 4's (`$J/collisions_c0b2.txt`), and
    `git merge-tree` against upstream's 8779d15e1 gives 104 conflicted paths for
    b0822a744, ca939ee19 and 90c34dbaa alike, the same set
    (`$J/mt_up_8779.txt`).

Not changed by C0b and not filed: a03, a19 and a20 are upstream's defects in a
one-element aggregate whose element is initialized in place (its by-copy
initializer, lower/aggregate.cpp `EmitAggregateInitializer`'s `ByCopy` arm,
:240-250 at d92a9c709, wraps the element's in-place result, `poison` or the
`void` of a call that returns in place, and a `return` of one stops in check),
the same on every toolchain above. Rev 5 said that no form or program of this
slice reaches them; that was unmeasured, and it is wrong (amended 2026-10-26,
review fold: RR5-M1). §A.6's `Dup(one)` (d01) reaches the class today through PR
59's hand-written `impl forall [T: Copy] (T,) as Copy`
(core/prelude/copy.carbon:55-59), whose `Op` returns `(self.0.Op(),)`, a by-copy
`(Loud,)` whose element is `Loud`'s `Copy.Op` call, which returns in place; d02
and d03 reach it for a run-time and a constant `((i32, i32),)`; M-11 checked
§A.6 only, so it could not see this. From C4 on, `Dup(one)` goes through the
variadic impl's `return (... each x);` with `Self` = `(Loud,)`, a
`PackSegmentInit` of a by-copy 1-tuple whose element initializes in place (§2.4
items 5 and 7), which nothing has built or measured: C2's lower `one_tuple`
split has an `i64` element, which is by copy. So C4's stage decides. d01 to d04
are in the probe set that every stage re-runs after its build (the hand-off
notes), expected as the last column above through C3 and, from C4 on, to print
101 1, 1 2, 1 2 and 1 2 3; if C4's impl still reaches the class, C4 stops and
amends, with a fix of the lowering or with a plan revision that makes the form
OUT with the precise TODO R17 requires, never at C5 and never with a guard that
hides an IN form. VA-2's ids W-330 to W-339 are all filed and W-340 to W-344 are
other workstreams', so no id is minted for the class here; §7.1's R-13 records
it with a break condition, and the stage that writes D's PR text names it for
the next allocation.

M-21. C1's split and its golden sources (amended 2026-10-26, implementation:
stop-and-amend: C1's split and golden sources). The implementer split Appendix
B, less its file_context.cpp hunk, by §2.1 to §2.3 (`$N/c1`, 27 files and 65
hunks, each passing `git apply --check` on F0's 8a7395cf1, and C2's built half,
`$N/c2_proto.patch`, 10 files; the two together give Appendix B less that hunk),
added C1's own changes and §A.11's C1 sources
(`$N/c1_uncommitted_source_state.patch`, 33 files, 1476 insertions and 118
deletions on 8a7395cf1), built it in full with 0 warnings (`$N/build_pre.log`)
and ran the gate before committing anything. Four differences from this plan,
each reproduced by the amender:

-   D1, the gate. file_test aborts, "0 passed, 0 failed" (exit 134), with `FATAL
    failure at toolchain/sem_ir/type_iterator.cpp:312: Unhandled type
    instruction {kind: PackType, ...}` in check/variadics/fail_todo_va2.carbon's
    split `fail_todo_cpp_template_on_tuple_of_pack` (`$N/gate_pre.log`; the
    amender's `$M/logs/d1_c1_gate.log`, the implementer's install on the saved
    state in the scratch worktree /dev/shm/va2-amend/wt), where §3 item 3 and
    §8.3 predict red on exactly ten files with no crash; with that split removed
    the gate is 1956 passed and 10 failed, the ten (`$N/gate_pre2.log`). The
    stack runs `ConvertArgsToTemplateArgs` of `Cpp.Traits((... each T))` >
    `ExprAsType` > `ConvertTupleToType` > `ExprAsType` >
    `PerformUserDefinedConversion` > `LookupImplWitness` > `TypeIterator::Next`,
    and the probes f03, r02, r02b, p04, ctF and ctF2, each with `(... each T)`
    in a type position, abort the same way, as do 60 compiles of the earlier
    probe sets in all, each with a tuple type that holds `... each T`
    (`$N/probes_c1pre.txt`, `$N/sets`). Root cause, read from the split's
    check/handle_pack_expansion.cpp, check/convert.cpp and
    sem_ir/type_iterator.cpp: §2.2 gives C1 the hunk of
    `HandleParseNode(PackExpansionExprId)` that makes `... each T` of a
    compile-time pack that pack (its constant), so `(... each T)` is a tuple
    literal whose one element is a value of a `PackType`, but §2.3 gave C2 the
    two hunks that take such an element as a segment: `ConvertTupleToType`'s,
    which makes it the segment `GetPackType(element, arity)`, and
    `TypeIterator::ProcessType`'s `PackType` case. Without them
    `ConvertTupleToType` calls `ExprAsType` on the pack, whose type is not
    `type`, the conversion looks up an `ImplicitAs(type)` impl for the pack
    type, and the type iterator's `default:` is `CARBON_FATAL` (:309-312 of the
    split). The split had never been built alone (§8.1 left that check to the
    implementer; every earlier build was of the whole prototype), so this is a
    defect of the plan's assignment of hunks to commits: not of Appendix B's
    code, not a header a relink missed (the implementer's build was a full one)
    and not a golden the manifest missed.
-   The fix of D1, measured: the two hunks, verbatim from Appendix B (§2.2's rev
    7 block, `$M/c1_moved_hunks_block.patch`, 2 files and 15 insertions; `git
    apply --check` passes on 8a7395cf1 and on it with the saved split), applied
    in /dev/shm/va2-amend/wt and relinked over the implementer's C1 objects with
    check/convert.cpp and sem_ir/type_iterator.cpp (`$M/bin/relink.sh`,
    `$M/logs/relink_v1b.log`). The gate before the fill: 1956 passed and 10
    failed, the ten files of §3 item 3, with no crash
    (`$M/logs/v1b_gate_pre.log`). clang-format 21.1.8 `--dry-run --Werror` and
    both §8.6 clang-tidy passes on the two files exit 0 with no diagnostic
    (`$M/tidy`), and prek with the hooks §8.6 runs passes on C1's 33 files and
    changes none (`$M/logs/prek_c1_1.log`). The split that crashed fills to §4's
    line, `unable to monomorphize specific `F(⟬i32, i64, bool⟭)`` at the call
    with the note `semantics TODO: `unsupported type used as template argument``
    once, and f03, r02, r02b, p04, ctF and ctF2 print rev 4's outputs
    (`$M/sets`, against `$H/r/rr2set_rev4.txt` and `probesall_rev4.txt`).
-   D2, four splits of C1's goldens. Autoupdate asks for a `fail_` prefix on
    check `hetero_pack`'s `type_pack`, `forward` and `method` splits and on
    `generic_pack`'s `call` split (`$N/au_pre1.log`; on C1 with the block,
    `$M/logs/au_v1b_asis_1.log`), each reporting `error: use of undefined
    generic function [MissingGenericFunctionDefinition]` at the call with the
    note `generic function declared here`, where §4 predicts no diagnostic. Root
    cause: §A.11's sources declare the called generic function of those splits,
    `Count`, `ForEach`, `C.F` and `F`, without a definition, and upstream
    requires the definition of a generic function that a call uses
    (check/check_unit.cpp:564-581 at b0822a744 and :507-523 at upstream's tip
    600fd55ba: `definitions_required_by_use`, "use of undefined generic
    function"), from a generic's body too (`forward`'s `ForEach(... each y)`);
    PR 59, trunk and C1 report it for the same shapes without packs
    (`$M/probes/ctl`, `$M/logs/ctl_undefined_generic.txt`: `fn F[T: type](x:
    T);` called from a function and from a generic). Rev 1 parsed these splits
    and no revision compiled them (rev 4's `$H/r/run_goldens.sh` compiled the
    six splits rev 4 added), so the defect is the sources' and §4's, not the
    code's. Three of C2's splits have the same form, `tuple_segment`'s `param`,
    `tuple_value` and `elements_around_segment`; no other split of §A.11 and no
    program of Appendix A calls a generic declared without a definition
    (`$M/bin/scan_decl.py`), but `fail_hetero_pack`'s `fail_missing_impl`, whose
    call fails its conversion first, as §4 says.
-   The fix of D2, measured: each such function gets the empty definition VA-1's
    goldens give a callee, `{}` with `unused` parameters (`fn ForEach(... unused
    each n: i64) {}` in VA-1's forward.carbon). On C1 with the block the four C1
    splits fill without a diagnostic (`$M/logs/au_v1b_rev7_1.log`):
    `type_pack`'s two specifics of `Count` take `%int_2` with the `pack_value
    (%i64, bool)` and `%int_0` with the empty `pack_value ()`, each specific's
    definition completing its `require_complete_type`. On C1 with C2's built
    half (below), `param` deduces `⟬%i64, bool⟭` and `⟬⟭` and
    `elements_around_segment` `⟬%i32, bool⟭` and `⟬⟭`, both without a
    diagnostic, where the sources as they were report the error twice each
    (`$M/src/ts_c2`: `asis_filled.carbon`, `defined_filled.carbon`);
    `tuple_value`'s call takes a tuple literal with a segment, §2.4 item 1,
    which C2 has yet to write, and reports VA-1's `pack expansion in a tuple
    literal outside a call's argument list` either way, so its definition is a
    prediction until C2.
-   D3, lower `hetero_pack`'s `layout`. §4 predicts that the caller "stores an
    `i64`, an `i1` and an `i32` into a `{ i64, i1, i32 }` alloca and passes its
    address"; the fill passes the address of an internal constant,
    `@.7fc.loc14_18.5 = internal constant { i64, i1, i32 } { i64 1, i1 true, i32
    2 }`, with no alloca, and the specific reads the three elements at constant
    GEPs (an `i64` load, an `i8` load truncated to `i1`, an `i32` load) and
    calls `One`'s three specifics in order, as predicted. Root cause: the row
    predates C1's `EmitAsConstant(PackValue)` (lower/constant.cpp, §2.2), which
    makes a pack value of constants a global constant, M-6's class for VA-1's
    refilled pack_expansion.carbon ("the per-call stores of constant packs
    disappear"); a wrong prediction, not a defect.
-   D4, lower `hetero_pack`'s `forward`. §4 predicts that `Forward`'s `⟬A, B⟭`
    specific "passes its own pack's address"; the fill allocas a `{ ptr, ptr }`,
    loads each element of `%y`, stores it into that pack and passes the new pack
    to `ForEach`'s `⟬A, B⟭` specific. Root cause: `ForEach(... each y)` is a
    `PackExpansionExpr` argument, which VA-1 lowers by allocating a pack and
    storing each iteration's result into it
    (lower/handle_pack_expansion.cpp:69-84 at b0822a744, `CreatePackStorage` and
    `StorePackElement`), for a pack of one type and of different types alike;
    passing the pack through would be an optimization that neither VA-1 nor this
    slice makes, so this too is a wrong prediction, not a defect.

The fill on C1 with the block and rev 7's sources (`$M/fill_rev7_p2`, the ten
files at their fixpoint; the second pass changes nothing,
`$M/logs/au_v1b_rev7_2.log`; the gate after it 1966 passed and 0 failed,
`$M/logs/v1b_gate_filled.log`): each_param, forward, import, fail_todo_slice,
the lower pack_expansion, fail_hetero_pack and the lower hetero_pack are the
implementer's fill (`$N/preview/p2`) byte for byte, the five refills rev 4's
VA-1 churn line for line but for fail_todo_slice's removed split and relabeled
TODO (`$N/va1_churn_c1_vs_rev4.txt`); fail_todo_va2 is the implementer's fill
plus the split it could not fill, as its own relink of the block filled it
(`$N/preview/fail_todo_va2_v1b_filled.carbon`); check hetero_pack and
generic_pack differ from the implementer's by the four definitions and their
dumps. The whole of C1, the saved state with the block and rev 7's four sources,
is `$M/c1_rev7.patch` (33 files, 1491 insertions and 118 deletions on 8a7395cf1;
27 non-test files, 996 and 109; the paths in `$M/c1_rev7_files.txt`), whose
`toolchain` tree is 57d89a880239dee5283f1a69b5ca6a9e2a8bc32d, and
913a132b474be56f16581c9ff3b022b35473ff4f with the fill. Conformance on C1 with
the block: PASS 137, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0,
DIFF-MISMATCH 0, SKIP 21 (of 158), bullets 49 PASS, 0 FAIL, 7 SKIP, 0
NOT-WRITTEN of 56 (`$M/logs/conf_v1b.log`). M-20's 36 probes and d01 to d04
print what stage 1 recorded but a03's indeterminate value and a19's and a20's
CHECK line, check/convert.cpp:2348 there (`$M/probes_v1b.txt`).

C2's forms on C1 with the block (`$M/sets/rr2set_v1b.txt`, `set_v1b.txt`,
`probesall_v1b.txt`): no probe of the sets crashes, where 60 compiles aborted on
the split without the block. A variadic impl declares, but until C2's
type_structure.cpp hunks the structure of `(... each T)` has no run entry, so
the type iterator's `SymbolicType` step for the segment is one `?` and the
impl's structure a 1-tuple's: a query of another arity finds no candidate
(`cannot access member of interface ... that does not implement that interface`
for p24, r09, x06, a1 and the other variadic-impl probes) or, beside a blanket
impl, selects the blanket one (x05 and x05b print 1 3 1 1 where rev 4 printed 1
3 2 2, r01 and r01b 1 1 where it printed 2 1, v06 5 5 where it printed 4 5).
These are C2's forms (§3 item 5, R-14). C1 with C2's built half: the scratch
worktree /dev/shm/va2-amend/wt2, the saved state with `$N/c2_proto.patch`, whose
toolchain files are C1 with the block plus `$M/c2_rest_after_v1b.patch` (9
files, 24 hunks, 381 insertions and 11 deletions, applying with `git
apply --check` on C1 with the block), built in full with
`CB_BUILD_ROOT=/dev/shm/va2-amend/builds` (324 steps, 0 warnings,
`$M/logs/build_wt2.log`); there `run_rr2.sh`, `run_set.sh` and `probes_all.sh`
print rev 4's outputs line for line but k3, p05, p18 and x03, which print C1's
own TODOs (the relabel's, F-3's, the relabel's and F-7's), and M-20's probes
with d01 to d04 print stage 1's, a19's and a20's CHECK at :2361
(`$M/sets/rr2set_wt2.txt`, `set_wt2.txt`, `probesall_wt2.txt`,
`$M/probes_wt2.txt`).

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
    has the type `«I; N»`, a pack of facets, when its expansion is an element
    of a function's or an impl's implicit parameter list; any other
    compile-time each-name, among a class's or an interface's parameters
    (`class C(... each T: type)`, W-222), in a class's or an interface's
    implicit list, or after an explicit `generic` (W-221), is the `semantics
    TODO: each-name binding of a class, interface or explicit compile-time
    parameter`, where rev 3 accepted every one (M-19) (amended 2026-10-26,
    review fold: RR2-M1).
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
a 1-tuple. The design's rule is "find the type structure by deleting deduced
parameters and replacing type parameters by a `?`" (generics/details.md
:4688-4689), which keeps the tuple: `(... each T)` is `(...?)`. Rev 1 made a
pack type and a whole tuple type with a pack segment a symbolic hole that
matched any type at its position, a second spelling of that rule (M-15); rev 2
keeps the tuple's open and close entries and makes the segment a run entry
inside them that matches the run of the query's elements its tuple leaves
after the elements before and after it, and ranks matching impls by the
overlap rule along the query (D-VA2-8) (amended 2026-10-22, review fold: A-M-1
/ B-B2). Deduction matches the segment against that run (D-VA2-8; rev 1 cited
D-VA2-9 here, amended 2026-10-22, review fold: B-m5).
`VerifyAllGenericBindingsUsed` (impl.cpp:209-247) deduces an impl
against its own self type, so a self type with a segment must deduce against
itself (p19 failed with "`impl` with unused generic binding" until it did).
The thunk builder (toolchain/check/thunk.cpp `ClonePattern`, VA-1's W-229)
is not reached: `Copy.Op`, `EqWith.Equal` and the `OrderedWith` functions take
`self` and one `Self` parameter, no pack, so the impl's functions match the
interface's without a thunk; W-229 (a pack in an interface function) stays
filed. SC-1 (PR 60) changes impl lookup and requirement checking in files
VA-2 also touches (§0.6) but adds no case for pack types; TP-1 (PR 61) defers
template-dependent operands in call.cpp, deduce.cpp and convert.cpp, and its
seam with packs is W-224, which CT-1 (PR 64) reaches through C++ calls on a
pack element (M5's probe, §8.7, D-VA2-14) (amended 2026-10-22, review fold:
B-M5).

### §0.5 The prototype

The rev 2 prototype (`$F/r3/va2_prototype_rev2.patch`) implements the central
mechanism and was built, gated and run (M-6, §0.2's proto column, M-12 to
M-16) (amended 2026-10-22, review fold: A-B-1 / A-B-2 / A-B-3 / A-M-1), and
since rev 3 the prototype is its successor (`$G/r/va2_prototype_rev3.patch`,
Appendix B until rev 4), built, gated and run the same way (M-17, M-18, M-9's
last bullet) (amended 2026-10-26, review fold: RR1-NB-1 / RR1-B-M5), and since
rev 4 the prototype is the rev 4 one (`$H/r/va2_prototype_rev4.patch`,
Appendix B), which corrects three of rev 3's measured defects and is built,
gated and run the same way (M-19) (amended 2026-10-26, review fold: RR2-M1 /
RR2-m1):

-   heterogeneous packs end to end: `[... each T: I]`, `... each x: each T`,
    deduction of the pack of types, per-element impl lookup, the body checked
    once, lowering per element (p02, p12, p14, p15), with one pack arity per
    generic enforced (M-14);
-   tuple types with one pack segment, their flattening, their deduction
    against a tuple, their dependent representation in the generic (M-13),
    and a variadic impl selected for tuples of arity 0, 2 and 4 and through a
    generic's requirement (p19, p24, p24b), ranked against blanket and
    fixed-arity impls by the design's overlap rule (M-15);
-   import of the new constants (VA-1's import.carbon passes after autoupdate),
    and since rev 3 the lowering of specifics of imported variadic functions
    and impls and of statement expansions in a variadic impl's functions
    (M-17) (amended 2026-10-26, review fold: RR1-NB-1);
-   the refusal of a dependent action whose operand depends on the pack
    index (M-18) (amended 2026-10-26, review fold: RR1-B-M5);
-   since rev 4, the refusal of a compile-time each-name outside a
    function's or an impl's implicit list, the pack literal of a specific's
    pack of types in diagnostics, and one evaluation of a failed specific
    (M-19) (amended 2026-10-26, review fold: RR2-M1 / RR2-m1);
-   the lowering of nested aggregate constants (M-12, C0's hunk), and since rev
    5, outside the prototype, C0b's copies of them into storage (M-20, §2.7)
    (amended 2026-10-26, implementation: stop-and-amend: nested constant
    initialization).

Rev 1's measured defects (M-9, M-12 to M-15) are corrected in it: the
`TupleType` deduction's fallback (§2.3), the representation of a segment tuple
(M-13), the second pack arity (M-14), the type-structure hole (M-15), the
nested constants (M-12) and the stringification of packs (M-16); rev 2's
measured defects (M-17, M-18) are corrected in the rev 3 prototype
(`$G/r/rev3_fixes.patch`, 4 files, 150 insertions and 25 deletions against
rev 2's tree, clang-format's re-wrapping of rev 2's lines in those files
included) (amended 2026-10-26, review fold: RR1-NB-1); rev 3's measured
defects (M-19) are corrected in the rev 4 prototype (`$H/r/rev4_fixes.patch`)
(amended 2026-10-26, review fold: RR2-M1 / RR2-m1).

It does not implement, and so §8.9 lists as unmeasured: tuple values with a
runtime pack segment (`(... each x)` as an initializer; the prototype reports
the placeholder `semantics TODO: initializing a tuple with a pack segment`
where C2's `PackSegmentInit` goes, r19), `let` with a pack expansion pattern,
statement expansions of `if`, the prelude rewrite, the goldens but C1's (whose
fill, with C1's relabeled TODO diagnostics, rev 7 measured on C1, M-21) (amended
2026-10-26, implementation: stop-and-amend: C1's split and golden sources), and
the programs of Appendix A except §A.1 to §A.3 and §A.10, which it runs.

### §0.6 Collisions with the held PRs (numstat, then `git merge-tree`)

For each held head, the files changed since its merge base with b0822a744
intersected with VA-2's files (the prototype's 31 and the 10 that C2 to C4 add
beyond them, §6.2; rev 3 said 30 and 14, counting four files the prototype
already changes among the added ones (amended 2026-10-26, review fold:
RR2-m3)), then `git merge-tree --write-tree --name-only` of the rev 2 prototype
commit 413968218 against the head, minus the conflicts b0822a744 already has
with that head (VA-1's §6.2 method). Re-measured for rev 2 at the heads of
2026-10-22 (`$F/r3/collisions_rev2.txt`): rev 1 used the earlier
prototype commit 74a8f47b4 (775 insertions) and the heads 2a4264056 (PR 63) and
f774ee836 (DR-1b), which have moved, and left eight rows unmeasured (amended
2026-10-22, review fold: A-M-2 / B-M4). Re-measured for rev 3 with the rev 3
prototype commit 80f1ec825 at the heads of 2026-10-26
(`$G/r/collisions_rev3.txt`, made by `$G/r/collisions.sh`): every count is
rev 2's; the rows of PR 60, PR 61 and PR 64 now list check/impl_lookup.cpp,
rev 2's ranking hunk, which rev 2's table omitted, and those of PR 61 and
PR 64 check/action.cpp, rev 3's refusal (D-VA2-14), both merging cleanly; PR
63 and DR-1b are at f163a2bde and 1dd904216, whose changes since rev 2's heads
are fork/ records and one DR-1b golden (amended 2026-10-26, review fold:
RR1-NB-1 / RR1-B-M5). Re-measured for rev 4 with the rev 4 prototype commit
ca939ee19 (`$H/r/collisions_rev4.txt`, made by `$H/r/collisions.sh`, whose
trunk row reads origin/trunk): every count and file list is rev 3's; PR 63 is
at 89aabd125, DR-1b (PR 65 since 2026-10-26) at fee0ef31c and trunk at
449fecdd7, each moved since rev 3's heads by fork/ records only (amended
2026-10-26, review fold: RR2-m3):

| PR (branch, head) | Shared files | Conflicts b0822a744 has | Conflicts with the prototype | New |
| --- | --- | --- | --- | --- |
| PR 51 ua2 (f96fe8a7a) | none | 2 | 2 | 0 |
| PR 52 cmake (ea573f672) | none | 4 | 4 | 0 |
| PR 53 safe (adaae4e35) | none | 3 | 3 | 0 |
| PR 54 ev (cb3ef2e74) | none | 4 | 4 | 0 |
| PR 55 st (21307851a) | none | 4 | 4 | 0 |
| PR 56 op (894139b34) | none | 4 | 4 | 0 |
| PR 57 op2 (a080c7886) | check/convert.cpp | 4 | 4 | 0 |
| PR 58 dd (fcee90d9b) | none | 4 | 4 | 0 |
| PR 60 sc (40a76ab81) | check/context.h, convert.cpp, handle_binding_pattern.cpp, impl_lookup.cpp, import_ref.cpp, merge.cpp, type.cpp, type.h, type_completion.cpp; lower/type.cpp; sem_ir/inst_kind.def, inst_namer.cpp, stringify.cpp, type_iterator.cpp, typed_insts.h | 3 | 3 | 0 |
| PR 61 tp (5661a35c8) | check/action.cpp, context.h, convert.cpp, eval.cpp, impl_lookup.cpp, import_ref.cpp; lower/file_context.cpp, function_context.cpp; sem_ir/inst_kind.def, stringify.cpp, typed_insts.h | 4 | 6 | convert.cpp, eval.cpp |
| PR 62 sv (0ef8a0334) | check/convert.cpp, type.cpp; lower/constant.cpp | 3 | 3 | 0 |
| PR 64 ct (4a3220c11) | as PR 61, plus check/eval.h, generic.cpp | 4 | 6 | convert.cpp, eval.cpp |
| PR 63 dr (89aabd125) | none | 3 | 3 | 0 |
| PR 65 DR-1b dr-idx (fee0ef31c) | check/convert.cpp | 3 | 3 | 0 |
| trunk (449fecdd7, OV-1 and the records) | none | 3 | 3 | 0 |

"None" means the head shares no toolchain or prelude file with VA-2: its
conflicts with b0822a744 are the records, fork/gap-analysis.md,
fork/inventory/work-items.json, fork/decision-log.md and fork/ORCHESTRATION.md,
and, on some heads, fork/conformance/README.md; their conflicts are the
land-time records commit's (§3), regenerated or rewritten from the merged trunk,
never merged by hand. The rev 1 table's call.cpp in DR-1b's row was a planned
file, not one the prototype changes. The two new conflicts with PR 61 (and so PR
64, stacked on it) are adjacent insertions: in `ConvertTupleToType`
(convert.cpp:700-750) PR 61 redirects a `SpliceInst` element and VA-2 turns a
pack-typed element into a segment, and in `EvalContext`'s members (eval.cpp:251)
PR 61 adds `diagnosed_non_constant_ids_` and VA-2 adds `pack_index_`. Each
resolves by keeping both, PR 61's line first (§6.2's merge rule), measured on
the PR 64 mirror of §8.7 (`/dev/shm/va2-fixer/mirror-64`, built, gate 1972
passed and 5 failed, the five VA-1 goldens of M-6), and again for rev 3 (M-18).
Rev 2's ranking hunk in toolchain/check/impl_lookup.cpp and type_structure.cpp,
and C0's hunk in lower/file_context.cpp, merge cleanly with every head (PR 61
and PR 64 change file_context.cpp elsewhere). No held PR touches
core/prelude/copy.carbon or core/prelude/operators/comparison.carbon, so PR
55's, PR 56's and PR 57's prelude programs are not affected textually, but the
variadic impls are candidates for every tuple's `Copy`, `EqWith` and
`OrderedWith` query (`Optional((i32, i32))` needs `(i32, i32) as Copy` through
`OptionalStorage`), so §8.7 gives each of those PRs, and DR-1a and DR-1b, a
mirror of its own (amended 2026-10-22, review fold: A-M-2 / B-M4).

Re-measured for rev 5 with the rev 4 prototype plus C0b, the dangling scratch
commit 90c34dbaa (`$J/collisions_c0b2.txt`, made by `$H/r/collisions.sh`): every
count and shared file list is rev 4's; the lower/function_context.cpp that PR 61
and PR 64 share merges cleanly with C0b's hunks too, no held PR changes
lower/file_context.h, and trunk is ad2e45a66, moved since 449fecdd7 by fork/
records only (amended 2026-10-26, implementation: stop-and-amend: nested
constant initialization).

### §0.7 Conformance programs touched

VA-1's nine programs under generics/ (variadics_each, variadics_fixed_params,
variadics_forward, variadics_empty_pack, variadics_expansion_args,
variadics_sum_diff, variadics_arg_order, variadics_no_copy,
variadics_generic_element) PASS on the prototype unchanged (M-6). The tuple
programs of other bullets (stdlib/tuples_arrays_structs.carbon, bullet "Stdlib:
tuple/array library parts", and every program that copies a tuple) run against
the new `Copy` impl only where `Core.Copy` of a tuple is required, which no
existing program does (M-3); the full conformance run of §8.4 is the check.
New programs: Appendix A, ten, three of them differential pairs (§1.8; ten
since rev 2 added `variadics_strcat`, amended 2026-10-22, review fold: B-M3).

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
-   F-6 (amended 2026-10-22, review fold: A-M-1 / B-B2). Rev 1's R-6 said a
    user `impl forall [T: type] T as Copy` "overlaps every impl and is
    rejected as it is today"; on PR 59 and the nightly a blanket impl beside
    a fixed `(T, U)` impl runs (r01c: 2), and it was rev 1's hole that made
    it an error (M-15).
-   F-7 (amended 2026-10-22, review fold: A-m-5 / B-M2). VA-1's DR-17 says
    the type-position form of an expansion without each-names is OUT
    (W-212), but PR 59 diagnoses `fn F(unused t: (... i32))` with the error
    `pack expansion does not use any each-name` (x03), which the design
    allows (:147-150, "If an expansion contains no each-names, it must be a
    pattern, or an expression in the type position of a binding pattern").
    C1 makes it a TODO (W-337, D-VA2-13).
-   F-8 (amended 2026-10-22, review fold: B-B1). Apply's `F: Call(... each
    T)` (:275) needs p002875's variadic `Core.Call`, which VA-1 filed as W-226
    ("a variadic `Core.Call`"); review B's "never filed" missed it, so no new
    id is minted for it.
-   F-9 (amended 2026-10-22, review fold: B-m5). Rev 1's Appendix B note said
    the stripped copy is "for reading" and that `git apply` takes the scratch
    patch; the copy applies itself (`git apply --cached --check` of rev 1's
    Appendix B, extracted verbatim, against b0822a744's tree succeeds, plain
    and with `--ignore-whitespace`: git reads an empty line in a hunk as a
    blank context line), and §2.0 gives the command.
-   F-10 (amended 2026-10-26, implementation: stop-and-amend: C1's split and
    golden sources). §3 item 3 and §8.3 said C1 alone is red on its ten files
    with no crash, and hand-off note 2 named f03, r02 and ctF, whose sources
    hold `(... each T)` as a type, as C1's probes, but §2.2 and §2.3 left in C2
    the two hunks such a type needs; and four of §A.11's C1 splits, parsed but
    never compiled, called a generic function that has only a declaration. Both
    are measured and corrected by rev 7 (M-21).

## §1 Design

Every decision auto-adopts the design's text under V-2, V-3b and R32 (R29(a))
and is recorded for after-the-fact veto in the decision-log entry "VA-2"
(§A.12), each with a one-sentence break condition.

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

That is everything the design's Min (:262-271, §A.5), StrCat's text with
Core's missing names declared locally and a `ToString` whose result needs no
per-element cleanup (:250-260, §A.10), StrCat's shape over an interface the
fork has (§A.1), the tuple-typed parameter and return of Apply's and
TupleConcat's signatures (:273-293, §A.4) and the prelude's tuple impls need.
It is not everything W-213's and W-212's arbiters need (amended 2026-10-22,
review fold: B-B1 / B-M3): StrCat's text with a `String`-typed `ToString`
needs per-element cleanups of the temporaries (W-220, x01); Zip's signature
needs element types computed from an each-name (W-330) and its body `...and`
(W-216); Apply needs p002875's variadic `Core.Call` (W-226), `...expand`
(W-217) and `-> auto`, which upstream's bf5d2a2ac adds and the next advance
brings; TupleConcat needs a second implicit-list pack and a tuple of two
segments (W-222) and `...expand` (W-217). So W-212 is discharged with its
arbiter's substitution recorded (§1.9), and W-213 is narrowed, not
discharged. It is one deduced arity per generic: every pack of a function or
impl has the arity of its first pack expansion pattern, so the same-arity
rule ("All each-names in a given expansion must refer to packs with the same
arity", :147-148) holds; rev 1 said "by construction", but a second
each-name binding whose type names no pack added a second arity silently, and
its specific read the shorter pack out of range (M-14), so rev 2 makes that
binding the `semantics TODO: more than one pack arity in a generic` (D-VA2-4),
and W-222's independent arities stay filed (amended 2026-10-22, review fold:
A-B-1). _Break condition:_ a form inside this boundary is mis-checked or
lowered with another iteration's type or callee, or an arbiter of §1.8 needs a
form outside it.

### §1.2 The design's rules, VA-1's DR-1..DR-42 table extended

Numbered as in VA-1's §1.2 (variadics.md lines at 57ba07a97, this branch's
copy). Only the rules whose status changes are listed; every other rule keeps
VA-1's status and label. Rev 1 added a second table, DR-43 to DR-46, whose
rows were parts of VA-1's own rules (DR-43 and DR-44 are reductions under
DR-41, DR-45 repeats DR-40's `auto` rule, DR-46 is DR-36); rev 2 records those
status changes on DR-41, DR-40 and DR-36 instead of minting numbers (amended
2026-10-22, review fold: B-M2).

| Rule | VA-1 | VA-2 | Label or evidence |
| --- | --- | --- | --- |
| DR-4 packs of different types (:86-90) | OUT | IN: a pack of the types of `[... each T: I]` and the value pack `... each x: each T` | §A.1, §A.2, §A.10, golden `hetero_pack` |
| DR-8 statement expansions (:108) | IN for expression statements | IN also for an `if` statement; declarations, loops, `break`, `continue` stay OUT | W-218 narrowed, `fail_todo_statement_kind` |
| DR-9 tuple element `... expression` (:108-110) | IN in call arguments | IN in a tuple literal that initializes or is converted to a tuple with the same pack segment | VA-1's `fail_todo_tuple_literal` (a segment converted to `(i64, i64)`) keeps a TODO, now W-215's `tuple pack segment matched with other segments` |
| DR-10 tuple pattern `... pattern` (:110-111) | IN in explicit parameter lists | IN also as the whole tuple pattern of a `let` whose expansion has fixed arity (its binding's type is an enclosing pack's each-name, :532-534, read with :219-221 as register entry (iv) records); a deduced-arity `let` (VA-1's `fail_todo_tuple_pattern`), `var`, `match` and nested tuple patterns stay OUT | W-214 narrowed (amended 2026-10-22, review fold: A-m-3) |
| DR-11 implicit parameter list `... pattern` (:113-114) | OUT | IN, one per implicit list | W-222 for a second |
| DR-14 `(... x)` is a tuple (:137-140) | parser only | IN | §A.4 |
| DR-16 same arity (:147-148) | IN, one pack | IN for packs that share one arity; a second arity in one generic is a TODO (M-14) | W-222 (amended 2026-10-22, review fold: A-B-1) |
| DR-17 expansion without each-names: a pattern, or an expression in a binding's type position (:148-150) | the statement and expression error IN; the type-position form OUT (W-212), but diagnosed with that error (F-7) | still OUT: `(... each T)` has an each-name and is DR-9 and DR-33's form, not this one; C1 replaces the misdiagnosis of `t: (... i32)` by a TODO | W-337, `fail_todo_va2` split `fail_todo_expansion_without_each_name` (amended 2026-10-22, review fold: A-m-5 / B-M2) |
| DR-24 binding type with an each-name (:219-221) | OUT | IN when the type is exactly `each T` of a deduced pack; a type computed from an each-name (`Optional(each T)`) OUT | W-330 |
| DR-31 segments, pack literals, shapes (:357-449) | one segment | IN for tuples of one pack segment and for packs of different types; a tuple or a pack literal with more than one segment OUT | W-215, W-222 |
| DR-32 iterative typechecking (:451-481) | one segment of one type | IN for one segment of a pack of types: `each x` has the scalar component `each T` | D-VA2-6 |
| DR-33 tuple element expansion's segments become the tuple's (:490-491) | OUT | IN | D-VA2-8 |
| DR-35 fixed and deduced arity (:532-546) | deduced only | IN also for a fixed-arity `let` expansion over an enclosing pack; a fixed-arity class parameter pack OUT | W-222 |
| DR-36 canonical form of a full pattern (:548-623, :845-973) | OUT | OUT, unchanged; the slice still matches the parameters around a pack position by position | W-215 (rev 1's DR-46) |
| DR-37 typechecking a match by splitting and merging (:627-668) | one segment | IN for a tuple type of one segment against a tuple of elements; merging a segment with other elements OUT | W-215 |
| DR-40 typing rules (:730-748) | `each x: auto` OUT | `each x: auto` still OUT ("The type of `each x: auto` is `each __X`", :732-734): `auto` parameters are `HandleAutoTypeLiteral` on every toolchain (§0.2 p13) | W-333 (rev 1 said W-212, whose records move it to W-333; rev 1's DR-45) (amended 2026-10-22, review fold: B-M2) |
| DR-41 reduction and equivalence rules (:750-837) | "Expansion convertibility" for one segment | IN also: "Tuple indexing", `(X, Ys).(I)` reducing to `E` for `X` of the form `...⟬«E; S»⟭` (:811-818), for the pack index into a tuple of one segment (`let` destructuring and initialization, D-VA2-9; rev 1's DR-43); "Pack expansion splitting" and "Singular expansion removal" (:765-771) at evaluation, so a tuple type or value whose segment has a known arity is the tuple of its elements (D-VA2-8; rev 1's DR-44); "Expansion convertibility" (:835-837) for a call's pack literal and for a pack of types forwarded to a pack of types, element by element at its iteration's types (D-VA2-5). OUT: between a pack of different types and a pack of one type (W-336), "Pack expanding" (:773-797, W-330), the rest (W-215) | D-VA2-5, D-VA2-8, D-VA2-9 (amended 2026-10-22, review fold: B-M2) |
| DR-13 `...expand` (:121-133) | OUT | OUT, and a V-3a register entry for the design's own TODO (:493) | W-217, §1.12 (i) |

### §1.3 Compile-time packs and the pack index (D-VA2-2, D-VA2-3, D-VA2-4)

**D-VA2-2 (the pack index is a per-iteration constant).** "These semantics are
implemented at monomorphization time, so the value of N is a known integer
constant. Although the value of `$I` can vary during execution, it is
nevertheless treated as a constant." (:300-303) and "the expansion body is
implicitly parameterized by an integer value called the _pack index_"
(:163-165). VA-1's `PackIndex` was a run-time value (`InstConstantKind::Never`);
VA-2 makes it a symbolic constant (`SymbolicOnly`, evaluated by a dedicated
`TryEvalTypedInst<SemIR::PackIndex>`): in a generic and in a specific it is
symbolic, so every constant computed from it (the type `each T`, an impl witness
for `each T`, a callee) is an eval-block entry of the generic; within iteration
`k` of a specific it is the `IntValue` `k`. A specific whose generic's eval
blocks contain a `PackIndex` and whose pack arities are known gets, when its
definition is resolved (`ResolveSpecificDefinition`, check/generic.cpp), its
declaration and definition eval blocks evaluated once per iteration `k` in `[0,
N)` (`TryEvalPackIterationsForSpecific`, check/eval.cpp), where `N` is its one
`<pack arity>` argument, found among the generic's bindings through each
binding's constant value, because an imported generic's bindings are import
references (M-17) (amended 2026-10-26, review fold: RR1-NB-1) (D-VA2-4 makes a
second arity in a generic a TODO, because rev 1's "largest of its `<pack arity>`
arguments" read a shorter pack out of range, M-14; amended 2026-10-22, review
fold: A-B-1); the values are stored on the `SemIR::Specific`
(`pack_iteration_block_id`, `pack_iteration_count`), and
`SemIR::GetConstantValueInSpecific` and `GetTypeOfInstInSpecific` take an
optional pack index that selects them. Evaluating an iteration also resolves the
definitions of the specifics its `RequireSpecificDefinition` entries name, so
each element's callee is lowered. `PackIndex` is a symbolic leaf like a binding
(the eval-block rebuild accepts it, check/generic.cpp:160-170), and an imported
`PackIndex` is symbolic too (`AddImportedConstant`, eval.cpp). _Break
condition:_ upstream represents the pack index or per-element monomorphization
otherwise (the advance then takes upstream's representation, §6.3), or a
measured file's check time rises beyond the gate's run-to-run noise, since a
specific evaluates its eval blocks `N + 1` times.

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
so a function or impl has one deduced arity, shared by its packs. That is
enforced, not assumed: an each-name binding that would add a `<pack arity>`
binding while one is already on the compile-time binding stack, of this
generic or of an enclosing one (`fn F[... each T: I](t: (... each T), ...
each n: i32)`, or a function with a pack in a variadic impl), is the
`semantics TODO: more than one pack arity in a generic` (W-222), because the
specific has one pack index and one iteration count (M-14) (amended
2026-10-22, review fold: A-B-1). An expansion in a function of a generic over
a pack of the enclosing generic (a variadic impl's pack in the impl's `Op`,
which is every prelude impl body of C4) uses the enclosing generic's arity
binding, whose constant is attached to the enclosing generic; rev 2's
`PackExpansionStatement` named that binding itself, which the function's
specific cannot give a value (M-17), so rev 3 names it by a
`specific_constant` of the enclosing generic's self specific
(`WrapInstForSpecific`), the way upstream refers to any name of an enclosing
generic since e1c8c1f85 ("Use `specific_constant` when referring to name in
enclosing generic": "This allows consumers of generic instructions to always
use a specific of the current scope's generic when accessing the constant
value or type of a dependent instruction"), not a second mechanism;
e1c8c1f85 is after the fork's cut, so the fork's name lookup does not wrap
yet, and §6.3 says what the advance does (amended 2026-10-26, review fold:
RR1-NB-1). A second pack
expansion pattern in one implicit parameter list is the `semantics TODO: more
than one pack expansion pattern in an implicit parameter list` (W-222), not
VA-1's `MultiplePackExpansionPatterns`, because the rule "A tuple pattern can
contain no more than one subpattern of the form `...` _operand_" (:333-334)
does not govern the implicit list and the design's own TupleConcat has two
there (:289; F-3). A template or `ref` each-name binding stays a `semantics
TODO` (W-221), relabeled `each-name binding that is ref, var or template`. A
compile-time each-name is accepted only in a function's or an impl's implicit
parameter list (the full pattern's kind is `ImplicitParamList` and the
declaration's introducer `fn` or `impl`); anywhere else it is the `semantics
TODO: each-name binding of a class, interface or explicit compile-time
parameter`, reported before any arity binding is added: W-222's for a pack
among a class's or an interface's parameters, the design's own `class C(...
each T: type)` (variadics.md :538 at 21c825a3f, whose member expansions have
fixed arity, DR-35), and for a pack in a class's or an interface's implicit
list, and W-221's for an explicit `generic` each-name, which VA-1's W-221
names ("each-name bindings that are `ref`, `var`, `template` or `generic`").
Rev 3 accepted every compile-time each-name, so those forms, OUT in this
slice, compiled or failed with arity and deduction errors where PR 59 reports
a TODO (M-19) (amended 2026-10-26, review fold: RR2-M1). _Break condition:_
upstream allows several deduced arities per full pattern before W-222 lands,
or reads `[... each T1, ... each T2]` otherwise, or a generic with two
arities reaches a specific without the TODO, or a compile-time each-name
outside a function's or an impl's implicit list checks without the TODO.

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
iteration's types (DR-41). Forwarding a pack of different types to a pack of
one element type (`H(... each x)` with `each x: each T` and `fn H(... each y:
i64)`), or the reverse, would need the design's "Expansion convertibility"
between `⟬each T⟭` and an arity coercion `«E; N»` (:835-837); rev 1's
deduction reported a misleading "cannot implicitly convert non-type value of
type `«Core.ImplicitAs(i64); <pack arity>»` to `type`", and rev 2 reports
`semantics TODO: forwarding a pack of different types to a pack of one type,
or the reverse` (W-336; f06, f07, x08) (amended 2026-10-22, review fold:
A-M-2). _Break condition:_ a call deduces a pack of types
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
every constant and type lookup (`GetValue`, `IsConstant`, `GetTypeIdOfInst`, the
callee lookup of handle_call.cpp), so iteration `k` of `... each x.F()` calls
the `k`th element type's `F`. A pack of different types is stored as a tuple of
the elements' value representations; `PackElement` addresses the element at the
current pack index with a constant GEP (valid for the array of `«E; N»` and the
struct of `⟬A, B⟭`), and a constant `PackValue` of types or facets lowers to a
null constant (no run-time content). VA-1's per-iteration erasure of locals is
unchanged. A specific of a generic imported from another library, the prelude's
tuple impls included, is lowered the same way, from the defining library's body
and the importing library's per-iteration values (M-17; rev 2 lowered none of
them (amended 2026-10-26, review fold: RR1-NB-1)). _Break condition:_ a specific
runs an iteration with another iteration's type or callee, which §8.5's mutants
MV-1 and MV-2 are built to detect, or a specific of an imported generic does not
get per-iteration values.

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
(`ConvertTupleToType`). A tuple type with a segment has a value and an
initializing representation that depend on the specific, as a symbolic
binding's type does (`MakeDependentTypeInfo`, type_completion.cpp): the
generic does not know how many elements the tuple has, so it must not compute
a concrete representation from the one pack element, which rev 1 did (a
1-tuple returned by copy, while each specific of arity 4 returns in place),
crashing every call that returns `Self` from a variadic impl's function
(M-13) (amended 2026-10-22, review fold: A-B-2). Deducing a tuple type with one
segment against a tuple type matches the elements before and after the segment
one by one and the segment against the remaining run as a pack literal of
those types; against a tuple type with a segment in the same place, segment
against segment ("The search for this rewrite processes each pattern segment
to the left of the segment with deduced arity, in order from left to right",
:651-658, for one segment).

Impl lookup's type structure follows the design's rule: "Given an impl
declaration, find the type structure by deleting deduced parameters and
replacing type parameters by a `?`" (generics/details.md :4688-4689), which
keeps the tuple, so the structure of `(... each T)` is `(...?)` and that of
`(i64, ... each T)` is `(c...?)`: the segment is a run entry inside the
tuple's open and close entries, which matches the run of the query's elements
its tuple leaves after the elements before and after it, zero or more, and an
empty tuple is an empty group so that a segment can match it. The candidates
that match a query rank by the overlap rule, "We pick the type structure with
a non-`?` at the first difference as most specific", which "corresponds to a
depth-first traversal of the type tree to identify the first difference, and
then picking the most specific choice at that difference" (:4921-4929), taken
along the query: an impl's ranking lists the query positions it does not match
concretely, so that two impls whose segments cover different runs are compared
where their coverage first differs. Where one impl has a `?` and another a
segment covering the same element, the design does not say which is more
specific; VA-2 reads "the most specific choice at that difference" as the `?`,
which matches that one element where the segment matches any run, and ranks a
segment that covers nothing just after a concrete element; that reading is
register entry (v) (W-338). Without segments, the ranking orders impls as
before (M-6's rev 2 line: no golden changes). Measured (M-15): a blanket `T`
beside `(... each T)` is selected for `i32` and the variadic impl for every
tuple, `(T, U)` beats `(... each T)` for a 2-tuple, `(... each T, bool)` beats
`(... each T)` where both match, in either declaration order, and two variadic
impls of one structure are the existing same-type-structure error. Rev 1's
whole-tuple hole was a second spelling of the rule above (R32(d)) and is
withdrawn (amended 2026-10-22, review fold: A-M-1 / B-B2). A tuple type with
more than one segment is the `semantics TODO: tuple with more than one pack
segment` (W-222, W-215). _Break condition:_ upstream canonicalizes tuple types
with segments otherwise, or gives pack segments a type-structure rule of its
own (the advance then takes it, register entry (v)), or a query matches an
impl whose self type's segment cannot cover its run, or a ranking depends on
declaration order.

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

The representation the generic sees is D-VA2-8's dependent one, so a `let`,
an initialization and a return in the generic make no assumption about the
specific's arity (M-13) (amended 2026-10-22, review fold: A-B-2). An expansion
element of a tuple literal whose body is an initializing
expression (`(... each x.Op())` initializing a tuple) would have to initialize
the target's element in place through the body's return slot; VA-2 diagnoses it
as the `semantics TODO: pack expansion of initializing expressions in a tuple
literal` (W-331) rather than copy each element twice. _Break condition:_ a
`let` pack binding or a tuple initialized from a pack copies an element more or
fewer times than once per element, or reads another element.

### §1.6 Variadic impls and the prelude (D-VA2-10, D-VA2-11, D-VA2-12)

**D-VA2-10 (impl selection and termination).** A variadic impl is an impl whose
implicit parameter list has a compile-time pack and whose self type has a pack
segment. Its selection is the impl lookup of today plus D-VA2-8's deduction, its
run entry in the type structure and its ranking (amended 2026-10-22, review
fold: A-M-1 / B-B2); `VerifyAllGenericBindingsUsed` deduces the impl against its
own self type, which D-VA2-8's segment-against-segment rule covers (p19).
Termination: impl lookup implements only the acyclic rule, and upstream's
p002687 termination rule, with its variadic count keys ("A `tuple` key in this
namespace is used to track the total number of components of tuple values",
:210-215), is a TODO upstream as in the fork (M-2). VA-2's impls terminate
without it, because each requirement they add (`each T: Copy`, `each T: Eq`,
`each T: Ordered`) is a lookup on an element of the query's tuple, a strict
subterm of the query's self type, so every chain of nested lookups is finite by
the size of the type. Implementing p002687 is filed as W-332: an accepted design
that neither toolchain implements, not an open question, so it is a residue, not
a V-3a register entry; its owner is VA-2 until VA-2 lands and then the next
impl-lookup workstream, which D's ORCHESTRATION Next actions names (amended
2026-10-22, review fold: B-M8). Reviewer A's r08c, a cycle of impls with no
variadics, hangs on PR 59 and the nightly as on the prototype, so it is W-332's
evidence, not VA-2's defect. _Break condition:_ a prelude or program impl whose
requirement is on a type not smaller than its self type needs termination
checking.

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
(comparison_operators.md :488-490). `Equal` calls each element's `==` (rev 1
called each element's `!=`, which the design's field-wise equality, the design's
`...and (each a == each b)` spelling and `std::tuple` all do not), and
`NotEqual` calls each element's `!=` and is true at the first element that is
not equal (amended 2026-10-22, review fold: A-m-1 / B-M1). Rev 2 left `NotEqual`
to `EqWith`'s `default fn NotEqual`, `return not self.Equal(other);`
(comparison.carbon :14-16), as `std::tuple`'s `!=` is `!(t == u)`, and
registered that reading as the design's silence; but the design is not silent:
tuples.md :108-114 lists "equality and inequality comparison" among the
operations that "are defined for tuples field-wise", and comparison_operators.md
:311-316 lets an element's `NotEqual` differ from `not Equal` ("where two values
can compare neither equal nor not-equal, and thus both functions would return
`false`"), which a field-wise `!=` keeps and the default does not. The
field-wise `NotEqual` also keeps the contract that "an implementation of
`EqWith` should _not_ allow both `Equal` and `NotEqual` to return `true` for the
same pair of values" (:314-315): both true would need an element whose own
`Equal` and `NotEqual` are both true. For elements whose `!=` is `not ==` (every
primitive, and any type that keeps `EqWith`'s default) the two readings agree,
as §A.7's oracle shows (amended 2026-10-26, review fold: RR1-Nm-2). The four
relational functions call only the elements' `<`, `std::tuple`'s rule, which the
design's "lexicographical ordering" does not contradict but which decides the
elements whose ordering is not total (a NaN's tuple is equivalent to itself
although `nan <= nan` is false; comparison_operators.md :457-464 leaves such
orderings as a TODO); that reading is register entry (vi) (W-339), pinned by
`tuple_ordered_diff` (amended 2026-10-22, review fold: A-m-2). The tuple impls
live where upstream keeps its tuple `Copy` impls (copy.carbon) and its
builtin-type comparisons (comparison.carbon, "this must be provided in this
library as `bool` doesn't have any associated libraries of its own", :38-40;
tuples have no library of their own either). `Copy.Op` copies each element once,
by the element's own `Copy` (D-VA2-9), as upstream's `(self.0.Op(),
self.1.Op())` does; the `(... each x.Op())` spelling would need W-331 and is the
impl's text once W-331 lands. The test-only
toolchain/testing/testdata/min_prelude/parts/copy.carbon (upstream's fixture,
with its own `()`, 2- and 3-tuple impls) is not changed, so no golden built on
it churns; of the 312 goldens on the production prelude
(`min_prelude/full.carbon`), M-9 predicts 44 refills, 43 by renamed SemIR names
and toolchain/lower/testdata/for/bindings.carbon by its lowered tuple copy, a
lower bound measured with proxy bodies (amended 2026-10-22, review fold: A-m-4 /
B-m4), and C4 adds two full-prelude goldens of its own that pin the impls
(D-VA2-15). The impls compare tuples of one type only (W-334, §1.12 (ii)).
_Break condition:_ upstream lands its own variadic tuple impls (the advance
takes upstream's text), or a tuple of more than three elements does not satisfy
`Core.Copy`, `Core.Eq` or `Core.Ordered` when its elements do, or a tuple's `==`
calls an element's `!=`.

### §1.7 Diagnostics, templates and C++ interop (D-VA2-13, D-VA2-14)

**D-VA2-13 (what stays a TODO, with its text).** Each a `semantics TODO` with a
golden split (§4), each in check, each filed:

| Form | Text after `semantics TODO:` | Item |
| --- | --- | --- |
| a second pack expansion pattern in an implicit list | `more than one pack expansion pattern in an implicit parameter list` | W-222 |
| a second pack arity in one generic, or in a generic and one that encloses it (M-14) | `more than one pack arity in a generic` (amended 2026-10-22, review fold: A-B-1) | W-222 |
| a pack expansion pattern in a `var`, `match` or nested tuple pattern | `pack expansion pattern in a pattern other than a parameter list or let` (VA-1's `pack expansion pattern outside an explicit parameter list`, relabeled) | W-214 |
| a `let` pack expansion pattern with deduced arity | `pack expansion pattern with deduced arity outside a parameter list` | W-214 |
| a binding type computed from an each-name | `pack expansion pattern whose binding type is computed from an each-name` | W-330 |
| an expansion without each-names in a binding's type, `t: (... i32)` (DR-17; VA-1's error `pack expansion does not use any each-name` there, F-7) | `pack expansion without an each-name in a binding's type` (amended 2026-10-22, review fold: A-m-5 / B-M2) | W-337 |
| forwarding a pack of different types to a pack of one type, or the reverse (M-16) | `forwarding a pack of different types to a pack of one type, or the reverse` (amended 2026-10-22, review fold: A-M-2) | W-336 |
| a tuple with more than one pack segment | `tuple with more than one pack segment` | W-222 |
| a segment merged with other elements in a deduction | `tuple pack segment matched with other segments` | W-215 |
| an initializing expansion element in a tuple literal | `pack expansion of initializing expressions in a tuple literal` | W-331 |
| a statement other than an expression or `if` statement | `pack expansion of a statement other than an expression or if statement` (relabeled) | W-218 |
| a `ref`, `var` or `template` each-name binding | `each-name binding that is ref, var or template` (relabeled) | W-221 |
| a compile-time each-name among a class's or an interface's parameters, in a class's or an interface's implicit list, or after an explicit `generic` (M-19) | `each-name binding of a class, interface or explicit compile-time parameter` (built since rev 4; amended 2026-10-26, review fold: RR2-M1) | W-222 (classes, interfaces), W-221 (`generic`) |
| a C++ call, a C++ class template or a template-dependent action whose operand or operand's type depends on the pack index, in C1 at `AddDependentActionInst` (D-VA2-14) | `C++ or template-dependent action on an element of a pack of different types` (amended 2026-10-22, review fold: B-M5; amended 2026-10-26, review fold: RR1-B-M5) | W-224 |
| `...expand` | upstream's `HandlePrefixOperatorExpand` (unchanged) | W-217 |
| `each x: auto` | `HandleAutoTypeLiteral` (unchanged, upstream's) | W-333 (amended 2026-10-22, review fold: B-M2) |

The prototype's `semantics TODO: initializing a tuple with a pack segment`
(convert.cpp, r19) is a placeholder where C2's `PackSegmentInit` goes (§2.4
item 5), not a residue, and no commit keeps it (amended 2026-10-22, review
fold: A-B-2).

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

**D-VA2-14 (templates and C++ interop).** Templates: upstream's own templates
already compose with packs of different types on this branch, without PR 61: on
the rev 3 and rev 4 prototypes alone, a template-dependent action on an element
of such a pack in `fn F[template U: type, ... each T: I](u: U, ... each x: each
T)` (`u.Get(each x)`, `u[each x]`, `u as each T`, `Sink(each x, u)`, the
re-review's tp1, tp3, tp4 and tp5) reaches C1's refusal below, and one whose
operands do not depend on the pack index (`u.n + each x.V()`, tp2) runs and
prints 211; C1 pins both, with `fail_todo_va2`'s
`fail_todo_template_action_on_hetero_element` and `hetero_pack`'s
`template_outer` (M-19). Rev 3 said no install composed templates with packs
(amended 2026-10-26, review fold: RR2-m2). PR 61's template-dependent forms,
which it adds beside upstream's, meet packs only on the PR 59 plus PR 61 mirror
(§8.7, m61), where VA-1's `pack expansion argument in a template-dependent call`
(W-224), VA-2's template each-name TODO (W-221) and C1's refusal keep packs and
templates apart. CT-1 (PR 64) defers a C++ call whose argument is symbolic to
each specific (`DeferCppCallOnSymbolicArgs`, call.cpp), which composes with
packs of one type (CT-1's va3, `... Cpp.Add(each x)` with `x: T`, prints 7 on PR
64 merged with the rev 2 prototype, as on CT-1's own mirror), but not with packs
of different types: the deferred action is resolved once per specific, not once
per iteration with the iteration's pack index, so on that mirror
`... Cpp.Add(each x)` with `each x: each T` compiles and runs but calls nothing
(ct1: prints 0 where the per-element instantiations Add<int>, Add<long> and
Add<bool> would print 308040101), and a C++ call whose result is used aborts in
lowering, "CHECK failure at toolchain/lower/function_context.cpp:287:
const_id.is_concrete(): Missing value: ... SpliceInst ... has non-concrete
value" (ct4) (amended 2026-10-22, review fold: B-M5). Rev 2's answer, a
land-time hunk in CT-1's `DeferCppCallOnSymbolicArgs` that tested whether an
argument's type was an each-name, was too narrow: a type argument `each T` has a
facet type, not an each-name type, and a C++ class template named with a
symbolic argument is deferred by another path, so on the mirror with that hunk
the re-review's ct5 (`Cpp.SizeOfFn(each T)`, `each T: type`), ct7 (the same with
`each T: I`) and ct6 (`Cpp.Traits(each T).size`) still aborted in lowering
("Casting inst {kind: CallAction...} to wrong kind InstValue"). And the defect
is VA-2's own, not only a composition with PR 64: upstream's
`PerformCallToNonFunction` (check/call.cpp:933 at b0822a744) defers
`Cpp.Traits(T)` for a symbolic `T` as a `CallAction` that each specific performs
once, so ct6 and ctD (`Cpp.Traits((each T)*).size`) abort the same way on the
rev 2 prototype alone, without PR 64 (M-18) (amended 2026-10-26, review fold:
RR1-B-M5). A dependent action is performed once per specific, and an operand
that depends on the pack index would need one performance per iteration, which
belongs with W-224's composition of packs and templates. So VA-2 takes the TODO
at the root, in C1: `AddDependentActionInst` (check/action.cpp, upstream's one
function through which every dependent action is added to a generic's eval
block: the `CallAction`s of upstream's C++ template path, of TP-1's
template-dependent calls and of CT-1's deferred C++ calls, with the
`TemplateInst`s they wrap, TP-1's other actions, and convert.cpp's
`InitializeAction`; check/inst.cpp:46-50 refuses any other way to add one, "Use
AddDependentActionInst to add an action instruction") reports `semantics TODO:
C++ or template-dependent action on an element of a pack of different types`
where the action is formed, and returns the error instruction, when an operand
of the action, or an operand's type, contains the pack index; the test walks the
operands' symbolic constants with `SubstInst` and callbacks that rebuild
nothing. `AddDependentActionSplice` and convert.cpp's `InitializeAction` site
return that error instruction instead of splicing it. An action whose operands
do not depend on the pack index is unchanged, inside such an expansion too (ctE:
`Cpp.Traits(U).size + (each x as i32)` prints 19), and a pack of one type has no
operand of a pack-index-dependent type (ctC prints 19, and ct3 7 on the mirror).
Measured (M-18): on the rev 3 prototype alone ct6 and ctD report the TODO and
ctB 8 1, ctC 19 and ctE 19 run; on PR 64 merged with rev 3 and nothing else (no
land-time code) ct1, ct2, ct4 to ct8 and ctD report it, ct3 prints 7 and ctA 8 8
1 1, and the gate is 1972 passed and 5 failed, VA-1's five (amended 2026-10-26,
review fold: RR1-B-M5). S-CT is therefore no longer a code commit: it is a
land-time test commit that, after M has brought PR 64's deferral, adds the split
`fail_todo_cpp_call_on_hetero_element` to
toolchain/check/testdata/interop/cpp/template/ with ct1's, ct5's and ct7's
shapes (a value, a type and a facet-typed type argument of a C++ function
template), which before M give upstream's "call argument of type `each T` is not
supported" and "no matching function", and F-M fills it; C1's own
`fail_todo_va2` split `fail_todo_cpp_template_on_hetero_element` (ct6's shape)
and `hetero_pack`'s `cpp_template_outer` (ctE's) pin the rule on this branch.
C++ otherwise: no tuple other than `()` maps to C++ (M-7), and VA-1's `exporting
a variadic function to C++` (W-228) also covers a heterogeneous one, so VA-2
changes nothing C++ sees; the differential pairs of §1.8 compare Carbon with C++
programs, not across the boundary. _Break condition:_ a held PR maps Carbon
tuples to `std::tuple` before VA-2 lands, which would make the tuple impls
reachable from C++, a C++ call on a pack element runs with another iteration's
type, or a dependent action whose operand depends on the pack index reaches a
specific without the TODO.

### §1.8 Goldens and programs (D-VA2-15, D-VA2-16)

**D-VA2-15 (goldens).** New goldens, each a source with `// AUTOUPDATE` and no
CHECK line (R15, R16(a)). Built on `min_prelude` with local interfaces, so that
none depends on the changed prelude: toolchain/check/testdata/variadics/
`hetero_pack.carbon`, `fail_hetero_pack.carbon`, `generic_pack.carbon`,
`tuple_segment.carbon`, `fail_todo_tuple_segment.carbon`, `impl.carbon`,
`fail_impl.carbon`, `expansion_if.carbon`, `fail_todo_va2.carbon`;
toolchain/lower/testdata/variadics/`hetero_pack.carbon`,
`tuple_segment.carbon`, `expansion_if.carbon`; and C0's
toolchain/lower/testdata/tuple/`nested_constant.carbon`, on min_prelude's
int.carbon like its neighbors (amended 2026-10-22, review fold: A-B-3). Built
on the production prelude (`min_prelude/full.carbon`), C4's own two, which
pin the prelude's tuple impls where rev 1 had none (amended 2026-10-22, review
fold: B-m4): toolchain/check/testdata/variadics/`prelude_tuple_impls.carbon`
and toolchain/lower/testdata/variadics/`prelude_tuple_impls.carbon`. Rev 2
adds splits that pin its corrections: `impl`'s `rank`, `rank_reversed`,
`rank_elements_after` and `rank_elements_after_reversed` (a local blanket
impl, a 2-tuple impl and segments with elements after them, beside the
variadic impl, review B's requested golden) and `fail_impl`'s
`fail_same_type_structure` (M-15); `fail_todo_va2`'s `fail_todo_two_arities`,
`fail_todo_enclosing_arity` (M-14), `fail_todo_forward_hetero_to_homo`
(W-336), `fail_todo_expansion_without_each_name` (W-337) and
`fail_todo_overload_hetero_member` (W-223, M-16); and lower `tuple_segment`'s
`self_return` (M-13) (amended 2026-10-22, review fold: A-B-1 / A-B-2 / A-M-1
/ B-B2). Refilled: VA-1's each_param.carbon, forward.carbon, import.carbon,
fail_todo_slice.carbon (the `fail_todo_generic_pack` split moved, relabeled
TODOs) and the lower pack_expansion.carbon (M-6's three classes), and, by C4,
M-9's predicted 44 goldens on the production prelude, a lower bound (M-9).
Sources in §A.11. _Break condition:_ a fill changes a golden outside this list
(§6.1).

**D-VA2-16 (programs).** Ten new conformance programs (§A.1 to §A.10), EXPECT
derived by hand in §A (R16(d)), three with a C++ oracle (DIFF-1), each pair
named `*_diff` with its oracle `*_diff.diff.cpp`, as all 24 existing pairs are
(amended 2026-10-22, review fold: B-m3): bullet "Generics: Definition-checked
variadics": `variadics_hetero_digits_diff` (StrCat's shape) with
`variadics_hetero_digits_diff.diff.cpp` (a C++17 fold over a template
parameter pack), `variadics_hetero_forward`, `variadics_hetero_empty`,
`variadics_tuple_param` (the tuple-typed parameter and return of Apply's and
TupleConcat's signatures, not those signatures), `variadics_min` (the design's
Min), `variadics_strcat` (StrCat's text, Core's missing names declared
locally, W-212's arbiter, amended 2026-10-22, review fold: B-M3); bullet
"Stdlib: tuple/array library parts": `tuple_copy_variadic`, `tuple_eq_diff`
with `tuple_eq_diff.diff.cpp` (`std::tuple`'s `operator==` and `!=`, with an
element type whose `==` prints, amended 2026-10-22, review fold: B-M1),
`tuple_ordered_diff` with `tuple_ordered_diff.diff.cpp` (`std::tuple`'s
`operator<` and the rest, with a NaN, amended 2026-10-22, review fold:
A-m-2), `tuple_impl_generic` (the tuple impls through generic requirements).
The three pairs pin agreement, not a divergence, so R30 (bidirectional
assertions) does not apply to them. Min and StrCat are diffed against the
design's spelling, R27 (§A.5, §A.10; amended 2026-10-22, review fold: B-m3);
the prelude impls implement copy.carbon's TODO, not a design sketch, so R27
has no sketch to diff them against. The variadic sum against a C++ parameter
pack is `variadics_hetero_digits_diff`'s second half. _Break condition:_ a
program passes against a mutant of §8.5.

### §1.9 Docs and records (D-VA2-17)

**D-VA2-17.** docs/design/variadics.md is not edited: every rule VA-2
implements is spelled as the page spells it, and no fork amendment is due (no
F id; R32). The records, written by commits R and D (§3, §A.12):

-   W-212 DISCHARGED for implicit-list packs, each-name binding types and
    packs of different types, its break condition ("StrCat compiles and
    runs") met by `variadics_strcat`, StrCat's text with Core's missing names
    (`ConvertibleToString`, `String.Reserve`, `String.Append`) declared
    locally and `ToString` returning an `i64`, the substitution and its two
    reasons recorded in its notes (Core lacks the names, p01; a class-typed
    `ToString` result needs W-220's per-element cleanups, x01), with `each x:
    auto` moved to W-333 (blocked on `auto` parameters), StrCat over `String`
    to W-220's note as its arbiter, and "multi-segment pack typechecking" in
    its title to W-215 (merging) and W-222 (several segments and arities)
    (amended 2026-10-22, review fold: B-M3); W-213 NARROWED, not discharged
    (amended 2026-10-22, review fold: B-B1): its break condition ("`(...
    each x)` is a value of a tuple type in a variadic function") is met by
    `variadics_tuple_param`, but its arbiters are not, so its note records the
    tuples of one pack segment as done and names what Zip's return type, Apply
    and TupleConcat still need (W-330, W-216, W-226, W-217, W-222; `-> auto`
    with the next advance); W-225 DISCHARGED (the four impls replaced, a
    4-tuple and a 5-tuple satisfy `Core.Copy`, tuple `EqWith(Self)` and
    `OrderedWith(Self)`), with mixed-type comparisons in W-334 and the
    comparison semantics of orderings that are not total in W-339. W-214,
    W-218 and W-219 narrowed by their notes; W-222 narrowed by its note to
    independent arities (a second pack arity in a generic, including a second
    implicit-list pack), tuples of more than one segment and class parameter
    packs, the one list §1.11 and §A.12 use (rev 1's §1.9 omitted the second
    implicit-list pack and the tuples, amended 2026-10-22, review fold:
    B-m5); W-220, W-223, W-224 and W-226 gain notes (§1.11); W-013 stays open,
    its note naming slice 2 and the next slice (W-330, W-222, W-217).
-   "Generics: Definition-checked variadics" stays PARTIAL; its evidence text
    gains slice 2 and its "Not yet" list loses "packs of several or deduced
    types (`[... each T: type]`)", "expansions in tuple literals ... outside
    calls" (one segment) and "variadic impls (the tuple `Copy` rewrite)", and
    names every remaining form with its id (§A.12; rev 1's range "W-214..W-230,
    W-330..W-334" included discharged items and other bullets' ids, amended
    2026-10-22, review fold: B-M7).
-   "Stdlib: tuple/array library parts" stays PARTIAL: its text "tuple Copy
    hand-written only for arities 0-3 with 'TODO: Implement tuple copy as a
    variadic generic impl'; no tuple Eq/Ordered — blocked on variadics." is
    replaced by the variadic impls' evidence, and its open text becomes
    W-334's comparisons that convert one operand (comparison_operators.md
    :504-505), which the design requires and VA-2 does not implement, and
    W-339's open question; the array half ("array Iterate impl works") is kept
    as written, its absorption of upstream's `Core.Array` (947c1eb52) being
    UA-3's. The row moves to DONE when W-334 lands and W-339 is settled. The
    header's counts do not move.
-   fork/decision-log.md gains "VA-2: definition-checked variadics, slice 2
    (<date>)" with D-VA2-1..D-VA2-19, the options of §7.2, the V-3 check and the
    V-3a register entries (§1.12), placed directly after VA-1's entry "VA-1:
    definition-checked variadics, slice 1 (2026-10-14)", because the log groups
    entries by workstream, not by date (DR-0's placement note; rev 1 appended it
    after the last entry, amended 2026-10-22, review fold: B-m3);
    fork/ORCHESTRATION.md (with W-332's, W-338's and W-339's Next actions),
    fork/conformance/README.md (regenerated table) and fork/gap-analysis.md §W6
    are updated.

_Break condition:_ a review shows VA-2 deciding a rule the design leaves open
without a register entry, its work item and a pin, which would need a dated
design amendment and an F id (amended 2026-10-22, review fold: B-M8).

### §1.10 Merge position (D-VA2-18)

**D-VA2-18.** VA-2 is one PR, stacked on PR 59 (R29(b)), merging last: after
DR-1b, in the order of trunk's fork/ORCHESTRATION.md (PR 53, 51, 52, 60, 54, 55,
56, 57, 58 through state L, 59, 61 through its land-time commits, 62, 64 through
M, S-VA, L-F, L and its land-time records commit, 63 through M-a and L-a, DR-1b
through M-b, C-b and L-b, then VA-2). Its land-time commits (§3 item 13,
messages verbatim there): M (merge of the trunk that holds every PR before it, a
merge commit), S-CT (the land-time test commit of D-VA2-14, after M has brought
PR 64's `DeferCppCallOnSymbolicArgs`; a code commit until rev 3 moved the
refusal into C1 (amended 2026-10-26, review fold: RR1-B-M5)), F-M (the fill that
M's merged toolchain and S-CT need), L-F (programs and README table regenerated
on the merged trunk), and L (the land-time records commit, re-quoting §8.8's
run) (amended 2026-10-22, review fold: B-M5 / B-m2). Before the implementation
reviews, §8.7's full-stack mirror simulates that land on scratch: the merge
order above with VA-2's head last, M's conflicts resolved by §6.2's rules,
S-CT's split added, built, gated, filled and run through conformance, with its
expected counts, as CT-1's §8 item 9 and DR-1's §3 simulate theirs (amended
2026-10-22, review fold: B-m2). _Break condition:_ a PR ahead of VA-2 gains an
unresolvable conflict with it at the land-time re-measurement, or the land
simulation's red set is not the predicted one.

### §1.11 Residues and narrowed items

Filed by commit D from W-330 (bullet "Generics: Definition-checked variadics"
unless named), each with its evidence and "follows VA-2 slice 2" in its notes;
rev 2 files all ten ids, and a shrink of §3 needs no new id (amended
2026-10-22, review fold: A-B-3 / B-M2 / B-M6 / B-M8):

1.  W-330: pack types whose element type is computed from an each-name
    (`... each x: Optional(each T)`, Zip's `... each vector: Vector(each
    ElementType)`), the design's "Pack expanding" reduction at evaluation
    (:773-797). Evidence: `fail_todo_va2` split
    `fail_todo_computed_element_type`.
2.  W-331: pack expansions of initializing expressions in a tuple literal,
    initialized in place (`return (... each x.Op());`). Evidence:
    `fail_todo_va2` split `fail_todo_initializing_element`.
3.  W-332: p002687's termination rule with variadic count keys (:186-193,
    :210-215), upstream's own TODO (impl_lookup.cpp:199 at 57ba07a97).
    Bullet "Generics: Checked generics". An unimplemented accepted design, not
    an open question, so not a register entry; owner VA-2 until it lands, then
    the next impl-lookup workstream, scheduled in ORCHESTRATION's Next actions
    by D. Evidence: M-2 and reviewer A's r08c, which hangs on PR 59, the
    nightly and the prototype alike.
4.  W-333: `each x: auto` (:732-734), blocked by `auto` parameters
    (`HandleAutoTypeLiteral`). Evidence: p13.
5.  W-334: tuple comparisons that convert one operand (comparison_operators.md
    :504-505), needing `EqWith((... each U))` over two packs of one arity and a
    per-element requirement. Bullet "Stdlib: tuple/array library parts".
    Evidence: p23 after C4.
6.  W-335: nested aggregate constants lowered with their object representation
    where their value representation is elementwise, and, once lowered so,
    copied into storage as if that were their object, an upstream defect on PR
    59, trunk, the nightly and upstream's tip (M-12, M-20), fixed by C0 and C0b
    and filed DISCHARGED by D. Bullet "Stdlib: tuple/array library parts".
    Evidence: C0's lower golden `tuple/nested_constant.carbon` with C0b's
    splits, r16, r16g, r16h, x07, and M-20's v01, v02, v04, a01, a04, a05, a08
    and a16 (amended 2026-10-22, review fold: A-B-3) (amended 2026-10-26,
    implementation: stop-and-amend: nested constant initialization).
7.  W-336: forwarding between a pack of different types and a pack of one
    type, the design's "Expansion convertibility" (:835-837) beyond one
    segment's types (DR-41). Evidence: `fail_todo_va2` split
    `fail_todo_forward_hetero_to_homo`, f06, f07, x08 (amended 2026-10-22,
    review fold: A-M-2).
8.  W-337: an expansion without each-names in a binding's type position,
    `t: (... i32)` (:148-150, DR-17), its arity deduced from the scrutinee;
    VA-1 misdiagnosed it as `pack expansion does not use any each-name` (F-7),
    and C1 makes it a TODO. Evidence: `fail_todo_va2` split
    `fail_todo_expansion_without_each_name`, x03 (amended 2026-10-22, review
    fold: A-m-5 / B-M2).
9.  W-338: register entry (v), how a pack segment ranks against a `?` in impl
    lookup's overlap rule, which the design does not say (D-VA2-8); a watch
    item: owner VA-2 until it lands, then the weekly upstream check, which
    re-reads generics/details.md "Overlap rule" and upstream's
    type_structure.cpp for pack segments and opens the realignment if upstream
    decides otherwise. Evidence: `impl`'s `rank` splits, M-15 (amended
    2026-10-22, review fold: A-M-1 / B-B2 / B-M8).
10. W-339: register entry (vi), tuple comparisons over elements whose ordering
    is not total or whose `Equal` and `NotEqual` are not complements
    (comparison_operators.md :311-316 and the TODO at :462-464,
    comparison.carbon :25-27's `Compare` TODO); a watch item with W-338's owner
    and next action, re-reading those passages. Bullet "Stdlib: tuple/array
    library parts". Evidence: `tuple_ordered_diff`'s NaN lines, x10 (amended
    2026-10-22, review fold: A-m-2 / B-M8).

Narrowed by notes, no new id: W-214 (only `var`, `match` and nested tuple
patterns, and a `let` expansion of deduced arity, remain; its note also carries
register entry (iv)), W-218 (only declarations, loops, `break`, `continue` and
`match` remain), W-219 (only control flow in expression bodies and the "Type
versus execution semantics" example remain), W-222 (only independent arities,
including a second pack arity in a generic and a second implicit-list pack,
tuples of several segments, and class and interface parameter packs remain, the
last the TODO `each-name binding of a class, interface or explicit compile-time
parameter` since rev 4 (amended 2026-10-26, review fold: RR2-M1)), W-229 (its
note gains p002274's variadic indexing interfaces, :250-257, which W-212's note
named: the proposal defers them "once we have a design for variadics" as an
alternative, not a rule, and they need packs in interface functions, which is
W-229), W-213 (tuples of one segment done; what remains is its arbiters', §1.9).
Notes, no narrowing (amended 2026-10-22, review fold: B-B1 / B-M3 / B-M5): W-220
(StrCat over `String` is its arbiter, x01), W-221 (an explicit `generic`
each-name is the TODO `each-name binding of a class, interface or explicit
compile-time parameter`, split `fail_todo_explicit_generic_pack`, and the `ref`,
`var` and `template` forms the relabeled `each-name binding that is ref, var or
template`; amended 2026-10-26, review fold: RR2-M1), W-223 (a heterogeneous-pack
member of an overload set, or such a pack forwarded to one, is its TODO too,
x16, x17), W-224 (C1's TODO for a C++ or template-dependent action on an element
of a pack of different types, reached by upstream's templates on this branch and
by CT-1's deferred C++ calls after M, until deferred actions are resolved per
iteration, D-VA2-14; rev 3 still named S-CT's TODO here (amended 2026-10-26,
review fold: RR2-m2)), W-226 (Apply's `F: Call(... each T)` is its arbiter),
W-230 (register entry (iii)). W-212 and W-225 discharged (§1.9), W-212's
`each x: auto` moving to W-333.

### §1.12 The V-3a register (DR-0) and decision index

Register entries VA-2 adds, each an open question of the design at
57ba07a97 where the fork stops at the text or reads it as stated here, each
carrying its work item under V-3b (R32(b)), each with an owner and a next
action that D writes into ORCHESTRATION's Next actions, each reviewed at the
weekly upstream check. Rev 1's (iii) (defaults beside a pack) and (iv)
(p002687's termination rule) were not open questions: the first is a watch on
upstream's 503f09037, now in W-215's note, the second an accepted design
unimplemented on both sides, now W-332's residue (§1.11) (amended 2026-10-22,
review fold: B-M8).

-   (i) `...expand`'s typechecking is the design's TODO (:493, :750);
    upstream's 2ec4bab59 parses a prefix `expand`; the fork implements neither,
    so Apply and TupleConcat (:273-293) stop at the text. Work item W-217;
    owner the next variadics slice, scheduled by D; next action: at each weekly
    check, re-read :493 and upstream's handle_pack_expansion.cpp, and when
    either settles `expand`, W-217 implements upstream's text.
-   (ii) Tuple comparisons convert neither operand, a narrowing of
    comparison_operators.md :504-505, not a second spelling. Work item W-334;
    owner the next variadics slice (which also needs W-222's second pack);
    next action: schedule it with W-222.
-   (iii) A pack's bare name without `each` has no meaning yet (p002240,
    "Omit each-names", :555, an alternative the proposal did not adopt);
    VA-1's `semantics TODO` stands. Work item W-230; owner the next variadics
    slice; next action: at each weekly check, re-read p002240's alternative and
    the design for a meaning or an error, which W-230 then implements (amended
    2026-10-22, review fold: B-M8).
-   (iv) A binding type with an each-name "must be a deduced parameter of the
    enclosing pattern" (:219-221), while :532-534 defines a fixed-arity
    expansion as one "that contains at least one usage of an each-name that is
    not a parameter of the enclosing full pattern", with the example `... each
    t: each T` in a method of `class C(... each T: type)` (:538-546). VA-2
    reads :219-221's "enclosing pattern" as including the enclosing
    declarations' patterns, as :538-546 requires, so `let (... each x: each T)
    = t;` in a function of `impl forall [... each T: Copy] (... each T)` is a
    fixed-arity expansion over the impl's pack. Work item W-214; owner VA-2,
    then the next variadics slice; next action: at each weekly check, re-read
    both passages, and if upstream narrows :219-221, the prelude bodies are
    rewritten to its rule. Pinned by `tuple_segment`'s `let` split and the
    prelude (amended 2026-10-22, review fold: A-m-3).
-   (v) How a pack segment ranks against a `?` in the overlap rule
    (generics/details.md :4921-4929 name only `?` and non-`?` entries): VA-2
    ranks a `?` above a segment covering the same element, and a segment that
    covers nothing above both (D-VA2-8). Work item W-338; owner VA-2, then the
    weekly upstream check; next action: re-read the overlap rule and
    upstream's type_structure.cpp at each weekly check. Pinned by `impl`'s
    `rank` splits (amended 2026-10-22, review fold: A-M-1 / B-B2).
-   (vi) Tuple comparisons over elements whose ordering is not total
    (comparison_operators.md :457-464: "There is no expectation that an
    `Ordered` implementation be a total order", and its TODO), or whose `Equal`
    and `NotEqual` are not complements (:311-316): VA-2 derives the four
    relations from the elements' `<`, as `std::tuple` does. `!=` is not part of
    this entry since rev 3: tuples.md :108-114 ("there are some operations are
    defined for tuples field-wise: ... equality and inequality comparison")
    decides it, so the tuple's `!=` calls the elements' `!=` field-wise, and an
    element whose `Equal` and `NotEqual` are both false makes the tuple's both
    false, as the element's contract allows (D-VA2-12; rev 2 derived `!=` from
    `Equal` by `EqWith`'s default and filed that as a reading of silence)
    (amended 2026-10-26, review fold: RR1-Nm-2). Work item W-339; owner VA-2,
    then the weekly upstream check; next action: re-read those passages and
    comparison.carbon's `Compare` TODO (:25-27) at each weekly check. Pinned by
    `tuple_ordered_diff`'s NaN lines (amended 2026-10-22, review fold: A-m-2).

| Decision | Summary | Break condition |
| --- | --- | --- |
| D-VA2-1 | the slice: implicit-list packs, packs of different types, tuples of one segment, `let` destructuring, `... if`, variadic impls; W-213 narrowed | a form inside it is mis-checked or mis-lowered, or an arbiter needs one outside |
| D-VA2-2 | symbolic pack index; per-iteration value blocks of a specific | upstream represents it otherwise, or check time rises beyond noise |
| D-VA2-3 | one `PackType` with `element_id` a type or a pack of types | a computed element type is needed (W-330) |
| D-VA2-4 | `[... each T: I]`; arity added by the binding; a second implicit-list pack or a second arity is a TODO | upstream allows several arities, or reads the form otherwise, or two arities reach a specific |
| D-VA2-5 | deduce the pack of types, convert element by element; hetero to homo forwarding a TODO | wrong order or a missing impl accepted |
| D-VA2-6 | `each x` has the symbolic type `each T` | a body is accepted or rejected against the facet's members wrongly |
| D-VA2-7 | lowering with per-iteration constants; tuple layout | an iteration uses another's type or callee |
| D-VA2-8 | tuple types with one segment; flattening; deduction; dependent representation; `(...?)` in the type structure, ranked along the query | upstream canonicalizes or ranks segments otherwise, a match covers a wrong run, or a ranking depends on declaration order |
| D-VA2-9 | `let` destructuring, initialization element by element, W-331 TODO | an element copied other than once |
| D-VA2-10 | variadic impl selection; termination by subterm requirements | a requirement on a non-smaller type is needed |
| D-VA2-11 | statement expansions of `if` with per-iteration blocks | a branch block shared by iterations |
| D-VA2-12 | the prelude impls, `==` by the elements' `==`, `!=` field-wise by the elements' `!=` (tuples.md :108-114; amended 2026-10-26, review fold: RR1-Nm-2), min_prelude unchanged | upstream lands its own, a tuple of more than three elements fails, a tuple's `==` calls an element's `!=`, or a tuple's `!=` calls an element's `==` |
| D-VA2-13 | TODO texts and the `...expand` register entry | an arbiter reaches a TODO, or upstream settles `...expand` |
| D-VA2-14 | templates unchanged; a dependent action (C++ call, C++ class template, template action) whose operand depends on the pack index is C1's TODO at `AddDependentActionInst`; S-CT a land-time test commit (amended 2026-10-26, review fold: RR1-B-M5) | a held PR maps tuples to C++ first, a C++ call on a pack element runs with another iteration's type, or a dependent action whose operand depends on the pack index reaches a specific without the TODO |
| D-VA2-15 | fifteen new goldens (with C0's and C4's), five VA-1 refills, C4's predicted 44 full-prelude refills (M-9) | a fill changes another golden |
| D-VA2-16 | ten programs, three differential (`*_diff`) | a program passes a mutant |
| D-VA2-17 | records; no design edit; W-212 and W-225 discharged, W-213 narrowed; both rows stay PARTIAL with narrower open text | VA-2 decides an open rule without a register entry |
| D-VA2-18 | one PR on PR 59, merging last, land-time M, S-CT (tests only since rev 3), F-M, L-F, L, simulated on the full-stack mirror | an unresolvable conflict at land time, or a land simulation's red set other than predicted |
| D-VA2-19 | C0, its stop-and-amend commit C0b (amended 2026-10-26, implementation: stop-and-amend: nested constant initialization) and five implementation commits with fills, fix budget three, a three-level shrink line by revert commits (§3); since rev 7 C1 takes two of the hunks rev 4 gave C2 (§2.2's block, M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) | a commit cannot build without a later one; since rev 7 also a commit whose gate crashes without a later commit's hunk, which then moves to it by a plan revision before it is committed |

## §2 Spec, file by file

### §2.0 Conventions

The built part of the spec is Appendix B, the rev 4 prototype's diff verbatim
(`$H/r/va2_prototype_rev4.patch`; rev 3 still named rev 2's here, amended
2026-10-26, review fold: RR2-m3), measured as §0.2, M-6 and M-12 to M-19
say; §2.1 to §2.3 and §2.7 say, file by file, what each hunk does and the
invariant it keeps, and which commit takes it: C0 takes the
lower/file_context.cpp hunk (§2.7), C1 the hunks §2.1 and §2.2 list, and C2
the hunks §2.3 lists, with the changes C1 makes beyond the prototype (the
review-facing corrections F-3 and F-7 and the TODO labels). §2.4 to §2.6
specify the unbuilt part (C2's tuple values, C3's `... if`, C4's prelude) with
the code to write; each is a prediction, and §8.9 lists it as unmeasured.
Fork comments name the decision (`// Fork (VA-2, D-VA2-n): ...`), quote the
design page they implement, and name no work item (VA-1's convention: ids live
in records only). Appendix B applies to b0822a744 as it stands in this file:
extract the lines between its opening `diff` fence and its closing fence into
a file and run `git apply` on it in a worktree at b0822a744 (`git apply
--check` first; `--ignore-whitespace` is not needed, because git reads the
empty lines that the trailing-whitespace hook leaves in place of blank context
lines as blank context lines; checked for rev 1's copy, F-9, and for rev 2's
before this plan's commit, amended 2026-10-22, review fold: B-m5).
C0b, since rev 5, is not part of Appendix B: its block is in §2.7, measured
against C0's commit d92a9c709, where `git apply --check` passes, and Appendix B
without its file_context.cpp hunk, which is C0's, applies on C0 plus C0b (M-20)
(amended 2026-10-26, implementation: stop-and-amend: nested constant
initialization).
Since rev 7 two of the hunks §2.3 gave C2, type_iterator.cpp's `PackType` case
and `ConvertTupleToType`'s pack segment, are C1's: C1 makes `... each T` the
pack, and without them C1's gate aborts on `(... each T)` (M-21). They are
§2.2's rev 7 block, Appendix B's text verbatim, and Appendix B itself does not
change (amended 2026-10-26, implementation: stop-and-amend: C1's split and
golden sources).

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
    symbolic `TupleAccess` (C1); a `PackType` is a `SymbolicType` step whose
    facet is the pack type, so the type structure records it as a run inside its
    tuple (C2's type_structure.cpp), and a `TupleType` with a `PackType` element
    is a tuple like any other (D-VA2-8; rev 1 made the whole tuple a hole,
    amended 2026-10-22, review fold: A-M-1 / B-B2). The `PackType` case is C1's
    since rev 7, where rev 4 gave it to C2: C1's `(... each T)` reaches impl
    lookup, and without the case the iterator's `default:` aborts (§2.2's block,
    M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and
    golden sources); on C1 alone the step is one `?` of a tuple's structure,
    C2's run entry the run (R-14).
-   toolchain/sem_ir/stringify.cpp: `PackType` prints `«E; N»` for a pack of one
    element type, the pack literal `⟬A, B⟭` of a concrete pack of types, and
    `⟬each T⟭` while the pack of types is symbolic; `PackElement` prints `each
    <pack>`; a `TupleType` whose element is a symbolic pack of types prints in
    the design's spelling, `(... each T)`, with no 1-tuple comma (C1). Rev 1
    had none of these and printed "<cannot stringify inst...>" for `each T`
    and `(«T; <pack arity>»,)` for a segment tuple (f01, f03), and reviewer A's
    r19 read "cannot copy value of type `«T; <pack arity>»`" for `⟬each T⟭`;
    rev 2's prototype has them (measured: f01 names `each T`, f03 `(... each
    T)`), so §4's predicted diagnostics are now its measured strings (amended
    2026-10-22, review fold: A-m-5). Since rev 4 a `PackValue`, such as the
    pack of types `T` holds in a specific's name, prints as its pack literal,
    `F(⟬i32, i64, bool⟭)`, and the concrete pack type prints its `PackValue`
    the same way; rev 3 printed `<cannot stringify inst...: {kind:
    PackValue, ...}>` there (M-19's ctF; amended 2026-10-26, review fold:
    RR2-m1).

### §2.2 C1, check and lower of packs of different types (built)

-   check/eval.cpp: `EvalContext::pack_index_` with `set_pack_index`, used by
    `GetConstantValue` and `GetTypeOfInst`; `TryEvalTypedInst<SemIR::PackIndex>`
    (concrete `IntValue` in an iteration, else `CheckedSymbolic`);
    `AddImportedConstant` keeps an imported `PackIndex` symbolic;
    `TryEvalPackIterationsForSpecific` (declaration and definition eval blocks,
    once per iteration, `N` the generic's one `<pack arity>` argument, the first
    and only one its bindings hold, since a second is the TODO of
    handle_binding_pattern.cpp, which adds no binding; rev 2's code and text
    still took the largest (amended 2026-10-26, review fold: RR1-Nm-3); only
    when an eval block holds a `PackIndex`), each binding read through its
    constant value (`GetConstantInstId`), because the bindings of a generic
    imported from another library are import references whose constant values
    are the bindings (M-17; amended 2026-10-26, review fold: RR1-NB-1). Since
    rev 4 it returns at once for a specific whose eval blocks have an error,
    which `TryEvalBlockForSpecific` diagnosed once under its `unable to
    monomorphize specific` context; rev 3 evaluated them again in each
    iteration and repeated a failed action's diagnostic once per element,
    without a location (M-19's ctF; amended 2026-10-26, review fold: RR2-m1).
    check/eval.h declares it.
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
    (taken as a tuple's segment by `ConvertTupleToType` and the type iterator,
    whose hunks are C1's since rev 7, M-21) (amended 2026-10-26, implementation:
    stop-and-amend: C1's split and golden sources); the expression expansion's
    pack type through
    `GetPackTypeForElementType`; a `PackExpansionStatement` whose arity is
    a binding of an enclosing generic (its symbolic constant's `generic_id`
    is not the pending generic's) names it by
    `WrapInstForSpecific(context, node_id, arity_id,
    context.generics().GetSelfSpecific(generic_id))`, a `specific_constant`
    (D-VA2-4, M-17; C2's hunk, since only a function of a variadic impl
    expands a pack of an enclosing generic) (amended 2026-10-26, review fold:
    RR1-NB-1). C1 adds: in an implicit list, a second
    `PackExpansionPattern` is `context.TODO(node_id, "more than one pack
    expansion pattern in an implicit parameter list")` instead of
    `MultiplePackExpansionPatterns` (F-3), and the relabeled TODOs of
    D-VA2-13.
-   check/action.cpp (new in rev 3 (amended 2026-10-26, review fold: RR1-B-M5)):
    `FindPackIndexCallbacks`, a `SubstInstCallbacks` whose `Subst` stops at a
    non-symbolic constant, records a `PackIndex` and rebuilds nothing;
    `DependsOnPackIndex` (the operand's constant or its type's constant contains
    the pack index) and `ActionDependsOnPackIndex` (an `InstId` or `InstBlockId`
    operand of the action, through `IdAndKind::Dispatch`, while a pack expansion
    is being checked); `AddDependentActionInst` reports
    `context.TODO(action.loc_id, "C++ or template-dependent action on an element
    of a pack of different types")` and returns `SemIR::ErrorInst::InstId`
    before refining the operands, and `AddDependentActionSplice` returns that
    error instead of a splice (D-VA2-14, M-18). Invariant: an action none of
    whose operands or operand types contains the pack index is added exactly as
    before, so no existing golden changes (M-17's gate).
-   check/handle_binding_pattern.cpp: compile-time each-name bindings, in a
    function's or an impl's implicit parameter list only (the full pattern's
    kind `ImplicitParamList`, the innermost declaration introducer `fn` or
    `impl`), any other compile-time each-name being `context.TODO(name_node,
    "each-name binding of a class, interface or explicit compile-time
    parameter")` before an arity is added (D-VA2-4, M-19; amended 2026-10-26,
    review fold: RR2-M1); the arity added by the binding; `⟬each T⟭` for an
    each-name type; the pack's arity registered for the binding and for its
    constant; an invalid element type keeps VA-1's `pack_type invalid, %arity`
    (the prototype's last fix, VA-1's `fail_invalid_element_type`). Before it
    adds an arity binding, it looks for one already on
    `scope_stack().compile_time_binding_stack()` (`NameId::PackArity`), which
    holds this generic's bindings and those of the generics that enclose it, and
    if there is one reports `context.TODO(name_node, "more than one pack arity
    in a generic")` (D-VA2-4, M-14; amended 2026-10-22, review fold: A-B-1). C1
    also makes the VA-1 error for an expansion without each-names in a binding's
    type position the `semantics TODO: pack expansion without an each-name in a
    binding's type` (W-337, D-VA2-13; amended 2026-10-22, review fold: A-m-5 /
    B-M2); the statement and expression forms keep VA-1's error.
-   check/deduce.cpp: the heterogeneous branch of the `PackType` case
    (D-VA2-5), which reports `semantics TODO: forwarding a pack of different
    types to a pack of one type, or the reverse` when exactly one of the
    parameter's and the argument's pack types is heterogeneous (W-336, M-16;
    amended 2026-10-22, review fold: A-M-2); the `TupleType` case of D-VA2-8
    (C2's, built).
-   check/convert.cpp: per-element target types in `ConvertPackLiteralToPack`;
    per-iteration types in `ConvertPackToPack`; the `PackValue` element-wise
    branch; `ConvertTupleToType`'s pack segment (C1's since rev 7, where rev 4
    gave it to C2: §2.2's block, M-21) (amended 2026-10-26, implementation:
    stop-and-amend: C1's split and golden sources); the
    template-dependent `InitializeAction` site returns the error instruction
    when `AddDependentActionInst` refuses the action (amended 2026-10-26, review
    fold: RR1-B-M5).
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

The rev 7 block (amended 2026-10-26, implementation: stop-and-amend: C1's split
and golden sources): the two hunks C1 takes from §2.3, verbatim from Appendix B
(`$M/c1_moved_hunks_block.patch`, 2 files, 15 insertions). `git apply --check`
passes on 8a7395cf1 (F0) and on 8a7395cf1 with the stopped run's saved split
(`$N/c1_uncommitted_source_state.patch`), and with them C1's gate is red on its
ten files with no crash (M-21). The `PackType` case's comment names
type_structure.cpp's run, C2's hunk, which is true from C2 on. The block,
against 8a7395cf1:

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/sem_ir/type_iterator.cpp b/toolchain/sem_ir/type_iterator.cpp
index a0ca5337e..57ef9de16 100644
--- a/toolchain/sem_ir/type_iterator.cpp
+++ b/toolchain/sem_ir/type_iterator.cpp
@@ -230,6 +233,13 @@ auto TypeIterator::ProcessType(InstId inst_id) -> std::optional<Step> {
       PushInstId(pointer_type.pointee_id);
       return Step::PointerStart();
     }
+    // Fork (VA-2): a pack type is a tuple's pack segment, `... each T`, which
+    // matches a run of the tuple's elements; it is symbolic, and the type
+    // structure records it as a run (type_structure.cpp).
+    case PackType::Kind: {
+      return Step::SymbolicType{.entity_name_id = EntityNameId::None,
+                                .facet = inst_id};
+    }
     case CARBON_KIND(TupleType tuple_type): {
       auto inner_types =
           sem_ir_->inst_blocks().Get(tuple_type.type_elements_id);
diff --git a/toolchain/check/convert.cpp b/toolchain/check/convert.cpp
index 5d6dc9141..84f0d09bc 100644
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -718,6 +734,14 @@ static auto ConvertTupleToType(Context& context, SemIR::LocId loc_id,
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
```

<!-- google-doc-style-resume -->

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
    segment `GetPackType(element, arity)`, a hunk that is C1's since rev 7
    (§2.2's block, M-21) (amended 2026-10-26, implementation: stop-and-amend:
    C1's split and golden sources), so C2 keeps the rest of this bullet. The
    prototype also reports the
    placeholder `semantics TODO: initializing a tuple with a pack segment`
    where a tuple with a segment is initialized element by element, which
    §2.4 item 5's `PackSegmentInit` replaces in C2; no commit keeps it.
-   check/type_completion.cpp, the tuple case of the value representation
    builder: a tuple type with a `PackType` element is
    `MakeDependentTypeInfo(type_id)`, the representation of a symbolic
    binding's type, because its arity is the specific's (D-VA2-8, M-13;
    amended 2026-10-22, review fold: A-B-2). A segment of known arity and
    element types is already flattened by `EvalConstantInst(TupleType)`, so
    only the generic and its eval blocks see such a tuple.
-   check/type_structure.h, type_structure.cpp: the structural entry
    `SymbolicRun` for a pack segment, built from the `SymbolicType` step of a
    `PackType`; the empty tuple is an open and a close entry rather than one
    concrete entry, so a run can match it; `CompareStructure` matches a run
    against the run of the other side's elements its tuple leaves after the
    elements before and after it (`CountElementsInGroup`,
    `ConsumeSymbolicRun`), and, given a ranking vector, records the impl's
    ranking against the query: `4p + 2` for an element matched by a `?`,
    `4p + 1` for each element a run covers and `4p + 3` for an empty run, at
    query position `p`; `IsBetterRanking` compares two rankings as `operator<`
    compares `symbolic_type_indices_` (D-VA2-8, M-15; amended 2026-10-22,
    review fold: A-M-1 / B-B2).
-   check/impl_lookup.cpp, `CollectCandidateImplsForQuery`: each candidate
    keeps its ranking against the query, and the candidates sort by
    `IsBetterRanking` instead of by their own type structures; without
    segments the order is the same (M-6's rev 2 line).

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
    destination, as `TupleInit` does for in-place elements. A specific in which
    the tuple is a 1-tuple, whose initializing representation is by copy
    (check/type_completion.cpp:585-592, `BuildStructOrTupleValueRepr`, and
    sem_ir/type_info.cpp:82-85), and whose element initializes in place (a
    class, or a tuple of two or more elements), such as `Self` = `(Loud,)` in
    §A.6's `Dup(one)`, is R-13's upstream class: no split of C2 has that shape
    (`one_tuple`'s element is an `i64`, by copy), so d01 to d03 at C4 are its
    first measurement (amended 2026-10-26, review fold: RR5-M1).

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
    ... if (not (each a == each b)) {
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
do (§A.7, §A.8). `Equal` calls only the elements' `==`, as the design's
field-wise equality and its own `...and (each a == each b)` spelling (A-8) do;
rev 1's `Equal` called the elements' `!=` and its hand-written `NotEqual`
did too, so a type whose `==` and `!=` disagree would have compared tuples by
its `!=`, and §A.9's EXPECT lines were derived from that body, not from the
design (amended 2026-10-22, review fold: A-m-1 / B-M1). `NotEqual` calls
only the elements' `!=`, field-wise as tuples.md :108-114 lists "equality and
inequality comparison", and stops at the first element that is not equal; an
element type whose `Equal` and `NotEqual` are both false for some pair (the
design's NaN example, comparison_operators.md :311-316) makes two tuples
that differ only there neither equal nor not-equal, as the element is. Rev 2
left `NotEqual` to
`EqWith`'s `default fn NotEqual`, `return not self.Equal(other);`
(comparison.carbon :14-16), which calls the elements' `==` as `std::tuple`'s
`!=` does and makes those tuples not-equal; for elements whose `!=` is `not
==` the two agree, so §A.7's Counted lines are the same under both (amended
2026-10-26, review fold: RR1-Nm-2). The four relational functions
call only the elements' `<`, `std::tuple`'s own rule ("`operator>` is `rhs <
lhs`", and `t <= u` is `!(u < t)`), so a type whose `<` and `>` disagree
compares tuples by its `<` alone, and a tuple of a NaN is equivalent to itself
although `nan <= nan` is false (register entry (vi), pinned by
`tuple_ordered_diff`) (amended 2026-10-22, review fold: A-m-2). Each function
is written out, as OP-1 wrote `Optional`'s (core/prelude/types/optional.carbon
on PR 56), rather than calling the impl's own `Less` through
`OrderedWith(Self)` inside the impl's definition. `Eq` and `Ordered` are the
constraints of comparison.carbon :19-21 and :34-36. The empty tuple is equal to
itself and not less than itself.

### §2.7 C0, nested aggregate constants (built)

Added by rev 2 (amended 2026-10-22, review fold: A-B-3). toolchain/lower/
file_context.cpp, `FileContext::GetConstant`: when the constant's value
representation is a value aggregate (`ValueRepr::ValueAggregate`), the
lowered constant, which is the object representation, is replaced by
`BuildElementwiseConstantValueRepr`, a new static helper that builds an
`llvm::ConstantStruct` of the value representation's type (the pointee of a
pointer representation) from the elements' own constants, each through
`GetConstant` again, so an inner tuple's element is the address of its own
global (a tail-padded element type `<{T, [N x i8]}>` is padded with zeros, as
lower/constant.cpp's `PadToType` pads); the global it then makes for a pointer
representation has that initializer. Invariant: a constant whose value
representation is the object representation (`ValueAndObjectAggregate`, every
flat tuple and struct of scalars) is lowered exactly as before, so no existing
golden changes (M-6's rev 2 line), and the helper returns null for anything
but a `TupleValue` or `StructValue`, which then keeps the old path. The defect
is upstream's (M-12): upstream's `GetConstant` at 57ba07a97 is unchanged, so
the next advance keeps this hunk, which conflicts with nothing upstream has
changed since the cut; it is a defect fix, not a second spelling. C0's golden
is toolchain/lower/testdata/tuple/nested_constant.carbon (§A.11), and W-335
records it.

**C0b** (added by rev 5) (amended 2026-10-26, implementation: stop-and-amend:
nested constant initialization). C0's invariant held, but C0 left two defects
that its probes, which lower values only, could not see (M-20): a copy of such a
constant into storage read the value representation as the object, and its
helper and `GetConstant` call each other, which clang-tidy's `misc-no-recursion`
rejects. C0b is a new commit on C0, before F0:

-   toolchain/lower/function_context.cpp and .h: `CopyValue`, for a type whose
    value representation is `ValueAggregate` and a constant source
    (`IsConstant`, fingerprinted as `AcquireValue` fingerprints a folded
    operand), copies the value representation into the object with the new
    `CopyValueReprToObject`, a worklist over the elements: an element whose
    value representation is its object is stored (`StoreObject`), one held by
    address is copied (`CopyObject`), an elementwise one is expanded in turn,
    and an empty one is skipped; each level reads its elements' values and finds
    their destinations before copying them. Every other type and every other
    source keeps upstream's two arms, so the IR changes only where such a
    constant is copied into storage, and a by-copy initializing expression that
    is not a constant still stores its object representation by value (a03's
    upstream defect, M-20, is not touched).
-   toolchain/lower/file_context.cpp and .h: C0's static helper becomes the
    private `GetElementwiseConstantValueRepr`, which builds the same elementwise
    values, nested ones first, with a worklist instead of calling `GetConstant`;
    upstream's tail of `GetConstant`, which finds or makes the global of a
    pointer value representation, moves unchanged into the private
    `GetOrCreateConstantGlobal`, which both use, so the globals, their names and
    their order are C0's (the fill's value splits are C0's line for line).
-   toolchain/lower/testdata/tuple/nested_constant.carbon gains the splits
    `return` (v04's shape, a constant returned in place) and `one_element`
    (a01's, a by-copy one-element aggregate of a tuple), filled by F0 with C0's.

Invariants: no existing golden changes (the gate before the fill is red on the
new golden alone, M-20); a constant whose value representation is its object
representation, or the address of it, is copied exactly as before; the static
call graph of both files has no cycle. The defect is upstream's: `CopyValue` at
8779d15e1 (function_context.cpp:393-411) has the same two arms, unreached there
for a pointer representation because `GetConstant` aborts first, so the next
advance keeps both hunks unless upstream fixes `GetConstant` and `CopyValue`
itself, and then takes upstream's. The block, against d92a9c709 (`git
apply --check` passes there and at the rev 5 commit; 5 files, 292 insertions and
51 deletions: file_context.cpp 140 and 50, file_context.h 17 and 0,
function_context.cpp 112 and 1, function_context.h 8 and 0, the golden
15 and 0):

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/lower/file_context.cpp b/toolchain/lower/file_context.cpp
index feec811df..da195d675 100644
--- a/toolchain/lower/file_context.cpp
+++ b/toolchain/lower/file_context.cpp
@@ -223,52 +223,6 @@ auto FileContext::Finalize() -> void {
                                          specific_functions_);
 }

-// Fork (VA-2): builds the elementwise value representation of a constant
-// tuple or struct value whose value representation differs from its object
-// representation, such as `((1, 2), 3)`, whose value holds a pointer to the
-// value of `(1, 2)` where its object holds `(1, 2)` itself. The lowered
-// constant `const_value` is the object representation. Returns nullptr if the
-// constant is not a tuple or struct value.
-static auto BuildElementwiseConstantValueRepr(FileContext& context,
-                                              SemIR::InstId const_inst_id,
-                                              SemIR::ValueRepr value_rep,
-                                              SemIR::InstId use_inst_id)
-    -> llvm::Constant* {
-  const auto& sem_ir = context.sem_ir();
-  auto inst = sem_ir.insts().Get(const_inst_id);
-  SemIR::InstBlockId elements_id = SemIR::InstBlockId::None;
-  if (auto tuple = inst.TryAs<SemIR::TupleValue>()) {
-    elements_id = tuple->elements_id;
-  } else if (auto struct_value = inst.TryAs<SemIR::StructValue>()) {
-    elements_id = struct_value->elements_id;
-  } else {
-    return nullptr;
-  }
-  auto repr_type_id = value_rep.kind == SemIR::ValueRepr::Pointer
-                          ? sem_ir.GetPointeeType(value_rep.type_id)
-                          : value_rep.type_id;
-  auto* llvm_type = dyn_cast<llvm::StructType>(context.GetType(repr_type_id));
-  if (!llvm_type) {
-    return nullptr;
-  }
-  llvm::SmallVector<llvm::Constant*> elements;
-  for (auto [index, element_id] :
-       llvm::enumerate(sem_ir.inst_blocks().Get(elements_id))) {
-    auto* element = cast<llvm::Constant>(context.GetConstant(
-        sem_ir.constant_values().Get(element_id), use_inst_id));
-    auto* element_type = llvm_type->getElementType(index);
-    if (element->getType() != element_type) {
-      // A tail-padded element, `<{T, [N x i8]}>`.
-      auto* padded = cast<llvm::StructType>(element_type);
-      element = llvm::ConstantStruct::get(
-          padded, element,
-          llvm::Constant::getNullValue(padded->getElementType(1)));
-    }
-    elements.push_back(element);
-  }
-  return llvm::ConstantStruct::get(llvm_type, elements);
-}
-
 auto FileContext::GetConstant(SemIR::ConstantId const_id,
                               SemIR::InstId use_inst_id) -> llvm::Value* {
   auto const_inst_id = sem_ir().constant_values().GetInstId(const_id);
@@ -311,14 +265,29 @@ auto FileContext::GetConstant(SemIR::ConstantId const_id,
       const_value) {
     // Fork (VA-2): the value representation is elementwise and is not the
     // object representation that `const_value` holds.
-    if (auto* elementwise = BuildElementwiseConstantValueRepr(
-            *this, const_inst_id, value_rep, use_inst_id)) {
-      const_value = elementwise;
+    if (auto* elementwise =
+            GetElementwiseConstantValueRepr(const_inst_id, use_inst_id)) {
+      return elementwise;
     }
   }
   if (value_rep.kind != SemIR::ValueRepr::Pointer) {
     return const_value;
   }
+  return GetOrCreateConstantGlobal(const_inst_id, value_rep, const_value,
+                                   use_inst_id);
+}
+
+// Fork (VA-2): the global variable that `GetConstant` makes for a constant
+// whose value representation is a pointer, split out so that
+// `GetElementwiseConstantValueRepr` makes the same globals for the elements.
+auto FileContext::GetOrCreateConstantGlobal(SemIR::InstId const_inst_id,
+                                            SemIR::ValueRepr value_rep,
+                                            llvm::Constant* value,
+                                            SemIR::InstId use_inst_id)
+    -> llvm::GlobalVariable* {
+  if (auto result = global_variables().Lookup(const_inst_id)) {
+    return result.value();
+  }

   // Include both the name of the constant, if any, and the point of use in
   // the name of the variable.
@@ -343,13 +312,134 @@ auto FileContext::GetConstant(SemIR::ConstantId const_id,

   auto* global_variable = new llvm::GlobalVariable(
       llvm_module(), GetType(sem_ir().GetPointeeType(value_rep.type_id)),
-      /*isConstant=*/true, llvm::GlobalVariable::InternalLinkage, const_value,
+      /*isConstant=*/true, llvm::GlobalVariable::InternalLinkage, value,
       const_name + sep + use_name);

   global_variables_.Insert(const_inst_id, global_variable);
   return global_variable;
 }

+// Fork (VA-2): builds the value representation of the constant tuple or
+// struct value `const_inst_id` whose value representation holds its elements'
+// value representations (`ValueRepr::ValueAggregate`), such as `((1, 2), 3)`,
+// whose value holds the address of the value of `(1, 2)` where its object holds
+// `(1, 2)` itself, from the elements' constants: the value itself, or the
+// address of a global that holds it if the value representation is a pointer.
+// An element of the same kind is built first, by a worklist rather than by
+// recursion. Returns nullptr if the constant is not such a value.
+auto FileContext::GetElementwiseConstantValueRepr(SemIR::InstId const_inst_id,
+                                                  SemIR::InstId use_inst_id)
+    -> llvm::Value* {
+  struct Aggregate {
+    llvm::ArrayRef<SemIR::InstId> elements;
+    SemIR::ValueRepr value_rep;
+    llvm::StructType* llvm_type;
+  };
+  // Returns the elements of `inst_id` if it is a lowered constant tuple or
+  // struct value whose value representation is elementwise.
+  auto get_aggregate = [&](SemIR::InstId inst_id) -> std::optional<Aggregate> {
+    auto inst = sem_ir().insts().Get(inst_id);
+    auto value_rep = SemIR::ValueRepr::ForType(sem_ir(), inst.type_id());
+    if (value_rep.aggregate_kind != SemIR::ValueRepr::ValueAggregate ||
+        !constants_.Get(inst_id)) {
+      return std::nullopt;
+    }
+    SemIR::InstBlockId elements_id = SemIR::InstBlockId::None;
+    if (auto tuple = inst.TryAs<SemIR::TupleValue>()) {
+      elements_id = tuple->elements_id;
+    } else if (auto struct_value = inst.TryAs<SemIR::StructValue>()) {
+      elements_id = struct_value->elements_id;
+    } else {
+      return std::nullopt;
+    }
+    auto repr_type_id = value_rep.kind == SemIR::ValueRepr::Pointer
+                            ? sem_ir().GetPointeeType(value_rep.type_id)
+                            : value_rep.type_id;
+    auto* llvm_type = dyn_cast<llvm::StructType>(GetType(repr_type_id));
+    if (!llvm_type) {
+      return std::nullopt;
+    }
+    return Aggregate{.elements = sem_ir().inst_blocks().Get(elements_id),
+                     .value_rep = value_rep,
+                     .llvm_type = llvm_type};
+  };
+  auto get_element_inst_id = [&](SemIR::InstId element_id) {
+    return sem_ir().constant_values().GetInstId(
+        sem_ir().constant_values().Get(element_id));
+  };
+
+  if (!get_aggregate(const_inst_id)) {
+    return nullptr;
+  }
+  // Each aggregate is popped once to push its elements of the same kind that
+  // are not built yet, and again, after them, to be built.
+  struct Pending {
+    SemIR::InstId inst_id;
+    bool elements_pushed;
+  };
+  llvm::SmallVector<Pending> worklist = {
+      {.inst_id = const_inst_id, .elements_pushed = false}};
+  // The value representations of the elements built so far.
+  Map<SemIR::InstId, llvm::Value*> built;
+  while (true) {
+    auto [inst_id, elements_pushed] = worklist.back();
+    auto aggregate = *get_aggregate(inst_id);
+    if (!elements_pushed) {
+      worklist.back().elements_pushed = true;
+      for (auto element_id : aggregate.elements) {
+        auto element_inst_id = get_element_inst_id(element_id);
+        if (get_aggregate(element_inst_id) &&
+            !built.Contains(element_inst_id) &&
+            !global_variables().Lookup(element_inst_id)) {
+          worklist.push_back(
+              {.inst_id = element_inst_id, .elements_pushed = false});
+        }
+      }
+      continue;
+    }
+    worklist.pop_back();
+
+    llvm::SmallVector<llvm::Constant*> elements;
+    for (auto [index, element_id] : llvm::enumerate(aggregate.elements)) {
+      auto element_inst_id = get_element_inst_id(element_id);
+      llvm::Value* element_value = nullptr;
+      if (auto nested = built.Lookup(element_inst_id)) {
+        element_value = nested.value();
+      } else {
+        // As `GetConstant` lowers an element of any other kind.
+        auto element_value_rep = SemIR::ValueRepr::ForType(
+            sem_ir(), sem_ir().insts().Get(element_inst_id).type_id());
+        auto* element_constant = constants_.Get(element_inst_id);
+        element_value =
+            element_value_rep.kind == SemIR::ValueRepr::Pointer
+                ? GetOrCreateConstantGlobal(element_inst_id, element_value_rep,
+                                            element_constant, use_inst_id)
+                : element_constant;
+      }
+      auto* element = cast<llvm::Constant>(element_value);
+      auto* element_type = aggregate.llvm_type->getElementType(index);
+      if (element->getType() != element_type) {
+        // A tail-padded element, `<{T, [N x i8]}>`.
+        auto* padded = cast<llvm::StructType>(element_type);
+        element = llvm::ConstantStruct::get(
+            padded, element,
+            llvm::Constant::getNullValue(padded->getElementType(1)));
+      }
+      elements.push_back(element);
+    }
+    auto* value = llvm::ConstantStruct::get(aggregate.llvm_type, elements);
+    llvm::Value* result =
+        aggregate.value_rep.kind == SemIR::ValueRepr::Pointer
+            ? GetOrCreateConstantGlobal(inst_id, aggregate.value_rep, value,
+                                        use_inst_id)
+            : value;
+    if (worklist.empty()) {
+      return result;
+    }
+    built.Insert(inst_id, result);
+  }
+}
+
 auto FileContext::GetOrCreateFunctionInfo(
     SemIR::FunctionId function_id, SemIR::SpecificId specific_id,
     FileContext* fallback_file, SemIR::FunctionId fallback_function_id,
diff --git a/toolchain/lower/file_context.h b/toolchain/lower/file_context.h
index 64d018bb3..f7add6d4a 100644
--- a/toolchain/lower/file_context.h
+++ b/toolchain/lower/file_context.h
@@ -362,6 +362,23 @@ class FileContext {
   auto BuildVtable(const SemIR::Vtable& vtable, SemIR::SpecificId specific_id)
       -> llvm::Constant*;

+  // Fork (VA-2): returns the global variable holding `value`, the constant
+  // `const_inst_id` in the pointee type of its pointer value representation
+  // `value_rep`, made on first use. Used by `GetConstant`.
+  auto GetOrCreateConstantGlobal(SemIR::InstId const_inst_id,
+                                 SemIR::ValueRepr value_rep,
+                                 llvm::Constant* value,
+                                 SemIR::InstId use_inst_id)
+      -> llvm::GlobalVariable*;
+
+  // Fork (VA-2): returns the value representation of a constant tuple or
+  // struct value whose value representation holds its elements' value
+  // representations, or nullptr for any other constant. Used by
+  // `GetConstant`.
+  auto GetElementwiseConstantValueRepr(SemIR::InstId const_inst_id,
+                                       SemIR::InstId use_inst_id)
+      -> llvm::Value*;
+
   // Records a specific that was lowered for a generic. These are added one
   // by one while lowering their definitions.
   auto AddLoweredSpecificForGeneric(SemIR::GenericId generic_id,
diff --git a/toolchain/lower/function_context.cpp b/toolchain/lower/function_context.cpp
index c19fafaa9..4c8659720 100644
--- a/toolchain/lower/function_context.cpp
+++ b/toolchain/lower/function_context.cpp
@@ -535,7 +535,23 @@ auto FunctionContext::StoreObject(TypeInFile type, llvm::Value* value,

 auto FunctionContext::CopyValue(TypeInFile type, SemIR::InstId source_id,
                                 SemIR::InstId dest_id) -> void {
-  switch (GetValueRepr(type).repr.kind) {
+  auto value_repr = GetValueRepr(type).repr;
+  if (value_repr.aggregate_kind == SemIR::ValueRepr::ValueAggregate) {
+    // Fork (VA-2): a constant is lowered to its value representation
+    // (`FileContext::GetConstant`), which for this type holds its elements'
+    // value representations, such as the address of the value of `(1, 2)` in
+    // the value of `((1, 2), 3)`, so it is neither the object representation
+    // nor its address, as the copies below assume. Any other source keeps
+    // them: for this type, an initializing expression that is not a constant
+    // produces the object representation by value (`InitRepr::ByCopy`).
+    bool is_constant = IsConstant(source_id);
+    AddIntToCurrentFingerprint(is_constant);
+    if (is_constant) {
+      CopyValueReprToObject(type, GetValue(source_id), GetValue(dest_id));
+      return;
+    }
+  }
+  switch (value_repr.kind) {
     case SemIR::ValueRepr::Unknown:
       CARBON_FATAL("Attempt to copy incomplete type");
     case SemIR::ValueRepr::Dependent:
@@ -570,6 +586,101 @@ auto FunctionContext::CopyObject(TypeInFile type, llvm::Value* source_addr,
                          layout.getTypeAllocSize(llvm_type));
 }

+auto FunctionContext::CopyValueReprToObject(TypeInFile type, llvm::Value* value,
+                                            llvm::Value* dest_addr) -> void {
+  // A worklist of copies rather than recursion over the elements.
+  struct PendingCopy {
+    TypeInFile type;
+    llvm::Value* value;
+    llvm::Value* dest_addr;
+  };
+  llvm::SmallVector<PendingCopy> worklist = {
+      {.type = type, .value = value, .dest_addr = dest_addr}};
+  while (!worklist.empty()) {
+    auto copy = worklist.pop_back_val();
+    auto value_repr = GetValueRepr(copy.type);
+    llvm::SmallVector<SemIR::TypeId> element_type_ids;
+    bool elementwise = false;
+    if (value_repr.repr.aggregate_kind == SemIR::ValueRepr::ValueAggregate) {
+      const auto& file = *copy.type.file;
+      auto type_inst = file.types().GetAsInst(copy.type.type_id);
+      if (auto tuple_type = type_inst.TryAs<SemIR::TupleType>()) {
+        elementwise = true;
+        for (auto element_type_id : file.types().GetBlockAsTypeIds(
+                 file.inst_blocks().Get(tuple_type->type_elements_id))) {
+          element_type_ids.push_back(element_type_id);
+        }
+      } else if (auto struct_type = type_inst.TryAs<SemIR::StructType>()) {
+        elementwise = true;
+        for (auto field :
+             file.struct_type_fields().Get(struct_type->fields_id)) {
+          element_type_ids.push_back(
+              file.types().GetTypeIdForTypeInstId(field.type_inst_id));
+        }
+      }
+    }
+    if (!elementwise) {
+      // The value representation is the object representation or its
+      // address.
+      switch (value_repr.repr.kind) {
+        case SemIR::ValueRepr::None:
+          break;
+        case SemIR::ValueRepr::Copy:
+          StoreObject(copy.type, copy.value, copy.dest_addr);
+          break;
+        case SemIR::ValueRepr::Pointer:
+          CopyObject(copy.type, copy.value, copy.dest_addr);
+          break;
+        case SemIR::ValueRepr::Unknown:
+        case SemIR::ValueRepr::Dependent:
+        case SemIR::ValueRepr::Custom:
+          CARBON_FATAL(
+              "Attempt to copy a value of type {0} with value "
+              "representation {1}",
+              copy.type.file->types().GetAsInst(copy.type.type_id),
+              value_repr.repr);
+      }
+      continue;
+    }
+
+    // The value representation is a struct of the elements' value
+    // representations, held by value or by address. Each element's value is
+    // read, and its destination found, before any element is copied.
+    auto value_repr_type = value_repr.type();
+    if (value_repr.repr.kind == SemIR::ValueRepr::Pointer) {
+      value_repr_type.type_id =
+          value_repr_type.file->GetPointeeType(value_repr_type.type_id);
+    }
+    auto* llvm_value_repr_type = GetType(value_repr_type);
+    auto* llvm_object_type = GetType(
+        {.file = copy.type.file,
+         .type_id = copy.type.file->types().GetObjectRepr(copy.type.type_id)});
+    llvm::SmallVector<PendingCopy> element_copies;
+    for (auto [index, element_type_id] : llvm::enumerate(element_type_ids)) {
+      TypeInFile element_type = {.file = copy.type.file,
+                                 .type_id = element_type_id};
+      auto element_value_repr = GetValueRepr(element_type);
+      if (element_value_repr.repr.kind == SemIR::ValueRepr::None) {
+        continue;
+      }
+      llvm::Value* element_value = nullptr;
+      if (value_repr.repr.kind == SemIR::ValueRepr::Pointer) {
+        element_value = LoadObject(
+            element_value_repr.type(),
+            builder().CreateStructGEP(llvm_value_repr_type, copy.value, index));
+      } else {
+        element_value = builder().CreateExtractValue(copy.value, index);
+      }
+      element_copies.push_back({.type = element_type,
+                                .value = element_value,
+                                .dest_addr = builder().CreateStructGEP(
+                                    llvm_object_type, copy.dest_addr, index)});
+    }
+    // Copied in order: the worklist is a stack.
+    worklist.append(element_copies.rbegin(), element_copies.rend());
+  }
+}
+
 auto FunctionContext::Inserter::InsertHelper(
     llvm::Instruction* inst, const llvm::Twine& name,
     llvm::BasicBlock::iterator insert_pt) const -> void {
diff --git a/toolchain/lower/function_context.h b/toolchain/lower/function_context.h
index 9436dd706..a11c4b1bd 100644
--- a/toolchain/lower/function_context.h
+++ b/toolchain/lower/function_context.h
@@ -387,6 +387,14 @@ class FunctionContext {
   auto CopyObject(TypeInFile type, SemIR::InstId source_id,
                   SemIR::InstId dest_id) -> void;

+  // Fork (VA-2): emits a copy of `value`, a value representation of `type`,
+  // into the object at `dest_addr`: element by element for a tuple or struct
+  // type whose value representation holds its elements' value
+  // representations (`ValueRepr::ValueAggregate`), and otherwise as a store
+  // or an object copy.
+  auto CopyValueReprToObject(TypeInFile type, llvm::Value* value,
+                             llvm::Value* dest_addr) -> void;
+
   // Serves a reference to a file-scope `let` binding whose bound value is a
   // runtime value (W-069): `inst_id` is either such a binding of the current
   // file (or its bound value), or an imported instruction whose canonical
diff --git a/toolchain/lower/testdata/tuple/nested_constant.carbon b/toolchain/lower/testdata/tuple/nested_constant.carbon
index 606a51464..ada23d40c 100644
--- a/toolchain/lower/testdata/tuple/nested_constant.carbon
+++ b/toolchain/lower/testdata/tuple/nested_constant.carbon
@@ -51,3 +51,18 @@ fn Read() -> i32 {
   let m: {.t: (i32, i32), .u: i32} = {.t = (4, 5), .u = 6};
   return m.t.1;
 }
+
+// --- return.carbon
+library "[[@TEST_NAME]]";
+
+fn Make() -> ((i32, i32), i32) {
+  return ((4, 5), 6);
+}
+
+// --- one_element.carbon
+library "[[@TEST_NAME]]";
+
+fn Read() -> i32 {
+  var v: ((i32, i32),) = ((1, 2),);
+  return v.0.1;
+}
```

<!-- google-doc-style-resume -->

## §3 Commits (one PR, "VA-2: definition-checked variadics, slice 2", R29(b))

**D-VA2-19.** A prerequisite commit C0, followed since rev 5 by its
stop-and-amend commit C0b before its fill (amended 2026-10-26, implementation:
stop-and-amend: nested constant initialization), and five implementation
commits, C1 to C5, each followed, when it adds or changes goldens, by its own
fill commit,
then the row commit R and, after the two implementation reviews and their fix
commits, the discharge D; at land time the commits M, S-CT, F-M, L-F and L
(D-VA2-18) (amended 2026-10-22, review fold: A-B-3 / B-M5); S-CT has been a
test-only commit since rev 3 (amended 2026-10-26, review fold: RR1-B-M5).
Each commit builds
on its own, and its gate is judged on the commit plus its fill, the fork's
practice since ST-1: an implementation commit alone is red on exactly its new
goldens and its listed refills, with no crash, and on nothing else. The split
of the prototype's one diff into C0, C1 and C2 is by file and by function, as
§2.1 to §2.3 and §2.7 assign each hunk; the implementer checks that C1 builds
without C2's hunks before writing C2 (§8.1). Rev 6's split built but its gate
aborted, so since rev 7 C1 takes two of the hunks §2.3 gave C2 (§2.2's block,
M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden
sources). _Break condition:_ a commit cannot build without a later commit's
files, which merges the two and is recorded in the landed notes; and, since rev
7, a commit whose gate crashes without a later commit's hunk takes that hunk, by
a plan revision before it is committed, which the landed notes record too.

**Fix commits and the shrink line** (amended 2026-10-22, review fold: A-B-2 /
B-M6). The rev 4 prototype, which is C0, C1 and the built half of C2, is 31
non-test toolchain files with 1399 insertions and 122 deletions (rev 2's,
which this sentence measured until rev 4: 30, 1242 and 121; amended
2026-10-26, review fold: RR2-m3); VA-1's
non-test toolchain change from its C2 to its head is 43 files, 1682
insertions and 41 deletions (`git diff --shortstat 663a29df6 b0822a744 --
toolchain ':!toolchain/*/testdata/*'`). VA-2 adds two instruction kinds
(`PackSegmentInit`, `PackExpansionNext`) against VA-1's eight, and more than
half of it has been built (§0.5); the lowering crash rev 1 measured (M-9) has
a root cause and a built fix (M-13), so no measured defect is left without a
spec. VA-1 used three fix commits. VA-2 budgets three fix commits after the
first builds and the implementation reviews, each its own commit with its own
fill, never an amend. Because the reviews see C0 to C5 built, a shrink removes
built commits by new revert commits, never by rewriting history (AGENTS.md):
each shrink is a plan revision the reviews see first, then `git revert
--no-commit` of the commits it names, a commit "VA-2 shrink <n>: <subject>"
with the records it changes, and its fill; no new id is needed, because what a
shrink drops stays in the items that hold it now. In order, each including the
ones before it:

1.  **Shrink 1, statement expansions of `if`** (C3 cannot pass §8.3 and §8.4
    within the budget). Reverts C3 and F3; removes the comparison impls from
    C4's comparison.carbon and their splits from C4's two goldens; removes
    `variadics_min`, `tuple_eq_diff`, `tuple_ordered_diff` and the comparison
    half of `tuple_impl_generic`. Expected: gate 1973 of 1973 after its fill
    (C3's two goldens gone; fail_todo_va2 and fail_todo_slice refilled
    without C3's splits; the full-prelude refills re-measured), conformance
    PASS 144, 0 failures, SKIP 21 of 165. Records: W-218 and W-219 keep their
    titles; W-225 is narrowed, not discharged (the `Copy` rewrite done, `Eq`
    and `Ordered` remain in it); the stdlib row keeps "no tuple Eq/Ordered".
2.  **Shrink 2, tuple values with a pack segment** (C2's `PackSegmentInit` or
    `let` cannot be made to work). Also reverts C4 and F4 (the prelude
    untouched), C2's tuple-value hunks and their splits (`tuple_segment`'s
    `return`, `let` and `tuple_value`, the lower `make_tuple`, `let` and
    `one_tuple`, `fail_todo_va2`'s `fail_todo_initializing_element`), and
    removes `tuple_copy_variadic`, `tuple_impl_generic` and
    `variadics_tuple_param`. Expected: gate 1971 of 1971 after its fill (C4's
    two goldens gone, the 44 refills reverted), conformance PASS 141, 0
    failures, SKIP 21 of 162. Records: W-225 stays as filed, open; W-213 is
    narrowed further (tuple types with a segment as parameter, return and
    impl self types, and their deduction, done; tuple values and `let`
    remain); W-214 is not narrowed; the stdlib row stays as it is.
3.  **Shrink 3, variadic impls** (impl selection, ranking or the lowering of a
    variadic impl's functions cannot be made to pass). Also reverts C2's
    type-structure, ranking and impl hunks and the `impl` and `fail_impl`
    goldens, and makes an impl whose self type has a pack segment the
    `semantics TODO: impl whose self type has a pack segment` (W-225), with a
    `fail_todo_va2` split. Expected: gate 1969 of 1969 after its fill,
    conformance PASS 141, 0 failures, SKIP 21 of 162 (no remaining program
    uses a variadic impl). Records: D-VA2-10 is withdrawn; W-225 stays as
    filed.

The commits, in order:

0.  **P, the plan.** Rev 1 (51c6cfb10), "VA-2 plan (rev 1): generic and
    heterogeneous packs, tuples with pack segments, variadic impls with the
    prelude tuple Copy, Eq and Ordered"; rev 2 (78524522b) folds the two plan
    reviews of R29(c); rev 3 (8d377a06d) folds the focused re-review of rev
    2; rev 4 (this commit) folds the second focused re-review, of rev 3, and
    is the sign-off revision (the Sign-off section); rev 3 still called rev 2
    "this commit" (amended 2026-10-26, review fold: RR2-m3). Each later
    revision is a new commit, each amended sentence marked "(amended <date>,
    review fold: <finding>)".
1.  **C0, nested aggregate constants** (§2.7: Appendix B's
    lower/file_context.cpp hunk). New golden: lower `tuple/nested_constant`.
    Expected gate: red on exactly that 1 file (amended 2026-10-22, review
    fold: A-B-3).
    Since rev 5 C0 is followed by **C0b, nested aggregate constants copied into
    storage** (§2.7's block): lower/file_context.cpp and .h,
    lower/function_context.cpp and .h, and the golden's `return` and
    `one_element` splits; expected gate: red on exactly that 1 file, with no
    crash (M-20) (amended 2026-10-26, implementation: stop-and-amend: nested
    constant initialization).
2.  **F0.** Autoupdate of that file to the fixpoint, after C0b (amended
    2026-10-26, implementation: stop-and-amend: nested constant initialization).
3.  **C1, packs of different types** (§2.1, §2.2: Appendix B's hunks in
    sem_ir/typed_insts.h, generic.h, generic.cpp, stringify.cpp,
    type_iterator.cpp's `PackElement` case and, since rev 7, its `PackType`
    case; check/eval.cpp, eval.h,
    eval_inst.cpp's `PackElement` case, generic.cpp, type.h, type.cpp,
    context.h, handle_pack_expansion.cpp, handle_binding_pattern.cpp,
    deduce.cpp's `PackType` branch, convert.cpp's pack conversions, its
    `InitializeAction` site and, since rev 7, `ConvertTupleToType`'s pack
    segment (§2.2's block, M-21) (amended 2026-10-26, implementation:
    stop-and-amend: C1's split and golden sources), type_completion.cpp's pack
    case, import_ref.cpp,
    merge.cpp, pattern_match.cpp, and since rev 3 action.cpp (amended
    2026-10-26, review fold: RR1-B-M5); the lower files but file_context.cpp),
    plus C1's own changes: the implicit-list TODO of F-3, the relabeled
    each-name binding TODO, the computed-element-type TODO, the DR-17 TODO of
    F-7. New goldens: check `hetero_pack`, `fail_hetero_pack`, `generic_pack`,
    `fail_todo_va2` (its C1 splits), lower `hetero_pack`, with since rev 3 lower
    `hetero_pack`'s `lib` and `use` splits, check `hetero_pack`'s
    `cpp_template_outer` and `fail_todo_va2`'s
    `fail_todo_cpp_template_on_hetero_element` (amended 2026-10-26, review fold:
    RR1-NB-1 / RR1-B-M5), and since rev 4 `hetero_pack`'s `template_outer` and
    `fail_todo_va2`'s `fail_todo_class_pack`, `fail_todo_interface_pack`,
    `fail_todo_explicit_generic_pack`,
    `fail_todo_template_action_on_hetero_element` and
    `fail_todo_cpp_template_on_tuple_of_pack` (amended 2026-10-26, review fold:
    RR2-M1 / RR2-m1 / RR2-m2); refilled: each_param, forward, import,
    fail_todo_slice (`fail_todo_generic_pack` removed, `fail_todo_ref_pack`
    relabeled) and the lower pack_expansion. Expected gate: red on exactly these
    10 files, with no crash: 1956 passed and 10 failed, measured on C1 with
    §2.2's block, where rev 6's split aborted (M-21) (amended 2026-10-26,
    implementation: stop-and-amend: C1's split and golden sources); the four
    splits of `hetero_pack` and `generic_pack` that call a generic define it
    since rev 7 (§A.11).
4.  **F1.** Autoupdate of those 10 files to the fixpoint: one pass, and the gate
    1966 passed (measured, M-21: the fill is `$M/fill_rev7_p2`) (amended
    2026-10-26, implementation: stop-and-amend: C1's split and golden sources).
5.  **C2, tuples with a pack segment** (§2.3 built, §2.4 specified): `TupleType`
    and `TupleValue` conditional, the tuple deduction, the dependent
    representation, the run entry and the ranking of the type structure
    (type_structure.h, type_structure.cpp, impl_lookup.cpp; since rev 7
    type_iterator.cpp's `PackType` case and `ConvertTupleToType`'s pack segment
    are C1's, and C2's built half is `$M/c2_rest_after_v1b.patch`, M-21)
    (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden
    sources), tuple literals with one segment,
    `PackSegmentInit`, `let` with a fixed-arity pack expansion pattern, the
    tuple TODOs, and since rev 3 handle_pack_expansion.cpp's `specific_constant`
    reference to an enclosing generic's arity, which only a function of a
    variadic impl needs (M-17) (amended 2026-10-26, review fold: RR1-NB-1). New
    goldens: check `tuple_segment`, `fail_todo_tuple_segment`, `impl` (with its
    `body_expansion` split), `fail_impl`, lower `tuple_segment` (with its
    `impl_body`, `impl_lib` and `impl_use` splits (amended 2026-10-26, review
    fold: RR1-NB-1)); `fail_todo_va2` gains its C2 splits; fail_todo_slice
    refilled (`fail_todo_tuple_pattern` and `fail_todo_tuple_literal`
    relabeled). Expected gate: red on exactly 7 files.
6.  **F2.** Autoupdate of those 7 files.
7.  **C3, statement expansions of `if`** (§2.5): the body region,
    `PackExpansionNext`, per-iteration blocks. New goldens: check
    `expansion_if`, lower `expansion_if`; `fail_todo_va2` gains
    `fail_todo_if_with_declaration` and `fail_todo_while`; fail_todo_slice
    refilled (`fail_todo_statement_kind` relabeled). Expected gate: red on
    exactly 4 files.
8.  **F3.** Autoupdate of those 4 files.
9.  **C4, the prelude** (§2.6): core/prelude/copy.carbon :50-71 and
    core/prelude/operators/comparison.carbon. New goldens: check and lower
    `variadics/prelude_tuple_impls` on the production prelude (amended
    2026-10-22, review fold: B-m4). Expected gate: red on those 2 and on M-9's
    predicted 44 full-prelude goldens (43 check goldens by renamed SemIR names,
    toolchain/lower/testdata/for/bindings.carbon by its lowered tuple copy), a
    lower bound (M-9), and on nothing that includes a `min_prelude` other than
    `full.carbon`. Before F4, d01 to d03 (M-20) print 101 1, 1 2 and 1 2 on C4's
    install; one that does not is R-13's stop at C4 (amended 2026-10-26, review
    fold: RR5-M1).
10. **F4.** Autoupdate of those files; a full-prelude golden outside M-9's 44
    is listed with its cause in the implementation review, and one that
    changes by more than renamed names or C4's lowered copies is a finding
    (R-5).
11. **C5, programs** (Appendix A): the ten programs and three `.diff.cpp`
    files, and fork/conformance/README.md's table regenerated by
    `runner.py --update-readme-table`. Expected: §8.4's totals.
12. **Implementation reviews** (two, R29(c)), then at most three fix commits
    by a separate fixer, each with its own fill, each named "VA-2 fix <n>:
    <subject>", or a shrink above.
13. **R, the rows.** §A.12's text for "Generics: Definition-checked variadics"
    and "Stdlib: tuple/array library parts", quoting §8.4's container run,
    EXPECTED, not of record; both stay PARTIAL, so the header's counts do not
    move (§1.9).
14. **D, discharge** (§A.12): the ledger (W-212 and W-225 discharged, W-213
    narrowed; W-214, W-218, W-219, W-222 narrowed; W-220, W-221 (since rev 4,
    amended 2026-10-26, review fold: RR2-M1), W-223, W-224, W-226, W-229,
    W-230 and W-013 noted; W-330 to W-339 filed, W-335 as
    DISCHARGED), the decision-log entry, fork/ORCHESTRATION.md (with the Next
    actions of W-332, W-338 and W-339), the W6 sentence of
    fork/gap-analysis.md, after §8.10's id re-scan.
15. **Land time, when VA-2 is next** (D-VA2-18), messages below: M, the merge of
    trunk (a merge commit, `git merge --no-ff`, conflicts resolved by §6.2's
    rules); S-CT, the land-time test commit of D-VA2-14 (the split file
    `fail_todo_cpp_call_on_hetero_element` of §A.11, no code: rev 2's
    `$F/r3/s_ct.patch` hunk in check/call.cpp is withdrawn, C1's
    `AddDependentActionInst` refusal covering CT-1's paths once M merges them
    (amended 2026-10-26, review fold: RR1-B-M5)); F-M, the fill that M and S-CT
    need (autoupdate only); L-F, the README table and any program header that
    names a count, regenerated on the merged tree; L, the land-time records
    commit, re-quoting §8.8's run on the merge commit in the rows, the ledger
    and ORCHESTRATION (amended 2026-10-22, review fold: B-M5 / B-m2).

Every commit uses explicit paths (R20, never `git add -A`), runs `SKIP=
fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
uvx prek run --files <its files>` to a fixpoint first, with R31's heading and
list-item counts before and after for each `.md`, and uses the author
`jmann345 <jerrymannstan@gmail.com>`, the committer `Claude
<noreply@anthropic.com>` (`GIT_COMMITTER_NAME=Claude
GIT_COMMITTER_EMAIL=noreply@anthropic.com`) and the session's attribution
trailers after a blank line, which this plan does not spell out because a
repository file names no model. A problem found after a commit exists is fixed
by a new commit (AGENTS.md). Fill commits, F-M included, are "Autoupdate
testdata goldens on the container arbiter". The other messages, verbatim but
for `<...>` fields (S-CT's last sentence, which rev 3 left singular for a file
of three splits, is plural since rev 4, amended 2026-10-26, review fold:
RR2-m3; C1's names the TODO of RR2-M1 and the pack literal of RR2-m1; C0b's
follows C0's since rev 5, and C0's last sentence, committed before C0b existed,
means the fill that follows C0b (amended 2026-10-26, implementation:
stop-and-amend: nested constant initialization); C0b's title has C0's form,
`VA-2 C0b:`, since rev 6, where rev 5 wrote `VA-2 (0b):` (amended 2026-10-26,
review fold: RR5-m1); since rev 7 C1's says what `(... each T)` is as a type,
and the `specific_constant` that names an enclosing generic's arity, a hunk §2.2
gives C2, is in C2's, where rev 4 put it in C1's (amended 2026-10-26,
implementation: stop-and-amend: C1's split and golden sources)):

<!-- google-doc-style-ignore -->

```text
VA-2 C0: lower nested aggregate constants in their value representation

A constant tuple or struct value whose value representation is elementwise,
such as `((1, 2), 3)`, whose value holds the inner tuple's value by
pointer, was given a global of the value representation's type initialized
with the object representation, which LLVM's verifier rejects ("Global
variable initializer type does not match global variable type!") on every
toolchain since the fork's cut, upstream's tip included. GetConstant now
builds the elementwise value representation from the elements' constants.
The new lower golden is filled by the next commit.

fork/variadics/va2-plan.md §2.7, M-12.
```

```text
VA-2 C0b: copy nested aggregate constants into storage element by element

C0 lowers a constant tuple or struct value whose value representation
holds its elements' value representations, such as `((1, 2), 3)`, to
that value representation, but copying such a constant into storage
still read it as the object representation:
`var v: ((i32, i32), i32) = ((4, 5), 6);` copied the inner tuple's
address into `v.0`, and a one-element aggregate of such a value, such as
`((1, 2),)`, which PR 59 and trunk copy correctly, aborted in
StoreObject. CopyValue now copies such a constant into the object
element by element, and GetConstant builds the elementwise value with a
worklist instead of a recursive call chain. The golden gains the splits
return and one_element and is filled, with C0's, by the next commit.

fork/variadics/va2-plan.md §2.7, M-20, the stop-and-amend record (rev 5).
```

```text
VA-2 C1: packs of different types in implicit parameter lists

A function or impl may declare `[... each T: I]` in its implicit
parameter list and take `... each x: each T`; a call deduces the pack of
argument types and their arity, checks each element's `I` by impl
lookup, and the body is checked once with `each x` of the symbolic type
`each T`. The pack index is a symbolic constant, so a specific of a
variadic generic evaluates its eval blocks once per element and lowers
each iteration with that element's types and callees; a pack of
different types is laid out as a tuple, and diagnostics name `each T`,
`⟬each T⟭`, `(... each T)` and a specific's pack of types `⟬A, B⟭`. A
specific of a variadic generic imported from another library gets the
same per-iteration values. `(... each T)` in a type position is the
tuple type whose one element is the pack type `⟬each T⟭`, which the type
iterator visits as a symbolic type. A second implicit-list pack, a
second pack arity in a generic, a computed element type, forwarding
between a pack of different types and a pack of one type, an expansion
without each-names in a binding's type, a template each-name, a
compile-time each-name of a class, an interface or an explicit `generic`
parameter, and a C++ or template-dependent action whose operand depends
on the pack index are semantics TODOs. VA-1's goldens are refilled by
the next commit.

fork/variadics/va2-plan.md §2.1, §2.2, D-VA2-2 to D-VA2-7, D-VA2-13, M-21.
```

```text
VA-2 C2: tuples with one pack segment, `let` pack bindings, variadic impls

`(... each T)` is a tuple type of one pack segment, flattened once the
segment's arity is known, deduced from a tuple argument, and represented
as the specific's until then. Impl lookup keeps the tuple in the type
structure, `(...?)`, the segment matching a run of the query's elements,
and ranks impls by the overlap rule along the query, so `impl forall
[... each T: I] (... each T) as I` is selected for tuples of every arity
beside blanket and fixed-arity impls; an expansion in a variadic impl's
function over the impl's pack names the impl's arity by a
specific_constant of its self specific, as a name from an enclosing
generic is named. `(... each x)` initializes a tuple element by element,
and `let (... each x: each T) = t;` binds a pack to a tuple's elements
without copying. More than one segment, a segment beside other elements
and initializing expansion elements are semantics TODOs.

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
Ordered: `==` calls the elements' `==`, `!=` the elements' `!=`, and the
four relations call the elements' `<`. Two goldens on the production
prelude pin the impls; the full-prelude goldens are refilled by the next
commit.

fork/variadics/va2-plan.md §2.6, D-VA2-12.
```

```text
VA-2 C5: conformance programs for packs of different types and tuple impls

Ten programs: six for "Generics: Definition-checked variadics" (the
design's StrCat shape with a C++17 oracle, the design's StrCat text over
locally declared names, forwarding, the empty pack, tuple-typed parameters
and returns, the design's Min) and four for "Stdlib: tuple/array library
parts" (tuple Copy at arities 1, 2, 4, 5 and 13 and nested, equality and
ordering against std::tuple, the impls through generic requirements). The
README table is regenerated.

fork/variadics/va2-plan.md Appendix A, D-VA2-16.
```

```text
VA-2 R: gap rows for slice 2, expected, not of record

"Generics: Definition-checked variadics" stays PARTIAL with slice 2 in its
evidence and a "Not yet" list that names each remaining form with its id;
"Stdlib: tuple/array library parts" stays PARTIAL with the variadic tuple
impls in its evidence and only mixed-operand comparisons and the
comparison of orderings that are not total open, on the container run
<run> (fork/variadics/va2-plan.md §8.4), expected, not of record; the
header's counts do not move.
```

```text
VA-2 discharge: W-212 and W-225 discharged, W-213 narrowed, W-330 to W-339 filed

W-013 stays open with slice 2 in its notes; W-213, W-214, W-218, W-219
and W-222 are narrowed and W-220, W-221, W-223, W-224, W-226, W-229 and
W-230 noted; W-330 to W-339 are filed from fork/variadics/va2-plan.md §1.11,
W-335 as discharged by C0 and C0b. The decision-log entry "VA-2" records
D-VA2-1 to D-VA2-19, the rejected alternatives and the V-3a register entries;
ORCHESTRATION records the PR and the Next actions of W-332, W-338 and
W-339.
```

```text
Merge trunk <sha> into VA-2 for landing

Merges trunk at <sha>, which holds every PR before VA-2 in
fork/ORCHESTRATION.md's merge order, into claude/carbon-fork-0-1-va2.
Conflicts resolved by fork/variadics/va2-plan.md §6.2's rules:
convert.cpp's ConvertTupleToType and eval.cpp's EvalContext members keep
both sides, PR 61's first; the records and fork/conformance/README.md's
table are taken from trunk and rewritten by L-F and L. No other conflict.
```

```text
VA-2 S-CT: test CT-1's deferred C++ calls on elements of a pack

CT-1's DeferCppCallOnSymbolicArgs, which the merge brings, defers a C++
call whose argument is symbolic to each specific; a call whose argument is
an element of a pack of different types, a value or a type, now stops at
VA-2's `semantics TODO: C++ or template-dependent action on an element of
a pack of different types` where it is written, because CT-1's deferral
adds its CallAction through AddDependentActionSplice, and so through
AddDependentActionInst, where VA-2's C1 refuses it. The new splits pin
that; they are filled by the next commit. No code changes.

fork/variadics/va2-plan.md D-VA2-14.
```

```text
VA-2 L-F: conformance table and program counts on the merged trunk

fork/conformance/README.md's table is regenerated by `runner.py
--update-readme-table` on the merge commit <M>, and every program header
that names a count is re-derived on it; no program's EXPECT lines change.
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
diagnostic strings in them, not a run, except where M-6 or M-12 to M-16 is
cited (rev 2's measured strings, amended 2026-10-22, review fold: A-m-5);
columns,
SemIR names and diagnostic kinds in brackets are the fill's to decide, and a
fill that contradicts a prediction is a finding for the implementation review,
never a reason to edit a golden (R16(a)). Sources are §A.11's. Directory
prefixes: `check/` is toolchain/check/testdata/variadics/, `lower/` is
toolchain/lower/testdata/variadics/. Since rev 7 the C1 rows are measured: C1
with §2.2's block fills to each of them as rev 7 states them, and rev 7 amends
the four that the fill contradicted (M-21) (amended 2026-10-26, implementation:
stop-and-amend: C1's split and golden sources).

| File (commit) | Split | Predicted key output |
| --- | --- | --- |
| check/hetero_pack.carbon (C1) | `call` | `ForEach`'s `fn_decl` with a `symbolic_binding_pattern T` of type `«%Code.type; %<pack arity>»` (a pack of facets), no second arity binding, and a value pack `x` of pattern type `⟬%T⟭` (printed by stringify as the pack type of `%T`); the body's `pack_expansion_statement` block holds `pack_index` (`[symbolic]`), `pack_element %T, %pack_index`, the facet access and the `Get` call through `%Code.lookup_impl_witness`; in `Call`, `ForEach(a, b, a)` passes a `pack_literal` of three converted to `⟬%A, %B, %A⟭`, and `ForEach()` an empty one; two specifics, `T` = `⟬%A, %B, %A⟭` (a `pack_value [concrete]`) and `⟬⟭` |
| (same) | `type_pack` | `Count(1 as i64, true)` deduces `T` = `⟬%i64, bool⟭` and the arity 2 (the dump's specific of `Count` for `%int_2` and the `pack_value (%i64, bool)`) and `Count()` the empty pack; no diagnostic, `Count` being defined, `{}`, since rev 7: declared only, both calls are upstream's `use of undefined generic function [MissingGenericFunctionDefinition]` (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `forward` | `ForEach(... each y)`: a `pack_expansion_expr` of type `⟬%U⟭`, deducing `T` = `%U` and the arity from `U`'s; no diagnostic, `ForEach` defined since rev 7, as `type_pack`'s `Count` (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `method` | `c.F(a, a)` with the bound `self` first and a 2-element `pack_literal`; `T` = `⟬%A, %A⟭`; no diagnostic, `C.F` defined since rev 7, as `type_pack`'s `Count` (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `qualified_member` | as `call`'s body, with `.(Code.Get)` as the compound member access on the symbolic `each T` |
| (same) | `template_outer` | `F`'s body holds `splice_inst`s for the template-dependent `u.n` and for the `Consume` call that takes it, whose operands (that splice and the run-time result of `each x.V()`, called through `HasV`'s witness for `pack_element %T, %pack_index`) contain no pack index as constants, so no diagnostic; `Call` deduces `T` = `⟬%i64, bool⟭` (M-19, measured on rev 3 and rev 4, `$H/r/gw_rev4/template_outer_ranges.out`; the re-review's tp2 prints 211; amended 2026-10-26, review fold: RR2-m2) |
| (same) | `cpp_template_outer` | `F`'s body holds a `call_action` for `Cpp.Traits(%U)` and a deferred call of `Consume` whose operands are that splice and `One(each x)`, of type `i32`, neither depending on the pack index, so no diagnostic; `Call` deduces `T` = `⟬bool, %i32⟭` (M-18's ctE; amended 2026-10-26, review fold: RR1-B-M5) |
| check/fail_hetero_pack.carbon (C1) | `fail_missing_impl` | `error: cannot convert type `C` into type implementing `Code` [ConversionFailureTypeToFacet]` at `ForEach(a, c)`, with the generic parameter note; nothing else |
| (same) | `fail_missing_member` | `error: member name `Missing` not found in `Code`` at `each x.Missing`, at the definition (no call exists) |
| (same) | `fail_convert_element` | `error: cannot implicitly convert expression of type `each T` to `i64` [ConversionFailure]`, naming `each T` by C1's stringify case (§2.1) |
| (same) | `fail_each_type_not_pack` | `error: `each T` does not name a pack [EachNameNotPack]` (VA-1's diagnostic, unchanged) |
| (same) | `fail_two_explicit_packs` | `error: parameter list can contain at most one pack expansion pattern [MultiplePackExpansionPatterns]` with the `previous pack expansion pattern is here` note: the explicit list is a tuple pattern (:333-334) |
| check/generic_pack.carbon (C1) | `declaration` | VA-1's `fail_todo_generic_pack` source, now without a diagnostic (M-6: "succeeded; if success is expected, remove the `fail_` prefix") |
| (same) | `call` | `F(1 as i64, true, 2 as i32)` deduces `T` = `⟬%i64, bool, %i32⟭`; no diagnostic, `F` defined since rev 7, as `hetero_pack`'s `Count`; the file has no dump range, so its golden holds the sources and no SemIR, and `type_pack` shows the deduction (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| check/fail_todo_va2.carbon (C1) | `fail_todo_two_implicit_packs` | `semantics TODO: `more than one pack expansion pattern in an implicit parameter list`` at the second `...`, and nothing for `U` |
| (same) | `fail_todo_computed_element_type` | `semantics TODO: `pack expansion pattern whose binding type is computed from an each-name`` at `Box(each T)` |
| (same) | `fail_todo_template_each` | `semantics TODO: `each-name binding that is ref, var or template`` |
| (same) | `fail_todo_class_pack`, `fail_todo_interface_pack`, `fail_todo_explicit_generic_pack` | `semantics TODO: `each-name binding of a class, interface or explicit compile-time parameter`` at `each T` of `class Tup(... each T: type) {}`, `interface I(... each T: type) {}` and `fn Count(... generic each T: type) -> i64;`, once each and nothing else (M-19, measured on rev 4; on rev 3 all three check without a diagnostic; amended 2026-10-26, review fold: RR2-M1) |
| (same) | `fail_todo_each_auto` | `semantics TODO: `HandleAutoTypeLiteral`` (upstream's, unchanged) |
| (same) | `fail_todo_two_arities` | `semantics TODO: `more than one pack arity in a generic`` at `each n` of `fn F[... each T: type](... each n: i64);`, §A.11's source, the re-review's v02 (measured on rev 2 and rev 3), the C1 form of reviewer A's r02 shape (M-14's text; amended 2026-10-22, review fold: A-B-1); rev 2's description, `t: T` in place of the tuple, is the re-review's v01, which reports VA-1's `use of a pack's name without `each`` (W-230) first and so pins W-230's TODO, not this one (amended 2026-10-26, review fold: RR1-Nm-1) |
| (same) | `fail_todo_forward_hetero_to_homo` | `semantics TODO: `forwarding a pack of different types to a pack of one type, or the reverse`` at `H(... each x)` (M-16, measured; amended 2026-10-22, review fold: A-M-2) |
| (same) | `fail_todo_expansion_without_each_name` | `semantics TODO: `pack expansion without an each-name in a binding's type`` at `(... i64)` (C1's change; PR 59 and the prototype give VA-1's error there, x03; amended 2026-10-22, review fold: A-m-5 / B-M2) |
| (same) | `fail_todo_overload_hetero_member` | VA-1's `semantics TODO: `variadic member of an overload set``, twice, at the member and at the call (x16, measured; amended 2026-10-22, review fold: A-M-2) |
| (same) | `fail_todo_cpp_template_on_hetero_element` | `semantics TODO: `C++ or template-dependent action on an element of a pack of different types`` at `Cpp.Traits(each T)`, once (M-18's ct6, measured on rev 3; amended 2026-10-26, review fold: RR1-B-M5) |
| (same) | `fail_todo_template_action_on_hetero_element` | `semantics TODO: `C++ or template-dependent action on an element of a pack of different types`` at `u.Get(each x)`, once: upstream's template member call on an element of the pack (M-19's tp1 shape, measured on rev 3 and rev 4; amended 2026-10-26, review fold: RR2-m2) |
| (same) | `fail_todo_cpp_template_on_tuple_of_pack` | `error: unable to monomorphize specific `F(⟬i32, i64, bool⟭)`` at the call in `Call`, naming the specific's pack of types by C1's `PackValue` case, with PR 59's note `semantics TODO: `unsupported type used as template argument`` (ctF0 gives it without packs), once and not repeated per iteration (M-19's ctF, measured on rev 4; on rev 3 `<cannot stringify ...>` and three more copies of the TODO without a location; amended 2026-10-26, review fold: RR2-m1); measured on C1 with §2.2's block, where rev 6's split aborted the gate here (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same, C2) | `fail_todo_initializing_element` | `semantics TODO: `pack expansion of initializing expressions in a tuple literal`` at the `...` of `(... each x.(Core.Copy.Op)())` |
| (same, C2) | `fail_todo_var_pattern` | `semantics TODO: `pack expansion pattern in a pattern other than a parameter list or let`` |
| (same, C2) | `fail_todo_enclosing_arity` | `semantics TODO: `more than one pack arity in a generic`` at `each n` of a function with a pack in a variadic impl (the fixer's f04, measured; amended 2026-10-22, review fold: A-B-1) |
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
| lower/hetero_pack.carbon (C1) | `call` | `ForEach`'s specific for `⟬A, B, A⟭` calls `A`'s `Get`, then `B`'s, then `A`'s, each on a constant GEP of a `{ ptr, ptr, ptr }` pack; the empty specific has no call, and `ForEach()` passes the address of an internal constant `{}` (measured, M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `layout` | `Count(1 as i64, true, 2 as i32)`'s caller passes the address of an internal constant `{ i64, i1, i32 } { i64 1, i1 true, i32 2 }`, with no alloca and no store, the pack value of constants lowered by C1's `EmitAsConstant(PackValue)` as M-6's class lowers pack_expansion's; the specific reads the three elements at constant GEPs (an `i64` load, an `i8` load truncated to `i1`, an `i32` load) and calls `One`'s three specifics (`i64`, `bool`, `i32`) in order (measured, M-21; rev 6 predicted a `{ i64, i1, i32 }` alloca and three stores) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `forward` | `Call` stores `%a` and `%b` into a `{ ptr, ptr }` alloca for `Forward`'s `⟬A, B⟭` specific, which allocas a second `{ ptr, ptr }`, loads each element of `%y` and stores it there, and passes that pack to `ForEach`'s `⟬A, B⟭` specific, VA-1's lowering of a `PackExpansionExpr` argument (lower/handle_pack_expansion.cpp:69-84 at b0822a744); `ForEach` calls `A`'s `Get`, then `B`'s (measured, M-21; rev 6 predicted that `Forward` passes its own pack's address) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `lib`, `use` | `use.carbon` lowers the imported `ForEach`'s `⟬A, B, A⟭` specific (A's `Get`, then B's, then A's) and the imported `Count`'s `⟬i64, bool, i32⟭` specific (`One`'s three specifics in order) from `lib.carbon`'s bodies, as `call` and `layout` do in one file (measured: the split compiled on rev 3 with `--optimize=none`, `$G/r/gw_rev3/lower_use_O0.out`; M-17's i2 and i5 print 16 and 3; amended 2026-10-26, review fold: RR1-NB-1); measured on C1 with §2.2's block, `Count`'s argument the address of an internal constant as in `layout` (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| lower/pack_expansion.carbon (C1, refill) | `sum`, `generic_element`, `class_element`, `arg_order`, `forward_converted_field`, `lib`, `use` | M-6's classes: a `pack_value` of constants becomes a global constant (the `llvm.lifetime.start` declarations and per-call stores of constant packs disappear); every call and every iteration as before |
| check/tuple_segment.carbon (C2) | `param` | `F`'s parameter of type `(⟬%T⟭)`, a `tuple_type` whose one element is a pack type; `F((1 as i64, true))` deduces `T` = `⟬%i64, bool⟭`, and the specific's parameter type is `(%i64, bool)`; no diagnostic, `F` defined, `{}`, since rev 7: declared only, both calls are `use of undefined generic function` (measured on C1 with C2's built half, M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `return` | `MakeTuple`'s `return (... each x)` is a `pack_segment_init` into the return slot whose block holds `pack_index`, two `pack_element`s and the element's `Copy` initialization; `Call` returns the specific's result of type `(%i64, bool)` with no conversion |
| (same) | `let` | `let (... each x: each T) = t;` binds a `pack_expansion_expr` of `pack_element %t, %pack_index`, no copy, no arity binding; the statement expansion calls `Get` |
| (same) | `tuple_value` | `Take((... each x))` passes the pack value as a value of `(⟬%T⟭)`, deducing `U` = `%T`; `Take` defined since rev 7, as `param`'s `F` (M-21; on C1 with C2's built half, before §2.4 item 1, the call is VA-1's `pack expansion in a tuple literal outside a call's argument list`) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| (same) | `elements_around_segment` | `F((1 as i64, 2 as i32, false, true))` deduces `T` = `⟬%i32, bool⟭` (the run between `i64` and the last `bool`), and `F((1 as i64, true))` deduces `T` = `⟬⟭`; no diagnostic, `F` defined since rev 7, as `param`'s (measured on C1 with C2's built half, M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden sources) |
| check/fail_todo_tuple_segment.carbon (C2) | `fail_todo_two_segments` | `semantics TODO: `tuple with more than one pack segment`` |
| (same) | `fail_todo_elements_beside_segment` | `semantics TODO: `tuple pack segment matched with other segments`` at the `return` |
| (same) | `fail_todo_segment_to_elements` | the same TODO at the `let` |
| check/impl.carbon (C2) | `select` | one `impl_decl` whose self type is `(⟬%T⟭)`; `t.(Count.N)()` and `e.(Count.N)()` find it, with `T` = `⟬%i64, bool⟭` and `⟬⟭`; no `ImplUnusedBinding` |
| (same) | `requirement` | `t.(Code.Get)()` on `(i64, (i64, i64))` finds the impl with `T` = `⟬%i64, (%i64, %i64)⟭`, whose second element's `Code` is the same impl with `T` = `⟬%i64, %i64⟭` |
| (same) | `generic_use` | `Use(t)` converts `(i64, bool)` to a facet of `Count` through the variadic impl's witness |
| (same) | `non_tuple_query` | `x.(Count.N)()` on `i64` selects `impl i64 as Count`; the variadic impl's structure `(...?)` does not match `i64`, so it is not a candidate (rev 1: a candidate by the hole that failed to deduce; amended 2026-10-22, review fold: A-M-1 / B-B2); no diagnostic |
| (same) | `symbolic_query` | `t.(Count.N)()` on the symbolic `(⟬%T⟭)` in `H`'s body finds the variadic impl with `T` = `%T` (§0.2 p25) |
| (same) | `self_query` | `self.(Count.N)()` inside the impl's own `Twice` finds the impl being defined, as for any impl; no crash (M-9's first crash was this path) |
| (same) | `lib`, `use` | `use.carbon` imports the variadic impl and selects it for `(i64, bool, i64)`, its self type imported with its pack segment (R-7) |
| (same) | `rank` | a blanket `impl forall [T: type] T as Count`, `impl forall [... each T: type] (... each T) as Count` and `impl forall [T: type, U: type] (T, U) as Count` in one library, no diagnostic; `N` on `i64` finds the blanket impl, on `(i64, bool)` the `(T, U)` impl, on `(i64, bool, i64)` and on `()` the variadic impl (M-15's x05: 1 3 2 2; amended 2026-10-22, review fold: A-M-1 / B-B2) |
| (same) | `rank_reversed` | the same three impls declared in the opposite order, the same selections (x05b) |
| (same) | `rank_elements_after` | `(... each T, bool)` and `(... each T)`: `(i64, bool)` and `(bool,)` find the first, `(bool, i64)` the second (x06: 1 2 1) |
| (same) | `rank_elements_after_reversed` | the same two declared in the opposite order, the same selections (x06b) |
| (same) | `body_expansion` | the `pack_expansion_statement` in `Get`'s body takes its arity from a `specific_constant` of the impl's `<pack arity>` binding with the impl's self specific, `@tuple.type.as.Sum.impl(%arity, %T)` (D-VA2-4; measured, `$G/r/gw_rev3/be.sem`; amended 2026-10-26, review fold: RR1-NB-1) |
| check/fail_impl.carbon (C2) | `fail_missing_element_impl` | `error: cannot access member of interface `Code` in type `(i64, bool)` that does not implement that interface [MissingImplInMemberAccess]` |
| (same) | `fail_not_a_tuple` | the same diagnostic for `Count` in type `i64`: `(...?)` matches only a tuple (amended 2026-10-22, review fold: A-M-1) |
| (same) | `fail_unused_pack` | `error: `impl` with unused generic binding [ImplUnusedBinding]` |
| (same) | `fail_same_type_structure` | `error: found non-final `impl` with the same type structure as another non-final `impl`` at the second of two variadic impls of one structure (x12, measured; amended 2026-10-22, review fold: A-M-1 / B-B2) |
| lower/tuple_segment.carbon (C2) | `make_tuple` | `MakeTuple`'s `⟬i64, bool, i32⟭` specific stores each element into the return slot's field 0, 1 and 2 in order, through each element type's `Copy` (a load and a store, the primitive copy) |
| (same) | `let` | `Sum`'s specific reads `t`'s three fields at constant indices, no alloca for the pack |
| (same) | `impl` | the impl's `Get` lowered for `⟬i64, (i64, i64)⟭` and for `⟬i64, i64⟭`, the first calling the second for its second element |
| (same) | `one_tuple` | `MakeTuple`'s `⟬i64⟭` specific returns the 1-tuple by its value representation, with the single element at index 0 |
| (same) | `self_return` | the variadic impl's `Op` for `⟬i64, i64, i64, i64⟭` takes `ptr sret({ i64, i64, i64, i64 })` and passes that return slot to its call of `Make`'s specific, which returns in place (M-13: reviewer A's r17 shape; amended 2026-10-22, review fold: A-B-2) |
| (same) | `impl_body` | the impl's `Get` for `⟬i64, bool, i64⟭` adds 3, 40 and 3 in order, one constant per iteration (measured, `$G/r/gw_rev3/impl_body_O0.out`; M-17's same3 prints 46; amended 2026-10-26, review fold: RR1-NB-1) |
| (same) | `impl_lib`, `impl_use` | `impl_use.carbon` selects the imported impl for `(i64, bool, i64)` and lowers its `Get` from `impl_lib.carbon`'s body with the same three additions (measured, `$G/r/gw_rev3/impl_use_O0.out`; M-17's i3 prints 46; amended 2026-10-26, review fold: RR1-NB-1) |
| check/expansion_if.carbon (C3) | `if_else` | `pack_expansion_statement` whose body region holds the condition block, both branches and the merge block ending in `pack_expansion_next` |
| (same) | `else_if_return` | the region holds the `return` block, the `else if` blocks and the merge; the function's final `return 0` is outside it |
| (same) | `generic` | `AnyLess`'s body checked once against `T`; `each next.Lt(first)` through `Less`'s witness |
| (same) | `nested` | the inner `if`'s blocks are in the same region |
| lower/expansion_if.carbon (C3) | `first` | `First`'s arity-3 specific has three copies of the condition, branch and merge blocks, each iteration's merge branching to the next iteration's condition, the `return 1` block of each returning; the last merge branches to `return 0` |
| (same) | `min` | `Min`'s arity-2 specific compares and stores twice, in order |
| lower/../tuple/nested_constant.carbon (C0, C0b) | `tuple` | `((1, 2), 3)`'s value is a constant `<{ ptr, i32 }>` (packed: the Carbon layout of `(ptr, i32)` has no tail padding, lower/type.cpp `BuildStructType`) whose first field is the address of the inner tuple's constant `{ i32, i32 }`, and the element read is a load from it (M-12; amended 2026-10-22, review fold: A-B-3; rev 4 wrote `{ ptr, i32 }`, measured by the implementer's C0 fill and again on C0b, M-20) (amended 2026-10-26, implementation: stop-and-amend: nested constant initialization) |
| (same) | `pass` | the same constant passed by its value representation's address (M-20) |
| (same) | `var` | the alloca of `{ { i32, i32 }, i32 }` initialized element by element from that constant: a load of the inner tuple's address and an 8-byte memcpy from it into `v.0`, a load of `6` and a store into `v.1` (C0b, measured, M-20; on C0 alone a 12-byte memcpy of the value representation itself, the stop-and-amend) (amended 2026-10-26, implementation: stop-and-amend: nested constant initialization) |
| (same) | `struct`, `struct_of_tuple` | the struct constants, by the same rule, as packed `<{ ptr, i32 }>` globals (M-20) (amended 2026-10-26, implementation: stop-and-amend: nested constant initialization) |
| (same) | `return` | `Make`'s `return ((4, 5), 6);` initializes its `sret` slot as `var` initializes its alloca (C0b, measured, M-20's v04) (amended 2026-10-26, implementation: stop-and-amend: nested constant initialization) |
| (same) | `one_element` | `var v: ((i32, i32),) = ((1, 2),);` is initialized by an 8-byte memcpy of the inner tuple's constant `{ i32, i32 }` into `v.0`, and no global holds the outer by-copy value (C0b, measured; on C0 alone a CHECK failure in `StoreObject`, M-20's a01) (amended 2026-10-26, implementation: stop-and-amend: nested constant initialization) |
| check/prelude_tuple_impls.carbon (C4) | `copy`, `eq`, `ordered` | on the production prelude, `Dup((1, 2, 3, 4))` deduces `T` = `(i32, i32, i32, i32)` whose `Copy` witness is the variadic impl's with `T` = `⟬i32, i32, i32, i32⟭`; `a == b` and `a < b` on `(i32, i64)` use the `EqWith` and `OrderedWith` impls (amended 2026-10-22, review fold: B-m4) |
| lower/prelude_tuple_impls.carbon (C4) | `copy_op`, `eq` | the 4-tuple's `Op` calls each element's `Copy` in order into the return slot; `==` on `(i32, i64)` compares the first elements and branches on the result before the second |
| check/../interop/cpp/template/fail_todo_cpp_call_on_hetero_element.carbon (S-CT, land time, after M) | `fail_todo_value_arg`, `fail_todo_type_arg`, `fail_todo_facet_type_arg` | the C1 TODO, `C++ or template-dependent action on an element of a pack of different types`, at `Cpp.Add(each x)`, `Cpp.SizeOfFn(each T)` with `each T: type` and the same with `each T: I` (M-18's ct1, ct5 and ct7 on the PR 64 mirror merged with rev 3; before M they are upstream's "call argument of type `each T` is not supported" and "no matching function"; amended 2026-10-26, review fold: RR1-B-M5) |

Totals: 15 new files (10 check, 5 lower: C0's one, C1 to C3's twelve, C4's
two), whose split count rev 3 raises by eight (`cpp_template_outer`,
`fail_todo_cpp_template_on_hetero_element`, the lower `lib` and `use`,
`body_expansion`, `impl_body`, `impl_lib`, `impl_use`; amended 2026-10-26,
review fold: RR1-NB-1 / RR1-B-M5) and rev 4 by six more (`template_outer`,
`fail_todo_class_pack`, `fail_todo_interface_pack`,
`fail_todo_explicit_generic_pack`,
`fail_todo_template_action_on_hetero_element`,
`fail_todo_cpp_template_on_tuple_of_pack`; amended 2026-10-26, review fold:
RR2-M1 / RR2-m1 / RR2-m2) and rev 5 by two more (`nested_constant`'s `return`
and `one_element`) (amended 2026-10-26, implementation: stop-and-amend: nested
constant initialization), and 5 refills; S-CT adds a sixteenth file
at land time; fail_todo_va2 and fail_todo_slice change in C1, C2 and C3; C4
changes M-9's predicted 44 full-prelude goldens, 43 of them only by
renamed SemIR names, a lower bound; no other golden changes (§6.1) (amended
2026-10-22, review fold: A-B-3 / B-m4).

## §5 Conformance delta (from PR 59's 137 PASS / 0 FAIL / 21 SKIP over 158, re-measured as M-5)

| Program | Before | After (stdout, §A) | Commit |
| --- | --- | --- | --- |
| generics/variadics_hetero_digits_diff.carbon (+ .diff.cpp) | absent | PASS, C++ oracle agrees (6, 742074, 3, 422, 0, 0, 40293, 5) | C5 |
| generics/variadics_hetero_forward.carbon | absent | PASS (3, 1, 50, 0, 3, 0) | C5 |
| generics/variadics_hetero_empty.carbon | absent | PASS (0, 7, 3, 12, 33) | C5 |
| generics/variadics_tuple_param.carbon | absent | PASS (112, 4, 71, 0) | C5 |
| generics/variadics_min.carbon | absent | PASS (1, 5, 2, 2, 0, 0) | C5 |
| generics/variadics_strcat.carbon | absent | PASS (4, 3, 41107, 0, 0) | C5 |
| stdlib/tuple_copy_variadic.carbon | absent | PASS (4, 8, 101, 102, 2, 101, 1, 6, 13, 0) | C5 |
| stdlib/tuple_eq_diff.carbon (+ .diff.cpp) | absent | PASS, C++ oracle agrees (1, 0, 1, 1, 0, 0, 1, 11, 12, 0, 11, 12, 1, 11, 12, 13, 1) | C5 |
| stdlib/tuple_ordered_diff.carbon (+ .diff.cpp) | absent | PASS, C++ oracle agrees (1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0) | C5 |
| stdlib/tuple_impl_generic.carbon | absent | PASS (11, 12, 0, 11, 12, 13, 1, 21, 22, 1, 1, 10; amended 2026-10-26, review fold: RR1-Nm-2) | C5 |

Rev 2 renames the three pairs to `*_diff`, adds `variadics_strcat` (W-212's
arbiter), adds the Counted lines to `tuple_eq_diff` and the NaN lines to
`tuple_ordered_diff`, and re-derives `tuple_impl_generic` from the corrected
`Equal` (amended 2026-10-22, review fold: A-m-1 / A-m-2 / B-M1 / B-M3 /
B-m3). `variadics_strcat`, `variadics_hetero_digits_diff`'s Carbon half,
`variadics_hetero_forward` and `variadics_hetero_empty` already run on the
rev 2 prototype with these outputs (`$F/r3/probes_rank.txt`), and the three
oracles, compiled with LLVM 21.1.8's `clang++ -std=c++17 -Wall -Wextra
-Werror -stdlib=libc++` and run, print exactly the lines above
(`$F/r3/out_prog`; M-10 for rev 1's lines). VA-2's own delta: PASS +10,
programs +10, so 147 / 0 / 21 over 168 on this branch. Both bullets are PASS
already ("Generics: Definition-checked variadics" by VA-1's nine programs,
"Stdlib: tuple/array library parts" by stdlib/tuples_arrays_structs.carbon;
`$Q/conf_baseline/scoreboard.json`), so the bullet count stays 49 PASS, 0
FAIL, 7 SKIP of 56. No existing program is predicted to move: none requires
`Core.Copy`, `Core.EqWith` or `Core.OrderedWith` of a tuple (M-3, M-4), and
M-9 runs the whole set against both prototypes with C4's declarations
(137/0/21 each time). The held PRs ahead of VA-2 move the totals before it
lands (each states its own expected count), so commit R quotes §8.4's run on
this branch and commit L quotes §8.8's run on the merge commit, not this table's
arithmetic. `tuple_copy_variadic`'s 101 and 1 for `Dup(one)` rest on R-13's
class at C4 (d01) (amended 2026-10-26, review fold: RR5-M1).

## §6 Churn and collisions

### §6.1 Golden churn

Existing goldens that change, by commit:

-   C1 (F1): VA-1's each_param.carbon, forward.carbon, import.carbon,
    fail_todo_slice.carbon and the lower pack_expansion.carbon, in exactly
    M-6's three classes (measured: the prototype's autoupdate,
    `$Q/proto_golden_churn.diff`, 125 insertions and 145 deletions), plus
    fail_todo_slice's moved split and relabeled TODO; measured again on C1 with
    §2.2's block, rev 4's churn line for line (M-21) (amended 2026-10-26,
    implementation: stop-and-amend: C1's split and golden sources).
-   C2 (F2) and C3 (F3): fail_todo_slice.carbon (two and one relabeled
    splits) and C1's new fail_todo_va2.carbon (two splits each).
-   C0 and C0b (F0): none (§2.7's invariants; M-6's rev 2 line; for C0b
    measured, M-20: before the fill the gate is red on the new golden alone)
    (amended 2026-10-26, implementation: stop-and-amend: nested constant
    initialization).
-   C4 (F4): M-9's 44 full-prelude goldens (43 by renamed SemIR names,
    toolchain/lower/testdata/for/bindings.carbon by its lowered copy of an
    `(i32, i32)`), measured with C4's declarations and proxy bodies on rev 1
    and again on rev 2, a lower bound: the real bodies may rename more names
    in the same files, and a full-prelude golden that changes by more than
    renamed names or the lowered tuple copies is a finding (amended
    2026-10-22, review fold: A-m-4 / B-m4); no golden that
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

§0.6's table is the measurement for the prototype's files at the current heads.
The files C2 to C4 add beyond the prototype (check/handle_tuple_literal.cpp,
handle_let.cpp, control_flow.cpp, control_flow.h, sem_ir/dominance.cpp,
inst_kind.def, inst_namer.cpp, formatter.cpp, core/prelude/copy.carbon,
core/prelude/operators/comparison.carbon; rev 3 also listed pattern_match.cpp,
lower/function_context.* and lower/handle_pack_expansion.cpp, which Appendix
B already changes and C2 and C3 change further, so they are in §0.6's table,
amended 2026-10-26, review fold: RR2-m3) were intersected with every held
head's changes since its merge base with b0822a744 (`git diff --name-only`):
only sem_ir/inst_kind.def (PR 60, PR 61, PR 64) and inst_namer.cpp (PR 60)
are shared, and of the prototype files C3 changes further,
lower/function_context.cpp (PR 61, PR 64). inst_kind.def is
alphabetical and their kinds (`StructuralRequirementType`, `AddrOfAction`,
`IndexAction`, `PointerDereferenceAction`, `TupleIndexAction`) are not adjacent
to `PackExpansionNext` (after :132) or `PackSegmentInit` (after :136);
function_context.cpp merged cleanly with the prototype's hunks (§0.6), and with
C0b's (M-20) (amended 2026-10-26, implementation: stop-and-amend: nested
constant initialization), and C3's
hunk is inside VA-1's `LowerPackExpansionBody`, which no held PR touches. Rev
3's check/action.cpp hunk (`AddDependentActionInst` and
`AddDependentActionSplice`) and its convert.cpp hunk at the `InitializeAction`
site merge cleanly with PR 61 and PR 64, which change other functions of
action.cpp and rewrite the lines around that site (§0.6), and S-CT has no hunk
(amended 2026-10-26, review fold: RR1-B-M5). Merge rules, applied by commit M
and by every mirror (§8.7):

1.  convert.cpp, `ConvertTupleToType` (PR 61, PR 64): keep both changes,
    PR 61's `SpliceInst` redirect first, then VA-2's pack segment, since a
    spliced element is resolved before its type is examined (applied on the
    PR 64 mirror, §0.6).
2.  eval.cpp, `EvalContext`'s members (PR 61, PR 64): keep both members,
    PR 61's `diagnosed_non_constant_ids_` first.
3.  Records (fork/gap-analysis.md, fork/inventory/work-items.json,
    fork/decision-log.md, fork/ORCHESTRATION.md) and
    fork/conformance/README.md's table: regenerated or rewritten from the
    merged tree (`runner.py --update-readme-table`), never merged by hand.
4.  Any other conflict is a stop: the merge is redone on a scratch branch and
    reported, never resolved by taking one side of a toolchain file.

The semantic touch points, which no textual merge shows, each with the mirror
of §8.7 that checks it (rev 1 said "each is covered by a mirror" while §8.7
had none for the prelude PRs or DR-1; amended 2026-10-22, review fold: A-M-2 /
B-M4): SC-1 (PR 60) rewrites requirement checking and impl lookup that the
variadic impls go through (impl_lookup.cpp, `TryGetSpecificWitnessIdForImpl`),
mirror m60; TP-1 (PR 61) and CT-1 (PR 64) defer template-dependent operands in
call.cpp, deduce.cpp and convert.cpp beside VA-2's pack branches (W-224 keeps
packs and templates apart), and CT-1's deferred C++ calls on a pack of
different types reach C1's refusal (D-VA2-14; S-CT tests it), mirrors m61
and m64; ST-1 (PR 55) adds
`Core.String` operations whose `Copy` and comparisons share the prelude's
impl lookups with the tuple impls, mirror m55; OP-1 and OP-2 (PR 56, PR 57)
add `Optional` comparisons that a tuple of `Optional`s uses through the
variadic impls, and `Optional((i32, i32))`'s storage requires `(i32, i32) as
Copy`, which only the variadic impl provides after C4, mirror m57; DR-1a and
DR-1b (PR 63 and its stack) change iterate.carbon, index.carbon, slice.carbon,
buf.carbon and handle_index.cpp, whose impls are tuple impls' neighbors in
every full-prelude lookup, and DR-1b's `IndirectIndexWith` changes call.cpp's
argument grouping beside VA-1's, mirror mdr; and every other PR's prelude and
lookup changes meet the variadic impls together only in the full stack, mirror
mall. OV-1, already on trunk and on this branch, never sees a pack in
`GetExplicitArityRange` (call.cpp:578): VA-1's `variadic member of an overload
set` and `pack expansion argument in a call to an overload set` TODOs precede
it for packs of different types too (x16, x17, W-223), so the call is
unchanged and m60 and mall carry those probes.

### §6.3 The next upstream advance

VA-2 adds no file to the conflicted set the next advance already has beyond
VA-1's (VA-1 M-16: handle_pack_expansion.cpp, node_kind.def, typed_nodes.h and
upstream's pack_expansion.carbon), plus core/prelude/copy.carbon :50-71 if
upstream edits its tuple impls before then (it has not since the cut, M-1),
and the files of §2 that upstream changes for other reasons (eval.cpp,
deduce.cpp, impl_lookup.cpp's neighbors; M-1's table): bf5d2a2ac's `-> auto`
changes check/call.cpp and check/control_flow.cpp and .h, where C3's body
region goes, and 24766e213 and 6c1d2a86e change impl_lookup.cpp beside rev 2's
ranking hunk; each is a textual conflict at the advance, resolved by keeping
both (amended 2026-10-22, review fold: A-m-4 / B-m1). Rev 3 re-measured at
21c825a3f: `git merge-tree --write-tree --name-only` gives 104 conflicted
paths against b0822a744, 413968218 and 80f1ec825 alike, the same set, so rev 3's
hunks add no conflicted path (the re-review's 104 at 57ba07a97, too). Rev 5 at
8779d15e1 (M-20) and rev 6 at 56d9bbc40 measured the same 104 paths, the same
set, for b0822a744, ca939ee19 and 90c34dbaa (`$J/mt_up_8779.txt`,
`$K/mt_up_56d9.txt`) (amended 2026-10-26, review fold: RR5-m3), and rev 7 at
600fd55ba, one commit past 56d9bbc40 that changes toolchain/benchmarking only,
the same 104 paths for the same three (`$M/mt_up_600f.txt`) (amended 2026-10-26,
implementation: stop-and-amend: C1's split and golden sources).
Two upstream commits change how rev 3's mechanisms sit at the advance, and
the advance re-runs M-17's probes for both: e1c8c1f85 makes name lookup pair
every name of an enclosing generic with that generic's self specific, so a
function of a variadic impl names `each T` of the impl through a
`specific_constant` too, as rev 3 already names the arity; and 71af20740
clears `declaring_impl_decls` in `TryEvalBlockForSpecific` while a specific is
resolved, which `TryEvalPackIterationsForSpecific` then does too, since it
evaluates the same blocks once per iteration (amended 2026-10-26, review
fold: RR1-NB-1 / RR1-Nm-3). The rule is VA-1's:
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
    there. Rev 2's prototype leaked one for every specific of an imported
    variadic generic, which only a lower golden with `lib` and `use` splits
    or a program sees (M-17) (amended 2026-10-26, review fold: RR1-NB-1).
-   **R-3. `TupleType` becomes conditional.** Every tuple type now goes
    through `EvalConstantInst(TupleType)`. M-6 measured no golden change and
    no conformance change on the prototype; a regression would show as
    churn outside §6.1 or a changed program, and is then a finding.
-   **R-4. A variadic impl is a candidate for every tuple query** (M-9,
    rewritten by rev 2; amended 2026-10-22, review fold: A-M-1 / B-B2). Rev 1's
    type-structure hole made the variadic impls candidates for every query,
    tuple or not, which the prototype's deduction defect turned into a crash
    (M-9). Rev 2's `(...?)` matches only tuples (`fail_impl`'s
    `fail_not_a_tuple`, `impl`'s `non_tuple_query`), so a non-tuple query
    never deduces against them; every tuple query of `Copy`, `EqWith` or
    `OrderedWith` does, and the cost of that candidate is R-1's. C2 keeps the
    deduction correction (a non-tuple argument fails to deduce, §2.3) for the
    queries that do reach it. Falsified by a crash or a changed impl
    selection in §8.3 or §8.4.
-   **R-5. Unexpected golden churn.** A golden outside §6.1 changes. Detected
    by each fill's diff; listed with its cause in the implementation review
    before it is accepted.
-   **R-6. Impl ranking** (rewritten by rev 2; amended 2026-10-22, review
    fold: A-M-1 / B-B2). Rev 1 said a user impl for one tuple type ranks above
    the hole and that a user `impl forall [T: type] T as Copy` "overlaps every
    impl and is rejected as it is today"; both were wrong (F-6, M-15): the
    hole made the blanket impl and the variadic impl the same structure, an
    error, where PR 59 and the nightly accept a blanket beside a fixed `(T, U)`
    impl. Rev 2 ranks by the design's overlap rule along the query with
    register entry (v)'s reading for a `?` against a segment, and §4's `rank`
    splits pin the blanket, fixed-arity and variadic impls together in both
    declaration orders; MV-9 shows the splits see the reading. Falsified by a
    selection the overlap rule does not predict, or one that changes with
    declaration order.
-   **R-7. An imported variadic generic.** Every program imports the prelude's
    variadic impls from another library, and their functions' bodies are
    statement expansions over the impl's pack. Rev 2 said rev 1's lowering
    failures there were M-13's representation and M-12's constants and that
    M-9's re-measure showed no failure; that was true only of bodies without an
    expansion, which were all M-9's proxies held: an imported generic with a
    pack of different types got no per-iteration values, and an expansion over a
    variadic impl's pack in one of its functions read its arity in the wrong
    generic, in one file too, so every program that copies or compares a tuple
    through Core would have aborted in lowering (M-17, the re-review's NB-1)
    (amended 2026-10-26, review fold: RR1-NB-1). Rev 3 fixes both (D-VA2-2,
    D-VA2-4) and re-measures M-9 with proxy bodies that hold such an expansion
    (M-9's last bullet). C1's lower `hetero_pack` and C2's lower `tuple_segment`
    gain `lib` and `use` splits (an imported variadic function, an imported
    variadic impl whose body expands its pack), C2's `impl` gains
    `body_expansion`, i1, i2, i3, i5, i6, i8, same3, f10 and pl1 are acceptance
    probes of C1 and C2 (hand-off notes; all run on the rev 3 prototype, M-17,
    and M-9's last bullet lowers the proxy prelude's imported impl body), and
    C4's programs all exercise the import; falsified by any failure of those, or
    by a lowering failure of an imported specific that checking alone passes.
-   **R-8. `... if` lowering.** Per-iteration blocks are VA-2's first
    expansion body with control flow; an iteration that branches into a block
    of another iteration, or a block shared between iterations, is either a
    verifier failure (LLVM's, at lowering) or a wrong answer. The lower
    golden `expansion_if` and the programs `variadics_min`, `tuple_eq_diff` and
    `tuple_ordered_diff` (whose answers depend on which element decides) detect
    both; MV-6 (§8.5) proves they do.
-   **R-9. The 1-tuple's value representation.** A tuple of one element may
    be passed by copy where a pack of one is passed by address; D-VA2-9
    loads element 0 in that case, and the lower split `one_tuple` and
    `tuple_copy_variadic`'s `(Loud,)` case detect a mismatch. The `(Loud,)` case
    also initializes a by-copy 1-tuple whose element initializes in place,
    R-13's class, which d01 measures from C4 on (amended 2026-10-26, review
    fold: RR5-M1).
-   **R-10. A prelude defect breaks every program.** C4 changes files every
    program compiles. Mitigated by C4's being the last toolchain-facing
    commit, by M-9's run of the whole conformance set against the prelude's
    declarations, and by §8.4; falsified by any existing program that
    changes status after C4.
-   **R-11. A dependent action inside an expansion over a pack of different
    types** (added by rev 2; amended 2026-10-22, review fold: B-M5; rewritten by
    rev 3 (amended 2026-10-26, review fold: RR1-B-M5)). A dependent action is
    performed once per specific, so one whose operand depends on the pack index
    called nothing or aborted; rev 2's S-CT hunk caught only a C++ function call
    whose argument's type was an each-name, and missed type arguments (ct5, ct7)
    and C++ class templates (ct6), which abort on VA-2 alone (ct6, ctD; M-18).
    C1 refuses every dependent action whose operand or operand type contains the
    pack index, at `AddDependentActionInst`, which every action passes through
    (check/inst.cpp:46-50); ct6 and ctD on this branch, and ct1, ct2, ct4 to ct8
    and ctD on the PR 64 mirror, report the TODO, and ctE, ctC, ctB, ct3 and ctA
    run (M-18); upstream's template actions on an element (tp1, tp3, tp4, tp5)
    report it on this branch too, and tp2, whose operands do not depend on the
    pack index, runs (M-19; amended 2026-10-26, review fold: RR2-m2). Falsified
    by a dependent action of any kind (a C++ call, a C++ class or function
    template, an upstream or TP-1 template action) whose operand depends on the
    pack index and that reaches a specific without the TODO, or by an action
    whose operands do not depend on it being refused.
-   **R-12. The ranking's reading** (added by rev 2; amended 2026-10-22,
    review fold: A-M-1 / B-B2). The overlap rule does not name segments
    (register entry (v)); if upstream gives pack segments a type-structure
    rule, impls that tie or rank otherwise under it change selection.
    Detected at the weekly upstream check by W-338; falsified by upstream's
    text or toolchain ranking `(T, U)` and `(... each T)` otherwise.
-   **R-13. A constant's value representation is not its object representation**
    (added by rev 5) (amended 2026-10-26, implementation: stop-and-amend: nested
    constant initialization). For a tuple or struct whose elements' value
    representations are not their objects, C0 lowers a constant to its value
    representation and C0b copies it into storage element by element; another
    lowering path that takes a constant's lowered value as an object, or a held
    PR or upstream advance that adds one, would read the value representation as
    one. Detected by `nested_constant`'s `var`, `return` and `one_element`
    splits, M-20's probes (which every later stage re-runs after its build,
    hand-off notes) and the programs; falsified by a run-time difference between
    a constant and the same value computed at run time, or by a CHECK failure in
    `StoreObject` or `CopyObject` for such a type. A one-element aggregate whose
    element initializes in place is upstream's defect, unchanged by C0 and C0b
    and filed by no one, whether it is copied into storage (a03), returned (a19,
    a20) or returned by copy from a `Copy.Op` (d01 to d03): VA-2's ids are all
    taken and the next free ones are not VA-2's to mint, so the stage that
    writes D's PR text names it for the next allocation. Rev 5 put the class
    outside the slice with the break condition "a form or program of this slice
    that reaches either", and that condition is met (amended 2026-10-26, review
    fold: RR5-M1): §A.6's `Dup(one)` reaches the class today, through PR 59's
    hand-written `(T,)` impl (core/prelude/copy.carbon:55-59), and from C4 on it
    reaches the variadic impl's `PackSegmentInit` for `Self` = `(Loud,)` (§2.4
    items 5 and 7), which nothing has built or measured. C4's stage decides: d01
    to d03 are re-run after every build and must print 101 1, 1 2 and 1 2 from
    C4 on; if C4's impl still reaches the class, C4 stops and amends, with a fix
    or with a plan revision that makes the form OUT with the precise TODO R17
    requires, and does not wait for §A.6 to fail at C5. Falsified for the class
    by d01, d02 or d03 failing at C4 or after, or by §A.6's `Dup(one)` printing
    anything but 101 and 1.
-   **R-14. A split commit accepts a form whose other half is a later commit's**
    (added by rev 7) (amended 2026-10-26, implementation: stop-and-amend: C1's
    split and golden sources). C1 forms `(... each T)` as a type and accepts a
    pack in an impl's implicit list, but the type structure's run entry, the
    ranking, the tuple deduction and the tuple values are C2's, so on C1 alone a
    variadic impl's structure is a 1-tuple's: a query of another arity finds no
    candidate or, beside a blanket impl, the blanket one (M-21's x05, r01 and
    v06). No golden of C1 declares a variadic impl, C1 lands only with C2, in
    one PR (D-VA2-18), and C1 with C2's built half selects as rev 4 measured
    (M-21). Detected by each split commit's gate (§8.3: no crash) and the probe
    sets every stage re-runs after its build; falsified by a crash in a split
    commit's gate or by a C2 probe that prints other than rev 4's on C2's
    install. If a review requires each commit to give the slice's result for
    every form it accepts, C1 takes C2's type-structure, ranking and
    tuple-deduction hunks too, by D-VA2-19's break condition.

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
    with no program output changing, which `tuple_copy_variadic` checks. On
    the rev 2 prototype `return self;` reaches the placeholder `semantics
    TODO: initializing a tuple with a pack segment` (r19), where C2's
    `PackSegmentInit` goes (amended 2026-10-22, review fold: A-B-2).
-   **A-8. `...and` for the equality impl** (rejected for this slice). `return
    ...and (each a == each b);` is the design's spelling (:307-312), but
    `...and` is VA-1's TODO (W-216, with `...or`), whose short-circuit is
    control flow inside an expression body (W-219); the `... if` statement
    form needs only D-VA2-11 and has the same semantics. When W-216 lands,
    the impl may be respelled; the programs pin the semantics either way.
-   **A-9. The rev 1 type-structure hole** (rejected by rev 2, R32(d);
    amended 2026-10-22, review fold: A-M-1 / B-B2). Treating `(... each T)` and
    every tuple containing a segment as one `?` deletes the tuple constructor
    that the design's rule keeps ("replacing type parameters by a `?`"), a
    second spelling of upstream's rule that rejected valid programs (M-15).
    Its falsifier was r01, a blanket impl beside a variadic one, which the
    hole rejected and the design's rule accepts.
-   **A-10. A pack index per arity binding** (rejected for this slice;
    amended 2026-10-22, review fold: A-B-1). Keying `PackIndex` and the
    per-iteration blocks by the expansion's arity binding would let each
    expansion of a generic iterate over its own arity (review A's first
    option), but it is W-222's mechanism (independent arities and the
    same-arity rule across packs), which the slice's arbiters do not need;
    the TODO of D-VA2-4 keeps the one-arity invariant honest instead.
    Falsified if an arbiter of §1.8 needs two arities in one generic.
-   **A-11. One memcpy of a constant's object representation for C0b**
    (rejected; added by rev 6, amended 2026-10-26, review fold: RR5-m2).
    `CopyValue` could copy a constant of a `ValueAggregate` type into storage
    with one memcpy from a global that holds its object representation, which
    `FileContext`'s `constants_` already holds as the lowered constant
    (file_context.h:301 at 8779d15e1), as upstream copies a constant whose value
    representation is its object's address, by `CopyObject`'s memcpy from that
    global, under `InitializeStorage`'s "TODO: If the type is small, emit a
    store rather than a memcpy." (function_context.cpp:299 at 8779d15e1).
    Rejected for two reasons. It needs a second global per such constant, beside
    the one its value uses need: `global_variables_` (file_context.h:304 at
    8779d15e1) maps a constant to the one global of its value representation,
    the `<{ ptr, i32 }>` of `((4, 5), 6)` (M-20), so the object's global needs a
    second map and a second name and holds once more the data the elements'
    globals hold (the `{ i32, i32 }` of `@tuple.8a1.loc4_3` again inside a `{ {
    i32, i32 }, i32 }`), in every module that copies one, where C0b adds no
    global (the fill's `var`, `return` and `one_element` splits). And
    `CopyValue` would reach past its source, which upstream's contract makes a
    value representation (function_context.h:318-320 at 8779d15e1) and
    `InitializeStorage`'s comment the constant's value ("Copy the constant value
    instead.", function_context.cpp:298 at 8779d15e1), into `FileContext`'s
    private constant table; C0b copies from that value alone, the value every
    other use of the constant reads, so a copy and a use cannot disagree.
    Falsified as a rejection if upstream fixes `GetConstant` or `CopyValue`
    itself, and §2.7 then takes upstream's fix, or if a review finds a copy that
    the element-by-element copy gets wrong and the memcpy gets right.
-   **A-12. C2 takes the pack collapse instead** (rejected; added by rev 7)
    (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden
    sources). M-21's crash could also go by moving to C2 the hunk of
    handle_pack_expansion.cpp that makes `... each T` the pack, beside the two
    hunks that consume it; `(... each T)` on C1 would then be VA-1's `pack
    expansion in a tuple literal outside a call's argument list`, as on PR 59.
    Rejected: C1's stringify case for `(... each T)` (§2.1), the split
    `fail_todo_cpp_template_on_tuple_of_pack` that rev 4 gave C1 for RR2-m1,
    C1's probes f03, r02, r02b and ctF (hand-off note 2) and C1's message would
    all change or move to C2, where §2.2's block is 15 lines of Appendix B that
    change no golden of C1 but that split, which they make fill as §4 says.
    Falsified as a rejection if a review finds a C1 golden that the two hunks
    change otherwise, or rejects R-14's partial variadic impls on C1.

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

### §8.0 The planner's and the fixer's measurements (done)

M-5 (the baseline), M-6 (the prototype's gate, churn and conformance), M-8
(build times) and M-9 (the prototype with C4's declarations) are the planner's,
on the planner's build of b0822a744 plus `$Q/va2_prototype.patch`; M-10 (the C++
oracles) and M-11 (the programs and golden sources parsed and checked on PR 59's
install) need no build of this branch. The probes and their outputs are
`$Q/probes` and `$Q/logs`, M-9's are `$Q/m9`, the programs, oracles and golden
sources as written are `$Q/programs`, `$Q/oracles` and `$Q/goldens`. Rev 2's are
the fixer's (amended 2026-10-22, review fold: every finding of both reviews):
the rev 1 prototype rebuilt (68e629c97, reviewer A's reproduction), the rev 2
prototype built twice (the fixes of `$F/r3/rev2_fixes.patch`, then the ranking
of `$F/r3/rank_fix.patch`), its gate, conformance and probes
(`$F/r3/gate_rank.log`, `conf_rank.log`, `probes_rank.txt`), M-9's re-measure (`$F/r3/m9r.sh`
and its logs), §0.6's collisions at the current heads
(`$F/r3/collisions_rev2.txt`), the PR 64 mirror with S-CT
(`$F/r3/build_m64.log`, `gate_m64.log`, `out_ct_sct`), reviewer A's probes
(`$S/reviewA/rp`, rerun on both prototypes and PR 59), the fixer's (`$F/probes`,
`$F/r3/probes`, `$F/r3/ct`), the rev 2 programs and oracles (`$F/r3/programs`,
`$F/r3/out_prog`), with `$S` the scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va2`.
Every build ran with no other workstream's ninja running, or with two jobs while
one was (incremental rebuilds only), and was deleted when the fold was
committed. Rev 3's are the fixer's of the re-review, with `$G` the scratch
directory `$S/fixer1` and every rev 3 number in `$G/r` (the files directly under
`$G` are an interrupted earlier attempt's at this fold, kept but superseded; its
edits were re-measured, not copied): the rev 2 prototype rebuilt from 413968218
(`$G/r/build_rev2.log`) and the re-review's cases on it (`$G/r/set_rev2.txt`,
made by `$G/r/run_set.sh` with `$G/r/run_imp.sh` over `$G/imp`, and
`$G/r/probesall_rev2.txt`, made by `$G/r/probes_all.sh`), the rev 3 prototype
built incrementally from it (`$G/r/build_rev3.log`) with the same runs
(`set_rev3.txt`, `probesall_rev3.txt`), the new golden splits of §A.11 compiled
as the file_test compiles them (`$G/r/run_goldens.sh`, `goldens_rev3.txt`), its
gate and conformance (`gate_rev3.log`, `conf_rev3.log`), M-9's re-measure with
expansion-holding proxies (`$G/r/m9.sh` with `$G/r/m9_prelude_v7.py`:
`gate_v7.log`, `churn_v7_stat.txt`, `conf_v7.log`, `probes_v7.txt`), the PR 64
mirror built twice under /dev/shm/va2-fixer1/m64, as 0084da002 (4a3220c11 merged
with 413968218 by §6.2's rules 1 and 2, plus `$F/r3/s_ct.patch`) and as
4234cdb6f (4a3220c11 merged with 80f1ec825 the same way, no land-time code),
with `set_m64r2.txt`, `set_m64r3.txt`, `goldens_m64r3.txt` and `gate_m64r3.log`,
§0.6's collisions (`collisions_rev3.txt`), M-1's commit lists (`m1_all.txt`,
`m1_rest.txt`), and the prototype itself (`va2_prototype_rev3.patch`,
`rev3_fixes.patch`) (amended 2026-10-26, review fold: RR1-NB-1 / RR1-B-M5 /
RR1-Nm-3). Rev 4's are the fixer's of the second re-review, with `$H` the
scratch directory `$S/fixer2` and every rev 4 number in `$H/r`: the rev 3
prototype rebuilt from 80f1ec825 in a scratch worktree
(/dev/shm/va2-fixer2/proto; `$H/r/build_rev3.log`) and the re-review's cases on
it (`rr2set_rev3.txt`, made by `$H/r/run_rr2.sh`; `set_rev3.txt` and
`probesall_rev3.txt`, made by `$H/r/run_set.sh` and `$H/r/probes_all.sh`, rev
3's scripts with their outputs moved to `$H/r`), PR 59's outcomes
(`rr2set_va.txt`, `goldens_va.txt`), the rev 4 prototype built incrementally
from it (`build_rev4.log`, ca939ee19 by `$H/r/rev4_edit.py`) with the same runs
(`rr2set_rev4.txt`, `set_rev4.txt`, `probesall_rev4.txt`), the six new golden
splits compiled as the file_test compiles them (`$H/r/run_goldens.sh`,
`goldens_rev3.txt`, `goldens_rev4.txt`), its gate, VA-1 churn and conformance
(`gate_rev4_raw.log`, `va1_churn_rev4.diff`, `conf_rev4.log`), the PR 64 mirror
5499d8dd9 built under /dev/shm/va2-fixer2/m64 (`build_m64r4.log`,
`set_m64r4.txt`, `rr2set_m64r4.txt`, `goldens_m64r4.txt`, `gate_m64r4_raw.log`,
`conf_m64r4.log`), §0.6's collisions (`collisions_rev4.txt`), `git merge-tree`
against upstream's 21c825a3f (`mt_up.txt`: 104 conflicted paths for b0822a744,
80f1ec825 and ca939ee19 alike, so §6.3's claim holds for rev 4), and the
prototype itself (`va2_prototype_rev4.patch`, `rev4_fixes.patch`) (amended
2026-10-26, review fold: RR2-M1 / RR2-m1 / RR2-m2 / RR2-m3).

Rev 5's are the plan amender's (amended 2026-10-26, implementation:
stop-and-amend: nested constant initialization), with `$J` and `$L` the
directories the header names and every rev 5 number in `$J` (M-20): the
implementer's C0 install (/home/user/carbon-build/carbon-va2, built from
d92a9c709) and logs (`$L`); the 36 probes (`$J/probes`, `$J/probes_impl`) on C0,
PR 59, trunk and the nightly; C0b in the scratch worktree /dev/shm/va2-amend/wt
at d92a9c709, relinked over the C0 build's objects into /dev/shm/va2-amend/c0b
(`$J/bin/relink.sh`, `relink_c0b_v2.log`), with its gate run by `$J/bin/ft.sh`
over the carbon-va2 runfiles, its fill, conformance, probes and clang-tidy
(`$J/bin/tidy_norec.sh`, `tidy_repo.sh`); the rev 4 prototype with C0b in the
scratch worktree /dev/shm/va2-amend/wt5, built in full with
`CB_BUILD_ROOT=/dev/shm/va2-amend/builds` (`$J/build_wt5_v2.log`), its gate,
VA-1's churn, conformance and the rev 4 probe sets, rerun from copies of
`$H/r`'s scripts that write to `$J/sets`; §0.6's collisions and upstream's `git
merge-tree` for the scratch commit 90c34dbaa; and C0b's block
(`$J/c0b_block.patch`). A first draft of C0b, recursive, was measured the same
way and replaced (`$J/set_c0b.txt`, the dangling 3b800ae9d); only the block of
§2.7 is of rev 5. The worktrees, the relinked binaries and the build were
removed when rev 5 was committed.

Rev 6's are the plan amender's of the re-review (amended 2026-10-26, review
fold: RR5-M1 / RR5-m3), with `$K` the directory the header names and every rev 6
number in `$K`: the re-review's d01 to d04 (`$K/probes_d`) on PR 59, trunk, the
nightly and C0's install; C0b's block extracted from §2.7 (`$K/c0b_block.patch`,
byte-identical to `$J/c0b_block_final.patch`), applied in the scratch worktree
/dev/shm/va2-impl/wt-c0b at d92a9c709 with §2.7's numstat and relinked over the
C0 build's objects into /dev/shm/va2-impl/c0b (`$K/bin/relink.sh`,
`relink_c0b.log`), with d01 to d04 and M-20's 36 probes on it (`set_c0b_d.txt`,
`set_c0b_probes.txt`, `set_c0b_impl.txt`); the rev 4 prototype with C0b,
90c34dbaa in the scratch worktree /dev/shm/va2-impl/wt6, built in full with
`CB_BUILD_ROOT=/dev/shm/va2-impl/builds` (`build_wt6.log`, `install_wt6.log`, 0
warnings), with the same probes (`set_wt6_d.txt`, `set_wt6_probes.txt`,
`set_wt6_impl.txt`); and upstream's tip, 56d9bbc40 (`git fetch upstream trunk`
and `git ls-remote upstream refs/heads/trunk`, 2026-10-26), with `git
merge-tree` against it (`mt_up_56d9.txt`). The worktrees, the relinked binaries
and the build were removed when rev 6 was committed.

Rev 7's are the plan amender's of stage 2's stop-and-amend (amended 2026-10-26,
implementation: stop-and-amend: C1's split and golden sources), with `$M` and
`$N` the directories the header names and every rev 7 number in `$M` (M-21): the
implementer's stage 2 logs, split and saved state (`$N`); the implementer's C1
install, on the saved state in the scratch worktree /dev/shm/va2-amend/wt
(`$M/logs/d1_c1_gate.log`); §2.2's block applied there and relinked over that
install's objects into /dev/shm/va2-amend/v1b (`$M/bin/relink.sh`,
`relink_v1b.log`), with its gates, both fills (`$M/fill_asis_p1`,
`$M/fill_rev7_p1`, `$M/fill_rev7_p2`), conformance (`$M/conf_v1b`), clang-format
and clang-tidy (`$M/tidy`), M-20's probes with d01 to d04 (`$M/probes_v1b.txt`)
and the earlier sets, run by copies of the implementer's scripts that write to
`$M/sets` (`$M/bin`); the controls of upstream's rule on PR 59, trunk and C1
(`$M/probes/ctl`); the scan of §A.11 and Appendix A (`$M/bin/scan_decl.py`,
`$M/bin/a11.py`); C1 with C2's built half in /dev/shm/va2-amend/wt2, built in
full with `CB_BUILD_ROOT=/dev/shm/va2-amend/builds` (`build_wt2.log`,
`install_wt2.log`), with C2's three splits (`$M/src/ts_c2`) and the same sets
(`*_wt2.txt`); `$M/c1_rev7.patch` applied in /dev/shm/va2-amend/wt3 at
8a7395cf1, with prek (`prek_c1_1.log`) and the `toolchain` trees of C1 and its
fill; the block checked in /dev/shm/va2-amend/wt4; and upstream's tip,
600fd55ba, with `git merge-tree` against it (`mt_up_600f.txt`). The worktrees,
the relinked binaries and the build were removed when rev 7 was committed.

### §8.1 Build (implementer)

After C0, C1, C2 and C3: `$CB/build.sh /home/user/carbon-va2` then
`$CB/install.sh /home/user/carbon-va2`, with `CB_BUILD_ROOT` as above. C0
changes one lower file and builds incrementally; each of C1 to C3 edits
sem_ir/typed_insts.h or inst_kind.def, which most objects include, so each is
a full build (M-8: about 6 minutes on 4 cores when the
machine is otherwise idle); C4 and C5 change no C++ and need only
`install.sh`, which copies core/ into the install (install.py :100-110).
Before C2 is written, C1's tree alone is built (§3's split check); 0 warnings
with the build's `-Werror` set. Rev 6's split passed that check and failed its
gate, so since rev 7 the split check is the build and the gate, both before C1
is committed (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's
split and golden sources). C0b changes lower/file_context.cpp,
function_context.cpp and the two headers they are declared in, so its
incremental build recompiles the 13 lower objects that include those headers and
relinks (amended 2026-10-26, implementation: stop-and-amend: nested constant
initialization).

### §8.2 Autoupdate to its fixpoint (implementer)

After each build with new or changed goldens: `$CB/autoupdate.sh
/home/user/carbon-va2 <the commit's goldens>`, then the same command again,
which must change nothing but `.loc` numbers (R26; a second run that changes
more is a stop, diagnosed before a third). Each fill's diff is reviewed
against §4 before the fill commit; a contradiction is a finding, never an
edit.

### §8.3 Gate (implementer)

`$CB/gate.sh /home/user/carbon-va2`. Expected, all passing: 1960 (M-5) before
C0; 1961 after F0 (one new file); 1966 after F1 (five more); 1971 after F2
(five more); 1973 after F3 (two more); 1975 after C4 and F4 (two more and the
predicted 44 refills) and after C5 (amended 2026-10-22, review fold: A-B-3 /
B-m4). Each implementation commit alone is red on exactly §3's listed files
and nothing else, with no crash. The gate's wall time is compared with M-5's
25 seconds (R-1). A shrink's expected counts are §3's. C0 alone and C0b alone
are each red on exactly that new file, with no crash (M-20) (amended 2026-10-26,
implementation: stop-and-amend: nested constant initialization).
C1 alone, with §2.2's block, is 1956 passed and 10 failed, the ten files of §3
item 3, with no crash, and 1966 passed after F1, both measured; rev 6's split
aborted it (M-21) (amended 2026-10-26, implementation: stop-and-amend: C1's
split and golden sources).

### §8.4 Conformance (implementer)

`XDG_CACHE_HOME=<a private directory> $CB/conformance.sh
/home/user/carbon-va2 <a private output directory>` after C5: expected PASS
147, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0,
DIFF-MISMATCH 0, SKIP 21 (of 168), bullets 49 PASS, 0 FAIL, 7 SKIP of 56, the
ten programs of §5 PASS with §A's outputs, and the three `.diff.cpp` oracles
compile with the toolchain's own clang++ and agree (amended 2026-10-22, review
fold: B-M3). Also after C0 alone and after C4 alone (before C5): 137 / 0 / 21
over 158, unchanged (R-10). Commit R quotes the C5 run, EXPECTED, not of
record. After C0b, before F0, too: 137 / 0 / 21 over 158 and bullets 49 / 0 / 7
of 56, measured on the relinked C0b and on the rev 4 prototype with C0b (M-20)
(amended 2026-10-26, implementation: stop-and-amend: nested constant
initialization). §A.6's 101 and 1 for `Dup(one)`, and with them the 147 after
C5, rest on R-13's class at C4: d01 printing 101 1 on C4's install is their
precondition, and a d01 that does not is a stop at C4, not a failure at C5
(amended 2026-10-26, review fold: RR5-M1). C1 with §2.2's block, too: 137 / 0 /
21 over 158 and bullets 49 / 0 / 7 of 56, measured (M-21), and the stage 2
re-run repeats it (amended 2026-10-26, implementation: stop-and-amend: C1's
split and golden sources).

### §8.5 Mutants that prove the programs are not vacuous (implementer)

One mutant per decision that a program can see, each applied to the C5 tree
in the worktree, rebuilt incrementally in the same build directory (never a
copied one), run against the ten programs and VA-1's nine, then reverted and
rebuilt; MV-7, MV-8, MV-10 and MV-11 change only the prelude and need only
`install.sh`.
Each must turn at least the listed programs red, and the result is recorded
per program.

| Mutant | Decision | Change | Predicted to fail |
| --- | --- | --- | --- |
| MV-1 | D-VA2-7 | lower/function_context.cpp: `GetValue` looks up constants without the pack index (`std::nullopt` for `current_pack_index()`) | variadics_hetero_digits_diff, variadics_hetero_forward, tuple_impl_generic (a lowering CHECK or a wrong callee) |
| MV-2 | D-VA2-2 | check/eval.cpp: `TryEvalPackIterationsForSpecific` evaluates every iteration with pack index 0 | variadics_hetero_digits_diff (first line 8, not 6), variadics_hetero_forward |
| MV-3 | D-VA2-5 | check/deduce.cpp: the deduced `PackValue` of argument types built from `llvm::reverse(element_ids)` | variadics_hetero_digits_diff and variadics_hetero_forward (COMPILE-FAIL: an argument converted to another's type) |
| MV-4 | D-VA2-8 | check/deduce.cpp, the `TupleType` case: the run drops its last element | variadics_tuple_param, tuple_copy_variadic, tuple_eq_diff (COMPILE-FAIL) |
| MV-5 | D-VA2-9 | lower/handle_pack_expansion.cpp: `PackSegmentInit` lowers its body for iteration 0 only | tuple_copy_variadic (101 without 102), variadics_tuple_param (71) |
| MV-6 | D-VA2-11 | lower: `PackExpansionNext` of every iteration branches past the last iteration | variadics_min (`Min(4, 9, 2, 2, 7)` prints 4), tuple_eq_diff (`a == c` prints 1), tuple_ordered_diff |
| MV-7 | D-VA2-12 | comparison.carbon: `Less`'s final `return false;` becomes `return true;` | tuple_ordered_diff (`a < c` prints 1), tuple_impl_generic is unaffected |
| MV-8 | A-2 | copy.carbon: the variadic impl replaced by hand-written impls for arities 0 to 12 | tuple_copy_variadic (COMPILE-FAIL at the 13-tuple) |
| MV-9 | D-VA2-8 | check/type_structure.cpp: a `?`'s ranking key `4p + 2` becomes `4p` (below a segment's) | the `impl` golden's `rank` splits (`(i64, bool)` finds the variadic impl), and no program: the prelude has no fixed-arity tuple impl beside the variadic ones (amended 2026-10-22, review fold: A-M-1 / B-B2) |
| MV-10 | D-VA2-12 | comparison.carbon: `Equal`'s `not (each a == each b)` becomes `each a != each b` (rev 1's body) | tuple_impl_generic (21 and 22 where 11 and 12), tuple_eq_diff (the Counted lines, DIFF-MISMATCH) (amended 2026-10-22, review fold: A-m-1 / B-M1) |
| MV-11 | D-VA2-12 | comparison.carbon: `NotEqual` removed, so `!=` is `EqWith`'s default `not Equal` (rev 2's reading) | tuple_impl_generic (`Differ(a, b)` prints 11 and 12 where 21 and 22); tuple_eq_diff is unaffected, its elements' `!=` being `not ==` (amended 2026-10-26, review fold: RR1-Nm-2) |

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
--self-test`, expected "168 programs parsed, 56 bullets in table, OK" (158 on
this branch before C5; 168 since rev 2 added `variadics_strcat`, amended
2026-10-22, review fold: B-M3). C0b is a code commit too: both passes run on its
file_context.cpp and function_context.cpp, and the second's line filter, the
lines changed since b0822a744, takes in C0's lines, which no pass had covered
and which fail `misc-no-recursion` on C0 alone; on C0b both passes are clean
(M-20) (amended 2026-10-26, implementation: stop-and-amend: nested constant
initialization).

### §8.7 Composition mirrors (implementer, before the implementation reviews)

Each mirror is a scratch worktree under `/dev/shm/va2-<role>/mirror-<name>`
(`git worktree add --detach` of the held head, then `git merge --no-ff` of
VA-2's head, conflicts resolved by §6.2's rules, the records taken from the
held head), built, gated and run through conformance with a private cache,
then removed with `git worktree remove` and its build deleted. Heads as of
§0.6, re-read when the mirrors are built; each mirror's expected red set
(before its own fill) is VA-2's own new and refilled goldens, which it then
fills, plus the set named below, and its programs are both sides' (amended
2026-10-22, review fold: A-M-2 / B-M4 / B-M5 / B-m2):

-   m61, PR 59 plus PR 61 (tp, 5661a35c8): templates with packs. Expected:
    every golden of both passes after the mirror's own fill; p16, p17 and p18
    of §0.2 as on PR 59 (p18 the template each-name TODO, now relabeled);
    TP-1's and VA-2's programs all PASS.
-   m60, PR 60 (sc, 40a76ab81): requirement checking and impl lookup beside
    the variadic impls and their ranking. Expected: both sets of goldens and
    programs pass, and §4's `rank` splits and x16, x17 give their §4 and M-16
    outputs.
-   m62, PR 62 (sv, 0ef8a0334): convert.cpp beside VA-2's. Expected as above.
-   m64, PR 64 (ct, 4a3220c11, stacked on PR 61): convert.cpp and eval.cpp
    beside VA-2's, and CT-1's deferred C++ calls on pack elements. Measured by
    the fixer of the re-review for the rev 3 prototype, with no land-time code
    (M-18): the merge's two conflicts resolve by rules 1 and 2; the gate is 1972
    passed and 5 failed (VA-1's five goldens, M-6); conformance PASS 156, 0
    failures, SKIP 19 of 175; ct1, ct2, ct4 to ct8 and ctD report C1's TODO, ct3
    prints 7, ctA to ctC and ctE run, and M-17's probes print their rev 3
    outputs. Measured again for the rev 4 prototype by the fixer of the second
    re-review (5499d8dd9, M-19): the same gate, conformance and outcomes, and
    the second re-review's probes as on rev 4 but ctH and ctJ, CT-1's (amended
    2026-10-26, review fold: RR2-M1 / RR2-m1). The implementer re-runs it with
    VA-2's head, expecting the same plus S-CT's split, filled (amended
    2026-10-26, review fold: RR1-B-M5).
-   m55, PR 55 (st, 21307851a): `Core.String`'s operations and impls beside
    the variadic tuple impls in the production prelude. Expected: ST-1's
    goldens and programs and VA-2's pass after the fill; the full-prelude
    refills are M-9's set and ST-1's, nothing else.
-   m57, PR 56 merged into PR 57 (op2, a080c7886, which holds PR 56's head
    894139b34): `Optional`'s comparisons and storage beside the tuple impls.
    Expected: OP-1's and OP-2's programs and VA-2's pass; a probe of
    `Optional((i32, i32))` built, compared with `==` and copied runs.
-   mdr, PR 63 and PR 65, DR-1b (dr-idx, fee0ef31c, stacked on PR 63's
    89aabd125; rev 3 named the heads 7a442f632 and 2abee5635, from which they
    moved by fork/ records and one DR-1b golden, amended 2026-10-26, review
    fold: RR2-m3): the `ref` cursor, `IndirectIndexWith` and the prelude files
    they change. Expected: DR-1's programs and VA-2's pass; a `for` loop over a
    slice of tuples whose elements are compared with `==` runs.
-   mall, the land simulation (D-VA2-18): trunk 563135b40 with every held PR
    merged in fork/ORCHESTRATION.md's order (each PR's head as its scratch
    merge, each conflict resolved by that PR's own land rules, the way CT-1's §8
    item 9 and DR-1's §3 compose theirs), then VA-2's head as commit M would
    merge it, then S-CT's split, built, gated, filled (as F-M), run through
    conformance and re-tabled (as L-F). Expected: the gate red only on the
    goldens the merged PRs' land-time fills and F-M name; conformance the trunk
    floor plus every PR's delta plus §5's ten; x16, x17, ct1 to ct8 and ctA to
    ctE as above (amended 2026-10-26, review fold: RR1-B-M5); i1, i2, i3, i5,
    i6, i8, same3, f10 and pl1 as M-17 (amended 2026-10-26, review fold:
    RR1-NB-1); OV-1's overload goldens unchanged.

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
    prelude's real bodies, the new goldens of C2 to C4 (rev 7 filled C1's five,
    its refills and its relabeled TODO texts on C1, M-21) (amended 2026-10-26,
    implementation: stop-and-amend: C1's split and golden sources), and the
    programs of Appendix A other than §A.1 to §A.3 and §A.10.
    §0.2's proto column, M-9 and M-12 to M-16 measure what the prototype does;
    every other output in this plan is a prediction (§4) or a hand derivation
    (§A).
-   The real prelude's full-prelude churn: M-9's 44 refills were measured with
    proxy bodies, so they are a lower bound (amended 2026-10-22, review fold:
    A-m-4 / B-m4).
-   The run of a variadic impl's `Copy` function: M-9's re-measure compiles
    and links every program that reaches one (no crash, no verifier failure,
    rev 2), but the proxy body calls itself, so their runtime outputs (§A.6,
    §A.9 and p20) are derivations until C2 to C4 exist (amended 2026-10-22,
    review fold: A-B-2 / B-M6). Among them is §A.6's `Dup(one)`, R-13's class,
    which the hand-written impl aborts on today (d01) (amended 2026-10-26,
    review fold: RR5-M1).
-   The mirrors m55, m57, m60, m61, m62, mdr and mall of §8.7, and m64 with
    VA-2's head: they need C5's tree; m64 was measured with the rev 2
    prototype (amended 2026-10-22, review fold: A-M-2 / B-M4) and the rev 3
    prototype (amended 2026-10-26, review fold: RR1-B-M5).
-   The mutants of §8.5: they need C5's tree.
-   clang-tidy: the prototypes were built with `-Werror` (0 warnings, M-8 and
    rev 2's builds) but not run through clang-tidy, except, since rev 5,
    `misc-no-recursion` over the rev 4 prototype's 24 .cpp files with C0b and
    both passes over C0b's two, all clean but C0's file_context.cpp alone
    (M-20); the second pass over C1's and C2's files is the implementer's
    (amended 2026-10-26, implementation: stop-and-amend: nested constant
    initialization).
-   Bazel-only tests (gtest unit tests, the diagnostics coverage test, lit
    tests, fuzzers): not part of the container gate; they run only on hosted
    CI, which is disabled on the fork.
-   Hosted CI and an optimized build: the container builds the fastbuild-like
    configuration only.
-   p25 and p26 on PR 59, trunk and the nightly: they need packs of
    different types, which only the prototypes check.
-   The builds (`/dev/shm/va2-planner`, `/dev/shm/va2-fixer`,
    `/dev/shm/va2-fixer1`, `/dev/shm/va2-fixer2`) were deleted when rev 1, rev
    2, rev 3 and rev 4 were written, and so were rev 3's and rev 4's PR 64
    mirrors (/dev/shm/va2-fixer1/m64, /dev/shm/va2-fixer2/m64) and rev 4's
    scratch worktrees; the rev 4 prototype is reproducible from Appendix B (or
    `$H/r/va2_prototype_rev4.patch`) on b0822a744, and the mirrors from the
    scratch commits 0084da002, 4234cdb6f and 5499d8dd9 (amended 2026-10-26,
    review fold: RR1-NB-1 / RR1-B-M5; amended 2026-10-26, review fold: RR2-M1
    / RR2-m1). Rev 5's relinked binaries, scratch worktrees and composition
    build were removed when rev 5 was committed; C0b is reproducible from §2.7's
    block on d92a9c709, and the composition from the scratch commit 90c34dbaa
    (amended 2026-10-26, implementation: stop-and-amend: nested constant
    initialization). Rev 6's (/dev/shm/va2-impl/c0b, wt-c0b, wt6 and builds)
    were removed when rev 6 was committed (amended 2026-10-26, review fold:
    RR5-M1). Rev 7's (/dev/shm/va2-amend/v1b, wt, wt2, wt3, wt4 and builds) were
    removed when rev 7 was committed; C1 is reproducible from `$M/c1_rev7.patch`
    on 8a7395cf1 and C1 with C2's built half from it and
    `$M/c2_rest_after_v1b.patch` (amended 2026-10-26, implementation:
    stop-and-amend: C1's split and golden sources).
-   The real prelude bodies' lowering through an import: M-9's last bullet
    lowers proxy bodies that hold an expansion over the impl's pack, and
    M-17 lowers imported variadic impls whose bodies do, but C4's own bodies
    (`let`, `PackSegmentInit`, `... if`) exist only with C2 to C4, so the
    lower `tuple_segment` `impl_lib` and `impl_use` splits and C4's programs
    are their first measurement (amended 2026-10-26, review fold: RR1-NB-1).

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
re-allocates from the maximum plus one, skipping reserved blocks, and §A.12's
ids are renumbered in D's commit, never in source.

## Hand-off notes for the implementer

1.  **Start from the prototype.** `git apply` of Appendix B (or of
    `$H/r/va2_prototype_rev4.patch`) on b0822a744 reproduces §0.5's rev 4
    tree (f023437c2, the scratch commit ca939ee19; measured by
    `$H/r/check_appb.sh`; rev 3's was 91dd88f60, 80f1ec825) (amended
    2026-10-26, review fold: RR1-NB-1; amended 2026-10-26, review fold:
    RR2-M1 / RR2-m1); split
    it into C0, C1 and C2's built half by §2.1 to §2.3 and §2.7,
    then add C1's own changes (F-3's TODO, F-7's TODO, the relabels) before
    C1's fill, and keep in C2 M-9's deduction correction (§2.3), the
    dependent representation and the ranking with the `fail_impl` and `impl`
    splits that exercise them (amended 2026-10-22, review fold: A-B-1 /
    A-B-2 / A-B-3 / A-M-1 / B-m5). C0 is followed by C0b, §2.7's block, before
    F0; Appendix B's file_context.cpp hunk is C0's and is not applied again, and
    its other hunks apply on C0 plus C0b (M-20) (amended 2026-10-26,
    implementation: stop-and-amend: nested constant initialization).
    Since rev 7 C1 also takes two hunks rev 4 gave C2, §2.2's block, and the
    stopped run's C1 with that block and §A.11's four amended splits is
    `$M/c1_rev7.patch`, C2's built half `$M/c2_rest_after_v1b.patch` (M-21)
    (amended 2026-10-26, implementation: stop-and-amend: C1's split and golden
    sources).
2.  **What to run first after each build:** C0: reviewer A's r16, r16g, r16h and
    x07; C0b, and after every later build, M-20's 36 probes, each with
    `$H/r/run_probe.sh <carbon> <probe> <outdir>`, expecting M-20's last column,
    but for a03's indeterminate value and the convert.cpp line of a19's and
    a20's CHECK failure (amended 2026-10-26, implementation: stop-and-amend:
    nested constant initialization); C1: §0.2's p02, p12, p14, p15, reviewer A's
    r02 and the fixer's f01, f03, f06, the import probes i2, i5, i6 and i8 (16,
    3, 8 2 and 116 0) and ct6, ctD, ctB, ctC and ctE (the TODO twice, then 8 1,
    19 and 19) (M-17, M-18), and the second re-review's v3, v6 and vB (the TODO
    `each-name binding of a class, interface or explicit compile-time
    parameter`), ctF (`F(⟬i32, i64, bool⟭)`, once), tp1 (the action TODO) and
    tp2 (211), all run by `$H/r/run_rr2.sh <tag> <install>` (M-19; amended
    2026-10-26, review fold: RR2-M1 / RR2-m1 / RR2-m2); C2: i1 (16 9), i3 and
    same3 (46 each), f10 (3 0) and pl1 (1, with `$G/imp/pl1_proxy.txt` appended
    to the install's comparison.carbon), then p19, p24, p24b, p25, p26, r01,
    r01b, r14, r17, x05, x05b, x06, x06b, x12 and the `tuple_segment` golden;
    `$G/r/run_set.sh <tag> <install>` runs the import, C++ and proxy probes in
    one go, and `$G/r/probes_all.sh` the rest (amended 2026-10-26, review fold:
    RR1-NB-1 / RR1-B-M5); C3: the design's Min (§A.5); C4: p20, p20c, p09, p10
    (now compiling and running), p23 (still an error, W-334) and d01 to d03 (101
    1, 1 2 and 1 2; R-13); then every program of Appendix A. Since rev 6, after
    C0b's build and after every later one, M-20's 36 probes are joined by d01 to
    d04 (`$K/probes_d`), expecting through C3 d01's, d02's and d03's `CHECK
    failure` at toolchain/lower/lower.cpp:48 (the verifier) and d04's 1 2 3, and
    from C4 on 101 1, 1 2, 1 2 and 1 2 3, a d01, d02 or d03 that fails at C4
    being R-13's stop (amended 2026-10-26, review fold: RR5-M1). Since rev 7
    C1's f03 prints `cannot implicitly convert expression of type `(... each T)`
    to `i32``, r02 and r02b `more than one pack arity in a generic`, and on C1
    every earlier set prints `$M/sets/*_v1b.txt` and M-20's with d01 to d04
    `$M/probes_v1b.txt` (M-21), the variadic-impl probes there being C2's forms
    (R-14) (amended 2026-10-26, implementation: stop-and-amend: C1's split and
    golden sources).
3.  **Fills are separate commits**, to their fixpoint, reviewed against §4.
4.  **Watch-outs.** A variadic impl is a candidate for every tuple query
    (R-4), so a non-tuple argument must fail deduction, never walk a tuple's
    operands; a symbolic `PackIndex` must never reach lowering without an
    iteration (R-2); a tuple type with a segment has the specific's
    representation, never one computed from the pack element (M-13); a
    ranking must never depend on declaration order (M-15); `PackSegmentInit`
    and `PackExpansionNext` sit in VA-1's alphabetical block of
    inst_kind.def; a lookup of a generic's bindings goes through each
    binding's constant value, since an imported generic's are import
    references, and an operand that names a binding of an enclosing generic
    is wrapped for that generic's self specific (M-17) (amended 2026-10-26,
    review fold: RR1-NB-1); a dependent action whose operand depends on the
    pack index never reaches an eval block (M-18) (amended 2026-10-26, review
    fold: RR1-B-M5); the prelude's tuple impls ask only for their elements'
    impls, never for `Self`'s (A-7); min_prelude's copy.carbon is not
    touched.
5.  **Records only in R and D.** No W-id appears in source, goldens or
    program headers; fork comments name decisions (`D-VA2-n`).
6.  **R31.** Code in this plan and in any record text sits between
    `<!-- google-doc-style-ignore -->` and `<!-- google-doc-style-resume -->`
    lines.

## Review fold record (rev 2, 2026-10-22)

Reviews A and B of rev 1 (51c6cfb10), both REJECT, folded by the fixer on
2026-10-22 against upstream's 57ba07a97 (rev 1's ebc155734 plus one
benchmarking commit). Every finding was reproduced in the fixer's scratch
where it is a measurement (§8.0), and each amended sentence above carries
"(amended 2026-10-22, review fold: <finding>)", with review A's findings
written `A-<id>` and review B's `B-<id>`. Twenty-five findings, all folded,
two of them in part with evidence; none rejected outright:

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| A-B-1 two pack arities crash | BLOCKER | folded: reproduced on rev 1 (r02, r02b abort "Pack index 2 out of range"; f04 compiles silently); a second arity in a generic or an enclosing one is the `semantics TODO: more than one pack arity in a generic` (W-222), built and measured; "by construction" corrected; per-arity pack indexes rejected as A-10 | header, M-14, D-VA2-1, D-VA2-2, D-VA2-4, DR-16, D-VA2-13, §2.2, §4, A-10 |
| A-B-2 segment tuple's 1-tuple representation | BLOCKER | folded: reproduced (r17 aborts in `HandleInst(Call)`); the dependent representation specified, built and measured (r17 links; M-9's re-measure lowers every variadic impl function); M-9's attribution to `PackSegmentInit` corrected; lower split `self_return` | M-9, M-13, D-VA2-8, D-VA2-9, §2.3, §4, §8.9 |
| A-B-3 nested tuple constants | BLOCKER | folded: reproduced on PR 59 and rev 1, root-caused in lower/file_context.cpp `GetConstant` (upstream's defect at 57ba07a97 too), fixed by the prerequisite commit C0 with a lower golden, W-335; M-9's verifier failures re-attributed; M-11's check-only limit stated | header, M-9, M-11, M-12, §2.7, §3 C0, §4, §1.11 |
| A-M-1 type-structure hole | MAJOR | folded: reproduced (r01, r01b, r14, x05, x06 rejected on rev 1); the tuple is kept, `(...?)`, and impls rank by the overlap rule along the query, built and measured in both declaration orders; the run-versus-`?` reading registered (W-338); R-6 rewritten | V-3 check, §0.4, M-15, D-VA2-8, §2.1, §2.3, §4, R-4, R-6, R-12, A-9, MV-9 |
| A-M-2 mirrors and stale heads | MAJOR | folded: §0.6 re-measured with the rev 2 prototype at the current heads; mirrors m55, m57, mdr and mall added; OV-1 audited (x16, x17: W-223's TODOs precede `GetExplicitArityRange`) | §0.6, §6.2, §8.7, M-16 |
| A-m-1 Equal by `!=` | MINOR | folded: `Equal` by `==`, `!=` by `EqWith`'s default | D-VA2-12, §2.6, §A.9, MV-10 |
| A-m-2 partial orders | MINOR | folded: decided as `std::tuple`'s rule, registered (W-339), pinned by `tuple_ordered_diff`'s NaN lines | D-VA2-12, §1.12 (vi), §2.6, §A.8 |
| A-m-3 fixed-arity `let` reading | MINOR | folded: both passages quoted, register entry (iv) on W-214 | DR-10, §1.12 (iv) |
| A-m-4 churn lower bound, upstream audit | MINOR | folded: churn labeled a lower bound and re-measured on rev 2; bf5d2a2ac and 24766e213 listed | M-1, M-9, §6.1, §6.3 |
| A-m-5 pack stringification, DR-17 | MINOR | folded: C1 prints `each T`, `⟬each T⟭`, `(... each T)` (built, measured); DR-17 relabeled | §2.1, DR-17, F-7 |
| B-B1 W-213 discharged without its arbiters | BLOCKER | folded: W-213 narrowed, not discharged; Apply's `Call(... each T)` is VA-1's existing W-226, so no new id (F-8); `-> auto` arrives with the advance; §A.4's claim corrected | header, D-VA2-1, D-VA2-17, §A.4, §A.12 |
| B-B2 hole is a second spelling | BLOCKER | folded with A-M-1; the V-3 check now states the rev 1 drift and its realignment | V-3 check, as A-M-1 |
| B-M1 tuple `==` calls `!=`; §A.9 pinned it | MAJOR | folded: `Equal` by `==`; §A.9 re-derived (11, 12, 0, ...); `tuple_eq_diff` gains a printing element whose oracle agrees | §2.6, §5, §A.7, §A.9 |
| B-M2 DR table errors | MAJOR | folded: DR-17 stays OUT with W-337 and a split; `each x: auto` labeled W-333; DR-43 to DR-46 folded into DR-41, DR-40 and DR-36 | §1.2, §1.11 |
| B-M3 W-212 without its break condition | MAJOR | folded: `variadics_strcat`, StrCat's text with Core's missing names declared locally, runs on rev 2; the substitution and its reasons (p01, and x01's W-220) recorded; multi-segment checking placed in W-215 and W-222 | D-VA2-1, D-VA2-16, D-VA2-17, §A.10, §A.12 |
| B-M4 mirrors incomplete; §6.2 against §8.7 | MAJOR | folded with A-M-2 | §0.6, §6.2, §8.7 |
| B-M5 CT-1 with packs of different types | MAJOR | folded: probed on the PR 64 mirror (ct1 calls nothing, ct4 aborts); decided as a TODO, land-time code commit S-CT specified and measured | D-VA2-14, D-VA2-18, §3, R-11, §8.7 |
| B-M6 lowering crash without a spec; shrink line | MAJOR | folded: the crash's root cause and fix (A-B-2); a third shrink; shrinks as revert commits with expected counts; W-213's fate under shrink 2 | §3, M-9 |
| B-M7 row text hides open limits | MAJOR | folded: the "Not yet" lists name each form with its id | §A.12 |
| B-M8 register incomplete and unowned | MAJOR | folded: entries with work item, owner and next action; W-230's entry added; rev 1's (iii) and (iv) moved out as not open questions | §1.12, §1.11, D-VA2-10 |
| B-m1 R32(c) commit list, p002274 path | MINOR | folded: five commits added; the path corrected and the check re-run | M-1, design authority |
| B-m2 land-time messages, land simulation | MINOR | folded: M, S-CT, F-M, L-F and L verbatim; mall simulates the land | §3, D-VA2-18, §8.7 |
| B-m3 conventions | MINOR | folded: `*_diff` names, R27 diffs for Min and StrCat, V-3b, the log entry placed after VA-1's, R30's miscite removed | §0.2, D-VA2-16, §A.5, §A.10, §A.12 |
| B-m4 C4's golden, proxy count | MINOR | folded: C4's two goldens; the count labeled predicted | D-VA2-12, D-VA2-15, §3, §4 |
| B-m5 internal contradictions | MINOR | folded in part: W-222's list, §0.4's cite and §A.6's evidence (x15, a `let`) corrected; the claim that Appendix B cannot be applied is refuted by measurement (F-9), and §2.0 gives the command | D-VA2-17, §0.4, §A.6, §2.0, F-9 |

The rev 2 prototype is the rev 1 patch plus M-9's correction, the fixes of
B-1, B-2, B-3, M-1 and m-5, and the forwarding TODO the fixer's own probes
found (f06, f07), measured with gate 1955 of 1960 (VA-1's five), conformance
137/0/21 of 158, M-9's re-measure with the proxy prelude, and the PR 64
mirror. Not signed off: the re-review decides.

## Review fold record (rev 3, 2026-10-26)

The focused re-review of rev 2 (78524522b), REJECT, folded by the fixer of
the re-review on 2026-10-26 against upstream's 21c825a3f (the re-review's
57ba07a97 plus 13 commits that change no design page, no prelude file and no
file of this plan, M-1). A first attempt at this fold was interrupted by a
container restart before it committed; its uncommitted edits were reused only
where their claims re-measured, and every rev 3 number comes from this fold's
own builds and runs (`$G/r`, §8.0). Every finding that is a measurement was
reproduced on the rev 2 prototype rebuilt from 413968218 or on the PR 64
mirror with rev 2's S-CT hunk, and each amended sentence above carries
"(amended 2026-10-26, review fold: RR1-<finding>)".

The re-review, as received (verdict REJECT; its own setup and logs are
`$S/rr1`): it applied Appendix B with `git apply` to b0822a744 (tree
5b9a5c2ec, the tree of the scratch commit 413968218), built it under
/dev/shm/va2-rr1, built a PR 64 mirror (4a3220c11 merged with 413968218,
convert.cpp and eval.cpp kept both, plus `$F/r3/s_ct.patch`), and deleted
both builds. It found rev 2's BLOCKERs and MAJORs resolved but one: A-B-1
(r02, r02b, f04, v02 and v13 give `more than one pack arity in a generic`,
with no crash), A-B-2 (r17 links; v12, `Self` returned at arities 0, 1, 2 and
nested, runs), A-B-3 (r16, r16g, r16h, x07 and its c01 to c08 run; c03 still
aborts on PR 59), A-M-1 and B-B2 (r01 and r01b print 2 1, r14 1 2, x05 and
x05b 1 3 2 2, x06 and x06b 1 2 1, v04 and v04b 2 1, v06 4 5, v08 2 2 1; the
reading is W-338), A-M-2 and B-M4 (the merge conflicts reproduce; the DR heads
moved by fork/ records only), and B-B1, B-M1, B-M2, B-M3, B-M6, B-M7 and B-M8
(`variadics_strcat` prints 4 3 41107 0 0; §A.9 re-derived by hand; the
shrink counts consistent; every register entry has a work item, an owner and
a next action); B-M5 was not resolved, and every MINOR was folded. Its
findings:

-   NB-1 (BLOCKER): a generic with a pack of different types, defined in
    another library, crashes when lowered, and C4's prelude impls have that
    shape. i3 (an imported `impl forall [... each T: HasN] (... each T) as K`
    whose `Get` runs `... s += (each T).N;`) aborts at
    lower/handle_pack_expansion.cpp:96 ("Pack arity ... is not an integer"),
    and so does pl1 (that shape appended to the install's comparison.carbon);
    i2 and i5 (imported `Sum[... each T: HasV]` and `Count[... each T:
    type]`) abort at lower/file_context.h:185 (`type_id.has_value()`) in
    `HandleInst(PackElement)`. Checking alone passes, so §4's check goldens
    cannot see it, and M-9 saw no crash only because its proxy bodies hold no
    expansion; the homogeneous control i6 prints 8 2. Fix: root-cause the
    per-iteration values of a specific of an imported generic, specify the
    fix in C1 and C2, add lower goldens with `lib` and `use` splits, make i2,
    i3, i5 and pl1 acceptance probes, re-measure M-9 with proxy bodies that
    hold an expansion, and correct R-7 and M-9.
-   B-M5 (MAJOR, not resolved): S-CT misses deferred C++ calls whose symbolic
    argument is a type `each T`, and C++ class templates. On the PR 64 mirror
    with S-CT, ct1, ct2 and ct4 give S-CT's TODO and ct3 prints 7, but ct5
    (`Cpp.SizeOfFn(each T)`), ct7 (the same with `each T: I`) and ct6
    (`Cpp.Traits(each T).size`) pass check and abort in lowering at
    sem_ir/inst.h:249 ("Casting inst {kind: CallAction...} to wrong kind
    InstValue"); the control ctA prints 8 8 1 1. R-11 is falsified. Fix:
    refuse any deferred action whose operands depend on a symbolic
    `PackIndex` inside an expansion over a pack of different types, and add
    ct5, ct6 and ct7 to S-CT's split and to the m64 and mall expectations.
-   Nm-1 (MINOR): §4's `fail_todo_two_arities` description, with `t: T`, is
    v01, which reports only `use of a pack's name without each`; v02 reports
    `more than one pack arity in a generic`. Fix: use v02's source.
-   Nm-2 (MINOR): the tuple `!=` reading is framed as design silence, but
    tuples.md :112-114 lists inequality as field-wise, and `EqWith`'s default
    `not Equal` differs from a field-wise `!=` for elements whose `Equal` and
    `NotEqual` are both false. Fix: quote tuples.md and justify the default,
    or spell `!=` field-wise.
-   Nm-3 (MINOR): §2.2 still says "the largest" `<pack arity>` and the code
    takes the maximum; M-1 omits the upstream commits that touch
    file_context.cpp or type_completion.cpp (9fd28f730, 2e2125585, 9799a2326,
    2c9739799, eb66bebc3, 51e2c76a8, f0bae9637, 62f1cc6a3); `git merge-tree`
    of 57ba07a97 gives 104 conflicted paths against both b0822a744 and
    413968218, so §6.3's claim holds. Fix: reword §2.2 and list the commits
    or narrow M-1.

Five findings, all folded, none rejected:

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| NB-1 imported generics with packs of different types crash in lowering | BLOCKER | folded: reproduced on rev 2 (i1, i2, i5, i8 abort at file_context.h:185 in `HandleInst(PackElement)`; i3 and pl1 at handle_pack_expansion.cpp:96; same3 and f10, in one file, at generic.cpp:84); two root causes, separated by the eval.cpp-only build 48edb5127: an imported generic's bindings are import references, so C1's `TryEvalPackIterationsForSpecific` reads each through its constant value, and an expansion over an enclosing generic's pack named that generic's arity binding, so C2 names it by a `specific_constant` of the enclosing generic's self specific, upstream's mechanism of e1c8c1f85; on rev 3 every case runs (i1 16 9, i2 16, i3 46, i5 3, i8 116 0, same3 46, f10 3 0, pl1 1), the 131 earlier probes keep their rev 2 outcomes but f10, the gate is 1955 of 1960 (VA-1's five, the same churn) and conformance 137/0/21; lower `hetero_pack` `lib` and `use`, lower `tuple_segment` `impl_body`, `impl_lib` and `impl_use`, and check `impl` `body_expansion` added and compiled; the cases made acceptance probes; M-9 re-measured with expansion-holding proxies (1911 of 1960, the same 44 refills, 137/0/21); R-7 and M-9 corrected | header, V-3 check, M-9, M-17, §0.5, D-VA2-2, D-VA2-4, D-VA2-7, §2.2, §3 C1 and C2, §4, §A.11, R-2, R-7, §6.3, §8.0, §8.7, §8.9, hand-off notes, Appendix B |
| B-M5 S-CT misses type arguments and C++ class templates | MAJOR | folded: reproduced on the PR 64 mirror with S-CT's hunk (ct5, ct6, ct7 and ctD abort at inst.h:249; ct1, ct2, ct4, ct8 give S-CT's TODO; ct3 7; ctA 8 8 1 1) and found to be VA-2's own (ct6 and ctD abort on rev 2 alone, through upstream's `PerformCallToNonFunction`); the refusal moved into C1 at upstream's `AddDependentActionInst`, which every dependent action passes through (inst.cpp:46-50), testing the operands and their types for the pack index; on rev 3 ct6 and ctD give the TODO and ctB, ctC, ctE run; on PR 64 merged with rev 3 and no land-time code ct1, ct2, ct4 to ct8 and ctD give it, ct3 prints 7, ctA to ctC and ctE run, gate 1972 of 1977 (VA-1's five), conformance 156/0/19 of 175; S-CT becomes a land-time test commit whose split holds ct1's, ct5's and ct7's shapes; C1 gains `fail_todo_cpp_template_on_hetero_element` and `cpp_template_outer`; R-11 rewritten; m64 and mall name ct1 to ct9 and ctA to ctE | V-3 check, M-18, §0.5, §0.6, D-VA2-13, D-VA2-14, D-VA2-18, §1.10, §2.2, §3, §4, §A.11, §6.2, R-11, §8.7, §8.9 |
| Nm-1 `fail_todo_two_arities` pins W-230's TODO | MINOR | folded: §4's row names §A.11's source, which already is v02's declaration form; v01 (W-230's TODO), v02 and §A.11's split (the two-arity TODO, once) re-measured on rev 2, rev 3 and the mirror | §4 |
| Nm-2 tuple `!=` framed as design silence | MINOR | folded by the second remedy: tuples.md :108-114 lists "equality and inequality comparison" among the field-wise operations, so the tuple's `NotEqual` calls the elements' `!=` and is true at the first that is; register entry (vi) loses `!=`; §A.9's EXPECT re-derived (21, 22 where 11, 12); §A.7's lines unchanged, its elements' `!=` being `not ==`; MV-11 added | V-3 check, D-VA2-12, §1.12 (vi), §2.6, §5, §8.5, §A.7, §A.9, §A.12 |
| Nm-3 stale "largest"; M-1's commit list | MINOR | folded: §2.2 and the code take the one arity; M-1 lists the 29 further commits that touch this plan's files by sha, subject and file, with the five that bear on rev 3's mechanisms; upstream re-read at 21c825a3f; `git merge-tree` re-measured (104 conflicted paths with and without VA-2) | M-1, design authority, §2.2, §6.3, Appendix B |

Rev 3 is NOT signed off: NB-1 was a BLOCKER, and its fold changes the
prototype's code in C1 and C2, as B-M5's moves a refusal into upstream's
`AddDependentActionInst`; the next focused re-review decides, and should
re-run `$G/r/run_set.sh` on the rev 3 prototype and on a PR 64 mirror and
re-read e1c8c1f85 against D-VA2-4.

## Review fold record (rev 4, 2026-10-26)

The second focused re-review, of rev 3 (8d377a06d), APPROVE-WITH-AMENDMENTS,
folded by the fixer of the second re-review on 2026-10-26 against upstream's
21c825a3f, which `git fetch upstream trunk` and `git ls-remote upstream
refs/heads/trunk` gave again that day, with no commit past rev 3's read. An
earlier attempt at this fold was interrupted by a container restart; its saved
patch (`$S/fixer-r2-partial.patch`) does not exist, so nothing of it was
reused, and the worktree was at rev 3 when this fold began. Every finding
that is a measurement was reproduced on the rev 3 prototype rebuilt from
80f1ec825 (M-19), every rev 4 number comes from this fold's own builds and
runs (`$H/r`, §8.0), and each amended sentence above carries "(amended
2026-10-26, review fold: RR2-<finding>)".

The re-review, as received (verdict APPROVE-WITH-AMENDMENTS; its own setup and
logs are `$S/rr2`): it fetched upstream (21c825a3f, no new commits), found the
design pages, the prelude and handle_pack_expansion.cpp unchanged against
b0822a744 and 57ba07a97, and only 2ec4bab59, a045da8e6, 947c1eb52, df3cf9294
and 6d80ceb58 touching variadics, tuples or the prelude since the cut, all in
M-1; it applied Appendix B to b0822a744 (tree 91dd88f60, 80f1ec825's), built
it under /dev/shm/va2-rr2, built the PR 64 mirror 4234cdb6f after checking it
is a plain keep-both merge of 4a3220c11 and 80f1ec825, and deleted both
builds. On rev 3 the gate was 1955 passed and 5 failed (VA-1's five),
conformance 137/0/21 and the 131 earlier probes the fixer's line for line; on
the mirror the gate was 1972 passed and 5 failed. It found rev 3's findings
resolved: NB-1 (i1 16 9, i2 16, i3 46, i5 3, i6 8 2, i8 116 0, same3 46, f10
3 0 and pl1 1 on rev 3 and on the mirror; its adversarial a1 46 0, a2 46, b1
4046, b2 4046 10346 10300, c1 1014 1010, c2 1014 and d1 1046 1080; every
§A.11 rev 3 split checking and lowering), B-M5 (on the mirror ct1, ct2, ct4 to
ct8 and ctD the TODO, ct3 7, ctA 8 8 1 1, ctB 8 1, ctC and ctE 19, S-CT's
three splits the TODO once each, ctG and tp1, tp3, tp4 and tp5 the TODO, ctJ
333, tp2 211 and tp6 5), Nm-1, Nm-2 (§A.9 re-derived, 21 and 22, MV-11
consistent) and Nm-3 (`git merge-tree` 104 = 104 at 21c825a3f). Its findings:

-   RR2-M1 (MAJOR): compile-time each-name bindings outside an implicit list
    are accepted, so variadic classes, interfaces and explicit `generic` packs
    regress from VA-1's TODO to wrong diagnostics. The binding handler accepts
    any `CompileTimeBindingPattern` each-name, and `PackExpansionStart` lets
    `...` into every explicit list, class and interface lists included: v3
    (`class Tup(... each T: type) {}`) compiles; v7, vE, v6, vA, vF and vC give
    arity errors, v8 cannot deduce `<pack arity>`, and vB, vD and vH cannot
    deduce `T`; each gave PR 59's TODO. Fix: accept a compile-time each-name
    only when its expansion starts an implicit parameter list, keep a relabeled
    TODO (W-222 for classes and interfaces, W-221 for `generic`), keep
    `generic` in W-221's text, add `fail_todo_va2` splits for v3, v6 and vB,
    and correct §0.3 item 2 and D-VA2-13's table.
-   RR2-m1 (MINOR): a concrete `PackValue` in a specific's name is not
    stringified: ctF (`return Cpp.Traits((... each T)).size;`) reports
    `unable to monomorphize specific F(<cannot stringify ...PackValue...>)` on
    rev 3 and the mirror; the underlying error is PR 59's (ctF0). Fix:
    `StringifyInst(PackValue)` printing `⟬i32, i64, bool⟭`, and a split that
    names such a specific.
-   RR2-m2 (MINOR): Carbon template actions in expansions over a pack of
    different types are unpinned, and D-VA2-14's "no install composes
    templates with packs" is stale: rev 3 alone composes upstream's
    `[template U: type, ... each T: ...]` (tp1, tp3, tp4, tp5 the TODO; tp2
    211). Fix: a `fail_todo_va2` split with tp1's shape, a passing
    `hetero_pack` split with tp2's, and D-VA2-14 reworded.
-   RR2-m3 (MINOR): stale counts, heads and wording: §3 item 0's "rev 2 (this
    commit)", §0.6's "the prototype's 30" (31), §6.2's list of files beyond
    the prototype that Appendix B already changes, §8.7's mdr heads (live:
    89aabd125 and fee0ef31c, moved by fork/ records only), and S-CT's "The new
    split" for a file of three splits. Fix: update each.

Four findings, all folded, none rejected:

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR2-M1 compile-time each-names outside an implicit list accepted | MAJOR | folded: reproduced on rev 3 (v3 compiles; v6, v7, vA, vC, vE and vF arity errors; v8 `<pack arity>` and vB, vD, vH `T` not deduced; the fixer's k1, k2 and k6, a pack in a class's or an interface's implicit list, compile); C1 accepts a compile-time each-name only in a function's or an impl's implicit list (full pattern `ImplicitParamList`, introducer `fn` or `impl`) and otherwise reports `each-name binding of a class, interface or explicit compile-time parameter` before any arity is added (W-222 for classes and interfaces, W-221, whose text keeps `generic`, for an explicit `generic`), built and measured on rev 4 and the mirror: every v and k probe but v4 and k3 (unchanged) reports it with PR 59's count of diagnostics, and the gate, VA-1's churn, conformance and the 131 earlier probes are rev 3's; `fail_todo_va2` gains `fail_todo_class_pack`, `fail_todo_interface_pack` and `fail_todo_explicit_generic_pack`; W-221 is noted by D | header, M-19, §0.3, §0.5, D-VA2-4, D-VA2-13, §1.11, §2.2, §3 C1 and D, §4, §A.11, §A.12, hand-off notes, Appendix B |
| RR2-m1 a specific's `PackValue` not stringified | MINOR | folded: reproduced (ctF names `F(<cannot stringify ...>)`), with three more copies of the TODO without a location, one per element, because `TryEvalPackIterationsForSpecific` evaluated a failed specific's blocks again in each iteration; `StringifyInst(PackValue)` prints the pack literal and the concrete pack type reuses it, and the per-iteration evaluation returns for a specific with an error; ctF now reports `F(⟬i32, i64, bool⟭)` and the note once; split `fail_todo_cpp_template_on_tuple_of_pack` added | M-19, §0.5, §2.1, §2.2, §3 C1, §4, §A.11, Appendix B |
| RR2-m2 Carbon template actions unpinned; D-VA2-14 stale | MINOR | folded: reproduced on rev 3 and rev 4 (tp1, tp3, tp4, tp5 the TODO; tp2 211); `fail_todo_template_action_on_hetero_element` (tp1's shape) and `hetero_pack`'s `template_outer` (tp2's) added and compiled; D-VA2-14's opening, R-11, §1.11's W-224 note and §A.12's W-224 sentence, which still named S-CT's TODO, rewritten | M-19, D-VA2-14, R-11, §1.11, §3 C1, §4, §A.11, §A.12 |
| RR2-m3 stale counts, heads and wording | MINOR | folded: §3 item 0 names revs 2 to 4; §0.6 counts 31 and 10; §6.2's list keeps only the files beyond the prototype; mdr names fee0ef31c on 89aabd125, re-read, and §0.6's table is re-measured at them and at trunk 449fecdd7 (`collisions_rev4.txt`: every row rev 3's); S-CT's last sentence plural; also stale and corrected: §2.0's "rev 2 prototype", the shrink line's prototype counts (now 31 files, 1399 and 122), the id re-scan and the upstream re-read | header, §0.6, §2.0, §3, §6.2, §8.7 |

Rev 4 is SIGNED OFF FOR IMPLEMENTATION: the verdict is APPROVE-WITH-AMENDMENTS,
not REJECT; every finding is folded; and the code the folds change (three
files, `$H/r/rev4_fixes.patch`) was built, gated, run through conformance and
the earlier probe sets, and measured on the PR 64 mirror, with no earlier
outcome changed but the ones the findings name (M-19).

## Stop-and-amend record (rev 5, 2026-10-26)

Stage 1 of the implementation (C0 and F0, §3 items 1 and 2) stopped before
committing F0 on 2026-10-26 and returned the difference below; the plan amender
reproduced it, found its root cause and wrote this revision (amended 2026-10-26,
implementation: stop-and-amend: nested constant initialization). The stage's
state at the stop: the branch holds C0 (d92a9c709, "VA-2 C0: lower nested
aggregate constants in their value representation", committed and not pushed;
`git branch -r --contains d92a9c709` prints nothing), the fill is uncommitted
and saved (`$L/nc_pass1.carbon`, `$L/f0_fill_uncommitted.diff`), the worktree is
clean and the install is C0's.

The difference, as the implementer recorded it (`$L`): the F0 fill of
toolchain/lower/testdata/tuple/nested_constant.carbon contradicts §4. Split
`var`: predicted "copied into a `var`'s alloca by its object representation,
element by element"; measured a 12-byte memcpy into `%v.var` from the value
representation's global `@tuple.c42.loc4_3 = internal constant <{ ptr, i32 }> <{
ptr @tuple.8a1.loc4_3, i32 6 }>`, so the inner tuple's address is copied into
the `{ { i32, i32 }, i32 }` object, which is wrong code: a `var` of
`((4, 5), 6)` prints two indeterminate values and 6, a nested struct `var` two
and 3, and an in-place `return` of `((4, 5), 6)` two and 6. Splits `tuple`,
`struct` and `struct_of_tuple`: predicted a constant `{ ptr, i32 }`, measured a
packed `<{ ptr, i32 }>`, the address and the load as predicted. The gate before
the fill was red on exactly that file, with no crash; with the fill 1961 of
1961; the fixpoint after one pass; the probes r16 3 2, r16g 3, r16h 3, x07 2 5 9
and c03 2 3 4 as recorded (r16h hides the defect: it reads `.1`, at offset 8 in
both layouts); conformance after C0 alone 137/0/21 of 158, unchanged.

Root cause (M-20): `InitializeStorage` copies a constant into its storage with
`CopyValue`, whose arms take the source's lowered value as the object
representation or its address; C0 made a constant of a type whose value
representation holds its elements' value representations lower to that value
representation, as upstream's `GetConstant` comment requires, so every copy of
such a constant into storage read a value as an object, and a one-element
aggregate of such a value, which before C0 was served as its object and so ran
on PR 59 and trunk, now aborts in `StoreObject` (a01, a16). C0's helper and
`GetConstant` also form a recursive call chain that `misc-no-recursion` rejects.
Neither is a header the relink missed, a golden the manifest missed or an
upstream rule misread: both are defects of the measured diff, which rev 2's
probes, lowering values only, could not see, and §4's `var` row predicted the
right result without a run.

The amendment:

-   C0b, a new code commit on C0 before F0 (§2.7's block, §3 item 1 and its
    message in §3): `CopyValue` copies a constant of such a type into the object
    element by element, `GetConstant` builds the elementwise value with a
    worklist, and the golden gains `return` and `one_element`. It is measured on
    C0 (gate, fill, conformance, probes, clang-tidy) and on the rev 4 prototype
    (gate, VA-1's churn, conformance, every earlier probe set, collisions), all
    as M-20 records.
-   §4's `nested_constant` rows are the measured fill's (the packed type,
    `var`'s element-by-element copy, two new rows); its totals gain two splits.
-   The header, M-12, M-20 (new), §0.5, §0.6, §1.11's W-335, §1.12's D-VA2-19,
    §2.0, §2.7, §3, §6.1, §6.2, §7.1's R-13 (new), §8.0, §8.1, §8.3, §8.4, §8.6,
    §8.9, the hand-off notes 1 and 2, §A.11 and §A.12 carry the amendment, each
    marked.
-   One decision changes, D-VA2-19: C0 is followed by C0b before its fill,
    because C0 alone miscopies such constants and aborts on a case PR 59 runs,
    and C0 is kept rather than reset away and re-committed with the fix, because
    keeping it rewrites no history (AGENTS.md: "Ask before rewriting history in
    any case"; R29 decides without asking, so the decision is not to rewrite);
    C0's message says the next commit fills its golden, which since this
    revision means the fill after C0b, and C0b's message says so. Its break
    condition, a commit that cannot build without a later one, is unchanged. No
    other decision changes: D-VA2-1 to D-VA2-18 hold as written, Appendix B is
    still the rev 4 prototype, and every count of §8.3 and §8.4 stands.

R32: upstream's tip is 8779d15e1 (`git fetch upstream trunk`, 2026-10-26), three
commits past 21c825a3f, c7de72757 (check/cpp/export.cpp and one golden),
e9d8d06f9 (comments in toolchain/base) and 8779d15e1 (toolchain/lex), none
touching docs/design, proposals, core, toolchain/lower or toolchain/sem_ir, and
`git merge-tree` against it gives the same 104 conflicted paths (M-20). C0b adds
no mechanism: it implements upstream's own contract for these copies
(function_context.h:318-320, file_context.cpp:213-215 and type_info.h:253-254 at
8779d15e1, quoted in M-20), lowering is internal representation, and no design
page is touched.

Instructions to the implementer, for stage 1 re-run after the focused re-review
of this amendment:

1.  Start at the rev 6 commit, which sits on rev 5 and C0 (rev 5 said "the rev 5
    commit" (amended 2026-10-26, review fold: RR5-M1)). C0 (d92a9c709) stays: do
    not reset it and do not amend it. Check that `git -C /home/user/carbon-va2
    branch -r --contains d92a9c709` prints nothing and that `git -C
    /home/user/carbon-va2 status --short` is empty; the stopped run's
    uncommitted fill is not reused. Read upstream's tip (`git -C
    /home/user/carbon-va2 fetch upstream trunk` and `git -C
    /home/user/carbon-va2 ls-remote upstream refs/heads/trunk`) and record its
    sha in the stage's log: rev 6 read 56d9bbc40; a later tip is listed with the
    files it changes since 56d9bbc40, and it is a difference if it changes a
    file that M-20, §2.7 or §7.2's A-11 cites
    (toolchain/lower/function_context.h and .cpp, file_context.h and .cpp,
    aggregate.cpp, sem_ir/type_info.h and .cpp, check/type_completion.cpp,
    core/prelude/copy.carbon) or a design page of the header's list (amended
    2026-10-26, review fold: RR5-m3).
2.  Extract §2.7's C0b block, the lines between the `diff` fence after "The
    block, against d92a9c709" and its closing fence, into a file under the stage
    directory, then `git -C /home/user/carbon-va2 apply --check <file>` and
    `git -C /home/user/carbon-va2 apply <file>`: five files change, with §2.7's
    numstat.
3.  `/home/user/llvm/bin/clang-format --dry-run --Werror` on
    toolchain/lower/file_context.cpp, file_context.h, function_context.cpp and
    function_context.h exits 0; prek with a private `XDG_CACHE_HOME` on the five
    files reaches its fixpoint.
4.  clang-tidy, §8.6's two passes, over toolchain/lower/file_context.cpp and
    function_context.cpp with the build's flags, the second line-filtered to the
    lines changed since b0822a744: exit 0 and no diagnostic (M-20).
5.  Commit C0b with explicit paths (the five files), §3's C0b message verbatim
    (title "VA-2 C0b: copy nested aggregate constants into storage element by
    element", where rev 5 wrote "VA-2 (0b):" (amended 2026-10-26, review fold:
    RR5-m1)), §3's author and committer, and the two session trailers after a
    blank line.
6.  `build.sh` and `install.sh`: an incremental build of the 13 lower objects
    and the links, with 0 warnings; `carbon version` prints the development
    version with C0b's short hash, since the harness stamps `git
    rev-parse --short HEAD` (the stopped run's finding, which no prediction of
    this plan contradicts).
7.  `gate.sh`: "1960 passed, 1 failed", red only on
    toolchain/lower/testdata/tuple/nested_constant.carbon ("Autoupdate would
    make changes"), with no crash.
8.  M-20's 36 probes (`$J/probes/*.carbon` and `$J/probes_impl/*.carbon`), each
    with `$H/r/run_probe.sh <install>/bin/carbon <probe> <outdir>` into the
    stage directory: a01 1 2, a02 1 2, a04 1 2 3 4, a05 7 8 9, a06 1 2 3 4, a07
    1 2 3 5 6, a08 1 2 3, a09 1 2 3 4, a10 4 5 6, a11 7 1, a12 1 2 3, a13 5 6 7,
    a14 1 2 3 4, a15 1 2 3, a16 1 2, a17 1 2 3 4, a18 1 2 3 1 3, c01 7 1, c02 2
    3, c03 2 3 4, c04 5 6 7, c05 1 2 4 5, c06 2 4, c07 1 3, c08 5 3, r16 3 2,
    r16g 3, r16h 3, v01 4 5 6, v02 1 2 3, v03 7 8 9, v04 4 5 6 and x07 2 5 9;
    a03 prints 1 and an indeterminate value, and a19 and a20 stop in check with
    `new_storage_id.has_value()` at check/convert.cpp:2313, as on every
    toolchain (M-20); neither is a difference. Since rev 6, also d01 to d04
    (`$K/probes_d`, M-20), the same way, into the same directory: d01, d02 and
    d03 stop in lowering with `CHECK failure` at toolchain/lower/lower.cpp:48
    (`!llvm::verifyModule(...)`, "Invalid InsertValueInst operands!"), and d04
    prints 1 2 3 (amended 2026-10-26, review fold: RR5-M1).
9.  F0: `autoupdate.sh /home/user/carbon-va2
    toolchain/lower/testdata/tuple/nested_constant.carbon`, then the same again,
    which changes nothing; the file is 483 lines, 415 more than C0b's 68-line
    source, byte-identical to `$J/nested_constant_c0b2_filled.carbon`, and is
    reviewed against §4's six rows.
10. `gate.sh`: "1961 passed, 0 failed".
11. `conformance.sh` with a private cache into a private directory: PASS 137,
    COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0,
    SKIP 21 (of 158), bullets 49 PASS, 0 FAIL, 7 SKIP, 0 NOT-WRITTEN of 56.
12. Commit F0, "Autoupdate testdata goldens on the container arbiter", with the
    golden's path only and the trailers, then `git push -u origin
    claude/carbon-fork-0-1-va2`, which pushes C0, rev 5, rev 6, C0b and F0 (rev
    5 said "C0, this revision, C0b and F0" (amended 2026-10-26, review fold:
    RR5-M1)).
13. Stage 2 (C1) as §3 item 3 and the hand-off notes say, its hunks taken from
    Appendix B by file and function (they apply on C0 plus C0b, M-20); after
    C1's build and after every later stage's, M-20's probes again, expecting the
    same outputs (R-13), but for a03's indeterminate value and the line of a19's
    and a20's CHECK failure, which moves with convert.cpp's hunks (:2361 on the
    rev 4 prototype with C0b, `$J/set_wt5.txt`) and is not a prediction. d01 to
    d04 are re-run with them: through C3 as item 8 says (measured on the rev 4
    prototype with C0b, `$K/set_wt6_d.txt`), and from C4 on d01 prints 101 1,
    d02 1 2, d03 1 2 and d04 1 2 3; a d01, d02 or d03 that does not print its
    line on C4's install is a stop at C4, before F4, whose amendment brings a
    fix or a plan revision that makes the form OUT with R17's precise TODO
    (R-13) (amended 2026-10-26, review fold: RR5-M1).

Predictions, EXPECTED, not of record: the gate 1960 passed and 1 failed after
C0b and 1961 after F0, then §8.3's 1966, 1971, 1973 and 1975; conformance
137/0/21 over 158 after C0b and after C4 alone, and 147/0/21 over 168 after C5,
bullets 49/0/7 of 56; §5's and Appendix A's outputs and C4's predicted churn as
rev 4 states them. A difference from these is a stop, as §8 says; the
indeterminate values in M-20 are not predictions. a03, a19 and a20 are
upstream's (R-13), and no id is minted for them; rev 5 also called them outside
the slice, which d01 to d03 refute, and since rev 6 the predictions hold d01 to
d04's lines in items 8 and 13 (amended 2026-10-26, review fold: RR5-M1).

**Rev 6: the re-review of this amendment (2026-10-26).** The focused re-review
of rev 5 (ef58cf5dd on C0 d92a9c709) returned APPROVE-WITH-AMENDMENTS with one
MAJOR and three MINORs; it edited no repository file and kept its logs and
probes in the directory `amendrr5` beside `$J`. It reproduced the stop on C0's
install (v01 and v04 printing two indeterminate values and 6, a01 and a16
stopping in `StoreObject` at function_context.cpp:522), the root cause and its
citations at 8779d15e1; extracted §2.7's block byte-identical to
`$J/c0b_block_final.patch` with the stated numstat, applying at ef58cf5dd, with
Appendix B less its file_context.cpp hunk applying on C0 plus C0b; found
clang-format 21.1.8 and both §8.6 clang-tidy passes clean on C0b's two .cpp
files and 13 lower objects including the two headers; relinked C0b over the C0
build, where the gate was 1960 passed and 1 failed before the fill, the fill 483
lines at its fixpoint after one pass, byte-identical to
`$J/nested_constant_c0b2_filled.carbon` and matching §4's six rows, the gate
1961 passed after it, conformance 137/0/21 of 158 with bullets 49/0/7 of 56, and
M-20's 36 probes as predicted; and ran 14 probes of its own (a `var` parameter,
a var pattern, the assignment of a 1-tuple, a 1-tuple in a pair, a 1-tuple of a
1-tuple, a mixed struct, duplicate elements, a constant imported from another
library copied into a `var`, two specifics of a generic), all right on C0b,
three of them (n03, n09, n16) stopping in `StoreObject` on C0 and running on
PR 59. It found no IN form hidden or weakened (R17), D-VA2-19's one change
justified with its break condition kept, §3's order (C0, C0b, F0, C1) kept, no
history rewritten, nothing pushed and the R31 counts unchanged. Four findings,
all folded, none rejected, each amended sentence marked "(amended 2026-10-26,
review fold: RR5-<finding>)":

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR5-M1 a program of the slice reaches the a03 class, against M-20 and R-13 | MAJOR | folded: reproduced (`$K/set_*_d.txt`): d01 (§A.6's `Dup(one)` verbatim), d02 and d03 abort in lowering on PR 59, trunk, the nightly, C0 and C0b and on the rev 4 prototype with C0b, d01 and d02 at the verifier with the `insertvalue ... void <badref>` of the hand-written `(T,)` impl's by-copy `Op`, d03 at lower/handle_call.cpp:984 on PR 59 and trunk (:783 on the nightly) and at the verifier from C0 on; d04, a control, aborts on PR 59, trunk and the nightly and prints 1 2 3 from C0 on; M-20's paragraph and R-13 now say that the class is reached today through core/prelude/copy.carbon:55-59 (the finding cited :54-58) and from C4 on through the unbuilt `PackSegmentInit` of a by-copy `(Loud,)`, that C4's stage decides, and that a d probe failing at C4 is a stop at C4 with a fix or a plan revision that makes the form OUT with R17's precise TODO; d01 to d04 join the probes every stage re-runs | header, M-11, M-20, R-9, R-13, §2.4 item 7, §3 item 9, §5, §8.0, §8.4, §8.9, hand-off note 2, §A.6, this record's items 8, 12 and 13 and its predictions |
| RR5-m1 C0b's title breaks §3's convention | MINOR | folded: "VA-2 C0b: copy nested aggregate constants into storage element by element" in §3's message and item 5; rev 5 recorded no reason for the `(0b)` form | §3, item 5 |
| RR5-m2 no rejected alternative for C0b's mechanism | MINOR | folded: §7.2's A-11, one memcpy from a global of the constant's object representation, rejected for its second global, map and name per constant and for reaching past `CopyValue`'s value into `FileContext`'s constant table, with the break condition that upstream fixes `GetConstant` or `CopyValue` (§2.7 then takes upstream's) or that a review finds a copy C0b gets wrong and the memcpy gets right | §7.2 |
| RR5-m3 upstream's tip has moved | MINOR | folded: `git fetch upstream trunk` and `git ls-remote upstream refs/heads/trunk` give 56d9bbc40 ("Support C++ friend declarations for Carbon generic classes", 2026-10-26 17:09 UTC), one commit past 8779d15e1, changing only toolchain/check/cpp/import.cpp and toolchain/check/testdata/interop/cpp/class/import/access.carbon, so none of docs/design, proposals, core, toolchain/lower and toolchain/sem_ir, and every citation at 8779d15e1 holds at 56d9bbc40; `git merge-tree` gives the same 104 conflicted paths, the same set, for b0822a744, ca939ee19 and 90c34dbaa (`$K/mt_up_56d9.txt`); item 1 has the implementer read and record the tip | this record, item 1, §6.3 |

R32 at rev 6: no design page, proposal or prelude file changed between 8779d15e1
and 56d9bbc40, so rev 5's reading stands, and rev 6 adds no mechanism: it
records measurements, a stop condition at C4 and a rejected alternative (amended
2026-10-26, review fold: RR5-m3). The instructions above are amended in items 1,
5, 8, 12 and 13 and in the predictions, each marked, and the stage 1 re-run
follows them as they now stand. No decision changes: D-VA2-1 to D-VA2-19 hold as
rev 5 states them, C0b's block, Appendix B and every count of §8.3 and §8.4
stand, and no id is minted.

## Stop-and-amend record (rev 7, 2026-10-26)

Stage 2 of the implementation (C1 and F1, §3 items 3 and 4) stopped before
committing C1 on 2026-10-26 and returned the differences below; the plan amender
reproduced them, found their root causes and wrote this revision (amended
2026-10-26, implementation: stop-and-amend: C1's split and golden sources). The
stage's state at the stop: the branch holds the plan's revisions and C0, C0b and
F0, all on origin (head 8a7395cf1, F0; `git branch -r --contains 8a7395cf1`
prints `origin/claude/carbon-fork-0-1-va2`); nothing of stage 2 was committed or
pushed; the worktree is clean; the stopped run's C1 is saved as
`$N/c1_uncommitted_source_state.patch`; and the install
/home/user/carbon-build/carbon-va2 holds that uncommitted state and
prints 0.0.0-0.dev+8a7395cf1.dirty.

The differences, as the implementer recorded them (`$N/stage.log`), each
detailed with its measurement in M-21:

-   D1: C1's gate, predicted red on exactly ten files with no crash (§3 item 3,
    §8.3), aborts with `Unhandled type instruction {kind: PackType, ...}` at
    sem_ir/type_iterator.cpp:312 in fail_todo_va2's
    `fail_todo_cpp_template_on_tuple_of_pack` (`$N/gate_pre.log`); every probe
    with `(... each T)` as a type aborts the same way, C1's f03, r02 and ctF
    among them.
-   D2: `hetero_pack`'s `type_pack`, `forward` and `method` and `generic_pack`'s
    `call`, predicted without a diagnostic, report `use of undefined generic
    function` (`$N/au_pre1.log`).
-   D3: lower `hetero_pack`'s `layout` passes an internal constant where §4
    predicts an alloca and three stores.
-   D4: lower `hetero_pack`'s `forward` re-packs `Forward`'s pack element by
    element where §4 predicts that it passes its own pack's address.
-   And an inconsistency: §3's C1 message named the `specific_constant`
    reference to an enclosing generic's arity, which §2.2 and §3 item 5 give C2.

Root causes (M-21). D1 is the plan's assignment of hunks to commits: §2.2 gave
C1 the hunk that makes `... each T` of a compile-time pack the pack itself, and
§2.3 gave C2 the two hunks that take that pack as a tuple's segment,
`ConvertTupleToType`'s and the type iterator's `PackType` case; the split had
never been built and gated alone. D2 is in the golden sources: they call generic
functions that have no definition, which upstream's check/check_unit.cpp rejects
for every generic function, and they had been parsed, never compiled. D3 and D4
are wrong predictions in §4, which C1's own `EmitAsConstant(PackValue)` and
VA-1's lowering of a `PackExpansionExpr` argument contradict. None is a header a
relink missed (the implementer built in full), a golden the manifest missed (the
red set is the ten predicted files) or an upstream design rule misread (D2's
rule is upstream's toolchain rule, which the sources now follow), and none is a
defect of Appendix B's code.

The amendment:

-   §2.2's rev 7 block: type_iterator.cpp's `PackType` case and
    `ConvertTupleToType`'s pack segment move from C2 to C1, verbatim from
    Appendix B, which does not change; C2's built half is then
    `$M/c2_rest_after_v1b.patch`. Measured on C1 (gate, fill, conformance,
    probes, clang-format, clang-tidy, prek) and on C1 with C2's built half (a
    full build, the probe sets, C2's three amended splits), as M-21 records.
-   §A.11: the four C1 splits and the three C2 splits of D2's form define their
    functions, `{}` with `unused` parameters, and §A.11's lead says why.
-   §4: the measured fill's rows for `type_pack`, `forward`, `method`,
    `generic_pack`'s `call`, `fail_todo_cpp_template_on_tuple_of_pack`, the
    lower `call`, `layout`, `forward`, `lib` and `use`, and C2's `param`,
    `tuple_value` and `elements_around_segment`; its totals are unchanged.
-   §3: D-VA2-19's paragraph and break condition, items 3, 4 and 5, the note
    before the messages, and C1's and C2's messages, C2's taking the
    `specific_constant` sentence from C1's.
-   The header, M-21 (new), §0.5, §0.8's F-10 (new), §1.12's D-VA2-19, §2.0,
    §2.1, §2.2, §2.3, §6.1, §6.3, §7.1's R-14 (new), §7.2's A-12 (new), §8.0,
    §8.1, §8.3, §8.4, §8.9 and the hand-off notes 1 and 2 carry the amendment,
    each marked.
-   One decision changes, D-VA2-19, the commit split: two hunks move from C2 to
    C1, because C1 accepts the form they complete and its gate aborts without
    them, and moving them is the smallest change that keeps every rev 4
    prediction for C1 (A-12 rejects moving the collapse to C2 instead); its
    break condition gains the case of a gate that crashes. C1 is committed only
    after its build and gate, so no commit is reset or rewritten. No design
    decision changes: D-VA2-1 to D-VA2-18 hold as written, every count of §8.3
    and §8.4 stands, and no id is minted.

R32: upstream's tip is 600fd55ba (`git fetch upstream trunk` and `git ls-remote
upstream refs/heads/trunk`, 2026-10-26), one commit past 56d9bbc40, "Add a
realistic header compile benchmark", which changes toolchain/benchmarking only,
so none of docs/design, proposals, core, toolchain/check, toolchain/lower and
toolchain/sem_ir; `git merge-tree` gives the same 104 conflicted paths for
b0822a744, ca939ee19 and 90c34dbaa (`$M/mt_up_600f.txt`). D2's rule is
upstream's (check/check_unit.cpp:507-523 at 600fd55ba: "use of undefined generic
function"), the amendment follows it as VA-1's goldens do, and it adds no
mechanism and no spelling: it moves two hunks of Appendix B between commits and
gives seven test functions an empty body.

Instructions to the implementer, for stage 2 re-run after the focused re-review
of this amendment:

1.  Start at the rev 7 commit, or the commit that folds its re-review, on F0
    (8a7395cf1). Nothing of stage 2 is in the history, so nothing is reset:
    `git -C /home/user/carbon-va2 branch -r --contains 8a7395cf1` prints
    `origin/claude/carbon-fork-0-1-va2`, `git -C /home/user/carbon-va2
    log --oneline origin/claude/carbon-fork-0-1-va2..HEAD` prints only the plan
    commits since F0, and `git -C /home/user/carbon-va2 status --short` is
    empty. Read upstream's tip (`git -C /home/user/carbon-va2 fetch upstream
    trunk` and `git -C /home/user/carbon-va2 ls-remote upstream
    refs/heads/trunk`) and record it in the stage's log: rev 7 read 600fd55ba; a
    later tip is listed with the files it changes since 600fd55ba, and it is a
    difference if it changes check/check_unit.cpp, check/convert.cpp,
    check/handle_pack_expansion.cpp, sem_ir/type_iterator.cpp,
    lower/handle_pack_expansion.cpp, a file that M-20, §2.7 or §7.2's A-11
    cites, or a design page of the header's list.
2.  Apply `$M/c1_rev7.patch` (`git -C /home/user/carbon-va2 apply --check`, then
    `git apply`): 33 files, 1491 insertions and 118 deletions against 8a7395cf1,
    the paths of `$M/c1_rev7_files.txt`. It is the stopped run's saved state
    (C1's hunks by §2.1 and §2.2, C1's own changes, clang-format's re-wrapping
    and §A.11's C1 sources), §2.2's rev 7 block and §A.11's four amended C1
    splits. Check it against this plan first: §2.2's block, extracted, applies
    with `git apply --check` on 8a7395cf1 with the saved state, and the five new
    goldens are §A.11's text, fail_todo_va2.carbon with its first fourteen
    splits and traits.h; a mismatch is a difference.
3.  `/home/user/llvm/bin/clang-format --dry-run --Werror` on C1's .cpp and .h
    files exits 0, and prek with a private `XDG_CACHE_HOME` and §8.6's SKIP list
    on the 33 files passes and changes nothing (measured,
    `$M/logs/prek_c1_1.log`).
4.  clang-tidy, §8.6's two passes, over C1's 21 .cpp files
    (`$N/c1_cpp_files.txt`) with the build's flags, the second line-filtered to
    the lines changed since b0822a744: exit 0 and no diagnostic (the stopped
    run's `$N/tidy`, and `$M/tidy` for the two files the block changes).
5.  Commit C1 with the 33 explicit paths, §3's title "VA-2 C1: packs of
    different types in implicit parameter lists" and its message as rev 7 amends
    it, §3's author and committer, and the two session trailers after a blank
    line; `git -C /home/user/carbon-va2 rev-parse HEAD:toolchain` prints
    57d89a880239dee5283f1a69b5ca6a9e2a8bc32d.
6.  `build.sh` and `install.sh`: a full build (typed_insts.h changes) with 0
    warnings, replacing the stopped run's install; `carbon version` prints C1's
    short hash.
7.  `gate.sh`: "1956 passed, 10 failed", the ten files of §3 item 3, with no
    crash.
8.  Probes: M-20's 36 and d01 to d04, as stage 1 ran them, print
    `$M/probes_v1b.txt` line for line but for a03's indeterminate value, the
    line of a19's and a20's CHECK failure in check/convert.cpp (:2348 there) and
    the paths; the sets of hand-off note 2 (`$H/r/run_rr2.sh`,
    `$G/r/run_set.sh`, `$G/r/probes_all.sh`, or stage 2's copies in `$N/bin`)
    print `$M/sets/rr2set_v1b.txt`, `set_v1b.txt` and `probesall_v1b.txt` line
    for line but for paths and that convert.cpp line: rev 4's outputs for C1's
    probes, and R-14's for C2's forms.
9.  F1: `autoupdate.sh /home/user/carbon-va2` on the ten files, then the same
    again, which changes nothing; each file is byte-identical to
    `$M/fill_rev7_p2/<its path>` and is reviewed against §4's C1 rows as rev 7
    states them.
10. `gate.sh`: "1966 passed, 0 failed".
11. `conformance.sh` with a private cache into a private directory: PASS 137,
    COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0,
    SKIP 21 (of 158), bullets 49 PASS, 0 FAIL, 7 SKIP, 0 NOT-WRITTEN of 56.
12. Commit F1, "Autoupdate testdata goldens on the container arbiter", with the
    ten paths and the trailers (`git -C /home/user/carbon-va2 rev-parse
    HEAD:toolchain` prints 913a132b474be56f16581c9ff3b022b35473ff4f), then `git
    push -u origin claude/carbon-fork-0-1-va2`, which pushes the plan commits
    since F0, C1 and F1.
13. Stage 3 (C2) as §3 item 5 says: its built half is
    `$M/c2_rest_after_v1b.patch` (9 files, applying on C1), with §2.4's code and
    C2's sources of §A.11 as rev 7 amends them; M-21 records what C1 with C2's
    built half prints.

Predictions, EXPECTED, not of record: the gate 1956 passed and 10 failed after
C1 and 1966 after F1, then §8.3's 1971, 1973 and 1975; conformance 137/0/21 over
158 after C1 and after C4 alone, and 147/0/21 over 168 after C5, bullets 49/0/7
of 56; the fill of item 9, the probes of item 8, §4's rows as rev 7 states them,
and §5's and Appendix A's outputs and C4's predicted churn as rev 4 states them.
A difference from these is a stop, as §8 says; a03's indeterminate value and the
convert.cpp line of a19's and a20's CHECK failure are not predictions.

## Sign-off

Rev 7 (2026-10-26) amends rev 6 for the implementation's stop-and-amend at stage
2, which the record above states (amended 2026-10-26, implementation:
stop-and-amend: C1's split and golden sources): rev 4's sign-off, as amended by
rev 5 and rev 6, stands for every part the amendment does not touch, and the
focused re-review of the amendment, which the orchestrator runs next, decides
the rest; its row joins the table below when it reports, and the table's rev 6
row names its commit, 4d5388af2, where rev 6 wrote "this revision".

Rev 6 (2026-10-26) folds the focused re-review of rev 5 (RR5,
APPROVE-WITH-AMENDMENTS: one MAJOR and three MINORs, all folded, none rejected),
as the rev 6 part of the stop-and-amend record states (amended 2026-10-26,
review fold: RR5-M1 / RR5-m1 / RR5-m2 / RR5-m3): the verdict is not REJECT, so
rev 4's sign-off, as amended by rev 5 and rev 6, stands, and stage 1 re-runs
with the record's instructions.

Rev 5 (2026-10-26) amends rev 4 for the implementation's stop-and-amend at stage
1, which the record above states (amended 2026-10-26, implementation:
stop-and-amend: nested constant initialization): rev 4's sign-off stands for
every part the amendment does not touch, and the focused re-review of the
amendment, which the orchestrator runs next, decides the rest; its row joins the
table below when it reports.

Rev 4 (2026-10-26) is SIGNED OFF FOR IMPLEMENTATION. The implementation
follows §3 from Appendix B (the hand-off notes), with its own two
implementation reviews (§3 item 12); a fill or a run that contradicts a
prediction of this plan is a finding for those reviews, never an edit to a
golden (§4, §8.2). Every review of this plan:

| Review | Of | Verdict | BLOCKER | MAJOR | MINOR | Findings | Folded by |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Review A (R29(c)) | rev 1 (51c6cfb10) | REJECT | 3 | 2 | 5 | 10 | rev 2 (78524522b): all folded, none rejected |
| Review B (R29(c)) | rev 1 (51c6cfb10) | REJECT | 2 | 8 | 5 | 15 | rev 2 (78524522b): all folded, none rejected |
| Focused re-review 1 (RR1) | rev 2 (78524522b) | REJECT | 1 | 1 | 3 | 5 | rev 3 (8d377a06d): all folded, none rejected |
| Focused re-review 2 (RR2) | rev 3 (8d377a06d) | APPROVE-WITH-AMENDMENTS | 0 | 1 | 3 | 4 | rev 4 (7188540ca): all folded, none rejected |
| Focused re-review of the amendment (RR5) | rev 5 (ef58cf5dd) | APPROVE-WITH-AMENDMENTS | 0 | 1 | 3 | 4 | rev 6 (4d5388af2): all folded, none rejected |
| Total | | | 6 | 13 | 19 | 38 | 38 folded, 0 rejected (37 distinct) |

RR1's MAJOR is review B's B-M5, which rev 2 folded without resolving it, so the
38 findings as reported are 37 distinct ones (34 and 33 before rev 6 (amended
2026-10-26, review fold: RR5-M1 / RR5-m1 / RR5-m2 / RR5-m3)); rev 2's record
counts two of reviews A's and B's 25 as folded in part, with evidence (B-m5 is
one). The records of each fold are the "Review fold record" sections above and
the stop-and-amend record.

## Appendix A. Conformance programs, golden sources and records

Every program is written to `fork/conformance/programs/<path>` by C5, verbatim.
Each of rev 1's was parsed by the planner with PR 59's install (`carbon
compile --phase=parse`, all nine parse), and the four stdlib programs, which use
no pack syntax, were checked there too (M-11). Rev 2 renames the three
differential pairs to `*_diff`, rewrites §A.7 to §A.9 and adds §A.10, and the
fixer parsed those four on PR 59's install and checked the three stdlib ones
there (M-11); §A.1 to §A.3 and §A.10 run on the rev 2 prototype with the
derived outputs, and the rest cannot run before C2 to C4 (amended 2026-10-22,
review fold: A-m-1 / A-m-2 / B-M1 / B-M3 / B-m3). EXPECT lines are derived from
the program text and the design (R16(d)), never from a run.

### §A.1 `generics/variadics_hetero_digits_diff.carbon`

Derived from the program text (DIFF-1, no EXPECT-STDOUT): `Cat(a, b, c, d)` has
`T` = `⟬Two, One, Two, One⟭`, prints the width 2 + 1 + 2 + 1 = 6 and returns
((((0 · 100 + 74) · 10 + 2) · 100 + 7) · 10 + 4) = 742074; `Cat(d, e)` prints
1 + 2 = 3 and returns 4 · 100 + 22 = 422; `Cat()` prints 0 and returns 0; `Sum`
of -7, 300 and 40000 is 40293; `Sum(5 as i32)` is 5. Stdout: 6, 742074, 3, 422,
0, 0, 40293, 5. The oracle, compiled by the planner with LLVM 21.1.8's
`clang++ -std=c++17 -Wall -Wextra -Werror -stdlib=libc++` and run (M-10), prints
exactly these lines, and the rev 2 prototype's Carbon side prints them too
(`$F/r3/probes_rank.txt`). Cat has StrCat's shape over names the fork has;
StrCat's own text is §A.10's program (amended 2026-10-22, review fold: B-M3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
//
// Differential pair: variadics_hetero_digits_diff.diff.cpp computes the same
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

// Differential C++17 equivalent of variadics_hetero_digits_diff.carbon: each Carbon
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

EXPECT, derived in the header: 112, 4, 71, 0. Rev 1's header said "as in the
signatures of the design's Apply and TupleConcat"; the program tests only
their tuple-typed parameter and return, and W-213 stays narrowed for the rest
(amended 2026-10-22, review fold: B-B1).

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
// shapes"), the tuple-typed parameter and return that the design's Apply and
// TupleConcat signatures use; those signatures themselves also need a
// variadic `Core.Call`, a second implicit-list pack, a tuple of two segments
// and `...expand`. SumTuple deduces its pack of types from its argument's
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
(error_handling/question_generic_thread_diff.carbon :121). R27's spelling diff
against the design's Min (variadics.md :264-270), the body identical and the
constraint names the prelude's (amended 2026-10-22, review fold: B-m3):

<!-- google-doc-style-ignore -->

```diff
--- docs/design/variadics.md :264-270
+++ fork/conformance/programs/generics/variadics_min.carbon
@@ -1,4 +1,5 @@
-fn Min[T: Comparable & Value](first: T, ... each next: T) -> T {
+fn Min[T: Core.Ordered & Core.Copy & Core.Destroy](first: T, ... each next: T)
+    -> T {
   var result: T = first;
   ... if (each next < result) {
     result = each next;
```

<!-- google-doc-style-resume -->

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
(Loud, Loud) = (l1, l2);` copies nothing is measured by the fixer's x15, which
binds that tuple with `let` and prints no copy, then copies it into a `var` and
prints each element's copy once (0 1 2 101 102 3 on PR 59 and the rev 2
prototype); rev 1 cited p22, which copies with `var` (amended 2026-10-22, review
fold: B-m5); every printed copy is the impl's. On PR 59's install the program
fails exactly at the four `Dup` calls of tuples of arity 4, 5, 13 and of the
nested tuple (`cannot convert type ... into type implementing Core.Copy`), and
nowhere else (M-11). That is its check; in lowering, `Dup(one)` aborts on PR 59,
trunk, the nightly, C0 and C0b (M-20's d01), and its 101 and 1 rest on C4 (R-13)
(amended 2026-10-26, review fold: RR5-M1).

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

### §A.7 `stdlib/tuple_eq_diff.carbon`

Derived (DIFF-1): `a == b` 1, `a == c` 0 (the middle element), `a != c` 1, `e1
== e2` 1, `n == m` 0 (the inner tuple's second element), `n != n2` 0, `w == w2`
1; `p == q` runs Counted's `Equal` on the first two elements, printing 11 and
12, and is 0; `p != q` runs Counted's `NotEqual` field-wise, which is `EqWith`'s
default `not Equal` for Counted, so it prints 11 (equal, so not yet decided) and
12 (not equal) and is 1, the lines std::tuple's `!(p == q)` prints too (amended
2026-10-26, review fold: RR1-Nm-2); `p == p` prints 11, 12 and 13 and is 1.
Stdout: 1, 0, 1, 1, 0, 0, 1, 11, 12, 0, 11, 12, 1, 11, 12, 13, 1; the oracle,
compiled by the fixer as M-10 compiles rev 1's and run, prints exactly these
(`$F/r3/out_prog`). Rev 2 renames the pair to `*_diff` and adds the Counted
lines, which an int-only oracle could not tell from an `Equal` that called `!=`
(amended 2026-10-22, review fold: B-M1 / B-m3). On PR 59's install the program
fails exactly at its ten comparisons (M-11).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
//
// Differential pair: tuple_eq_diff.diff.cpp compares the same values with
// std::tuple's operator== and operator!=, which compare element by element
// with the elements' ==, in order, stopping at the first element that
// differs, as Carbon's tuple equality does (docs/design/tuples.md,
// "Operations performed field-wise"; docs/design/expressions/
// comparison_operators.md, "Default implementations for basic types"), and
// define != as the negation of ==; Carbon's tuple != compares field-wise with
// the elements' !=, which for every element type here is the negation of ==
// (Counted keeps EqWith's default NotEqual), so the two run the same element
// comparisons and C++ is the oracle for every printed line (no
// EXPECT-STDOUT). The prelude's variadic impl makes a tuple
// `EqWith` itself when every element type is `Eq`: elements of three types, a
// tuple that differs in its middle element, the empty tuple, a tuple of
// tuples (the impl used again for the inner tuple), a 5-tuple, and tuples of
// Counted, whose Equal prints 10 plus its field, so the comparisons each
// element runs, and where they stop, are printed too.

import Core library "io";

class Counted {
  var v: i32;
}

impl Counted as Core.EqWith(Counted) {
  fn Equal(self, other: Counted) -> bool {
    Core.Print(10 + self.v);
    return self.v == other.v;
  }
}

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
  let c1: Counted = {.v = 1};
  let c2: Counted = {.v = 2};
  let c3: Counted = {.v = 3};
  let c5: Counted = {.v = 5};
  let p: (Counted, Counted, Counted) = (c1, c2, c3);
  let q: (Counted, Counted, Counted) = (c1, c5, c3);
  Show(p == q);
  Show(p != q);
  Show(p == p);
  return 0;
}
```

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of tuple_eq_diff.carbon: each Carbon tuple is
// a std::tuple of the same element types, and `==` and `!=` are std::tuple's,
// which compare element by element with the elements' `==`, in order,
// stopping at the first element that differs, and define `!=` as the
// negation of `==`. Counted's `==` prints 10 plus its field, as the Carbon
// program's Equal does. printf("%d\n", ...) mirrors Core.Print's lowering.

#include <cstdint>
#include <cstdio>
#include <tuple>

static auto Show(bool b) -> void { std::printf("%d\n", b ? 1 : 0); }

struct Counted {
  int32_t v;
};

static auto operator==(const Counted& self, const Counted& other) -> bool {
  std::printf("%d\n", 10 + self.v);
  return self.v == other.v;
}

using Pair = std::tuple<int32_t, int32_t>;
using Five = std::tuple<int32_t, int32_t, int32_t, int32_t, int32_t>;
using Three = std::tuple<Counted, Counted, Counted>;

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
  Counted c1{1};
  Counted c2{2};
  Counted c3{3};
  Counted c5{5};
  Three p{c1, c2, c3};
  Three q{c1, c5, c3};
  Show(p == q);
  Show(p != q);
  Show(p == p);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.8 `stdlib/tuple_ordered_diff.carbon`

Derived (DIFF-1): `a` = (1, 2, 3) against `b` = (1, 3, 0) is decided by the
second element: `<` 1, `<=` 1, `>` 0, `>=` 0; against the equal `c`: `<` 0, `>`
0, `<=` 1, `>=` 1; the empty tuples: `<` 0, `<=` 1; `n` = ((2, 1), 0) against
`m` = ((1, 9), 5) is decided by the inner tuples' first elements: `>` 1, `<` 0;
`t` = (NaN,): `<` 0, `<=` 1 and `>=` 1, since neither element is less than the
other, while `nan <= nan` is 0 (x10). Stdout: 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1,
0, 0, 1, 1, 0; the oracle prints exactly these (`$F/r3/out_prog`; rev 1's
twelve lines by M-10). Rev 2 renames the pair and adds the NaN lines, which pin
register entry (vi) (amended 2026-10-22, review fold: A-m-2 / B-m3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
//
// Differential pair: tuple_ordered_diff.diff.cpp compares the same values
// with std::tuple's operator<, operator<=, operator> and operator>=, which
// compare lexicographically using only the elements' `<`, as Carbon's tuple
// ordering does (docs/design/expressions/comparison_operators.md, "Default
// implementations for basic types"), so C++ is the oracle for every printed
// line (no EXPECT-STDOUT). The prelude's variadic impl makes a tuple
// `OrderedWith` itself when every element type is `Ordered`: tuples decided
// by their second element, equal tuples, the empty tuple, a tuple of a tuple
// and an i64 decided by the inner tuple's first element, and a 1-tuple of a
// NaN: neither element is less than the other, so the tuples are
// equivalent and `<=` and `>=` hold, although the element's own `<=` does
// not (the design leaves orderings that are not total open, "There is no
// expectation that an `Ordered` implementation be a total order").

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
  let z: f64 = 0.0;
  let nan: f64 = z / z;
  let t: (f64,) = (nan,);
  Show(t < t);
  Show(t <= t);
  Show(t >= t);
  Show(nan <= nan);
  return 0;
}
```

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of tuple_ordered_diff.carbon: each Carbon
// tuple is a std::tuple of the same element types, and `<`, `<=`, `>` and
// `>=` are std::tuple's, which compare lexicographically using only the
// elements' `<` (`t <= u` is `!(u < t)`), so a 1-tuple of a NaN is
// equivalent to itself although the NaN's own `<=` is false.
// printf("%d\n", ...) mirrors Core.Print's lowering.

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
  double z = 0.0;
  double nan = z / z;
  std::tuple<double> t{nan};
  Show(t < t);
  Show(t <= t);
  Show(t >= t);
  Show(nan <= nan);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.9 `stdlib/tuple_impl_generic.carbon`

EXPECT, derived in the header from §2.6's corrected `Equal` (rev 1's 21, 22, 0,
21, 22, 23 were derived from an `Equal` that called the elements' `NotEqual`,
not from the design; amended 2026-10-22, review fold: A-m-1 / B-M1), and from
rev 3's field-wise `NotEqual` (amended 2026-10-26, review fold: RR1-Nm-2): 11,
12, 0, 11, 12, 13, 1, 21, 22, 1, 1, 10. On PR 59's install the program fails
exactly at the five generic calls whose requirement is a tuple's (`cannot
convert type ... into type implementing Core.Eq`, `Core.Ordered`, `Core.Copy`),
and nowhere else (M-11).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: tuple/array library parts
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   11
//   12
//   0
//   11
//   12
//   13
//   1
//   21
//   22
//   1
//   1
//   10
//
// The prelude's tuple impls are found through a generic function's
// requirement, where the tuple is a specific's type argument. Counted's
// `Equal` prints 10 plus its field and its `NotEqual` prints 20 plus its
// field; the tuple impl's `Equal` calls each element's `Equal` once, in
// order, stopping at the first element that differs, and its `NotEqual`
// calls each element's `NotEqual`, stopping at the first that is true
// (tuples compare field-wise with `==` and `!=`, docs/design/tuples.md,
// "Operations performed field-wise"): Same(a, b) compares the first two
// elements, printing 11 and 12, and is false (0); Same(a, a) compares all
// three, printing 11, 12 and 13, and is true (1); Differ(a, b) prints 21
// (the first elements are not not-equal) and 22, and is true (1). Less through
// `Core.Ordered` is true for (1, 2) < (1, 3) (1), and Copies through
// `Core.Copy` copies a 4-tuple whose last element is 10.

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

fn Differ[T: Core.Eq](x: T, y: T) -> bool {
  return x != y;
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
  Show(Differ(a, b));
  Show(Less((1 as i32, 2 as i32), (1 as i32, 3 as i32)));
  Core.Print(Copies((7 as i32, 8 as i32, 9 as i32, 10 as i32)).3);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.10 `generics/variadics_strcat.carbon`

Added by rev 2 as W-212's arbiter (amended 2026-10-22, review fold: B-M3).
EXPECT, derived in the header: 4, 3, 41107, 0, 0; the rev 2 prototype prints
exactly these (`$F/r3/probes_rank.txt`). Its `StrCat` is the design's text
(variadics.md :252-259) with Core's missing names declared locally; R27's
spelling diff against the design:

<!-- google-doc-style-ignore -->

```diff
--- docs/design/variadics.md :252-259
+++ fork/conformance/programs/generics/variadics_strcat.carbon
@@ -1,7 +1,7 @@
-fn StrCat[... each T: ConvertibleToString](... each param: each T) -> String {
+fn StrCat[... each T: ConvertibleToString](... each param: each T) -> Str {
   var len: i64 = 0;
   ... len += each param.Length();
-  var result: String = "";
+  var result: Str = {.reserved = 0, .appended = 0, .code = 0};
   result.Reserve(len);
   ... result.Append(each param.ToString());
   return result;
```

<!-- google-doc-style-resume -->

The return type and the initializer are the local `Str`'s, because Core's
`String` on this branch has no `Reserve` or `Append` (p01: "name
`ConvertibleToString` not found", and no such members); `ToString` returns an
`i64` because a class- or struct-typed result is a temporary that each
iteration would have to destroy, VA-1's `pack expansion element that needs a
cleanup` (W-220; x01 with a class, x13 with a struct), so StrCat over a
`String`-typed `ToString` is W-220's arbiter.

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   3
//   41107
//   0
//   0
//
// The design's StrCat (docs/design/variadics.md, "Additional examples"), its
// body as the design spells it. Core has no `ConvertibleToString` and its
// `String` has no `Reserve` or `Append`, so this program declares the
// interface and a class `Str` with those two methods for `String`; and
// `ToString` returns a one-character code as an `i64`, because a class or
// struct result is a temporary that each iteration would have to destroy,
// which statement expansions do not do yet. StrCat(4 as i32, true, 7 as i32)
// reserves the sum of the lengths, 1 + 2 + 1 = 4, and appends three codes in
// order, 4, 11 and 7, each shifting the code two digits: 41107. StrCat() of
// no arguments reserves 0 and appends nothing.

import Core library "io";

class Str {
  var reserved: i64;
  var appended: i64;
  var code: i64;
  fn Reserve(ref self, n: i64) { self.reserved = n; }
  fn Append(ref self, c: i64) {
    self.code = self.code * 100 + c;
    self.appended = self.appended + 1;
  }
}

impl Str as Core.Copy {
  fn Op(self) -> Self {
    return {.reserved = self.reserved, .appended = self.appended,
            .code = self.code};
  }
}

interface ConvertibleToString {
  fn Length(self) -> i64;
  fn ToString(self) -> i64;
}

impl i32 as ConvertibleToString {
  fn Length(unused self) -> i64 { return 1; }
  fn ToString(self) -> i64 { return self as i64; }
}

impl bool as ConvertibleToString {
  fn Length(unused self) -> i64 { return 2; }
  fn ToString(self) -> i64 {
    if (self) {
      return 11;
    }
    return 10;
  }
}

fn StrCat[... each T: ConvertibleToString](... each param: each T) -> Str {
  var len: i64 = 0;
  ... len += each param.Length();
  var result: Str = {.reserved = 0, .appended = 0, .code = 0};
  result.Reserve(len);
  ... result.Append(each param.ToString());
  return result;
}

fn Run() -> i32 {
  let s: Str = StrCat(4 as i32, true, 7 as i32);
  Core.Print(s.reserved as i32);
  Core.Print(s.appended as i32);
  Core.Print(s.code as i32);
  let e: Str = StrCat();
  Core.Print(e.reserved as i32);
  Core.Print(e.appended as i32);
  return 0;
}
```

<!-- google-doc-style-resume -->

### §A.11 Golden sources (AUTOUPDATE, no CHECK lines; R15, R16(a))

Each file is written by the commit named, verbatim, and filled only by
autoupdate; `fail_todo_va2.carbon` is written by C1 with its first fourteen
splits and its `traits.h` (rev 3 said eight, which its own ninth split had
already made stale, and rev 4 adds five; amended 2026-10-26, review fold:
RR2-M1 / RR2-m1 / RR2-m2), and C2 and C3 append theirs (three and two) before
their fills. Every
split of rev 1 was parsed by the planner with PR 59's install (`carbon compile
--phase=parse` on each split as its own file: 52 splits, all parse), and every
split rev 2 adds by the fixer the same way (21 more, all parse, `$F/r3/splits`);
the rev 2 splits that need only the rev 2 prototype were compiled on it, with
the outcomes §4 quotes as measured (amended 2026-10-22, review fold: A-B-1 /
A-B-2 / A-B-3 / A-M-1 / B-B2 / B-m4). The refills of VA-1's goldens change no
source except fail_todo_slice.carbon, whose `fail_todo_generic_pack` split is
deleted by C1 (its source is `generic_pack.carbon`'s `declaration` split).
Rev 1's splits were parsed, not compiled, and four of C1's (`hetero_pack`'s
`type_pack`, `forward` and `method`, `generic_pack`'s `call`) and three of C2's
(`tuple_segment`'s `param`, `tuple_value` and `elements_around_segment`) called
a generic function that has only a declaration, which upstream rejects with `use
of undefined generic function` (M-21). Since rev 7 each of those functions has
the empty definition `{}`, its parameters `unused`, as VA-1's goldens give a
callee, and every C1 split has been compiled and filled on C1 (M-21) (amended
2026-10-26, implementation: stop-and-amend: C1's split and golden sources).

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
fn Count[... each T: type](... unused each x: each T) {}
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

fn ForEach[... each T: Code](... unused each x: each T) {}

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
  fn F[... each T: Code](unused self, ... unused each x: each T) {}
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

// --- template_outer.carbon
library "[[@TEST_NAME]]";

interface HasV {
  fn V(self) -> i64;
}

class G {
  var n: i64;
}

impl i64 as HasV {
  fn V(self) -> i64 { return self; }
}

impl bool as HasV {
  fn V(unused self) -> i64 { return 10; }
}

fn Consume(n: i64, v: i64);

//@dump-sem-ir-begin
fn F[template U: type, ... each T: HasV](u: U, ... each x: each T) {
  ... Consume(u.n, each x.V());
}
//@dump-sem-ir-end

fn Call(g: G) {
  F(g, 1 as i64, true);
}

// --- traits.h

template<typename T> struct Traits {
  static constexpr int size = sizeof(T);
};

// --- cpp_template_outer.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn One[V: type](unused v: V) -> i32 { return 1; }

fn Consume(n: i32, m: i32);

//@dump-sem-ir-begin
fn F[U: type, ... each T: type](unused u: U, ... each x: each T) {
  ... Consume(Cpp.Traits(U).size, One(each x));
}
//@dump-sem-ir-end

fn Call() {
  F(1 as i64, true, 2 as i32);
}
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

fn F[... each T: type](... unused each x: each T) {}

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

// --- fail_todo_class_pack.carbon
library "[[@TEST_NAME]]";

class Tup(... each T: type) {}

// --- fail_todo_interface_pack.carbon
library "[[@TEST_NAME]]";

interface I(... each T: type) {}

// --- fail_todo_explicit_generic_pack.carbon
library "[[@TEST_NAME]]";

fn Count(... generic each T: type) -> i64;

// --- fail_todo_each_auto.carbon
library "[[@TEST_NAME]]";

fn F(... each x: auto);

// --- fail_todo_two_arities.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each n: i64);

// --- fail_todo_forward_hetero_to_homo.carbon
library "[[@TEST_NAME]]";

fn H(... each y: i64);

fn F[... each T: Core.ImplicitAs(i64)](... each x: each T) {
  H(... each x);
}

// --- fail_todo_expansion_without_each_name.carbon
library "[[@TEST_NAME]]";

fn F(t: (... i64));

// --- fail_todo_overload_hetero_member.carbon
library "[[@TEST_NAME]]";

overload fn G(unused b: bool) {}
overload fn G[... each T: type](... unused each x: each T) {}

fn Call() {
  G(1 as i64, true);
}

// --- traits.h

template<typename T> struct Traits {
  static constexpr int size = sizeof(T);
};

// --- fail_todo_cpp_template_on_hetero_element.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn Consume(x: i32);

fn F[... each T: type](... unused each x: each T) {
  ... Consume(Cpp.Traits(each T).size);
}

// --- fail_todo_cpp_template_on_tuple_of_pack.carbon
library "[[@TEST_NAME]]";

import Cpp library "traits.h";

fn F[... each T: type](... unused each x: each T) -> i32 {
  return Cpp.Traits((... each T)).size;
}

fn Call() {
  F(1 as i32, 2 as i64, true);
}

// --- fail_todo_template_action_on_hetero_element.carbon
library "[[@TEST_NAME]]";

fn F[template U: type, ... each T: type](u: U, ... each x: each T) {
  ... u.Get(each x);
}

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

// --- fail_todo_enclosing_arity.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 0; }
  fn Extra(... unused each n: i64) -> i64 { return 0; }
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

// --- lib.carbon
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

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn One[V: type](unused v: V) -> i64 { return 1; }

fn Count[... each T: type](... each x: each T) -> i64 {
  var n: i64 = 0;
  ... n = Add(n, One(each x));
  return n;
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call(a: A, b: B) -> i64 {
  ForEach(a, b, a);
  return Count(1 as i64, true, 2 as i32);
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
fn F[... each T: type](unused t: (... each T)) {}
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

fn Take[... each U: type](unused t: (... each U)) {}

//@dump-sem-ir-begin
fn Pass[... each T: type](... each x: each T) {
  Take((... each x));
}
//@dump-sem-ir-end

// --- elements_around_segment.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](unused t: (i64, ... each T, bool)) {}

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

// --- rank.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [T: type] T as Count {
  fn N(unused self) -> i64 { return 1; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [T: type, U: type] (T, U) as Count {
  fn N(unused self) -> i64 { return 3; }
}

fn Call(x: i64, p: (i64, bool), t: (i64, bool, i64), e: ()) -> i64 {
  return x.(Count.N)() + p.(Count.N)() + t.(Count.N)() + e.(Count.N)();
}

// --- rank_reversed.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [T: type, U: type] (T, U) as Count {
  fn N(unused self) -> i64 { return 3; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [T: type] T as Count {
  fn N(unused self) -> i64 { return 1; }
}

fn Call(x: i64, p: (i64, bool), t: (i64, bool, i64), e: ()) -> i64 {
  return x.(Count.N)() + p.(Count.N)() + t.(Count.N)() + e.(Count.N)();
}

// --- rank_elements_after.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T, bool) as Count {
  fn N(unused self) -> i64 { return 1; }
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

fn Call(a: (i64, bool), b: (bool, i64), c: (bool,)) -> i64 {
  return a.(Count.N)() + b.(Count.N)() + c.(Count.N)();
}

// --- rank_elements_after_reversed.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 2; }
}

impl forall [... each T: type] (... each T, bool) as Count {
  fn N(unused self) -> i64 { return 1; }
}

fn Call(a: (i64, bool), b: (bool, i64), c: (bool,)) -> i64 {
  return a.(Count.N)() + b.(Count.N)() + c.(Count.N)();
}

// --- body_expansion.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

//@dump-sem-ir-begin
impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}
//@dump-sem-ir-end

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
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

// --- fail_same_type_structure.carbon
library "[[@TEST_NAME]]";

interface Count {
  fn N(self) -> i64;
}

impl forall [... each T: type] (... each T) as Count {
  fn N(unused self) -> i64 { return 1; }
}

impl forall [... each U: type] (... each U) as Count {
  fn N(unused self) -> i64 { return 2; }
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

// --- self_return.carbon
library "[[@TEST_NAME]]";

interface Cp {
  fn Op(self) -> Self;
}

fn Make[T: type](x: T) -> T {
  return Make(x);
}

impl forall [... each T: type] (... each T) as Cp {
  fn Op(self) -> Self { return Make(self); }
}

fn Call(t: (i64, i64, i64, i64)) -> (i64, i64, i64, i64) {
  return t.(Cp.Op)();
}

// --- impl_body.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
}

// --- impl_lib.carbon
library "[[@TEST_NAME]]";

interface HasN {
  let N: i64;
}
impl i64 as HasN where .N = 3 {}
impl bool as HasN where .N = 40 {}

interface Sum {
  fn Get(self) -> i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

impl forall [... each T: HasN] (... each T) as Sum {
  fn Get(unused self) -> i64 {
    var s: i64 = 0;
    ... s = Add(s, (each T).N);
    return s;
  }
}

// --- impl_use.carbon
library "[[@TEST_NAME]]";

import library "impl_lib";

fn Call(t: (i64, bool, i64)) -> i64 {
  return t.(Sum.Get)();
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

toolchain/lower/testdata/tuple/nested_constant.carbon (C0; amended
2026-10-22, review fold: A-B-3), on min_prelude's int.carbon like its
neighbors in that directory; its splits are reviewer A's r16, r16g and r16h and
the fixer's x07 (M-12), and since rev 5 C0b's `return` and `one_element`, v04's
and a01's shapes (M-20) (amended 2026-10-26, implementation: stop-and-amend:
nested constant initialization):

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/tuple/nested_constant.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/tuple/nested_constant.carbon

// --- tuple.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let n: ((i32, i32), i32) = ((1, 2), 3);
  return n.0.1;
}

// --- pass.carbon
library "[[@TEST_NAME]]";

fn Take(unused t: ((i32, i32), i32)) {}

fn Call() {
  let n: ((i32, i32), i32) = ((1, 2), 3);
  Take(n);
}

// --- var.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  var v: ((i32, i32), i32) = ((4, 5), 6);
  return v.0.0;
}

// --- struct.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let s: {.a: {.b: i32, .c: i32}, .d: i32} = {.a = {.b = 1, .c = 2}, .d = 3};
  return s.a.c;
}

// --- struct_of_tuple.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  let m: {.t: (i32, i32), .u: i32} = {.t = (4, 5), .u = 6};
  return m.t.1;
}

// --- return.carbon
library "[[@TEST_NAME]]";

fn Make() -> ((i32, i32), i32) {
  return ((4, 5), 6);
}

// --- one_element.carbon
library "[[@TEST_NAME]]";

fn Read() -> i32 {
  var v: ((i32, i32),) = ((1, 2),);
  return v.0.1;
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/variadics/prelude_tuple_impls.carbon (C4; amended
2026-10-22, review fold: B-m4), on the production prelude:

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/prelude_tuple_impls.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/prelude_tuple_impls.carbon

// --- copy.carbon
library "[[@TEST_NAME]]";

fn Dup[T: Core.Copy](x: T) -> T { return x.(Core.Copy.Op)(); }

fn Call() -> (i32, i32, i32, i32) {
  //@dump-sem-ir-begin
  return Dup((1 as i32, 2 as i32, 3 as i32, 4 as i32));
  //@dump-sem-ir-end
}

// --- eq.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  //@dump-sem-ir-begin
  return a == b;
  //@dump-sem-ir-end
}

// --- ordered.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  //@dump-sem-ir-begin
  return a < b;
  //@dump-sem-ir-end
}
```

<!-- google-doc-style-resume -->

toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon (C4; amended
2026-10-22, review fold: B-m4), on the production prelude:

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon

// --- copy_op.carbon
library "[[@TEST_NAME]]";

fn Call(t: (i32, i32, i32, i32)) -> (i32, i32, i32, i32) {
  return t.(Core.Copy.Op)();
}

// --- eq.carbon
library "[[@TEST_NAME]]";

fn Call(a: (i32, i64), b: (i32, i64)) -> bool {
  return a == b;
}
```

<!-- google-doc-style-resume -->

toolchain/check/testdata/interop/cpp/template/fail_todo_cpp_call_on_hetero_element.carbon
(S-CT, land time, after M; amended 2026-10-26, review fold: RR1-B-M5):

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/template/fail_todo_cpp_call_on_hetero_element.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/template/fail_todo_cpp_call_on_hetero_element.carbon

// --- templates.h

template<typename T> void Add(T x);
template<typename T> int SizeOfFn() { return sizeof(T); }

// --- fail_todo_value_arg.carbon
library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn F[... each T: type](... each x: each T) {
  ... Cpp.Add(each x);
}

// --- fail_todo_type_arg.carbon
library "[[@TEST_NAME]]";

import Cpp library "templates.h";

fn Consume(x: i32);

fn F[... each T: type](... unused each x: each T) {
  ... Consume(Cpp.SizeOfFn(each T));
}

// --- fail_todo_facet_type_arg.carbon
library "[[@TEST_NAME]]";

import Cpp library "templates.h";

interface I {}

fn Consume(x: i32);

fn F[... each T: I](... unused each x: each T) {
  ... Consume(Cpp.SizeOfFn(each T));
}
```

<!-- google-doc-style-resume -->

### §A.12 Records, verbatim but for `<...>` fields

Commit R writes the two rows of fork/gap-analysis.md (lines 59 and 80 on this
branch; records refer to rows by bullet text, R7); commit D writes the rest.
`<date>` is the UTC date of the commit (`date -u +%F`), `<run>` the container
run's scoreboard time and log path, `<counts>` its totals, and `<C0>` to `<F4>`
(`<C0b>` among them since rev 5 (amended 2026-10-26, implementation:
stop-and-amend: nested constant initialization)), `<fixes>` and `<R>` the
commits' short hashes. Rev 2 rewrites W-212's title
and notes, keeps W-213 open with a note instead of replacing it, lists every
open form with its id in both rows, adds W-335 to W-339 and the notes of
W-213, W-215, W-220, W-223, W-224, W-226 and W-230, and places the
decision-log entry after VA-1's (amended 2026-10-22, review fold: B-B1 / B-M3
/ B-M7 / B-M8 / B-m3).

Row "Generics: Definition-checked variadics" (replaces line 59):

<!-- google-doc-style-ignore -->

```text
| Generics: Definition-checked variadics | PARTIAL | Slice 1 landed by VA-1 (fork/variadics/plan.md) and slice 2 by VA-2 (fork/variadics/va2-plan.md; W-013 stays open), EXPECTED, not of record: `...` (upstream's 2ec4bab59, cherry-picked) and `each` lex and parse; a function may take one pack `... each x: T` of one element type or, with a compile-time pack `[... each T: I]` in its implicit parameter list, a pack `... each x: each T` of different types, binding its arguments' values without copying them, expand them in expression statements and `if` statements and pass them on as call arguments (`... e`, evaluated where written); a tuple type of one pack segment, `(... each T)`, is a parameter, return or impl self type, `(... each x)` is a tuple, and `let (... each x: each T) = t;` binds a tuple's elements; the arity and the pack of types are deduced at each call, the body is checked once against the element type or the symbolic `each T`, and each specific is lowered once per element with that element's types and callees; a variadic impl is selected for tuples of every arity and ranked beside blanket and fixed-arity impls by the overlap rule. generics/variadics_each.carbon and fourteen more programs PASS in the container run <run> (<counts>). Not yet: two pack arities in one generic, a second implicit-list pack, and class and interface parameter packs (W-222); element types computed from an each-name (W-330); tuples of several segments (W-222) and segments merged with other elements or arguments, default values beside a pack (W-215); the design's Zip, Apply and TupleConcat (W-213); `let` expansions of deduced arity and pack patterns in `var`, `match` and nested tuple patterns (W-214); `...and` and `...or` (W-216); `...expand` (W-217); declarations, loops, `break`, `continue` and `match` in expansions (W-218); control flow inside expression bodies (W-219); per-element cleanups (W-220); `ref`, `var` and phase-qualified each-names (W-221); variadic overload-set members (W-223); packs in templates and C++ calls on elements of packs of different types (W-224); a variadic `Core.Call` (W-226); C++ variadic templates (W-227) and export (W-228); variadic interface functions (W-229); a pack's bare name (W-230); initializing expansion elements in tuple literals (W-331); `each x: auto` (W-333); forwarding between packs of different types and packs of one type (W-336); expansions without each-names in a binding's type (W-337); the termination rule of impl selection (W-332). |
```

<!-- google-doc-style-resume -->

Row "Stdlib: tuple/array library parts" (replaces line 80):

<!-- google-doc-style-ignore -->

```text
| Stdlib: tuple/array library parts | PARTIAL | array Iterate impl works; tuple `Copy` is one variadic impl for every arity (core/prelude/copy.carbon), and tuples compare with `==`, `!=` and lexicographic `<`, `<=`, `>`, `>=` when their element types do (core/prelude/operators/comparison.carbon), by VA-2 (fork/variadics/va2-plan.md), EXPECTED, not of record: stdlib/tuple_copy_variadic.carbon, tuple_eq_diff.carbon, tuple_ordered_diff.carbon and tuple_impl_generic.carbon PASS in the container run <run>. Not yet: comparisons between tuples that convert one operand (W-334); the comparison of tuples whose elements' orderings are not total, which VA-2 reads as `std::tuple` does where the design leaves it open (W-339). |
```

<!-- google-doc-style-resume -->

fork/inventory/work-items.json, commit D: W-212 and W-225 are replaced by
these entries; W-213, W-214, W-215, W-218, W-219, W-220, W-221, W-222, W-223,
W-224, W-226, W-229, W-230 and W-013 gain the sentences below at the end of
their `notes`; W-330 to W-339 are appended after W-230, in id order. The file's
`source` string gains "Updated <date> by the VA-2 discharge: W-212 and W-225
discharged; W-213, W-214, W-215, W-218, W-219, W-220, W-221, W-222, W-223,
W-224, W-226, W-229, W-230 and W-013 noted; W-330 to W-339 added, W-335 as
discharged."

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-212",
  "kind": "implemented",
  "title": "VA-2 (LANDED <date>): VA-1 residue: generic and heterogeneous packs (`[... each T: type]`, `... each x: each T`); `each x: auto` moved to W-333, multi-segment checking to W-215 and W-222",
  "subsystem": "toolchain/check + toolchain/lower",
  "size": "XL",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "toolchain/check/testdata/variadics/hetero_pack.carbon, fail_hetero_pack.carbon, generic_pack.carbon and toolchain/lower/testdata/variadics/hetero_pack.carbon (new in <C1>, filled in <F1>)",
    "fork/conformance/programs/generics/variadics_strcat.carbon (the design's StrCat over locally declared names), variadics_hetero_digits_diff.carbon (+ .diff.cpp), variadics_hetero_forward.carbon, variadics_hetero_empty.carbon: PASS in the container run <run>, expected, not of record",
    "fork/variadics/va2-plan.md D-VA2-2 to D-VA2-7, §A.10"
  ],
  "blocked_by": [],
  "notes": "DISCHARGED (fork/variadics/va2-plan.md, VA-2, <date>; branch claude/carbon-fork-0-1-va2 stacked on PR 59; <C0> to <C5>, fills <F0> to <F4>, fix commits <fixes>, R <R>, then D; decision-log \"VA-2: definition-checked variadics, slice 2 (<date>)\"). A function or impl declares one compile-time pack `[... each T: I]` in its implicit parameter list and takes `... each x: each T`; each call deduces the pack of argument types and its arity and checks each element's `I`; the body is checked once with `each x` of the symbolic type `each T` and lowered once per element; a generic has one pack arity, and a second is a semantics TODO (W-222). Break condition met with a substitution: StrCat compiles and runs as fork/conformance/programs/generics/variadics_strcat.carbon, the design's text (variadics.md :252-259) with Core's missing names declared locally (`ConvertibleToString`, and a class `Str` for `String`, whose `Reserve` and `Append` Core lacks on this branch) and `ToString` returning an `i64`, because a class- or struct-typed result needs per-element cleanups (W-220, whose arbiter StrCat over `String` now is). Moved: `each x: auto` to W-333 (blocked on `auto` parameters), computed element types to W-330, multi-segment checking to W-215 (merging) and W-222 (several segments and arities), a second implicit-list pack and a second arity to W-222, forwarding between packs of different types and packs of one type to W-336, p002274's variadic indexing interfaces to W-229's note. Follows VA-1 slice 1."
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
    "toolchain/check/testdata/variadics/prelude_tuple_impls.carbon and toolchain/lower/testdata/variadics/prelude_tuple_impls.carbon (new in <C4>, filled in <F4>); toolchain/check/testdata/variadics/impl.carbon's `rank` splits",
    "fork/conformance/programs/stdlib/tuple_copy_variadic.carbon, tuple_eq_diff.carbon (+ .diff.cpp), tuple_ordered_diff.carbon (+ .diff.cpp), tuple_impl_generic.carbon and generics/variadics_min.carbon: PASS in the container run <run>, expected, not of record",
    "fork/variadics/va2-plan.md D-VA2-8, D-VA2-10 to D-VA2-12"
  ],
  "blocked_by": [],
  "notes": "DISCHARGED (fork/variadics/va2-plan.md, VA-2, <date>; commits as W-212's). Break condition met: the four hand-written impls are replaced, and a 4-tuple, a 5-tuple and a 13-tuple satisfy `Core.Copy`, each element copied once by its own `Copy`; tuples whose element types are `Eq` or `Ordered` compare field-wise with the elements' `==` and `!=` and lexicographically with the elements' `<`. Impl lookup's type structure keeps the tuple, `(...?)`, and ranks impls by the overlap rule along the query (a `?` above a segment covering the same element, W-338). Impl selection terminates because each impl's requirements are on strict subterms of its self type; p002687's termination rule is W-332. Remaining: comparisons that convert one operand, W-334; orderings that are not total, W-339. Follows VA-1 slice 1."
}
```

<!-- google-doc-style-resume -->

Sentences appended to `notes` (each preceded by a space):

<!-- google-doc-style-ignore -->

```text
W-213: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-8, D-VA2-9): NARROWED, not discharged. Tuples of one pack segment are done: `(... each T)` is a parameter, return and impl self type, flattened once its arity is known, deduced from a tuple argument (with elements before and after the segment), represented as the specific's until then, and `(... each x)` initializes a tuple element by element and is a value of the tuple type, so the break condition's form runs (fork/conformance/programs/generics/variadics_tuple_param.carbon). The arbiters do not yet: Zip's signature needs W-330 and its body W-216; Apply needs W-226 (`F: Call(... each T)`), W-217 and `-> auto` (upstream's bf5d2a2ac, with the next advance); TupleConcat needs W-222 (a second implicit-list pack and a tuple of two segments) and W-217. Close this item when they check.
W-214: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-9): `let (... each x: each T) = t;` of fixed arity binds a pack; only `var`, `match` and nested tuple patterns, and a `let` expansion of deduced arity (`pack expansion pattern with deduced arity outside a parameter list`), remain. V-3a register entry (iv): VA-2 reads variadics.md :219-221's "a deduced parameter of the enclosing pattern" as including an enclosing declaration's pattern, as :532-546's fixed-arity example requires; re-read both at each weekly upstream check.
W-215: VA-2 (<date>): upstream's 503f09037 adds default values for non-generic parameters of generic functions, which defaults beside a pack follow when this item is taken; multi-segment checking from W-212's title is this item's merging half.
W-218: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-11): statement expansions whose body is an `if` statement, with `else if`, `else` and `return`, are checked and lowered; only declarations, `while`, `for`, `break`, `continue` and `match` in a body remain (`pack expansion of a statement other than an expression or if statement`).
W-219: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-11): control flow at the statement level (`... if`) is implemented; only control flow inside an expression body and the "Type versus execution semantics" example remain.
W-220: VA-2 (<date>): the design's StrCat with a `String`-typed `ToString` is this item's arbiter: its `... result.Append(each param.ToString());` destroys a temporary per element (fork/variadics/va2-plan.md M-16, x01).
W-221: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-4): an explicit `generic` each-name is `semantics TODO: each-name binding of a class, interface or explicit compile-time parameter`, a text it shares with W-222's class and interface parameter packs (`fail_todo_explicit_generic_pack`); the `ref`, `var` and `template` forms are `semantics TODO: each-name binding that is ref, var or template`.
W-222: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-4): every pack of a function or impl shares one deduced arity, and a second arity in a generic or an enclosing one is `semantics TODO: more than one pack arity in a generic`; only independent arities (including that second arity and a second implicit-list pack, `more than one pack expansion pattern in an implicit parameter list`), tuples of more than one segment and class and interface parameter packs remain, the last `semantics TODO: each-name binding of a class, interface or explicit compile-time parameter` (`fail_todo_class_pack`, `fail_todo_interface_pack`).
W-223: VA-2 (<date>): a member of an overload set with a pack of different types, and such a pack forwarded to an overload set, are this item's TODOs too (fork/variadics/va2-plan.md M-16, x16, x17); OV-1's `GetExplicitArityRange` is not reached with a pack.
W-224: VA-2 (<date>, fork/variadics/va2-plan.md D-VA2-14): a C++ call, a C++ class template or a template-dependent action whose operand depends on an element of a pack of different types is `semantics TODO: C++ or template-dependent action on an element of a pack of different types`, refused by C1 at `AddDependentActionInst` for upstream's templates (`fail_todo_template_action_on_hetero_element`) and C++ templates (`fail_todo_cpp_template_on_hetero_element`) and, after the land-time merge, for CT-1's deferred calls (S-CT's splits); this item resolves deferred actions once per iteration.
W-226: VA-2 (<date>): the design's Apply (`F: Call(... each T)`, variadics.md :275) is this item's arbiter, with W-213.
W-229: VA-2 (<date>): p002274's variadic indexing interfaces (:250-257), named by W-212's note, are deferred by that proposal "once we have a design for variadics" as an alternative, not a rule, and need packs in interface functions; they are tracked here.
W-230: VA-2 (<date>): V-3a register entry (iii): a pack's bare name has no meaning in the design (p002240 "Omit each-names", :555, an alternative not adopted); re-read at each weekly upstream check, and implement the meaning or the error the design or upstream gives it.
W-013: VA-2 slice 2 (<date>, fork/variadics/va2-plan.md): packs of different types in implicit parameter lists, tuples with one pack segment, `let` pack bindings, statement expansions of `if`, variadic impls, and the prelude's tuple `Copy`, `EqWith` and `OrderedWith` as variadic impls (W-212 and W-225 discharged, W-213 narrowed; W-330 to W-339 filed). Next: W-330 (computed element types), W-222 (several packs), W-217 (`...expand`).
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
    "toolchain/check/impl_lookup.cpp:183-194 (\"TODO: Implement the termination rule\"); the same TODO upstream at 57ba07a97, :199",
    "fork/variadics/va2-plan.md M-2; reviewer A's r08c, a cycle of impls that hangs on PR 59, the nightly and the VA-2 prototype alike"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11, D-VA2-10). An accepted design that neither toolchain implements, not an open question. Impl lookup implements only the acyclic rule, upstream as in the fork; VA-2's variadic impls terminate because their requirements are on strict subterms of their self types. Owner: VA-2 until it lands, then the next impl-lookup workstream, named in ORCHESTRATION's Next actions; take upstream's implementation at the advance if it lands first. Break condition: an impl whose requirement is on a type not smaller than its self type is rejected by the rule."
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
    "docs/design/variadics.md :732-734 (\"The type of `each x: auto` is `each __X`\"); DR-40",
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
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11, §1.12 (ii)). V-3a register entry (ii), a narrowing, owner the next variadics slice with W-222. VA-2's tuple impls are `EqWith(Self)` and `OrderedWith(Self)`; the design's conversions need `EqWith((... each U))` over a second pack of the same arity and a per-element conversion requirement. Break condition: p23 compiles and prints 1. Follows VA-2 slice 2."
}
```

```json
{
  "id": "W-335",
  "kind": "implemented",
  "title": "VA-2 (LANDED <date>): nested aggregate constants lowered with their object representation where their value representation is elementwise (`let t: ((i32, i32), i32) = ((1, 2), 3);`)",
  "subsystem": "toolchain/lower",
  "size": "S",
  "bullet": "Stdlib: tuple/array library parts",
  "evidence": [
    "toolchain/lower/file_context.cpp `GetConstant` (<C0>, <C0b>); upstream's `GetConstant` at 57ba07a97 has the same defect",
    "toolchain/lower/function_context.cpp `CopyValue` (<C0b>); upstream's `CopyValue` at 8779d15e1 has the same two arms",
    "toolchain/lower/testdata/tuple/nested_constant.carbon (new in <C0>, splits added in <C0b>, filled in <F0>)",
    "fork/variadics/va2-plan.md M-20: on <C0> alone `var v: ((i32, i32), i32) = ((4, 5), 6);` copied the inner tuple's address into `v.0` and `var v: ((i32, i32),) = ((1, 2),);` aborted in `StoreObject`; on <C0b> both run",
    "fork/variadics/va2-plan.md M-12: \"Global variable initializer type does not match global variable type!\" on PR 59, trunk and the nightly 2026.10.12 before <C0>"
  ],
  "blocked_by": [],
  "notes": "Filed and DISCHARGED at the VA-2 discharge (fork/variadics/va2-plan.md §2.7). A constant tuple or struct value whose value holds an inner aggregate's value by pointer was given a global initialized with its object representation; the elementwise value representation is now built from the elements' constants, and a copy of such a constant into storage copies it element by element. Keep the hunks at the next upstream advance unless upstream fixes `GetConstant` and `CopyValue` itself, and then take upstream's."
}
```

```json
{
  "id": "W-336",
  "kind": "missing-feature",
  "title": "VA-2 residue: forwarding between a pack of different types and a pack of one type (`H(... each x)` with `each x: each T` and `fn H(... each y: i64)`)",
  "subsystem": "toolchain/check + toolchain/lower",
  "size": "M",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "docs/design/variadics.md \"Expansion convertibility\" (:835-837); DR-41",
    "toolchain/check/testdata/variadics/fail_todo_va2.carbon split `fail_todo_forward_hetero_to_homo` (`semantics TODO: forwarding a pack of different types to a pack of one type, or the reverse`)"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11). Converting `⟬each T⟭` to `«E; N»` element by element at each iteration's types. Break condition: the split checks and converts each element by its own type's conversion. Follows VA-2 slice 2."
}
```

```json
{
  "id": "W-337",
  "kind": "missing-feature",
  "title": "VA-2 residue: an expansion without each-names in a binding's type position (`fn F(t: (... i64))`)",
  "subsystem": "toolchain/check",
  "size": "M",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "docs/design/variadics.md :147-150 (\"If an expansion contains no each-names, it must be a pattern, or an expression in the type position of a binding pattern, and its arity is deduced from the scrutinee\"); DR-17",
    "toolchain/check/testdata/variadics/fail_todo_va2.carbon split `fail_todo_expansion_without_each_name` (`semantics TODO: pack expansion without an each-name in a binding's type`)"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.11). VA-1 diagnosed this design-valid form with the error `pack expansion does not use any each-name` and labeled it W-212; VA-2 made it a TODO. Break condition: `fn F(t: (... i64))` checks and deduces its arity from a tuple argument. Follows VA-2 slice 2."
}
```

```json
{
  "id": "W-338",
  "kind": "design-needed",
  "title": "VA-2 V-3a register entry (v): how a pack segment ranks against a `?` in impl lookup's overlap rule",
  "subsystem": "toolchain/check",
  "size": "S",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "docs/design/generics/details.md \"Overlap rule\" (:4906-4929), which names only `?` and non-`?` entries",
    "toolchain/check/testdata/variadics/impl.carbon's `rank` splits; fork/variadics/va2-plan.md D-VA2-8, M-15"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.12 (v)). VA-2 ranks impls by the overlap rule taken along the query and reads \"the most specific choice at that difference\" as a `?` above a segment covering the same element, and a segment covering nothing just after a concrete element. A watch item: owner VA-2 until it lands, then the weekly upstream check, which re-reads the overlap rule and upstream's type_structure.cpp and opens the realignment if upstream decides otherwise."
}
```

```json
{
  "id": "W-339",
  "kind": "design-needed",
  "title": "VA-2 V-3a register entry (vi): tuple comparisons over elements whose ordering is not total or whose `Equal` and `NotEqual` are not complements",
  "subsystem": "core/prelude",
  "size": "S",
  "bullet": "Stdlib: tuple/array library parts",
  "evidence": [
    "docs/design/expressions/comparison_operators.md :311-316, :457-464 (\"There is no expectation that an `Ordered` implementation be a total order\", and its TODO); core/prelude/operators/comparison.carbon :25-27 (`Compare` TODO)",
    "fork/conformance/programs/stdlib/tuple_ordered_diff.carbon's NaN lines; fork/variadics/va2-plan.md D-VA2-12"
  ],
  "blocked_by": [],
  "notes": "Filed at the VA-2 discharge (fork/variadics/va2-plan.md §1.12 (vi)). VA-2 derives the four relations from the elements' `<` as `std::tuple` does, so a tuple of a NaN is equivalent to itself; `!=` is field-wise with the elements' `!=` (docs/design/tuples.md :108-114), so it is not part of this entry. A watch item with W-338's owner and next action, re-reading those passages."
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
TupleConcat need (W-213).
```

<!-- google-doc-style-resume -->

fork/decision-log.md, commit D, placed directly after VA-1's entry "VA-1:
definition-checked variadics, slice 1 (2026-10-14)", because the log groups
entries by workstream, not by date (DR-0's placement note; amended
2026-10-22, review fold: B-m3):

<!-- google-doc-style-ignore -->

```text
### VA-2: definition-checked variadics, slice 2 (<date>)

Context: W-212, W-213 and W-225 (VA-1's residues; gap rows "Generics:
Definition-checked variadics" and "Stdlib: tuple/array library parts", both
PARTIAL); fork/variadics/va2-plan.md, rev <n> after two plan reviews, all
folded; branch claude/carbon-fork-0-1-va2, one PR stacked on PR 59. Every
decision auto-adopted under V-2 and V-3b, which R32 states (R29(a)), and open
to veto.

Decisions (plan §1, each with its break condition): D-VA2-1 the slice;
D-VA2-2 a symbolic pack index and per-iteration values of a specific;
D-VA2-3 one pack type whose element is a type or a pack of types; D-VA2-4
`[... each T: I]` with one deduced arity per generic, a second a TODO;
D-VA2-5 to D-VA2-7 deduction, definition checking against `each T`, and
lowering per element; D-VA2-8 and D-VA2-9 tuples of one pack segment with a
dependent representation, `(...?)` in impl lookup's type structure ranked by
the overlap rule, `let` bindings and element-wise initialization; D-VA2-10
variadic impl selection, terminating by subterm requirements; D-VA2-11
statement expansions of `if`; D-VA2-12 the prelude's tuple impls; D-VA2-13
and D-VA2-14 the TODO texts, templates unchanged and C++ calls on elements
of packs of different types a land-time TODO; D-VA2-15 to D-VA2-19 goldens,
programs, records, merge position and commits, with C0's and C0b's fix of
nested aggregate constants.

Options considered (plan §7.2): a second checking path (A-1); hand-written
impls to a larger fixed arity (A-2); a pack-to-tuple shim (A-3); two packs
now (A-4); a specific per element (A-5); constant packs everywhere (A-6);
`return self;` as the tuple `Copy.Op` (A-7); `...and` for equality (A-8);
the rev 1 type-structure hole (A-9); a pack index per arity binding (A-10).

V-3 check: every mechanism is the design's (docs/design/variadics.md and
docs/design/generics/details.md at upstream's 57ba07a97), the fork's SemIR is
internal representation, and no design page is edited; rev 1's
type-structure hole was a second spelling of the design's type-structure
rule, realigned before implementation. V-3a register entries, each with its
work item: `...expand`'s typechecking is the design's TODO (W-217); tuple
comparisons convert neither operand (W-334); a pack's bare name has no
meaning yet (W-230); the fixed-arity `let` reading of :219-221 (W-214); a
segment's rank against a `?` (W-338); comparisons of orderings that are not
total (W-339).

Records: W-212 and W-225 discharged, W-213 narrowed; W-214, W-215, W-218,
W-219, W-220, W-221, W-222, W-223, W-224, W-226, W-229, W-230 and W-013 noted;
W-330 to W-339 filed, W-335 as discharged by C0 and C0b. Both rows stay
PARTIAL with narrower open text, expected, not of record, on the container run
<run>.
```

<!-- google-doc-style-resume -->

fork/ORCHESTRATION.md, commit D, appended to the paragraph that records VA-1
(and its row in the PR table updated by commit L at land time), with three
Next actions items:

<!-- google-doc-style-ignore -->

```text
VA-2 (claude/carbon-fork-0-1-va2, stacked on PR 59, fork/variadics/va2-plan.md)
implements packs of different types, tuples with one pack segment, statement
expansions of `if` and variadic impls, makes the prelude's tuple Copy,
EqWith and OrderedWith single variadic impls, and fixes the lowering of
nested aggregate constants; W-212 and W-225 discharged, W-213 narrowed,
W-330 to W-339 filed (W-335 discharged); expected <counts> over <programs>
on the container run <run>. It merges last, after DR-1b, with the land-time
code commit S-CT after its merge of trunk (fork/variadics/va2-plan.md
D-VA2-18), held open.
```

```text
W-332 (p002687's termination rule): owner VA-2 until it lands, then the next
impl-lookup workstream; take upstream's implementation at each advance if
it lands first.
W-338 and W-339 (VA-2's V-3a register entries (v) and (vi)): at each weekly
upstream check, re-read generics/details.md "Overlap rule",
comparison_operators.md :311-316 and :457-464 and comparison.carbon's
Compare TODO, and upstream's type_structure.cpp; open the realignment if
upstream decides otherwise.
W-214, W-217, W-230 (VA-2's V-3a register entries (iv), (i), (iii)): at each
weekly upstream check, re-read variadics.md :219-221 with :532-546, :493 and
p002240's "Omit each-names".
```

<!-- google-doc-style-resume -->

## Appendix B. The prototype, verbatim

`$H/r/va2_prototype_rev4.patch`, the diff of the rev 4 prototype against
b0822a744 (31 files, 1399 insertions, 122 deletions; the scratch commit
ca939ee19, tree f023437c2), which §2.1 to §2.3 and §2.7 describe hunk by hunk
and C0, C1 and C2 split: the planner's rev 1 patch, M-9's correction to its
`TupleType` deduction (`if (!arg_tuple) { break; }` before the segment test,
R-4), the rev 2 corrections of §2 (amended 2026-10-22, review fold: A-B-1 /
A-B-2 / A-B-3 / A-M-1 / A-m-5 / B-m5), the rev 3 corrections
(`$G/r/rev3_fixes.patch`: the bindings read through their constant values
and the one arity in check/eval.cpp, the enclosing arity's
`specific_constant` in check/handle_pack_expansion.cpp, the refusal in
check/action.cpp and its `InitializeAction` site in check/convert.cpp)
(amended 2026-10-26, review fold: RR1-NB-1 / RR1-B-M5 / RR1-Nm-3), and the
rev 4 corrections (`$H/r/rev4_fixes.patch`: the compile-time each-name
accepted only in a function's or an impl's implicit list in
check/handle_binding_pattern.cpp, the `PackValue` case in
sem_ir/stringify.cpp, and no per-iteration evaluation of a failed specific in
check/eval.cpp, with clang-format's re-wrapping of rev 3's lines in those
files) (amended 2026-10-26, review fold: RR2-M1 / RR2-m1). The repository's
trailing-whitespace hook strips the single space of the diff's blank context
lines; `git apply` reads those empty lines as blank context lines, so this
copy applies as it stands (§2.0, F-9), which `$H/r/check_appb.sh` checks.

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/action.cpp b/toolchain/check/action.cpp
index 4c0308ef2..ac61ec4ee 100644
--- a/toolchain/check/action.cpp
+++ b/toolchain/check/action.cpp
@@ -8,6 +8,7 @@
 #include "toolchain/check/generic.h"
 #include "toolchain/check/generic_region_stack.h"
 #include "toolchain/check/inst.h"
+#include "toolchain/check/subst.h"
 #include "toolchain/check/type.h"
 #include "toolchain/sem_ir/constant.h"
 #include "toolchain/sem_ir/copy_on_write_block.h"
@@ -336,8 +337,100 @@ static auto RefineOperands(Context& context, SemIR::LocId loc_id,
   return action;
 }

+namespace {
+// Fork (VA-2, D-VA2-14): finds the pack index in a constant, without
+// substituting into it.
+class FindPackIndexCallbacks final : public SubstInstCallbacks {
+ public:
+  explicit FindPackIndexCallbacks(Context* context)
+      : SubstInstCallbacks(context) {}
+
+  auto Subst(SemIR::InstId& inst_id) -> SubstResult override {
+    if (found_ || !context().constant_values().Get(inst_id).is_symbolic()) {
+      return FullySubstituted;
+    }
+    if (context().insts().Is<SemIR::PackIndex>(inst_id)) {
+      found_ = true;
+      return FullySubstituted;
+    }
+    return SubstOperands;
+  }
+
+  auto Rebuild(SemIR::InstId orig_inst_id, SemIR::Inst /*new_inst*/)
+      -> SemIR::InstId override {
+    return orig_inst_id;
+  }
+
+  auto found() const -> bool { return found_; }
+
+ private:
+  bool found_ = false;
+};
+}  // namespace
+
+// Fork (VA-2, D-VA2-14): returns whether the value of `inst_id`, or its type,
+// depends on the pack index of an enclosing pack expansion, as an element of a
+// pack of different types does: `each T`, or `each x` of type `each T`, is a
+// different type or value in each iteration (docs/design/variadics.md,
+// "Iterative typechecking of pack expansions").
+static auto DependsOnPackIndex(Context& context, SemIR::InstId inst_id)
+    -> bool {
+  if (!inst_id.has_value()) {
+    return false;
+  }
+  auto uses_pack_index = [&](SemIR::ConstantId const_id) {
+    if (!const_id.is_symbolic()) {
+      return false;
+    }
+    FindPackIndexCallbacks callbacks(&context);
+    SubstInst(context, context.constant_values().GetInstId(const_id),
+              callbacks);
+    return callbacks.found();
+  };
+  auto type_id = context.insts().Get(inst_id).type_id();
+  return uses_pack_index(context.constant_values().Get(inst_id)) ||
+         (type_id.has_value() &&
+          uses_pack_index(context.types().GetConstantId(type_id)));
+}
+
+// Fork (VA-2, D-VA2-14): returns whether an operand of `action` depends on the
+// pack index of an enclosing pack expansion. A dependent action is performed
+// once for each specific, but such an operand differs between the
+// expansion's iterations.
+static auto ActionDependsOnPackIndex(Context& context, SemIR::Inst action)
+    -> bool {
+  if (context.pack_expansion_stack().empty()) {
+    return false;
+  }
+  auto depends = [&](SemIR::IdAndKind arg) {
+    return arg.Dispatch<bool>([&](auto id) {
+      using IdT = decltype(id);
+      if constexpr (std::derived_from<IdT, SemIR::InstId>) {
+        return DependsOnPackIndex(context, id);
+      } else if constexpr (std::derived_from<IdT, SemIR::InstBlockId>) {
+        return id.has_value() &&
+               llvm::any_of(context.inst_blocks().Get(id),
+                            [&](SemIR::InstId inst_id) {
+                              return DependsOnPackIndex(context, inst_id);
+                            });
+      } else {
+        return false;
+      }
+    });
+  };
+  return depends(action.arg0_and_kind()) || depends(action.arg1_and_kind());
+}
+
 auto AddDependentActionInst(Context& context, SemIR::LocIdAndInst action)
     -> SemIR::InstId {
+  // Fork (VA-2, D-VA2-14): an action on an element of a pack of different
+  // types would need to be performed once per iteration of the expansion.
+  if (ActionDependsOnPackIndex(context, action.inst)) {
+    context.TODO(action.loc_id,
+                 "C++ or template-dependent action on an element of a pack "
+                 "of different types");
+    return SemIR::ErrorInst::InstId;
+  }
   action.inst = RefineOperands(context, action.loc_id, action.inst);
   return AddTemplateConstantInstToEvalBlock(context, action);
 }
@@ -348,6 +441,10 @@ auto AddDependentActionSplice(Context& context, SemIR::LocIdAndInst action,
   action.inst = RefineOperands(context, action.loc_id, action.inst);

   auto inst_id = AddDependentActionInst(context, action);
+  // Fork (VA-2, D-VA2-14): the action was refused.
+  if (inst_id == SemIR::ErrorInst::InstId) {
+    return inst_id;
+  }
   return AddSpliceInst(context, inst_id, result_type_inst_id);
 }

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
index 5d6dc9141..84f0d09bc 100644
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
@@ -654,6 +657,19 @@ static auto ConvertTupleToTuple(Context& context, SemIR::TupleType src_type,
     return SemIR::ErrorInst::InstId;
   }

+  // Fork (VA-2, D-VA2-9): a tuple with a pack segment has as many elements as
+  // its segment's arity, so it is initialized by one expansion over the
+  // segment's elements, not element by element here.
+  // TODO: Initialize it with `PackSegmentInit` (fork/variadics/va2-plan.md
+  // §2.4, item 5).
+  if (target.is_initializer() &&
+      llvm::any_of(dest_elem_types, [&](SemIR::InstId elem_id) {
+        return sem_ir.insts().Is<SemIR::PackType>(elem_id);
+      })) {
+    context.TODO(value_loc_id, "initializing a tuple with a pack segment");
+    return SemIR::ErrorInst::InstId;
+  }
+
   ConversionTarget::Kind inner_kind =
       GetAggregateElementConversionTargetKind(sem_ir, target);

@@ -718,6 +734,14 @@ static auto ConvertTupleToType(Context& context, SemIR::LocId loc_id,
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
@@ -1891,6 +1915,30 @@ static auto PerformBuiltinConversion(Context& context, SemIR::LocId loc_id,
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
+        auto converted_id = Convert(context, loc_id, element_id,
+                                    {.kind = ConversionTarget::Value,
+                                     .type_id = SemIR::GetPackElementTypeId(
+                                         sem_ir, *target_pack_type, index),
+                                     .diagnose = target.diagnose});
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
@@ -2469,6 +2517,10 @@ static auto AddConvertActionIfDependent(Context& context, SemIR::LocId loc_id,
                  .storage_id = target.storage_id,
                  .in_place = SemIR::BoolValue::From(
                      target.kind == ConversionTarget::InPlaceInitializing)})});
+    // Fork (VA-2, D-VA2-14): the action was refused.
+    if (action_id == SemIR::ErrorInst::InstId) {
+      return action_id;
+    }

     // Extract the first result: this is the instruction that performs the
     // initialization and produces the result.
diff --git a/toolchain/check/deduce.cpp b/toolchain/check/deduce.cpp
index 805ba2beb..a3df57b28 100644
--- a/toolchain/check/deduce.cpp
+++ b/toolchain/check/deduce.cpp
@@ -443,10 +443,23 @@ auto DeductionContext::Deduce() -> bool {
       case CARBON_KIND(SemIR::PackType pack_type): {
         if (auto arg_pack_type =
                 context().insts().TryGetAs<SemIR::PackType>(arg_id)) {
+          // Fork (VA-2, D-VA2-5): forwarding a pack of different types to a
+          // pack of one element type, or the reverse, needs the design's
+          // "Expansion convertibility" between a pack of types and an arity
+          // coercion `«E; N»` (docs/design/variadics.md, "Reduction rules").
+          if (IsHeterogeneousPackType(context(), pack_type) !=
+              IsHeterogeneousPackType(context(), *arg_pack_type)) {
+            if (diagnose_) {
+              context().TODO(loc_id_,
+                             "forwarding a pack of different types to a pack "
+                             "of one type, or the reverse");
+            }
+            return false;
+          }
           Add(pack_type.arity_id, arg_pack_type->arity_id,
               /*want_value=*/true);
-          Add(pack_type.element_type_inst_id,
-              arg_pack_type->element_type_inst_id, /*want_value=*/true);
+          Add(pack_type.element_id, arg_pack_type->element_id,
+              /*want_value=*/true);
           continue;
         }
         auto arg_tuple_type =
@@ -463,9 +476,88 @@ auto DeductionContext::Deduce() -> bool {
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
+        if (!arg_tuple) {
+          break;
+        }
+        if (segment == param_elements.end()) {
+          // Deduce through the tuple's operands as before.
+          worklist_.AddInstArg(param_inst.arg0_and_kind(),
+                               context().insts().Get(arg_id).arg0(),
+                               want_value);
+          continue;
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
index d632afebd..4530e49f4 100644
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
@@ -3592,6 +3637,86 @@ auto TryEvalBlockForSpecific(Context& context, SemIR::LocId loc_id,
   }
 }

+auto TryEvalPackIterationsForSpecific(Context& context, SemIR::LocId loc_id,
+                                      SemIR::SpecificId specific_id) -> void {
+  auto& specific = context.specifics().Get(specific_id);
+  // A specific whose eval blocks failed was diagnosed once and is not lowered;
+  // evaluating them again per iteration would repeat its diagnostics.
+  if (specific.pack_iteration_block_id.has_value() || specific.HasError()) {
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
+  // of the generic, whose arity is one of the specific's arguments: the one
+  // pack arity of the generic (a second is diagnosed where it is declared, and
+  // adds no binding).
+  int64_t count = 0;
+  auto bindings = context.inst_blocks().Get(generic.bindings_id);
+  auto args = context.inst_blocks().Get(specific.args_id);
+  for (auto [binding_id, arg_id] : llvm::zip(bindings, args)) {
+    // The binding of a generic imported from another library is an import
+    // reference whose constant value is the binding.
+    auto binding = context.insts().TryGetAs<SemIR::SymbolicBinding>(
+        context.constant_values().GetConstantInstId(binding_id));
+    if (!binding ||
+        context.entity_names().Get(binding->entity_name_id).name_id !=
+            SemIR::NameId::PackArity) {
+      continue;
+    }
+    auto arity = context.sem_ir().GetZExtIntValue(arg_id);
+    if (!arity) {
+      // A symbolic specific is not lowered.
+      return;
+    }
+    count = static_cast<int64_t>(*arity);
+    break;
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
+        context.specifics()
+            .Get(specific_id)
+            .SetHasError(SemIR::GenericInstIndex::Definition);
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
index 8a2f4cb9a..b931ff531 100644
--- a/toolchain/check/handle_binding_pattern.cpp
+++ b/toolchain/check/handle_binding_pattern.cpp
@@ -366,12 +366,32 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
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
+    // Fork (VA-2, D-VA2-4): a compile-time pack is declared by "an implicit
+    // parameter list element of the form `...` pattern" of a function or an
+    // impl. A pack among a class's or an interface's parameters, whose
+    // expansions in the members have fixed arity, and an explicit `generic`
+    // pack are not implemented.
+    if (node_kind == Parse::NodeKind::CompileTimeBindingPattern) {
+      auto introducer_kind =
+          context.decl_introducer_state_stack().innermost().kind;
+      if (context.full_pattern_stack().CurrentKind() !=
+              FullPatternStack::Kind::ImplicitParamList ||
+          (introducer_kind != Lex::TokenKind::Fn &&
+           introducer_kind != Lex::TokenKind::Impl)) {
+        return context.TODO(name_node,
+                            "each-name binding of a class, interface or "
+                            "explicit compile-time parameter");
+      }
+    }
     if (pack_scope->each_binding_pattern_id.has_value()) {
       return context.TODO(name_node,
                           "pack expansion pattern declaring more than one "
@@ -382,15 +402,68 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
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
+    if (auto each_pack = is_error
+                             ? std::nullopt
+                             : GetEachNameTypePack(
+                                   context, type_expr.type_component_inst_id)) {
+      pack_type_id = GetPackType(context, each_pack->first, each_pack->second);
+      // The each-name's pack is a binding of this generic, whose arity binding
+      // the pack's expansions use.
+      pack_scope->arity_binding_id = each_pack->second;
+      if (auto arity =
+              context.pack_binding_arities().Lookup(each_pack->first)) {
+        pack_scope->arity_binding_id = arity.value();
+      }
+    } else {
+      // Fork (VA-2, D-VA2-4): every pack of a generic, and of the generics
+      // that enclose it, shares one deduced arity, so the pack index of a
+      // specific has one range; an expansion pattern that would add a second
+      // arity ("each pack expansion pattern introduces a deduced arity") is a
+      // TODO until packs of independent arities are implemented.
+      for (auto bind_id :
+           context.scope_stack().compile_time_binding_stack().PeekAllValues()) {
+        if (auto bind =
+                context.insts().TryGetAs<SemIR::SymbolicBinding>(bind_id);
+            bind && context.entity_names().Get(bind->entity_name_id).name_id ==
+                        SemIR::NameId::PackArity) {
+          return context.TODO(name_node,
+                              "more than one pack arity in a generic");
+        }
+      }
+      auto arity_type_id =
+          GetSingletonType(context, SemIR::IntLiteralType::TypeInstId);
+      auto arity_entity_name_id = AddBindingEntityName(
+          context, SemIR::NameId::PackArity, SemIR::TypeInstId::None,
+          SemIR::InstId::None, /*is_unused=*/false, BindingPhase::Symbolic);
+      auto arity =
+          AddBindingPattern(context, pack_scope->start_node_id,
+                            SemIR::ExprRegionId::None, arity_type_id,
+                            {.kind = SemIR::SymbolicBindingPattern::Kind,
+                             .type_id = GetPatternType(context, arity_type_id),
+                             .entity_name_id = arity_entity_name_id,
+                             .subpattern_id = SemIR::InstId::None});
+      pack_scope->arity_pattern_id = arity.pattern_id;
+      pack_scope->arity_binding_id = arity.bind_id;
+      // An invalid element type was diagnosed; the pack keeps its arity, as
+      // in VA-1, and the binding its error type.
+      pack_type_id = GetPackType(
+          context,
+          is_error ? SemIR::InstId::None : type_expr.type_component_inst_id,
+          arity.bind_id);
+    }
+    pack_scope->pack_type_id = pack_type_id;
+    if (!is_error) {
+      type_expr.type_component_id = pack_type_id;
+      type_expr.type_component_inst_id =
+          context.types().GetTypeInstId(pack_type_id);
+    }
   }

   const DeclIntroducerState& introducer =
@@ -568,7 +641,6 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
             // Record the pack for its pack expansion pattern, and for name
             // lookup of its each-name.
             pack_scope->each_binding_pattern_id = result_inst_id;
-            pack_scope->element_type_inst_id = element_type_inst_id;
             context.pack_binding_arities().Insert(context.bind_name_map()
                                                       .Lookup(result_inst_id)
                                                       .value()
@@ -583,6 +655,21 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
         case Parse::NodeKind::CompileTimeBindingPattern:
           result_inst_id =
               make_binding_pattern(SemIR::SymbolicBindingPattern::Kind);
+          if (is_each) {
+            // Fork (VA-2): a compile-time pack, such as the pack of types
+            // `T` of `[... each T: I]`, which the types of later bindings
+            // name by its constant value.
+            pack_scope->each_binding_pattern_id = result_inst_id;
+            auto bind_id = context.bind_name_map()
+                               .Lookup(result_inst_id)
+                               .value()
+                               .bind_name_id;
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
index e10f50a06..a9430d800 100644
--- a/toolchain/check/handle_pack_expansion.cpp
+++ b/toolchain/check/handle_pack_expansion.cpp
@@ -55,12 +55,19 @@ auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
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
+      bool in_explicit_list = context.node_stack().PeekIs(
+                                  Parse::NodeKind::ExplicitParamListStart) &&
+                              context.full_pattern_stack().CurrentKind() ==
+                                  FullPatternStack::Kind::ExplicitParamList;
+      bool in_implicit_list = context.node_stack().PeekIs(
+                                  Parse::NodeKind::ImplicitParamListStart) &&
+                              context.full_pattern_stack().CurrentKind() ==
+                                  FullPatternStack::Kind::ImplicitParamList;
+      if (!in_explicit_list && !in_implicit_list) {
         return context.TODO(node_id,
                             "pack expansion pattern outside an explicit "
                             "parameter list");
@@ -99,21 +106,10 @@ auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
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
@@ -207,9 +203,29 @@ auto HandleParseNode(Context& context, Parse::PackExpansionStatementId node_id)
   if (!body_block_id->has_value()) {
     return true;
   }
+  // Fork (VA-2, D-VA2-4): the arity of an expansion over a pack of an
+  // enclosing generic, such as a variadic impl's pack in one of the impl's
+  // functions, is a binding of that generic. It is referred to by a
+  // `specific_constant` of the enclosing generic's self specific, as upstream
+  // refers to a name from an enclosing generic, so that each specific of this
+  // generic gives it a value.
+  auto arity_id = scope.arity_id;
+  if (auto const_id = context.constant_values().GetAttached(arity_id);
+      const_id.is_symbolic() && !context.generic_region_stack().Empty()) {
+    auto generic_id =
+        context.constant_values().GetSymbolicConstant(const_id).generic_id;
+    if (generic_id.has_value() &&
+        generic_id !=
+            context.generic_region_stack().PeekPendingGeneric().generic_id) {
+      arity_id =
+          WrapInstForSpecific(context, node_id, arity_id,
+                              context.generics().GetSelfSpecific(generic_id))
+              .inst_id;
+    }
+  }
   AddInst<SemIR::PackExpansionStatement>(
       context, node_id,
-      {.arity_id = scope.arity_id, .body_block_id = *body_block_id});
+      {.arity_id = arity_id, .body_block_id = *body_block_id});
   return true;
 }

@@ -221,6 +237,25 @@ auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
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
@@ -243,7 +278,7 @@ auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
   // "The type of a pack expansion expression or pattern is `...B`, where `B`
   // is the type of its body" (docs/design/variadics.md, "Typing and shaping
   // rules"): a pack of the body's type, with the arity of its each-names.
-  auto pack_type_id = GetPackType(
+  auto pack_type_id = GetPackTypeForElementType(
       context, context.types().GetTypeInstId(result_type_id), scope.arity_id);
   // Lowering reads the pack type's value representation in every specific, so
   // each specific's pack type must be complete, even when nothing else requires
@@ -296,9 +331,9 @@ auto HandleParseNode(Context& context, Parse::PackExpansionPatternId node_id)

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
@@ -338,7 +373,12 @@ auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
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
@@ -352,7 +392,9 @@ auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
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
@@ -378,13 +420,14 @@ auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
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

diff --git a/toolchain/check/impl_lookup.cpp b/toolchain/check/impl_lookup.cpp
index ec428ca7e..67e0f9155 100644
--- a/toolchain/check/impl_lookup.cpp
+++ b/toolchain/check/impl_lookup.cpp
@@ -650,6 +650,9 @@ struct CandidateImpl {

   // Used for sorting the candidates to find the most-specialized match.
   TypeStructure type_structure;
+  // Fork (VA-2, D-VA2-8): the impl's ranking against the query, which sorts
+  // the candidates (`TypeStructure::IsBetterRanking`).
+  llvm::SmallVector<int, 0> ranking;
   SemIR::InstId match_first_block;
   int match_first_position;
 };
@@ -734,9 +737,10 @@ static auto CollectCandidateImplsForQuery(
     // TODO: We can skip the comparison here if the `impl_interface_const_id` is
     // not symbolic, since when the interface and specific ids match, and they
     // aren't symbolic, the structure will be identical.
+    llvm::SmallVector<int, 0> ranking;
     if (!query_type_structure.CompareStructure(
             TypeStructure::CompareTest::IsEqualToOrMoreSpecificThan,
-            *type_structure)) {
+            *type_structure, &ranking)) {
       // If the query does not match this impl, but the impl is part of a final
       // `match_first` block, then we also check to see if the impl is _more
       // specific_ than the query. Meaning that the query, once specialized,
@@ -758,7 +762,7 @@ static auto CollectCandidateImplsForQuery(
     }

     candidates.impls.push_back({id, &impl, std::move(*type_structure),
-                                impl.match_first_id,
+                                std::move(ranking), impl.match_first_id,
                                 impl.match_first_position});
   }

@@ -790,7 +794,7 @@ static auto CollectCandidateImplsForQuery(
       return lhs.match_first_position < rhs.match_first_position;
     }
     // Otherwise, specificity wins.
-    return lhs.type_structure < rhs.type_structure;
+    return TypeStructure::IsBetterRanking(lhs.ranking, rhs.ranking);
   };
   // Stable sort is used so that impls that are seen first are preferred when
   // they have an equal priority ordering.
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
index 3fc909b01..624f175fb 100644
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
@@ -651,6 +662,17 @@ auto TypeCompleter::BuildInfoForInst(SemIR::TypeId type_id,
     return MakeEmptyTypeInfo();
   }

+  // Fork (VA-2, D-VA2-8): a tuple type with a pack segment, `(... each T)`,
+  // has as many elements as its segment's arity, which only a specific knows,
+  // so its value and initializing representations depend on the specific, as
+  // a symbolic binding's type does. (A segment of known arity and element
+  // types was already replaced by its elements, "Pack expansion splitting".)
+  if (llvm::any_of(elements, [&](SemIR::InstId element_id) {
+        return context_->insts().Is<SemIR::PackType>(element_id);
+      })) {
+    return MakeDependentTypeInfo(type_id);
+  }
+
   // Find the value representation for each element, and construct a tuple
   // of value representations.
   llvm::SmallVector<SemIR::InstId> value_rep_elements;
@@ -715,8 +737,45 @@ auto TypeCompleter::BuildInfoForInst(SemIR::TypeId type_id,
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
diff --git a/toolchain/check/type_structure.cpp b/toolchain/check/type_structure.cpp
index 3106fa7b2..1edb32fe5 100644
--- a/toolchain/check/type_structure.cpp
+++ b/toolchain/check/type_structure.cpp
@@ -16,7 +16,15 @@
 namespace Carbon::Check {

 auto TypeStructure::CompareStructure(CompareTest test,
-                                     const TypeStructure& other) const -> bool {
+                                     const TypeStructure& other,
+                                     llvm::SmallVectorImpl<int>* ranking) const
+    -> bool {
+  if (test != CompareTest::IsEqualToOrMoreSpecificThan) {
+    ranking = nullptr;
+  }
+  if (ranking) {
+    ranking->clear();
+  }
   const auto& lhs = structure_;
   const auto& rhs = other.structure_;

@@ -35,9 +43,33 @@ auto TypeStructure::CompareStructure(CompareTest test,
     if (lhs_cursor == lhs.end() || rhs_cursor == rhs.end()) {
       return false;
     }
+    // Fork (VA-2, D-VA2-8): a pack segment matches a run of the other side's
+    // elements, including the other side's own segment.
+    if (*rhs_cursor == Structural::SymbolicRun) {
+      if (!ConsumeSymbolicRun(lhs_cursor, lhs.end(), lhs_concrete_cursor,
+                              rhs_cursor, rhs.end(), lhs.begin(), ranking)) {
+        return false;
+      }
+      continue;
+    }
+    if (*lhs_cursor == Structural::SymbolicRun) {
+      // A query with a pack segment is less specific than an impl with
+      // elements in its place.
+      if (test == CompareTest::IsEqualToOrMoreSpecificThan) {
+        return false;
+      }
+      if (!ConsumeSymbolicRun(rhs_cursor, rhs.end(), rhs_concrete_cursor,
+                              lhs_cursor, lhs.end())) {
+        return false;
+      }
+      continue;
+    }
     // Same structural element on both sides. Compare concrete values if
     // possible to ensure they match. Both will be consumed.
     if (*lhs_cursor == *rhs_cursor) {
+      if (ranking && *rhs_cursor == Structural::Symbolic) {
+        ranking->push_back(4 * (lhs_cursor - lhs.begin()) + 2);
+      }
       // Each Concrete and ConcreteOpenParen shape entry has a paired concrete
       // value.
       if (*lhs_cursor == Structural::Concrete ||
@@ -72,6 +104,9 @@ auto TypeStructure::CompareStructure(CompareTest test,
         if (*lhs_cursor == Structural::Symbolic) {
           return false;
         }
+        if (ranking) {
+          ranking->push_back(4 * (lhs_cursor - lhs.begin()) + 2);
+        }
         if (!ConsumeRhsSymbolic(lhs_cursor, lhs_concrete_cursor, rhs_cursor)) {
           return false;
         }
@@ -97,6 +132,84 @@ auto TypeStructure::CompareStructure(CompareTest test,
   return true;
 }

+auto TypeStructure::CountElementsInGroup(
+    llvm::SmallVector<Structural>::const_iterator cursor,
+    llvm::SmallVector<Structural>::const_iterator end) -> int {
+  int count = 0;
+  int depth = 0;
+  for (; cursor != end; ++cursor) {
+    if (*cursor == Structural::ConcreteCloseParen) {
+      if (depth == 0) {
+        break;
+      }
+      --depth;
+      continue;
+    }
+    if (depth == 0) {
+      ++count;
+    }
+    if (*cursor == Structural::ConcreteOpenParen) {
+      ++depth;
+    }
+  }
+  return count;
+}
+
+auto TypeStructure::ConsumeSymbolicRun(
+    llvm::SmallVector<Structural>::const_iterator& elements_cursor,
+    llvm::SmallVector<Structural>::const_iterator elements_end,
+    llvm::SmallVector<ConcreteType>::const_iterator& elements_concrete_cursor,
+    llvm::SmallVector<Structural>::const_iterator& run_cursor,
+    llvm::SmallVector<Structural>::const_iterator run_end,
+    llvm::SmallVector<Structural>::const_iterator elements_begin,
+    llvm::SmallVectorImpl<int>* ranking) -> bool {
+  // Consume the run.
+  ++run_cursor;
+  // The run takes every element of its tuple except as many as follow it.
+  int after = CountElementsInGroup(run_cursor, run_end);
+  int available = CountElementsInGroup(elements_cursor, elements_end);
+  if (available < after) {
+    return false;
+  }
+  int to_skip = available - after;
+  if (ranking && to_skip == 0) {
+    ranking->push_back(4 * (elements_cursor - elements_begin) + 3);
+  }
+  int depth = 0;
+  while (to_skip > 0) {
+    if (ranking && depth == 0 &&
+        *elements_cursor != Structural::ConcreteCloseParen) {
+      ranking->push_back(4 * (elements_cursor - elements_begin) + 1);
+    }
+    switch (*elements_cursor) {
+      case Structural::ConcreteOpenParen:
+        ++elements_concrete_cursor;
+        ++depth;
+        break;
+      case Structural::ConcreteCloseParen:
+        --depth;
+        if (depth == 0) {
+          --to_skip;
+        }
+        break;
+      case Structural::Concrete:
+        ++elements_concrete_cursor;
+        if (depth == 0) {
+          --to_skip;
+        }
+        break;
+      case Structural::Symbolic:
+      case Structural::SymbolicRun:
+        if (depth == 0) {
+          --to_skip;
+        }
+        break;
+    }
+    ++elements_cursor;
+  }
+  return true;
+}
+
 // Returns false if the lhs and rhs can not match, true if we should
 // continue checking for compatibility.
 auto TypeStructure::ConsumeRhsSymbolic(
@@ -140,6 +253,7 @@ auto TypeStructure::ConsumeRhsSymbolic(
         ++lhs_concrete_cursor;
         break;
       case Structural::Symbolic:
+      case Structural::SymbolicRun:
         break;
     }
     ++lhs_cursor;
@@ -192,6 +306,11 @@ class TypeStructureBuilder {
     symbolic_type_indices_.push_back(structure_.size());
     structure_.push_back(TypeStructure::Structural::Symbolic);
   }
+  // Fork (VA-2, D-VA2-8): a tuple's pack segment.
+  auto AppendStructuralSymbolicRun() -> void {
+    symbolic_type_indices_.push_back(structure_.size());
+    structure_.push_back(TypeStructure::Structural::SymbolicRun);
+  }

   Context* context_;

@@ -225,8 +344,14 @@ auto TypeStructureBuilder::Build(SemIR::TypeIterator type_iter)
         AppendStructuralConcrete(concrete.type_id);
         break;
       }
-      case CARBON_KIND(Step::SymbolicType _): {
-        AppendStructuralSymbolic();
+      case CARBON_KIND(Step::SymbolicType symbolic): {
+        // Fork (VA-2): a tuple's pack segment.
+        if (symbolic.facet.has_value() &&
+            context_->insts().Is<SemIR::PackType>(symbolic.facet)) {
+          AppendStructuralSymbolicRun();
+        } else {
+          AppendStructuralSymbolic();
+        }
         break;
       }
       case CARBON_KIND(Step::TemplateType _): {
@@ -268,7 +393,12 @@ auto TypeStructureBuilder::Build(SemIR::TypeIterator type_iter)
         break;
       }
       case CARBON_KIND(Step::TupleStartOnly _): {
-        AppendStructuralConcrete(TypeStructure::ConcreteTypeStart::Tuple);
+        // Fork (VA-2, D-VA2-8): the empty tuple is an empty group, as a
+        // tuple of elements is a group of them, so that a pack segment
+        // `(...?)` matches it with an empty run.
+        AppendStructuralConcreteOpenParen(
+            TypeStructure::ConcreteTypeStart::Tuple);
+        AppendStructuralConcreteCloseParen();
         break;
       }
       case CARBON_KIND(Step::TupleStart _): {
diff --git a/toolchain/check/type_structure.h b/toolchain/check/type_structure.h
index 7ac6018b7..3f3c1bd10 100644
--- a/toolchain/check/type_structure.h
+++ b/toolchain/check/type_structure.h
@@ -8,6 +8,7 @@
 #include <algorithm>

 #include "common/ostream.h"
+#include "llvm/ADT/ArrayRef.h"
 #include "llvm/ADT/SmallVector.h"
 #include "toolchain/check/context.h"
 #include "toolchain/check/scope_index.h"
@@ -45,9 +46,36 @@ class TypeStructure : public Printable<TypeStructure> {

   // Compares the structure of `this` and `other`, and returns whether the
   // structures match according to the specified test.
-  auto CompareStructure(CompareTest test, const TypeStructure& other) const
+  //
+  // Fork (VA-2, D-VA2-8): with `IsEqualToOrMoreSpecificThan` and a non-null
+  // `ranking`, `this` is a query and `other` an impl, and a match also
+  // computes the impl's ranking against the query (see `IsBetterRanking`).
+  auto CompareStructure(CompareTest test, const TypeStructure& other,
+                        llvm::SmallVectorImpl<int>* ranking = nullptr) const
       -> bool;

+  // Fork (VA-2, D-VA2-8): whether the impl ranked `lhs` against a query is a
+  // better, more specific, match than the impl ranked `rhs` against the same
+  // query. A ranking lists, in order, a key for each position `p` in the
+  // query's structure that the impl does not match by a concrete element:
+  // `4p + 2` for an element matched by a `?`, `4p + 1` for an element covered
+  // by a pack segment, and `4p + 3` for a pack segment that covers no element
+  // and sits before position `p`. The rule is the overlap rule ("We pick the
+  // type structure with a non-`?` at the first difference as most specific",
+  // docs/design/generics/details.md) taken position by position along the
+  // query, so that impls whose segments cover different runs of the query
+  // are compared where their coverage first differs; at one position, a
+  // segment that covers nothing is the most specific choice after a concrete
+  // element, and a `?`, which matches that element alone, is a more specific
+  // choice than a segment that covers it, which matches any run. Without pack
+  // segments, this orders impls as `operator<` does.
+  static auto IsBetterRanking(llvm::ArrayRef<int> lhs, llvm::ArrayRef<int> rhs)
+      -> bool {
+    return std::lexicographical_compare(
+        lhs.begin(), lhs.end(), rhs.begin(), rhs.end(),
+        [](int lhs_index, int rhs_index) { return rhs_index < lhs_index; });
+  }
+
   // Ordering of type structures. A lower value is a better match.
   // TODO: switch to operator<=> once we can depend on
   // std::lexicographical_compare_three_way (in particular, once we can
@@ -90,6 +118,9 @@ class TypeStructure : public Printable<TypeStructure> {
         case Structural::ConcreteCloseParen:
           out << ')';
           break;
+        case Structural::SymbolicRun:
+          out << "...";
+          break;
       }
     }
   }
@@ -119,6 +150,15 @@ class TypeStructure : public Printable<TypeStructure> {
     // or `Symbolic`, or everything from a `ConcreteOpenParen` to its paired
     // `ConcreteCloseParen`.
     Symbolic,
+
+    // Fork (VA-2, D-VA2-8): a tuple's pack segment, `... each T`, whose type
+    // parameter the type structure replaces by `?` ("replacing type
+    // parameters by a `?`", generics/details.md) inside the tuple, `(...?)`.
+    // When matching type structures, it matches a run of zero or more
+    // elements of the enclosing tuple: as many as leave the elements after it
+    // to match the tuple's last elements. It ranks below a `Symbolic` at the
+    // same position, which matches exactly one element.
+    SymbolicRun,
   };

   // Marks a type of the named kind.
@@ -166,6 +206,26 @@ class TypeStructure : public Printable<TypeStructure> {
         symbolic_type_indices_(std::move(symbolic_type_indices)),
         concrete_types_(std::move(concrete_types)) {}

+  // A helper for ConsumeSymbolicRun: counts the elements from `cursor` to the
+  // end of the enclosing tuple (or of the structure).
+  static auto CountElementsInGroup(
+      llvm::SmallVector<Structural>::const_iterator cursor,
+      llvm::SmallVector<Structural>::const_iterator end) -> int;
+
+  // A helper for CompareStructure: consumes the `SymbolicRun` at
+  // `run_cursor` and the run of elements at `elements_cursor` that it
+  // matches. Returns false if too few elements remain.
+  // If `ranking` is not null, the elements are the query's, starting at
+  // `elements_begin`, and the run's coverage is appended to it.
+  static auto ConsumeSymbolicRun(
+      llvm::SmallVector<Structural>::const_iterator& elements_cursor,
+      llvm::SmallVector<Structural>::const_iterator elements_end,
+      llvm::SmallVector<ConcreteType>::const_iterator& elements_concrete_cursor,
+      llvm::SmallVector<Structural>::const_iterator& run_cursor,
+      llvm::SmallVector<Structural>::const_iterator run_end,
+      llvm::SmallVector<Structural>::const_iterator elements_begin = {},
+      llvm::SmallVectorImpl<int>* ranking = nullptr) -> bool;
+
   // A helper for CompareStructure.
   static auto ConsumeRhsSymbolic(
       llvm::SmallVector<Structural>::const_iterator& lhs_cursor,
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
diff --git a/toolchain/lower/file_context.cpp b/toolchain/lower/file_context.cpp
index 880e9a98f..feec811df 100644
--- a/toolchain/lower/file_context.cpp
+++ b/toolchain/lower/file_context.cpp
@@ -223,6 +223,52 @@ auto FileContext::Finalize() -> void {
                                          specific_functions_);
 }

+// Fork (VA-2): builds the elementwise value representation of a constant
+// tuple or struct value whose value representation differs from its object
+// representation, such as `((1, 2), 3)`, whose value holds a pointer to the
+// value of `(1, 2)` where its object holds `(1, 2)` itself. The lowered
+// constant `const_value` is the object representation. Returns nullptr if the
+// constant is not a tuple or struct value.
+static auto BuildElementwiseConstantValueRepr(FileContext& context,
+                                              SemIR::InstId const_inst_id,
+                                              SemIR::ValueRepr value_rep,
+                                              SemIR::InstId use_inst_id)
+    -> llvm::Constant* {
+  const auto& sem_ir = context.sem_ir();
+  auto inst = sem_ir.insts().Get(const_inst_id);
+  SemIR::InstBlockId elements_id = SemIR::InstBlockId::None;
+  if (auto tuple = inst.TryAs<SemIR::TupleValue>()) {
+    elements_id = tuple->elements_id;
+  } else if (auto struct_value = inst.TryAs<SemIR::StructValue>()) {
+    elements_id = struct_value->elements_id;
+  } else {
+    return nullptr;
+  }
+  auto repr_type_id = value_rep.kind == SemIR::ValueRepr::Pointer
+                          ? sem_ir.GetPointeeType(value_rep.type_id)
+                          : value_rep.type_id;
+  auto* llvm_type = dyn_cast<llvm::StructType>(context.GetType(repr_type_id));
+  if (!llvm_type) {
+    return nullptr;
+  }
+  llvm::SmallVector<llvm::Constant*> elements;
+  for (auto [index, element_id] :
+       llvm::enumerate(sem_ir.inst_blocks().Get(elements_id))) {
+    auto* element = cast<llvm::Constant>(context.GetConstant(
+        sem_ir.constant_values().Get(element_id), use_inst_id));
+    auto* element_type = llvm_type->getElementType(index);
+    if (element->getType() != element_type) {
+      // A tail-padded element, `<{T, [N x i8]}>`.
+      auto* padded = cast<llvm::StructType>(element_type);
+      element = llvm::ConstantStruct::get(
+          padded, element,
+          llvm::Constant::getNullValue(padded->getElementType(1)));
+    }
+    elements.push_back(element);
+  }
+  return llvm::ConstantStruct::get(llvm_type, elements);
+}
+
 auto FileContext::GetConstant(SemIR::ConstantId const_id,
                               SemIR::InstId use_inst_id) -> llvm::Value* {
   auto const_inst_id = sem_ir().constant_values().GetInstId(const_id);
@@ -254,16 +300,26 @@ auto FileContext::GetConstant(SemIR::ConstantId const_id,

   auto value_rep = SemIR::ValueRepr::ForType(
       sem_ir(), sem_ir().insts().Get(const_inst_id).type_id());
+  if (value_rep.kind == SemIR::ValueRepr::Pointer) {
+    // The value representation is a pointer. Find and reuse an existing
+    // variable holding the value, or generate one below.
+    if (auto result = global_variables().Lookup(const_inst_id)) {
+      return result.value();
+    }
+  }
+  if (value_rep.aggregate_kind == SemIR::ValueRepr::ValueAggregate &&
+      const_value) {
+    // Fork (VA-2): the value representation is elementwise and is not the
+    // object representation that `const_value` holds.
+    if (auto* elementwise = BuildElementwiseConstantValueRepr(
+            *this, const_inst_id, value_rep, use_inst_id)) {
+      const_value = elementwise;
+    }
+  }
   if (value_rep.kind != SemIR::ValueRepr::Pointer) {
     return const_value;
   }

-  // The value representation is a pointer. Generate a variable to hold the
-  // value, or find and reuse an existing one.
-  if (auto result = global_variables().Lookup(const_inst_id)) {
-    return result.value();
-  }
-
   // Include both the name of the constant, if any, and the point of use in
   // the name of the variable.
   llvm::StringRef const_name;
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
index 450d36921..3924b6f04 100644
--- a/toolchain/sem_ir/stringify.cpp
+++ b/toolchain/sem_ir/stringify.cpp
@@ -876,8 +876,43 @@ class Stringifier {
   }

   auto StringifyInst(InstId /*inst_id*/, PackType inst) -> void {
+    // Fork (VA-2, D-VA2-3): a pack of different types prints as the pack
+    // literal of its types, `⟬A, B⟭`, or as `⟬each T⟭` while its pack of
+    // types `T` is symbolic; a pack of one element type prints as `«E; N»`
+    // (docs/design/variadics.md, "Tuples, packs, segments, and shapes").
+    if (sem_ir_->types().Is<PackType>(
+            sem_ir_->insts().Get(inst.element_id).type_id())) {
+      if (sem_ir_->insts().Is<PackValue>(inst.element_id)) {
+        step_stack_->PushInstId(inst.element_id);
+        return;
+      }
+      *out_ << "⟬each ";
+      step_stack_->Push(inst.element_id, "⟭");
+      return;
+    }
     *out_ << "«";
-    step_stack_->Push(inst.element_type_inst_id, "; ", inst.arity_id, "»");
+    step_stack_->Push(inst.element_id, "; ", inst.arity_id, "»");
+  }
+
+  // Fork (VA-2, D-VA2-3): a concrete pack, such as the pack of types that a
+  // specific of `[... each T: I]` gives `T`, prints as the pack literal of its
+  // elements, `⟬A, B⟭` (docs/design/variadics.md, "Tuples, packs, segments,
+  // and shapes").
+  auto StringifyInst(InstId /*inst_id*/, PackValue inst) -> void {
+    *out_ << "⟬";
+    step_stack_->PushString("⟭");
+    llvm::ListSeparator sep;
+    for (auto ref :
+         llvm::reverse(sem_ir_->inst_blocks().Get(inst.elements_id))) {
+      step_stack_->Push(ref, &sep);
+    }
+  }
+
+  // Fork (VA-2, D-VA2-6): the scalar component of a pack of types at the pack
+  // index, which the source spells `each T`.
+  auto StringifyInst(InstId /*inst_id*/, PackElement inst) -> void {
+    *out_ << "each ";
+    step_stack_->PushInstId(inst.pack_id);
   }

   auto StringifyInst(InstId /*inst_id*/, PartialType inst) -> void {
@@ -963,12 +998,23 @@ class Stringifier {
     *out_ << "(";
     step_stack_->PushString(")");
     // A tuple of one element has a comma to disambiguate from an
-    // expression.
-    if (refs.size() == 1) {
+    // expression; a pack segment, `... each T`, needs none.
+    if (refs.size() == 1 && !sem_ir_->insts().Is<PackType>(refs.front())) {
       step_stack_->PushString(",");
     }
     llvm::ListSeparator sep;
     for (auto ref : llvm::reverse(refs)) {
+      // Fork (VA-2, D-VA2-8): a pack segment prints as the expansion that
+      // spells it (docs/design/variadics.md, "Tuples, packs, segments, and
+      // shapes").
+      if (auto pack = sem_ir_->insts().TryGetAs<PackType>(ref);
+          pack &&
+          sem_ir_->types().Is<PackType>(
+              sem_ir_->insts().Get(pack->element_id).type_id()) &&
+          !sem_ir_->insts().Is<PackValue>(pack->element_id)) {
+        step_stack_->Push("... each ", pack->element_id, &sep);
+        continue;
+      }
       step_stack_->Push(ref, &sep);
     }
   }
diff --git a/toolchain/sem_ir/type_iterator.cpp b/toolchain/sem_ir/type_iterator.cpp
index a0ca5337e..57ef9de16 100644
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
@@ -230,6 +233,13 @@ auto TypeIterator::ProcessType(InstId inst_id) -> std::optional<Step> {
       PushInstId(pointer_type.pointee_id);
       return Step::PointerStart();
     }
+    // Fork (VA-2): a pack type is a tuple's pack segment, `... each T`, which
+    // matches a run of the tuple's elements; it is symbolic, and the type
+    // structure records it as a run (type_structure.cpp).
+    case PackType::Kind: {
+      return Step::SymbolicType{.entity_name_id = EntityNameId::None,
+                                .facet = inst_id};
+    }
     case CARBON_KIND(TupleType tuple_type): {
       auto inner_types =
           sem_ir_->inst_blocks().Get(tuple_type.type_elements_id);
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
