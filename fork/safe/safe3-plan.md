<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# SAFE-3 plan: the built-in operator exemption re-derived from the safety argument

**Status:** rev 3 -- NOT signed off pending re-review round 2: RR1-M1.
Rev 3, 2026-10-29, is the fixer's fold of the focused re-review, round 1, of
rev 2 (APPROVE-WITH-AMENDMENTS: one MAJOR, RR1-M1, and three MINORs, RR1-m1 to
RR1-m3; all four accepted, the rev 3 fold record after rev 2's); sign-off needs
a round with no BLOCKER and no MAJOR. Rev 2, 2026-10-29, the fixer's fold of the
two plan reviews (review A: REJECT, one BLOCKER, two MAJORs, six MINORs; review
B: APPROVE-WITH-AMENDMENTS, four MAJORs, six MINORs; all 18 accepted), is
commit 782a5b740; rev 1, the planner's draft of 2026-10-29, is commit f97cdf414.
Workstream SAFE-3 re-derives from the ground up M3(d) and
fork/safe/safe2-plan.md's D-SAFE2-6, the exemption of a built-in operator's
`ref` operand from the `ref` rule of the safe-Carbon design, and completes
SAFE-2's realignment of W-347 to W-351 and W-353 on PR 53's branch, under the
orchestrator's rulings of 2026-10-29 recorded in sections 8.16, 8.19 and 8.20 of
safe2-plan.md. Branch `claude/carbon-fork-0-1-safe` (PR 53, held open, second in
the land sequence after PR 67), pushed head 2407efa74, local head 0f22798fb with
SAFE-2's 27 unpushed commits (plan rev 1 to rev 14, commits 48f2e66a0
and 954f1c542, the four counted fix commits 0f281d8bd, e1574b003, cbdc0552e
and 9d0b072cb and their records commits), mirrored against loss at
`claude/carbon-fork-0-1-safe-wip`, which is not a PR, never a base, and is
deleted when PR 53's head is pushed (at f97cdf414 on 2026-10-29, the plan's
rev 1 commit, by `git ls-remote origin`; amended 2026-10-29, review fold:
A-RA3-m4, B-M4; at 782a5b740, rev 2's commit, when rev 3 was written, a moved
head reported, amended 2026-10-29, review fold: RR1-m2). This plan is a new file
beside fork/safe/safe2-plan.md, which this planner does not edit; its dated
pointer marks come with the fold commit (section 2). Upstream was read at its
tip 9192ee003, fetched 2026-10-29 (section 0.1). Records and design text only:
no toolchain, prelude, golden, program or conformance change, no build of any
kind, the nightly compiling examples and probes only (R30).

**Items:** W-347 to W-351 and W-353 (PR 67's ledger,
fork/inventory/work-items.json on `claude/carbon-fork-0-1-rg1` at 56e2e5bbd),
realigned by SAFE-2's commits 1 and 2 and its four fix commits, whose W-347
clause for the built-in operators SAFE-3 re-derives; residue W-365 (planned by
SAFE-2 for RB-M3 and not yet filed) and the new watch item W-366 (the
toolchain's interim `=`), both filed by SAFE-3's fold commit on PR 53's ledger
(section 0.8); W-144 to W-150, SAFE-1's stage items, of which W-148 and W-149
gain dated notes.

**The rule applied** (R32, R17): the design states upstream's rule, a
classification beyond upstream's text is labelled this design's, and no
dependent line is left stating the narrowed or refuted rule; every rewritten
passage keeps the text it supersedes visible inside a dated amendment
(D-SAFE3-7). The governing obligation is p005434:83, "The address of a `ref`
binding is `nocapture` and `noalias`.", true under the design's own model for
every probe of section 0.3.

## Sections

-   Section 0, audit: section 0.0 the root cause; upstream at the tip; the
    toolchain and the prelude; the probes, 91 re-run, 23 new, rev 2's 11 and
    the re-review's 4 of rev 3, with the IR order of each; PR 67's checks;
    every sentence on the pages and in the records that states the exemption;
    the interlocks; the collisions; the id re-scan; SAFE-2's findings that the
    tree does not yet carry.
-   Section 1, design: the three models weighed, decisions D-SAFE3-1 to
    D-SAFE3-12, and the noalias claim decided probe by probe.
-   Section 2, spec: the conventions and the index of every text change; the
    verbatim texts are Appendix A (pages) and Appendix B (records).
-   Section 3, commits and reviews; section 4, the worked-example matrix;
    section 5, scoreboard; section 6, churn and collisions; section 7, risks
    and rejected alternatives; section 8, verification and the not-run list.
-   The review fold records of rev 2 and rev 3, the hand-off notes, then
    Appendix A (pages), Appendix B (records), Appendix C (the PR texts and
    PR 67's note commit) and Appendix D (trunk's fork/ORCHESTRATION.md).

## §0 Audit

### §0.0 Root cause

SAFE-1's D-SAFE-8 exempted every built-in operator's `ref` operand from the
`ref` rule on the ground that "it lives for the one operation, during which
nothing else is evaluated", and SAFE-2 kept that ground (D-SAFE2-6, M3(d))
while it realigned every other `ref` binding to p005434:83's `nocapture` and
`noalias`. The ground is a claim about the toolchain, and four review rounds
refuted it by nightly probes. RR2-M1 and RR8-M1: "built in" had no definition
that covered the prelude's `CppCompat` integers, and was re-planned as "where
the implementation is written". RR3-M1: the prelude's generic compound
assignments over `U: ImplicitAs(Int(N))` convert a user's `U` inside the thunk
of docs/design/generics/details.md:5769-5779 while `ref self` is bound, so a
user's `Convert` writes the referent through an alias (r3_thunk, a_p06: 101).
RA-M2, RB-M2 and PRR2-M1: the toolchain's interim `=` initializes an aggregate
left operand in place, element by element, so a user's call, `Copy` or
`ImplicitAs` evaluated after the first element runs while the operand is bound
(z1: 42 0 7; z2). PRR3-B1, the BLOCKER: with no code written outside
core/prelude at all, the right operand's own reads of the left operand through
an alias come after the in-place initialization begins, `*q = {.a = p->b, .b =
p->a}` with `p == q` printing 2 2 (v09: load `b`, store `a`, load `a`, store
`b`), so the governing test of SAFE-2's rev 11 to rev 13, "exempt exactly when
no code written outside core/prelude can run while the operand is bound",
exempts programs in which another path observes the bound referent.

Every repair of the exemption by a clause about who wrote the code that runs
left such a program, because the obligation p005434:83 states is not about who
wrote code but about which paths reach the referent while the `ref` lives. The
re-derivation therefore starts from the obligation. It takes the `ref`'s
lifetime from upstream's semantics, where every such operator is a call, "The
statement `x = y;` is rewritten to `x.(AssignWith(U).Op)(y);`"
(docs/design/assignment.md:184), so that the `ref` lives for the call and the
call receives its other operands complete; it classifies an operation by what
can reach the referent during that lifetime, the call's body, its thunk and
the thunk's conversions, and the other operands, which are copies or borrowed
objects under the frozen loan SAFE-2 already gives them (D-SAFE2-3 to
D-SAFE2-5); and it says plainly what today's toolchain does differently. The
interim `=` (toolchain/check/handle_operator.cpp:99-123, "TODO: Switch to using
assignment interface for most assignment") differs from that rewrite, recorded
as watch item W-366 (for the scalars of assignment.md:148-151 a deviation by
upstream's own TODO; for aggregates, whose assignment upstream has not decided,
assignment.md:159-164 and leads issue 686, this design's reading of :184), and
while it stands the Strict checker checks it by what it does: a left operand
whose type is not copy-represented at every depth, which the interim `=`
initializes in place in whole or in part, has its whole right operand evaluated
while it is bound. Under that model the noalias claim is true for every one of
the 129 probes of section 0.3 (section 1.3; rev 2 counted 125, amended
2026-10-29, review fold: RR1-M1). Today's lowering emits no `noalias`
on any Carbon function (no probe's IR carries it), so no program has undefined
behavior today; the model's claim must still be true under the model, and now
is.

Rev 1 keyed the interim rule on the left operand's own value representation,
"a copy-represented left operand is stored once from a complete value", and
review A refuted it (RA3-B1): a one-element tuple or struct is copy-represented
whatever its element (toolchain/check/type_completion.cpp:572-578), yet the
conversion gives each element of a by-copy aggregate an initializing target
inside the destination (toolchain/check/convert.cpp:283-297, :400-405), so a
pointer-represented element is initialized in place there, and
`*q = {.s = {.a = p->s.b, .b = p->s.a}}` through `{.s: {.a: i32, .b: i32}}*`
with `p == q` prints 2 2 (ra01: load `p.s.1`, store `q.s.0`, load `p.s.0`, store
`q.s.1`). The root cause is the same as PRR3-B1's, a property of the type
standing in for what the toolchain does with it: the keying is therefore on what
the interim `=` initializes in place, which D-SAFE2-3's own one-element clause
already states for borrowed objects ("When the copy is a one-element aggregate,
its element's own representation decides", mutation_safety.md:620-622), so a
type is stored once from a complete value only when it is copy-represented at
every depth, itself and, where its representation is a one-element tuple or
struct's, its element in turn (f02: one store of `{ { i32 } }`), and every
other type is under the interim rule (amended 2026-10-29, review fold:
A-RA3-B1; amended 2026-10-29, review fold: RR1-m1, where this read "for a
one-element tuple or struct, its element in turn").

Rev 2 stated the interim rule's second condition over the carriers of the left
operand's place, "uses no carrier of the left operand's place or of a place that
overlaps it", and T3 defines a carrier as "a pointer value, `ref` binding, value
binding or loan-carrying class value that holds the loan"
(temporal_safety.md:508-510), so an owner, a local `var`, a `var` parameter or a
`returned var` (T1, temporal_safety.md:420-421), is none:
`x = {.a = x.b, .b = x.a}` passed all three conditions, the `=` was exempt and
formed no loan of its own, and T4, which the same paragraph said rejects it, had
nothing to check, so PRR3-B1's local shape was accepted while a `var` parameter,
a `returned var` of a class and a class local each print the in-place
order's 2 2, 4 4 and 6 6 (n03; the re-review's RR1-M1). The model was the one
section 1.1 states, nothing but the operand reaching the referent while it is
bound, and the condition named only part of the paths it rules out, T3's word
standing in for every path to the place: the root cause is the same as RA3-B1's,
a narrower term in place of the property. The second condition is therefore
stated over every path the place kinds name, the owner and every carrier, "reads
or uses no part of the left operand's place, or of a place that overlaps it,
through its owner or a carrier of it (T1, T3)", and the gloss of what qualifies
keeps only "the body's closed places that do not overlap the left operand's
place". The re-review also found the keying's recursion stated only through a
one-element tuple or struct, while an adapter of one is converted part by part
into the storage too (toolchain/check/convert.cpp:1467-1518 at 9192ee003; n02's
SemIR initializes `C`'s `Copy` result into `(q as {.c: C}).c` from
`(p as {.c: C}).c`), so "copy-represented at every depth" is now defined by
representation, the type, or an adapter, `const` or `MaybeUnformed` of one
(D-SAFE3-5; RR1-m1). Where this plan says a one-element tuple, struct or
aggregate in the keying, it means a type whose representation is one's, such an
adapter included (added 2026-10-29, review fold: RR1-M1, RR1-m1).

### §0.1 Upstream at the tip

`git -C /home/user/carbon-lang fetch -q upstream trunk` on 2026-10-29 at 08:54
UTC gives upstream/trunk = **9192ee003** (2026-10-28 20:51:45 UTC, "Make
`TokenInfo` use a single 32-bit store for initialization.", upstream PR 8054),
the tip SAFE-2's rev 11 to rev 14 read; nothing newer; the cut c1e83b0b7 is its
ancestor. `git log --oneline c1e83b0b7..9192ee003 -- <file>` for every file
this plan quotes:

| Upstream file | Commits since the cut |
| --- | --- |
| proposals/p005434, p005914, p000257 | none |
| docs/design/README.md, safety/README.md, expressions/arithmetic.md, values.md, assignment.md | none |
| docs/design/pattern_matching.md, proposals/p005545 (added 2026-10-29, review fold: A-RA3-M1) | none |
| docs/design/classes.md | f21c62524 "Interface as base class use case supported" (upstream PR 8002); no line this plan or the pages cite moves |
| docs/design/generics/details.md | db87a84b6 "Improve tests and clarify design for observe equivalence chains" (upstream PR 7987): every line from :4700 on moves up by one, so the cut's :4729 and :5770 are the tip's :4728 and :5769, the text unchanged; this plan cites the tip's numbers, as SAFE-2's rev 11 did (a moved quote, reported) |
| toolchain/check/handle_operator.cpp | 2c9739799 "Render diagnostics through the terminal library" (upstream PR 7683), a diagnostic of another operator; :97-124 are the cut's and the fork's |
| toolchain/check/convert.cpp | 7beb29f8b, 2c9739799, 230227264, 059ee7b9e, 4a8993af2, 947c1eb52; the functions cited move, their bodies as quoted |
| toolchain/check/call.cpp | 0d3b606a5, 3af25cc1b, 7beb29f8b, 2c9739799, bf5d2a2ac, 62f1cc6a3, 230227264 |
| toolchain/check/impl.cpp | ac31fd198, fb7eff130, 2b5f90cd7, 2c9739799, e41862d55, f0bae9637, 24766e213, b1de0e037, 6a0a1f3e8, 62f1cc6a3 |
| toolchain/check/type_completion.cpp | fb7eff130, eb66bebc3, 51e2c76a8, f0bae9637, 24766e213, b1de0e037, 62f1cc6a3 (facet-type code only, as SAFE-2's section 0.1 recorded) |
| toolchain/sem_ir/type_info.cpp | 947c1eb52 "Add a `Core.Array` class type, and make `array` refer to it." (upstream PR 7892); :82-89 equal at the cut, in the fork and at the tip |
| core/prelude int, uint, float, cpp/int, operators/arithmetic, bitwise, as, string | none |
| core/prelude/operators/index.carbon | 6d80ceb58 "Add the `IndirectIndexWith` interface to the prelude" (upstream PR 7974) |

The quotes, at 9192ee003; every one is also a row of section 0.4's 110-row
check, which passes at the tip (29 of them fail at the cut, the moved lines
named above; rev 1's 67 rows, the fixer's 33 and the 10 toolchain lines of
section 0.2 that rev 3 adds, amended 2026-10-29, review fold: A-RA3-M1,
A-RA3-m3, B-m1; amended 2026-10-29, review fold: RR1-m1, where this read
"100-row" and "19 of them"):

-   p005434:83 "The address of a `ref` binding is `nocapture` and
    `noalias`."; :302-316, the operators that take a `ref` operand: "the
    address-of operator `&`", "the first operand of the indexing operator",
    "the member access operator", and "The statement operators now use `ref`
    instead of pointers: the left-hand operand of assignment operators such as
    `=` and `+=`" and "the `++` and `--` operators"; :660-661 "Mutation of
    objects with a non-copy-value representation in an active value binding
    ("borrowed objects") is erroneous behavior."; :834-835 "We will reconsider
    this with the memory safety design." (rev 1 cited :833-834; amended
    2026-10-29, review fold: B-m1); :846-848 "The address of a `ref`
    binding is `noalias` and either `captures(none)` or `captures(ret:
    address, provenance)`"; :850-852 "`noalias` means like C `restrict`; you
    can't observe mutations through aliases; mutation through a restricted
    pointer is not observable through another pointer"; :859-864 "The
    combination of `noalias` and `captures(none)` semantics are the minimum for
    the "move-in-move-out" optimization. But this condition is hard to check,
    so safe code will use a stricter criteria. Unsafe code will be required to
    adhere to just the `noalias` restrictions, but will not be checked (except
    possibly by a sanitizer at runtime). The details here will be tackled as
    part of the memory safety design." (added 2026-10-29, review fold:
    A-RA3-m3); :866-868 "Optimizations will only be performed based on
    information that is enforced or checked by the compiler, so these
    attributes won't be passed to LLVM unless their requirements can be
    established."
-   docs/design/assignment.md:76-77 "the first operand must be modifiable
    because it is passed to a `(ref self: Self)` parameter"; :86-87 "A simple
    assignment statement is intended to exactly mirror the semantics of
    initialization."; :102-106 "when an object is in an unformed state, running
    the assignment function is _optional_, just like running the destructor is.
    If the assignment function is not run, the object will be directly
    initialized from the right-hand side instead. The type is still required to
    implement `AssignWith` for the assignment to be valid."; :148-151 "Integers
    and floating-point types, `bool`, and pointer types support simple
    assignment with `=`. The right-hand operand is implicitly converted to the
    type of the left-hand operand, and the converted value replaces the value of
    that operand."; :159-161 "## Tuples, structs, choice types, and data
    classes" / "_TODO_: Describe the rules for assignment in these cases.";
    :163-164 "See leads issue" / "[#686: Operation order in struct/class
    assignment/initialization]"; :116-120 the unformed `var y: C;` / `y = F();`,
    whose `returned var` "can be `&y`" (:113; added 2026-10-29, review fold:
    A-RA3-M1); :168-170 "Implementations of these interfaces are provided for
    built-in types as necessary to give the semantics described above.";
    :176-177 `interface AssignWith(U: type) {` / `fn Op(ref self, other: U);`;
    :184 "The statement `x = y;` is rewritten to `x.(AssignWith(U).Op)(y);`.";
    :302-316 the default `$=` "defined in terms of `AssignWith` and `OpWith`",
    whose body is `*self = *self $ other;`.
-   docs/design/generics/details.md:5759-5779: "the function in the `impl` is
    used directly when: Each parameter in the `impl` function has the same type
    as the parameter in the `interface`." (:5759-5762); "Otherwise, a synthetic
    function called a _thunk_ is generated:" (:5769); "The body of the thunk
    calls the function in the `impl`" (:5774); "Implicit conversions are
    performed as necessary to initialize the parameters of the function in the
    `impl` from the parameters of the thunk" (:5777-5778). :4728-4736, the
    orphan rule: "Some name from the type structure of an `impl` declaration
    must be an _anchor name_".
-   docs/design/values.md:456-463 "When forming a value expression from a
    reference expression, Carbon acquires the value of the referenced object.
    This allows immediately reading from the object's storage into a machine
    register or a copy if desired, but does not require that. The read of the
    underlying object can also be deferred until the value expression itself is
    used. Once an object is bound to a value expression in this way, any
    mutation to the object or its storage ends the lifetime of the value
    binding, and makes any use of the value expression an error."; :604-607
    "Storage in Carbon is initialized using _initializing expressions_. Their
    evaluation takes a _result location_ as an implicit input, and produces an
    initialized object at that location"; :117-122, :186-192 and :573-595 as
    SAFE-2's section 0.1 quotes them, unchanged.
-   classes.md: no line this plan cites; the pages' cites (:1852-1870,
    :1920-1957, :1941-1944, :1968-1982) do not move (f21c62524 replaces two
    lines at :124-125).
-   docs/design/pattern_matching.md:834-948, "Evaluation order", for
    `var cd: (C, D) = (MakeA(), MakeB());` (:855), the first, third and fourth
    of its six steps: "Call `MakeA`." (:860), "Call `A.(Core.Copy).Op` to copy
    the `C` value into the storage for `cd.0`," (:863) and "Call `MakeB`."
    (:865); "The order of evaluation is
    determined by a depth-first postorder traversal of the this DAG" (:913-914);
    "Note in particular that this means the fields of a struct-type binding are
    not necessarily initialized in declaration order." (:947-948).
    proposals/p005545:118-122: "those rules call for conversions to be
    evaluated depth-first (along with the expressions they convert from and the
    pattern-matches they feed into), and for struct conversions to use the field
    order of the source, not the target." (Added 2026-10-29, review fold:
    A-RA3-M1.)

What upstream's design gives an operator's `ref` operand, read from these: the
operator is a call of an interface method whose `ref self` is that operand
(assignment.md:176-177, :184, and the compound interfaces of :186-295); for the
integers, floating-point types, `bool` and pointers the right operand is
"the converted value" that "replaces the value of that operand" (:148-151); an
assignment "is intended to exactly mirror the semantics of initialization"
(:86-87), and for an unformed object "the object will be directly initialized
from the right-hand side instead" (:104-105), where `y = F();` may initialize
`y` in place (:113, :116-120). For tuples, structs, choice types and data
classes upstream has not stated the rule: :159-164 is a TODO pointing at leads
issue 686, "Operation order in struct/class assignment/initialization", while
upstream's designed initialization, which assignment mirrors, is depth-first
and in place, copying `cd.0`'s value into its storage before `MakeB` runs
(pattern_matching.md:858-867, :913-918; p005545:118-122). So the rewrite of
:184 applied to an aggregate, with the right operand formed complete before the
call, is this design's reading of :184 pending issue 686, not upstream's stated
order, and every "designed" outcome this plan gives for an aggregate is
labelled so (amended 2026-10-29, review fold: A-RA3-M1, where this read "the
right operand is an argument to `other: U`, "the converted value" that
"replaces the value of that operand" (:149-151); an assignment "mirror[s] the
semantics of initialization" (:86-87), and runs in place only for an unformed
object"). Nothing upstream says how a checker establishes the `ref`'s
`noalias`; p005434:859-864 says that "safe code will use a stricter criteria",
:866-868 withholds the attribute until "their requirements can be
established", and :834-835 leaves the rest to "the memory safety design".

### §0.2 The toolchain and the prelude

The toolchain at 9192ee003, cited at the tip's line numbers; the quoted text is
the same at the cut c1e83b0b7 and in the fork at 0f22798fb, where some of it
sits elsewhere: convert.cpp's `InitializeExisting` at :2622 at the tip, :2565 at
the cut and :2720 in the fork, `PerformCopy` at :1867, :1856 and :1992, "When
initializing from a value, perform a copy." at :2162, :2146 and :2282;
call.cpp's thunk inlining at :312, :284 and :359; impl.cpp's `BuildThunk` at
:83, :82 and :82; type_completion.cpp's one-element clause at :572-578,
:577-583 and :578-584; handle_operator.cpp :99-124 and type_info.cpp :82-89 are
the same at all three (amended 2026-10-29, review fold: B-m1, where this read
"equal at the cited lines to the cut and the fork"):

-   toolchain/check/handle_operator.cpp:97-124: `=` is not routed through
    `AssignWith`: ":99 // TODO: Switch to using assignment interface for most
    assignment. Some cases / :100 // may need to be handled directly.", the
    left operand checked for a durable reference and not `const` (:107-118),
    ":119 // TODO: Destroy the old value before reinitializing. This will
    require", and ":121 rhs_id = InitializeExisting(context, node_id, lhs_id,
    rhs_id);", then `SemIR::Assign` (:122-123).
-   toolchain/check/convert.cpp: `InitializeExisting` (:2622-2638) converts the
    right operand into the storage as an `Initializing` target;
    `ConvertAggregateElement` (:361) converts a tuple or struct element into
    its target element, "the destination, `target_block` is a pending block for
    target location calculations that will be spliced as the return slot of the
    initializer if necessary" (:355-358), once per field (:946);
    `PerformCopy` (:1867-1880) forms a `Copy` call "that copies from that value
    to the specified target"; "When initializing from a value, perform a copy."
    (:2162-2165). `GetAggregateElementConversionTargetKind` (:283-297): "If
    we're forming an initializer, then we want an initializer for each
    element.", `InPlaceInitializing` for an in-place aggregate and
    `Initializing` otherwise, each element's target being its own element of
    the destination (`target.storage_id = MakeElementAccessInst<...>(...,
    target_id, ...)`, :400-405), so the elements of a by-copy aggregate are
    initialized into the destination one at a time as well (added 2026-10-29,
    review fold: A-RA3-B1).
-   toolchain/sem_ir/type_info.cpp:82-89: `case ValueRepr::Copy:` returns
    `InitRepr::ByCopy` (":83 // TODO: Use in-place initialization for types
    that have non-trivial destructive move."), and `ValueRepr::Pointer` and
    `ValueRepr::Custom` return `InitRepr::InPlace`: a copy-represented type is
    initialized by copy, every other type in place. With convert.cpp:283-297, a
    copy-represented one-element tuple or struct whose element is not
    copy-represented has that element initialized in place inside the
    destination (ra01, ra04, ra05), so only a type that is copy-represented at
    every depth, itself and, where its representation is a one-element tuple
    or struct's, its element in turn, is stored once from a complete value
    (s01, s13's struct, s16, f02) (amended 2026-10-29, review fold: A-RA3-B1,
    where this read "a copy-represented type is initialized by a copy of a
    complete value, every other type in place"; amended 2026-10-29, review
    fold: RR1-m1, where this read "for a one-element tuple or struct").
-   toolchain/check/type_completion.cpp:762-770, :786-788 and :806-826, a
    representation that wraps another: ":762 // The object and value
    representation of an adapter are the object and value / :763 //
    representation of its adapted type.", ":786 // The object and value
    representation of `const T` are the same as those of / :787 // `T`." and
    ":806 // `MaybeUnformed(T)` has the same value representation as `T` if
    that value / :807 // representation preserves all the bytes of the value,
    including any padding / :808 // bits. Otherwise we need to use a different
    representation."; and toolchain/check/convert.cpp:1467-1518, the adapter
    case of `PerformBuiltinConversion`: ":1467 // If a class adapts a tuple or
    struct, we convert each of its parts when / :1468 // there's no other
    conversion going on (the source and target types are the / :1469 //
    same).", converting the value and the initializing target to the adapted
    type and its parts into the target's parts. So an adapter of a one-element
    tuple or struct whose element is not copy-represented is copy-represented
    and initialized in part in place, as the struct is (n02's SemIR for
    `*q = *p` with `class A { adapt {.c: C}; }`: `C`'s `Copy` called with
    `init %C to` the left operand's `(q as {.c: C}).c` and `self` from
    `(p as {.c: C}).c`), and "copy-represented at every depth" reads the
    representation through an adapter, `const` and `MaybeUnformed` (D-SAFE3-5).
    At the cut these lines are type_completion.cpp:767, :791 and :811 and
    convert.cpp:1461, in the fork at 0f22798fb :768, :792, :812 and :1597,
    type_completion.cpp's text the same and convert.cpp's comment and
    conversion the same, its "in copy of" diagnostic rendered otherwise before
    2c9739799 (added 2026-10-29, review fold: RR1-m1).
-   toolchain/check/type_completion.cpp:564-583: a struct or tuple of one
    element has a copy value representation of a one-element aggregate of its
    element's representation (:572-578, ":576 // TODO: Consider doing the same
    whenever `elementwise_rep` is sufficiently small."), one of more elements a
    pointer (:580-582); classes and arrays are pointers (SAFE-2's section 0.1,
    unchanged).
-   toolchain/check/call.cpp:311-331: "If we're about to form a direct call to a
    thunk, inline it." (:312); toolchain/check/impl.cpp:83 `return
    BuildThunk(...)`.

The prelude's operator impls that take a `ref` operand, `git grep -n 'ref self'`
at the tip over core/prelude: core/prelude/operators/arithmetic.carbon (7, the
interfaces, `fn Op(ref self, other: Other);` at :31 and `fn Op(ref self);` for
`Inc` and `Dec`), bitwise.carbon (5, interfaces), types/int.carbon (12: ten
compound assignments `fn Op(ref self, other: Self) = "int.sadd_assign";` and its
siblings at :331-376, each `impl forall [N: IntLiteral, U: ImplicitAs(Int(N))]
Int(N) as ...AssignWith(U)`, and `Dec` and `Inc` at :384-399 with the bodies
`self -= AsInt(1);` and `self += AsInt(1);`), types/uint.carbon (12, the same
shape, `Inc`'s body `self += AsUInt(1);` at :460), types/float.carbon (4, `fn
Op(ref self, other: Self) = "float.add_assign";` and its siblings at :206-221
for `AddAssignWith(Self)`, no thunk), types/cpp/int.carbon (36, the `CppCompat`
integers' compound assignments over `U: ImplicitAs(CppCompat.Long32)` and their
siblings at :1011-1212, `Inc` at :1183-1187 with `self += (1 as
CppCompat.Long32);`) and destroy.carbon (3, `Destroy`, not an operator of
p005434:302-316). Every compound assignment's impl has `other: Self` where its
interface has `other: Other`, so by details.md:5759-5769 it is called through a
thunk that converts `U` to `Self`; `Float`'s are for `Self` alone and direct.
The fork's prelude equals the tip's in all these files (md5 compared) but for
destroy.carbon (4 lines, the fork's `SubobjectDestroy` and `SelfDestruct`) and
the fork's own types/buf.carbon:59, `Core.Buf(T)`'s `fn Op(ref self) {
HeapFree(self.ptr); }`, a destructor. No prelude impl that takes a `ref` operand
takes a pointer-represented `other`. The nightly's prelude equals the tip's for
these files; the nightly also has 947c1eb52's `Core.Array` (types/array.carbon),
which the fork's cut lacks.

### §0.3 The probes

All 91 probes CONTEXT lists (the 59 of amend3/reprobe and the 32 of amend3/probe
in safe2-rev10/, which hold reviewA's, reviewB's, rev11's, planrr1's, planrr2's
and planrr3's and the round 3 thunk) were copied to
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe3/planner/probe/re/
and re-run by bin/run.sh there (`carbon compile --output-last-input-only`,
`carbon link`, the run, and `--phase=lower --dump-llvm-ir --optimize=none` for
the IR) with the 2026.10.12 nightly: all 91 outputs equal the recorded ones, the
three lowering crashes (b_p6_assign_tuple, q06i_assign_struct_elems and
q04b_literal_generic; rev 1 left the third unnamed, amended 2026-10-29, review
fold: B-m1) differing only in addresses. The 23 new probes are in probe/new/;
probe/INDEX.tsv lists all 114 with the claim tested, the command and the output;
bin/irorder.py prints each function's loads, stores and calls in order with
element pointers named base.field. The fixer re-ran all 114 from copies
(fixer/probe/rerun/, by fixer/bin/rerun.sh): every output equal to the recorded
one, the four aborts being the three crashes and s14b. Review A's seven probes
(ra01 to ra07, in
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe3/reviewA/probe/,
re-run identical in fixer/probe/ra/) and the fixer's four (f01 to f04, in
fixer/probe/new/) make 125; fixer/probe/INDEX.tsv lists the eleven (added
2026-10-29, review fold: A-RA3-B1, A-RA3-m6). The focused re-review's four (n01
to n04, in
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe3/rr1/probe/,
its INDEX.tsv listing them) make 129; the rev 3 fixer re-ran them from copies in
fixer1/probe/rr1/ by fixer1/bin/run.sh, n02 and n03 printing what the re-review
recorded and n01 and n04 the same but for the uninitialized values the nightly's
`poison` store leaves, and dumped n02's SemIR (added 2026-10-29, review fold:
RR1-M1, RR1-m1). The new probes, with the IR order of the function that does the
operation (`p` aliasing `q` where the program passes one place twice):

| probe | shape | IR order | output |
| --- | --- | --- | --- |
| s01 | `*q = *p + 1`, `i32` | load `p`; store `q` | 2 |
| s02 | `*q += *p`; `q->a += p->a` | load `p`, load `q`, store `q`; load `p.0`, load `q.0`, store `q.0` | 6 10 |
| s03 | struct `{.a: i32, .b: i32}`: `*q = {.a = p->b, .b = p->a}`; `*q = *p` | load `p.1`, store `q.0`, load `p.0`, store `q.1`; the same for the copy | 2 2; 3 4 |
| s04 | tuple `*q = (p->1, p->0)` | load `p.1`, store `q.0`, load `p.0`, store `q.1` | 2 2 |
| s05 | array swap; `(*q)[0] = (*p)[1] + 10` | load `p.1`, store `q.0`, load `p.0`, store `q.1`; load `p.1`, store `q.0` | 2 2; 12 |
| s06 | `Core.Optional(i32)`: `*q = *p`; `*q = Some(p->Get() + 1)` | the prelude's `Copy.Op(q, p)` in place; `Get(p)` then `Some(q)` | 4; 5 |
| s07 | class with a user `Copy` building `{.a = self.b, .b = self.a}`, `*q = *p` | `Copy.Op(q, p)`; in it load `self.1`, load `self.0`, store `return.0`, store `return.1` | 2 1 |
| s08 | user `ImplicitAs(C)` building its result from `e.p == q` | `Convert(q, e)`; in it load `p.1`, store `return.0`, load `p.0`, store `return.1` | 2 2 |
| s09 | swap by a `var` copy, on locals and through `p != q` and `p == q` | element-wise copies through the temporary | 3 1; 1 3; 1 2 |
| s10 | the remedy: `let v = {...}; *q = v;` and `var v = {...}; *q = v;` | loads of `p` into the temporary, then copies into `q` | 2 1; 1 2 |
| s11 | the rewrite emulated, `AssignFrom(ref *q, y)` | the argument formed in a temporary before the call | 2 1; 2 1 |
| s12, s12b, s12c | a literal naming fields out of order, `{.b = r->a, .a = r->b}` | runtime values stored by position, constants by name | 1 2; 2 1 4 3; 1 2 1 2 1 2 |
| s13 | one-field class and one-element struct from `p->n + 1` | load `p.0`, store `q.0`; load `p.0`, store `q` | 2; 6 |
| s14, s14b | `str` `*q = *p`; `{.s: str}` from `t->s` | the prelude's `String` `Copy.Op(q, p)`; the nightly crashes in lowering | 2; crash |
| s15 | nested `{.i = {.a = p->i.b, .b = p->i.a}, .n = p->i.a}` | load `p.i.1`, store `q.i.0`, load `p.i.0`, store `q.i.1`, load `p.i.0`, store `q.n` | 2 2 2 |
| s16 | `Core.Optional(i32*)` `*q = *p` | load `p`, the prelude's copy of the value, store `q` | 7 |
| s17 | `var y = {.a = x.b, .b = x.a}` beside `x = {...}` | the new object written only | 2 1; 2 2 |
| s18 | `*q = {.a = 1, .o = Some(42)}` | `Some(q.o)`, store `q.a` | 1 42 |
| s19 | `*q += 1`, `*q *= *p`, `i64 += u32`, `++`, `--`, `CppCompat.Long32` | each right operand loaded or converted by prelude code before the left operand's load | 17 15 3 |
| s20 | the rewrite emulated for a class, `AssignFrom(ref *q, *p)` | `other` is `p` itself; load `other.1`, store `target.0`, load `other.0` | 2 2; 4 3 |
| ra01 | `W = {.s: {.a: i32, .b: i32}}`, copy-represented: `*q = {.s = {.a = p->s.b, .b = p->s.a}}`; on a local `y = {.s = {.a = y.s.b, .b = y.s.a}}` | load `p.s.1`, store `q.s.0`, load `p.s.0`, store `q.s.1`, then `store poison` over `*q`; the local the same | 2 2; 4 4 |
| ra02 | one-element tuple of a pair; one-element struct of an array | the nightly crashes in lowering | crash |
| ra03 | `W` from `{.s = {.a = Id(5), .b = Peek(p)}}`, `Peek` printing `p->s.a` | the calls before the stores, then `store poison` | 1 5 2 |
| ra04 | `((i32, i32),)`: `*q = ((p->0.1, p->0.0),)`; the local the same | load `p.0.1`, store `q.0.0`, load `p.0.0`, store `q.0.1`, `store poison` | 2 2; 4 4 |
| ra05 | `{.c: C}`, `C` a two-field class: `*q = {.c = {.a = p->c.b, .b = p->c.a}}` | load `p.c.1`, store `q.c.0`, load `p.c.0`, store `q.c.1`, `store poison` | 2 2 |
| ra06 | ra01's remedy, `let v: W = {...}; *q = v;` and `var v` | `p` read into the temporary first, then copied into `q`, then `store poison` over `*q` | 2 2; 4 4 (wrong code) |
| ra07 | `let v = x; x = {.a = v.b, .b = v.a}` for `{.a: i32, .b: i32}` | `v` copied at the `let` | 2 1 |
| f01 | the rewrite emulated for `W`, `AssignFrom(ref *q, *p)` and with the right operand formed | the nightly copies `*p` into a temporary before the call | 2 1; 2 1 |
| f02 | copy-represented at every depth: `{.s: {.n: i32}}` from `p->s.n + 1` and from `Bump(p)`; `{.o: Core.Optional(i32*)}` | one `store { { i32 } }` after the load or the call; load, the prelude's copy, one store | 2 13 7 |
| f03 | class `{.data: i32, .next: i32*}`: `c = {.data = 42, .next = &c.data}`; the remedy `e.data = 43; e.next = &e.data;` | the pointer stored, nothing read through it during the `=` | 44 45 |
| f04 | ra01's remedies on the nightly: `let v: W = {...}; y = v;` on a local; each element read into a local `i32` and assigned on its own | the first followed by `store poison` over `y`; the second two loads, then two stores | 2 2; 2 1 |
| n01 (rev 3) | `class A { adapt W; }`: `*q = {.s = {.a = (*p as W).s.b, .b = (*p as W).s.a}} as A` | both loads of `p` into a temporary, the temporary copied into `q`, then `store poison` over `*q` (the `as` forms the value first) | order-only (an undefined value, 3) |
| n02 (rev 3) | `class A { adapt {.c: C}; }`, `C` a two-field class with a user `Copy`: `*q = *p` | the nightly crashes in lowering; the SemIR calls `C`'s `Copy` with `init %C to` `(q as {.c: C}).c` and `self` from `(p as {.c: C}).c` | crash; the SemIR is the evidence |
| n03 (rev 3) | reads through the owner, no carrier: a `var` parameter `x = {.a = x.b, .b = x.a}`, a `returned var` of a class `r = {.a = r.b, .b = r.a}`, a class local `d = {.a = d.b, .b = d.a}` | load `x.1`, store `x.0`, load `x.0`, store `x.1`; the same for `return` and for `d` | 2 2; 4 4; 6 6 |
| n04 (rev 3) | `let v: W = y; y = {.s = {.a = v.s.b, .b = v.s.a}}`; the same with `v` bound from `*p` and the left operand `*q` | `v`'s elements copied into a temporary at the `let`, then the stores, then `store poison` | order-only |

Facts the probes give, each with the probes that show it: the call-based
operators evaluate the left operand's place, then the right operand, then the
operation (a_p07, b_p1 to b_p3, s02, s19); a thunk converts its `U` inside the
call, before it loads `%self` (a_p06, a_p13, q03, x1); the interim `=` stores a
left operand that is copy-represented at every depth once from a complete value
(s01, s13's struct, s16, q06a, q06f, w4, f02); it initializes any other type in
place, a copy-represented one-element aggregate whose element is not
copy-represented included (ra01, ra04, ra05; rev 1 said "a copy-represented
left operand", amended 2026-10-29, review fold: A-RA3-B1) and so is an adapter
of one (n02's SemIR; added 2026-10-29, review fold: RR1-m1), one element at a
time, an element that is a reference expression read at its own position and
a computed one earlier (v09 to v11, v14, v24, s03 to s05, s15), whether the
right operand reaches the left operand through a pointer or through its owner,
a `var` parameter, a `returned var` or a local, with no carrier at all (n03:
2 2, 4 4, 6 6; added 2026-10-29, review fold: RR1-M1), passing the left
operand or an element as the return slot of a call or a `Copy` or `ImplicitAs`
(b_p8, a_p11, q06b, z1, z2, x2, s06, s07, s08, s14), a call initialized in
place receiving its place only once its arguments are evaluated (v04 to v06,
PRR3-m1); upstream's rewrite, emulated by a function with a `ref` parameter,
forms the right operand before the binding (s11: 2 1 where the interim `=`
gives 2 2), and where the right operand is a pointer-represented value of the
referent itself the call's `other` reads the referent (s20: 2 2), the
borrowed-object case; for a one-element aggregate whose element is not
copy-represented the nightly copies the element into a temporary when it forms
`other` (f01: 2 1), a read values.md:456-463 allows to be immediate or deferred,
so the design keeps D-SAFE2-3's one-element clause and treats that element as a
borrowed object. No Carbon function in any probe's IR carries `noalias`.
The nightly's evidence limits: the three lowering crashes, s14b and ra02 are no
evidence; v12 and s12 to s12c are order-only, the nightly storing reordered
struct-literal fields with runtime values by position, not by name (s12c: 1 2
where the names give 2 1, in `=` and in `var` alike, while constants are
placed by name, s12b), a wrong-code defect of the nightly that this plan does
not file (section 8's not-run list); and after the in-place `=` of a
copy-represented one-element aggregate whose element is not copy-represented the
nightly stores `poison` of the whole object over the left operand (ra01, ra03 to
ra06, f04, and the re-review's n01 and n04), a second wrong-code defect, so
those outputs are order-only too, the IR order being the evidence, and ra06's
and f04's 2 2 for the formed-first remedy is the defect's, not the remedy's
(added 2026-10-29, review fold: A-RA3-B1; n01 and n04 added 2026-10-29, review
fold: RR1-m1), and n02's lowering crashes, its SemIR being the evidence; v17,
b_p7 and y1 show no destructor at the `=`.

### §0.4 PR 67's quote and silence checks

From a detached worktree of 56e2e5bbd at /dev/shm/safe3-planner/rg1, removed
after, against /home/user/carbon-lang at 9192ee003:

-   `fork/register/check_quotes.sh /home/user/carbon-lang 9192ee003
    fork/register/rg1-quotes.tsv`: "checked 273 quotes, 0 failed";
    `check_greps.sh` over rg1-checks.tsv: "checked 89 silence checks, 0
    failed".
-   The H1 subsets SAFE-2 recorded (safe2-rev10/amend3/h1-97.tsv, h1-120.tsv,
    h1-checks.tsv): "checked 97 quotes, 0 failed", "checked 120 quotes, 0
    failed", "checked 5 silence checks, 0 failed".
-   With SAFE-2's Appendix C.2 eleven rows appended, the 284 rows Appendix C
    of this plan keeps: "checked 284 quotes, 0 failed"; with H1.7 widened by
    `SharedImmutable`: "checked 89 silence checks, 0 failed".
-   This plan's own 67 upstream lines (logs/safe3-quotes.tsv: assignment.md,
    details.md, values.md, p005434, handle_operator.cpp, type_info.cpp,
    convert.cpp, call.cpp, impl.cpp): "checked 67 quotes, 0 failed"; at the
    cut c1e83b0b7, 12 fail, the lines section 0.1 names as moved.
-   Rev 2's 33 lines (fixer/logs/safe3-rev2-quotes.tsv: assignment.md:86-87,
    :102-105, :119, :148, :159-164, pattern_matching.md:834-948,
    p005545:119-120, p005434:834-835 and :860-861, handle_operator.cpp:100,
    convert.cpp:283-297 and :401, type_completion.cpp:572-580) and the 100 of
    both (fixer/logs/safe3-quotes-all.tsv): "checked 33 quotes, 0 failed" and
    "checked 100 quotes, 0 failed"; at the cut, 7 of the 33 fail, the moved
    convert.cpp and type_completion.cpp lines.
-   Re-run by the fixer on 2026-10-29 from a detached worktree of 56e2e5bbd at
    /dev/shm/safe3-fixer/rg1, removed after, at 9192ee003 (fetched again,
    nothing newer): 273 and 89; the H1 subsets of
    safe2-rev10/amend3/ 97, 120 and 5; 284 (the planner's logs/q284.tsv) and
    89 (logs/c89.tsv); the 67, 33 and 100 above; every one 0 failed (added
    2026-10-29, review fold: A-RA3-M1, A-RA3-m3, B-m1).
-   Re-run by the rev 3 fixer on 2026-10-29 from a detached worktree of
    56e2e5bbd at /dev/shm/safe2-fixer1/rg1, removed after, at 9192ee003
    (fetched again, nothing newer): 273 and 89; the H1 subsets 97, 120 and 5;
    284 and 89; rev 3's 10 toolchain lines of section 0.2
    (fixer1/logs/safe3-rev3-quotes.tsv: type_completion.cpp:762-763, :786-787
    and :806-808, convert.cpp:1467-1469) and the 110 of all three revisions
    (fixer1/logs/safe3-quotes-all3.tsv); every one 0 failed; at the cut
    c1e83b0b7 all 10 of rev 3's fail, the lines moved, and 29 of the 110
    (added 2026-10-29, review fold: RR1-m1).

So no break condition of H1.8 to H1.12 has fired, H1.13's correction stands,
and every Appendix C.2 anchor of PR 67's files is found once at 56e2e5bbd
(measured: the H1.7 Entry and Upstream cells, the H1.13 row, "The block's
re-basing clause", D-RG-20's "and W-350's target becomes the release build's
row.", the Status's "section 4.2's quote table holds 273 lines.", section 4.2's
"and fork/register/check_greps.sh are the checkers below." and the log entry's
"_The count._" paragraph).

### §0.5 The pages: every sentence that states the exemption

`grep -n -i -E 'built in|built-in|interim|nothing else is evaluated|while its
\`ref\`|where it is written|thunk|AssignWith|in place|copy-represented|value
representation'` over docs/design/safety/, values.md and slices.md at
0f22798fb, with fork/safe/plan.md sections 0.3 and 1, the log's F-013 entry,
safe2-plan.md section 1 and the ledger's W-144 to W-150. Every line that states
or restates the exemption, or classifies an operation for it, with its
disposition (the hits on value representations elsewhere, on `in place` as an
English phrase, on Rust thunks and on the `unsafe class` interim state no part
of this rule and are left):

| place (0f22798fb) | text, in short | disposition |
| --- | --- | --- |
| temporal_safety.md:268-350, `ref` bindings, the second paragraph | "Where the operator's implementation is built in, that `ref` lives for the one operation and nothing else is evaluated while it does", the where-written test, "its `ImplicitAs` runs when the caller converts the right operand to `other: Self`, before the call binds `ref self`", `Inc`'s `self += AsInt(1);` attributed to uint.carbon (RR3-m1), the interim `=` as the language's own | replaced by A.1; quoted whole in A.2's blockquote |
| temporal_safety.md:189-192, the kinds paragraph | "A built-in operator's `ref` operand, an assignment's among them, lives for the one operation and is established on any place, M3 deciding what the operation may do" | A.3 |
| temporal_safety.md:1487-1495, the D-SAFE-8 decision | "built in meaning that its implementation is the language's own or an impl of an operator interface written in core/prelude that calls no impl written outside core/prelude while its `ref` operand is bound", "lives for the one operation and is established on any place" | A.0 at this place, and A.4 |
| mutation_safety.md:237-271, M3's first paragraph | "is not a call in (d)'s sense when its implementation is built in", the where-written list, "a user's type that fills their `U` being converted to `Self` before the `ref` is bound", the interim `=` as the language's own | replaced by A.7; quoted whole in A.8's blockquote |
| mutation_safety.md:174-176, M1 | the kinds paragraph's sentence | A.9 |
| mutation_safety.md:1338-1347, the D-SAFE-9 decision | the clause of the temporal D-SAFE-8 decision | A.0 at this place |
| safety/README.md:460-463, the kinds paragraph | the same sentence | A.19 |
| fork/decision-log.md:3131-3190 and fork/safe/plan.md:430-489, D-SAFE-8 | "lives for the one operation, during which nothing else is evaluated", the where-written test, the converted-before claim, the interim `=` as the language's own | B.1, the same text at both places |
| fork/decision-log.md:3269-3278 and fork/safe/plan.md:568-577, D-SAFE-9 | the clause | A.0 at both places |
| fork/safe/plan.md:1613-1616, section 1.5 | the kinds sentence | B.6 |
| fork/safe/plan.md:1643-1650, section 1.6 | the clause | A.0 at this place |
| fork/inventory/work-items.json, W-148's notes (three SAFE-2 notes) | the built-in operator test as each fix commit left it | B.12 appends the superseding note |
| fork/safe/safe2-plan.md, D-SAFE2-6 (:1576-1709) | the decision's text, with SAFE-2's own pointer to section 8.20 and its PRR3-B1 mark | B.16 appends the dated pointer to this plan; the decision's text stays, as safe2-plan.md is SAFE-2's record |
| mutation_safety.md:835-844, the message texts (added 2026-10-29, review fold: A-RA3-M2) | `StrictInvalidatingThroughShared` "assignment to `{0}` of non-`Plain` type `{1}` requires exclusive access" and the `ref self` call form, both false for the new rejections of `Plain` types | A.23 adds a third form |
| fork/safe/plan.md:1697-1699, section 1.6's diagnostics (added 2026-10-29, review fold: A-RA3-M2) | the same message, as an instance for `Buf(i32)` | B.22 |
| fork/safe/plan.md:3045-3048 and fork/decision-log.md:4280-4282 and :4346-4348 (added 2026-10-29, review fold: B-m3) | "SAFE-2's PR 67 note commit", "safe2-plan.md section 3 step 6", the note commit now being this plan's section 3 step 7 | B.23, B.24 and B.25 re-point them |

No other page line states it: values.md's hits are its own value-representation
text and SAFE-2's notes on borrowed objects (unchanged by this rule);
slices.md's one hit (:437) is a C++ thunk; initialization_safety.md,
spatial_safety.md and rust_interop.md hit only `in place` as English, the
`Drop` thunk and C++ thunks; arithmetic.md's are its "Built-in types" section.
W-144, W-145, W-146, W-147 and W-150 do not state it. The dry run of section 8
item 4 checks after the fold that "nothing else is evaluated" and "lives for
the one operation" appear on the pages, in the log and in fork/safe/plan.md
only inside a quoted superseded text, and fails otherwise: each hit must lie
inside a span that follows "where this read", "read:" or "this text read as" up
to its closing quotation mark or blockquote (rev 1's check only printed the
counts; amended 2026-10-29, review fold: B-M2).

### §0.6 The interlocks

| structure | changes under SAFE-3 |
| --- | --- |
| T2 (forming loans), T3, T5, T6, T7, the Store rule | no: a user-written operator's `ref self` is a T2 formation as SAFE-2 has it; the interim rule uses T4 as it stands |
| T4 (conflicts) | no change of text: the interim `=`'s right operand's read or use of the left operand's place through its owner or a carrier of it is a conflict with the operand's checked reborrow, `StrictExclusiveBorrowConflict` for a read through the owner (n03) and `StrictSharedBorrowInvalidated` for a loan the use forms, as T4 already reports them (amended 2026-10-29, review fold: RR1-M1, where this read "the interim `=`'s right operand's use of a carrier of the left operand's place", which left the owner's read it names out) |
| T8 (codegen honesty) | no: T8 emits `noalias` only where established against every writer, never on an open place; under the interim rule every accepted in-place `=` meets it |
| the loan kinds, closed and open places | no; the rule is stated in their terms |
| D-SAFE2-3 to D-SAFE2-5, the value-representation keying of borrowed objects | no change; the re-derivation relies on it: a right operand that is not copy-represented, or a one-element aggregate whose element is not, holds a borrowed object whose frozen loan T4 and M3 check, and the interim rule keys the in-place case on the same representation read at every depth, as D-SAFE2-3's one-element clause reads it (mutation_safety.md:620-622; type_info.cpp:82-89, convert.cpp:283-297; amended 2026-10-29, review fold: A-RA3-B1, where this read "a pointer-represented right operand is a borrowed object" and "keys the in-place case on the same representation (type_info.cpp:82-89)") |
| `Core.SharedImmutable` and M3's structural write rule | no: M3 still decides what an exempt operation may write through a shared path (`Peek2`, `Peek4` unchanged) |
| M3(c) for types that are not `Core.Plain` | no |
| the `bound` rule (T5(d), W-349) | no |
| Permissive | no: each new Strict rejection has the twin warning `PermissiveAliasedExclusive` |
| the Debug value-binding flag (D-SAFE2-7) | no |
| the C++ boundary | no: a C++ function is never core/prelude code, so an operator that calls one is user-written, as before |
| the Rust mapping (D-SAFE-19) | no |
| the diagnostic names | none added or renamed: the rule uses `StrictInvalidatingThroughShared`, `StrictSharedBorrowInvalidated`, `StrictExclusiveBorrowConflict`, `StrictBorrowFromShared`, `StrictBorrowedObjectMutated`, `StrictSharedImmutableWrite` and `StrictRefFromShared`; `StrictInvalidatingThroughShared`'s message gains a third form, for a `ref` operand that is not exempt, naming what reaches the referent (A.23, B.22; added 2026-10-29, review fold: A-RA3-M2) |
| safe2-plan.md section 4's matrix | every page row keeps its outcome; new rows for the probe shapes (section 4) |

### §0.7 Collisions with trunk and the held heads

`git ls-remote origin` on 2026-10-29: PR 53 2407efa74, PR 51 f96fe8a7a, PR 52
e6bc32a6d, PR 60 cc4daba00, PR 54 cb3ef2e74, PR 55 c3cdecc5d, PR 56 9f12209d8,
PR 57 e23113ba2, PR 58 fcee90d9b, PR 59 b0822a744, PR 61 66aa13132, PR 62
0ef8a0334, PR 64 551a03328, PR 63 89aabd125, PR 65 fee0ef31c, PR 66 43c8ab476,
PR 67 56e2e5bbd, PR 68 097c76473, and `claude/carbon-fork-0-1-safe-wip`
0f22798fb, all as the brief states; re-checked by the fixer on 2026-10-29, the
18 heads and trunk unchanged and the mirror moved to f97cdf414, this plan's rev
1 commit, which the orchestrator mirrored (a moved head, reported; amended
2026-10-29, review fold: A-RA3-m4, B-M4); re-checked by the rev 3 fixer on
2026-10-29, the 18 heads and trunk unchanged and the mirror moved to 782a5b740,
rev 2's commit (a moved head, reported; added 2026-10-29, review fold: RR1-m2).
Trunk is **abdc798c6**, a descendant
of 1c83422a0 by one records-only commit ("ORCHESTRATION: SAFE-2 stopped at its
plan rev 14 on PRR3-B1; SAFE-3 planned to re-derive the built-in operator
exemption", fork/ORCHESTRATION.md only), whose text Appendix D's anchors are
taken from (reported, not silently taken).

No held head touches the safety pages or fork/safe/ (`git diff --name-only` from
each head's merge base with 0f22798fb); PR 51 and PR 65 touch slices.md, which
SAFE-3 does not edit. The planner applied the whole fold of section 2 to a
detached scratch worktree of 0f22798fb and made a scratch commit 34c19b364 (on
no branch; the worktree removed after):
`git merge-tree --write-tree --name-only` of it against trunk and each of the 18
heads gives exactly the conflict sets of 0f22798fb against the same heads, which
are safe2-plan.md section 0.8's table with trunk at abdc798c6: trunk,
ORCHESTRATION.md, decision-log.md, work-items.json; PR 51, work-items.json; PR
52, 54, 55, 56, 57 and 58, those three and gap-analysis.md; PR 60,
ORCHESTRATION.md, gap-analysis.md, work-items.json; PR 59 and PR 66,
decision-log.md, gap-analysis.md, work-items.json; PR 61 and PR 64,
decision-log.md, work-items.json; PR 62, 63, 65, 67 and 68, ORCHESTRATION.md,
decision-log.md, work-items.json; all under fork/, no page. Rev 1's 34c19b364
differed from rev 1's committed texts in two places (the log's "D-SAFE3-1 to
D-SAFE3-8" and W-366's "D-SAFE3-4", review B's m2). For rev 2 the fixer applied
this plan's texts by bin/dryrun.py, reading them from this file with the
placeholders filled at their real widths, to a detached scratch worktree of
0f22798fb at /dev/shm/safe3-fixer/wt and made scratch commit 3cff85911 there
(on no branch; removed after): its conflict sets against trunk abdc798c6 and
the 18 heads are again exactly 0f22798fb's, PR 53's own head none (amended
2026-10-29, review fold: B-m2). For rev 3 the fixer did the same with
fixer1/bin/dryrun.py at /dev/shm/safe3-fixer1/wt, scratch commit f5487ba94 (on
no branch; removed after): its conflict sets against trunk abdc798c6 and the
18 heads, all 19, are exactly 0f22798fb's, PR 53's own head 2407efa74 none
(added 2026-10-29, review fold: RR1-M1).

### §0.8 The id re-scan

`git grep -ohE '\bW-3[6-9][0-9]\b' <ref> -- fork/` over all 167 origin refs and
local branches, and the same over fork/ in every worktree: W-360 to W-364,
W-398 and W-399 (VA-2's and DR-1's range bounds) and W-365, which appears only
in fork/safe/safe2-plan.md and trunk's fork/ORCHESTRATION.md as SAFE-2's
planned residue; no ledger on any ref has an id past W-363
(`"id": "W-3[4-9][0-9]"` over every ref's fork/inventory/work-items.json:
W-340 to W-356 and W-360 to W-363). W-357 to W-359 (RG-1's) and W-364 (OV-4's)
are reserved and not taken. So W-365 is filed for RB-M3 as planned, and the
next free id, **W-366**, is the watch item of the interim `=` (D-SAFE3-9). No F
id is minted; F-013 is amended by dated marks. Repeated by the fixer on
2026-10-29 over the same 167 refs and every worktree: the same ids, W-366 now
appearing only in this plan (fork/safe/safe3-plan.md at f97cdf414 on the branch
and the mirror), no ledger past W-363; rev 2 mints no id. Repeated by the rev 3
fixer on 2026-10-29 over the 167 refs and every worktree: the same, W-366 only
in this plan on the branch and the mirror; rev 3 mints no id (added
2026-10-29, review fold: RR1-M1).

### §0.9 SAFE-2's findings that the tree does not carry

Every accepted finding of safe2-plan.md's rounds that 0f22798fb does not carry,
with where SAFE-3's fold lands it (SAFE-2's fold texts F1 to F27, section 8.20,
are reference only; this plan's texts are Appendix A and B):

| finding | substance | lands |
| --- | --- | --- |
| RR3-M1, RA-M1, RB-M1 | the compound assignments convert a user's `U` inside a thunk while `ref self` is bound | A.1, A.7, B.1, A.0, B.12: user-written, the program converting first |
| RR3-m1, RB-m2 | uint.carbon:460 is `self += AsUInt(1);`, not `self += AsInt(1);` | A.1 |
| RA-M2, RB-M2, PRR2-M1, PRR2-m1 | the interim `=` runs user code while its left operand is bound | A.1, A.7, B.1 (the interim rule's third condition), D-SAFE3-5 |
| PRR3-B1 | the interim `=`'s right operand reads the left operand after its initialization begins, no user code running | A.1, A.7, B.1 (the interim rule's first two conditions), D-SAFE3-5 |
| PRR3-m1 | a call initialized in place receives its place only once its arguments are evaluated (v04 to v06) | section 0.3; D-SAFE3-5's sentence on why the interim rule does not need the clause, and B.26's mark on PRR3-m1's break condition in safe2-plan.md (amended 2026-10-29, review fold: B-m6, where this read "section 0.3 and D-SAFE3-5 (a fact the conservative rule does not need)") |
| RB-m1 | when the operand is bound | A.1, A.7, B.1: at the call, after the operands are evaluated |
| PRR1-m1, PRR1-m2, PRR2-m2, PRR2-m3 | a prelude conversion over a user's type; the closed-place diagnostic; the restrictive symbolic-witness clause with `Inc` and `Dec`; the same words in every copy | A.1, A.7, B.1, A.0 |
| RB-M3, PRR1-M2 | M7's data-race guarantee fails for a `const T*` into a scoped thread and for globals | W-365 (B.14) with pointers on M7 (A.11), Data races and the facets (A.12), the D-SAFE-16 bullet (A.13), the log's and plan's D-SAFE-16 (B.2), safety/README.md's data races (A.20), W-149's notes (B.13) and the mutation page's overview (A.18) |
| RA-m1 | upstream's prelude declares `IndirectIndexWith.Ref` with no `bound` | A.14, beside `Core.Buf(T).Set`'s paragraph |
| RA-m2 | the `bool` exclusion is `MaybeUnformed`'s alone | A.15, B.3 |
| RB-m3 | lines that start with an R31 hazard | A.5, A.6, A.16, A.17, A.21, A.22, B.4, B.9, B.10, B.11 |
| PRR1-m3, PRR3-m2 | the destructor TODO; the nightly's limits | W-366's notes (B.14); section 0.3 |
| RA-m3, RA-m4, PRR1-m4, PRR1-m5, PRR2-m4 | records-only | carried by safe2-plan.md as recorded; no page text |

F1 to F6 are superseded, not applied: their governing test is PRR3-B1's refuted
one. RA-m1's slices.md half stays REJECTED as safe2-plan.md section 8.20 records
it.

## §1 Design

### §1.1 The three models weighed

Each decided by probe and by the quoted text (rejected ones with their
refuting program in section 7):

-   **(A) Value-representation keying as the rule.** An operator's `ref` operand
    on an open place exempt only when the referent's type is copy-represented at
    every depth. Sound for every probe: such a left operand is initialized by
    copy, one store of a complete value (type_info.cpp:82-85,
    convert.cpp:283-297; s01, s13, s16, q06a, f02), where a type that is only
    copy-represented at its top, a one-element aggregate of a
    pointer-represented element, is not (ra01, ra04, ra05; amended 2026-10-29,
    review fold: A-RA3-B1, where this read "exempt only when the referent's type
    is copy-represented" and "a copy-represented left operand is initialized by
    copy"). But as the rule of the design it is beyond upstream's text: under
    the rewrite of assignment.md:184 the right operand is an argument formed
    before the call for every type it routes, and `*q = {.n = 1, .m = 2}`
    through a `T*` to a `Plain` two-field struct, which nothing but the call can
    reach, would be M3(d)'s; and it would outlive the deviation it answers.
    Taken for the interim path only, as its keying (D-SAFE3-5).
-   **(B) The element-wise model of the interim `=`.** Each element's store its
    own `ref`, live for that store. The noalias claim then holds per element for
    v09 to v25, but a program the model accepts changes its result when the
    toolchain adopts the rewrite of assignment.md:184 for its type: the swap
    `*q = {.a = p->b, .b = p->a}` prints 2 2 on the interim `=` and 2 1 with the
    right operand formed first as the rewrite forms it (s11), so the model would
    certify as safe a result that a toolchain change silently alters. Rejected
    on that ground alone (amended 2026-10-29, review fold: A-RA3-M1, where this
    read "the model defines the swap's result as 2 2 where upstream's "the
    converted value replaces the value of that operand" (assignment.md:150)
    gives 2 1 (s11), a second spelling of upstream's assignment, and a program
    it accepts changes its result when the toolchain adopts the rewrite";
    assignment.md:148-151 covers integers, floating-point types, `bool` and
    pointers only, and upstream has not stated the order for aggregates,
    :159-164).
-   **(C) Upstream's rule as the design.** `x = y;` is
    `x.(AssignWith(U).Op)(y);`, the `ref` bound for the call, the right
    operand an argument formed before it; the exemption granted for a call
    whose body and thunk run only core/prelude code and whose other operands
    reach the referent only as the borrowed-object rule checks. Sound for every
    call-based probe (a_p07, b_p1 to b_p3, s02, s19, s11, s20, f01), and
    upstream's text for the operators and types :184 and :148-151 cover; for
    tuples, structs, choice types and data classes, whose assignment upstream
    leaves a TODO (assignment.md:159-164, leads issue 686) while its designed
    initialization, which assignment is "intended to exactly mirror" (:86-87),
    is depth-first and in place (pattern_matching.md:858-867, :913-918;
    p005545:118-122), applying :184 is this design's reading, pending issue
    686 (amended 2026-10-29, review fold: A-RA3-M1, where this read "and true
    to upstream"); the interim `=` recorded as today's difference from it.
    **Chosen, with (A)'s keying for the interim path**: while the difference
    stands, Strict checks an in-place `=` by what it does (D-SAFE3-5).

The rule in words a page can carry: an operator's `ref` operand is bound for the
operator's call, after its other operands are evaluated, and it is exempt from
the `ref` rule's marker, established on any place with no loan of its own, M3
alone deciding the write, when the checker establishes that nothing but the
operand can reach its referent while it is bound, by two conditions that are the
stricter criterion p005434:860-861 says safe code will use, sufficient and not
necessary: everything that runs then is core/prelude code reached through no
symbolic witness a library outside core/prelude can fill, and every other
operand is a copy that holds no borrowed object or a borrowed object's value
binding under its frozen loan. Today's toolchain initializes in place, in whole
or in part, a left operand whose type is not copy-represented at every depth, so
while that stands, for a left operand whose type is not copy-represented at
every depth, the whole right operand counts as evaluated while the left operand
is bound, and the `=` keeps the exemption only when its right operand reads no
open place and passes no carrier of one to a call, reads or uses no part of the
left operand's place, or of a place that overlaps it, through its owner or a
carrier of it (T1, T3), and, on an open place, runs no code written outside
core/prelude (amended 2026-10-29, review fold: A-RA3-B1, A-RA3-m3, B-M3, where
this read "exactly when nothing but the operand can reach its referent while it
is bound", "every other operand is a copy or a borrowed object under its frozen
loan" and "Today's toolchain initializes a left operand that is not
copy-represented in place, so while that deviation stands such an `=` keeps the
exemption only when its right operand reads no open place, uses no carrier of
the left operand's place and, on an open place, runs no code written outside
core/prelude"; amended 2026-10-29, review fold: RR1-M1, where this read "uses no
carrier of the left operand's place or of a place that overlaps it", which
exempted `x = {.a = x.b, .b = x.a}`, a read through the owner, section 0.0).

### §1.2 Decisions

Each under R29, with its break condition.

-   **D-SAFE3-1 — The baseline.** Upstream at 9192ee003 (section 0.1): no
    quoted passage changed since SAFE-2 read it, the one moved file
    (details.md, by one line) cited at the tip's numbers, PR 67's 273 quotes
    and 89 checks passing, and this plan's 110 quote rows passing (rev 1's 67,
    rev 2's 33 and rev 3's 10; amended 2026-10-29, review fold: A-RA3-M1,
    A-RA3-m3; amended 2026-10-29, review fold: RR1-m1, where this read "100").
    Break
    condition: the implementer's re-fetch finds a newer tip under which a line
    this plan quotes fails; the block that rests on it stops and this plan is
    revised for it before its text is committed.
-   **D-SAFE3-2 — The operation's `ref` lifetime is the operator's call.**
    Every operator p005434:302-316 gives a `ref` operand is, in upstream's
    design, a call of its interface's method with that operand as `ref self`
    (assignment.md:176-177, :184, :186-295), so the `ref` is bound from the
    call's start to its return, the left operand's place and then the right
    operand evaluated before it (a_p07, b_p1 to b_p3), and the call receives
    the right operand complete, a copy that holds no borrowed object, or a
    value binding of a borrowed object for the call, which a type that is not
    copy-represented holds and so does a one-element aggregate whose element
    is not (D-SAFE2-3 and its one-element clause; amended 2026-10-29, review
    fold: A-RA3-B1, where this read "a copy when copy-represented and otherwise
    a value binding of a borrowed object"). What runs while it is bound is the
    impl's body, the thunk of details.md:5769-5779 and that thunk's
    conversions, the toolchain's inlining of a direct call's thunk
    (call.cpp:311-331) moving the code but not its place in the semantics.
    The language's own `&`, member access naming a field and indexing of an
    array form a reference expression after their operands are evaluated and
    run nothing while the operand is bound (v23). Labelled: the call model is
    upstream's text (assignment.md:184) for every operator and type it routes,
    and this design's reading for an aggregate's `=`, pending leads issue 686
    (section 0.1); the operands' order, the left operand's place and then the
    right operand, is the toolchain's behavior (a_p07, b_p1 to b_p3), which no
    upstream text fixes; that no code but the call runs while the `ref` is
    bound is their consequence (amended 2026-10-29, review fold: A-RA3-M1,
    A-RA3-m2, where this read "the call model and the operands' order are
    upstream's text and the toolchain's behavior"). Break condition:
    upstream's design binds an operator's operand otherwise, for example by
    resolving leads issue 686 ("Operation order in struct/class
    assignment/initialization", assignment.md:163-164) with an in-place,
    depth-first assignment that mirrors pattern_matching.md:858-867's
    initialization; the rule then follows by a dated mark and the interim rule
    of D-SAFE3-5 becomes the design's for those types.
-   **D-SAFE3-3 — The exemption, re-derived.** The operand is exempt from the
    `ref` rule's marker, established on any place, with no loan of its own,
    neither M3(d)'s exclusive-receiver call nor M3(e)'s exclusive loan, M3 alone
    deciding what the operation may write through a shared path, when the
    checker establishes that no path but the operand can reach its referent
    while it is bound. Two conditions establish it, the stricter criterion
    p005434:859-864 says safe code will use ("But this condition is hard to
    check, so safe code will use a stricter criteria."): sufficient, not
    necessary, so the exemption is granted when both hold and not otherwise,
    and a program both reject may still have no other path (amended 2026-10-29,
    review fold: A-RA3-m3, where this read "exactly when no path but the operand
    can reach its referent while it is bound. Two conditions establish it"):
    (a) everything that runs while it is bound is code written in core/prelude,
    reached through no symbolic witness that an impl written outside
    core/prelude can fill when a generic is called, the prelude's bodies
    trusted under S0 to reach the referent only through the operand; (b)
    every other operand reaches the referent only as the borrowed-object rule
    checks: a copy that holds no borrowed object reaches nothing, and a value
    binding of the referent itself, or a copy that holds one, a one-element
    aggregate whose element is not copy-represented (`*q = *p` for
    `{.s: {.a: i32, .b: i32}}`, D-SAFE2-3's one-element clause), breaks
    its own frozen loan, `StrictBorrowedObjectMutated` on a closed place (T4
    sees both) and on an open place `StrictBorrowFromShared` unless the type is
    `Core.SharedImmutable`, whose write through a shared path M3 rejects (s20:
    `other` reads the referent; f01: the nightly copies the element first,
    which values.md:456-463 permits and does not require; amended 2026-10-29,
    review fold: A-RA3-B1, where this read "a copy reaches nothing, and a value
    binding of the referent itself breaks its own frozen loan"). In every
    program (a) and (b) accept, nothing but the operation touches the referent
    while the `ref` lives, so p005434:83's `noalias` holds. Anything else is
    user-written: a `ref` binding under the general rule, a checked reborrow on
    a closed place (T4) and M3(d)'s `StrictInvalidatingThroughShared` through a
    shared path. Labelled this design's: upstream says the `ref` is `noalias`
    and leaves its checking to "the memory safety design" (p005434:834-835,
    :859-864, :866-868). Break condition:
    a Strict-accepted program in which a path not derived from the operand
    accesses the referent while it is bound; the conditions are narrowed until
    none exists, never a clause added about who wrote the code.
-   **D-SAFE3-4 — What is built in.** By (a): the language's own `&`, member
    access naming a field and indexing of an array; the prelude's impls for
    `Int`, `UInt`, `Float` and the `CppCompat` integers when their thunk
    converts a literal (q04, a_p03), another prelude integer (x3, s19) or a
    value the program converted first (a_p02, `*q += e as i32`); `Inc` and
    `Dec`, whose `self += AsInt(1);`, `self += AsUInt(1);` and `self -=
    AsInt(1);` reach witnesses only the prelude can fill by the orphan rule
    (details.md:4728-4736; z3, z3b). User-written: a thunk that runs an
    `ImplicitAs` written outside core/prelude (a_p06, a_p13, q03), a prelude
    conversion that calls one (`const U as ImplicitAs(T)`, as.carbon:46-48,
    x1; `U as OptionalAs(T)`, x2), an impl written outside core/prelude, an
    impl or conversion reached through a symbolic witness such an impl can
    fill (x4, v21), and assignment.md:302-316's default compound assignment
    wherever its `AssignWith` or `OpWith` is user-written (a_p04, b_p11). Two
    classifications are this design's, beyond upstream's text: the conversion
    of `=`'s right operand (assignment.md:149-150) counts as the compound
    assignments' does, the prelude having no `AssignWith` impl yet (a_p05), so
    a user's `ImplicitAs` makes `=` user-written (w4); and the assignment of
    tuples, structs, choice types and data classes (assignment.md:159-161, a
    TODO) is the language's own, member by member, user-written where a
    member's assignment is, a classification the interim `=` extends to every
    type with no `AssignWith` impl, arrays and classes that are not data
    classes among them. Break condition: upstream's `AssignWith` impls for the
    built-in types land with `other` of the right operand's own type and no
    thunk, or leads issue 686 states the aggregate rule; the classification
    follows by a dated mark. (Unchanged by the review fold of 2026-10-29: the
    copy-represented-at-every-depth keying is D-SAFE3-5's, about how the interim
    `=` initializes, not about who wrote the code.)
-   **D-SAFE3-5 — The interim `=`: a difference from the rewrite and Strict's
    interim rule.** Today's toolchain does not perform the rewrite for `=`: its
    interim `=` (handle_operator.cpp:99-123) calls no `AssignWith` and
    initializes the left operand from the right (:121), by copy for a
    copy-represented type and in place for any other (type_info.cpp:82-89), one
    element at a time (convert.cpp:361, :946; values.md:604-607), each element
    of a by-copy aggregate too having its own initializing target inside the
    destination (convert.cpp:283-297, :400-405), so a copy-represented
    one-element tuple or struct whose element is not copy-represented is
    initialized in place in part (ra01, ra04, ra05), an element's value acquired
    at its own position (values.md:458-460), so the right operand reads the left
    operand after its initialization has begun (v09, v10, v11, v14, v24, v25,
    s03 to s05, s15, ra01, ra04, ra05: 2 2 where s11's emulated rewrite gives 2
    1), and a user's `Copy`, `ImplicitAs` or call initialized in place runs
    while it is written (z1, z2, b_p8, s07, s08, ra03). For the integers,
    floating-point types, `bool` and pointers, whose `=` assignment.md:148-151
    states, this is a deviation from :184's rewrite by upstream's own TODO
    (handle_operator.cpp:99-100, which adds "Some cases may need to be handled
    directly."); for tuples, structs, choice types, data classes and every other
    type with no `AssignWith` impl upstream has not decided the order
    (assignment.md:159-164, leads issue 686) and its designed initialization is
    itself depth-first and in place (pattern_matching.md:858-867;
    p005545:118-122), so calling the in-place order a difference from the design
    is this design's reading of :184, pending issue 686 (amended 2026-10-29,
    review fold: A-RA3-M1, where this read "This is a deviation of today's
    toolchain from upstream's design, by upstream's own TODOs"). Either way it
    is recorded as watch item W-366; it is not this design's semantics, and with
    no `noalias` emitted its results are defined, not undefined behavior. While
    it stands, Strict checks the interim `=` by what it does as well as by
    D-SAFE3-3: for a left operand whose type is not copy-represented at every
    depth, the whole right operand counts as evaluated while the left operand is
    bound, and the `=` keeps the exemption only when its right operand reads no
    open place and passes no carrier of one to a call, reads or uses no part of
    the left operand's place, or of a place that overlaps it, through its owner
    or a carrier of it (T1, T3), and, on an open place, runs no code written
    outside core/prelude; these are conditions (i), (ii) and (iii), and the
    sentence is the one every copy of the rule carries (section 8 item 4 checks
    it; amended 2026-10-29, review fold: A-RA3-B1, B-M3, where this read "for a
    left operand whose type is not copy-represented"; amended 2026-10-29,
    review fold: RR1-M1, where (ii) read "uses no carrier of the left operand's
    place or of a place that overlaps it", T3's carriers leaving the owner out,
    section 0.0). Condition (ii) covers every path to the place that the place
    kinds name, the owner and every carrier, and with (i) and (iii) every path
    by which the right operand can reach the referent: an open place only
    through an open read or a carrier passed to a call, or through code written
    outside core/prelude, and a closed place only through its owner or a
    carrier, every carrier of a loan on it being in the body's view by the
    definition of a closed place (temporal_safety.md:134-143). A type is
    copy-represented at every depth when it is copy-represented and, if its
    representation is a one-element tuple or struct's (the type, or an adapter,
    `const` or `MaybeUnformed` of one), its element is copy-represented at
    every depth (type_completion.cpp:572-578, :762-770, :786-788 and
    :806-826, convert.cpp:283-297 and :1467-1518 at 9192ee003): `i32`,
    `{.n: i32}`, `{.s: {.n: i32}}`, `Core.Optional(i32*)` and
    `{.o: Core.Optional(i32*)}` are (f02), `{.s: {.a: i32, .b: i32}}`,
    `((i32, i32),)` and a class that adapts `{.s: {.a: i32, .b: i32}}` or
    `{.c: C}` are not (ra01, ra04, n01, n02) (amended 2026-10-29, review fold:
    RR1-m1, where this read "if it is a one-element tuple or struct, its
    element is copy-represented at every depth" and "`{.s: {.a: i32, .b: i32}}`
    and `((i32, i32),)` are not (ra01, ra04)"). Otherwise it is a
    `ref` binding under the general rule, a checked reborrow on a closed place
    (T4: `x = {.a = x.b, .b = x.a}`, the right operand reading the left
    operand's place through its owner, as n03's `var` parameter, `returned var`
    and class local do, and `y = {.s = {.a = y.s.b, .b = y.s.a}}`,
    `StrictExclusiveBorrowConflict`; `c = Make(&c.a)` and `c = {.data = 42,
    .next = &c.data}`, `StrictSharedBorrowInvalidated`) and M3(d)'s through a
    shared path (`*q = {.a = p->b, .b = p->a}` and ra01's `*q = {.s = {.a =
    p->s.b, .b = p->s.a}}`, `StrictInvalidatingThroughShared`), the program
    forming the right operand first (s10: 2 1; for ra01's shape the nightly's
    own wrong code, a `poison` store after the elements, makes ra06's and f04's
    output order-only, and the element-by-element remedy of f04 prints 2 1).
    Where D-SAFE3-3 rejects too, its diagnostic is reported. A left operand
    whose type is copy-represented at every depth is stored once from a complete
    value, and D-SAFE3-3 decides alone (amended 2026-10-29, review fold:
    A-RA3-B1, where this read "A copy-represented left operand is stored once
    from a complete value"). The interim rule only adds conditions, so every
    program it accepts D-SAFE3-3 accepts, and the toolchain's adoption of the
    rewrite withdraws it by a dated mark with nothing newly rejected; a program
    both rules reject, such as `*q = *p` for a pointer-represented type, stays
    rejected by D-SAFE3-3. PRR3-m1's clause, that a call initialized in place
    receives its place in the left operand only once its arguments are evaluated
    (v04 to v06), is true and not needed here: the whole right operand counts as
    evaluated while the left operand is bound, so no outcome of the rule depends
    on when within the right operand the place is passed, which is why
    safe2-plan.md's PRR3-m1 break condition is closed by B.26's mark without the
    clause (added 2026-10-29, review fold: B-m6). Labelled this design's interim
    checker rule. Break condition: the toolchain routes `=` through `AssignWith`
    for every type (W-366's discharge); or it does so for some types only, the
    scalars of assignment.md:148-151 first, and the interim rule then stays, by
    a dated mark naming them, for every type still initialized by
    `InitializeExisting`; or the toolchain or upstream gives an unformed left
    operand the direct initialization of assignment.md:102-106 (`y = F();`,
    :116-120), which is initialization in place and stays under the interim rule
    whatever the rewrite's status; or handle_operator.cpp:119-120's destructor
    TODO or type_info.cpp:83-84's in-place TODO is done first, re-opening the
    copy-represented case; or type_completion.cpp:576-577's TODO gives a tuple
    or struct of more than one element a copy representation, which this keying
    would then count as stored once, a probe deciding before a dated mark keeps
    or narrows the keying; each followed by a dated mark (amended 2026-10-29,
    review fold: A-RA3-B1, A-RA3-M1, where this read "the toolchain routes `=`
    through `AssignWith` (W-366's discharge)" and "or
    type_completion.cpp:576-577's TODO makes a small aggregate copy-represented,
    moving it to the by-copy case").
-   **D-SAFE3-6 — Everything else stays.** T1 to T8, the Store rule, the loan
    kinds, closed and open places, D-SAFE2-3 to D-SAFE2-5,
    `Core.SharedImmutable` and M3's structural rule, M3(c), the `bound` rule,
    Permissive's twin warnings, the Debug flag, the C++ boundary, the Rust
    mapping and the diagnostic names (section 0.6); no diagnostic is added or
    renamed: the interim rule's T4 conflicts are `StrictExclusiveBorrowConflict`
    and `StrictSharedBorrowInvalidated` as T4 reports them, and the
    exemption's M3(d) rejections are `StrictInvalidatingThroughShared`, whose
    specified message, for an assignment "of non-`Plain` type `{1}`" or a "call
    of `ref self` method", would be false for a `Plain` type's swap, `*q += e`
    on `i32` or the interim `=`, so the message texts gain a third form, for a
    `ref` operand that is not exempt, naming what reaches the referent (A.23 on
    the mutation page, B.22 in fork/safe/plan.md section 1.6; added 2026-10-29,
    review fold: A-RA3-M2). Break condition: stage 4 (W-148) finds the reused
    diagnostics misleading at the interim `=`; a name is added by a dated edit.
-   **D-SAFE3-7 — The amendment convention.** Every rewritten passage carries
    "(re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5" and quotes the text it
    supersedes in full: inline, after "where this read", for a clause or a
    sentence (A.0, A.3, A.4, A.9, A.19, B.6); in a blockquote at the end of its
    section for the two page paragraphs it replaces whole, the temporal page's
    (A.2) and M3's clause (A.8), which keeps the rule readable; and inline in
    D-SAFE-8 for the log and fork/safe/plan.md section 0.3 (B.1), whose D-SAFE
    block stays identical. A quote carries SAFE-2's own marks word for word.
    Carried SAFE-2 findings are labelled "SAFE-3, the fold of SAFE-2's
    whole-tree review: <id>". Break condition: a reviewer finds a superseded
    sentence dropped unquoted; the passage is redone, never the convention.
-   **D-SAFE3-8 — SAFE-2's open findings.** The fold applies the substance of
    every accepted finding the tree does not carry (section 0.9), F7 to F27's
    texts taken with SAFE-3's labels and checked against 0f22798fb by the dry
    run, F1 to F6 superseded by this re-derivation, RA-m1's slices.md half
    still rejected. Break condition: a reviewer shows an accepted SAFE-2
    finding left unapplied; it is folded by the fixer within the budget.
-   **D-SAFE3-9 — Ids.** W-365 filed for RB-M3 as SAFE-2 planned it; W-366 the
    watch item of the interim `=`, kind `language-gap` (the kind W-072 uses for
    an upstream-designed rule the toolchain does not yet implement), not
    blocked, discharged when the toolchain adopts the rewrite (section 0.8).
    Break condition: the implementer's re-scan finds either taken; the next
    free ids replace them in every text by a plan revision before the commit.
-   **D-SAFE3-10 — Records placement and dates.** As SAFE-2's D-SAFE2-16: a
    dated-note records commit on PR 67's branch from a detached worktree of its
    head, reviewed and pushed as a fast-forward after PR 53's dry head is
    pushed, with SAFE-2's five edits re-cited to both plans and the counts kept
    (284 quotes, 89 checks, H1.7 widened, H1.13 ALIGNED; Appendix C.2).
    `<rdate>`, the realignment's date in Appendix C and D, is SAFE-3 commit 1's
    UTC date, the date the realignment is complete; SAFE-2's commits keep their
    own dates where named. Break condition: PR 67 lands before section 3 step 8
    pushes the note commit, or the owner forbids further commits on it; the
    texts then go into trunk's records commit that stamps PR 53, and the
    land-time note discharges the items (amended 2026-10-29, review fold: B-m5,
    where this read "PR 67 lands first", which always holds, PR 67 being first
    in the land sequence).
-   **D-SAFE3-11 — The process.** Two commits (section 3), two whole-tree
    document reviews in parallel, one fixer with a budget of two fix commits and
    no shrink line, and a focused re-review by two fresh agents per round, at
    most three rounds, dry being no BLOCKER, no MAJOR and every MINOR
    records-only; a page-changing finding past the budget or the rounds stops at
    a plan revision for the orchestrator's ruling, and a finding that would
    soften a re-derived rule is never folded as such. Break condition: the
    orchestrator's ruling.
-   **D-SAFE3-12 — The cost, accepted.** Unchanged and permitted: `q->n = 2`,
    `p->n += 1` and `++p->n` through a plain `T*` (copy-represented, by copy,
    prelude only), `*q = F(p)` for an `i32` result, `*q = {.a = 1, .b = 2}` for
    a `Plain` aggregate through `T*`, every page example (section 4). Newly
    rejected while the deviation stands, each with its remedy: an in-place `=`
    whose right operand reads the left operand's place on a closed place (`x =
    {.a = x.b, .b = x.a}`, `pos = {.x = pos.x + dx, .y = pos.y}` for a
    pointer-represented `pos`), reads an open place or runs user code through a
    shared path (`*q = {.a = p->b, .b = 1}`, `*q = {.a = 1, .n = F(p)}`, `*q =
    {.x = e as i32, .y = e as i32}` with a user's `Convert`), or passes a
    carrier of the place (`c = Make(&c.a)`; and, though nothing reads through it
    during the `=`, a self-referential assignment of a class, `c = {.data = 42,
    .next = &c}` as toolchain/lower/testdata/return/return_var.carbon:20 writes
    it and `s = {.p = &s}` as
    toolchain/check/testdata/class/self/self_type.carbon:19 does, f03): the
    program forms the right operand, or each user-converted element, first, or
    assigns field by field, `pos.x += dx;`, `c.data = 42; c.next = &c;` (each
    field copy-represented, f03: 45). The same holds for a copy-represented
    one-element aggregate whose element is not copy-represented, ra01's
    `*q = {.s = {.a = p->s.b, .b = p->s.a}}`, whose remedy is the element-wise
    one of f04 (amended 2026-10-29, review fold: A-RA3-B1, A-RA3-m6). Newly
    rejected by the designed rule itself: a user's `ImplicitAs` converted in a
    thunk (`*q += e` through a shared path; `*q = e` into an `i32`), the
    program converting first; `*q = *p` through shared pointers to a
    pointer-represented type or to a one-element aggregate of one
    (`StrictBorrowFromShared`, as SAFE-2's `let v = *p` already is), the
    program copying first (`var v: T = *p; *q = v;`); `x = x` for such a type
    (`StrictBorrowedObjectMutated`). The cost is right
    because each rejected program is one in which, under the model, another path
    can observe the referent while the `ref` lives (section 1.3), or, for the
    interim rule, one whose result today differs from the one formed first, or
    one the rule's stricter criterion cannot tell from such a program (the
    self-referential assignment). Measured (risk R-5, by fixer/bin/r5count.py
    and a multi-line search, logs/r5-fork.txt and logs/r5-wide.txt): of 654
    assignment statements in fork/conformance's programs, the `carbon` blocks of
    docs/design/safety/ and examples/, none is newly rejected, every
    self-referential one being on a copy-represented type or a disjoint sibling
    field (`self.steps = self.next_steps;`, both `i32`); of 3185 in
    toolchain/**/testdata, core/ and docs/design/, two are, the two
    self-referential class assignments above, and docs/design/values.md:1275's
    generic `**dest = *arg;` is `*q = *p`'s shape in upstream's illustrative
    code (amended 2026-10-29, review fold: A-RA3-m6, where this read "Break
    condition: risk R-5's count shows the cost larger than the pages state; the
    count is added by a dated edit, the rule unchanged." without a count). Break
    condition: a later count shows the cost larger than the pages state; the
    count is added by a dated edit, the rule unchanged.

### §1.3 The noalias claim, probe by probe

For each probe, the outcome under D-SAFE3-3 to D-SAFE3-5 and why nothing but
the operation reaches the referent while the `ref` lives in every accepted
program:

| probes | outcome | why `noalias` holds |
| --- | --- | --- |
| a_p03, b_p12, q04, q05, s19, v22, z3, z3b | built in, accepted | the thunk converts a literal or a prelude integer; `Inc` and `Dec` reborrow `self` |
| a_p02, x3 | built in, accepted | the conversion is the program's own `as` before the call, or prelude code |
| q01 | built in | `Float` direct call, builtin body |
| r3_thunk, a_p01, b_p0, a_p06, a_p13, q03, x1, x2 | user-written: M3(d) through `T*`, T4 on a closed place | rejected through a shared path; on a closed place the user's `Convert` gets no carrier of the place unless T4 sees it |
| x4, v21 | user-written | the symbolic witness is fillable outside core/prelude |
| a_p04, b_p11, a_p05, a_p12, v19, v20, q02 | compile errors | no program |
| a_p07, b_p1 to b_p3 | as their operators classify | the right operand's side effects end before the call |
| q06a, q06f, w4 (`i32`), s01, s16, s13's struct, f02 | copy-represented at every depth, by copy (rev 1: "copy-represented"; amended 2026-10-29, review fold: A-RA3-B1) | one store of a complete value; w4's user `ImplicitAs` makes it user-written by D-SAFE3-4 |
| v09, v11, v14, s03 to s05, s15, ra01, ra04, ra05 (through aliasing `T*`) | M3(d), `StrictInvalidatingThroughShared` (v09, v11 and ra05 also M3(c)) | rejected: the right operand reads an open place; ra01, ra04 and ra05 are copy-represented one-element aggregates whose element is not, under the interim rule since rev 2 (added 2026-10-29, review fold: A-RA3-B1) |
| v10, v24, s17, ra01's and ra04's locals, n03 (a `var` parameter, a `returned var` and a class local) | condition (ii) fails, the right operand reading the left operand's place through its owner, so the `=` is a checked reborrow and T4 reports `StrictExclusiveBorrowConflict` (rev 2's (ii), over carriers only, exempted these; amended 2026-10-29, review fold: RR1-M1) | rejected: the right operand reads the left operand's place through its owner while the reborrow is live |
| ra03 | M3(d) through `T*`: user code (`Peek`) in the right operand of an in-place `=` | rejected |
| ra06, f04's first (the formed-first remedy for ra01's shape) | the interim rule accepts (the right operand reads only the body's value `v`); M3 decides | nothing in the right operand reaches the left operand's place; the nightly's `poison` store makes the output order-only (section 0.3) |
| ra07, n04's local (rev 3) | `v` is a value binding of `x` (of `y.s` for n04's `W`), a borrowed object under a frozen loan, so the `=` is `StrictSharedBorrowInvalidated` (T4) before the interim rule applies; condition (ii) fails too, `v` being a carrier (T3), and the gloss excludes it ("values that carry no loan on it"; rev 2's gloss read "values that carry no loan on the left operand's place", amended 2026-10-29, review fold: RR1-M1) | rejected |
| n04's alias (rev 3) | `let v: W = *p` binds a borrowed object, `W`'s element, on an open place: `StrictBorrowFromShared` (D-SAFE2-3's one-element clause) | rejected at the `let` |
| n01 (rev 3) | `class A { adapt W; }` is not copy-represented at every depth (D-SAFE3-5, RR1-m1), so the interim rule applies, and the right operand reads `*p`, an open place: M3(d), `StrictInvalidatingThroughShared` | rejected; the nightly forms the value first through `as` and stores `poison` after (order-only) |
| n02 (rev 3) | `class A { adapt {.c: C}; }` is not copy-represented at every depth, and `*q = *p` initializes `C`'s part in place by a user `Copy`: D-SAFE3-3 (b), `StrictBorrowFromShared`, and the interim rule's (i) and (iii) | rejected |
| f01 | designed, `W`'s `other` holding its element as a borrowed object: `StrictBorrowFromShared` through `T*` | the nightly copies the element first, which the design does not rely on |
| f03 | the interim rule (ii) rejects `c = {.data = 42, .next = &c.data}`, T4 `StrictSharedBorrowInvalidated`; the field-by-field remedy is accepted | nothing reads through the carrier during the `=`, a cost of the stricter criterion |
| v25 | M3 (`Core.Optional(i32)` holds a `Core.SharedImmutable` sub-object) and the interim rule | rejected |
| b_p8, a_p08, a_p11, q06b, z1, w1 to w3, v01 to v08, v12, v13, v15, v16, s06's `Bump`, s07, s08 | M3(d) through `T*`; on a closed place a checked reborrow | rejected through a shared path: user code or an open read in the right operand |
| q06h | T4, `StrictSharedBorrowInvalidated` | rejected: `&c.a` is a carrier of the place |
| a_p09, b_p5, z2 | user-written (a user `Copy` runs while bound) | rejected through a shared path |
| q06c, z1b, w3's remedy, q06g, q06e, s09's `var` copies, s10, v24's bound-first | the interim rule accepts when the right operand reads only literals, the body's closed places that do not overlap the left operand's place, values that carry no loan on it (T3), and prelude calls over them; M3 then decides (amended 2026-10-29, review fold: A-RA3-m1, where this read "the body's own values and literals"; amended 2026-10-29, review fold: RR1-M1, where this read "the body's closed places and values that carry no loan on the left operand's place") | nothing in the right operand can reach the left operand's place |
| s11, s20 (the rewrite emulated) | designed, for these aggregates this design's reading of assignment.md:184 pending leads issue 686 (amended 2026-10-29, review fold: A-RA3-M1): s11 accepted; s20's `other` is a value binding of the referent | s20 rejected by D-SAFE3-3 (b): `StrictBorrowFromShared` or `StrictBorrowedObjectMutated` |
| s06's `Whole`, s14 | M3, `StrictSharedImmutableWrite` (and M3(c) for `Optional`) | rejected |
| s18 | the interim rule accepts (literals, a prelude call over them); M3(c) rejects the non-`Plain` class through `T*` | as M3 decides |
| v23 | built in: the index and the right operand evaluated before the store | the element is copy-represented, one store |
| v17, v18, v18b, v26, b_p7, y1, b_p9, q06d, b_p6_assign_tuple, q06i, q04b, s12 to s12c, s14b, ra02 | no evidence, no assignment, or a compile error | (section 0.3) |

## §2 Spec

### §2.1 Conventions for the implementer

Every text change is a block of Appendix A or B, under a heading `### A.n` or
`### B.n` that the dry-run script reads, naming the file, the place at
0f22798fb, the action and the text, verbatim, in the first fenced block after
the heading, between the column-0 comment lines google-doc-style-ignore and
google-doc-style-resume; the implementer copies the fenced text without the
fence. Three actions:

-   **Lines.** Replace whole lines, from the line that begins with the block's
    stated first words to the line that ends with its stated last words, both
    found once, with the fenced text, which is wrapped already.
-   **Words.** A block of two parts separated by a blank line, the old words and
    the new words: replace the old words, found once in the stated place, line
    breaks and indentation set aside, with the new words, then rewrap by hand,
    to 80 columns, the lines from the one where the replacement starts to the
    end of its paragraph or list item, keeping its indentation, each code span
    on one line where it fits and no line started by `+`, by `*` or `-` other
    than a list marker, by `>`, by `#` and a digit or by a digit and a period.
-   **Insert.** After the stated anchor words, found once, add one space and the
    fenced text, then rewrap as for Words; or, where the block says paragraph,
    a blank line and the fenced text as its own paragraph after the stated line.

The JSON blocks go in as JSON: a note appended to an item's `notes` string after
one space, its quotes escaped; the two new items inserted after W-150's object
and a comma, in the file's two-space layout. Placeholders, filled when the text
is written:

-   `<date>`: the UTC date, `date -u +%F`, of the commit that writes the text,
    commit 1's for Appendix A and B, the PR 67 note commit's for Appendix C.2,
    the orchestrator's stamp's for C.1, C.3 and D; `<rdate>`, the date the
    realignment is complete, commit 1's `date -u +%F`, wherever Appendix C or D
    says "realigned", "REALIGNED", "CLOSED", "re-derived" or "realignment of".
-   `<s1>` and `<s2>`: commit 1's and commit 2's short hashes, written only in
    Appendix C and D and in section 8's records, never in the commit they name.
-   `<head>`: PR 53's dry head, the branch head after the records commit that
    folds the dry round of section 3 step 6, the head step 8 pushes and step
    9 (b) checks the mirror against, the round having reviewed the commit
    before that records commit, which a stamp that names it names by its own
    sha (amended 2026-10-29, review fold: RR1-m2, where this read "the head at
    which section 3 step 6's re-review is dry", which left the dry round's
    records commit out of step 8's push and failed step 9 (b));
    `<c2-sha>`: the PR 67 note commit's short hash; `<fixes>`: the fix
    commits' short hashes, "none" if there are none; `<verdict A>` and `<verdict
    B>`: the two document reviews' verdicts with their counts; `<tip>`: the
    upstream tip of the implementer's section 8 item 6; `<time>`: the UTC time,
    `date -u +%H:%M`, of the orchestrator's stamp.

Every fenced text that a block gives already wrapped, the Lines texts of A.1,
A.2, A.7, A.8 and B.1 among them, is wrapped with each placeholder counted at
the width of the value that fills it, `<date>` and `<rdate>` at 10 characters
(`2026-10-30`), `<s1>`, `<s2>`, `<head>`, `<c2-sha>` and `<tip>` at 9, so that
filling them keeps every line within 80 columns and no line start changes; the
dry run of section 8 item 4 fills them with stand-ins of those widths and runs
prek, rumdl and r31.py on that tree, and a line that would still move is a
defect of this plan, which stops the implementer at a plan revision, never a
rephrasing of reviewed text (added 2026-10-29, review fold: B-M1).

Every anchor and superseded text a block quotes is byte-equal to its file at
0f22798fb once line breaks with the indentation after them, the `>` and space
that start a blockquote line, and the indentation of a list item's
continuation lines are set aside (SAFE-2's section 2.1 test, which this plan
keeps); link markup, code spans and punctuation belong to the text. The dry run
of section 8 item 4 applies every block to a fresh `git archive` of 0f22798fb
and checks that each anchor is found once.

### §2.2 Commit 1, the fold of Appendices A and B

| file | blocks | what changes |
| --- | --- | --- |
| docs/design/safety/temporal_safety.md | A.0 (one place), A.1 to A.6 | the `ref` bindings section's second paragraph replaced by four (the rule, the exemption, the user-written operators, the interim `=`); the superseded paragraph quoted whole in a blockquote at the section's end; the kinds paragraph's sentence; the D-SAFE-8 decision's clause and sentence; two rewraps (RB-m3) |
| docs/design/safety/mutation_safety.md | A.0 (one place), A.7 to A.18, A.23 | M3's built-in clause replaced, quoted whole in a blockquote at M3's end; M1's sentence; the D-SAFE-9 decision's clause; RB-M3's pointer in the overview, M7, Data races and the facets and the D-SAFE-16 bullet; RA-m1's sentence on `IndirectIndexWith.Ref`; RA-m2's bullet; two rewraps; `StrictInvalidatingThroughShared`'s third message form (A.23, added 2026-10-29, review fold: A-RA3-M2) |
| docs/design/safety/README.md | A.19, A.20 | the kinds paragraph's sentence; RB-M3's pointer in the data-race paragraph |
| docs/design/safety/initialization_safety.md, spatial_safety.md | A.21, A.22 | one rewrap each (RB-m3) |
| fork/decision-log.md | B.1, A.0, B.2, B.3, B.4, B.5, B.24, B.25 | D-SAFE-8's operator clause (B.1), D-SAFE-9's clause, D-SAFE-16's pointer, D-SAFE-17's RA-m2 clause, a rewrap, a SAFE-3 sentence in RG-1's paragraph of the F-013 entry; the F-013 entry's two pointers to SAFE-2's PR 67 note commit re-pointed (B.24, B.25, added 2026-10-29, review fold: B-m3) |
| fork/safe/plan.md | B.1, A.0 (two places), B.2, B.3, B.6 to B.11, B.22, B.23 | section 0.3's D-SAFE block as the log's; section 1.5's sentence and section 1.6's clause; the pointer paragraph after the realigned one; the "Realigned notes (SAFE-2)" section's SAFE-3 paragraph; three rewraps; section 1.6's message instance (B.22, A-RA3-M2) and the realigned notes' pointer to SAFE-2's note commit (B.23, B-m3; both added 2026-10-29, review fold) |
| fork/inventory/work-items.json (PR 53's ledger) | B.12 to B.14 | a note on W-148 and on W-149; W-365 and W-366 filed after W-150 |
| fork/safe/safe2-plan.md | B.15 to B.21, B.26 | dated pointer marks: a Status paragraph, D-SAFE2-6, section 3 step 5, section 8.20 before F1, the Sign-off, Appendix C and Appendix D; PRR3-m1's break condition closed (B.26, added 2026-10-29, review fold: B-m6) |

Not edited: values.md, slices.md (PR 51's and PR 65's hunks, and RA-m1's
rejected half), rust_interop.md, type_safety.md, terminology.md, the two SKIP
stubs, fork/gap-analysis.md, PR 53's own fork/ORCHESTRATION.md,
fork/rulebook.md, the toolchain, the prelude and every golden. The commit adds
no heading, bullet, numbered item or table row to any file (section 8 item 1).

### §2.3 Commit 2, the records

"SAFE-3 (2/2): records" edits this plan alone: the Status paragraph's first
sentence, the one that begins "**Status:** rev" (at rev 3 it reads "**Status:**
rev 3 -- NOT signed off pending re-review round 2: RR1-M1.", and the
signed-off revision the implementer works from replaces it; amended
2026-10-29, review fold: RR1-M1, where this quoted rev 2's), becomes the
implementation's state, dated; and a new section 8.1, "Implementation record",
with commit 1's hash, every measurement of section 8 as run on commit 1's tree
(prek passes, the R31 counts before and after per file, rumdl, the dry-run's
checks, the nightly compiles of section 8 item 5, PR 67's checks at the tip,
`--self-test`, the merge-trees, the id re-scan, the model-name grep,
`json.load`, the D-SAFE block identity) and the not-run list, and a correction
of the plan's rev 1 commit message: f97cdf414's message says prek's first pass
"rewrote one Latin abbreviation", where that pass replaced "instance" with
"example" after "for" at the plan's line 561, a phrase the style hook rewrites
wherever it is spelled out (the planner's hand-off; the commit is never
amended). Before it is committed, bin/checktree.py (section 8 item 4) is run on
commit 2's tree, and r31.py and rumdl on this plan, the counts recorded in its
message. It adds headings to this plan only, recorded in its message (amended
2026-10-29, review fold: A-RA3-m5, B-M2, B-m2, where this read "the Status line
("rev 1 -- signed off" becomes the implementation's state, dated)" and "dry-run
first on a scratch copy of this plan by bin/dryrun.py's companion check (section
8 item 4)", a script that did not exist).

## §3 Commits and reviews

All on `claude/carbon-fork-0-1-safe` in /home/user/carbon-safe unless named
otherwise; NEW commits only, never amend, rebase or force-push (PR 53 is a
submitted PR, AGENTS.md); `--author='jmann345 <jerrymannstan@gmail.com>'` with
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`; explicit
paths only (R20); each message recording the prek fixpoint, the R31 counts
before and after, rumdl, the dry run and the nightly compiles, and ending after
a blank line with the session's two attribution trailers.

1.  **Dry run.** The implementer copies this plan's scripts, the rev 3 fixer's
    fixer1/bin/dryrun.py, checktree.py, pw.py and wrap.py (section 8 item 4;
    amended 2026-10-29, review fold: RR1-M1, where this named the rev 2 fixer's
    bin/, whose checktree.py checks rev 2's interim-rule sentence), to its own
    scratch, runs dryrun.py on a fresh `git archive` of the branch head over
    docs/design and fork/, reading the texts from this plan, with the
    placeholders filled at their real widths, and gets "ALL OK" before it edits
    the worktree; a FAIL stops it at a plan revision for a ruling, never a
    silent fix (amended 2026-10-29, review fold: B-M1, B-M2, where this read
    "copies this plan's bin/dryrun.py and wrap.py").
2.  **SAFE-3 (1/2): the built-in operator exemption re-derived from the safety
    argument (D-SAFE3-1 onward); SAFE-2's open findings folded.** Appendix A and
    B, the files of section 2.2, edited by Edit or Write only (R25), the JSON by
    Edit; then prek to a fixpoint and the checks of section 8, checktree.py on
    the committed tree among them.
3.  **SAFE-3 (2/2): records.** Section 2.3. After each commit on the branch
    from this plan's rev 1 on, every plan revision included, through the last
    records commit of step 6, the orchestrator advances the mirror over it,
    `git push origin <sha>:claude/carbon-fork-0-1-safe-wip` as a fast-forward
    (the mirror stood at f97cdf414, this plan's rev 1, on 2026-10-29, and at
    782a5b740, rev 2, when rev 3 was written), and confirms it with `git
    ls-remote origin claude/carbon-fork-0-1-safe-wip`, so that no unpushed
    commit is outside R29's safeguard (added 2026-10-29, review fold: B-M4;
    amended 2026-10-29, review fold: RR1-m2, where this read "After each SAFE-3
    commit on the branch, from commit 1", which left the plan's revisions
    outside the mirror).
4.  **Two whole-tree document reviews**, fresh agents, in parallel, read-only,
    over the whole tree at commit 2's head, not a diff range: every page commit
    1 and SAFE-2's commits touched and every safety page they restate,
    fork/safe/plan.md sections 0.3 and 1, the log's F-013 entry, W-144 to W-150,
    W-365, W-366 and the six items on PR 67's ledger, this plan and
    safe2-plan.md's marks. Reviewer A, fidelity to upstream's text and to the
    toolchain's behavior: every quote re-read at a freshly fetched tip by sha,
    PR 67's checks and this plan's 110 rows re-run (100 before rev 3), every
    claim about evaluation
    order, thunks, conversions, in-place initialization or value representation
    checked by a nightly probe (R30) or by upstream's checker source at the tip.
    Reviewer B, soundness of the safety argument and consistency of every copy:
    the noalias claim attacked by new probes, every probe of section 0.3 re-run,
    every copy of the rule compared word for word (the five places of A.0, the
    four short forms, B.1 in the log and fork/safe/plan.md), R31 and R27. Each
    finding graded BLOCKER, MAJOR or MINOR, with a file:line cite (R8) and a
    fix.
5.  **The fixer**, one fresh agent: reproduces every finding, dispositions each
    (ACCEPTED with where it lands, REJECTED with the refuting cite, R17), folds
    them by NEW commits marked "(amended <date>, SAFE-3 document-review fold:
    <id>)" on every copy the finding reaches, with a budget of TWO fix commits,
    records-only commits not counted; NO shrink line: a page-changing defect
    past the budget stops the workflow at a plan revision of this file for the
    orchestrator's ruling, and a finding that would soften a re-derived rule is
    never folded as such, only re-planned. Its records commit adds section 8.2.
6.  **The focused re-review**, TWO fresh agents per round, each over the range
    from commit 2 and over the whole tree's consistency, at most three rounds,
    until dry: dry is no BLOCKER and no MAJOR and every MINOR records-only,
    folded by one records commit. A round that is not dry goes back to step 5
    within its budget; a page-changing finding past the rounds or the budget
    stops at a plan revision. At round 3, a BLOCKER or MAJOR whose fix touches
    only records (this plan, the log, fork/safe/plan.md's records sections, the
    ledger or safe2-plan.md's marks, no page text) is folded by that round's
    records commit, checked by the dry run's checks and checktree.py, and ends
    the re-review dry when nothing else is open; one that touches a page stops
    at a plan revision. Each round's records commit adds a section 8.n (amended
    2026-10-29, review fold: B-m5).
7.  **The PR 67 note commit** (D-SAFE3-10, Appendix C.2), made by the
    implementer in a detached scratch worktree of 56e2e5bbd under
    /dev/shm/safe3-implementer/rg1, removed after, with `<head>` filled in;
    `check_quotes.sh` 284 and `check_greps.sh` 89 at the tip; r31.py's counts
    of fork/register/rg1-plan.md and fork/decision-log.md before the edit,
    after it and after each prek pass, unchanged; prek to a fixpoint over the
    touched files with a private cache, deleted after; `uvx rumdl@0.2.58 check`
    clean; `json.load` of the ledger; merge-treed against `<head>`, PR 68's
    head and trunk, the expected conflicts in the three records files resolved
    by the ledger rule and RG-1's log and ORCHESTRATION rules; reviewed by one
    fresh agent per round, at most three rounds, until dry, a finding open after
    round 3 stopping at a plan revision; not pushed by the implementer (amended
    2026-10-29, review fold: B-m5, where this read "reviewed by one fresh agent
    until dry").
8.  **The pushes**, by the orchestrator once steps 6 and 7 are dry: `<head>` as
    a fast-forward of 2407efa74, `git push origin
    <head>:claude/carbon-fork-0-1-safe`, then the note commit as a fast-forward
    of 56e2e5bbd, `git push origin <c2-sha>:claude/carbon-fork-0-1-rg1`; then
    `git ls-remote origin claude/carbon-fork-0-1-safe
    claude/carbon-fork-0-1-rg1` shows `<head>` and `<c2-sha>`, and a moved head
    stops the steps after this one (added 2026-10-29, review fold: B-M4).
9.  **The refreshes, the mirror's deletion and the stamp, in that order**: (a)
    the orchestrator refreshes PR 53's description (Appendix C.1, under the
    heading "SAFE-2 and SAFE-3 realignment (<date>)") and PR 67's (Appendix
    C.3), appended to each current description, and re-reads both (`gh pr view
    53 --json body` and `gh pr view 67 --json body`), each appended text found
    once; (b) it reads the mirror's head as `git ls-remote origin
    claude/carbon-fork-0-1-safe-wip` reports it then, checks that head is
    `<head>` or an ancestor of it (`git merge-base --is-ancestor <mirror head>
    <head>`), and deletes the mirror, `git push origin --delete
    claude/carbon-fork-0-1-safe-wip`, a mirror holding a commit `<head>` lacks
    stopping the step instead; (c) it stamps trunk's fork/ORCHESTRATION.md
    (Appendix D), whose texts record the deletion as done. The texts come from
    files the implementer writes with every placeholder filled:
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe3/impl/pr_53_refresh.md,
    .../safe3/impl/pr_67_refresh.md and .../safe3/impl/orchestration_stamp.md;
    no PR is merged, no workflow dispatched.
10. **The check after the stamp**: `git ls-remote origin` lists no
    `claude/carbon-fork-0-1-safe-wip`, PR 53's and PR 67's branches still hold
    `<head>` and `<c2-sha>`, and trunk's fork/ORCHESTRATION.md at the stamp
    holds Appendix D's six edits (amended 2026-10-29, review fold: A-RA3-m4,
    B-M4, where steps 9 and 10 read "The refreshes and the stamp" and "The
    mirror deleted: the orchestrator checks that the mirror's head 0f22798fb is
    an ancestor of `<head>` (`git merge-base --is-ancestor 0f22798fb <head>`)
    and deletes it, `git push origin --delete claude/carbon-fork-0-1-safe-wip`,
    as the stamp of step 9 records.", the deletion following the stamp that
    records it).

## §4 The worked-example matrix

"HEAD" is the outcome under the pages at 0f22798fb (SAFE-2's four fix commits);
"SAFE-3" is the outcome under D-SAFE3-3 to D-SAFE3-5 with the toolchain's
deviation standing, and "designed" the outcome once the toolchain adopts the
rewrite, where it differs; for a tuple, struct, array or class the "designed"
outcome is this design's reading of assignment.md:184, upstream's aggregate
order being open (assignment.md:159-164, leads issue 686; amended 2026-10-29,
review fold: A-RA3-M1). Every row of safe2-plan.md's section 4 was re-traced
operator by operator, again under rev 2's keying on types copy-represented at
every depth, whose change touches no example's outcome, every example's right
operand being a literal, a prelude call over literals or a scalar; none
changes:

| example | operators re-traced | SAFE-3 |
| --- | --- | --- |
| EX-M-1 `Fill`, EX-M-4a, EX-M-4b, EX-M-4c | `a->Set(0, 5)` is a method call; `a = 2` (`i32`, by copy); `a = Core.Buf(i32).Make(2, 0)` and `a.n = 2` on locals, literal operands | as safe2-plan.md section 4 |
| EX-M-4d `Peek`, `BufSize`, `Peek2`, `Peek4`, `Peek8` | `q->n = 2` (`i32`); `*q = "longer"` and `*q = {.s = "longer", .n = 1}`, literals only, so the interim rule exempts them and M3 decides | unchanged: `StrictSharedImmutableWrite` for `Peek2` and `Peek4` |
| EX-M-5, EX-M-6 | `*d = Core.Optional(i32*).None()`, copy-represented, a prelude call | unchanged: M3(c) |
| EX-TM-1, EX-TM-3, EX-TM-8, EX-TM-9 | `s = "def"`, `buf = Core.Buf(i32).Make(1, 0)`, `z = Core.Buf(i32).Make(5, 0)` on closed places with literal operands; `x += 1` on a `ref` | unchanged |
| initialization, spatial and slices examples | `x = 1`, `x = Core.Optional(i32).Some(1)`, `s = Core.Buf(i32).Make(2, 0)`, `total += s[i]`, `++i`, `a[2] = 30`, `total += x` | unchanged |
| `Core.Guarded`, EX-M-3, the union examples | `self->busy = true`, `*q = 1`, `u.n = 0x1234` | unchanged |

New rows, the probe shapes; a `StrictInvalidatingThroughShared` that rejects a
`Plain` type's operation, which neither of the message's first two forms
describes, takes A.23's third message form, and each such row says so (amended
2026-10-29, review fold: RR1-m3):

| program | HEAD | SAFE-3 (deviation standing) | designed | decided by |
| --- | --- | --- | --- | --- |
| swap on a local, `x = {.a = x.b, .b = x.a}`; the same through the owner of a `var` parameter, a `returned var` of a class and a class local (rev 3) | accepted, prints 2 2 (n03: 2 2, 4 4, 6 6) | `StrictExclusiveBorrowConflict` (T4, the interim rule's (ii) failing on the read through the owner; rev 2's (ii) exempted it, amended 2026-10-29, review fold: RR1-M1); remedy `let v: T = {...}; x = v;` prints 2 1 | accepted, 2 1 | v10, v24, s17, s10, n03 |
| swap through aliasing `T*` to a `Plain` struct, `*q = {.a = p->b, .b = p->a}` | accepted, 2 2 | `StrictInvalidatingThroughShared` (M3(d)), A.23's third message form | accepted, 2 1 | s03, s04, s05, s11 |
| the same for v09's class `C`, which is not `Plain` | `StrictInvalidatingThroughShared` (M3(c)) | the same | the same | v09 |
| `*q = *p` through shared pointers to a pointer-represented type, or to a one-element aggregate of one (rev 2), or to an adapter of either (rev 3) | accepted (a `Plain` struct) | `StrictBorrowFromShared` | the same | s03, s20, f01, n02 |
| `x = x` for such a type | accepted | `StrictBorrowedObjectMutated` | the same | s20 |
| swap inside a copy-represented one-element aggregate through aliasing `W*`, `*q = {.s = {.a = p->s.b, .b = p->s.a}}`, `W = {.s: {.a: i32, .b: i32}}`; the same for `((i32, i32),)` and `{.c: C}` (added 2026-10-29, review fold: A-RA3-B1) | accepted, 2 2 | `StrictInvalidatingThroughShared` (M3(d)), A.23's third message form for `W` and `((i32, i32),)`; `{.c: C}` also M3(c); the same for a class that adapts `W` (n01, rev 3); remedy: each element read into a local and assigned on its own (f04: 2 1) | accepted, 2 1 | ra01, ra04, ra05, f04, n01 |
| the same on a local, `y = {.s = {.a = y.s.b, .b = y.s.a}}` | accepted, 4 4 | `StrictExclusiveBorrowConflict` (T4) | accepted | ra01, ra04 |
| self-referential class assignment, `c = {.data = 42, .next = &c}` (added 2026-10-29, review fold: A-RA3-m6) | accepted | `StrictSharedBorrowInvalidated` (T4, the carrier `&c`); remedy `c.data = 42; c.next = &c;` | accepted | f03 |
| in-place call, `*q = {.a = 1, .n = F(p)}` | accepted | `StrictInvalidatingThroughShared`, A.23's third message form for a `Plain` struct; remedy: call first | accepted | w1, w2, w3, z1b |
| `c = Make(&c.a)` on a local | accepted | `StrictSharedBorrowInvalidated` | accepted | q06h |
| thunk conversion, `*q += e` with a user's `ImplicitAs(i32)` | accepted | `StrictInvalidatingThroughShared`, A.23's third message form naming the user's `Convert`; remedy `*q += e as i32` | the same | r3_thunk, a_p06, a_p13, q03, x1 |
| `*q = e` into an `i32` with a user's `ImplicitAs` | accepted | `StrictInvalidatingThroughShared` (D-SAFE3-4), A.23's third message form | the same | w4 |
| user `Copy` payload, `*q = v` holding `Optional(C)` | `StrictInvalidatingThroughShared` (M3(c), `Optional` is not `Plain`) | the same, and user-written | the same | z2 |
| user `Copy` of a class into `*q` | as M3(c) | user-written, `StrictInvalidatingThroughShared` | the same | a_p09, b_p5, s07 |
| `*q = {.x = e as i32, .y = e as i32}` with a user's `Convert` | accepted | `StrictInvalidatingThroughShared`, A.23's third message form; remedy: convert before the statement | accepted | q06c |
| `q->n = 2`, `p->n += 1`, `++p->n` through `T*` | accepted | accepted | accepted | q06f, a_p03, b_p12, s19 |

## §5 Scoreboard

No conformance program and no golden moves: SAFE-3 touches no file under
fork/conformance/, toolchain/, core/ or testdata. The two SKIP stubs
(safe_carbon_design.carbon, safety_strategy_doc.carbon) are untouched;
`python3 -I fork/conformance/runner.py --self-test` prints "self-test: 150
programs parsed, 56 bullets in table, OK" at 0f22798fb and must on each
commit's tree. Gap row 89 and the bullet are unchanged.

## §6 Churn and collisions

Measured on the rev 3 fixer's scratch commit f5487ba94 against 0f22798fb (`git
diff --numstat`, added and removed, the placeholders filled at their widths):
temporal_safety.md 281 and 107, mutation_safety.md 263 and 150,
safety/README.md 24 and 13, initialization_safety.md 2 and 2, spatial_safety.md
2 and 2, fork/decision-log.md 295 and 189, fork/safe/plan.md 338 and 200,
fork/inventory/work-items.json 30 and 2, fork/safe/safe2-plan.md 72 and 35
(amended 2026-10-29, review fold: B-M1, B-m2, where rev 1's figures were
34c19b364's with the placeholders unfilled, its wraps differing from the
filled ones; amended 2026-10-29, review fold: RR1-M1, RR1-m1, where rev 2's
were 3cff85911's, temporal_safety.md 277, the log 291 and fork/safe/plan.md 334
added). No
heading is added or renamed on any of those files, so no table of contents
moves. Collisions (section 0.7): none on a page; the records keep the merge
rules already recorded for PR 53 (the F-013 entry and its register block are
PR 53's own region of the log, merged at PR 53's landing by keeping both sides'
entries in newest-first order; the ledger merges by id, W-148, W-149, W-365 and
W-366 touched by no other head; fork/safe/ is PR 53's alone). The PR 67 note
commit's files and rules are safe2-plan.md section 6's.

## §7 Risks and rejected alternatives, each falsifiable

Risks:

-   **R-1 a Strict-accepted program in which another path reaches the
    referent while the `ref` lives.** Falsifier: such a program, by probe or by
    trace; the reviewers of section 3 step 4 attack the claim with new probes.
    Answered by narrowing D-SAFE3-3's conditions or the interim rule, never by
    a clause about who wrote the code.
-   **R-2 the interim `=` changes under the rule.** Falsifier: an upstream or
    fork commit that routes `=` through `AssignWith`, runs the old value's
    destructor at the `=` (handle_operator.cpp:119-120), initializes a
    copy-represented type in place (type_info.cpp:83-84), gives a tuple or
    struct of more than one element a copy representation
    (type_completion.cpp:576-577), routes `=` through `AssignWith` for some
    types only, or gives an unformed left operand assignment.md:102-106's direct
    initialization; W-366 and D-SAFE3-5's break conditions, each followed by a
    dated mark (amended 2026-10-29, review fold: A-RA3-B1, A-RA3-M1).
-   **R-3 upstream's `AssignWith` impls for the built-in types land with a
    shape other than the compound assignments'.** Falsifier: the prelude gains
    `AssignWith`; D-SAFE3-4's classification of `=`'s conversion follows it.
-   **R-4 leads issue 686 resolves aggregate assignment as in-place
    initialization of formed objects.** Falsifier: that resolution; the interim
    rule becomes the design's rule for those types (D-SAFE3-2's break
    condition).
-   **R-5 the cost is larger than D-SAFE3-12 states.** Falsifier: over the
    fork's examples and conformance programs read as Strict files, count the
    in-place `=` whose right operand reads the left operand's place, an open
    place or user code; more than the rows of section 4 means the pages
    under-state it, and the count is added by a dated edit. Measured by the
    fixer (D-SAFE3-12): none in the fork's programs, pages and examples, and
    two self-referential class assignments in upstream's toolchain testdata
    (amended 2026-10-29, review fold: A-RA3-m6, where this risk was left
    unmeasured).
-   **R-6 the nightly's struct-literal field order (s12c).** A literal that
    names fields out of order stores runtime values by position on
    the 2026.10.12 nightly; no probe this plan relies on has that shape, and a
    future probe of it is order-only evidence.

Rejected alternatives:

-   **(A) the value-representation keying as the design's rule.** Rejected
    (section 1.1): beyond upstream's text, under whose rewrite of
    assignment.md:184 the right operand is an argument formed before the call
    for every type it routes; it would reject `*q = {.n = 1, .m = 2}` for a
    `Plain` two-field struct through `T*` (s18's shape with a `Plain` type),
    which nothing but the call reaches, and outlive the deviation. Kept as the
    interim path's keying, on types copy-represented at every depth (RA3-B1).
    Falsifier: an upstream text that initializes assigned aggregates in place,
    leads issue 686 so resolved (R-4).
-   **(B) the element-wise model.** Rejected: it accepts v09 and v10 with a
    result of 2 2 that the right operand formed first gives as 2 1 (s11), a
    silent change of result when the toolchain adopts the rewrite for those
    types (amended 2026-10-29, review fold: A-RA3-M1, where this read "that the
    designed rule gives as 2 1 (s11), a second spelling of
    assignment.md:149-151 and a silent change of result", :149-151 covering
    scalars only). Falsifier: leads issue 686 resolved element-wise.
-   **Keeping a who-wrote-it test** (SAFE-2's rev 11 to rev 13). Rejected:
    v09, v10, v11, v14, v24 and v25 run no code written outside core/prelude
    and still read the referent through another path while it is bound
    (PRR3-B1). Falsifier: none; the test is refuted by those probes.
-   **Withdrawing the exemption entirely**, every write through `T*` needing
    `unsafe` or an `exclusive T*`. Rejected: `q->n = 2`, `p->n += 1` and
    `++p->n` would need a marker though nothing but the operation can reach
    the referent (s01, s02, s19), undoing M3(c)'s `Plain` writes through shared
    pointers that every safety page and section 4's `Peek`, `Core.Guarded` and
    EX-M-3 rows rest on. Falsifier: a probe in which such a write is observed
    through another path while bound.
-   **The eager copy**, the checker treating the interim `=` as if the right
    operand were copied first. Rejected: the toolchain does not copy (v09), so
    the model would describe semantics the binary does not have; Strict asks
    the program to form the right operand first instead (s10). Falsifier: a
    toolchain change that copies first, which is W-366's discharge.
-   **A Strict warning for the swap.** Rejected: a warning accepts a program
    whose `noalias` claim is false under the model and whose result changes
    with the rewrite; the error's remedy is one line (s10). Falsifier: upstream
    defining the in-place order as the meaning of `=`.

## §8 Verification

For commit 1, each fix commit and each records commit:

1.  R31 counts with `python3 -I
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5/bin/r31.py
    <file>` before the edit, after it and after each prek pass. Baseline at
    0f22798fb (headings by level, bullets, numbered items, rows, lines):
    safety/README.md H1 1 H2 15 H3 7, 70, 0, 47, 849; mutation_safety.md H1 1 H2
    16 H3 17, 73, 0, 60, 1533; temporal_safety.md H1 1 H2 19 H3 18, 113, 0, 49,
    1656; initialization_safety.md H1 1 H2 11 H3 11, 36, 0, 14, 595;
    spatial_safety.md H1 1 H2 12 H3 5, 55, 0, 22, 758; fork/safe/plan.md H1 1 H2
    16 H3 28 H4 2, 45, 28, 179, 3051; fork/decision-log.md H1 1 H2 2 H3 45 H4 1
    H5 6, 54, 0, 11, 8317; fork/safe/safe2-plan.md H1 1 H2 16 H3 134, 304, 36,
    359, 11760. Expected after commit 1, measured on the dry run with every
    placeholder filled at its real width (`2026-10-30`, nine-character shas):
    every heading, bullet, numbered and row count unchanged, the lines 860,
    1646, 1830, 595, 758, 3189, 8423 and 11797 (amended 2026-10-29, review fold:
    B-M1, where these were rev 1's 859, 1630, 1803, 595, 758, 3160, 8400 and
    11796, measured with the six-character `<date>`; amended 2026-10-29, review
    fold: RR1-M1, RR1-m1, where rev 2's were 1826, 3185 and 8419 for
    temporal_safety.md, fork/safe/plan.md and the log). Any other change is a
    defect of this plan: the implementer stops at a plan revision, never
    rephrasing reviewed text (amended 2026-10-29, review fold: B-M1, where this
    read "a defect to repair by rephrasing").
2.  `cd /home/user/carbon-safe && XDG_CACHE_HOME=<a private dir under the
    scratchpad's safe3/implementer/>
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <touched>` to a fixpoint, the cache deleted after
    (measured by the fixer on the filled dry tree, a detached scratch worktree
    of 0f22798fb: exit 0 and no file changed on each of three passes); the
    heading-line sets compared with `comm -13`, nothing new (amended 2026-10-29,
    review fold: B-m2, where this read "exit 0 with no change on the first pass,
    three passes").
3.  `uvx rumdl@0.2.58 check <touched>` exits 0 (measured on the filled dry
    tree: "Success: No issues found in 8 files").
4.  The dry run and the tree checker: the rev 3 fixer's
    /tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/safe3/fixer1/bin/dryrun.py
    `<tree> fork/safe/safe3-plan.md --fill --baseline <tree0>` on a fresh copy
    of the head's docs/design and fork/ (an archive, or a detached scratch
    worktree where prek must run), never the worktree of record, `<tree0>` being
    an archive of 0f22798fb; it reads every text from this plan, fills the
    placeholders with stand-ins of their real widths (bin/pw.py), checks that
    each anchor it uses is the one the plan's block states, applies every block
    with each anchor found once, and then runs bin/checktree.py, whose every
    check fails on a miss: r31.py's counts unchanged, no new hazard line (a
    blockquote line's content and a hyphen-space start included) and no new line
    over 80 columns outside code and tables, exactly ten RB-m3 hazards cleared,
    the D-SAFE block of the log identical to fork/safe/plan.md section 0.3, the
    clause of A.0 at its five places, the short form at its four, the
    interim-rule sentence at its four page and records copies and in W-148's
    note, the gloss of what qualifies on the temporal page, the definition of
    "copy-represented at every depth" on the temporal page, in the log, in
    fork/safe/plan.md and in W-148's note, none of rev 2's six superseded
    wordings of condition (ii), the gloss and the definition on any of the five
    pages and records files or in W-148's note (added 2026-10-29, review fold:
    RR1-M1, RR1-m1), the relation "The interim rule only adds conditions, so
    every program it accepts the rule above accepts" at its three, none of the
    three false statements of review B's M3, A.23's and B.22's message forms,
    the superseded phrases ("nothing else is evaluated", "lives for the one
    operation", "SAFE-2's PR 67 note commit", "exactly when nothing but the
    operand") each inside a quoted superseded text, `json.load` of the ledger
    with W-365 and W-366 last and W-366's notes stating the relation, and no
    placeholder of the fold left. bin/checktree.py `<tree> --baseline <tree0>`
    runs alone on any later commit's tree (each fix and records commit). The
    fixer's run on rev 2: "ALL OK", 184 steps and checks, filled, and "ALL OK"
    unfilled; prek and rumdl as items 2 and 3; checktree.py on 0f22798fb itself
    fails 31 checks, as it must (amended 2026-10-29, review fold: B-M1, B-M2,
    B-M3, where this named the planner's bin/dryrun.py, whose quoted-phrase and
    hazard-cleared checks only printed counts, whose own r31() and hard-coded
    anchors went untested, and which could not run on a later commit's tree).
    The rev 3 fixer's run, with fixer1/bin/checktree.py checking rev 3's
    sentence, gloss and definition: "ALL OK", 225 steps and checks, filled
    (fixer1/logs/dryrun-fill-1.txt), and "ALL OK", 216, unfilled; checktree.py
    alone on the filled tree "ALL OK", 136 checks; on 0f22798fb itself it fails
    36 checks, the five new ones among them (added 2026-10-29, review fold:
    RR1-M1, RR1-m1).
5.  The nightly compiles: the 14 example sources of safe2-plan.md section 0.7
    re-compiled (measured: the outcomes recorded there, EX-M-4a, EX-M-4c and
    EX-M-4d printing 1, p005434:152-162's `F` rejected and its variant printing
    3, EX-SP-3 and EX-TM-7 rejected, the rest compiling), and every probe of
    section 0.3 re-run with its recorded output. No page example changes.
6.  PR 67's quote and silence checks at a freshly fetched tip from a detached
    worktree of 56e2e5bbd under /dev/shm/safe3-implementer/rg1, removed after
    (273 and 89; the H1 subsets 97, 120 and 5; 284 and 89 with Appendix C.2's
    rows and H1.7), and this plan's 110 rows, the rev 3 fixer's
    fixer1/logs/safe3-quotes-all3.tsv (rev 1's 67, rev 2's 33 and rev 3's 10;
    amended 2026-10-29, review fold: RR1-m1, where this read "100 rows, the
    fixer's logs/safe3-quotes-all.tsv").
7.  `python3 -I fork/conformance/runner.py --self-test` clean (R7).
8.  `git merge-tree --write-tree --name-only <head> <held head>` for trunk and
    every held head, each set equal to section 0.7's.
9.  The id re-scan of section 0.8 repeated.
10. A case-insensitive grep for model names over the changed files and the
    messages, the pattern kept in the implementer's brief rather than in a
    file of the repository: nothing but the Co-Authored-By trailer.
11. `python3 -I -c "import json;
    json.load(open('fork/inventory/work-items.json'))"` after commit 1 and in
    the PR 67 note commit's worktree.
12. The D-SAFE block of fork/decision-log.md identical to fork/safe/plan.md
    section 0.3 (1217 lines at 0f22798fb, 1309 after commit 1, measured on the
    filled dry tree; rev 1's 1292 was before B.1 grew to 130 lines, and rev 2's
    1305 before it grew to 134, amended 2026-10-29, review fold: RR1-M1,
    RR1-m1).

Not run, and why: no build of any kind, and no upstream toolchain test (no
toolchain, prelude or golden changes; nothing may be built); no conformance run
beyond `--self-test` (no program changes; hosted runners are disabled, R28); no
probe of a Strict diagnostic, the checker being stage 4 (W-148) and the NEW
syntax parsing nowhere, so every Strict outcome in sections 1.3 and 4 is traced
by hand from the rules; no probe of `Core.Thread` (W-365's shape), which the
nightly lacks; no probe of `IndirectIndexWith` or slices, which the nightly's
prelude lacks; the nightly's three lowering crashes, s14b, ra02, n02's
lowering crash, its struct-literal field-order defect (s12c) and its `poison`
store after the in-place `=` of a copy-represented one-element aggregate or an
adapter of one (ra01, ra03 to ra06, f04, n01, n04), which this plan reports as
no evidence or as order-only evidence and does not file, leaving the decision
to the orchestrator (amended 2026-10-29, review fold: A-RA3-B1, A-RA3-m6, where
this list also named "no measurement of the cost count of risk R-5", which the
fixer measured, D-SAFE3-12; amended 2026-10-29, review fold: RR1-m1, n01, n02
and n04 added).

## Review fold record (rev 2, 2026-10-29)

The fixer folded the two plan reviews of rev 1 (f97cdf414): review A, fidelity
to upstream and to the toolchain, REJECT with RA3-B1, RA3-M1, RA3-M2 and RA3-m1
to RA3-m6; review B, soundness and consistency, APPROVE-WITH-AMENDMENTS with M1
to M4 and m1 to m6. Every finding was reproduced at its cite before it was
folded; none is rejected. Marks in this file read "(amended 2026-10-29, review
fold: A-<id>)" or "B-<id>"; the page and records texts of Appendix A and B
carry SAFE-3's own marks only, so no review id reaches a page. RA3-B1 changed
the model, not a clause: the interim rule's keying moved from the left
operand's own value representation to what the interim `=` initializes in
place, every type that is not copy-represented at every depth (section 0.0),
and with it D-SAFE3-3's condition (b), a copy that holds no borrowed object.

| finding | reproduced by | disposition and where it lands |
| --- | --- | --- |
| A RA3-B1 BLOCKER | ra01, ra04, ra05 re-run (2 2; 4 4; 2 2) and their IR; convert.cpp:283-297 and :400-405 and type_completion.cpp:572-578 read at 9192ee003; f02 shows a type copy-represented at every depth stored once; f01 the designed side | ACCEPTED: sections 0.0, 0.2, 0.3, 0.6, 1.1 (A) and the rule in words, D-SAFE3-2, D-SAFE3-3 (b), D-SAFE3-5 with its type_completion break condition, D-SAFE3-12, 1.3, 4, 7 (R-2, (A)); A.0, A.1, A.7, B.1, B.12, B.14 (W-366's evidence, notes and the nightly's `poison` store, also in section 0.3 and the not-run list) |
| A RA3-M1 MAJOR | assignment.md:86-87, :102-106, :113-120, :148-151, :159-164; pattern_matching.md:834-948; p005545:118-122, all at 9192ee003, no upstream commit since the cut | ACCEPTED: section 0.1's quotes and reading, 1.1 (B) and (C), D-SAFE3-2's label and break condition, D-SAFE3-5's label and its partial-adoption and direct-initialization break conditions, 1.3's s11 and s20 row, 4's "designed" column, 7 (R-2, (A), (B)); A.1, A.7, B.1, B.12, B.14, C.1, C.2, D block 4 |
| A RA3-M2 MAJOR | mutation_safety.md:835-844 and fork/safe/plan.md:1697-1699 read at 0f22798fb against section 4's `Plain` rows | ACCEPTED: D-SAFE3-6, section 0.5 and 0.6; A.23 and B.22 add a third message form naming what reaches the referent; no diagnostic added or renamed |
| A RA3-m1 | ra07 (`v` a value binding of `x`) against A.1's gloss | ACCEPTED: A.1's gloss and 1.3's row |
| A RA3-m2 | assignment.md:184 fixes no operand order; a_p07, b_p1 to b_p3 | ACCEPTED: D-SAFE3-2's label; A.1 "an order no upstream text fixes" |
| A RA3-m3 | p005434:859-864 at 9192ee003 | ACCEPTED: quoted in section 0.1; D-SAFE3-3 and 1.1 state (a) and (b) as the stricter criterion, sufficient and not necessary; "exactly when" becomes "when the checker establishes that" in A.0, A.1, A.3, A.7, A.9, A.19, B.1, B.5 to B.8, B.12, B.16, C.1, C.2 and D |
| A RA3-m4 | `git ls-remote origin`: the mirror at f97cdf414 | ACCEPTED: Status, section 0.7, step 9 (b) reads the mirror's head as reported then |
| A RA3-m5 | f97cdf414's message line 4 against the planner's rebuilt pre-prek text | ACCEPTED: section 2.3 schedules the correction in commit 2's section 8.1; recorded here too |
| A RA3-m6 | r5count.py over fork/conformance, docs/design/safety and examples/ (654 statements) and over toolchain testdata, core/ and docs/design/ (3185); f03 | ACCEPTED: D-SAFE3-12 lists the self-referential shape and its remedy, measures R-5; section 4's row; R-5 and the not-run list |
| B M1 MAJOR | the dry run with every placeholder filled at its width (fixer/bin/pw.py), then prek and rumdl on that tree | ACCEPTED: section 2.1's width rule; A.1, A.7, B.1, B.7, B.20 and B.21 rewrapped at the filled width, no line moving under prek; section 8 items 1 to 4 re-stated; "stop at a plan revision" |
| B M2 MAJOR | the planner's dryrun.py read: two checks only printed, own r31(), hard-coded anchors, no later-tree mode, no companion script | ACCEPTED: fixer/bin/dryrun.py and bin/checktree.py (section 8 item 4), every check failing on a miss, anchors checked against the plan, r31.py used, blockquote and hyphen-space starts tested; section 0.5, 2.3 and steps 1 and 2 |
| B M3 MAJOR | A.7, B.1, B.12 against A.1; A.1's, B.1's and W-366's relation sentences against section 4's `*q = *p` row | ACCEPTED: one interim-rule sentence at every copy (section 1.1, D-SAFE3-5, A.1, A.7, B.1, B.12), "an impl written outside core/prelude" in B.12, the relation as D-SAFE3-5 states it in A.1, B.1 and W-366, all checked by checktree.py |
| B M4 MAJOR | `git ls-remote origin`; steps 8 to 10 read | ACCEPTED: step 3 advances the mirror after each SAFE-3 commit; step 8 confirms the pushes; step 9 re-reads both descriptions, checks the mirror's reported head and deletes it before the stamp; step 10 checks after; Appendix D block 4 |
| B m1 | the cut's, the fork's and the tip's line numbers of the four functions; the fork's details.md; p005434:834-835; the re-run's aborts | ACCEPTED: section 0.2's first line, section 0.1 :834-835, B.1 and B.12 at 9192ee003, q04b named in section 0.3 |
| B m2 | the Status line; 34c19b364 against rev 1's texts; section 8 item 2 | ACCEPTED: section 2.3 quotes the Status sentence and schedules the message correction; scratch commit 3cff85911 regenerated from the plan (section 0.7, 6); item 2 re-stated |
| B m3 | `git grep` over fork/: three pointers to SAFE-2's note commit, plan.md:3047 and the log's :4281 and :4346-4347 | ACCEPTED: B.23, B.24 and B.25, the third beyond the two the review named |
| B m4 | trunk abdc798c6's fork/ORCHESTRATION.md:1070 | ACCEPTED: Appendix D block 2 keeps "the description refreshed" and the rulings |
| B m5 | steps 6 and 7 and D-SAFE3-10 read | ACCEPTED: step 6's round-3 records-only case, step 7's checks and round cap, D-SAFE3-10's break condition |
| B m6 | safe2-plan.md:5521-5528 | ACCEPTED: D-SAFE3-5's sentence, section 0.9's row and B.26's mark |

Measured for rev 2 on 2026-10-29: upstream re-fetched, tip 9192ee003, nothing
newer; the 18 held heads and trunk abdc798c6 as section 0.7 states them, the
mirror at f97cdf414; PR 67's checks from a detached worktree of 56e2e5bbd at
/dev/shm/safe3-fixer/rg1, removed after: 273 quotes and 89 silence checks, the
H1 subsets 97, 120 and 5, 284 and 89 with Appendix C.2's rows and H1.7, this
plan's 67, 33 and 100 rows, every one 0 failed; all 114 earlier probes re-run
identical, review A's seven re-run, four new probes, 125 in all; the dry run
"ALL OK" filled (184 steps and checks) and unfilled, prek's three passes
changing nothing, rumdl clean, r31.py's counts unchanged on the eight pages and
records files with the lines 860, 1646, 1826, 595, 758, 3185, 8419 and 11797;
the D-SAFE blocks identical at 1305 lines; `json.load` 134 items, W-365 and
W-366 last; the merge-trees of 3cff85911 equal to 0f22798fb's; `--self-test`
"150 programs parsed, 56 bullets in table, OK"; the id re-scan unchanged. Not
run: no build, no Strict checker (W-148), no probe of `Core.Thread`.

Correction of a records error: the planner's commit f97cdf414 says in its
message that prek's first pass "rewrote one Latin abbreviation"; that pass
replaced "instance" with "example" after "for" at the plan's line 561, the
phrase spelled apart here because the style hook rewrites it (the planner's
hand-off). The commit is not amended; commit 2's section 8.1 records the same
correction (section 2.3).

## Review fold record (rev 3, 2026-10-29)

The fixer of re-review round 1 folded the focused re-review, round 1, of rev 2
(782a5b740): APPROVE-WITH-AMENDMENTS, no new BLOCKER, one MAJOR (RR1-M1) and
three MINORs (RR1-m1 to RR1-m3). Of the earlier findings the re-review found
RA3-B1, RA3-M1, RA3-M2, review B's M1 to M4, RA3-m2 to RA3-m6 and review B's m1
to m6 resolved, and RA3-m1 not resolved, subsumed by RR1-M1, whose gloss now
resolves it. Its baseline: upstream tip 9192ee003, nothing newer, the rev 2
quotes matching at the tip; PR 67's checks from a detached worktree of 56e2e5bbd
at /dev/shm/safe2-rr1/rg1, 273, 89, the H1 subsets 97, 120 and 5, then 284
and 89, and this plan's 100 and 33, every one 0 failed; the 18 held heads and
trunk abdc798c6 as stated and the mirror at f97cdf414; rev 2's dryrun.py
`--fill` on a fresh archive of 0f22798fb "ALL OK", 184 checks, and checktree.py
failing 31 on the baseline; rumdl 0.2.58 clean; the R31 counts and the line
counts as section 8 item 1 then stated; `json.load` and `--self-test` OK; W-366
only in this plan over 167 refs. Its four probes, n01 to n04, are section 0.3's
last rows. Every finding was reproduced at its cite before it was folded; none
is rejected. Marks in this file read "(amended 2026-10-29, review fold:
RR1-<n>)"; the page and records texts of Appendix A and B carry SAFE-3's own
marks only. RR1-M1 showed the model unsound as written, the interim rule
exempting PRR3-B1's local shape, and it is folded as the model's own condition
stated over every path to the place, the owner and every carrier (section 0.0,
D-SAFE3-5's completeness sentence), not as a clause added beside it. The round
left a MAJOR, so rev 3 is not signed off and re-review round 2 decides; sign-off
needs a round with no BLOCKER and no MAJOR.

| finding | reproduced by | disposition and where it lands |
| --- | --- | --- |
| RR1-M1 MAJOR | n03 re-run in fixer1/probe/rr1/ (2 2, 4 4, 6 6; IR: load `x.1`, store `x.0`, load `x.0`, store `x.1`, and the same for the `returned var` and the class local); T3 at temporal_safety.md:508-510 and T1 at :420-421, read at 0f22798fb; the interim-rule sentence and the gloss at every copy | ACCEPTED: condition (ii) reads "reads or uses no part of the left operand's place, or of a place that overlaps it, through its owner or a carrier of it (T1, T3)" in section 1.1, D-SAFE3-5, A.1, A.7, B.1 and B.12, and fixer1/bin/checktree.py checks that sentence; the gloss reads "the body's closed places that do not overlap the left operand's place, values that carry no loan on it (T3)" in A.1 and section 1.3; D-SAFE3-5 states why (i) to (iii) cover every path; sections 0.0, 0.3 (n03), 0.6's T4 row, 1.3's rows, 4's local row and W-366's evidence (B.14) name the owner's read; the dry run re-run |
| RR1-m1 MINOR | n01 and n02 re-run, n02's SemIR dumped (`C`'s `Copy` called with `init %C to` the left operand's `(q as {.c: C}).c` and `self` from `(p as {.c: C}).c`); type_completion.cpp:762-770, :786-788 and :806-826 and convert.cpp:1467-1518 read at 9192ee003, at the cut and at 0f22798fb | ACCEPTED: "copy-represented at every depth" defined by representation, "copy-represented and, if its representation is a one-element tuple or struct's (the type, or an adapter, `const` or `MaybeUnformed` of one), its element is copy-represented at every depth", in D-SAFE3-5, A.1's first paragraph (its borrowed-object sentence, the fourth paragraph referring to it), B.1 and B.12, which checktree.py checks at four copies; convert.cpp:1467-1518 named in A.1, B.1, B.12 and W-366; sections 0.0, 0.2, 0.3 (n01, n02 and n04), 1.3 and 4; ten quote rows added, 110 in all |
| RR1-m2 MINOR | `git ls-remote origin`: the mirror at f97cdf414 at the review and at 782a5b740 when rev 3 was written; steps 3, 6, 8 and 9 (b) read | ACCEPTED: section 2.1 defines `<head>` as the head after the dry round's records commit; step 3 mirrors every commit from rev 1 on, the plan's revisions included; C.1 and Appendix D's first two blocks say "until dry, PR 53 then at `<head>`"; the Status and section 0.7 record the mirror's move |
| RR1-m3 MINOR | section 4's `Plain` rows against A.23 | ACCEPTED: section 4's introduction and its swap, one-element, in-place call, thunk, `*q = e` and `q06c` rows name A.23's third message form; records only |

Measured for rev 3 on 2026-10-29: upstream re-fetched, tip 9192ee003, nothing
newer; the 18 held heads and trunk abdc798c6 as section 0.7 states them, the
mirror at 782a5b740; PR 67's checks from a detached worktree of 56e2e5bbd at
/dev/shm/safe2-fixer1/rg1, removed after: 273 and 89, the H1 subsets 97, 120 and
5, 284 and 89, rev 3's 10 rows and the 110, every one 0 failed, the 10 failing
at the cut where their lines sit elsewhere; the re-review's four probes re-run,
129 in all; the dry run "ALL OK" filled (225 steps and checks) and unfilled
(216), checktree.py "ALL OK" alone (136 checks) and failing 36 on 0f22798fb;
on scratch commit f5487ba94 prek's three passes changing nothing, rumdl clean,
r31.py's counts unchanged on the eight pages and records files with the lines
860, 1646, 1830, 595, 758, 3189, 8423 and 11797, the D-SAFE blocks identical at
1309 lines, `json.load` 134 items, W-365 and W-366 last, and the merge-trees
against trunk and the 18 heads equal to 0f22798fb's; `--self-test` "150
programs parsed, 56 bullets in table, OK"; the id re-scan unchanged, no id
minted. This plan: r31.py before the fold H1 1, H2 16, H3 69, 55 bullets, 34
numbered items, 181 rows, 3293 lines, and after it H2 17 (this record), 57
bullets (one each in sections 0.2 and 0.4), 194 rows (four in section 0.3,
three in section 1.3 and the six lines of this record's table), the other
counts unchanged and no unguarded line; prek's first pass, its rumdl,
rewrapped two paragraph ends (section 0.3's opening and section 8 item 4) after
a long path line, the counts unchanged, and the next two passes changed
nothing; `uvx rumdl@0.2.58 check` clean, the unpinned 0.3.2 reporting only the
two long command lines of section 8 items 1 and 2 that rev 2 had too. Not run:
no build, no Strict checker (W-148), no probe of `Core.Thread`; n02's lowering
crashes on the nightly, its SemIR the evidence.

## Hand-off notes for the implementer

1.  Read section 1 first, then the blocks of Appendix A and B in order; re-open
    each file and find each anchor before editing; line numbers are
    0f22798fb's and move as earlier blocks of the same file land, so work from
    the bottom of each file up, or find each anchor again; B.8 goes in before
    B.23, whose rewrap moves B.8's anchor line, as bin/dryrun.py orders them
    (added 2026-10-29, review fold: B-m3).
2.  Markdown edits by Edit or Write only, never a shell append or a script
    (R25); the JSON by Edit, parsed after.
3.  Keep every superseded text byte for byte under section 2.1's test; the
    quotes in A.2, A.8 and B.1 are of 0f22798fb's lines and a reviewer diffs
    them.
4.  R31 and the style hook: never let a `#NN`, a list marker, `+`, `-`, `>` or
    a digit and a period start a prose line; write "PR 53", "proposal 5434" or
    "p005434"; no Latin abbreviation; headings never end in punctuation.
5.  Do not touch values.md, slices.md, rust_interop.md, type_safety.md,
    terminology.md, the stubs, the toolchain, the prelude or any golden; do not
    edit PR 65's branch, nor PR 67's except by the note commit of section 3
    step 7; push nothing, the orchestrator pushing at steps 3, 8 and 9 (the
    mirror's advance, the pushes and the mirror's deletion; amended 2026-10-29,
    review fold: B-M4, where this read "at steps 8 and 10"); do not open or
    edit a PR.
6.  Every count and cite in a message is measured on that commit's tree (R10);
    a moved anchor is reported, never silently taken.

## Appendix A. Page texts, verbatim (commit 1)

Paths are under docs/design/safety/ unless named; line numbers are 0f22798fb's.

### A.0 The D-SAFE-9 clause, five places

Words. The old words, then the new ones, at five places: temporal_safety.md's
D-SAFE-8 decision (:1488-1492, with A.4), mutation_safety.md's D-SAFE-9
decision (:1338-1343, A.10), fork/decision-log.md's D-SAFE-9 (:3269-3274),
fork/safe/plan.md section 0.3's D-SAFE-9 (:568-573, the first of the file's two
occurrences) and fork/safe/plan.md section 1.6 (:1644-1649, the second); the
same words at each (amended 2026-10-29, review fold: A-RA3-B1, A-RA3-m3: the
new words name the stricter criterion and a copy that holds no borrowed object,
where they read "that nothing but the operand can reach its referent while it
is bound for the operator's call, the impl's body, its thunk and the thunk's
conversions being code written in core/prelude reached through no symbolic
witness that an impl written outside core/prelude can fill and every other
operand a copy or a borrowed object's value binding under its frozen loan").

<!-- google-doc-style-ignore -->

```text
that its implementation is the language's own or an impl of an operator interface written in core/prelude that calls no impl written outside core/prelude while its `ref` operand is bound, M3 counting every assignment operator, compound assignment included, and `++` and `--` as an assignment to that operand (added 2026-10-29, re-review round 3: RR2-M1)

that the checker establishes that nothing but the operand can reach its referent while it is bound for the operator's call, by conditions stricter than that (p005434:859-864): the impl's body, its thunk and the thunk's conversions are code written in core/prelude reached through no symbolic witness that an impl written outside core/prelude can fill, and every other operand is a copy that holds no borrowed object or a borrowed object's value binding under its frozen loan, the toolchain's in-place `=` meeting that only under the interim rule of D-SAFE-8, M3 counting every assignment operator, compound assignment included, and `++` and `--` as an assignment to that operand (added 2026-10-29, re-review round 3: RR2-M1; re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, where this read "that its implementation is the language's own or an impl of an operator interface written in core/prelude that calls no impl written outside core/prelude while its `ref` operand is bound")
```

<!-- google-doc-style-resume -->

### A.1 temporal_safety.md, `ref` bindings, the second paragraph replaced by four

Lines. Replace :268-350, from the line "The `ref` operand of a built-in
operator is exclusive by construction." to the line that ends "fold:
R1-M1).", with the text below (amended 2026-10-29, review fold: A-RA3-B1,
A-RA3-M1, A-RA3-m1, A-RA3-m2, A-RA3-m3, B-M1, B-M3: the aggregate reading of
:184 labelled, the order labelled the toolchain's, a copy that holds no borrowed
object, the stricter criterion, the keying on types copy-represented at every
depth with convert.cpp:283-297, the interim rule in the one sentence every copy
carries, the gloss narrowed to values that carry no loan on the left operand's
place, the relation to the rule above stated as D-SAFE3-5 states it, and the
lines wrapped at the filled width of `<date>`; amended 2026-10-29, review fold:
RR1-M1, RR1-m1: the interim rule's second condition over the owner and every
carrier, where it read "uses no carrier of the left operand's place or of a
place that overlaps it", the gloss's closed places limited to those that do not
overlap the left operand's place, where it read "the body's closed places and
values that carry no loan on the left operand's place (T3)", "copy-represented
at every depth" defined in the first paragraph by representation, where that
paragraph read "a type that is not copy-represented binds one, and so does a
one-element tuple or struct whose element is not" and the fourth "one that is
not copy-represented or a one-element tuple or struct whose element is not
copy-represented at every depth", and the adapter case of convert.cpp:1467-1518
named):

<!-- google-doc-style-ignore -->

```markdown
The `ref` operand of a built-in operator is a `ref` binding under this section's
rule, bound for the operator's call. Proposal p005434 passes to a `ref`
parameter the first operand of the assignment operators and of `++` and `--`,
the operand of `&`, the object of member access and the first operand of
indexing (p005434:302-318), and the [assignment](../assignment.md#syntax)
design's first operand "is passed to a `(ref self: Self)` parameter" whatever
its form, "A dereference of a pointer" and "Member access naming a field" among
them (assignment.md:76-82). That design makes each such statement a call: "The
statement `x = y;` is rewritten to `x.(AssignWith(U).Op)(y);`"
(assignment.md:184), a compound assignment calls its interface's `Op`, and `++`
and `--` call `Inc` and `Dec`, each declared `fn Op(ref self, other: U);` or
`fn Op(ref self);` (assignment.md:176-177;
core/prelude/operators/arithmetic.carbon:30-37). For tuples, structs, choice
types and data classes it leaves the rules a TODO that points at leads
issue 686, "Operation order in struct/class assignment/initialization"
(assignment.md:159-164), while the initialization it mirrors is depth-first,
each element initialized in place before the next is evaluated (the
[pattern matching](../pattern_matching.md#evaluation-order) design's example,
pattern_matching.md:858-867 at 9192ee003), so applying :184 to them is this
design's reading, pending that issue. So the `ref` is bound when the call starts
and lives until it returns: the operands are evaluated before it, the left
operand's place and then the right operand, as the toolchain does for every
call-based operator, an order no upstream text fixes (fork/safe/safe3-plan.md
section 0.3), the left operand's place held across that evaluation by the loans
of the carriers it is reached through (T2, T3), and the call receives the right
operand complete, a copy that holds no borrowed object or a value binding of a
borrowed object, which holds a frozen loan for the call (the mutation page's
[Value bindings](mutation_safety.md#value-bindings)): it binds one unless its
type is copy-represented at every depth, a type being so when it is
copy-represented and, if its representation is a one-element tuple or struct's
(the type, or an adapter, `const` or `MaybeUnformed` of one), its element is
copy-represented at every depth. What runs while the `ref` is bound is the
impl's body, the thunk that the generics design generates for an impl whose
parameter types differ from the interface's, "Otherwise, a synthetic function
called a _thunk_ is generated:" (docs/design/generics/details.md:5769
at 9192ee003), whose body performs the "Implicit conversions ... as necessary to
initialize the parameters of the function in the `impl` from the parameters of
the thunk" (:5777-5778), and that thunk's conversions; the language's own `&`,
member access naming a field and indexing of an array form a reference
expression and run nothing.

Such an operand is exempt from the marker this section otherwise requires on an
open place when the checker establishes that no path but the operand can reach
its referent while it is bound: it is then established on any place, it forms no
loan of its own, neither the mutation page's M3(d) exclusive-receiver call nor
its M3(e) exclusive loan, the loans of the operation's result, `&x`'s and a
member access's sub-loan, being T2's, and M3 alone decides what the operation
may do through a shared path. The checker establishes that by two conditions,
the stricter criterion that p005434:859-864 says safe code will use, "But this
condition is hard to check, so safe code will use a stricter criteria.",
sufficient and not necessary, and in every program they accept p005434:83's
`noalias` holds by construction. First, everything that runs while the operand
is bound is code written in core/prelude, reached through no symbolic witness
that an impl written outside core/prelude can fill when a generic is called, and
trusted under S0 to reach the referent only through the operand: the builtin
`"int.sadd_assign"` (core/prelude/types/int.carbon:331) and its siblings for
`Int`, `UInt` and `Float`; `Inc`'s `self += AsInt(1);` (int.carbon:395-399) and
`self += AsUInt(1);` (uint.carbon:457-461), and `Dec`'s, whose witnesses no
library outside core/prelude can fill by the orphan rule
(docs/design/generics/details.md:4728-4736 at 9192ee003); the same impls of the
`CppCompat` integers, classes that adapt an integer
(core/prelude/types/cpp/int.carbon:16-38); and the thunks of the integers'
compound assignments, generic over `U: ImplicitAs(Int(N))` (int.carbon:329-331),
whose `fn Op(ref self, other: Self)` differs from the interface's
`fn Op(ref self, other: Other);` (arithmetic.carbon:31), when the thunk converts
a literal, another prelude integer or a value the program converted first,
`*q += e as i32`. Second, every other operand reaches the referent only as the
borrowed-object rule checks it: a copy that holds no borrowed object reaches
nothing, and a value binding of the referent itself, or a copy that holds one,
`x = x` for a class or `*q = *p` with `p` aliasing `q` for a class or for
`{.s: {.a: i32, .b: i32}}`, holds a frozen loan that the operation's write
breaks, `StrictBorrowedObjectMutated` on a closed place and, on an open place,
`StrictBorrowFromShared` unless the type is `Core.SharedImmutable`, whose write
through a shared path M3 rejects.

Any other operator is user-written: a thunk that runs an `ImplicitAs` written
outside core/prelude, or a prelude conversion that calls one such as
`const U as ImplicitAs(T)` (core/prelude/operators/as.carbon:46-48), an impl
written outside core/prelude, an impl or a conversion reached through a symbolic
witness that such an impl can fill, and the assignment design's default compound
assignment, `*self = *self $ other;` (assignment.md:302-316), wherever the
`AssignWith` or `OpWith` impl it calls is written outside core/prelude. Its
`ref self` is a `ref` binding under this section's rule: on a closed place a
checked reborrow, so T4 rejects `x += e` where `e.p` holds `&x`
(`StrictSharedBorrowInvalidated`), and through a shared path the mutation page's
M3(d) exclusive-receiver call, `StrictInvalidatingThroughShared`, the program
converting first. M3 counts every assignment operator, compound assignment
included, and `++` and `--` as an assignment to the first operand, so a built-in
operator on a type that is not `Core.Plain` is M3(c)'s through a shared path.
Two classifications are this design's, not the assignment design's text: the
conversion of `=`'s right operand, which "is implicitly converted to the type of
the left-hand operand" (assignment.md:149-150), counts as the compound
assignments' does, the prelude having no `AssignWith` impl yet; and the
assignment of tuples, structs, choice types and data classes, whose rules
assignment.md:159-161 leaves a TODO, is the language's own, member by member,
and user-written where a member's assignment is, a classification the interim
`=` below extends to every type with no `AssignWith` impl, an array or a class
that is not a data class among them.

Today's toolchain does not perform the rewrite for `=` (W-366). Its interim `=`
(toolchain/check/handle_operator.cpp:99-123 at 9192ee003, "TODO: Switch to using
assignment interface for most assignment") calls no `AssignWith` and initializes
the left operand from the right,
`rhs_id = InitializeExisting(context, node_id, lhs_id, rhs_id);` (:121): by copy
for a copy-represented type and in place for any other
(toolchain/sem_ir/type_info.cpp:82-89), a tuple or struct right operand
converted into the left operand one element at a time, each element into its own
part of the left operand even when the whole is copy-represented
(toolchain/check/convert.cpp:283-297 at 9192ee003), and an adapter of a tuple or
struct the same way, part by part (:1467-1518), each element's value acquired at
its own position, as [values](../values.md) allows (values.md:456-460 and
:604-607). So for a type that is not copy-represented at every depth, as the
first paragraph defines it, the right operand reads the left operand's place
after its initialization has begun, and a user's `Copy`, `ImplicitAs` or call
initialized in place runs while the left operand is written:
`*q = {.a = p->b, .b = p->a}` with `p` aliasing `q` prints 2 2 on the 2026.10.12
nightly toolchain, and so does `*q = {.s = {.a = p->s.b, .b = p->s.a}}` for
`{.s: {.a: i32, .b: i32}}`, where the right operand formed first prints 2 1
(fork/safe/safe3-plan.md section 0.3). For the integers, floating-point types,
`bool` and pointers that is a deviation from the assignment design by its own
TODO; for an aggregate, whose order that design leaves open, it differs from
this design's reading of the rewrite. No Carbon function's lowering carries
`noalias` today, so the difference gives a different defined result, not
undefined behavior. While it stands, Strict checks the interim `=` by what it
does as well as by the rule above: for a left operand whose type is not
copy-represented at every depth, the whole right operand counts as evaluated
while the left operand is bound, and the `=` keeps the exemption only when its
right operand reads no open place and passes no carrier of one to a call, reads
or uses no part of the left operand's place, or of a place that overlaps it,
through its owner or a carrier of it (T1, T3), and, on an open place, runs no
code written outside core/prelude; literals, the body's closed places that do
not overlap the left operand's place, values that carry no loan on it (T3), and
prelude calls over them qualify. Otherwise the `=` is a `ref` binding under this
section's rule: on a closed place a checked reborrow, so T4 rejects
`x = {.a = x.b, .b = x.a}` (`StrictExclusiveBorrowConflict`) and
`c = Make(&c.a)` (`StrictSharedBorrowInvalidated`), and through a shared path
M3(d)'s, so `*q = {.a = p->b, .b = p->a}` is `StrictInvalidatingThroughShared`;
the program forms the right operand first,
`let v: {.a: i32, .b: i32} = {.a = p->b, .b = p->a}; *q = v;`, which prints 2 1.
A left operand whose type is copy-represented at every depth, such as `i32`,
`{.n: i32}` or `Core.Optional(i32*)`, is stored once from a complete value, and
the rule above decides alone. The interim rule only adds conditions, so every
program it accepts the rule above accepts, and the toolchain's adoption of the
rewrite withdraws it by a dated mark with nothing newly rejected. So `q->n = 2`,
`p->n += 1` and `++p->n` for `q: T*` and a field `n: i32` are `Plain` writes
that M3 permits, and `*q = "longer"` for `q: str*` is
`StrictSharedImmutableWrite` (re-derived <date>, SAFE-3: D-SAFE3-1 to
D-SAFE3-5; until then this paragraph read as the one quoted in full at the end
of this section).
```

<!-- google-doc-style-resume -->

### A.2 temporal_safety.md, `ref` bindings, a blockquote at the section's end

Insert, paragraph: after the line "> R2-m2.)" (:410, the last line of SAFE-2's
"Realigned" blockquote, before "## Rules T1 to T8 and the Store rule"), a blank
line and:

<!-- google-doc-style-ignore -->

```markdown
> **Re-derived (fork amendment <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, F-013
> D-SAFE-8).** The second to fifth paragraphs of this section, the `ref` operand
> of a built-in operator, are re-derived from the safety argument by
> fork/safe/safe3-plan.md, after nightly probes showed four times that the
> operand does not live "for the one operation, during which nothing else is
> evaluated", the last time with no code written outside core/prelude: the
> toolchain's interim `=` reads its right operand after its in-place
> initialization has begun. The superseded paragraph, as SAFE-2's fix commits
> 0f281d8bd, cbdc0552e and 9d0b072cb left it, read: "The `ref` operand of a
> built-in operator is exclusive by construction. Proposal p005434 passes to a
> `ref` parameter the first operand of the assignment operators and of `++` and
> `--`, the operand of `&`, the object of member access and the first operand of
> indexing (p005434:302-318), and the [assignment](../assignment.md#syntax)
> design's first operand "is passed to a `(ref self: Self)` parameter" whatever
> its form, "A dereference of a pointer" and "Member access naming a field"
> among them (assignment.md:76-82). Where the operator's implementation is built
> in, that `ref` lives for the one operation and nothing else is evaluated while
> it does, so no other path observes the referent during it, on any place, open
> ones included: the checker establishes it with no marker, the `ref` forms no
> loan of its own, neither the mutation page's M3(d) exclusive-receiver call nor
> its M3(e) exclusive loan, the loans of the operation's result, `&x`'s and a
> member access's sub-loan, being T2's, and M3 alone decides what the operation
> may do through a shared path. An implementation is built in by where it is
> written, not by the type it serves: it is built in when it is the language's
> own, `&`, member access naming a field, indexing of an array or the
> toolchain's interim `=` that this paragraph classifies below, or an impl of an
> operator interface written in core/prelude whose body, while its `ref` operand
> is bound, calls no impl written outside core/prelude, whichever type it is
> for; any other is user-written, an impl written outside core/prelude among
> them. Each such prelude impl that takes a `ref` operand has a builtin body or
> one that calls only the prelude's own impls, so nothing user-written is
> evaluated while its `ref` lives: the impls "provided for built-in types as
> necessary to give the semantics described above" (assignment.md:168-170), the
> builtin `"int.sadd_assign"` (core/prelude/types/int.carbon:331) and `Inc`'s
> `self += AsInt(1);` (int.carbon:395-399, uint.carbon:457-461) among them, as
> much as the same impls of the `CppCompat` integers, classes that adapt an
> integer (core/prelude/types/cpp/int.carbon:16-38), `"int.sadd_assign"` again
> (:1011) and `Inc`'s `self += (1 as CppCompat.Long32);` (:1183-1187). A user's
> type may fill the `U` of their compound assignments, `U: ImplicitAs(Int(N))`
> (int.carbon:329-331), but its `ImplicitAs` runs when the caller converts the
> right operand to `other: Self`, before the call binds `ref self`, so those
> impls stay built in. The default compound assignment that the assignment
> design provides, `*self = *self $ other;` (assignment.md:302-316), calls the
> `AssignWith` and `OpWith` impls of the type it serves while `ref self` is
> bound, so it is user-written wherever one of those is written outside
> core/prelude, as for a user's class. The mutation page's M3 counts every
> assignment operator, compound assignment included, and `++` and `--` as an
> assignment to the first operand, so a built-in operator on a type that is not
> `Core.Plain` is M3(c)'s through a shared path. The
> [assignment](../assignment.md#built-in-types) design gives `=` to "Integers
> and floating-point types, `bool`, and pointer types" (assignment.md:148) and
> routes every `=` through `AssignWith`: "The statement `x = y;` is rewritten to
> `x.(AssignWith(U).Op)(y);`" (assignment.md:184), and "The type is still
> required to implement `AssignWith` for the assignment to be valid"
> (assignment.md:105-106), so there an assignment is classified by where its
> `AssignWith` impl is written. The toolchain's interim `=`
> (toolchain/check/handle_operator.cpp:99-123, "TODO: Switch to using assignment
> interface for most assignment") calls no `AssignWith`; counting it as the
> language's own on every type with no `AssignWith` impl, an array or a class
> that is not a data class among them besides the "Tuples, structs, choice
> types, and data classes" whose rules assignment.md:159-161 leaves a TODO, is
> this design's classification, not the assignment design's text: it calls no
> user-written `AssignWith`, any user-written `Copy` or `ImplicitAs` it runs to
> convert the right operand or initialize the left from it is checked under M3
> on every path it takes, a type that is not `Core.Plain` is M3(c)'s, and
> `Core.String`, a class whose fields are private
> (core/prelude/types/string.carbon:16-26) and which has no `AssignWith` impl,
> would otherwise be neither built in nor user-written (amended 2026-10-29,
> re-review round 2: RR1-m1, where this read "Where the operator's
> implementation is built in, the language's own or a prelude impl whose body is
> a builtin, such as `fn Op(ref self, other: Self) = "int.sadd_assign";`
> (core/prelude/types/int.carbon:331), that `ref` lives for the one operation"
> and "the checker establishes it with no marker, and the mutation page's M3
> alone decides"; amended 2026-10-29, re-review round 3: RR2-M1, RR2-m1, where
> this read "An implementation is built in when it gives a built-in type the
> semantics the [assignment](../assignment.md#built-in-types) design states, `=`
> on integers, floating-point types, `bool` and pointers, compound assignment on
> integers and floating-point types, and `++` and `--` on integers
> (assignment.md:146-157), the prelude's impls of those, "provided for built-in
> types as necessary to give the semantics described above"
> (assignment.md:168-170), counting as built in whatever their body, `Inc`'s
> `self += AsInt(1);` (core/prelude/types/int.carbon:395-399,
> uint.carbon:457-461) as much as
> `fn Op(ref self, other: Self) = "int.sadd_assign";` (int.carbon:331); when it
> is the assignment of a tuple, struct, array, choice type or class with no
> user-written `AssignWith` impl, whose rules assignment.md:159-161 leaves a
> TODO; and when it is the language's own `&`, member access naming a field or
> indexing of an array"). So `q->n = 2` for `q: T*` is a `Plain` write that M3
> permits, and `*q = "longer"` for `q: str*` is `StrictSharedImmutableWrite`.
> The `ref self` of a user-written impl of an operator interface is a `ref`
> binding under this section's rule, and its call through a shared path is
> M3(d)'s exclusive-receiver call, `StrictInvalidatingThroughShared` (amended
> 2026-10-28, document-review fold: R1-M1)."
```

<!-- google-doc-style-resume -->

### A.3 temporal_safety.md, the kinds paragraph's sentence

Words, at :189-192. The new words of A.3, A.9, A.19 and B.6 say "when the
checker establishes that", where rev 1's said "exactly when" (amended
2026-10-29, review fold: A-RA3-m3).

<!-- google-doc-style-ignore -->

```text
lives for the one operation and is established on any place, M3 deciding what the operation may do ([`ref` bindings](#ref-bindings); amended 2026-10-29, re-review round 2: RR1-M1)

is bound for the operator's call and is established on any place, M3 deciding what the operation may do, when the checker establishes that nothing but the operand can reach its referent while it is bound, the toolchain's in-place `=` meeting that only under the interim rule of D-SAFE-8 ([`ref` bindings](#ref-bindings); amended 2026-10-29, re-review round 2: RR1-M1; re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, where this read "lives for the one operation and is established on any place, M3 deciding what the operation may do")
```

<!-- google-doc-style-resume -->

### A.4 temporal_safety.md, the D-SAFE-8 decision's sentence

Words, at :1493-1495, after A.0 is applied at :1488-1492 of the same bullet.

<!-- google-doc-style-ignore -->

```text
lives for the one operation and is established on any place, M3 deciding what the operation may do (amended 2026-10-29, re-review round 2: RR1-M1)

is established on any place, M3 deciding what the operation may do (amended 2026-10-29, re-review round 2: RR1-M1; re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, where this read "lives for the one operation and is established on any place")
```

<!-- google-doc-style-resume -->

### A.5 temporal_safety.md, a rewrap of :84-85 (RB-m3)

Lines. Replace the 2 lines from "`Core.Lifetime`, named below, are D-SAFE-20
library residue and are not in the" to "0.1 prelude. Every pointer in today's
toolchain behaves as an unmarked", the words unchanged:

<!-- google-doc-style-ignore -->

```markdown
`Core.Lifetime`, named below, are D-SAFE-20 library residue and are not in
the 0.1 prelude. Every pointer in today's toolchain behaves as an unmarked
```

<!-- google-doc-style-resume -->

### A.6 temporal_safety.md, a rewrap of :997-998 (RB-m3)

Lines. Replace the 2 lines from "the stage that will). The examples marked
"today's syntax" were compiled on the" to "2026.10.12 nightly toolchain with
`carbon compile --output-last-input-only`,":

<!-- google-doc-style-ignore -->

```markdown
the stage that will). The examples marked "today's syntax" were compiled on
the 2026.10.12 nightly toolchain with `carbon compile --output-last-input-only`,
```

<!-- google-doc-style-resume -->

### A.7 mutation_safety.md, M3's built-in operator clause replaced

Lines. Replace :237-271, from the line that begins "require. An operator that
passes its operand to a `ref` parameter, an" to the line that ends "call of a
user-written impl's `ref self` is (d)'s").", with the text below (amended
2026-10-29, review fold: A-RA3-B1, A-RA3-M1, A-RA3-m3, B-M1, B-M3: the
interim rule given in A.1's one sentence, where this text left out "passes no
carrier of one to a call", "or of a place that overlaps it" and "the whole right
operand counts as evaluated while bound"; the stricter criterion, a copy that
holds no borrowed object, the keying at every depth and issue 686 named; the
lines wrapped at the filled width of `<date>`, so that no reflow starts a line
with `*self $ other;`; amended 2026-10-29, review fold: RR1-M1: A.1's sentence
with its second condition over the owner and every carrier, where it read
"uses no carrier of the left operand's place or of a place that overlaps
it"):

<!-- google-doc-style-ignore -->

```markdown
require. An operator that passes its operand to a `ref` parameter, an assignment
among them (the [assignment](../assignment.md#syntax) design's "a
`(ref self: Self)` parameter"), is a call whose `ref` is bound from the call's
start to its return, its other operands evaluated before it, and it is not a
call in (d)'s sense, nor its operand's `ref` an exclusive loan in (e)'s, when
the checker establishes that no path but that operand can reach the referent
while it is bound, by the two conditions that the temporal page's
[`ref` bindings](temporal_safety.md#ref-bindings) state, the stricter criterion
p005434:859-864 calls for: everything that runs then, the impl's body, the thunk
docs/design/generics/details.md:5769-5779 (at 9192ee003) generates for an impl
whose parameter types differ from the interface's and that thunk's conversions,
is code written in core/prelude reached through no symbolic witness that an impl
written outside core/prelude can fill, the prelude's own `Inc` and `Dec` among
them by the orphan rule, and every other operand reaches the referent only as M8
checks it, a copy that holds no borrowed object reaching nothing and a value
binding of the referent, or a copy that holds one, breaking its own frozen loan.
So the language's own `&`, member access naming a field and indexing of an
array, and the prelude's impls for `Int`, `UInt`, `Float` and the `CppCompat`
integers with a literal, another prelude integer or a value the program
converted first, are built in, and (a) to (c) and the next paragraph decide what
they may do through a shared path; a compound assignment whose thunk runs a
user's `ImplicitAs`, an impl written outside core/prelude,
assignment.md:302-316's default `*self = *self $ other;` for a user's class and
the assignment of an aggregate with a member whose assignment is user-written
are not, and their call is (d)'s, `StrictInvalidatingThroughShared` through a
shared path, the program converting first, `*q += e as i32`. The toolchain's
interim `=` (toolchain/check/handle_operator.cpp:99-123), which initializes its
left operand in place, in whole or in part, where the assignment design rewrites
`x = y;` to `x.(AssignWith(U).Op)(y);` (assignment.md:184), counts as the
language's own on a type with no `AssignWith` impl, an array or a class that is
not a data class among them, by this design's classification beside the
assignment design's "Tuples, structs, choice types, and data classes"
(assignment.md:159), whose order that design leaves to leads issue 686, and
while it stands it is checked by the temporal page's interim rule: for a left
operand whose type is not copy-represented at every depth, the whole right
operand counts as evaluated while the left operand is bound, and the `=` keeps
the exemption only when its right operand reads no open place and passes no
carrier of one to a call, reads or uses no part of the left operand's place, or
of a place that overlaps it, through its owner or a carrier of it (T1, T3), and,
on an open place, runs no code written outside core/prelude; otherwise the `=`
is (d)'s through a shared path, as `*q = {.a = p->b, .b = p->a}` is. This rule
counts every assignment operator, compound assignment included, and `++` and
`--` as an assignment to the first operand, in (c) and in the next paragraph
(re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5; until then this text
read as quoted in full at the end of this section).
```

<!-- google-doc-style-resume -->

### A.8 mutation_safety.md, a blockquote at M3's end

Insert, paragraph: after the line "at run time." (:321, the end of M3's escape
paragraph, before "### M4: Method classification by receiver"), a blank line
and:

<!-- google-doc-style-ignore -->

```markdown
> **Re-derived (fork amendment <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, F-013
> D-SAFE-9).** The built-in operator clause of this rule's first paragraph is
> re-derived from the safety argument by fork/safe/safe3-plan.md; the temporal
> page's [`ref` bindings](temporal_safety.md#ref-bindings) state the rule in
> full. The superseded clause, as SAFE-2's fix commits 0f281d8bd, cbdc0552e and
> 9d0b072cb left it, read: "An operator that passes its operand to a `ref`
> parameter, an assignment among them (the [assignment](../assignment.md#syntax)
> design's "a `(ref self: Self)` parameter"), is not a call in (d)'s sense when
> its implementation is built in, as the temporal page's
> [`ref` bindings](temporal_safety.md#ref-bindings) define it, the language's
> own, `&`, member access naming a field, indexing of an array or the
> toolchain's interim `=` on a type with no `AssignWith` impl, or an impl of an
> operator interface written in core/prelude whose body, while its `ref` operand
> is bound, calls no impl written outside core/prelude, whichever type it is
> for, the `CppCompat` integers' as much as `Int`'s, a user's type that fills
> their `U` being converted to `Self` before the `ref` is bound; the interim `=`
> (toolchain/check/handle_operator.cpp:99-123), where the assignment design
> rewrites `x = y;` to `x.(AssignWith(U).Op)(y);` (assignment.md:184), counts as
> the language's own on an array or a class that is not a data class by this
> design's classification and not by the assignment design's "Tuples, structs,
> choice types, and data classes" (assignment.md:159), and any user-written
> `Copy` or `ImplicitAs` it runs is checked under this rule on every path it
> takes; and this rule counts every assignment operator, compound assignment
> included, and `++` and `--` as an assignment to the first operand, in (c) and
> in the next paragraph: that section establishes its operand for the one
> operation, the operand's `ref` forms no loan of its own, neither (d)'s call
> nor (e)'s exclusive loan, and (a) to (c) and the next paragraph decide what it
> may do through a shared path, while the call of a user-written impl's
> `ref self`, an impl written outside core/prelude or a prelude impl that calls
> one while its `ref` operand is bound, assignment.md:302-316's default
> `*self = *self $ other;` for a user's class among them, is (d)'s (amended
> 2026-10-28, document-review fold: R1-M1; amended 2026-10-29, re-review round
> 2: RR1-m1, where this read "the language's own or a prelude impl whose body is
> a builtin: the temporal page's
> [`ref` bindings](temporal_safety.md#ref-bindings) establish its operand for
> the one operation, and (a) to (c)"; amended 2026-10-29, re-review round 3:
> RR2-M1, RR2-m1, where this read "the semantics the assignment design gives a
> built-in type with the prelude's impls of them whatever their body, an
> assignment of a tuple, struct, array, choice type or class with no
> user-written `AssignWith` impl, `&`, member access naming a field or indexing
> of an array" and "while the call of a user-written impl's `ref self` is
> (d)'s")."
```

<!-- google-doc-style-resume -->

### A.9 mutation_safety.md, M1's sentence

Words, at :174-176.

<!-- google-doc-style-ignore -->

```text
lives for the one operation and is established on any place, M3 deciding what the operation may do (amended 2026-10-29, re-review round 2: RR1-M1)

is bound for the operator's call and is established on any place, M3 deciding what the operation may do, when the checker establishes that nothing but the operand can reach its referent while it is bound, the toolchain's in-place `=` meeting that only under the interim rule of D-SAFE-8 (amended 2026-10-29, re-review round 2: RR1-M1; re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, where this read "lives for the one operation and is established on any place, M3 deciding what the operation may do")
```

<!-- google-doc-style-resume -->

### A.10 mutation_safety.md, the D-SAFE-9 decision's clause

Words, at :1338-1343: A.0's words, repeated here for the place.

<!-- google-doc-style-ignore -->

```text
that its implementation is the language's own or an impl of an operator interface written in core/prelude that calls no impl written outside core/prelude while its `ref` operand is bound, M3 counting every assignment operator, compound assignment included, and `++` and `--` as an assignment to that operand (added 2026-10-29, re-review round 3: RR2-M1)

that the checker establishes that nothing but the operand can reach its referent while it is bound for the operator's call, by conditions stricter than that (p005434:859-864): the impl's body, its thunk and the thunk's conversions are code written in core/prelude reached through no symbolic witness that an impl written outside core/prelude can fill, and every other operand is a copy that holds no borrowed object or a borrowed object's value binding under its frozen loan, the toolchain's in-place `=` meeting that only under the interim rule of D-SAFE-8, M3 counting every assignment operator, compound assignment included, and `++` and `--` as an assignment to that operand (added 2026-10-29, re-review round 3: RR2-M1; re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, where this read "that its implementation is the language's own or an impl of an operator interface written in core/prelude that calls no impl written outside core/prelude while its `ref` operand is bound")
```

<!-- google-doc-style-resume -->

### A.11 mutation_safety.md, M7, RB-M3's pointer

Insert after "or joins inside the borrow, the _thread-boundary lifetime rule_."
(:424):

<!-- google-doc-style-ignore -->

```markdown
As stated, that rule holds a loan that crosses into a scoped thread at the kind
it was formed with, so the spawning thread may still make a `Plain` write to a
place a `const T*` argument lets the scoped thread read, and a global, which
every thread reaches by name with no loan, is outside it: the stage 5 contract
this guarantee waits for gives a scoped API a frozen hold on every place its
arguments' loans reach until the join, an exclusive one through an
`exclusive T*`, and gives globals a rule, residue item W-365 (added <date>,
SAFE-3, the fold of SAFE-2's whole-tree review: RB-M3).
```

<!-- google-doc-style-resume -->

### A.12 mutation_safety.md, Data races and the facets, RB-M3's pointer

Insert after "and never into a detached one (EX-M-3)." (:578):

<!-- google-doc-style-ignore -->

```markdown
As stated, that rule holds a loan that crosses into a scoped thread at the kind
it was formed with, so the spawning thread may still make a `Plain` write to a
place a `const T*` argument lets the scoped thread read, and a global, which
every thread reaches by name with no loan, is outside it: the stage 5 contract
this guarantee waits for gives a scoped API a frozen hold on every place its
arguments' loans reach until the join, an exclusive one through an
`exclusive T*`, and gives globals a rule, residue item W-365 (added <date>,
SAFE-3, the fold of SAFE-2's whole-tree review: RB-M3).
```

<!-- google-doc-style-resume -->

### A.13 mutation_safety.md, the D-SAFE-16 decision, RB-M3's pointer

Insert after "with the thread-boundary lifetime rule (a free loan set or a
scoped join)." (:1360):

<!-- google-doc-style-ignore -->

```markdown
    As stated, that rule holds a loan that crosses into a scoped thread at the
    kind it was formed with, so the spawning thread may still make a `Plain`
    write to a place a `const T*` argument lets the scoped thread read, and a
    global, which every thread reaches by name with no loan, is outside it: the
    stage 5 contract this guarantee waits for gives a scoped API a frozen hold
    on every place its arguments' loans reach until the join, an exclusive one
    through an `exclusive T*`, and gives globals a rule, residue item W-365
    (added <date>, SAFE-3, the fold of SAFE-2's whole-tree review: RB-M3).
```

<!-- google-doc-style-resume -->

### A.14 mutation_safety.md, Value bindings, upstream's `IndirectIndexWith.Ref` (RA-m1)

Insert after "where an unbound `Ref` would leave `s` frozen on an element
reached through a free result and the call accepted.":

<!-- google-doc-style-ignore -->

```markdown
Upstream's prelude declares the interface with
`fn Ref(self, subscript: SubscriptType) -> ref ElementType;` and no `bound`
(core/prelude/operators/index.carbon:14-17 at 9192ee003, added by
upstream's 6d80ceb58 after the fork's cut, so that this tree's prelude has it
once PR 65 lands), so W-144's `bound self` at the interface changes upstream's
signature, in upstream's own shape for a `ref`-returning operator interface,
`Deref`'s `fn Op[bound ref self: Self]() -> ref Result;` (p005434:952-960; added
<date>, SAFE-3, the fold of SAFE-2's whole-tree review: RA-m1).
```

<!-- google-doc-style-resume -->

### A.15 mutation_safety.md, Value bindings, the `bool` exclusion (RA-m2)

Words, in the bullet "A copy-represented type holds no loan" (:608-610).

<!-- google-doc-style-ignore -->

```text
an adapter, `const T` and `MaybeUnformed(T)` of a copy-represented `T` other than `bool` take the representation of the type they wrap (:762-770, :783-789, :803-826)

an adapter and `const T` take the representation of the type they wrap (:762-770, :783-789), and `MaybeUnformed(T)` is copy-represented exactly when `T` is, with a copy that is its object representation, and is not `bool` (:803-826; amended <date>, SAFE-3, the fold of SAFE-2's whole-tree review: RA-m2, where this read "an adapter, `const T` and `MaybeUnformed(T)` of a copy-represented `T` other than `bool` take the representation of the type they wrap")
```

<!-- google-doc-style-resume -->

### A.16 mutation_safety.md, a rewrap of :96-100 (RB-m3)

Lines. Replace the 5 lines from "functions `Peek`, `Peek2` and `Peek4` of
EX-M-4d, were compiled and run on the" to "M5 and M8, and the sections they
cite, were realigned 2026-10-28 by fork":

<!-- google-doc-style-ignore -->

```markdown
functions `Peek`, `Peek2` and `Peek4` of EX-M-4d, were compiled and run on
the 2026.10.12 nightly toolchain and their outcomes are stated with them
(EX-M-4c and EX-M-4d added 2026-10-28, SAFE-2: W-348). File and line citations
are against trunk 0bdce60a5 unless a citation says otherwise. Rules M1, M2, M3,
M4, M5 and M8, and the sections they cite, were realigned 2026-10-28 by fork
```

<!-- google-doc-style-resume -->

### A.17 mutation_safety.md, a rewrap of :895-901 (RB-m3)

Lines. Replace the 7 lines from "on the 2026.10.12 nightly toolchain with
`carbon compile" to "record of [fork/safe/plan.md](/fork/safe/plan.md).":

<!-- google-doc-style-ignore -->

```markdown
on the 2026.10.12 nightly toolchain with `carbon
compile --output-last-input-only` and no `package` line, then linked and run
(EX-M-4c and EX-M-4d added 2026-10-28, SAFE-2: W-348); EX-M-4b and EX-M-4d's
`BufSize` and `Peek8` use the fork prelude's `Core.Buf`, which that toolchain
lacks; every other example is NEW syntax. Prelude names are `Core.`-qualified
throughout. Tags of the form A-n, B-n and RR-n in example comments index the
review-fold record of [fork/safe/plan.md](/fork/safe/plan.md).
```

<!-- google-doc-style-resume -->

### A.18 mutation_safety.md, the overview, RB-M3's pointer

Insert after "this design prevents all races between Carbon-spawned threads,
which that section also permits." (:127-128):

<!-- google-doc-style-ignore -->

```markdown
As M7 states, that guarantee waits for the stage 5 thread contract, which must
still close two gaps, a `Plain` write by the spawning thread to a place that a
`const T*` argument lets a scoped thread read and a global, which every thread
reaches by name with no loan, residue item W-365 (added <date>, SAFE-3, the fold
of SAFE-2's whole-tree review: RB-M3).
```

<!-- google-doc-style-resume -->

### A.19 safety/README.md, the kinds paragraph's sentence

Words, at :460-463.

<!-- google-doc-style-ignore -->

```text
lives for the one operation and is established on any place, M3 deciding what the operation may do ([Temporal safety](temporal_safety.md), `ref` bindings; amended 2026-10-29, re-review round 2: RR1-M1)

is bound for the operator's call and is established on any place, M3 deciding what the operation may do, when the checker establishes that nothing but the operand can reach its referent while it is bound, the toolchain's in-place `=` meeting that only under the interim rule of D-SAFE-8 ([Temporal safety](temporal_safety.md), `ref` bindings; amended 2026-10-29, re-review round 2: RR1-M1; re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, where this read "lives for the one operation and is established on any place, M3 deciding what the operation may do")
```

<!-- google-doc-style-resume -->

### A.20 safety/README.md, the data-race paragraph, RB-M3's pointer

Insert after the last sentence of the paragraph that begins "The fork design
(2026-10-12, F-013) prevents all data races", which ends `which this section
permits; see [Mutation safety](mutation_safety.md).`:

<!-- google-doc-style-ignore -->

```markdown
That guarantee waits for the thread API's lifetime contract at stage 5, and as
stated it is not yet complete: the spawning thread may still make a `Plain`
write to a place that a `const T*` argument lets a scoped thread read, and a
global, which every thread reaches by name with no loan, is outside the
thread-boundary lifetime rule; residue item W-365 gives that contract a frozen
hold until the join and globals a rule (added <date>, SAFE-3, the fold of
SAFE-2's whole-tree review: RB-M3).
```

<!-- google-doc-style-resume -->

### A.21 initialization_safety.md, a rewrap of :321-322 (RB-m3)

Lines. Replace the 2 lines from "the stage that will). The examples marked
"today's syntax" were compiled on the" to "2026.10.12 nightly toolchain with
`carbon compile --output-last-input-only`":

<!-- google-doc-style-ignore -->

```markdown
the stage that will). The examples marked "today's syntax" were compiled on
the 2026.10.12 nightly toolchain with `carbon compile --output-last-input-only`
```

<!-- google-doc-style-resume -->

### A.22 spatial_safety.md, a rewrap of :684-685 (RB-m3)

Lines. Replace the 2 lines from "    first, fail-stop bounds, zero-fill and
division-by-zero fail-stop as the" to "    0.1 deliverable, with annotated
borrows later. Judge 1 found that C "is":

<!-- google-doc-style-ignore -->

```markdown
    first, fail-stop bounds, zero-fill and division-by-zero fail-stop as the 0.1
    deliverable, with annotated borrows later. Judge 1 found that C "is
```

<!-- google-doc-style-resume -->

### A.23 mutation_safety.md, the message texts, a third form of `StrictInvalidatingThroughShared`

Insert after "with the same suggestion. A note points at the receiver's
declaration." (:843-844, the end of the `StrictInvalidatingThroughShared`
bullet), D-SAFE3-6's dependent line: the bullet's two forms name a
"non-`Plain` type" and a "`ref self` method", false for SAFE-3's new rejections
of `Plain` types (added 2026-10-29, review fold: A-RA3-M2):

<!-- google-doc-style-ignore -->

```markdown
For a built-in operator's `ref` operand that is not exempt (the temporal page's
[`ref` bindings](temporal_safety.md#ref-bindings)), whatever the operand's type,
`Core.Plain` ones included, the text reads "operator `{0}` binds its `ref`
operand `{1}` through shared pointer `{2}` while `{3}` can reach it; form the
right operand first, use an `exclusive` pointer, `Core.Guarded`, or `unsafe`",
`{3}` naming what reaches the referent while the operand is bound, the open
place the right operand reads, the carrier it passes or the code written outside
core/prelude that runs, so that `*q = {.a = p->b, .b = p->a}` reads "operator
`=` binds its `ref` operand `*q` through shared pointer `q` while `p->b` can
reach it" and `*q += e` with a user's `ImplicitAs(i32)` names that impl's
`Convert` (added <date>, SAFE-3: D-SAFE3-6).
```

<!-- google-doc-style-resume -->

## Appendix B. Records texts, verbatim (commit 1)

Line numbers are 0f22798fb's. A block that names both fork/decision-log.md and
fork/safe/plan.md section 0.3 is applied to each with the same words, so that
the two D-SAFE blocks stay identical (section 8 item 12).

### B.1 D-SAFE-8's operator clause, the log and fork/safe/plan.md section 0.3

Lines. In fork/decision-log.md (:3131-3190) and in fork/safe/plan.md (:430-489),
replace the 60 lines from the line that begins "Permissive as
`PermissiveAliasedExclusive`. The `ref` operand of a" to the line that ends "A
`ref` return is not a binding, so p005434:717-720", each found once in each
file, with the 134 lines below, the same in both files. The superseded text is
quoted whole after "which SAFE-2's fix commits 0f281d8bd, cbdc0552e and
9d0b072cb wrote, read:" (D-SAFE3-7). Amended 2026-10-29, review fold: A-RA3-B1,
A-RA3-M1, A-RA3-m3, B-M1, B-M3, B-m1: the first 67 lines, up to "(re-derived
<date>,", carry the aggregate reading of :184, a copy that holds no borrowed
object, the stricter criterion, details.md cited at 9192ee003, the interim rule
in A.1's sentence and its relation to the rule above as D-SAFE3-5 states it,
where rev 1's 56 said "a copy when its type is copy-represented", "exactly
when", "for such a type the whole right operand counts as evaluated while bound"
and "The interim rule rejects only what the rule above accepts"; the quoted
superseded text after them is rev 1's, unchanged. Amended 2026-10-29, review
fold: RR1-M1, RR1-m1: those lines, 71 now, carry A.1's sentence with its second
condition over the owner and every carrier, where it read "uses no carrier of
the left operand's place or of a place that overlaps it", the definition of
"copy-represented at every depth" by representation, where they read "which a
type that is not copy-represented holds and so does a one-element aggregate
whose element is not", and convert.cpp:1467-1518's adapter case; rev 2 replaced
the 60 lines with 130:

<!-- google-doc-style-ignore -->

```markdown
    Permissive as `PermissiveAliasedExclusive`. The `ref` operand of a built-in
    operator — the first operand of assignment, of the compound assignments and
    of `++` and `--`, the operand of `&`, the object of member access and the
    first operand of indexing, which p005434:302-318 passes to a `ref` parameter
    and assignment.md:76-82 to "a `(ref self: Self)` parameter" whatever its
    form, a dereference of a pointer included — is bound for the operator's
    call: assignment.md:184 rewrites `x = y;` to `x.(AssignWith(U).Op)(y);`,
    applied to an aggregate by this design's reading while assignment.md:159-164
    leaves the aggregate order to leads issue 686, and each compound assignment
    and `++` and `--` is likewise a call of its interface's `Op`, so the
    operands are evaluated first and the call receives the right operand
    complete, a copy that holds no borrowed object or a borrowed object's value
    binding under D-SAFE-17's frozen loan, the latter unless its type is
    copy-represented at every depth, a type being so when it is copy-represented
    and, if its representation is a one-element tuple or struct's (the type, or
    an adapter, `const` or `MaybeUnformed` of one), its element is
    copy-represented at every depth. It is established on any place, open ones
    included, forms no loan of its own, neither D-SAFE-9's (d) nor its (e), and
    D-SAFE-9's M3 alone decides what the operation may do through a shared path,
    when the checker establishes, by two conditions stricter than that property
    (p005434:859-864), that nothing but the operand can reach its referent while
    it is bound: everything that runs then, the impl's body, the thunk
    docs/design/generics/details.md:5769-5779 at 9192ee003 generates for an impl
    whose parameter types differ from the interface's and that thunk's
    conversions, is code written in core/prelude reached through no symbolic
    witness that an impl written outside core/prelude can fill (the prelude's
    `Inc` and `Dec` included by the orphan rule, details.md:4728-4736
    at 9192ee003), and every other operand reaches the referent only as
    D-SAFE-17 checks, a copy that holds no borrowed object reaching nothing and
    a value binding of the referent, or a copy that holds one, breaking its own
    frozen loan (`StrictBorrowedObjectMutated`, or `StrictBorrowFromShared` on
    an open place unless the type is `Core.SharedImmutable`). So `&`, member
    access naming a field, indexing of an array and the prelude's impls for the
    integer and floating-point types with a literal, another prelude integer or
    a value the program converted first are built in; a thunk that runs a user's
    `ImplicitAs` (int.carbon:329-331's compound assignments over
    `U: ImplicitAs(Int(N))`, or a prelude conversion that calls one), an impl
    written outside core/prelude and assignment.md:302-316's default
    `*self = *self $ other;` wherever its `AssignWith` or `OpWith` impl is are
    user-written, a `ref` binding under this rule: a checked reborrow on a
    closed place and D-SAFE-9's (d) through a shared path, the program
    converting first (`*q += e as i32`). Classifying `=`'s conversion as the
    compound assignments' and the assignment of tuples, structs, choice types
    and data classes (assignment.md:159-161, a TODO) as the language's own,
    member by member, extended to every type with no `AssignWith` impl, is this
    design's. The toolchain's interim `=`
    (toolchain/check/handle_operator.cpp:99-123) differs from the rewrite
    (W-366): it initializes its left operand from the right
    (`InitializeExisting`, :121), in place for a type that is not
    copy-represented (toolchain/sem_ir/type_info.cpp:82-89) and element by
    element, each element into its own part of the left operand even when the
    whole is copy-represented, an adapter of a tuple or struct the same way
    (toolchain/check/convert.cpp:283-297 and :1467-1518; values.md:604-607), so
    its right operand reads the left operand after the initialization has begun
    (`*q = {.a = p->b, .b = p->a}` with `p == q` gives 2 2 where the right
    operand formed first gives 2 1), a different defined result while no
    `noalias` is emitted. While that stands, for a left operand whose type is
    not copy-represented at every depth, the whole right operand counts as
    evaluated while the left operand is bound, and the `=` keeps the exemption
    only when its right operand reads no open place and passes no carrier of one
    to a call, reads or uses no part of the left operand's place, or of a place
    that overlaps it, through its owner or a carrier of it (T1, T3), and, on an
    open place, runs no code written outside core/prelude; otherwise it is a
    checked reborrow on a closed place (T4: `x = {.a = x.b, .b = x.a}` is
    `StrictExclusiveBorrowConflict`, `c = Make(&c.a)`
    `StrictSharedBorrowInvalidated`) and D-SAFE-9's (d) through a shared path,
    the program forming the right operand first (`let v: T = ...; *q = v;`). A
    left operand whose type is copy-represented at every depth is stored once
    from a complete value. The interim rule only adds conditions, so every
    program it accepts the rule above accepts, and adopting the rewrite
    withdraws it (re-derived <date>,
    SAFE-3: D-SAFE3-1 to D-SAFE3-5; fork/safe/safe3-plan.md; the superseded
    text, from "The `ref` operand of a built-in operator — the first operand"
    through "naming a field and indexing of an array")", which SAFE-2's fix
    commits 0f281d8bd, cbdc0552e and 9d0b072cb wrote, read: "The `ref` operand
    of a built-in operator — the first operand of assignment, of the compound
    assignments and of `++` and `--`, the operand of `&`, the object of member
    access and the first operand of indexing, which p005434:302-318 passes to a
    `ref` parameter and assignment.md:76-82 to "a `(ref self: Self)` parameter"
    whatever its form, a dereference of a pointer included — lives for the one
    operation, during which nothing else is evaluated, so where the
    implementation is built in it is established on any place, open ones
    included, forms no loan of its own, neither D-SAFE-9's (d) nor its (e), and
    D-SAFE-9's M3 alone decides what the operation may do through a shared path;
    a user-written impl's `ref self` is a `ref` binding under this rule and its
    call D-SAFE-9's (d) (amended 2026-10-28, document-review fold: R1-M1:
    without it every `Plain` write through `T*` that M3 permits was
    `StrictRefFromShared`). Built in is decided by where an implementation is
    written, not by the type it serves: the language's own `&`, member access
    naming a field and indexing of an array, the toolchain's interim `=` below,
    and every impl of an operator interface written in core/prelude whose body,
    while its `ref` operand is bound, calls no impl written outside
    core/prelude, whichever type it is for, each of the prelude's that takes a
    `ref` operand having a builtin body or one that calls only the prelude's own
    impls (the impls :168-170 says are "provided for built-in types as necessary
    to give the semantics described above", int.carbon:331's `"int.sadd_assign"`
    and :395-399's `Inc` as much as cpp/int.carbon:1011's `"int.sadd_assign"`
    and :1183-1187's `Inc` for the `CppCompat` integers, classes that adapt an
    integer, :16-38), and a user's type that fills their `U`
    (int.carbon:329-331, `U: ImplicitAs(Int(N))`) being converted to
    `other: Self` before `ref self` is bound; any other impl is user-written,
    assignment.md:302-316's default `*self = *self $ other;` among them wherever
    the `AssignWith` or `OpWith` impl it calls is written outside core/prelude.
    D-SAFE-9's M3 counts every assignment operator, compound assignment
    included, and `++` and `--` as an assignment to the first operand.
    assignment.md:184 has "The statement `x = y;` is rewritten to
    `x.(AssignWith(U).Op)(y);`" and :105-106 "The type is still required to
    implement `AssignWith` for the assignment to be valid", so there an
    assignment is classified by where its `AssignWith` impl is written; the
    toolchain's interim `=` (toolchain/check/handle_operator.cpp:99-123) calls
    none, and counting it as the language's own on every type with no
    `AssignWith` impl, an array or a class that is not a data class among them
    besides :159's "Tuples, structs, choice types, and data classes", whose
    rules :161 leaves a TODO, is this design's classification, not that text: it
    calls no user-written `AssignWith`, any user-written `Copy` or `ImplicitAs`
    it runs is checked under D-SAFE-9's M3 on every path it takes, a non-`Plain`
    type's assignment is D-SAFE-9's (c), and `Core.String`, whose fields are
    private (string.carbon:16-26) and which has no `AssignWith` impl, would
    otherwise be neither built in nor user-written (amended 2026-10-29,
    re-review round 2: RR1-m1, where this read "where the implementation is the
    language's own or a prelude impl whose body is a builtin (int.carbon:331's
    `"int.sadd_assign"`) it is established on any place, open ones included, and
    D-SAFE-9's M3 alone decides"; amended 2026-10-29, re-review round 3: RR2-M1,
    RR2-m1, where this read "Built in is the semantics assignment.md:146-157
    gives the built-in types, `=` on integers, floating-point types, `bool` and
    pointers, compound assignment on integers and floating-point types, and `++`
    and `--` on integers, the prelude's impls of them counting as built in
    whatever their body (the impls :168-170 says are "provided for built-in
    types as necessary to give the semantics described above";
    int.carbon:395-399's `Inc` as much as :331's `"int.sadd_assign"`); the
    assignment of a tuple, struct, array, choice type or class with no
    user-written `AssignWith` impl (assignment.md:159-161, a TODO upstream); and
    the language's own `&`, member access naming a field and indexing of an
    array")"). A `ref` return is not a binding, so p005434:717-720
```

<!-- google-doc-style-resume -->

### B.2 D-SAFE-16, the log and fork/safe/plan.md section 0.3, RB-M3's pointer

Insert, in fork/decision-log.md (:3758) and in fork/safe/plan.md (:1057), after
"a local `x` is rejected (program `Race` in §4.1).", found once in each:

<!-- google-doc-style-ignore -->

```markdown
    As stated, that rule holds a loan that crosses into a scoped thread at the
    kind it was formed with, so the spawning thread may still make a `Plain`
    write to a place a `const T*` argument lets the scoped thread read, and a
    global, which every thread reaches by name with no loan, is outside it: the
    stage 5 contract this guarantee waits for gives a scoped API a frozen hold
    on every place its arguments' loans reach until the join, an exclusive one
    through an `exclusive T*`, and gives globals a rule, residue item W-365
    (added <date>, SAFE-3, the fold of SAFE-2's whole-tree review: RB-M3).
```

<!-- google-doc-style-resume -->

### B.3 D-SAFE-17, the log and fork/safe/plan.md section 0.3, the `bool` exclusion (RA-m2)

Words, in fork/decision-log.md (:3773-3776) and in fork/safe/plan.md
(:1072-1075), the same words in both; the replacement keeps the list's "and"
before its last member:

<!-- google-doc-style-ignore -->

```text
and an adapter, `const T` or `MaybeUnformed(T)` of a copy-represented `T` other than `bool` (toolchain/check/type_completion.cpp:572-578, :697-751, :762-770, :783-789 and :803-826 at 0421bf3b4)

an adapter or `const T` of a copy-represented `T`, and `MaybeUnformed(T)` of a copy-represented `T` whose copy is its object representation and that is not `bool` (toolchain/check/type_completion.cpp:572-578, :697-751, :762-770, :783-789 and :803-826 at 0421bf3b4; amended <date>, SAFE-3, the fold of SAFE-2's whole-tree review: RA-m2, where this read "and an adapter, `const T` or `MaybeUnformed(T)` of a copy-represented `T` other than `bool`")
```

<!-- google-doc-style-resume -->

### B.4 fork/decision-log.md, a rewrap of :2901-2902 (RB-m3)

Lines. Replace the 2 lines from "(ACCEPTS / REJECTS / ACCEPTS-UNCHECKED /
NEW-SYNTAX, each with the nightly" to "2026.10.12 outcome or the scoreboard
program that proves the cell).":

<!-- google-doc-style-ignore -->

```markdown
(ACCEPTS / REJECTS / ACCEPTS-UNCHECKED / NEW-SYNTAX, each with the
nightly 2026.10.12 outcome or the scoreboard program that proves the cell).
```

<!-- google-doc-style-resume -->

### B.5 fork/decision-log.md, the F-013 entry's RG-1 paragraph, a SAFE-3 sentence

Insert after SAFE-2's sentence that ends 'I5's text gained the customization and
lost the word "promotes").' (:4349-4350):

<!-- google-doc-style-ignore -->

```markdown
SAFE-3 completed those realignments by re-deriving W-347's operator clause
(fork/safe/safe3-plan.md, its fold commit of <date>): a built-in operator's
`ref` operand is bound for the operator's call and is exempt from D-SAFE-8's
marker when the checker establishes that nothing but the operand can reach its
referent while it is bound, the toolchain's in-place `=`, which differs from
assignment.md:184's rewrite, being checked by D-SAFE-8's interim rule (W-366);
it filed W-365, the
data-race gap SAFE-2's whole-tree review found in D-SAFE-16, and folded that
review's other accepted findings (re-derived <date>, SAFE-3: D-SAFE3-1 to
D-SAFE3-9).
```

<!-- google-doc-style-resume -->

### B.6 fork/safe/plan.md section 1.5, the short form

Words, at :1614-1616 (the same short form as A.3, A.4, A.9 and A.19, with this
place's R1-M1 mark):

<!-- google-doc-style-ignore -->

```text
lives for the one operation and is established on any place, M3 deciding what the operation may do (amended 2026-10-28, document-review fold: R1-M1)

is bound for the operator's call and is established on any place, M3 deciding what the operation may do, when the checker establishes that nothing but the operand can reach its referent while it is bound, the toolchain's in-place `=` meeting that only under the interim rule of D-SAFE-8 (amended 2026-10-28, document-review fold: R1-M1; re-derived <date>, SAFE-3: D-SAFE3-1 to D-SAFE3-5, where this read "lives for the one operation and is established on any place, M3 deciding what the operation may do")
```

<!-- google-doc-style-resume -->

### B.7 fork/safe/plan.md, a pointer after SAFE-2's realigned paragraph

Insert, as a paragraph, after the line "is superseded by the pages as
fork/safe/safe2-plan.md Appendix A realigns them." (:62):

<!-- google-doc-style-ignore -->

```markdown
**Re-derived (<date>, SAFE-3):** the `ref` operand of a built-in operator in
D-SAFE-8 and D-SAFE-9 of §0.3, and the §1.5 and §1.6 text that states it, were
re-derived from the safety argument by fork/safe/safe3-plan.md after SAFE-2
stopped at its plan rev 14 (PRR3-B1): the operand is bound for the operator's
call and is exempt when the checker establishes that nothing but the operand can
reach its referent while it is bound, the toolchain's in-place `=` checked by
D-SAFE-8's interim rule. Each re-derived passage carries "(re-derived
<date>, SAFE-3: D-SAFE3-n)" and quotes the text it supersedes; SAFE-3 also
folded the accepted findings that SAFE-2's rounds left unapplied (D-SAFE-16,
D-SAFE-17 and four rewraps), and the "Realigned notes (SAFE-2)" section records
it.
```

<!-- google-doc-style-resume -->

### B.8 fork/safe/plan.md, Realigned notes (SAFE-2), a SAFE-3 paragraph

Insert, as a paragraph, after the line "land-sequence records commit when it
lands." (:3050), the last of the section that begins at :3014:

<!-- google-doc-style-ignore -->

```markdown
SAFE-3 (fork/safe/safe3-plan.md) completed this realignment on <date> after
SAFE-2 stopped at its plan rev 14 on PRR3-B1, under the orchestrator's rulings
recorded in safe2-plan.md sections 8.16, 8.19 and 8.20: its fold commit
re-derives the `ref` operand of a built-in operator from the safety argument
(D-SAFE-8, D-SAFE-9 and the temporal and mutation pages; the operand exempt
when the checker establishes that nothing but it can reach its referent while
it is bound for the operator's call, the toolchain's in-place `=` checked by
D-SAFE-8's interim rule while it differs from upstream's rewrite, W-366), files
W-365 for D-SAFE-16's
data-race gap, and folds SAFE-2's other accepted findings; its records commit,
two whole-tree document reviews, its fixer and a two-reviewer re-review until
dry follow, safe3-plan.md section 8 recording the hashes. PR 53's head is pushed
only when that re-review is dry.
```

<!-- google-doc-style-resume -->

### B.9 fork/safe/plan.md, a rewrap of :2273-2276 (RB-m3)

Lines. Replace the 4 lines :2273-2276, from the one that begins "2); a[2];" to
the one that ends "The guard body (:29-34) is unchanged.":

<!-- google-doc-style-ignore -->

```markdown
2); a[2];` as the compile-time spatial rejection, and `// let r: i32 =
unsafe *q;` as the temporal audit point — still comments, still not
compile-verified (R6 cannot apply to syntax no toolchain parses; disclosed in
the comment). The guard body (:29-34) is unchanged.
```

<!-- google-doc-style-resume -->

### B.10 fork/safe/plan.md, a rewrap of :2574-2575 (RB-m3)

Lines. Replace the 2 lines :2574-2575, both indented four spaces, the first
beginning with the code span `grep -cE '^\s*[0-9]+\. '` and the second with "-n
'^#' <f> > before":

<!-- google-doc-style-ignore -->

```markdown
    `grep -cE '^\s*[0-9]+\. '`), and save the set of heading lines (`grep -n
    '^#' <f> > before`). (b) Run `SKIP=fix-cc-deps,check-build-graph,
```

<!-- google-doc-style-resume -->

### B.11 fork/safe/plan.md, a rewrap of :2793-2795 (RB-m3)

Lines. Replace the 3 lines from "posture with `--default-safety-mode`;
`unsafe import`; the S1a/S1b executable" to "stage-1 soundness claim
(counterexamples `Leak`, the scope-escaping":

<!-- google-doc-style-ignore -->

```markdown
posture with `--default-safety-mode`; `unsafe import`; the S1a/S1b
executable 0.1-optional slice; `unsafe class` interim; the per-row Stage column.
Fatal: C's stage-1 soundness claim (counterexamples `Leak`, the scope-escaping
```

<!-- google-doc-style-resume -->

### B.12 fork/inventory/work-items.json, W-148's notes

Append to W-148's `notes` string, after one space, its quotes escaped (amended
2026-10-29, review fold: A-RA3-B1, A-RA3-M1, A-RA3-M2, A-RA3-m3, B-M3, B-m1:
A.1's interim-rule sentence, where this said "such an `=` keeps the exemption
only when its right operand reads no open place and passes no carrier of one to
a call, uses no carrier of the left operand's place or an overlapping one, and
on an open place runs no code written outside core/prelude"; "an impl written
outside core/prelude", where this said "a library outside core/prelude";
details.md at 9192ee003; the keying at every depth and the third message form;
amended 2026-10-29, review fold: RR1-M1, RR1-m1: A.1's sentence with its second
condition over the owner and every carrier, where it read "uses no carrier of
the left operand's place or of a place that overlaps it", the definition of
"copy-represented at every depth" by representation, where it read "a
one-element aggregate whose element is not copy-represented holding one", and
convert.cpp:1467-1518's adapter case):

<!-- google-doc-style-ignore -->

```text
SAFE-3 (<date>; D-SAFE3-1 to D-SAFE3-5; fork/safe/safe3-plan.md): superseding the built-in operator test of the three previous notes, an operator's `ref` operand is bound for the operator's call (docs/design/assignment.md:184 rewrites `x = y;` to `x.(AssignWith(U).Op)(y);`, applied to an aggregate by this design's reading while :159-164 leaves the aggregate order to leads issue 686), its other operands evaluated first, and the checker establishes it on any place, with no loan of its own, when it establishes, by two conditions stricter than that property (p005434:859-864), that nothing but the operand can reach the referent while it is bound: what runs then (the impl's body, the thunk of docs/design/generics/details.md:5769-5779 at 9192ee003 and its conversions) is core/prelude code reached through no symbolic witness that an impl written outside core/prelude can fill, and every other operand is a copy that holds no borrowed object or a borrowed object's value binding under its frozen loan, the latter unless its type is copy-represented at every depth, a type being so when it is copy-represented and, if its representation is a one-element tuple or struct's (the type, or an adapter, `const` or `MaybeUnformed` of one), its element is copy-represented at every depth; anything else is a `ref` binding under the general rule. The toolchain's interim `=` (toolchain/check/handle_operator.cpp:99-123) initializes in place, in whole or in part, a left operand whose type is not copy-represented at every depth, element by element (toolchain/check/convert.cpp:283-297 gives each element of a by-copy aggregate its own target inside the destination, and :1467-1518 converts an adapter of a tuple or struct part by part), so the checker also implements the interim rule while that stands (W-366): for a left operand whose type is not copy-represented at every depth, the whole right operand counts as evaluated while the left operand is bound, and the `=` keeps the exemption only when its right operand reads no open place and passes no carrier of one to a call, reads or uses no part of the left operand's place, or of a place that overlaps it, through its owner or a carrier of it (T1, T3), and, on an open place, runs no code written outside core/prelude; otherwise it is a checked reborrow on a closed place (`StrictExclusiveBorrowConflict` for the right operand's read, `StrictSharedBorrowInvalidated` for a carrier it passes) and M3(d) through a shared path, whose `StrictInvalidatingThroughShared` takes the message form for a `ref` operand that is not exempt (mutation_safety.md's message texts). The interim rule only adds conditions, so every program it accepts the rule above accepts.
```

<!-- google-doc-style-resume -->

### B.13 fork/inventory/work-items.json, W-149's notes (RB-M3)

Append to W-149's `notes` string, after one space, its quotes escaped:

<!-- google-doc-style-ignore -->

```text
SAFE-3, the fold of SAFE-2's whole-tree review (<date>; RB-M3; fork/safe/safe2-plan.md section 8.20, fork/safe/safe3-plan.md section 0.9): D-SAFE-16's guarantee, all races between Carbon-spawned threads prevented, does not follow from the thread-boundary lifetime rule as stated: the spawning thread may still make a `Plain` write to a place that a `const T*` argument lets a scoped thread read, and a global, which every thread reaches by name with no loan, is outside the rule. W-365 holds what this item's stage 5 contract must add, a frozen hold on every place a scoped API's arguments' loans reach until the join (an exclusive one through `exclusive T*`) and a rule for globals.
```

<!-- google-doc-style-resume -->

### B.14 fork/inventory/work-items.json, W-365 and W-366

Insert after W-150's object, the last of `items`, a comma, a line break and the
two objects below, in the file's layout; W-365 is SAFE-2's planned residue item
of RB-M3 (its F11) relabelled, W-366 the watch item of D-SAFE3-5 and D-SAFE3-9
(W-366 amended 2026-10-29, review fold: A-RA3-B1, A-RA3-M1, B-M3: its title,
evidence and notes name the keying at every depth with convert.cpp:283-297 and
ra01, ra04 and ra05, label the aggregate order this design's reading pending
issue 686, add the partial-adoption and direct-initialization break conditions
and the nightly's `poison` store, and say "the interim rule only adding
conditions, so that every program it accepts the designed rule accepts", where
they said "every program it rejects being accepted under the designed rule",
which section 4's `*q = *p` row contradicts; W-366's evidence amended
2026-10-29, review fold: RR1-M1, RR1-m1: convert.cpp:1467-1518's adapter case
and the re-review's n02 and n03 added):

<!-- google-doc-style-ignore -->

```json
    {
      "id": "W-365",
      "kind": "missing-feature",
      "title": "SAFE-2 residue, filed by SAFE-3: the thread-boundary lifetime rule's loan kinds and globals across threads (D-SAFE-16) — a scoped thread-crossing API holds every place its arguments' loans reach under a frozen loan until the join (an exclusive one through `exclusive T*`), and globals, which every thread reaches by name with no loan, get a rule, so that \"no data races between Carbon-spawned threads\" follows",
      "subsystem": "docs/design/safety (mutation_safety.md M7 and 'Data races and the facets', D-SAFE-16); toolchain/check (stage 5 thread-crossing calls)",
      "size": "M",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "docs/design/safety/mutation_safety.md 'M7: Data races' and 'Data races and the facets' (the thread-boundary lifetime rule; the `const T*` row of the facet table; RB-M3's pointer)",
        "fork/safe/safe2-plan.md section 8.20 (the whole-tree review B's RB-M3, reproduced by rev 11)"
      ],
      "blocked_by": ["W-148"],
      "notes": "Filed by SAFE-3's fold commit (<date>; fork/safe/safe3-plan.md section 0.9; SAFE-2's whole-tree review B, RB-M3, fork/safe/safe2-plan.md section 8.20). As stated, the thread-boundary lifetime rule holds a loan that crosses into a scoped thread at the kind it was formed with: `fn Race2() { var x: i32 = 0; Core.Thread.Scope(fn (ref s: Core.Thread.Scope) { s.Spawn(fn (var q: const i32*) { Core.Print(*q); }, &x); x = 1; }); }` is accepted, `const i32*` being `Send` because `i32` is `Sync`, the scope keeping the shared loan on `x` live and the owner's `Plain` write under a live shared loan being allowed (T4), so the write races the reading thread; and a global, which every thread reaches by name with no loan, lets two Carbon-spawned threads write one `Plain` object with no pointer crossing at all. Review B's candidate rule: a thread-crossing API holds every place its arguments' loans reach under a frozen loan until the join, an exclusive one through `exclusive T*`, so that any other path's write, the spawning thread's included, is `StrictBorrowedObjectMutated`; globals need a rule of their own, which the stage 5 design (W-149) decides with this one. NEW syntax: the nightly has no `Core.Thread`, so no probe exists."
    },
    {
      "id": "W-366",
      "kind": "language-gap",
      "title": "SAFE-3 watch: the toolchain's interim `=` initializes its left operand from the right, in place for a type that is not copy-represented at every depth, element by element, instead of calling `AssignWith` as docs/design/assignment.md:184 states it (`x = y;` rewritten to `x.(AssignWith(U).Op)(y);`; for an aggregate this design's reading, assignment.md:159-164 leaving the order to leads issue 686), so a right operand that reads the left operand sees the in-place order's result (`*q = {.a = p->b, .b = p->a}` with `p == q` gives 2 2, the right operand formed first 2 1); the Strict checker's interim rule (D-SAFE-8, fork/safe/safe3-plan.md D-SAFE3-5) stands until the toolchain adopts the rewrite",
      "subsystem": "toolchain/check (handle_operator.cpp's `=`, convert.cpp's InitializeExisting); docs/design/safety (temporal_safety.md `ref` bindings, the interim rule; mutation_safety.md M3)",
      "size": "M",
      "bullet": "Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)",
      "evidence": [
        "toolchain/check/handle_operator.cpp:99-123 at upstream 9192ee003 and the fork (\"TODO: Switch to using assignment interface for most assignment\"; `rhs_id = InitializeExisting(context, node_id, lhs_id, rhs_id);`, :121), toolchain/sem_ir/type_info.cpp:82-89 (a copy representation initializes by copy, a pointer or custom one in place) and toolchain/check/convert.cpp:283-297 and :400-405 at 9192ee003 (each element of a by-copy aggregate gets an initializing target inside the destination, so an element that is not copy-represented is initialized in place inside a copy-represented one-element tuple or struct; :1467-1518 converts an adapter of a tuple or struct part by part, so the same holds inside such an adapter)",
        "fork/safe/safe3-plan.md section 0.3 (v09, v10, v11, v14, v24, v25, s03, s04, s05, s15 and review A's ra01, ra04 and ra05, the last three copy-represented one-element aggregates of a pointer-represented element, and the re-review's n03, a `var` parameter, a `returned var` and a class local read through their owner, print the in-place order's result on the 2026.10.12 nightly; the re-review's n02, an adapter of `{.c: C}`, has `C`'s `Copy` initialize its part of the left operand in place (its SemIR); s10 and s11, the right operand formed first and the rewrite emulated, print 2 1)"
      ],
      "blocked_by": [],
      "notes": "Filed by SAFE-3's fold commit (<date>; fork/safe/safe3-plan.md D-SAFE3-5). No Carbon function's lowering carries `noalias` today, so the deviation gives a defined result different from the designed one, not undefined behavior. For the integers, floating-point types, `bool` and pointers the in-place `=` is a deviation from the assignment design by upstream's own TODO (handle_operator.cpp:99-100, \"Some cases may need to be handled directly.\"); for tuples, structs, choice types and data classes upstream has not decided the order (assignment.md:159-164, leads issue 686), and its designed initialization is itself depth-first and in place (pattern_matching.md:858-867; p005545:118-122), so treating the in-place order as a difference from the design is this design's reading of :184, pending that issue. Break condition and discharge: the toolchain routes `=` through `AssignWith` for every type, by an upstream advance (upstream's own TODO, handle_operator.cpp:99-100) or a fork change under R32; the interim rule of D-SAFE-8 is then withdrawn by a dated mark, the interim rule only adding conditions, so that every program it accepts the designed rule accepts and none is newly rejected, and this item is discharged. Partial: the toolchain routes only some types through `AssignWith`, the scalars of assignment.md:148-151 first; the interim rule then stays, by a dated mark naming them, for every type still initialized by `InitializeExisting`. Direct initialization: the toolchain or upstream gives an unformed left operand assignment.md:102-106's direct initialization (`y = F();`, :116-120); that is initialization in place and stays under the interim rule whatever the rewrite's status. Further TODOs re-open the interim rule's keying by a dated mark if done first: handle_operator.cpp:119-120's \"Destroy the old value before reinitializing\", which would run the old value's destructor, user-written for a user's class, at the `=`; type_info.cpp:83-84's \"Use in-place initialization for types that have non-trivial destructive move\"; and type_completion.cpp:576-577's \"Consider doing the same whenever `elementwise_rep` is sufficiently small\", which would give a tuple or struct of more than one element a copy representation that the keying would count as stored once, a probe deciding first. The 2026.10.12 nightly's evidence for the copy-represented one-element case is order-only: after the in-place `=` of such a type it stores `poison` of the whole object over the left operand (ra01, ra03 to ra06), a wrong-code defect of the nightly not filed here (fork/safe/safe3-plan.md section 0.3)."
    }
```

<!-- google-doc-style-resume -->

### B.15 fork/safe/safe2-plan.md, a Status paragraph

Insert as its own paragraph, followed by a blank line, before the line that
begins "**Items:** W-347 (D-SAFE-8 narrows p005434:83)" (:199):

<!-- google-doc-style-ignore -->

```markdown
SAFE-3's plan, fork/safe/safe3-plan.md, re-derives M3(d) and D-SAFE2-6 from the
safety argument and completes this realignment: its fold commit supersedes F1 to
F6 of section 8.20 with its own texts and applies the substance of F7 to F27,
relabelled, and steps 4 to 8 of section 3 continue under its section 3 (added
<date>, SAFE-3: fork/safe/safe3-plan.md).
```

<!-- google-doc-style-resume -->

### B.16 fork/safe/safe2-plan.md, D-SAFE2-6

Insert at the end of the D-SAFE2-6 bullet (:1576-1709), after "and close the
item); and D-SAFE-8's, kept." (:1709):

<!-- google-doc-style-ignore -->

```markdown
(Re-derived <date>, SAFE-3: fork/safe/safe3-plan.md D-SAFE3-1 to D-SAFE3-5
replace, on the pages and in the records, the text this decision gives from
"lives for the one operation" through the RR2-M1 mark; the operand is bound for
the operator's call and is exempt when the checker establishes that nothing but
the operand can reach its referent while it is bound, the toolchain's in-place
`=` being checked by D-SAFE-8's interim rule. This decision's text stays as
SAFE-2 left it.)
```

<!-- google-doc-style-resume -->

### B.17 fork/safe/safe2-plan.md, section 3 step 5

Insert after "a MAJOR at round 4 doing the same as section 8.19 says (amended
2026-10-29, plan re-review round 3: section 8.20)." (:2199-2201):

<!-- google-doc-style-ignore -->

```markdown
(Amended <date>, SAFE-3: steps 4 to 8 continue under fork/safe/safe3-plan.md
section 3, whose fold commit takes the fifth fix commit's place, whose fixer has
a budget of two fix commits and whose re-review by two fresh agents per round
replaces round 4; its Appendix C and D texts supersede this plan's.)
```

<!-- google-doc-style-resume -->

### B.18 fork/safe/safe2-plan.md, section 8.20, before F1

Insert as its own paragraph, followed by a blank line, before the line that
begins "F1, docs/design/safety/temporal_safety.md, `ref` bindings, the paragraph
that" (:5591):

<!-- google-doc-style-ignore -->

```markdown
(Added <date>, SAFE-3: no block below is applied as written.
fork/safe/safe3-plan.md re-derives the rule of F1 to F6, which PRR3-B1 showed
unsound for the toolchain's interim `=`, and its fold commit applies the
substance of F7 to F27 in its own texts, relabelled "SAFE-3, the fold of
SAFE-2's whole-tree review".)
```

<!-- google-doc-style-resume -->

### B.19 fork/safe/safe2-plan.md, the Sign-off

Insert as its own paragraph, followed by a blank line, before the line "##
Hand-off notes for the implementer" (:7323), the last paragraph of the Sign-off
section that begins at :7145:

<!-- google-doc-style-ignore -->

```markdown
SAFE-3, <date>: fork/safe/safe3-plan.md is the ground-up re-derivation the
ruling on rev 13 called for; its own reviews sign it off, and its fold commit
supersedes F1 to F6 and folds F7 to F27, so this plan's sign-off of rev 5 stands
for the texts of commits 1 and 2 that SAFE-3's fold commit leaves as they were
(added <date>, SAFE-3).
```

<!-- google-doc-style-resume -->

### B.20 fork/safe/safe2-plan.md, Appendix C

Insert, as a paragraph, after the line "## Appendix C. PR texts and PR 67's
notes" (:11492):

<!-- google-doc-style-ignore -->

```markdown
(Superseded <date>, SAFE-3: fork/safe/safe3-plan.md Appendix C gives the
PR 53 and PR 67 texts that are posted and the PR 67 note commit's edits; the
texts below stay as SAFE-2 planned them.)
```

<!-- google-doc-style-resume -->

### B.21 fork/safe/safe2-plan.md, Appendix D

Insert, as a paragraph, after the line "## Appendix D. Trunk's
fork/ORCHESTRATION.md (section 3 step 8)" (:11663):

<!-- google-doc-style-ignore -->

```markdown
(Superseded <date>, SAFE-3: fork/safe/safe3-plan.md Appendix D gives the
edits of trunk's fork/ORCHESTRATION.md that the orchestrator stamps; the texts
below stay as SAFE-2 planned them.)
```

<!-- google-doc-style-resume -->

### B.22 fork/safe/plan.md section 1.6, the message instance of `StrictInvalidatingThroughShared`

Words, at :1697-1699, the diagnostics list after section 1.6's D-SAFE-17
paragraph, A.23's form for this place (added 2026-10-29, review fold:
A-RA3-M2):

<!-- google-doc-style-ignore -->

```text
`Core.Guarded`, or `unsafe`"), `StrictBorrowFromShared`,

`Core.Guarded`, or `unsafe`"; for a built-in operator's `ref` operand that is not exempt, whatever its type, "operator `=` binds its `ref` operand `*q` through shared pointer `q` while `p->b` can reach it; form the right operand first, use an `exclusive` pointer, `Core.Guarded`, or `unsafe`", the mutation page's third form, added <date>, SAFE-3: D-SAFE3-6), `StrictBorrowFromShared`,
```

<!-- google-doc-style-resume -->

### B.23 fork/safe/plan.md, Realigned notes (SAFE-2), the note commit re-pointed

Words, at :3047-3048, in the paragraph that B.8's SAFE-3 paragraph follows,
applied after B.8, whose anchor is that paragraph's last line (added 2026-10-29,
review fold: B-m3):

<!-- google-doc-style-ignore -->

```text
once SAFE-2's PR 67 note commit lands (safe2-plan.md section 3 step 6;

once the PR 67 note commit lands (fork/safe/safe3-plan.md section 3 step 7, which takes over safe2-plan.md section 3 step 6; re-pointed <date>, SAFE-3: D-SAFE3-10, where this read "once SAFE-2's PR 67 note commit lands (safe2-plan.md section 3 step 6";
```

<!-- google-doc-style-resume -->

### B.24 fork/decision-log.md, the F-013 entry's silence-check pointer re-pointed

Words, at :4280-4282 (added 2026-10-29, review fold: B-m3):

<!-- google-doc-style-ignore -->

```text
whose silence check SAFE-2's PR 67 note commit widens to it, fork/safe/safe2-plan.md section 3 step 6;

whose silence check the PR 67 note commit widens to it, fork/safe/safe3-plan.md section 3 step 7, which takes over fork/safe/safe2-plan.md section 3 step 6 (re-pointed <date>, SAFE-3: D-SAFE3-10, where this read "whose silence check SAFE-2's PR 67 note commit widens to it, fork/safe/safe2-plan.md section 3 step 6");
```

<!-- google-doc-style-resume -->

### B.25 fork/decision-log.md, the F-013 entry's H1.13 pointer re-pointed

Words, at :4346-4348 (added 2026-10-29, review fold: B-m3):

<!-- google-doc-style-ignore -->

```text
and SAFE-2's PR 67 note commit (fork/safe/safe2-plan.md section 3 step 6) re-classifies H1.13 ALIGNED in PR 67's register,

and the PR 67 note commit (fork/safe/safe3-plan.md section 3 step 7, which takes over fork/safe/safe2-plan.md section 3 step 6; re-pointed <date>, SAFE-3: D-SAFE3-10, where this read "and SAFE-2's PR 67 note commit (fork/safe/safe2-plan.md section 3 step 6)") re-classifies H1.13 ALIGNED in PR 67's register,
```

<!-- google-doc-style-resume -->

### B.26 fork/safe/safe2-plan.md, PRR3-m1's break condition closed

Insert after "Break condition: safe3-plan.md keeps an interim-`=` clause; it
then takes this one." (:5527-5528, the PRR3-m1 bullet of section 8.20's record;
added 2026-10-29, review fold: B-m6):

<!-- google-doc-style-ignore -->

```markdown
(Fired <date>, SAFE-3: fork/safe/safe3-plan.md keeps an interim-`=` rule,
and its D-SAFE3-5 records why that rule does not need this clause: the whole
right operand counts as evaluated while the left operand is bound, so no outcome
depends on when within it a call receives its place.)
```

<!-- google-doc-style-resume -->

## Appendix C. PR texts and PR 67's note commit

These texts supersede safe2-plan.md Appendix C, which is never posted (B.20).
The placeholders are section 2.1's.

### C.1 PR 53's description, a section appended

The orchestrator appends this heading and paragraph to PR 53's current
description at section 3 step 9, from the file that step names (amended
2026-10-29, review fold: A-RA3-M1, A-RA3-m3: "states it (for an aggregate this
design's reading, leads issue 686 being open)", "when the checker establishes
that" and "differs from", where this read "designs it", "exactly when" and
"deviates from"; amended 2026-10-29, review fold: RR1-m2: "re-reviewed until
dry, PR 53 then at `<head>`", where this read "re-reviewed until dry at
`<head>`", `<head>` now being the head after the dry round's records commit):

<!-- google-doc-style-ignore -->

```markdown
### SAFE-2 and SAFE-3 realignment (<date>)

**SAFE-2 and SAFE-3 (<rdate>): the six departures realigned (R32 (e)).**
SAFE-2's commits 48f2e66a0 (the pages) and 954f1c542 (the records), with its fix
commits 0f281d8bd, e1574b003, cbdc0552e and 9d0b072cb, realign SAFE-1's
departures from accepted text under the owner's no-direction-drift directive:
every `ref` binding is `nocapture` and `noalias` as p005434:83 states (W-347);
Strict prevents mutation of borrowed objects as p005434:663 states, keyed on the
value representation, with the opt-in `Core.SharedImmutable` for shared paths,
whose shared-path writes M3 rejects (W-348); each `bound` argument is immutable
for the duration of the result as p005434:831-832 states, a pointer argument's
pointee included (W-349); arithmetic.md's performance-build row and the
strategy's unsupported benchmarking build are kept, read through the build modes
(W-350, W-351); and W-353 is closed, its classification corrected, the zeroing
of every type's storage being p000257:356-358's hardening initialization,
accepted text RG-1's H1.13 row had not quoted. SAFE-2 stopped at its plan rev 14
when a nightly probe showed its exemption of a built-in operator's `ref` operand
unsound under the toolchain's in-place `=`. SAFE-3's commits <s1> (the
fold) and <s2> (its records) and the fix commits <fixes>, reviewed by two
whole-tree document reviews and re-reviewed until dry, PR 53 then at <head>,
re-derive that exemption from the safety argument: the operand is bound for the
operator's call, as assignment.md:184's rewrite of `x = y;` to
`x.(AssignWith(U).Op)(y);` states it (for an aggregate this design's reading,
leads issue 686 being open), and is exempt when the checker establishes that
nothing but the operand can reach its referent while it is bound, the
toolchain's in-place `=` being checked by an interim rule while it differs from
that rewrite (W-366). SAFE-3 also files W-365, the data-race gap SAFE-2's review
found in D-SAFE-16, and folds SAFE-2's other accepted findings. The plans are
fork/safe/safe2-plan.md and fork/safe/safe3-plan.md, and the examples whose
outcomes changed are in each plan's section 4. Still documentation and records
only: no toolchain, prelude, golden or program change, the two SKIP stubs
unchanged.
```

<!-- google-doc-style-resume -->

### C.2 PR 67's records, the note commit (section 3 step 7)

The PR 67 note commit, made in a detached worktree of PR 67's head 56e2e5bbd,
makes SAFE-2's five edits of safe2-plan.md Appendix C.2, re-cited to both plans,
every `<date>` its own UTC date, every `<rdate>` SAFE-3 commit 1's, and every
note citing PR 53's dry head `<head>`; the counts are SAFE-2's: 284 quotes, 89
silence checks, H1.7 widened to `Core.SharedImmutable`, H1.13 ALIGNED, the
register 18 DRIFT, 33 ALIGNED and 104 NONE. Each anchor below was found once at
56e2e5bbd by the planner. Its message is "RG-1 records: SAFE-2's and SAFE-3's
realignment of W-347 to W-351 noted, W-353 closed and H1.13 re-classified
ALIGNED, H1.7 widened to Core.SharedImmutable, eleven quote rows added
(PR 53 at <head>)". The W-347 note says "is exempt when the checker
establishes that" and "differs from", where rev 1 said "exactly when" and
"deviates from" (amended 2026-10-29, review fold: A-RA3-M1, A-RA3-m3); the
commit's checks are section 3 step 7's.

(i) fork/inventory/work-items.json: append each text of the first block to its
item's `notes`, after a space, its quotes escaped.

(ii) fork/register/rg1-checks.tsv: replace the row whose id is `H1.7` (:56) with
the second block's row, the regex widened by `SharedImmutable` (measured at the
tip 9192ee003 from the detached worktree of section 0.4: `check_greps.sh` prints
"checked 89 silence checks, 0 failed").

(iii) fork/register/rg1-quotes.tsv: append the third block's eleven rows after
its 273 (measured at 9192ee003: `check_quotes.sh` over the 284 rows prints
"checked 284 quotes, 0 failed").

(iv) fork/register/rg1-plan.md: in section 2.H1's row H1.7 (:881), replace
"`Atomic`, `Thread`" in the Entry cell with "`Atomic`, `Thread`, and
`SharedImmutable` (added <date>, SAFE-2 and SAFE-3: W-348, PR 53's
fork/safe/safe2-plan.md D-SAFE2-5)" and `\|Thread)\b'` in the Upstream cell's
check with `\|Thread\|SharedImmutable)\b'`; in row H1.13 (:887), append the
fourth block to the Upstream cell, replace the Verdict cell's leading
"**DRIFT**" with the fifth block, replace the Break condition cell with the
ninth block, and append "; closed <rdate> by SAFE-2 and SAFE-3, its
classification corrected; W-355" to the Item cell; insert the sixth block as a
paragraph after the H1 table and before "The block's re-basing clause"; append
the seventh block to D-RG-20's paragraph after "and W-350's target becomes the
release build's row."; and append the eighth block to the Status paragraph after
"section 4.2's quote table holds 273 lines." and to section 4.2's paragraph
after "and fork/register/check_greps.sh are the checkers below.".

(v) fork/decision-log.md, RG-1's entry: append the eighth block to the paragraph
that begins "_The count._", after "so the register stays a work queue.".

`<TAB>` in the second and third blocks is one tab character. The ninth block
follows the eighth.

<!-- google-doc-style-ignore -->

```text
W-347: REALIGNED <rdate> by SAFE-2 and SAFE-3 on PR 53 at <head> (fork/safe/safe2-plan.md D-SAFE2-6, fork/safe/safe3-plan.md D-SAFE3-1 to D-SAFE3-5): every `ref` binding is `nocapture` and `noalias`, a checked reborrow on a closed place and an `unsafe` formation on an open one, T8 emitting the attributes only where established against every writer; a built-in operator's `ref` operand is bound for the operator's call and is exempt when the checker establishes that nothing but the operand can reach its referent while it is bound, the toolchain's in-place `=` checked by D-SAFE-8's interim rule while it differs from assignment.md:184's rewrite (W-366 on PR 53); discharged by PR 53's land-sequence records commit.
W-348: REALIGNED <rdate> by SAFE-2 and SAFE-3 on PR 53 at <head> (fork/safe/safe2-plan.md D-SAFE2-3 to D-SAFE2-5 and D-SAFE2-7, fork/safe/safe3-plan.md D-SAFE3-1 to D-SAFE3-5): Strict prevents mutation of borrowed objects, keyed on the value representation, with the opt-in `Core.SharedImmutable` on shared paths, whose shared-path writes M3 rejects, M3's built-in operator clause re-derived with the exemption; discharged by PR 53's land-sequence records commit.
W-349: REALIGNED <rdate> by SAFE-2 and SAFE-3 on PR 53 at <head> (fork/safe/safe2-plan.md D-SAFE2-9, fork/safe/safe3-plan.md D-SAFE3-10): each `bound` argument is immutable for the duration of the result, a pointer argument's pointee written by no path but the result; discharged by PR 53's land-sequence records commit.
W-350: REALIGNED <rdate> by SAFE-2 and SAFE-3 on PR 53 at <head> (fork/safe/safe2-plan.md D-SAFE2-11, fork/safe/safe3-plan.md D-SAFE3-10): arithmetic.md's three rows are read through the build modes under D-RG-20, the performance-build row standing for the unsupported benchmarking build; discharged by PR 53's land-sequence records commit.
W-351: REALIGNED <rdate> by SAFE-2 and SAFE-3 on PR 53 at <head> (fork/safe/safe2-plan.md D-SAFE2-13, fork/safe/safe3-plan.md D-SAFE3-10): the unsupported benchmarking build is kept as safety README.md:260-262 promises, `unsafe fn GetUnchecked` the supported opt-out; discharged by PR 53's land-sequence records commit.
W-353: CLOSED <rdate>, its classification corrected (SAFE-2 and SAFE-3 on PR 53 at <head>; fork/safe/safe2-plan.md section 0.3, fork/safe/safe3-plan.md D-SAFE3-10): the zeroing of every type's storage is upstream's, p000257:356-358, "The entire storage, including any padding bytes, for all types will be at least be zeroed as part of hardening initialization", accepted text at the cut that I5 already cited when this item was filed (PR 53's initialization_safety.md:223-226 at 2407efa74, as p000257:355-358) and that H1.13's quote set left out; nothing upstream changed, H1.13 is re-classified ALIGNED, I5's text gained the customization of p000257:358-360 and lost its "departure", and rg1-quotes.tsv now quotes p000257:356, :357 and :359 for the weekly check. Discharged by PR 53's land-sequence records commit.
W-355: SAFE-2 and SAFE-3 (<date>; PR 53 at <head>): the counts this item's evidence gives become 131 NONE and ALIGNED entries (H1.13 re-classified ALIGNED), fork/register/rg1-quotes.tsv's 284 quoted lines (eleven added: p000257:356, :357, :359 and eight lines of upstream's toolchain/check/type_completion.cpp that PR 53's value-representation rule rests on) and fork/register/rg1-checks.tsv's 89 silence checks, H1.7 widened to `Core.SharedImmutable`.
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
; p000257:356-360 (added <date>, SAFE-2 and SAFE-3): "The entire storage, including any padding bytes, for all types will be at least be zeroed as part of hardening initialization. This routine simply allows a user defined type to specifically customize the hardening initialization of some parts or members of the object to values other than zero."
```

```markdown
**ALIGNED** (amended <date>, SAFE-2 and SAFE-3 on PR 53 at <head>: the classification corrected; p000257:356-358, accepted text at the cut that this row's quotes left out, makes the zeroing of every type's storage language-defined as hardening initialization, and :358-360's customization is README.md:2130's "additional initialization", so the mandate is upstream's and D-RG-20 places it in the release build; the superseded verdict was **DRIFT**, for the reason that follows)
```

```markdown
Amended <date> by SAFE-2 and SAFE-3 (PR 53 at <head>; fork/safe/safe2-plan.md
section 0.3, fork/safe/safe3-plan.md): H1.13 is ALIGNED, so this block holds
five DRIFTs, H1.8 to H1.12, and the register 18 DRIFT, 33 ALIGNED and 104 NONE;
H1.7 names `Core.SharedImmutable`, the one library name SAFE-2 adds, and its
check covers it. W-347 to W-351 are realigned on PR 53 and W-353 is closed.
```

```markdown
Since <date> (SAFE-2 and SAFE-3) H1.13 is ALIGNED; the zeroing stays in the
release build, and this break condition, the hardened mode reconciled into an
extension of Release, would re-open H1.13 as a DRIFT of the zeroing's placement.
```

```markdown
Amended <date> by SAFE-2 and SAFE-3 (PR 53 at <head>): H1.13 re-classified
ALIGNED, so the verdicts are 18 DRIFT, 33 ALIGNED and 104 NONE, ten of the
DRIFTs carried by items RG-1 filed, W-353 being closed; the quote table holds
284 lines, eleven added for p000257:356-360 and upstream's
toolchain/check/type_completion.cpp; the 89 silence checks stay 89, H1.7 widened
to `Core.SharedImmutable`.
```

```markdown
upstream supersedes p000257:356-358's zeroing of every type's storage (an accepted proposal later than p000257, or README.md:2130-2132 shown to supersede it), or reconciles its build-mode pages otherwise than D-RG-20 reads them, the hardened mode becoming an extension of Release; either re-opens H1.13 as a DRIFT (amended <date>, SAFE-2 and SAFE-3 on PR 53 at <head>; the superseded DRIFT condition read "an accepted upstream memory-safety design that makes unformed-state zeroing language-defined for every type, or upstream reconciles its build-mode pages otherwise than D-RG-20 reads them (if the hardened mode becomes an extension of Release, the placement joins W-353)")
```

<!-- google-doc-style-resume -->

### C.3 PR 67's description, a paragraph appended

The orchestrator appends this paragraph to PR 67's current description at
section 3 step 9, from the file that step names:

<!-- google-doc-style-ignore -->

```markdown
**SAFE-2 and SAFE-3 (<date>).** PR 53 realigned W-347 to W-351 at <head> and
closed W-353 with its classification corrected: p000257:356-358, accepted text
H1.13's quotes left out, zeroes every type's storage, so H1.13 is ALIGNED and
the register counts 18 DRIFT, 33 ALIGNED and 104 NONE; SAFE-3 re-derived the
exemption of a built-in operator's `ref` operand after SAFE-2 stopped at its
plan rev 14 (fork/safe/safe3-plan.md on PR 53). The commit <c2-sha> notes the
six items and W-355, widens check H1.7 to `Core.SharedImmutable` (89 checks),
adds eleven quote rows (284 quotes) and dates the counts in the plan and the log
entry. PR 67 still lands first.
```

<!-- google-doc-style-resume -->

## Appendix D. Trunk's fork/ORCHESTRATION.md (section 3 step 9)

Six edits of trunk's fork/ORCHESTRATION.md at abdc798c6 (or the records-only
commit after it, its anchors found again), the texts below with every
placeholder filled; they supersede safe2-plan.md Appendix D (B.21) and record
the history as it happened: SAFE-2 stopped at its plan rev 14, SAFE-3 completed
the realignment, and the mirror branch was created to keep the unpushed commits
and deleted once PR 53's head was pushed, before this stamp (section 3 step 9's
order). The paragraphs of the first and fourth blocks hold `<fixes>`,
`<verdict A>`, `<verdict B>` and `<time>`, whose filled widths are not known
here, so the implementer rewraps each filled paragraph to 80 columns in
orchestration_stamp.md and runs `uvx rumdl@0.2.58 check` on it (amended
2026-10-29, review fold: B-M1, B-M4, B-m4: the second block keeps "the
description refreshed" and "by the orchestrator's rulings (its
sections 8.16, 8.19 and 8.20)" from trunk's row at abdc798c6:1070, where rev 1
dropped them; the fourth says "was deleted before this stamp", where it said
"is deleted with this stamp"; the W-347 sentence is A.1's; amended 2026-10-29,
review fold: RR1-m2: the first and second blocks say "until dry, PR 53 then
at `<head>`", where they said "until dry at `<head>`", `<head>` being the
head after the dry round's records commit, section 2.1).

1.  The header: insert the first block as the new first entry, "Last updated:"
    moving to it, so that the current first entry, which begins "Last updated:
    2026-10-29 (SAFE-2, the R32 realignment" (:13), begins "2026-10-29 (SAFE-2,"
    as the earlier entries do.

2.  The branch row whose first cell is `claude/carbon-fork-0-1-safe` (:1070, its
    second cell beginning "HELD OPEN as PR #53"): replace it with the second
    block.

3.  The branch row whose first cell is `claude/carbon-fork-0-1-rg1` (:1085):
    replace "at 56e2e5bbd (2026-10-28; twelve commits:" with "at <c2-sha>
    (2026-10-28; thirteen commits, the thirteenth the SAFE-2 and SAFE-3 note
    commit <c2-sha> of <date>:" and "273 quotes and 89 silence checks passing at
    e6fddcf97;" with the third block.

4.  A dated paragraph: insert the fourth block after the paragraph that begins
    "2026-10-29 (08:49 UTC): SAFE-2 is STOPPED" (:698), in the form that
    paragraph uses.

5.  Next actions item 6 (:1181): replace "W-353 (SAFE-1: SAFE-2's realignment,
    fork/safe/safe2-plan.md, stopped at rev 14 on 2026-10-29 by the
    orchestrator's rulings, PRR3-B1; SAFE-3, fork/safe/safe3-plan.md, re-derives
    the built-in operator exemption and completes it before PR 53 lands; the
    land sequence waits at PR 53 until then)," with the fifth block.

6.  The land-time discharge, which the fifth block schedules: PR 53's
    land-sequence records commit, made when PR 53 merges after PR 67 (so that PR
    67's ledger is trunk's), appends the sixth block to the notes of W-347 to
    W-351 and W-353, with the landing's date and merge commit filled in.

<!-- google-doc-style-ignore -->

```markdown
Last updated: <date> (SAFE-2 and SAFE-3, the R32 realignment of SAFE-1's six
departures from accepted text, are made on PR 53 and reviewed until dry, PR 53
then at <head>: SAFE-2 stopped at its plan rev 14 on PRR3-B1, SAFE-3
re-derived the built-in operator exemption from the safety argument and
completed the realignment, W-347 to W-351 realigned and W-353 closed with its
classification corrected; the mirror claude/carbon-fork-0-1-safe-wip is deleted;
the land sequence no longer waits at PR 53; eighteen PRs are held open, PR 51 to
PR 68, none merged; see the paragraph dated <date> (<time> UTC) below; the
earlier 2026-10-29 text follows).
```

```markdown
| `claude/carbon-fork-0-1-safe` | HELD OPEN as PR #53 — SAFE-1 safe-Carbon design (F-013) at <head>, documentation and records only (gap row 89 expected DONE on document review, W-063 discharged, W-144..W-150, W-365, W-366); merges first in the land sequence after RG-1's PR (fork/register/rg1-plan.md section 5); amended 2026-10-28 by RG-1's records commit cd3c5b2e1 and its review fix 2407efa74 (R32 (e)), the description refreshed; SAFE-2 (fork/safe/safe2-plan.md; commits 48f2e66a0 and 954f1c542 and the fix commits 0f281d8bd, e1574b003, cbdc0552e and 9d0b072cb) STOPPED 2026-10-29 at its plan rev 14 by the orchestrator's rulings (its sections 8.16, 8.19 and 8.20) on PRR3-B1; realigned <rdate> by SAFE-3 (fork/safe/safe3-plan.md; commits <s1>, <s2> and the fix commits <fixes>, re-reviewed until dry, PR 53 then at <head>): the built-in operator exemption re-derived, W-347 to W-351 realigned and W-353 closed with its classification corrected, W-365 and W-366 filed, noted on PR 67's ledger by <c2-sha>, the descriptions of PR 53 and PR 67 refreshed; the mirror claude/carbon-fork-0-1-safe-wip, created 2026-10-29 for the unpushed commits, deleted once <head> was pushed. |
```

```markdown
273 quotes and 89 silence checks passing at e6fddcf97, and 284 quotes and 89 silence checks at <tip> after the SAFE-2 and SAFE-3 note commit <c2-sha> (W-347 to W-351 noted as realigned on PR 53, W-353 closed and H1.13 re-classified ALIGNED: 18 DRIFT, 33 ALIGNED, 104 NONE; H1.7 widened to `Core.SharedImmutable`);
```

```markdown
<date> (<time> UTC): SAFE-3 is DONE AND REVIEWED on PR 53
(claude/carbon-fork-0-1-safe at <head>; commits <s1> (the fold) and <s2> (the
records) and the fix commits <fixes>), under fork/safe/safe3-plan.md, completing
the realignment that SAFE-2 began under fork/safe/safe2-plan.md (its commits
48f2e66a0 and 954f1c542 and fix commits 0f281d8bd, e1574b003, cbdc0552e and
9d0b072cb, beneath SAFE-3's) and that stopped at its plan rev 14 on PRR3-B1.
Records and design text only, no toolchain, prelude, golden or program change:
SAFE-1's six departures from accepted text, filed by RG-1 as drifts, are
realigned to upstream at <tip>. W-347: every `ref` binding is `nocapture` and
`noalias` (p005434:83); a built-in operator's `ref` operand is bound for the
operator's call, as assignment.md:184's `x.(AssignWith(U).Op)(y)` states it
(for an aggregate this design's reading, leads issue 686 being open), and is
exempt when the checker establishes that nothing but the operand can reach its
referent while it is bound, the toolchain's in-place `=` being checked by an
interim rule while it differs from that rewrite (W-366, a watch item discharged
when the toolchain adopts it). W-348: Strict prevents mutation of borrowed objects (p005434:663),
keyed on the value representation, with the opt-in `Core.SharedImmutable` for
shared paths. W-349: each `bound` argument is immutable for the result's
lifetime (p005434:831-832). W-350 and W-351: arithmetic.md's performance-build
row and safety README.md:260-262's unsupported benchmarking build are kept, read
through the build modes (D-RG-20). W-353 is closed with its classification
corrected (p000257:356-358), and H1.13 is ALIGNED on PR 67, whose ledger notes
the six at <c2-sha>. W-365 holds the data-race gap SAFE-2's review found in
D-SAFE-16. Reviews: two whole-tree document reviews (<verdict A>, <verdict B>),
the fixer and a focused re-review by two reviewers per round until dry. PR 53's
head was pushed as a fast-forward of 2407efa74, and the mirror
claude/carbon-fork-0-1-safe-wip, which held the unpushed commits from 2026-10-29
and was never a PR or a base, was deleted before this stamp. No build, merge or
dispatch; Actions is still disabled. Eighteen PRs are held open (PR 51 to PR
68); none is merged. Merge order: PR 67 (RG-1), then PR 53, 51, 52, 60, 54, 55,
56, 57, 58, 59, 61, 62, 64, 63, 65, 66, then PR 68 (OV-4) through its land-time
commits M, F-M, L-R and L (fork/overload/ov4-plan.md section 3); the sequence no
longer waits at PR 53, and still waits at PR 60 for SC-1's W-139 and at PR 56
for OP-1's W-352. Next: SC-1's W-139 on PR 60 and OP-1's W-352 on PR 56; DR-1
notes on PR 65's records, before PR 65 lands, that its `IndirectIndexWith.Ref`
takes `bound self` under W-144, with the counterexample of
fork/safe/safe2-plan.md section 0.8; then EH-C (W-346) after the held PRs land,
then UA-3; the weekly upstream check of 2026-11-02 runs W-355's scripts over 284
quotes and 89 silence checks.
```

```markdown
W-353 (SAFE-1: realigned <rdate> by SAFE-2 and SAFE-3 on PR 53 at <head>,
fork/safe/safe2-plan.md and fork/safe/safe3-plan.md, W-353 closed with its
classification corrected; the land sequence no longer waits at PR 53; when PR 53
lands, its land-sequence records commit appends to W-347 to W-351 and W-353, in
the ledger PR 67 brought to trunk, the note "DISCHARGED <landing date> by PR
53's landing at <merge commit> (SAFE-2's and SAFE-3's realignment of <rdate>;
fork/safe/safe2-plan.md, fork/safe/safe3-plan.md)"),
```

```text
DISCHARGED <landing date> by PR 53's landing at <merge commit> (SAFE-2's and SAFE-3's realignment of <rdate>; fork/safe/safe2-plan.md, fork/safe/safe3-plan.md).
```

<!-- google-doc-style-resume -->
