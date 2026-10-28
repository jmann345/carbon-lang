<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# SAFE-2 plan: the R32 realignment of SAFE-1's six departures (W-347 to W-351, W-353)

**Status:** rev 2, 2026-10-28, not signed off: the focused re-review decides.
Rev 1 (475b7ecb0) was the planner's draft; rev 2 folds the two plan reviews,
review A (REJECT, two BLOCKERs) and review B (APPROVE-WITH-AMENDMENTS), 21
findings, every one accepted (section 8.8; review A's ids carry the prefix
"A-", so A-B-1 is review A's B-1). Workstream SAFE-2 realigns the six
"departures from accepted text" of SAFE-1's design (fork decision F-013) to
upstream's recorded direction, as rulebook R32 requires since the owner's
directive of 2026-10-21 ("Direction drifts are not permitted"; decision-log
V-3b, DR-0). Branch
`claude/carbon-fork-0-1-safe` (PR 53, held open, second in the land sequence
after PR 67), head 2407efa74; this plan is a new file beside fork/safe/plan.md,
which receives a dated pointer paragraph in commit 2 (section 2.3). Upstream
was read at its tip 0421bf3b4 (fetched 2026-10-28). Records and design text
only: no toolchain, prelude, golden, program or conformance change; the two
SKIP stubs stay as they are; nothing is built.

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
-   Section 8, verification, the list of what was not run, and the plan
    reviews' fold record (section 8.8).
-   Hand-off notes for the implementer.
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
heading Appendix A renames is regenerated by the prek toc hook.

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
safety/temporal_safety.md:517 | no change: T5(f), whose weakest kind counts frozen below shared by T4 (A.3.6) | weakest among them; a store from a place in set `a` into a place in set `a`
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
slices.md:84 | no change: the slices design's value binding of an array, consistent | conversion from an array _value_: a value binding of array type may be
slices.md:258 | no change: a by-value parameter of a class does not copy, consistent with a borrowed object | by-value parameter does not copy it (value bindings of a non-`Copy` class
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

### §0.6 The interlocks

Each structure that states one of the six rules, traced:

| Structure (PR 53) | States | Changes under SAFE-2 |
| --- | --- | --- |
| T2, forming loans (temporal_safety.md:235-289) | D-SAFE-17's shared loan for a non-`Plain` value binding, the eager copy for `Plain`, `let ref` exclusive, the reborrow clause naming "a `bound self` by value" | yes (A.3.5): borrowed objects by value representation, the frozen loan, `ref` formation by closed and open place, frozen reborrows read-only |
| T4, conflicts (:303-317) | shared loans exclude only invalidation; the weakest kind for a mixed set | yes (A.3.6): a frozen loan excludes every write, and passing a writable carrier of the place to a call, except through the result that holds a `bound` pointer argument's pointee (amended 2026-10-28, review fold: A-B-2) |
| T5(a) and (d) (:477-488, :499-505) | the result's kind map (value parameters give shared); "immutable" narrowed to "not invalidated" | yes (A.3.9): value and `const` `ref` parameters give frozen, and a `ref` parameter under a `val` or by-value result; each `bound` argument immutable, a `bound` pointer argument's pointee written by no path but the result (amended 2026-10-28, review fold: A-B-2, A-m-1) |
| T6's binding spelling (:370-379) | `let ref r = unsafe *q;` for a ⊥ carrier | sentence added (A.3.7): the same spelling marks a `ref` on an open place |
| T8, codegen honesty (:425-442) | attributes for exclusive loans only | yes (A.3.8): for `ref` bindings on closed places, `captures(ret: ...)` for `bound`; on a `ref` parameter's referent or an `exclusive T*` parameter's pointee only under the whole-package condition; never on an open place or for an `unsafe`-formed one (amended 2026-10-28, review fold: A-M-1, A-B-1) |
| T1, T3, T7, the Store rule, the P-subset | none of the six | no |
| The kinds table (README.md:393-403, temporal_safety.md:138-146, plan §1.5) | the `const T*` row's receivers `ref self: const Self` and by-value `self` as callable through every kind (M4) | the table's cells stay; a dated paragraph after each copy (A.1.5, A.3.3, B.3.4) states the binding rule the receivers now meet |
| The diagnostic matrix (README.md:309-326, plan §1.1) | `StrictSharedBorrowInvalidated` with Debug `MutationDuringValueBinding` | four rows added (A.1.3, B.3.2): `StrictRefFromShared`, `StrictBorrowFromShared`, `StrictBorrowedObjectMutated`, `StrictSharedImmutableWrite`; the existing row's Debug cell re-worded, the report being `StrictBorrowedObjectMutated`'s (amended 2026-10-28, review fold: A-B-1, B-m6) |
| The Debug value-binding shadow flag (mutation_safety.md:437-444, :511-514) | the detector of the narrowed rule's erroneous writes | kept as the Debug detector of the mutations unchecked code can still make, counting whole-object `Plain` assignments through `T*` beside field writes (D-SAFE2-7; A.2.8, A.2.9; amended 2026-10-28, review fold: A-B-1) |
| D-SAFE-19's Rust rows (rust_interop.md:126-140, :336, :343-352, :380-401, :633-638) | value bindings as one reason `const T*` and a value parameter cannot be `&T` | yes (A.6): a value parameter of a borrowed `Freeze` type exports as `&T`; the `const T*` reason stays |
| M1, M2, M3, M4, M5, M8 and Value bindings (mutation_safety.md) | `ref` kind inheritance, shared value-binding loans, const receivers through every kind, payload refs through shared paths, `Plain` assignments through `T*` to any type | yes (A.2.3 to A.2.8; M3's paragraph on `Core.SharedImmutable` writes, A.2.4a, amended 2026-10-28, review fold: A-B-1) |
| §4.1 worked examples | EX-M-1's `a->Set(0, 5)` under `first`; EX-M-4a/4b's reasons; EX-M-5/6's `ref` payloads through shared pointers; `Pick`/`UsePick`; `Valid1`, `ValToRef`, `Conditional`; the `Launder` programs; EX-I rows; SP4's `GetUnchecked` | outcomes in section 4: EX-M-1, EX-M-5, EX-M-6 and `UsePick` change; EX-M-4c, EX-M-4d and EX-TM-9 are added; the rest keep their outcomes with realigned reasons or none |
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
| a fixer's probe, not a page example: EX-M-4c with `{.n: i32, .m: i32}`, whose elements are all copy-represented (`ValueAndObjectAggregate`), with a `Run` | (section 0.1's second branch) | 0, run exit 0 | prints `1`, as EX-M-4c's `ValueAggregate` does: the printed value does not tell the two aggregate kinds apart, and no page text says it does (amended 2026-10-28, review fold: A-M-2) |
| EX-TM-2 `Bad` | temporal | 0 | none |
| EX-TM-3, the `String` half | temporal | 0 | none |
| EX-TM-7 `Temp` | temporal | 1 | "error: cannot bind durable reference to non-reference value of type `str`" |
| EX-TM-9 `F` (added, A.3.14) with a `Run` passing `&y` for `y == 2` | temporal | 0, run exit 0 | prints `3` |
| p005434:152-162's `F` verbatim, with `fn Assert(b: bool) {}` | (source of EX-TM-9) | 1 | "error: cannot access member of interface `Core.EqWith(i32*)` in type `i32*` that does not implement that interface" at `&x == ptr`, so EX-TM-9 omits the `Assert` line |
| EX-SP-3 `ConstOob` | spatial | 1 | "error: array index `2` is past the end of type `array(i32, 2)`" |
| EX-SP-4 `RuntimeArr` | spatial | 0 | none |
| EX-SP-6 `Div` | spatial | 0 | none |

The fork-prelude examples (EX-M-4b, the `Core.Buf` half of EX-TM-3, EX-TM-7b,
EX-SP-1 and EX-SP-2, the `Launder` programs) keep their cited evidence; the NEW
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
touched by PR 55 at :189-190 and SAFE-2 edits :167-175; slices.md (PR 51, PR 65)
is not edited by SAFE-2 (section 0.4: its :65 is SP3's). fork/safe/plan.md and
this file are PR 53's alone. The records files fork/decision-log.md,
fork/inventory/work-items.json, fork/ORCHESTRATION.md and fork/gap-analysis.md
are touched by every head.

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
    OV-4 convention; a passage whose text stays true and only needs the rule's
    consequence gains a dated sentence instead. A heading that states a
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
    falsifier; amended 2026-10-28, review fold: A-m-4), and it is why
    `Core.Buf`'s by-value `Set` stays callable on a borrowed `Buf`. A `ref`
    binding of a `const` type also holds a frozen loan (D-SAFE2-6). Break
    condition: upstream counts storage reached through an owning pointer as the
    object's storage, or keys borrowed objects on something other than the
    value representation; then the storage sentence, and `Core.Buf.Set`'s
    receiver with it (W-144), follow the upstream text.
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
    rule M3: every write of a `Core.SharedImmutable` type's storage, a
    whole-object assignment and a field assignment included and a `Plain` one
    among them, needs exclusive access, so through `T*`, through `addr self`
    or to an open place such as a global it is rejected,
    `StrictSharedImmutableWrite` (or, for a non-`Plain` assignment, M3's own
    `StrictInvalidatingThroughShared`), while the owner of a closed place under
    no frozen loan writes it as before (the temporal page's EX-TM-3,
    `s = "def"` under a live `const Core.String*`, stays accepted). The
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
    through shared paths by no Strict code.
    Any other binding of a borrowed object on an open place is
    `StrictBorrowFromShared`, with the fixes the pages name: an owner or an
    `exclusive T*`, `Core.Guarded(T)`, the type's `value_rep = const Self` when
    it is small and copyable, a `var` copy of a struct or tuple
    (`var v: T = *p;`, whose `Plain` elements are read and whose class
    elements bind under this same rule), or `unsafe` at the binding, whose
    obligation is that no
    path mutates the object while the binding lives. A value binding from a
    materialized temporary owns the storage and holds no loan, as before. The
    mechanism is the loan rule widened, with the eager copy left to the type by
    upstream's `value_rep`; the eager copy for every type stays rejected
    (section 7). **Cost of realignment:** in Strict, a `Plain`-field write or an
    `addr` call on a borrowed object during its binding is rejected even where
    it frees nothing (EX-M-4c; EX-M-1's `a->Set(0, 5)` under `first` by W-349);
    a by-value method of a class that does not opt in, called through a `T*` or
    `const T*` parameter, a global or a loaded pointer, needs `unsafe` or one of
    the fixes; a whole two-element struct read into a `let` through a
    shared parameter is rejected (EX-M-4d); and a `Core.String` or
    `Core.Slice(T)` is assigned through a `T*` only with `unsafe`, an
    `exclusive T*` or a `ref` (EX-M-4d's `Peek2`), so a class's setter of such
    a field takes `ref self` where `addr self` sufficed (M4), where SAFE-1
    accepted all four. M3, M4 and D-SAFE-9 carry the language half as dated
    edits (A.2.4a, A.2.5, A.2.19, B.1.2a, B.3.5).
    This is the cost p005434:667-669 anticipates ("if enforcing it in the
    strict mode proves fundamentally untenable due to ergonomic costs"), and
    revisiting it is upstream's call. Break condition: upstream relaxes
    p005434:663 under its :665-669 conditions (W-348's own), or a reviewer
    shows a prelude opt-in false (a prelude function, or a language-level
    write the rules admit, that writes its type's storage through a shared
    path), in which case that type's opt-in is withdrawn in a dated edit and
    its examples re-measured.
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
    unmarked it is `StrictRefFromShared`. The shared-kind `ref` is gone. A `ref`
    _return_ is not a binding, so the proposal's `Valid1` (:717-720), `ValToRef`
    (:826) and `Conditional` (:772-779) stay valid in both modes, each returning
    a reference expression whose kind is that of its loans; `Conditional`'s
    mixed set `{(r, exclusive), (*p, shared)}` keeps the weakest kind, shared,
    for the result expression, and binding that result with `let ref` is a `ref`
    formation like any other: checked when every place in the set is closed
    (`UsePick`, whose `z` now conflicts with the live `q2`:
    `StrictExclusiveBorrowConflict`), `unsafe` otherwise. T8 emits `noalias` and
    `captures(none)` or `captures(ret: address, provenance)` only where the
    requirement is established against every writer, Permissive and C++ ones
    included (amended 2026-10-28, review fold: A-M-1, A-B-1; rev 1 emitted for
    every checked `ref` and made a Permissive caller's aliasing undefined
    behavior): for a `ref` binding on a place whose every carrier is the body's
    own, an owner of the body or a place reached only through carriers of such
    owners' loans, intra-function; for one on the referent of a `ref` parameter
    or the pointee of an `exclusive T*` parameter, and for those parameters
    themselves, only under T8's whole-package condition (no export to C++, no
    address taken, every Carbon call site in the package Strict-checked); and
    never for a `ref` on an open place, the checked `const` `ref` on a
    `Core.SharedImmutable` type included, whose frozen loan Strict enforces but
    which a Permissive body or C++ may still write as erroneous behavior, nor
    for an `unsafe`-formed one or one in a Permissive body, whose `noalias` is
    the unsafe code's obligation and not "established" (p005434:866-868).
    Permissive warns `PermissiveAliasedExclusive` and accepts, so D-SAFE-8's
    break condition ("an accepted p005434 example that becomes invalid in
    Permissive mode") stays unbroken. The options the brief names: the exclusive
    formation is taken where the place is closed, the `unsafe` formation where
    it is open, and "no `ref` from a shared pointer" is rejected (section 7).
    **Cost of realignment:** p005434:152-162's `F(ptr: i32*)`, whose `let ref x:
    i32 = *ptr;` binds through a shared parameter, is rejected in Strict
    (EX-TM-9) and is accepted with an `exclusive i32*` parameter or the `unsafe`
    marker; a `ref self: const Self` method called through a shared pointer to a
    type that does not opt in needs `unsafe`; and a `match` through a shared
    pointer binds payloads by value, not by `ref` (EX-M-5, EX-M-6). Break
    condition: W-347's own, an accepted upstream memory-safety proposal that
    narrows p005434:83 (cite it and close the item); and D-SAFE-8's, kept.
-   **D-SAFE2-7 — The Debug value-binding shadow flag.** Kept, as the Debug
    detector of what p005434:670-672 says unchecked code can still do: a
    Permissive body, an `unsafe`-formed binding's aliases or C++ mutating a
    borrowed object. Debug keeps, in shadow memory keyed by object address and
    never in the object's layout, a per-object count of live frozen loans, and
    a `Plain` assignment through `T*`, to a field or to the whole object, or an
    `addr self` call, whose target's count is non-zero reports
    `MutationDuringValueBinding` (the whole-object assignment amended
    2026-10-28, review fold: A-B-1: review A's `Peek2` writes a whole `str`),
    "carbon: mutation of
    a borrowed object; terminating", then `abort()`; Release does nothing, the
    write being erroneous and defined. It is never a Strict rule: a Strict body
    is statically rejected first. The name is kept; the message uses upstream's
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
    ("write to `{0}` of `Core.SharedImmutable` type `{1}` through a shared
    path; use an `exclusive` pointer or `unsafe`", mutation page, M3), the
    last two with the Debug column `MutationDuringValueBinding` (the fourth
    and the generalized `{0}` amended 2026-10-28, review fold: A-B-1, A-B-2;
    rev 1 had three, and `StrictBorrowFromShared` read "value binding of
    `{0}` borrows"). None renamed;
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
    pointer argument's pointee rule is T5(d)'s, applied with the shared kind
    the map gives. **Cost of realignment:** EX-M-1's aliased `a->Set(0, 5)`
    while `first` lives is rejected and moves after `first`'s last use; a
    caller's write to a local passed to `Longest`, `Load`, `Valid1` or
    `Conditional` is rejected while the result lives; and a call of a function
    with a `bound` pointer parameter through a `T*` or `const T*` that reaches
    an open place of a type that does not opt in, `Valid1(p)` for a parameter
    `p: i32*` among them, needs `unsafe` or an `exclusive` pointer, where
    SAFE-1 accepted every one; `Core.String`'s opt-in keeps EX-TM-1's calls
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
    and a by-value `Set` like `Core.Buf`'s may write it while the receiver is
    frozen (D-SAFE2-3). Verdict part (3)'s "the D-SAFE-17 value-binding case
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
-   **D-SAFE2-14 — The examples whose outcomes change** (section 4): EX-M-1
    (the aliased `Set` under `first`), EX-M-5 and EX-M-6 (value payloads
    through shared pointers), `UsePick` (`StrictExclusiveBorrowConflict` in
    place of `StrictInvalidatingThroughShared`); added, EX-M-4c and EX-M-4d (the
    closed and the open borrowed object, EX-M-4d with review A's `Peek2`, the
    `Plain` whole-object write through a shared pointer that is now
    `StrictSharedImmutableWrite`; amended 2026-10-28, review fold: A-B-1) and
    EX-TM-9 (p005434:152-162's `F`).
    Each changed program is rewritten in place with its superseded line kept
    in a comment, and the regression sets' "kept verbatim" sentences gain the
    dated exception. Break condition: a reviewer traces a page example to an
    outcome other than section 4's; the example or the rule is fixed, never
    the matrix alone.
-   **D-SAFE2-15 — Ids and residue.** No new work item and no F id (section
    §0.9): the implementation of every rule above falls inside SAFE-1's stage
    items, which gain dated notes (Appendix B.4): W-144 (the prelude's
    `Core.SharedImmutable` opt-ins, conditional on `Core.Freeze`, and `Box`'s
    when W-144 adds `Box`), W-146 (the benchmarking build, the
    hardening-initialization customization), W-148 (frozen loans, the closed
    and open places, M3's `Core.SharedImmutable` write rule, the four
    diagnostics, T5(d)'s pointee rule, the Debug flag's new scope, T8's
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
    C.3 and D.
-   `<sha1>` and `<sha2>`: commit 1's and commit 2's short hashes, known only
    after they exist, so the texts that cite them (the register sentence, the
    landed notes, Appendix C and D) are written in commit 2 or later.
-   `<head>`: PR 53's dry head, the head at which section 3 step 5's re-review
    is dry; the PR 67 notes (C.2), the PR texts (C.1, C.3) and Appendix D cite
    it rather than `<sha1>`.
-   `<c2-sha>`: the PR 67 note commit's short hash (section 3 step 6);
    `<time>`: the UTC time, `date -u +%H:%M`, of the orchestrator's stamp of
    trunk's fork/ORCHESTRATION.md.
-   `<verdict 1>`, `<verdict 2>`: the two document reviews' verdicts with their
    finding counts; `<fixes>`: the fold commits' short hashes; `<n>`: the
    number of findings; all filled by section 3 step 4's records commit.

Where a block replaces a sentence inside a paragraph, it
quotes the sentence to be replaced in full as its anchor and the rest of the
paragraph is untouched.

### §2.2 Commit 1: the pages (Appendix A)

| Page (docs/design/) | Blocks | What changes |
| --- | --- | --- |
| safety/README.md | A.1.1 to A.1.7 | S0 stated for the supported build modes; the `unsafe` form for a binding on an open place; four matrix rows and the `StrictSharedBorrowInvalidated` row's Debug cell; the spatial bullet; the kinds table's dated paragraph; the benchmarking blockquote kept, not withdrawn; staging rows 2 and 4 |
| safety/mutation_safety.md | A.2.0 to A.2.21, with A.2.4a and A.2.7a | the definition's exception; M1, M2, M3's `Core.SharedImmutable` paragraph, M4, M5, M8; the `Core.Plain` consequences; the Value bindings section with `Core.SharedImmutable`; diagnostics; EX-M-1, EX-M-4a, EX-M-4b, EX-M-5, EX-M-6 rewritten; EX-M-4c and EX-M-4d added; checklist, staging, decisions, alternatives, references |
| safety/temporal_safety.md | A.3.1 to A.3.17 | status; vocabulary (frozen, closed, open); the kinds paragraph; `ref` bindings; T2, T4, T6's sentence, T8; T5(a) and (d); diagnostics and the `StrictSharedBorrowInvalidated` row's Debug cell; EX-TM-1's prose; `Load` and `UsePick`; EX-TM-9 added; staging, decisions, alternatives |
| safety/initialization_safety.md | A.4.1 to A.4.6 | status; I5's first paragraph and one clause of its second; staging row 2; D-SAFE-13's I5 sentence and break condition; the alternatives introduction and bullet; the external fact's row |
| safety/spatial_safety.md | A.5.1 to A.5.11 | overview; status; SP2's heading and sentence; SP4's heading and body; arithmetic; EX-SP-5, EX-SP-6; the C++ division bullet; staging row 2; D-SAFE-14 and D-SAFE-15; two alternatives; one external fact |
| safety/rust_interop.md | A.6.1 to A.6.6 | the asymmetry bullet; a "By type" row and the `Freeze` proviso's sentence; the `At` line and bullet; verdict parts (1) and (3); the break condition and D-SAFE-19's bullet; fold A-9's sentence and the eager-copy alternative |
| values.md | A.7.1, A.7.2 | the "Answered" and "Pinned" notes |
| README.md | A.8.1 | the unformed-state amendment |
| expressions/arithmetic.md | A.9.1 | the amendment blockquote |

Not edited, measured (section 0.4): slices.md (:65 is SP3's), type_safety.md,
terminology.md, unions.md, docs/project/principles/safety_strategy.md, the two
SKIP stubs.

### §2.3 Commit 2: the records (Appendix B)

| File | Blocks | What changes |
| --- | --- | --- |
| fork/decision-log.md (the F-013 entry) | B.1.0 to B.1.10, B.2.1, B.2.2 | D-SAFE-2's S0 scope and break condition (B.1.0, amended 2026-10-28, review fold: B-M4), D-SAFE-8, D-SAFE-10's T2, T4 and T8 sentences, D-SAFE-11(a) and (d), D-SAFE-13's I5 and break condition, D-SAFE-14's SP2, SP4 and break condition, D-SAFE-15, D-SAFE-17, D-SAFE-19's new mapping and verdict part (3), D-SAFE-20's surface, D-SAFE-21's stages 2 and 4; the register block's spellings and departures sentence; RG-1's paragraph gains a dated SAFE-2 sentence per item |
| fork/safe/plan.md | B.1 (the same texts in §0.3), B.3.1 to B.3.8 | the pointer paragraph after Status; §1.1's S0 sentence, matrix rows and `StrictSharedBorrowInvalidated` Debug cell (amended 2026-10-28, review fold: B-M4, B-m6); §1.4's and §1.3's sentences; §1.5's kinds paragraph and diagnostics; §1.6's M5 and M8 sentence; §4.1's rows; §4.3's adversary-1 sentence; the "Realigned notes (SAFE-2)" paragraph after the landed notes |
| fork/inventory/work-items.json (PR 53's ledger) | B.4 | dated notes on W-144, W-146, W-148 and W-150, those on W-146 and W-148 quoting and superseding the lines section 0.5 lists (amended 2026-10-28, review fold: B-M6) |

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
    arithmetic.md and README.md (W-347 to W-351, W-353).** Appendix A, the nine
    pages of section 2.2. The brief's title named slices.md too; section 0.4
    measured slices.md:65 as SP3's line, which SAFE-2 does not change, so the
    title names the pages the commit edits (R10).
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
    section 8.7 by a records commit.
5.  **The focused re-review of the fix commits**, one fresh agent per round,
    at most three rounds, until dry: dry is no BLOCKER and no MAJOR and every
    MINOR records-only, folded by one records commit. A round that is not dry
    goes back to step 4 within its budget.
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
| EX-M-4d `Peek`, `BufSize`, `Peek2` (new; `Peek2` amended 2026-10-28, review fold: A-B-1) | ACCEPTS-UNCHECKED (nightly exit 0: `Peek` prints 1, `Peek2(&x, &x)` prints 6; `BufSize` is fork prelude) | `Peek`: `StrictBorrowFromShared` at `let v`; `BufSize`: accepted (`Core.Buf(i32)` is `Core.SharedImmutable`, `i32` being `Freeze`); `Peek2`: the binding of `*p` is accepted (`Core.String` opts in) and `*q = "longer"` is `StrictSharedImmutableWrite` (M3); stage 4 with W-144 | (not in the design; SAFE-1 accepted `Peek2`'s write, M3(c)) | W-348 |
| EX-M-5 `Alt` | NEW-SYNTAX | the realigned program, a value payload, is accepted; the old `case .Some(ref s)` would be `StrictRefFromShared`; stage 4 plus the `Optional` redesign | accepted with a shared-kind `ref` payload | W-347 |
| EX-M-6 `Alt2` | NEW-SYNTAX | `StrictInvalidatingThroughShared` at `*d = ...` with a copied payload `p: i32*` | the same diagnostic with `ref p` | W-347 (program only) |
| EX-TM-1 `Longest` | NEW-SYNTAX | accepted: `a->Size()` binds `*a` frozen, `Core.String` being `Core.SharedImmutable`; in a caller both pointees are held by the result, frozen (the parameters are `const`), for its lifetime (T5(d)), a caller's write to either through any other path being `StrictBorrowedObjectMutated`; stage 4 with W-144 (amended 2026-10-28, review fold: A-B-2) | accepted; a caller's `Plain` write to an argument under a live result accepted | reason, and a caller's writes under a live result (W-349) |
| EX-TM-3 `Use` | ACCEPTS-UNCHECKED (`String` half: nightly exit 0) | unchanged; `p->Size()` binds on a closed place, and `s = "def"` writes through the owner, a closed place under no frozen loan, so M3's `Core.SharedImmutable` paragraph does not apply (amended 2026-10-28, review fold: A-B-1) | unchanged | none |
| EX-TM-8 `Pick` | NEW-SYNTAX | accepted: returns a reference expression | accepted | none |
| EX-TM-8 `UsePick` | NEW-SYNTAX | `StrictExclusiveBorrowConflict` at `q2->AsSlice()`: `z` is an exclusive `ref` on the closed `x` and `y`; stage 4 | `StrictInvalidatingThroughShared` at `z = ...` | W-347 |
| EX-TM-8 `Launder1` to `Launder5`, `Wild`, `Wild3`, `Load` | as before | unchanged; re-traced (amended 2026-10-28, review fold: A-M-2, A-B-2): a `Core.Slice(i32)` receiver bound on a local (`Launder1`'s `s.Subslice`, `Launder3`'s `b.AsSlice`) is a frozen loan on a closed place; `Launder4`'s `o.Get()` binds a copy-represented `Core.Optional(i32*)`, an adapter of `MaybeUnformed(i32*)` (section 0.1), so it forms no loan on `o` and the loan on `x` its value carries is unchanged; `Load`'s result also holds the caller's `*q` (T5(d)), which in `Wild3` is ⊥ and needs the T6 `unsafe` first; no diagnostic changes | unchanged | none |
| EX-TM-9 `F`, `F2`, `F3` (new) | `F`: ACCEPTS-UNCHECKED (nightly exit 0, prints 3); `F2`, `F3`: NEW-SYNTAX | `F`: `StrictRefFromShared`; `F2` (an `exclusive i32*`) and `F3` (`unsafe *ptr`) accepted; stage 4 | `F` accepted (a shared-kind `ref`) | W-347 |
| p005434 `Valid1`, `ValToRef`, `Conditional` | NEW-SYNTAX (`bound`) | the definitions accepted in both modes: reference returns, not bindings; a call checks T5(d): on a local, the pointee is held by the result and the caller's other paths may not write it while the result lives; through a parameter `p: i32*` to an open place, `Valid1(p)` is `StrictBorrowFromShared` in Strict, `PermissiveAliasedExclusive` in Permissive (amended 2026-10-28, review fold: A-B-2) | accepted, definitions and calls | reason; calls through open places (W-349) |
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
10 each; fork/decision-log.md about 120 and 60, fork/safe/plan.md about 80 and
40, work-items.json four notes. Heading changes: six renamed, all H3 (spatial
SP2 and SP4; mutation M5, EX-M-4a, EX-M-4b and EX-M-5), and three added
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
-   **R-2 a prelude `Core.SharedImmutable` opt-in is false.** Falsifier: a
    prelude function of `Core.String`, `Core.Slice`, `Core.Buf`,
    `Core.Optional` or `Core.Box` that writes its type's storage through a
    shared path or returns a mutable pointer into it (`Box.DerefShared` returns
    the pointee, not the box, and is the one to check), or a language-level
    write the rules still admit through a shared path: a whole-object or field
    assignment, an `addr` call, a non-`const` pointer formed to a sub-object
    (amended 2026-10-28, review fold: A-B-1; rev 1 checked prelude functions
    only, and review A's `Peek2` was such a write until M3's new paragraph).
    Then that opt-in is withdrawn (D-SAFE2-5's break condition) and its
    examples re-measured.
-   **R-3 the storage reading of D-SAFE2-3.** Falsifier: an upstream text that
    counts memory reached through an owning pointer as the object's storage for
    values.md:461-462. Then `Core.Buf`'s `Set` takes `addr self` (W-144) and
    EX-TM-3's `buf.Set(1, 7)` under the live view `v` becomes
    `StrictBorrowedObjectMutated`.
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
    16 H3 2, bullets 64, numbered 4, rows 51, 712; values.md H2 13 H3 16 H4 8,
    bullets 132, rows 11, 1570; README.md H2 18 H3 63 H4 28 H5 5, bullets 341,
    numbered 3, rows 7, 4022; arithmetic.md H2 7 H3 4 H4 2, bullets 51, 332;
    fork/safe/plan.md H2 15 H3 28 H4 2, bullets 45, numbered 28, rows 172, 2573;
    fork/decision-log.md H2 2 H3 45 H4 1 H5 6, bullets 54, rows 11. Expected
    deltas, every one a number (amended 2026-10-28, review fold: B-m5; rev 1
    said "plus the checklist rows added"): safety/README.md rows +4 (A.1.3),
    bullets +1 (A.1.2); mutation_safety.md H3 +2 (A.2.14), rows +5 (A.2.9 +3,
    A.2.17 +2), bullets +6 (A.2.8 +1, A.2.9 +3, and the toc hook's two entries
    for the new H3s); temporal_safety.md H3 +1 (A.3.14), rows +2 (A.3.10 +1,
    A.3.13 +1), bullets +3 (A.3.2 +1, A.3.10 +1, the toc entry for EX-TM-9);
    rust_interop.md rows +1 (A.6.2); fork/safe/plan.md H2 +1 (B.3.8), rows +7
    (B.3.2 +4, B.3.6 +3); initialization_safety.md, spatial_safety.md,
    values.md, README.md, arithmetic.md and fork/decision-log.md 0 everywhere,
    numbered items 0 everywhere. Any other change is a defect to repair by
    rephrasing, recorded in the message.
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
    after; plus this plan's own quotes (section 0.1) re-read at that tip.
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

Filled in by the fixer (section 3 step 4).

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
    at 2407efa74 and a reviewer diffs them.
4.  R31 and the style hook (SAFE-1's hand-off note 4 applies unchanged):
    never let a `#NN`, a list marker, `+`, `-` or a digit and a period start a
    prose line; write "PR 53", "proposal 5434" or "p005434"; headings never end
    in punctuation; code blocks inside pages are fenced as the pages already
    fence them.
5.  Do not touch slices.md, type_safety.md, terminology.md, the stubs, the
    toolchain, the prelude or any golden; do not edit PR 67's branch except by
    step 6 of section 3; do not push before section 3 step 5 is dry; do not
    open or edit a PR.
6.  Every count and cite in a commit message is measured on that commit's
    tree (R10); a moved anchor is reported, never silently taken.

## Appendix A. Page replacements, verbatim (commit 1)

Paths are under docs/design/; line numbers are 2407efa74's. Each block's text
goes into the page as written, without the fence.

### §A.1.1 safety/README.md :146-155, Soundness model, a paragraph inserted

Insert after the paragraph that ends "amended 2026-10-12, document-review fold:
D-8)." (its parenthesis begins "(see" and a link to the mutation page) and
before "## Safety modes":

<!-- google-doc-style-ignore -->

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
and before "### C++ call allowlist":

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
exclude the storage of a `Core.SharedImmutable` type, a `Core.String` or
`Core.Slice` field among it, which only an exclusive path writes
([Mutation safety](mutation_safety.md), M3; realigned <date>, SAFE-2: W-347,
W-348).
```

<!-- google-doc-style-resume -->

### §A.1.6 safety/README.md :560-566, Build modes, the blockquote replaced

Replace the blockquote that begins "> **Withdrawn (fork amendment 2026-10-12,
F-013 D-SAFE-14).**" and ends "> is kept as history." with the block, whose
label is dated by SAFE-2's commit and names the 2026-10-12 note it replaces
(amended 2026-10-28, review fold: B-M5; rev 1 dated the new note 2026-10-12):

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
> the build; see Spatial safety. The paragraph above is kept as history.")
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
functions `Peek` and `Peek2` of EX-M-4d, were compiled and run on the
2026.10.12 nightly toolchain and their outcomes are stated with them (EX-M-4c
and EX-M-4d added <date>, SAFE-2: W-348).
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
`Core.SharedImmutable`'s promise, without which review A's `Peek2` breaks it):

<!-- google-doc-style-ignore -->

```markdown
Everything else, reads, overwriting `Plain` fields, `addr` and `const` methods,
is permitted through any number of aliases at once, but for the writes of a
`Core.SharedImmutable` type's storage that the next paragraph but one names
(realigned <date>, SAFE-2: W-348; this sentence ended "is permitted through
any number of aliases at once.").
```

```markdown
One more class of write needs exclusive access although it invalidates
nothing: a write of a `Core.SharedImmutable` type's storage
([Value bindings](#value-bindings)), a whole-object or a field assignment of
such a type, a `Plain` one included. Through `T*`, through `addr self`, or to
an open place such as a global
([temporal safety: vocabulary](temporal_safety.md#vocabulary)), it is
`StrictSharedImmutableWrite`, a non-`Plain` one staying
`StrictInvalidatingThroughShared`; through the owner of a closed place it is
permitted while no frozen loan on the place is live and is
`StrictBorrowedObjectMutated` while one is. This is the language half of the
facet's promise that no path but an exclusive one writes the type's storage,
which a frozen loan on an open place relies on. `Core.String` and
`Core.Slice(T)` are `Plain` and opt in, so `*q = "longer"` through a `str*` is
rejected in Strict (EX-M-4d's `Peek2`), and `s = "def"` through the owner under
a live `const Core.String*` stays accepted (the temporal page's EX-TM-3). The
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
access). Replace the bullet "`ref self: const Self` and by-value `self` are
const access: the body mutates nothing in `self`, and a call is permitted
through every kind." with the second block.

<!-- google-doc-style-ignore -->

```markdown
it may assign `Plain` fields (`i32`, the pointer kinds), but a field of a
`Core.SharedImmutable` type, `Core.Slice` or the prelude's non-owning
`Core.String` among them, only as M3 allows such a write, so a setter of a
`Core.String` field takes `ref self` (realigned <date>, SAFE-2: W-348; this
clause read "it may assign `Plain` fields (`i32`, the pointer kinds,
`Core.Slice`, the prelude's non-owning `Core.String`),"),
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
stating `Plain` assignment as accepted does not hide M3's new paragraph):

<!-- google-doc-style-ignore -->

```markdown
Through a `T*` the same assignment is `StrictSharedImmutableWrite` in Strict,
`Core.String` being `Core.SharedImmutable` (M3; added <date>, SAFE-2: W-348).
```

<!-- google-doc-style-resume -->

### §A.2.8 safety/mutation_safety.md :415-470, Value bindings, the section body replaced

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
    object's, which is why `Core.Buf`'s by-value `Set` stays callable on a
    borrowed `Buf`.
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
first: every write of the type's storage through a shared path, a whole-object
assignment included and a `Plain` one among them, is rejected in Strict by M3
(`StrictSharedImmutableWrite`). The author keeps the second, what no check of
the language sees: every field is private, no `addr` method writes `self`, no
function writes the type's storage through a shared path or returns a
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

The memory-safety argument, and what the rule costs. A frozen loan on a closed
place is sound because every carrier of the place is in the body's view and a
carrier of a local cannot escape it (the Store rule and T5(b)); on an open place
of a `Core.SharedImmutable` type, because M3 rejects every Strict write of the
object through a shared path, the live shared path excludes the exclusive ones
(M2), and the opt-in's obligation covers what the checker cannot see. A write by
unchecked code, a Permissive body, C++ or an alias an `unsafe` binding promised
away, is the erroneous behavior proposal p005434 keeps for it
(p005434:670-672), never undefined behavior, because the safe-code optimizer
assumes nothing about it (the temporal page's T8 emits no `noalias` on an open
place), and the Debug build detects it: Debug keeps, in shadow memory keyed by
object address and never in the object's layout, a per-object count of live
frozen loans, incremented when the binding is formed and decremented at its
last use as the stage-4 checker computes it, and a `Plain` assignment through
`T*`, to a field or to the whole object, or an `addr self` call, whose target's
count is non-zero reports `MutationDuringValueBinding`. The rule rejects in
Strict what the rule of 2026-10-12 accepted: a `Plain`-field write during a
binding even where it frees nothing (EX-M-4c), the aliased write of EX-M-1
while a `bound` result lives (the temporal page's T5(d)), a by-value call or a
`let` of a type that does not opt in, through a shared pointer whose aliases the
body cannot see (EX-M-4d's `Peek`), and a `Plain` assignment of a
`Core.String` or `Core.Slice(T)` through a shared pointer (EX-M-4d's `Peek2`).
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
"What a stale read costs is correctness").

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
`bound` argument, B-m6 for the Debug clause, B-M5 for the W ids).

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
-   `StrictSharedImmutableWrite`: "write to `{0}` of `Core.SharedImmutable`
    type `{1}` through a shared path; use an `exclusive` pointer or `unsafe`",
    at the write, with a note at the type's opt-in (M3; realigned <date>,
    SAFE-2: W-348).
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
    nothing, the write being erroneous and defined. It reports what unchecked
    code can still do, a Permissive body, C++ or an alias an `unsafe` binding
    promised away, and never a Strict body's write, which is rejected first
    (realigned <date>, SAFE-2: W-348; the superseded 2026-10-12 message read
    "carbon: mutation of an object during a live value binding; terminating").
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
EX-M-4a, EX-M-4c and the functions `Peek` and `Peek2` of EX-M-4d use only the
upstream prelude and were compiled on the 2026.10.12 nightly toolchain with
`carbon compile --output-last-input-only` and no `package` line, then linked
and run (EX-M-4c and EX-M-4d added <date>, SAFE-2: W-348); EX-M-4b and EX-M-4d's
`BufSize` use the fork prelude's `Core.Buf`, which that toolchain lacks; every
other example is NEW syntax.
```

<!-- google-doc-style-resume -->

### §A.2.11 safety/mutation_safety.md :546-566, EX-M-1

In the code block, replace the four lines from " let first: const i32* =
vec->Get(0);" through " vec->Push(3); // fine: a, b, first
are dead (NLL)" with the first block. In the prose, replace "`Get` is `bound
self` so its result is a shared loan on `*vec`." with "`Get` is `bound self`
so its result keeps `*vec` borrowed.", and replace the two sentences from
"`first` is a shared loan too," through "`vec->Push(3)` is accepted." with the
second block.

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

<!-- google-doc-style-resume -->

### §A.2.12 safety/mutation_safety.md :615-634, EX-M-4a

Rename the heading "### EX-M-4a: A `Plain` value binding" to "### EX-M-4a: A
value binding that copies". Replace the code block's first two comment lines,
"// EX-M-4a (today's syntax; accepted today and in Strict — amended 2026-10-12,
review fold: A-8, B3:" and "// i32 is Plain, the binding copies eagerly
(D-SAFE-17), there is no loan to invalidate; b is 1)", with the first block.
Replace "Rule M8, the `Plain` case. `i32` is `Plain`, so `b` acquires eagerly
and holds no loan;" with the second block.

<!-- google-doc-style-ignore -->

```carbon
// EX-M-4a (today's syntax; accepted today and in Strict — amended 2026-10-12, review fold: A-8, B3;
// realigned <date>, SAFE-2: W-348: i32's value representation is a copy, so the binding holds no loan; b is 1)
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

Insert before "### EX-M-5: Payload references through a shared path":

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
// EX-M-4d (Peek, Peek2: today's syntax, accepted today; BufSize: fork prelude — added <date>, SAFE-2: W-348)
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
`StrictSharedImmutableWrite`. Outcome: `Peek` and `Peek2` ACCEPTS-UNCHECKED —
the nightly compiles both with exit status 0; `Peek(&a, &a)` for `a.n == 1`
prints `1`, and `Peek2(&x, &x)` for `x == "ab"` prints `6`, `s` reading the
string `q` wrote, the erroneous behavior Strict now prevents; `BufSize` is
fork prelude, not compile-verified in this PR. Stage 4, with W-144 for the
opt-ins.
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
| M8 borrowed object through a shared pointer, `Core.SharedImmutable` (added <date>, SAFE-2: W-348) | EX-M-4d | ACCEPTS-UNCHECKED for `Peek` and `Peek2` (nightly exit 0, print 1 and 6); `BufSize` fork prelude | 4 (W-144) |
| M5 payload bindings (realigned <date>, SAFE-2: W-347) | EX-M-5 | NEW-SYNTAX | 4 plus the `Optional` redesign |
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
with "Invalidating operations require exclusive access, and so do the writes of
a `Core.SharedImmutable` type's storage (M3, D-SAFE-17; added <date>, SAFE-2:
W-348); everything else is permitted through any number of aliases." (amended
2026-10-28, review fold: A-B-1). In the D-SAFE-20 bullet replace "and
`Core.Box(T)` are this page's items;" with "`Core.Box(T)` and
`Core.SharedImmutable` (opt-in only, implying `Core.Freeze`; added <date>,
SAFE-2: W-348) are this page's items;". In the closing paragraph replace "the
pointer kinds and the `ref`-kind inheritance of M1 are D-SAFE-7 and D-SAFE-8,"
with the second block.

<!-- google-doc-style-ignore -->

```markdown
-   **D-SAFE-17 — Value bindings through shared pointers.** A value binding of
    a type whose value representation is a copy holds no loan; any other binds
    a borrowed object (proposal p005434) under a frozen loan for its lifetime,
    so Strict prevents every mutation of the object through any path,
    `StrictBorrowedObjectMutated` or, for an invalidating one,
    `StrictSharedBorrowInvalidated`; the loan is formed on a closed place, or
    on an open place for a `Core.SharedImmutable` type (an `unsafe impl` opt-in
    whose shared-path writes M3 rejects, which the prelude takes for `String`
    and, for a `Freeze` argument, `Slice`, `Buf` and `Optional`, and for `Box`
    when W-144 adds it), and the binding is `StrictBorrowFromShared`
    otherwise; a binding from a
    materialized temporary owns the storage. This is proposal p005434's plan to
    prevent mutation of borrowed objects in the strict dialect, kept. Break
    condition: upstream relaxes p005434:663 under its :665-669 conditions, or a
    prelude opt-in is shown false (realigned <date>, SAFE-2: W-348; the
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
owner kills it."). Bullets plus one.

<!-- google-doc-style-ignore -->

```markdown
The rules use seven words, fixed by D-SAFE-10, and two more, _closed_ and
_open_, added <date> by SAFE-2 (W-347, W-348).
```

```markdown
-   A _loan_ is a triple of a place, a _kind_ and an _origin_. The kind is
    _exclusive_, _shared_ or _frozen_, the last the loan of a borrowed object
    or of a `const` `ref`, under which no path writes the place's storage
    (added <date>, SAFE-2: W-348); the origin is the expression that formed the
    loan, which the diagnostics name.
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
    whose loan set is not closed, through a free loan or through ⊥. An
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
by-value `self` are const access." with the second block.

<!-- google-doc-style-ignore -->

```markdown
Every `ref` binding is exclusive access to its referent, or a frozen read of it
when its type is `const`, whatever its source, and a value binding of a type
whose value representation is not a copy binds a borrowed object, frozen for
the binding's lifetime. Through `T*` or `const T*` such a binding is formed
only on a closed place or, for a frozen one, a `Core.SharedImmutable` type, and
is an `unsafe` operation otherwise, so the `const T*` row's receivers meet that
rule when they are called through a shared pointer (T2); and the `T*` row's
`Plain` writes exclude the storage of a `Core.SharedImmutable` type, a
`Core.String` or `Core.Slice` field among it, which only an exclusive path
writes (the mutation page's M3; realigned <date>, SAFE-2: W-347, W-348).
```

```markdown
`ref self: const Self` and by-value `self` are const access, and a call of
either binds `self` under the rules of [`ref` bindings](#ref-bindings) and T2
(realigned <date>, SAFE-2: W-347, W-348).
```

<!-- google-doc-style-resume -->

### §A.3.4 safety/temporal_safety.md :191-218, `ref` bindings, the section body replaced

Keep the heading "## `ref` bindings"; replace its two paragraphs and the
"Narrowing" blockquote, from "A `ref` binding inherits the kind of its source
(D-SAFE-8)." through "because a shared-kind `ref` is, by construction, one alias
among many.", with:

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
pointer loaded from memory, a free or ⊥ pointer, is an `unsafe` formation,
spelled at the binding as T6 spells a binding through a ⊥ carrier
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
rev 1 kept a `bound ref`'s exclusive loan under a `val` result).

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
    held by the result: while the result lives no carrier but the result and
    the carriers copied from it writes the pointee, and the result writes it
    only as its own kind allows, never through a `const T*`; an
    `exclusive T*`'s pointee is reached by no other path at all. On a closed
    place T4 enforces this against every carrier. On an open place it needs
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

### §A.3.13 safety/temporal_safety.md :900-968, EX-TM-8's `UsePick`

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
of the first block are the page's own, unchanged.

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
    carry loans.", read "fails-stop in every build mode" in SP2, and read in
    SP4 "no build flag disables checks, and the strategy's promise of an
    unsupported disable for benchmarking is withdrawn by the fork, dated".)
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

### §A.5.10 safety/spatial_safety.md :552-566 and :573-575, Alternatives, the build-flag bullet and the mode-gated sentence

Replace the bullet from "**A build flag that disables the checks.**"
through "which is also the program that would ship." with the first block. In
the "Mode-gated checks" bullet replace "but not of a bounds violation." with the
second block.

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
    build flag that disables the checks." and began: "The strategy's build
    modes section promised an unsupported way to disable the default
    hardening in release builds for benchmarking, and attempt C carried it as
    an `--unhardened` build flag beside its hardened runtime core. The
    synthesis withdraws it (D-SAFE-14, review fold A-13(c) in
    fork/safe/plan.md) for two reasons."; it ended: "and a benchmark that
    wants the unchecked build measures the program with the accessor at its
    hot sites, which is also the program that would ship.")
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
are stage 4." with the second block.

<!-- google-doc-style-ignore -->

```carbon
fn At[bound self: Self](i: i64) -> const i32*;      // → fn at<'a>(&'a Self, i: i64) -> &'a SharedView<i32>   (stage 5 with Freeze, else &'a SharedView<Self> at stage 4; never &'a i32 for an exported class — A-9; receiver realigned <date>, SAFE-2: W-348, was &'a SharedView<Self>)
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
    in a `Core.Buf` block, and a by-value `Set` that writes that block, like
    `Core.Buf`'s, is callable on the frozen receiver from Carbon or from Rust
    through the same `&'a Self` (the mutation page's
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
D-SAFE-13 I5).**" (the one under "Types may define additional initialization
for the hardened build mode", not the move blockquote at :2175, which stays)
with the block, whose label is dated by SAFE-2's commit and names the
2026-10-12 amendment it replaces (amended 2026-10-28, review fold: B-M5; rev 1
dated the new "Fork note" 2026-10-12):

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
D-SAFE-15):**" with:

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
> superseded 2026-10-12 text read: "The performance-build row above, under
> which the behavior is not defined, is withdrawn for Carbon code.")
```

<!-- google-doc-style-resume -->

## Appendix B. Records, verbatim (commit 2)

Each B.1 block is applied twice, to the F-013 entry of fork/decision-log.md and
to the same text in fork/safe/plan.md section 0.3, which are identical at
2407efa74 (measured: `diff` of fork/decision-log.md:2936-3800 against
fork/safe/plan.md:221-1085 prints nothing; the plan's line number is the log's
less 2715, as measured). The line numbers given are the log's. `<sha1>` is
commit 1's short hash.

### §B.1.0 D-SAFE-2 (log :2952-2967, plan :237-252), S0's scope and break condition

Added 2026-10-28, review fold: B-M4 (rev 1 scoped S0 on the strategy page,
A.1.1, and left D-SAFE-2 unscoped, so that its break condition fired trivially
in the benchmarking build, where overflow is undefined behavior). Replace "A
Strict function body cannot cause a safety bug provided" with the first block,
and "Break condition: a program that Strict accepts with no `unsafe` spelled
and that exhibits a safety bug (terminology.md :150-176) — a model bug;" with
the second block.

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

<!-- google-doc-style-resume -->

### §B.1.1 D-SAFE-8 (log :3098-3121, plan :383-406), the bullet replaced

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
only where the checker established them —" with the fifth block.

<!-- google-doc-style-ignore -->

```markdown
a _loan_ is (place, kind ∈ {exclusive, shared, frozen}, origin), a frozen
loan, a borrowed object's or a `const` `ref`'s, excluding every write to its
place; a place is _closed_ in a body when every carrier of a loan on it is in
the body's view and _open_ otherwise (realigned <date>, SAFE-2: W-348;
fork/safe/safe2-plan.md D-SAFE2-3, D-SAFE2-4; the kinds were "{exclusive,
shared}");
```

```markdown
`let ref r = x;` exclusive, and every `ref` binding exclusive, or frozen for a
`const` type, formed on a closed place and, unmarked on an open place,
`StrictRefFromShared` (D-SAFE-8); a value binding of a borrowed object, whose
type's value representation is not a copy, is a frozen loan, on an open place
only for a `Core.SharedImmutable` type and `StrictBorrowFromShared` otherwise —
from a materialized temporary it owns the storage instead, D-SAFE-17, RR-5 —
and a value binding of a copy-represented type a read with no loan — D-SAFE-17,
M8 (realigned <date>, SAFE-2: W-347, W-348; this text read "a value binding of
a non-`Plain` type is a shared loan — from a materialized temporary it owns the
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
of D-SAFE-9's "everything else is permitted"). Replace "Everything else (reads,
overwriting `Plain` fields, `addr`/`const` methods) is permitted through any
number of aliases." with:

<!-- google-doc-style-ignore -->

```markdown
Everything else (reads, overwriting `Plain` fields, `addr`/`const` methods) is
permitted through any number of aliases, but a write of a
`Core.SharedImmutable` type's storage, a whole-object or field assignment of
such a type and a `Plain` one included, needs exclusive access too:
`StrictSharedImmutableWrite` through `T*`, `addr self` or an open place, so
that D-SAFE-17's frozen loan on an open place of such a type is sound
(realigned <date>, SAFE-2: W-348; fork/safe/safe2-plan.md D-SAFE2-5; this
sentence read "Everything else (reads, overwriting `Plain` fields,
`addr`/`const` methods) is permitted through any number of aliases.").
```

<!-- google-doc-style-resume -->

### §B.1.3 D-SAFE-11 (log :3297-3354, plan :582-639), clauses (a) and (d)

In (a) replace "with kind = the parameter's kind (`ref`/`exclusive T*` →
exclusive, value/`T*`/`const` → shared), a mixed set taking the weakest kind
(D-SAFE-8, A-5);" with the first block. Replace clause (d), from "(d) For the
duration of a returned loan" through "review fold: A-13(b))." with the second
block (amended 2026-10-28, review fold: A-B-2, A-m-1, B-M5).

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
`bound` pointer argument is held by the result, written through no other
carrier while the result lives, on a closed place by T4 and on an open place
only for a `Core.SharedImmutable` type, else `StrictBorrowFromShared` or
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
item's." with the second block.

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
benchmarking promise removes the benchmarking build with it (added <date>,
SAFE-2: W-351).
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

Replace the bullet from "**D-SAFE-17 — Value bindings through shared
pointers (MS-5, ratified" through "then the eager-copy alternative is
adopted." with the block, which quotes the whole superseded bullet and carries
none of its 2026-10-12 marks (A-8, B3, B13(c), RR-5) on rewritten text
(amended 2026-10-28, review fold: B-M5, A-B-1, A-M-2, A-m-2, A-m-4; rev 1
dropped "Memory safety holds ..." and the alternative's "simplest" from the
quote, left "A-8, B3" and "B13(c)" on rewritten sentences, kept "of a
non-`Plain` type" in the temporary's sentence, listed the opt-ins
unconditionally and cited values.md:461-462 for the storage reading).

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
    exclusive one writes the type's storage: M3 rejects every Strict write of
    such a type's storage through a shared path, a whole-object `Plain`
    assignment included (`StrictSharedImmutableWrite`), and the author's
    obligation covers what the checker cannot see (every field private, no
    `addr` method writing `self`, no function writing the storage through a
    shared path or returning a non-`const` pointer or `ref` into it, no stored
    self-pointer). It implies `Core.Freeze`; the prelude opts in for
    `Core.String` and, under `forall [T: Core.Freeze]`, for `Core.Slice(T)`,
    `Core.Buf(T)` and `Core.Optional(T)`, and for `Core.Box(T)` once W-144
    adds it (W-144). Any other binding of a borrowed object on an open place
    is `StrictBorrowFromShared` (EX-M-4d), fixed by an owner or an
    `exclusive T*`, `Core.Guarded(T)`, `value_rep = const Self`, a `var`
    copy, or `unsafe` at the binding with the obligation that no path mutates
    the object while the binding lives. The object's storage is its own bytes
    and sub-objects; storage reached through a pointer it holds is another
    object's (the reading of values.md:461-462's "the object or its storage"
    that fork/safe/safe2-plan.md D-SAFE2-3 makes and its risk R-3 records), so
    `Core.Buf`'s by-value `Set` stays callable on a borrowed `Buf`. Mutation
    by unchecked code — a Permissive body, the aliases an `unsafe` binding
    promised away, C++ — stays erroneous (p005434:670-672), never undefined
    behavior (T8 emits no `noalias` on an open place), and is Debug-detected
    by a value-binding shadow flag: Debug keeps, in shadow memory keyed by
    object address (never in the object's layout), a per-object count of live
    frozen loans, incremented when the binding is formed and decremented at
    its last use as stage 4 computes it; a `Plain` assignment through `T*`,
    to a field or to the whole object, or an `addr self` call, whose target's
    count is non-zero reports `MutationDuringValueBinding`, "carbon: mutation
    of a borrowed object; terminating". A value binding initialized from an
    initializing expression — a materialized temporary, values.md:186-192's third source,
    neither `*p` nor an owner — takes ownership of the materialized storage,
    values.md:192's `var` rule applied to `let`, and carries no loan on it,
    so `let o: Core.Optional(i32) = Core.Optional(i32).Some(1);` followed by
    `o.HasValue()` on the next line is accepted; the loans carried _by_ the
    value are unaffected, which is why EX-TM-7b's view of a temporary `Buf`
    stays `StrictBorrowOfTemporary`. Alternative recorded and rejected: eager
    acquisition for every type (always copy — not upstream's rule and costly
    for large owning types; a type's `value_rep` is upstream's way to choose
    a copy). Consequence for Rust (D-SAFE-19): a by-value parameter of a
    borrowed `Freeze` type exports as `&T`. Break condition: upstream relaxes
    p005434:663 under its :665-669 conditions (W-348's own), or a prelude
    `Core.SharedImmutable` opt-in is shown false, by a prelude function or by
    a language-level write through a shared path, which withdraws that opt-in
    in a dated edit.
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

### §B.1.8 D-SAFE-19 (log :3645-3710, plan :930-995), the mapping, verdict parts (1) and (3), the break condition

Four replacements in the bullet. (i) Replace "(EX-TM-3, EX-M-1), so an
`IntVec` reachable" with "(EX-TM-3; EX-M-1's write under a live `first` is
rejected since SAFE-2, W-349), so an `IntVec` reachable", and insert the first
block after "(amended 2026-10-12, review fold: A-9);" (the end of the `const
T*` clause). (ii) In verdict part (1) replace "`const T*` as
`&SharedView<T>`, with `bound`-expressible lifetimes," with "`const T*` as
`&SharedView<T>`, a by-value parameter of a borrowed `Freeze` type as `&T`,
with `bound`-expressible lifetimes,". (iii) In part (3) replace
"(`SharedView`/`SharedSlice` instead, the D-SAFE-17 case generalized — moved
here from part (1), A-9)" with the second block. (iv) Append the third block
after "and the page says so." at the bullet's end.

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
2026-10-28, review fold: A-B-1, A-B-2, A-m-3, B-M1):

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
RG-1's H1.13 row had not quoted it, and PR 67's register re-classifies H1.13
ALIGNED; I5's text gained the customization and lost the word "promotes").
```

<!-- google-doc-style-resume -->

### §B.3.1 fork/safe/plan.md, a pointer paragraph after Status

Insert after the Status paragraph (it ends "(precedent: commit 119b35439's
message).") and before "**Items:**":

<!-- google-doc-style-ignore -->

```markdown
**Realigned (<date>, SAFE-2):** D-SAFE-8, D-SAFE-10's vocabulary, T2, T4 and
T8, D-SAFE-11(a) and (d), D-SAFE-13's I5, D-SAFE-14, D-SAFE-15, D-SAFE-17,
D-SAFE-19, D-SAFE-20 and D-SAFE-21 in §0.3, and the §1, §4.1 and §4.3 text that
states them, were realigned to upstream under R32 by fork/safe/safe2-plan.md
(W-347 to W-351 realigned, W-353 closed as a classification corrected). Each realigned
passage carries "(realigned <date>, SAFE-2: W-n)" and quotes the text it
supersedes; the "Realigned notes (SAFE-2)" section after the landed notes
records the commits.
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
first cell is "unverified (any kind)"). Replace "Diagnostics:
`StrictExclusiveBorrowConflict`" with the second block.

<!-- google-doc-style-ignore -->

```markdown
Every `ref` binding is exclusive access to its referent, or a frozen read of it
for a `const` type, whatever its source; a value binding of a borrowed object
holds a frozen loan, the third loan kind; through `T*` or `const T*` either is
formed only on a closed place or, for a frozen one, a `Core.SharedImmutable`
type, and is an `unsafe` operation otherwise; and the `T*` row's `Plain` writes
exclude the storage of a `Core.SharedImmutable` type, which only an exclusive
path writes (§1.6's M3; realigned <date>, SAFE-2: W-347, W-348; the table's
rows are unchanged).
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
(`i32`, pointers; a `Slice` or `String` field, a `Core.SharedImmutable` type,
only through exclusive access, M3 — realigned <date>, SAFE-2: W-348, where this
read "(`i32`, pointers, `Slice`, the prelude's non-owning `String`)")," and in
M3 replace "M3 the no-invalidation rule and `Core.Plain` (D-SAFE-9);" with "M3
the no-invalidation rule and `Core.Plain` (D-SAFE-9), and exclusive access for
every write of a `Core.SharedImmutable` type's storage (realigned <date>,
SAFE-2: W-348);" (amended 2026-10-28, review fold: A-B-1).

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
M8 value bindings, stated (D-SAFE-17, A-8/B3): a value binding of a
copy-represented type reads the object and holds no loan — mutation of the
source afterwards is accepted; a value binding of any other type binds a
borrowed object under a frozen loan for its NLL lifetime, under which every
write to the object's storage is rejected in Strict
(`StrictSharedBorrowInvalidated` if invalidating, `StrictBorrowedObjectMutated`
otherwise), on an open place formed only for a `Core.SharedImmutable` type and
`StrictBorrowFromShared` otherwise, and unchecked code's writes are erroneous
and Debug-reported — and from a materialized temporary it owns the storage and
holds no loan (RR-5; realigned <date>, SAFE-2: W-348; the superseded text read
"a value binding of a `Plain` type copies eagerly and holds no loan — mutation
of the source afterwards is accepted; a value binding of a non-`Plain` type is
a shared loan for its NLL lifetime, under which an invalidating operation on
the bound object is `StrictSharedBorrowInvalidated` and a `Plain`-field write
through another alias is erroneous, Debug-reported").
```

<!-- google-doc-style-resume -->

### §B.3.6 fork/safe/plan.md §4.1 (:1900-1938), the checklist rows

Replace the row whose first cell is "D-SAFE-8 mixed-kind result (A-5)" with the
first block's two rows; replace the row whose first cell is "M8 value binding,
`Plain`" with the second block's first row and the row "M8 value binding,
non-`Plain`" with its second; insert the third block's two rows after that
second row; and replace the row whose first cell is "M5 payload refs" with the
fourth block's row. The first cells are the page checklist's (A.2.17, A.3.13)
word for word (amended 2026-10-28, review fold: B-m4; rev 1 kept the
"non-`Plain`" and "M5 payload refs" rows and worded two first cells
differently from the page).

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
| M8 borrowed object through a shared pointer, `Core.SharedImmutable` (added <date>, SAFE-2: W-348) | EX-M-4d `Peek`, `BufSize`, `Peek2` | ACCEPTS-UNCHECKED (`Peek` and `Peek2`: nightly 2026.10.12 exit 0, print 1 and 6; `BufSize`: fork prelude); Strict `StrictBorrowFromShared` for `Peek`, accepted for `BufSize`, `StrictSharedImmutableWrite` at `Peek2`'s write | p005434:663; `Core.SharedImmutable` (W-144); M3 | 4 with W-144 |
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
place).

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
<fixes>; the fold record is safe2-plan.md's section 8.7. The six items are PR
67's; their notes there read "REALIGNED" or "CLOSED" with this branch's dry
head and are discharged by this branch's land-sequence records commit when it
lands.
```

<!-- google-doc-style-resume -->

### §B.4 fork/inventory/work-items.json (PR 53's ledger), four notes

Append each text to the item's `notes` string, after a space; the file must
still parse (`python3 -I -c 'import json;
json.load(open("fork/inventory/work-items.json"))'`). The W-146 and W-148
notes quote and supersede the lines of those items that state the narrowed
rules, which section 0.5 lists; the items' titles and evidence are left as
written, the notes saying how to read them (amended 2026-10-28, review fold:
B-M6; also A-B-1, A-B-2, A-M-1, A-m-2 for the rules the notes name).

<!-- google-doc-style-ignore -->

```text
W-144: SAFE-2 (<date>, <sha1>; fork/safe/safe2-plan.md D-SAFE2-5): the audit also adds `unsafe impl ... as Core.SharedImmutable {}` for `Core.String` and, under `forall [T: Core.Freeze]`, for `Core.Slice(T)`, `Core.Buf(T)` and `Core.Optional(T)`, and for `Core.Box(T)` when this item adds `Box`, each checked against the facet's obligation (every field private, no `addr` method writing `self`, no function writing the type's storage through a shared path or returning a non-`const` pointer or `ref` into it, no stored self-pointer), and `Core.SharedImmutable` joins the library surface.
W-146: SAFE-2 (<date>, <sha1>; D-SAFE2-11 to D-SAFE2-13): stage 2 also spells the unsupported benchmarking build, the Release build without the bounds check, the division guard, the overflow wrap and the zero-fill (kept as safety README.md's build modes promise it, W-351); the zero-fill is p000257:356-358's hardening initialization, with a type's customization once upstream names its interface (W-353 closed, its classification corrected). Superseded by this note: the title's "`--build-mode=debug|release`" names the supported modes only, and the benchmarking build is a third, unsupported configuration (W-351); the evidence's "the dated blockquote at docs/design/README.md:2147 promoting zero-fill to the Release baseline" reads as the blockquote SAFE-2 replaced with a note that the zeroing is p000257's (W-353), and "the dated blockquote withdrawing the performance-build row, D-SAFE-15" as the blockquote SAFE-2 rewrote to keep the row for the benchmarking build (W-350); the notes' "D-SAFE-14 (fail-stop everywhere, no build flag disables the checks — the benchmarking disable of safety README.md:260-262 withdrawn, A-13(c); break condition: a measured corpus where the checks exceed the strategy's budget — then a per-site `unsafe fn` accessor, never a flag)" reads "fail-stop in every supported build mode, the benchmarking build kept" (W-351), and the fork-benchmark break conditions "a real-world benchmark where the loss of `nsw` exceeds 0.5 percent — an owner call" (D-SAFE-15) and "more than 0.5 percent from zero-fill alone — then scoped to escaped-unformed objects" (D-SAFE-13 I5) are replaced by upstream's, as the realigned decisions state them (W-350, W-353).
W-148: SAFE-2 (<date>, <sha1>; D-SAFE2-3 to D-SAFE2-9): the checker also implements the frozen loan kind and the closed and open place rule; M3's exclusive access for every write of a `Core.SharedImmutable` type's storage; `StrictRefFromShared`, `StrictBorrowFromShared`, `StrictBorrowedObjectMutated` and `StrictSharedImmutableWrite`, each with the Permissive twin `PermissiveAliasedExclusive`; M8's loans keyed on the value representation rather than `Core.Plain`, the Debug shadow count counting live frozen loans and reporting a `Plain` assignment through `T*`, to a field or to the whole object, or an `addr self` call (`MutationDuringValueBinding`, "carbon: mutation of a borrowed object; terminating"); T5(a)'s frozen kind and T5(d)'s immutability of each `bound` argument, a `bound` pointer argument's pointee held by the result; T8's `noalias` with `captures(none)` or `captures(ret: address, provenance)` only where established against every writer (intra-function on the body's own places, on `ref` and `exclusive T*` parameters' places under the whole-package condition, never on an open place). Superseded by this note: the evidence's "proposals/p005434 (`bound`, `ref`, `val`; :83 and :831-832 narrowed by D-SAFE-8 and D-SAFE-11(d))" reads ":83 and :831-832 kept by D-SAFE-8 and D-SAFE-11(d) as realigned" (W-347, W-349); its row names "'M8 value binding, non-`Plain`' EX-M-4b", "'M5 payload refs' EX-M-5" and "'D-SAFE-8 mixed-kind result' `Pick`/`UsePick`" read as fork/safe/plan.md §4.1's renamed rows "M8 value binding, borrowed object", "M5 payload bindings" and "D-SAFE-8 mixed-kind result, a `ref` binding on closed places"; and the notes' "D-SAFE-17 (value bindings; break condition: a corpus where the Debug shadow count's cost is measurable — then opt-in)" reads as the realigned D-SAFE-17, whose break condition is upstream's relaxation of p005434:663 or a prelude opt-in shown false (W-348).
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
step 8, with `<sha1>`, `<sha2>`, the dry head `<head>` and the stamp's `<date>`
filled in, from the file that step names:

<!-- google-doc-style-ignore -->

```markdown
**SAFE-2 (<date>): the six departures realigned (R32 (e)).** Commits <sha1>
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
edits below, every `<date>` its own UTC date and every note citing PR 53's dry
head `<head>` (amended 2026-10-28, review fold: B-M1, B-M2, B-m2, A-M-2,
A-m-3; rev 1 cited `<sha1>`, wrote W-353 "CLOSED by its break condition" at
:355-358, added a check H1.7b with no register row, left H1.13 at DRIFT, and
added no quote row). Its message is "RG-1 records: SAFE-2's realignment of
W-347 to W-351 noted, W-353 closed and H1.13 re-classified ALIGNED, H1.7
widened to Core.SharedImmutable, eleven quote rows added (PR 53 at <head>)".

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
block, and append "; closed <date> by SAFE-2, its classification corrected" to
the Item cell; insert the sixth block as a paragraph after the H1 table and
before "The block's re-basing clause"; append the seventh block to D-RG-20's
paragraph after "and W-350's target becomes the release build's row."; and
append the eighth block to the Status paragraph after "section 4.2's quote
table holds 273 lines." and to section 4.2's paragraph after "and
fork/register/check_greps.sh are the checkers below."

(v) fork/decision-log.md, RG-1's entry: append the eighth block to the
paragraph that begins "_The count._", after "so the register stays a work
queue.".

`<TAB>` in the second and third blocks is one tab character.

<!-- google-doc-style-ignore -->

```text
W-347: REALIGNED <date> by SAFE-2 on PR 53 at <head> (fork/safe/safe2-plan.md D-SAFE2-6): every `ref` binding is `nocapture` and `noalias`, a checked reborrow on a closed place and an `unsafe` formation on an open one, T8 emitting the attributes only where established against every writer; discharged by PR 53's land-sequence records commit.
W-348: REALIGNED <date> by SAFE-2 on PR 53 at <head> (D-SAFE2-3 to D-SAFE2-5, D-SAFE2-7): Strict prevents mutation of borrowed objects, keyed on the value representation, with the opt-in `Core.SharedImmutable` on shared paths, whose shared-path writes M3 rejects; discharged by PR 53's land-sequence records commit.
W-349: REALIGNED <date> by SAFE-2 on PR 53 at <head> (D-SAFE2-9): each `bound` argument is immutable for the duration of the result, a pointer argument's pointee written by no path but the result; discharged by PR 53's land-sequence records commit.
W-350: REALIGNED <date> by SAFE-2 on PR 53 at <head> (D-SAFE2-11): arithmetic.md's three rows are read through the build modes under D-RG-20, the performance-build row standing for the unsupported benchmarking build; discharged by PR 53's land-sequence records commit.
W-351: REALIGNED <date> by SAFE-2 on PR 53 at <head> (D-SAFE2-13): the unsupported benchmarking build is kept as safety README.md:260-262 promises, `unsafe fn GetUnchecked` the supported opt-out; discharged by PR 53's land-sequence records commit.
W-353: CLOSED <date>, its classification corrected (SAFE-2 on PR 53 at <head>; fork/safe/safe2-plan.md section 0.3): the zeroing of every type's storage is upstream's, p000257:356-358, "The entire storage, including any padding bytes, for all types will be at least be zeroed as part of hardening initialization", accepted text at the cut that I5 already cited when this item was filed (PR 53's initialization_safety.md:223-226 at 2407efa74, as p000257:355-358) and that H1.13's quote set left out; nothing upstream changed, H1.13 is re-classified ALIGNED, I5's text gained the customization of p000257:358-360 and lost its "departure", and rg1-quotes.tsv now quotes p000257:356, :357 and :359 for the weekly check. Discharged by PR 53's land-sequence records commit.
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
Amended <date> by SAFE-2 (PR 53 at <head>; fork/safe/safe2-plan.md section
0.3): H1.13 is ALIGNED, so this block holds five DRIFTs, H1.8 to H1.12, and
the register 18 DRIFT, 33 ALIGNED and 104 NONE; H1.7 names
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

Six edits of trunk's fork/ORCHESTRATION.md (1c83422a0 or the records-only
commit after it), the texts below with every placeholder filled; `<tip>` is
the upstream tip the implementer's section 8 item 5 read (amended 2026-10-28,
review fold: B-M3; rev 1 gave only the safe row and a paragraph that named
neither the remaining waits, the held count nor a Next line, and gave no
header, no item 6 text, no PR 67 row and no land-time discharge):

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
| `claude/carbon-fork-0-1-safe` | HELD OPEN as PR #53 — SAFE-1 safe-Carbon design (F-013) at <head>, documentation and records only (gap row 89 expected DONE on document review, W-063 discharged, W-144..W-150); merges first in the land sequence after RG-1's PR (fork/register/rg1-plan.md section 5); amended 2026-10-28 by RG-1's records commit cd3c5b2e1 and its review fix 2407efa74 (R32 (e)); realigned <date> by SAFE-2 (fork/safe/safe2-plan.md; commits <sha1>, <sha2> and the fold commits <fixes>, re-reviewed until dry at <head>): W-347 to W-351 realigned and W-353 closed with its classification corrected, noted on PR 67's ledger by <c2-sha>, the descriptions of PR 53 and PR 67 refreshed. |
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
OP-1's W-352. Next: SC-1's W-139 on PR 60 and OP-1's W-352 on PR 56, then EH-C
(W-346) after the held PRs land, then UA-3; the weekly upstream check of
2026-11-02 runs W-355's scripts over 284 quotes and 89 silence checks.
```

```markdown
W-353 (SAFE-1: realigned <date> by SAFE-2 on PR 53 at <head>,
fork/safe/safe2-plan.md, W-353 closed with its classification corrected; the
land sequence no longer waits at PR 53; when PR 53 lands, its land-sequence
records commit appends to W-347 to W-351 and W-353, in the ledger PR 67
brought to trunk, the note "DISCHARGED <landing date> by PR 53's landing at
<merge commit> (SAFE-2's realignment of <date>; fork/safe/safe2-plan.md)"),
```

```text
DISCHARGED <landing date> by PR 53's landing at <merge commit> (SAFE-2's realignment of <date>; fork/safe/safe2-plan.md).
```

<!-- google-doc-style-resume -->
