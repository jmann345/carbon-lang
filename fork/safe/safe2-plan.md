<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# SAFE-2 plan: the R32 realignment of SAFE-1's six departures (W-347 to W-351, W-353)

**Status:** rev 8, 2026-10-29 -- SIGNED OFF FOR IMPLEMENTATION at rev 5, AMENDED
BY A STOP-AND-AMEND (rev 6) AND BY THE FOLD OF ITS FOCUSED RE-REVIEW (rev 7),
STOPPED AT THE FIX BUDGET AND RE-PLANNED, NOT SIGNED OFF (rev 8; amended
2026-10-29, rev 8: section 8.16, where this read "rev 7, 2026-10-28" and "(rev
7); IMPLEMENTED"); IMPLEMENTED by commits 48f2e66a0 and 954f1c542, whose two
document reviews raised ten findings, all folded by fix commits 0f281d8bd and
e1574b003 and the records commit of section 8.7, none rejected (amended
2026-10-28, document-review fold: section 8.7); the focused re-review of section
3 step 5, round 1, returned REJECT on one BLOCKER, two MAJORs and two MINORs, so
it is not dry: its one records-only MINOR, RR1-m2, is folded by the round's
records commit, and RR1-B1, RR1-M1, RR1-M2 and RR1-m1 go to round 2's fixer,
which has the last fix commit of the budget (amended 2026-10-28, re-review round
1: section 8.13, where this read "the focused re-review of section 3 step 5
next"). Round 2's fixer accepted all four and folded them by fix commit
cbdc0552e, the third and last of the budget, recorded in section 8.14; round 2
reviews it next (amended 2026-10-29, re-review round 2: section 8.14; amended
2026-10-29, re-review round 2: RR2-m2, where this read "round 3 reviews it
next"). The focused re-review's round 2 returned APPROVE-WITH-FIXES on one MAJOR
and two MINORs, one of them records-only, so it is not dry: its records-only
MINOR, RR2-m2, is folded by the round's records commit, and RR2-M1 and RR2-m1,
which change pages, go to round 3's fixer, for which the budget of section 3
step 4 has no fix commit left (amended 2026-10-29, re-review round 2: section
8.15). Rev 8, 2026-10-29, is the stop-and-amend of section 3 step 4's last
clause: round 3's fixer reproduced and accepted RR2-M1 and RR2-m1, found the
budget spent, and re-planned the built-in test at its root, by where an
implementation is written rather than by the type it serves, with the aggregate
clause stated as this design's classification beside
docs/design/assignment.md:159's heading; section 8.16 records the stop and gives
the texts of the one fold commit that answers both, for the orchestrator to rule
on, and no page, record or ledger line changes (amended 2026-10-29, rev 8:
section 8.16). Rev 8 is 1f9d0a16f, and section 8.17 records round 3's fold, in
which the budget is exceeded and the orchestrator rules (amended 2026-10-29,
re-review round 3 fold: section 8.17). Rev 7 is the plan amender's fold of the
focused re-review of rev 6 (486d2bc74), whose verdict was
APPROVE-WITH-AMENDMENTS with no BLOCKER, one MAJOR and one MINOR, both folded
and none rejected (section 8.12; amended 2026-10-28, stop-and-amend re-review:
AM6-M1, AM6-m1). AM6-M1: section 2.1's test, as rev 6 worded it, failed five
quotes that rev 6 kept, three code lines whose runs of spaces the quotes shorten
(A.2.11 twice, A.2.13), A.3.13's anchor, which also ends in "..." for the rest
of its code line, and A.8.1's locator, which quoted a link by its text alone.
AM6-m1: section 8.12 overstated what rev 6's checker set aside and scanned. Rev
7 adds the two code-line set-asides to section 2.1, scopes its test to anchors
and superseded texts, writes a quote that carries link markup in this plan's own
prose as a code span, quotes A.8.1's locator with its link, and records a sweep,
in section 8.12, that applies exactly section 2.1's test to every quoted span of
Appendices A to D, prose anchors included, with no mismatch left. No page or
record text, rule, example, diagnostic, line count or count of section 8 item 1
changes, so the implementation resumes from this revision's commit with section
3's commit 1. Rev 6 was the plan amender's revision of rev 5 (4ca369e38) after
the implementer stopped before committing commit 1: the superseded texts that
Appendix A's blocks A.1.6 and A.5.10 quote had dropped the link markup of three
links on the page lines they quote, so they were not byte-equal to the pages at
2407efa74. Rev 6 restored the three links in those two quotes, stated in section
2.1 the byte-equality test every superseded text and anchor meets, added that
test to section 8 item 5, and corrected A.10.2's line count from 10 to 11 and
the line ranges in A.1.6's and A.5.10's headings (section 8.12; amended
2026-10-28, implementation: stop-and-amend: link markup in two superseded
quotes). Rev 5 was the fixer's fold of the focused re-review (round 3) of rev 4
(9d48a863e), whose verdict was APPROVE-WITH-AMENDMENTS: no BLOCKER (RR2-B1
resolved), one MAJOR, RR3-M1 (PR 65's `IndirectIndexWith.Ref`, a by-value
producer of a `ref` into the block with no `bound`, would reopen `Peek8`'s shape
once PR 65 lands), and two MINORs, RR3-m1 and RR3-m2; all three are folded and
none is rejected (section 8.11), and the "Sign-off" section tables every review
of this plan. The implementation started from rev 5's commit with section 3's
commit 1 and stopped before committing it (section 8.12). Rev 4, 2026-10-28, was
the fixer's fold of the focused re-review (round 2) of rev 3 (603749ee1), whose
verdict was REJECT on one BLOCKER, RR2-B1 (a trusted prelude writer,
`Core.Buf(T).Set` with its by-value receiver, wrote a borrowed `Core.String`
element in Strict), with three MINORs; all four were folded and none was
rejected (section 8.10), and since RR2-B1's fold changed a rule of the design (a
trusted body keeps M3's write rule, and `Core.Buf(T).Set` takes `ref self`),
only the next focused re-review could sign rev 4 off. Rev 3, 2026-10-28, was the
fixer's fold of the focused re-review of rev 2 (46980f8bd), whose verdict was
REJECT on one BLOCKER, RR1-B1 (review A's B-1 not resolved: a write to an
enclosing `Plain` aggregate, a struct or class that holds a `str`, still mutated
a borrowed `Core.SharedImmutable` object through `T*`), with one MAJOR and four
MINORs; all six were folded and none was rejected (section 8.9). Rev 2
(46980f8bd) folded the two plan reviews, review A (REJECT, two BLOCKERs) and
review B (APPROVE-WITH-AMENDMENTS), 21 findings, every one accepted (section
8.8; review A's ids carry the prefix "A-", so A-B-1 is review A's B-1); rev 1
(475b7ecb0) was the planner's draft. Workstream SAFE-2 realigns the six
"departures from accepted text" of SAFE-1's design (fork decision F-013) to
upstream's recorded direction, as rulebook R32 requires since the owner's
directive of 2026-10-21 ("Direction drifts are not permitted"; decision-log
V-3b, DR-0). Branch `claude/carbon-fork-0-1-safe` (PR 53, held open, second in
the land sequence after PR 67), head 2407efa74; this plan is a new file beside
fork/safe/plan.md, which receives a dated pointer paragraph in commit 2 (section
2.3). Upstream was read at its tip 0421bf3b4 (fetched 2026-10-28) and re-read
for rev 3 at 22f3cd353 and for rev 4, rev 5 and rev 6 at 07718a832, where no
quoted file has changed (section 0.1). Records and design text only: no
toolchain, prelude, golden, program or conformance change; the two SKIP stubs
stay as they are; nothing is built.

**Items:** W-347 (D-SAFE-8 narrows p005434:83), W-348 (D-SAFE-17 narrows
p005434:660-664), W-349 (D-SAFE-11(d) narrows p005434:831-832), W-350
(D-SAFE-15 withdraws arithmetic.md:156-158's performance-build row), W-351
(D-SAFE-14 SP4 withdraws safety/README.md:260-262's benchmarking disable) and
W-353 (D-SAFE-13 I5's zero-fill for every type), filed by RG-1 on PR 67's
ledger (fork/inventory/work-items.json on `claude/carbon-fork-0-1-rg1` at
56e2e5bbd), each owned by SAFE-1 and realigned "by a new commit on PR 53's
branch under SAFE-1's plan amendment, two document reviews and a fixer, before
PR 53 lands" (R32 (e); fork/register/rg1-plan.md D-RG-7, section 5, section 6
R-4). The brief of each item is its ledger Work sentence; where this plan's
audit finds that an item was misclassified, the item is closed with its
classification corrected rather than realigned (section 0.3, W-353; amended
2026-10-28, review fold: A-m-3, B-M1).

**The rule applied to each item** (R32, R17): the fork keeps upstream's
sentence as its rule; where SAFE-1 narrowed or withdrew it for a reason, this
plan records the cost of realignment and re-derives the dependent rules,
examples and diagnostics under upstream's text, on every page and record that
states them. No dependent line is left stating a narrowed rule; every realigned
passage keeps the superseded 2026-10-12 text visible inside a dated
amendment, the OV-4 precedent (fork/overload/ov4-plan.md on PR 68, Appendix C
and section 2.6).

## Sections

-   Section 0, audit: upstream at the tip, PR 67's checks, the classification
    corrected, PR 53's dependent lines, the interlocks, the examples, the
    collisions, the id re-scan and the records placement.
-   Section 1, design: decisions D-SAFE2-1 to D-SAFE2-16.
-   Section 2, spec: the conventions and the index of every text change;
    the verbatim texts are Appendix A (pages) and Appendix B (records).
-   Section 3, commits and reviews.
-   Section 4, the worked-example matrix.
-   Section 5, scoreboard.
-   Section 6, churn and collisions.
-   Section 7, risks and rejected alternatives.
-   Section 8, verification, the list of what was not run, the plan
    reviews' fold records (sections 8.8 to 8.11) and the stop-and-amend
    record with the fold of its focused re-review (section 8.12; amended
    2026-10-28, implementation: stop-and-amend: link markup in two superseded
    quotes; amended 2026-10-28, stop-and-amend re-review: AM6-m1), and the
    implementation's records: the document-review fold record (section 8.7)
    and the focused re-review's round 1 (section 8.13; amended 2026-10-28,
    re-review round 1), the fold of its findings (section 8.14) and the
    re-review's round 2 (section 8.15; amended 2026-10-29, re-review round 2),
    and the stop-and-amend record of rev 8 (section 8.16; amended 2026-10-29,
    rev 8) with the fold record of round 3 (section 8.17; amended 2026-10-29,
    re-review round 3 fold).
-   The sign-off, every review of this plan with its verdict and counts, then
    the hand-off notes for the implementer.
-   Appendix A, page replacements; Appendix B, records texts; Appendix C, the
    PR 53 and PR 67 texts; Appendix D, the ORCHESTRATION texts.

## §0 Audit

### §0.1 Upstream at the tip

`git -C /home/user/carbon-lang fetch -q upstream trunk` on 2026-10-28 gives
upstream/trunk = **0421bf3b4** (2026-10-28 05:36:57 UTC, "Optimize token kinds
and whitespace flags", upstream PR 8044), the tip the OV-4 plan read. The cut
c1e83b0b7 is its ancestor. `git log --oneline c1e83b0b7..0421bf3b4 -- <file>`
for each source this plan quotes:

| Upstream file | Commits since the cut |
| --- | --- |
| proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md | none |
| proposals/p005914-updating-carbon-s-safety-strategy.md | none |
| proposals/p000257-initialization-of-memory-and-variables.md | none |
| docs/design/README.md | none |
| docs/design/safety/ (README.md and terminology.md) | none |
| docs/design/expressions/arithmetic.md | none |
| docs/design/values.md | none |
| docs/design/classes.md | f21c62524 "Interface as base class use case supported" (upstream PR 8002): two lines of "Use cases" (:124-125) replaced by two; no line count changes, and no line the safety pages cite (classes.md:1852-1870, :1920-1957, :1941-1944, :1968-1982) moves |
| docs/design/slices.md | not an upstream file: slices.md is the fork's (SL-1); no upstream text to compare |
| toolchain/check/type_completion.cpp (amended 2026-10-28, review fold: B-m7) | seven: fb7eff130 "Move IdentifiedFacetType to check" (upstream PR 8004), eb66bebc3 "New specifics formed during identify need to be marked `identified`" (PR 8003), 51e2c76a8 "Add a HasError helper to SpecificStore" (PR 7970), f0bae9637 "Verify non-extend require constraints are satisfied at `impl as` definition" (PR 7937), 24766e213 "Defer evaluation of witnesses substituted while identifying a facet type" (PR 7930), b1de0e037 "Give the facet type as a TypeId to IdentifyFacetType functions" (PR 7926) and 62f1cc6a3 "Rename `GenericClassType` to `ParameterizedClassType`" (PR 7953); `git diff c1e83b0b7 0421bf3b4` of the file changes no line of the value-representation code (`BuildStructOrTupleValueRepr` and the struct, tuple, array, class, `const` and `MaybeUnformed` cases), only the facet-type code around it, so the lines this plan cites are the tip's and their text is the cut's |

Re-read for rev 3 on 2026-10-28: upstream/trunk = 22f3cd353 (2026-10-28
16:23:27 UTC, upstream PR 8053), two commits past 0421bf3b4, 6d5142779
(upstream PR 8051, check tests only) and 22f3cd353 (toolchain/parse/context.cpp
and context.h only). `git diff --stat 0421bf3b4 22f3cd353 -- proposals
docs/design toolchain/check/type_completion.cpp core/prelude` prints nothing,
the commits since the cut on the files above are still the ones the table
names, and PR 67's checks pass at 22f3cd353 (section 0.2).

Re-read for rev 4 on 2026-10-28 (added 2026-10-28, review fold: RR2-B1, the
round-2 re-review's tip): `git fetch upstream trunk` gives 07718a832 (upstream
PR 8041, "Switch symbol token to be templated on its character to simplify its
dispatch"), one commit past 22f3cd353; `git diff --stat 0421bf3b4 07718a832 --
proposals docs/design toolchain/check/type_completion.cpp core/prelude` prints
nothing; `git log --oneline c1e83b0b7..07718a832` over p005434, p005914,
p000257, docs/design/README.md, safety/README.md, arithmetic.md, values.md,
classes.md and slices.md lists only f21c62524, the table's; and PR 67's checks
pass at 07718a832 (section 0.2).

Re-read for rev 5 on 2026-10-28 (added 2026-10-28, review fold: RR3-M1, the
round-3 re-review's tip): `git fetch upstream trunk` gives 07718a832 again;
`git log --oneline c1e83b0b7..07718a832` over the nine files above lists only
f21c62524, and `git diff --stat 0421bf3b4 07718a832` over them prints nothing,
so p005434:83, :660-664 and :831-834, README.md:2130-2132,
safety/README.md:260-262, arithmetic.md:156-158 and values.md:456-462 read as
below. Read for RR3-M1 at the same tip: upstream's prelude declares
`interface IndirectIndexWith(SubscriptType: type)` with
`fn Ref(self, subscript: SubscriptType) -> ref ElementType;`
(core/prelude/operators/index.carbon:14-17, added by upstream PR 7974,
6d80ceb58), with no `bound`, as no prelude declaration there has one yet; and
p005434's use case for a `ref`-returning operator interface puts `bound` on
the receiver at the interface and keeps it in the impl: `interface Deref`
declares `fn Op[bound ref self: Self]() -> ref Result;` and its impl for `T*`
defines `fn Op[bound self: Self]() -> ref T` (p005434:952-960), the shape
W-144 gives `IndirectIndexWith.Ref` (D-SAFE2-5).

Re-read for the document-review fold on 2026-10-28 (added 2026-10-28,
document-review fold: R1-m3, which found the last recorded re-read at
07718a832 while the tip had moved): `git fetch upstream trunk` gives
9192ee003 ("Make `TokenInfo` use a single 32-bit store for initialization.",
upstream PR 8054); `git diff --stat 07718a832 9192ee003` over proposals,
docs/design, toolchain/check/type_completion.cpp and core/prelude prints
nothing; `git log --oneline c1e83b0b7..9192ee003` over the nine files above
and docs/design/assignment.md and docs/design/expressions/indexing.md lists
only f21c62524; the quotes below read as before. Read for R1-M1 at the same
tip: docs/design/assignment.md:76-77, "the first operand must be modifiable
because it is passed to a `(ref self: Self)` parameter", whose allowed forms
include "A dereference of a pointer." (:80) and "Member access naming a
field" (:82); :184, "The statement `x = y;` is rewritten to
`x.(AssignWith(U).Op)(y);`."; and p005434:302-318, the operators that take a
`ref` operand, `&`, the first operand of indexing and member access, and "The
statement operators now use `ref` instead of pointers", the left-hand operand
of the assignment operators and `++` and `--`. PR 67's checks pass at
9192ee003 (section 0.2).

No quoted passage moved or changed. The passages, at 0421bf3b4, verbatim:

-   p005434:83 "The address of a `ref` binding is `nocapture` and `noalias`."
    :173-175 "A `ref` binding may only bind to a durable reference expression
    or an expression that can be converted to one. The bound durable reference
    expression must outlive the `ref` binding." :177-179 "The address of a
    `ref` bound name gives the address of the bound object, so `&x == ptr`
    above. The reference itself does not have an address, and unlike a pointer
    can't be rebound to reference a different object." The example the last
    sentence names is :152-162, `fn F(ptr: i32*) { let ref x: i32 = *ptr;
    Assert(&x == ptr); x += 1; }` with its caller `G` passing `&y`.
-   p005434:660-669: "Mutation of objects with a non-copy-value representation
    in an active value binding ("borrowed objects") is erroneous behavior." /
    "Our plan is to prevent mutation of borrowed objects in Carbon's strict
    safe dialect." / "We should only relax our stance here and consider making
    such mutation _allowed_ if we discover difficulty with this that we cannot
    overcome." / "But we _should_ revisit the underlying idea of mutation being
    erroneous if enforcing it in the strict mode proves fundamentally
    untenable due to ergonomic costs." :670-672 "There will always be the
    potential for unchecked code, either unsafe Carbon code or C++ code by way
    of interop, to mutate a borrowed object, hence the need to define it as
    erroneous behavior."
-   p005434:698-702 "It is erroneous behavior to return something that
    references a local object that won't live once the function returns, even
    if it is a parameter marked `bound`." :717-720 `fn Valid1(bound p: i32*) ->
    ref i32 { return *p; }` (marked valid). :772-779 `fn Conditional(b: bool,
    bound ref r: C, bound p: C*) -> ref C` returning `r` or `*p`. :782-784
    "The `impl` of that interface for a type can omit occurrences of `bound`
    from the interface, but cannot add new ones." :826
    `fn ValToRef(bound y: C) -> ref D { return *y.ptr; }`.
-   p005434:831-835 "For full safety, we need each bound parameter to be
    immutable for the duration of the lifetime of the returned result. However,
    the objective for now is only matching `[[clang::lifetimebound]]`, which
    has the goal of preventing some classes of bugs, not full memory safety. We
    will reconsider this with the memory safety design."
-   p005434:846-848 "The address of a `ref` binding is `noalias` and either
    `captures(none)` or `captures(ret: address, provenance)`, depending on
    whether the binding is marked `bound`." :850-852 "`noalias` means like C
    `restrict`; you can't observe mutations through aliases; mutation through
    a restricted pointer is not observable through another pointer." :859-863
    "The combination of `noalias` and `captures(none)` semantics are the
    minimum for the "move-in-move-out" optimization. But this condition is hard
    to check, so safe code will use a stricter criteria. Unsafe code will be
    required to adhere to just the `noalias` restrictions, but will not be
    checked (except possibly by a sanitizer at runtime)." :866-868
    "Optimizations will only be performed based on information that is
    enforced or checked by the compiler, so these attributes won't be passed to
    LLVM unless their requirements can be established." :1130 "## Future work";
    :1226 "### Restore `addr`"; :1234-1236 "To allow the `self` parameter to
    use one of the pointer semantics we create as part of the upcoming memory
    safety design, that can't be achieved with `ref`."
-   p005914:85-88 "Requires temporal, spatial, and type errors to be rejected
    at compile time or detected at runtime with fail-stop behavior." /
    "Requires initialization errors to not have undefined behavior, but
    allows, for example, zero-initialization rather than fail-stop behavior."
    :110-111 "Minimal temporal safety runtime overhead: in aggregate and in
    real-world application benchmarks, any performance overhead would need to
    be under 1%." :182-184 "We expect to have more distinguished types of
    pointers in Carbon to be able to model more C++ coding patterns safely,
    including both shared mutable pointers, and exclusive mutable pointers".
    :204-210 "To avoid undefined behavior, the optimization of safe code will
    not rely on properties that are not established locally." (with the C++
    example and the erroneous-behavior sentence that follow).
-   p000257:102-104 "The object must not be used in any way other than
    assignment or destruction." / "Taking the address is fine". :179-182 "These
    errors should be diagnosed as early as possible in a debug build and at
    least at runtime. In a performance build, it may lead to undefined
    behavior, but in a hardened build we have a strong mitigation that restores
    safety by defining the behavior using a maximally safe representation."
    :345-347 "There are two _optional_ aspects of unformed states that types
    may elect to explicitly specify (again by implementing interfaces, here by
    specializing the implementation rather than relying on the default
    fallback)." :351-360 "First, types may customize how to further initialize
    an object that is in the unformed state to most effectively harden it
    against erroneous usage. ... User defined types have the option of
    specifying a specific routine to do similar hardening initialization. The
    entire storage, including any padding bytes, for all types will be at
    least be zeroed as part of hardening initialization. This routine simply
    allows a user defined type to specifically customize the hardening
    initialization of some parts or members of the object to values other than
    zero." :630-642 "No unformed members"; :760-764 "This proposal suggests
    **not** allowing code to pass unformed objects to other functions as
    arguments or to return them."
-   docs/design/README.md:377-383 "## Build modes" / "The behavior of the Carbon
    compiler depends on the _build mode_:" / "In a _debug build_, the priority
    is diagnosing problems and fast build time." / "In a _release build_, the
    priority is fastest execution time and lowest memory usage." :1303-1304 (the
    fork's copy :1320-1321) "This binding will be implemented using a pointer,
    unless it is legal to copy and copying is cheaper." :2127-2132 "A type might
    have more than one in-memory representation for the unformed state ... Types
    may define additional initialization for the hardened build mode. For
    example, this causes integers to be set to `0` when in unformed state in
    this mode." (the words "hardened build mode" link the build modes section,
    `#build-modes`)
-   docs/design/safety/README.md:80-81 "We instead focus on the narrow and
    specific unsafe operations and constructs." :98-99 "_Strict Carbon_ is the
    mode in which all unsafe code is marked with the `unsafe` keyword". :116-124
    the two future-work blocks (mode syntax; marking imports). :207-262 "Build
    modes": "There are two primary build modes:" (:212), **Release** (:214-215)
    and **Debug** (:216-217); "The release build will include a baseline of
    hardening necessary to uphold the run-time enforcement components of our
    memory safety model above. This means, for example, that bounds checking is
    enabled in the release build." (:219-222); "Carbon will provide ways to
    write unsafe code that disables the run-time enforcement, enabling the
    control of any overhead incurred." (:224-226); the debug build's fail-stop
    and AddressSanitizer and MemorySanitizer-class detection (:231-235); the
    extensions, each "an extension of either the debug or release build for
    that specific purpose" (:242-252); and "Carbon will provide a way to
    disable the default hardening in release builds, but not in a supported
    way. Its use is expected to be strictly for benchmarking purposes."
    (:260-262). :266-283 "Probabilistic techniques likely cannot stop attacks".
-   docs/design/expressions/arithmetic.md:151-165 the three rows: "In a
    development build, they will be caught immediately when they happen at
    runtime." / "In a performance build, the optimizer can assume that such
    conditions don't occur. As a consequence, if they do, the behavior of the
    program is not defined." / "In a hardened build, overflow and division by
    zero do not result in undefined behavior. ... no control flow or memory
    access that depends on the value will be performed." :171-173 "**TODO:** In
    a hardened build, should we prefer to trap on overflow, give a two's
    complement result, or produce zero? Using zero may defeat some classes of
    exploit, but comes at a code size and performance cost."
-   docs/design/values.md:117 "only entire reference expressions can be
    destructively moved"; :119-122 the future-work note on moving from
    pointer dereferences; :186-192 value bindings and the `var` pattern that
    "takes ownership of the newly-allocated temporary storage"; :442-445 "A
    value cannot be mutated, cannot have its address taken, and may not have
    storage at all or a stable address of storage."; :456-463 "When forming a
    value expression from a reference expression, Carbon acquires the value of
    the referenced object. This allows immediately reading from the object's
    storage into a machine register or a copy if desired, but does not require
    that. ... Once an object is bound to a value expression in this way, any
    mutation to the object or its storage ends the lifetime of the value
    binding, and makes any use of the value expression an error."; :465-475 the
    two notes ("not intended to ever become "undefined behavior"" and
    "**experimental**"); :573-595 the escape-hatch open question; :1353-1398
    "Value representation and customization": "while Carbon code must be
    correct with either a copy or a reference-based implementation, we want
    which implementation strategy is used to be a predictable and customizable
    property of the type of a value" (:1358-1361), `value_rep` with
    `const Self` ("forces the use of a _copy_"), `const ref` ("forces the use
    of a pointer to the original object") or a custom type (:1363-1382), a
    placeholder syntax (:1374-1375), and, with no customization, heuristics:
    "Non-copyable types and polymorphic types would use a `const ref`." /
    "Small objects that are trivially copied in a machine register would use
    `const Self`." (:1393-1398).
-   Upstream's toolchain, which the fork's toolchain is, picks the value
    representation in toolchain/check/type_completion.cpp at 0421bf3b4, in
    three branches (amended 2026-10-28, review fold: A-M-2; rev 1 said "every
    class ... a pointer to the object", which is wrong for an adapter and for
    a struct or tuple whose elements' representations differ):
    -   A copy: `bool`, the integer, floating-point and pointer types
        (:697-751); a struct or tuple of one element, whose value is a copy of
        a one-element aggregate of its element's value representation ("The
        value representation for a struct or tuple with a single element is a
        struct or tuple containing the value representation of the element.",
        :572-578), so that the element's own representation decides what it
        holds; and, as the same type's representation, an adapter ("The
        object and value representation of an adapter are the object and
        value representation of its adapted type.", :762-770), `const T`
        (:783-789) and `MaybeUnformed(T)` for a copy-represented `T` other
        than `bool` (:803-826). So `Core.Optional(T*)`, which adapts
        `MaybeUnformed(T*)` (the fork prelude's optional.carbon:30-46 and
        :188-189 at 2407efa74), is copy-represented.
    -   A pointer to the object: every class that is not an adapter ("the
        value representation for a class is a pointer to the object
        representation", :771-781, with "TODO: Support customized value
        representations for classes." and "TODO: Pick a better value
        representation when possible." at :775-776) and every array (:674-695,
        "For arrays, it's convenient to always use a pointer representation");
        and a struct or tuple of more than one element whose elements' value
        representations are all copies of their object representations
        (`ValueAndObjectAggregate`, :568-570, :597-609, :620-627).
    -   A pointer to a separate elementwise aggregate: a struct or tuple of
        more than one element with an element whose value representation is
        not a copy of its object representation (`ValueAggregate`): "For a
        struct or tuple with multiple fields, we use a pointer to the
        elementwise value representation" (:580-582), which copies the
        copy-represented elements and points to the others.

    The second and third branches are both a pointer, not a copy, so the
    criterion of proposal p005434 (:660, "objects with a non-copy-value
    representation") is the same for both; the aggregate kind decides only
    what an implementation reads at the binding. Upstream's prelude
    `Core.String` (core/prelude/types/string.carbon:16-26) is a class of two
    private fields, so its value representation is a pointer.

### §0.2 PR 67's quote and silence checks for the H1 rows

Run from a detached worktree of 56e2e5bbd at /dev/shm/safe2-planner/rg1
(removed after the run) against /home/user/carbon-lang at 0421bf3b4:

-   `fork/register/check_quotes.sh /home/user/carbon-lang 0421bf3b4
    fork/register/rg1-quotes.tsv`: "checked 273 quotes, 0 failed".
-   `fork/register/check_greps.sh /home/user/carbon-lang 0421bf3b4
    fork/register/rg1-checks.tsv`: "checked 89 silence checks, 0 failed".
-   The H1 subset (the 90 quote rows on p005434, p005914, safety/README.md,
    arithmetic.md, values.md, README.md:377-383 and :474-486 and :2126-2135,
    and the two parser files; the five checks H1.1, H1.3, H1.4, H1.7 and
    H1.15): 90 of 90 and 5 of 5 pass.

Re-run for rev 3 at 22f3cd353 from a detached worktree of 56e2e5bbd at
/dev/shm/safe2-fixer1/rg1 (removed after): "checked 273 quotes, 0 failed" and
"checked 89 silence checks, 0 failed"; over the rows with Appendix C.2's eleven
appended, "checked 284 quotes, 0 failed" (at 0421bf3b4 too), and over the
checks with H1.7 widened, "checked 89 silence checks, 0 failed".

Re-run for rev 4 at 07718a832 from a detached worktree of 56e2e5bbd at
/dev/shm/safe2-fixer2/rg1 (removed after; added 2026-10-28, review fold:
RR2-B1): "checked 273 quotes, 0 failed" and "checked 89 silence checks, 0
failed"; the 97 quote rows on p005434, arithmetic.md, safety/README.md and
docs/design/README.md, the files the H1 rows quote for the six items, "checked
97 quotes, 0 failed"; with Appendix C.2's eleven rows, "checked 284 quotes, 0
failed"; with H1.7 widened, "checked 89 silence checks, 0 failed".

Re-run for rev 5 at 07718a832 from a detached worktree of 56e2e5bbd at
/dev/shm/safe2-fixer3/rg1 (removed after; added 2026-10-28, review fold:
RR3-M1): "checked 273 quotes, 0 failed" and "checked 89 silence checks, 0
failed"; the same 97 rows, "checked 97 quotes, 0 failed"; the 120 rows on
p005434, p005914, p000257, values.md and the three README and arithmetic
files, "checked 120 quotes, 0 failed"; the five H1 checks, "checked 5 silence
checks, 0 failed"; with Appendix C.2's eleven rows, "checked 284 quotes, 0
failed"; with H1.7 widened, "checked 89 silence checks, 0 failed".

Re-run for the document-review fold at 9192ee003 from a detached worktree of
56e2e5bbd at /dev/shm/safe2-fixer/rg1 (removed after; added 2026-10-28,
document-review fold: R1-m3): "checked 273 quotes, 0 failed" and "checked 89
silence checks, 0 failed"; the 97 and the 120 rows, "checked 97 quotes, 0
failed" and "checked 120 quotes, 0 failed"; the five H1 checks, "checked 5
silence checks, 0 failed"; and the nine upstream lines the fold quotes
(docs/design/assignment.md:76, :77, :80, :82 and :184, p005434:83, :302, :314
and :316), "checked 9 quotes, 0 failed".

So the break conditions of H1.8 to H1.12 have not fired: no accepted upstream
proposal narrows p005434:83 (H1.8); upstream has not relaxed p005434:663
(H1.9) nor reconsidered :831-834 (H1.10); arithmetic.md:156-158 and the
build-mode pages are unchanged, so D-RG-20's reading stands (H1.11); and
safety/README.md:260-262 is unchanged (H1.12). Those five are realigned.

### §0.3 A classification corrected: p000257:356-358 (H1.13, W-353)

H1.13's break condition is "an accepted upstream memory-safety design that makes
unformed-state zeroing language-defined for every type (cite it and close this
item)", and W-353's notes repeat it. Nothing upstream changed to meet it: the
text that does was accepted before the cut, and SAFE-1's I5 already cited it
when RG-1 filed W-353 (initialization_safety.md:223-226 at 2407efa74, "Proposal
p000257 already asked that the entire storage, padding bytes included, be zeroed
as hardening initialization (p000257:355-358)"). What was wrong is the
classification: H1.13's quote set left that passage out. W-353 is therefore
closed as a classification corrected, not as a break condition that fired, and
H1.13 is re-classified ALIGNED by a dated amendment on PR 67 (Appendix C.2;
amended 2026-10-28, review fold: A-m-3, B-M1; rev 1 headed this section "A break
condition that fired" and cited :355-358, but the sentence begins on :356). The
accepted proposal p000257, "Initialization of memory and variables", which
defines the unformed state the design overview summarizes and whose
README.md:2138-2141 references block the overview's paragraph cites, states at
:356-358: "The entire storage, including any padding bytes, for all types will
be at least be zeroed as part of hardening initialization." The hardening
initialization it describes is the hardened build's (:179-182, "in a hardened
build we have a strong mitigation that restores safety by defining the behavior
using a maximally safe representation"), and what a type may define is the
customization beyond the zeroing: "This routine simply allows a user defined
type to specifically customize the hardening initialization of some parts or
members of the object to values other than zero." (:358-360).
README.md:2130-2132's "Types may define additional initialization for the
hardened build mode" is that customization, "additional" to the zeroing every
type receives. The passage was there at the cut and at the tip (no commit since
the cut touches p000257); RG-1's H1.13 row quotes README.md:2130-2132 and
p005914:87-88 but not p000257:356-360, and fork/register/rg1-quotes.tsv quotes
p000257 only at :274, so no weekly check watches the passage; Appendix C.2 adds
quote rows for :356, :357 and :359. Under D-RG-20 (fork/register/rg1-plan.md)
the hardened build is the release build. So D-SAFE-13 I5's "Release
`make_uninitialized` zero-fills the whole object including padding" is p000257's
rule in upstream's place, and its mandate for every type is not a drift: W-353
is **closed, its classification corrected** (D-SAFE2-12). What stays to realign
is text, and SAFE-2 does it: the disclosures that call the zeroing a departure
or a promotion (README.md:2151-2153 and I5 on PR 53) state upstream's position
wrongly, and I5 omits the type-defined customization that p000257:358-360 and
README.md:2130-2131 describe. Break condition of this reading: a reviewer shows
that README.md:2130-2132, or an accepted proposal later than p000257, supersedes
p000257:356-358's zeroing for all types; then W-353 is realigned as its brief
states, by the alternative texts of Appendix B.5.

### §0.4 PR 53's dependent lines at 2407efa74 (D-RG-7's table re-measured)

D-RG-7's table was measured at adaae4e35. `git diff --stat adaae4e35 2407efa74`
touches fork/decision-log.md only (48 lines, RG-1's H53 records), so every page
line is unchanged and the table's line numbers hold. `git grep -n -E
'\b(D-SAFE-8|D-SAFE-11|D-SAFE-13|D-SAFE-14|D-SAFE-15|D-SAFE-17)\b' 2407efa74 --
docs` gives 66 hits on 63 distinct lines (values.md:137,
safety/temporal_safety.md:75 and safety/spatial_safety.md:66 each name two
decisions), exactly D-RG-7's sets: D-SAFE-8 13, D-SAFE-17 20, D-SAFE-11 7,
D-SAFE-15 8, D-SAFE-14 5, D-SAFE-13 13. D-SAFE-19, which exports D-SAFE-17's
binding, adds 11 lines (safety/README.md:398, :402; rust_interop.md:50, :149,
:236, :319, :378, :553, :606; temporal_safety.md:140, :144), listed with the
wider grep below. The listing gives each of the 63 lines as four fields
separated by vertical bars, the line (under docs/design/ at 2407efa74), the
item, the disposition and the line's text verbatim, fenced so that the quoted
links and table pipes stay inert; the disposition is the Appendix A block that
rewrites the line, or "no change" with the reason. A line that names a decision
but states a rule SAFE-2 does not touch (I4, SP3, T5(g), a pointer to another
page) is "no change"; R17 is checked against what the line says, not against the
id it carries.

<!-- google-doc-style-ignore -->

```text
README.md:2151 | W-353 | A.8.1 | > **Fork amendment (2026-10-12, F-013 D-SAFE-13 I5).** The fork promotes this
README.md:2175 | W-353 | no change: the move blockquote, I4, which SAFE-2 does not touch | > **Fork amendment (2026-10-12, F-013 D-SAFE-13).** The fork fixes `~x` as a
expressions/arithmetic.md:167 | W-350 | A.9.1 | > **Amendment (2026-10-12, SAFE-1 — F-013 D-SAFE-15):** for Carbon code the
safety/README.md:322 | W-348 | no change: the invalidating case keeps its row; A.1.3 inserts three rows after it | | `StrictSharedBorrowInvalidated` ([temporal safety](temporal_safety.md)) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` for the value-binding case (D-SAFE-17) |
safety/README.md:561 | W-351 | A.1.6 | > **Withdrawn (fork amendment 2026-10-12, F-013 D-SAFE-14).** The fork provides
safety/initialization_safety.md:64 | W-353 | no change: names the sub-decision; A.4.1 appends the status sentence | sub-decision D-SAFE-13, synthesized in [fork/safe/plan.md](/fork/safe/plan.md).
safety/initialization_safety.md:127 | W-353 | no change: I2, unchanged | fold: D-12; D-SAFE-13 amended identically). Conditional initialization is
safety/initialization_safety.md:193 | W-353 | no change: I4, unchanged | document-review fold: D-13; D-SAFE-13 amended identically).
safety/initialization_safety.md:455 | W-353 | A.4.4 | -   **D-SAFE-13 — Initialization: definite formation, zero-fill, moves.** I1
safety/initialization_safety.md:517 | W-353 | A.4.5 | question is the break condition of D-SAFE-13, not a reason to leave the
safety/mutation_safety.md:74 | W-348 | no change: names the sub-decisions; A.2.2 appends the status sentence | sub-decisions D-SAFE-9, D-SAFE-16, D-SAFE-17 and D-SAFE-20, synthesized in
safety/mutation_safety.md:76 | W-347 | no change: names D-SAFE-8 as the pointer kinds' owner, still true | the strategy page and the pointer kinds are D-SAFE-7 and D-SAFE-8 on the
safety/mutation_safety.md:143 | W-347 | A.2.3 | inherits the kind of its source (D-SAFE-8): a `ref` formed from a place is
safety/mutation_safety.md:159 | W-347 | A.2.4 | place in the set (D-SAFE-8).
safety/mutation_safety.md:282 | W-348 | A.2.7 | D-SAFE-17, stated in full with its memory-safety argument under
safety/mutation_safety.md:419 | W-348 | A.2.8 | erroneous. D-SAFE-17 ratifies that rule into Strict Carbon in three parts, by
safety/mutation_safety.md:463 | W-349 | A.2.8 | narrowing is applied at the temporal page's D-SAFE-11(d), where a `bound`
safety/mutation_safety.md:465 | W-348 | A.2.8 | loan. The alternative recorded in D-SAFE-17 is eager acquisition for every
safety/mutation_safety.md:619 | W-348 | A.2.12 | // i32 is Plain, the binding copies eagerly (D-SAFE-17), there is no loan to invalidate; b is 1)
safety/mutation_safety.md:832 | W-348 | A.2.19 | -   **D-SAFE-17 — Value bindings through shared pointers.** A `Plain` value
safety/mutation_safety.md:850 | W-347 | A.2.19 | and the `ref`-kind inheritance of M1 are D-SAFE-7 and D-SAFE-8, and the
safety/mutation_safety.md:886 | W-348 | A.2.20 | rather than inherited, which D-SAFE-17 does under
safety/mutation_safety.md:906 | W-348 | A.2.20 | of D-SAFE-17 and its break condition.
safety/mutation_safety.md:936 | W-348 | A.2.21 | D-SAFE-17 narrows.
safety/rust_interop.md:132 | W-348 | A.6.1 | same writes are permitted (D-SAFE-17). A Rust `&IntVec` reachable from the
safety/rust_interop.md:197 | W-353 | no change: I4 relocation, unchanged | | Ownership transfer | A `Core.Relocatable` value crosses by value: a bitwise relocation leaves the source unformed (I4, D-SAFE-13). A non-`Relocatable` value never crosses by value | `repr(C)` struct for a `Relocatable` type, with a generated `Drop` thunk that runs the Carbon destructor; an owning opaque handle otherwise | A value received by Rust is owned by Rust: Carbon holds no loan on it (a moved-from object is unformed, and I2 forbids its use). Safe Rust relies on the value being a complete, formed object of the declared `repr` | after stage 4 (the `Relocatable` facet and the move operator) |
safety/rust_interop.md:217 | W-353 | no change: the `Core.Relocatable` facet, I4, unchanged | | a `Core.Relocatable` value | `repr(C)` struct by value, with a generated `Drop` thunk | The facet decides by-value crossing (D-SAFE-13) | after stage 4 |
safety/rust_interop.md:399 | W-348 | A.6.4 | `&SharedSlice<T>` stand in for them, which is the D-SAFE-17 value-binding
safety/rust_interop.md:585 | W-348 | no change: names D-SAFE-17 as the value-binding rule's owner, still true | the facets and the value-binding rule are D-SAFE-9, D-SAFE-16 and D-SAFE-17
safety/rust_interop.md:587 | W-353 | no change: I4, unchanged | operator are D-SAFE-13 ([initialization safety](initialization_safety.md)); the
safety/rust_interop.md:633 | W-348 | A.6.6 | -   **Eager-copy value bindings, for a `&T` mapping.** D-SAFE-17's recorded
safety/spatial_safety.md:66 | W-350, W-351 | no change: names the sub-decisions; A.5.2 appends the status sentence | sub-decisions D-SAFE-14 and D-SAFE-15, synthesized in
safety/spatial_safety.md:248 | W-350 | A.5.5 | reach the wrong element without the program noticing. The rule (D-SAFE-15,
safety/spatial_safety.md:405 | W-350 | A.5.6 | -   **EX-SP-6 (D-SAFE-15, division by zero).** `Div(1, 0)` reaches an
safety/spatial_safety.md:420 | W-350 | no change: the checklist row's outcome and stage hold; the prose change is A.5.6 | | D-SAFE-15 division | EX-SP-6 | ACCEPTS-UNCHECKED | handle_call.cpp:188-192 | 2 (W-146) |
safety/spatial_safety.md:510 | W-351 | A.5.9 | -   **D-SAFE-14 — Spatial: fail-stop everywhere, `unsafe fn` is the opt-out,
safety/spatial_safety.md:534 | W-350 | A.5.9 | -   **D-SAFE-15 — Arithmetic.** Release: signed overflow wraps, the existing
safety/spatial_safety.md:556 | W-351 | A.5.10 | runtime core. The synthesis withdraws it (D-SAFE-14, review fold A-13(c) in
safety/spatial_safety.md:584 | W-350 | no change, history: what attempt C contributed | which is D-SAFE-15. What this page keeps from C is therefore its runtime
safety/spatial_safety.md:611 | W-350 | A.5.11 | | The run-time cost of bounds checking in a hardened standard library is small enough that production deployments enable it by default, the figure the strategy's evidence link reports | The expectation in SP2 that the check is cheap; no rule depends on the figure | UNVERIFIED: we expect the figure to be below one percent on typical workloads, as the linked account reports; the fork's own measurement is what D-SAFE-15's 0.5 percent break condition reads |
safety/temporal_safety.md:75 | W-347, W-349 | no change: names the sub-decisions; A.3.1 appends the status sentence | sub-decisions D-SAFE-7, D-SAFE-8, D-SAFE-10, D-SAFE-11 and D-SAFE-12, with the
safety/temporal_safety.md:76 | W-353 | no change: I4 relocation, unchanged | relocation rule of D-SAFE-13, synthesized in
safety/temporal_safety.md:191 | W-347 | A.3.4 | A `ref` binding inherits the kind of its source (D-SAFE-8). A `ref` formed from
safety/temporal_safety.md:212 | W-347 | A.3.4 | > **Narrowing (fork amendment 2026-10-12, F-013 D-SAFE-8).** Proposal p005434
safety/temporal_safety.md:250 | W-348 | A.3.5 | shared loan on the bound object for the binding's lifetime (D-SAFE-17, rule
safety/temporal_safety.md:321 | W-349 | no change: names T5's owner | T5 is the `bound` contract of D-SAFE-11, stated in its own section,
safety/temporal_safety.md:475 | W-349 | no change: names T5's owner | This section is D-SAFE-11 and rule T5. `bound` is the one lifetime annotation,
safety/temporal_safety.md:505 | W-348 | A.3.9 | same narrowing D-SAFE-17 applies to value bindings. This is a dated
safety/temporal_safety.md:524 | W-349 | no change: T5(g), unchanged | document-review fold: D-3; D-SAFE-11(g) amended identically). A Strict
safety/temporal_safety.md:585 | W-353 | no change: the `Core.Relocatable` facet, I4, unchanged | defined structurally (D-SAFE-13): a type is `Relocatable` when all of its
safety/temporal_safety.md:628 | W-348 | A.3.10 | | `StrictSharedBorrowInvalidated` | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` for the value-binding case (D-SAFE-17) |
safety/temporal_safety.md:761 | W-349 | no change: T5(g), unchanged | unsafe class Holder { var p: i32*; }  // D-SAFE-11(g): fields ⊥, a ⊥ store destination (A-15); plain `class` until bound(a) lands at stage 6
safety/temporal_safety.md:907 | W-347 | A.3.13 | Rules T6, T2, T5(a) and D-SAFE-8; the programs the plan's reviews added, kept
safety/temporal_safety.md:947 | W-347 | A.3.13 | -   **`Pick`, `UsePick`** (D-SAFE-8). `Pick`'s result carries `{(r, exclusive),
safety/temporal_safety.md:968 | W-347 | A.3.13 | | D-SAFE-8 mixed-kind result | EX-TM-8 `Pick`/`UsePick` | NEW-SYNTAX (`bound`) | p005434 `Conditional` | 1, 4 |
safety/temporal_safety.md:1096 | W-347 | A.3.16 | -   **D-SAFE-8 — `ref` bindings inherit the kind of their source.** A `ref`
safety/temporal_safety.md:1109 | W-349 | A.3.16 | -   **D-SAFE-11 — `bound` semantics fixed; named lifetimes pinned.** As stated
safety/temporal_safety.md:1125 | W-353 | no change: I4, unchanged | move operator are D-SAFE-13 ([initialization safety](initialization_safety.md));
safety/temporal_safety.md:1128 | W-348 | no change: names D-SAFE-17 as the mutation page's, still true | D-SAFE-17 ([mutation safety](mutation_safety.md)); the C++ annotation mapping
safety/temporal_safety.md:1155 | W-347 | A.3.17 | D-SAFE-8 are that repair: `exclusive T*` exists, and a `ref` through `*p`
slices.md:65 | W-351 | no change: SP3, unchanged (section 3 step 1) | > **Amendment (2026-10-12, SAFE-1 — F-013 D-SAFE-14 SP3):** in Strict Carbon
values.md:137 | W-347, W-348 | A.7.1 | > **Answered (2026-10-12, SAFE-1 — F-013 D-SAFE-7, D-SAFE-8, D-SAFE-17):** a
values.md:485 | W-348 | A.7.2 | > **Pinned (2026-10-12, SAFE-1 — F-013 D-SAFE-17):** a value binding of a
```

<!-- google-doc-style-resume -->

### §0.5 The wider grep: every line stating one of the six rules

The rules' own words over the touched pages at 2407efa74 (`git grep -n -i -E`
for noalias, `captures(none)`, nocapture, "not invalidated", immutable,
`MutationDuringValueBinding`, `SharedView`, "performance build", benchmark,
zero-fill, hardened, shadow, eager, weakest, "every build mode", "only opt-out",
"copies eagerly", "`Plain`-field write" and "value binding", plus D-SAFE-19,
over docs/design/safety, values.md, README.md, expressions/arithmetic.md and
slices.md) give 202 lines beyond the 63. Each is listed below as three fields
separated by vertical bars, the line, the disposition and the line's text
verbatim, fenced as in section 0.4. A line of
upstream text the fork does not amend (README.md:480, values.md:150 and the
like) is "no change, upstream's text"; a line of the panel record or an
attempt's history is "no change, history"; a table-of-contents entry whose
heading Appendix A renames is regenerated by the prek toc hook. Two lines that
no word of the grep reaches state W-349's narrowed rule by example and are
listed too, slices.md:53 and :61: under T5(d) the opening example's
`a[2] = 30` while the view `s` lives is rejected in Strict (amended
2026-10-28, review fold: RR1-M1). Six more that no word of the grep reaches
state the by-value `Core.Buf(T).Set` that D-SAFE2-5 now gives `ref self`, and
are listed too: safety/README.md:133 (the prelude's trusted bodies, which gain
the write rule), temporal_safety.md:725 and :741 (EX-TM-3's `buf.Set(1, 7)`
under the live view), rust_interop.md:213 (the `Core.Slice(const T)` row's
"`Buf.Set` during a live view"), slices.md:162 and :243 (the receiver), with
slices.md:258's disposition changed (amended 2026-10-28, review fold: RR2-B1).
Six more state how EX-M-1's `IntVec` writes an element, which `Set`'s
`ref self` changes for the body of `IntVec.Set`, and are listed too:
mutation_safety.md:536 (the `addr self` declaration), :556-558 (the reason,
which the round-3 re-review cites as :555-556) and :736 and :742 (the C++
partition bullet, which it cites as :736-741) (amended 2026-10-28, review
fold: RR3-m1). Two more name W-144's `bound self` producers and stay as they
are, spatial_safety.md:174 (SP3) and temporal_safety.md:509 (T5(e))
(amended 2026-10-28, review fold: RR3-M1).

<!-- google-doc-style-ignore -->

```text
README.md:480 | no change, upstream's text; the rows stand (A.9.1) | -   In a performance build, the optimizer can assume that such conditions don't
README.md:483 | no change, upstream's text; the rows stand (A.9.1) | -   In a hardened build, overflow does not result in undefined behavior.
README.md:2148 | no change, upstream's text, which A.4.2 and A.8.1 cite | initialization for the [hardened build mode](#build-modes). For example, this
README.md:2152 | A.8.1 | > zeroing to the Release baseline for every type; there is no separate hardened
README.md:2725 | no change: "shadowing" of names, not the rules | [shadowing](https://en.wikipedia.org/wiki/Variable_shadowing) of names.
expressions/arithmetic.md:156 | no change, upstream's text, read by A.9.1 | -   In a performance build, the optimizer can assume that such conditions don't
expressions/arithmetic.md:159 | no change, upstream's text, read by A.9.1 | -   In a hardened build, overflow and division by zero do not result in
expressions/arithmetic.md:180 | no change: upstream's TODO, answered for Release by A.9.1 | **TODO:** In a hardened build, should we prefer to trap on overflow, give a
safety/README.md:332 | no change: the C++ boundary still withholds `noalias` (T8) | only, never a codegen one, because the loan checker withholds `noalias` and
safety/README.md:333 | no change: the C++ boundary still withholds `noalias` (T8) | `captures(none)` at every such boundary ([Temporal safety](temporal_safety.md),
safety/README.md:133 | A.1.1 (added 2026-10-28, review fold: RR2-B1): a sentence appended, the trusted bodies' write rule | The prelude is the first client of this model. `Core.Slice`, `Core.Buf` and
safety/README.md:379 | no change: zero-fill in Release stands (section 0.3) | checked in Strict over unformed storage, zero-fill in Release, and moves
safety/README.md:382 | A.1.4 | and fails-stop in every build mode, `unsafe fn GetUnchecked` is the only
safety/README.md:388 | no change: names the topics, not the rule | place, the no-invalidation rule with `Core.Plain`, value bindings, and
safety/README.md:398 | no change: the kinds table stands; A.1.5 adds a paragraph after it | | Kind | Spelling | Formed by | Loan kind | Through it you may | Receiver form | Rust analogue (D-SAFE-19) |
safety/README.md:402 | no change: a `const T*` carries a shared loan, still true; A.1.5 follows the table | | shared-const | `const T*` | conversion from either kind; C++ `const T&` | shared (const) | read; `const` methods | `ref self: const Self`, by-value `self` | `&SharedView<T>` (`&T` only under the D-SAFE-19 proviso) |
safety/README.md:423 | no change: the C++ allowlist row, not the rules | | 3. The members of `std::atomic<T>` and `std::thread` that fork decision F-008 models: `fetch_add`, `load`, `store`, the constructor taking a Carbon function value, `join` | Their contract is fixed by the 0.1 threading decision ([fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)); the function value crossing is the export case under which the loan checker emits no `noalias` | cpp_thread_carbon_fn_diff.carbon:38-52 (`Cpp.hits.fetch_add(...)`, `Cpp.std.thread.thread(Work)`, `Cpp.hits.load()`) |
safety/README.md:558 | no change, upstream's text, now kept (A.1.6) | but not in a supported way. Its use is expected to be strictly for benchmarking
safety/README.md:562 | A.1.6 | > no build flag that disables the default hardening, for benchmarking or
safety/README.md:673 | A.1.7 | | 2 | Runtime hardening regardless of mode: array index fail-stop, division by zero fail-stop, `--build-mode=debug\|release`, Release zero-fill | — |
safety/README.md:675 | A.1.7 | | 4 | The loan checker: loans, `bound`, no-invalidation, `exclusive`; `error` default; `noalias` under T8 | The matrix's error column |
safety/README.md:728 | no change, history: the design panel | and re-meant `const T*` as shared-immutable; judge 1 found both fatal because
safety/README.md:731 | no change, history: the design panel | `noalias` claim. Attempt B, "Places, projections and shared cells", kept `T*`
safety/README.md:735 | no change, history: the design panel | Attempt C, "Ratchet: hardened runtime core now, annotated borrows later", made
safety/initialization_safety.md:19 | no change: the I5 heading stands | -   [I5: Zero-fill in Release, poison in Debug](#i5-zero-fill-in-release-poison-in-debug)
safety/initialization_safety.md:47 | no change: the overview's zero-fill stands | zero-fill unformed storage so that a read which escapes the check is erroneous
safety/initialization_safety.md:119 | no change: I2, unchanged | Every read, member access, method call, value binding, `&x`, `ref` binding or
safety/initialization_safety.md:214 | no change: the I5 heading stands | ### I5: Zero-fill in Release, poison in Debug
safety/initialization_safety.md:216 | A.4.2 | In every safety mode, the Release build's `make_uninitialized` zero-fills the
safety/initialization_safety.md:218 | A.4.2 | is assigned. This promotes the design overview's hardened-mode sentence —
safety/initialization_safety.md:226 | A.4.2 | hardened build for this purpose, recorded as a dated amendment at the
safety/initialization_safety.md:422 | no change: Release zero-fill stands | Release zero-fill is what C++ sees. A C++ function that reads a Carbon object
safety/initialization_safety.md:436 | no change: 0.1 claims nothing, still true | diagnosed or zero-filled by the 0.1 toolchain.
safety/initialization_safety.md:441 | A.4.3 | | 2 | Runtime hardening regardless of mode | I5: Release `make_uninitialized` zero-fill of the whole object; Debug poison-fill and the read-of-unformed fail-stop |
safety/initialization_safety.md:465 | A.4.4 | move. I5 Release zero-fills the whole object in every mode and Debug
safety/initialization_safety.md:467 | A.4.4 | Break condition: a benchmark in the fork showing more than 0.5 percent
safety/initialization_safety.md:468 | A.4.4 | from zero-fill alone — then zero-fill is scoped to escaped-unformed
safety/initialization_safety.md:483 | A.4.5 | zero-fill, so the alternatives specific to this page are two pieces the
safety/initialization_safety.md:487 | no change, history: attempt C | "Ratchet: hardened runtime core now, annotated borrows later", put its 0.1
safety/initialization_safety.md:511 | A.4.5 | -   **Zero-fill in a hardened build only.** The design overview placed
safety/initialization_safety.md:512 | A.4.5 | zero-fill in a hardened build mode and the fork promotes it to the Release
safety/initialization_safety.md:513 | A.4.5 | baseline. Keeping it hardened-only was not taken because the
safety/initialization_safety.md:530 | A.4.6 | | Clang's `-ftrivial-auto-var-init=zero` zero-fills automatic storage in C and C++, and deployments of it report a cost small enough that production builds enable it | The plausibility of I5's 0.5 percent break condition; no rule depends on the figure | UNVERIFIED: we expect the option to exist under that name and the reported cost to be below one percent on typical workloads; the fork's own benchmark is what the break condition reads |
safety/mutation_safety.md:23 | no change: the M8 heading stands | -   [M8: Value bindings](#m8-value-bindings)
safety/mutation_safety.md:27 | no change: the section heading stands | -   [Value bindings](#value-bindings)
safety/mutation_safety.md:33 | regenerated by the toc hook (A.2.12 renames the heading) | -   [EX-M-4a: A `Plain` value binding](#ex-m-4a-a-plain-value-binding)
safety/mutation_safety.md:34 | regenerated by the toc hook (A.2.13 renames the heading) | -   [EX-M-4b: A non-`Plain` value binding](#ex-m-4b-a-non-plain-value-binding)
safety/mutation_safety.md:58 | A.2.1 | alternative while a payload reference lives; and a value binding of a
safety/mutation_safety.md:158 | A.2.4 | does. For a carrier whose loan set mixes kinds, the weakest kind governs every
safety/mutation_safety.md:272 | no change: the M8 heading stands | ### M8: Value bindings
safety/mutation_safety.md:274 | A.2.7 | A value binding of a `Plain` type copies eagerly and holds no loan, so
safety/mutation_safety.md:275 | A.2.7 | mutation of the source afterwards is accepted in every mode. A value binding of
safety/mutation_safety.md:279 | A.2.7 | `Plain`-field write through another alias is erroneous and Debug-reported as
safety/mutation_safety.md:280 | A.2.7 | `MutationDuringValueBinding`. A value binding of a non-`Plain` type from a
safety/mutation_safety.md:283 | A.2.7 | [Value bindings](#value-bindings).
safety/mutation_safety.md:413 | no change: the section heading stands (A.2.8 keeps it) | ## Value bindings
safety/mutation_safety.md:415 | A.2.8 | A value binding (`let x: T = e;`, a by-value parameter, a by-value `self`) is
safety/mutation_safety.md:422 | A.2.8 | -   **A `Plain` type acquires eagerly and holds no loan.** The binding is a
safety/mutation_safety.md:435 | A.2.8 | "mutation ends the lifetime of the value binding" becomes a static
safety/mutation_safety.md:437 | A.2.8 | `Plain`-field write through _another_ shared alias during the binding is
safety/mutation_safety.md:439 | A.2.8 | Debug-detected by a value-binding shadow flag. Debug keeps, in shadow
safety/mutation_safety.md:441 | A.2.8 | per-object count of live non-`Plain` value bindings, incremented when the
safety/mutation_safety.md:443 | A.2.8 | computes it; a `Plain`-field write through `T*` or `addr self` whose
safety/mutation_safety.md:444 | A.2.8 | target's count is non-zero reports `MutationDuringValueBinding`.
safety/mutation_safety.md:446 | A.2.8 | An initializing expression is the third source of a value binding, neither
safety/mutation_safety.md:469 | A.2.8 | exports as `&SharedView<T>`, not `&T`
safety/mutation_safety.md:487 | no change: the invalidating case's Debug column, as safety/README.md:322 | `MutationDuringValueBinding` for the value-binding case, and
safety/mutation_safety.md:511 | A.2.9 | -   `MutationDuringValueBinding`: the Debug report, one line in the fail-stop
safety/mutation_safety.md:513 | A.2.9 | mutation of an object during a live value binding; terminating", then
safety/mutation_safety.md:536 | no change: `IntVec.Set` keeps `addr self`, an `i32` element holding no `Core.SharedImmutable` sub-object; A.2.11 names its body's path (RR3-m1) | fn Set[addr self: Self*](i: i64, v: i32);        // non-invalidating: i32 is Plain
safety/mutation_safety.md:556 | A.2.11 (amended 2026-10-28, review fold: RR3-m1): a sentence names `Set`'s body path, `Core.Buf(T).Set` taking `ref self` | lifetime of every element and so is invalidating (M3(a)); `Set` is `addr self`
safety/mutation_safety.md:557 | A.2.11 (RR3-m1) | because writing an `i32` element is a `Plain` write (M3(c) does not fire) and
safety/mutation_safety.md:558 | A.2.11 (RR3-m1) | its body is checked to do nothing else; `Get` is `bound self` so its result is
safety/mutation_safety.md:615 | A.2.12 | ### EX-M-4a: A `Plain` value binding
safety/mutation_safety.md:622 | no change: the comment "eager copy" is true of a copy-represented binding | let b: i32 = a;                 // eager copy
safety/mutation_safety.md:628 | A.2.12 | Rule M8, the `Plain` case. `i32` is `Plain`, so `b` acquires eagerly and holds
safety/mutation_safety.md:633 | no change: true of a copy-represented binding; A.2.12 edits the sentence before | rule of the values design does not arise for an eager copy, and that design's
safety/mutation_safety.md:636 | A.2.13 | ### EX-M-4b: A non-`Plain` value binding
safety/mutation_safety.md:639 | A.2.13 | // EX-M-4b (fork-prelude syntax; accepted today — M8: a non-Plain value binding is a shared loan)
safety/mutation_safety.md:655 | no change: a `var` copy is one of D-SAFE2-5's fixes | fix is to end `b`'s use before the assignment or to copy eagerly with a `var`.
safety/mutation_safety.md:657 | no change: the toolchain outcome stands | the fork toolchain compiles it, the value binding being today's
safety/mutation_safety.md:722 | A.2.17 | | M8 value binding, `Plain` | EX-M-4a | ACCEPTS (today and in Strict; `b` is 1) | — |
safety/mutation_safety.md:723 | A.2.17 | | M8 value binding, non-`Plain` | EX-M-4b | ACCEPTS-UNCHECKED (fork prelude) | 4 |
safety/mutation_safety.md:736 | A.2.17a (added 2026-10-28, review fold: RR3-m1): a sentence appended to the bullet, the element writes that take `ref self` | `addr self` methods, the element writes and other non-invalidating
safety/mutation_safety.md:742 | A.2.17a (RR3-m1) | guarantees do not are the `addr self` ones. EX-M-1's `IntVec` is the
safety/mutation_safety.md:763 | no change: the C++ boundary still withholds `noalias` (T8) | withholds `noalias` at every such boundary. A `_Nonnull` or
safety/mutation_safety.md:774 | no change: the C++ boundary still withholds `noalias` (T8) | which no `noalias` is emitted.
safety/mutation_safety.md:790 | no change: 0.1 claims nothing, still true | pointer is diagnosed, no facet exists, and no value binding holds a loan in
safety/mutation_safety.md:797 | A.2.18 | | 4 | The loan checker (W-148) | M1 to M5: `Core.Plain` synthesis, `StrictInvalidatingThroughShared` with its twin `PermissiveAliasedExclusive`, the `addr` body check of M4, payload sub-loans of M5; M8: the non-`Plain` value-binding loan and the Debug shadow count behind `MutationDuringValueBinding`; M6: `Core.Guarded(T)` under W-144 |
safety/mutation_safety.md:833 | A.2.19 | binding copies eagerly and holds no loan; a non-`Plain` one from `*p` or
safety/mutation_safety.md:835 | A.2.19 | and `Plain`-field writes through other aliases stay erroneous and
safety/mutation_safety.md:839 | A.2.19 | memory-safety (not correctness) consequence — then the eager-copy
safety/mutation_safety.md:865 | no change, history: attempt A | shared-immutable, and added a NEW `shared T*` as the Ante-style
safety/mutation_safety.md:870 | no change, history: attempt A | an unverified `noalias` claim, and `const` acquiring "shared" reads a
safety/mutation_safety.md:887 | A.2.20 | [Value bindings](#value-bindings).
safety/mutation_safety.md:900 | A.2.20 | write through any alias during a non-`Plain` value binding and would
safety/mutation_safety.md:901 | A.2.20 | make a value binding of `i32` a loan. The first is rejected because it
safety/mutation_safety.md:903 | A.2.20 | aliased `Set` of EX-M-1 whenever a value binding of the container is
safety/mutation_safety.md:904 | A.2.20 | live; the second contradicts the eager copy the toolchain performs today
safety/mutation_safety.md:905 | A.2.20 | (EX-M-4a). The eager-copy-for-every-type rule is the recorded alternative
safety/mutation_safety.md:941 | no change: a reference to values.md | -   [values.md](/docs/design/values.md) on value bindings, acquisition and the
safety/mutation_safety.md:958 | no change: a reference to the Rust page | `&SharedView<T>`.
safety/rust_interop.md:20 | no change: the wrappers heading | -   [The `Shared<T>` and `SharedView<T>` wrappers](#the-sharedt-and-sharedviewt-wrappers)
safety/rust_interop.md:50 | no change: names the sub-decisions | sub-decisions D-SAFE-19 and D-SAFE-22, synthesized in
safety/rust_interop.md:93 | no change: the C++ boundary still withholds `noalias` (T8) | Strict; and the codegen rule T8 withholds `noalias` at every C++ boundary, so a
safety/rust_interop.md:126 | no change: the `T*` bullet, unchanged | allows. The [wrappers](#the-sharedt-and-sharedviewt-wrappers) section is
safety/rust_interop.md:131 | A.6.1 | and a value binding of a non-`Plain` type is a shared loan under which the
safety/rust_interop.md:135 | no change: the `const T*` rule stands; A.6.1 edits the sentence before | `const T*` exports as `&SharedView<T>`, the read-only `Cell`-shaped view,
safety/rust_interop.md:149 | no change: the transport, unchanged | The transport is analysis, not rule (D-SAFE-19): its three facts about Rust are
safety/rust_interop.md:198 | no change: the aliasing row's pointer kinds stand | | Aliasing and mutability | Three kinds: `exclusive T*` is the one live access path (T4, M2); `T*` admits aliases that write `Plain` fields and call `addr self` methods (M3); `const T*` reads. Invalidating operations need exclusive access (D-SAFE-9) | `&mut T`; `&Shared<T>`; `&SharedView<T>`, or `&T` under the proviso | A Strict signature's kinds are checked, so a `&mut T` received by Rust is unique for the call and a `&Shared<T>` is never read or written as a `&T`. Safe Rust relies on the usual meaning of `&mut`, and on `Shared<T>` exposing nothing M3 forbids | after stage 4 (the loan checker and `exclusive`) |
safety/rust_interop.md:201 | no change: the facets row, unchanged | | `Send`, `Sync` versus Carbon threads | Compiler-determined facets (D-SAFE-16): a `T*` or `Slice(T)` field makes a type neither; `exclusive T*` is `Send` iff `T: Send`; `const T*` is `Send` iff `T: Sync`; `unsafe impl` opts in. Thread-crossing APIs accept only free loan sets or join inside the borrow | `unsafe impl Send`/`Sync` emitted exactly when the Carbon facet holds; nothing exported `Send` or `Sync` before stage 5. `Shared<T>` and `SharedView<T>` are never `Sync` | A type Rust sees as `Send` is one Carbon's facet rules say may cross a thread, and Rust's `spawn` requires `'static`, the same free-loan-set rule as Carbon's `Core.Thread.Spawn`. Safe Rust relies on the auto-trait meaning of the emitted impls | after stage 5 (the facets) |
safety/rust_interop.md:210 | no change: the `const T*` default row stands; A.6.2 inserts after :211 | | `const T*` | `&SharedView<T>` | By default: the read-only `Cell`-shaped view | after stage 4 |
safety/rust_interop.md:213 | A.6.3a (added 2026-10-28, review fold: RR2-B1) | | `Core.Slice(const T)` | `&[T]` | Only for a `Freeze` element type under the same proviso as `&T`: `Buf.Set` during a live view is the temporal page's EX-TM-3, so a slice of a class reachable through `&Shared` cannot be `&[T]` | after stage 5 (`Freeze`) |
safety/rust_interop.md:228 | no change: the wrappers heading | ## The `Shared<T>` and `SharedView<T>` wrappers
safety/rust_interop.md:236 | no change: the wrappers sketch, unchanged | // Analysis sketch (D-SAFE-19), not generated code. One pair per exported class T.
safety/rust_interop.md:240 | no change: the wrappers sketch, unchanged | pub struct SharedView<T>(Shared<T>);
safety/rust_interop.md:252 | no change: the wrappers sketch, unchanged | pub fn view(&self) -> &SharedView<T> { unsafe { &*(self as *const Self as *const SharedView<T>) } }
safety/rust_interop.md:254 | no change: the wrappers sketch, unchanged | impl<T> SharedView<T> {
safety/rust_interop.md:304 | stands; A.6.2 appends a sentence to this bullet | are immutable, which is undefined behavior for the holder of the `&T`.
safety/rust_interop.md:307 | stands; A.6.2 appends a sentence to this bullet | `&SharedView<T>` otherwise; the generator checks the whole set, not one
safety/rust_interop.md:319 | stands; A.6.5 appends a sentence to this paragraph | Break condition (D-SAFE-19): a Rust soundness argument against the wrapper —
safety/rust_interop.md:336 | A.6.3 | fn At[bound self: Self](i: i64) -> const i32*;      // → fn at<'a>(&'a SharedView<Self>, i: i64) -> &'a SharedView<i32>   (stage 4; never &'a i32 for an exported class — A-9)
safety/rust_interop.md:339 | no change: `Longest` takes pointers, whose rows stand | fn Longest(bound a: const Core.String*, bound b: const Core.String*) -> const Core.String*;   // → fn longest<'a>(a: &'a SharedView<str>, b: &'a SharedView<str>) -> &'a SharedView<str> (stage 4: one lifetime shared by both bound parameters, D-10; &str needs Core.Utf8 and the Freeze proviso)
safety/rust_interop.md:347 | A.6.3 | receiver. The receiver exports as `&'a SharedView<Self>` and the result as
safety/rust_interop.md:348 | A.6.3 | `&'a SharedView<i32>`, not `&'a i32`: `i32` is `Freeze`, but the element
safety/rust_interop.md:372 | no change: `Longest` takes pointers, whose rows stand | `&'a SharedView<str>` rather than `&'a str`: `&str` needs the UTF-8
safety/rust_interop.md:378 | no change: names the decision | The four parts of D-SAFE-19, stated against [the bar](#the-bar).
safety/rust_interop.md:382 | A.6.4 | as `&SharedView<T>`, with `bound`-expressible lifetimes, `Core.Optional(T*)`
safety/rust_interop.md:398 | A.6.4 | are never produced for exported classes and slices; `&SharedView<T>` and
safety/rust_interop.md:404 | no change: multi-lifetime imports, unchanged | conservatively, with the weakest kind and the union of the loan sets
safety/rust_interop.md:449 | no change: I5 and I6 for a by-value crossing stand | -   **Zero-fill.** A `Relocatable` value crossing by value is a formed object
safety/rust_interop.md:450 | no change: I5 and I6 for a by-value crossing stand | (I6: no unformed object is passed or returned), so Release zero-fill (I5)
safety/rust_interop.md:468 | no change: C++ `const T&` stays `&SharedView<T>` | exports as `&SharedView<T>`. Nothing on the C++ side is ever
safety/rust_interop.md:507 | no change: the string view, unchanged | or `&SharedView<str>`; the Carbon-side bounds check is the only check
safety/rust_interop.md:538 | no change: staging row 4, unchanged | | 4 | The loan checker: loans, `bound`, no-invalidation, `exclusive`; `Core.Relocatable` and the move operator | The rows marked "after stage 4": `&mut T`, `&Shared<T>`, `&SharedView<T>`, `&SharedSlice<T>`, elided lifetimes, by-value `Relocatable` crossing, `Option<&Shared<T>>` and `Option<&mut T>`; `Core.Utf8` for `&str` (residue, D-SAFE-20) |
safety/rust_interop.md:540 | no change: staging row 6, unchanged; the `&T` row is stage 5 | | 6 | `bound(a)` and `Core.Lifetime`, `Core.DynCast`, the Rust binding generator | The generator itself: the C-ABI shims on both sides, the `Shared`/`SharedView`/`SharedSlice` wrappers, the `choice` and `Core.Result` tagged-union shims, per-instantiation generics; named lifetimes for `bound(a)` (the `Longest` example) |
safety/rust_interop.md:553 | A.6.5 | -   **D-SAFE-19 — Safe-Rust interop mapping and verdict.** The transport is
safety/rust_interop.md:558 | A.6.5 | no-invalidation rule is; `const T*` as `&SharedView<T>` by default and as
safety/rust_interop.md:606 | no change, history: attempt A | is `Cell` semantics. A's raw pointer survives only as D-SAFE-19's break
safety/rust_interop.md:609 | no change, history: attempt C | -   **Attempt C's cxx-level posture for 0.1.** Attempt C, "Ratchet: hardened
safety/rust_interop.md:625 | stands; A.6.6 appends a sentence to this bullet | rewritten to `&SharedView<T>` and `&SharedSlice<T>` by default with `&T`
safety/rust_interop.md:634 | A.6.6 | alternative, eager acquisition for every type, would make a value binding
safety/rust_interop.md:637 | A.6.6 | types, and the other reason — `Plain`-field writes through `T*` aliases —
safety/rust_interop.md:654 | no change: an external fact about Rust's `&T`, unchanged | | 1 | Rust's `&T` must point to memory that is not mutated while the reference is live, except for data inside an `UnsafeCell`, and `&mut T` must point to memory that is not read or written by any pointer not derived from it and that no other reference points to while it is live; breaking these rules is undefined behavior | [The asymmetry](#the-asymmetry); the `&mut T` and `&T` rows; the `Freeze` proviso | VERIFIED against the Rust Reference, "Behavior considered undefined" ("`&T` must point to memory that is not mutated while they are live (except for data inside an `UnsafeCell<U>`), and `&mut T` must point to memory that is not read or written by any pointer not derived from the reference and that no other reference points to while they are live (with no exceptions)"; "the bytes pointed to by a shared reference ... are immutable") |
safety/spatial_safety.md:16 | regenerated by the toc hook (A.5.3 renames the heading) | -   [SP2: Every element access is bounds-checked and fails-stop in every build mode](#sp2-every-element-access-is-bounds-checked-and-fails-stop-in-every-build-mode)
safety/spatial_safety.md:18 | regenerated by the toc hook (A.5.4 renames the heading) | -   [SP4: `unsafe fn GetUnchecked` is the only opt-out](#sp4-unsafe-fn-getunchecked-is-the-only-opt-out)
safety/spatial_safety.md:41 | A.5.1 | [fails-stop][fail-stop] in every build mode and in every
safety/spatial_safety.md:115 | A.5.3 | ### SP2: Every element access is bounds-checked and fails-stop in every build mode
safety/spatial_safety.md:174 | no change, decided under R29 (added 2026-10-28, review fold: RR3-M1): SP3's producer rule names the prelude's producers at 2407efa74; `IndirectIndexWith.Ref`'s `bound self` is stated where the trusted-body rule is (A.1.1, A.2.8, B.1.0, B.1.7) and in W-144's note (B.4); break condition: a reviewer reads SP3 as letting `Ref` drop `bound`, and SP3 gains a dated sentence | `Convert` (:100-106) and every other producer whose result views `self`'s
safety/spatial_safety.md:206 | A.5.4 | ### SP4: `unsafe fn GetUnchecked` is the only opt-out
safety/spatial_safety.md:270 | A.5.5 | The arithmetic design's "performance build" row, under which the optimizer may
safety/spatial_safety.md:275 | A.5.5 | cannot occur. Its open question, whether a hardened build should trap, wrap or
safety/spatial_safety.md:278 | A.5.5 | condition is a real-world benchmark of the class p005914 names where the loss
safety/spatial_safety.md:357 | A.5.6 | // EX-SP-5 (NEW): the only opt-out
safety/spatial_safety.md:470 | no change: C++'s hardened library modes, SP5 | model trusts; Carbon does not re-check it, and the hardened standard
safety/spatial_safety.md:497 | A.5.8 | | 2 | Runtime hardening regardless of mode: array index fail-stop, division by zero fail-stop, `--build-mode=debug\|release`, Release zero-fill | `ArrayIndex` lowered as compare-and-`fail_stop` with "carbon: array index out of bounds; terminating", array subscripts through `IndexWith(i64)` (absorbing W-116); the division and remainder guard with "carbon: division by zero; terminating"; Debug overflow fail-stop; residue item W-146 |
safety/spatial_safety.md:530 | A.5.9 | for benchmarking is withdrawn by the fork, dated. SP5 hardening extensions
safety/spatial_safety.md:538 | A.5.9 | already rejected. The arithmetic design's "performance build ... not
safety/spatial_safety.md:542 | A.5.9 | wrap, not zero. Break condition: a real-world benchmark of the class
safety/spatial_safety.md:554 | A.5.10 | disable the default hardening in release builds for benchmarking, and
safety/spatial_safety.md:555 | A.5.10 | attempt C carried it as an `--unhardened` build flag beside its hardened
safety/spatial_safety.md:565 | A.5.10 | keyword is, and a benchmark that wants the unchecked build measures the
safety/spatial_safety.md:576 | no change, history: attempt C | -   **Attempt C's ratchet.** Attempt C's thesis was a hardened runtime core
safety/spatial_safety.md:577 | no change, history: attempt C | first, fail-stop bounds, zero-fill and division-by-zero fail-stop as the
safety/spatial_safety.md:589 | no change: the zero-on-overflow alternative quotes upstream's TODO | a hardened-build result because it "may defeat some classes of exploit".
safety/temporal_safety.md:104 | A.3.2 | -   A _loan set_ is what every pointer value, `ref` binding, value binding and
safety/temporal_safety.md:136 | no change: a `const T*` freezes nothing, still true | read into it, and in particular `const T*` is not an "immutable" or "frozen"
safety/temporal_safety.md:140 | no change: the kinds table stands; A.3.3 follows it | | Kind | Spelling | Formed by | Loan kind | Through it you may | Receiver form | Rust analogue (D-SAFE-19) |
safety/temporal_safety.md:144 | no change: a `const T*` carries a shared loan, still true | | shared-const | `const T*` | conversion from either kind; C++ `const T&` | shared (const) | read; `const` methods | `ref self: const Self`, by-value `self` | `&SharedView<T>` (`&T` only under the D-SAFE-19 proviso) |
safety/temporal_safety.md:185 | no change: the case against an exclusive `T*`, unchanged | exclusive `T*` would turn every one of those into an unverified `noalias`
safety/temporal_safety.md:203 | A.3.4 | A `ref` or a call result whose loan set mixes kinds has the **weakest** kind:
safety/temporal_safety.md:213 | A.3.4 | > states (p005434:83) that "the address of a `ref` binding is `nocapture` and
safety/temporal_safety.md:214 | A.3.4 | > `noalias`". This design emits `noalias` and `captures(none)` only for
safety/temporal_safety.md:249 | A.3.5 | -   A value binding of a non-`Plain` type, from `*p` or from an owner, forms a
safety/temporal_safety.md:251 | A.3.5 | M8 of the mutation page); a value binding of a `Plain` type copies eagerly
safety/temporal_safety.md:252 | A.3.5 | and holds no loan; and a value binding of a non-`Plain` type from an
safety/temporal_safety.md:294 | no change: the definition of a carrier, T3 | a carrier is a pointer value, `ref` binding, value binding or loan-carrying
safety/temporal_safety.md:314 | A.3.6 | loan set mixes kinds, T4 is applied to every place in the set at the weakest
safety/temporal_safety.md:427 | A.3.8 | `noalias` and `captures(none)` are emitted for exclusive loans only where the
safety/temporal_safety.md:482 | A.3.9 | parameters give shared, and a mixed set takes the weakest kind. A function
safety/temporal_safety.md:502 | A.3.9 | "immutable for the duration of the lifetime of the returned result"; this
safety/temporal_safety.md:503 | A.3.9 | design narrows "immutable" to "not invalidated": a shared-kind bound
safety/temporal_safety.md:509 | no change, decided under R29 (added 2026-10-28, review fold: RR3-M1): T5(e)'s list names the interfaces the prelude has at 2407efa74, and its rule is the reason `IndirectIndexWith.Ref` takes `bound self` at the interface (D-SAFE2-5, A.2.8, B.4); break condition as the SP3 row's | declarations `IndexWith.At` (core/prelude/operators/index.carbon:9) and
safety/temporal_safety.md:517 | no change: T5(f), whose weakest kind counts frozen below shared by T4 (A.3.6) | weakest among them; a store from a place in set `a` into a place in set `a`
safety/temporal_safety.md:725 | A.3.12a (added 2026-10-28, review fold: RR2-B1) |   buf.Set(1, 7);                    // OK: Set is non-invalidating and i32 is Plain
safety/temporal_safety.md:741 | A.3.12a (added 2026-10-28, review fold: RR2-B1) | is `[bound self]` (W-144), `buf.Set(1, 7)` is permitted through it because
safety/temporal_safety.md:840 | no change: EX-TM-7's temporary, owned storage | statement is `StrictBorrowOfTemporary`. The value binding `v` itself takes
safety/temporal_safety.md:894 | no change: `Pick` returns a reference expression; its result kind is still the weakest | if (b) { return r; } else { return *p; }               // p005434:772-779's Conditional: result kind is the weakest (shared)
safety/temporal_safety.md:1012 | no change: the C++ boundary still withholds `noalias` (T8) | one, because T8 withholds `noalias` and `captures(none)` at every such
safety/temporal_safety.md:1021 | no change: the C++ boundary still withholds `noalias` (T8) | -   **C++ callers and function values switch off `noalias`.** A Carbon function
safety/temporal_safety.md:1067 | A.3.15 | | 4 | The loan checker | T1 to T8 and the Store rule over loan sets; `bound` per T5(a) to (e); `exclusive`; the reborrow and same-kind-copy clauses; `StrictExclusiveBorrowConflict`, `StrictSharedBorrowInvalidated`, `StrictBorrowOfTemporary`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam`; `noalias` and `captures(none)` under T8; `error` default (residue item W-148) |
safety/temporal_safety.md:1098 | A.3.16 | set has the weakest kind and T4 applies to every place in it. `noalias`
safety/temporal_safety.md:1099 | A.3.16 | and `captures(none)` are emitted only for exclusive-kind refs under T8,
safety/temporal_safety.md:1112 | A.3.16 | with the narrowing of p005434:831-832 from "immutable" to "not invalidated".
safety/temporal_safety.md:1140 | no change, history: attempt A | exclusive pointer, re-meant `const T*` as shared-immutable, and added a
safety/temporal_safety.md:1144 | no change, history: attempt A | into an unverified `noalias` claim, and `const` acquiring "shared" reads
safety/temporal_safety.md:1159 | no change, history: attempt C | hardened runtime core now, annotated borrows later", annotated returns
safety/temporal_safety.md:1203 | no change: an external fact about LLVM's `noalias` | | LLVM's `noalias` parameter attribute means that memory accessed through pointers based on the argument is not also accessed, during the function, through pointers not based on it, for locations modified during the function, with undefined behavior otherwise; `captures(none)` means the pointer is not captured | T8's codegen rule and the reason the attributes are withheld at Permissive and C++ boundaries | VERIFIED against the LLVM Language Reference, "Parameter Attributes" ("memory locations accessed by way of pointer values based on the argument or return value are not also accessed, during the execution of the function, by way of pointer values not based on the argument or return value"; "If there are other accesses not based on the argument or return value, the behavior is undefined"; "`captures(none)`: Pointer not captured"), read 2026-10-12 |
slices.md:53 | A.10.1 (amended 2026-10-28, review fold: RR1-M1) | every write to that storage is visible through every slice of it:
slices.md:61 | A.10.1 (amended 2026-10-28, review fold: RR1-M1) | a[2] = 30;
slices.md:84 | no change: the slices design's value binding of an array, consistent | conversion from an array _value_: a value binding of array type may be
slices.md:162 | no change: the 0.1 API listing, today's prelude; A.10.2's amendment gives the receiver W-144 sets (added 2026-10-28, review fold: RR2-B1) |   fn Set(self, i: i64, value: T);
slices.md:243 | A.10.2 (added 2026-10-28, review fold: RR2-B1): the amendment after the bullet list, the bullet itself kept for 0.1 | -   `Set(self, i, value)` writes through the shared heap block, so it takes
slices.md:258 | A.10.2 (amended 2026-10-28, review fold: RR2-B1; rev 3 read "no change: a by-value parameter of a class does not copy, consistent with a borrowed object"): the by-value parameter stays a borrowed object, and its "callee can `Set` through it" is 0.1's, a Strict callee needing a `ref` parameter or an `exclusive` pointer | by-value parameter does not copy it (value bindings of a non-`Copy` class
values.md:140 | A.7.1 | > the pointer it was formed through; a value binding is a shared read; and
values.md:150 | no change, upstream's text | by eagerly reading that value into a machine register, lazily reading that value
values.md:180 | no change, upstream's text | A [_value binding pattern_](/docs/design/README.md#binding-patterns) introduces
values.md:194 | no change, upstream's text | Value bindings require the matched expression to be a _value expression_,
values.md:221 | no change, upstream's text | // `1` starts as a value expression, which is what a value binding expects.
values.md:470 | no change, upstream's text, which D-SAFE2-5 enforces in Strict | storage ends the lifetime of the value binding, and makes any use of the value
values.md:486 | A.7.2 | > `Core.Plain` type acquires eagerly and is unaffected by later mutation (the
values.md:489 | A.7.2 | > operations are rejected in Strict Carbon and `Plain`-field writes through
values.md:491 | A.7.2 | > [Mutation safety: Value bindings](safety/mutation_safety.md#value-bindings).
values.md:518 | no change, upstream's text | Value expressions and value bindings can be used with
values.md:808 | no change, upstream's text | too, many small types will not need to be lazy and simply eagerly initialize the
values.md:1291 | no change, upstream's text | feature in Carbon -- for more fundamentally "immutable" use cases, value
values.md:1423 | no change, upstream's text | and as the implementation representation for value bindings and other value
values.md:1489 | no change, upstream's text | // Or we can use a value binding for `self` much like normal, but the
```

<!-- google-doc-style-resume -->

Three more pages carry the rules and are not reached by the page grep: the
F-013 entry of fork/decision-log.md (D-SAFE-8 :3098-3121, D-SAFE-10
:3171-3296, D-SAFE-11 :3297-3354, D-SAFE-13 :3369-3426, D-SAFE-14 :3427-3482,
D-SAFE-15 :3483-3493, D-SAFE-17 :3532-3568, D-SAFE-19 :3645-3710, the register
block :3920-3940 and RG-1's paragraph :3941-3983), fork/safe/plan.md (§0.3
holds the same decision texts verbatim at :383-406, :456-581, :582-639,
:654-711, :712-767, :768-778, :817-853 and :930-995, measured identical line
for line by `diff`; §1.1's matrix :1129-1146; §1.5's kinds table :1214-1220;
§1.6's M5 and M8 sentences :1249-1263; §4.1's rows :1897-1937; §4.3
:1957-1970) and PR 53's ledger items W-146 (D-SAFE-14's withdrawn disable,
D-SAFE-13 I5), W-148 (D-SAFE-8, D-SAFE-11(d), D-SAFE-17, the Debug flag) and
W-150 (D-SAFE-19's `SharedView`). Their texts are Appendix B. Not reached and
not changed: the two SKIP stubs (fork/conformance/programs/project/
safe_carbon_design.carbon and safety_strategy_doc.carbon state none of the six
rules), gap row 89 (fork/gap-analysis.md:92 names the pages and the residue
items, not the rules) and docs/design/safety/terminology.md (its mutation
safety entry is D-SAFE-1's taxonomy, which SAFE-2 keeps).

Two more decision sentences carry the by-value `Core.Buf(T).Set` (added
2026-10-28, review fold: RR2-B1): D-SAFE-2's prelude clause (log :2961-2964,
plan :246-249, "The prelude is the first client: `Core.Slice`, `Core.Buf`,
`Core.Optional` are Permissive-implemented behind Strict-checkable
signatures"), which B.1.0 gives the trusted bodies' write rule, and D-SAFE-19's
`&[T]` proviso (log :3671-3672, plan :956-957, "(`Buf.Set` during a live view
is the plan's own EX-TM-3 — A-9)"), which B.1.8 re-words. And
fork/safe/plan.md §2, the deliverable spec of 2026-10-12, states the six rules
in its outlines and example copies (amended 2026-10-28, review fold: RR2-m2;
rev 3 limited fork/safe/plan.md to §0.3, §1, §4.1 and §4.3): at 2407efa74,
:1391-1392 (the benchmarking disable withdrawn), :1518 (EX-SP-5's "the only
opt-out"), :1530 and :1533 (the narrowings of p005434:83), :1559 (EX-TM-3's
`buf.Set(1, 7)` under the live view), :1641 and :1643 (`UsePick`'s shared-kind
`ref`), :1679 (EX-M-1's `a->Set(0, 5)` "fine"), :1694 and :1697 (EX-M-4a's
eager copy by `Plain`), :1701 and :1704 (EX-M-4b's shared loan), :1743 (`At`'s
`&'a SharedView<Self>`), :1772-1774 ("the fork promotes this zeroing"), :1786
("the performance-build UB row withdrawn") and :1789-1795 (the values.md
notes). Each is "no change, history (B.3.1)": §2 is the spec SAFE-1's commits
implemented, superseded where it states the six rules by the pages as Appendix
A realigns them, and B.3.1's pointer paragraph names these lines.

The ledger and the gap analysis, grepped field by field (amended 2026-10-28,
review fold: B-M6; rev 1 grepped only docs/). Over PR 53's
fork/inventory/work-items.json, the six decision ids and the rules' words
(noalias, narrow, withdraw, benchmark, zero-fill, performance build, promote,
shared-kind, not invalidated) hit W-144, W-146, W-147, W-148 and W-150 and,
for "narrow" or "promote" alone, nine unrelated items (W-008, W-010, W-023,
W-038, W-056, W-069, W-071, W-072, W-104); W-063, W-145 and W-149 have none.
The lines that
state a superseded rule, each given a dated note in Appendix B.4 that quotes and
supersedes it:

-   W-146's title, "`--build-mode=debug|release`", which names the supported
    modes only (W-351);
-   W-146's evidence, "the dated blockquote at docs/design/README.md:2147
    promoting zero-fill to the Release baseline" (W-353) and "the dated
    blockquote withdrawing the performance-build row, D-SAFE-15" (W-350);
-   W-146's notes, "D-SAFE-14 (fail-stop everywhere, no build flag disables
    the checks — the benchmarking disable of safety README.md:260-262
    withdrawn, A-13(c); break condition: ... never a flag)" (W-351), D-SAFE-15's
    "break condition: a real-world benchmark where the loss of `nsw` exceeds 0.5
    percent — an owner call" (W-350) and D-SAFE-13 I5's "break condition: more
    than 0.5 percent from zero-fill alone — then scoped to escaped-unformed
    objects" (W-353);
-   W-148's evidence, "proposals/p005434 (`bound`, `ref`, `val`; :83 and
    :831-832 narrowed by D-SAFE-8 and D-SAFE-11(d))" (W-347, W-349), and its
    checklist row names "'M8 value binding, non-`Plain`' EX-M-4b", "'M5
    payload refs' EX-M-5" and "'D-SAFE-8 mixed-kind result' `Pick`/`UsePick`",
    which B.3.6 renames;
-   W-148's notes, "D-SAFE-17 (value bindings; break condition: a corpus
    where the Debug shadow count's cost is measurable — then opt-in)" (W-348).

W-144's D-SAFE-11 (a)/(e) and D-SAFE-14 SP3, W-147's D-SAFE-2 and D-SAFE-13
I2/I3, and W-150's D-SAFE-11 (f) and D-SAFE-19 `const T*` rows state rules
SAFE-2 keeps. fork/gap-analysis.md has no hit for the six ids or those words;
its row 89 (:92) and the W3 narrative (:131-141) name the pages and items only.

The grep above missed the lines that state W-348's consequence for a `const`
method call or a read through a shared pointer, because they name neither the
six ids nor a value binding (added 2026-10-28, document-review fold: R1-M3):
mutation_safety.md:142-143 (the M1 table's `T*` and `const T*` rows),
:206-210 (M3's "Everything else"), :285-286 (M4's `addr self` bullet) and
:1239-1241 (the page's D-SAFE-9), the log's D-SAFE-9 with fork/safe/plan.md
:488, and fork/safe/plan.md :1543 (section 1.6's M4), at 954f1c542. Fix commit
0f281d8bd qualifies each with M8's rule (section 8.7).

### §0.6 The interlocks

Each structure that states one of the six rules, traced:

| Structure (PR 53) | States | Changes under SAFE-2 |
| --- | --- | --- |
| T2, forming loans (temporal_safety.md:235-289) | D-SAFE-17's shared loan for a non-`Plain` value binding, the eager copy for `Plain`, `let ref` exclusive, the reborrow clause naming "a `bound self` by value" | yes (A.3.5): borrowed objects by value representation, the frozen loan, `ref` formation by closed and open place, frozen reborrows read-only |
| T4, conflicts (:303-317) | shared loans exclude only invalidation; the weakest kind for a mixed set | yes (A.3.6): a frozen loan excludes every write, and passing a writable carrier of the place to a call, except through the result that holds a `bound` pointer argument's pointee (amended 2026-10-28, review fold: A-B-2) |
| T5(a) and (d) (:477-488, :499-505) | the result's kind map (value parameters give shared); "immutable" narrowed to "not invalidated" | yes (A.3.9): value and `const` `ref` parameters give frozen, and a `ref` parameter under a `val` or by-value result; each `bound` argument immutable, a `bound` pointer argument's pointee written by no path but the result (amended 2026-10-28, review fold: A-B-2, A-m-1), under a frozen loan the result holds, an exclusive one for an `exclusive T*`, the result's own access being at (a)'s kind (amended 2026-10-28, review fold: RR1-m1); so a view `FromArray(&a)` holds `a`, and slices.md's opening `a[2] = 30` under the live view is rejected (A.10.1; amended 2026-10-28, review fold: RR1-M1) |
| T6's binding spelling (:370-379) | `let ref r = unsafe *q;` for a ⊥ carrier | sentence added (A.3.7): the same spelling marks a `ref` on an open place |
| T8, codegen honesty (:425-442) | attributes for exclusive loans only | yes (A.3.8): for `ref` bindings on closed places, `captures(ret: ...)` for `bound`; on a `ref` parameter's referent or an `exclusive T*` parameter's pointee only under the whole-package condition; never on an open place or for an `unsafe`-formed one (amended 2026-10-28, review fold: A-M-1, A-B-1) |
| T1, T3, T7, the Store rule, the P-subset | none of the six | no |
| The kinds table (README.md:393-403, temporal_safety.md:138-146, plan §1.5) | the `const T*` row's receivers `ref self: const Self` and by-value `self` as callable through every kind (M4) | the table's cells stay; a dated paragraph after each copy (A.1.5, A.3.3, B.3.4) states the binding rule the receivers now meet |
| The diagnostic matrix (README.md:309-326, plan §1.1) | `StrictSharedBorrowInvalidated` with Debug `MutationDuringValueBinding` | four rows added (A.1.3, B.3.2): `StrictRefFromShared`, `StrictBorrowFromShared`, `StrictBorrowedObjectMutated`, `StrictSharedImmutableWrite`; the existing row's Debug cell re-worded, the report being `StrictBorrowedObjectMutated`'s (amended 2026-10-28, review fold: A-B-1, B-m6) |
| The Debug value-binding shadow flag (mutation_safety.md:437-444, :511-514) | the detector of the narrowed rule's erroneous writes | kept as the Debug detector of the mutations unchecked code can still make, counting whole-object `Plain` assignments through `T*` beside field writes (D-SAFE2-7; A.2.8, A.2.9; amended 2026-10-28, review fold: A-B-1) and testing the written byte range against a per-byte count, so that a write of an enclosing aggregate and a field at a nonzero offset are both seen (amended 2026-10-28, review fold: RR1-B1); every store that writes a counted byte is tested, of any type and by any path, `T*`, a `ref`, the owner, a global or an `addr self` body, so that a Permissive body's write to a global and a Strict body's write that a Permissive caller made aliasing are seen (amended 2026-10-28, review fold: RR2-m1) |
| D-SAFE-19's Rust rows (rust_interop.md:126-140, :213, :336, :343-352, :380-401, :633-638) | value bindings as one reason `const T*` and a value parameter cannot be `&T`; `Buf.Set` under a live view as the reason a `Slice(const T)` is not `&[T]` | yes (A.6): a value parameter of a borrowed `Freeze` type exports as `&T`; the `const T*` reason stays; the `&[T]` row's reason becomes an element write through a view's `Data()` (A.6.3a, B.1.8; amended 2026-10-28, review fold: RR2-B1) |
| The prelude's trusted bodies (safety/README.md:133-139; buf.carbon:48-53 at 2407efa74) and the slices design's `Buf` bullets (slices.md:243-259) | `Core.Buf(T).Set` by value, writing an element of the block through `self.ptr`; "a callee can `Set` through it" | yes (added 2026-10-28, review fold: RR2-B1): a trusted body keeps M3's write rule (A.1.1, A.2.8, B.1.0, B.1.7), `Set` takes `ref self` (W-144), EX-TM-3's `buf.Set(1, 7)` moves before the view (A.3.12a), and the slices design gains a dated amendment (A.10.2); PR 65's `IndirectIndexWith.Ref`, which hands out a `ref` into the block, takes `bound self` at the interface and in both impls (W-144; the same four texts, D-SAFE2-5 and B.4; amended 2026-10-28, review fold: RR3-M1) |
| M1, M2, M3, M4, M5, M8 and Value bindings (mutation_safety.md) | `ref` kind inheritance, shared value-binding loans, const receivers through every kind, payload refs through shared paths, `Plain` assignments through `T*` to any type | yes (A.2.3 to A.2.8; M3's paragraph on `Core.SharedImmutable` writes, A.2.4a, amended 2026-10-28, review fold: A-B-1, over every assignment whose type holds a `Core.SharedImmutable` sub-object, a closure like `Core.Plain`'s, amended 2026-10-28, review fold: RR1-B1) |
| §4.1 worked examples | EX-M-1's `a->Set(0, 5)` under `first`; EX-M-4a/4b's reasons; EX-M-5/6's `ref` payloads through shared pointers; `Pick`/`UsePick`; `Valid1`, `ValToRef`, `Conditional`; the `Launder` programs; EX-I rows; SP4's `GetUnchecked` | outcomes in section 4: EX-M-1, EX-M-5, EX-M-6, `UsePick` and EX-TM-3's `Buf` half change (EX-TM-3 amended 2026-10-28, review fold: RR2-B1); EX-M-4c, EX-M-4d and EX-TM-9 are added; the rest keep their outcomes with realigned reasons or none |
| Diagnostic names | `StrictSharedBorrowInvalidated`, `StrictInvalidatingThroughShared`, `MutationDuringValueBinding` | none renamed; four added (D-SAFE2-8; the fourth, `StrictSharedImmutableWrite`, amended 2026-10-28, review fold: A-B-1); `MutationDuringValueBinding`'s message reworded to upstream's "borrowed object" |
| SP2, SP4, the arithmetic rows, the build-modes blockquote | "every build mode", "the only opt-out", the withdrawn row and disable | yes (A.5, A.1.6, A.9) |
| I5, the README.md:2151 blockquote, I5's break condition, the alternatives bullet | the zero-fill as a promotion and a departure | text only (A.4, A.8); the rule stands (section 0.3) |

D-SAFE-11(d) is D-SAFE-17 at a second site, so W-348 and W-349 are one
re-derivation; D-SAFE-19 exports D-SAFE-17's binding, so its rows follow W-348;
W-350 and W-351 are one build (the benchmarking build); W-347 and W-348 share
one new piece of vocabulary, the closed and open place (D-SAFE2-4), because a
`noalias` `ref` and a frozen value binding are established by the same
condition.

### §0.7 The examples on the touched pages, compiled on the nightly

Every example marked "today's syntax" on a touched page, and the three this plan
adds, written to
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/planner/ex/
with no `package` line and `import Core library "io";` where `Core.Print` is
used, compiled with
/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon
`compile --output-last-input-only --output=<f>.o <f>.carbon` and, where a `Run`
was given, linked with `carbon link --output=<f>.bin <f>.o` and run, as SAFE-1's
§8 item 1a did. This is the baseline the implementer's run must reproduce.

| Example | Page | Exit status | First diagnostic, or the run's output |
| --- | --- | --- | --- |
| EX-I-1 `Choose` | initialization | 0 | none |
| EX-I-2 `Choose2` | initialization | 0 | none |
| EX-I-5 `Fill`/`Out`, `Fill` bodied `*p unsafe as i32 = 1;` | initialization | 0 | none |
| EX-M-4a `ValueBinding` with a `Run` printing it | mutation | 0, run exit 0 | prints `1` |
| EX-M-4c `ValueBinding3` (added, A.2.14) with a `Run` | mutation | 0, run exit 0 | prints `1` |
| EX-M-4d `Peek(&a, &a)` (added, A.2.14) with a `Run` | mutation | 0, run exit 0 | prints `1` |
| EX-M-4d `Peek2(&x, &x)` for `x == "ab"` (added, A.2.14; review A's counterexample, amended 2026-10-28, review fold: A-B-1), `fn Peek2(p: const str*, q: str*) -> i64 { let s: str = *p; *q = "longer"; return s.Size(); }` with a `Run` printing `Peek2(&x, &x) as i32` | mutation | 0, run exit 0 | prints `6`: `s` reads `*p` through the pointer representation after the write through `q` (re-run by the fixer) |
| EX-M-4d `Peek4(&y, &y)` for `y == {.s = "ab", .n = 0}` (added, A.2.14; the focused re-review's counterexample, amended 2026-10-28, review fold: RR1-B1), `fn Peek4(p: {.s: str, .n: i32}*, q: {.s: str, .n: i32}*) -> i64 { let s: str = p->s; *q = {.s = "longer", .n = 1}; return s.Size(); }` with a `Run` printing `Peek4(&y, &y) as i32` | mutation | 0, run exit 0 | prints `6`: the whole-struct assignment through `q` writes the `str` that `s` borrows (re-run by the rev 3 fixer) |
| the re-review's class probe, not a page example: `class W { var s: str; }` with `fn Peek5(p: W*, q: W*) -> i64 { let s: str = p->s; *q = {.s = "longer"}; return s.Size(); }` and a `Run` printing `Peek5(&w, &w) as i32` for `w == {.s = "ab"}` (amended 2026-10-28, review fold: RR1-B1) | (the class shape of RR1-B1) | 0, run exit 0 | prints `6`, as `Peek4` does (re-run by the rev 3 fixer) |
| the round-2 re-review's stand-in for EX-M-4d's `Peek8`, not a page example (`Core.Buf` is fork prelude): `class B { fn Data(self) -> str* { return self.ptr; } fn Set(self, value: str) { *self.ptr = value; } var ptr: str*; }` with `fn Peek8(b: B*) -> i64 { let s: str = *b->Data(); b->Set("longer"); return s.Size(); }` and a `Run` printing `Peek8(&b) as i32` for `b == {.ptr = &e}`, `e == "ab"` (amended 2026-10-28, review fold: RR2-B1) | (the shape of `Core.Buf(T).Set`, buf.carbon:48-53) | 0, run exit 0 | prints `6`: the by-value `Set` writes the element `s` borrows (re-run by the rev 4 fixer, ex/peek8.carbon) |
| a fixer's probe, not a page example: `var g: str = "ab"; fn Q() { g = "longer"; }` with `fn F() -> i64 { let s: str = g; Q(); return s.Size(); }` and a `Run` printing `F() as i32` (amended 2026-10-28, review fold: RR2-m1) | (a write to a global by name, the first shape of RR2-m1) | 0, run exit 0 | prints `6`: the store through the name `g` is the one rev 3's Debug flag did not test (ex/global.carbon) |
| a fixer's probe, not a page example: `fn F(ref r: str, p: const str*) -> i64 { let s: str = *p; r = "longer"; return s.Size(); }` with a `Run` printing `F(ref x, &x) as i32` for `x == "ab"` (the nightly requires the argument's `ref` marker, "argument to `ref` parameter not marked with `ref`" without it; amended 2026-10-28, review fold: RR2-m1) | (the third shape of RR2-m1: a write through a `ref` that the caller made aliasing) | 0, run exit 0 | prints `6` (ex/refalias.carbon) |
| a fixer's probe, not a page example: EX-M-4c with `{.n: i32, .m: i32}`, whose elements are all copy-represented (`ValueAndObjectAggregate`), with a `Run` | (section 0.1's second branch) | 0, run exit 0 | prints `1`, as EX-M-4c's `ValueAggregate` does: the printed value does not tell the two aggregate kinds apart, and no page text says it does (amended 2026-10-28, review fold: A-M-2) |
| the round-3 re-review's shape, a fixer's stand-in, not a page example (`IndirectIndexWith` is PR 65's and not on the nightly): `class B { fn Ref(self) -> ref str { return *self.ptr; } fn Set(self, value: str) { *self.ptr = value; } var ptr: str*; }` with `fn Peek9() -> i64 { var e: str = "ab"; var b: B = {.ptr = &e}; let s: str = b.Ref(); b.Set("longer"); return s.Size(); }` and a `Run` printing `Peek9() as i32` (added 2026-10-28, review fold: RR3-M1) | (the shape of PR 65's by-value `Ref` with no `bound`) | 0, run exit 0 | prints `6`: `s` binds the element through the `ref` result and reads it after the by-value writer's store (the rev 5 fixer's ex/ref8.carbon) |
| the same stand-in with `fn At(self) -> str { return *self.ptr; }` in place of `Ref` and `let s: str = b.At();`, the shape of the `IndexWith(i64)` impl `Core.Buf` has at 2407efa74 (buf.carbon:72-75) (added 2026-10-28, review fold: RR3-M1) | (the shape before PR 65) | 0, run exit 0 | prints `2`: the by-value result is a copy the binding owns, so the reopening is PR 65's `ref` result (ex/at8.carbon) |
| EX-TM-2 `Bad` | temporal | 0 | none |
| EX-TM-3, the `String` half | temporal | 0 | none |
| EX-TM-7 `Temp` | temporal | 1 | "error: cannot bind durable reference to non-reference value of type `str`" |
| EX-TM-9 `F` (added, A.3.14) with a `Run` passing `&y` for `y == 2` | temporal | 0, run exit 0 | prints `3` |
| p005434:152-162's `F` verbatim, with `fn Assert(b: bool) {}` | (source of EX-TM-9) | 1 | "error: cannot access member of interface `Core.EqWith(i32*)` in type `i32*` that does not implement that interface" at `&x == ptr`, so EX-TM-9 omits the `Assert` line |
| EX-SP-3 `ConstOob` | spatial | 1 | "error: array index `2` is past the end of type `array(i32, 2)`" |
| EX-SP-4 `RuntimeArr` | spatial | 0 | none |
| EX-SP-6 `Div` | spatial | 0 | none |

The fork-prelude examples (EX-M-4b, EX-M-4d's `BufSize` and `Peek8`, the
`Core.Buf` half of EX-TM-3, EX-TM-7b, EX-SP-1 and EX-SP-2, the `Launder`
programs) keep their cited evidence (`Peek8` and EX-TM-3's amendment added
2026-10-28, review fold: RR2-B1); the NEW
syntax examples (`bound`, `exclusive`, `addr`, the `unsafe` prefix forms) do not
parse on any toolchain and keep the NEW-SYNTAX outcome.

### §0.8 Collisions with trunk and the held heads

Every held head was re-read with `git ls-remote origin` on 2026-10-28 and
matches the brief: PR 53 2407efa74, PR 51 f96fe8a7a, PR 52 e6bc32a6d, PR 60
cc4daba00, PR 54 cb3ef2e74, PR 55 c3cdecc5d, PR 56 9f12209d8, PR 57 e23113ba2,
PR 58 fcee90d9b, PR 59 b0822a744, PR 61 66aa13132, PR 62 0ef8a0334, PR 64
551a03328, PR 63 89aabd125, PR 65 fee0ef31c, PR 66 43c8ab476, PR 67 56e2e5bbd,
PR 68 097c76473; trunk 1c83422a0. None moved.

Files SAFE-2 edits against what each head changes from trunk
(`git diff --name-only 1c83422a0 <head>`): the six safety pages and values.md
are touched by no other head; docs/design/README.md is touched by PR 55 (one
hunk at :636), PR 56 and PR 57 (one hunk at :862) and PR 58 (hunks from :151 to
:4098), and SAFE-2 edits only :2151-2154, inside PR 53's own amendment, more
than 700 lines from the nearest other hunk (PR 58's at :2890); arithmetic.md is
touched by PR 55 at :189-190 and SAFE-2 edits :167-175; slices.md is touched by
PR 51 (one hunk at :386) and PR 65 (hunks from :114 to :437), and SAFE-2
inserts A.10.1's note after :70, the end of PR 53's own SP3 amendment
(trunk's :64, 50 lines before PR 65's nearest hunk); a three-way
`git merge-file` of PR 53's slices.md with the note applied against each
head's copy, on their merge bases, is clean (amended 2026-10-28, review fold:
RR1-M1; rev 2 left slices.md unedited). A.10.2's amendment goes after the
`Buf` bullet list, after PR 53's :264 ("trivially destroyed."; the merge
base's :257), not into the `Set` bullet, because PR 65 rewrites that bullet's
last two lines (its hunk at the merge base's :238-239) and its next hunk is
at :272, 15 lines past the insertion; the three-way `git merge-file` of PR
53's slices.md with both A.10.1 and A.10.2 applied against PR 51's, PR 65's
and trunk's copies on their merge bases (8068151ed, 0bdce60a5, 0bdce60a5)
reports 0 conflicts each (amended 2026-10-28, review fold: RR2-B1; measured
in the rev 4 fixer's scratch, mf/). fork/safe/plan.md and this file are
PR 53's alone. The records files fork/decision-log.md,
fork/inventory/work-items.json, fork/ORCHESTRATION.md and fork/gap-analysis.md
are touched by every head.

PR 65's prelude collides with no file SAFE-2 edits, but it meets the design
(added 2026-10-28, review fold: RR3-M1). At fee0ef31c it declares
`interface IndirectIndexWith(SubscriptType: type)` with `fn Ref(self,
subscript: SubscriptType) -> ref ElementType;` (index.carbon:14-17, :16 the
method) and gives `Core.Slice(T)` and `Core.Buf(T)` by-value impls that return
`*PointerOffset(self.Data(), subscript)` and
`*PointerOffset(self.AsSlice().Data(), subscript)` (slice.carbon:74-82,
buf.carbon:72-80), a `ref` into the storage the view or the block holds, with
no `bound`. PR 65 lands after PR 53 (section 5 of RG-1's plan), and from then
on, with that `Ref`, `var b: Core.Buf(str) = Core.Buf(str).Make(1, "ab"); let
s: str = b[0]; b.Set(0, "longer"); return s.Size();` binds `s` frozen on an
element reached through a free result, holding no loan on `b`, so the
`ref self` `Set` is accepted and the trusted body writes the element `s`
borrows: 6, `Peek8`'s shape again (section 0.7's `Peek9` stand-in prints 6,
and its by-value `At` twin, the `IndexWith(i64)` shape `Core.Buf` has at
2407efa74, prints 2). Under W-144 `Ref` takes `bound self` at the interface,
as `IndexWith.At` does (temporal T5(e): an impl may not add `bound` beyond its
interface), and in both impls, so a binding formed through `b[i]` keeps the
loan on `b` that `Set`'s `ref self` conflicts with (D-SAFE2-5, A.1.1, A.2.8,
B.1.0, B.1.7, B.4). DR-1, PR 65's workstream, carries the counterexample: the
orchestrator's stamp names it among the next actions (Appendix D's fourth
block), for a dated note on PR 65's records before PR 65 lands, and W-144's
note on PR 53's ledger (B.4) carries it until then.

`git merge-tree --write-tree --name-only 2407efa74 <head>` today, before
SAFE-2: every one of the 18 merges reports conflicts in records files only
(fork/ORCHESTRATION.md, fork/decision-log.md, fork/inventory/work-items.json,
fork/gap-analysis.md, in the per-head combinations RG-1's section 4.7 already
records), and none in a page. SAFE-2's page edits lie in regions no other head
touches, and its records edits lie inside PR 53's own F-013 entry and register
block, PR 53's residue items W-144 to W-150 and PR 53's plan files, so the set
of conflicting files and their merge rules are unchanged (section 6). The sets
measured on 2026-10-28 by `git merge-tree --write-tree --name-only` of
2407efa74 and each head, all under fork/ (amended 2026-10-28, review fold:
B-m3; rev 1 deferred them to RG-1's section 4.7, measured at older heads):

| Against | Conflicting files |
| --- | --- |
| trunk 1c83422a0 | ORCHESTRATION.md, decision-log.md, inventory/work-items.json |
| PR 51 f96fe8a7a | inventory/work-items.json |
| PR 52, 54, 55, 56, 57, 58 | ORCHESTRATION.md, decision-log.md, gap-analysis.md, inventory/work-items.json |
| PR 60 cc4daba00 | ORCHESTRATION.md, gap-analysis.md, inventory/work-items.json |
| PR 59 b0822a744, PR 66 43c8ab476 | decision-log.md, gap-analysis.md, inventory/work-items.json |
| PR 61 66aa13132, PR 64 551a03328 | decision-log.md, inventory/work-items.json |
| PR 62, 63, 65, 67, 68 | ORCHESTRATION.md, decision-log.md, inventory/work-items.json |

Section 8 item 7 compares the implementer's merge-trees with this table. Before
the PR 67 note commit (section 3, step 6; rev 1 said step 8, amended
2026-10-28, review fold: A-m-4, B-m3) the same merge-tree is run between
the note commit and PR 53's new head, PR 68's head and trunk; the expected
result is the three records files, resolved by the ledger rule (union by id,
the later dated note kept) and the decision-log and ORCHESTRATION rules RG-1
recorded.

### §0.9 The id re-scan

`grep -o '"W-3[4-9][0-9]"'` over fork/inventory/work-items.json on every origin
ref and local branch, and `grep -ohE '\bW-3[6-9][0-9]\b'` over fork/ in every
worktree: ids in the ledgers end at W-363 (W-360 to W-363 on PR 68); text names
W-364 (OV-4's, reserved unused), W-357 to W-359 (RG-1's, reserved unused) and
W-398 and W-399 only as range bounds in VA-2's and DR-1's plans. Widened by the
fixer to `git grep -ohE '\bW-3[6-9][0-9]\b' <ref> -- fork/` on each of the 165
origin refs and local branches (amended 2026-10-28, review fold: B-m7): W-360 to
W-364, W-398 and W-399 as above, and W-365 only in this file's rev 1 (:733 and
:1072, "next free" and "filed as W-365 after a fresh re-scan"). The next free id
is **W-365**. SAFE-2 files none (D-SAFE2-15): every implementation residue it
creates falls inside SAFE-1's stage items W-144, W-146, W-148 and W-150, which
receive dated notes (Appendix B.4). No F id is minted; F-013 is amended by dated
marks.

### §0.10 The records placement (R29)

The six items live on PR 67's ledger, not on PR 53's or trunk's. Two
placements:

-   (a) A dated-note records commit on PR 67's branch, made in a detached
    scratch worktree of PR 67's head, reviewed, pushed as a fast-forward, and
    PR 67's description refreshed: RG-1's own precedent for its held records
    commits (fork/register/rg1-plan.md sections 3.2 and 3.3). Each item's notes
    gain "REALIGNED <date> by SAFE-2 on PR 53 at <head>; discharged when PR 53
    lands", W-353's "CLOSED <date>, its classification corrected" (amended
    2026-10-28, review fold: B-M1, B-m2: the notes cite PR 53's dry head).
-   (b) A land-time note only, written when PR 53 merges.

**Decision: (a).** The items are the land sequence's gate ("the sequence waits
at PR 53"), so the gate's state must be readable from the ledger that lands
first, not only from PR 53's branch; and (a) is the shape RG-1 used for every
held branch it amended. The PR 67 commit also records what SAFE-2 changes in
RG-1's register (amended 2026-10-28, review fold: B-M1, B-M2, A-M-2, A-m-3): the
fork spelling `Core.SharedImmutable` (D-SAFE2-5) joins entry H1.7, whose name
list and silence check H1.7 are widened to it (the check's count stays 1 at
0421bf3b4, measured, so the 89 checks stay 89 and the 155 entries 155; rev 1's
separate check H1.7b had no register row, R32 (b)); H1.13 is re-classified
ALIGNED by a dated amendment quoting p000257:356-360, so RG-1's count becomes 18
DRIFT, 33 ALIGNED and 104 NONE; and eleven quote rows join
fork/register/rg1-quotes.tsv, p000257:356, :357 and :359 and eight lines of
upstream's toolchain/check/type_completion.cpp that section 0.1 and risk R-5
rest on, so the weekly check (W-355) watches them and its quote count becomes
284 (measured: `check_quotes.sh` over the 284 rows at 0421bf3b4, "checked 284
quotes, 0 failed"; `check_greps.sh` with the widened H1.7, "checked 89 silence
checks, 0 failed"). Break condition: PR 67 lands before SAFE-2's notes are
pushed, or the owner forbids further commits on PR 67; then the same texts go
into the trunk records commit that stamps PR 53's realignment, and (b)'s
land-time note discharges the items. The texts are Appendix C.2.

## §1 Design

Each decision is made under R29 with its break condition, and each realigning
decision states the cost of realignment that R32 asks a stated good reason to
record. "The pages" are PR 53's; "the log" is the F-013 entry of PR 53's
fork/decision-log.md, whose D-SAFE texts are fork/safe/plan.md §0.3's, so one
replacement text serves both (Appendix B.1).

-   **D-SAFE2-1 — The baseline.** Upstream is read at 0421bf3b4 (section 0.1):
    no quoted passage moved, PR 67's 273 quotes and 89 silence checks pass, and
    of the six items five are realigned and W-353 is closed, its
    classification corrected (section 0.3; amended 2026-10-28, review fold:
    A-m-3). Break condition: the implementer's re-fetch finds
    a newer tip under which `check_quotes.sh` or `check_greps.sh` fails on a
    line this plan quotes; the affected item stops and this plan is revised
    for it before its text is committed.
-   **D-SAFE2-2 — The amendment convention.** A passage that states a narrowed
    or withdrawn rule is rewritten in place to state upstream's rule, and the
    rewrite carries the mark "(realigned <date>, SAFE-2: W-nnn; the superseded
    2026-10-12 text read: "...")" with the superseded sentences verbatim, the
    OV-4 convention, verbatim being section 2.1's byte-equality with the
    page's source, link markup included (amended 2026-10-28, implementation:
    stop-and-amend: link markup in two superseded quotes); a passage whose
    text stays true and only needs the rule's consequence gains a dated
    sentence instead. A heading that states a
    withdrawn rule is renamed, and the renamed section's first paragraph
    quotes the old heading; the markdown-toc hook regenerates each page's
    table of contents. `<date>` is the implementing commit's `date -u +%F`.
    The log and fork/safe/plan.md §0.3 and §1 carry the same marks (R27). The
    words SAFE-1's records used for the six, "narrowed", "withdrawn",
    "departure" and "promotes", stay only inside the quoted superseded texts.
    A replaced passage quotes every superseded sentence, in full; every
    rewritten clause carries the SAFE-2 mark with its W id; a fold mark of
    2026-10-12 (such as "A-8, B3" or "B13(c)") stays only inside the quoted
    text, never on a rewritten sentence; and a note SAFE-2 writes is dated by
    SAFE-2's commit and names the 2026-10-12 note it replaces, never re-dated
    2026-10-12 (amended 2026-10-28, review fold: B-M5). Break condition: a
    reviewer finds a rewritten passage that drops a superseded sentence without
    quoting it; the passage is redone, never the convention.
-   **D-SAFE2-3 — Borrowed objects and the frozen loan.** A value binding binds
    a _borrowed object_, proposal p005434's term (:660-661), exactly when the
    bound type's value representation is not a copy: its `value_rep` is
    `const ref` or a custom type, or it declares none and the implementation
    chooses a pointer, as today's toolchain does for every class that is not
    an adapter, every array and every struct or tuple of more than one
    element, whether the pointer is to the object or to an elementwise
    aggregate of the element values (section 0.1's second and third
    branches); an adapter, `const T` and `MaybeUnformed(T)` have the
    representation section 0.1 gives them, so `Core.Optional(T*)` is
    copy-represented and holds no loan. When the bound type is
    copy-represented only as a one-element struct or tuple, the binding's
    value holds its element's value representation, and the element object is
    a borrowed object when that representation is not a copy (amended
    2026-10-28, review fold: A-M-2; rev 1 said "every class and every struct or
    tuple of more than one element", a pointer "to the object"). The criterion
    is upstream's, which `Core.Plain` was not: SAFE-1 keyed the eager copy on
    `Plain`, a fork facet that decides invalidation (D-SAFE-9) and that a
    `value_rep` customization or the implementation's choice can disagree
    with, a second spelling of upstream's mechanism under R32 (d). A binding
    of a copy-represented type holds no loan, its value having been read when
    it was bound (values.md:456-460, "immediately reading from the object's
    storage into a machine register or a copy"). A binding of a borrowed
    object holds a _frozen_ loan, the third loan kind beside exclusive and
    shared: while it is live no path writes the object's storage. The
    object's storage is its own bytes and sub-objects; storage reached through
    a pointer it holds, an owned block's elements included, is another
    object's. That is this plan's reading of values.md:461-462's "the object or
    its storage", which does not say it (risk R-3 records the reading and its
    falsifier; amended 2026-10-28, review fold: A-m-4), and it is why a
    `Plain` write of a `Core.Buf` element through the `T*` that a view's
    `Data()` returns stays accepted while a value binding of the `Buf` lives,
    for an element type that holds no `Core.SharedImmutable` sub-object (M3);
    `Data()` points at the view's element 0, so element `i` is reached through
    the one-element view `AsSlice().Subslice(i, i + 1)` (slice.carbon:35-37
    and :46-52 at 2407efa74), and once PR 65 lands through
    `IndirectIndexWith.Ref`, `b[i] = v` and `s[i] = v`, whose `bound self`
    keeps the loan, D-SAFE2-5 (amended 2026-10-28, review fold: RR3-m1, where
    rev 4 named `Data()` alone; amended 2026-10-28, review fold: RR2-B1; rev 3
    read "it is why
    `Core.Buf`'s by-value `Set` stays callable on a borrowed `Buf`", and the
    reading did not make that call safe for a `Core.String` element:
    `Core.Buf(T).Set` now takes `ref self`, D-SAFE2-5). A `ref`
    binding of a `const` type also holds a frozen loan (D-SAFE2-6). Break
    condition: upstream counts storage reached through an owning pointer as the
    object's storage, or keys borrowed objects on something other than the
    value representation; then the storage sentence, and the element writes
    through `Data()` and `Ref` with it (W-144), follow the upstream text.
-   **D-SAFE2-4 — Closed and open places.** A place is _closed_ in a function
    body when every carrier of a loan on it is in the body's view: the body's
    own owners (local `var`s, `var` parameters, temporaries) and their
    sub-objects, the referents of its `ref` parameters and of `ref self`, the
    pointees of its `exclusive T*` parameters, and every place reached through
    a carrier whose loan set holds only closed places, such as `*p` for a local
    `let p: T* = &x;`. Every other place is _open_: one reached through a `T*`
    or `const T*` parameter or `addr self`, a pointer loaded from memory or
    returned by a call whose loan set is not closed, a free loan (a global,
    allocator storage) or ⊥. An exclusive or a frozen loan, the two loans that
    exclude other paths, is formed on a closed place by T4, which sees every
    carrier and rejects every use of one that the loan excludes, a value that
    carries a writable loan on the place and is passed to a call included; on
    an open place no check can see the other carriers, so the formation is an
    `unsafe` operation, except a frozen loan on a `Core.SharedImmutable` type
    (D-SAFE2-5). A local carrier of a closed place cannot escape it: the Store
    rule keeps a loan on a local out of every free, ⊥ or outliving
    destination, and T5(b) keeps a non-`bound` parameter from escaping. Break
    condition: a counterexample in which a carrier the body cannot see writes
    a closed place during a frozen or exclusive loan; the closed-place list is
    narrowed until none exists.
-   **D-SAFE2-5 — W-348: Strict prevents mutation of borrowed objects
    (p005434:663).** A frozen loan on a borrowed object excludes every write to
    its storage through any carrier for the binding's non-lexical lifetime: an
    assignment of any type, `Plain` included, an `addr` or `ref self` call,
    `~`, destruction, and passing a writable carrier of the place, a non-`const`
    pointer or a value that carries one, to a call. A write that is not
    invalidating is `StrictBorrowedObjectMutated`; an invalidating one stays
    `StrictSharedBorrowInvalidated` (T4), so EX-M-4b's diagnostic is unchanged.
    On a closed place the loan is formed by T4. On an open place it is formed
    only when the bound type is **`Core.SharedImmutable`**, a new facet, opt-in
    only (`unsafe impl T as Core.SharedImmutable {}`, the author's audited
    obligation in the pattern of `unsafe impl T as Core.Send {}`), which
    promises that no path but an exclusive one writes the type's storage. The
    promise has two halves (amended 2026-10-28, review fold: A-B-1; rev 1's
    obligation listed only fields, `addr` methods and functions, so the
    language-level assignment M3(c) permits through `T*` for a `Plain` type
    broke it: review A's `fn Peek2(p: const str*, q: str*) -> i64 { let s: str
    = *p; *q = "longer"; return s.Size(); }` prints 6 on the nightly for
    `Peek2(&x, &x)` with `x == "ab"`). The language half is a new paragraph of
    rule M3, over a structural property beside `Core.Plain`'s: a type _holds a
    `Core.SharedImmutable` sub-object_ when it is `Core.SharedImmutable`, or
    is an array, tuple, struct or class with an element, a field or a base
    that holds one, or an adapter of a type that holds one. Every assignment
    whose assigned type holds one, a whole-object or a field assignment and a
    `Plain` one among them, needs exclusive access, so through `T*`, through
    `addr self` or to an open place such as a global it is rejected,
    `StrictSharedImmutableWrite` (or, for a non-`Plain` assignment, M3's own
    `StrictInvalidatingThroughShared`), while an exclusive path, the owner of
    a closed place, a `ref` or an `exclusive T*`, writes it as before when no
    frozen loan on an overlapping place is live (the temporal page's EX-TM-3,
    `s = "def"` under a live `const Core.String*`, stays accepted) (amended
    2026-10-28, review fold: RR1-B1; rev 2 covered only an assignment of the
    `Core.SharedImmutable` type itself, so the focused re-review's
    `fn Peek4(p: {.s: str, .n: i32}*, q: {.s: str, .n: i32}*) -> i64 { let s:
    str = p->s; *q = {.s = "longer", .n = 1}; return s.Size(); }`, whose
    `Plain` struct is not `Core.SharedImmutable` but holds a `str`, still
    wrote the borrowed `str` through `q` and prints 6 on the nightly for
    `Peek4(&y, &y)`, as does the same write of a `class W { var s: str; }`).
    A union is outside the closure: reading its field is `unsafe` in Strict
    (unions.md, "Strict Carbon and future safety hooks"), so a binding of a
    union's field is formed under that marker, whose obligation then includes
    that no path writes the union while the binding lives (break condition of
    that exclusion: the unions design makes a Strict field read safe; a union
    with such a field then joins the closure by a dated edit). The
    author's half is what no check of the language sees: every field
    private, no `addr` method that writes `self`, no function that writes the
    type's storage through a shared path or returns a non-`const` pointer or
    `ref` into it, no pointer into its own storage stored in it. It implies
    `Core.Freeze`, so the prelude's generic opt-ins are conditional
    (amended 2026-10-28, review fold: A-m-2): `Core.String`, and
    `Core.Slice(T)`, `Core.Buf(T)` and `Core.Optional(T)` for
    `forall [T: Core.Freeze]` (W-144), their bodies trusted under S0; and
    `Core.Box(T)`, which the prelude does not yet have, opts in the same way
    when W-144 adds it. So a by-value call through a shared pointer to one of
    them stays accepted (EX-TM-1, EX-M-4d), and a type that opts in is written
    through shared paths by no Strict code. The live shared path excludes the
    exclusive ones only through a loan the writer's checker sees, so a frozen
    loan formed through the free result of a marked `unsafe fn` call, whose
    carrier holds none, rests on that marker, whose obligation T6 extends:
    while a frozen loan formed through the result, or through a carrier
    derived from it, is live, whatever carries the loan, a value binding of a
    borrowed object, a `const` `ref` or the result of a call that keeps it, no
    path other than the result and its copies writes the storage that loan
    covers (amended 2026-10-28, document-review fold:
    R1-M2: `var x: str = "ab"; let v: Core.Slice(str) =
    unsafe Core.Slice(str).Make(&x, 1); let s: str = *v.Data(); x = "longer";
    return s.Size();` met `Make`'s stated obligation and read the owner's
    write, a nightly stand-in of its shape printing 6, section 8.7; amended
    2026-10-29, re-review round 2: RR1-B1, where this read "while the binding
    lives no path other than the result and its copies writes the storage it
    borrows": with `unsafe fn Alias(p: Core.Buf(i32)*) -> Core.Buf(i32)*`,
    `let r: Core.Buf(i32)* = unsafe Alias(&b); let s: Core.Slice(i32) =
    r->AsSlice();` keeps `AsSlice`'s frozen loan on `*r` in `s` after the
    `bound self` binding is dead (T5(d)), so `b = Core.Buf(i32).Make(1, 0);`
    freed the block `s[0]` then read with the binding-keyed obligation met,
    section 8.14). The
    trusted bodies keep the
    language half too (amended 2026-10-28, review fold: RR2-B1): a trusted
    body, the prelude's under S0, follows M3's write rule, writing an object
    whose type holds a `Core.SharedImmutable` sub-object only through an
    exclusive path, an owner, a `ref` or an `exclusive T*`, or through a
    pointer into storage owned by an object the body holds exclusively, every
    other path to that storage the type hands out being `bound` to that
    object; so `Core.Buf(T).Set`, which writes an element of the block, takes
    `ref self` (W-144). Rev 3's opt-in obligations covered each type's own
    storage and Strict code, and `Set`'s by-value receiver
    (buf.carbon:48-53 at 2407efa74: `*PointerOffset(self.ptr, i) = value`)
    wrote an element through a shared path: the focused re-review's
    `fn Peek8(b: Core.Buf(str)*) -> i64 { let s: str =
    *b->AsSlice().Data(); b->Set(0, "longer"); return s.Size(); }` binds `s`
    frozen on the open element and then has the trusted body write it, and a
    stand-in class of the same shape prints 6 on the nightly (section 0.7).
    Decided under R29: `Set` takes `ref self` for every element type, the
    receiver the re-review's first option names, so `b->Set` through the
    shared `b` is `StrictInvalidatingThroughShared` (M3(d)), and through an
    owner, a `ref` or an `exclusive` pointer it is
    `StrictSharedBorrowInvalidated` while a view of the block, or a binding
    formed through one, is live (T4); a by-value `Set` limited to element
    types that hold none, beside an exclusive setter, is rejected (section 7).
    The prelude's other writers were read at 2407efa74: `Make` writes a block
    no other path reaches yet (buf.carbon:39), `Destroy` takes `ref self`, and
    no other function of string.carbon, slice.carbon, buf.carbon or
    optional.carbon stores through a pointer; PR 65's `IndirectIndexWith`
    impls (`fn Ref(self, subscript: i64) -> ref T` on `Slice` and `Buf` at
    fee0ef31c, slice.carbon:76 and buf.carbon:74, under the interface's
    `fn Ref(self, subscript: SubscriptType) -> ref ElementType;`,
    index.carbon:16) write nothing themselves, and a Strict `b[i] = v` through
    them is M3's: accepted for an element type that holds none and
    `StrictSharedImmutableWrite` otherwise, a reference returned through a
    by-value receiver being no exclusive path. They do hand out a path into
    the storage, a `ref` into the block or the view's storage, which the rule
    above requires `bound`: under W-144 `IndirectIndexWith.Ref` takes
    `bound self` at the interface, as `IndexWith.At` does (temporal T5(e): an
    impl may not add `bound` beyond its interface), and in the `Slice` and
    `Buf` impls, upstream's own shape for a `ref`-returning operator
    interface (p005434:952-960, `Deref.Op`'s `bound ref self` at the interface
    and `bound self` in the impl for `T*`). A binding formed through `b[i]`
    then keeps the loan on `b` that `Set`'s `ref self` conflicts with:
    `var b: Core.Buf(str) = Core.Buf(str).Make(1, "ab"); let s: str = b[0];
    b.Set(0, "longer"); return s.Size();` is `StrictSharedBorrowInvalidated`
    at the `Set` (T4), where with PR 65's unbound `Ref` `s` binds frozen on an
    element reached through a free result, with no loan on `b`, the `Set` is
    accepted and the trusted body writes the element `s` borrows, returning 6,
    `Peek8`'s shape again (the focused re-review's round 3; a nightly stand-in
    prints 6, section 0.7). PR 65 lands after PR 53, so the obligation is
    W-144's brief (B.4) and DR-1 carries the counterexample on PR 65's
    records (section 0.8) (amended 2026-10-28, review fold: RR3-M1; rev 4
    read only "write nothing themselves", auditing the write half of `Ref`).
    Any other binding of a borrowed object on an open place is
    `StrictBorrowFromShared`, with the fixes the pages name: an owner or an
    `exclusive T*`, `Core.Guarded(T)`, the type's `value_rep = const Self` when
    it is small and copyable, a `var` copy of a struct or tuple
    (`var v: T = *p;`, whose `Plain` elements are read and whose class
    elements bind under this same rule), or `unsafe` at the binding, whose
    obligation is that no path mutates the object while the binding's loan
    is live, a `bound self`'s as long as the call's result that keeps it
    (T5(d); amended 2026-10-29, re-review round 2: RR1-B1, where this read
    "while the binding lives"). A value binding from a
    materialized temporary owns the storage and holds no loan, as before. The
    mechanism is the loan rule widened, with the eager copy left to the type by
    upstream's `value_rep`; the eager copy for every type stays rejected
    (section 7). **Cost of realignment:** in Strict, a `Plain`-field write or an
    `addr` call on a borrowed object during its binding is rejected even where
    it frees nothing (EX-M-4c; EX-M-1's `a->Set(0, 5)` under `first` by W-349);
    a by-value method of a class that does not opt in, called through a `T*` or
    `const T*` parameter, a global or a loaded pointer, needs `unsafe` or one of
    the fixes; a whole two-element struct read into a `let` through a
    shared parameter is rejected (EX-M-4d); a `Core.String` or a
    `Core.Slice(T)` for a `Core.Freeze` `T` (amended 2026-10-28, review fold:
    RR2-m3; rev 3 named `Core.Slice(T)` for every `T`, whose opt-in is
    conditional), or a struct, tuple, array or class that holds one, is
    assigned through a `T*` only with `unsafe`, an `exclusive T*` or a `ref`
    (EX-M-4d's `Peek2` and `Peek4`; the aggregate amended 2026-10-28, review
    fold: RR1-B1), so a class's setter of such a field takes `ref self` where
    `addr self` sufficed (M4); a global that holds one, an open place, is
    assigned in Strict only with `unsafe` (amended 2026-10-28, review fold:
    RR1-m4); and `Core.Buf(T).Set` needs exclusive access to the `Buf` for
    every `T`, so EX-TM-3's `buf.Set(1, 7)` under the live view `v` is
    `StrictSharedBorrowInvalidated` and moves before `v` is formed, a callee
    given a `Buf` by value or through a shared pointer cannot `Set` it
    (slices.md:243-246 and :256-259 gain a dated amendment, A.10.2), and a
    `Plain` element is written while a view lives, or by such a callee, only
    through the `T*` that a view's `Data()` returns, for an element type that
    holds no `Core.SharedImmutable` sub-object (amended 2026-10-28, review
    fold: RR2-B1): `Data()` points at the view's element 0, so element `i` is
    written through `AsSlice().Subslice(i, i + 1).Data()` until PR 65's
    `IndirectIndexWith.Ref` gives `b[i] = v` and `s[i] = v`, and the body of
    EX-M-1's `IntVec.Set`, an `addr self` method over a private
    `Core.Buf(i32)`, writes its element that way, `self->buf.Set(i, v)` being
    `StrictInvalidatingThroughShared` (M3(d); A.2.11; amended 2026-10-28,
    review fold: RR3-m1, where rev 4 named `Data()`'s `T*` as if it reached
    every element), where SAFE-1 accepted all six. M3, M4 and D-SAFE-9 carry the
    language half as dated edits (A.2.4a, A.2.5, A.2.19, B.1.2a, B.3.5), and
    the soundness model and D-SAFE-2 the trusted bodies' rule (A.1.1, B.1.0).
    This is the cost p005434:667-669 anticipates ("if enforcing it in the
    strict mode proves fundamentally untenable due to ergonomic costs"), and
    revisiting it is upstream's call. Break condition: upstream relaxes
    p005434:663 under its :665-669 conditions (W-348's own); or a reviewer
    shows a prelude function that writes storage holding a
    `Core.SharedImmutable` sub-object through a shared path, an element of a
    block it owns included, or that hands out a path into such storage that is
    not `bound` to the object (amended 2026-10-28, review fold: RR3-M1: PR
    65's `IndirectIndexWith.Ref`), which is answered by fixing that function in
    a dated edit, its receiver made exclusive or `bound`, or its body changed
    (W-144), as `Core.Buf(T).Set` and `Ref` were; or a language-level write the
    rules admit through
    a shared path, answered by M3 (amended 2026-10-28, review fold: RR2-B1;
    rev 3 read "or a reviewer shows a prelude opt-in false (a prelude
    function, or a language-level write the rules admit, that writes its
    type's storage through a shared path), in which case that type's opt-in is
    withdrawn in a dated edit and its examples re-measured", which would have
    withdrawn `Core.String`'s opt-in for `Set`'s write, the alternative
    section 7 rejects for EX-TM-1's cost). An opt-in is withdrawn, in a dated
    edit with its examples re-measured, only when its own type's author
    obligation is shown false and the function cannot be fixed.
-   **D-SAFE2-6 — W-347: every `ref` binding is `nocapture` and `noalias`
    (p005434:83).** A `ref` binding, whatever its source, is exclusive access to
    its referent for its lifetime: no other path reads or writes it, or, for a
    `ref` of a `const` type, writes it (the read-only case of p005434:850-852's
    `restrict`, a frozen loan); a `ref` binding not marked `bound` does not
    escape (`captures(none)`), one marked `bound` escapes only into the result (`captures(ret:
    address, provenance)`, p005434:846-848). The source decides only whether the
    checker can establish this. On a closed place it is a checked reborrow that
    suspends every other carrier of the place (T2, T4); a `const` `ref` on an
    open place of a `Core.SharedImmutable` type is checked the same way; any
    other `ref` on an open place is an `unsafe` formation, spelled at the
    binding as T6 already spells a binding through a ⊥ carrier (`let ref r: T =
    unsafe *p;`, `unsafe F(ref *p)`), whose obligation is the one p005434 gives
    unsafe code, to "adhere to just the `noalias` restrictions" (:861-862);
    unmarked it is `StrictRefFromShared`. The shared-kind `ref` is gone. The
    `ref` operand of a built-in operator, the first operand of assignment, of
    the compound assignments and of `++` and `--`, the operand of `&`, the
    object of member access and the first operand of indexing (p005434:302-318;
    docs/design/assignment.md:76-82, "a `(ref self: Self)` parameter" whatever
    the operand's form), lives for the one operation, during which nothing else
    is evaluated, so where the implementation is built in it is established on
    any place, open ones included, forms no loan of its own, neither M3(d)'s
    exclusive-receiver call nor M3(e)'s exclusive loan, and M3 alone decides
    what the operation may do through a shared path; a user-written impl's `ref
    self` is a `ref` binding under this rule and its call M3(d)'s (amended
    2026-10-28, document-review fold: R1-M1: without it upstream's operator rule
    made every `Plain` write through `T*` that M3 permits, `q->n = 2` in
    EX-M-4d's `Peek` among them, a `ref` binding on an open place and so
    `StrictRefFromShared`). Built in is the semantics
    docs/design/assignment.md:146-157 gives the built-in types, `=` on integers,
    floating-point types, `bool` and pointers, compound assignment on integers
    and floating-point types, and `++` and `--` on integers, the prelude's impls
    of them counting as built in whatever their body (the impls :168-170 says
    are "provided for built-in types as necessary to give the semantics
    described above"; core/prelude/types/int.carbon:395-399's `Inc` as much as
    :331's `"int.sadd_assign"`); the assignment of a tuple, struct, array,
    choice type or class with no user-written `AssignWith` impl
    (assignment.md:159-161, a TODO upstream); and the language's own `&`, member
    access naming a field and indexing of an array (amended 2026-10-29,
    re-review round 2: RR1-m1, where this read "where the implementation is the
    language's own or a prelude impl whose body is a builtin it is established
    on any place, open ones included, and M3 alone decides": `++p->n` through
    `T*` was neither built in nor user-written, `Inc`'s body `self += AsInt(1);`
    being no builtin, while `p->n += 1` was built in). (Re-planned 2026-10-29,
    rev 8: RR2-M1, RR2-m1: section 8.16 restates this test by where an
    implementation is written and quotes assignment.md:159's heading, its block
    E4 replacing the sentence above; the pages and records state the sentence
    above until the fold commit that section plans.) A `ref` _return_ is not a
    binding, so the proposal's `Valid1` (:717-720), `ValToRef` (:826) and
    `Conditional` (:772-779) stay valid in both modes, each returning a
    reference expression whose kind is that of its loans; `Conditional`'s mixed
    set `{(r, exclusive), (*p, shared)}` keeps the weakest kind, shared, for the
    result expression, and binding that result with `let ref` is a `ref`
    formation like any other: checked when every place in the set is closed
    (`UsePick`, whose `z` the live `q2`'s shared loan on `y` excludes:
    `StrictSharedBorrowInvalidated` at the `let ref z`, T4; amended 2026-10-28,
    document-review fold: R1-m1, where this read "whose `z` now conflicts with
    the live `q2`: `StrictExclusiveBorrowConflict`"), `unsafe` otherwise. T8
    emits `noalias` and `captures(none)` or `captures(ret: address, provenance)`
    only where the requirement is established against every writer, Permissive
    and C++ ones included (amended 2026-10-28, review fold: A-M-1, A-B-1; rev 1
    emitted for every checked `ref` and made a Permissive caller's aliasing
    undefined behavior): for a `ref` binding on a place whose every carrier is
    the body's own, an owner of the body or a place reached only through
    carriers of such owners' loans, intra-function; for one on the referent of a
    `ref` parameter or the pointee of an `exclusive T*` parameter, and for those
    parameters themselves, only under T8's whole-package condition (no export to
    C++, no address taken, every Carbon call site in the package
    Strict-checked); and never for a `ref` on an open place, the checked `const`
    `ref` on a `Core.SharedImmutable` type included, whose frozen loan Strict
    enforces but which a Permissive body or C++ may still write as erroneous
    behavior, nor for an `unsafe`-formed one or one in a Permissive body, whose
    `noalias` is the unsafe code's obligation and not "established"
    (p005434:866-868). Permissive warns `PermissiveAliasedExclusive` and
    accepts, so D-SAFE-8's break condition ("an accepted p005434 example that
    becomes invalid in Permissive mode") stays unbroken. The options the brief
    names: the exclusive formation is taken where the place is closed, the
    `unsafe` formation where it is open, and "no `ref` from a shared pointer" is
    rejected (section 7). **Cost of realignment:** p005434:152-162's `F(ptr:
    i32*)`, whose `let ref x: i32 = *ptr;` binds through a shared parameter, is
    rejected in Strict (EX-TM-9) and is accepted with an `exclusive i32*`
    parameter or the `unsafe` marker; a `ref self: const Self` method called
    through a shared pointer to a type that does not opt in needs `unsafe`; a
    `ref` binding or a `ref` argument on a global, an open place, needs the
    `unsafe` formation (`unsafe F(ref g)` for an argument), a `const` `ref` of a
    `Core.SharedImmutable` type excepted (amended 2026-10-28, review fold:
    RR1-m4); and a `match` through a shared pointer binds payloads by value, not
    by `ref` (EX-M-5, EX-M-6). Break condition: W-347's own, an accepted
    upstream memory-safety proposal that narrows p005434:83 (cite it and close
    the item); and D-SAFE-8's, kept.
-   **D-SAFE2-7 — The Debug value-binding shadow flag.** Kept, as the Debug
    detector of what p005434:670-672 says unchecked code can still do: a
    Permissive body, an `unsafe`-formed binding's aliases or C++ mutating a
    borrowed object. Debug keeps, in shadow memory keyed by address and never
    in the object's layout, a count of live frozen loans for each byte of a
    borrowed object's storage, and every store that writes a byte whose count
    is non-zero, of any type and by any path, through `T*`, through a `ref`,
    through the owner, to a global by name or in an `addr self` body,
    reports `MutationDuringValueBinding` (the whole-object assignment
    amended 2026-10-28, review fold: A-B-1: review A's `Peek2` writes a whole
    `str`; the per-byte count amended 2026-10-28, review fold: RR1-B1: rev 2's
    count per object address missed `Peek4`'s write of an enclosing struct
    and any field at a nonzero offset; every store amended 2026-10-28, review
    fold: RR2-m1: rev 3 read "a `Plain` assignment through `T*`, to a field or
    to a whole object, that writes a byte whose count is non-zero, or an
    `addr self` call on an object one of whose bytes has a non-zero count",
    which missed a Permissive body's `g = "longer"` to a global that a Strict
    `let s: str = g;` binds, a write through a `ref` in Permissive code, and a
    Strict body's own write through a `ref` parameter that a Permissive
    caller made aliasing, `F(ref x, &x)` for
    `fn F(ref r: str, p: const str*) -> i64 { let s: str = *p; r = "longer";
    return s.Size(); }`; the fixer's nightly probes of the global and the
    `ref` shapes print 6, section 0.7), "carbon: mutation of
    a borrowed object; terminating", then `abort()`; Release does nothing, the
    write being erroneous and defined. It is never a Strict rule: a Strict
    body's write is statically rejected first, except a write that a
    Permissive caller made aliasing, which the Strict body cannot see and that
    call's `PermissiveAliasedExclusive` flags; the flag then reports it at the
    store. The name is kept; the message uses upstream's
    term. Break condition: a Debug-cost measurement past the strategy's Debug
    budget; the flag is then narrowed to writes from Permissive bodies, a dated
    edit.
-   **D-SAFE2-8 — Diagnostics.** Added, each with the Permissive twin
    `PermissiveAliasedExclusive` and stage 4 (W-148): `StrictRefFromShared`
    ("`ref` binding `{0}` of `{1}` through a shared path; use an `exclusive`
    pointer or `unsafe`", temporal page), `StrictBorrowFromShared` ("`{0}`
    borrows `{1}` through a shared path; `{2}` is not `Core.SharedImmutable`;
    copy it with `var`, use an `exclusive` pointer, or `unsafe`", where `{0}`
    names a value binding or a `bound` pointer argument, mutation page),
    `StrictBorrowedObjectMutated` ("write to `{0}` while it is borrowed by the
    value binding `{1}`", mutation page) and `StrictSharedImmutableWrite`
    ("write to `{0}` through a shared path overwrites `{1}` of
    `Core.SharedImmutable` type `{2}`; use an `exclusive` pointer or
    `unsafe`", where `{1}` is `{0}` itself or the sub-object of it that holds
    the type, mutation page, M3), the last two with the Debug column
    `MutationDuringValueBinding` (the fourth and the generalized `{0}` amended
    2026-10-28, review fold: A-B-1, A-B-2; rev 1 had three, and
    `StrictBorrowFromShared` read "value binding of `{0}` borrows"; the
    sub-object `{1}` amended 2026-10-28, review fold: RR1-B1, where rev 2's
    text read "write to `{0}` of `Core.SharedImmutable` type `{1}` through a
    shared path"). None renamed;
    `StrictSharedBorrowInvalidated` and `StrictInvalidatingThroughShared` keep
    their meanings. Break condition: stage 4 finds two of them
    indistinguishable at their sites; they merge in a dated edit.
-   **D-SAFE2-9 — W-349: each `bound` argument is immutable for the duration of
    the returned result (p005434:831-832).** A by-value `bound` argument of a
    borrowed type, `bound self` included, and a `bound` `const` `ref` keep their
    frozen loan for the result's lifetime, so no path writes their storage
    while the result lives (`StrictBorrowedObjectMutated`); a `bound ref`
    argument keeps its exclusive loan, which the result carries
    (`captures(ret: address, provenance)`), so no path but the result reaches
    it, when the result is a `ref` return (p005434:730-731's `ValidRef`), and
    keeps a frozen loan instead when the result is returned by value or with
    `val` (p005434:825's `RefToVal`), so it may be read and is written by no
    path while the result lives (amended 2026-10-28, review fold: A-m-1; rev 1
    kept the exclusive loan for every result, rejecting reads that upstream's
    "immutable" allows); and the pointee of a `bound` pointer argument, `T*`,
    `const T*` or `exclusive T*`, is held by the result: no path but the result
    and the carriers copied from it writes the pointee while the result lives,
    and the result writes it only as its own kind allows, never through a
    `const T*` (amended 2026-10-28, review fold: A-B-2; rev 1 read "each bound
    parameter" of a pointer as the copied pointer, immutable by construction,
    and left the pointee "not invalidated", which kept the W-349 narrowing in
    other words: under a live result, `Plain` writes through other aliases
    stayed legal for `Longest`, `Load`, `Valid1` and `Conditional`'s `p`). On a
    closed place T4 enforces this against every carrier; on an open place it
    is formed only when the pointee's type is `Core.SharedImmutable` (whose
    shared paths write nothing, M3), and the call is otherwise
    `StrictBorrowFromShared`, or `unsafe` at the call, as T6 spells a call
    that consumes a ⊥ carrier, with the obligation that no other path writes
    the pointee while the result lives. T5(a)'s kind map becomes: `ref`
    parameters give exclusive under a `ref` return and frozen otherwise,
    `exclusive T*` parameters give exclusive, `T*` and `const T*` parameters
    give shared, and a by-value parameter of a borrowed type or a `const` `ref`
    gives frozen; a mixed set takes the weakest kind, frozen counting below
    shared, so no write reaches a frozen argument through the result. The
    pointee of a `bound` `T*` or `const T*` argument carries a frozen loan
    held by the result, and that of a `bound` `exclusive T*` argument an
    exclusive loan the result holds; the result's own access to the pointee
    is at the kind T5(a)'s map gives its parameter, so it may write `Plain`
    storage through a `T*`, only reads through a `const T*` and has exclusive
    access through an `exclusive T*` (amended 2026-10-28, review fold:
    RR1-m1; rev 2 read "The pointer argument's pointee rule is T5(d)'s,
    applied with the shared kind the map gives.", which named no loan for
    the pointee). **Cost of realignment:** EX-M-1's aliased `a->Set(0, 5)`
    while `first` lives is rejected and moves after `first`'s last use; a
    caller's write to a local passed to `Longest`, `Load`, `Valid1` or
    `Conditional` is rejected while the result lives; while an array view
    `Core.Slice(T).FromArray(&a)` lives, `a` is written only through the
    view, so the slices design's opening `a[2] = 30` under the live view `s`
    is rejected and moves after `s`'s last use (A.10.1; amended 2026-10-28,
    review fold: RR1-M1); and a call of a function with a `bound` pointer
    parameter through a `T*` or `const T*` that reaches an open place of a
    type that does not opt in, `Valid1(p)` for a parameter `p: i32*` among
    them, needs `unsafe` or an `exclusive` pointer, where SAFE-1 accepted
    every one; `Core.String`'s opt-in keeps EX-TM-1's calls
    through shared pointers accepted. Break condition: W-349's own, upstream's
    memory-safety design reconsiders the rule (p005434:834) otherwise; or
    upstream reads "each bound parameter" of a pointer as the pointer value
    alone, and the pointee rule is withdrawn in a dated edit.
-   **D-SAFE2-10 — D-SAFE-19's Rust mapping.** A by-value parameter of a
    borrowed type is frozen for the call, which is what Rust's `&T` promises,
    so it exports as `&T` when `T: Core.Freeze` (Rust could otherwise mutate
    an interior-mutable field through `&T`) and as `&SharedView<T>` otherwise
    (a new "By type" row, stage 5 with `Freeze`). The wrappers section's
    `Freeze` proviso gains one sentence: a by-value parameter's `&T` is taken
    from the Rust caller for the call, not handed to Rust, so the proviso's
    reachability check governs the rows that hand Rust a `&T` and not this
    one (A.6.2). The `const T*` rows are
    unchanged: a live `const T*` is not frozen, `Plain` fields being writable
    through `T*` aliases (M3), so `const T*` stays `&SharedView<T>` with `&T`
    only under the `Freeze` proviso. The `At` example's receiver, a by-value
    `bound self`, exports as `&'a Self` under `Freeze`; its result stays
    `&'a SharedView<i32>`, because the element is not the receiver's storage
    and a by-value method may write it while the receiver is frozen, through
    the `T*` a view of the block returns, an `i32` holding no
    `Core.SharedImmutable` sub-object (D-SAFE2-3; amended 2026-10-28, review
    fold: RR2-B1, where rev 3 read "a by-value `Set` like `Core.Buf`'s", which
    now takes `ref self`). For the same reason the `Core.Slice(const T)` row
    keeps `&[T]` behind the `Freeze` proviso, its stated reason re-worded from
    "`Buf.Set` during a live view is the temporal page's EX-TM-3" to an element
    written through a view's `Data()` while another view lives (A.6.3a, B.1.8).
    Verdict part (3)'s "the D-SAFE-17 value-binding case
    generalized" is withdrawn from the gap; the gap is the const kind's. Break
    condition: D-SAFE-19's own (a Rust soundness argument against the
    wrappers), and a Rust soundness argument against `&T` for a frozen
    binding, which returns the row to `&SharedView<T>`.
-   **D-SAFE2-11 — W-350: arithmetic.md's three rows are upstream's build
    modes.** Under D-RG-20 the development build is Debug, the hardened build
    is Release and the performance build is the unsupported benchmarking build
    of safety/README.md:260-262, the Release build with its default hardening
    disabled. The fork keeps all three rows: Release wraps signed overflow (the
    hardened row's "two's complement result", answering :171-173's TODO for
    Release), Debug fails-stop on overflow (the development row), both fail-stop
    on division or remainder by zero, and the performance-build row stands for
    the benchmarking build, where "the behavior of the program is not
    defined". p005914:85-88 is met in every supported build mode, which is the
    strategy's own scope for it, the benchmarking build being "not ... a
    supported way". **Cost of realignment:** a build mode exists in which
    Carbon code, Strict included, may have undefined behavior; it is
    unsupported, never shipped, and named on the pages as outside every
    guarantee. D-SAFE-15's break condition is re-derived: the 0.5 percent `nsw`
    benchmark no longer asks for a "performance-build opt-in", which exists;
    the break condition is upstream's, an answer to :171-173 other than wrap,
    a rewrite of the rows, or a reconciliation of the build-mode pages
    otherwise than D-RG-20 reads them (W-350's own, the restored row then
    following the reconciled text).
-   **D-SAFE2-12 — W-353: closed, its classification corrected; I5's text
    realigned.** The zero-fill of every type's storage, padding included, in
    the Release build is p000257:356-358's hardening initialization in
    D-RG-20's hardened build (section 0.3), an accepted text at the cut that
    RG-1's H1.13 row did not quote, so W-353 was a misclassification, not a
    drift, and I5's rule stands (amended 2026-10-28, review fold: A-m-3, B-M1;
    rev 1 called it "closed by its break condition" and cited :355-358); I5
    gains the type-defined customization p000257:358-360 and README.md:2130-2131
    describe (a type may set parts of its unformed storage to values other
    than zero), with the spelling left to upstream (p000257:345-347 says
    only "by implementing interfaces"); the benchmarking build skips the
    hardening initialization, where an unformed read "may lead to undefined
    behavior" (p000257:180-181); Debug's poison-fill and fail-stop are
    unchanged. How an initialization error avoids undefined behavior for a
    type that defines no initialization of its own: its storage is zeros,
    the read erroneous with a defined value (p005914:87-88's
    "zero-initialization rather than fail-stop") in Release and a fail-stop in
    Debug; I2, I3 and the Permissive read rule are unchanged, and the EX-I rows
    keep their outcomes. The disclosures are corrected: README.md:2151-2153's
    "The fork promotes this zeroing to the Release baseline for every type;
    there is no separate hardened mode", I5's "promotes ... the departure is
    only ...", the alternatives bullet "Zero-fill in a hardened build only",
    and the register block's listing among the departures. D-SAFE-13's break
    condition is re-derived: a fork benchmark no longer scopes the zeroing,
    which is upstream's; the break condition is an upstream amendment of
    p000257's hardening initialization or a reconciliation of the build-mode
    pages otherwise than D-RG-20 reads them. **Cost of realignment:** none in
    the rule. Break condition of this decision: section 0.3's. The records
    (Appendix C.2) re-classify H1.13 ALIGNED with the quote, add the quote
    rows the weekly check reads, and word W-353's note as the corrected
    classification naming the cite I5 carried at filing.
-   **D-SAFE2-13 — W-351: SP4 keeps upstream's promise.** The fork provides
    "a way to disable the default hardening in release builds, but not in a
    supported way", "strictly for benchmarking purposes" (safety/README.md:
    260-262): the benchmarking build, the Release build with every run-time
    enforcement component of the release baseline removed, the bounds check,
    the division guard, the overflow wrap and the hardening initialization;
    its spelling is fixed with the build modes at stage 2 (W-146), not here,
    so the fork adds no spelling to the register. Beside it the per-site `unsafe
    fn GetUnchecked` stays the supported opt-out (README.md:223-226's "ways to
    write unsafe code that disables the run-time enforcement"). SP2 holds in
    every supported build mode; S0 and the memory-safe-language claim are
    stated for the supported build modes, on the strategy page (A.1.1), in
    D-SAFE-2's text and break condition (B.1.0) and in fork/safe/plan.md
    §1.1's S0 sentence (B.3.2), so that S0's break condition does not fire
    trivially in the benchmarking build, where overflow is undefined behavior
    (amended 2026-10-28, review fold: B-M4; rev 1 scoped the page only); the
    matrix's fail-stop row is the supported modes' row. D-SAFE-14's break
    condition gains W-351's own:
    upstream withdraws the promise, and the build goes with it. **Cost of
    realignment:** the audit property "no search of the source finds where
    the check was removed" holds for every program the design supports and
    not for a benchmarking build, which is configured outside the source.
-   **D-SAFE2-14 — The examples whose outcomes change** (section 4): EX-M-1 (the
    aliased `Set` under `first`), EX-M-5 and EX-M-6 (value payloads through
    shared pointers), `UsePick` (`StrictSharedBorrowInvalidated` at the `let ref
    z` in place of `StrictInvalidatingThroughShared` at `z = ...`; amended
    2026-10-28, document-review fold: R1-m1, where this read "`StrictExclusiveBorrowConflict`
    in place of"); added, EX-M-4c and EX-M-4d (the closed and the open borrowed
    object, EX-M-4d with review A's `Peek2`, the `Plain` whole-object write
    through a shared pointer that is now `StrictSharedImmutableWrite`; amended
    2026-10-28, review fold: A-B-1; and with the focused re-review's `Peek4`,
    the same write of an enclosing struct, amended 2026-10-28, review fold:
    RR1-B1; and with the round-2 re-review's `Peek8`, the fork-prelude
    `Core.Buf(str)` whose `Set` through the shared `b` is now
    `StrictInvalidatingThroughShared`, amended 2026-10-28, review fold: RR2-B1)
    and EX-TM-9 (p005434:152-162's `F`); the slices design's opening example,
    whose `a[2] = 30` under the live view `s` is now
    `StrictBorrowedObjectMutated` (A.10.1; amended 2026-10-28, review fold:
    RR1-M1); and EX-TM-3's `Buf` half, whose `buf.Set(1, 7)` under the live view
    `v` is now `StrictSharedBorrowInvalidated` and moves before `v` (A.3.12a;
    amended 2026-10-28, review fold: RR2-B1). Each changed program is rewritten
    in place with its superseded line kept in a comment, and the regression
    sets' "kept verbatim" sentences gain the dated exception. Break condition: a
    reviewer traces a page example to an outcome other than section 4's; the
    example or the rule is fixed, never the matrix alone.
-   **D-SAFE2-15 — Ids and residue.** No new work item and no F id (section
    §0.9): the implementation of every rule above falls inside SAFE-1's stage
    items, which gain dated notes (Appendix B.4): W-144 (the prelude's
    `Core.SharedImmutable` opt-ins, conditional on `Core.Freeze`, and `Box`'s
    when W-144 adds `Box`; the trusted bodies' write rule and
    `Core.Buf(T).Set`'s `ref self`, amended 2026-10-28, review fold: RR2-B1),
    W-146 (the benchmarking build, the
    hardening-initialization customization), W-148 (frozen loans, the closed
    and open places, M3's `Core.SharedImmutable` write rule over every type
    that holds such a sub-object, the four diagnostics, T5(d)'s pointee rule,
    the Debug flag's new scope and per-byte test (amended 2026-10-28, review
    fold: RR1-B1) over every store (amended 2026-10-28, review fold: RR2-m1),
    T8's
    attributes where established) and W-150 (the `&T` row); W-146's and
    W-148's notes also quote and supersede their lines that state the
    narrowed rules (section 0.5). The one new library name,
    `Core.SharedImmutable`, joins the register block's fork spellings and
    RG-1's entry H1.7 with its widened silence check (amended 2026-10-28,
    review fold: A-B-1, A-B-2, A-m-2, B-M2, B-M6). Break condition: a review
    finds a residue no stage item covers; it is filed as W-365 after a fresh
    re-scan.
-   **D-SAFE2-16 — The records placement.** Section 0.10's option (a): a
    dated-note records commit on PR 67's branch, after SAFE-2's commits exist,
    with the break condition stated there.

## §2 Spec

### §2.1 Conventions for the implementer

Every text change is a block of Appendix A or B that names the file, the line
range at 2407efa74, the anchor (the first words and the last words of the text
replaced, or of the text after which the new text goes), the action (replace,
insert after, rename) and the new text, verbatim, in a fenced block between the
column-0 comment lines google-doc-style-ignore and google-doc-style-resume, so
that the style hook leaves this plan's copy alone. The implementer copies the
fenced text without the fence. The texts are wrapped at 80 columns with no line
starting with a list marker, a `#` or a digit and a period except real list
items, and with no Latin abbreviation, no three-letter synonym of "by way of"
and no short form of "repository" (hand-off note four of SAFE-1's plan); the
implementer re-checks after prek (section 8). The placeholders (amended
2026-10-28, review fold: B-m2; rev 1 left `<head>`, `<c2-sha>`, `<time>`,
`<verdict 1>` and `<fixes>` undefined):

-   `<date>`: the UTC date, `date -u +%F`, of the commit that writes the text:
    commit 1's for Appendix A, commit 2's for Appendix B, the PR 67 note
    commit's for Appendix C.2, and the orchestrator's stamp's for Appendix C.1,
    C.3 and D; and `<rdate>`, the realignment's date, commit 1's
    `date -u +%F` (2026-10-28), which Appendix C and D use wherever they say
    "realigned", "REALIGNED", "CLOSED" or "realignment of", `<date>` staying
    the date of a "Last updated" line, a paragraph or the note commit (added
    2026-10-28, document-review fold: R2-m4: the stamp can land on a later UTC
    date than commit 1, and one placeholder dated the realignment differently
    in trunk's ORCHESTRATION and PR 67's ledger than the pages' marks do).
-   `<sha1>` and `<sha2>`: commit 1's and commit 2's short hashes, known only
    after they exist, so the texts that cite them (the register sentence, the
    landed notes, Appendix C and D) are written in commit 2 or later. Commit
    2's own texts, B.2.2 and B.3.8, cannot hold its hash: commit 2 writes
    "pending" in its place, and section 3 step 4's records commit fills
    `<sha2>` there with `<verdict 1>`, `<verdict 2>` and `<fixes>` (amended
    2026-10-28, document-review fold: R2-m1).
-   `<head>`: PR 53's dry head, the head at which section 3 step 5's re-review
    is dry; the PR 67 notes (C.2), the PR texts (C.1, C.3) and Appendix D cite
    it rather than `<sha1>`.
-   `<c2-sha>`: the PR 67 note commit's short hash (section 3 step 6);
    `<time>`: the UTC time, `date -u +%H:%M`, of the orchestrator's stamp of
    trunk's fork/ORCHESTRATION.md.
-   `<verdict 1>`, `<verdict 2>`: the two document reviews' verdicts with their
    finding counts; `<fixes>`: the fold commits' short hashes; `<n>`: the
    number of findings, which no text uses; filled by section 3 step 4's
    records commit, with `<sha2>`, where commit 2 wrote "pending"
    (amended 2026-10-28, document-review fold: R2-m1), and in Appendix D's
    copies, with `<sha1>` and `<sha2>` there and in C.1, from the files of
    section 3 step 8 (amended 2026-10-28, re-review round 1: RR1-m2, where
    this read "all filled by section 3 step 4's records commit"; the table
    of section 8.13 lists every placeholder still unfilled, the step that
    fills it and its known value).

Where a block replaces a sentence inside a paragraph, it
quotes the sentence to be replaced in full as its anchor and the rest of the
paragraph is untouched.

Every anchor and every superseded text a block quotes is byte-equal to its
file's source at 2407efa74 once these, and nothing else, are set aside: a line
break with the indentation after it; the `>` and the space after it that start a
blockquote line; the `//` and the space after it that start the second line of a
code comment the quote joins into one (A.2.12); the " / " with which a block
says it joins list items or separate pieces (A.2.8, A.3.4); a run of spaces in
a code line, the line's indentation included, which a quote writes as one
space or two (A.2.11's two anchors and its first block's quote, A.2.13's
anchor, A.3.13's two anchors); and a closing "..." that stands for the rest of
an anchor's code line (A.3.13). Link markup, code spans, emphasis and
punctuation belong to the text: a link is quoted as `[text](target)`, never as
its text alone, because the quote is of the page's source, not of its
rendered words. A quote in this plan's own prose that carries link markup is
written as a code span rather than between double quotes, the backticks being
its delimiters, so that this plan holds no live link for the check-links hook
to resolve against this file (A.1.6, A.5.10, A.8.1). A ledger note's quote is
of the item's JSON string value. The test is of anchors and superseded texts,
the texts the implementer finds on the page and replaces or keeps as quotes; a
quote of another file inside a new text, as A.4.2's and B.5's quote of the
design overview's sentence at docs/design/README.md:2147-2148, quotes the words
a reader of that file sees, a link by its text, and is not an anchor. The
implementer tests every quote this way before each commit, a mismatch being a
stop (section 8 item 5). (Added 2026-10-28, implementation: stop-and-amend:
link markup in two superseded quotes: rev 5's A.1.6 and A.5.10 quoted three
links by their text alone, section 8.12. The two code-line set-asides, the
code-span form and the test's scope amended 2026-10-28, stop-and-amend
re-review: AM6-M1: rev 6 named none of them, so its test as worded failed five
quotes it kept, section 8.12.)

### §2.2 Commit 1: the pages (Appendix A)

| Page (docs/design/) | Blocks | What changes |
| --- | --- | --- |
| safety/README.md | A.1.1 to A.1.7 | S0 stated for the supported build modes; the trusted bodies' write rule appended to the prelude paragraph (amended 2026-10-28, review fold: RR2-B1), with `IndirectIndexWith.Ref`'s `bound self` (amended 2026-10-28, review fold: RR3-M1); the `unsafe` form for a binding on an open place; four matrix rows and the `StrictSharedBorrowInvalidated` row's Debug cell; the spatial bullet; the kinds table's dated paragraph; the benchmarking blockquote kept, not withdrawn; staging rows 2 and 4 |
| safety/mutation_safety.md | A.2.0 to A.2.21, with A.2.4a, A.2.7a and A.2.17a (A.2.17a added 2026-10-28, review fold: RR3-m1) | the definition's exception; M1, M2, M3's `Core.SharedImmutable` paragraph, M4, M5, M8; the `Core.Plain` consequences; the Value bindings section with `Core.SharedImmutable`; diagnostics; EX-M-1, EX-M-4a, EX-M-4b, EX-M-5, EX-M-6 rewritten; EX-M-4c and EX-M-4d added, EX-M-4d with `Peek8` (amended 2026-10-28, review fold: RR2-B1); checklist, staging, decisions, alternatives, references; the Value bindings section's trusted-body paragraph names `IndirectIndexWith.Ref`'s `bound self` (amended 2026-10-28, review fold: RR3-M1); EX-M-1's prose names `IntVec.Set`'s body path and the C++ partition bullet gains the element writes that take `ref self` (A.2.11, A.2.17a; amended 2026-10-28, review fold: RR3-m1) |
| safety/temporal_safety.md | A.3.1 to A.3.17, with A.3.12a | status; vocabulary (frozen, closed, open); the kinds paragraph; `ref` bindings; T2, T4, T6's sentence, T8; T5(a) and (d); diagnostics and the `StrictSharedBorrowInvalidated` row's Debug cell; EX-TM-1's prose; EX-TM-3's `buf.Set(1, 7)` moved before the view and its reason (A.3.12a, amended 2026-10-28, review fold: RR2-B1); `Load` and `UsePick`; EX-TM-9 added; staging, decisions, alternatives |
| safety/initialization_safety.md | A.4.1 to A.4.6 | status; I5's first paragraph and one clause of its second; staging row 2; D-SAFE-13's I5 sentence and break condition; the alternatives introduction and bullet; the external fact's row |
| safety/spatial_safety.md | A.5.1 to A.5.11 | overview; status; SP2's heading and sentence; SP4's heading and body; arithmetic; EX-SP-5, EX-SP-6; the C++ division bullet; staging row 2; D-SAFE-14 and D-SAFE-15; two alternatives; one external fact |
| safety/rust_interop.md | A.6.1 to A.6.6, with A.6.3a | the asymmetry bullet; a "By type" row and the `Freeze` proviso's sentence; the `At` line and bullet; the `Core.Slice(const T)` row's reason (A.6.3a, amended 2026-10-28, review fold: RR2-B1); verdict parts (1) and (3); the break condition and D-SAFE-19's bullet; fold A-9's sentence and the eager-copy alternative |
| values.md | A.7.1, A.7.2 | the "Answered" and "Pinned" notes |
| README.md | A.8.1 | the unformed-state amendment |
| expressions/arithmetic.md | A.9.1 | the amendment blockquote |
| slices.md | A.10.1, A.10.2 | a dated note after SP3's amendment to the opening example: in Strict the write to the array goes through the view or after the view's last use (W-349; added 2026-10-28, review fold: RR1-M1); a dated amendment after the `Buf` bullets: in Strict `Set` takes `ref self` (W-348; added 2026-10-28, review fold: RR2-B1) |

Not edited, measured (section 0.4): type_safety.md, but for its `unsafe fn`
contract sentence (:135-140), which the focused re-review's round 2 fix commit
widens by T6's obligation for a free result (amended 2026-10-29, re-review
round 2: RR1-B1; section 8.14), terminology.md, unions.md
(whose Strict read rule M3's new paragraph cites),
docs/project/principles/safety_strategy.md, the two SKIP stubs; slices.md:65,
SP3's line, stays as it is (rev 2 listed slices.md here; amended 2026-10-28,
review fold: RR1-M1).

### §2.3 Commit 2: the records (Appendix B)

| File | Blocks | What changes |
| --- | --- | --- |
| fork/decision-log.md (the F-013 entry) | B.1.0 to B.1.10, B.2.1, B.2.2 | D-SAFE-2's S0 scope and break condition (B.1.0, amended 2026-10-28, review fold: B-M4) and its prelude clause's trusted-body rule (amended 2026-10-28, review fold: RR2-B1; with `IndirectIndexWith.Ref`'s `bound self` in B.1.0 and B.1.7, amended 2026-10-28, review fold: RR3-M1), D-SAFE-8, D-SAFE-10's T2, T4 and T8 sentences, D-SAFE-11(a) and (d), D-SAFE-13's I5 and break condition, D-SAFE-14's SP2, SP4 and break condition, D-SAFE-15, D-SAFE-17, D-SAFE-19's new mapping, verdict part (3) and `&[T]` proviso (the last amended 2026-10-28, review fold: RR2-B1), D-SAFE-20's surface, D-SAFE-21's stages 2 and 4; the register block's spellings and departures sentence; RG-1's paragraph gains a dated SAFE-2 sentence per item |
| fork/safe/plan.md | B.1 (the same texts in §0.3), B.3.1 to B.3.8 | the pointer paragraph after Status; §1.1's S0 sentence, matrix rows and `StrictSharedBorrowInvalidated` Debug cell (amended 2026-10-28, review fold: B-M4, B-m6); §1.4's and §1.3's sentences; §1.5's kinds paragraph and diagnostics; §1.6's M5 and M8 sentence; §4.1's rows; §4.3's adversary-1 sentence; the "Realigned notes (SAFE-2)" paragraph after the landed notes |
| fork/inventory/work-items.json (PR 53's ledger) | B.4 | dated notes on W-144, W-146, W-148 and W-150, those on W-146 and W-148 quoting and superseding the lines section 0.5 lists (amended 2026-10-28, review fold: B-M6), W-144's naming `IndirectIndexWith.Ref`'s `bound self` and the counterexample (amended 2026-10-28, review fold: RR3-M1) |

Not edited on PR 53: fork/gap-analysis.md (row 89 states no narrowed rule),
PR 53's own fork/ORCHESTRATION.md (trunk's is the live snapshot; the
orchestrator stamps it, Appendix D), the six ledger items (PR 67's, Appendix
C.2), fork/rulebook.md.

## §3 Commits and reviews

All on `claude/carbon-fork-0-1-safe` in /home/user/carbon-safe unless named
otherwise, NEW commits only (never amend, rebase or force-push: PR 53 is a
submitted PR), `--author='jmann345 <jerrymannstan@gmail.com>'` with
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`, explicit
paths only (R20), each message recording the prek fixpoint, the R31 counts
before and after, rumdl, the nightly compiles where a page with an example
changed, and ending after a blank line with the session's two attribution
trailers.

1.  **SAFE-2 (1/2): the six realignments on the safety pages, values.md,
    slices.md, arithmetic.md and README.md (W-347 to W-351, W-353).** Appendix
    A, the ten pages of section 2.2. slices.md is edited by A.10.1 and A.10.2
    only, not at :65, SP3's line, which SAFE-2 does not change, nor in the
    `Set` bullet that PR 65 rewrites (amended 2026-10-28, review fold:
    RR1-M1; rev 2 left slices.md out of the title and the nine pages; A.10.2
    amended 2026-10-28, review fold: RR2-B1).
2.  **SAFE-2 (2/2): records: the F-013 decisions realigned, SAFE-1's plan
    aligned, the register block and the landed notes.** Appendix B, with
    `<sha1>` filled in.
3.  **Two document reviews**, fresh agents, in parallel, read-only, on the
    head after commit 2; each returns findings graded BLOCKER, MAJOR or MINOR,
    each citing file:line (R8). Adversary 1, design fidelity and soundness:
    every realigned rule against upstream's text at the tip (re-fetched, the
    sha named; section 0.1's quotes re-read; check_quotes.sh and
    check_greps.sh re-run), the memory-safety argument of each new rule (the
    closed-place claim of D-SAFE2-4, the frozen loan's soundness on an open
    place under `Core.SharedImmutable`, T8's honesty, the benchmarking build
    outside S0), the section 0.3 reading of p000257, and every section 4 row
    traced by hand through the pages' rules. Adversary 2, readability,
    consistency across the pages and this plan, records readiness and R31:
    every page states the same rule in the same words where it restates one,
    no dependent line of section 0.4's and 0.5's tables states a superseded
    rule outside a quoted superseded text, the log and §0.3 are identical, the
    §1 sentences match the pages (R27), the heading-set and count diffs are
    the deliberate ones only, every link resolves, and Appendix C's and D's
    texts match the commits.
4.  **The fixer**, one fresh agent: reproduces every finding against the
    files, then folds it by NEW commits, each fold marked "(amended <date>,
    document-review fold: <id>)" on the page and, where the same finding
    reaches a §0.3, §1 or log sentence, there too; a budget of three fix
    commits, records-only commits not counted; NO shrink line: a defect past
    the budget stops the workflow at a plan revision of this file. Every
    finding is dispositioned (ACCEPTED with where it landed, or REJECTED with
    the cite that refutes it, R17); the fold record goes into this plan as
    section 8.7 by a records commit, which also fills `<sha2>`, `<verdict 1>`,
    `<verdict 2>` and `<fixes>` where commit 2 wrote "pending" (B.2.2, B.3.8;
    amended 2026-10-28, document-review fold: R2-m1). The budget is spent by
    0f281d8bd, e1574b003 and cbdc0552e, and round 2's RR2-M1 and RR2-m1 change
    pages, so the workflow stopped here at rev 8: section 8.16 re-plans both at
    their root and gives the texts of one fold commit, which is made only on an
    orchestrator's ruling that allows that one commit past the budget, no
    shrink line being drawn (amended 2026-10-29, rev 8: section 8.16).
5.  **The focused re-review of the fix commits**, one fresh agent per round,
    at most three rounds, until dry: dry is no BLOCKER and no MAJOR and every
    MINOR records-only, folded by one records commit. A round that is not dry
    goes back to step 4 within its budget. Round 3, the loop's last, reviews
    rev 8 and its records commit; the fold commit of section 8.16, if the
    ruling allows it, is reviewed under this step's dry test by the fresh
    agent the ruling names, before steps 6 to 8 (amended 2026-10-29, rev 8:
    section 8.16).
6.  **The PR 67 note commit** (D-SAFE2-16, Appendix C.2), in a detached scratch
    worktree of PR 67's head under /dev/shm/safe2-implementer/rg1 (removed
    after), with `<head>` filled in, reviewed by one fresh agent before any
    push, merge-treed (section 0.8), and pushed by the implementer as a
    fast-forward of `claude/carbon-fork-0-1-rg1` (`git push origin
    <c2-sha>:claude/carbon-fork-0-1-rg1`) once that review is dry, RG-1's
    precedent (fork/register/rg1-plan.md section 3.2: its records commits were
    pushed by its implementer at its step 6).
7.  **Push PR 53's branch**: the implementer pushes `<head>` as a fast-forward
    of 2407efa74 (`git push origin <head>:claude/carbon-fork-0-1-safe`) after
    step 5 is dry and before step 6's push, so that the notes cite a pushed
    head.
8.  **The orchestrator** refreshes PR 53's and PR 67's descriptions and stamps
    trunk's fork/ORCHESTRATION.md, verifying each by the API; no PR is merged,
    no workflow dispatched. It posts from files the implementer writes, with
    every placeholder filled, and names in its hand-off (RG-1's section 3.3
    precedent): Appendix C.1 under the heading "SAFE-2 realignment (<date>)" in
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/impl/pr_53_refresh.md,
    Appendix C.3 in
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/impl/pr_67_refresh.md,
    each appended to the PR's current description, which the orchestrator
    fetches, and Appendix D's texts in
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/impl/orchestration_stamp.md
    (amended 2026-10-28, review fold: B-m1; rev 1 named no pusher and no file).

## §4 The worked-example matrix

"Today" is the 0.1 toolchain's outcome in the checklist's vocabulary (for
today's syntax, the nightly results of section 0.7); "Strict" is the outcome
under the realigned design and the stage that enforces it.

| Example | Today | Strict, realigned | Was (2026-10-12) | Changed by |
| --- | --- | --- | --- | --- |
| EX-M-1 `Fill` | NEW-SYNTAX | `a->Set(0, 5)` under `first` is `StrictBorrowedObjectMutated` (`Get`'s `bound self` freezes `*vec`, a closed place as the pointee of the `exclusive` parameter `vec`); the program moves the write after `Core.Print(*first)`, where it is accepted; stage 4 | accepted, `*first` reads 5 | W-349 |
| EX-M-4a `ValueBinding` | ACCEPTS (nightly exit 0, prints 1) | ACCEPTS, `b` is 1: `i32` is copy-represented | ACCEPTS, by `Plain` | reason only (W-348) |
| EX-M-4b `ValueBinding2` | ACCEPTS-UNCHECKED (fork prelude) | `StrictSharedBorrowInvalidated` at the assignment; stage 4 | the same | reason only |
| EX-M-4c `ValueBinding3` (new) | ACCEPTS-UNCHECKED (nightly exit 0, prints 1) | `StrictBorrowedObjectMutated` at `a.n = 2`; stage 4 | (not in the design) | W-348 |
| EX-M-4d `Peek`, `BufSize`, `Peek2`, `Peek4`, `Peek8` (new; `Peek2` amended 2026-10-28, review fold: A-B-1; `Peek4` amended 2026-10-28, review fold: RR1-B1; `Peek8` amended 2026-10-28, review fold: RR2-B1) | ACCEPTS-UNCHECKED (nightly exit 0: `Peek` prints 1, `Peek2(&x, &x)` prints 6, `Peek4(&y, &y)` prints 6; `BufSize` and `Peek8` are fork prelude, `Peek8`'s stand-in class printing 6, section 0.7) | `Peek`: `StrictBorrowFromShared` at `let v`; `BufSize`: accepted (`Core.Buf(i32)` is `Core.SharedImmutable`, `i32` being `Freeze`); `Peek2`: the binding of `*p` is accepted (`Core.String` opts in) and `*q = "longer"` is `StrictSharedImmutableWrite` (M3); `Peek4`: the binding of `p->s` is accepted and `*q = {.s = "longer", .n = 1}` is `StrictSharedImmutableWrite`, the `Plain` struct holding a `str` (M3); `Peek8`: the binding of the element is accepted (`str` opts in) and `b->Set(0, "longer")` is `StrictInvalidatingThroughShared`, `Set` taking `ref self` (M3(d)); stage 4 with W-144 | (not in the design; SAFE-1 accepted the writes of `Peek2`, `Peek4` and `Peek8`, M3(c) and the by-value `Set`) | W-348 |
| EX-M-5 `Alt` | NEW-SYNTAX | the realigned program, a value payload, is accepted; the old `case .Some(ref s)` would be `StrictRefFromShared`; stage 4 plus the `Optional` redesign | accepted with a shared-kind `ref` payload | W-347 |
| EX-M-6 `Alt2` | NEW-SYNTAX | `StrictInvalidatingThroughShared` at `*d = ...` with a copied payload `p: i32*` | the same diagnostic with `ref p` | W-347 (program only) |
| EX-TM-1 `Longest` | NEW-SYNTAX | accepted: `a->Size()` binds `*a` frozen, `Core.String` being `Core.SharedImmutable`; in a caller both pointees are held by the result, frozen as the pointees of `bound` pointer arguments that are not `exclusive T*`, the `const` only keeping the result's own access to reads (amended 2026-10-28, document-review fold: R1-m2, where this read "frozen (the parameters are `const`)"), for its lifetime (T5(d)), a caller's write to either through any other path being `StrictBorrowedObjectMutated`; stage 4 with W-144 (amended 2026-10-28, review fold: A-B-2) | accepted; a caller's `Plain` write to an argument under a live result accepted | reason, and a caller's writes under a live result (W-349) |
| EX-TM-3 `Use` | ACCEPTS-UNCHECKED (`String` half: nightly exit 0) | the `String` half unchanged: `p->Size()` binds on a closed place, and `s = "def"` writes through the owner, a closed place under no frozen loan, so M3's `Core.SharedImmutable` paragraph does not apply (amended 2026-10-28, review fold: A-B-1); the `Buf` half: `buf.Set(1, 7)` under the live view `v` is `StrictSharedBorrowInvalidated`, `Set` taking `ref self` (W-144) and `v` holding a frozen loan on `buf`, so the program calls it before `v` is formed and `v[1]` still prints 7; stage 4 with W-144 (amended 2026-10-28, review fold: RR2-B1; rev 3 read "unchanged") | accepted, `buf.Set(1, 7)` under the live `v` | W-348 (`Buf` half; amended 2026-10-28, review fold: RR2-B1) |
| EX-TM-8 `Pick` | NEW-SYNTAX | accepted: returns a reference expression | accepted | none |
| EX-TM-8 `UsePick` | NEW-SYNTAX | `StrictSharedBorrowInvalidated` at `let ref z`: `z` would be an exclusive `ref` on the closed `x` and `y`, and `q2`'s shared loan on `y` is live (T4); stage 4 (amended 2026-10-28, document-review fold: R1-m1, where this read "`StrictExclusiveBorrowConflict` at `q2->AsSlice()`: `z` is an exclusive `ref` on the closed `x` and `y`") | `StrictInvalidatingThroughShared` at `z = ...` | W-347 |
| EX-TM-8 `Launder1` to `Launder5`, `Wild`, `Wild3`, `Load` | as before | unchanged; re-traced (amended 2026-10-28, review fold: A-M-2, A-B-2): a `Core.Slice(i32)` receiver bound on a local (`Launder1`'s `s.Subslice`, `Launder3`'s `b.AsSlice`) is a frozen loan on a closed place; `Launder4`'s `o.Get()` binds a copy-represented `Core.Optional(i32*)`, an adapter of `MaybeUnformed(i32*)` (section 0.1), so it forms no loan on `o` and the loan on `x` its value carries is unchanged; `Load`'s result also holds the caller's `*q` (T5(d)), which in `Wild3` is ⊥ and needs the T6 `unsafe` first; no diagnostic changes | unchanged | none |
| EX-TM-9 `F`, `F2`, `F3` (new) | `F`: ACCEPTS-UNCHECKED (nightly exit 0, prints 3); `F2`, `F3`: NEW-SYNTAX | `F`: `StrictRefFromShared`; `F2` (an `exclusive i32*`) and `F3` (`unsafe *ptr`) accepted; stage 4 | `F` accepted (a shared-kind `ref`) | W-347 |
| p005434 `Valid1`, `ValToRef`, `Conditional` | NEW-SYNTAX (`bound`) | the definitions accepted in both modes: reference returns, not bindings; a call checks T5(d): on a local, the pointee is held by the result and the caller's other paths may not write it while the result lives; through a parameter `p: i32*` to an open place, `Valid1(p)` is `StrictBorrowFromShared` in Strict, `PermissiveAliasedExclusive` in Permissive (amended 2026-10-28, review fold: A-B-2) | accepted, definitions and calls | reason; calls through open places (W-349) |
| slices.md's opening example (`s` from `FromArray(&a).Subslice(1, 3)`, then `a[2] = 30`; added 2026-10-28, review fold: RR1-M1) | ACCEPTS-UNCHECKED (fork prelude; the page's comments give the run, `s[1]` reading 30) | `a[2] = 30` is `StrictBorrowedObjectMutated` while `s` lives: `FromArray`'s `bound p` holds `a`, a closed place, for the view's lifetime (T5(d)); the write moves after `s`'s last use, or goes through the view once slices are writable; Permissive warns `PermissiveAliasedExclusive`; stage 4 with W-144's `bound` | accepted, the write visible through `s` | W-349 |
| EX-SP-5 `Hot` | NEW-SYNTAX | unchanged; the comment reads "the supported opt-out" | "the only opt-out" | W-351 (comment) |
| EX-SP-6 `Div` | ACCEPTS-UNCHECKED (nightly exit 0) | stage 2 guard fails-stop in every supported build mode; the benchmarking build has no guard | "in every mode" | W-350 (prose) |
| EX-I-1 to EX-I-5 | as before (EX-I-1, EX-I-2, EX-I-5 nightly exit 0) | unchanged; EX-I-1's Release read yields 0 by I5 | unchanged | none (W-353 closed) |
| Rust `At` | ANALYSIS | receiver `&'a Self` under `Freeze`, result `&'a SharedView<i32>` | receiver `&'a SharedView<Self>` | D-SAFE2-10 |

## §5 Scoreboard

No conformance program and no golden moves: SAFE-2 touches no file under
fork/conformance/, toolchain/, core/ or testdata. The two SKIP stubs
(safe_carbon_design.carbon, safety_strategy_doc.carbon) are untouched, and
`python3 -I fork/conformance/runner.py --self-test` must pass on each commit's
tree. The bullet and gap row 89 are unchanged (DONE on document review); the
held state's container-local numbers are unaffected.

## §6 Churn and collisions

Expected churn, measured by the implementer as `git diff --numstat 2407efa74`:
safety/mutation_safety.md about 180 added and 70 removed lines (the Value
bindings section and two new examples), temporal_safety.md about 130 and 50
(the `ref` section, T2, T4, T8, EX-TM-9), spatial_safety.md about 60 and 30,
README.md (safety) about 40 and 10, initialization_safety.md about 40 and 20,
rust_interop.md about 30 and 15, values.md, README.md and arithmetic.md about
10 each, slices.md 11 added and none removed (A.10.1; amended 2026-10-28,
review fold: RR1-M1) and 11 more added (A.10.2; amended 2026-10-28, review
fold: RR2-B1), temporal_safety.md's figure including about 10 more added and
4 removed for EX-TM-3 (A.3.12a); fork/decision-log.md about 120 and 60,
fork/safe/plan.md about 80 and 40, work-items.json four notes. Heading
changes: six renamed, all H3 (spatial SP2 and SP4; mutation M5, EX-M-4a,
EX-M-4b and EX-M-5), and three added
(mutation EX-M-4c and EX-M-4d, temporal EX-TM-9, H3); the markdown-toc hook
rewrites the three tables of contents (amended 2026-10-28, review fold: B-m5;
rev 1 counted two renames).

Collisions (section 0.8): the page edits collide with no held head. The
records follow the merge rules already recorded for PR 53: the F-013 entry and
its register block are PR 53's own region of fork/decision-log.md, merged at
PR 53's landing by keeping both sides' entries in the log's newest-first order
(RG-1's section 4.7); PR 53's ledger notes on W-144 to W-150 merge by id with
no other head touching those items; fork/safe/ is PR 53's alone. The PR 67
note commit edits seven items of PR 67's ledger (the six and W-355), the H1.7
row of fork/register/rg1-checks.tsv, eleven appended rows of
fork/register/rg1-quotes.tsv, rows H1.7 and H1.13 and the counts of
fork/register/rg1-plan.md, and RG-1's entry in PR 67's fork/decision-log.md
(amended 2026-10-28, review fold: B-M1, B-M2, A-M-2); no other head touches
the register files or those items, PR 68's ORCHESTRATION and log edits are in
other regions (merge-tree before the push, section 3 step 6), and PR 67's own
fork/ORCHESTRATION.md is left as RG-1 wrote it, trunk's being the live
snapshot that Appendix D stamps.

## §7 Risks and rejected alternatives (falsifiable)

Risks:

-   **R-1 the ergonomic cost of W-348 is larger than section 1 states.**
    Falsifier: on the fork's own corpus of examples and conformance programs
    read as Strict files, count the by-value calls and `let` bindings of
    borrowed objects through open places on types that do not opt in; more
    than the examples section 4 lists means the pages under-state the cost,
    and the count is added to D-SAFE2-5's cost sentence by a dated edit. The
    rule does not change: relaxing it is upstream's call (p005434:665-669).
-   **R-2 a prelude `Core.SharedImmutable` opt-in is false, or a prelude
    function breaks M3's write rule** (the second half added 2026-10-28,
    review fold: RR2-B1). Falsifier: a
    prelude function of `Core.String`, `Core.Slice`, `Core.Buf`,
    `Core.Optional` or `Core.Box` that writes its type's storage through a
    shared path or returns a mutable pointer into it (`Box.DerefShared` returns
    the pointee, not the box, and is the one to check), or a language-level
    write the rules still admit through a shared path: a whole-object or field
    assignment, an `addr` call, a non-`const` pointer formed to a sub-object
    (amended 2026-10-28, review fold: A-B-1; rev 1 checked prelude functions
    only, and review A's `Peek2` was such a write until M3's new paragraph),
    or an assignment of an enclosing aggregate, a struct, tuple, array or
    class that holds such a type, the shape of the focused re-review's
    `Peek4` and of a class with a `str` field, which rev 2's paragraph still
    admitted and M3's structural "holds a `Core.SharedImmutable` sub-object"
    now rejects (amended 2026-10-28, review fold: RR1-B1); or any prelude
    function that writes storage holding a `Core.SharedImmutable`
    sub-object through a shared path, an element of a block it owns
    included, the shape of the round-2 re-review's `Peek8`, whose element
    `Core.Buf(T).Set`'s by-value receiver wrote (amended 2026-10-28, review
    fold: RR2-B1; rev 3's falsifier named only a function writing its own
    type's storage); or any prelude function that hands out a path into such
    storage without `bound` on the object it views, the shape of the round-3
    re-review's counterexample: PR 65's by-value `IndirectIndexWith.Ref`
    returns a `ref T` into the block from an unbound receiver, so in
    `var b: Core.Buf(str) = Core.Buf(str).Make(1, "ab"); let s: str = b[0];
    b.Set(0, "longer"); return s.Size();` the binding `s` holds no loan on `b`,
    the `ref self` `Set` is accepted and 6 is returned (a nightly stand-in
    prints 6, section 0.7; amended 2026-10-28, review fold: RR3-M1; rev 4's
    falsifier named only the writers). A prelude function is answered by
    fixing it, its receiver made exclusive or `bound` or its body changed by a
    dated edit (W-144), as `Set`'s and `Ref`'s were, and a language-level
    write by M3; an opt-in is withdrawn
    (D-SAFE2-5's break condition) and its examples re-measured only when its
    own type's author obligation is shown false and no fix of the function
    keeps it.
-   **R-3 the storage reading of D-SAFE2-3.** Falsifier: an upstream text that
    counts memory reached through an owning pointer as the object's storage for
    values.md:461-462. Then a `Plain` write of a `Core.Buf` element through
    the `T*` that a view's `Data()` returns, while a value binding of the
    `Buf` lives, becomes `StrictBorrowedObjectMutated`, and the Rust `At`
    result and `Core.Slice(const T)` rows are re-derived (D-SAFE2-10). Rev 3
    named EX-TM-3's `buf.Set(1, 7)` under the live view `v` as this
    falsifier's consequence, with `Set` taking `addr self`; that consequence
    is now the design's under either reading: `Set` takes `ref self`
    (D-SAFE2-5), an exclusive use that `v`'s frozen loan on `buf` excludes, so
    the call is `StrictSharedBorrowInvalidated` and EX-TM-3 makes it before
    `v` is formed (A.3.12a; amended 2026-10-28, review fold: RR2-B1; an
    `addr self` receiver would not do, its `Self*` being a shared path through
    which M3 lets no trusted body write a `Core.String` element).
-   **R-4 the p000257 reading of section 0.3.** Falsifier: section 0.3's break
    condition. Appendix B.5 holds the alternative texts.
-   **R-5 the value representation moves under the examples.** Upstream's
    toolchain has "TODO: Pick a better value representation when possible"
    (type_completion.cpp:776; rev 1 said :779, amended 2026-10-28, review fold:
    A-M-2, and the line is one of the quote rows Appendix C.2 adds); if upstream
    gives small structs or classes a copy
    representation, EX-M-4c's and EX-M-4d's struct bindings become copies and
    their diagnostics disappear. Falsifier: an upstream commit to
    type_completion.cpp's struct or class representation, which the weekly
    check lists (R32 (c)); the pages state the outcome against the
    representation the toolchain chooses at the tip named.
-   **R-6 the closed-place claim (D-SAFE2-4) has a hole.** Falsifier: a Strict
    program in which a carrier the body cannot see writes a closed place during
    a frozen or exclusive loan. The likeliest shape is a pointer to a local
    reached through a `bound` result stored somewhere the Store rule admits;
    the reviewers trace it (section 3 step 3).

Rejected alternatives:

-   **RG-1 restating the sentences as text** (fork/register/rg1-plan.md section
    6 R-4). Rejected there and here: each decision is named on two to five
    pages whose rules derive from it, so a one-sentence restatement leaves the
    dependent lines stating the narrowed rule (D-RG-7). Falsifier: D-RG-7's
    break condition, a reviewer showing one of the six realignable with no
    dependent line changing; sections 0.4 and 0.5 show none is.
-   **Keeping the Debug detection as the rule.** Rejected: p005434:663 plans
    to "prevent mutation of borrowed objects in Carbon's strict safe dialect",
    and a Debug report is detection, not prevention; the flag stays as the
    detector of unchecked code's mutations (D-SAFE2-7). Falsifier: an upstream
    text that accepts Debug detection as the strict dialect's enforcement.
-   **The eager copy for every type** (D-SAFE-17's recorded alternative).
    Rejected: a non-`Copy` type such as `Core.Buf` cannot be copied, a deep
    copy of an owning type is the cost values.md:447-454 says values exist to
    avoid, and an implicit copy is a second spelling of the type's own choice,
    `value_rep = const Self`, which the realigned rule honors. Falsifier: an
    upstream text that makes every value binding a copy.
-   **Withdrawing the benchmarking build instead of restoring it.** Rejected:
    safety/README.md:260-262 is upstream's promise and its withdrawal was the
    drift (R32); the audit property SAFE-1 cited holds for every supported
    build. Falsifier: W-351's break condition.
-   **A language-mandated zero-fill kept as the fork's own baseline,
    disclosed as a departure.** Rejected: the zero-fill for every type is
    p000257:356-358's, so a disclosure calling it the fork's states upstream's
    position wrongly. And its mirror, **type-defined initialization only, with
    no zeroing for a type that defines none** (the brief's reading of
    README.md:2130), is rejected because p000257:356-358 zeroes "all types";
    choosing it would create the drift W-353 was filed to remove. Falsifier:
    section 0.3's break condition.
-   **`Core.SharedImmutable` for non-`Plain` types only, withdrawing the
    `Core.String` and `Core.Slice` opt-ins** (review A's option 1 and its
    fallback; added 2026-10-28, review fold: A-B-1). Rejected: it makes every
    by-value call of a `Core.String` or `Core.Slice` method through a shared
    pointer `StrictBorrowFromShared`, EX-TM-1's `a->Size()` among them, which
    is the common read; M3's new paragraph instead rejects the rarer write, a
    `Plain` assignment to such a type through a shared path, and keeps the
    reads checked. Falsifier: a count (risk R-1's corpus) showing shared-path
    writes of strings or slices more common than shared-path reads.
-   **"Each bound parameter" of a pointer read as the copied pointer alone**
    (rev 1's D-SAFE2-9; added 2026-10-28, review fold: A-B-2). Rejected: the
    pointer is immutable by construction, so that reading makes p005434:831's
    rule vacuous for every pointer parameter and leaves the pointee "not
    invalidated", W-349's narrowing in other words; it also contradicts the
    reading for a `bound ref`, whose referent no path but the result reaches.
    Falsifier: an upstream text reading the sentence as the pointer value.
-   **A structural, compiler-derived `Core.SharedImmutable`.** Rejected for
    now: deriving it from a class's declarations needs three conditions and a
    body rule (every field private, no writing `addr` method, no
    function writing a field of the type through a shared path or returning a
    mutable pointer into it, no stored self-pointer), and a missed corner is a
    hole in a rule upstream plans to prevent; the opt-in puts the obligation
    where `unsafe impl` puts every other. Falsifier: a reviewed structural rule
    with a soundness argument, added later as a dated amendment.
-   **A by-value `Core.Buf(T).Set` for element types that hold no
    `Core.SharedImmutable` sub-object, beside an exclusive setter for the
    rest** (the round-2 re-review's second option for RR2-B1; added
    2026-10-28, review fold: RR2-B1). Rejected: no constraint names a type
    that holds no such sub-object, M3's property being structural and its
    complement no facet, so the split needs a new compiler-determined facet,
    a library name the register would carry and R32 (d) would weigh, and two
    setters for one operation. Weighed against the exclusive receiver's full
    cost (amended 2026-10-28, review fold: RR3-m1; rev 4 counted "only the
    writes made while a view of the block, or a binding formed through one, is
    live", which D-SAFE2-5's own cost list contradicts): a `Set` call is
    rejected without exclusive access to the `Buf`, under a live view of the
    block or a binding formed through one (EX-TM-3's), through a shared
    pointer, on a `Buf` bound by value, and in an `addr self` body such as
    EX-M-1's `IntVec.Set`. For an element type that holds no such sub-object,
    the only types the split would serve, every one of those writes keeps a
    path that needs no exclusive access: the `T*` that a view's `Data()`
    returns, element `i` through `AsSlice().Subslice(i, i + 1)`
    (slice.carbon:35-37 and :46-52 at 2407efa74), and once PR 65 lands
    `IndirectIndexWith.Ref` with its `bound self`, `b[i] = v` and `s[i] = v`;
    so the cost is a longer spelling until PR 65, not a lost operation, and
    the rejection stands. Falsifier: a constraint for "holds no
    `Core.SharedImmutable` sub-object" that upstream's generics or a reviewed
    fork design provides, or a Strict element write of such a type that
    neither the `Data()` path nor `Ref` can express; the by-value `Set` is
    then restored for such element types by a dated edit.
-   **Withdrawing `Core.String`'s opt-in for `Set`'s write** (the reading of
    rev 3's D-SAFE2-5 break condition the re-review flagged; added 2026-10-28,
    review fold: RR2-B1). Rejected, as the `Core.String` and `Core.Slice`
    opt-ins' withdrawal is above: EX-TM-1's `a->Size()` would become
    `StrictBorrowFromShared`, and the defect is the writer's, which the
    exclusive receiver fixes. Falsifier: the same count as that alternative's.
-   **Dynamic prevention in Release** (the shadow count checked on every shared
    write). Rejected: a per-write check on every program's hot path is outside
    p005914:110-111's under-1-percent budget; the Debug flag is the dynamic
    half. Falsifier: a measurement under budget on a real-world benchmark.
-   **No `ref` from a shared pointer at all.** Rejected: p005434:861-862 gives
    unsafe code the `noalias` obligation, which the `unsafe` formation spells,
    and Permissive must keep p005434:152-162 accepted (D-SAFE-8's break
    condition). Falsifier: an upstream text forbidding `ref` through a
    pointer.
-   **Exclusive formation on an open place by a may-alias analysis.**
    Rejected: a callee can reach the place through a global or a pointer field
    the body never sees, so no local analysis establishes `noalias` there.
    Falsifier: a sound modular analysis that does.

## §8 Verification

For each of commits 1 and 2, and every fold commit:

1.  R31 counts with `python3 -I
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5/bin/r31.py
    <file>` before the edit, after the edit and after each prek pass, for every
    touched markdown file. The baseline at 2407efa74 (headings by level,
    bullets, numbered items, table rows, lines): safety/README.md H1 1 H2 15 H3
    7, bullets 69, rows 43, 778 lines; mutation_safety.md H2 16 H3 15, bullets
    67, rows 55, 962; temporal_safety.md H2 19 H3 17, bullets 110, rows 47,
    1243; initialization_safety.md H2 11 H3 11, bullets 36, rows 14, 555;
    spatial_safety.md H2 12 H3 5, bullets 55, rows 22, 651; rust_interop.md H2
    16 H3 2, bullets 64, numbered 4, rows 51, 712; slices.md H1 1 H2 10 H3 4,
    bullets 55, rows 6, 462 (added 2026-10-28, review fold: RR1-M1); values.md
    H2 13 H3 16 H4 8, bullets 132, rows 11, 1570; README.md H2 18 H3 63 H4 28 H5
    5, bullets 341, numbered 3, rows 7, 4022; arithmetic.md H2 7 H3 4 H4 2,
    bullets 51, 332; fork/safe/plan.md H2 15 H3 28 H4 2, bullets 45, numbered
    28, rows 172, 2573; fork/decision-log.md H2 2 H3 45 H4 1 H5 6, bullets 54,
    rows 11. Expected deltas, every one a number (amended 2026-10-28, review
    fold: B-m5; rev 1 said "plus the checklist rows added"): safety/README.md
    rows plus 4 (A.1.3), bullets plus 1 (A.1.2); mutation_safety.md H3 plus 2
    (A.2.14), rows plus 5 (A.2.9 plus 3, A.2.17 plus 2), bullets plus 6 (A.2.8
    plus 1, A.2.9 plus 3, and the toc hook's two entries for the new H3s);
    temporal_safety.md H3 plus 1 (A.3.14), rows plus 2 (A.3.10 plus 1, A.3.13
    plus 1), bullets plus 3 (A.3.2 plus 1, A.3.10 plus 1, the toc entry for
    EX-TM-9); rust_interop.md rows plus 1 (A.6.2); fork/safe/plan.md H2 plus 1
    (B.3.8), rows plus 7 (B.3.2 plus 4, B.3.6 plus 3); initialization_safety.md,
    spatial_safety.md, values.md, README.md, arithmetic.md, slices.md and
    fork/decision-log.md 0 everywhere, numbered items 0 everywhere (the signs
    spelled "plus" on 2026-10-28 so that no wrapped line starts with one).
    A.1.1's appended sentence, A.3.12a's code and prose, A.6.3a's replaced row,
    A.10.2's blockquote and B.1.0's third block add no heading, item or row, so
    the deltas above stand (amended 2026-10-28, review fold: RR2-B1), nor do the
    sentences A.1.1, A.2.8, B.1.0 and B.1.7 gain for `IndirectIndexWith.Ref`,
    A.2.11's sentence on `IntVec.Set`'s body and A.2.17a's sentence appended to
    a bullet (amended 2026-10-28, review fold: RR3-M1, RR3-m1). Any other change
    is a defect to repair by rephrasing, recorded in the message. The
    document-review fold's commits 0f281d8bd and e1574b003 move none of these
    counts (amended 2026-10-28, document-review fold; section 8.7), nor does the
    focused re-review's round 2 fix commit cbdc0552e (amended 2026-10-29,
    re-review round 2; section 8.14).
2.  `cd /home/user/carbon-safe && XDG_CACHE_HOME=<private dir under the
    scratchpad's safe2/implementer/>
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <touched>` repeated to a fixpoint, the private cache
    deleted after; `git diff -U0 | grep -nE '^\+\s*#{1,6} [0-9]|^\+#[0-9]'`
    empty; the heading-line sets compared with `comm -13`, only the renamed and
    added headings new.
3.  `uvx rumdl@0.2.58 check <touched>` exits 0, as SAFE-1's §8 item 1 (e) used
    it, at the version .pre-commit-config.yaml pins (measured on this plan: the
    unpinned latest rumdl reports three MD013 lines that 0.2.58 and the prek
    hook accept, two of them an unbreakable path).
4.  The nightly compiles of section 0.7, re-run on the page text as committed
    (EX-M-4a, EX-M-4c, EX-M-4d, EX-TM-9 with their `Run` lines; the unchanged
    examples once), outcomes as section 0.7.
5.  PR 67's quote and silence checks at a freshly fetched tip, from a detached
    worktree of PR 67's head under /dev/shm/safe2-implementer/rg1, removed
    after; plus this plan's own quotes (section 0.1) re-read at that tip. And
    before each commit, every anchor and superseded text of the Appendix A or
    B blocks it applies is compared with its file at 2407efa74 under the test
    of section 2.1, link markup included, and found once (amended 2026-10-28,
    implementation: stop-and-amend: link markup in two superseded quotes),
    with section 2.1's set-asides and no other normalization, prose anchors
    as well as fenced texts: a checker that collapses every whitespace run or
    drops link markup does not run this test. Section 8.12 records the sweep
    of rev 7, under which every such quote passes (amended 2026-10-28,
    stop-and-amend re-review: AM6-M1).
6.  `python3 -I fork/conformance/runner.py --self-test` clean (R7).
7.  `git merge-tree --write-tree --name-only <head> <held head>` for trunk and
    every held head; the conflict set of each equals its row of section 0.8's
    table (amended 2026-10-28, review fold: B-m3).
8.  The id re-scan of section 0.9 repeated; no id taken.
9.  A case-insensitive grep for model names over the changed files and the
    messages, the pattern kept in the implementer's brief rather than in a
    file of the repository: nothing but the Co-Authored-By trailer.
10. `python3 -I -c "import json;
    json.load(open('fork/inventory/work-items.json'))"` after commit 2 and after
    the PR 67 note commit.
11. In the PR 67 note commit's worktree: `check_quotes.sh` over the amended
    rg1-quotes.tsv prints "checked 284 quotes, 0 failed" and `check_greps.sh`
    over the amended rg1-checks.tsv "checked 89 silence checks, 0 failed" at
    the freshly fetched tip (the fixer's measurement at 0421bf3b4; amended
    2026-10-28, review fold: B-M1, B-M2, A-M-2).

Not run, and why: no build of any kind (the toolchain, the prelude and the
goldens are untouched, and nothing may be built); no conformance run beyond
`--self-test` (no program changes; hosted runners are disabled, R28); no
upstream toolchain test (the NEW syntax parses nowhere); no Rust tool (D-SAFE-19
is analysis, D-SAFE-22); the planner made no scratch commit of the page edits,
so section 0.8's merge-trees are of PR 53's current head and the region analysis
stands for the edits until step 7 measures them.

### §8.7 Document-review fold record

Filled in by the fixer on 2026-10-28 (section 3 step 4). Both document reviews
read 954f1c542. Review 1, design fidelity and soundness: APPROVE-WITH-FIXES,
no BLOCKER, three MAJORs and three MINORs, one of them records-only. Review
2, readability, consistency, records and R31: APPROVE-WITH-FIXES, no BLOCKER,
no MAJOR, four MINORs, three of them records-only. All ten findings were
reproduced against the files, the plan and upstream's tip, re-fetched as
9192ee003 (section 0.1, where nothing the plan quotes has changed since
07718a832, and section 0.2, where PR 67's checks pass). All ten are folded
and none is rejected. The six page findings are folded by two fix commits,
0f281d8bd (R1-M1, R1-M2, R1-M3) and e1574b003 (R1-m1, R1-m2, R2-m2). The four
records-only findings are folded by this section's records commit. Each fold
carries "(amended 2026-10-28, document-review fold: <id>)" on the page and in
the log, fork/safe/plan.md section 0.3 and section 1, and this plan's section
1 and section 4 where it reaches them (R27). A fold's quote of a superseded
2026-10-12 sentence is byte-equal to 2407efa74 under section 2.1's test; its
quote of SAFE-2's own superseded words, after "where this read" or "this
read", is of the text at 954f1c542.

| Finding | Severity | Reproduced | Disposition and where it landed |
| --- | --- | --- | --- |
| R1-M1, an operator's `ref` operand | MAJOR | docs/design/assignment.md:76-82 and p005434:302-318 at 9192ee003 pass the operand to a `ref` parameter; with every `ref` binding exclusive and an unmarked one on an open place `StrictRefFromShared` (temporal `ref` bindings at 954f1c542), EX-M-4d's `q->n = 2` was rejected; a nightly probe of `q->n = 2; q->n += 1;` through a struct pointer compiles and prints 3 | ACCEPTED, 0f281d8bd: a paragraph of the temporal `ref` bindings section (a built-in operator's `ref` operand lives for the one operation and is established on any place, M3 deciding the operation; a user-written impl's `ref self` stays a `ref` binding, its call M3(d)'s), M3, the page's D-SAFE-9, D-SAFE-8 and D-SAFE-9 in the log and fork/safe/plan.md section 0.3, that plan's sections 1.5 and 1.6, D-SAFE2-6, and W-148's notes |
| R1-M2, a free result of a marked `unsafe fn` | MAJOR | the reviewer's program meets `Make`'s stated obligation and the owner's write sees no frozen loan on `x`, the view being free (T6); a nightly stand-in, a class whose by-value `Data` returns its stored `str*`, prints 6 | ACCEPTED, 0f281d8bd, the reviewer's first option: T6's marker also takes on that no path other than the result and its copies writes the storage a binding formed through it borrows; SP3's `Make` bullet, the spatial audit-line bullet, M8's soundness argument, D-SAFE-10's T6 and D-SAFE-17 in the log and section 0.3, D-SAFE2-5 and W-148's notes say so; type_safety.md, not edited (section 2.2), cites T6 for the result's loan set and the ⊥ rule rather than restating them (type_safety.md:144-146), but restates `Make`'s contract as its doc comment's sentence alone (:135-140), a line RR1-B1 hands to round 2's fixer (amended 2026-10-28, re-review round 1: RR1-m2, where this read "cites T6 for the rule rather than restating it (type_safety.md:145-147)") |
| R1-M3, `const` calls through shared pointers | MAJOR | mutation_safety.md:142-143, :206-210, :285-286 and :1239-1241, the log's D-SAFE-9 and fork/safe/plan.md :488 and :1543 at 954f1c542 permit `const` methods through `T*` and `const T*` unconditioned, where M4's third bullet and M8 make the binding of a borrowed object on an open place `StrictBorrowFromShared` | ACCEPTED, 0f281d8bd: a dated paragraph after the M1 table, a sentence of M3, M4's `addr self` bullet, the page's D-SAFE-9, D-SAFE-9 in the log and section 0.3, and section 1.6's M4; section 0.5 records the lines its grep missed |
| R1-m1, `UsePick`'s diagnostic | MINOR | T4's shared-loan clause excludes forming `z`'s exclusive loan on `y` while `q2`'s shared loan is live, so the error is `StrictSharedBorrowInvalidated` at the `let ref z` | ACCEPTED, e1574b003: the temporal `ref` bindings sentence, EX-TM-8's two comments and its bullet, D-SAFE-8 in the log and section 0.3, fork/safe/plan.md section 4.1's row, D-SAFE2-6, D-SAFE2-14 and section 4's row |
| R1-m2, the temporal page's kinds | MINOR | T5(a) gives frozen for `ValToRef`'s by-value `y`; the weakest-kind sentence named no frozen kind; the reborrow clause listed a by-value `bound self` as a shared formation; EX-TM-1 tied the frozen hold to `const` where T5(d) holds the pointee of every non-exclusive `bound` pointer argument frozen | ACCEPTED, e1574b003: the four temporal passages, the reborrow clause of D-SAFE-10 in the log and section 0.3, quoting its 2026-10-12 words, and section 4's EX-TM-1 row |
| R1-m3, placeholders and the re-read tip | MINOR, records-only | the log's RG-1 paragraph and fork/safe/plan.md's realigned notes read "pending"; no re-read at 9192ee003 was recorded | ACCEPTED, this records commit: the placeholders filled with R2-m1; the re-read paragraphs of sections 0.1 and 0.2 |
| R2-m1, `<sha2>` | MINOR, records-only | section 2.1 and section 3 step 4 named no step that fills `<sha2>` in commit 2's own texts | ACCEPTED, this records commit: dated marks in section 2.1, section 3 step 4, B.2.2 and B.3.8; 954f1c542 written in the log and in fork/safe/plan.md |
| R2-m2, superseded sentences quoted in full | MINOR | the passages at 2407efa74 mutation_safety.md:654, :680-681 and :234-244 and temporal_safety.md:191-195 and :203-207 were cut or unquoted | ACCEPTED, e1574b003: each quoted in full, byte-equal to 2407efa74 under section 2.1's test (eleven quotes, eleven found once); Appendix A keeps commit 1's blocks, with the dated pointers decided below |
| R2-m3, PR 67 acts stated as made | MINOR, records-only | at 56e2e5bbd, rg1-checks.tsv's H1.7 regex has no `SharedImmutable` and rg1-plan.md's H1.13 reads DRIFT, so the log's two sentences, and fork/safe/plan.md's "their notes there read", state section 3 step 6's acts as done | ACCEPTED, this records commit: the three sentences name SAFE-2's PR 67 note commit as the act; B.2.1, B.2.2 and B.3.8 carry the same words |
| R2-m4, one `<date>` for two dates | MINOR, records-only | section 2.1 dated C.1, C.3 and D by the stamp and C.2 by the note commit, while their texts date the realignment | ACCEPTED, this records commit: `<rdate>`, commit 1's date, defined in section 2.1 and used in C.1, C.2's six notes and Item cell, and D's safe row and W-353 texts; `<date>` kept for "Last updated", the paragraph dates and the note commit |

Decisions under R29, each with its break condition:

-   The six page findings are held by two fix commits, and the third fix
    commit of the budget is left for the focused re-review. Break condition:
    a re-review finding that two commits' grouping hides, which is then split
    by its own commit.
-   Appendix A and Appendix B stay commit 1's and commit 2's texts, as their
    headings say. The nine blocks a fold changed on its target, A.2.6, A.2.8,
    A.3.4, A.3.12, A.3.13, B.1.1, B.1.2, B.1.7 and B.3.6, carry a dated
    pointer to this section. The fold texts are the fix commits' diffs, and
    this plan's sections 1 and 4 match them (R27). B.2.1, B.2.2 and B.3.8,
    whose words this records commit changes, are amended in place. Break
    condition: a re-reviewer needs the fold texts verbatim in this plan; they
    are then copied from the fix commits into a dated subsection. (Amended
    2026-10-29, re-review round 2: the pointer covers too the fifteen blocks
    whose targets the round 2 fix commit cbdc0552e changes, listed by the
    decisions of section 8.14.)
-   R1-M1's "built in" means the language's own operation or a prelude impl
    whose body is a builtin (core/prelude/types/int.carbon:331's
    `"int.sadd_assign"`). Break condition: upstream specifies the borrow
    semantics of an operator's operand otherwise; the rule then follows it.
    (Amended 2026-10-28, re-review round 1: RR1-m1: the test leaves out the
    prelude's integer `Inc` and `Dec` impls, whose bodies are not builtins,
    and round 2's fixer restates it; section 8.13.) (Amended 2026-10-29,
    re-review round 2: RR1-m1: restated by cbdc0552e as the semantics
    docs/design/assignment.md:146-157 gives the built-in types, the
    prelude's impls of them whatever their body, an aggregate's assignment
    with no user-written `AssignWith` impl, and the language's own `&`,
    member access and array indexing, the operand forming no loan of its
    own; section 8.14, whose decision carries the break condition.)
    (Amended 2026-10-29, rev 8: RR2-M1, RR2-m1: re-planned by where an
    implementation is written, the language's own or an impl of an operator
    interface written in core/prelude; section 8.16.)
-   R1-M2 takes the reviewer's first option, the marker's obligation, so that
    `unsafe Core.Slice(T).Make(p, n)` stays the single audit line and no
    `v[i]` through the view needs a marker. Break condition: a counterexample
    in which a binding formed through a free result is invalidated with the
    extended obligation met; the second option, `unsafe` at such a binding,
    then replaces it. (Amended 2026-10-28, re-review round 1: RR1-B1: the
    break condition fired, the obligation lasting while the binding lives and
    not while the frozen loan formed through the result does, and round 2's
    fixer re-runs this decision; section 8.13.) (Amended 2026-10-29,
    re-review round 2: RR1-B1: re-run by cbdc0552e, the obligation kept and
    keyed to the frozen loan formed through the result or a carrier derived
    from it for as long as that loan is live; section 8.14, whose decision
    carries the break condition.)
-   No new item and no F id: W-148's notes gain the checker's share of R1-M1
    and R1-M2, and the id re-scan is unchanged, with W-365 the next free id.

Measured after each commit. R31 headings, bullets, numbered items and table
rows are unchanged on every page and record that 0f281d8bd and e1574b003
touch, so section 8 item 1's expected deltas stand. This records commit adds
to this plan this section's twelve table rows and thirteen bullets, five
decisions and eight checks, and changes no other count of this plan, the log,
fork/safe/plan.md or the ledger. Other checks, with the logs under the
scratchpad's safe2-impl/fixer/:

-   prek to a fixpoint in two passes, the first a rumdl reflow only and the
    word diff empty.
-   rumdl@0.2.58: no issues. The heading sets are unchanged.
-   Links over the ten pages: 1355, then 1358, then 1359, all resolving.
-   The nightly outcomes of section 0.7: unchanged.
-   runner.py --self-test: OK.
-   The log's D-SAFE block is identical to fork/safe/plan.md section 0.3.
-   The merge-tree sets against trunk and the 18 held heads: section 0.8's.
-   PR 67's checks at 9192ee003: 273 of 273 quotes and 89 of 89 silence
    checks; the H1 subsets 97, 120 and 5.

Placeholders left for later steps: every placeholder Appendices C and D still
carry, with the step that fills it and its known value, is listed in the
table of section 8.13 (amended 2026-10-28, re-review round 1: RR1-m2, where
this read "`<head>`, `<c2-sha>`, `<time>`, `<tip>`, `<rdate>` and `<date>` in
Appendices C and D, which the later steps of section 3 fill (steps 6 to 8);
no text uses `<n>`", a list that left out `<sha1>`, `<sha2>`, `<fixes>`,
`<verdict 1>`, `<verdict 2>`, `<landing date>` and `<merge commit>`).

### §8.8 Review fold record (rev 2, 2026-10-28)

Plan reviews A (design fidelity and soundness: REJECT, two BLOCKERs) and B
(records, consistency and R31: APPROVE-WITH-AMENDMENTS) of rev 1 (475b7ecb0)
filed 21 findings; review A's eight are written here with the prefix "A-". Every
one was reproduced at the cited lines (PR 53 at 2407efa74, upstream at
0421bf3b4, PR 67 at 56e2e5bbd, trunk at 1c83422a0) before it was folded, and
every measurement a finding is about, a grep, a quote, a count, a merge-tree or
a nightly compile, was re-run in the fixer's scratch,
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/fixer/.
All 21 are accepted and none is rejected. Where a finding offered options, the
row names the one taken, and section 7 keeps the other as a rejected alternative
with its falsifier. No id was taken: W-365 stays the next free work item, and no
F id (section 0.9). Each fold is marked in this plan's own text as "(amended
2026-10-28, review fold: A-B-1)" is; the page and records texts of Appendices A
and B carry only their SAFE-2 marks, since a plan review's id means nothing on a
page, and every changed replacement text changed together with its entry in
section 2, its row in section 4 and its appendix copy.

| finding | severity | disposition | where |
| --- | --- | --- | --- |
| A-B-1 the `Core.String` and `Core.Slice` opt-ins are false: M3(c)'s whole-object `Plain` write through `T*` breaks the frozen loan and T8's `noalias` | BLOCKER | folded by the fix's option 2: reproduced (mutation_safety.md:166-177, :309-310 and :323-326 at 2407efa74; review A's `Peek2(&x, &x)` re-run on the nightly prints `6`); `Core.SharedImmutable` gains a language half, a new M3 paragraph under which every write of such a type's storage needs exclusive access (`StrictSharedImmutableWrite` otherwise), with M4's `addr self` clause, the `Core.Plain` sentence and D-SAFE-9's exception, beside the author's half; the Debug flag counts whole-object `Plain` writes through `T*`; R-2 covers language-level writes; option 1, withdrawing the opt-ins, rejected in section 7 for its cost (EX-TM-1's `a->Size()` would become `StrictBorrowFromShared`) | §0.6, §0.7, D-SAFE2-5, D-SAFE2-7, D-SAFE2-8, D-SAFE2-14, §4 EX-M-4d, §7, A.1.3, A.1.5, A.2.4a, A.2.5, A.2.7a, A.2.8, A.2.9, A.2.14, A.2.18, A.2.19, A.3.8, A.3.10, B.1.2a, B.1.7, B.2.2, B.3.2, B.3.5, B.4 |
| A-B-2 W-349 kept in other words for `bound` pointer arguments | BLOCKER | folded as the fix asks: reproduced (decision-log.md:3315-3322 at 2407efa74; rev 1's T5(d) and A.3.12's "not invalidated"); the pointee of a `bound` `T*`, `const T*` or `exclusive T*` argument is held by the result, enforced by T4 on a closed place and formed on an open place only for a `Core.SharedImmutable` pointee, `StrictBorrowFromShared` or `unsafe` at the call otherwise; EX-TM-1, EX-TM-8's `UsePick` and `Load`, `Valid1` and `Conditional` re-traced; the cost recorded; rev 1's reading rejected in section 7 | §0.6, D-SAFE2-9, §4 rows, §7, A.2.9, A.3.4, A.3.9, A.3.12, A.3.13, B.1.1, B.1.3, B.2.2, B.4 |
| A-M-1 T8 emits `noalias` on a local `ref` of a `ref`-parameter referent without the whole-package condition | MAJOR | folded as the fix asks: reproduced on rev 1's T8 and closed-place list (a Permissive `G(ref x, &x)` is warned and accepted); the attribute on a local `ref` of a `ref`-parameter referent or an `exclusive T*` pointee is emitted only under the parameter attributes' whole-package condition, never on an open place or for `unsafe` or Permissive code; the checks are unchanged | §0.6, D-SAFE2-6, A.3.8, A.3.16, B.1.1, B.4 |
| A-M-2 upstream's value representation misstated | MAJOR | folded as the fix asks: re-read at type_completion.cpp 0421bf3b4 (a copy: :697-751, the one-element struct or tuple :572-578, the adapter :762-770, `const` :783-789, `MaybeUnformed` :803-826; the object: the class :771-781, the array :674-695, `ValueAndObjectAggregate` :568-570, :597-609, :620-627; an elementwise aggregate: `ValueAggregate` :580-582) and optional.carbon:30-46 at 2407efa74; the three branches stated; `Core.Optional(T*)` is copy-represented and holds no loan; EX-M-4c's struct is a `ValueAggregate`, and a fixer's `ValueAndObjectAggregate` probe prints the same `1`; `Launder` and `Optional(T*)` re-traced; eight quote rows of the file join rg1-quotes.tsv; R-5's TODO is :776 | §0.1, §0.7, §0.10, D-SAFE2-3, §4 rows, §6, §7 R-5, §8 item 11, A.2.8, A.2.14, B.1.7, B.3.6, C.2 |
| A-m-1 a `bound ref` with a `val` return keeps an exclusive loan | MINOR | folded as the fix asks: p005434:825's `RefToVal` re-read; exclusive under a `ref` return, frozen under a `val` or by-value result, and T5(a)'s kind map says so | §0.6, D-SAFE2-9, A.3.9, B.1.3 |
| A-m-2 "implies `Core.Freeze`" false for the unconditional opt-ins; no `Core.Box` in the prelude | MINOR | folded as the fix asks: reproduced (mutation_safety.md:253-255; core/prelude/types/ at 2407efa74 has no box.carbon); `Core.String` opts in unconditionally, `Core.Slice`, `Core.Buf` and `Core.Optional` under `forall [T: Core.Freeze]`, `Core.Box` once W-144 adds it | D-SAFE2-5, A.2.8, A.2.19, B.1.7, B.4 |
| A-m-3 W-353's records gaps | MINOR | folded with B-M1: the p000257 quote rows, H1.13 amended ALIGNED, :356-358 everywhere but the quotes of old texts and I5's filing cite, and the closure recorded as a classification corrected, not a break condition that fired | Status, Items, §0.3, §0.10, D-SAFE2-12, A.4.1, A.4.2, B.1.4, B.2.2, C.2, C.3, D |
| A-m-4 cite and record nits | MINOR | folded as the fix asks: section 0.8's step is 6; the storage reading of values.md:461-462 is marked R-3's own; D-RG-20 is cited at fork/register/rg1-plan.md | §0.8, D-SAFE2-3, A.4.2, A.5.5, B.1.7 |
| B-M1 W-353 closed with RG-1's register left at DRIFT and the basis unwatched | MAJOR | folded as the fix asks: reproduced (rg1-plan.md §2.H1's H1.13 DRIFT; rg1-quotes.tsv quotes p000257:274 only; initialization_safety.md:223-226 cited :355-358 at filing); the PR 67 note commit amends H1.13 ALIGNED quoting p000257:356-360 (18 DRIFT, 33 ALIGNED, 104 NONE), adds p000257:356, :357 and :359 as quote rows (273 to 284 with A-M-2's eight; "checked 284 quotes, 0 failed" at 0421bf3b4), words the W-353 note as a corrected classification naming I5's filing cite, and cites :356-358 | Status, §0.3, §0.10, D-SAFE2-12, §6, §8 item 11, B.2.2, C.2, C.3, D |
| B-M2 `Core.SharedImmutable` has no row in PR 67's register | MAJOR | folded by the fix's second option: entry H1.7's name list and silence check widened to `Core.SharedImmutable` (its count stays 1 at 0421bf3b4, measured, so 89 checks and 155 entries stay), no check H1.7b; W-355's counts noted | §0.10, D-SAFE2-15, §6, §8 item 11, B.2.1, C.2, C.3 |
| B-M3 Appendix D's texts incomplete | MAJOR | folded as the fix asks: six verbatim edits, the "Last updated" entry, the safe and rg1 rows, a dated paragraph with the full merge order, both remaining waits (PR 60 for W-139, PR 56 for W-352), eighteen held and none merged and a Next line, item 6's W-353 text, and the land-time discharge of W-347 to W-351 and W-353 | Appendix D |
| B-M4 S0 scoped on the page but not in D-SAFE-2 or the plan's section 1.1 | MAJOR | folded as the fix asks: decision-log.md:2952-2967 = plan.md:237-252 and plan.md:1110 re-read; B.1.0 scopes D-SAFE-2's S0 to the supported build modes and re-derives its break condition, and B.3.2 gives section 1.1 the matching sentence | D-SAFE2-13, §2.3, B.1.0, B.3.2 |
| B-M5 the plan's own texts break D-SAFE2-2 | MAJOR | folded as the fix asks: each superseded passage re-diffed against its lines at 2407efa74 and quoted whole; every rewritten clause marked with its W id; no 2026-10-12 mark left on new text; A.1.6's and A.8.1's labels dated `<date>` | D-SAFE2-2, A.1.6, A.2.8, A.2.9, A.2.17, A.8.1, B.1.1, B.1.3, B.1.7, B.2.1 |
| B-M6 PR 53's ledger lines still state the narrowed rules | MAJOR | folded as the fix asks: section 0.5's grep widened to fork/inventory/work-items.json (W-063, W-144 to W-150) and fork/gap-analysis.md, every hit listed; B.4's notes on W-146 and W-148 quote and supersede each line; the gap analysis has no hit | §0.5, D-SAFE2-15, §2.3, B.4 |
| B-m1 no pusher and no file for the filled texts | MINOR | folded: the implementer pushes at steps 6 and 7; the orchestrator posts from pr_53_refresh.md, pr_67_refresh.md and orchestration_stamp.md under the scratchpad's safe2/impl/ | §3 steps 6 to 8, C.3 |
| B-m2 placeholders undefined; the notes cite the pages commit | MINOR | folded: section 2.1 defines every placeholder and whose date each `<date>` is; the notes cite the dry head `<head>` | §0.10, §2.1, B.3.8, C.2, C.3, D |
| B-m3 a stale step number and no merge-tree target | MINOR | folded: step 6; the eighteen sets re-measured on 2026-10-28 and tabulated as the review lists them; section 8 item 7 compares against the table | §0.8, §8 item 7 |
| B-m4 section 4.1's rows and the page checklist diverge | MINOR | folded: one text for each row on both | A.2.17, B.3.6 |
| B-m5 an anchor misquoted and a delta that is not a number | MINOR | folded: B.1.2's anchor quoted as log:3209 has it, no "and" before `vec->Push(3)`; section 8 item 1 gives every delta as a number | §6, §8 item 1, B.1.2 |
| B-m6 the Debug report kept on the invalidating rows | MINOR | folded: the Debug cells of safety/README.md:322, temporal_safety.md:628 and section 1.1's row re-worded and dated: ASan-class detection when the invalidation frees what a loan reads, the value-binding report being `StrictBorrowedObjectMutated`'s | §0.6, §2.3, A.1.3, A.2.9, A.3.10, B.3.2 |
| B-m7 unnamed upstream commits and a narrow id re-scan | MINOR | folded: the seven type_completion.cpp commits since the cut named, none touching the value-representation code; the re-scan run on every origin ref | §0.1, §0.9 |

Disk: the fixer's probes (`Peek2`, EX-M-4c's struct variants) were compiled
with the 2026-10-12 nightly into the scratch directory above; nothing was
built, and no worktree or install is kept.

### §8.9 Review fold record (rev 3, 2026-10-28)

The focused re-review (round 1) of rev 2 (46980f8bd) returned REJECT on one
BLOCKER, RR1-B1, with one MAJOR, RR1-M1, and four MINORs, RR1-m1 to RR1-m4.
Its trace of rev 2's 21 folds found A-B-1 not resolved (RR1-B1), A-B-2
resolved in text but inheriting RR1-B1's hole on open places and introducing
RR1-M1, A-M-1, A-M-2 and B-M1 to B-M6 resolved (B-M5 but for RR1-m2's slips),
and the minors folded with the residues RR1-m1 to RR1-m4. It re-fetched
upstream at 6d5142779 (upstream PR 8051, tests only; `git diff 0421bf3b4
6d5142779` changes no quoted file), ran PR 67's checks there from a detached
56e2e5bbd worktree (273 quotes and 89 silence checks pass, 284 quotes with
Appendix C.2's eleven rows, 89 checks with H1.7 widened), matched all 18
heads by `git ls-remote`, reproduced section 0.8's merge-tree table, found
W-365 still the next free id, rumdl clean and the R31 counts as rev 2's fixer
reported (H3 117, bullets 74, numbered 31, rows 115), and found the log's and
fork/safe/plan.md's D-SAFE ranges byte-identical.

Every finding was reproduced by the rev 3 fixer before it was folded, in
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/fixer1/:
`Peek4(&y, &y)` and the class variant `Peek5(&w, &w)` compiled, linked and run
on the 2026.10.12 nightly print `6` and `6` (ex/peek4.carbon);
mutation_safety.md:304-305 at 2407efa74 (the re-review cites :306) reads "The
facet is closed under arrays, tuples, structs and classes whose every field is
`Plain`", so the struct of `Peek4` is `Plain` and rev 2's M3 paragraph, keyed on
the assigned type being `Core.SharedImmutable`, admitted its write;
slices.md:52-63 at 2407efa74 present `a[2] = 30` under the live `s` as the
design's behavior, and SP3 gives `FromArray` its `bound p`; PR 51's slices.md
hunk is at :386 and PR 65's run from :114 to :437 (`git diff -U0 1c83422a0
<head>`), and a three-way `git merge-file` of PR 53's slices.md with A.10.1's
note against each head's copy is clean; rev 2's vocabulary (A.3.2) defined a
frozen loan only for a borrowed object or a `const` `ref` and D-SAFE2-9 applied
"the shared kind the map gives" to the pointee, while A.3.6 and A.3.12 relied on
a frozen loan the result holds; A.9.1 and A.5.9 rewrote the sentences RR1-m2
names without quoting them, and B.3.5's M8 clause kept "A-8/B3" and "RR-5"; the
H1.13 row of PR 67's rg1-plan.md at 56e2e5bbd keeps the DRIFT break condition
and no W-355, which D-RG-17 attaches to every ALIGNED entry outside VA-2's
block; and D-SAFE2-5's and D-SAFE2-6's cost sentences named no global. Upstream
was re-fetched for rev 3 at 22f3cd353, two commits past 0421bf3b4 and touching
no quoted file, where PR 67's checks pass with and without the C.2 rows
(sections 0.1 and 0.2). All six findings are accepted and none is rejected. No
id was taken: W-365 stays the next free work item, and no F id. The marks read
"(amended 2026-10-28, review fold: RR1-B1)" and the like; as in section 8.8, the
page and records texts of Appendices A and B carry only their SAFE-2 marks.

| finding | severity | disposition | where |
| --- | --- | --- | --- |
| RR1-B1 a write to an enclosing `Plain` aggregate still mutates a borrowed `Core.SharedImmutable` object through `T*` | BLOCKER | folded as the fix asks: a structural property beside `Core.Plain`'s, a type _holds a `Core.SharedImmutable` sub-object_ when it is one or is an array, tuple, struct or class with an element, field or base that holds one, or an adapter of one; M3's paragraph and M4's `addr self` clause cover every assignment whose type holds one, `*self` included, with `StrictSharedImmutableWrite`, whose text now names the sub-object written; the rule restated in the same words in D-SAFE2-5, A.1.5, A.2.4a, A.2.5, A.2.7a, A.2.8, A.2.19, A.3.3, B.1.2a, B.1.7, B.3.4, B.3.5 and B.4; the Debug flag counts per byte and tests the written range; `Peek4` added to EX-M-4d, section 0.7 (with the class probe), section 4, A.2.2, A.2.10, A.2.17 and B.3.6, and R-2 names the shape; decided under R29, a union stays outside the closure because a Strict read of its field already needs `unsafe`, whose obligation the binding takes on (break condition in D-SAFE2-5: the unions design makes the read safe); and A.2.4a's first block now points at "the next paragraph", which rev 2 called "the next paragraph but one" | §0.6, §0.7, D-SAFE2-5, D-SAFE2-7, D-SAFE2-8, D-SAFE2-14, D-SAFE2-15, §4, §7 R-2, A.1.5, A.2.2, A.2.4a, A.2.5, A.2.7a, A.2.8, A.2.9, A.2.10, A.2.14, A.2.17, A.2.19, A.3.3, B.1.2a, B.1.7, B.3.4, B.3.5, B.3.6, B.4 |
| RR1-M1 the A-B-2 fold makes slices.md's opening example Strict-rejected, untraced | MAJOR | folded as the fix asks, the note placed after SP3's amendment (slices.md:70), which states the loan the note relies on, rather than between the example and that amendment: A.10.1 says that in Strict `a[2] = 30` under the live `s` is `StrictBorrowedObjectMutated`, that the write goes after `s`'s last use or through the view once slices are writable, and that Permissive warns; section 0.5 lists slices.md:53 and :61, section 4 has the row, D-SAFE2-9's cost and A.3.9 name the array view; slices.md joins section 2.2, commit 1's title, section 6, section 8 item 1 (baseline H1 1 H2 10 H3 4, bullets 55, rows 6, 462 lines; delta 0) and hand-off note 5; section 0.8 records the hunks and the clean merge-file | §0.5, §0.6, §0.8, D-SAFE2-9, D-SAFE2-14, §2.2, §3 step 1, §4, §6, §8 item 1, hand-off note 5, A.3.9, A.10.1 |
| RR1-m1 T5(d)'s hold has no defined loan kind | MINOR | folded as the fix asks: the pointee of a `bound` `T*` or `const T*` argument carries a frozen loan the result holds, that of an `exclusive T*` an exclusive one, the result's own access at the kind T5(a)'s map gives its parameter; stated in the vocabulary, T5(d) and D-SAFE2-9, and in the log's D-SAFE-10 vocabulary and D-SAFE-11(d) | §0.6, D-SAFE2-9, A.3.2, A.3.9, B.1.2, B.1.3, B.4 |
| RR1-m2 residual breaks of the superseded-text convention | MINOR | folded as the fix asks: A.9.1 quotes the whole superseded blockquote, A.5.9 SP4's whole sentence and the old break condition, and B.3.5's M8 clause drops "A-8/B3" and "RR-5" into its full quote; the same sweep of Appendices A and B found four more and folded them: A.2.12's EX-M-4a comment ("A-8, B3"), A.6.3's `At` line ("A-9"), B.1.2's second block ("RR-5") and B.1.5's break condition, rewritten without a quote | A.2.12, A.5.9, A.6.3, A.9.1, B.1.2, B.1.5, B.3.5 |
| RR1-m3 the H1.13 re-classification leaves the DRIFT break condition and no W-355 | MINOR | folded as the fix asks: C.2 (iv) replaces the row's break-condition cell with a ninth block, the ALIGNED re-open condition of the seventh block and section 0.3 with the superseded DRIFT condition quoted, and appends W-355 to the Item cell | C.2 |
| RR1-m4 the cost of open-place globals is not stated | MINOR | folded as the fix asks: D-SAFE2-6's cost names a `ref` binding or `ref` argument on a global, D-SAFE2-5's an assignment to a global that holds a `Core.String` or `Core.Slice`, the page's cost list in A.2.8 names the global too, and the vocabulary (A.3.2) and the `ref` bindings section (A.3.4) name a global as an open place | D-SAFE2-5, D-SAFE2-6, A.2.8, A.3.2, A.3.4 |

Disk: the rev 3 fixer's probe and merge-file inputs are in the scratch
directory above; the detached worktree under /dev/shm/safe2-fixer1 was removed
after the checks; nothing was built.

### §8.10 Review fold record (rev 4, 2026-10-28)

The focused re-review (round 2) of rev 3 (603749ee1) returned REJECT on one
BLOCKER, RR2-B1, with three MINORs, RR2-m1 to RR2-m3. Its trace found rev 3's
six folds resolved (RR1-B1, RR1-M1, RR1-m1 to RR1-m4; the A.9.1 and A.5.9
quotes byte-equal to 2407efa74) and accepted both of the rev 3 fixer's
judgement calls. It fetched upstream at 07718a832, newer than 22f3cd353
(`git diff 0421bf3b4 07718a832` touches nothing under proposals/, docs/design/,
core/prelude or type_completion.cpp, and f21c62524 is the only commit on the
quoted files since the cut), ran PR 67's checks from a detached 56e2e5bbd
worktree (273 quotes, 0 failed; 89 silence checks, 0 failed; the 51 H1 quote
rows, 0 failed; 284 quotes with Appendix C.2's eleven rows; 89 checks with
H1.7 widened; C.2's ninth block's superseded DRIFT condition word for word
rg1-plan.md:887), matched all 18 heads and trunk 1c83422a0 by `git ls-remote`,
found W-365 the next free id, rumdl@0.2.58 clean, the R31 counts headings
{1: 1, 2: 15, 3: 119}, bullets 74, numbered 31, rows 127 with no unguarded
block, the 2407efa74 baselines equal to section 8 item 1, the runner's
`--self-test` exit 0, A.10.1's three-way merge-file clean against PR 51
(f96fe8a7a) and PR 65 (fee0ef31c), and EX-M-4d's nightly outputs 1, 6 and 6.

Every finding was reproduced by the rev 4 fixer before it was folded, in
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/fixer2/:
buf.carbon:48-53 and slice.carbon:37 at 2407efa74 read as the finding cites (a
by-value `Set` storing `*PointerOffset(self.ptr, i) = value`, and `Data`
returning `T*`), and the spatial page's SP3 list (spatial_safety.md:171-178)
gives `Data` and `AsSlice` `bound self`; a stand-in of `Peek8`'s shape, a class
with a `str*` field and by-value `Data` and `Set` (ex/peek8.carbon), compiled,
linked and run on the 2026.10.12 nightly prints `6`; `Core.Buf(str)` is
well-formed, `str` meeting `Copy & Destroy` on the same nightly (ex/cd.carbon);
a scan of the prelude at 2407efa74 finds buf.carbon:39 (`Make`'s fresh block)
and :52 (`Set`) the only stores through a pointer, and PR 65's
`IndirectIndexWith` impls at fee0ef31c a by-value `Ref` that returns `ref T` and
stores nothing; RR2-m1's global and `ref` shapes compiled and run print `6` and
`6` (ex/global.carbon, ex/refalias.carbon; the nightly requires the call spelled
`F(ref x, &x)`); fork/safe/plan.md's §2 at 2407efa74 has the lines RR2-m2 names,
:1641, :1643, :1694, :1772, :1786 and :1789-1792, and a grep of §2 finds
:1391-1392, :1518, :1530, :1533, :1559, :1679, :1697, :1701, :1704, :1743 and
:1793-1795 too; and the sentences RR2-m3 names state `Core.Slice(T)` for every
`T` against D-SAFE2-5's `forall [T: Core.Freeze]`. Upstream was re-fetched for
rev 4 at 07718a832, where PR 67's checks pass with and without the C.2 rows (the
last paragraph of section 0.1, and section 0.2); all 18 heads and trunk
1c83422a0 match `git ls-remote`; the id re-scan over the 165 origin refs and
local branches and every worktree finds W-360 to W-364, W-398 and W-399 as
before and W-365 only in this file; the three-way merge-file of slices.md with
A.10.1 and A.10.2 applied is clean against PR 51, PR 65 and trunk (section 0.8);
and `runner.py --self-test` exits 0. All four findings are accepted and none is
rejected. No id was taken: W-365 stays the next free work item, and no F id. The
marks read "(amended 2026-10-28, review fold: RR2-B1)" and the like; as in
sections 8.8 and 8.9, the page and records texts of Appendices A and B carry
only their SAFE-2 marks.

| finding | severity | disposition | where |
| --- | --- | --- | --- |
| RR2-B1 `Core.Buf(T).Set`, a trusted by-value writer, mutates a borrowed `Core.String` element in Strict | BLOCKER | folded as the fix asks, the writer fixed and not the opt-in: a trusted body keeps M3's write rule, writing an object whose type holds a `Core.SharedImmutable` sub-object only through an exclusive path or through a pointer into storage owned by an object it holds exclusively, every other path the type hands out being `bound` to that object, stated in the same words in D-SAFE2-5, A.1.1 (the soundness model's prelude paragraph), A.2.4a, A.2.8, B.1.0 (D-SAFE-2's prelude clause, which R27 aligns with the page), B.1.7 and B.4's W-144 note; decided under R29, `Set` takes `ref self` for every `T` (W-144), the re-review's first option, its cost recorded (EX-TM-3's `buf.Set(1, 7)` under the live `v` is `StrictSharedBorrowInvalidated` and moves before `v`; a callee given a `Buf` by value or through a shared pointer cannot `Set` it; an `i32` element stays writable through the `T*` of `Data()`, element `i` through `AsSlice().Subslice(i, i + 1)` and, once PR 65 lands, through `IndirectIndexWith.Ref`, amended 2026-10-28, review fold: RR3-m1), and the second option, a by-value `Set` for element types that hold none beside an exclusive setter, rejected in section 7 because no constraint names such a type; EX-TM-3 rewritten (A.3.12a); slices.md given a dated amendment after the `Buf` bullets rather than in the `Set` bullet PR 65 rewrites (A.10.2); the reason of the Rust `Core.Slice(const T)` row and of D-SAFE-19's proviso re-worded (A.6.3a, B.1.8 (v)), with D-SAFE2-3's storage sentence and D-SAFE2-10's and A.6.3's `At` reasons; `Peek8` added to EX-M-4d, section 0.7 (the stand-in), section 4 and both checklists; R-2's falsifier and D-SAFE2-5's break condition widened to any prelude function that writes such storage through a shared path, elements included, answered by fixing the function; R-3 records that EX-TM-3's consequence is now the design's | Status, §0.1, §0.2, §0.5, §0.6, §0.7, §0.8, D-SAFE2-3, D-SAFE2-5, D-SAFE2-10, D-SAFE2-14, D-SAFE2-15, §2.2, §2.3, §3 step 1, §4, §6, §7, §8 item 1, hand-off note 5, A.1.1, A.2.4a, A.2.8, A.2.10, A.2.14, A.2.17, A.2.19, A.3.12a, A.6.3, A.6.3a, A.10.2, B.1.0, B.1.7, B.1.8, B.3.6, B.4 |
| RR2-m1 the Debug flag fires only on writes through `T*`; A.2.9's "never a Strict body's write" is false | MINOR | folded as the fix asks: Debug tests every store that writes a byte whose frozen count is non-zero, of any type and by any path, `T*`, a `ref`, the owner, a global by name or an `addr self` body; A.2.9's item states the exception, a Strict body's write that a Permissive caller made aliasing, which that call's `PermissiveAliasedExclusive` flags; the global and `ref` shapes reproduced on the nightly (section 0.7) | §0.6, §0.7, D-SAFE2-7, D-SAFE2-15, A.2.8, A.2.9, B.1.7, B.4 |
| RR2-m2 fork/safe/plan.md section 2 still states the six superseded rules without a mark | MINOR | folded as the fix asks: B.3.1's pointer paragraph makes §2, the 2026-10-12 deliverable spec, history, superseded by Appendix A where it states the six rules or the by-value `Set`, and names its lines at 2407efa74, the finding's six and the nine more a grep of §2 finds; section 0.5 lists them as "no change, history (B.3.1)"; B.3.1's list of realigned decisions also gains D-SAFE-2 and D-SAFE-9, which B.1.0 and B.1.2a edit | §0.5, B.3.1 |
| RR2-m3 `Core.Slice(T)` stated to hold and opt in for every `T` | MINOR | folded as the fix asks: "`Core.Slice(T)` for a `Core.Freeze` `T`" in D-SAFE2-5's cost, A.1.5, both sentences of A.2.4a, A.2.5, A.2.7a, A.2.8's cost list and A.3.3, and "`Slice(T)` for a `Freeze` `T`" in B.3.5's M4 text; B.3.4's paragraph names neither type, so the finding's B.3.4 cite is folded in B.3.5, the §1.6 sentence that names `Slice` | D-SAFE2-5, A.1.5, A.2.4a, A.2.5, A.2.7a, A.2.8, A.3.3, B.3.5 |

Disk: the rev 4 fixer's probes (ex/), merge-file inputs (mf/), the copy of
fork/safe/plan.md at 2407efa74 and the check subsets are in the scratch
directory above; the detached worktree under /dev/shm/safe2-fixer2 was removed
after the checks; nothing was built.

The rev 4 fixer rewrote nine cells of six rows of sections 2.2 and 2.3 (the
"What changes" cells of the safety/README.md, mutation_safety.md,
temporal_safety.md, rust_interop.md and slices.md rows and of the
fork/decision-log.md row, and the "Blocks" cells of the temporal_safety.md,
rust_interop.md and slices.md rows; the round-3 re-review counts seven) by a
python3 string replace rather than by Edit, a deviation from R25 and hand-off
note 2 that the rev 4 record and commit message left out. The rewrite is the
text rev 4 committed: prek's fourth pass left the file unchanged, the
fixpoint, and 9d48a863e's file is byte-equal to that pass's input; rev 5's
changes to those cells are made by Edit, and its commit message records this
deviation (added 2026-10-28, review fold: RR3-m2).

### §8.11 Review fold record (rev 5, 2026-10-28)

The focused re-review (round 3) of rev 4 (9d48a863e) returned
APPROVE-WITH-AMENDMENTS: no BLOCKER, one MAJOR, RR3-M1, and two MINORs, RR3-m1
and RR3-m2. Its trace found RR2-B1 resolved (`Peek8`'s `b->Set` through the
shared `b` is M3(d)'s `StrictInvalidatingThroughShared`, through an owner, a
`ref` or an `exclusive` pointer T4's `StrictSharedBorrowInvalidated` while `s`
holds the loan `AsSlice` and `Data` carry, and a store scan of core/prelude on
all 19 heads finds only buf.carbon:39 and :52 and PR 55's `ref self`
`AddAssign`), RR2-m1 to RR2-m3 resolved (B.3.1's 25 lines exist in
fork/safe/plan.md section 2 at 2407efa74 and state what it says; no
unqualified `Core.Slice(T)` is left), and B.1.0's anchor (log :2964, plan
:249) matching. It fetched upstream at 07718a832, unchanged since rev 4's read
(over the nine quoted files `git log c1e83b0b7..upstream/trunk` lists only
f21c62524, and the seven quoted passages are unchanged), ran PR 67's checks
from a detached 56e2e5bbd worktree (273 quotes and 89 silence checks, the 97
H1-file rows, 284 quotes with C.2's eleven rows, 89 checks with H1.7 widened,
all with 0 failed), matched all 18 held heads and trunk 1c83422a0 by
`git ls-remote`, found W-360 to W-364, W-398 and W-399 taken over 165 refs and
every worktree and W-365 only in this file, counted the headings
`{1: 1, 2: 15, 3: 123}`, bullets 76, numbered 31, rows 137 with no unguarded
block, found
rumdl@0.2.58 clean (the unpinned 0.3.2's three MD013 lines being section 8
item 3's), `runner.py --self-test` exiting 0, the three-way merge-file of
slices.md with A.10.1 and A.10.2 clean against PR 51, PR 65 and trunk, and a
nightly stand-in of `Peek8` printing 6.

Every finding was reproduced by the rev 5 fixer before it was folded, in
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/fixer3/.
RR3-M1: PR 65's prelude at fee0ef31c reads as cited (index.carbon:16 `fn
Ref(self, subscript: SubscriptType) -> ref ElementType;`, and by-value `Ref`
impls at slice.carbon:74-82 and buf.carbon:72-80 returning a `ref` into the
storage with no `bound`), as do T5(a) (an unbound result is free), T5(e) (an
impl may not add `bound`) and SP3 (spatial_safety.md:170-177) at 2407efa74; the
stand-in `Peek9`, a class with a by-value `Ref` returning `ref str` and a
by-value writer, compiled, linked and run on the 2026.10.12 nightly prints 6,
and its twin with a by-value `At` returning `str`, the `IndexWith(i64)` shape
`Core.Buf` has at 2407efa74, prints 2 (ex/ref8.carbon, ex/at8.carbon), so the
reopening comes with PR 65's `ref` result; upstream at 07718a832 declares the
same unbound `Ref` (index.carbon:14-17), and p005434:952-960's `Deref` puts
`bound` on the receiver of a `ref`-returning operator at the interface and in
the impl. RR3-m1: slice.carbon:35-37 at 2407efa74 calls `Data()` "The raw
pointer to element 0", mutation_safety.md:536 and :556-558 give `IntVec.Set`
`addr self` over a private `Core.Buf(i32)`, :736 and :742 state the partition,
and slices.md:245 reads "Writes to owned storage go through `Set`"; the
finding's premise that at PR 53 every element `i > 0` is written only by `Set`
was measured false, since the public `Subslice` (slice.carbon:46-52) returns a
view whose `Data()` points at element `start`, and a store through the `Data()`
of `b.AsSlice().Subslice(i, i + 1)` writes element `i` with no `Set`; the
finding's defects stand: rev 4 named `Data()`'s `T*` as if it reached every
element, A.2.11 named no body path for `IntVec.Set`, whose forward to
`self->buf.Set` is M3(d)'s, and section 7 weighed the exclusive receiver against
the writes under a live view only, which D-SAFE2-5's own cost list contradicts.
RR3-m2: a cell-by-cell comparison of sections 2.2 and 2.3 between 603749ee1 and
9d48a863e (cells.py) finds nine changed cells in six rows, where the re-review
counts seven, and the rev 4 fixer's scratch shows 9d48a863e's file byte-equal to
the input of prek's fourth, unchanged pass. Upstream was re-fetched for rev 5 at
07718a832 and PR 67's checks re-run there (sections 0.1 and 0.2); all 18 heads
and trunk 1c83422a0 match `git ls-remote`; the id re-scan finds W-365 the next
free id, unused outside this file; and `runner.py --self-test` exits 0. All
three findings are accepted and none is rejected. No id was taken: W-365 stays
the next free work item, and no F id. The marks read "(amended 2026-10-28,
review fold: RR3-M1)" and the like; as in sections 8.8 to 8.10, the page and
records texts of Appendices A and B carry only their SAFE-2 marks.

| finding | severity | disposition | where |
| --- | --- | --- | --- |
| RR3-M1 the trusted-body rule's `bound` condition is not applied to PR 65's `IndirectIndexWith.Ref`, which reopens `Peek8`'s shape after PR 65 lands | MAJOR | folded as the fix asks: under W-144 `Ref` takes `bound self` at the interface (T5(e), as `IndexWith.At` does; upstream's `Deref` shape, p005434:952-960) and in the `Slice` and `Buf` impls, so a binding formed through `b[i]` keeps the loan on `b` that `Set`'s `ref self` conflicts with; stated in D-SAFE2-5's PR 65 sentence and break condition, in A.2.8's trusted-body paragraph and, in the same words, in A.1.1, B.1.0 and B.1.7, which rev 4 aligned with it, and in B.4's W-144 note with the counterexample; R-2's falsifier and section 0.8's PR 65 paragraph carry the counterexample, DR-1 carrying it on PR 65's records (Appendix D's fourth block names it); section 0.7 gains the stand-in and its by-value twin; decided under R29, SP3's producer list and T5(e)'s interface list are left as they are (section 0.5, with the break condition) | Status, §0.1, §0.2, §0.5, §0.6, §0.7, §0.8, D-SAFE2-3, D-SAFE2-5, §2.2, §2.3, §7 R-2, §8 item 1, hand-off note 5, A.1.1, A.2.8, B.1.0, B.1.7, B.4, D |
| RR3-m1 the cost record names `Data()`'s `T*` as the surviving element-write path; EX-M-1's `IntVec.Set` is not traced | MINOR | folded with the premise corrected (element `i` is reached through `AsSlice().Subslice(i, i + 1).Data()` at PR 53, not by `Set` alone): D-SAFE2-3, D-SAFE2-5's cost list, A.2.8's storage bullet, B.1.7 and section 8.10's RR2-B1 row name the one-element view and, once PR 65 lands, `IndirectIndexWith.Ref` (`b[i] = v`, `s[i] = v`); A.2.11 names `IntVec.Set`'s body path, `self->buf.Set(i, v)` being M3(d)'s; A.2.17a appends to the C++ partition bullet the element writes that take `ref self`; section 0.5 lists mutation_safety.md:536, :556-558, :736 and :742 (the re-review's :555-556 and :736-741); section 7's alternative is re-weighed against the full cost and still rejected, the cost being a longer spelling until PR 65, with its falsifier widened | §0.5, D-SAFE2-3, D-SAFE2-5, §2.2, §7, §8 item 1, §8.10, A.2.8, A.2.11, A.2.17a, B.1.7 |
| RR3-m2 the R25 deviation is not recorded in the plan or the commit | MINOR | folded by the first option: section 8.10 gains a sentence recording the python3 replace, the nine cells of six rows it touched and prek's fixpoint after it; rev 5 edits every cell it changes by Edit, and its commit message records the deviation | §8.10 |

Disk: the rev 5 fixer's probes (ex/), the C.2 and check subsets, the cell
comparison and the copy of mutation_safety.md at 2407efa74 are in the scratch
directory above; the detached worktree under /dev/shm/safe2-fixer3 was removed
after the checks; nothing was built.

### §8.12 Stop-and-amend record (rev 6 and rev 7, 2026-10-28)

The implementer of section 3's commits 1 and 2 stopped before committing
commit 1 on the stop condition "a superseded text the block quotes is not
byte-equal to the page's text at 2407efa74". Nothing was committed or pushed,
its worktree was left clean at 4ca369e38, and every other check of commit 1
matched this plan: every anchor found once, the R31 deltas of section 8 item 1,
prek's fixpoint with no word of a replacement text changed, rumdl@0.2.58, the
heading sets, the links, the nightly outcomes of section 0.7, the merge-tree
sets of section 0.8, the id re-scan (W-365 next free), PR 67's checks and the
self-test.

**The difference.** Two blocks quote a superseded text with the link markup of
the page's source removed, three links in all:

| block | line at 2407efa74 | the page's source | rev 5's quote |
| --- | --- | --- | --- |
| A.1.6 | safety/README.md:566 | `see [Spatial safety](spatial_safety.md).` | `see Spatial safety.` |
| A.5.10 | safety/spatial_safety.md:553 | `The strategy's [build modes](README.md#build-modes) section` | `The strategy's build modes section` |
| A.5.10 | safety/spatial_safety.md:557 | `in [fork/safe/plan.md](/fork/safe/plan.md)) for two reasons.` | `in fork/safe/plan.md) for two reasons.` |

With the three links restored, both quotes are byte-equal to their pages once
line breaks and blockquote markers are set aside.

**Root cause.** A quote that was not byte-exact. The planner quoted the two
passages' rendered words, the link text without its target, and the plan
never said what "verbatim" (D-SAFE2-2) and "byte for byte" (hand-off note 3)
set aside, so a quote of the rendered page and a quote of its source could not
be told apart by their words. The sweeps that followed, B-M5's re-diff of each
superseded passage (section 8.8), RR1-m2's sweep for dropped fold marks
(section 8.9) and RR2's check of the A.9.1 and A.5.9 quotes (section 8.10),
looked for missing sentences and marks, and none compared every quote with its
source with link markup included. It is not a wrong anchor, a stale line, a
count of section 8 item 1, a hook rewrite, an unlisted dependent line or a
design statement: no rule changes, and no shrink line is drawn.

**Measured facts** (the rev 6 amender, 2026-10-28, scratch directory
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2/amender6/):

-   Upstream fetched at 07718a832, the tip rev 4 and rev 5 read. Over p005434,
    p005914, p000257, docs/design/README.md, safety/README.md, arithmetic.md,
    values.md, classes.md and slices.md, `git log c1e83b0b7..upstream/trunk`
    lists only f21c62524 (classes.md), and safety/README.md:260-262,
    p005434:83, :660-664 and :831-835, p000257:355-360, p005914:85-88 and
    arithmetic.md:150-173 read as section 0.1 quotes them.
-   PR 67's checks, from a detached worktree of 56e2e5bbd under
    /dev/shm/safe2-amender/rg1, removed after, at 07718a832: "checked 273
    quotes, 0 failed", "checked 89 silence checks, 0 failed", the H1 subsets
    of 97 and 120 quote rows with 0 failed, and the five H1 silence checks
    (H1.1, H1.3, H1.4, H1.7, H1.15) with 0 failed. All 18 held heads and
    trunk 1c83422a0 match `git ls-remote origin`.
-   A checker written apart from the implementer's (bin/q6.py) took every
    top-level quoted span of 25 characters or more in the fenced texts of
    Appendices A and B, and in Appendices C and D against PR 67's files at
    56e2e5bbd and trunk's fork/ORCHESTRATION.md at 1c83422a0. It read no
    prose, so no prose anchor (q6.py:54-57). It compared each span with its
    file after collapsing every whitespace run to one space and removing
    every blockquote marker (q6.py:24, :31), and tested a span that failed
    again with link markup and a leading `//` also removed (q6.py:26, :30),
    the only form in which it compared a span with upstream's files
    (q6.py:41, :84). The only spans
    that matched in the second form and not the first were A.1.6's, A.5.10's
    and A.2.12's. Because the first form collapses every whitespace run, a
    span it matched is not thereby byte for byte: A.2.11's first block quotes
    a run of 19 spaces as two and passed it; and the upstream quotes it found
    were found in rendered words with whitespace collapsed, not byte for byte
    (rewritten 2026-10-28, stop-and-amend re-review: AM6-m1, where rev 6 said
    the spans were compared "with only line breaks and blockquote markers set
    aside" and that every other span "is on its file byte for byte, is a
    quote of upstream found byte for byte at 07718a832, or is new text"; the
    sweep of rev 7 below measures section 2.1's test as worded). B.4's eleven
    superseded quotes equal the JSON string values of W-146 and W-148, and
    the 281 verbatim line fields of sections 0.4 and 0.5 equal their page
    lines apart from leading indentation.
-   A.2.12's quote joins the two comment lines it replaces without the second
    line's `//` and its space; a quote inside a comment of one line cannot
    keep the break,
    so section 2.1 now names that marker among the things set aside, and the
    block is unchanged.
-   The two amended texts, applied to the implementer's applied copies of
    safety/README.md and spatial_safety.md in the worktree and run through
    prek to a fixpoint (the first pass changed nothing; check-links and the
    style hook passed), pass `uvx rumdl@0.2.58 check`, keep the R31 counts of
    section 8 item 1 (safety/README.md bullets 70 and rows 47,
    spatial_safety.md bullets 55 and rows 22, headings unchanged), make each
    page one line longer than the implementer's copy (841 and 742 lines), and
    quote their pages byte for byte under section 2.1's test; the two files
    were restored from the index after.
-   A.10.2's block is ten lines and its blank line an eleventh, as A.10.1's;
    the implementer measured slices.md going from 462 to 484 lines.

**The amended instructions.** A.1.6's fenced block quotes the superseded
note's last sentence but one with the link `[Spatial safety](spatial_safety.md)`
as :566 writes it, its last two lines becoming three, and its heading cites
:561-567. A.5.10's first
block quotes the superseded opening with `[build modes](README.md#build-modes)`
and `[fork/safe/plan.md](/fork/safe/plan.md)`, and its heading cites the
bullet as :552-567. A.10.2 adds 11 lines, not 10. Section 2.1 states the
byte-equality test, D-SAFE2-2 and hand-off note 3 point at it, and section 8
item 5 runs it before each commit, a mismatch being a stop. No other block,
record, count, merge-tree set, nightly outcome or design statement changes;
the three restored links point where links of the same pages already point at
2407efa74. The implementer resumes the stage from rev 6's commit: it applies
commit 1 from the rev 6 blocks, or applies the two amended texts to its saved
copies of the pages, and re-runs every check of section 8 before committing,
then commit 2.

**The focused re-review of rev 6 and its fold (rev 7, 2026-10-28).** The
focused re-review of rev 6 (486d2bc74) re-fetched upstream at 07718a832, ran
PR 67's checks, compared the amended texts with the pages and applied them to
the implementer's copies in a detached worktree, where prek, rumdl@0.2.58,
the R31 counts and the heading sets matched rev 6. Its verdict was
APPROVE-WITH-AMENDMENTS, with no BLOCKER (amended 2026-10-28, stop-and-amend
re-review: AM6-M1, AM6-m1):

| finding | severity | what it found | disposition |
| --- | --- | --- | --- |
| AM6-M1 | MAJOR | section 2.1's test, as rev 6 worded it ("these, and nothing else"), fails five quotes that rev 6 keeps, so the resumed stage would stop again | folded: section 2.1, section 8 item 5, A.8.1's locator |
| AM6-m1 | MINOR | the q6.py bullet above overstated what that checker set aside and what it scanned (R10) | folded: the bullet rewritten, and this record's sweep |

The five quotes, each measured on its file at 2407efa74 by the rev 7 amender:

| block | the quote | line at 2407efa74 | what the quote differs by |
| --- | --- | --- | --- |
| A.2.11, first block | the superseded `a->Set(0, 5);` line | safety/mutation_safety.md:547 | a run of 19 spaces quoted as two |
| A.2.11, prose | the anchor that ends with the `vec->Push(3);` line | safety/mutation_safety.md:549 | a run of 19 spaces quoted as one |
| A.2.13, prose | the anchor's `let b: Core.Buf(i32) = a;` line | safety/mutation_safety.md:642 | a run of 7 spaces quoted as one |
| A.3.13, prose | the anchor that ends with the `z = Core.Buf(i32).Make(5, 0);` line | safety/temporal_safety.md:902 | a run of 5 spaces quoted as one, and the rest of the comment quoted as "..." |
| A.8.1, prose | the locator of the replaced blockquote | README.md:2147-2148 | the link `[hardened build mode](#build-modes)` quoted by its text |

**Root cause.** Rev 6 wrote section 2.1's test from the two quotes that had
stopped the implementer and validated it with a checker laxer than the test:
q6.py collapsed every whitespace run and read no prose, so the code-line
quotes, whose runs of spaces this plan has shortened since rev 1, and the
prose anchors were never measured against the test as worded, and its
"nothing else" was not true of the plan it governed. The fold names that
practice in section 2.1 (a run of spaces in a code line, and a closing "..."
for the rest of an anchor's code line), quotes A.8.1's link, the one quote
outside any set-aside, scopes the test to anchors and superseded texts, and
measures the test as worded with a checker that implements it and nothing
more, prose anchors included. No rule, example, diagnostic, page or record
text, line range or count changes, and no shrink line is drawn.

**Measured facts** (the rev 7 amender, 2026-10-28, scratch directory
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2-impl/amend7/):

-   Upstream fetched at 07718a832 again; over the nine files of rev 6's first
    bullet `git log c1e83b0b7..upstream/trunk` lists only f21c62524
    (classes.md). PR 67's checks, from a detached worktree of 56e2e5bbd under
    /dev/shm/safe2-amend7/rg1, removed after: "checked 273 quotes, 0
    failed", "checked 89 silence checks, 0 failed", and the five H1 silence
    checks with 0 failed. All 18 held heads and trunk 1c83422a0 match
    `git ls-remote origin`, PR 53's pushed head being 2407efa74.
-   bin/sweep.py reads every double-quoted span of Appendices A to D, in prose
    and fenced texts alike, and every code span of this plan's prose that
    carries link markup, and compares it with the block's file: PR 53's files
    at 2407efa74, and for Appendices C and D PR 67's files at 56e2e5bbd and
    trunk's fork/ORCHESTRATION.md at 1c83422a0. It tests a span first with
    only the line-break and blockquote set-asides, then with each other
    set-aside of section 2.1 alone, then with link markup reduced to its text,
    which section 2.1 does not set aside; a span that holds a nested quote is
    tested whole. Its output is sweep-r6.txt for rev 6 and sweep-r7.txt for
    rev 7.
-   On rev 6 the anchors and superseded texts that fail the line-break and
    blockquote set-asides are A.2.12's comment quote, which the comment
    marker clears, and the five quotes of the table above, and no other.
-   On rev 7 it reads 614 spans. 479 are equal to their files under the
    line-break and blockquote set-asides alone. A.2.12's comment quote needs
    the comment marker, A.2.11's two code-line quotes and A.2.13's anchor a
    run of spaces, and A.3.13's anchor a run of spaces and its closing "...".
    The four code-span quotes, A.1.6's, A.5.10's two and A.8.1's, are equal. So
    every anchor and superseded text passes section 2.1's test as rev 7 words
    it. Of the other 126 spans, none an anchor or a superseded text: 35 are
    found only in upstream's files at 07718a832 (28 quotes of upstream's
    words in new texts, and seven times the string literal "longer" of the
    new examples' code, a word upstream's files also hold); one,
    the design overview's sentence inside A.4.2's new text, only in rendered
    words, as section 2.1 now says such a quote is written; 31 quote new texts
    of this plan's fenced blocks; 52 are found nowhere and were read one by
    one, each a new text given in prose (a renamed heading, a replacement
    clause, a diagnostic's or the runtime's message, a commit message or a
    check's output) or a quote of an earlier revision of this plan; five are
    words found on another file, none an anchor; and two, A.1.6's "see
    Spatial safety" and B.1.7's "Memory safety holds ...", quote what rev 5
    and rev 1 wrote.

**The amended instructions (rev 7).** No fenced text of Appendices A to D
changes, nor any line range, count, merge-tree set or nightly outcome, and no
anchor's words but A.8.1's locator. Section 2.1 sets aside, besides rev 6's
four, a run of spaces in a code line and a closing "..." for the rest of an
anchor's code line; it scopes its test to anchors and superseded texts; and
A.8.1's locator quotes the sentence at :2147-2148 with its link, whose words
are those of the sentence the implementer already found once. The
implementer resumes the stage from rev 7's commit as rev 6's instructions
above say, and runs section 8 item 5's test as section 2.1 now words it,
prose anchors and fenced texts alike, with no whitespace collapsed beyond a
code line's runs of spaces and no link markup dropped; bin/sweep.py in the
rev 7 scratch directory is such a checker, and sweep-r7.txt is the expected
result.

### §8.13 Focused re-review, round 1 (2026-10-28)

Round 1 of section 3 step 5's loop: one fresh agent reviewed the commits after
the head 954f1c542 up to 106fc1877, at 106fc1877: the document-review fold's fix
commits 0f281d8bd and e1574b003, two of section 3 step 4's budget of three, and
its records commit 106fc1877 with section 8.7, against the two document reviews'
findings, this plan and upstream's tip. Its ids, RR1-B1 to RR1-m2, are this
round's: section 8.9 records the plan's own round 1 under the same prefix, and
the marks tell them apart, "re-review round 1" here and "review fold" there. The
review's scratch is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2-rr/r1/review/,
and this records commit's runs are in rec1/ beside r1/. Everything measured is
container-local, EXPECTED, not of record (R9).

**The review**, REJECT, with one BLOCKER, two MAJORs and two MINORs, one of
them records-only. Its runs, as it reports them:

-   Upstream at 9192ee003: since 07718a832 nothing changed under proposals,
    docs/design, toolchain/check/type_completion.cpp or core/prelude, and
    since the cut only f21c62524 touches classes.md among the quoted files;
    section 0.1's quotes and the fold's quotes of docs/design/assignment.md
    and p005434 read as before.
-   PR 67's checks, from a detached worktree of 56e2e5bbd at
    /dev/shm/safe2-review/rg1, removed after: 273 quotes and 89 silence
    checks with 0 failed, the H1 subsets of 97 and 120 quote rows and the
    five H1 checks with 0 failed, and the fold's nine quotes with 0 failed.
-   Trunk 1c83422a0 and all 18 held heads match `git ls-remote`; the
    merge-tree sets equal those of section 0.8, and the nightly outcomes
    those of section 0.7.
-   R31: the deltas are those section 8.7 records, none on the pages, the
    log and fork/safe/plan.md, and on this plan bullets from 86 to 99 and
    rows from 168 to 180. Run twice on a detached copy, prek exits 0 with no
    change; rumdl@0.2.58 is clean, and the heading sets are unchanged.
-   The log's D-SAFE block, 1149 lines, is identical to fork/safe/plan.md
    section 0.3; the ledger parses with `json.load`; `runner.py --self-test`
    exits 0; author, committer and trailers are right, 2407efa74 is an
    ancestor, and no model identifier appears outside the trailers.
-   Of section 8.7's dispositions the tree bears out R1-m1, R1-m2, R2-m2
    (its quotes equal to 2407efa74), R1-m3, R2-m1, R2-m3 and R2-m4, and not
    the three page fixes of 0f281d8bd: R1-M2's (RR1-B1), R1-M1's (RR1-M1)
    and R1-M3's (RR1-M2).

**Dry judgment and the orchestrator's ruling.** By section 3 step 5 a round
is dry when it has no BLOCKER and no MAJOR and every MINOR is records-only.
This round has a BLOCKER and two MAJORs, and RR1-m1 changes the temporal and
mutation pages, so it is not dry, as the review judges it. The orchestrator
ruled it "NOT DRY: 3 serious or 4 page-changing findings go to round 2's
fixer". The round goes back to section 3 step 4 within its budget: the
commits 0f281d8bd and e1574b003 are two of the three fix commits, so the
fixer of round 2 folds RR1-B1, RR1-M1, RR1-M2 and RR1-m1 in at most one fix
commit, its records commits not counted, with no shrink line: a defect past
the budget stops the workflow at a plan revision of this file. A fresh agent
then reviews round 2, the loop having at most three rounds, and section 3's
steps 6 to 8 wait for a dry round. This round's one records-only MINOR,
RR1-m2, is folded now by this records commit, "SAFE-2 records: focused
re-review round 1 recorded" (2026-10-28, the UTC date of its commit). Each
finding was reproduced against the tree at 106fc1877, whose line numbers the
table cites, before it was dispositioned:

| finding | severity | reproduced | disposition | where |
| --- | --- | --- | --- | --- |
| RR1-B1, R1-M2's free-result obligation lasts while the binding lives, not while its frozen loan does | BLOCKER | the cites read as quoted: T6 keys the marker's obligation to "while a value binding of a borrowed object, or a `const` `ref`, formed through the result or a copy of it lives" (temporal_safety.md:533-535), the spatial bullets (spatial_safety.md:199-203 and :509-514) to a value binding, without the `const` `ref`, M8 to "while the binding lives" (mutation_safety.md:670-673), and type_safety.md:135-140 calls the doc comment's sentence "the contract a caller discharges"; under T5(d) `AsSlice`'s by-value `bound self` keeps its frozen loan for its result's lifetime, so in the review's `Alias` and `AsSlice` program `s` holds that loan after the binding is dead, and the review traces the program to a read of freed memory; this records commit compiles nothing | to round 2's fixer, not touched here: it fires the break condition of section 8.7's R1-M2 decision, which that fixer re-runs between the review's two remedies, the obligation keyed to every frozen loan formed through the result or a carrier derived from it for as long as the loan is live (T3), or `unsafe` at each such formation, stated in the same words in T6, both spatial bullets, M8, D-SAFE-10's T6 and D-SAFE-17 in the log and fork/safe/plan.md section 0.3, D-SAFE2-5, W-148's note and type_safety.md:135-140; section 2.2 and hand-off note 5 leave type_safety.md unedited, so an edit there takes a dated mark in both | section 8.7's R1-M2 decision, a dated mark |
| RR1-M1, R1-M1's operator exception is missing from dependent lines | MAJOR | fork/safe/plan.md:1545-1548, section 1.5, reads "A built-in operator's `ref` operand, an assignment's among them, lives for the one operation and is established on any place, M3 deciding what the operation may do"; safety/README.md:443-455, the paragraph section 1.5 drafts (R27), and temporal_safety.md:178-189 do not carry it, and the temporal page's D-SAFE-8 bullet (:1398-1412) gives no operand exception where the log's D-SAFE-8 does (:3131-3142) | to round 2's fixer, not touched here: the sentence, dated, in the three page passages | none |
| RR1-M2, R1-M3's qualifier misses `ref self: const Self` calls | MAJOR | mutation_safety.md:220-223 and :1280-1283, the log's :3217-3220 and fork/safe/plan.md:516-519 subject a `const` call through `T*` or `const T*` to M8 only where it binds a borrowed object (:221, "when they bind a borrowed object"), an object in an active value binding (p005434:660-661 at 9192ee003), which a `ref self: const Self` receiver, a frozen `ref`, is not; M4's third bullet (mutation_safety.md:314-322) and the temporal page's `ref` bindings (:250-262) make that call through a shared pointer to an open place `StrictRefFromShared` unless the type is `Core.SharedImmutable` | to round 2's fixer, not touched here: the qualifier names the `ref self: const Self` receiver in the four places, the two records lines with the two page lines (R27) | none |
| RR1-m1, the "built in" test leaves out the integer `++` and `--` | MINOR, not records-only | core/prelude/types/int.carbon:384-399 and uint.carbon:446-461, equal to upstream's at 9192ee003, give `Dec` and `Inc` bodies, `self -= AsInt(1);` and `self += AsInt(1);`, under the TODO "Add builtins for these to avoid emitting a call." (int.carbon:382, uint.carbon:444), so under the test of temporal_safety.md:271-274, "the language's own or a prelude impl whose body is a builtin", `++p->n` through `T*` is neither built in nor user-written while `p->n += 1` is built in; upstream's docs/design/assignment.md:156-157 at 9192ee003 reads "For integer types, `++n;` and `--n;` behave the same as `n += 1;` and `n -= 1;` respectively."; and no page says that the operand's `ref` forms no loan of its own under M3(d) or (e) | to round 2's fixer, not touched here: the temporal and mutation pages change; the test is section 8.7's R1-M1 decision, which that fixer restates | section 8.7's R1-M1 decision, a dated mark |
| RR1-m2, section 8.7's placeholder list is incomplete and its type_safety.md claim overstated | MINOR, records-only | section 8.7's list (:2364-2366) names `<head>`, `<c2-sha>`, `<time>`, `<tip>`, `<rdate>` and `<date>`, while C.1 carries `<sha1>` and `<sha2>` (:7033-7034), D's second block those and `<fixes>`, its fourth block those and `<verdict 1>` and `<verdict 2>` (:7246-7247, :7259), and its fifth and sixth `<landing date>` and `<merge commit>` (:7279-7284); section 2.1 (:1791-1795) says section 3 step 4's records commit filled the verdicts and the fixes, which it did only where commit 2 wrote "pending"; section 8.7's R1-M2 row (:2308) says type_safety.md "cites T6 for the rule rather than restating it (type_safety.md:145-147)", where :144-146 cite T6 for the result's loan set and the ⊥ rule and :135-140 restate `Make`'s contract | folded by this records commit: the table below lists every placeholder still unfilled, the step that fills it and its known value, and section 8.7's paragraph points to it; section 2.1's bullet says which copies step 4 filled and that Appendix D's are step 8's; the R1-M2 row's claim is corrected and the restatement named as RR1-B1's | section 2.1; section 8.7's R1-M2 row and placeholder paragraph; this section |

The placeholders still unfilled at this commit, all in Appendices C and D
(RR1-m2); the placeholders of Appendices A and B are filled in the files
those blocks were applied to, the four that commit 2 wrote "pending" for by
section 8.7's records commit:

| placeholder | where | filled by | known value |
| --- | --- | --- | --- |
| `<sha1>` | C.1; D's second and fourth blocks | the files of section 3 step 8 | 48f2e66a0 |
| `<sha2>` | C.1; D's second and fourth blocks | the files of section 3 step 8 | 954f1c542 |
| `<fixes>` | D's second and fourth blocks | the files of section 3 step 8 | 0f281d8bd, e1574b003 and cbdc0552e (amended 2026-10-29, re-review round 2: section 8.14, where this read "0f281d8bd and e1574b003, with round 2's fix commit when it is made (decided below)") |
| `<verdict 1>` | D's fourth block | the files of section 3 step 8 | "APPROVE-WITH-FIXES with three MAJORs and three MINORs", the words of fork/safe/plan.md's realigned notes |
| `<verdict 2>` | D's fourth block | the files of section 3 step 8 | "APPROVE-WITH-FIXES with four MINORs", the same notes' words |
| `<head>` | C.1; C.2's message and blocks; C.3; D's first, second, fourth and fifth blocks | section 3 step 6 for C.2, step 7's push, step 8 for C.1, C.3 and D | not known: the head at which step 5 is dry, and round 1 is not |
| `<c2-sha>` | C.3; D's edit 3 and its second, third and fourth blocks | section 3 step 6, the PR 67 note commit, then step 8 | not known |
| `<rdate>` | C.1; C.2's edit (iv) and first block; D's second, fifth and sixth blocks | the step that writes each text, step 6 or step 8 | 2026-10-28, commit 1's `date -u +%F` |
| `<date>` | C.2's edit (iv) and its blocks after the first, and the W-355 note; C.3; D's edit 3 and its first and fourth blocks | section 3 step 6 for C.2, the note commit's date; step 8 for C.3 and D, the stamp's | not known |
| `<time>` | D's first and fourth blocks | section 3 step 8 | not known |
| `<tip>` | D's third and fourth blocks | section 3 step 8, the tip section 8 item 5 last read | 9192ee003 at this commit |
| `<landing date>`, `<merge commit>` | D's fifth and sixth blocks | PR 53's land-sequence records commit, when PR 53 merges after PR 67 (D's edit 6), after section 3's steps | not known until PR 53 lands |
| `<n>` | no text | none | unused |

Decisions under R29, each with its break condition:

-   This round's ids keep the review's spelling, RR1-B1 to RR1-m2, though
    section 8.9 records the plan's round 1 under the same prefix: every mark
    of this round reads "re-review round 1", every mark of section 8.9 reads
    "review fold", and this section names the implementation's round where
    both could be meant. Break condition: a reviewer takes a finding of one
    round for the other's; this round's ids then gain a prefix by a dated
    mark.
-   `<fixes>` stands for every fix commit of section 3 steps 4 and 5, so
    round 2's fix commit, when it is made, joins 0f281d8bd and e1574b003 in
    Appendix D's texts; the log's RG-1 paragraph and fork/safe/plan.md's
    realigned notes name the fold of the two document reviews, as "folded
    by 0f281d8bd and e1574b003", and round 2's records commit adds there, by
    a dated mark, the fix commit that redoes the R1-M1, R1-M2 and R1-M3
    folds. Break condition: round 2 makes no fix commit, the workflow
    stopping at a plan revision of this file; `<fixes>` then stays the two.
-   The Sign-off section's table stays the table of this plan's reviews, as
    its rows are; the implementation's reviews, the two document reviews and
    this round, are recorded in section 8.7, this section and the Status
    line, and section 8.7's two decisions that the round reaches carry a
    dated mark pointing here. Break condition: a reviewer requires every
    review of the implementation in the Sign-off table; rows are then added
    there by a records commit.

**Measured** by this records commit, 2026-10-28, in rec1/:

-   `git -C /home/user/carbon-lang fetch -q upstream trunk` gives 9192ee003
    again (2026-10-28 20:51:45 UTC, upstream PR 8054), the review's tip;
    `git log 07718a832..9192ee003` over proposals, docs/design,
    toolchain/check/type_completion.cpp and core/prelude lists nothing, and
    `git log c1e83b0b7..9192ee003` over section 0.1's nine files,
    docs/design/assignment.md, docs/design/expressions/indexing.md and
    core/prelude/types/int.carbon and uint.carbon lists only f21c62524
    (classes.md); the fork's int.carbon and uint.carbon equal upstream's
    there.
-   PR 67's checks, from a detached worktree of 56e2e5bbd at
    /dev/shm/safe2-rec1/rg1, removed after, against /home/user/carbon-lang
    at 9192ee003: "checked 273 quotes, 0 failed" and "checked 89 silence
    checks, 0 failed"; the 97 and the 120 H1 quote rows, byte-equal to the
    review's subsets, "checked 97 quotes, 0 failed" and "checked 120
    quotes, 0 failed"; the five H1 checks, "checked 5 silence checks, 0
    failed"; the fold's nine quotes, "checked 9 quotes, 0 failed"; with
    C.2's eleven rows, "checked 284 quotes, 0 failed", and with H1.7
    widened, "checked 89 silence checks, 0 failed".
-   `git ls-remote origin`: trunk 1c83422a0 and the 18 held heads as
    section 0.8 names them, PR 53's pushed head still 2407efa74.
-   The id re-scan of section 0.9 over the 165 origin refs and local
    branches and the 22 worktrees: the ledgers end at W-363, the text names
    W-360 to W-364, W-398 and W-399 as there, and W-365 only in this file;
    no id is taken and no F id minted.
-   R31 on this plan, the one file this commit changes: before, headings
    {1: 1, 2: 16, 3: 126}, bullets 99, numbered 31, rows 180, 7288 lines;
    after, headings {1: 1, 2: 16, 3: 127}, bullets 115, numbered 31, and
    rows 202, 7471 lines, the same after the edit and after each prek pass;
    the changes are this section's heading, its 16 bullets and its 22
    table rows, with no unguarded block.
-   prek to a fixpoint with a private cache, deleted after: its first pass
    reflowed this section's first paragraph only, the word diff empty, and
    the later passes exit 0 with no change; rumdl@0.2.58: no issues; the
    heading sets differ by this section's heading alone, and the
    manufactured-heading grep is empty.
-   `runner.py --self-test`: "150 programs parsed, 56 bullets in table, OK".
    The model-name grep over this plan's changed lines and the message: no
    hit outside the trailers. The merge-tree of the new head against trunk
    and the 18 held heads: the sets of section 0.8's table, unchanged.

No page, example, log, fork/safe/plan.md or ledger line changes, so the
nightly compiles of section 0.7 are not re-run and the ledger's `json.load`
is not owed; nothing is pushed (section 3 step 7 waits for a dry round).

### §8.14 Focused re-review fold record, round 2 (2026-10-29)

Round 1 of section 3 step 5's loop goes back to section 3 step 4, as the ruling
recorded in section 8.13 has it, and round 2 is the review of this fold (amended
2026-10-29, re-review round 2: RR2-m2, where this read "Round 2 of section 3
step 5's loop goes back to section 3 step 4"): one fresh fixer, the fixer of
round 2, took round 1's four findings that are serious or change a page, RR1-B1,
RR1-M1, RR1-M2 and RR1-m1, reproduced each against the tree at 6ebe4d650, this
plan and upstream's tip, re-fetched as 9192ee003 (2026-10-28 20:51:45 UTC,
upstream PR 8054, the tip of section 8.13), and dispositioned it. All four are
ACCEPTED and none is rejected. They are folded by one fix commit, cbdc0552e,
"SAFE-2 fix: the free-result and `unsafe`-binding obligations keyed to the
frozen loan, the operator exception and the `ref self: const Self` qualifier on
every dependent line, and the built-in test (RR1-B1, RR1-M1, RR1-M2, RR1-m1)",
the third and last commit of section 3 step 4's budget (0f281d8bd and e1574b003
are the other two), and recorded by this records commit, "SAFE-2 records:
focused re-review round 2 fold", which is not counted. No defect needed a commit
past the budget, and no finding was answered by softening a realignment, so no
plan revision is made. Each fold carries "(amended 2026-10-29, re-review round
2: <id>)", the UTC date of the fix commit, on the page and in the same words in
the log's F-013 entry, fork/safe/plan.md section 0.3 and section 1, this plan's
section 1 and W-148's notes (R27); each superseded clause is quoted after "where
this read", every quote found in its file at 6ebe4d650 (29 of 29), and
type_safety.md's superseded sentence, SAFE-1's 2026-10-12 text, in full. The
scratch is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2-rr/r2/fixer/.
Everything measured is container-local, EXPECTED, not of record (R9).

| finding | severity | reproduced at 6ebe4d650 | disposition | where it landed |
| --- | --- | --- | --- | --- |
| RR1-B1, the free-result obligation lasts while the binding lives, not while its frozen loan does | BLOCKER | temporal_safety.md:532-536 keyed T6's obligation to "while a value binding of a borrowed object, or a `const` `ref`, formed through the result or a copy of it lives", spatial_safety.md:199-203 and :512-514, M8 (mutation_safety.md:671-673), D-SAFE-10's T6 and D-SAFE-17 (log :3354-3357 and :3741-3744, fork/safe/plan.md :653-656 and :1040-1043), D-SAFE2-5 (:1305-1309) and W-148 to the binding; T5(d) (temporal_safety.md:704-707) keeps a by-value `bound self`'s frozen loan for the result's lifetime, and the fork prelude's `AsSlice(self)` (buf.carbon:54) takes `bound self` under W-144 (spatial_safety.md:184-191), so in the review's `Alias` program `s` holds the loan on `*r`, an open place of the `Core.SharedImmutable` type `Core.Buf(i32)`, after the binding is dead, the owner's `b = Core.Buf(i32).Make(1, 0);` sees no loan on `b` and frees the block, and `s[0]` reads freed memory with `Alias`'s doc comment and the binding-keyed obligation both met; type_safety.md:135-140 called the doc comment's sentence the contract; the same root keys the `unsafe` binding's own obligation to "while the binding lives" (README.md:309-310, mutation_safety.md:259 and :608-609, log :3762-3763, fork/safe/plan.md :1061-1062, D-SAFE2-5 :1371-1373), shorter than a `bound self`'s loan | ACCEPTED: the obligation keyed to the frozen loan, as decided below: while a frozen loan formed through the result, or through a carrier derived from it, is live (T3), whatever carries the loan, a value binding of a borrowed object, a `const` `ref` or the result of a call that keeps it (T5(d)), no path other than the result and its copies writes the storage that loan covers; the `unsafe` binding's obligation lasts while the binding's loan is live, a `bound self`'s as long as the call's result that keeps it | cbdc0552e: T6 with the `Alias` program, both spatial bullets, M8's soundness argument and its open-place bullet, M3's union sentence, type_safety.md:135-140 (rewritten, the 2026-10-12 sentence quoted in full), README's operation-tied bullet, D-SAFE-10's T6 and D-SAFE-17 in the log and section 0.3, D-SAFE2-5 twice, W-148's notes; section 2.2 and hand-off note 5 gain a dated mark for type_safety.md |
| RR1-M1, the operator exception missing from dependent lines | MAJOR | fork/safe/plan.md:1545-1548 (section 1.5) carries "A built-in operator's `ref` operand, an assignment's among them, lives for the one operation and is established on any place, M3 deciding what the operation may do"; safety/README.md:443-455, the paragraph section 1.5 drafts, temporal_safety.md:178-189 and the temporal D-SAFE-8 bullet (:1398-1412), and mutation_safety.md:164-172 (M1's `ref` sentence), each "every `ref` binding ... an `unsafe` formation on an open place", do not, so read with docs/design/assignment.md:76-82 at 9192ee003 they made `q->n = 2` `StrictRefFromShared` | ACCEPTED: section 1.5's sentence, word for word, in the four passages | cbdc0552e: safety/README.md's kinds paragraph, the temporal kinds paragraph and D-SAFE-8 bullet, mutation M1 (the fourth beyond the review's three, R17) |
| RR1-M2, the qualifier misses `ref self: const Self` calls | MAJOR | mutation_safety.md:219-223 (M3), :307-309 (M4's `addr self` bullet) and :1280-1283 (the page's D-SAFE-9), the log's D-SAFE-9 (:3217-3220), fork/safe/plan.md :516-519 and :1585-1587 subject a `const` call to M8 "when they bind a borrowed object", which a `ref self: const Self` receiver, a frozen `ref` (p005434:660-661 at 9192ee003), is not; the temporal `ref` bindings (:250-262) and M4's third bullet make that call through a shared pointer to an open place `StrictRefFromShared` | ACCEPTED: a `const` call whose `self` binds a borrowed object or is a `ref self: const Self`, and a read into a value binding of a borrowed object, need besides a closed place, a `Core.SharedImmutable` type, or `unsafe`, under M8 (D-SAFE-17) and, for the `const` `ref`, the `ref` bindings (D-SAFE-8) | cbdc0552e: M3, M4's `addr self` bullet, the page's D-SAFE-9, D-SAFE-9 in the log and section 0.3, fork/safe/plan.md section 1.6's M4; the M1 table's paragraph (:145-152) already named the receiver |
| RR1-m1, the built-in test leaves out the integer `++` and `--` | MINOR, page change | the test "the language's own or a prelude impl whose body is a builtin" (temporal_safety.md:271-277, mutation_safety.md:232-234, log :3138-3139, fork/safe/plan.md :437-438, D-SAFE2-6 :1451-1452) excludes `Inc` and `Dec`, whose bodies `self += AsInt(1);` and `self -= AsInt(1);` (core/prelude/types/int.carbon:384-399, uint.carbon:446-461, equal to upstream's at 9192ee003, under :382's TODO) are no builtin, so `++p->n` through `T*` was neither built in nor user-written while `p->n += 1` was built in; docs/design/assignment.md:156-157 reads "For integer types, `++n;` and `--n;` behave the same as `n += 1;` and `n -= 1;` respectively."; and no line said that the operand's `ref` forms no loan of its own, M3(e) included | ACCEPTED: built in is the semantics assignment.md:146-157 gives the built-in types, the prelude's impls of them, which :168-170 says are "provided for built-in types as necessary to give the semantics described above", counting whatever their body; the assignment of a tuple, struct, array, choice type or class with no user-written `AssignWith` impl (:159-161, a TODO upstream); and the language's own `&`, member access naming a field and indexing of an array; the operand's `ref` forms no loan of its own, neither M3(d)'s call nor M3(e)'s exclusive loan | cbdc0552e: the temporal `ref` bindings section, M3, the page's D-SAFE-9, D-SAFE-8 and D-SAFE-9 in the log and section 0.3, section 1.6's M3, D-SAFE2-6, W-148's notes; section 8.7's R1-M1 decision carries a dated mark |

Decisions under R29, each with its break condition:

-   Section 8.7's R1-M2 decision is re-run, its break condition having fired
    (section 8.13), and keeps the obligation, keyed now to the frozen loan
    and not to the binding, over the second option, `unsafe` at each frozen
    formation through a free result: the counterexample broke the
    obligation's duration, not its kind, and the second option would put a
    marker on every value binding of a `Core.SharedImmutable` element read
    through a `Make` view, undoing the single audit line that T6, SP3 and
    the spatial audit-line bullet state. Break condition: a counterexample
    in which a frozen loan formed through a free result is invalidated with
    the loan-keyed obligation met; `unsafe` at each such formation then
    replaces it.
-   The `unsafe` binding's own obligation is re-keyed in the same commit,
    beyond the review's list, because it has RR1-B1's root: an
    `unsafe p->M()` whose `bound self` binds a borrowed object on an open
    place keeps its frozen loan in the result (T5(d)), longer than the
    binding (R17). Break condition: T5(d) stops keeping a by-value `bound`
    argument's frozen loan in the result; the obligations then return to the
    binding's lifetime by a dated mark.
-   RR1-m1's test follows the review's remedy and spells the aggregate case
    as a type with no user-written `AssignWith` impl, so that the assignment
    of `Core.String`, a class whose fields are private
    (core/prelude/types/string.carbon:16-26) and which the prelude gives no
    `AssignWith` impl, stays built in and `*q = "longer"` through a `str*`
    stays `StrictSharedImmutableWrite`; every `ref self` operator impl in
    core/prelude is for `Int`, `UInt`, `Float` or a `CppCompat` integer.
    Break condition: upstream answers assignment.md:159-161's TODO, or
    routes `=` through `AssignWith` for a type this test calls built in; the
    test then follows upstream by a dated mark. (Amended 2026-10-29,
    re-review round 2: RR2-M1, RR2-m1: the test leaves the prelude's
    `CppCompat` integer impls neither built in nor user-written, and its
    aggregate clause credits assignment.md:159-161, whose heading reads
    "Tuples, structs, choice types, and data classes", with arrays and with
    every class that has no user-written `AssignWith` impl; round 3's fixer
    restates both; section 8.15.) (Amended 2026-10-29, rev 8: RR2-M1, RR2-m1:
    section 8.16 re-plans the test by where an implementation is written and
    keeps the aggregate clause's reach as this design's classification, this
    break condition with it.)
-   type_safety.md is edited although section 2.2 and hand-off note 5 left it
    alone, because its sentence calling the doc comment the whole contract
    is a dependent line of RR1-B1 (R17); both carry a dated mark. Break
    condition: a held PR's change to type_safety.md:131-146 collides with
    it; none does at cbdc0552e (section 0.8's merge-tree sets unchanged).
-   Appendix A and B keep commits 1 and 2's texts, as section 8.7 decided.
    The blocks whose targets cbdc0552e changes are A.1.2, A.1.5, A.2.3,
    A.2.4a, A.2.5, A.2.8, A.2.19, A.3.3, A.3.4, A.3.16, B.1.1, B.1.2, B.1.2a,
    B.1.7 and B.3.5; section 8.7's pointer decision is extended by a dated
    mark to this list rather than marking fifteen blocks, and the spatial
    lines, T6's free-result paragraph, M3's two fold sentences and
    type_safety.md are no block's text. Break condition: section 8.7's, a
    re-reviewer needs the fold texts verbatim in this plan. (Amended
    2026-10-29, re-review round 2: RR2-m2: B.3.8, whose target this records
    commit, b30c77990, changed by the realigned notes' cbdc0552e sentence, is
    amended in place by the records commit of section 8.15, as section 8.7
    decided for it, and is on no pointer list.)
-   `<fixes>` is now 0f281d8bd, e1574b003 and cbdc0552e (section 8.13's
    placeholder row, a dated mark), and fork/safe/plan.md's realigned notes,
    the one record that names the fold commits, gain cbdc0552e by a dated
    mark; section 8.13's decision named the log's RG-1 paragraph too, which
    names commits 1 and 2 only and is left as it is. Break condition: a
    later fix commit; it then joins the list the same way.

**Measured** after cbdc0552e, 2026-10-29, logs in the scratch's logs/:

-   `git -C /home/user/carbon-lang fetch -q upstream trunk` gives 9192ee003;
    `git log 9192ee003..upstream/trunk` over proposals, docs/design,
    toolchain/check/type_completion.cpp and core/prelude lists nothing, and
    `git log c1e83b0b7..9192ee003` over section 0.1's nine files,
    docs/design/assignment.md, docs/design/expressions/indexing.md,
    core/prelude/types/int.carbon and uint.carbon lists only f21c62524
    (classes.md); the fork's assignment.md, int.carbon and uint.carbon equal
    upstream's there.
-   PR 67's checks, from a detached worktree of 56e2e5bbd at
    /dev/shm/safe2-r2fixer/rg1, removed after, against
    /home/user/carbon-lang at 9192ee003: "checked 273 quotes, 0 failed",
    "checked 89 silence checks, 0 failed", the 97 and the 120 H1 quote rows
    "checked 97 quotes, 0 failed" and "checked 120 quotes, 0 failed", the
    five H1 checks "checked 5 silence checks, 0 failed", the earlier fold's
    nine quotes "checked 9 quotes, 0 failed", and the sixteen upstream lines
    this round cites (docs/design/assignment.md:146, :148, :153, :156, :159,
    :161, :169 and :170, core/prelude/types/int.carbon:331, :382, :395 and
    :398, uint.carbon:457 and :460, p005434:660 and :831) "checked 16
    quotes, 0 failed".
-   `git ls-remote origin`: trunk 1c83422a0 and the 18 held heads as the
    table of section 0.8 names them, PR 53's pushed head still 2407efa74.
-   R31 at cbdc0552e: every heading, bullet, numbered and row count of the
    eight markdown files it changes equals the count at 6ebe4d650, after the
    edit and after each prek pass, so section 8 item 1's expected deltas
    stand; lines temporal 1564 to 1607, mutation 1472 to 1511, spatial 748
    to 758, safety/README.md 841 to 849, type_safety.md 539 to 551, the log
    8249 to 8284, fork/safe/plan.md 2966 to 3007, this plan 7471 to 7505.
-   prek with a private cache, deleted after: pass 1 reflowed one paragraph
    of this plan (rumdl MD013), the words equal; pass 2 exits 0 with no
    change. rumdl@0.2.58: no issues in 8 files. The heading sets are
    unchanged and the manufactured-heading grep is empty.
-   Links: 1359 to 1366 over the ten pages and 82 to 83 on type_safety.md,
    the unresolved set unchanged and the checker's own (italic-heading
    anchors of terminology.md and the README's parenthesized URLs); the prek
    link hook passes.
-   The nightly outcomes of section 0.7: m4a 1, m4c 1, Peek 1, Peek2 6,
    Peek4 6, tm9 3; i1, i2, i5, tm2, tm3, sp4 and sp6 compile 0; tm7 and
    sp3 exit 1 with the table's diagnostics.
-   `runner.py --self-test`: "150 programs parsed, 56 bullets in table, OK";
    the ledger parses with `json.load`; the log's D-SAFE-1 to D-SAFE-23
    block, 1184 lines, is identical to fork/safe/plan.md section 0.3.
-   The merge-tree of cbdc0552e against trunk and the 18 held heads: the
    sets of section 0.8, the same as 6ebe4d650's.
-   The id re-scan widened to W-3[6-9][0-9] over the 165 origin refs and
    local branches and the 22 worktrees: the ledgers end at W-363, the text
    names W-360 to W-365, W-398 and W-399 as before; no id is taken, no
    residue is filed and no F id is minted.
-   The model-name grep over the changed lines and the message: no hit
    outside the trailers.
-   R31 of this records commit, on this plan: before, headings {1: 1, 2: 16,
    3: 127}, bullets 115, numbered 31, rows 202; after, headings {1: 1, 2:
    16, 3: 128}, bullets 133, numbered 31, rows 208, the changes this
    section's heading, its eighteen bullets and its six table rows;
    fork/safe/plan.md's counts are unchanged.

Nothing is pushed: section 3 step 7 waits for a dry round, and round 2, a
fresh agent, reviews cbdc0552e and this records commit (amended 2026-10-29,
re-review round 2: RR2-m2, where this read "round 3, a fresh agent, reviews";
section 8.15 records that review).

### §8.15 Focused re-review, round 2 (2026-10-29)

Round 2 of section 3 step 5's loop: one fresh agent reviewed the commits after
the head 106fc1877 up to b30c77990, at b30c77990: round 1's records commit
6ebe4d650 with section 8.13, round 2's fix commit cbdc0552e, the third and last
of section 3 step 4's budget (0f281d8bd and e1574b003 are the other two), and
its records commit b30c77990 with section 8.14, against round 1's findings, this
plan and upstream's tip. Its ids, RR2-M1, RR2-m1 and RR2-m2, are this round's:
section 8.10 records the plan's own round 2 under the same prefix, with an
RR2-m1 and an RR2-m2 of its own, and the marks tell them apart, "re-review round
2" with an RR2 id here, "review fold" there, and "re-review round 2" with an RR1
id for round 2's fixer. The review's scratch is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2-rr/r2/review/,
and this records commit's runs are in rec2/ beside r2/. Everything measured is
container-local, EXPECTED, not of record (R9).

**The review**, APPROVE-WITH-FIXES, with no BLOCKER, one MAJOR and two MINORs,
one of them records-only. Its runs, as it reports them:

-   Upstream re-fetched: still 9192ee003; since the cut c1e83b0b7 only
    f21c62524 touches classes.md among the files the plan quotes, and the
    fork's docs/design/assignment.md and core/prelude/types/int.carbon,
    uint.carbon and cpp/int.carbon equal upstream's there.
-   PR 67's checks, from a detached worktree of 56e2e5bbd at
    /dev/shm/safe2-review/rg1, removed after: 273 quotes and 89 silence
    checks with 0 failed, the H1 subsets of 97 and 120 quote rows and the
    five H1 checks with 0 failed, and the earlier fold's nine quotes with 0
    failed.
-   Trunk 1c83422a0 and all 18 held heads match `git ls-remote`; the
    merge-tree sets equal those of section 0.8, and no held head touches
    docs/design/safety.
-   The nightly compiles reproduce section 0.7: m4a prints 1, m4c 1, Peek 1,
    Peek2 6, Peek4 6 and tm9 3, and tm7 and sp3 exit 1.
-   R31: the counts equal the recorded ones at cbdc0552e and at b30c77990.
    Run twice on a detached copy, prek exits 0 with no change; rumdl@0.2.58
    is clean; only the headings of sections 8.13 and 8.14 are new.
-   The log's D-SAFE block is identical to fork/safe/plan.md section 0.3;
    the ledger parses with `json.load`, and `runner.py --self-test` passes.
-   The budget is used, three of three; author, committer and trailers are
    right, 2407efa74 is an ancestor, no model identifier appears, and the
    ledgers end at W-363. Every quote of round 2 that it checked is found
    at 6ebe4d650.
-   Of section 8.14's dispositions the tree bears out RR1-B1, RR1-M1 and
    RR1-M2, with section 8.13's RR1-m2, and the loan-keyed obligation
    handles the `Alias` program; RR1-m1 is not closed at its root, the
    prelude's `CppCompat` integer impls falling outside the new test
    (RR2-M1).

**Dry judgment and the orchestrator's ruling.** By section 3 step 5 a round is
dry when it has no BLOCKER and no MAJOR and every MINOR is records-only. This
round has a MAJOR, RR2-M1, and RR2-m1 changes the temporal and mutation pages,
so it is not dry, as the review judges it. The orchestrator ruled it
"NOT DRY: 1 serious or 2 page-changing findings go to round 3's fixer". The
round goes back to section 3 step 4, whose budget of three fix commits is spent
(0f281d8bd, e1574b003 and cbdc0552e): step 4 has no shrink line, and "a defect
past the budget stops the workflow at a plan revision of this file", the
review's own reading of RR2-M1's fix ("a plan revision under section 3
step 4"). Round 3's fixer takes RR2-M1 and RR2-m1 under that clause, as the
decisions below record; round 3, the loop's last, then reviews what it
commits, and section 3's steps 6 to 8 wait for a dry round. This round's one
records-only MINOR, RR2-m2, is folded now by this records commit, "SAFE-2
records: focused re-review round 2 recorded" (2026-10-29, the UTC date of its
commit). Each finding was reproduced against the tree at b30c77990, whose line
numbers the table cites, and against upstream at 9192ee003, before it was
dispositioned:

| finding | severity | reproduced | disposition | where |
| --- | --- | --- | --- | --- |
| RR2-M1, RR1-m1's built-in test leaves the prelude's `CppCompat` integer operators neither built in nor user-written | MAJOR | the test (temporal_safety.md:282-299, mutation_safety.md:238-252, the log :3144-3156, fork/safe/plan.md :443-455, D-SAFE2-6 :1475-1490) counts as built in the semantics docs/design/assignment.md:146-157 gives the built-in types (:148, "Integers and floating-point types, `bool`, and pointer types support simple"), with the prelude's impls of those, an aggregate's assignment with no user-written `AssignWith` impl, and the language's own `&`, member access and array indexing; core/prelude/types/cpp/int.carbon at 9192ee003, equal to the fork's, declares its six `CppCompat` integers as classes that adapt an integer (:16-38, amended 2026-10-29, re-review round 3 fold, where this read ":16-37"; `class CppCompat.Long32 {` and `adapt i32;` at :16-17), none a built-in type of :148, and gives them in core/prelude `fn Op(ref self, other: Self) = "int.sadd_assign";` (:1011) and the `Dec` and `Inc` bodies `self -= (1 as CppCompat.Long32);` and `self += (1 as CppCompat.Long32);` (:1179, :1185), impls that are thus neither the prelude's impls of a built-in type nor user-written under temporal_safety.md:301-305's rule; so `p->n += 1` and `++p->n` through `T*` for a C++ `long` field are unclassified, and read as user-written they are M3(d)'s `StrictInvalidatingThroughShared`, rejecting a `Plain` write M3 permits, R1-M1's class; section 8.14's third decision (:3109-3116) names these impls without classifying them | to round 3's fixer, not touched here: the review's remedy, built in by provenance, the language's own operators and every core/prelude impl of an operator interface whatever its body, user-written an impl outside core/prelude, in the same words with a dated mark in the temporal `ref` bindings section, M3, D-SAFE-8 and D-SAFE-9 on the page, in the log and fork/safe/plan.md section 0.3, that plan's section 1.6, D-SAFE2-6 and W-148's notes; a page change past the budget, under section 3 step 4's last clause | section 8.14's third decision, a dated mark |
| RR2-m1, the aggregate clause credits assignment.md:159-161 with more than it says | MINOR, not records-only | upstream's docs/design/assignment.md:159 at 9192ee003 is the heading "Tuples, structs, choice types, and data classes" and :161 reads "_TODO_: Describe the rules for assignment in these cases."; docs/design/classes.md:130-131 there, "Data classes are types that consist of data fields that are publicly accessible and directly read and manipulated by client code", and no array is named; temporal_safety.md:290-293 reads "the assignment of a tuple, struct, array, choice type or class with no user-written `AssignWith` impl, whose rules assignment.md:159-161 leaves a TODO", and mutation_safety.md:243-244, the log :3151-3152, fork/safe/plan.md :450-451, D-SAFE2-6 :1482-1484 and W-148's notes carry the same clause; the widening to arrays and to classes with private fields, `Core.String` among them (core/prelude/types/string.carbon:16-26, `private var ptr: Char*;` and `private var size: i64;`), is section 8.14's third decision, not upstream's text (R32 (a), R10) | to round 3's fixer, not touched here: upstream's heading quoted, and the widening stated as this design's classification with its reason, `Core.String`, in every copy, with a dated mark | section 8.14's third decision, the same dated mark |
| RR2-m2, records number this review round 3, and B.3.8 is left stale | MINOR, records-only | the Status line (:21-23) reads "round 3 reviews it next" and section 8.14's last paragraph (:3195-3196) "round 3, a fresh agent, reviews cbdc0552e and this records commit", while section 3 step 5 has "one fresh agent per round" and section 8.13 hands round 1's findings to "round 2's fixer", whose fold this review reads; section 8.14's first sentence (:3058) has round 2 go back to section 3 step 4, where by step 5 round 1, not dry, does; fork/safe/plan.md's realigned notes (:3001-3004) gained, by b30c77990, "The focused re-review's round 1 found four page defects in that fold, folded by cbdc0552e", while B.3.8 (:7274-7316), which section 8.7's decision amends in place, did not, and section 8.14's pointer list of fifteen blocks does not name it | folded by this records commit: dated marks in the Status line and in section 8.14's first and last paragraphs name this review round 2; B.3.8's block gains the sentence in the file's words and its lead paragraph a dated mark; section 8.14's pointer decision a dated mark that B.3.8 is amended in place; the Sections list names sections 8.14 and 8.15 | Status; Sections; section 8.14; B.3.8 |

Decisions under R29, each with its break condition:

-   This round's ids keep the review's spelling though section 8.10 uses
    RR2-m1 and RR2-m2 for the plan's own round 2: every mark of this round
    reads "re-review round 2" with an RR2 id, every mark of section 8.10
    reads "review fold". Break condition: a reviewer takes one round's
    finding for the other's; this round's ids then gain a prefix by a dated
    mark.
-   Round 3's fixer finds the budget spent. This records commit neither
    revises the plan nor widens the budget, and it does not choose for that
    fixer: it records the orchestrator's ruling and section 3 step 4's last
    clause side by side, the review reading RR2-M1's fold as a plan revision
    under that clause. Break condition: the orchestrator's next
    ruling names another path; this section then gains a dated mark naming
    it.
-   The round of a fold is the round whose review reads it, as section 8.13's
    "round 2's fixer" has it, so section 8.14's heading and the fixer's
    marks, "re-review round 2" with an RR1 id, stay as they are; RR2-m2's
    marks correct the two places that gave this review a later number and,
    beyond the review's list (R17), section 8.14's first sentence, which had
    round 2 go back to section 3 step 4. Break condition: a reviewer reads a
    fold's mark as a round of its own; the marks then name the review's round
    by a dated mark.
-   B.3.8 is amended in place rather than added to section 8.14's pointer
    list: section 8.7's decision names it among the blocks amended in place,
    and the pointer list is for blocks whose targets a fix commit changed,
    where B.3.8's was changed by the records commit b30c77990. Break
    condition: a reviewer needs B.3.8 kept as commit 2's text; the sentence
    then moves to a dated pointer to this section.
-   fork/safe/plan.md's realigned notes, the log and W-148's notes are not
    changed: they state the folds made, and this round's two page findings
    are not folded yet; round 3's fixer amends every copy with its fold, in
    the same words (R27). Break condition: a reviewer finds a record stating
    RR1-m1's test as closed at its root; that line then gains a dated mark
    pointing here.

**Measured** by this records commit, 2026-10-29, in rec2/:

-   `git -C /home/user/carbon-lang fetch -q upstream trunk` gives 9192ee003
    again (2026-10-28 20:51:45 UTC, upstream PR 8054), the review's tip;
    `git log 9192ee003..upstream/trunk` lists nothing, and `git log
    c1e83b0b7..9192ee003` over section 0.1's nine files,
    docs/design/assignment.md, docs/design/expressions/indexing.md and
    core/prelude/types/int.carbon, uint.carbon, cpp/int.carbon and
    string.carbon lists only f21c62524 (classes.md); the fork's
    assignment.md and those four prelude files equal upstream's there.
    Section 0.1's quotes read at the tip as before, among them p005434:83,
    :660-669 and :831-835, p005914:85-88, p000257:355-358,
    docs/design/README.md:2130-2132, docs/design/safety/README.md:260-262
    and docs/design/expressions/arithmetic.md:171-173.
-   PR 67's checks, from a detached worktree of 56e2e5bbd at
    /dev/shm/safe2-rec2/rg1, removed after, against /home/user/carbon-lang
    at 9192ee003: "checked 273 quotes, 0 failed" and "checked 89 silence
    checks, 0 failed"; the H1 subsets, byte-equal to the review's,
    "checked 97 quotes, 0 failed", "checked 120 quotes, 0 failed" and
    "checked 5 silence checks, 0 failed"; the document-review fold's nine
    quotes and the sixteen of round 2's fixer, "checked 9 quotes, 0 failed"
    and "checked 16 quotes, 0 failed"; and the thirteen upstream lines this
    round cites (docs/design/assignment.md:148, :159 and :161,
    docs/design/classes.md:128 and :130, core/prelude/types/cpp/int.carbon:16,
    :17, :37, :1011, :1179 and :1185, string.carbon:23 and :25), "checked 13
    quotes, 0 failed".
-   `git ls-remote origin`: trunk 1c83422a0 and the 18 held heads as the
    table of section 0.8 names them, PR 53's pushed head still 2407efa74.
-   The id re-scan widened to W-3[6-9][0-9] over the 165 origin refs and
    local branches and the 22 worktrees: the ledgers end at W-363, the text
    names W-360 to W-365, W-398 and W-399 as before, and W-365 only in this
    file; no id is taken, no residue is filed and no F id is minted.
-   B.3.8's block, with its placeholders filled as fork/safe/plan.md fills
    them, equals that file's realigned notes, line breaks aside.
-   R31 on this plan, the one file this commit changes: before, headings
    {1: 1, 2: 16, 3: 128}, bullets 133, numbered 31, rows 208, 7665 lines;
    after, headings {1: 1, 2: 16, 3: 129}, bullets 155, numbered 31, and
    rows 213, the same after the edit and after each prek pass, in 7860
    lines; the changes are this section's heading, its 22 bullets and its
    five table rows, with no unguarded block.
-   prek to a fixpoint with a private cache, deleted after: its first pass
    reflowed, under rumdl's MD013, section 8.14's first paragraph, which a
    mark of this commit lengthens, and this section's first paragraph, each
    holding a scratch path longer than a line, the word diff empty; the
    later passes exit 0 with no change. rumdl@0.2.58: no issues; the heading
    sets differ by this section's heading alone, and the
    manufactured-heading grep is empty.
-   `runner.py --self-test`: "150 programs parsed, 56 bullets in table, OK".
    The model-name grep over this plan's changed lines and the message: no
    hit outside the trailers.
-   The merge-tree of the new head against trunk and the 18 held heads: the
    sets of section 0.8's table, unchanged.

No page, example, log, fork/safe/plan.md or ledger line changes, so the
nightly compiles of section 0.7 are not re-run and the ledger's `json.load` is
not owed; nothing is pushed (section 3 step 7 waits for a dry round).

### §8.16 Stop-and-amend record (rev 8, 2026-10-29)

Round 3's fixer, one fresh agent, took round 2's two findings that are serious
or change a page, RR2-M1 and RR2-m1 (section 8.15), and reproduced each against
the tree at 4e40e74d8, this plan and upstream's tip, re-fetched as 9192ee003
(2026-10-28 20:51:45 UTC, upstream PR 8054, the tip of sections 8.13 to 8.15).
Both are ACCEPTED and none is rejected. Each needs a change of
docs/design/safety/temporal_safety.md and mutation_safety.md, and section 3 step
4's budget of three fix commits is spent by 0f281d8bd, e1574b003 and cbdc0552e.
Step 4 has no shrink line: "a defect past the budget stops the workflow at a
plan revision of this file". Rev 8 is that revision. It makes no fix commit,
changes no page, record, ledger line or Appendix A to D text, and does not widen
the budget; it re-plans the defect at its root and gives below the texts of the
one fold commit that answers both findings, for the orchestrator to rule on
(section 3 step 4's dated mark). The scratch is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2-rr/r3/fixer/.
Everything measured is container-local, EXPECTED, not of record (R9).

**The defect**, with line numbers at 4e40e74d8:

| finding | severity | reproduced | root |
| --- | --- | --- | --- |
| RR2-M1, the built-in test leaves the prelude's `CppCompat` integer operators neither built in nor user-written | MAJOR | the test (temporal_safety.md:282-299) counts as built in `the semantics the [assignment](../assignment.md#built-in-types) design states`, which docs/design/assignment.md:148 at 9192ee003 gives "Integers and floating-point types, `bool`, and pointer types", with "the prelude's impls of those"; core/prelude/types/cpp/int.carbon, equal to upstream's there, declares `class CppCompat.Long32 {` with `adapt i32;` (:16-17) and five more classes that adapt an integer (:20-38), to which upstream's toolchain/check/cpp/import.cpp:1235-1260 maps C++'s `long`, `unsigned long`, `long long` and `unsigned long long`, and gives them thirty compound assignments with builtin bodies, `fn Op(ref self, other: Self) = "int.sadd_assign";` at :1011 among them, and six `Inc` and `Dec` impls, `self += (1 as CppCompat.Long32);` at :1185 among them; a class is no type of :148, and a core/prelude impl is not user-written (temporal_safety.md:301-305), so `q->m += 1` and `++q->m` for `q: T*` and a field `m` of C++ `long` type fell in no class, and read as user-written they are M3(d)'s `StrictInvalidatingThroughShared`, rejecting a `Plain` write M3 permits, R1-M1's class | the test names types and their semantics, while what it rests on, that the operand's `ref` lives for the one operation with nothing user-written evaluated while it does, follows from where the implementation is written; each list of types leaves the next prelude type out, `Inc` and `Dec` in RR1-m1, the `CppCompat` integers here |
| RR2-m1, the aggregate clause credits assignment.md:159-161 with more than it says | MINOR, not records-only | upstream's docs/design/assignment.md:159 at 9192ee003 is "## Tuples, structs, choice types, and data classes" and :161 "_TODO_: Describe the rules for assignment in these cases."; docs/design/classes.md:130 there begins "Data classes are types that consist of data fields that are publicly accessible"; no array is named; temporal_safety.md:290-293, mutation_safety.md:243-244, the log :3150-3152, fork/safe/plan.md :449-451, D-SAFE2-6 (this plan :1490-1492 at 4e40e74d8) and W-148's notes credit :159-161 with "a tuple, struct, array, choice type or class" | the clause states this design's widening, to arrays and to classes that are not data classes, `Core.String` among them (core/prelude/types/string.carbon:16-26), as upstream's text (R32 (a)) |

**The re-planned test: built in by where it is written.** An operator's
implementation is built in when it is the language's own, `=` on a type with no
`AssignWith` impl, `&`, member access naming a field or indexing of an array,
or an impl of an operator interface written in core/prelude, whatever its body
and whichever type it is for; it is user-written when it is written outside
core/prelude. The ground of the exception, that the operand's `ref` lives for
the one operation with nothing user-written evaluated while it does, holds of
every such prelude impl that takes a `ref` operand, at 9192ee003 and in the
fork alike. There are 64, all for `Int`, `UInt`, `Float` or a `CppCompat`
integer (`ref self` in core/prelude/types/int.carbon 12 times, uint.carbon 12,
float.carbon 4 and cpp/int.carbon 36). Of these, 54 have a builtin body, and
the other ten, the `Inc` and `Dec` of `Int` and `UInt` (int.carbon:384-399,
uint.carbon:446-461) and of the three signed `CppCompat` integers
(cpp/int.carbon:1177-1215), are a `self += ...;` or `self -= ...;` of a
prelude conversion of `1`. The `ref self` impls of `Destroy`
(core/prelude/destroy.carbon, types/buf.carbon:58-59) are no operator
interface's, and the test leaves them as they are. The prelude's bodies are
trusted (S0, safety/README.md:117-139), so the claim is the prelude's to keep,
under W-144's audit. The aggregate clause becomes the language's own `=` on a
type with no `AssignWith` impl: assignment.md:148 names the scalars and
pointers, and :159's heading the tuples, structs, choice types and data
classes, whose rules :161 leaves a TODO; counting an array and a class that is
not a data class too is this design's classification, said so in every copy,
because such an assignment runs no user-written code, and `Core.String`, whose
fields are private (string.carbon:23 and :25, `private var ptr: Char*;` and
`private var size: i64;`) and which no prelude impl gives `AssignWith`, would
otherwise be neither built in nor user-written, RR2-M1's gap for another
prelude type. No classification other than the `CppCompat` impls' moves: what
cbdc0552e's test made built in stays built in, since core/prelude has no
`AssignWith` impl and no other impl of an operator interface that takes a
`ref` operand, and `*q = "longer"` for `q: str*` stays
`StrictSharedImmutableWrite` under M3's `Core.SharedImmutable` rule, which the
test does not decide.

Decisions under R29, each with its break condition:

-   Built in by where it is written, the review's remedy, over adding the
    `CppCompat` integers to the list of types, a wording patch that leaves the
    next prelude type out (R17), and over reading their impls as user-written,
    which rejects a `Plain` write M3 permits, R1-M1's class. Break condition:
    a core/prelude impl of an operator interface whose body, while its `ref`
    operand is bound, evaluates a user-written impl, a blanket impl over a
    type parameter that a user's type fills, say; that impl then counts as
    user-written for this test by a dated mark.
-   The aggregate clause keeps its reach, arrays and classes that are not data
    classes included, and says it is this design's, over narrowing it to
    upstream's heading, which would leave `Core.String`'s `=` unclassified.
    Break condition: section 8.14's, upstream answers assignment.md:161's TODO
    or routes `=` through `AssignWith` for a type the clause calls the
    language's own; the clause then follows upstream by a dated mark.
-   The fold is one commit, past the budget, made only on the orchestrator's
    ruling; this revision neither makes it nor files a residue for it. Break
    condition: the ruling keeps the fold out of SAFE-2; this section then
    gains a dated mark naming the ruling, and W-365, the next free id, is
    filed for the fold by a records commit.
-   D-SAFE2-6 and every other copy keep their text until the fold commit,
    D-SAFE2-6 carrying a dated pointer here, so that this plan's section 1 and
    the pages state the same test at every commit (R27). Break condition: a
    reviewer requires section 1 to state the re-planned test first; D-SAFE2-6
    then takes block E4 by a records commit with a dated mark.
-   The four sentences that only use the term, "A built-in operator's `ref`
    operand, an assignment's among them, lives for the one operation and is
    established on any place", in safety/README.md:460-463, the temporal
    kinds paragraph (:189-192), mutation M1 (:174-176) and fork/safe/plan.md
    section 1.5 (:1580-1583), state no test and point to the `ref` bindings
    section, which holds it, so they are left as they are; the copies the
    review lists, D-SAFE-8 and D-SAFE-9 on the pages, in the log and in
    section 0.3, and section 1.6, take E3 or E5. Break condition: a reviewer
    reads one of the four as stating the type-based test; it then takes E5's
    clause.

**The fold commit.** "SAFE-2 fix: the built-in test by where an implementation
is written and the aggregate clause as this design's classification (RR2-M1,
RR2-m1)", with `<date>` its UTC date, applies E1 to E6 below and changes
nothing else. Each anchor is quoted as section 2.1's test reads it, line breaks
and indentation aside. Expected: no heading, bullet, numbered item or table row
moves on any file it touches, so section 8 item 1's deltas stand; it touches
the files cbdc0552e touched but type_safety.md and safety/README.md, so the
merge-tree sets of section 0.8 stand; no example changes, and the nightly
outcomes of section 0.7 are re-run as section 8 item 4 asks; the log's
D-SAFE block stays identical to fork/safe/plan.md section 0.3. The records
commit after it writes its hash into `<fixes>` (section 8.13's placeholder
row), fork/safe/plan.md's realigned notes and B.3.8 by dated marks, and
records the review of it that the ruling names.

E1, docs/design/safety/temporal_safety.md, `ref` bindings: replace from "An
implementation is built in when it gives a built-in type the semantics the"
through the end of the RR1-m1 mark that follows it, "and the mutation page's
M3 alone decides")", with:

<!-- google-doc-style-ignore -->

```markdown
An implementation is built in by where it is written, not by the type it
serves: it is built in when it is the language's own, `=` on a type with no
`AssignWith` impl, `&`, member access naming a field or indexing of an array,
or an impl of an operator interface written in core/prelude, whatever its body
and whichever type it is for, and it is user-written when it is written outside
core/prelude. Each such prelude impl that takes a `ref` operand has a builtin
body or one that calls only the prelude's own impls, so nothing user-written is
evaluated while its `ref` lives: the impls "provided for built-in types as
necessary to give the semantics described above" (assignment.md:168-170), the
builtin `"int.sadd_assign"` (core/prelude/types/int.carbon:331) and `Inc`'s
`self += AsInt(1);` (int.carbon:395-399, uint.carbon:457-461) among them, as
much as the same impls of the `CppCompat` integers, classes that adapt an
integer (core/prelude/types/cpp/int.carbon:16-38), `"int.sadd_assign"` again
(:1011) and `Inc`'s `self += (1 as CppCompat.Long32);` (:1183-1187). The
[assignment](../assignment.md#built-in-types) design gives
`=` to "Integers and floating-point types, `bool`, and pointer types"
(assignment.md:148), and its next section, "Tuples, structs, choice types, and
data classes" (assignment.md:159), leaves its rules a TODO (:161); counting as
the language's own the assignment of every other type with no `AssignWith`
impl, an array or a class that is not a data class among them, is this
design's classification, not that section's text: such an assignment runs no
user-written code, and `Core.String`, a class whose fields are private
(core/prelude/types/string.carbon:16-26) and which has no `AssignWith` impl,
would otherwise be neither built in nor user-written (amended 2026-10-29,
re-review round 2: RR1-m1, where this read "Where the operator's implementation
is built in, the language's own or a prelude impl whose body is a builtin, such
as `fn Op(ref self, other: Self) = "int.sadd_assign";`
(core/prelude/types/int.carbon:331), that `ref` lives for the one operation"
and "the checker establishes it with no marker, and the mutation page's M3
alone decides"; amended <date>, re-review round 3: RR2-M1, RR2-m1, where this
read "An implementation is built in when it gives a built-in type the
semantics the [assignment](../assignment.md#built-in-types) design states, `=`
on integers, floating-point types, `bool` and pointers, compound assignment on
integers and floating-point types, and `++` and `--` on integers
(assignment.md:146-157), the prelude's impls of those, "provided for built-in
types as necessary to give the semantics described above"
(assignment.md:168-170), counting as built in whatever their body, `Inc`'s
`self += AsInt(1);` (core/prelude/types/int.carbon:395-399, uint.carbon:457-461)
as much as `fn Op(ref self, other: Self) = "int.sadd_assign";`
(int.carbon:331); when it is the assignment of a tuple, struct, array, choice
type or class with no user-written `AssignWith` impl, whose rules
assignment.md:159-161 leaves a TODO; and when it is the language's own `&`,
member access naming a field or indexing of an array")
```

<!-- google-doc-style-resume -->

E2, docs/design/safety/mutation_safety.md, M3: replace "the semantics the
assignment design gives a built-in type with the prelude's impls of them
whatever their body, an assignment of a tuple, struct, array, choice type or
class with no user-written `AssignWith` impl, `&`, member access naming a field
or indexing of an array:" with the first block, and from "while the call of a
user-written impl's `ref self` is (d)'s" through the end of the RR1-m1 mark that
follows it, "and (a) to (c)")", with the second:

<!-- google-doc-style-ignore -->

```markdown
the language's own, `=` on a type with no `AssignWith` impl, `&`, member
access naming a field or indexing of an array, or an impl of an operator
interface written in core/prelude whatever its body and whichever type it is
for, the `CppCompat` integers' as much as `Int`'s, the assignment of an array
or of a class that is not a data class counting as the language's own by this
design's classification and not by the assignment design's "Tuples, structs,
choice types, and data classes" (assignment.md:159):
```

```markdown
while the call of a user-written impl's `ref self`, an impl written outside
core/prelude, is (d)'s (amended 2026-10-28, document-review fold: R1-M1;
amended 2026-10-29, re-review round 2: RR1-m1, where this read "the language's
own or a prelude impl whose body is a builtin: the temporal page's
[`ref` bindings](temporal_safety.md#ref-bindings) establish its operand for the
one operation, and (a) to (c)"; amended <date>, re-review round 3: RR2-M1,
RR2-m1, where this read "the semantics the assignment design gives a built-in
type with the prelude's impls of them whatever their body, an assignment of a
tuple, struct, array, choice type or class with no user-written `AssignWith`
impl, `&`, member access naming a field or indexing of an array" and "while the
call of a user-written impl's `ref self` is (d)'s")
```

<!-- google-doc-style-resume -->

E3, fork/decision-log.md D-SAFE-8 and fork/safe/plan.md section 0.3's, the
same words in both: replace from "Built in is the semantics
assignment.md:146-157" through the end of the RR1-m1 mark that follows it, "and
D-SAFE-9's M3 alone decides")", with:

<!-- google-doc-style-ignore -->

```markdown
    Built in is decided by where an implementation is written, not by the
    type it serves: the language's own, `=` on a type with no `AssignWith`
    impl, `&`, member access naming a field and indexing of an array, and
    every impl of an operator interface written in core/prelude whatever its
    body and whichever type it is for, each of those that takes a `ref`
    operand having a builtin body or one that calls only the prelude's own
    impls (the impls :168-170 says are "provided for built-in types as
    necessary to give the semantics described above", int.carbon:331's
    `"int.sadd_assign"` and :395-399's `Inc` as much as cpp/int.carbon:1011's
    `"int.sadd_assign"` and :1183-1187's `Inc` for the `CppCompat` integers,
    classes that adapt an integer, :16-38); an impl written outside
    core/prelude is user-written. assignment.md:148 gives `=` to "Integers
    and floating-point types, `bool`, and pointer types" and :159-161 leaves
    "Tuples, structs, choice types, and data classes" a TODO; counting as the
    language's own the assignment of an array or of a class that is not a
    data class is this design's classification, not that section's text: it
    runs no user-written code, and `Core.String`, whose fields are private
    (string.carbon:16-26) and which has no `AssignWith` impl, would otherwise
    be neither built in nor user-written (amended 2026-10-29, re-review
    round 2: RR1-m1, where this read "where the implementation is the
    language's own or a prelude impl whose body is a builtin (int.carbon:331's
    `"int.sadd_assign"`) it is established on any place, open ones included,
    and D-SAFE-9's M3 alone decides"; amended <date>, re-review round 3:
    RR2-M1, RR2-m1, where this read "Built in is the semantics
    assignment.md:146-157 gives the built-in types, `=` on integers,
    floating-point types, `bool` and pointers, compound assignment on
    integers and floating-point types, and `++` and `--` on integers, the
    prelude's impls of them counting as built in whatever their body (the
    impls :168-170 says are "provided for built-in types as necessary to give
    the semantics described above"; int.carbon:395-399's `Inc` as much as
    :331's `"int.sadd_assign"`); the assignment of a tuple, struct, array,
    choice type or class with no user-written `AssignWith` impl
    (assignment.md:159-161, a TODO upstream); and the language's own `&`,
    member access naming a field and indexing of an array")
```

<!-- google-doc-style-resume -->

E4, this plan's D-SAFE2-6: replace from "Built in is the semantics
docs/design/assignment.md:146-157" through "while `p->n += 1` was built in)."
and the rev 8 pointer after it with:

<!-- google-doc-style-ignore -->

```markdown
    Built in is decided by where an implementation is written, not by the
    type it serves: the language's own, `=` on a type with no `AssignWith`
    impl, `&`, member access naming a field and indexing of an array, and
    every impl of an operator interface written in core/prelude whatever its
    body and whichever type it is for, each of those that takes a `ref`
    operand having a builtin body or one that calls only the prelude's own
    impls (the impls docs/design/assignment.md:168-170 says are "provided for
    built-in types as necessary to give the semantics described above",
    core/prelude/types/int.carbon:331's `"int.sadd_assign"` and :395-399's
    `Inc` as much as core/prelude/types/cpp/int.carbon:1011's
    `"int.sadd_assign"` and :1183-1187's `Inc` for the `CppCompat` integers,
    classes that adapt an integer, :16-38); an impl written outside
    core/prelude is user-written. docs/design/assignment.md:148 gives `=` to
    "Integers and floating-point types, `bool`, and pointer types" and
    :159-161 leaves "Tuples, structs, choice types, and data classes" a TODO;
    counting as the language's own the assignment of an array or of a class
    that is not a data class is this design's classification, not that
    section's text: it runs no user-written code, and `Core.String`, whose
    fields are private (core/prelude/types/string.carbon:16-26) and which has
    no `AssignWith` impl, would otherwise be neither built in nor
    user-written (amended 2026-10-29, re-review round 2: RR1-m1, where this
    read "where the implementation is the language's own or a prelude impl
    whose body is a builtin it is established on any place, open ones
    included, and M3 alone decides": `++p->n` through `T*` was neither built
    in nor user-written, `Inc`'s body `self += AsInt(1);` being no builtin,
    while `p->n += 1` was built in; amended <date>, re-review round 3:
    RR2-M1, RR2-m1, where this read "Built in is the semantics
    docs/design/assignment.md:146-157 gives the built-in types, `=` on
    integers, floating-point types, `bool` and pointers, compound assignment
    on integers and floating-point types, and `++` and `--` on integers, the
    prelude's impls of them counting as built in whatever their body (the
    impls :168-170 says are "provided for built-in types as necessary to give
    the semantics described above"; core/prelude/types/int.carbon:395-399's
    `Inc` as much as :331's `"int.sadd_assign"`); the assignment of a tuple,
    struct, array, choice type or class with no user-written `AssignWith`
    impl (assignment.md:159-161, a TODO upstream); and the language's own
    `&`, member access naming a field and indexing of an array": `q->m += 1`
    and `++q->m` for a field `m` of a `CppCompat` integer type, C++'s `long`
    among them, were neither built in nor user-written, and the aggregate
    clause credited assignment.md:159-161 with arrays and every class).
```

<!-- google-doc-style-resume -->

E5, the decision copies the review lists: right after "a built-in operator's
`ref` operand", capitalized or not, insert the clause below, before the comma
that follows it in the temporal page's D-SAFE-8 bullet (:1442 at 4e40e74d8),
the mutation page's D-SAFE-9 bullet (:1319-1320), the log's D-SAFE-9 (:3240)
and fork/safe/plan.md section 0.3's (:539), and with a comma after it in
fork/safe/plan.md section 1.6 (:1611), where "being classified" follows:

<!-- google-doc-style-ignore -->

```markdown
, built in meaning the language's own or one written in core/prelude (added
<date>, re-review round 3: RR2-M1)
```

<!-- google-doc-style-resume -->

E6, fork/inventory/work-items.json, W-148: append to its `notes` string, after
a space:

<!-- google-doc-style-ignore -->

```text
SAFE-2 focused re-review, round 3 (<date>; RR2-M1, RR2-m1): superseding the previous note's list of the built-in operators, an operator's implementation is built in by where it is written, the language's own (`=` on a type with no `AssignWith` impl, `&`, member access naming a field, indexing of an array) or an impl of an operator interface written in core/prelude whatever its body and whichever type it is for, the `CppCompat` integers' as much as `Int`'s, and user-written when written outside core/prelude; counting the assignment of an array or of a class that is not a data class as the language's own is this design's classification beside docs/design/assignment.md:159's "Tuples, structs, choice types, and data classes", not that section's text.
```

<!-- google-doc-style-resume -->

**Measured** by rev 8, 2026-10-29, logs in the scratch's logs/:

-   `git -C /home/user/carbon-lang fetch -q upstream trunk` gives 9192ee003
    again; `git log 9192ee003..upstream/trunk` lists nothing, and `git log
    c1e83b0b7..9192ee003` over section 0.1's nine files,
    docs/design/assignment.md, docs/design/expressions/indexing.md and
    core/prelude/types/int.carbon, uint.carbon, float.carbon, cpp/int.carbon,
    string.carbon and operators/arithmetic.carbon lists only f21c62524
    (classes.md); the fork's assignment.md and those six prelude files and
    operators/bitwise.carbon equal upstream's there. Section 0.1's quotes and
    the lines this section cites read at the tip as quoted.
-   PR 67's checks, from a detached worktree of 56e2e5bbd at
    /dev/shm/safe2-r3fixer/rg1, removed after, against /home/user/carbon-lang
    at 9192ee003: "checked 273 quotes, 0 failed" and "checked 89 silence
    checks, 0 failed"; the H1 subsets, byte-equal to rounds 1 and 2's,
    "checked 97 quotes, 0 failed", "checked 120 quotes, 0 failed" and
    "checked 5 silence checks, 0 failed" (H1.1, H1.3, H1.4, H1.7, H1.15);
    round 2's thirteen lines, "checked 13 quotes, 0 failed"; and the twenty
    upstream lines this section cites (docs/design/assignment.md:148, :159,
    :161 and :170, docs/design/classes.md:128 and :130,
    core/prelude/types/cpp/int.carbon:16, :17, :1011, :1183 and :1185,
    int.carbon:331, :395 and :398, uint.carbon:460, string.carbon:23 and :25,
    toolchain/check/cpp/import.cpp:1235, :1240 and :1253), "checked 20
    quotes, 0 failed".
-   `git ls-remote origin`: trunk 1c83422a0 and the 18 held heads as section
    0.8's table names them, PR 53's pushed head still 2407efa74.
-   A dry run of the fold (bin/dryrun.py) applied E1 to E6 to scratch copies
    of the six files at 4e40e74d8: each anchor is found once, each round 3
    quote equals the text it replaces once whitespace is set aside, each
    RR1-m1 mark is kept, the ledger parses with `json.load`, and the log's
    D-SAFE-1 to D-SAFE-23 block, 1203 lines, is identical to fork/safe/plan.md
    section 0.3; after two `rumdl@0.2.58 check --fix` passes no MD013 issue is
    left, no line starts with `+`, `#NN` or a digit and a period that did not
    before, and the R31 counts of temporal_safety.md, mutation_safety.md, the
    log and fork/safe/plan.md equal 4e40e74d8's (lines 1607 to 1632, 1511 to
    1519, 8284 to 8296, 3010 to 3022).
-   The id re-scan widened to W-3[6-9][0-9] over the 165 origin refs and
    local branches and the 23 worktrees, this fixer's /dev/shm one among
    them: the ledgers end at W-363, the text names W-360 to W-365, W-398 and
    W-399 as before, and W-365 only in this file; no id is taken, no residue
    is filed and no F id is minted.
-   R31 on this plan, the one file rev 8 changes: before, headings {1: 1, 2:
    16, 3: 129}, bullets 155, numbered 31, rows 213, 7860 lines; after,
    headings {1: 1, 2: 16, 3: 130}, bullets 168, numbered 31, rows 217,
    8287 lines, the same after the edit and after each prek pass; the
    changes are this section's heading, its thirteen bullets, its four table
    rows and its seven fenced blocks, each guarded.
-   prek to a fixpoint with a private cache, deleted after: its first pass
    reflowed, under rumdl's MD013, the Status paragraph, which rev 8's mark
    lengthens, and this section's first paragraph, which holds a scratch path
    longer than a line, the word diff empty, and its second pass exits 0 with
    no change; rumdl@0.2.58: no issues; the heading sets differ by this
    section's heading alone, and the manufactured-heading grep is empty.
-   `runner.py --self-test`: "150 programs parsed, 56 bullets in table, OK".
    The model-name grep over this plan's changed lines and the message: no
    hit outside the trailers and the scratch path. The merge-tree of the new
    tree against trunk and the 18 held heads: the sets of section 0.8's
    table, unchanged.

No page, example, log, fork/safe/plan.md or ledger line changes, so the
nightly compiles of section 0.7 are not re-run and the ledger's `json.load` is
not owed; nothing is pushed (section 3 step 7 waits for a dry round).

### §8.17 Focused re-review fold record, round 3 (2026-10-29)

Round 2 of section 3 step 5's loop, not dry, went back to section 3 step 4, as
the orchestrator's ruling recorded in section 8.15 has it: one fresh fixer, the
fixer of round 3, took round 2's two findings that are serious or change a page,
RR2-M1 and RR2-m1, reproduced each against the tree at 4e40e74d8, this plan and
upstream's tip, re-fetched as 9192ee003, and dispositioned it. Both are ACCEPTED
and none is rejected, and neither is folded on a page: the budget of three fix
commits is spent (0f281d8bd, e1574b003 and cbdc0552e), and step 4 has no shrink
line. The fixer made the plan revision that step 4's last clause names,
1f9d0a16f, "SAFE-2 plan (rev 8): focused re-review fold: the built-in test names
types and misattributes its aggregate clause, re-planned at its root", whose
section 8.16, the stop-and-amend record, re-plans both findings at their root
and gives the texts of the one fold commit that answers them; this records
commit, "SAFE-2 records: focused re-review round 3 fold", which is not counted,
records the round. The budget is exceeded, and the orchestrator rules on the
fold commit; round 3, the loop's last, reviews 1f9d0a16f and this commit. Round
2's one records-only MINOR, RR2-m2, was folded by round 2's records commit
4e40e74d8; rev 8 touches two of the places its marks are in, the Status line and
section 8.14's third decision, and both of RR2-m2's marks stand there as
written. The scratch is
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe2-rr/r3/fixer/.
Everything measured is container-local, EXPECTED, not of record (R9).

| finding | severity | reproduced at 4e40e74d8 and 9192ee003 | disposition | where |
| --- | --- | --- | --- | --- |
| RR2-M1, RR1-m1's built-in test leaves the prelude's `CppCompat` integer operators neither built in nor user-written | MAJOR | reproduced as section 8.16's table states it: docs/design/assignment.md:148's built-in types are "Integers and floating-point types, `bool`, and pointer types"; `class CppCompat.Long32 {` and `adapt i32;` (core/prelude/types/cpp/int.carbon:16-17), one of six such classes (:16-38), and its `"int.sadd_assign"` (:1011) and `self += (1 as CppCompat.Long32);` (:1185) are core/prelude impls of a class, so neither clause of temporal_safety.md:282-305 classes them; upstream's toolchain/check/cpp/import.cpp:1235-1260 maps C++'s `long` and `long long` to them | ACCEPTED, not folded: past the budget; re-planned by rev 8 at its root, built in by where an implementation is written (section 8.16, blocks E1 to E6), for one fold commit on the orchestrator's ruling | 1f9d0a16f: section 8.16; dated marks in the Status line, the Sections list, D-SAFE2-6 (a pointer), section 3 steps 4 and 5, section 8.7's R1-M1 decision, section 8.14's third decision and the Sign-off |
| RR2-m1, the aggregate clause credits assignment.md:159-161 with more than it says | MINOR, not records-only | reproduced as section 8.16's table states it: assignment.md:159 is "## Tuples, structs, choice types, and data classes" and :161 "_TODO_: Describe the rules for assignment in these cases."; classes.md:130's data classes have publicly accessible fields; the six copies credit :159-161 with "a tuple, struct, array, choice type or class" | ACCEPTED, not folded: a page change past the budget; re-planned by rev 8: upstream's heading quoted, the reach to arrays and to classes that are not data classes stated as this design's classification with its reason, `Core.String` (string.carbon:16-26), in every copy | 1f9d0a16f: section 8.16, blocks E1 to E4 and E6; the same marks |

Decisions under R29, each with its break condition:

-   Two commits, the plan revision and then this records commit, rather than
    one: rev 8 holds the re-plan and its stop-and-amend record, and this
    section names rev 8's hash, which rev 8 cannot hold. Break condition: the
    orchestrator wants the round in one commit; the next records commit then
    says so by a dated mark.
-   Section 8.15's RR2-M1 row gives the `CppCompat` classes as ":16-37",
    where they span :16-38, the sixth class's closing brace being :38; the
    row gains a dated mark. Break condition: none; a cite is exact or marked
    (R10).
-   No residue is filed: the fold is planned, not dropped, and W-365, the next
    free id, stays free. Break condition: section 8.16's third decision, the
    ruling keeps the fold out of SAFE-2.
-   `<fixes>` (section 8.13's placeholder row) stays 0f281d8bd, e1574b003 and
    cbdc0552e, since this round makes no fix commit. Break condition: section
    8.14's last decision, a later fix commit, which then joins the list.

**Measured** by this records commit, 2026-10-29, logs in the scratch's logs/:

-   `git -C /home/user/carbon-lang fetch -q upstream trunk` gives 9192ee003,
    as for rev 8; `git log 9192ee003..upstream/trunk` lists nothing.
-   `git ls-remote origin`: trunk 1c83422a0 and the 18 held heads as section
    0.8's table names them, PR 53's pushed head still 2407efa74.
-   R31 on this plan, the one file this commit changes: before, headings
    {1: 1, 2: 16, 3: 130}, bullets 168, numbered 31, rows 217, 8287 lines;
    after, headings {1: 1, 2: 16, 3: 131}, bullets 177, numbered 31, rows
    221, 8366 lines, the same after the edit and after each prek pass; the
    changes are this section's heading, its nine bullets and its four table
    rows, with no unguarded block.
-   prek to a fixpoint with a private cache, deleted after: its first pass
    reflowed, under rumdl's MD013, the Status paragraph, which this commit's
    mark lengthens, and this section's first paragraph, which holds a scratch
    path longer than a line, the word diff empty, and its second pass exits
    0 with no change; rumdl@0.2.58: no issues; the heading sets differ by
    this section's heading alone, and the manufactured-heading grep is empty.
-   `runner.py --self-test`: "150 programs parsed, 56 bullets in table, OK".
    The model-name grep over this plan's changed lines and the message: no
    hit outside the trailers and the scratch path. The merge-tree of the new
    tree against trunk and the 18 held heads: the sets of section 0.8's
    table, unchanged. The id re-scan of section 8.16 stands: no ledger
    changed since.

No page, example, log, fork/safe/plan.md or ledger line changes, so the
nightly compiles of section 0.7 are not re-run and the ledger's `json.load` is
not owed; nothing is pushed (section 3 step 7 waits for a dry round).

## Sign-off

Every review of this plan, with its verdict and its counts (added 2026-10-28,
review fold: RR3-M1, RR3-m1, RR3-m2):

| review | read | verdict | BLOCKER | MAJOR | MINOR | folded | rejected | fold |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A: design fidelity and soundness | rev 1, 475b7ecb0 | REJECT | 2 | 2 | 4 | 8 | none | rev 2, 46980f8bd, §8.8 |
| B: records, consistency and R31 | rev 1, 475b7ecb0 | APPROVE-WITH-AMENDMENTS | 0 | 6 | 7 | 13 | none | rev 2, 46980f8bd, §8.8 |
| RR1: the focused re-review, round 1 | rev 2, 46980f8bd | REJECT | 1 | 1 | 4 | 6 | none | rev 3, 603749ee1, §8.9 |
| RR2: the focused re-review, round 2 | rev 3, 603749ee1 | REJECT | 1 | 0 | 3 | 4 | none | rev 4, 9d48a863e, §8.10 |
| RR3: the focused re-review, round 3 | rev 4, 9d48a863e | APPROVE-WITH-AMENDMENTS | 0 | 1 | 2 | 3 | none | rev 5, 4ca369e38, §8.11 |
| AM6: the focused re-review of the stop-and-amend | rev 6, 486d2bc74 | APPROVE-WITH-AMENDMENTS | 0 | 1 | 1 | 2 | none | rev 7, §8.12 |

The five reviews before the implementation raised 34 findings, 4 BLOCKERs, 10
MAJORs and 20 MINORs; all 34 are folded and none is rejected. RR3, the last of
them, found no BLOCKER and
its verdict is not REJECT, so rev 5 is SIGNED OFF FOR IMPLEMENTATION on
2026-10-28. Its one MAJOR fold adds no rule: it applies the trusted-body rule
of rev 4, which RR3 traced and accepted, to PR 65's `Ref`, in the words W-144
already uses for `IndexWith.At`. The implementation started from rev 5's
commit with section 3's commit 1; its two document reviews and the focused
re-review of section 3 steps 3 to 5 follow.

Rev 6, 2026-10-28, is a stop-and-amend of rev 5, not a review fold (see
section 8.12): it restores three links in two superseded quotes, corrects two
line ranges and A.10.2's line count, and states the byte-equality test the
quotes meet. It changes no rule, example, diagnostic, Appendix B to D text,
count of section 8 item 1 or merge-tree set, so rev 5's sign-off stands for
every text rev 6 leaves as it was; the focused re-review of the
amendment comes next, and the implementation resumes from rev 6's commit
with section 3's commit 1 once it finds no BLOCKER (amended 2026-10-28,
implementation: stop-and-amend: link markup in two superseded quotes).

Rev 7, 2026-10-28, folds that focused re-review, AM6 in the table, which
found no BLOCKER: its MAJOR and its MINOR are folded and none is rejected, so
the six reviews of this plan raised 36 findings, 4 BLOCKERs, 11 MAJORs and 21
MINORs, all folded. The fold changes section 2.1's statement of the test, its
measurement in section 8.12 and A.8.1's locator, and no rule, example,
diagnostic, fenced text, line range, count of section 8 item 1 or merge-tree
set, so rev 5's sign-off stands for every text rev 7 leaves as it was, and
the implementation resumes from rev 7's commit with section 3's commit 1
(amended 2026-10-28, stop-and-amend re-review: AM6-M1, AM6-m1).

Rev 8, 2026-10-29, is a stop-and-amend of rev 7 at section 3 step 4's last
clause, not a review fold (section 8.16): the focused re-review's round 2 found
the built-in test incomplete (RR2-M1, MAJOR) and its aggregate clause crediting
docs/design/assignment.md:159-161 with this design's classification (RR2-m1,
MINOR), both changing pages, with the budget of three fix commits spent. Rev 8
re-plans the test at its root and gives the fold commit's texts. It changes no
page, record, ledger line, example, diagnostic, count of section 8 item 1 or
merge-tree set, so rev 5's sign-off stands for every text rev 8 leaves as it
was; its re-planned texts are not signed off: the orchestrator rules on the one
fold commit past the budget, and fresh agents review rev 8 (round 3 of section
3 step 5) and that commit before section 3's steps 6 to 8 (amended 2026-10-29,
rev 8: RR2-M1, RR2-m1).

## Hand-off notes for the implementer

1.  Read section 1 first, then the Appendix A block for each page in order;
    every block quotes its anchor, so re-open the page and find the anchor
    before editing. Line numbers are 2407efa74's and move as earlier blocks of
    the same page land; work from the bottom of each page up, or re-find each
    anchor.
2.  Markdown edits by Edit or Write only, never a shell append (R25). The JSON
    notes of Appendix B.4 append to each item's `notes` string, a space and the
    note text, keeping the file's two-space indentation; parse it after.
3.  Keep the superseded texts byte for byte: they are quotes of PR 53's lines
    at 2407efa74 and a reviewer diffs them. Byte for byte is section 2.1's
    test: a quoted link keeps its `[text](target)` (amended 2026-10-28,
    implementation: stop-and-amend: link markup in two superseded quotes),
    and a run of spaces in a code line may be quoted as one space or two,
    the only whitespace the test sets aside besides a line break and its
    indentation (amended
    2026-10-28, stop-and-amend re-review: AM6-M1).
4.  R31 and the style hook (SAFE-1's hand-off note 4 applies unchanged):
    never let a `#NN`, a list marker, `+`, `-` or a digit and a period start a
    prose line; write "PR 53", "proposal 5434" or "p005434"; headings never end
    in punctuation; code blocks inside pages are fenced as the pages already
    fence them.
5.  Do not touch type_safety.md (but for the round 2 fix commit's sentence at
    :135-140; amended 2026-10-29, re-review round 2: RR1-B1), terminology.md,
    the stubs, the toolchain,
    the prelude or any golden, nor slices.md beyond A.10.1's note and A.10.2's
    amendment (amended 2026-10-28, review fold: RR1-M1, RR2-B1); the prelude
    change A.10.2 and D-SAFE2-5 describe, `Core.Buf(T).Set`'s `ref self`, is
    W-144's, not this workstream's, as is `IndirectIndexWith.Ref`'s
    `bound self` once PR 65 lands (amended 2026-10-28, review fold: RR3-M1);
    do not edit PR 65's branch, nor PR 67's except by
    step 6 of section 3; do not push before section 3 step 5 is dry; do not
    open or edit a PR.
6.  Every count and cite in a commit message is measured on that commit's
    tree (R10); a moved anchor is reported, never silently taken.

## Appendix A. Page replacements, verbatim (commit 1)

Paths are under docs/design/; line numbers are 2407efa74's. Each block's text
goes into the page as written, without the fence.

### §A.1.1 safety/README.md :133-155, Soundness model, a sentence appended and a paragraph inserted

Append the first block to the prelude paragraph (:133-139, which begins "The
prelude is the first client of this model." and ends "(W-144; see" and a link
to the temporal page), after a space; it is the trusted bodies' half of M3's
write rule, the same words as D-SAFE2-5, A.2.8, B.1.0 and B.1.7 (added
2026-10-28, review fold: RR2-B1: the re-review's `Peek8` had `Core.Buf(T).Set`,
a trusted by-value writer, write a borrowed `Core.String` element; amended
2026-10-28, review fold: RR3-M1: the `IndirectIndexWith.Ref` clause, where
rev 4's block ended "takes `ref self` under W-144" before its link). Insert the
second block after the paragraph that ends "amended 2026-10-12,
document-review fold: D-8)." (its parenthesis begins "(see" and a link to the
mutation page) and before "## Safety modes":

<!-- google-doc-style-ignore -->

```markdown
A trusted body keeps the write rule of the mutation page's M3: it writes an
object whose type holds a `Core.SharedImmutable` sub-object only through an
exclusive path, an owner, a `ref` or an `exclusive T*`, or through a pointer
into storage owned by an object it holds exclusively, every other path to that
storage the type hands out being `bound` to that object; so
`Core.Buf(T).Set`, which writes an element of the block, takes `ref self`
under W-144, and the `Ref` method of the indexing interface
`IndirectIndexWith`, once the prelude has it, which hands out a `ref` into
the storage a `Core.Slice` views or a `Core.Buf` owns, takes `bound self`
under W-144, at the interface and in both impls, so that a binding formed
through `b[i]` keeps the loan on `b` that `Set`'s `ref self` conflicts with
([Mutation safety](mutation_safety.md), Value bindings; added <date>, SAFE-2:
W-348).
```

```markdown
The guarantee is stated for the supported build modes, Release and Debug and
their extensions. The unsupported benchmarking build of
[Build modes](#build-modes) removes the run-time enforcement the guarantee
relies on, the bounds check, the division guard, the overflow wrap and the
hardening initialization of unformed storage, and nothing on the safety pages
holds in it (realigned <date>, SAFE-2: W-350, W-351).
```

<!-- google-doc-style-resume -->

### §A.1.2 safety/README.md :286-290, Operation-tied `unsafe`, a bullet inserted

Insert after the bullet that ends "(amended 2026-10-12, document-review fold:
D-9)." (the `unsafe p->Push(3)` bullet) and before the `unsafe fn F(...) =
"name"` bullet:

<!-- google-doc-style-ignore -->

```markdown
-   `let ref r: T = unsafe *p;`, `unsafe F(ref *p)`, `let v: T = unsafe *p;`,
    `unsafe p->M(args)` and `unsafe F(p)` — a `ref` binding, a value binding
    of a borrowed object, or a call whose `bound` pointer argument reaches an
    open place, formed where the checker cannot see every other carrier
    ([Temporal safety](temporal_safety.md), `ref` bindings, T2 and T5(d);
    [Mutation safety](mutation_safety.md), M8). For a `ref` the obligation is
    the one proposal p005434 gives unsafe code, to "adhere to just the
    `noalias` restrictions": no other path accesses the referent, or writes it
    for a `const` `ref`, while the binding lives; for a value binding, no path
    mutates the borrowed object while the binding lives; for a `bound` pointer
    argument, no path but the result writes the pointee while the result lives
    (realigned <date>, SAFE-2: W-347, W-348, W-349).
```

<!-- google-doc-style-resume -->

### §A.1.3 safety/README.md :322, What each mode diagnoses, the row's Debug cell and four rows inserted

Replace the row whose first cell is `StrictSharedBorrowInvalidated` with a
link to the temporal page with the block's first row (its Debug cell re-worded,
amended 2026-10-28, review fold: B-m6), and insert the block's other four rows
after it (the fourth amended 2026-10-28, review fold: A-B-1):

<!-- google-doc-style-ignore -->

```markdown
| `StrictSharedBorrowInvalidated` ([temporal safety](temporal_safety.md)) | error | warning `PermissiveAliasedExclusive` | ASan-class detection when the invalidation frees what a loan reads; the value-binding report is `StrictBorrowedObjectMutated`'s (realigned <date>, SAFE-2: W-348; this cell read "`MutationDuringValueBinding` for the value-binding case (D-SAFE-17)") |
| `StrictRefFromShared` ([temporal safety](temporal_safety.md); realigned <date>, SAFE-2: W-347) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowFromShared` ([mutation safety](mutation_safety.md); realigned <date>, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowedObjectMutated` ([mutation safety](mutation_safety.md); realigned <date>, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` |
| `StrictSharedImmutableWrite` ([mutation safety](mutation_safety.md); realigned <date>, SAFE-2: W-348) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` when a binding of the object is live |
```

<!-- google-doc-style-resume -->

### §A.1.4 safety/README.md :381-383, Safe Carbon design, the spatial bullet replaced

Replace the bullet that begins with the link "Spatial safety" to the spatial
page and continues ": every element access is bounds-checked and fails-stop in
every build mode, `unsafe fn GetUnchecked` is the only opt-out, and views carry
their length and a loan." with:

<!-- google-doc-style-ignore -->

```markdown
-   [Spatial safety](spatial_safety.md): every element access is bounds-checked
    and fails-stop in every supported build mode, `unsafe fn GetUnchecked` is
    the supported opt-out beside the unsupported benchmarking build, and views
    carry their length and a loan (realigned <date>, SAFE-2: W-351; the
    superseded 2026-10-12 text read "fails-stop in every build mode,
    `unsafe fn GetUnchecked` is the only opt-out").
```

<!-- google-doc-style-resume -->

### §A.1.5 safety/README.md :403, Pointer kinds at a glance, a paragraph inserted

Insert after the table (its last row's first cell is "unverified (any kind)")
and before "### C++ call allowlist" (the last clause amended 2026-10-28,
review fold: RR1-B1, to M3's structural rule; `Core.Slice(T)` conditioned on
a `Core.Freeze` `T`, amended 2026-10-28, review fold: RR2-m3, where rev 3 read
"a `Core.String`, a `Core.Slice` or a struct"; A.3.3's first block has the
same words with the temporal page's own cites):

<!-- google-doc-style-ignore -->

```markdown
Every `ref` binding is exclusive access to its referent, or a frozen read of it
when its type is `const`, whatever its source, and a value binding of a type
whose value representation is not a copy binds a borrowed object, frozen for
the binding's lifetime. Through `T*` or `const T*` such a binding is formed
only on a closed place or, for a frozen one, a `Core.SharedImmutable` type, and
is an `unsafe` operation otherwise, so the `const T*` row's receivers meet that
rule when they are called through a shared pointer
([Temporal safety](temporal_safety.md), T2); and the `T*` row's `Plain` writes
exclude every assignment whose type holds a `Core.SharedImmutable` sub-object,
a `Core.String`, a `Core.Slice(T)` for a `Core.Freeze` `T`, or a struct,
tuple, array or class holding one, which only an exclusive path makes
([Mutation safety](mutation_safety.md), M3; realigned <date>, SAFE-2: W-347,
W-348).
```

<!-- google-doc-style-resume -->

### §A.1.6 safety/README.md :561-567, Build modes, the blockquote replaced

Replace the blockquote that begins "> **Withdrawn (fork amendment 2026-10-12,
F-013 D-SAFE-14).**" and ends "> is kept as history." with the block, whose
label is dated by SAFE-2's commit and names the 2026-10-12 note it replaces
(amended 2026-10-28, review fold: B-M5; rev 1 dated the new note 2026-10-12).
The quoted superseded note keeps the page's link to the spatial page, as
:566 writes it, `[Spatial safety](spatial_safety.md)` (amended 2026-10-28,
implementation: stop-and-amend: link markup in two superseded quotes; rev 5
quoted the link by its text alone, "see Spatial safety", and its heading gave
the blockquote's lines as :560-566, section 8.12):

<!-- google-doc-style-ignore -->

```markdown
> **Kept (fork note <date>, SAFE-2: W-351, replacing the withdrawal of
> 2026-10-12, F-013 D-SAFE-14).** The fork provides the way the paragraph
> above promises: the _benchmarking build_, the Release build with its default
> hardening disabled,
> that is with no bounds check, no division-by-zero guard, no overflow wrap,
> which leaves the arithmetic design's performance-build row in force, and no
> hardening initialization of unformed storage. It is not a supported build
> mode: no guarantee of the safety pages holds in it, no program is shipped
> from it, and its spelling is fixed with the build modes at stage 2 (residue
> item W-146). The per-site `unsafe fn GetUnchecked` on `Core.Slice` and
> `Core.Buf` is the supported opt-out ([Spatial safety](spatial_safety.md),
> SP4). (The superseded 2026-10-12 note read: "The fork provides no build flag
> that disables the default hardening, for benchmarking or otherwise. The
> per-site `unsafe fn GetUnchecked` on `Core.Slice` and `Core.Buf` is the only
> disable, which keeps the strategy's "manually disabled for
> performance-critical use cases" (proposal p000196) at the site rather than
> the build; see [Spatial safety](spatial_safety.md). The paragraph above is
> kept as history.")
```

<!-- google-doc-style-resume -->

### §A.1.7 safety/README.md :673 and :675, Implementation staging, rows 2 and 4 replaced

Replace the stage 2 row, whose second cell begins "Runtime hardening regardless
of mode:", and the stage 4 row, whose second cell begins "The loan checker:
loans, `bound`, no-invalidation,", with:

<!-- google-doc-style-ignore -->

```markdown
| 2 | Runtime hardening regardless of mode: array index fail-stop, division by zero fail-stop, `--build-mode=debug\|release`, Release zero-fill; the unsupported benchmarking build that disables them (realigned <date>, SAFE-2: W-350, W-351) | — |
| 4 | The loan checker: loans, `bound`, no-invalidation, `exclusive`; frozen loans, the closed-place rule, the `bound` pointer argument's pointee and `Core.SharedImmutable` (realigned <date>, SAFE-2: W-347, W-348, W-349); `error` default; `noalias` under T8 | The matrix's error column |
```

<!-- google-doc-style-resume -->

### §A.2.0 safety/mutation_safety.md :103-106, Definition, a sentence appended

Append to the paragraph that ends "committed to (proposal p005914) made
checkable.":

<!-- google-doc-style-ignore -->

```markdown
The one exception is upstream's: an object in an active value binding whose
value representation is not a copy is a borrowed object, which no path mutates
while the binding lives (M8; realigned <date>, SAFE-2: W-348).
```

<!-- google-doc-style-resume -->

### §A.2.1 safety/mutation_safety.md :57-59, Overview, a clause replaced

Replace "a `match` on a sum through a shared path pins the alternative while a
payload reference lives; and a value binding of a non-`Plain` type is itself a
shared access path." with:

<!-- google-doc-style-ignore -->

```markdown
a `match` on a sum pins the alternative while a payload binding lives; every
`ref` binding is exclusive access, or a frozen read for a `const` type; and a
value binding of a type whose value representation is not a copy binds a
borrowed object that no path mutates while it lives (realigned <date>, SAFE-2:
W-347, W-348; the superseded 2026-10-12 text read: "a `match` on a sum through
a shared path pins the alternative while a payload reference lives; and a
value binding of a non-`Plain` type is itself a shared access path").
```

<!-- google-doc-style-resume -->

### §A.2.2 safety/mutation_safety.md :90-93, the status paragraph

Replace "The one example on this page in today's syntax, EX-M-4a, was compiled
and run on the 2026.10.12 nightly toolchain and its outcome is stated with it."
with the first block, and append the second block to the paragraph after
"against trunk 0bdce60a5 unless a citation says otherwise.":

<!-- google-doc-style-ignore -->

```markdown
The examples on this page in today's syntax, EX-M-4a, EX-M-4c and the
functions `Peek`, `Peek2` and `Peek4` of EX-M-4d, were compiled and run on
the 2026.10.12 nightly toolchain and their outcomes are stated with them
(EX-M-4c and EX-M-4d added <date>, SAFE-2: W-348).
```

```markdown
Rules M1, M2, M3, M4, M5 and M8, and the sections they cite, were
realigned <date> by fork workstream SAFE-2 to proposal p005434's rules for
`ref` bindings and borrowed objects (W-347, W-348, W-349;
fork/safe/safe2-plan.md); each realigned passage quotes the text it
supersedes.
```

<!-- google-doc-style-resume -->

### §A.2.3 safety/mutation_safety.md :142-145, M1, the last sentence replaced

Replace "A `ref` binding inherits the kind of its source (D-SAFE-8): a `ref`
formed from a place is exclusive access, a `ref` formed from `*p` has `p`'s
kind, and so the rules of this page apply to a shared-kind `ref` exactly as to
a `T*`." with:

<!-- google-doc-style-ignore -->

```markdown
Every `ref` binding is exclusive access to its referent, or a frozen read for
a `const` type, whatever its source (D-SAFE-8): formed from a place, or through
a pointer to a closed place, it is a checked reborrow, and formed through a
shared pointer to an open place it is the `unsafe` formation of the temporal
page's [`ref` bindings](temporal_safety.md#ref-bindings), so no shared-kind
`ref` exists (realigned <date>, SAFE-2: W-347; the superseded 2026-10-12 text
read: "A `ref` binding inherits the kind of its source (D-SAFE-8): a `ref`
formed from a place is exclusive access, a `ref` formed from `*p` has `p`'s
kind, and so the rules of this page apply to a shared-kind `ref` exactly as to
a `T*`.").
```

<!-- google-doc-style-resume -->

### §A.2.4 safety/mutation_safety.md :149-159, M2, the paragraph replaced

Replace the paragraph from "At every program point a place is under at most
one exclusive loan" through "place in the set (D-SAFE-8)." with:

<!-- google-doc-style-ignore -->

```markdown
At every program point a place is under at most one exclusive loan or under any
number of shared and frozen loans, never both. This is the temporal page's
conflict rule T4 read as a mutation rule: a live exclusive loan excludes every
other access to overlapping places, except through the suspended carrier at the
kind the reborrow clause allows; a live shared loan excludes exclusive loans and
the invalidating operations of M3, and an invalidating operation on a place
kills every interior loan on it; and a live frozen loan, the loan of a borrowed
object (M8) or of a `const` `ref`, excludes besides every other write to the
place's storage, `Plain` writes and `addr` calls included. Liveness is
non-lexical (T3): a loan is live from its creation to the last use of any
carrier, so a shared pointer that is never used again does not block an
invalidating operation on the next line, which is what makes EX-M-1 read as it
does. For a call result or reference expression whose loan set mixes kinds,
the weakest kind governs every place in the set (D-SAFE-8; realigned <date>,
SAFE-2: W-347, W-348; the superseded 2026-10-12 text read: "At every program
point a place is under at most one exclusive loan or under any number of shared
loans, never both." and "For a carrier whose loan set mixes kinds, the weakest
kind governs every place in the set (D-SAFE-8).").
```

<!-- google-doc-style-resume -->

### §A.2.4a safety/mutation_safety.md :174-187, M3, a sentence replaced and a paragraph inserted

Replace "Everything else, reads, overwriting `Plain` fields, `addr` and `const`
methods, is permitted through any number of aliases at once." with the first
block, and insert the second block after the paragraph that ends "exactly what
(a) and the sub-object clause require." and before "The escape is the uniform
`unsafe` prefix" (added 2026-10-28, review fold: A-B-1: the language half of
`Core.SharedImmutable`'s promise, without which review A's `Peek2` breaks it;
amended 2026-10-28, review fold: RR1-B1: the paragraph now covers every
assignment whose type holds a `Core.SharedImmutable` sub-object, a closure
like `Core.Plain`'s, so that the focused re-review's `Peek4` and its class
variant are rejected, and the first block names "the next paragraph", which
rev 2 called "the next paragraph but one"; amended 2026-10-28, review fold:
RR2-m3: `Core.Slice(T)` holds one and opts in for a `Core.Freeze` `T` only,
where rev 3 named it for every `T`; amended 2026-10-28, review fold: RR2-B1:
the paragraph's last sentence but one states that a trusted body keeps the
rule):

<!-- google-doc-style-ignore -->

```markdown
Everything else, reads, overwriting `Plain` fields, `addr` and `const` methods,
is permitted through any number of aliases at once, but for the assignments of
a type that holds a `Core.SharedImmutable` sub-object, which the next paragraph
names (realigned <date>, SAFE-2: W-348; this sentence ended "is permitted
through any number of aliases at once.").
```

```markdown
One more class of write needs exclusive access although it invalidates
nothing: a write of storage that holds a `Core.SharedImmutable` object
([Value bindings](#value-bindings)). A type _holds a `Core.SharedImmutable`
sub-object_ when it is `Core.SharedImmutable`, or is an array, tuple, struct or
class with an element, a field or a base that holds one, or an adapter of a
type that holds one, a closure like `Core.Plain`'s below: `Core.String`,
`Core.Slice(T)` for a `Core.Freeze` `T`, `{.s: str, .n: i32}` and a class with
a `str` field all hold one. An assignment whose assigned type holds one, a
whole-object or a field
assignment and a `Plain` one included, through `T*`, through `addr self`, or to
an open place such as a global
([temporal safety: vocabulary](temporal_safety.md#vocabulary)), is
`StrictSharedImmutableWrite`, a non-`Plain` one staying
`StrictInvalidatingThroughShared`; through an exclusive path, the owner of a
closed place, a `ref` or an `exclusive T*`, it is permitted while no frozen
loan on an overlapping place is live and is `StrictBorrowedObjectMutated`
while one is. A union is outside the closure: reading its field is `unsafe` in
Strict ([unions](../unions.md#strict-carbon-and-future-safety-hooks)), so a
binding of a union's field is formed under that marker, whose obligation then
includes that no path writes the union while the binding lives. This is the
language half of the facet's promise that no path but an exclusive one writes
the type's storage, which a frozen loan on an open place relies on, and an
assignment of an enclosing object writes that storage too. `Core.String`, and
`Core.Slice(T)` for a `Core.Freeze` `T`, are `Plain` and opt in, so
`*q = "longer"` through a `str*` and `*q = {.s = "longer", .n = 1}` through a
`{.s: str, .n: i32}*` are rejected in Strict (EX-M-4d's `Peek2` and `Peek4`),
and `s = "def"` through the owner under a live `const Core.String*` stays
accepted (the temporal page's EX-TM-3). A trusted body keeps this rule too,
writing such an object only through an exclusive path or through storage
owned by an object it holds exclusively, which is why `Core.Buf(T).Set` takes
`ref self` ([Value bindings](#value-bindings); EX-M-4d's `Peek8`). The
`unsafe` prefix on the write, `unsafe (*q = "longer")`, takes on the
obligation that no binding of the object is live (added <date>, SAFE-2:
W-348).
```

<!-- google-doc-style-resume -->

### §A.2.5 safety/mutation_safety.md :209-220, M4, a clause of the second bullet and the third bullet replaced

In the `addr self: Self*` bullet replace "it may assign `Plain` fields (`i32`,
the pointer kinds, `Core.Slice`, the prelude's non-owning `Core.String`)," with
the first block (amended 2026-10-28, review fold: A-B-1: M3's new paragraph
makes a `Core.String` or `Core.Slice` field written only through exclusive
access; amended 2026-10-28, review fold: RR1-B1: so is a field, or `*self`,
whose type holds such a sub-object; amended 2026-10-28, review fold: RR2-m3:
a `Core.Slice(T)` field for a `Core.Freeze` `T`, where rev 3 read "a
`Core.Slice`"). Replace the bullet "`ref self: const
Self` and by-value `self` are const access: the body mutates nothing in
`self`, and a call is permitted through every kind." with the second block.

<!-- google-doc-style-ignore -->

```markdown
it may assign `Plain` fields (`i32`, the pointer kinds), but a field whose type
holds a `Core.SharedImmutable` sub-object, a `Core.Slice(T)` for a
`Core.Freeze` `T`, the prelude's non-owning `Core.String` or a struct holding
one, and `*self` when `Self` holds one, only as M3 allows such a write, so a
setter of a `Core.String`
field takes `ref self` (realigned <date>, SAFE-2: W-348; this clause read "it
may assign `Plain` fields (`i32`, the pointer kinds, `Core.Slice`, the
prelude's non-owning `Core.String`),"),
```

```markdown
-   `ref self: const Self` and by-value `self` are const access: the body
    mutates nothing in `self`. A call binds `self`, a frozen `ref` or a value
    binding that borrows the object when its value representation is not a
    copy, so through an owner, a `ref` or an `exclusive T*` it is permitted,
    and through `T*` or `const T*` it needs a closed place or a
    `Core.SharedImmutable` type, else `StrictBorrowFromShared`, or
    `StrictRefFromShared` for `ref self: const Self` (M8; realigned <date>,
    SAFE-2: W-347, W-348; the superseded 2026-10-12 text read: "the body
    mutates nothing in `self`, and a call is permitted through every kind.").
```

<!-- google-doc-style-resume -->

### §A.2.6 safety/mutation_safety.md :232-244, M5, renamed and replaced

(Amended 2026-10-28, document-review fold: R2-m2. The block below is commit
1's text. Since e1574b003 the page's superseded quote runs to the end of the
superseded paragraph, as section 8.7 records.)

Rename the heading "### M5: Payload references through `match`" to
"### M5: Payload bindings through `match`", and replace the paragraph from "A
`match` through an exclusive path binds `ref` payloads" through "EX-M-5 and
EX-M-6 are its two shapes." with:

<!-- google-doc-style-ignore -->

```markdown
A `match` binds a payload by `ref` or by value, under the rules of `ref`
bindings and value bindings. Through a path to a closed place, an owner, a
`ref` or an `exclusive T*`, a `ref` payload is an exclusive sub-loan on the
scrutinee and a value payload that borrows is a frozen one; through a shared
path to an open place a `ref` payload is `StrictRefFromShared` unless it is
marked `unsafe`, and a value payload that borrows is formed only when the
payload's type is `Core.SharedImmutable` (M8). Under any of these sub-loans the
alternative of the sum cannot change while the payload binding lives, and this
is a consequence of M3(c) rather than a separate rule: a payload `choice`, and
`Core.Optional(T)` for every `T`, is non-`Plain`, so assigning a new
alternative to the scrutinee through any shared alias is
`StrictInvalidatingThroughShared`, and assigning it through the owner while the
sub-loan is live is `StrictSharedBorrowInvalidated` (T4). The change of a sum
type's alternative under a payload binding is the second mutation safety bug of
the [definition](#definition); EX-M-5 and EX-M-6 are its two shapes (realigned
<date>, SAFE-2: W-347; the heading read "M5: Payload references through
`match`", and the superseded 2026-10-12 text read: "A `match` through an
exclusive path binds `ref` payloads as exclusive sub-loans on the scrutinee; a
`match` through a shared path binds them as shared sub-loans. Under a shared
sub-loan the alternative of the sum cannot change while the payload reference
lives").
```

<!-- google-doc-style-resume -->

### §A.2.7 safety/mutation_safety.md :274-283, M8, the paragraph replaced

Replace the paragraph from "A value binding of a `Plain` type copies eagerly"
through its last words, "stated in full with its memory-safety argument under"
and the link to the Value bindings section, with:

<!-- google-doc-style-ignore -->

```markdown
A value binding of a type whose value representation is a copy holds no loan,
so mutation of the source afterwards is accepted in every mode. A value binding
of any other type binds a borrowed object (proposal p005434) and holds a frozen
loan on it for the binding's non-lexical lifetime, under which every write to
the object's storage through any path is rejected in Strict: an invalidating one
with `StrictSharedBorrowInvalidated`, any other with
`StrictBorrowedObjectMutated`. The loan is formed on a closed place, or on an
open place when the type is `Core.SharedImmutable`, and the binding is
`StrictBorrowFromShared` otherwise. A value binding from a materialized
temporary owns that storage and holds no loan on it. The rule is D-SAFE-17,
stated in full with its memory-safety argument under
[Value bindings](#value-bindings) (realigned <date>, SAFE-2: W-348; the
superseded 2026-10-12 text read: "A value binding of a `Plain` type copies
eagerly and holds no loan, so mutation of the source afterwards is accepted in
every mode. A value binding of a non-`Plain` type, from `*p` or from an owner,
is a shared loan on the bound object for the binding's non-lexical lifetime,
under which an invalidating operation on the bound object is
`StrictSharedBorrowInvalidated` and a `Plain`-field write through another alias
is erroneous and Debug-reported as `MutationDuringValueBinding`.").
```

<!-- google-doc-style-resume -->

### §A.2.7a safety/mutation_safety.md :323-326, `Core.Plain`, a sentence appended

Append to the paragraph that ends "and an owning string, once the prelude has
one, will not be." (added 2026-10-28, review fold: A-B-1, so that the line
stating `Plain` assignment as accepted does not hide M3's new paragraph;
amended 2026-10-28, review fold: RR1-B1, for the aggregates that hold a
string; amended 2026-10-28, review fold: RR2-m3, `Core.Slice(T)` for a
`Core.Freeze` `T` only, where rev 3 read "or a `Core.Slice(T)`,"):

<!-- google-doc-style-ignore -->

```markdown
Through a `T*` the same assignment is `StrictSharedImmutableWrite` in Strict,
`Core.String` being `Core.SharedImmutable`, and so is a `Plain` assignment
through a `T*` of an array, tuple, struct or class that holds a `Core.String`
or a `Core.Slice(T)` for a `Core.Freeze` `T`, which holds a
`Core.SharedImmutable` sub-object as M3 defines it by the same closure as this
facet's (M3; added <date>, SAFE-2: W-348).
```

<!-- google-doc-style-resume -->

### §A.2.8 safety/mutation_safety.md :415-470, Value bindings, the section body replaced

(Amended 2026-10-28, document-review fold: R1-M2. The blocks below are commit
1's text. Since 0f281d8bd the page's soundness argument also names the
marker's obligation for the free result of a marked `unsafe fn` call, as
section 8.7 records.)

Keep the heading "## Value bindings"; replace everything from "A value binding
(`let x: T = e;`, a by-value parameter, a by-value `self`) is" through the
section's last line, a parenthesized link to the safe-Rust interop page,
before "## Diagnostics", with:

<!-- google-doc-style-ignore -->

````markdown
A value binding (`let x: T = e;`, a by-value parameter, a by-value `self`) is
the binding the [values](../values.md) design describes as acquiring the value
of a referenced object, with the read possibly deferred, and under which "any
mutation to the object or its storage ends the lifetime of the value binding,
and makes any use of the value expression an error". Proposal p005434 names
the object such a binding reads when its value representation is not a copy:
"Mutation of objects with a non-copy-value representation in an active value
binding ("borrowed objects") is erroneous behavior", and "Our plan is to
prevent mutation of borrowed objects in Carbon's strict safe dialect"
(p005434:660-664). D-SAFE-17 is that plan, in four parts:

-   **A copy-represented type holds no loan.** A type's value representation is
    its `value_rep` when it declares one and otherwise the implementation's
    choice
    ([values: value representation and customization](../values.md#value-representation-and-customization)).
    Today's toolchain (upstream toolchain/check/type_completion.cpp at
    0421bf3b4) gives a copy to `bool`, the integer, floating-point and pointer
    types (:697-751) and to a struct or tuple of one element, whose value is a
    one-element aggregate of its element's value representation (:572-578);
    an adapter, `const T` and `MaybeUnformed(T)` of a copy-represented `T`
    other than `bool` take the representation of the type they wrap (:762-770,
    :783-789, :803-826), so `Core.Optional(T*)`, an adapter of
    `MaybeUnformed(T*)`, is copy-represented. It gives a pointer to every
    other class and to every array (:674-695, :771-781), and to every struct or
    tuple of more than one element, a pointer to the object when every
    element's value representation is a copy of its object representation and
    otherwise a pointer to a separate aggregate of the element values
    (:580-582, :597-609). A binding of a copy-represented type read the value
    when it was bound, so there is no borrowed object and mutation of the
    source afterwards is accepted in every mode: `let b: i32 = a; a = 2;
    return b;` is accepted in Strict and returns 1 (EX-M-4a), and the values
    design carries a dated note saying so. When the copy is a one-element
    aggregate, its element's own representation decides: an element whose
    value representation is not a copy is a borrowed object of the binding.
-   **Any other type binds a borrowed object, under a frozen loan.** The
    binding holds a _frozen_ loan on the bound object for its non-lexical
    lifetime (T2): no path writes the object's storage while it lives. A
    `Plain`-field assignment or an `addr` call on the object through any
    alias, the owner included, and passing a writable carrier of it, a
    non-`const` pointer or a value that carries one, to a call, are
    `StrictBorrowedObjectMutated` (EX-M-4c); an invalidating operation, an
    assignment of a non-`Plain` value, a `ref self` call, a move or a destroy,
    is `StrictSharedBorrowInvalidated` as before (T4; EX-M-4b). The object's
    storage is the object and its sub-objects; storage reached through a
    pointer it holds, the elements of a `Core.Buf` among them, is another
    object's, which is why an `i32` element of a borrowed `Buf` may still be
    written through the `T*` that a view's `Data()` returns, element `i`
    through the one-element view `AsSlice().Subslice(i, i + 1)`, and through
    `b[i] = v` once the indexing interface `IndirectIndexWith` lands;
    `Core.Buf(T).Set` itself takes `ref self`, below.
-   **The frozen loan needs a place the checker can see.** On a closed place
    ([temporal safety: vocabulary](temporal_safety.md#vocabulary)), an owner, a
    `ref`, the pointee of an `exclusive T*` or a place every carrier of whose
    loans the body sees, T4 enforces it against every carrier. On an open
    place, `*p` for a `T*` or `const T*` parameter, a pointer loaded from
    memory, a free or ⊥ pointer, an alias the body cannot see could write the
    object, so the loan is formed only when the bound type is
    `Core.SharedImmutable`, below; any other such binding is
    `StrictBorrowFromShared` (EX-M-4d), and its spellings
    `let v: T = unsafe *p;` and `unsafe p->M()` take on the obligation that no
    path mutates the object while the binding lives. The other fixes are an
    owner or an `exclusive T*`, `Core.Guarded(T)`, the type's own
    `value_rep = const Self` when it is small and copyable, and a `var` copy of
    a struct or tuple, `var v: T = *p;`, whose `Plain` elements are read and
    whose class elements bind under this same rule.
-   **A materialized temporary owns its storage.** An initializing expression
    is the third source of a value binding, neither `*p` nor an owner; the
    binding takes ownership of the materialized storage, the values design's
    rule for a `var` pattern applied to `let`, and carries no loan on it, so
    `let o: Core.Optional(i32) = Core.Optional(i32).Some(1);` followed by
    `o.HasValue()` on the next line is accepted. The loans carried _by_ the
    value are unaffected, which is why a view of a temporary `Buf` stays
    `StrictBorrowOfTemporary` on the temporal page (EX-TM-7b).

**`Core.SharedImmutable`** is the facet that says no path but an exclusive one
writes a type's storage. The promise has two halves. The language keeps the
first: every assignment through a shared path whose assigned type holds a
`Core.SharedImmutable` sub-object, the type itself or an array, tuple, struct
or class that holds it, a `Plain` one included, is rejected in Strict by M3
(`StrictSharedImmutableWrite`; EX-M-4d's `Peek2` and `Peek4`), and a union's
field binds only under the `unsafe` its read needs. The author keeps the
second, what no check of the language sees: every field is private, no `addr`
method writes `self`, no function writes the type's storage through a shared
path or returns a
non-`const` pointer or `ref` into it, and no pointer into its own storage is
stored in it. It is opt-in only, `unsafe impl T as Core.SharedImmutable {}`, the
author's audited obligation in the pattern of `unsafe impl T as Core.Send {}`,
and it implies `Core.Freeze`, so a generic type opts in only for a `Freeze`
argument. The prelude opts in for `Core.String`, and for `Core.Slice(T)`,
`Core.Buf(T)` and `Core.Optional(T)` under `forall [T: Core.Freeze]`, and for
`Core.Box(T)` the same way once residue item W-144, which holds the opt-ins,
adds `Box`, their bodies
trusted under the [soundness model](README.md#soundness-model), so a by-value
call such as `p->Size()` through a `Core.Buf(i32)*` or a `const Core.String*`
parameter binds a borrowed object the checker can rely on (EX-M-4d; the temporal
page's EX-TM-1). A struct or tuple type has public elements and never opts in.
The trusted bodies keep the language half too: a trusted body writes an object
whose type holds a `Core.SharedImmutable` sub-object only through an exclusive
path, an owner, a `ref` or an `exclusive T*`, or through a pointer into
storage owned by an object it holds exclusively, every other path to that
storage the type hands out being `bound` to that object; so `Core.Buf(T).Set`,
which writes an element of the block, takes `ref self` under W-144, and
EX-M-4d's `Peek8`, which binds an element frozen through a shared
`Core.Buf(str)*` and then calls `Set`, is `StrictInvalidatingThroughShared` at
the call. The `Ref` method of the indexing interface `IndirectIndexWith`, once
the prelude has it, hands out a `ref` into the storage a `Core.Slice` views or
a `Core.Buf` owns, so it takes `bound self` under W-144, at the interface,
since an impl may not add `bound` beyond it
([temporal safety](temporal_safety.md), T5(e)), and in the `Core.Slice` and
`Core.Buf` impls: a binding formed through `b[i]`, such as
`let s: str = b[0];`, then keeps the loan on `b` that `Set`'s `ref self`
conflicts with, and `b.Set(0, "longer")` while `s` lives is
`StrictSharedBorrowInvalidated` (T4), where an unbound `Ref` would leave `s`
frozen on an element reached through a free result and the call accepted.

The memory-safety argument, and what the rule costs. A frozen loan on a closed
place is sound because every carrier of the place is in the body's view and a
carrier of a local cannot escape it (the Store rule and T5(b)); on an open place
of a `Core.SharedImmutable` type, because M3 rejects every Strict assignment
through a shared path that writes the object's storage, whether its type is
the object's or holds it, every trusted body keeps the same rule, the live
shared path excludes the exclusive ones (M2), and the opt-in's obligation
covers what the checker cannot see. A write by
unchecked code, a Permissive body, C++ or an alias an `unsafe` binding promised
away, is the erroneous behavior proposal p005434 keeps for it
(p005434:670-672), never undefined behavior, because the safe-code optimizer
assumes nothing about it (the temporal page's T8 emits no `noalias` on an open
place), and the Debug build detects it: Debug keeps, in shadow memory keyed by
address and never in the object's layout, a count of live frozen loans for each
byte of a borrowed object's storage, incremented when the binding is formed and
decremented at its last use as the stage-4 checker computes it, and every store
that writes a byte whose count is non-zero, of any type and by any path,
through `T*`, through a `ref`, through the owner, to a global by name or in an
`addr self` body, reports `MutationDuringValueBinding`. The rule rejects in
Strict what the rule of 2026-10-12 accepted: a `Plain`-field write during a
binding even where it frees nothing (EX-M-4c), the aliased write of EX-M-1
while a `bound` result lives (the temporal page's T5(d)), a by-value call or a
`let` of a type that does not opt in, through a shared pointer whose aliases the
body cannot see (EX-M-4d's `Peek`), a `Plain` assignment through a shared
pointer, or to a global, of a `Core.String`, a `Core.Slice(T)` for a
`Core.Freeze` `T` or an array, tuple, struct or class that holds one (EX-M-4d's
`Peek2` and `Peek4`), and a `Core.Buf(T).Set` call through a shared pointer, on
a `Buf` bound by value, or while a view of the block lives (EX-M-4d's `Peek8`;
the temporal page's EX-TM-3).
That is the cost proposal p005434 anticipated when it said to
"revisit the underlying idea of mutation being erroneous if enforcing it in
the strict mode proves fundamentally untenable due to ergonomic costs"
(p005434:667-669), and revisiting it is upstream's call. For Rust, a parameter
bound this way is frozen for the call, which is what `&T` promises, and it
exports as `&T` when its type is `Core.Freeze`
([safe-Rust interop](rust_interop.md)).

(Realigned <date>, SAFE-2: W-348, W-349. The superseded 2026-10-12 section body
read, in full, its list items separated by " / ": "A value binding (`let x: T =
e;`, a by-value parameter, a by-value `self`) is the binding the
[values](../values.md) design describes as acquiring the value of a referenced
object, with the read possibly deferred, and under which any mutation of the
object ends the binding's lifetime and makes a later use erroneous. D-SAFE-17
ratifies that rule into Strict Carbon in three parts, by the type of the
binding:" / "**A `Plain` type acquires eagerly and holds no loan.** The binding
is a copy, which is what the design overview says a parameter binding does when
copying is legal and cheaper ([functions](../README.md#parameters)); there is no
deferred read, so there is no object whose mutation could end the binding. `let
b: i32 = a; a = 2; return b;` is accepted in Strict and returns 1 (EX-M-4a); the
erroneous reading of the values design does not arise, and that design carries a
dated note saying so." / "**A non-`Plain` type, from `*p` or from an owner, is a
shared loan** on the bound object for the binding's non-lexical lifetime (T2).
Under it an invalidating operation on the bound object, an assignment of a
non-`Plain` value, a `ref self` call, a move or a destroy, is
`StrictSharedBorrowInvalidated` (T4; EX-M-4b): the value design's "mutation ends
the lifetime of the value binding" becomes a static rejection for exactly the
mutations that could invalidate. A `Plain`-field write through _another_ shared
alias during the binding is not rejected: it stays erroneous, as the values
design says, and is Debug-detected by a value-binding shadow flag. Debug keeps,
in shadow memory keyed by object address and never in the object's layout, a
per-object count of live non-`Plain` value bindings, incremented when the
binding is formed and decremented at its last use as the stage-4 checker
computes it; a `Plain`-field write through `T*` or `addr self` whose target's
count is non-zero reports `MutationDuringValueBinding`." / "**A non-`Plain` type
from a materialized temporary owns the storage.** An initializing expression is
the third source of a value binding, neither `*p` nor an owner; the binding
takes ownership of the materialized storage, the values design's rule for a
`var` pattern applied to `let`, and carries no loan on it, so `let o:
Core.Optional(i32) = Core.Optional(i32).Some(1);` followed by `o.HasValue()` on
the next line is accepted. The loans carried _by_ the value are unaffected,
which is why a view of a temporary `Buf` stays `StrictBorrowOfTemporary` on the
temporal page (EX-TM-7b)." / "The memory-safety argument for the second part,
which is the part the fork ratified rather than inherited: `Plain` fields carry
no ownership, so a write to one through another alias changes a value the
binding may read stale but frees nothing the binding may read freed; owning
fields cannot be written through `T*` at all (M3); and exclusive writes are
statically dead for the binding's lifetime (M2). What a stale read costs is
correctness, and that is what the Debug report is for. What is narrowed is the
plan of proposal p005434 to prevent _all_ mutation of borrowed objects in the
strict dialect; this page narrows it, dated 2026-10-12, to "no invalidating
mutation", and the same narrowing is applied at the temporal page's
D-SAFE-11(d), where a `bound` argument stays writable in its `Plain` fields for
the duration of a returned loan. The alternative recorded in D-SAFE-17 is eager
acquisition for every type: always copy, the simplest rule, costly for large
owning types, and the rule the break condition adopts if a memory-safety
consequence, as opposed to a correctness one, is ever demonstrated. For Rust, a
parameter bound this way exports as `&SharedView<T>`, not `&T` ([safe-Rust
interop](rust_interop.md)).")
````

<!-- google-doc-style-resume -->

The section's list goes from three items to four (bullets plus one). The
superseded text is quoted in full, its bullets joined by " / " so that no
quoted line starts with a list marker (amended 2026-10-28, review fold: B-M5;
rev 1 dropped the introduction, the first bullet's body, the Debug sentence and
"What a stale read costs is correctness"). The `Core.SharedImmutable`
paragraph's language half, the memory-safety argument's M3 clause, the Debug
count and the cost list state M3's structural rule, the per-byte test and
`Peek4` (amended 2026-10-28, review fold: RR1-B1; rev 2 read "every write of
the type's storage through a shared path, a whole-object assignment included",
"M3 rejects every Strict write of the object through a shared path" and "a
per-object count of live frozen loans", and named only `Peek2` in the cost).
The storage bullet's last sentence, the trusted bodies' sentence after the
`Core.SharedImmutable` paragraph, the memory-safety argument's "every trusted
body keeps the same rule" and the cost list's `Core.Buf(T).Set` clause state
RR2-B1's fold, where rev 3 read "which is why `Core.Buf`'s by-value `Set`
stays callable on a borrowed `Buf`." and had no trusted-body sentence; the
Debug sentence tests every store, where rev 3 read "a `Plain` assignment
through `T*`, to a field or to a whole object, that writes a byte whose count
is non-zero, or an `addr self` call on an object one of whose bytes has a
non-zero count" (RR2-m1); and the cost list's `Core.Slice(T)` is conditioned
on a `Core.Freeze` `T` (RR2-m3; all three amended 2026-10-28, review fold:
RR2-B1, RR2-m1, RR2-m3). The storage bullet's element paths after "`Data()`
returns" and the trusted bodies' paragraph's last two sentences, from "The
`Ref` method", are rev 5's: rev 4's bullet ended "the `T*` that a view's
`Data()` returns; `Core.Buf(T).Set` itself takes `ref self`, below." and its
paragraph "is `StrictInvalidatingThroughShared` at the call." (amended
2026-10-28, review fold: RR3-m1, RR3-M1).

### §A.2.9 safety/mutation_safety.md :474-514, Diagnostics

Replace "The first is a stage-4 diagnostic, landing with the loan checker and
the `error` default; the second is stage 5." with the first block; insert the
second block's three rows after the table's `StrictInvalidatingThroughShared`
row; in the paragraph that begins "Two diagnostics the examples on this page
produce" replace "whose Debug column is `MutationDuringValueBinding` for the
value-binding case," with the third block's first part and append its second
part after "which the thread-boundary lifetime rule raises at a spawn."; insert
the fourth block's three items after the `StrictNotSend` item; in the
`PermissiveAliasedExclusive` item replace "under `--strict-checks=warn` or in a
Permissive file;" with the fifth block; and replace the
`MutationDuringValueBinding` item with the sixth (amended 2026-10-28, review
fold: A-B-1 for the third row and item, A-B-2 for `StrictBorrowFromShared`'s
`bound` argument, B-m6 for the Debug clause, B-M5 for the W ids; amended
2026-10-28, review fold: RR1-B1, `StrictSharedImmutableWrite`'s text naming
the sub-object written, where rev 2's read "write to `{0}` of
`Core.SharedImmutable` type `{1}` through a shared path"; amended 2026-10-28,
review fold: RR2-m1, the sixth block's Debug test over every store and its
exception for a write a Permissive caller made aliasing, where rev 3's read
"It reports what unchecked code can still do, a Permissive body, C++ or an
alias an `unsafe` binding promised away, and never a Strict body's write,
which is rejected first").

<!-- google-doc-style-ignore -->

```markdown
The rows other than `StrictNotSend` and `StrictNotSync` are stage-4
diagnostics, landing with the loan checker and the `error` default; those two
are stage 5 (three rows added <date>, SAFE-2: W-348, W-349).
```

```markdown
| `StrictBorrowFromShared` (realigned <date>, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowedObjectMutated` (realigned <date>, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` |
| `StrictSharedImmutableWrite` (realigned <date>, SAFE-2: W-348) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` when a binding of the object is live |
```

```markdown
whose Debug column is ASan-class detection when the invalidation frees what a
loan reads, the value-binding report being `StrictBorrowedObjectMutated`'s
(realigned <date>, SAFE-2: W-348; this read "whose Debug column is
`MutationDuringValueBinding` for the value-binding case,"),
```

```markdown
A fourth, `StrictRefFromShared`, a `ref` binding through a shared path to an
open place, is the temporal page's too, and a `ref` payload binding through a
shared pointer raises it (M5; realigned <date>, SAFE-2: W-347).
```

```markdown
-   `StrictBorrowFromShared`: "`{0}` borrows `{1}` through a shared path;
    `{2}` is not `Core.SharedImmutable`; copy it with `var`, use an
    `exclusive` pointer, or `unsafe`", where `{0}` names the value binding or
    the `bound` pointer argument of a call (the temporal page's T5(d)), at the
    binding or the argument, with a note at the shared path's origin
    (realigned <date>, SAFE-2: W-348, W-349).
-   `StrictBorrowedObjectMutated`: "write to `{0}` while it is borrowed by the
    value binding `{1}`", at the write or at the call that receives a writable
    carrier of the object, with a note at the binding; for the frozen loan of
    a `const` `ref` or of a `bound` argument the text names that binding or
    that result (realigned <date>, SAFE-2: W-348, W-349).
-   `StrictSharedImmutableWrite`: "write to `{0}` through a shared path
    overwrites `{1}` of `Core.SharedImmutable` type `{2}`; use an `exclusive`
    pointer or `unsafe`", where `{1}` is `{0}` itself or the sub-object of it
    that holds the type, at the write, with a note at the type's opt-in (M3;
    realigned <date>, SAFE-2: W-348).
```

```markdown
under `--strict-checks=warn` or in a Permissive file, and the twin of
`StrictRefFromShared`, `StrictBorrowFromShared`, `StrictBorrowedObjectMutated`
and `StrictSharedImmutableWrite` (realigned <date>, SAFE-2: W-347, W-348);
```

```markdown
-   `MutationDuringValueBinding`: the Debug report, one line in the fail-stop
    convention of the [spatial safety](spatial_safety.md) page, "carbon:
    mutation of a borrowed object; terminating", then `abort()`; Release does
    nothing, the write being erroneous and defined. Debug tests every store
    that writes a byte of a borrowed object under a live frozen loan, of any
    type and by any path, `T*`, a `ref`, the owner, a global by name or an
    `addr self` body. It reports what unchecked code can still do, a
    Permissive body, C++ or an alias an `unsafe` binding promised away, and a
    Strict body's write only when a Permissive caller made it aliasing, as
    `F(ref x, &x)` does for a Strict `fn F(ref r: str, p: const str*)` that
    binds `*p` and then assigns `r`, which that call's
    `PermissiveAliasedExclusive` flags; any other Strict body's write is
    rejected first (realigned <date>, SAFE-2: W-348; the superseded 2026-10-12
    message read "carbon: mutation of an object during a live value binding;
    terminating").
```

<!-- google-doc-style-resume -->

Bullets plus three, table rows plus three.

### §A.2.10 safety/mutation_safety.md :522-525, Worked examples, the toolchain sentence replaced

Replace the sentence from "EX-M-4a uses only the upstream prelude and was
compiled on the" through "every other example is NEW syntax." (it names the
nightly toolchain, `carbon compile --output-last-input-only`, the missing
`package` line and EX-M-4b's `Core.Buf`) with:

<!-- google-doc-style-ignore -->

```markdown
EX-M-4a, EX-M-4c and the functions `Peek`, `Peek2` and `Peek4` of EX-M-4d use
only the upstream prelude and were compiled on the 2026.10.12 nightly
toolchain with `carbon compile --output-last-input-only` and no `package`
line, then linked and run (EX-M-4c and EX-M-4d added <date>, SAFE-2: W-348);
EX-M-4b and EX-M-4d's `BufSize` and `Peek8` use the fork prelude's
`Core.Buf`, which that toolchain lacks; every other example is NEW syntax.
```

<!-- google-doc-style-resume -->

### §A.2.11 safety/mutation_safety.md :546-566, EX-M-1

In the code block, replace the four lines from " let first: const i32* =
vec->Get(0);" through " vec->Push(3); // fine: a, b, first
are dead (NLL)" with the first block. In the prose, replace "`Get` is `bound
self` so its result is a shared loan on `*vec`." with the third block, and
replace the two sentences from "`first` is a shared loan too," through
"`vec->Push(3)` is accepted." with the second block (amended 2026-10-28,
review fold: RR3-m1: the third block adds the sentence that names `Set`'s
body path, where rev 4 replaced the `Get` sentence with "`Get` is `bound
self` so its result keeps `*vec` borrowed." alone; with `Core.Buf(T).Set`
taking `ref self`, the page's "its body is checked to do nothing else" left
the body's write unnamed).

<!-- google-doc-style-ignore -->

```carbon
  let first: const i32* = vec->Get(0);   // the bound self of Get freezes *vec while first lives (T5(d))
  // a->Set(0, 5);                // StrictBorrowedObjectMutated: an addr call on the frozen *vec while first lives (realigned <date>, SAFE-2: W-349; this line read "a->Set(0, 5);  // fine: *first now reads 5 — observable, not dangling")
  Core.Print(*first);
  a->Set(0, 5);                   // fine: first is dead (NLL), and its frozen loan with it
  vec->Push(3);                   // fine: a, b, first are dead (NLL)
```

```markdown
`first` is the result of `Get`'s `bound self`, a value binding of `*vec` whose
value representation is a pointer, so for `first`'s lifetime `*vec` is a
borrowed object under a frozen loan (the temporal page's T5(d): each `bound`
argument is immutable for the duration of the returned result), and
`a->Set(0, 5)` under it is `StrictBorrowedObjectMutated`: an `addr` call through
an alias writes the frozen object. After `Core.Print(*first)` `first` is dead,
so the same `a->Set(0, 5)` is accepted there, and once no carrier of any loan
is used again `vec->Push(3)` is accepted (realigned <date>, SAFE-2: W-349; the
superseded 2026-10-12 text read: "`first` is a shared loan too, and
`a->Set(0, 5)` under it is fine: `*first` observes the new value, which is not
a mutation safety bug, because nothing was invalidated. After
`Core.Print(*first)` no carrier of any shared loan is used again, so by
non-lexical liveness the loans are dead and `vec->Push(3)` is accepted.").
```

```markdown
`Get` is `bound self` so its result keeps `*vec` borrowed. `Set`'s body
writes the element through the private `buf` with no exclusive access to it,
which a `Plain` `i32` element, another object's storage, does not need
([Value bindings](#value-bindings)): as
`*self->buf.AsSlice().Subslice(i, i + 1).Data() = v;` until the indexing
interface `IndirectIndexWith` lands, and as `self->buf[i] = v` after it, its
`Ref` taking `bound self` under residue item W-144; `self->buf.Set(i, v)`
would be `StrictInvalidatingThroughShared` (M3(d)), `Core.Buf(T).Set` taking
`ref self` (realigned <date>, SAFE-2: W-349, W-348; the superseded 2026-10-12
text read: "`Get` is `bound self` so its result is a shared loan on
`*vec`.").
```

<!-- google-doc-style-resume -->

### §A.2.12 safety/mutation_safety.md :615-634, EX-M-4a

Rename the heading "### EX-M-4a: A `Plain` value binding" to "### EX-M-4a: A
value binding that copies". Replace the code block's first two comment lines,
"// EX-M-4a (today's syntax; accepted today and in Strict — amended 2026-10-12,
review fold: A-8, B3:" and "// i32 is Plain, the binding copies eagerly
(D-SAFE-17), there is no loan to invalidate; b is 1)", with the first block
(amended 2026-10-28, review fold: RR1-m2: the 2026-10-12 mark "A-8, B3" moved
into the quoted superseded comment, off the rewritten one). Replace "Rule M8,
the `Plain` case. `i32` is `Plain`, so `b` acquires eagerly and holds no
loan;" with the second block.

<!-- google-doc-style-ignore -->

```carbon
// EX-M-4a (today's syntax; accepted today and in Strict — realigned <date>, SAFE-2: W-348: i32's value representation is a copy,
// so the binding holds no loan; b is 1; this comment read "amended 2026-10-12, review fold: A-8, B3: i32 is Plain, the binding copies eagerly (D-SAFE-17), there is no loan to invalidate; b is 1")
```

```markdown
Rule M8, the copy case. `i32`'s value representation is a copy, so `b` read
the value when it was bound and holds no loan (the heading read "A `Plain`
value binding" and this sentence "Rule M8, the `Plain` case. `i32` is `Plain`,
so `b` acquires eagerly and holds no loan;" before <date>, SAFE-2: W-348);
```

<!-- google-doc-style-resume -->

### §A.2.13 safety/mutation_safety.md :636-659, EX-M-4b

Rename the heading "### EX-M-4b: A non-`Plain` value binding" to "### EX-M-4b:
A value binding that borrows". In the code block replace the comment line "//
EX-M-4b (fork-prelude syntax; accepted today — M8: a non-Plain value binding is
a shared loan)" and the line " let b: Core.Buf(i32) = a; // shared loan
on a for b's lifetime (T2)" with the first block. In the prose replace "Rule
M8, the non-`Plain` case. `Core.Buf(i32)` is not `Plain`, so `b` is a shared
loan on `a` for its lifetime, which extends to `b.Size()` on the last line."
with the second block, and "Debug reports the stale read if it happens." with
"Debug reports `MutationDuringValueBinding` at the write in a Permissive body."

<!-- google-doc-style-ignore -->

```carbon
// EX-M-4b (fork-prelude syntax; accepted today — M8: a Core.Buf binding borrows its object under a frozen loan; realigned <date>, SAFE-2: W-348, was "a non-Plain value binding is a shared loan")
fn ValueBinding2() -> i64 {
  var a: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  let b: Core.Buf(i32) = a;       // frozen loan on a for b's lifetime (T2)
```

```markdown
Rule M8, the borrowing case. `Core.Buf(i32)` is a class, whose value
representation is a pointer, so `b` binds `a` as a borrowed object under a
frozen loan for its lifetime, which extends to `b.Size()` on the last line
(realigned <date>, SAFE-2: W-348; the heading read "A non-`Plain` value
binding", and the superseded 2026-10-12 text read "Rule M8, the non-`Plain`
case. `Core.Buf(i32)` is not `Plain`, so `b` is a shared loan on `a` for its
lifetime").
```

<!-- google-doc-style-resume -->

(The first block's last two lines repeat the unchanged `fn` and `var` lines so
the anchor is unambiguous; only the comment and the `let` line change.)

### §A.2.14 safety/mutation_safety.md :660, EX-M-4c and EX-M-4d inserted

Insert before "### EX-M-5: Payload references through a shared path" (EX-M-4d's
`Peek4` and its paragraph amended 2026-10-28, review fold: RR1-B1; `Peek8`,
the fork-prelude shape of a trusted writer, and its sentences amended
2026-10-28, review fold: RR2-B1):

<!-- google-doc-style-ignore -->

````markdown
### EX-M-4c: A `Plain` write to a borrowed object

```carbon
// EX-M-4c (today's syntax; accepted today — added <date>, SAFE-2: W-348): the Plain write left erroneous before is rejected
fn ValueBinding3() -> i32 {
  var a: {.n: i32, .o: Core.Optional(i32)} = {.n = 1, .o = Core.Optional(i32).None()};
  let b: {.n: i32, .o: Core.Optional(i32)} = a;   // two elements: a pointer representation, so b borrows a under a frozen loan
  a.n = 2;                                        // Strict: StrictBorrowedObjectMutated (b is live below)
  return b.n;
}
```

Rule M8, the frozen loan on a closed place. The struct has two elements and
its `Core.Optional(i32)` element's value representation is a pointer, so
today's toolchain represents the struct's values by a pointer to a separate
aggregate of the element values (upstream
toolchain/check/type_completion.cpp:580-582 and :597-609 at 0421bf3b4), not a
copy, and `b` binds `a` as a borrowed object; `a` is an owner, a closed place,
and the `Plain` assignment
`a.n = 2` writes the borrowed object's storage while `b` lives, which Strict
rejects with `StrictBorrowedObjectMutated` and Permissive warns
`PermissiveAliasedExclusive`. Nothing is invalidated: the program is
memory-safe either way, and the rejection is proposal p005434's prevention of
an erroneous mutation, not a memory-safety repair. Outcome: ACCEPTS-UNCHECKED —
the nightly compiles it with exit status 0 and no diagnostic, and with a `Run`
that prints `ValueBinding3()` the linked program prints `1`: the toolchain
copied the `i32` element into the aggregate it built at the binding, one of the
outcomes the erroneous behavior allows. The fix is a copy,
`var b: {.n: i32, .o: Core.Optional(i32)} = a;`. Stage 4.

### EX-M-4d: A borrowed object through a shared pointer

```carbon
// EX-M-4d (Peek, Peek2, Peek4: today's syntax, accepted today; BufSize, Peek8: fork prelude — added <date>, SAFE-2: W-348)
fn Peek(p: {.n: i32, .o: Core.Optional(i32)}*, q: {.n: i32, .o: Core.Optional(i32)}*) -> i32 {
  let v: {.n: i32, .o: Core.Optional(i32)} = *p;  // Strict: StrictBorrowFromShared — *p is an open place, and a struct is never Core.SharedImmutable
  q->n = 2;                                       // the write the rule exists for: q may be p
  return v.n;
}
fn BufSize(p: Core.Buf(i32)*) -> i64 { return p->Size(); }   // accepted: Core.Buf(i32) is Core.SharedImmutable (W-144), so self binds frozen on the open *p
fn Peek2(p: const str*, q: str*) -> i64 {
  let s: str = *p;                                // accepted: str, the prelude's Core.String, is Core.SharedImmutable, so s binds frozen on the open *p
  *q = "longer";                                  // Strict: StrictSharedImmutableWrite (M3) — q may be p
  return s.Size();
}
fn Peek4(p: {.s: str, .n: i32}*, q: {.s: str, .n: i32}*) -> i64 {
  let s: str = p->s;                              // accepted: s binds frozen on the open p->s, str being Core.SharedImmutable
  *q = {.s = "longer", .n = 1};                   // Strict: StrictSharedImmutableWrite (M3) — the struct holds a str, and q may be p
  return s.Size();
}
fn Peek8(b: Core.Buf(str)*) -> i64 {
  let s: str = *b->AsSlice().Data();              // accepted: s binds frozen on the open element, str being Core.SharedImmutable
  b->Set(0, "longer");                            // Strict: StrictInvalidatingThroughShared — Set takes ref self (W-144), so no trusted body writes the element s borrows
  return s.Size();
}
```

Rule M8, the open place. In `Peek`, `p` and `q` are shared pointers that may
alias, and nothing the body can see says whether they do, so the frozen loan
`v` needs cannot be established on `*p`: the binding is
`StrictBorrowFromShared`, and the fixes are `var v: ... = *p;`, an `exclusive`
parameter, or `unsafe *p` with its obligation. In `BufSize`, the by-value
`Size` binds `*p` the same way, and `Core.Buf(i32)`'s opt-in to
`Core.SharedImmutable` makes it sound: no path but an exclusive one writes a
`Buf`'s storage, and the live shared path `p` excludes those. `Peek2` is the
other half of that promise: `str` opts in too, so `s` binds frozen on the open
`*p`, and the write the opt-in would otherwise let through, a `Plain`
assignment of the whole `str` through the shared `q`, is rejected by M3 with
`StrictSharedImmutableWrite`. `Peek4` is the same write one level up: the
struct `{.s: str, .n: i32}` is `Plain` and is not `Core.SharedImmutable`, but
it holds a `str`, so the whole-struct assignment through `q` writes the
storage `s` borrows and M3 rejects it with `StrictSharedImmutableWrite`; a
class with a `str` field is rejected the same way. `Peek8` is the same write
made by a trusted body: `s` binds an element of the block frozen, and the
by-value `Set` of the 0.1 prelude would write that element through the block's
pointer, so the prelude keeps M3's rule too ([Value bindings](#value-bindings))
and `Set` takes `ref self`, an exclusive receiver, which the shared `b` cannot
provide (M3(d)); with `b: exclusive Core.Buf(str)*` the call is
`StrictSharedBorrowInvalidated` while `s`, which carries the view's loan on
`*b`, lives, and is accepted after `s`'s last use. Outcome: `Peek`, `Peek2`
and `Peek4` ACCEPTS-UNCHECKED — the nightly compiles all three with exit
status 0; `Peek(&a, &a)` for `a.n == 1` prints `1`, `Peek2(&x, &x)` for
`x == "ab"` prints `6`, and `Peek4(&y, &y)` for `y == {.s = "ab", .n = 0}`
prints `6`, `s` reading the string `q` wrote, the erroneous behavior Strict
now prevents; `BufSize` and `Peek8` are fork prelude, not compile-verified in
this PR, and a class of `Peek8`'s shape, a `str*` field with a by-value `Set`
writing through it, prints `6` on the same nightly. Stage 4, with W-144 for
the opt-ins and `Set`'s receiver.
````

<!-- google-doc-style-resume -->

Headings H3 plus two.

### §A.2.15 safety/mutation_safety.md :661-683, EX-M-5

Rename the heading "### EX-M-5: Payload references through a shared path" to
"### EX-M-5: Payload bindings through a shared path". Replace the code block's
body, the four lines from "// EX-M-5 (NEW-SYNTAX: payload `match` on
Core.Optional," through "}", with the first block. In the prose replace "Rule
M5. `c` is a shared pointer, so the `match` through `*c` binds `s` as a shared
sub-loan on `*c`'s payload; while `s` lives" with the second block, and
"`case .Some(ref s)` does not parse against the fork prelude" with "the
`case .Some(...)` pattern does not parse against the fork prelude".

<!-- google-doc-style-ignore -->

```carbon
// EX-M-5 (NEW-SYNTAX: payload `match` on Core.Optional, which is not a choice today, optional.carbon:64-68 — RR-4; Core.Buf per B2;
// realigned <date>, SAFE-2: W-347 — a value payload through a shared path, where `case .Some(ref s)` is StrictRefFromShared): payload bindings through a shared path
fn Alt(c: Core.Optional(Core.Buf(i32))*) {
  match (*c) { case .Some(s: Core.Buf(i32)) => { Core.Print(s.Size()); } default => {} }   // frozen sub-loan on the payload (Core.Buf is Core.SharedImmutable, W-144); *c cannot change alternative while s lives (M3(c): Optional is non-Plain)
}
```

```markdown
Rule M5. `c` is a shared pointer to an open place, so a `ref` payload binding
through `*c` would be `StrictRefFromShared`, and the program binds the payload
by value: `s` binds a `Core.Buf(i32)`, whose value representation is a pointer,
so it is a borrowed object, and the frozen sub-loan stands on the open place
because `Core.Buf` is `Core.SharedImmutable` (realigned <date>, SAFE-2: W-347;
the superseded 2026-10-12 text read "Rule M5. `c` is a shared pointer, so the
`match` through `*c` binds `s` as a shared sub-loan on `*c`'s payload;"). While
`s` lives
```

<!-- google-doc-style-resume -->

### §A.2.16 safety/mutation_safety.md :685-713, EX-M-6

Replace the code block's body, from "// EX-M-6 (regression, review A-3;"
through the closing "}" of `Alt2`, with the first block. In the prose replace
the two sentences from "The `match` through `*c` binds `p` as a shared
sub-loan on the payload." through "regardless of whether any `match` is
active." with the second block.

<!-- google-doc-style-ignore -->

```carbon
// EX-M-6 (regression, review A-3; NEW-SYNTAX for the same reason as EX-M-5, RR-4; realigned <date>, SAFE-2: W-347 —
// the payload binds by value, a copied i32*, where it was `case .Some(ref p)`): the alternative cannot change through another shared alias either
fn Alt2(c: Core.Optional(i32*)*, d: Core.Optional(i32*)*) {   // two shared T* to one object: allowed
  match (*c) {
    case .Some(p: i32*) => {
      *d = Core.Optional(i32*).None();   // StrictInvalidatingThroughShared: Optional(i32*) is not Plain (D-SAFE-9, A-3)
      Core.Print(*p);
    }
    default => {}
  }
}
```

```markdown
The `match` through `*c` binds `p` by value: a pointer is copy-represented, so
`p` is a copy and holds no loan on the payload, where a `ref p` would be
`StrictRefFromShared` through the shared `c` (M5), and the 2026-10-12
program's `Core.Print(**p)` through the `ref` becomes `Core.Print(*p)`.
`*d = Core.Optional(i32*).None()` would change the alternative of the object
`c` and `d` share, which under a live payload binding is the second mutation
safety bug of the [definition](#definition), and the rule that catches it is
not a special rule about sums: `Optional(i32*)` is non-`Plain`, so the
assignment through the shared `d` is `StrictInvalidatingThroughShared`
regardless of whether any `match` is active (realigned <date>, SAFE-2: W-347;
the superseded 2026-10-12 text read: "The `match` through `*c` binds `p` as a
shared sub-loan on the payload. `*d = Core.Optional(i32*).None()` would change
the alternative under `p`, the second mutation safety bug of the
[definition](#definition), and the rule that catches it is not a special rule
about sums").
```

<!-- google-doc-style-resume -->

### §A.2.17 safety/mutation_safety.md :717-725, the checklist table

Replace the rows whose first cells are "M8 value binding, `Plain`", "M8 value
binding, non-`Plain`" and "M5 payload refs" with the block (two rows added).
The first cells are the ones §4.1 of fork/safe/plan.md uses (B.3.6), word for
word, and each mark names its W id (amended 2026-10-28, review fold: B-m4,
B-M5):

<!-- google-doc-style-ignore -->

```markdown
| M8 value binding, copy representation (realigned <date>, SAFE-2: W-348) | EX-M-4a | ACCEPTS (today and in Strict; `b` is 1) | — |
| M8 value binding, borrowed object (realigned <date>, SAFE-2: W-348) | EX-M-4b | ACCEPTS-UNCHECKED (fork prelude) | 4 |
| M8 `Plain` write to a borrowed object (added <date>, SAFE-2: W-348) | EX-M-4c | ACCEPTS-UNCHECKED (nightly exit 0, prints 1) | 4 |
| M8 borrowed object through a shared pointer, `Core.SharedImmutable` (added <date>, SAFE-2: W-348) | EX-M-4d | ACCEPTS-UNCHECKED for `Peek`, `Peek2` and `Peek4` (nightly exit 0, print 1, 6 and 6); `BufSize` and `Peek8` fork prelude | 4 (W-144) |
| M5 payload bindings (realigned <date>, SAFE-2: W-347) | EX-M-5 | NEW-SYNTAX | 4 plus the `Optional` redesign |
```

<!-- google-doc-style-resume -->

The EX-M-4d row names `Peek4` (amended 2026-10-28, review fold: RR1-B1) and
`Peek8` among the fork-prelude functions (amended 2026-10-28, review fold:
RR2-B1), as B.3.6's row does.

### §A.2.17a safety/mutation_safety.md :734-747, C++ interop consequence, a sentence appended to the partition bullet

Added 2026-10-28, review fold: RR3-m1: the bullet at :734-747 partitions a
migrated class's methods into `addr self` ones, "the element writes and other
non-invalidating mutations", and `ref self` ones, and M3's paragraph (A.2.4a)
now gives an element write of a type that holds a `Core.SharedImmutable`
sub-object exclusive access. Append the block to the bullet, after "can call
exactly the methods that cannot invalidate its other pointers." and a space,
keeping the bullet's four-space indentation (no heading, list item or row
added):

<!-- google-doc-style-ignore -->

```markdown
An element write takes `addr self` only when the element type holds no
`Core.SharedImmutable` sub-object (M3): a setter of a `str` element, like a
setter of a `str` field (M4), takes `ref self` although it invalidates
nothing, as `Core.Buf(T).Set` does for every element type
([Value bindings](#value-bindings); added <date>, SAFE-2: W-348).
```

<!-- google-doc-style-resume -->

### §A.2.18 safety/mutation_safety.md :797, Implementation staging, row 4 replaced

<!-- google-doc-style-ignore -->

```markdown
| 4 | The loan checker (W-148) | M1 to M5: `Core.Plain` synthesis, `StrictInvalidatingThroughShared` with its twin `PermissiveAliasedExclusive`, M3's `StrictSharedImmutableWrite`, the `addr` body check of M4, payload sub-loans of M5; M8: the frozen loan of a borrowed object, `StrictBorrowedObjectMutated` and `StrictBorrowFromShared`, `Core.SharedImmutable` with the prelude's opt-ins (W-144), and the Debug shadow count behind `MutationDuringValueBinding` (realigned <date>, SAFE-2: W-348); M6: `Core.Guarded(T)` under W-144 |
```

<!-- google-doc-style-resume -->

### §A.2.19 safety/mutation_safety.md :811-853, Decisions

Replace the D-SAFE-17 bullet (from "**D-SAFE-17 — Value bindings through
shared pointers.**" through "alternative is adopted for every type.") with the
first block. In the D-SAFE-9 bullet replace "Invalidating operations require
exclusive access; everything else is permitted through any number of aliases."
with "Invalidating operations require exclusive access, and so does every
assignment whose type holds a `Core.SharedImmutable` sub-object (M3,
D-SAFE-17; added <date>, SAFE-2: W-348); everything else is permitted through
any number of aliases." (amended 2026-10-28, review fold: A-B-1; amended
2026-10-28, review fold: RR1-B1, where rev 2 read "and so do the writes of a
`Core.SharedImmutable` type's storage"). In the D-SAFE-20 bullet replace "and
`Core.Box(T)` are this page's items;" with "`Core.Box(T)` and
`Core.SharedImmutable` (opt-in only, implying `Core.Freeze`; added <date>,
SAFE-2: W-348) are this page's items;". In the closing paragraph replace "the
pointer kinds and the `ref`-kind inheritance of M1 are D-SAFE-7 and D-SAFE-8,"
with the second block. (The first block's trusted-body clause and its break
condition amended 2026-10-28, review fold: RR2-B1, where rev 3 read "which the
prelude takes for `String` and, for a `Freeze` argument, `Slice`, `Buf` and
`Optional`, and for `Box` when W-144 adds it)" and "or a prelude opt-in is
shown false".)

<!-- google-doc-style-ignore -->

```markdown
-   **D-SAFE-17 — Value bindings through shared pointers.** A value binding of
    a type whose value representation is a copy holds no loan; any other binds
    a borrowed object (proposal p005434) under a frozen loan for its lifetime,
    so Strict prevents every mutation of the object through any path,
    `StrictBorrowedObjectMutated` or, for an invalidating one,
    `StrictSharedBorrowInvalidated`; the loan is formed on a closed place, or
    on an open place for a `Core.SharedImmutable` type (an `unsafe impl` opt-in
    whose storage M3 lets no shared-path assignment write, of the type or of
    one that holds it, which the prelude takes for `String`
    and, for a `Freeze` argument, `Slice`, `Buf` and `Optional`, and for `Box`
    when W-144 adds it, its trusted bodies keeping the same write rule, so
    that `Buf`'s `Set` takes `ref self`), and the binding is
    `StrictBorrowFromShared` otherwise; a binding from a
    materialized temporary owns the storage. This is proposal p005434's plan to
    prevent mutation of borrowed objects in the strict dialect, kept. Break
    condition: upstream relaxes p005434:663 under its :665-669 conditions, or a
    prelude function is shown to write such storage through a shared path, an
    element of a block it owns included, which is answered by fixing that
    function (realigned <date>, SAFE-2: W-348; the
    superseded 2026-10-12 text read: "A `Plain` value binding copies eagerly
    and holds no loan; a non-`Plain` one from `*p` or an owner is a shared loan
    under which invalidating operations are rejected and `Plain`-field writes
    through other aliases stay erroneous and Debug-detected; one from a
    materialized temporary owns the storage. This narrows proposal p005434's
    plan to prevent all mutation of borrowed objects in the strict dialect.
    Break condition: a demonstrated memory-safety (not correctness) consequence
    — then the eager-copy alternative is adopted for every type.").
```

```markdown
the pointer kinds and the `ref` rule of M1 are D-SAFE-7 and D-SAFE-8 (the
latter realigned <date>, SAFE-2: W-347, where this text read "the `ref`-kind
inheritance of M1"),
```

<!-- google-doc-style-resume -->

### §A.2.20 safety/mutation_safety.md :885-907, Alternatives

In the "Attempt B's single pointer kind" bullet append, after the sentence that
ends "which D-SAFE-17 does under" and a link to the Value bindings section, the
sentence "D-SAFE-17 was
realigned <date> by SAFE-2 (W-348) to proposal p005434's rule for borrowed
objects." Replace the bullet that begins "**Preventing all mutation of
borrowed objects.**" and ends "the recorded alternative of D-SAFE-17 and its
break condition." with:

<!-- google-doc-style-ignore -->

```markdown
-   **Narrowing the prevention to invalidating mutation.** The rule of
    2026-10-12 rejected only the invalidating mutations of a non-`Plain` value
    binding's object and left `Plain`-field writes through other aliases
    erroneous and Debug-detected, on the argument that such a write frees
    nothing a binding may read. Withdrawn <date> by SAFE-2 (W-348) under
    rulebook R32: proposal p005434 plans to prevent mutation of borrowed
    objects in the strict dialect and keeps relaxing that plan to itself
    (p005434:663-669), so a memory-safety argument is a cost to record, not a
    license; the realigned rule is [Value bindings](#value-bindings). Two
    further alternatives stay rejected: eager acquisition for every type,
    because a non-`Copy` type such as `Core.Buf` cannot be copied and an
    implicit deep copy is the cost the values design says values exist to
    avoid, where a type that wants copies says so with `value_rep = const Self`;
    and a structural, compiler-derived `Core.SharedImmutable`, because its
    soundness rests on declaration conditions and a body rule whose corners an
    opt-in states as the author's obligation. (The superseded 2026-10-12 bullet
    read: "**Preventing all mutation of borrowed objects.** Proposal p005434's
    plan for the strict dialect, taken literally, would reject a `Plain`-field
    write through any alias during a non-`Plain` value binding and would make a
    value binding of `i32` a loan. The first is rejected because it prevents
    nothing a memory-safety argument needs and would reject the aliased `Set`
    of EX-M-1 whenever a value binding of the container is live; the second
    contradicts the eager copy the toolchain performs today (EX-M-4a). The
    eager-copy-for-every-type rule is the recorded alternative of D-SAFE-17 and
    its break condition.")
```

<!-- google-doc-style-resume -->

### §A.2.21 safety/mutation_safety.md :935-936, References

Replace "for `ref`, `addr` and the mutation restriction on borrowed objects that
D-SAFE-17 narrows." with:

<!-- google-doc-style-ignore -->

```markdown
    for `ref`, `addr` and the mutation restriction on borrowed objects that
    D-SAFE-17 keeps as its rule (realigned <date>, SAFE-2: W-348; this text read
    "that D-SAFE-17 narrows").
```

<!-- google-doc-style-resume -->

### §A.3.1 safety/temporal_safety.md :86-89, the status paragraph, a sentence appended

Append after "the examples marked "today's syntax" were compiled on
the 2026.10.12 nightly toolchain and their outcomes are stated with each
example.":

<!-- google-doc-style-ignore -->

```markdown
The `ref` bindings section, T2, T4, T8, T5(a) and (d), and the examples they
decide were realigned <date> by fork workstream SAFE-2 to proposal p005434's
rules: every `ref` binding is `nocapture` and `noalias`, Strict prevents
mutation of borrowed objects, and each `bound` argument is immutable for the
duration of the returned result (W-347, W-348, W-349;
fork/safe/safe2-plan.md); each realigned passage quotes the text it
supersedes.
```

<!-- google-doc-style-resume -->

### §A.3.2 safety/temporal_safety.md :93-119, Vocabulary

Replace "The rules use seven words, fixed by D-SAFE-10." with the first block;
replace the loan bullet (from "A _loan_ is a triple of a place," through
"which the diagnostics name.") with the second block; insert the third block
after the interior-loan bullet (which ends "and an invalidating operation on the
owner kills it."). Bullets plus one. (The frozen loan of a `bound` pointer
argument's pointee in the second block amended 2026-10-28, review fold:
RR1-m1, and the global in the third, review fold: RR1-m4.)

<!-- google-doc-style-ignore -->

```markdown
The rules use seven words, fixed by D-SAFE-10, and two more, _closed_ and
_open_, added <date> by SAFE-2 (W-347, W-348).
```

```markdown
-   A _loan_ is a triple of a place, a _kind_ and an _origin_. The kind is
    _exclusive_, _shared_ or _frozen_. A frozen loan is the loan of a borrowed
    object or of a `const` `ref`, under which no path writes the place's
    storage, or the loan a call's result holds on the pointee of a `bound`
    `T*` or `const T*` argument, under which no path but the result and the
    carriers copied from it writes the pointee, the result's own access being
    at the kind T5(a) gives its parameter (T5(d); added <date>, SAFE-2: W-348,
    W-349); the origin is the expression that formed the loan, which the
    diagnostics name.
```

```markdown
-   A place is _closed_ in a function body when every carrier of a loan on it
    is in the body's view: the body's own owners, local `var`s, `var`
    parameters and temporaries, and their sub-objects, the referents of its
    `ref` parameters and of `ref self`, the pointees of its `exclusive T*`
    parameters, and every place reached through a carrier whose loan set holds
    only closed places, such as `*p` for a local `let p: T* = &x;`. Every other
    place is _open_: one reached through a `T*` or `const T*` parameter or
    `addr self`, through a pointer loaded from memory or returned by a call
    whose loan set is not closed, through a free loan, a global among them, or
    through ⊥. An
    exclusive or a frozen loan is formed on a closed place, where T4 sees every
    carrier; on an open place it is an `unsafe` operation, except a frozen loan
    on a `Core.SharedImmutable` type, whose shared-path writes the mutation
    page's M3 rejects (M8). A carrier of a
    closed place cannot escape it: the Store rule keeps a loan on a local out
    of every destination it does not outlive, and T5(b) keeps a non-`bound`
    parameter in (added <date>, SAFE-2: W-347, W-348).
```

<!-- google-doc-style-resume -->

### §A.3.3 safety/temporal_safety.md :146 and :173-174, Pointer kinds and receivers

Insert the first block after the kinds table (whose last row's first cell is
"unverified (any kind)") and before "`&x` on a place under exclusive access —
an owner, a `ref` binding, or `*p` for". Replace "`ref self: const Self` and
by-value `self` are const access." with the second block. The first block is
A.1.5's words with this page's own cites, its last clause amended with A.1.5's
(2026-10-28, review fold: RR1-B1; and `Core.Slice(T)` conditioned on a
`Core.Freeze` `T`, 2026-10-28, review fold: RR2-m3).

<!-- google-doc-style-ignore -->

```markdown
Every `ref` binding is exclusive access to its referent, or a frozen read of it
when its type is `const`, whatever its source, and a value binding of a type
whose value representation is not a copy binds a borrowed object, frozen for
the binding's lifetime. Through `T*` or `const T*` such a binding is formed
only on a closed place or, for a frozen one, a `Core.SharedImmutable` type, and
is an `unsafe` operation otherwise, so the `const T*` row's receivers meet that
rule when they are called through a shared pointer (T2); and the `T*` row's
`Plain` writes exclude every assignment whose type holds a
`Core.SharedImmutable` sub-object, a `Core.String`, a `Core.Slice(T)` for a
`Core.Freeze` `T`, or a struct, tuple, array or class holding one, which only
an exclusive path makes (the mutation page's M3; realigned <date>, SAFE-2:
W-347, W-348).
```

```markdown
`ref self: const Self` and by-value `self` are const access, and a call of
either binds `self` under the rules of [`ref` bindings](#ref-bindings) and T2
(realigned <date>, SAFE-2: W-347, W-348).
```

<!-- google-doc-style-resume -->

### §A.3.4 safety/temporal_safety.md :191-218, `ref` bindings, the section body replaced

(Amended 2026-10-28, document-review fold: R1-M1, R1-m1, R1-m2, R2-m2. The
block below is commit 1's text. Since 0f281d8bd and e1574b003 the page's
section also holds the paragraph on a built-in operator's `ref` operand, the
kinds of the `Valid1` and `ValToRef` results, the frozen kind in the
weakest-kind rule, `UsePick`'s `StrictSharedBorrowInvalidated`, and its second
and sixth superseded sentences quoted in full, as section 8.7 records.)

Keep the heading "## `ref` bindings"; replace its two paragraphs and the
"Narrowing" blockquote, from "A `ref` binding inherits the kind of its source
(D-SAFE-8)." through "because a shared-kind `ref` is, by construction, one alias
among many.", with the block (its "a global" amended 2026-10-28, review fold:
RR1-m4):

<!-- google-doc-style-ignore -->

```markdown
Every `ref` binding is exclusive access to its referent for its lifetime, as
proposal p005434 states: "The address of a `ref` binding is `nocapture` and
`noalias`" (p005434:83), where `noalias` "means like C `restrict`; you can't
observe mutations through aliases; mutation through a restricted pointer is not
observable through another pointer" (p005434:850-852). A `ref` of a `const`
type is the read-only case: its loan is frozen, so no path writes the referent
while it lives and other paths may read it; any other `ref` holds an exclusive
loan, so no other path reads or writes the referent. A `ref` binding not
marked `bound` does not escape, `captures(none)`, and one marked `bound`
escapes only into the result, `captures(ret: address, provenance)`
(p005434:846-848; T5(b)). The binding's source does not change this, and the
proposal's rule that "A `ref` binding may only bind to a durable reference
expression or an expression that can be converted to one. The bound durable
reference expression must outlive the `ref` binding." is kept; the source
decides only whether the checker can establish it. On a closed place
([Vocabulary](#vocabulary)), an owner, the referent of a `ref`, the pointee of
an `exclusive T*`, or `*p` for a local `p` whose loans are closed, the binding
is a checked reborrow: forming it suspends every other carrier of the place
(T2), and T4 rejects any use of them that the binding excludes. A `const` `ref`
on an open place of a `Core.SharedImmutable` type is checked the same way. Any
other `ref` on an open place, `*p` for a `T*` or `const T*` parameter, a
pointer loaded from memory, a global, a free or ⊥ pointer, is an `unsafe`
formation, spelled at the binding as T6 spells a binding through a ⊥ carrier
(`let ref r: T = unsafe *p;`, or `unsafe F(ref *p)` for a `ref` argument),
whose obligation is the one the proposal gives unsafe code, to "adhere to just
the `noalias` restrictions" (p005434:861-862); unmarked, it is
`StrictRefFromShared` in Strict and its twin `PermissiveAliasedExclusive` in
Permissive. EX-TM-9 is the proposal's own example through a shared pointer.

A `ref` _return_ is not a binding. The proposal's
`Valid1(bound p: i32*) -> ref i32 { return *p; }` and
`ValToRef(bound y: C) -> ref D { return *y.ptr; }` return a reference
expression to an open place and stay valid in both modes; the call's result
has the kind of its loans, shared here, and using it is using `*p` (the
mutation page's M3 applies). A call of either is checked by T5(d): while the
result lives, the `bound` argument is written by no path but the result, so a
call through a shared pointer to an open place of a type that is not
`Core.SharedImmutable`, `Valid1(p)` for a parameter `p: i32*`, is
`StrictBorrowFromShared` (added <date>, SAFE-2: W-349). A result whose loan
set mixes kinds has the
**weakest** kind: shared if any loan in the set is shared. The proposal's
`Conditional(b: bool, bound ref r: C, bound p: C*) -> ref C` carries the set
`{(r, exclusive), (*p, shared)}`, so its result is a shared-kind reference
expression, and T4 applies to every place in the set. Binding such a result
with `let ref` is a `ref` binding like any other: checked when every place in
the set is closed, `unsafe` otherwise. The program `Pick`/`UsePick` of EX-TM-8
is the closed case: `z` is an exclusive `ref` on both `x` and `y`, which
conflicts with the live `q2` (`StrictExclusiveBorrowConflict`).

> **Realigned (fork amendment <date>, SAFE-2: W-347, F-013 D-SAFE-8).** This
> section states proposal p005434:83 for every `ref` binding. The superseded
> 2026-10-12 section read, in the sentences that stated the narrowed rule: "A
> `ref` binding inherits the kind of its source (D-SAFE-8). A `ref` formed from
> a place is exclusive access, as p005434 states and this design keeps" / "A
> `ref` formed from `*p` inherits `p`'s kind: exclusive from `exclusive T*`,
> shared-mutable from `T*`, under which the mutation page's M3 applies to every
> use of the binding, and const from `const T*`. So the proposal's
> `Valid1(bound p: i32*) -> ref i32 { return *p; }` and its
> `ValToRef(bound y: C) -> ref D { return *y.ptr; }` stay valid in both modes,
> the result being a shared-kind `ref`: a `ref` through which an invalidating
> operation is rejected but a `Plain` write is not." / "A `ref` or a call
> result whose loan set mixes kinds has the **weakest** kind: shared if any
> loan in the set is shared, const if any is const." / "and so is a
> shared-kind `ref`" / "The program `Pick`/`UsePick` of EX-TM-8 is this rule's
> example: a non-`Plain` assignment through such a `ref` is
> `StrictInvalidatingThroughShared` regardless of whether any other view is
> live." Its blockquote read: "**Narrowing (fork amendment 2026-10-12, F-013
> D-SAFE-8).** Proposal p005434 states (p005434:83) that "the address of a
> `ref` binding is `nocapture` and `noalias`". This design emits `noalias` and
> `captures(none)` only for exclusive-kind refs, and only under the conditions
> of T8 below; a shared-kind `ref` carries neither attribute. The proposal's
> sentence is kept for the exclusive kind and narrowed for the rest, because a
> shared-kind `ref` is, by construction, one alias among many."
```

<!-- google-doc-style-resume -->

### §A.3.5 safety/temporal_safety.md :247-289, T2

Replace the bullet "`let ref r = x;` forms an exclusive loan on `x`", which
ends with a parenthesized link to the `ref` bindings section, with the first
block; replace the
value-binding bullet, from "A value binding of a non-`Plain` type, from
`*p` or from an owner, forms a" through "bound value are unaffected in every
case.", with the second block; append the third block to the "**Reborrow.**"
paragraph after "and `vec->Push(3)` is legal only once every derived view is
dead.".

<!-- google-doc-style-ignore -->

```markdown
-   `let ref r = x;` forms an exclusive loan on `x`, and a `ref` of a `const`
    type a frozen one; a `ref` formed from `*p` or from a call's result forms
    the same loan on every place in the source's loan set when each is closed,
    suspending the source carrier as the reborrow clause below does, and is
    the `unsafe` formation of [`ref` bindings](#ref-bindings) otherwise
    (realigned <date>, SAFE-2: W-347; this bullet read "`let ref r = x;` forms
    an exclusive loan on `x`").
```

```markdown
-   A value binding of a type whose value representation is not a copy binds a
    borrowed object and forms a frozen loan on it for the binding's lifetime,
    on a closed place, or on an open place when the type is
    `Core.SharedImmutable` (D-SAFE-17, rule M8 of the mutation page); a value
    binding of a copy-represented type holds no loan, the value having been
    read; and a value binding from an initializing expression — a materialized
    temporary, the third source
    [values](../values.md#binding-patterns-and-local-variables-with-let-and-var)
    names — takes ownership of the materialized storage, the `var` rule
    applied to `let`, and holds no loan on it. The loans carried _by_ the
    bound value are unaffected in every case (realigned <date>, SAFE-2: W-348;
    the superseded 2026-10-12 text read: "A value binding of a non-`Plain`
    type, from `*p` or from an owner, forms a shared loan on the bound object
    for the binding's lifetime (D-SAFE-17, rule M8 of the mutation page); a
    value binding of a `Plain` type copies eagerly and holds no loan; and a
    value binding of a non-`Plain` type from an initializing expression").
```

```markdown
A frozen loan derived from an exclusive carrier, a by-value `bound self` of a
borrowed type or a value binding of `*p`, suspends it further: until the frozen
loan is dead the carrier may only be read, so EX-M-1's `a->Set(0, 5)` while
`first` lives is `StrictBorrowedObjectMutated` (realigned <date>, SAFE-2:
W-348, W-349).
```

<!-- google-doc-style-resume -->

### §A.3.6 safety/temporal_safety.md :305-317, T4, the paragraph replaced

Replace the paragraph from "A live exclusive loan excludes every other access
to overlapping places," through "place is under." with:

<!-- google-doc-style-ignore -->

```markdown
A live exclusive loan excludes every other access to overlapping places,
except through the suspended carrier at the kind the reborrow clause of T2
allows: a second loan or a direct use while one is live is
`StrictExclusiveBorrowConflict`. A live shared loan excludes exclusive loans
and invalidating operations on overlapping places — destruction, `~`,
assignment of a non-`Plain` value, a `ref self` call, formation of an exclusive
loan, the mutation page's rule M3 — and an invalidating operation on a place
`P` kills every interior loan on `P`: the operation is
`StrictSharedBorrowInvalidated` while such a loan is live. A live frozen loan
excludes everything a shared loan excludes and every other write to the
place's storage through any carrier: a `Plain` assignment, an `addr` method
call, and passing a carrier of a shared or exclusive loan on an overlapping
place, a non-`const` pointer or a value that carries one, to a call that could
write through it; such a write is `StrictBorrowedObjectMutated`, and the
invalidating ones stay `StrictSharedBorrowInvalidated`. The one carrier a
frozen loan does not exclude is its holder when the holder may write: the
result of a call that holds a `bound` pointer argument's pointee (T5(d)), with
the carriers copied from it, writes the pointee as the result's own kind allows,
and only it does. For a call result or
reference expression whose loan set mixes kinds, T4 is applied to every place
in the set at the weakest kind, frozen counting below shared
([`ref` bindings](#ref-bindings)). T4 and the mutation page's rule M2 are one
rule seen from two sides: T4 is stated over loans and M2 over the access a
place is under (realigned <date>, SAFE-2: W-347, W-348, W-349; the superseded
2026-10-12 text read "except through the suspended carrier at shared kind (the
reborrow clause of T2)" and "For a carrier whose loan set mixes kinds, T4 is
applied to every place in the set at the weakest kind
([`ref` bindings](#ref-bindings)).", and named no frozen loan).
```

<!-- google-doc-style-resume -->

### §A.3.7 safety/temporal_safety.md :379-381, T6, a sentence inserted

Insert after "(amended 2026-10-12, document-review fold: D-1)." and before
"Each marker discharges exactly one obligation:":

<!-- google-doc-style-ignore -->

```markdown
The same spelling marks a `ref` binding, or a value binding of a borrowed
object, formed on an open place ([`ref` bindings](#ref-bindings), T2): its
obligation is the binding's, `noalias` for a `ref`, which for a ⊥ carrier
includes this one, one marker for one binding (added <date>, SAFE-2: W-347,
W-348).
```

<!-- google-doc-style-resume -->

### §A.3.8 safety/temporal_safety.md :427-442, T8, the paragraph replaced

Replace the paragraph from "`noalias` and `captures(none)` are emitted for
exclusive loans only where the" through "properties that are not established
locally" (proposal p005914)." with the block (amended 2026-10-28, review fold:
A-M-1, A-B-1: rev 1 emitted the attributes for a local `ref` on a `ref`
parameter's referent without the whole-package condition, so a Permissive
caller's `G(ref x, &x)` made a write through `p` undefined behavior, and for
a `const` `ref` on an open place, which Permissive and C++ writes may breach):

<!-- google-doc-style-ignore -->

```markdown
`noalias` is emitted, with `captures(none)` for a `ref` not marked `bound` and
`captures(ret: address, provenance)` for one marked `bound` (p005434:846-848),
only where the checker established the requirement against every other
access, Permissive and C++ ones included: intra-function, for a `ref` binding
or an `exclusive T*` loan a Strict body forms on a place whose every carrier
is the body's own, an owner of the body or a place reached only through
carriers of such owners' loans; and, for a `ref` binding on the referent of a
`ref` parameter or on the pointee of an `exclusive T*` parameter, and on those
parameters themselves, only in functions that are not exported to C++, not
address-taken (no function value crosses to C++ or Permissive code), and whose
every Carbon call site in the package is Strict-checked. That is a
whole-package fact, and otherwise the attributes are not emitted; nor are they
ever emitted for a `ref` on an open place, the checked `const` `ref` on a
`Core.SharedImmutable` type included, whose frozen loan Strict enforces but
which a Permissive body or C++ may still write as erroneous behavior. That is
the policy p005434 states under "How addresses interact with `ref`": "these
attributes won't be passed to LLVM unless their requirements can be
established". A `ref` binding formed with `unsafe`, and every `ref` in a
Permissive body, keeps the language's `noalias` rule as the unsafe code's
obligation, "Unsafe code will be required to adhere to just the `noalias`
restrictions, but will not be checked" (p005434:861-863), and carries no
attribute. The fork's own corpus has both excluded shapes: C++ calls
`fn Bump(ref self, n: i32)` from `inline Cpp`
(fork/conformance/programs/interop/cpp_export_method.carbon:31-33), and
`std::thread` takes a Carbon function value
(cpp_thread_carbon_fn_diff.carbon:38-45), and both are callers the
whole-package fact must count. A Permissive or C++ caller that aliases such a
parameter produces erroneous behavior, never undefined behavior, which is the
strategy's rule that "the optimization of safe code will not rely on
properties that are not established locally" (proposal p005914; realigned
<date>, SAFE-2: W-347; the superseded 2026-10-12 text began "`noalias` and
`captures(none)` are emitted for exclusive loans only where the checker
established them:").
```

<!-- google-doc-style-resume -->

### §A.3.9 safety/temporal_safety.md :478-506, T5(a) and (d)

In (a) replace "with kind equal to the parameter's kind: `ref` and
`exclusive T*` parameters give exclusive, value, `T*` and `const` parameters
give shared, and a mixed set takes the weakest kind." with the first block.
Replace the (d) bullet, from "**(d) The argument stays borrowed.**"
through "narrowing, recorded here and in the F-013 entry.", with the second
(amended 2026-10-28, review fold: A-B-2: rev 1 left a `bound` pointer
argument's pointee "not invalidated", W-349's narrowing in other words; A-m-1:
rev 1 kept a `bound ref`'s exclusive loan under a `val` result; amended
2026-10-28, review fold: RR1-m1, the pointee's frozen loan and the result's
own kind, and RR1-M1, the array view's cost).

<!-- google-doc-style-ignore -->

```markdown
with kind equal to the parameter's kind: a `ref` parameter gives exclusive
under a `ref` return and frozen under a `val` or by-value return, an
`exclusive T*` parameter gives exclusive, `T*` and `const T*` parameters give
shared, and a by-value parameter of a borrowed type, `self` included, or a
`const` `ref` gives frozen; a mixed set takes the weakest kind, frozen counting
below shared, so no write reaches a frozen argument through the result
(realigned <date>, SAFE-2: W-349; the superseded 2026-10-12 sentence read
"with kind equal to the parameter's kind: `ref` and `exclusive T*` parameters
give exclusive, value, `T*` and `const` parameters give shared, and a mixed set
takes the weakest kind.").
```

```markdown
-   **(d) The argument stays immutable.** For the duration of a returned loan
    each `bound` argument is immutable, as the proposal says full safety needs:
    "For full safety, we need each bound parameter to be immutable for the
    duration of the lifetime of the returned result" (p005434:831-832); no
    path but the result writes it. A by-value `bound` argument of a borrowed
    type, `bound self` included, and a `bound` `const` `ref` keep their frozen
    loan for the result's lifetime, so no path writes their storage while the
    result lives (`StrictBorrowedObjectMutated`, T4; the mutation page's
    EX-M-1). A `bound ref` argument keeps its exclusive loan, which the result
    carries (`captures(ret: address, provenance)`), so no path but the result
    reaches it, when the result is a `ref` return, as the proposal's
    `ValidRef`, returning `self.m` from `bound ref self`, needs
    (p005434:730-731); under a `val` or by-value result, the proposal's
    `RefToVal` (p005434:825), it keeps a frozen loan, and may be read but not
    written while the result lives. The pointee of a `bound` pointer argument,
    `T*`, `const T*` or `exclusive T*`, the pointer itself being a copy, is
    held by the result under a frozen loan, an exclusive one for an
    `exclusive T*`: while the result lives no carrier but the result and the
    carriers copied from it writes the pointee, and the result's own access
    is at the kind (a) gives the parameter, so it writes the pointee only as
    that kind allows, never through a `const T*`; an `exclusive T*`'s pointee
    is reached by no other path at all. On a closed place T4 enforces this
    against every carrier, so while a view `Core.Slice(T).FromArray(&a)` of a
    local array lives, `a` is written only through the view
    ([slices](../slices.md), the opening example). On an open place it needs
    the pointee's type to be `Core.SharedImmutable`, whose shared-path writes
    the mutation page's M3 rejects; otherwise the call is
    `StrictBorrowFromShared`, or `unsafe` at the call (`unsafe Valid1(p)`, the
    T6 spelling of a call that consumes a carrier the checker cannot vouch
    for) with the obligation that no path but the result writes the pointee
    while the result lives. The proposal's "We will reconsider this with the
    memory safety design" (p005434:834-835) is answered by keeping the
    sentence (realigned <date>, SAFE-2: W-349; the bullet was "(d) The argument
    stays borrowed.", and its superseded 2026-10-12 text read: "For the
    duration of a returned loan the bound argument stays borrowed in the
    caller at the parameter's kind. The proposal asks (p005434:831-832) for
    the bound parameter to be "immutable for the duration of the lifetime of
    the returned result"; this design narrows "immutable" to "not
    invalidated": a shared-kind bound argument stays writable in its `Plain`
    fields through other aliases, the same narrowing D-SAFE-17 applies to value
    bindings. This is a dated narrowing, recorded here and in the F-013
    entry.").
```

<!-- google-doc-style-resume -->

### §A.3.10 safety/temporal_safety.md :628 and :637-639, Diagnostics

Replace the table row whose first cell is `StrictSharedBorrowInvalidated` with
the first block's first row, its Debug cell re-worded as on the strategy page
(amended 2026-10-28, review fold: B-m6), and insert its second row after it;
insert the second block after the `StrictSharedBorrowInvalidated` item, which
ends "(T4; the reborrow clause of T2).". Rows plus one, bullets plus one.

<!-- google-doc-style-ignore -->

```markdown
| `StrictSharedBorrowInvalidated` | error | warning `PermissiveAliasedExclusive` | ASan-class detection when the invalidation frees what a loan reads; the value-binding report is `StrictBorrowedObjectMutated`'s (realigned <date>, SAFE-2: W-348; this cell read "`MutationDuringValueBinding` for the value-binding case (D-SAFE-17)") |
| `StrictRefFromShared` (realigned <date>, SAFE-2: W-347) | error | warning `PermissiveAliasedExclusive` | — |
```

```markdown
-   `StrictRefFromShared`: "`ref` binding `{0}` of `{1}` through a shared path;
    use an `exclusive` pointer or `unsafe`", placed at the binding or at the
    call that binds a `ref` parameter, with a note at the shared path's origin
    ([`ref` bindings](#ref-bindings); added <date>, SAFE-2: W-347). Its
    siblings `StrictBorrowFromShared`, which a `bound` pointer argument on an
    open place also raises (T5(d)), `StrictBorrowedObjectMutated` and
    `StrictSharedImmutableWrite` are the mutation page's (M3, M8).
```

<!-- google-doc-style-resume -->

### §A.3.11 safety/temporal_safety.md :677-679, Worked examples, a clause added

Replace "two regression sets, EX-TM-4 and EX-TM-8, are the standing
counterexamples the design must reject and are kept verbatim from the plan."
with:

<!-- google-doc-style-ignore -->

```markdown
two regression sets, EX-TM-4 and EX-TM-8, are the standing counterexamples the
design must reject and are kept verbatim from the plan, but for `UsePick`'s
comments in EX-TM-8, realigned <date> by SAFE-2 (W-347) with the superseded
comments kept in them.
```

<!-- google-doc-style-resume -->

### §A.3.12 safety/temporal_safety.md :693-697, EX-TM-1, the prose sentence replaced

(Amended 2026-10-28, document-review fold: R1-m2. The block below is commit
1's text. Since e1574b003 the page holds both pointees frozen as the pointees
of `bound` pointer arguments, the `const` limiting the result's own access, as
section 8.7 records.)

Replace "Under the design the result's loan set is the union of `a`'s and `b`'s
at shared kind, so in a caller both arguments stay borrowed, not invalidated,
while the result is live; neither may be destroyed or assigned a non-`Plain`
value, and both may still be read." with the block (amended 2026-10-28, review
fold: A-B-2: rev 1 kept the phrase "stay loaned, not invalidated" and read
"each bound parameter" of a pointer as the copied pointer):

<!-- google-doc-style-ignore -->

```markdown
Under the design the result's loan set is the union of `a`'s and `b`'s at
shared kind, and by T5(d) the result holds both pointees, frozen because the
parameters are `const T*`: in a caller, while the result is live, neither
pointee may be written, destroyed or assigned through any path, and both may
still be read; on a caller's local the check is T4's, and through a caller's
own shared pointers the prelude's opt-in of `Core.String` to
`Core.SharedImmutable` (W-144) lets the loan be formed. `a->Size()` binds `*a`,
an open place, by value, which the same opt-in makes a checked frozen loan (the
mutation page's M8; realigned <date>, SAFE-2: W-348, W-349; the superseded
2026-10-12 sentence read "Under the design the result's loan set is the union
of `a`'s and `b`'s at shared kind, so in a caller both arguments stay borrowed,
not invalidated, while the result is live; neither may be destroyed or assigned
a non-`Plain` value, and both may still be read.").
```

<!-- google-doc-style-resume -->

### §A.3.12a safety/temporal_safety.md :713-745, EX-TM-3, the `Set` call moved and its reason replaced

Added 2026-10-28, review fold: RR2-B1: `Core.Buf(T).Set` takes `ref self`
(D-SAFE2-5), an exclusive use of `buf` (M3(d)) that the live view `v`'s
frozen loan excludes (T4), so the page's `buf.Set(1, 7)` after `let v` would
be `StrictSharedBorrowInvalidated`; the call moves before `v` is formed and
`v[1]` still prints 7. In the code block replace the three consecutive lines
that begin `var buf: Core.Buf(i32)`, `let v: Core.Slice(i32)` and
`buf.Set(1, 7);` (whose comment reads "OK: Set is non-invalidating and i32 is
Plain") with the first block (one line added). In the prose replace
"`buf.Set(1, 7)` is permitted through it because `Set` is non-invalidating and
`i32` is `Plain`," with the second block. The heading "EX-TM-3: Liveness and
non-invalidating writes" stays: the `String` half's `s = "def"` is the
non-invalidating write it names, and the section 4.1 row of fork/safe/plan.md
and the page checklist's row state today's outcome, which is unchanged.

<!-- google-doc-style-ignore -->

```carbon
  var buf: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  buf.Set(1, 7);                    // OK: no loan on buf is live; Set takes ref self after W-144 (realigned <date>, SAFE-2: W-348; this call followed the next line and read "buf.Set(1, 7);                    // OK: Set is non-invalidating and i32 is Plain")
  let v: Core.Slice(i32) = buf.AsSlice();   // AsSlice is [bound self] after W-144: v holds an interior loan on buf
  // buf.Set(1, 7);                 // here: StrictSharedBorrowInvalidated — Set's ref self is an exclusive use of buf, and v's frozen loan on buf is live (T4)
```

```markdown
`buf.Set(1, 7)` comes before `v` is formed, because `Set` takes `ref self` once
W-144 lands, the exclusive receiver the mutation page's
[Value bindings](mutation_safety.md#value-bindings) requires of a trusted
writer of an element, so that under the live `v` the call is
`StrictSharedBorrowInvalidated` (realigned <date>, SAFE-2: W-348; the
superseded clause read "`buf.Set(1, 7)` is permitted through it because `Set`
is non-invalidating and `i32` is `Plain`,"),
```

<!-- google-doc-style-resume -->

### §A.3.13 safety/temporal_safety.md :900-968, EX-TM-8's `UsePick`

(Amended 2026-10-28, document-review fold: R1-m1. The blocks below are commit
1's text. Since e1574b003 the page's `UsePick` comments and bullet give
`StrictSharedBorrowInvalidated` at the `let ref z`, as section 8.7 records.)

In the code block replace the three lines from " let ref z: Core.Buf(i32) =
Pick(false, x, q);" through " z = Core.Buf(i32).Make(5, 0); //
StrictInvalidatingThroughShared (RR-7): ..." with the first block. In the
prose replace "the programs the plan's reviews added, kept verbatim," with
"the programs the plan's reviews added, kept verbatim but for `UsePick`'s
comments, realigned <date> (SAFE-2: W-347),". Replace the bullet whose bold
lead is "`Pick`, `UsePick`" (from its "(D-SAFE-8)." through "second reason.
Rejected at stage 4.") with the second block. Replace the checklist row whose
first cell is "D-SAFE-8 mixed-kind result" with the third block (one row
added). Append the fourth block to the bullet whose bold lead is "`Load`",
after its last words "whose result carries `q`'s loans at shared kind."
(amended 2026-10-28, review fold: A-B-2, the re-trace of `Load` under T5(d);
B-M5, the checklist rows' W ids).

<!-- google-doc-style-ignore -->

```carbon
  let ref z: Core.Buf(i32) = Pick(false, x, q);          // z: an exclusive ref on x and y, both closed places (realigned <date>, SAFE-2: W-347; was "z: shared-kind ref whose loan set covers x and y (A-5)")
  let v: Core.Slice(i32) = q2->AsSlice();                // StrictExclusiveBorrowConflict: q2 reaches y while z's exclusive loan on y is live (was "interior loan on y")
  z = Core.Buf(i32).Make(5, 0);     // through the exclusive ref, not itself rejected (was "StrictInvalidatingThroughShared (RR-7): a non-Plain assignment through a shared-kind ref, rejected regardless of v; y's live view is the second reason")
```

```markdown
-   **`Pick`, `UsePick`** (D-SAFE-8). `Pick` returns a reference expression,
    not a binding, and is accepted; its result carries
    `{(r, exclusive), (*p, shared)}` and has the weakest kind, shared. In
    `UsePick` both places in that set, `x` and `y`, are locals, so `let ref z`
    forms an exclusive loan on each (T2) and suspends `q`, the carrier passed;
    `q2` is another carrier of `y`, live on the next line, so `q2->AsSlice()`
    is `StrictExclusiveBorrowConflict`. Rejected at stage 4 (realigned <date>,
    SAFE-2: W-347; the superseded 2026-10-12 text read: "`Pick`'s result
    carries `{(r, exclusive), (*p, shared)}` and is a shared-kind `ref`; the
    assignment of a new `Buf` through `z` is `StrictInvalidatingThroughShared`,
    the mutation page's diagnostic for a non-`Plain` assignment through
    shared-kind access, regardless of the view `v`; the live view of `y`
    through `q2` is the second reason.").
```

```markdown
| D-SAFE-8 mixed-kind result, a `ref` binding on closed places (realigned <date>, SAFE-2: W-347) | EX-TM-8 `Pick`/`UsePick` | NEW-SYNTAX (`bound`) | p005434 `Conditional` | 1, 4 |
| D-SAFE-8 a `ref` through a shared pointer (added <date>, SAFE-2: W-347) | EX-TM-9 | ACCEPTS-UNCHECKED for `F` (nightly exit 0, prints 3); NEW-SYNTAX for `F2`, `F3` | p005434:152-162 | 1, 4 |
```

```markdown
    By T5(d) the result also holds the caller's `*q`, the pointer `q` points
    to: while the result lives no other path writes it, and in `Wild3` the
    argument is ⊥, which needs the T6 `unsafe` before T5(d) applies (added
    <date>, SAFE-2: W-349).
```

<!-- google-doc-style-resume -->

### §A.3.14 safety/temporal_safety.md :953, EX-TM-9 inserted

Insert before "The checklist rows this page owns, in the checklist's own
vocabulary:" (after the `Pick`, `UsePick` bullet). One H3 added.

<!-- google-doc-style-ignore -->

````markdown
### EX-TM-9: A `ref` binding through a shared pointer

```carbon
// EX-TM-9 (F: today's syntax, accepted today — p005434:152-162's F without its Assert line; F2, F3: NEW — added <date>, SAFE-2: W-347)
fn F(ptr: i32*) {
  let ref x: i32 = *ptr;          // Strict: StrictRefFromShared — *ptr is an open place; Permissive: PermissiveAliasedExclusive
  x += 1;
}
fn F2(ptr: exclusive i32*) { let ref x: i32 = *ptr; x += 1; }   // accepted: a checked reborrow of the exclusive pointee
fn F3(ptr: i32*) { let ref x: i32 = unsafe *ptr; x += 1; }      // accepted: the marker takes on the noalias obligation (p005434:861-862)
```

[`ref` bindings](#ref-bindings), the open place. `ptr` is a shared-pointer
parameter, so `*ptr` is an open place: the caller may hold another `i32*` to
the same object, and nothing in `F` can show that none is used while `x`
lives, which is what `noalias` requires. Strict rejects `F` with
`StrictRefFromShared`; Permissive warns and accepts it, so the proposal's
example stays valid where unchecked code is allowed, as D-SAFE-8's break
condition requires. `F2` takes the exclusive kind, under which `x` is a checked
reborrow, and `F3` spells the obligation; the proposal's caller,
`var y: i32 = 2; F(&y);`, is unchanged for all three, `&y` on the owner
yielding `exclusive i32*`. Outcome: `F` ACCEPTS-UNCHECKED — the nightly
compiles it with exit status 0, and with
`fn Run() -> i32 { var y: i32 = 2; F(&y); Core.Print(y); return 0; }` the
linked program prints `3`; the proposal's own line `Assert(&x == ptr);` is left
out because the nightly has no pointer comparison ("cannot access member of
interface `Core.EqWith(i32*)` in type `i32*` that does not implement that
interface"). `F2` and `F3` are NEW-SYNTAX. Stage 4.
````

<!-- google-doc-style-resume -->

### §A.3.15 safety/temporal_safety.md :1067, Implementation staging, row 4 replaced

<!-- google-doc-style-ignore -->

```markdown
| 4 | The loan checker | T1 to T8 and the Store rule over loan sets; `bound` per T5(a) to (e), with T5(d)'s hold of a `bound` pointer argument's pointee; `exclusive`; the reborrow and same-kind-copy clauses; frozen loans and the closed-place rule; `StrictExclusiveBorrowConflict`, `StrictSharedBorrowInvalidated`, `StrictRefFromShared`, `StrictBorrowOfTemporary`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam`; `noalias` with `captures(none)` or `captures(ret: address, provenance)` under T8 where established (realigned <date>, SAFE-2: W-347, W-348, W-349); `error` default (residue item W-148) |
```

<!-- google-doc-style-resume -->

### §A.3.16 safety/temporal_safety.md :1096-1115, Decisions

Replace the D-SAFE-8 bullet, from "**D-SAFE-8 — `ref` bindings inherit the
kind of their source.**" through "mode (none may; the checklist lists them as
accepted).", with the first block. In the D-SAFE-11 bullet replace "with the
narrowing of p005434:831-832 from "immutable" to "not invalidated"." with the
second block.

<!-- google-doc-style-ignore -->

```markdown
-   **D-SAFE-8 — Every `ref` binding is `nocapture` and `noalias`.** Proposal
    p005434:83's rule holds for every `ref` binding, exclusive, or frozen for a
    `const` type: a checked reborrow on a closed place, and on an open place an
    `unsafe` formation (`StrictRefFromShared` unmarked), a `const` `ref` on a
    `Core.SharedImmutable` type excepted; a `ref` return is not a binding, so
    `Valid1`, `ValToRef` and `Conditional` stay valid, a mixed result set
    taking the weakest kind; T8 emits `noalias` with `captures(none)` or
    `captures(ret: address, provenance)` only where established against every
    writer, on the body's own places and, under the whole-package condition,
    on `ref` and `exclusive T*` parameters' places, never on an open place nor
    for an `unsafe` one. Break condition: an accepted
    p005434 example that becomes invalid in Permissive mode (none may; the
    checklist lists them as accepted), or an accepted upstream memory-safety
    proposal that narrows p005434:83 (realigned <date>, SAFE-2: W-347; the
    heading read "`ref` bindings inherit the kind of their source." and the
    superseded 2026-10-12 text: "A `ref` from a place is exclusive; a `ref`
    from `*p` has `p`'s kind; a mixed loan set has the weakest kind and T4
    applies to every place in it. `noalias` and `captures(none)` are emitted
    only for exclusive-kind refs under T8, which narrows p005434:83 in a dated
    amendment on this page.").
```

```markdown
with p005434:831-832's "immutable for the duration of the lifetime of the
returned result" kept for each `bound` argument, a pointer argument's pointee
included (T5(d); realigned <date>, SAFE-2: W-349, where this text read "with the
narrowing of p005434:831-832 from "immutable" to "not invalidated"").
```

<!-- google-doc-style-resume -->

### §A.3.17 safety/temporal_safety.md :1154-1157, Alternatives, attempt B's bullet

Replace "D-SAFE-7 and D-SAFE-8 are that repair: `exclusive T*` exists, and a
`ref` through `*p` inherits `p`'s kind so that the proposal's `Valid1` and
`ValToRef` stay valid." with:

<!-- google-doc-style-ignore -->

```markdown
D-SAFE-7 and D-SAFE-8 are that repair: `exclusive T*` exists, `ref self` is
reachable through it, and the proposal's `Valid1` and `ValToRef` stay valid
because they return reference expressions, not bindings (realigned <date>,
SAFE-2: W-347; this text read "and a `ref` through `*p` inherits `p`'s kind so
that the proposal's `Valid1` and `ValToRef` stay valid").
```

<!-- google-doc-style-resume -->

### §A.4.1 safety/initialization_safety.md :65-74, the status paragraph, a sentence appended

Append after "the examples marked "today's syntax" were compiled on
the 2026.10.12 nightly toolchain and their outcomes are stated with each
example.":

<!-- google-doc-style-ignore -->

```markdown
Rule I5 and the D-SAFE-13 text that states it were realigned <date> by fork
workstream SAFE-2: the zero-fill they specify is proposal p000257's hardening
initialization in the build the fork's Release build is, not a departure from
it (W-353, closed as a classification corrected; fork/safe/safe2-plan.md); each
realigned passage quotes the text it supersedes.
```

<!-- google-doc-style-resume -->

### §A.4.2 safety/initialization_safety.md :216-233, I5, the first paragraph replaced and one clause of the second

Replace the paragraph from "In every safety mode, the Release build's
`make_uninitialized` zero-fills the whole object" through "recorded as a dated
amendment at the overview's sentence." with the first block. In the next
paragraph replace "zeros for storage that was never assigned," with the second
block.

<!-- google-doc-style-ignore -->

```markdown
In every safety mode, the Release build's `make_uninitialized` zero-fills the
whole object, padding included, so that unformed storage holds zeros until it
is assigned. This is proposal p000257's hardening initialization: "The entire
storage, including any padding bytes, for all types will be at least be zeroed
as part of hardening initialization." (p000257:356-358), and the fork's Release
build is the build the design overview calls hardened (fork decision D-RG-20,
fork/register/rg1-plan.md). A type may customize its hardening initialization to set
parts or members of its unformed storage to values other than zero
(p000257:358-360), which is the design overview's "Types may define additional
initialization for the hardened build mode" (docs/design/README.md:2147-2149);
the interface that spells the customization is upstream's to name
(p000257:345-347 says only "by implementing interfaces"), and until it is named
every type's unformed storage is zeros. Proposal p005914's memory-safe-language test
requires initialization errors to have no undefined behavior and allows
zero-initialization in place of fail-stop (p005914:87-88); the hardening
initialization is how the Release build meets it. The unsupported benchmarking
build of the [build modes](README.md#build-modes) section skips the hardening
initialization, and there an unformed read "may lead to undefined behavior"
(p000257:180); no guarantee of this page holds in it. (Realigned <date>,
SAFE-2: W-353, closed as a classification corrected. The superseded 2026-10-12 text
read: "This promotes the design overview's hardened-mode sentence — "this
causes integers to be set to `0` when in unformed state in this mode"
(docs/design/README.md:2148-2149) — to the Release baseline, which proposal
p005914 permits: its memory-safe-language test requires initialization errors
to have no undefined behavior and allows zero-initialization in place of
fail-stop (p005914:87-88). Proposal p000257 already asked that the entire
storage, padding bytes included, be zeroed as hardening initialization
(p000257:355-358); the departure is only that the fork's Release build is the
hardened build for this purpose, recorded as a dated amendment at the
overview's sentence.")
```

```markdown
the hardening initialization's value for storage that was never assigned
(zeros, or the values a type's customization sets; realigned <date>, SAFE-2:
W-353, where this clause read "zeros for storage that was never assigned"),
```

<!-- google-doc-style-resume -->

### §A.4.3 safety/initialization_safety.md :441, Implementation staging, row 2 replaced

Replace the stage 2 row, whose second cell is "Runtime hardening regardless of
mode", with:

<!-- google-doc-style-ignore -->

```markdown
| 2 | Runtime hardening regardless of mode | I5: Release `make_uninitialized` zero-fill of the whole object, proposal p000257's hardening initialization, with the type customization once upstream names its interface; Debug poison-fill and the read-of-unformed fail-stop; the unsupported benchmarking build skips the zero-fill (realigned <date>, SAFE-2: W-351, W-353) |
```

<!-- google-doc-style-resume -->

### §A.4.4 safety/initialization_safety.md :455-470, D-SAFE-13, the I5 sentence and the break condition

In the D-SAFE-13 bullet replace "I5 Release zero-fills the whole object in
every mode and Debug poison-fills and detects." with the first block, and
replace the bullet's last sentence, "Break condition: a benchmark in the fork
showing more than 0.5 percent from zero-fill alone — then zero-fill is scoped
to escaped-unformed objects only, which the same pass knows, and the rule text
of I5 is amended in a dated edit.", with the second block.

<!-- google-doc-style-ignore -->

```markdown
    I5 Release zero-fills the whole object in every mode, which is
    p000257:356-358's hardening initialization in the build D-RG-20 reads as
    the hardened one, a type customizing it under p000257:358-360, and Debug
    poison-fills and detects; the benchmarking build skips it.
```

```markdown
    Break condition: an upstream amendment of p000257's hardening
    initialization, or a reconciliation of the build-mode pages otherwise than
    D-RG-20 reads them; I5 then follows the upstream text in a dated edit
    (realigned <date>, SAFE-2: W-353; the superseded 2026-10-12 break
    condition read: "a benchmark in the fork showing more than 0.5 percent
    from zero-fill alone — then zero-fill is scoped to escaped-unformed
    objects only, which the same pass knows, and the rule text of I5 is
    amended in a dated edit").
```

<!-- google-doc-style-resume -->

### §A.4.5 safety/initialization_safety.md :482-484 and :511-518, Alternatives

In the Alternatives introduction replace "and one the design overview had."
with the first block. Replace the bullet from "**Zero-fill in a hardened
build only.**" through "not a reason to leave the default mode unsafe." with
the second block.

<!-- google-doc-style-ignore -->

```markdown
and one reading of the design overview's build modes (realigned <date>,
SAFE-2: W-353; this sentence ended "and one the design overview had").
```

```markdown
-   **Zero-fill in an extension of Release only.** Proposal p000257 places the
    zeroing in the hardened build's hardening initialization, and the fork's
    Release build is that build (D-RG-20), so one reading would have kept the
    Release build without it and offered zero-fill as one of the specialized
    Release extensions. That reading is not taken because it would move
    upstream's hardening out of the build upstream names into a build it does
    not, and because the memory-safe-language test of proposal p005914
    requires initialization errors to have no undefined behavior in the
    supported build modes; the benchmarking build, which skips it, is
    unsupported. (Realigned <date>, SAFE-2: W-353. The superseded 2026-10-12
    bullet was headed "Zero-fill in a hardened build only." and read: "The
    design overview placed zero-fill in a hardened build mode and the fork
    promotes it to the Release baseline. Keeping it hardened-only was not
    taken because the memory-safe-language test of proposal p005914 requires
    initialization errors to have no undefined behavior in the default mode,
    and an uninitialized read in Release is exactly such an error; the cost
    question is the break condition of D-SAFE-13, not a reason to leave the
    default mode unsafe.")
```

<!-- google-doc-style-resume -->

### §A.4.6 safety/initialization_safety.md :530, External facts, the row replaced

Replace the row whose first cell begins "Clang's
`-ftrivial-auto-var-init=zero` zero-fills automatic storage" with:

<!-- google-doc-style-ignore -->

```markdown
| Clang's `-ftrivial-auto-var-init=zero` zero-fills automatic storage in C and C++, and deployments of it report a cost small enough that production builds enable it | The expectation that p000257's hardening initialization is affordable in the Release build; no rule depends on the figure (realigned <date>, SAFE-2: W-353; the cell read "The plausibility of I5's 0.5 percent break condition") | UNVERIFIED: we expect the option to exist under that name and the reported cost to be below one percent on typical workloads; no break condition reads a fork benchmark since SAFE-2 |
```

<!-- google-doc-style-resume -->

### §A.5.1 safety/spatial_safety.md :40-48, Overview, two clauses replaced

Replace the clauses from "a violation" through "spelled `unsafe` at the call;"
(their words "fails-stop" and "safety mode" are links; they read "in every
build mode and in every" safety mode and "the only way to read without the
check is an `unsafe fn`") with the first block, and
"the rule is that arithmetic never produces undefined behavior in Carbon
code." with the second block.

<!-- google-doc-style-ignore -->

```markdown
a violation [fails-stop][fail-stop] in every supported build mode and in every
[safety mode](README.md#safety-modes); the supported way to read without the
check is an `unsafe fn`, spelled `unsafe` at the call, the unsupported
benchmarking build of the [build modes](README.md#build-modes) section removing
the check with the rest of the default hardening;
```

```markdown
the rule is that arithmetic never produces undefined behavior in Carbon code
in a supported build mode (realigned <date>, SAFE-2: W-350, W-351; this
paragraph read "fails-stop in every build mode", "the only way to read without
the check" and "never produces undefined behavior in Carbon code.").
```

<!-- google-doc-style-resume -->

### §A.5.2 safety/spatial_safety.md :66-86, the status paragraph, a sentence appended

Append after "examples that use the fork's `Core.Slice` cite the scoreboard
program that proves their outcome.":

<!-- google-doc-style-ignore -->

```markdown
SP2, SP4, the Arithmetic section, and the examples and decisions that state
them were realigned <date> by fork workstream SAFE-2 to the strategy's build
modes: the arithmetic design's three rows are read through them, and the
strategy's unsupported benchmarking build is kept rather than withdrawn (W-350,
W-351; fork/safe/safe2-plan.md); each realigned passage quotes the text it
supersedes.
```

<!-- google-doc-style-resume -->

### §A.5.3 safety/spatial_safety.md :115 and :119-125, SP2, the heading renamed and a sentence inserted

Rename the heading "### SP2: Every element access is bounds-checked and
fails-stop in every build mode" to the first block; the table of contents entry
at :16 is regenerated by the prek toc hook and is not edited by hand, and no
other file links the old anchor (measured: `grep -rn 'sp2-every-element'` finds
only :16). Insert the second block after "because the safety modes govern where
the `unsafe` keyword is written and this access has no keyword." and before
"The fork's decision D-SL-4".

<!-- google-doc-style-ignore -->

```markdown
### SP2: Every element access is bounds-checked and fails-stop in every supported build mode
```

```markdown
Those are the supported build modes; the unsupported benchmarking build the
same section promises removes the check with the rest of the default hardening,
and no rule of this page holds in it (realigned <date>, SAFE-2: W-351; the
heading read "fails-stop in every build mode").
```

<!-- google-doc-style-resume -->

### §A.5.4 safety/spatial_safety.md :206 and :213-221, SP4, the heading renamed and the body replaced

Rename the heading "### SP4: `unsafe fn GetUnchecked` is the only opt-out" to
the first block (the table of contents entry at :18 is regenerated by the prek
toc hook; `grep -rn 'sp4-unsafe-fn'` finds only :18). Replace the text from
"This is the "ways to write unsafe code that disables the run-time
enforcement"" through "rather than at the build, where no search in the source
finds it." with the second block; the paragraph "Permissive removes only the
keyword" after it is unchanged.

<!-- google-doc-style-ignore -->

```markdown
### SP4: `unsafe fn GetUnchecked` is the supported opt-out
```

```markdown
This is the "ways to write unsafe code that disables the run-time enforcement"
the strategy's [build modes](README.md#build-modes) section promises, and it is
the only supported such way. The same section's other promise, that Carbon
"will provide a way to disable the default hardening in release builds, but not
in a supported way", "strictly for benchmarking purposes", is kept: the
benchmarking build removes every check of this page, no program the design
supports is built that way, and its spelling is fixed with the build modes at
stage 2 (W-146). The per-site `unsafe fn GetUnchecked` keeps proposal p000196's
"manually disabled for performance-critical use cases" at the site, where an
audit finds it with the same search that finds every other `unsafe`; the
benchmarking build is configured outside the source, which is why it is not a
supported mode. (Realigned <date>, SAFE-2: W-351. The heading read "`unsafe fn
GetUnchecked` is the only opt-out", and the superseded 2026-10-12 text read:
"and it is the only such way: no build flag disables the checks. The
strategy's sentence that Carbon "will provide a way to disable the default
hardening in release builds, but not in a supported way" is withdrawn by the
fork, dated, in a blockquote under that sentence; the per-site `unsafe fn
GetUnchecked` keeps proposal p000196's "manually disabled for
performance-critical use cases" at the site, where an audit finds it with the
same search that finds every other `unsafe`, rather than at the build, where no
search in the source finds it.")
```

<!-- google-doc-style-resume -->

### §A.5.5 safety/spatial_safety.md :246-252, :260-264 and :270-280, Arithmetic

Replace the introduction's last sentence, from "The rule (D-SAFE-15, amending
the build-mode behavior of", a link to the arithmetic page's overflow section,
"and answering its open question) is that arithmetic in Carbon code never
produces undefined behavior:", with the first block. In the second bullet
replace "**Every mode: division and remainder by zero fail-stop.**" with
"**Every supported build mode: division and remainder by zero fail-stop.**" and
"and lands at stage 2 (W-146)." with the second block. Replace the paragraph
from "The arithmetic design's "performance build" row" through "not a change to
the rule." with the third block.

<!-- google-doc-style-ignore -->

```markdown
The rule (D-SAFE-15, reading the build-mode rows of
[Arithmetic: overflow and other error conditions](../expressions/arithmetic.md#overflow-and-other-error-conditions)
through the strategy's build modes and answering its open question for Release)
is that arithmetic in Carbon code never produces undefined behavior in a
supported build mode (realigned <date>, SAFE-2: W-350; this sentence read
"amending the build-mode behavior of" and ended "never produces undefined
behavior"):
```

```markdown
    and lands at stage 2 (W-146); the benchmarking build omits it (realigned
    <date>, SAFE-2: W-350, where the lead read "Every mode").
```

```markdown
The arithmetic design's three rows are upstream's build modes as the fork reads
them (fork decision D-RG-20, fork/register/rg1-plan.md): the development build is
Debug, the hardened build is Release, and the "performance build" row, under
which the optimizer may assume overflow and division by zero do not occur so
that "the behavior of the program is not defined", is the unsupported
benchmarking build of the strategy's [build modes](README.md#build-modes)
section, the Release build with its default hardening disabled. That row
stands. No guarantee of the safety pages holds in that build, and proposal
p005914's prohibition of undefined behavior in safe code is met in every
supported build mode, where bounds checks make an overflowed index a logic bug
rather than a memory bug. The arithmetic design's open question, whether a
hardened build should trap, wrap or produce zero, is answered for Release:
wrap, never zero; Debug traps, the development row. The arithmetic page carries
a dated blockquote with this reading. The break condition is upstream's: an
answer to the open question other than wrap, a rewrite of the rows, or a
reconciliation of the build-mode pages otherwise than D-RG-20 reads them, which
the rule then follows in a dated edit. (Realigned <date>, SAFE-2: W-350. The
superseded 2026-10-12 text read: "The arithmetic design's "performance build"
row, under which the optimizer may assume overflow and division by zero do not
occur so that "the behavior of the program is not defined", is withdrawn for
Carbon code: proposal p005914 forbids undefined behavior in safe code, and with
bounds checks in place the one consequence of overflow the row was guarding
against, an out-of-range access, cannot occur. Its open question, whether a
hardened build should trap, wrap or produce zero, is answered: wrap in Release,
trap in Debug, never zero. The arithmetic page carries a dated blockquote with
this decision. The break condition is a real-world benchmark of the class
p005914 names where the loss of `nsw` exceeds 0.5 percent; that is an owner
call on a performance-build opt-in, not a change to the rule.")
```

<!-- google-doc-style-resume -->

### §A.5.6 safety/spatial_safety.md :357, :398-404 and :405-410, EX-SP-5 and EX-SP-6

Replace the code line "// EX-SP-5 (NEW): the only opt-out" with the first
block. In the EX-SP-5 bullet append the second block after "Stage 1 parses the
call spelling and W-144 adds the accessor.". In the EX-SP-6 bullet replace the
sentence from "Stage 2 (W-146) emits the guard, after which `Div(1, 0)`" through
"wraps in Release and fails-stop in Debug." with the third block.

<!-- google-doc-style-ignore -->

```carbon
// EX-SP-5 (NEW): the supported opt-out (realigned <date>, SAFE-2: W-351; was "the only opt-out")
```

```markdown
    The unsupported benchmarking build removes the check from `s[i]` as well,
    and a program built that way is outside every guarantee of this page;
    `Hot` is the program that ships (added <date>, SAFE-2: W-351).
```

```markdown
    Stage 2 (W-146) emits the guard, after which `Div(1, 0)` fails-stop with
    "carbon: division by zero; terminating" in every supported build mode,
    and a `Div` of the least `i32` by −1, the overflowing division, wraps in
    Release and fails-stop in Debug; in the benchmarking build both are the
    arithmetic design's performance row (realigned <date>, SAFE-2: W-350;
    this sentence read "in every mode").
```

<!-- google-doc-style-resume -->

### §A.5.7 safety/spatial_safety.md :474-477, C++ interop, the division bullet

Replace "a division in Carbon code is guarded at the Carbon operation in every
mode," with:

<!-- google-doc-style-ignore -->

```markdown
    a division in Carbon code is guarded at the Carbon operation in every
    supported build mode (realigned <date>, SAFE-2: W-350; this read "in every
    mode"),
```

<!-- google-doc-style-resume -->

### §A.5.8 safety/spatial_safety.md :497, Implementation staging, row 2 replaced

Replace the stage 2 row, whose second cell begins "Runtime hardening regardless
of mode: array index fail-stop,", with:

<!-- google-doc-style-ignore -->

```markdown
| 2 | Runtime hardening regardless of mode: array index fail-stop, division by zero fail-stop, `--build-mode=debug\|release`, Release zero-fill; the unsupported benchmarking build that disables them | `ArrayIndex` lowered as compare-and-`fail_stop` with "carbon: array index out of bounds; terminating", array subscripts through `IndexWith(i64)` (absorbing W-116); the division and remainder guard with "carbon: division by zero; terminating"; Debug overflow fail-stop; the benchmarking build's removal of the checks, the guard and the wrap; residue item W-146 (realigned <date>, SAFE-2: W-350, W-351) |
```

<!-- google-doc-style-resume -->

### §A.5.9 safety/spatial_safety.md :509-544, Decisions, the D-SAFE-14 and D-SAFE-15 bullets replaced

Replace the bullet from "**D-SAFE-14 — Spatial: fail-stop everywhere,"
through "the unchecked accessor's name is the residue item's." with the first
block, and the bullet from "**D-SAFE-15 — Arithmetic.**" through "an owner
call on a performance-build opt-in." with the second block. The SP3 sentences
of the first block are the page's own, unchanged. The first block's quote
holds SP4's whole superseded sentence and the superseded break condition
(amended 2026-10-28, review fold: RR1-m2; rev 2 rewrote "SP4 unchecked access
is" and "Break condition: none for the semantics;" without quoting them).

<!-- google-doc-style-ignore -->

```markdown
-   **D-SAFE-14 — Spatial: fail-stop in every supported build mode, `unsafe fn`
    is the supported opt-out, views carry loans.** SP1 no arithmetic,
    `pointer.offset` bound by the prelude and by an `unsafe fn` anywhere else.
    SP2 every element access through `array(T, N)`, `Core.Slice(T)` and
    `Core.Buf(T)` is bounds-checked and a violation fails-stop in every
    supported build mode, D-SL-4 retained as the Release baseline; the array
    gap, constant indices rejected at compile time and run-time indices lowered
    unchecked, is a stage-2 lowering residue in which `ArrayIndex` emits the
    compare-and-`fail_stop` sequence of `Slice.Get` and array subscripts go
    through `IndexWith(i64)`. SP3 views carry their length and a loan:
    `FromArray` takes `bound p`, every producer whose result views `self`'s
    storage takes `bound self`, and the W-144 audit rule reviews every prelude
    signature as if its body were Strict-checked, marking `bound` or `unsafe
    fn`, with `bound self` on the interface declarations `IndexWith.At` and
    `Copy.Op` so that impls may keep it; `UnsafeMake` becomes `unsafe fn
    Make(p: T*, size: i64)` with its existing comment as the stated
    obligation; the prelude churn is the named residue item W-144, gated, and
    never assumed in an example. SP4 the supported unchecked access is
    `unsafe fn GetUnchecked[bound self: Self](i: i64) -> T` on `Slice` and
    `Buf`; the strategy's promise of a way to disable the default hardening in
    release builds, "not in a supported way" and "strictly for benchmarking
    purposes", is kept as the benchmarking build, which removes the bounds
    check, the division guard, the overflow wrap and the hardening
    initialization and whose spelling is fixed with the build modes at stage 2
    (W-146). SP5 hardening extensions carry no Strict guarantee. The fail-stop
    message text stays fixed (W-113) so that `fail_stop` needs no formatting
    runtime. Break condition: none for the semantics in the supported build
    modes; the unchecked accessor's name is the residue item's; an upstream
    withdrawal of the benchmarking promise removes the benchmarking build with
    it. (Realigned <date>, SAFE-2: W-351. The superseded 2026-10-12 text was
    headed "Spatial: fail-stop everywhere, `unsafe fn` is the opt-out, views
    carry loans.", read "fails-stop in every build mode" in SP2, read in SP4
    "SP4 unchecked access is `unsafe fn GetUnchecked[bound self: Self](i:
    i64) -> T` on `Slice` and `Buf`; no build flag disables checks, and the
    strategy's promise of an unsupported disable for benchmarking is
    withdrawn by the fork, dated.", and ended "Break condition: none for the
    semantics; the unchecked accessor's name is the residue item's.")
```

```markdown
-   **D-SAFE-15 — Arithmetic.** Release: signed overflow wraps, the existing
    lowering made normative, and signed or unsigned division or remainder by
    zero fails-stop, a NEW guard before the division instruction at stage 2.
    Debug: overflow fails-stop with a diagnostic. Compile-time overflow is
    already rejected. The arithmetic design's rows are read through the
    strategy's build modes (D-RG-20): development is Debug, hardened is
    Release, and the "performance build ... not defined" row stands for the
    unsupported benchmarking build, outside every guarantee; proposal
    p005914's prohibition of undefined behavior in safe code holds in every
    supported build mode, where bounds checks make overflow a logic bug rather
    than a memory bug; the open question is answered for Release with wrap,
    not zero. Break condition: an upstream answer to the arithmetic design's
    open question other than wrap, a rewrite of its rows, or a reconciliation
    of the build-mode pages otherwise than D-RG-20 reads them; the rule then
    follows the upstream text in a dated edit. (Realigned <date>, SAFE-2:
    W-350. The superseded 2026-10-12 text read: "The arithmetic design's
    "performance build ... not defined" row is withdrawn for Carbon code,
    because proposal p005914 forbids undefined behavior in safe code and
    bounds checks make overflow a logic bug rather than a memory bug; its open
    question is answered with wrap, not zero. Break condition: a real-world
    benchmark of the class p005914 names where the loss of `nsw` exceeds 0.5
    percent, an owner call on a performance-build opt-in.")
```

<!-- google-doc-style-resume -->

### §A.5.10 safety/spatial_safety.md :552-567 and :573-575, Alternatives, the build-flag bullet and the mode-gated sentence

Replace the bullet from "**A build flag that disables the checks.**"
through "which is also the program that would ship." with the first block. In
the "Mode-gated checks" bullet replace "but not of a bounds violation." with the
second block. The first block's quote of the superseded bullet's opening keeps
the page's two links as :553 and :557 write them,
`[build modes](README.md#build-modes)` and
`[fork/safe/plan.md](/fork/safe/plan.md)` (amended 2026-10-28,
implementation: stop-and-amend: link markup in two superseded quotes; rev 5
quoted both links by their text alone, and its heading ended the bullet at
:566, section 8.12).

<!-- google-doc-style-ignore -->

```markdown
-   **A supported build flag that disables the checks.** Attempt C carried the
    strategy's unsupported benchmarking disable as an `--unhardened` build flag
    beside its hardened runtime core, and SAFE-1's synthesis withdrew the
    disable altogether (D-SAFE-14, review fold A-13(c) in
    [fork/safe/plan.md](/fork/safe/plan.md)). The fork keeps the strategy's
    promise instead: the benchmarking build exists and is unsupported, as the
    [build modes](README.md#build-modes) section says. What stays rejected is
    making that build a supported mode, for the two reasons SAFE-1 gave
    against the flag. A build-level disable moves the disable from the site to
    the build configuration, so no search of the source finds where the check
    was removed, which is the audit property the whole design rests on
    ([Safe and unsafe code](README.md#safe-and-unsafe-code)); and it makes the
    matrix's fail-stop row depend on how the program was built. Both
    properties hold for every program the design supports, because the
    benchmarking build is outside that set, and a program that ships uses the
    per-site `unsafe fn GetUnchecked`, which keeps proposal p000196's disable
    "for performance-critical use cases" where the keyword is. (Realigned
    <date>, SAFE-2: W-351. The superseded 2026-10-12 bullet was headed "A
    build flag that disables the checks." and began: "The strategy's
    [build modes](README.md#build-modes) section promised an unsupported way
    to disable the default hardening in release builds for benchmarking, and
    attempt C carried it as an `--unhardened` build flag beside its hardened
    runtime core. The synthesis withdraws it (D-SAFE-14, review fold A-13(c)
    in [fork/safe/plan.md](/fork/safe/plan.md)) for two reasons."; it ended:
    "and a benchmark that wants the unchecked build measures the program with
    the accessor at its hot sites, which is also the program that would
    ship.")
```

```markdown
    but not of a bounds violation in a supported build mode; the unsupported
    benchmarking build removes the check with the rest of the default
    hardening (realigned <date>, SAFE-2: W-351; this sentence ended "but not
    of a bounds violation.").
```

<!-- google-doc-style-resume -->

### §A.5.11 safety/spatial_safety.md :611, External facts, row 2 replaced

Replace the row whose first cell begins "The run-time cost of bounds checking
in a hardened standard library" with:

<!-- google-doc-style-ignore -->

```markdown
| The run-time cost of bounds checking in a hardened standard library is small enough that production deployments enable it by default, the figure the strategy's evidence link reports | The expectation in SP2 that the check is cheap; no rule depends on the figure | UNVERIFIED: we expect the figure to be below one percent on typical workloads, as the linked account reports; no break condition reads a fork measurement since SAFE-2 (realigned <date>, SAFE-2: W-350; this cell ended "the fork's own measurement is what D-SAFE-15's 0.5 percent break condition reads") |
```

<!-- google-doc-style-resume -->

### §A.6.1 safety/rust_interop.md :128-133, the asymmetry bullet, a clause replaced

In the bullet "**Even the const kind cannot be `&T` for an exported class.**"
replace "(EX-TM-3 on the temporal page, EX-M-1 on the mutation page), and a
value binding of a non-`Plain` type is a shared loan under which the same
writes are permitted (D-SAFE-17)." with:

<!-- google-doc-style-ignore -->

```markdown
    (EX-TM-3 on the temporal page), because a `const T*` is not a binding and
    freezes nothing. A value binding of a borrowed object is the opposite
    case: Carbon freezes it for the binding's lifetime, which is why the
    [type table](#by-type) maps a by-value parameter of a borrowed `Freeze`
    type to `&T` (realigned <date>, SAFE-2: W-348, W-349; this text read
    "(EX-TM-3 on the temporal page, EX-M-1 on the mutation page), and a value
    binding of a non-`Plain` type is a shared loan under which the same
    writes are permitted (D-SAFE-17).").
```

<!-- google-doc-style-resume -->

### §A.6.2 safety/rust_interop.md :211 and :300-307, By type, a row inserted, and the `Freeze` proviso bullet

Insert the first block after the row whose cells begin `const T*`, `&T` and
"Only when `T: Core.Freeze`". In the wrappers section's bullet "**The `Freeze`
proviso keeps `&T` honest.**" append the second block after "the generator
checks the whole set, not one signature.", so that the bullet's "`&T` is
therefore emitted only when" stays true of the rows that hand Rust a `&T`.

<!-- google-doc-style-ignore -->

```markdown
| a by-value parameter of a borrowed type | `&T` | When `T: Core.Freeze`, and `&SharedView<T>` otherwise: the parameter binds a borrowed object, frozen for the call ([mutation safety](mutation_safety.md), M8), which is what Rust's `&T` promises; the `&T` is the Rust caller's, and `Freeze` excludes Rust-side interior mutability (added <date>, SAFE-2: W-348) | after stage 5 (`Freeze`) |
```

```markdown
    A by-value parameter's `&T` is not handed to Rust but taken from it, for
    the call only: Rust holds a `&T` only to an object it owns or to one a
    row above handed it under this proviso, the wrappers convert nothing to
    `&T`, and the Carbon callee keeps the object frozen for the call, so no
    `&Shared<T>` to the same object is used while that `&T` lives (added
    <date>, SAFE-2: W-348).
```

<!-- google-doc-style-resume -->

### §A.6.3 safety/rust_interop.md :336 and :344-353, `At`, the code line and the bullet replaced

Replace the code line that begins "fn At[bound self: Self](i: i64) -> const
i32*;" with the first block, and the bullet from "**`At`: a `bound` result
over a const receiver.**" through "Stage 4, because `bound` and the loan checker
are stage 4." with the second block. (The first block's 2026-10-12 mark "A-9"
moved into its quote of the superseded line, off the rewritten comment;
amended 2026-10-28, review fold: RR1-m2. The second block's writer of the
block amended 2026-10-28, review fold: RR2-B1, where rev 3 read "and a
by-value `Set` that writes that block, like `Core.Buf`'s, is callable on the
frozen receiver", `Core.Buf(T).Set` now taking `ref self`.)

<!-- google-doc-style-ignore -->

```carbon
fn At[bound self: Self](i: i64) -> const i32*;      // → fn at<'a>(&'a Self, i: i64) -> &'a SharedView<i32>   (stage 5 with Freeze, else &'a SharedView<Self> at stage 4; never &'a i32 for an exported class; receiver realigned <date>, SAFE-2: W-348; the line read "→ fn at<'a>(&'a SharedView<Self>, i: i64) -> &'a SharedView<i32>   (stage 4; never &'a i32 for an exported class — A-9)")
```

```markdown
-   **`At`: a `bound` result over a frozen receiver.** The receiver is
    `bound self: Self`, a by-value receiver: for an exported class it binds a
    borrowed object, frozen for the call and, through `bound`, for the life
    of the result (the temporal page's T5(d)), so the result's loan set is
    the receiver's and the generated lifetime `'a` ties the result to the
    receiver. The receiver exports as `&'a Self` when `Self: Core.Freeze`,
    the by-value row of the [type table](#by-type), and as
    `&'a SharedView<Self>` otherwise. The result exports as
    `&'a SharedView<i32>`, not `&'a i32`: `i32` is `Freeze`, but the element
    is not the receiver's storage, a class like `IntVec` holding its elements
    in a `Core.Buf` block, and a by-value method that writes an `i32` of that
    block through the `T*` a view of it returns, which M3 permits for an
    element type that holds no `Core.SharedImmutable` sub-object, is callable
    on the frozen receiver from Carbon or from Rust through the same
    `&'a Self` (the mutation page's
    [Value bindings](mutation_safety.md#value-bindings)). A Rust `&'a i32`
    would promise immutability that Carbon does not keep. Stage 4, because
    `bound` and the loan checker are stage 4, and stage 5 for the `&'a Self`
    receiver, because `Freeze` is. (Realigned <date>, SAFE-2: W-348, W-349.
    The superseded 2026-10-12 bullet was headed "`At`: a `bound` result over
    a const receiver." and read in part: "The receiver is `bound self: Self`
    on a `const` path, so the result's loan set is the receiver's and the
    generated lifetime `'a` ties the result to the receiver. The receiver
    exports as `&'a SharedView<Self>` and the result as `&'a SharedView<i32>`,
    not `&'a i32`: `i32` is `Freeze`, but the element lives inside an
    exported class that is reachable as `&Shared<Self>` from another
    signature, under which `set` on the element is permitted (EX-M-1 on the
    mutation page writes `a->Set(0, 5)` while `first: const i32*` is
    live).")
```

<!-- google-doc-style-resume -->

### §A.6.3a safety/rust_interop.md :213, By type, the `Core.Slice(const T)` row replaced

Added 2026-10-28, review fold: RR2-B1: the row's reason, "`Buf.Set` during a
live view is the temporal page's EX-TM-3", names a call that `Set`'s
`ref self` now rejects under a live view (A.3.12a). The proviso stands, an
element being writable through another path while a view lives; replace the
row whose first cell is `Core.Slice(const T)` and whose second is `&[T]` with
the block (no row added):

<!-- google-doc-style-ignore -->

```markdown
| `Core.Slice(const T)` | `&[T]` | Only for a `Freeze` element type under the same proviso as `&T`: an element is written through the `T*` that a view's `Data()` returns while another view of the same storage lives (realigned <date>, SAFE-2: W-348; this read "`Buf.Set` during a live view is the temporal page's EX-TM-3", and `Core.Buf(T).Set` now takes `ref self`, which rejects that call), so a slice of a class reachable through `&Shared` cannot be `&[T]` | after stage 5 (`Freeze`) |
```

<!-- google-doc-style-resume -->

### §A.6.4 safety/rust_interop.md :380-401, Verdict, parts (1) and (3)

In part (1) replace "`const T*` as `&SharedView<T>`, with `bound`-expressible
lifetimes," with the first block. In part (3) replace "`&SharedView<T>` and
`&SharedSlice<T>` stand in for them, which is the D-SAFE-17 value-binding case
generalized to the boundary." with the second block.

<!-- google-doc-style-ignore -->

```markdown
    `const T*` as `&SharedView<T>`, a by-value parameter of a borrowed
    `Freeze` type as `&T` (realigned <date>, SAFE-2: W-348), with
    `bound`-expressible lifetimes,
```

```markdown
    `&SharedView<T>` and `&SharedSlice<T>` stand in for them, because a
    `const T*` freezes nothing in Carbon, M3 permitting `Plain` writes through
    `T*` aliases while it lives; a by-value parameter of a borrowed `Freeze`
    type, which Carbon freezes for the call, is the one place a Carbon
    signature yields `&T` (realigned <date>, SAFE-2: W-348; this sentence
    ended "which is the D-SAFE-17 value-binding case generalized to the
    boundary.").
```

<!-- google-doc-style-resume -->

### §A.6.5 safety/rust_interop.md :319-322 and :553-569, the break condition and D-SAFE-19

In the D-SAFE-19 bullet insert the first block after "`const T*` as
`&SharedView<T>` by default and as `&T` only under the `Freeze` and
no-reachable-`T*` proviso;", and replace "durable gap, and this page says so in
a dated edit." with the second block. Append the second block's last sentence,
"A Rust soundness argument ... (added <date>, SAFE-2: W-348).", in the form
"A Rust soundness argument against `&T` for a frozen by-value parameter returns
that row to `&SharedView<T>` (added <date>, SAFE-2: W-348)." to the paragraph
"Break condition (D-SAFE-19): a Rust soundness argument against the wrapper"
at :319-322, after "would say so in a dated edit.".

<!-- google-doc-style-ignore -->

```markdown
    a by-value parameter of a borrowed type, frozen for the call, as `&T`
    when `T: Core.Freeze` and as `&SharedView<T>` otherwise (realigned
    <date>, SAFE-2: W-348);
```

```markdown
    durable gap, and this page says so in a dated edit; a Rust soundness
    argument against `&T` for a frozen by-value parameter returns that row to
    `&SharedView<T>` (added <date>, SAFE-2: W-348).
```

<!-- google-doc-style-resume -->

### §A.6.6 safety/rust_interop.md :619-627 and :633-638, Alternatives, fold A-9's sentence and the eager-copy bullet

In the bullet "**`&T` for `const T*` and `&[T]` for `Core.Slice(const T)` by
default.**" append the first block after "and the verdict's part (1) was
narrowed with the difference moved to part (3).". Replace the bullet that
begins with the bold lead "Eager-copy value bindings, for a `&T` mapping." and
ends "so the mapping would not change." with the second block.

<!-- google-doc-style-ignore -->

```markdown
    (EX-M-1's write under the live `first` was realigned <date> by SAFE-2,
    W-349, and is rejected now; EX-TM-3 still shows the writes.)
```

```markdown
-   **Eager-copy value bindings, for a `&T` mapping.** SAFE-1's recorded
    alternative to D-SAFE-17, eager acquisition for every type, would make a
    value binding carry no loan. It is not upstream's rule: proposal p005434
    makes a value binding of a non-copy type a borrowed object that Strict
    prevents from being mutated, which SAFE-2 adopted, and that frozen
    binding is what gives a by-value parameter its `&T` row. The `const T*`
    rows are unchanged by either choice, because `Plain`-field writes through
    `T*` aliases during a live `const T*` remain (EX-TM-3). (Realigned
    <date>, SAFE-2: W-348. The superseded 2026-10-12 bullet read:
    "D-SAFE-17's recorded alternative, eager acquisition for every type,
    would make a value binding carry no loan and would remove one of the two
    reasons `const T*` cannot be `&T`; it was rejected on the mutation page
    as costly for large owning types, and the other reason — `Plain`-field
    writes through `T*` aliases — would remain, so the mapping would not
    change.")
```

<!-- google-doc-style-resume -->

### §A.7.1 values.md :137-143, the "Answered" note replaced

Replace the blockquote that begins "> **Answered (2026-10-12, SAFE-1 — F-013
D-SAFE-7, D-SAFE-8, D-SAFE-17):**" with:

<!-- google-doc-style-ignore -->

```markdown
> **Answered (2026-10-12, SAFE-1 — F-013 D-SAFE-7, D-SAFE-8, D-SAFE-17;
> realigned <date>, SAFE-2: W-347, W-348):** a durable entire reference
> expression is a _place_ in the safety design's sense; a `ref` binding is
> exclusive access to its place, or a frozen read of it for a `const` type,
> whatever it was formed through, as proposal p005434's `nocapture` and
> `noalias` rule requires; a value binding of a type whose value
> representation is a copy is a read, and a value binding of any other type
> binds a borrowed object, frozen while the binding lives; and `T*`,
> `exclusive T*` and `const T*` are the three pointer kinds. See
> [Temporal safety](safety/temporal_safety.md) and
> [Mutation safety](safety/mutation_safety.md). (The superseded 2026-10-12
> text read "a `ref` binding is exclusive access to its place, or has the kind
> of the pointer it was formed through; a value binding is a shared read".)
```

<!-- google-doc-style-resume -->

### §A.7.2 values.md :485-491, the "Pinned" note replaced

Replace the blockquote that begins "> **Pinned (2026-10-12, SAFE-1 — F-013
D-SAFE-17):**" with:

<!-- google-doc-style-ignore -->

```markdown
> **Pinned (2026-10-12, SAFE-1 — F-013 D-SAFE-17; realigned <date>, SAFE-2:
> W-348):** the restriction above is kept as proposal p005434 states it for
> borrowed objects. A value binding of a type whose value representation is a
> copy reads the object when it is bound and is unaffected by later mutation
> (the mutation safety page's EX-M-4a is accepted, and its `b` is 1). A value
> binding of any other type binds a borrowed object, and Strict Carbon rejects
> every mutation of it while the binding lives, invalidating or not;
> Permissive Carbon warns, and the Debug build reports the erroneous behavior
> this section describes as `MutationDuringValueBinding`. See
> [Mutation safety: Value bindings](safety/mutation_safety.md#value-bindings).
> (The superseded 2026-10-12 text read: "a value binding of a `Core.Plain` type
> acquires eagerly and is unaffected by later mutation (the mutation safety
> page's EX-M-4a is accepted, and its `b` is 1); a value binding of a
> non-`Plain` type is a shared loan under which invalidating operations are
> rejected in Strict Carbon and `Plain`-field writes through other aliases
> stay erroneous.")
```

<!-- google-doc-style-resume -->

### §A.8.1 README.md :2151-2153, Unformed state, the blockquote replaced

Replace the blockquote that begins "> **Fork amendment (2026-10-12, F-013
D-SAFE-13 I5).**" (the one under the sentence at :2147-2148 that begins "Types
may define additional initialization for the" and ends
`[hardened build mode](#build-modes).`, not the move blockquote at :2175,
which stays) with the block, whose label is dated by SAFE-2's commit and names
the 2026-10-12 amendment it replaces (amended 2026-10-28, review fold: B-M5;
rev 1 dated the new "Fork note" 2026-10-12; the locator's link amended
2026-10-28, stop-and-amend re-review: AM6-M1, where rev 6 quoted the sentence
with the link's text alone, section 8.12):

<!-- google-doc-style-ignore -->

```markdown
> **Fork note (<date>, SAFE-2: W-353, replacing the fork amendment of
> 2026-10-12, F-013 D-SAFE-13 I5).** The fork's Release build is the hardened
> build of this paragraph (fork decision D-RG-20), so its `make_uninitialized`
> zeroes the whole object, padding included, for every type, which is the
> hardening initialization of proposal p000257; a type's additional
> initialization is the customization p000257 describes. See
> [Initialization safety](safety/initialization_safety.md), rule I5. (The
> superseded 2026-10-12 amendment read: "The fork promotes this zeroing to the
> Release baseline for every type; there is no separate hardened mode.")
```

<!-- google-doc-style-resume -->

### §A.9.1 expressions/arithmetic.md :167-174, the amendment blockquote replaced

Replace the blockquote that begins "> **Amendment (2026-10-12, SAFE-1 — F-013
D-SAFE-15):**" with the block, which quotes the whole superseded blockquote
(amended 2026-10-28, review fold: RR1-m2; rev 2 rewrote "for Carbon code the
fork fixes the behavior by build mode." and "The second TODO below is
answered: wrap, not zero." without quoting them):

<!-- google-doc-style-ignore -->

```markdown
> **Amendment (2026-10-12, SAFE-1 — F-013 D-SAFE-15; realigned <date>,
> SAFE-2: W-350):** the fork reads the three rows above through the safety
> strategy's build modes: the development build is Debug, the hardened build
> is Release, and the performance build is the unsupported benchmarking build,
> the Release build with its default hardening disabled. For Carbon code, in
> the Release build signed overflow wraps to the two's complement result; in
> the Debug build, overflow fails-stop with a diagnostic; signed or unsigned
> division or remainder by zero fails-stop in both. The performance-build row
> stands for the benchmarking build, where the behavior is not defined, and no
> supported build mode has that behavior. The second TODO below is answered
> for the hardened build: wrap, not zero. See
> [Spatial safety: Arithmetic](../safety/spatial_safety.md#arithmetic). (The
> superseded 2026-10-12 text read, in full: "for Carbon code the fork fixes
> the behavior by build mode. In the Release build, signed overflow wraps to
> the two's complement result; in the Debug build, overflow fails-stop with a
> diagnostic; signed or unsigned division or remainder by zero fails-stop in
> both. The performance-build row above, under which the behavior is not
> defined, is withdrawn for Carbon code. The second TODO below is answered:
> wrap, not zero.")
```

<!-- google-doc-style-resume -->

### §A.10.1 slices.md :70, the opening example, a note inserted

Added 2026-10-28, review fold: RR1-M1: under T5(d) the write the opening
example presents as the design's behavior, `a[2] = 30` while the view `s`
lives, is rejected in Strict, and rev 2 left the page saying otherwise. Insert
after the SP3 amendment that follows the opening example, whose last line ends
with a link to the spatial page and "rule SP3.", and before "The element type
is constrained to `Copy & Destroy`", a blank line and the block (11 lines
added, no heading, list item or row):

<!-- google-doc-style-ignore -->

```markdown
> **Amendment (<date>, SAFE-2 — F-013 D-SAFE-11(d), W-349):** in Strict
> Carbon the write `a[2] = 30` above is rejected while `s` lives. `FromArray`
> takes `bound p`, so for the view's lifetime `a` is held by the view and no
> path but the view writes it, proposal p005434's "each bound parameter to be
> immutable for the duration of the lifetime of the returned result"
> ([Temporal safety](safety/temporal_safety.md), T5(d)), and the owner's write
> is `StrictBorrowedObjectMutated`. A Strict program writes `a` after the last
> use of `s`, or through the view once slice elements are writable
> ([0.1 limits](#01-limits)); Permissive warns `PermissiveAliasedExclusive`
> and accepts the write, and 0.1 keeps the unchecked contract above.
```

<!-- google-doc-style-resume -->

### §A.10.2 slices.md :264, Heap buffers, an amendment after the `Buf` bullets

Added 2026-10-28, review fold: RR2-B1: the bullets at :243-246 ("`Set(self, i,
value)` writes through the shared heap block, so it takes `self` by value")
and :256-259 ("so a callee can `Set` through it") describe the 0.1 prelude's
by-value `Set`, which D-SAFE2-5 gives `ref self` under W-144. Insert after the
bullet that ends "and its fields are trivially destroyed." (the last of the
`Buf` bullets, :260-264) and before "## Iteration", a blank line and the block
(11 lines added, the blank line and the block's 10, as A.10.1's 11, so
slices.md goes from 462 lines to 484 with both blocks; no heading, list item
or row; amended 2026-10-28, implementation: stop-and-amend: A.10.2's line
count, which rev 5 gave as 10). It goes after the list, not
into the `Set` bullet, because PR 65 rewrites that bullet's last two lines
(section 0.8); the three-way merge-file with PR 51's, PR 65's and trunk's
copies is clean.

<!-- google-doc-style-ignore -->

```markdown
> **Amendment (<date>, SAFE-2 — F-013 D-SAFE-17, W-348):** in Strict Carbon
> `Set` takes `ref self` once residue item W-144 lands, for every element
> type, an exclusive receiver: an element of the block may be a borrowed
> object, a `Core.String` bound by a live value binding among them, and the
> prelude's trusted bodies write such an object only through an exclusive
> path ([Mutation safety](safety/mutation_safety.md), M3 and Value bindings).
> So `Set` is called through an owner, a `ref` or an `exclusive` pointer while
> no view of the block, and no binding formed through one, is live, and a
> callee given a `Buf` by value or through a shared pointer cannot `Set` it,
> where 0.1 keeps the by-value receiver above.
```

<!-- google-doc-style-resume -->

## Appendix B. Records, verbatim (commit 2)

Each B.1 block is applied twice, to the F-013 entry of fork/decision-log.md and
to the same text in fork/safe/plan.md section 0.3, which are identical at
2407efa74 (measured: `diff` of fork/decision-log.md:2936-3800 against
fork/safe/plan.md:221-1085 prints nothing; the plan's line number is the log's
less 2715, as measured). The line numbers given are the log's. `<sha1>` is
commit 1's short hash.

### §B.1.0 D-SAFE-2 (log :2952-2967, plan :237-252), S0's scope, the trusted bodies and the break condition

Added 2026-10-28, review fold: B-M4 (rev 1 scoped S0 on the strategy page,
A.1.1, and left D-SAFE-2 unscoped, so that its break condition fired trivially
in the benchmarking build, where overflow is undefined behavior). Replace "A
Strict function body cannot cause a safety bug provided" with the first block,
and "Break condition: a program that Strict accepts with no `unsafe` spelled
and that exhibits a safety bug (terminology.md :150-176) — a model bug;" with
the second block. Insert the third block after "optional.carbon:186-203)."
(the end of the prelude clause, log :2964) and before the second block, a
space on each side: the trusted bodies' write rule in the words of A.1.1's
first block, which R27 aligns with D-SAFE-2 (added 2026-10-28, review fold:
RR2-B1; its `IndirectIndexWith.Ref` clause amended 2026-10-28, review fold:
RR3-M1, as A.1.1's is).

<!-- google-doc-style-ignore -->

```markdown
A Strict function body cannot cause a safety bug in a supported build mode,
Release or Debug or an extension of either (README.md:207-252), provided
```

```markdown
Break condition: a program that Strict accepts with no `unsafe` spelled and
that exhibits a safety bug (terminology.md :150-176) in a supported build mode
— a model bug; the unsupported benchmarking build of README.md:260-262 is
outside S0, so a safety bug in it alone breaks nothing (realigned <date>,
SAFE-2: W-350, W-351; fork/safe/safe2-plan.md D-SAFE2-13; the superseded
2026-10-12 text read "A Strict function body cannot cause a safety bug
provided" and "Break condition: a program that Strict accepts with no `unsafe`
spelled and that exhibits a safety bug (terminology.md :150-176) — a model
bug;");
```

```markdown
A trusted body keeps the write rule of M3 (D-SAFE-9, D-SAFE-17): it writes an
object whose type holds a `Core.SharedImmutable` sub-object only through an
exclusive path, an owner, a `ref` or an `exclusive T*`, or through a pointer
into storage owned by an object it holds exclusively, every other path to that
storage the type hands out being `bound` to that object; so
`Core.Buf(T).Set`, which writes an element of the block, takes `ref self`
under W-144, and the `Ref` method of the indexing interface
`IndirectIndexWith`, once the prelude has it, which hands out a `ref` into
the storage a `Core.Slice` views or a `Core.Buf` owns, takes `bound self`
under W-144, at the interface and in both impls, so that a binding formed
through `b[i]` keeps the loan on `b` that `Set`'s `ref self` conflicts with
(added <date>, SAFE-2: W-348; fork/safe/safe2-plan.md D-SAFE2-5).
```

<!-- google-doc-style-resume -->

### §B.1.1 D-SAFE-8 (log :3098-3121, plan :383-406), the bullet replaced

(Amended 2026-10-28, document-review fold: R1-M1, R1-m1. The block below is
commit 2's text. Since 0f281d8bd and e1574b003 the log and fork/safe/plan.md
section 0.3 also state the built-in operator's `ref` operand and give
`UsePick`'s `StrictSharedBorrowInvalidated`, as section 8.7 records.)

Replace the bullet from "**D-SAFE-8 — `ref` bindings inherit the kind of
their source.**" through "(none may; §4.1 lists them as "ACCEPTS")." with the
block, which quotes the whole superseded bullet and carries none of its
2026-10-12 marks on new text (amended 2026-10-28, review fold: B-M5, A-M-1,
A-B-2; rev 1 dropped "the result being a shared-kind `ref`", the "(shared if
any loan is shared, const if any is const)" clause and the `Pick` sentence, and
kept "A-5, RR-7" on the rewritten `Pick` sentence):

<!-- google-doc-style-ignore -->

```markdown
-   **D-SAFE-8 — Every `ref` binding is `nocapture` and `noalias`
    (p005434:83).** A `ref` binding, whatever its source, is exclusive access
    to its referent for its lifetime, or, for a `ref` of a `const` type, a
    frozen read (p005434:850-852's read-only `restrict`); one not marked
    `bound` does not escape (`captures(none)`), one marked `bound` escapes
    only into the result (`captures(ret: address, provenance)`,
    p005434:846-848). On a closed place (D-SAFE-10's vocabulary) it is a
    checked reborrow (T2, T4), as is a `const` `ref` on an open place of a
    `Core.SharedImmutable` type; any other `ref` on an open place is an
    `unsafe` formation (`let ref r: T = unsafe *p;`, `unsafe F(ref *p)`)
    whose obligation is to "adhere to just the `noalias` restrictions"
    (p005434:861-862), and unmarked it is `StrictRefFromShared`, warned in
    Permissive as `PermissiveAliasedExclusive`. A `ref` return is not a
    binding, so p005434:717-720
    (`Valid1(bound p: i32*) -> ref i32 { return *p; }`) and :826
    (`ValToRef`) stay valid in both modes, each returning a reference
    expression whose kind is that of its loans, and a call of either holds
    its `bound` argument's pointee for the result's lifetime (D-SAFE-11(d));
    a result whose loan set mixes kinds — p005434:772-779's
    `Conditional(b, bound ref r: C, bound p: C*) -> ref C` carries `{(r,
    exclusive), (*p, shared)}` — has the **weakest** kind, frozen counting
    below shared, and T4 applies to every place in the set; binding such a
    result with `let ref` is a `ref` formation like any other. Program `Pick`
    in §4.1: in `UsePick` both places of the set, `x` and `y`, are locals, so
    `let ref z = Pick(false, x, q)` forms an exclusive loan on each, and
    `q2->AsSlice()`, another carrier of `y` used while `z` lives, is
    `StrictExclusiveBorrowConflict`. T8 emits `noalias` with `captures(none)`
    or `captures(ret: address, provenance)` only where the requirement is
    established against every writer: intra-function, for a `ref` binding on
    a place whose every carrier is the body's own; on the referent of a `ref`
    parameter or the pointee of an `exclusive T*` parameter, and on those
    parameters, only under D-SAFE-10's whole-package condition; never on an
    open place, the checked `const` `ref` on a `Core.SharedImmutable` type
    included, nor for an `unsafe`-formed one or one in a Permissive body
    (p005434:866-868). Break condition: an accepted p005434 example that
    becomes invalid in Permissive mode (none may; §4.1 lists them as
    "ACCEPTS"), or an accepted upstream memory-safety proposal that narrows
    p005434:83 (W-347's own).
    (Realigned <date>, SAFE-2: W-347; fork/safe/safe2-plan.md D-SAFE2-6. The
    superseded 2026-10-12 bullet read, in full: "**D-SAFE-8 — `ref` bindings
    inherit the kind of their source.** A `ref` formed from a place is exclusive
    access (p005434:83, :173-180 kept); a `ref` formed from `*p` inherits `p`'s
    kind: exclusive from `exclusive T*`, shared-mutable from `T*` (M3 applies to
    uses of it), const from `const T*`. So p005434:717-720 (`Valid1(bound p:
    i32*) -> ref i32 { return *p; }`; re-pinned, B10) and :826 (`ValToRef`) stay
    valid in both modes (judge 2 fatal B), the result being a shared-kind `ref`.
    A `ref` or result whose loan set mixes kinds — p005434:772-779's
    `Conditional(b, bound ref r: C, bound p: C*) -> ref C` carries `{(r,
    exclusive), (*p, shared)}` — has the **weakest** kind (shared if any loan is
    shared, const if any is const), and T4 applies to every place in the set:
    program `Pick` in §4.1 (a shared-kind `ref` to `y` obtained from
    `Pick(false, x, q)` cannot be assigned a new `Buf` while `q2->AsSlice()`
    views `y`) is `StrictInvalidatingThroughShared` — a non-`Plain` assignment
    through shared-kind access, rejected even with no live view, the view `v`
    being a second reason (amended 2026-10-12, review fold: A-5; the diagnostic
    name corrected from `StrictSharedBorrowInvalidated`, re-review fold: RR-7).
    `noalias`/`captures(none)` are emitted only for exclusive-kind refs and only
    under D-SAFE-10's T8, which narrows p005434:83's "The address of a `ref`
    binding is `nocapture` and `noalias`" to the exclusive kind — a dated
    amendment on the temporal page and in the F-013 entry. Break condition: an
    accepted p005434 example that becomes invalid in Permissive mode (none may;
    §4.1 lists them as "ACCEPTS").")
```

<!-- google-doc-style-resume -->

### §B.1.2 D-SAFE-10 (log :3171-3296, plan :456-581), four sentences

(Amended 2026-10-28, document-review fold: R1-M2, R1-m2. The blocks below are
commit 2's text. Since 0f281d8bd and e1574b003 the log's and section 0.3's
reborrow clause no longer lists a by-value `bound self` as a shared formation,
and their T6 gives the marker of an `unsafe fn` call with a free result its
obligation, as section 8.7 records.)

Make four replacements in the D-SAFE-10 bullet. (i) Replace "a _loan_ is
(place, kind ∈ {exclusive, shared}, origin);" with the first block. (ii)
Replace "`let ref r = x;` exclusive; a value binding of a non-`Plain` type is a
shared loan — from a materialized temporary it owns the storage instead,
D-SAFE-17, RR-5 — of a `Plain` type an eager copy with no loan — D-SAFE-17,
M8;" with the second block. (iii) In T4 replace "a live shared loan excludes
exclusive loans and invalidating operations (D-SAFE-9)," with the third block,
and append ", frozen counting below shared" after "at the weakest kind
(D-SAFE-8, A-5"; in the reborrow clause append the fourth block after
"`vec->Push(3)` is legal only once `a`, `b` and `first` are dead." (the log's
words; rev 1 quoted an "and" before them that the log does not have, amended
2026-10-28, review fold: B-m5). (iv) Replace
"T8 codegen honesty: `noalias`/`captures(none)` are emitted for exclusive loans
only where the checker established them —" with the fifth block. (The first
block's frozen loan on a `bound` pointer argument's pointee amended
2026-10-28, review fold: RR1-m1; the second block's 2026-10-12 mark "RR-5"
moved into its quote, off the rewritten clause, review fold: RR1-m2.)

<!-- google-doc-style-ignore -->

```markdown
a _loan_ is (place, kind ∈ {exclusive, shared, frozen}, origin), a frozen
loan, a borrowed object's or a `const` `ref`'s, excluding every write to its
place, or the one a call's result holds on a `bound` `T*` or `const T*`
argument's pointee, excluding every write but the result's and its copies',
the result's own access being at the kind D-SAFE-11(a) gives the parameter
(D-SAFE-11(d)); a place is _closed_ in a body when every carrier of a loan on
it is in the body's view and _open_ otherwise (realigned <date>, SAFE-2:
W-348, W-349; fork/safe/safe2-plan.md D-SAFE2-3, D-SAFE2-4, D-SAFE2-9; the
kinds were "{exclusive, shared}");
```

```markdown
`let ref r = x;` exclusive, and every `ref` binding exclusive, or frozen for a
`const` type, formed on a closed place and, unmarked on an open place,
`StrictRefFromShared` (D-SAFE-8); a value binding of a borrowed object, whose
type's value representation is not a copy, is a frozen loan, on an open place
only for a `Core.SharedImmutable` type and `StrictBorrowFromShared` otherwise —
from a materialized temporary it owns the storage instead, D-SAFE-17 — and a
value binding of a copy-represented type a read with no loan — D-SAFE-17, M8
(realigned <date>, SAFE-2: W-347, W-348; this text read "a value binding of a
non-`Plain` type is a shared loan — from a materialized temporary it owns the
storage instead, D-SAFE-17, RR-5 — of a `Plain` type an eager copy with no loan
— D-SAFE-17, M8");
```

```markdown
a live shared loan excludes exclusive loans and invalidating operations
(D-SAFE-9), a live frozen loan excludes every write to its place through any
carrier but, for the hold a call's result has on a `bound` pointer argument's
pointee (D-SAFE-11(d)), the result and its copies,
`StrictBorrowedObjectMutated` for a non-invalidating one (D-SAFE-17; added
<date>, SAFE-2: W-348, W-349),
```

```markdown
A frozen derived loan, a by-value `bound self` of a borrowed type or a value
binding of `*p`, restricts the carrier to reads until it is dead (added <date>,
SAFE-2: W-349).
```

```markdown
T8 codegen honesty: `noalias` with `captures(none)`, or with `captures(ret:
address, provenance)` for a `bound` one, is emitted for a `ref` binding or
exclusive loan only where the checker established it against every writer,
Permissive and C++ ones included, never on an open place and never for an
`unsafe`-formed `ref` (realigned <date>, SAFE-2: W-347; this text read
"`noalias`/`captures(none)` are emitted for exclusive loans only where the
checker established them") —
```

<!-- google-doc-style-resume -->

### §B.1.2a D-SAFE-9 (log :3122-3170, plan :407-455), one sentence

Added 2026-10-28, review fold: A-B-1 (M3's new paragraph is a dependent line
of D-SAFE-9's "everything else is permitted"; amended 2026-10-28, review fold:
RR1-B1, to M3's structural rule over the types that hold such a sub-object).
Replace "Everything else (reads, overwriting `Plain` fields, `addr`/`const`
methods) is permitted through any number of aliases." with:

<!-- google-doc-style-ignore -->

```markdown
Everything else (reads, overwriting `Plain` fields, `addr`/`const` methods) is
permitted through any number of aliases, but an assignment whose type holds a
`Core.SharedImmutable` sub-object (the type itself, or an array, tuple,
struct, class or adapter that holds one, closed like `Core.Plain`), a
whole-object or field assignment and a `Plain` one included, needs exclusive
access too: `StrictSharedImmutableWrite` through `T*`, `addr self` or an open
place, so that D-SAFE-17's frozen loan on an open place of such a type is
sound, a union's field binding only under its read's `unsafe` (realigned
<date>, SAFE-2: W-348; fork/safe/safe2-plan.md D-SAFE2-5; this sentence read
"Everything else (reads, overwriting `Plain` fields, `addr`/`const` methods)
is permitted through any number of aliases.").
```

<!-- google-doc-style-resume -->

### §B.1.3 D-SAFE-11 (log :3297-3354, plan :582-639), clauses (a) and (d)

In (a) replace "with kind = the parameter's kind (`ref`/`exclusive T*` →
exclusive, value/`T*`/`const` → shared), a mixed set taking the weakest kind
(D-SAFE-8, A-5);" with the first block. Replace clause (d), from "(d) For the
duration of a returned loan" through "review fold: A-13(b))." with the second
block (amended 2026-10-28, review fold: A-B-2, A-m-1, B-M5; the pointee's
frozen loan and the result's own kind amended 2026-10-28, review fold:
RR1-m1).

<!-- google-doc-style-ignore -->

```markdown
with kind = the parameter's kind (`ref` → exclusive under a `ref` return and
frozen under a `val` or by-value return, `exclusive T*` → exclusive,
`T*`/`const T*` → shared, a by-value parameter of a borrowed type or a `const`
`ref` → frozen), a mixed set taking the weakest kind, frozen counting below
shared (D-SAFE-8; realigned <date>, SAFE-2: W-349, where the map read
"`ref`/`exclusive T*` → exclusive, value/`T*`/`const` → shared" and carried the
mark A-5);
```

```markdown
(d) For the duration of a returned loan each bound argument is immutable, as
p005434:831-832 asks, and no path but the result writes it: a by-value
argument of a borrowed type, `bound self` included, and a `const` `ref` keep
their frozen loan, so no path writes their storage while the result lives
(`StrictBorrowedObjectMutated`); a `bound ref` argument keeps its exclusive
loan, which the result carries, under a `ref` return, and a frozen loan under
a `val` or by-value return (p005434:825's `RefToVal`); the pointee of a
`bound` pointer argument is held by the result under a frozen loan (an
exclusive one for an `exclusive T*`), written through no other carrier while
the result lives and by the result only at the kind (a) gives the parameter,
on a closed place by T4 and on an open place only for a `Core.SharedImmutable`
type, else `StrictBorrowFromShared` or
`unsafe` at the call (realigned <date>, SAFE-2: W-349; fork/safe/safe2-plan.md
D-SAFE2-9; the superseded 2026-10-12 text read: "the bound argument stays
borrowed in the caller at the parameter's kind: p005434:831-832 asks for the
bound parameter to be "immutable for the duration", which this design
**narrows** to "not invalidated" — a shared-kind bound argument stays writable
in its `Plain` fields through other aliases (the D-SAFE-17 narrowing applied at
a second site; a dated narrowing on the temporal page, in §4.3's list and in
the F-013 entry — amended 2026-10-12, review fold: A-13(b))").
```

<!-- google-doc-style-resume -->

### §B.1.4 D-SAFE-13 (log :3369-3426, plan :654-711), I5 and the break condition

Replace the I5 parenthesis, from "(p000257:355-358; README.md:2147-2149's hook,"
through "review fold: A-13(e));", with the first block, and the break
condition, from "Break condition: a benchmark in the fork showing more than 0.5
percent" through "(the same pass knows which).", with the second block.

<!-- google-doc-style-ignore -->

```markdown
which is p000257:356-358's hardening initialization in the build D-RG-20 reads
as the hardened one (README.md:2147-2149's hook; p005914:87-88's
zero-initialization), a type customizing it under p000257:358-360 with the
spelling left to upstream, and which the unsupported benchmarking build skips
(realigned <date>, SAFE-2: W-353, closed as a classification corrected; the
superseded parenthesis read "(p000257:355-358; README.md:2147-2149's hook,
promoted from "hardened" to the Release baseline, which p005914:87-88 permits —
a dated departure disclosed by a §2.9-style blockquote at README.md:2147,
amended 2026-10-12, review fold: A-13(e))");
```

```markdown
Break condition: an upstream amendment of p000257's hardening initialization,
or a reconciliation of the build-mode pages otherwise than D-RG-20 reads them —
then I5 follows the upstream text in a dated edit (realigned <date>, SAFE-2:
W-353; the superseded break condition read "a benchmark in the fork showing
more than 0.5 percent from zero-fill alone — then zero-fill is scoped to
escaped-unformed objects only (the same pass knows which)").
```

<!-- google-doc-style-resume -->

### §B.1.5 D-SAFE-14 (log :3427-3482, plan :712-767), the heading, SP2, SP4 and the break condition

Replace the heading "**D-SAFE-14 — Spatial: fail-stop everywhere, `unsafe fn`
is the opt-out, views carry loans.**" with "**D-SAFE-14 — Spatial: fail-stop in
every supported build mode, `unsafe fn` is the supported opt-out, views carry
loans.**"; in SP2 replace "a violation fails-stop in every build mode" with "a
violation fails-stop in every supported build mode"; replace SP4's sentence
from "no build flag disables checks — README.md:260-262's promise" through "at
the site rather than the build." with the first block; and replace "Break
condition: none for the semantics; the unchecked-accessor name is the residue
item's." with the second block, which quotes it (amended 2026-10-28, review
fold: RR1-m2, the slip RR1-m2 found in A.5.9 repeated here: rev 2 marked the
rewritten break condition "added" and did not quote it).

<!-- google-doc-style-ignore -->

```markdown
README.md:260-262's promise that Carbon "will provide a way to disable the
default hardening in release builds, but not in a supported way", "strictly
for benchmarking purposes", is kept as the _benchmarking build_, the Release
build without the bounds check, the division guard, the overflow wrap and the
hardening initialization, outside every guarantee of the pages and spelled with
the build modes at stage 2 (W-146), while the per-site `unsafe fn GetUnchecked`
is the supported disable, which keeps p000196:45-48's "manually disabled for
performance-critical use cases" at the site (realigned <date>, SAFE-2: W-351;
fork/safe/safe2-plan.md D-SAFE2-13; the superseded text read "no build flag
disables checks — README.md:260-262's promise that Carbon "will provide a way
to disable the default hardening in release builds, but not in a supported
way" is **withdrawn by the fork, dated** (amended 2026-10-12, review fold:
A-13(c)): the per-site `unsafe fn GetUnchecked` is the only disable, which
keeps p000196:45-48's "manually disabled for performance-critical use cases" at
the site rather than the build", the heading "fail-stop everywhere, `unsafe
fn` is the opt-out" and SP2 "in every build mode").
```

```markdown
Break condition: none for the semantics in the supported build modes; the
unchecked-accessor name is the residue item's; an upstream withdrawal of the
benchmarking promise removes the benchmarking build with it (realigned
<date>, SAFE-2: W-351; this sentence read "Break condition: none for the
semantics; the unchecked-accessor name is the residue item's.").
```

<!-- google-doc-style-resume -->

### §B.1.6 D-SAFE-15 (log :3483-3493, plan :768-778), the bullet replaced

Replace the bullet from "**D-SAFE-15 — Arithmetic (amends
arithmetic.md:150-166," through "an owner call on a performance-build
opt-in." with:

<!-- google-doc-style-ignore -->

```markdown
-   **D-SAFE-15 — Arithmetic (reads arithmetic.md:150-166 through the build
    modes, answers its :171-173 TODO for Release).** Release: signed overflow
    wraps (the existing lowering, lower/handle_call.cpp:165-181, made
    normative) and signed or unsigned division/remainder by zero fails-stop
    (NEW guard before `CreateSDiv`/`CreateSRem`, :188-192; stage 2). Debug:
    overflow fails-stop with a diagnostic. Compile-time overflow is already
    rejected. Under D-RG-20 the development build is Debug, the hardened build
    is Release and the "performance build ... behavior ... is not defined"
    row is the unsupported benchmarking build of README.md:260-262 (D-SAFE-14),
    the Release build with its default hardening disabled; the row stands, and
    p005914:85-88's prohibition of UB in safe code holds in every supported
    build mode, where bounds checks make overflow a logic bug rather than a
    memory bug. Break condition: an upstream answer to :171-173 other than
    wrap, a rewrite of the rows, or a reconciliation of the build-mode pages
    otherwise than D-RG-20 reads them — the rule then follows the upstream
    text in a dated edit (W-350's own). (Realigned <date>, SAFE-2: W-350;
    fork/safe/safe2-plan.md D-SAFE2-11. The superseded 2026-10-12 heading read
    "(amends arithmetic.md:150-166, answers its :171-173 TODO)" and the text:
    "The "performance build ... behavior ... is not defined" row is withdrawn
    for Carbon code because p005914:85-88 forbids UB in safe code and bounds
    checks make overflow a logic bug rather than a memory bug. Break
    condition: a real-world benchmark (p005914:110-111's class) where the
    loss of `nsw` exceeds 0.5 percent — an owner call on a performance-build
    opt-in.")
```

<!-- google-doc-style-resume -->

### §B.1.7 D-SAFE-17 (log :3532-3568, plan :817-853), the bullet replaced

(Amended 2026-10-28, document-review fold: R1-M2. The block below is commit
2's text. Since 0f281d8bd the decision also names the marker's obligation for a
binding formed through the free result of a marked `unsafe fn` call, as
section 8.7 records.)

Replace the bullet from "**D-SAFE-17 — Value bindings through shared
pointers (MS-5, ratified" through "then the eager-copy alternative is
adopted." with the block, which quotes the whole superseded bullet and carries
none of its 2026-10-12 marks (A-8, B3, B13(c), RR-5) on rewritten text
(amended 2026-10-28, review fold: B-M5, A-B-1, A-M-2, A-m-2, A-m-4; rev 1
dropped "Memory safety holds ..." and the alternative's "simplest" from the
quote, left "A-8, B3" and "B13(c)" on rewritten sentences, kept "of a
non-`Plain` type" in the temporary's sentence, listed the opt-ins
unconditionally and cited values.md:461-462 for the storage reading; amended
2026-10-28, review fold: RR1-B1: M3's clause states the structural rule over
the types that hold such a sub-object, and the Debug count is per byte, where
rev 2 read "M3 rejects every Strict write of such a type's storage through a
shared path" and "a per-object count of live frozen loans"; amended
2026-10-28, review fold: RR2-B1: the trusted bodies keep M3's rule and `Set`
takes `ref self`, the storage sentence names the element write through
`Data()` where rev 3 read "so `Core.Buf`'s by-value `Set` stays callable on a
borrowed `Buf`", and the break condition is answered by fixing a prelude
function, where rev 3 read "or a prelude `Core.SharedImmutable` opt-in is
shown false, by a prelude function or by a language-level write through a
shared path, which withdraws that opt-in in a dated edit."; amended
2026-10-28, review fold: RR2-m1: the Debug flag tests every store, where rev 3
read "a `Plain` assignment through `T*`, to a field or to a whole object, that
writes a byte whose count is non-zero, or an `addr self` call on an object one
of whose bytes has a non-zero count, reports"; amended 2026-10-28, review
fold: RR3-M1, RR3-m1: the trusted-body sentence gains the
`IndirectIndexWith.Ref` clause, where rev 4 ended it "moves before its
view).", and the storage sentence the element paths after "`Data()`
returns", where rev 4 ended it there).

<!-- google-doc-style-ignore -->

```markdown
-   **D-SAFE-17 — Value bindings of borrowed objects (MS-5; realigned to
    p005434:660-672).** A value binding of a type whose value representation
    is a copy — its `value_rep` (values.md, "Value representation and
    customization"), or the implementation's choice, which upstream's
    toolchain makes for `bool`, the integer, floating-point and pointer
    types, a struct or tuple of one element, and an adapter, `const T` or
    `MaybeUnformed(T)` of a copy-represented `T` other than `bool`
    (toolchain/check/type_completion.cpp:572-578, :697-751, :762-770,
    :783-789 and :803-826 at 0421bf3b4), `Core.Optional(T*)` among them —
    reads the object when it is bound and carries no loan, so `let b: i32 =
    a; a = 2; return b;` is **accepted in Strict and returns 1** (EX-M-4a;
    values.md:456-468's erroneous reading does not arise, and the
    values.md:473-475 dated note says so); the element of a one-element
    struct or tuple whose own value representation is not a copy is a
    borrowed object of the binding. A value binding of any other type, every
    other class, every array and every struct or tuple of more than one
    element today (type_completion.cpp:580-582, :674-695, :771-781), binds a
    _borrowed object_ (p005434:660-661) and holds a frozen loan on it for the
    binding's NLL lifetime (T2): every write to the object's storage through
    any carrier is rejected in Strict, `StrictSharedBorrowInvalidated` for an
    invalidating one (T4; EX-M-4b) and `StrictBorrowedObjectMutated`
    otherwise (EX-M-4c) — p005434:663's prevention of mutation of borrowed
    objects in strict mode, and M8 stated as a rule. The loan is formed on a
    closed place (D-SAFE-10), and on an open place only when the bound type
    is `Core.SharedImmutable`, an opt-in facet
    (`unsafe impl T as Core.SharedImmutable {}`) promising that no path but an
    exclusive one writes the type's storage: M3 rejects every Strict
    assignment through a shared path whose type holds such a sub-object, the
    type itself or an array, tuple, struct, class or adapter that holds it, a
    whole-object `Plain` assignment included (`StrictSharedImmutableWrite`; a
    union's field binds only under its read's `unsafe`), and the author's
    obligation covers what the checker cannot see (every field private, no
    `addr` method writing `self`, no function writing the storage through a
    shared path or returning a non-`const` pointer or `ref` into it, no stored
    self-pointer). It implies `Core.Freeze`; the prelude opts in for
    `Core.String` and, under `forall [T: Core.Freeze]`, for `Core.Slice(T)`,
    `Core.Buf(T)` and `Core.Optional(T)`, and for `Core.Box(T)` once W-144
    adds it (W-144). A trusted body keeps the write rule of M3: it writes an
    object whose type holds a `Core.SharedImmutable` sub-object only through
    an exclusive path, an owner, a `ref` or an `exclusive T*`, or through a
    pointer into storage owned by an object it holds exclusively, every other
    path to that storage the type hands out being `bound` to that object; so
    `Core.Buf(T).Set`, which writes an element of the block, takes
    `ref self` under W-144 (EX-M-4d's `Peek8`; EX-TM-3's `buf.Set(1, 7)`
    moves before its view), and the `Ref` method of the indexing interface
    `IndirectIndexWith`, once the prelude has it, which hands out a `ref`
    into the storage a `Core.Slice` views or a `Core.Buf` owns, takes
    `bound self` under W-144, at the interface and in both impls, so that a
    binding formed through `b[i]` keeps the loan on `b` that `Set`'s
    `ref self` conflicts with. Any other binding of a borrowed object on an
    open place is `StrictBorrowFromShared` (EX-M-4d), fixed by an owner or an
    `exclusive T*`, `Core.Guarded(T)`, `value_rep = const Self`, a `var`
    copy, or `unsafe` at the binding with the obligation that no path mutates
    the object while the binding lives. The object's storage is its own bytes
    and sub-objects; storage reached through a pointer it holds is another
    object's (the reading of values.md:461-462's "the object or its storage"
    that fork/safe/safe2-plan.md D-SAFE2-3 makes and its risk R-3 records), so
    an `i32` element of a borrowed `Buf` may still be written through the
    `T*` that a view's `Data()` returns, element `i` through the one-element
    view `AsSlice().Subslice(i, i + 1)`, and through `b[i] = v` once
    `IndirectIndexWith` lands. Mutation
    by unchecked code — a Permissive body, the aliases an `unsafe` binding
    promised away, C++ — stays erroneous (p005434:670-672), never undefined
    behavior (T8 emits no `noalias` on an open place), and is Debug-detected
    by a value-binding shadow flag: Debug keeps, in shadow memory keyed by
    address (never in the object's layout), a count of live frozen loans for
    each byte of a borrowed object's storage, incremented when the binding is
    formed and decremented at its last use as stage 4 computes it; every
    store that writes a byte whose count is non-zero, of any type and by any
    path, through `T*`, through a `ref`, through the owner, to a global by
    name or in an `addr self` body, reports `MutationDuringValueBinding`,
    "carbon: mutation of a borrowed object; terminating", a Strict body's
    store among them only when a Permissive caller made it aliasing. A value binding
    initialized from an initializing expression — a materialized temporary,
    values.md:186-192's third source, neither `*p` nor an owner — takes
    ownership of the materialized storage,
    values.md:192's `var` rule applied to `let`, and carries no loan on it,
    so `let o: Core.Optional(i32) = Core.Optional(i32).Some(1);` followed by
    `o.HasValue()` on the next line is accepted; the loans carried _by_ the
    value are unaffected, which is why EX-TM-7b's view of a temporary `Buf`
    stays `StrictBorrowOfTemporary`. Alternative recorded and rejected: eager
    acquisition for every type (always copy — not upstream's rule and costly
    for large owning types; a type's `value_rep` is upstream's way to choose
    a copy). Consequence for Rust (D-SAFE-19): a by-value parameter of a
    borrowed `Freeze` type exports as `&T`. Break condition: upstream relaxes
    p005434:663 under its :665-669 conditions (W-348's own); or a prelude
    function is shown to write storage that holds a `Core.SharedImmutable`
    sub-object through a shared path, an element of a block it owns included,
    which is answered by fixing that function in a dated edit, its receiver
    made exclusive or its body changed (W-144); or a language-level write
    through a shared path is shown, which M3 answers; an opt-in is withdrawn,
    in a dated edit, only when its own type's author obligation is shown
    false and no fix of the function keeps it.
    (Realigned <date>, SAFE-2: W-348; fork/safe/safe2-plan.md D-SAFE2-3,
    D-SAFE2-5, D-SAFE2-7. The superseded 2026-10-12 bullet read, in full:
    "**D-SAFE-17 — Value bindings through shared pointers (MS-5, ratified
    explicitly).** A value binding of a `Plain` type — from `*p` or from an
    owner — acquires eagerly (a copy, README.md:1319-1321) and carries no loan,
    so `let b: i32 = a; a = 2; return b;` is **accepted in Strict and returns
    1** (EX-M-4a; values.md:456-468's erroneous reading does not arise, and the
    values.md:473-475 dated note says so — amended 2026-10-12, review fold: A-8,
    B3); a value binding of a non-`Plain` type, from `*p` or from an owner, is a
    shared loan on the bound object for the binding's NLL lifetime (T2) under
    which invalidating operations are `StrictSharedBorrowInvalidated` (T4;
    EX-M-4b) — this is M8 stated as a rule — while `Plain`-field writes through
    _other_ shared aliases during the binding remain erroneous
    (values.md:456-468) and are Debug-detected by a value-binding shadow flag:
    Debug keeps, in shadow memory keyed by object address (never in the object's
    layout), a per-object count of live non-`Plain` value bindings, incremented
    when the binding is formed and decremented at its last use as stage 4
    computes it; a `Plain`-field write through `T*` or `addr self` whose
    target's count is non-zero reports `MutationDuringValueBinding` (amended
    2026-10-12, review fold: B13(c)). A value binding of a non-`Plain` type
    initialized from an initializing expression — a materialized temporary,
    values.md:186-192's third source, neither `*p` nor an owner — takes
    ownership of the materialized storage, values.md:192's `var` rule applied to
    `let`, and carries no loan on it, so `let o: Core.Optional(i32) =
    Core.Optional(i32).Some(1);` followed by `o.HasValue()` on the next line is
    accepted; the loans carried _by_ the value are unaffected, which is why
    EX-TM-7b's view of a temporary `Buf` stays `StrictBorrowOfTemporary`
    (amended 2026-10-12, re-review fold: RR-5). Memory safety holds (plain
    fields carry no ownership; owning fields cannot be written through `T*`;
    exclusive writes are statically dead for the binding's lifetime); what is
    narrowed is p005434:660-663's plan to prevent _all_ mutation of borrowed
    objects in strict (judge 1 fatal B: must be ratified, not inherited).
    Alternative recorded: eager acquisition for every type (always copy —
    simplest, costly for large owning types). Consequence for Rust (D-SAFE-19):
    such a parameter exports as `&SharedView<T>`, not `&T`. Break condition: a
    demonstrated memory-safety (not correctness) consequence — then the
    eager-copy alternative is adopted.")
```

<!-- google-doc-style-resume -->

### §B.1.8 D-SAFE-19 (log :3645-3710, plan :930-995), the mapping, verdict parts (1) and (3), the break condition, the slice proviso

Five replacements in the bullet (rev 3 had four). (i) Replace "(EX-TM-3,
EX-M-1), so an `IntVec` reachable" with "(EX-TM-3; EX-M-1's write under a live
`first` is rejected since SAFE-2, W-349), so an `IntVec` reachable", and insert
the first block after "(amended 2026-10-12, review fold: A-9);" (the end of the
`const T*` clause). (ii) In verdict part (1) replace "`const T*` as
`&SharedView<T>`, with `bound`-expressible lifetimes," with "`const T*` as
`&SharedView<T>`, a by-value parameter of a borrowed `Freeze` type as `&T`, with
`bound`-expressible lifetimes,". (iii) In part (3) replace "(`SharedView`/`SharedSlice`
instead, the D-SAFE-17 case generalized — moved here from part (1), A-9)" with
the second block. (iv) Append the third block after "and the page says so." at
the bullet's end. (v) Replace "(`Buf.Set` during a live view is the plan's own
EX-TM-3 — A-9)" (log :3672) with the fourth block, the reason A.6.3a gives the
page's `Core.Slice(const T)` row (added 2026-10-28, review fold: RR2-B1, a fifth
replacement: `Core.Buf(T).Set` takes `ref self`, so the call that reason names
is rejected under a live view).

<!-- google-doc-style-ignore -->

```markdown
a by-value parameter of a borrowed type, frozen for the call (D-SAFE-17), ↔
`&T` when `T: Core.Freeze` and `&SharedView<T>` otherwise, `At`'s by-value
`bound self` receiver becoming `&'a Self` while its element result stays
`&'a SharedView<i32>` (realigned <date>, SAFE-2: W-348; fork/safe/safe2-plan.md
D-SAFE2-10);
```

```markdown
(`SharedView`/`SharedSlice` instead, because a `const T*` freezes nothing —
moved here from part (1), A-9; realigned <date>, SAFE-2: W-348, where this
read "the D-SAFE-17 case generalized")
```

```markdown
A Rust soundness argument against `&T` for a frozen by-value parameter returns
that row to `&SharedView<T>` (added <date>, SAFE-2: W-348).
```

```markdown
(an element written through the `T*` that a view's `Data()` returns while
another view of the same storage lives — A-9; realigned <date>, SAFE-2: W-348,
where this read "`Buf.Set` during a live view is the plan's own EX-TM-3",
`Core.Buf(T).Set` now taking `ref self`)
```

<!-- google-doc-style-resume -->

### §B.1.9 D-SAFE-20 (log :3711-3728, plan :996-1013), one name added

Replace "`Core.Plain`, `Core.Relocatable`, `Core.Send`/`Sync`/`Freeze`
(compiler-determined; `unsafe impl` opt-in)," with:

<!-- google-doc-style-ignore -->

```markdown
`Core.Plain`, `Core.Relocatable`, `Core.Send`/`Sync`/`Freeze`
(compiler-determined; `unsafe impl` opt-in), `Core.SharedImmutable` (opt-in
only, by `unsafe impl`, implying `Freeze`, its shared-path writes rejected by
M3; the prelude's opt-ins for `Core.String` and, for a `Freeze` argument,
`Core.Slice(T)`, `Core.Buf(T)` and `Core.Optional(T)`, and for `Core.Box(T)`
once it exists, are W-144's; added <date>, SAFE-2: W-348),
```

<!-- google-doc-style-resume -->

### §B.1.10 D-SAFE-21 (log :3729-3758, plan :1014-1043), stages 2 and 4

Replace "Release zero-fill)." (the end of stage 2's parenthesis) with the first
block, and "Stage 4: the loan checker (T1-T8, `bound`, no-invalidation,
`exclusive`), `error` default, `noalias` under T8." with the second block.

<!-- google-doc-style-ignore -->

```markdown
Release zero-fill; the unsupported benchmarking build that disables them,
W-146 — realigned <date>, SAFE-2: W-350, W-351).
```

```markdown
Stage 4: the loan checker (T1-T8, `bound`, no-invalidation, `exclusive`,
frozen loans and the closed-place rule, the `bound` pointer argument's
pointee, `Core.SharedImmutable` and M3's write rule for it), `error` default,
`noalias` under T8 where established (realigned <date>, SAFE-2: W-347, W-348,
W-349).
```

<!-- google-doc-style-resume -->

### §B.2.1 The register block (log :3920-3940), the spellings and the departures sentence

In the library names replace "`DynCast`/`Move`/`Utf8`/`Atomic`/`Thread` —"
with "`DynCast`/`Move`/`Utf8`/`Atomic`/`Thread`/`SharedImmutable` (the last
added <date>, SAFE-2: W-348; silent at the tip under RG-1's entry H1.7, whose
check SAFE-2 widened to it) —" (amended 2026-10-28, review fold: B-M2, B-M5).
Since the records commit of the document-review fold the log's parenthesis
names SAFE-2's PR 67 note commit (section 3 step 6) as the act that widens
H1.7's silence check, with its dated mark, the widening being that commit's
and not yet on PR 67's head (amended 2026-10-28, document-review fold: R2-m3).
Replace the parenthesized departures, from "p005434:83
(`noalias`/`captures(none)` for exclusive-kind refs only," through "Release
baseline, D-SAFE-13)," with the first block, and append the second block
after "are disclosed on the owning page.".

<!-- google-doc-style-ignore -->

```markdown
p005434:83 (`noalias`/`captures(none)` for exclusive-kind refs only,
D-SAFE-8; realigned <date> by SAFE-2 at <sha1>: every `ref` binding),
p005434:663 (D-SAFE-17; realigned <date> by SAFE-2 at <sha1>: Strict prevents
mutation of borrowed objects), p005434:831-832 ("immutable" narrowed to "not
invalidated", D-SAFE-11(d); realigned <date> by SAFE-2 at <sha1>: immutable),
arithmetic.md:156-158 (the performance-build row withdrawn, D-SAFE-15;
realigned <date> by SAFE-2 at <sha1>: the row stands for the benchmarking
build), safety README.md:260-262 (the benchmarking disable withdrawn,
D-SAFE-14; realigned <date> by SAFE-2 at <sha1>: the benchmarking build
kept), docs/design/README.md:2130-2132 (upstream's at f27a977d8; this branch's
copy :2147-2149; zero-fill promoted to the Release baseline, D-SAFE-13; closed
<date> by SAFE-2 at <sha1>, its classification corrected: p000257:356-358,
accepted text the departure list did not cite, zeroes every type's storage as
hardening initialization, so the rule is upstream's and only its disclosure
was corrected),
```

```markdown
Since <date> (SAFE-2, <sha1>; fork/safe/safe2-plan.md) the first six are no
longer departures: five are realigned to the accepted text and the sixth was
upstream's rule; they stay listed, dated, as history.
```

<!-- google-doc-style-resume -->

### §B.2.2 RG-1's paragraph (log :3941-3983), a SAFE-2 sentence per item

Insert after "its cite above corrected from this branch's copy)." and before
"Each decision is named on two to five of this branch's pages" (amended
2026-10-28, review fold: A-B-1, A-B-2, A-m-3, B-M1). Commit 2 writes "pending"
for `<sha2>`, which section 3 step 4's records commit fills (amended
2026-10-28, document-review fold: R2-m1), and the block's last clause reads
as amended 2026-10-28, document-review fold: R2-m3, the re-classification
being the PR 67 note commit's act, not yet on PR 67's head:

<!-- google-doc-style-ignore -->

```markdown
SAFE-2 made those realignments on <date> (commits <sha1> and <sha2>;
fork/safe/safe2-plan.md): p005434:83 (realigned <date>, SAFE-2: W-347, every
`ref` binding `nocapture` and `noalias`, an `unsafe` formation where the
checker cannot establish it), p005434:663 (realigned <date>, SAFE-2: W-348,
borrowed objects keyed on the value representation, frozen in Strict,
`Core.SharedImmutable` the opt-in for open places, its shared-path writes
rejected by M3), p005434:831-832 (realigned <date>, SAFE-2: W-349, each
`bound` argument immutable for the result's lifetime, a pointer argument's
pointee included), arithmetic.md:156-158 (realigned <date>, SAFE-2: W-350, the
row kept for the benchmarking build under D-RG-20), safety README.md:260-262
(realigned <date>, SAFE-2: W-351, the benchmarking build kept and unsupported)
and the zero-fill (closed <date>, SAFE-2: W-353, its classification
corrected: p000257:356-358, "The entire storage, including any padding bytes,
for all types will be at least be zeroed as part of hardening initialization",
is accepted text, there at the cut and cited by I5 at the filing
(initialization_safety.md:223-226, as p000257:355-358), that makes the
zeroing language-defined for every type, and README.md:2130-2132's
"additional initialization" is p000257:358-360's customization beyond it;
RG-1's H1.13 row had not quoted it, and SAFE-2's PR 67 note commit
(fork/safe/safe2-plan.md section 3 step 6) re-classifies H1.13 ALIGNED in PR
67's register, amended 2026-10-28, document-review fold: R2-m3, where this
read "and PR 67's register re-classifies H1.13 ALIGNED"; I5's text gained the
customization and lost the word "promotes").
```

<!-- google-doc-style-resume -->

### §B.3.1 fork/safe/plan.md, a pointer paragraph after Status

Insert after the Status paragraph (it ends "(precedent: commit 119b35439's
message).") and before "**Items:**" (amended 2026-10-28, review fold: RR2-m2:
the last two sentences make §2, the 2026-10-12 deliverable spec, history and
name its lines that state the six rules, where rev 3's pointer named only
§0.3, §1, §4.1 and §4.3; D-SAFE-2 and D-SAFE-9, which B.1.0 and B.1.2a edit,
are added to the list rev 3 gave):

<!-- google-doc-style-ignore -->

```markdown
**Realigned (<date>, SAFE-2):** D-SAFE-2, D-SAFE-8, D-SAFE-9, D-SAFE-10's
vocabulary, T2, T4 and T8, D-SAFE-11(a) and (d), D-SAFE-13's I5, D-SAFE-14,
D-SAFE-15, D-SAFE-17, D-SAFE-19, D-SAFE-20 and D-SAFE-21 in §0.3, and the §1,
§4.1 and §4.3 text that states them, were realigned to upstream under R32 by
fork/safe/safe2-plan.md (W-347 to W-351 realigned, W-353 closed as a
classification corrected). Each realigned passage carries "(realigned <date>,
SAFE-2: W-n)" and quotes the text it supersedes; the "Realigned notes
(SAFE-2)" section after the landed notes records the commits. §2, the
deliverable spec of 2026-10-12 that SAFE-1's commits implemented, is history
and is not edited: where it states the six rules or the by-value
`Core.Buf(T).Set`, at its lines of 2407efa74 :1391-1392, :1518, :1530, :1533,
:1559, :1641, :1643, :1679, :1694, :1697, :1701, :1704, :1743, :1772-1774,
:1786 and :1789-1795, it is superseded by the pages as fork/safe/safe2-plan.md
Appendix A realigns them.
```

<!-- google-doc-style-resume -->

### §B.3.2 fork/safe/plan.md §1.1 (:1110-1149), S0's sentence, the matrix's Debug cell, four rows and a sentence

Append the first block to the S0 sentence that ends "every obligation the
checker cannot discharge is spelled `unsafe` at the operation." (amended
2026-10-28, review fold: B-M4: the sentence R27 aligns with A.1.1 and
D-SAFE-2). Replace the row whose first cell is "`StrictSharedBorrowInvalidated`
(§1.5)" with the second block's first row (its Debug cell re-worded, amended
2026-10-28, review fold: B-m6) and insert the block's other four rows after it
(the fourth amended 2026-10-28, review fold: A-B-1). Insert the third block,
the sentence, after the table.

<!-- google-doc-style-ignore -->

```markdown
S0 is stated for the supported build modes; the unsupported benchmarking build
of README.md:260-262 is outside it (realigned <date>, SAFE-2: W-350, W-351).
```

```markdown
| `StrictSharedBorrowInvalidated` (§1.5) | error | warning `PermissiveAliasedExclusive` | ASan-class detection when the invalidation frees what a loan reads; the value-binding report is `StrictBorrowedObjectMutated`'s (realigned <date>, SAFE-2: W-348; this cell read "`MutationDuringValueBinding` for the value-binding case (D-SAFE-17)") |
| `StrictRefFromShared` (§1.5; realigned <date>, SAFE-2: W-347) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowFromShared` (§1.6; realigned <date>, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowedObjectMutated` (§1.6; realigned <date>, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` |
| `StrictSharedImmutableWrite` (§1.6; realigned <date>, SAFE-2: W-348) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` when a binding of the object is live |
```

```markdown
The matrix is the supported build modes'. The unsupported benchmarking build of
README.md:260-262 removes the bounds check, the division guard, the overflow
wrap and the hardening initialization, and no row holds in it (realigned
<date>, SAFE-2: W-350, W-351).
```

<!-- google-doc-style-resume -->

### §B.3.3 fork/safe/plan.md §1.3 and §1.4 (:1181-1206), two sentences

In §1.3 append the first block after "sees zeros, never garbage (erroneous,
defined)."; in §1.4 append the second block after "(the fail-stop rows of
§1.1's matrix are identical in every mode).".

<!-- google-doc-style-ignore -->

```markdown
The zero-fill is p000257:356-358's hardening initialization in the Release
build, a type customizing it under p000257:358-360 (realigned <date>, SAFE-2:
W-353).
```

```markdown
Every check of this section is the supported build modes'; the unsupported
benchmarking build removes them, and the arithmetic design's performance-build
row stands for it (realigned <date>, SAFE-2: W-350, W-351).
```

<!-- google-doc-style-resume -->

### §B.3.4 fork/safe/plan.md §1.5 (:1207-1238), the opening sentence, a paragraph after the table, the diagnostics

Replace "`ref` inheritance (D-SAFE-8)," with "`ref` bindings, every one
`noalias` (D-SAFE-8; realigned <date>, SAFE-2: W-347, where this read "`ref`
inheritance"),". Insert the first block after the kinds table (its last row's
first cell is "unverified (any kind)"; its last clause amended 2026-10-28,
review fold: RR1-B1, to M3's structural rule, where rev 2 read "exclude the
storage of a `Core.SharedImmutable` type, which only an exclusive path
writes"). Replace "Diagnostics: `StrictExclusiveBorrowConflict`" with the
second block.

<!-- google-doc-style-ignore -->

```markdown
Every `ref` binding is exclusive access to its referent, or a frozen read of it
for a `const` type, whatever its source; a value binding of a borrowed object
holds a frozen loan, the third loan kind; through `T*` or `const T*` either is
formed only on a closed place or, for a frozen one, a `Core.SharedImmutable`
type, and is an `unsafe` operation otherwise; and the `T*` row's `Plain` writes
exclude every assignment whose type holds a `Core.SharedImmutable` sub-object,
which only an exclusive path makes (§1.6's M3; realigned <date>, SAFE-2:
W-347, W-348; the table's rows are unchanged).
```

```markdown
Diagnostics: `StrictRefFromShared` ("`ref` binding `{0}` of `{1}` through a
shared path; use an `exclusive` pointer or `unsafe`"; realigned <date>,
SAFE-2: W-347), `StrictExclusiveBorrowConflict`
```

<!-- google-doc-style-resume -->

### §B.3.5 fork/safe/plan.md §1.6 (:1239-1273), M5 and M8

Replace "through a shared path as shared sub-loans whose alternative cannot
change while they live" with the first block, and the M8 clause from "M8 value
bindings, stated (D-SAFE-17, A-8/B3):" through "and holds no loan (RR-5)."
with the second block. Replace "`StrictNotSend`, `StrictNotSync`, Debug report
`MutationDuringValueBinding`." with "`StrictBorrowFromShared`,
`StrictBorrowedObjectMutated`, `StrictSharedImmutableWrite` (realigned <date>,
SAFE-2: W-348), `StrictNotSend`, `StrictNotSync`, Debug report
`MutationDuringValueBinding` ("carbon: mutation of a borrowed object;
terminating").". In M4 replace "may assign `Plain` fields (`i32`, pointers,
`Slice`, the prelude's non-owning `String`)," with "may assign `Plain` fields
(`i32`, pointers; a field whose type holds a `Core.SharedImmutable`
sub-object, a `Slice(T)` for a `Freeze` `T`, a `String` or an aggregate
holding one, and `*self` when `Self` holds one, only through exclusive
access, M3 — realigned <date>,
SAFE-2: W-348, where this read "(`i32`, pointers, `Slice`, the prelude's
non-owning `String`)")," and in M3 replace "M3 the no-invalidation rule and
`Core.Plain` (D-SAFE-9);" with "M3 the no-invalidation rule and `Core.Plain`
(D-SAFE-9), and exclusive access for every assignment whose type holds a
`Core.SharedImmutable` sub-object, the type itself or an array, tuple,
struct, class or adapter that holds it (realigned <date>, SAFE-2: W-348);"
(amended 2026-10-28, review fold: A-B-1; the M4 and M3 texts amended
2026-10-28, review fold: RR1-B1, to M3's structural rule, where rev 2's read
"a `Slice` or `String` field, a `Core.SharedImmutable` type, only through
exclusive access" and "every write of a `Core.SharedImmutable` type's
storage"; and the second block's M8 clause carries no 2026-10-12 mark, the
marks "A-8/B3" and "RR-5" standing only in its quote, review fold: RR1-m2;
the M4 text's `Slice(T)` conditioned on a `Freeze` `T`, amended 2026-10-28,
review fold: RR2-m3, where rev 3 read "a `Slice`, a `String` or an aggregate
holding one"; B.3.4's paragraph names neither type, so the finding's B.3.4
cite is folded here, in the §1.6 sentence that names `Slice`).

<!-- google-doc-style-ignore -->

```markdown
through a shared path to an open place a `ref` payload is `StrictRefFromShared`
unless marked `unsafe` and a value payload that borrows needs a
`Core.SharedImmutable` type, and under every such sub-loan the alternative
cannot change while it lives (realigned <date>, SAFE-2: W-347; this read
"through a shared path as shared sub-loans whose alternative cannot change
while they live")
```

```markdown
M8 value bindings, stated (D-SAFE-17): a value binding of a copy-represented
type reads the object and holds no loan — mutation of the source afterwards is
accepted; a value binding of any other type binds a borrowed object under a
frozen loan for its NLL lifetime, under which every write to the object's
storage is rejected in Strict (`StrictSharedBorrowInvalidated` if
invalidating, `StrictBorrowedObjectMutated` otherwise), on an open place formed
only for a `Core.SharedImmutable` type and `StrictBorrowFromShared` otherwise,
and unchecked code's writes are erroneous and Debug-reported — and from a
materialized temporary it owns the storage and holds no loan (realigned
<date>, SAFE-2: W-348; the superseded text read, in full: "M8 value bindings,
stated (D-SAFE-17, A-8/B3): a value binding of a `Plain` type copies eagerly
and holds no loan — mutation of the source afterwards is accepted; a value
binding of a non-`Plain` type is a shared loan for its NLL lifetime, under
which an invalidating operation on the bound object is
`StrictSharedBorrowInvalidated` and a `Plain`-field write through another alias
is erroneous, Debug-reported — and from a materialized temporary it owns the
storage and holds no loan (RR-5).").
```

<!-- google-doc-style-resume -->

### §B.3.6 fork/safe/plan.md §4.1 (:1900-1938), the checklist rows

(Amended 2026-10-28, document-review fold: R1-m1. The block below is commit
2's text. Since e1574b003 its D-SAFE-8 row gives `UsePick` as
`StrictSharedBorrowInvalidated` at `let ref z`, as section 8.7 records.)

Replace the row whose first cell is "D-SAFE-8 mixed-kind result (A-5)" with the
first block's two rows; replace the row whose first cell is "M8 value binding,
`Plain`" with the second block's first row and the row "M8 value binding,
non-`Plain`" with its second; insert the third block's two rows after that
second row; and replace the row whose first cell is "M5 payload refs" with the
fourth block's row. The first cells are the page checklist's (A.2.17, A.3.13)
word for word (amended 2026-10-28, review fold: B-m4; rev 1 kept the
"non-`Plain`" and "M5 payload refs" rows and worded two first cells
differently from the page). The EX-M-4d row names `Peek4` (amended
2026-10-28, review fold: RR1-B1) and `Peek8` with its `Set` (amended
2026-10-28, review fold: RR2-B1).

<!-- google-doc-style-ignore -->

```markdown
| D-SAFE-8 mixed-kind result, a `ref` binding on closed places (realigned <date>, SAFE-2: W-347) | EX-TM-8 `Pick`/`UsePick` | NEW-SYNTAX (`bound`); `UsePick` is `StrictExclusiveBorrowConflict` | p005434:772-779 | 1, 4 |
| D-SAFE-8 a `ref` through a shared pointer (added <date>, SAFE-2: W-347) | EX-TM-9 `F`, `F2`, `F3` | ACCEPTS-UNCHECKED for `F` (nightly 2026.10.12 exit 0, prints 3); NEW-SYNTAX for `F2`, `F3` | p005434:152-162 | 1, 4 |
```

```markdown
| M8 value binding, copy representation (realigned <date>, SAFE-2: W-348) | EX-M-4a | ACCEPTS (today and in Strict; `b` is 1) | nightly 2026.10.12 exit 0; `i32`'s value representation is a copy (type_completion.cpp:724-736 at 0421bf3b4) | — |
| M8 value binding, borrowed object (realigned <date>, SAFE-2: W-348) | EX-M-4b | ACCEPTS-UNCHECKED (fork prelude) | values.md:456-468; buf.carbon:58-60; a class's pointer representation (type_completion.cpp:771-781) | 4 |
```

```markdown
| M8 `Plain` write to a borrowed object (added <date>, SAFE-2: W-348) | EX-M-4c | ACCEPTS-UNCHECKED (nightly 2026.10.12 exit 0, prints 1); Strict `StrictBorrowedObjectMutated` | p005434:663; type_completion.cpp:580-582 and :597-609 at 0421bf3b4 | 4 |
| M8 borrowed object through a shared pointer, `Core.SharedImmutable` (added <date>, SAFE-2: W-348) | EX-M-4d `Peek`, `BufSize`, `Peek2`, `Peek4`, `Peek8` | ACCEPTS-UNCHECKED (`Peek`, `Peek2` and `Peek4`: nightly 2026.10.12 exit 0, print 1, 6 and 6; `BufSize` and `Peek8`: fork prelude); Strict `StrictBorrowFromShared` for `Peek`, accepted for `BufSize`, `StrictSharedImmutableWrite` at the writes of `Peek2` and `Peek4`, `StrictInvalidatingThroughShared` at `Peek8`'s `Set`, which takes `ref self` | p005434:663; `Core.SharedImmutable` (W-144); M3; buf.carbon:48-53 | 4 with W-144 |
```

```markdown
| M5 payload bindings (realigned <date>, SAFE-2: W-347) | EX-M-5 | NEW-SYNTAX (payload `match` on `Core.Optional`: optional.carbon:64-68 says `Optional` "is not a choice" and the `match` form "applies once an approved `Optional` design makes it one", so the `case .Some(...)` pattern does not parse against the fork prelude; payload bindings exist today only for user `choice` types, handle_binding_pattern.cpp:518-528; the 2026-10-12 cell, with its marks RR-4, read "`case .Some(ref s)` does not parse" and "`ref` payload bindings") | optional.carbon:30-46, :64-68 | 4 plus the choice-based `Optional` redesign the prelude comment names |
```

<!-- google-doc-style-resume -->

### §B.3.7 fork/safe/plan.md §4.3 (:1959-1967), a sentence appended to adversary 1

Append after "must each be found explicitly disclosed.":

<!-- google-doc-style-ignore -->

```markdown
Since SAFE-2 (<date>) the first five are realigned to the accepted text and the
zero-fill promotion is closed as upstream's rule (fork/safe/safe2-plan.md); a
review checks instead that each realigned passage quotes its superseded text
and that no page states a narrowing, a withdrawal or a promotion as current.
```

<!-- google-doc-style-resume -->

### §B.3.8 fork/safe/plan.md, a section after the landed notes

Append at the end of the file, after the "## Landed notes (SAFE-1)" section.
`<verdict 1>` and `<verdict 2>` are the two document reviews' verdicts and
counts, `<fixes>` the fold commits' hashes, filled in by the records commit of
section 3 step 4 (commit 2 writes the paragraph with "pending" in their
place), and so is `<sha2>`, commit 2's own hash (amended 2026-10-28,
document-review fold: R2-m1). The paragraph's last sentence reads as amended
2026-10-28, document-review fold: R2-m3, the notes on PR 67 being the PR 67
note commit's, not yet on PR 67's head. The sentence after the fold record's,
on the focused re-review's round 1 and cbdc0552e, is the one the records
commit b30c77990 added to the file, in the file's words (amended 2026-10-29,
re-review round 2: RR2-m2; section 8.7 amends this block in place, and
b30c77990 had left it without the sentence).

<!-- google-doc-style-ignore -->

```markdown
## Realigned notes (SAFE-2)

SAFE-2 realigned the six departures RG-1 classified as drifts (W-347 to W-351
and W-353; fork/register/rg1-plan.md on claude/carbon-fork-0-1-rg1) on this
branch in commits <sha1> (the pages) and <sha2> (these records), under
fork/safe/safe2-plan.md. W-347: every `ref` binding is `nocapture` and
`noalias`, a checked reborrow on a closed place and an `unsafe` formation on an
open one (`StrictRefFromShared`). W-348: a value binding binds a borrowed object
exactly when its type's value representation is not a copy, under a frozen loan
Strict enforces (`StrictBorrowedObjectMutated`, `StrictBorrowFromShared`, the
opt-in `Core.SharedImmutable`, whose shared-path writes M3 rejects with
`StrictSharedImmutableWrite`). W-349: each `bound` argument is immutable for
the duration of the result, a pointer argument's pointee written by no path
but the result. W-350: arithmetic.md's three rows are read through the build
modes, the performance-build row standing for the unsupported benchmarking
build. W-351: that benchmarking build is kept as the strategy promises, `unsafe
fn GetUnchecked` being the supported opt-out. W-353 is closed, its
classification corrected: p000257:356-358, accepted text RG-1's H1.13 row had
not quoted, zeroes every type's storage as hardening initialization, so I5's
rule is upstream's and only its disclosure changed. The examples whose outcomes
changed are safe2-plan.md's section 4.
The two document reviews returned <verdict 1> and <verdict 2>, folded by
<fixes>; the fold record is safe2-plan.md's section 8.7. The
focused re-review's round 1 found four page defects in that fold, folded by
cbdc0552e (the pages; amended 2026-10-29, re-review round 2: safe2-plan.md
section 8.14). The six items are PR
67's; their notes there are to read "REALIGNED" or "CLOSED" with this branch's
dry head once SAFE-2's PR 67 note commit lands (safe2-plan.md section 3 step
6; amended 2026-10-28, document-review fold: R2-m3, where this read "their
notes there read"), and they are discharged by this branch's land-sequence
records commit when it lands.
```

<!-- google-doc-style-resume -->

### §B.4 fork/inventory/work-items.json (PR 53's ledger), four notes

Append each text to the item's `notes` string, after a space; the file must
still parse (`python3 -I -c 'import json;
json.load(open("fork/inventory/work-items.json"))'`). The W-146 and W-148
notes quote and supersede the lines of those items that state the narrowed
rules, which section 0.5 lists; the items' titles and evidence are left as
written, the notes saying how to read them (amended 2026-10-28, review fold:
B-M6; also A-B-1, A-B-2, A-M-1, A-m-2 for the rules the notes name; the W-148
note's M3 clause, per-byte Debug count and pointee loan amended 2026-10-28,
review fold: RR1-B1, RR1-m1; the W-144 note's trusted-body rule and `Set`'s
receiver amended 2026-10-28, review fold: RR2-B1, and the W-148 note's Debug
test over every store, review fold: RR2-m1, where rev 3 read "reporting a
`Plain` assignment through `T*`, to a field or to a whole object, that writes
a counted byte, or an `addr self` call on an object with a counted byte"; the
W-144 note's last sentence, on `IndirectIndexWith.Ref`'s `bound self` and the
counterexample, added 2026-10-28, review fold: RR3-M1).

<!-- google-doc-style-ignore -->

```text
W-144: SAFE-2 (<date>, <sha1>; fork/safe/safe2-plan.md D-SAFE2-5): the audit also adds `unsafe impl ... as Core.SharedImmutable {}` for `Core.String` and, under `forall [T: Core.Freeze]`, for `Core.Slice(T)`, `Core.Buf(T)` and `Core.Optional(T)`, and for `Core.Box(T)` when this item adds `Box`, each checked against the facet's obligation (every field private, no `addr` method writing `self`, no function writing the type's storage through a shared path or returning a non-`const` pointer or `ref` into it, no stored self-pointer), and `Core.SharedImmutable` joins the library surface. Every prelude body is also checked against M3's write rule as a trusted body keeps it: it writes an object whose type holds a `Core.SharedImmutable` sub-object only through an exclusive path, an owner, a `ref` or an `exclusive T*`, or through a pointer into storage owned by an object it holds exclusively, every other path to that storage the type hands out being `bound` to that object; so `Core.Buf(T).Set` changes from `fn Set(self, i: i64, value: T)` to `fn Set(ref self, i: i64, value: T)` for every `T` (buf.carbon:48-53 at 2407efa74; the cost: a `Set` under a live view of the block, through a shared pointer or on a `Buf` bound by value is rejected, EX-TM-3's call moving before its view and slices.md's amendment saying so), and a prelude function found writing such storage through a shared path, an element of a block it owns included, is fixed the same way, never answered by withdrawing an opt-in that its own type's obligation still keeps. The audit also covers every prelude function that hands out a path into such storage: `IndirectIndexWith.Ref`, which PR 65 adds as `fn Ref(self, subscript: SubscriptType) -> ref ElementType;` (index.carbon:16 at fee0ef31c) with by-value impls on `Slice` and `Buf` (slice.carbon:76, buf.carbon:74), takes `bound self` at the interface, as `IndexWith.At` does (an impl may not add `bound` beyond its interface, temporal T5(e); upstream's `Deref.Op` has the same shape, p005434:952-960), and in both impls, so that `let s: str = b[0];` keeps the loan on `b` that `Set`'s `ref self` conflicts with; with an unbound `Ref`, `var b: Core.Buf(str) = Core.Buf(str).Make(1, "ab"); let s: str = b[0]; b.Set(0, "longer"); return s.Size();` binds `s` on an element reached through a free result, the `Set` is accepted and 6 is returned (fork/safe/safe2-plan.md section 0.8; DR-1 carries it on PR 65).
W-146: SAFE-2 (<date>, <sha1>; D-SAFE2-11 to D-SAFE2-13): stage 2 also spells the unsupported benchmarking build, the Release build without the bounds check, the division guard, the overflow wrap and the zero-fill (kept as safety README.md's build modes promise it, W-351); the zero-fill is p000257:356-358's hardening initialization, with a type's customization once upstream names its interface (W-353 closed, its classification corrected). Superseded by this note: the title's "`--build-mode=debug|release`" names the supported modes only, and the benchmarking build is a third, unsupported configuration (W-351); the evidence's "the dated blockquote at docs/design/README.md:2147 promoting zero-fill to the Release baseline" reads as the blockquote SAFE-2 replaced with a note that the zeroing is p000257's (W-353), and "the dated blockquote withdrawing the performance-build row, D-SAFE-15" as the blockquote SAFE-2 rewrote to keep the row for the benchmarking build (W-350); the notes' "D-SAFE-14 (fail-stop everywhere, no build flag disables the checks — the benchmarking disable of safety README.md:260-262 withdrawn, A-13(c); break condition: a measured corpus where the checks exceed the strategy's budget — then a per-site `unsafe fn` accessor, never a flag)" reads "fail-stop in every supported build mode, the benchmarking build kept" (W-351), and the fork-benchmark break conditions "a real-world benchmark where the loss of `nsw` exceeds 0.5 percent — an owner call" (D-SAFE-15) and "more than 0.5 percent from zero-fill alone — then scoped to escaped-unformed objects" (D-SAFE-13 I5) are replaced by upstream's, as the realigned decisions state them (W-350, W-353).
W-148: SAFE-2 (<date>, <sha1>; D-SAFE2-3 to D-SAFE2-9): the checker also implements the frozen loan kind and the closed and open place rule; M3's exclusive access for every assignment whose type holds a `Core.SharedImmutable` sub-object (the type itself or an array, tuple, struct, class or adapter that holds it); `StrictRefFromShared`, `StrictBorrowFromShared`, `StrictBorrowedObjectMutated` and `StrictSharedImmutableWrite`, each with the Permissive twin `PermissiveAliasedExclusive`; M8's loans keyed on the value representation rather than `Core.Plain`, the Debug shadow count counting live frozen loans for each byte of a borrowed object's storage and reporting every store, of any type and by any path (`T*`, a `ref`, the owner, a global by name, an `addr self` body), that writes a counted byte (`MutationDuringValueBinding`, "carbon: mutation of a borrowed object; terminating"), a Strict body's store among them only when a Permissive caller made it aliasing; T5(a)'s frozen kind and T5(d)'s immutability of each `bound` argument, a `bound` pointer argument's pointee held by the result under a frozen loan, an exclusive one for an `exclusive T*`, the result's own access at T5(a)'s kind; T8's `noalias` with `captures(none)` or `captures(ret: address, provenance)` only where established against every writer (intra-function on the body's own places, on `ref` and `exclusive T*` parameters' places under the whole-package condition, never on an open place). Superseded by this note: the evidence's "proposals/p005434 (`bound`, `ref`, `val`; :83 and :831-832 narrowed by D-SAFE-8 and D-SAFE-11(d))" reads ":83 and :831-832 kept by D-SAFE-8 and D-SAFE-11(d) as realigned" (W-347, W-349); its row names "'M8 value binding, non-`Plain`' EX-M-4b", "'M5 payload refs' EX-M-5" and "'D-SAFE-8 mixed-kind result' `Pick`/`UsePick`" read as fork/safe/plan.md §4.1's renamed rows "M8 value binding, borrowed object", "M5 payload bindings" and "D-SAFE-8 mixed-kind result, a `ref` binding on closed places"; and the notes' "D-SAFE-17 (value bindings; break condition: a corpus where the Debug shadow count's cost is measurable — then opt-in)" reads as the realigned D-SAFE-17, whose break condition is upstream's relaxation of p005434:663, or a prelude function shown writing storage that holds a `Core.SharedImmutable` sub-object through a shared path, answered by fixing that function (W-348).
W-150: SAFE-2 (<date>, <sha1>; D-SAFE2-10): the generator maps a by-value parameter of a borrowed type to `&T` when `T: Core.Freeze`, else `&SharedView<T>`; `At`'s by-value receiver becomes `&'a Self` under `Freeze`, its element result staying `&'a SharedView<i32>`.
```

<!-- google-doc-style-resume -->

### §B.5 The W-353 alternative texts (used only if section 0.3's break condition fires)

If a reviewer shows that README.md:2130-2132, or an accepted proposal later
than p000257, supersedes p000257:356-358's zeroing for all types, W-353 is
realigned as its brief states and these texts replace A.4.2's first block,
A.8.1, B.1.4's first block and C.2's W-353 note; every other block stands.

<!-- google-doc-style-ignore -->

```markdown
In every safety mode, the Release build's `make_uninitialized` gives an
unformed object the hardening initialization its type defines (the design
overview's "Types may define additional initialization for the hardened build
mode", docs/design/README.md:2147-2149, the fork's Release build being that
mode under D-RG-20), and gives an object whose type defines none only what the
memory-safety model needs: storage that holds a pointer, at any depth, is
zeroed, so no read of unformed storage forms a pointer the program did not
store, and the rest is made determinate, so a read yields an arbitrary fixed
value, erroneous and defined, never undefined behavior (p005914:87-88).
(Realigned <date>, SAFE-2: W-353; the superseded 2026-10-12 text is quoted as
in A.4.2.)
```

```markdown
> **Fork note (<date>, SAFE-2: W-353, replacing the fork amendment of
> 2026-10-12, F-013 D-SAFE-13 I5).** The fork's Release build is the hardened
> build of this paragraph (fork decision D-RG-20): a type's additional
> initialization runs there, and
> a type that defines none has its pointer-holding storage zeroed and the rest
> made determinate. See [Initialization safety](safety/initialization_safety.md),
> rule I5. (The superseded 2026-10-12 amendment read: "The fork promotes this
> zeroing to the Release baseline for every type; there is no separate
> hardened mode.")
```

```markdown
which gives a type's own hardening initialization in the build D-RG-20 reads as
the hardened one and, for a type that defines none, zeroes pointer-holding
storage and makes the rest determinate (p005914:87-88) (realigned <date>,
SAFE-2: W-353; the superseded parenthesis is quoted as in B.1.4);
```

```text
W-353: REALIGNED <date> by SAFE-2 on PR 53 at <head> (fork/safe/safe2-plan.md Appendix B.5): I5's Release initialization is type-defined, with pointer-holding storage zeroed and the rest made determinate for a type that defines none; discharged when PR 53 lands.
```

<!-- google-doc-style-resume -->

## Appendix C. PR texts and PR 67's notes

### §C.1 PR 53's description, a paragraph appended

The orchestrator appends this paragraph to PR 53's description at section 3's
step 8, with `<sha1>`, `<sha2>`, the dry head `<head>` and the realignment's
`<rdate>` filled in, from the file that step names (amended 2026-10-28,
document-review fold: R2-m4, where the paragraph's date was the stamp's
`<date>`):

<!-- google-doc-style-ignore -->

```markdown
**SAFE-2 (<rdate>): the six departures realigned (R32 (e)).** Commits <sha1>
(the pages) and <sha2> (the records), reviewed by two document reviews and
re-reviewed until dry at <head>, realign SAFE-1's departures from accepted
text under the owner's no-direction-drift directive: every `ref` binding is
`nocapture` and `noalias` as p005434:83 states (W-347); Strict prevents
mutation of borrowed objects as p005434:663 states, keyed on the value
representation, with the opt-in `Core.SharedImmutable` for shared paths, whose
shared-path writes M3 rejects (W-348); each `bound` argument is immutable for
the duration of the result as p005434:831-832 states, a pointer argument's
pointee included (W-349); arithmetic.md's performance-build row and the
strategy's unsupported benchmarking build are kept, read through the build
modes (W-350, W-351); and W-353 is closed, its classification corrected, the
zeroing of every type's storage being p000257:356-358's hardening
initialization, accepted text RG-1's H1.13 row had not quoted. The
plan is fork/safe/safe2-plan.md; the examples whose outcomes changed are its
section 4. Still documentation and records only: no toolchain, prelude,
golden or program change, the two SKIP stubs unchanged.
```

<!-- google-doc-style-resume -->

### §C.2 PR 67's records (section 3 step 6)

The PR 67 note commit, in a detached worktree of PR 67's head, makes the five
edits below, every `<date>` its own UTC date, every `<rdate>` commit 1's
(amended 2026-10-28, document-review fold: R2-m4), and every note citing PR 53's
dry head `<head>` (amended 2026-10-28, review fold: B-M1, B-M2, B-m2, A-M-2,
A-m-3; rev 1 cited `<sha1>`, wrote W-353 "CLOSED by its break condition" at
:355-358, added a check H1.7b with no register row, left H1.13 at DRIFT, and
added no quote row). Its message is "RG-1 records: SAFE-2's realignment of W-347
to W-351 noted, W-353 closed and H1.13 re-classified ALIGNED, H1.7 widened to
Core.SharedImmutable, eleven quote rows added (PR 53 at <head>)".

(i) fork/inventory/work-items.json: append each text of the first block to its
item's `notes`, after a space.

(ii) fork/register/rg1-checks.tsv: replace the row whose id is `H1.7` with the
second block's row, the regex widened by `SharedImmutable` (measured at
0421bf3b4: the widened check counts 1, as before, and `check_greps.sh` prints
"checked 89 silence checks, 0 failed"; `git grep -c -F SharedImmutable` over
docs/design, proposals, core and toolchain prints nothing).

(iii) fork/register/rg1-quotes.tsv: append the third block's eleven rows
(measured at 0421bf3b4: `check_quotes.sh` over the 284 rows prints "checked 284
quotes, 0 failed").

(iv) fork/register/rg1-plan.md: in section 2.H1's row H1.7, replace "`Atomic`,
`Thread`" in the Entry cell with "`Atomic`, `Thread`, and `SharedImmutable`
(added <date>, SAFE-2: W-348, PR 53's fork/safe/safe2-plan.md D-SAFE2-5)" and
`\|Thread)\b'` in the Upstream cell's check with
`\|Thread\|SharedImmutable)\b'`; in row H1.13, append the fourth block to the
Upstream cell, replace the Verdict cell's leading "**DRIFT**" with the fifth
block, replace the Break condition cell with the ninth block, and append
"; closed <rdate> by SAFE-2, its classification corrected; W-355" to the Item
cell (the break condition and W-355 amended 2026-10-28, review fold: RR1-m3:
an ALIGNED entry carries the re-open condition the seventh block states, and
D-RG-17 attaches W-355 to every ALIGNED entry outside VA-2's block, which
W-355's 131-entry note counts); insert the sixth block as a paragraph after
the H1 table and before "The block's re-basing clause"; append the seventh
block to D-RG-20's
paragraph after "and W-350's target becomes the release build's row."; and
append the eighth block to the Status paragraph after "section 4.2's quote
table holds 273 lines." and to section 4.2's paragraph after "and
fork/register/check_greps.sh are the checkers below."

(v) fork/decision-log.md, RG-1's entry: append the eighth block to the
paragraph that begins "_The count._", after "so the register stays a work
queue.".

`<TAB>` in the second and third blocks is one tab character. The ninth block
follows the eighth.

<!-- google-doc-style-ignore -->

```text
W-347: REALIGNED <rdate> by SAFE-2 on PR 53 at <head> (fork/safe/safe2-plan.md D-SAFE2-6): every `ref` binding is `nocapture` and `noalias`, a checked reborrow on a closed place and an `unsafe` formation on an open one, T8 emitting the attributes only where established against every writer; discharged by PR 53's land-sequence records commit.
W-348: REALIGNED <rdate> by SAFE-2 on PR 53 at <head> (D-SAFE2-3 to D-SAFE2-5, D-SAFE2-7): Strict prevents mutation of borrowed objects, keyed on the value representation, with the opt-in `Core.SharedImmutable` on shared paths, whose shared-path writes M3 rejects; discharged by PR 53's land-sequence records commit.
W-349: REALIGNED <rdate> by SAFE-2 on PR 53 at <head> (D-SAFE2-9): each `bound` argument is immutable for the duration of the result, a pointer argument's pointee written by no path but the result; discharged by PR 53's land-sequence records commit.
W-350: REALIGNED <rdate> by SAFE-2 on PR 53 at <head> (D-SAFE2-11): arithmetic.md's three rows are read through the build modes under D-RG-20, the performance-build row standing for the unsupported benchmarking build; discharged by PR 53's land-sequence records commit.
W-351: REALIGNED <rdate> by SAFE-2 on PR 53 at <head> (D-SAFE2-13): the unsupported benchmarking build is kept as safety README.md:260-262 promises, `unsafe fn GetUnchecked` the supported opt-out; discharged by PR 53's land-sequence records commit.
W-353: CLOSED <rdate>, its classification corrected (SAFE-2 on PR 53 at <head>; fork/safe/safe2-plan.md section 0.3): the zeroing of every type's storage is upstream's, p000257:356-358, "The entire storage, including any padding bytes, for all types will be at least be zeroed as part of hardening initialization", accepted text at the cut that I5 already cited when this item was filed (PR 53's initialization_safety.md:223-226 at 2407efa74, as p000257:355-358) and that H1.13's quote set left out; nothing upstream changed, H1.13 is re-classified ALIGNED, I5's text gained the customization of p000257:358-360 and lost its "departure", and rg1-quotes.tsv now quotes p000257:356, :357 and :359 for the weekly check. Discharged by PR 53's land-sequence records commit.
W-355: SAFE-2 (<date>; PR 53 at <head>): the counts this item's evidence gives become 131 NONE and ALIGNED entries (H1.13 re-classified ALIGNED), fork/register/rg1-quotes.tsv's 284 quoted lines (eleven added: p000257:356, :357, :359 and eight lines of upstream's toolchain/check/type_completion.cpp that PR 53's value-representation rule rests on) and fork/register/rg1-checks.tsv's 89 silence checks, H1.7 widened to `Core.SharedImmutable`.
```

```text
H1.7<TAB>G<TAB>-E<TAB>Core\.(Plain|Guarded|Box|Send|Sync|Freeze|Relocatable|Lifetime|DynCast|Move|Utf8|Atomic|Thread|SharedImmutable)\b<TAB>docs/design proposals core<TAB>1
```

```text
proposals/p000257-initialization-of-memory-and-variables.md<TAB>356<TAB>similar hardening initialization. The entire storage, including any padding
proposals/p000257-initialization-of-memory-and-variables.md<TAB>357<TAB>bytes, for all types will be at least be zeroed as part of hardening
proposals/p000257-initialization-of-memory-and-variables.md<TAB>359<TAB>customize the hardening initialization of some parts or members of the object to
toolchain/check/type_completion.cpp<TAB>573<TAB>// The value representation for a struct or tuple with a single element
toolchain/check/type_completion.cpp<TAB>580<TAB>// For a struct or tuple with multiple fields, we use a pointer
toolchain/check/type_completion.cpp<TAB>677<TAB>// For arrays, it's convenient to always use a pointer representation,
toolchain/check/type_completion.cpp<TAB>713<TAB>return {.value_repr = MakeCopyValueRepr(type_id),
toolchain/check/type_completion.cpp<TAB>762<TAB>// The object and value representation of an adapter are the object and value
toolchain/check/type_completion.cpp<TAB>771<TAB>// Otherwise, the value representation for a class is a pointer to the
toolchain/check/type_completion.cpp<TAB>776<TAB>// TODO: Pick a better value representation when possible.
toolchain/check/type_completion.cpp<TAB>806<TAB>// `MaybeUnformed(T)` has the same value representation as `T` if that value
```

```markdown
; p000257:356-360 (added <date>, SAFE-2): "The entire storage, including any padding bytes, for all types will be at least be zeroed as part of hardening initialization. This routine simply allows a user defined type to specifically customize the hardening initialization of some parts or members of the object to values other than zero."
```

```markdown
**ALIGNED** (amended <date>, SAFE-2 on PR 53 at <head>: the classification corrected; p000257:356-358, accepted text at the cut that this row's quotes left out, makes the zeroing of every type's storage language-defined as hardening initialization, and :358-360's customization is README.md:2130's "additional initialization", so the mandate is upstream's and D-RG-20 places it in the release build; the superseded verdict was **DRIFT**, for the reason that follows)
```

```markdown
Amended <date> by SAFE-2 (PR 53 at <head>; fork/safe/safe2-plan.md,
section 0.3): H1.13 is ALIGNED, so this block holds five DRIFTs, H1.8 to
H1.12, and the register 18 DRIFT, 33 ALIGNED and 104 NONE; H1.7 names
`Core.SharedImmutable`, the one library name SAFE-2 adds, and its check covers
it. W-347 to W-351 are realigned on PR 53 and W-353 is closed.
```

```markdown
Since <date> (SAFE-2) H1.13 is ALIGNED; the zeroing stays in the release
build, and this break condition, the hardened mode reconciled into an extension
of Release, would re-open H1.13 as a DRIFT of the zeroing's placement.
```

```markdown
Amended <date> by SAFE-2 (PR 53 at <head>): H1.13 re-classified ALIGNED, so
the verdicts are 18 DRIFT, 33 ALIGNED and 104 NONE, ten of the DRIFTs carried
by items RG-1 filed, W-353 being closed; the quote table holds 284 lines,
eleven added for p000257:356-360 and upstream's
toolchain/check/type_completion.cpp; the 89 silence checks stay 89, H1.7 widened
to `Core.SharedImmutable`.
```

```markdown
upstream supersedes p000257:356-358's zeroing of every type's storage (an accepted proposal later than p000257, or README.md:2130-2132 shown to supersede it), or reconciles its build-mode pages otherwise than D-RG-20 reads them, the hardened mode becoming an extension of Release; either re-opens H1.13 as a DRIFT (amended <date>, SAFE-2 on PR 53 at <head>; the superseded DRIFT condition read "an accepted upstream memory-safety design that makes unformed-state zeroing language-defined for every type, or upstream reconciles its build-mode pages otherwise than D-RG-20 reads them (if the hardened mode becomes an extension of Release, the placement joins W-353)")
```

<!-- google-doc-style-resume -->

### §C.3 PR 67's description, a sentence appended

The orchestrator appends this paragraph to PR 67's description from the file
section 3 step 8 names (amended 2026-10-28, review fold: B-M1, B-M2, B-m1):

<!-- google-doc-style-ignore -->

```markdown
**SAFE-2 (<date>).** PR 53 realigned W-347 to W-351 at <head> and closed W-353
with its classification corrected: p000257:356-358, accepted text H1.13's
quotes left out, zeroes every type's storage, so H1.13 is ALIGNED and the
register counts 18 DRIFT, 33 ALIGNED and 104 NONE. The commit <c2-sha> notes
the six items and W-355, widens check H1.7 to `Core.SharedImmutable` (89
checks), adds eleven quote rows (284 quotes) and dates the counts in the plan
and the log entry. PR 67 still lands first.
```

<!-- google-doc-style-resume -->

## Appendix D. Trunk's fork/ORCHESTRATION.md (section 3 step 8)

Six edits of trunk's fork/ORCHESTRATION.md (1c83422a0 or the records-only commit
after it), the texts below with every placeholder filled, `<rdate>` being commit
1's date where a text says "realigned" or "realignment of" and `<date>` the
stamp's (amended 2026-10-28, document-review fold: R2-m4); `<tip>` is the
upstream tip the implementer's section 8 item 5 read (amended 2026-10-28, review
fold: B-M3; rev 1 gave only the safe row and a paragraph that named neither the
remaining waits, the held count nor a Next line, and gave no header, no item 6
text, no PR 67 row and no land-time discharge; the fourth block's DR-1 action
amended 2026-10-28, review fold: RR3-M1):

1.  The header: insert the first block as the new first entry, "Last updated:"
    moving to it, so that the current first entry, which begins "Last updated:
    2026-10-28 (OV-4,", begins "2026-10-28 (OV-4," as the earlier entries do.
2.  The branch row whose first cell is `claude/carbon-fork-0-1-safe` (its
    second begins "HELD OPEN as PR #53"): replace it with the second block.
3.  The branch row whose first cell is `claude/carbon-fork-0-1-rg1`: replace
    "at 56e2e5bbd (2026-10-28; twelve commits:" with "at <c2-sha> (2026-10-28;
    thirteen commits, the thirteenth SAFE-2's note commit <c2-sha> of <date>:"
    and "273 quotes and 89 silence checks passing at e6fddcf97;" with the third
    block.
4.  A dated paragraph: insert the fourth block after the paragraph that begins
    "2026-10-28 (13:28 UTC): OV-4 is IMPLEMENTED", in the form that paragraph
    and the RG-1 one (04:47 UTC) use.
5.  Next actions item 6: replace "W-353 (SAFE-1: a plan amendment of
    fork/safe/plan.md, a re-derivation commit on PR 53's branch, two document
    reviews and a fixer, before PR 53 lands; the land sequence waits at PR 53
    until then)," with the fifth block.
6.  The land-time discharge, which the fifth block schedules: PR 53's
    land-sequence records commit, made when PR 53 merges after PR 67 (so that
    PR 67's ledger is trunk's), appends the sixth block to the notes of W-347
    to W-351 and W-353, with the landing's date and merge commit filled in.

<!-- google-doc-style-ignore -->

```markdown
Last updated: <date> (SAFE-2, the R32 realignment of SAFE-1's six departures
from accepted text, is made on PR 53 and reviewed until dry at <head>: W-347 to
W-351 realigned, W-353 closed with its classification corrected; the land
sequence no longer waits at PR 53; eighteen PRs are held open, PR 51 to PR 68,
none merged; see the paragraph dated <date> (<time> UTC) below; the earlier
2026-10-28 text follows).
```

```markdown
| `claude/carbon-fork-0-1-safe` | HELD OPEN as PR #53 — SAFE-1 safe-Carbon design (F-013) at <head>, documentation and records only (gap row 89 expected DONE on document review, W-063 discharged, W-144..W-150); merges first in the land sequence after RG-1's PR (fork/register/rg1-plan.md section 5); amended 2026-10-28 by RG-1's records commit cd3c5b2e1 and its review fix 2407efa74 (R32 (e)); realigned <rdate> by SAFE-2 (fork/safe/safe2-plan.md; commits <sha1>, <sha2> and the fold commits <fixes>, re-reviewed until dry at <head>): W-347 to W-351 realigned and W-353 closed with its classification corrected, noted on PR 67's ledger by <c2-sha>, the descriptions of PR 53 and PR 67 refreshed. |
```

```markdown
273 quotes and 89 silence checks passing at e6fddcf97, and 284 quotes and 89 silence checks at <tip> after SAFE-2's note commit <c2-sha> (W-347 to W-351 noted as realigned on PR 53, W-353 closed and H1.13 re-classified ALIGNED: 18 DRIFT, 33 ALIGNED, 104 NONE; H1.7 widened to `Core.SharedImmutable`);
```

```markdown
<date> (<time> UTC): SAFE-2 is DONE AND REVIEWED on PR 53
(claude/carbon-fork-0-1-safe at <head>; commits <sha1> (the pages), <sha2>
(the records) and the fold commits <fixes>), under fork/safe/safe2-plan.md.
Records and design text only, no toolchain, prelude, golden or program change:
SAFE-1's six departures from accepted text, filed by RG-1 as drifts, are
realigned to upstream at <tip>. W-347: every `ref` binding is `nocapture` and
`noalias` (p005434:83). W-348: Strict prevents mutation of borrowed objects
(p005434:663), keyed on the value representation, with the opt-in
`Core.SharedImmutable` for shared paths. W-349: each `bound` argument is
immutable for the result's lifetime (p005434:831-832). W-350 and W-351:
arithmetic.md's performance-build row and safety README.md:260-262's
unsupported benchmarking build are kept, read through the build modes
(D-RG-20). W-353 is closed with its classification corrected
(p000257:356-358), and H1.13 is ALIGNED on PR 67, whose ledger notes the six
at <c2-sha>. Reviews: two document reviews (<verdict 1>, <verdict 2>), the
fixer and a focused re-review until dry. No build, merge or dispatch; Actions
is still disabled. Eighteen PRs are held open (PR 51 to PR 68); none is
merged. Merge order: PR 67 (RG-1), then PR 53, 51, 52, 60, 54, 55, 56, 57, 58,
59, 61, 62, 64, 63, 65, 66, then PR 68 (OV-4) through its land-time commits M,
F-M, L-R and L (fork/overload/ov4-plan.md section 3); the sequence no longer
waits at PR 53, and still waits at PR 60 for SC-1's W-139 and at PR 56 for
OP-1's W-352. Next: SC-1's W-139 on PR 60 and OP-1's W-352 on PR 56; DR-1
notes on PR 65's records, before PR 65 lands, that its `IndirectIndexWith.Ref`
takes `bound self` under W-144, with the counterexample of
fork/safe/safe2-plan.md section 0.8; then EH-C (W-346) after the held PRs
land, then UA-3; the weekly upstream check of 2026-11-02 runs W-355's scripts
over 284 quotes and 89 silence checks.
```

```markdown
W-353 (SAFE-1: realigned <rdate> by SAFE-2 on PR 53 at <head>,
fork/safe/safe2-plan.md, W-353 closed with its classification corrected; the
land sequence no longer waits at PR 53; when PR 53 lands, its land-sequence
records commit appends to W-347 to W-351 and W-353, in the ledger PR 67
brought to trunk, the note "DISCHARGED <landing date> by PR 53's landing at
<merge commit> (SAFE-2's realignment of <rdate>; fork/safe/safe2-plan.md)"),
```

```text
DISCHARGED <landing date> by PR 53's landing at <merge commit> (SAFE-2's realignment of <rdate>; fork/safe/safe2-plan.md).
```

<!-- google-doc-style-resume -->
