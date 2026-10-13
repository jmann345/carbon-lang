<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Optional plan: comparison and the fork design for `Core.Optional` (OP-1, W-058)

**Status:** rev 2, 2026-10-13 -- SIGNED OFF FOR IMPLEMENTATION (sign-off at the
end); folds the two plan reviews of R29(c) (review A, design soundness and
toolchain correctness: APPROVE-WITH-AMENDMENTS with 3 MAJOR and 7 MINOR
findings; review B, concreteness, process, Goodhart and cross-workstream:
APPROVE-WITH-AMENDMENTS with 4 MAJOR and 5 MINOR), each amended sentence or row
marked "(amended 2026-10-13, review fold: A-n)" or "(... review fold: B-n)" and
tabled in the [Review fold record](#review-fold-record-rev-2-2026-10-13); all 19
are folded and none is rejected. Review A's ids A-1..A-10 are review findings;
the rejected alternatives of §7 keep their own A-1..A-10 numbering and are
always cited as "§7 A-n". The fixer re-ran every measurement a finding is about
in its own scratch tree
(`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/op1-fixer`:
a copy of the trunk install carrying §2.1 as extracted from rev 1 and applied
with `git apply`, mutant and prototype copies, copies of the ST-1 and SC-1
installs, and file_test mirrors) and added M-18 to M-22. Rev 1 was the planner's
draft (7aa1497c8). Nothing below is implemented. Branch
`claude/carbon-fork-0-1-op`, cut from trunk 9d3ca60a3, whose toolchain, core and
docs sources are identical to 0bdce60a5 (the only later trunk commits are
fork/ORCHESTRATION.md stamps); trunk has since moved to 162c7e839, again
fork/ORCHESTRATION.md only, which records this workstream ("ids from W-170 and
fork design id F-015 if minted", the merge order "PR 53, PR 51, PR 52, SC-1, PR
54 ..., PR 55 (ST-1), then OP-1", :86-91) and adds its Branches row (:429).
Every line number below is against 9d3ca60a3 and was re-read for this plan.
Every measured outcome in §0.2 was taken in this container with the trunk build
(`/home/user/carbon-build/carbon-trunk`, `carbon version` 0.0.0-0.dev+0bdce60a5)
and its file_test, with the prelude of §2.1 applied to a COPY of the install
tree in a scratch directory; the compositions used copies of the ST-1 install
(0.0.0-0.dev+84ff63560; M-13, M-21) and of the SC-1 installs
(0.0.0-0.dev+bc8b37290, M-14; 0.0.0-0.dev+ff490bd48, M-22) the same way. No
toolchain was built, nothing was installed, no worktree other than this one was
modified, and the owner's runner was not used (R28). OP-1 changes no C++ source
and adds no prelude file, so the trunk busybox compiles every file OP-1 changes
exactly as an OP-1 build would; the trunk file_test differs from an OP-1
file_test only by the three manifest entries of §2.3, which §0.2 handles with a
mirror.

**Item:** W-058 ("W9d: approved Optional design with comparison support", kind
`design-needed`, size M, subsystem core/prelude + docs/design, bullet "Stdlib:
Optional"). **Milestone row:** fork/gap-analysis.md:78, PARTIAL. The row is :79,
:80, :81, :82 and :83 on the cmake, ev, safe, st and sc branches, so records
refer to it by its bullet text (R7) and re-read its line at the merge of trunk
(amended 2026-10-13, review fold: B-4). **Criterion:** the bullet text,
docs/project/milestones.md:203 "Optional" (under "Types with important language
support", :201), read with the W9 **Arbiter** (gap-analysis.md:241-244: "an
approved-design Optional and String with comparison/ownership story") and with
milestones.md:55-56 (language design components "documented, cohesive, and
understandable by evaluators without placeholders"), whose example library
components name "optionals" (:68-70) (amended 2026-10-13, review fold: A-6).

**Outcome this plan commits to:** the placeholder TODO (optional.carbon:28-29)
is answered by a decided fork design, F-015, docs/design/optional.md;
`Core.Optional(T)` gains `==`, `!=`, `<`, `<=`, `>` and `>=` whenever `T` has
them; stdlib/optional_missing_ops.carbon goes SKIP → PASS with its EXPECT
unchanged and re-derived from the design (R16(d)); three PASS programs and three
write-tests-first SKIPs are added, two of them the arbiters of the two items
that keep the row PARTIAL (amended 2026-10-13, review fold: B-2); no existing
golden changes. The row stays **PARTIAL**, bounded by exactly two items filed
here, both operations of `Core.Optional` itself that are missing or broken
through its documented API: an Optional never destroys the value it holds
(W-170), and `Core.Optional(bool)`'s `Get()` and copy crash the compiler
(W-171), whose root cause also makes `Get()`, a copy and `==` on
`Core.Optional(Core.Optional(U*))` return wrong values with no diagnostic, so
W-171 has a second arbiter, optional_nested_pointer, a fourth write-tests-first
SKIP (amended 2026-10-13, implementation review fold: R1-1). That is the test
D-ST-16 (fork/string/plan.md) applied to keep row 79 PARTIAL and named as its
own break condition, so the row-82/row-77 precedents (DONE with filed limits)
are not claimed (D-OP-13). The row moves to DONE only when the arbiters of those
two items PASS in a conformance run of record and F-013's TY4 (PR 53, which
lands first) is no longer falsified by `Get()` on an empty `Optional(T*)`
(W-173) (amended 2026-10-13, review fold: B-2, B-3). Every other residue is a
0.1 limit beyond the bullet's text or another bullet's item (§1.7). All
conformance totals are expected, not of record (Actions is disabled).

**Id allocation (recorded so no workstream collides):** the ledger maximum
across trunk and every live branch is W-167 (ST-1, PR 55), re-scanned for this
plan over trunk (162c7e839) and the 68 local and `origin`
`claude/carbon-fork-0-1-*` refs (and again by the fixer at rev 2 over the same
68 refs: every head unchanged except sc, now 77838fdd5, whose ledger reaches
W-168, one of its two reserved ids; nothing names W-169 or above, or F-015,
beyond trunk's reservation): trunk W-125, ua2 W-127, cmake W-133, safe W-150, sc
W-151 (head 2497d5000), ev W-155, st W-167; the only text on any ref that names
an id from W-170 or F-015 is trunk's own reservation of them for OP-1
(fork/ORCHESTRATION.md:89 and :429, also on claude/carbon-fork-0-1-dd, which
points at trunk's commit). W-151 is SC-1's renumber of its W-144; W-152..W-159
are EV-1's block (PR 54); W-160..W-167 are ST-1's; W-168 and W-169 are reserved
for SC-1's late residues. **OP-1 reserves W-170..W-179**: W-170..W-178 are the
nine residues the planner filed in §1.7, and W-179, held as the spare for a
residue a review finds, is the one review A found: the toolchain diagnoses a
non-final impl that a `final` impl subsumes only where it is used (§1.7)
(amended 2026-10-13, review fold: A-10); a reserved id that goes unused stays
unused and is never reused, and a further residue takes max + 1 at discharge.
Fork design ids run F-006..F-013 on trunk and the held branches and F-014 is
ST-1's; OP-1 mints **F-015** (D-OP-6). Immediately before the discharge commit
writes the ledger, the maximum is re-scanned (§2.6); if any of W-170..W-179 is
taken by then, the residues are re-allocated from max + 1 (skipping every
reserved block) and the landed notes say so.

**Design authority** (each cited where used):

-   proposals/p006357-c-interop-mapping-pointer-types.md (accepted): a nullable
    C++ `T*` maps to `Core.Optional(T*)` (:107-112); "This places a constraint
    on the implementation of `Core.Optional(T*)` that it has the same ABI as a
    C++ pointer, including that the "none" state is represented with a C++ null
    pointer representation." (:247-249); "While we do not yet have an approved
    design for the `Core.Optional` type, it is already in use in the design of
    `for` statements. Adding a design for `Core.Optional` is out of scope for
    this proposal." (:251-253); future work "Add a design for `Core.Optional`,
    as we now have multiple language proposals that depend upon it." (:341-342).
-   docs/design/control_flow/loops.md:88-114 (p001885): `Iterate.Next` returns
    `Optional(ElementType)` (:96), and a `for` loop "behaves conceptually as
    (though an API for `Optional` has not been approved)" a loop over
    `iter.HasValue()` and `iter.Get()` (:104-114).
-   docs/design/README.md:858-860 ("There are no null pointers in Carbon. To
    represent a pointer that may not refer to a valid object, use the type
    `Optional(T*)`."), :3754 (the interop table row `T*` to `Optional(T*)`),
    :3260-3261 (the generic-impl example `impl forall [U: type, T: As(U)]
    Optional(T) as As(Optional(U));`); values.md:1119-1131 (pointers cannot be
    null; "Optional pointers are expected to serve nullable use cases").
-   docs/design/expressions/comparison_operators.md: `EqWith` and `Eq`, `x == y`
    calls `x.(EqWith(U).Equal)(y)` (:248-286); `Equal` and `NotEqual` must not
    both return true for one pair, and "these operations should have no
    observable side-effects" (:312-316), as "the members of an `OrderedWith`
    implementation should have no observable side-effects" (:430-434), from
    which F-015 discloses a divergence (V-3) (amended 2026-10-13, review fold:
    A-2); "The `EqWith` overload is selected without considering possible
    implicit conversions" (:288-289), with the `like` operator as the remedy
    (:289-300); `OrderedWith`, transitivity and consistency under reversal
    (:345-465); "There is no requirement that a pair of types that implements
    `OrderedWith` also implements `EqWith`" and equality refining the order
    (:466-472); comparisons of tuples, structs and data classes "only available
    if it is supported by all element types" (:479-505), pointers not among
    them.
-   docs/design/generics/details.md: conditional conformance (:4457-4597), whose
    motivating example is "A container could be compared to another container
    with the same element type ... if the element type is comparable"
    (:4466-4469); the `Optional(T) as As(Optional(U))` combination example
    (:4655-4665); `final` impls (:5262-5379) and the libraries that may declare
    one (:5381-5417); `OptionalStorage` as the specialization example, with
    `class Optional(T: Movable)` and the storage bound kept out of the public
    API (:6925-7030, :7001-7015).
-   docs/design/sum_types.md: `choice Optional(T)` as the example choice
    (:63-75); `Optional` as a class implementing `Match`, whose "Operations like
    destruction, copying, assignment, and comparison are omitted for brevity."
    (:154-184, :181-182).
-   proposals/p002188-pattern-matching-syntax-and-semantics.md:488-489 and
    docs/design/pattern_matching.md:527-528: "a pattern of the form
    `Optional(T).None` is an expression pattern and is compared using `==`", so
    an accepted design already presupposes `==` on Optional (D-OP-1);
    proposals/p001154-destructors.md:211-227, a considered alternative whose
    `Optional` sketch destroys its value only when it holds one (`destructor
    [me: Self] { if (me.holds_value) value.Destroy(); }`) and opts into
    `TrivialDestructor` when its argument does, beside the adopted rule of
    docs/design/classes.md:1992-2003 (a class is `TrivialDestructor` only if it
    defines no destructor or an empty one and all its members are), which is the
    union and pointer-niche tension W-170 measured (§1.3, M-6) (amended
    2026-10-13, review fold: A-9).
-   docs/design/error_handling.md: D9, `Optional(T)` implements `Try` with
    `BreakType = ()` and no bridge to `Result` (:975-979); the `Try` sketch for
    `Optional` (:392-405) and its EH-A amendment (:416-435), which records the
    landed signature and says "the `match` body above applies verbatim once
    W-058 makes `Optional` a choice" (:432-433); :437-444.
-   fork/decision-log.md, "EH-A: Core.Result, Optional as Try, Result entry
    points" (:5585-5772): D-EH-1 resolved SF-9 as "`Core.Optional` KEEPS its
    placeholder class identity -- it is NOT re-platformed onto `choice` (that is
    W-058's approved-design work, with the pointer null-niche ABI and the
    entry-point `argv: Core.Optional(char*)*` signature to preserve)", and
    W-058's notes require the `Try` impl's signature `final impl forall [T:
    Destroy & OptionalStorage] Optional(T) as Try where .ContinueType = T and
    .BreakType = ()` to be kept.
-   External semantics, cited for the comparison rules only: C++
    [optional.relops] and [optional.nullops] (two empty optionals are equal; an
    empty optional is unequal to and less than an engaged one; two engaged
    optionals compare with the contained type's corresponding operator, `!=`
    with its `!=`); Rust's `core::option` documentation, "Comparison operators"
    (`Option<T>` derives `PartialOrd`, so `None` compares less than any `Some`,
    and two `Some` values compare as their contained values).

V-3: no accepted proposal or leads' direction is contradicted, and two
divergences are disclosed (amended 2026-10-13, review fold: A-2, A-9). The class
identity and the storage strategy are upstream's placeholder (upstream
nightly 2026.10.12's optional.carbon equals upstream-trunk 62f1cc6a3's and
differs from the fork's only by the EH-A `Try` lines, :12 and :56-78), p006357's
ABI constraint and loops.md's `HasValue()`/`Get()` are kept, and the comparisons
follow comparison_operators.md and details.md's conditional conformance. Where
design examples differ from the prelude (`Optional` as a `choice` in
sum_types.md and pattern_matching.md:501-527; `Optional(T: Movable)` with no
storage bound in details.md:6988-7015), the fork records the difference as
residue (W-177, W-176) and does not claim it as design. The fork-level decisions
(the design page itself, `final`, same-type-only comparison, the class kept) are
F-015, recorded for after-the-fact veto (R29(a)). The two divergences, recorded
in F-015 and in the decision-log V-3a register (§2.6): (1)
comparison_operators.md says comparison operations "should have no observable
side-effects" (:316, :434), and OP-1's bodies run `T.Copy` and `T.Destroy` once
per value whenever both operands hold one, because the placeholder `Get()`
returns by copy (:23-24, :40-42; M-5 prints `101 102 202 201` inside one `a ==
b`); a by-reference accessor or matchability (W-177) removes it (D-OP-4); (2)
p002188:488-489 and pattern_matching.md:527-528 spell the empty value
`Optional(T).None`, a value, where F-015 freezes the function `None()` that the
prelude declares and the toolchain's callers use, beside the choice identity
those examples assume (W-177).

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Sub-feature table (verified in-tree at 9d3ca60a3)

| # | Element | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `Core.Optional(T)` | LANDED, placeholder | core/prelude/types/optional.carbon is 204 lines (`wc -l`). `class Optional(T: OptionalStorage)` :30-46: `None()` :31-33, `Some(value: T)` :34-36, `HasValue(self)` :37-39, `Get(self) -> T` :40-42 (each storage `Get` returns by copy, :23-24), `adapt T.Type` :45 (TODO :44). The placeholder TODO is :28-29; upstream's file has it at :27-28, and the fork's EH-A `import library "prelude/try"` at :12 moved it by one line. |
| 2 | `OptionalStorage` | LANDED, private | `private interface OptionalStorage` :16-26 (`Type`, `None`, `Some`, `Has`, `Get`, `Copy`), TODO :16 "Decide how to expose this in the public API". User code cannot name it, so a generic `Core.Optional(T)` needs a bound under which a public impl provides it: `Core.Copy & Core.Destroy`, the default storage's (row 3; M-10). |
| 3 | Default storage | LANDED | `private class DefaultOptionalStorage(T: Copy & Destroy)` :140-143, `{value: MaybeUnformed(T), has_value: bool}`; the non-final blanket `impl forall [T: Copy & Destroy] T as OptionalStorage` :148-179; `Some` assigns the value into the unformed field (:156-165, one `Copy`, M-5); `Get` is `value.value unsafe as T` (:169-171). No `Destroy` impl anywhere in the file, and `MaybeUnformed(T)` runs no destructor (maybe_unformed.carbon:12-15), so the held value is never destroyed (M-6). |
| 4 | Pointer niche | LANDED | `final impl forall [T: type] T* as OptionalStorage where .Type = MaybeUnformed(T*)` :188-204: `None` is `"pointer.make_null"` (:190), `Has` is `not PointerIsNull(value)` (:181, :197-199), comment :186-187 "ABI-compatible with a C++ nullable pointer" (p006357:247-249). |
| 5 | Conversions | LANDED | private `interface OptionalAs(T)` :99-101 with impls `T` to `Optional(T)` (:103-108), `U: ImplicitAs(T)` to `Optional(T)` (:110-115) and `Optional(U)` to `Optional(T)` (:117-126), behind the public `impl forall [T: OptionalStorage, U: OptionalAs(T)] U as ImplicitAs(Optional(T))` (:128-133). No `As` between Optionals (W-175, M-10). |
| 6 | `Copy`, `UnformedInit` | LANDED | `impl forall [T: OptionalStorage] Optional(T) as Copy` :50-54, through the storage `Copy`; `UnformedInit` when the storage is (:48). |
| 7 | `Try` | LANDED (EH-A) | :56-78: `final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try where .ContinueType = T and .BreakType = ()` (:69-70), body over `HasValue()`/`Get()` (:71-76), `FromBreak(unused b: ())` (:77). W-058's notes require the signature to stay; OP-1 changes none of :56-78 (D-OP-7). |
| 8 | Comparison | MISSING | `grep -n 'EqWith\|OrderedWith' core/prelude/types/optional.carbon` is empty. The interfaces (core/prelude/operators/comparison.carbon): `EqWith` :12-17, `constraint Eq` :19-21, `OrderedWith` :24-32 (no `Compare`, TODO :25), `constraint Ordered` :34-36; comparison.carbon `export import`s `prelude/types/bool` (:7). Precedents for `final` comparison impls (the integer ones cross-width, `Int(N)` with `Int(M)`; the float and C++ ones same-type; corrected 2026-10-13, implementation review fold: IR2-5): `final impl forall [N: IntLiteral, M: IntLiteral] Int(N) as EqWith(Int(M))` (int.carbon:93-96) and its `OrderedWith` (:98-104), and the same `final` shape in uint.carbon:125-134, float.carbon:165-170 and cpp/int.carbon:341-375; `impl Char as EqWith(Char)` (char.carbon:49-52) and ST-1's `impl String as EqWith(String)` (string.carbon:116-121 on the st branch) are not `final`; every one defines `NotEqual` explicitly. |
| 9 | Users that fix the API | LANDED | `for` calls `HasValue` and `Get` by name (check/handle_loop_statement.cpp:194, :280-281, :290-291, `CoreIdentifier::HasValue` and `CoreIdentifier::Get`); a nullable C++ `T*` imports as `Core.Optional(T*)` (check/cpp/import.cpp:1481-1507, `MakeOptionalType`) and `Core.Optional(T*)` exports as `T*` (sem_ir/type_info.cpp:149, :190, the `"Optional"` name case; check/cpp/type_mapping.cpp:267-285); `main`'s `argv: Core.Optional(char*)*` (check/handle_function.cpp:733); prelude users iterate.carbon:17, :24-31, :74-81, range.carbon:20-26, cpp/nullptr.carbon:50-54 (`Cpp.nullptr` converts to `Optional(T*).None()`, with `// TODO: impl as EqWith(Self)` at :48) and cpp/slice.carbon:49. |
| 10 | Pointers | LANDED, no `==` | No `T* as EqWith(T*)` in core/ (M-10: `p == q` on two `i32*` is "cannot access member of interface `Core.EqWith(i32*)`"), no pointer comparison builtin (sem_ir/builtin_function_kind.def:150-154), no pointer comparison in the design (comparison_operators.md:479-505, values.md:1119-1131). The comparison impls therefore apply to `Optional(T*)` exactly when `T*` is `Core.Eq`: never for a built-in pointer such as `i32*` (W-174), and for `C*` when the user library that owns `C` implements `C* as Core.EqWith(C*)` (M-18) (amended 2026-10-13, review fold: A-1). |
| 11 | min_prelude | LANDED, separate | toolchain/testing/testdata/min_prelude/parts/optional.carbon:19-35 is its own `class Optional(T: Copy)` with public fields and no impls, included by min_prelude/for.carbon:10 and parts/iterate.carbon:6, so by the two goldens that include for.carbon (check/testdata/for/basic.carbon, for/pattern.carbon). The 315 goldens that include min_prelude/full.carbon (`grep -rl 'INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon' toolchain`) load the install tree's core/ instead (`--expect-full-prelude`, toolchain/testing/file_test.cpp:178-197). |
| 12 | Goldens that use Optional | -- | Of the 315 full-prelude goldens, 29 mention `Optional`, 17 of them in source lines (check: interop/cpp/stdlib/vector_view, vector_view_span, function/import/void_pointer, pointer, union/basic, operators/question_optional, choice/alternative_copy, generic_payload, unit_payload, for/actual; lower: interop/cpp/nullptr, pointer, void, union/basic, primitives/optional, choice/generic_payload, for/bindings). Lower goldens print the prelude functions they instantiate with debug-info lines in optional.carbon (lower/testdata/primitives/optional.carbon:481-484, `line: 189`), which is why moving optional.carbon's lines moves 13 lower goldens and one check golden (M-12). |
| 13 | Conformance | 2 PASS, 1 SKIP | stdlib/optional_basic.carbon PASS (its :23-25 names the missing slice "no `==`"); stdlib/optional_pointer_niche.carbon PASS (its :16 cites optional.carbon:156-179, stale); stdlib/optional_missing_ops.carbon SKIP (:6), `EXPECT-STDOUT` `1` (:8-9), body :20-26. Two other PASS programs use Optional: error_handling/optional_try.carbon (EH-A) and stdlib/iterate_interface.carbon; control_flow/match_sum_type_payload.carbon is the SKIPped std::optional interop half of row 68 (W-011). |

### §0.2 Measurements

Setup, all under the planner's scratch directory (`$S` below is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/op1`;
the ST-1 recipe of fork/string/plan.md §0.2): `install-copy` is a `cp -a` of the
trunk install whose `lib/carbon/core/prelude/types/optional.carbon` is replaced
by each prototype in turn; `runfiles` is a tree whose
`carbon/toolchain/install/*` entries symlink `install-copy/lib/carbon/*`
(file_test finds the install root through `RUNFILES_DIR`, the carbonbuild
README's runfiles section); `bin/run.sh` compiles one program with
`--output-last-input-only` (R2), links and runs it. Each prototype got a fresh
`XDG_CACHE_HOME`, because the runtimes cache that holds the compiled prelude is
keyed by the install digest (toolchain/driver/runtimes_cache.cpp:177-186), which
the copy leaves unchanged. The copy is a faithful model of an OP-1 build: the
prelude source list is compiled into the binary
(`RuntimesBuildInfo::CarbonCorePreludeSrcs`,
toolchain/driver/carbon_runtimes.cpp:64-70) and OP-1 adds no prelude file, and
OP-1 changes no C++ source. Prototype `v1` is an earlier draft of §2.1 that
differs from it in two places: line 27 is still the blank line, and the comment
over the appended impls is 6 lines of other wording where §2.1 has 9, so v1's
impls start three lines earlier; `v2` is §2.1 byte for byte (amended 2026-10-13,
review fold: A-5). M-6's prototype, M-10, M-14 and M-17 ran on v1; no golden or
program they ran sees a line of the appended block, M-13 was re-run on v2 at rev
2, and M-17 is superseded by rev 2's whole-suite run on v2 (M-16). Every
prediction quoted below was written down before its run (R16(d)).

```
S=/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/op1
T=/home/user/carbon-build/carbon-trunk
cp -a $T/install $S/install-copy
cp $S/proto/optional.v2.carbon $S/install-copy/lib/carbon/core/prelude/types/optional.carbon
$S/bin/run.sh $S/install-copy $S/cache-v2 <program.carbon>
cd /home/user/carbon-op && RUNFILES_DIR=$S/runfiles TEST_TMPDIR=$S/ft-tmp \
  $T/bin/file_test --print_slowest_tests=0 < /dev/null
cd /home/user/carbon-op && XDG_CACHE_HOME=$S/cache-v2 python3 fork/conformance/runner.py \
  --toolchain $S/install-copy/lib/carbon/carbon-busybox --programs <dir> --out <out>
```

-   **M-1 (the SKIP program on trunk).** `carbon compile --phase=check` of
    stdlib/optional_missing_ops.carbon with the trunk install prints exactly the
    error its SKIP line quotes, `` 24:17: error: cannot access member of
    interface `Core.EqWith(Core.Optional(i32 as Core.OptionalStorage))` in type
    `Core.Optional(i32 as Core.OptionalStorage)` that does not implement that
    interface ``, exit 1. The upstream nightly 2026.10.12 prints the same line.
    The SKIP line's provenance ("captured verbatim from
    carbon_toolchain-0.0.0-0.nightly.2026.07.19") therefore still describes
    today's toolchain.
-   **M-2 (the brief's spelling does not compile).** `final impl forall [T:
    Destroy & EqWith(T) & OptionalStorage] Optional(T) as EqWith(Optional(T))`
    (and the `OrderedWith(T)` twin) fails in the prelude with "name `T` not
    found" at the `T` inside `EqWith(T)` (212:40 and 234:45 of the probe): a
    binding is not in scope in its own facet type, so the self-referential bound
    is spelled with the constraint `Eq`, which is `EqWith(Self)`
    (comparison.carbon:19-21), and `Ordered` (:34-36). With
    `[T: OptionalStorage & Eq]`, that is without `Destroy`, the prelude fails
    with 12 errors "cannot access member of interface `Destroy` in type `T` that
    does not implement that interface", two on each of the six
    `return self.Get() <op> other.Get();` lines: each `Get()` result is a
    temporary that must be destroyed, and a symbolic `T` bound by a non-`type`
    facet proves only its declared interfaces. This is EH-A's R-12 failure mode
    (decision-log :5685-5702), in which every full-prelude golden gains the
    errors; hence `Destroy` in the bound (D-OP-3).
-   **M-3 (the prototype prelude is accepted).** With §2.1 in the copy every
    prelude file checks with no diagnostic, and optional_missing_ops.carbon,
    unmodified, compiles, links and prints `1`, exit 0 (first on v1, again on
    v2). The same impls without `final` also check clean; their only measured
    difference is M-11.
-   **M-4 (semantics).** A probe of 22 comparisons over `Core.Optional(i32)`
    (`none`, `none2`, `one = Some(1)`, `one2 = Some(1)`, `two = Some(2)`,
    `neg = Some(-5)`) printed, as predicted line for line: `none == none2` 1,
    `none == one` 0, `one == none` 0, `one == one2` 1, `one == two` 0,
    `none != none2` 0, `none != one` 1, `one != two` 1, `one != one2` 0,
    `none < one` 1, `none < neg` 1 (empty orders before a negative value too),
    `one < none` 0, `none < none2` 0, `none <= none2` 1, `one <= none` 0,
    `neg < one` 1, `two > one` 1, `none > neg` 0, `neg > none` 1,
    `none >= none2` 1, `none >= one` 0, `one >= one2` 1. Generic use: `fn
    Same[T: Core.Eq & Core.Copy & Core.Destroy](a: Core.Optional(T), b:
    Core.Optional(T)) -> bool { return a == b; }` on `Some(3)`/`Some(3)` printed
    1; `Before[T: Core.Ordered & Core.Copy & Core.Destroy]` printed 1 for `i64`
    (`None` before `Some(-9)`) and 0 for `u8` (`Some(200)` before `Some(7)`:
    `u8` orders unsigned); a nested `Core.Optional(Core.Optional(i32))` equals
    itself (1). `f64` and `char` payloads built from typed values:
    `Some(2.5) < Some(3.5)` 1, `==` 0, `Some('a') != Some('b')` 1,
    `Some('b') > Some('a')` 1. On a copy of the ST-1 install with §2.1,
    `Core.Optional(str)` compares too: `Some("apple") == Some("apple")` 1,
    `== Some("apricot")` 0, `<` 1, `None < Some("apple")` 1, `None == None` 1;
    on trunk the same lines are M-10's "does not implement" diagnostic, because
    `str` has no `EqWith` before ST-1.
-   **M-5 (comparisons copy and destroy, never the operands).** The probe below,
    a class `P` whose `Copy` prints 100 + v and whose `Destroy` prints 200 + v,
    printed `-9 101 102 -1 101 102 202 201 0 -2 0 -3 101 102 202 201 1 -4 1 -5
    202 201`. Reading: each `Some(p)` copies its argument once (101, 102);
    `a == b` copies each held value once through `Get()`, left operand first
    (101, 102), and destroys both copies, last first, before the result is
    printed (202, 201), so the operands are read and never moved or destroyed;
    `n == a` with an empty operand copies nothing; `a < b` behaves as `==`; at
    the end of `Run` only `p2` and `p1` are destroyed (202, 201), never the two
    values the Optionals hold (M-6).

```carbon
import Core library "io";

class P {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self {
      Core.Print(100 + self.v);
      return {.v = self.v};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      Core.Print(200 + self.v);
    }
  }
}

impl P as Core.EqWith(P) {
  fn Equal(self, other: P) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: P) -> bool { return self.v != other.v; }
}

impl P as Core.OrderedWith(P) {
  fn Less(self, other: P) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: P) -> bool { return self.v <= other.v; }
  fn Greater(self, other: P) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: P) -> bool { return self.v >= other.v; }
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  var p1: P = {.v = 1};
  var p2: P = {.v = 2};
  Core.Print(-9);
  var a: Core.Optional(P) = Core.Optional(P).Some(p1);
  var b: Core.Optional(P) = Core.Optional(P).Some(p2);
  var n: Core.Optional(P) = Core.Optional(P).None();
  Core.Print(-1);
  Core.Print(B(a == b));
  Core.Print(-2);
  Core.Print(B(n == a));
  Core.Print(-3);
  Core.Print(B(a < b));
  Core.Print(-4);
  Core.Print(B(n < a));
  Core.Print(-5);
  return 0;
}
```

-   **M-6 (an Optional never destroys its value, and the obvious fix breaks
    unions).** M-5's last line is the leak: the two copies that `Some` stored
    are never destroyed, because `DefaultOptionalStorage(T)` (:140-143) holds a
    `MaybeUnformed(T)`, which runs no destructor, and nothing declares a
    `Destroy` that would. A prototype (`$S/proto/optional.dtor2.carbon`: v1,
    `let Type: Destroy;` at :18, and the two impls below appended) fixes the
    probe: its output gains `202 201` at the end. But it is not OP-1 material
    (D-OP-12): file_test over the whole manifest passes 1916 of 1942, and the 26
    that change are 13 check goldens (interop/cpp/class/export/union,
    class/import/field, function/import/decayed_param, pointer, void_pointer,
    macros/macros, range_for, stdlib/initializer_list, vector_view,
    vector_view_span, operators/question_optional, slice/basic, union/basic) and
    13 lower goldens (array/iterate, builtins/cpp, for/bindings,
    for/break_continue, for/for, interop/cpp/class/export/union, nullptr,
    pointer, std_initializer_list_pointer_pointer,
    std_initializer_list_pointer_size, void, primitives/optional, union/basic),
    and in both union/basic goldens the split `optional_pointer_field.carbon`
    stops compiling with "union field `o` has type
    `Core.Optional(i32* as Core.OptionalStorage)`, which is not trivially
    copyable and destructible [UnionFieldNotTriviallyCopyable]": a declared
    `Destroy` on `Optional(T)` makes every Optional, the pointer niche included,
    user-destructible, which the union field rule rejects
    (docs/design/unions.md:233-239 admits `Core.Optional(T*)` fields). The fix
    needs a destroy that keeps `Optional(T*)` trivially destructible; filed as
    W-170 with this measurement.

```carbon
impl forall [T: Copy & Destroy] DefaultOptionalStorage(T) as Destroy {
  fn Op(ref self) {
    if (self.has_value) {
      (self.value unsafe as T).(Destroy.SelfDestruct)();
    }
  }
}

impl forall [T: OptionalStorage] Optional(T) as Destroy {
  fn Op(ref self) {
    (self as T.Type).(Destroy.SelfDestruct)();
  }
}
```

-   **M-7 (`Core.Optional(bool)` crashes the compiler, before and after OP-1).**
    On the unmodified trunk install, `let x: Core.Optional(bool) =
    Core.Optional(bool).Some(true); Core.Print(if x.Get() then 1 else 0);`
    aborts in lowering: "Function return type does not match operand type of
    return inst! `ret ptr %value1` ... i1", `CHECK failure at
    toolchain/lower/lower.cpp:48: !llvm::verifyModule(...)`; copying one
    (`var y: Core.Optional(bool) = x;`) aborts with "CHECK failure at
    toolchain/lower/handle_call.cpp:984: args_ok: Argument mismatch: call ptr
    @"_CSome.74becf39533834ee:OptionalStorage.Core.27639e8ca00f0d64"(ptr
    %return, ptr %value1)"; `Some(true)` and `HasValue()` work (prints 1). The
    upstream nightly 2026.10.12 aborts the same way on the `Get()` program.
    Outside Optional, `fn F(m: Core.MaybeUnformed(bool)) -> bool { return m
    unsafe as bool; }` aborts check: "CHECK failure at
    toolchain/check/convert.cpp:1698: unformed_value_rep.kind ==
    SemIR::ValueRepr::Pointer", in the branch that converts when the value
    representations of `MaybeUnformed(T)` and `T` differ (:1687-1704;
    upstream-trunk 62f1cc6a3 has the same code at convert.cpp:1559-1562); the
    `i32` twin compiles. With §2.1, `Optional(bool) == Optional(bool)` passes
    check and aborts lowering the same way, where trunk gave a check error
    (D-OP-13, R-3). Filed as W-171.
-   **M-8 (a float or character literal argument aborts check, generally).**
    `Core.Optional(f64).Some(2.5)` and `Core.Optional(char).Some('a')` abort
    check on trunk: "FATAL failure at toolchain/check/custom_witness.cpp:487:
    Unexpected type for CanDestroyType: FloatLiteralType" (`CharLiteralType` for
    the character), raised while deducing the call through
    `PerformBuiltinConversion` and `LookupImplWitness`. It is not Optional's:
    `class Box(T: Core.Copy & Core.Destroy) { fn Make(value: T) -> i32 { return
    1; } }` with `Box(f64).Make(2.5)` aborts the same way, and the upstream
    nightly aborts at its custom_witness.cpp:401 for both kinds. Typed values
    work (`let f: f64 = 2.5; ...Some(f)`, M-4). Filed as W-172 under the
    generics bullet.
-   **M-9 (`Get()` on an empty Optional is unchecked).** On trunk,
    `Core.Print(Core.Optional(i32).None().Get())` (through a `let`) printed
    `-93156344`, the unformed storage; `*p.Get()` on an empty
    `Core.Optional(i32*)` dereferences the null pointer, `SIGSEGV`, exit 139.
    Filed as W-173; OP-1's impls call `Get()` only after `HasValue()` (D-OP-4).
-   **M-10 (what is rejected, on v1).** Each check-only probe failed with
    exactly one kind of diagnostic:
    `Core.Optional(i32*) == Core.Optional(i32*)`, "cannot access member of
    interface `Core.EqWith(Core.Optional(i32* as Core.OptionalStorage))` ..."
    (and `p == q` on two `i32*`, "... `Core.EqWith(i32*)` in type `i32*` ..."),
    W-174; a class with `Copy` and no `EqWith`, the same diagnostic for
    `Core.Optional(NoEq)`, while on v2 everything else about that Optional still
    works (`Some`, a copy, `HasValue()`, `Get()` and `None()` printed `5` and
    `0`), so the conditional impls constrain only comparison; `a == 5` and
    `a == b` with `b: i32`, "... `Core.EqWith(Core.IntLiteral)` ..." and "...
    `Core.EqWith(i32)` ..." (no mixed comparison,
    comparison_operators.md:288-289); `Optional(i32) == Optional(i64)`, "...
    `Core.EqWith(Core.Optional(i64 as Core.OptionalStorage))` in type
    `Core.Optional(i32 as Core.OptionalStorage)` ..." (same-type only, D-OP-5);
    `a as Core.Optional(i8)` from `Core.Optional(i32)`, "cannot convert
    expression of type ... with `as`" and "does not implement interface
    `Core.As(Core.Optional(i8 as Core.OptionalStorage))`" (W-175), while the
    implicit `Optional(i32)` to `Optional(i64)` compiles;
    `fn F[T: Core.Eq](a: Core.Optional(T), ...)`, "cannot convert type `T` that
    implements `Core.Eq` into type implementing `Core.OptionalStorage`" with a
    note at optional.carbon:30:16, once per parameter (W-176); a class that is
    `OrderedWith` itself but not `EqWith`: `<` on its Optionals compiles and
    `==` is the "does not implement" diagnostic
    (comparison_operators.md:466-472); `impl like M as Core.EqWith(like M)`,
    "expected expression" and "semantics TODO:
    `handle invalid parse trees in check`": `like` is a keyword
    (toolchain/lex/token_kind.def:214) with no parser support (W-178).
-   **M-11 (what `final` changes).** A user library declaring `impl
    Core.Optional(Q) as Core.EqWith(Core.Optional(Q))` (whose `Equal` returns
    `self.HasValue()`) and comparing two `Core.Optional(Q)` values: with §2.1's
    `final` impls the compile fails, "`impl` will never be used
    [ImplFinalOverlapsNonFinal]" at the user's impl with "`final impl` declared
    here would always be used instead [ImplFinalOverlapsNonFinalNote]" at
    optional.carbon:215 (the diagnostic appears when an `==` uses the impl; the
    declaration alone compiles); without `final` it compiles, runs, and the
    user's impl wins, printing 1 for `Some(q1) == Some(q2)` with `q1.v = 1`,
    `q2.v = 2`. That is the whole measured difference (D-OP-3).
-   **M-12 (golden blast radius).** file_test in test mode over the whole
    manifest, read-only from /home/user/carbon-op, with the prelude copy: v1
    `Ran 1942 tests`, 1942 passed; v2 (§2.1) 1942 passed. The harness reads the
    copy: with v2's `other.Get()` in `Equal` (:224) misspelled `other.Gett()`,
    the whole manifest runs `[==========] 1942 tests from 1 test suite ran.` and
    `[  PASSED  ] 1617 tests.`; the 325 that fail are every test that loads the
    full prelude (312 of the 315 files that include min_prelude/full.carbon, the
    other three being `.tmpl` inputs, plus 12 driver and 1 language-server
    tests), each gaining the prelude error "member name `Gett` not found"; rev
    1's "fails alone" does not reproduce over the whole manifest (amended
    2026-10-13, review fold: A-4). Line stability matters: a variant of v1 that
    inserts the dated amendment as three lines after :29 (shifting :30-204 by
    three) fails 14 goldens, check/testdata/operators/question_optional.carbon
    and 13 lower goldens (array/iterate, builtins/cpp, for/bindings,
    for/break_continue, for/for, interop/cpp/class/export/union, nullptr,
    pointer, std_initializer_list_pointer_pointer,
    std_initializer_list_pointer_size, void, primitives/optional, union/basic),
    every one on optional.carbon debug-info or diagnostic line numbers, which is
    the churn EH-A recorded when its lines moved (decision-log :5759-5760);
    hence D-OP-8. Wall time on a quiet machine (load 0.8 to 2.4): the unmodified
    prelude 21.8 s, v2 22.1 s.
-   **M-13 (composition with ST-1).** A `git archive` of
    claude/carbon-fork-0-1-st at 21307851a (whose toolchain and core sources
    equal those of its build 84ff63560, `git diff --name-only 84ff63560
    claude/carbon-fork-0-1-st -- toolchain core` naming testdata only) run with
    ST-1's own file_test and a copy of ST-1's install carrying v1: `Ran 1950
    tests`, 1950 passed. ST-1's string.carbon and OP-1's optional.carbon compose
    with no golden change; M-4's `Optional(str)` lines are the positive half.
    Re-run at rev 2 with v2, §2.1 byte for byte, in the fixer's tree (the same
    archive of 21307851a, ST-1's file_test, a copy of ST-1's install carrying
    v2): `[==========] 1950 tests from 1 test suite ran.` and `[  PASSED  ] 1950
    tests.` (amended 2026-10-13, review fold: A-5).
-   **M-14 (composition with SC-1, partial).** A copy of SC-1's install
    (0.0.0-0.dev+bc8b37290; the SC-1 head is now 2497d5000, whose two later
    commits change fork/ORCHESTRATION.md, fork/decision-log.md,
    fork/inventory/work-items.json and fork/structural/plan.md only) carrying v1
    runs M-4's 22-comparison probe, M-5's probe and the typed `f64`/`char` probe
    with output identical to the trunk copy's. SC-1 changes member access and
    name lookup (check/member_access.cpp, name_lookup.cpp), through which `a ==
    b` resolves (`a.(EqWith(U).Equal)(b)`, comparison_operators.md:270). Its
    file_test was not run: at the time of this measurement (20:48 UTC) the
    binary (19:18) predated its busybox (20:12) in
    /home/user/carbon-build/carbon-sc, so its parity with the SC-1 toolchain was
    unverified, and that build directory was in use by SC-1's own conformance
    run (R-5). Superseded in part at rev 2 by M-22 (amended 2026-10-13, review
    fold: B-8).
-   **M-15 (the new goldens).** The three §2.3 sources, autoupdated by the trunk
    file_test in a scratch mirror (`$S/mirror`, holding a copy of
    toolchain/testing/testdata/min_prelude/) at substitute manifest paths
    (check/testdata/operators/question_optional.carbon,
    check/testdata/operators/fail_question.carbon,
    lower/testdata/primitives/optional.carbon), with v2, from rev 2's sources:
    check `optional/compare.carbon` 1435 lines (1345 CHECK), check
    `optional/fail_compare.carbon` 157 (37), lower `optional/compare.carbon` 488
    (465); rev 1's sources filled to 1140 (1074), 127 (37) and 362 (341), which
    the fixer reproduced in its own mirror before filling rev 2's (amended
    2026-10-13, review fold: A-1, A-3, A-10, B-1). Each converges on its second
    run (the first fills it and prints `!`, the second prints `.`; runs counted
    as in fork/string/plan.md M-10) and then passes in test mode. A first fill
    named the four `concrete.carbon` functions `Eq`, `Ne`, `Lt` and `Ge`; SemIR
    named the first `@Eq.loc5`, colliding with `Core.Eq`, so they are `IsEq`,
    `IsNe`, `IsLt` and `IsGe` (the ST-1 `Dup` precedent), and rev 2 adds `IsLe`
    and `IsGt`. §4 quotes the key lines.
-   **M-16 (conformance).** The nine Optional programs of §2.4 (rev 2 texts) on
    v2: `optional_basic`, `optional_pointer_niche`, `optional_missing_ops`,
    `optional_compare_diff` (36 lines; the C++17 oracle's bytes equal the Carbon
    binary's, and both equal the 36 lines predicted from §1.2's table before the
    run), `optional_compare_generic` and `optional_compare_payload` PASS;
    `optional_pointer_compare`, `optional_destroys_value` and `optional_bool`
    SKIP (M-20 measures what each SKIP line quotes; compiled on v2 the pointer
    program's only diagnostic is the one its SKIP line quotes, four times, lines
    37-40). On the trunk install the four programs that compare Optionals are
    COMPILE-FAIL (not vacuous; re-measured for rev 2's 36-line
    `optional_compare_diff`). The whole suite on v2 with rev 2's programs in a
    scratch copy of programs/: `PASS 132`, `SKIP 24` and every other status 0,
    over 156 programs, bullets 48 PASS / 0 FAIL / 8 SKIP, and against
    fork/conformance/out/scoreboard.json exactly seven status differences, all
    Optional (`optional_missing_ops` SKIP to PASS and six new programs), the 16
    error_handling programs among the unchanged PASSes. In a scratch tree
    (runner.py, README.md, gap-analysis.md and that programs/ copy),
    `runner.py --update-readme-table` writes 156 rows, seven of them new or
    changed, and `--self-test` then prints `self-test: 156 programs parsed, 56
    bullets in table, OK`. Rev 1's seven programs had measured `PASS 132 ...
    SKIP 22` over 154 (amended 2026-10-13, review fold: A-3, B-1, B-2).
    clang-format 21.1.8 (`/home/user/llvm/bin/clang-format`, the R18 pin, with
    the repository's `.clang-format`) leaves the oracle unchanged.
-   **M-17 (the `Try` path and the error-handling programs are unchanged).** The
    whole suite on v1 (before the new programs existed): 128 PASS / 0 FAIL / 22
    SKIP over 150, zero status differences against
    fork/conformance/out/scoreboard.json, the 16 error_handling programs among
    the PASSes (optional_try.carbon included). §2.1 changes no line of :56-78
    (the patch's hunks are at :13, :27 and after :204, `git apply --check` clean
    on 9d3ca60a3). Superseded at rev 2 by M-16's whole-suite run on v2, which
    shows the same: no status change outside the Optional bullet (amended
    2026-10-13, review fold: A-5).
-   **M-18 (a user pointer equality makes the pointer niche compare; a final
    prelude one would forbid it).** A user library declaring `class C { var v:
    i32; }` and `impl C* as Core.EqWith(C*)` comparing the pointees (allowed,
    because `C` is local, details.md:5381-5417) compiles on v2, and its
    `Core.Optional(C*)` values compare: with `c1.v` and `c2.v` 4 and `c3.v` 5,
    `Some(&c1) == Some(&c2)` prints 1, `Some(&c1) == Some(&c3)` 0, `Some(&c1) ==
    None()` 0, `None() == None()` 1 and `Some(&c1) != Some(&c3)` 1; on trunk
    each `==` is M-10's "does not implement" diagnostic. The filled
    `user_pointer` split of §2.3 shows the route: the specific's facet is
    `facet_value %ptr.6b6, (%EqWith.impl_witness.8c5,
    %OptionalStorage.impl_witness.2e9, %custom_witness.f8f)`, where
    `%EqWith.impl_witness.8c5` is the user's `@ptr.as.EqWith.impl` and
    `%OptionalStorage.impl_witness.2e9` is `@ptr.as.OptionalStorage.impl(%C)`,
    the null niche. A probe prelude with `final impl forall [T: type] T* as
    EqWith(T*)` (placeholder bodies, because no pointer comparison builtin
    exists) appended to core/prelude/operators/comparison.carbon checks clean,
    and the same user library then fails with "`impl` will never be used" at its
    impl and the note "`final impl` declared here would always be used instead"
    at comparison.carbon:64; the same impl appended to optional.carbon instead
    is rejected, "`final impl` found in file that does not contain the root self
    type nor the interface definition". So a `final` prelude pointer `==`
    (W-174) would make every such user impl an error and change what `==` means
    on `Optional(C*)` from the user's rule to the prelude's (amended 2026-10-13,
    review fold: A-1).
-   **M-19 (mutation falsifiers for the comparison bodies).** Two mutant
    preludes in their own install copies, each v2 with bodies changed: mutant A
    (review A's) changes `NotEqual`'s both-empty `return false;` (:231) to
    `return true;` and `Greater`'s `>` (:264) to `>=`; mutant B (review B's,
    byte-identical to its file) changes :231, :233, :253, :255, :264, :268 and
    :273, so that `!=`, `<=`, `>` and `>=` ignore the held values and three
    empty-operand branches are inverted. Rev 1's 16-line `optional_compare_diff`
    PASSes under both (its C++ oracle agrees with each mutant on all 16 lines),
    and `optional_compare_generic`, `optional_compare_payload` and
    `optional_missing_ops` PASS under both: the reviews' finding, reproduced.
    Rev 2's 36-line `optional_compare_diff` is DIFF-MISMATCH under both, every
    other Optional program unchanged; it is §8.4's non-vacuity falsifier
    (amended 2026-10-13, review fold: A-3, B-1).
-   **M-20 (the two row-bounding arbiters).** `optional_destroys_value` (§2.4)
    compiled on v2 and on the trunk install, with its SKIP line removed, exits 0
    printing `2 1 1 0 3 2` where its EXPECT, derived from F-015's ownership
    rule, is `2 0 1 0 3 0`; on a copy of v2 carrying M-6's two `Destroy` impls
    (and `let Type: Destroy;`) it prints `2 0 1 0 3 0`, so the body un-SKIPs
    unchanged once W-170 lands. `optional_bool` checks on v2 with no diagnostic
    (`--phase=check`, exit 0), and a full compile aborts in lowering, exit 134:
    "Lowering function Copy(bool as Core.Copy & Core.Destroy)" at
    optional.carbon:172 with "CHECK failure at
    toolchain/lower/handle_call.cpp:984: args_ok: Argument mismatch: call ptr
    @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.8ae0339be4ca7eba"(ptr
    %return, ptr %value1)"; without its copy, and with only an `==`, the abort
    is the verifier's "Function return type does not match operand type of
    return inst!" with "CHECK failure at toolchain/lower/lower.cpp:48". On the
    trunk install the same `==` lines are the clean `MissingImplInMemberAccess`
    diagnostic; the abort on `==` is OP-1's (D-OP-13, R-3) (amended 2026-10-13,
    review fold: B-2, A-8).
-   **M-21 (the new goldens with ST-1's toolchain).** Rev 2's three §2.3
    sources, filled the same way in a second mirror (holding ST-1's min_prelude)
    by ST-1's file_test with the copy of ST-1's install carrying v2, converge on
    their second run at 1435, 157 and 488 lines, byte-identical to M-15's trunk
    fills; the nine Optional programs on that install give M-16's statuses.
    OP-1's goldens and programs therefore compose with ST-1's toolchain as well
    as its goldens (M-13) (amended 2026-10-13, review fold: B-4).
-   **M-22 (composition with SC-1's later build).** After rev 1, SC-1's head
    moved from 2497d5000 to 77838fdd5 (its round-4 fixes, fill and records),
    built as 0.0.0-0.dev+ff490bd48, whose toolchain and core sources equal the
    head's (`git diff --name-only ff490bd48 77838fdd5 -- toolchain core testing`
    names testdata only); its file_test binary was linked at 21:51, before its
    last toolchain commit aa67ea281 (22:04), and its busybox at 22:05, so the
    two binaries' parity with that commit is unverified. With a `git archive` of
    77838fdd5, a copy of SC-1's file_test and a copy of SC-1's install carrying
    v2: `[==========] 1959 tests from 1 test suite ran.` and `[  PASSED  ] 1959
    tests.`; rev 2's three §2.3 sources fill in a third mirror on their second
    run at 1435, 157 and 488 lines, byte-identical to M-15's trunk fills, so the
    `ConversionFailureFacetToFacet` errors that `fail_generic_without_copy` pins
    gain no structural-conformance note and every §4 key line holds under SC-1's
    checker; the nine Optional programs give M-16's statuses. On SC-1's head,
    convert.cpp's W-171 CHECK is at :1712, and impl_lookup.cpp (+47) and
    impl.cpp (+237) differ from trunk as B-8 states (amended 2026-10-13, review
    fold: B-8, B-4).

Not measured, and why: an OP-1 toolchain built from this worktree by carbonbuild
(the planner builds nothing; the trunk build is equivalent for every file OP-1
changes, and §8 builds it); SC-1's file_test built from exactly SC-1's head
(M-22 used SC-1's binaries as built, whose file_test of 21:51 predates SC-1's
last toolchain commit aa67ea281 of 22:04, so their parity with that commit is
unverified; §8.8 re-runs everything on the merge commit; amended 2026-10-13,
review fold: B-8); Bazel-only tests, macOS, Windows and an opt-mode toolchain
(§8); a fix for W-171 (the CHECK at convert.cpp:1698 reads the target's
representation where its comment describes the operand's, but the generic path
inside Optional passes check and fails in lowering, so a one-token change is not
known to suffice).

### §0.3 Ledger, row and brief claims found stale (each corrected where §2 says)

1.  W-058's evidence
    `fork/conformance/programs/stdlib/optional_missing_ops.carbon:2` is a
    license line; the SKIP line is :6 (the SKIP line is deleted at the un-SKIP,
    and W-058's evidence is rewritten at discharge, §2.6).
2.  W-058's evidence `core/prelude/types/optional.carbon:27-28`, gap row 78's
    "(optional.carbon:27-28)" and optional_basic.carbon:24 name the placeholder
    TODO's upstream lines; in the fork it is :28-29 since EH-A's
    `import library "prelude/try"` (:12). Corrected in W-058 and row 78 at
    discharge and in optional_basic.carbon's refreshed header (§2.4).
3.  optional_pointer_niche.carbon:16 cites
    `core/prelude/types/optional.carbon:156-179` for the pointer niche; it is
    :181-204 (`PointerIsNull` :181, the `final impl` :188-204). Corrected in its
    refreshed header (§2.4).
4.  The brief's prototype spelling `impl forall [T: EqWith(T) & OptionalStorage]
    Optional(T) as EqWith(Optional(T))` does not compile, twice over (M-2): `T`
    is not in scope in its own bound, and without `Destroy` every `Get()`
    temporary is undestroyable. §2.1 spells it
    `[T: Destroy & OptionalStorage & Eq]`.
5.  The brief calls the std::optional mapping "row 71 / W-011": on trunk the row
    of the bullet "Control flow: matching — sum-type consumption incl.
    std::variant/std::optional interop" is :68 (it is :71 on the safe branch,
    which inserts three rows above it); this plan cites it by bullet text.
6.  docs/design/error_handling.md:432-433 says the `match` body of the
    `Optional` `Try` sketch "applies verbatim once W-058 makes `Optional` a
    choice", and :905-910 that the `Try` impl and every `.Some`/`.None` pattern
    there "require it to become a payload-carrying choice; that rebuild rides
    the SF-9 decision": W-058 is discharged without making `Optional` a choice
    (D-OP-7), so a dated amendment after :444 says so (§2.5); the matchability
    question moves to W-177.
7.  docs/design/control_flow/loops.md:104-105 "(though an API for `Optional` has
    not been approved)": the fork's design now fixes the API it uses
    (`HasValue()`, `Get()`); a dated amendment after the block it introduces
    (§2.5).
8.  gap-analysis.md §W9 "Depends on" (:226-230) lists variadics, sum types,
    native unions and std::variant/optional interop as dependencies of "the
    String and Optional halves": OP-1 implements the Optional half's design and
    comparisons without any of them; only two of its residues touch them (W-177,
    the choice question, and W-011's std::optional interop). ST-1 rewrites the
    same line to "the Optional half only" on its branch; at OP-1's discharge the
    line names the two residues instead (§2.6).
9.  fork/ORCHESTRATION.md "Next actions" item 3 (:480 at 9d3ca60a3, :496 at
    trunk 162c7e839) still calls W5-S3p "GATED on the OPEN SF-9 fork": SF-9 was
    decided at EH-A (D-EH-1). The discharge stamp corrects it in a dated
    sentence (§2.6).
10. docs/design/error_handling.md:424 (EH-A's amendment) cites
    `core/prelude/types/optional.carbon:29` for the `T: OptionalStorage` bound;
    in the fork the class is at :30, because EH-A's own `import library
    "prelude/try"` (:12) moved it. OP-1's error_handling.md amendment names the
    correct line (§2.5); the EH-A text is not rewritten (amendments, never
    rewrites) (amended 2026-10-13, review fold: A-6).

### §0.4 Decisions this plan auto-adopts (R29(a): the design recommendation under V-2/V-3, veto-able after the fact)

Each decision cites what it follows or the silence it fills and carries a
one-sentence break condition. The decision-log entry F-015 is written at
discharge (§2.6) with these decisions by number.

-   **D-OP-1: equality.** Two empty Optionals are equal; an empty and a
    non-empty Optional are unequal; two non-empty Optionals are equal exactly
    when their values are equal under `T`'s `==`, and `!=` is `T`'s `!=` on two
    non-empty operands (C++ [optional.relops] uses the contained type's
    corresponding operator; every prelude same-type impl defines `NotEqual`
    explicitly, int.carbon:93-96, char.carbon:49-52). An accepted design already
    presupposes this `==`: "a pattern of the form `Optional(T).None` is an
    expression pattern and is compared using `==`" (p002188:488-489,
    pattern_matching.md:527-528), which spells the empty value as a value where
    F-015 keeps the function `None()` (V-3) (amended 2026-10-13, review fold:
    A-9). This is Rust's derived `PartialEq` for `Option` and C++'s
    `operator==`/`operator!=` for `std::optional`; the two agree, so a C++17
    differential oracle is legitimate (R30 does not apply: the two sides agree
    by construction). It is an equivalence when `T`'s is, and refines the order
    of D-OP-2 when `T`'s `==` refines `T`'s order
    (comparison_operators.md:466-472). Break condition: an accepted upstream
    design for `Core.Optional` specifies a different equality; the impl bodies
    and the oracle follow it.
-   **D-OP-2: ordering, with only `Ordered` required.** An empty Optional orders
    before every non-empty one, two empty ones are equivalent, and two non-empty
    ones order as their values under `T`'s four operators; `Less`,
    `LessOrEquivalent`, `Greater` and `GreaterOrEquivalent` are C++'s `<`, `<=`,
    `>` and `>=` for `std::optional` term for term ([optional.relops]) and
    Rust's derived `PartialOrd` ("`None` compares less than any `Some`"). The
    impl needs `T: Ordered` only, not `Eq`, because
    comparison_operators.md:468-469 imposes no such requirement and C++ does not
    (measured: an ordered-only payload's Optionals order and do not compare
    equal, M-10). Transitivity and consistency under reversal (:436-465) carry
    over from `T`'s. Break condition: upstream decides that `Optional` is not
    ordered or orders `None` last; the `OrderedWith` impl is deleted or its four
    bodies changed, and `optional_compare_diff` with them.
-   **D-OP-3: the spelling
    `final impl forall [T: Destroy & OptionalStorage & Eq] Optional(T) as EqWith(Optional(T))`
    and its `Ordered` twin.** The constraints `Eq`/`Ordered`
    (comparison.carbon:19-21, :34-36) because `[T: EqWith(T)]` is "name `T` not
    found" (M-2); `OptionalStorage` because the class forces it (:30); `Destroy`
    because each `Get()` copy is destroyed (M-2, the `Try` impl's bound for the
    same reason, :62-64); the conditional form is details.md's conditional
    conformance (:4457-4469), whose own example is comparing containers of
    comparable elements. `final`: EqWith and OrderedWith have no associated
    constants, so `final` is not needed for generic code to type-check (both
    variants check, M-3); it is chosen because comparison is part of the type's
    definition, so when the payload is `Core.Eq` (and `Destroy`) a payload
    type's library cannot change what `==` means on its Optionals (M-11: without
    `final` a user impl silently wins), while for a payload that is not
    `Core.Eq` the final impl does not match and that library's `impl Optional(Q)
    as EqWith(Optional(Q))` is legal and defines `==` (amended 2026-10-13,
    review fold: A-10); the prelude's integer comparison impls (cross-width,
    `Int(N)` with `Int(M)`) and its float and C++-integer ones are `final` too
    (int.carbon:93-104, float.carbon:165-170, cpp/int.carbon:341-375; corrected
    2026-10-13, implementation review fold: IR2-5) and so is the `Try` impl
    (:69; for `Try`, `final` is load-bearing, because generic code reads its
    associated constants `ContinueType` and `BreakType`, details.md:5262-5379,
    and R27 records the W-072 incident that restored the sketch's `final`). The
    `final` impls may be declared here: optional.carbon declares the root of the
    `Self` type (details.md:5381-5395). p5337:280-286 makes a non-final impl
    that a final impl completely subsumes an error; the 0.1 toolchain diagnoses
    it only where it is used (M-11: the declaration alone compiles), which the
    `fail_specialize` and `todo_fail_specialize_unused` splits pin (§2.3) and
    W-179 files (amended 2026-10-13, review fold: A-10). Break condition: a
    payload type needs its own Optional equality (for example a niche-aware
    one); `final` is dropped, which changes only the `fail_specialize` and
    `todo_fail_specialize_unused` splits of §2.3.
-   **D-OP-4: bodies over `HasValue()` and `Get()`, no builtin, no
    storage-interface change.** Each function tests `HasValue()` before calling
    `Get()`, so an empty operand's unformed storage is never read (W-173 is
    about `Get()` on an empty value, which the impls never do); `Get()` returns
    a copy, destroyed by the end of the call, and the operands are neither moved
    nor destroyed (M-5). Comparing in place through a storage-level `Equal`
    would need a new member of the private `OptionalStorage` (:16-26)
    implemented for the pointer niche too, where it needs pointer equality
    (W-174), for no 0.1 benefit; the copy is the placeholder API's documented
    cost (:23-24). That cost is observable: for a `T` whose `Copy` or `Destroy`
    has an effect, each comparison of two non-empty operands runs each once per
    value (M-5), a divergence from comparison_operators.md:316 and :434 ("should
    have no observable side-effects") that V-3 discloses and F-015 states
    (amended 2026-10-13, review fold: A-2). Break condition: `Optional` becomes
    matchable (W-177) or a by-reference accessor lands; the bodies then compare
    in place, with no `Copy` or `Destroy` of `T`, the signatures unchanged, and
    the divergence entry of the V-3a register is closed (amended 2026-10-13,
    review fold: A-2).
-   **D-OP-5: same-type comparisons only.** `Optional(T)` compares with
    `Optional(T)`: not with a `T` (`o == 5`, measured rejected), not with
    `Cpp.nullptr`, and not with `Optional(U)` for `U != T` (measured rejected).
    comparison_operators.md:288-289 selects `EqWith` "without considering
    possible implicit conversions" and names the `like` operator as the way to
    admit them (:289-300), which the toolchain does not parse (M-10, W-178);
    details.md:4466-4469's conditional-conformance example compares containers
    "with the same element type"; Rust's `Option<T>: PartialEq<Option<T>>`
    agrees. C++'s mixed operators (`opt == value`, `opt == std::nullopt`,
    `optional<T> == optional<U>`) are rejected alternatives (§7 A-1, A-2). Break
    condition: `like` lands (W-178); the impls become `impl like Optional(T) as
    EqWith(like Optional(T))` if the design then says so.
-   **D-OP-6: F-015, a fork design for `Core.Optional`:
    docs/design/optional.md.** Upstream has no approved design (p006357:251-253;
    the TODO at :28-29) and lists one as future work (p006357:341-342); the
    bullet and the W9 Arbiter ask for an approved design with a comparison and
    ownership story. As F-012 did for slices and F-014 for strings, OP-1 records
    a decided fork design under R29(a), veto-able after the fact: the type as it
    is (a class, D-OP-7), its storage strategy with p006357's null niche, its
    API with `HasValue()` and `Get()` frozen because the toolchain calls them by
    name (handle_loop_statement.cpp:280-291) and loops.md uses them, its
    conversions, `Copy`, `UnformedInit`, `Try` (D9), the comparisons, the
    ownership rules with the W-170 limit stated, its C++ mapping, and the 0.1
    limits. The TODO at :28-29 is not deleted: a dated one-line amendment
    replaces the blank line :27 above it (D-OP-8). Break condition: an accepted
    upstream design for `Core.Optional` lands; F-015 is re-derived against it at
    the next upstream advance and the amendment line follows.
-   **D-OP-7: SF-9's KEEP stands; `Optional` stays a class.** D-EH-1 kept the
    class identity and W-058's notes require the `Try` signature; OP-1 changes
    none of :56-78 (signature or body) and does not re-platform `Optional` onto
    `choice`. Re-platforming would have to keep p006357's pointer ABI, the `Try`
    signature, the names `for` calls (handle_loop_statement.cpp:280-291) and the
    C++ mapping's name case (type_info.cpp:190; type_mapping.cpp:267-285), and
    is not required for comparison; it is the matchability residue W-177, linked
    to W-011. This also resolves coherence risk 9 of W-006 ("Nobody owns
    `Optional`'s redesign", fork/design-sprint/README.md:234-238: "Fold it into
    W5's deliverables explicitly") the other way: Optional's design lands
    outside W5, the class kept per D-EH-1, and W5's coupling is carried by
    matchability (W-177) and the `std::optional` mapping (W-011); the F-015
    entry records that outcome in the decision log, as W-006 asks (§2.6)
    (amended 2026-10-13, review fold: A-7, B-6). Break condition: W-177 makes
    `Optional` a choice; the `Try` body is rewritten to error_handling.md's
    `match` sketch with its signature unchanged, and the comparison bodies per
    D-OP-4.
-   **D-OP-8: no existing line of optional.carbon moves.** The one import
    comparison needs replaces :13 (`prelude/types/bool` becomes
    `prelude/operators/comparison`, which `export import`s `prelude/types/bool`,
    comparison.carbon:7, so `bool` stays visible), the amendment replaces the
    blank line :27, and everything else is appended after :204. Measured: 0 of
    1942 goldens change, against 14 for the same amendment inserted as three
    lines after :29 (M-12), and SAFE-1's normative pages, which cite
    optional.carbon by line and never above :203 (on the safe branch at
    adaae4e35: README.md:136; initialization_safety.md:102, :154-155, :258,
    :337, :388, :396; mutation_safety.md:90, :317, :664, :678, :710;
    rust_interop.md:202; temporal_safety.md:916, :967; type_safety.md:184), keep
    correct citations; what one of them states, TY4, is falsified by M-9
    regardless of lines (W-173, D-OP-13) (amended 2026-10-13, review fold: A-6,
    B-3). Break condition: upstream edits optional.carbon above :204; both sides
    are kept at the merge and M-12 is re-run.
-   **D-OP-9: min_prelude does not change.** Its `Optional` is a separate class
    with no impls (parts/optional.carbon:19-35), included by two `for` goldens
    that compare nothing (§0.1 row 11), and no min_prelude golden can see
    core/prelude; the new goldens include min_prelude/full.carbon, as SL-1's and
    ST-1's did. Break condition: a min_prelude golden needs Optional comparison;
    parts/optional.carbon then grows the impl it needs, by itself.
-   **D-OP-10: three new goldens, no refill.**
    check/testdata/optional/compare.carbon (all six operators on `i32`, generic
    use, an ordered-only payload, and a pointer niche that a user `C* as
    EqWith(C*)` makes comparable) (amended 2026-10-13, review fold: A-1, A-3,
    B-1), check/testdata/optional/fail_compare.carbon (six rejected shapes: a
    non-`Eq` payload, the pointer niche, a value operand, different payload
    types, a generic without `Copy & Destroy`, a user specialization against
    `final`, plus a `todo_fail_` split whose subsumed specialization compiles
    today although p5337 makes it an error, W-179) (amended 2026-10-13, review
    fold: A-10) and lower/testdata/optional/compare.carbon (the lowered
    `Optional(i32)` specifics of all six functions, with their `HasValue()`
    tests before `Get()`) (amended 2026-10-13, review fold: B-1). Sources only,
    filled by autoupdate (R15/R16(a)); no existing golden changes (M-12). Break
    condition: the fill changes any other golden; then stop and explain it in a
    plan revision before the fill commit (R-2).
-   **D-OP-11: conformance.** optional_missing_ops.carbon is un-SKIPped with its
    EXPECT `1` unchanged and re-derived from D-OP-1 (`Some(1) == Some(1)`), its
    body unchanged except one comment line; three PASS programs are added:
    `optional_compare_diff` with a C++17 `std::optional` oracle over every case
    of all six operators (D-OP-1/2 make the oracle legitimate; amended
    2026-10-13, review fold: A-3, B-1), `optional_compare_generic`
    (checked-generic use, a class payload, nesting) and
    `optional_compare_payload` (the copy and destroy interplay of D-OP-4,
    counted); and three write-tests-first SKIPs: `optional_destroys_value`
    (W-170) and `optional_bool` (W-171), the arbiters of the two items that
    bound the row (D-OP-13), whose SKIP lines quote the measured wrong output
    and the measured abort (M-20) (amended 2026-10-13, review fold: B-2), and
    `optional_pointer_compare` (W-174), whose SKIP line quotes the measured
    diagnostic, whose header says it does not bound the row, and whose body
    needs no change when W-174 lands. optional_basic.carbon's and
    optional_pointer_niche.carbon's headers are refreshed, bodies untouched. The
    implementation review's fold adds a fourth write-tests-first SKIP,
    `optional_nested_pointer` (W-171's second arbiter, whose SKIP line quotes
    the measured wrong output), and a generic `!=` on a NaN payload to
    `optional_compare_generic`, whose new EXPECT line `0` follows from D-OP-1
    and comparison_operators.md:311-314 (amended 2026-10-13, implementation
    review fold: R1-1, R1-5). Break condition: a program stops passing on a
    toolchain that contains OP-1; its EXPECT is re-derived from the design,
    never from the run (R16(d)), and the cause fixed or filed before the program
    changes.
-   **D-OP-12: payload destruction is not OP-1's.** An Optional never destroys
    the value it holds (M-5, M-6). A 16-line prototype that declares `Destroy`
    for the default storage and for `Optional(T)` destroys it correctly, but
    makes every Optional user-destructible: `Core.Optional(i32*)` union fields
    stop compiling (UnionFieldNotTriviallyCopyable;
    docs/design/unions.md:233-239 admits them) and 26 goldens move, 10 of them
    C++ interop check goldens (M-6). Fixing it needs a destroy that keeps the
    pointer niche trivially destructible, which is design work beyond
    comparison: under classes.md:1992-2003 a class that defines a destructor
    with a non-empty body is not `TrivialDestructor` (corrected 2026-10-13,
    implementation review fold: R1-7), and p001154:211-227's way out (a
    conditional `TrivialDestructor` impl for `Optional(U)`) is a considered
    alternative, not adopted (amended 2026-10-13, review fold: A-9); filed as
    W-170 with the prototype and the blast radius. Break condition: such a
    destroy is found and measured with no union or interop regression; W-170
    lands it and D-OP-13 re-evaluates the row.
-   **D-OP-13: row 78 stays PARTIAL, bounded by W-170 and W-171.** The bullet's
    design gap is closed (F-015) and comparison exists, but two operations of
    `Core.Optional` itself fail through its documented API: destroying a
    non-empty Optional does not destroy its value (W-170; a leak through the
    documented API is the break condition D-ST-16 wrote for row 77), and
    `Core.Optional(bool)` cannot be read or copied without crashing the compiler
    (W-171; on trunk and upstream too). D-ST-16 kept row 79 PARTIAL for exactly
    that kind of gap (an operation of its own type missing) and called row 77
    DONE only because none remained; the row-82/row-77 precedents therefore do
    not apply. The other residues are 0.1 limits filed under their own bullets
    or beyond the bullet's text (§1.7), as W-162 (unchecked `str` subscripts)
    was for row 77. OP-1 also turns `Optional(bool) == Optional(bool)` from a
    check error into M-7's lowering crash; that is accepted because the crash is
    `Get()`'s and already reachable, because no bound can exclude `bool` (Carbon
    has no negative constraints) and any body, a non-final specific impl for
    `bool` included, must read the `bool` through the same `MaybeUnformed` path,
    and because W-171 is row-bounding (amended 2026-10-13, review fold: A-8).
    OP-1 likewise turns `==` on `Core.Optional(Core.Optional(U*))`, for a
    `Core.Eq` pointer type `U*`, from a check error into W-171's silent wrong
    answer, and `==` on `Core.Optional(Core.IntLiteral)` from a check error into
    a lowering crash (W-190, a generic defect that `Eq2(1, 2)` reaches on
    trunk); both are accepted on the same grounds (no bound can exclude those
    payloads, `Get()` and the copy of the nested value and the generic `==` on
    `Core.IntLiteral` are already wrong on trunk, and W-171 is row-bounding,
    with an arbiter for the nested case), and F-015 states both (amended
    2026-10-13, implementation review fold: R1-1, R1-4). Break condition:
    `optional_destroys_value`, `optional_bool` and `optional_nested_pointer`
    (amended 2026-10-13, implementation review fold: R1-1) all un-SKIP to PASS
    in a conformance run of record (W-170 and W-171 landed), and F-013's TY4 is
    not falsified by `Get()` on an empty `Optional(T*)` (W-173 lands a checked
    `Get`, or TY4 is amended to name that obligation); only then does the row
    move to DONE, with the remaining residues as filed limits, in the commit
    that un-SKIPs the arbiters and quotes that run, never by a records-only
    commit (R9) (amended 2026-10-13, review fold: B-2, B-3).
    `optional_pointer_compare` (W-174) does not bound the row: pointer `==`
    belongs to "Stdlib: pointer types", and `Optional(T*)` already compares
    whenever `T*` is `Core.Eq` (M-18).
-   **D-OP-14: docs.** A new normative page docs/design/optional.md marked as
    fork design F-015, and dated blockquote amendments (never rewrites) at
    loops.md after its desugaring block (:107-114), error_handling.md after
    :444, and README.md's pointer types after :860 (§2.5), and, if PR 53 is on
    trunk at discharge, after type_safety.md's TY4 paragraph (W-173) and
    mutation_safety.md's staging paragraph for EX-M-5 and EX-M-6 (W-177)
    (amended 2026-10-13, review fold: B-3, B-5). Break condition: upstream's
    Optional design lands; optional.md is reconciled with it.
-   **D-OP-15: merge position and ids.** OP-1 merges last in the land sequence
    trunk 162c7e839 records (fork/ORCHESTRATION.md:89-91: PR 53, PR 51, PR 52,
    SC-1, PR 54, PR 55, then OP-1), after PR 55 (ST-1): no OP-1 file is touched
    by another branch except the shared records (§6), and M-13 measured the
    composition with ST-1. Trunk already reserves "ids from W-170" and F-015 for
    OP-1 (:89, :429); the discharge commit narrows that to W-170..W-179 used
    (§2.6) (amended 2026-10-13, review fold: A-10). Break condition: ST-1 is
    held past OP-1's verification; OP-1 then merges first and ST-1 re-reads the
    shared records at its merge of trunk (no code overlap).

## §1 Design

### §1.1 The type and its API (F-015 adopts what exists; OP-1 adds §1.2)

`Core.Optional(T)` is a class (D-OP-7) holding either no value ("empty", made by
`None()`) or one value of type `T` (made by `Some(v)`). It adapts the storage
type `T.(OptionalStorage.Type)`: by default a `{MaybeUnformed(T), bool}` pair,
and for a pointer type `T*` a single `MaybeUnformed(T*)` word in which the null
pointer is the empty value, so `Core.Optional(T*)` has a C++ pointer's ABI
(p006357:247-249) and is what a nullable C++ `T*` imports as. `OptionalStorage`
is private (:16-26), so in 0.1 every `T` must be `Core.Copy & Core.Destroy` (the
default storage's bound) or a pointer, and generic code names
`Core.Copy & Core.Destroy` for its `T` (W-176).

| Member | Meaning |
| --- | --- |
| `fn None() -> Self` | the empty value |
| `fn Some(value: T) -> Self` | a value holding a copy of `value` (one `Copy`, M-5) |
| `fn HasValue(self) -> bool` | whether it holds a value |
| `fn Get(self) -> T` | a copy of the held value; requires `HasValue()`, unchecked in 0.1 (W-173, M-9) |
| `impl forall [T: OptionalStorage] Optional(T) as Copy` | copies the held value, if any |
| `impl forall [T: OptionalStorage & UnformedInit] Optional(T) as UnformedInit` | an Optional may be declared without an initializer when `T` may (`T: UnformedInit`) (corrected 2026-10-13, implementation review fold: IR2-6) |
| `ImplicitAs(Optional(T))` from `T`, from any `U: ImplicitAs(T)` and from `Optional(U)` | `Some` of the (converted) value; empty stays empty |
| `final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try where .ContinueType = T and .BreakType = ()` | `o?` continues with the value or propagates absence as `()` (D9) |
| `final impl forall [T: Destroy & OptionalStorage & Eq] Optional(T) as EqWith(Optional(T))` | `==` and `!=` (new, §1.2) |
| `final impl forall [T: Destroy & OptionalStorage & Ordered] Optional(T) as OrderedWith(Optional(T))` | `<`, `<=`, `>` and `>=` (new, §1.2) |

Not provided, on purpose or as a filed limit: `.Some`/`.None` patterns and
`match` over an Optional (W-177); an explicit `as` between Optionals of
different payloads (W-175); comparison with a bare `T` or with `Cpp.nullptr`
(D-OP-5, W-178); comparison of a pointer-niche Optional whose pointer type is
not `Core.Eq`, which is every built-in pointer (W-174, M-18) (amended
2026-10-13, review fold: A-1); a checked `Get()` (W-173; for `T*` it returns a
null, B-3); destruction of the held value (W-170).

### §1.2 Comparison

With `a` and `b` of type `Core.Optional(T)`, and `x`, `y` their values when they
hold one:

| Expression | both empty | `a` empty, `b` not | `a` not, `b` empty | both hold values |
| --- | --- | --- | --- | --- |
| `a == b` | true | false | false | `x == y` |
| `a != b` | false | true | true | `x != y` |
| `a < b` | false | true | false | `x < y` |
| `a <= b` | true | true | false | `x <= y` |
| `a > b` | false | false | true | `x > y` |
| `a >= b` | true | false | true | `x >= y` |

This is the table of C++ [optional.relops] for two `std::optional<T>` operands,
and the order Rust derives for `Option<T>` (D-OP-1, D-OP-2). `==` and `!=` exist
when `T` is `Core.Eq`; the four relational operators when `T` is `Core.Ordered`;
the two do not depend on each other (comparison_operators.md:466-472). The
operands must have the same type (D-OP-5). Each operator reads at most one copy
of each held value and destroys it before it returns; neither operand changes
(D-OP-4, M-5, `optional_compare_payload`). That copy and destroy are observable
for a `T` whose `Copy` or `Destroy` has an effect, a disclosed divergence from
comparison_operators.md:316 and :434 (V-3) (amended 2026-10-13, review fold:
A-2). Both statements hold where `T`'s own `Destroy` is complete: when `T` is
itself an Optional, the copy that `Get()` returns is destroyed without its held
value (W-170), so comparing two `Core.Optional(Core.Optional(P))` values whose
inner values hold `P1` and `P2` leaks one `P` per operand (review 1's
nesttrace.carbon prints `101 102 101 102 202 201 0` for `o1 == o2`)
(amended 2026-10-13, implementation review fold: R1-2).

Generic code compares Optionals by naming the payload's constraint (measured,
M-4 and `optional_compare_generic`):

```carbon
fn Same[T: Core.Eq & Core.Copy & Core.Destroy](a: Core.Optional(T),
                                               b: Core.Optional(T)) -> bool {
  return a == b;
}
```

In 0.1 a checked generic can compare only `Core.Optional(T)` values it receives:
a local or temporary `Core.Optional(T)` in its body is rejected, "cannot access
member of interface `Core.Destroy` in type `Core.Optional(T as
Core.OptionalStorage)`", because `Core.Optional` declares no `Destroy` impl
(W-170; review 1's gentemp.carbon, gentemp2.carbon and gentemp3.carbon, the same
on trunk) (amended 2026-10-13, implementation review fold: R1-2).

`Core.Optional(T*)` compares exactly when `T*` is `Core.Eq`. The prelude gives
built-in pointer types no `==` (§0.1 row 10, W-174), so `Core.Optional(i32*)`
and the other nullable C++ pointers do not compare, and their empty test is
`o.HasValue()`; a user library that owns a class `C` may implement `C* as
Core.EqWith(C*)`, and `Core.Optional(C*)` then compares through the null niche
(M-18, the `user_pointer` split of §2.3) (amended 2026-10-13, review fold: A-1).
`Core.Optional(bool)` is `Core.Eq`, but in 0.1 comparing it crashes the compiler
(W-171, M-20) (amended 2026-10-13, review fold: A-8). The same root cause makes
`==` on `Core.Optional(Core.Optional(U*))` return wrong values silently (W-171),
and `==` on `Core.Optional(Core.IntLiteral)` passes check and aborts lowering
(W-190) (amended 2026-10-13, implementation review fold: R1-1, R1-4).

### §1.3 Ownership and lifetime

-   `Some(v)` stores a copy of `v`; `Get()` returns a copy of the held value;
    copying an Optional copies its value (`T.Copy`, :50-54, :172-178).
-   The design rule F-015 states: an Optional owns its value, and destroying a
    non-empty Optional destroys it, as C++ `std::optional` and Rust `Option` do,
    and as p001154's considered `Optional` sketch does (`if (me.holds_value)
    value.Destroy();`, :211-227) (amended 2026-10-13, review fold: A-9). The 0.1
    toolchain does not: the default storage's `MaybeUnformed(T)` runs no
    destructor, so a `T` with a `Destroy` that matters (one that frees or
    counts) leaks one destruction per held value (M-5, M-6). Filed as W-170, one
    of the two items keeping the row PARTIAL (D-OP-13), with
    `optional_destroys_value` as its write-tests-first arbiter (M-20) (amended
    2026-10-13, review fold: B-2). The fix must keep `Core.Optional(T*)`
    trivially destructible for union fields (M-6): under classes.md:1992-2003 a
    class that defines a destructor with a non-empty body is not
    `TrivialDestructor` (corrected 2026-10-13, implementation review fold:
    R1-7), and p001154's conditional `TrivialDestructor` impl was a considered
    alternative, not adopted (amended 2026-10-13, review fold: A-9). The PASS
    programs and the examples do not rely on either behavior (`optional_compare_payload`
    prints its counts before any Optional is destroyed).
-   Comparisons never move or destroy a held value; a comparison of two
    non-empty operands runs `T.Copy` and `T.Destroy` once per value, and one
    with an empty operand runs neither (D-OP-4, M-5, V-3) (amended 2026-10-13,
    review fold: A-2). Until W-170 lands, comparing two non-empty
    `Core.Optional(Core.Optional(T))` values also leaks one copy of each `T`
    that the inner values hold (amended 2026-10-13, implementation review fold:
    R1-2).
-   `Core.Optional(T)` is not `Core.Plain` for any `T` under F-013 (D-SAFE-9;
    mutation_safety.md:317 on the safe branch): its payload sub-object exists
    only for a non-empty value, so assigning an Optional through a shared path
    is an invalidating operation in Strict Carbon (amended 2026-10-13, review
    fold: B-5).
-   `Get()` requires `HasValue()` and is unchecked in 0.1 (W-173, M-9). For
    `Core.Optional(T*)` it returns a null `T*` whose dereference needs no
    `unsafe`, which falsifies F-013's TY4 (type_safety.md:179-195 and its
    checklist row :342 on the safe branch: "that marker is the only place a null
    can be dereferenced"); F-015, the V-3a register and W-173 record the
    contradiction between the two fork designs, and D-OP-13 makes it a DONE gate
    (amended 2026-10-13, review fold: B-3).
-   Assignment `o = p;` does not destroy the old value of any class with a
    `Destroy` (ST-1's W-160, filed on the st branch; named here by its title if
    PR 55 has not landed at discharge).

### §1.4 Placeholder or design: what F-015 answers

The TODO at :28-29 says there is no approved design and calls the API a
placeholder. Upstream still has none (p006357:251-253, :341-342). The fork
answers with F-015: the type keeps its identity (D-EH-1), its API is the one the
language already depends on (loops.md:104-114 and
handle_loop_statement.cpp:280-291 call `HasValue` and `Get`; p006357 needs the
pointer niche; error_handling.md D9 needs `Try`), and the comparisons of §1.2
complete the operations the design examples leave "omitted for brevity"
(sum_types.md:181-182) except destruction (W-170). docs/design/optional.md is
that design (§2.5); the TODO stays as upstream wrote it, with a dated amendment
line above it (D-OP-6, D-OP-8).

### §1.5 C++ interop (boundary)

Unchanged by OP-1: a nullable C++ `T*` imports as `Core.Optional(T*)` and
`Core.Optional(T*)` exports as `T*` (§0.1 row 9); `Cpp.nullptr` converts to
`Optional(T*).None()` (nullptr.carbon:50-54). Not in scope: a `std::optional<T>`
mapping in either direction, which is the open half of W-011 under the bullet
"Control flow: matching — sum-type consumption incl. std::variant/std::optional
interop" (gap row 68); OP-1 neither designs nor constrains it. F-015 records
only that if that mapping targets `Core.Optional(T)`, F-015 is amended first
(W-011's coherence note, "Optional's redesign (W-058) folds into these
deliverables", gets OP-1's resolution at discharge). Comparing two C++ pointers
in Carbon needs W-174.

### §1.6 Interplay with `Try` and iteration

`?` over an Optional (the `Try` impl, :56-78) and `for` over any `Iterate`
(whose `Next` returns an Optional, iterate.carbon:12-18) are unchanged: no line
they use moves or changes (D-OP-8), every golden passes unchanged (M-12) and
every program that uses them passes (M-17). The iteration interplay that remains
is W-176: `Iterate.ElementType` must be `Copy & Destroy` (iterate.carbon:13-14,
"TODO: Support iterating ranges of non-copyable values") because `Optional(T)`
requires it.

### §1.7 What OP-1 does not do (residue titles; ids reserved at the head, filed at §2.6)

-   W-170 (Stdlib: Optional; row-bounding): an Optional never destroys the value
    it holds; the default storage holds a `MaybeUnformed(T)` (:140-143,
    maybe_unformed.carbon:12-15). A declared `Destroy` fixes the probe but
    rejects `Core.Optional(T*)` union fields and moves 26 goldens (M-6);
    classes.md:1992-2003 and p001154:211-227 are the design inputs (A-9).
    Arbiter: `optional_destroys_value` (SKIP, M-20) (amended 2026-10-13, review
    fold: A-9, B-2). Its consequences for comparison: a checked generic cannot
    hold or compare a local or temporary `Core.Optional(T)`, and comparing two
    nested non-empty Optionals leaks one payload copy per operand; M-6's
    prototype removes both (amended 2026-10-13, implementation review fold:
    R1-2).
-   W-171 (Stdlib: Optional; row-bounding): `Core.Optional(bool)`'s `Get()` and
    copy crash the compiler (lowering: LLVM verifier "Function return type does
    not match operand type of return inst!", and handle_call.cpp:984 `args_ok`);
    outside Optional, `Core.MaybeUnformed(bool) unsafe as bool` fails the CHECK
    at check/convert.cpp:1698; upstream nightly 2026.10.12 too (M-7). With OP-1
    the same crash is reached from `==` on `Optional(bool)`, where trunk and
    upstream give a check error (A-8). Arbiter: `optional_bool` (SKIP, M-20).
    SC-1 moves the CHECK from convert.cpp:1698 to :1712 (amended 2026-10-13,
    review fold: A-8, B-2, B-8). The root cause is wider than `bool`: the
    default storage's `Get` and `Copy` (:169-171, :172-178) read
    `MaybeUnformed(T) unsafe as T` and pass the field's address where `T`'s
    value is expected, with no load, so for `Core.Optional(Core.Optional(U*))`,
    where both sides are a `ptr`, nothing aborts and `Get()` and a copy return
    wrong values (on trunk too), and OP-1's `==` on it returns wrong answers
    where trunk gave a check error; second arbiter `optional_nested_pointer`
    (SKIP) (amended 2026-10-13, implementation review fold: R1-1).
-   W-172 (Generics: generic functions and types; found while measuring): a
    float or character literal passed for a `T: Core.Copy & Core.Destroy`
    parameter of a generic class's method (`Core.Optional(f64).Some(2.5)`,
    `Box(f64).Make(2.5)`) aborts check, "FATAL ... custom_witness.cpp:487:
    Unexpected type for CanDestroyType: FloatLiteralType" (`CharLiteralType`);
    upstream nightly at :401 (M-8).
-   W-173 (Stdlib: Optional): `Get()` on an empty Optional is unchecked: it
    reads the unformed storage (prints garbage) or returns the null pointer of
    the niche (SIGSEGV on dereference) (M-9). A checked `Get` would fail-stop as
    `Core.Slice` does (D-SL-4), at the cost of a branch in every `Get` and a
    refill of every lower golden that instantiates `Get` (the `for` goldens
    among them). For `Core.Optional(T*)` the null it returns is dereferenced
    with no `unsafe`, which falsifies F-013's TY4 (type_safety.md:179-195, :342
    on the safe branch); related to SAFE-1's W-146 and to SP4's model of checked
    access with an `unsafe` opt-out (spatial_safety.md:206); a DONE gate of
    D-OP-13 while TY4 stands as written (amended 2026-10-13, review fold: B-3).
-   W-174 (Stdlib: pointer types; design-needed): the prelude gives built-in
    pointer types no `==`/`!=` (no `T* as EqWith(T*)`, no builtin, none in
    comparison_operators.md:479-505), so `Core.Optional(T*)` compares only when
    `T*` is `Core.Eq`: never for a built-in pointer such as the C++ nullable
    pointer `Core.Optional(i32*)`, while a user library can make
    `Core.Optional(C*)` compare for its own class `C` (M-18); and `o ==
    Cpp.nullptr` has no impl either (nullptr.carbon:48's TODO). A `final`
    prelude pointer `==` would make every user `impl C* as EqWith(C*)` an error
    and change `==` on `Optional(C*)` from the user's rule to the prelude's
    (M-18), so W-174's design must choose between `final` and a non-final impl
    and say what happens to user pointer impls (amended 2026-10-13, review fold:
    A-1). The arbiter is `optional_pointer_compare` (SKIP), which does not bound
    the Optional row (D-OP-13).
-   W-175 (Stdlib: Optional): no explicit `as` between Optionals, `impl forall
    [U: type, T: As(U)] Optional(T) as As(Optional(U))`, which is the design's
    own example (README.md:3260-3261, details.md:4655-4665); the implicit
    direction exists (:117-133).
-   W-176 (Stdlib: Optional): `Core.Optional(T)` requires `T: Copy & Destroy`
    (or a pointer) through the private `OptionalStorage` (:16-26, :30, :148),
    where the design's `Optional(T: Movable)` keeps the storage bound out of the
    public API (details.md:6988-7015): generic code must name
    `Core.Copy & Core.Destroy` (M-10), a non-copyable value (`Core.Buf`, ST-1's
    `Core.StringBuf`) cannot be held, and `Iterate.ElementType` must be copyable
    (iterate.carbon:13-14).
-   W-177 (Control flow: matching — sum-type consumption incl.
    std::variant/std::optional interop): `Core.Optional` is not matchable: no
    `.Some`/`.None` patterns, no `match` or `if let` over it, because it is a
    class (D-EH-1) and sum_types.md's `Match` interface for classes (:154-184)
    is unimplemented; the design examples (sum_types.md:63-75,
    pattern_matching.md:501-527) and error_handling.md's `Try` sketch (:392-405)
    assume it. Related: W-011. Dependents on the safe branch: SAFE-1's EX-M-5
    and EX-M-6 (mutation_safety.md:664-683, :724-725, :801-803), whose staging
    waits on "the choice-based `Core.Optional` redesign the prelude's own
    comment names", which F-015 does not make; they wait on W-177 instead
    (amended 2026-10-13, review fold: B-5).
-   W-178 (Generics: Checked generics): the `like` operator (details.md:6598,
    comparison_operators.md:289-300) is a keyword with no parser support
    (token_kind.def:214; M-10), so no comparison admits implicit conversions of
    its operands; for Optional, `o == v` and `o == Cpp.nullptr` have no impl.
-   W-179 (Generics: Checked generics; found by review A-10): p5337:280-286
    makes a non-final impl that a `final` impl completely subsumes an error, but
    the toolchain diagnoses it only where it is used: `impl Core.Optional(Q) as
    Core.EqWith(Core.Optional(Q))` beside §2.1's final impl compiles as a
    declaration and fails "`impl` will never be used" only at an `==` (M-11).
    Pinned by the `fail_specialize` and `todo_fail_specialize_unused` splits
    (§2.3) (amended 2026-10-13, review fold: A-10).
-   W-190 (Generics: generic functions and types; found by the implementation
    review, R1-4; the first id after DD-1's reserved W-180..W-189, re-scanned at
    discharge with the others): a checked generic body that applies a
    compile-time-only operation to a symbolic `T` aborts lowering instead of
    being evaluated or diagnosed. With OP-1, `==` on two
    `Core.Optional(Core.IntLiteral)` values checks clean and `carbon compile`
    aborts in lowering `Equal` (optional.carbon:217, the call at :224) on an
    `llvm::cast` assertion, where trunk gives `MissingImplInMemberAccess`;
    without Optional, `fn Eq2[T: Core.Eq](a: T, b: T)` called as `Eq2(1, 2)`
    aborts the same way on trunk (amended 2026-10-13, implementation review
    fold: R1-4).
-   Not filed again: assignment does not destroy the old value (ST-1's W-160);
    temporaries of a declaration initializer live to the end of the block
    (ST-1's M-7, design per F-013 D-SAFE-12).

## §2 Implementation spec, file by file

### §2.1 core/prelude/types/optional.carbon (204 → 275 lines; no existing line moves)

The whole change as a patch with one line of context (no blank context line, so
the block below applies with `git apply` exactly as extracted from this file):
the import on :13 and the blank line :27 are replaced (D-OP-8), and :205-275 are
appended after :204. The date on line 27 is the date commit 2 is made, written
once and never re-stamped, so no records commit changes core/ source (amended
2026-10-13, review fold: B-9); any `YYYY-MM-DD` keeps that line at 75 columns.
The measured text used 2026-10-14.

```diff
--- a/core/prelude/types/optional.carbon
+++ b/core/prelude/types/optional.carbon
@@ -12,3 +12,3 @@
 import library "prelude/try";
-import library "prelude/types/bool";
+import library "prelude/operators/comparison";
 import library "prelude/types/maybe_unformed";
@@ -26,3 +26,3 @@
 }
-
+// Fork amendment (2026-10-14, F-015): designed in docs/design/optional.md.
 // TODO: We don't have an approved design for an `Optional` type yet, but it's
@@ -204 +204,72 @@
 }
+
+// Fork (OP-1, F-015, docs/design/optional.md): comparison when `T` compares,
+// with the semantics of C++ `std::optional`'s relational operators and Rust's
+// `Option`. Two empty values are equal; an empty and a non-empty value are
+// not; two non-empty values compare as their values do under `T`'s own
+// operator; and an empty value orders before every non-empty one. Each
+// function tests `HasValue()` before it calls `Get()`, so the storage of an
+// empty operand is never read. `Get()` returns a copy, destroyed by the end of
+// the call, so `Destroy` is in the bound (as in the `Try` impl above), and the
+// operands are left unchanged.
+final impl forall [T: Destroy & OptionalStorage & Eq]
+    Optional(T) as EqWith(Optional(T)) {
+  fn Equal(self, other: Optional(T)) -> bool {
+    if (self.HasValue() != other.HasValue()) {
+      return false;
+    }
+    if (not self.HasValue()) {
+      return true;
+    }
+    return self.Get() == other.Get();
+  }
+  fn NotEqual(self, other: Optional(T)) -> bool {
+    if (self.HasValue() != other.HasValue()) {
+      return true;
+    }
+    if (not self.HasValue()) {
+      return false;
+    }
+    return self.Get() != other.Get();
+  }
+}
+
+final impl forall [T: Destroy & OptionalStorage & Ordered]
+    Optional(T) as OrderedWith(Optional(T)) {
+  fn Less(self, other: Optional(T)) -> bool {
+    if (not other.HasValue()) {
+      return false;
+    }
+    if (not self.HasValue()) {
+      return true;
+    }
+    return self.Get() < other.Get();
+  }
+  fn LessOrEquivalent(self, other: Optional(T)) -> bool {
+    if (not self.HasValue()) {
+      return true;
+    }
+    if (not other.HasValue()) {
+      return false;
+    }
+    return self.Get() <= other.Get();
+  }
+  fn Greater(self, other: Optional(T)) -> bool {
+    if (not self.HasValue()) {
+      return false;
+    }
+    if (not other.HasValue()) {
+      return true;
+    }
+    return self.Get() > other.Get();
+  }
+  fn GreaterOrEquivalent(self, other: Optional(T)) -> bool {
+    if (not other.HasValue()) {
+      return true;
+    }
+    if (not self.HasValue()) {
+      return false;
+    }
+    return self.Get() >= other.Get();
+  }
+}
```

Compile verification (M-3, M-12): with exactly this file in the scratch install
copy, `XDG_CACHE_HOME=$S/cache-v2 $S/install-copy/bin/carbon
compile --phase=check --output-last-input-only optional_missing_ops.carbon`
exits 0 with no diagnostic from core/; `$S/bin/run.sh $S/install-copy
$S/cache-v2 .../optional_missing_ops.carbon` prints `compile rc=0`, `link rc=0`,
`run rc=0` and `1`; the trunk file_test over the whole manifest prints
`Ran 1942 tests` and `[  PASSED  ] 1942 tests.`; `git apply --check` of the
patch on 9d3ca60a3 is clean. The `final impl` of `EqWith` is :215, which the
`fail_specialize` note of §2.3 pins
(`{{.*}}/prelude/types/optional.carbon:215:1`); an edit above :215 moves that
note and autoupdate follows.

### §2.2 Toolchain

None. OP-1 changes no C++ source, no SemIR instruction, no builtin and no
diagnostic (W-171 and W-172 are filed, not fixed, §0.2 "Not measured").

### §2.3 Goldens (sources only: `// AUTOUPDATE`, no CHECK lines; R15/R16)

Three new files under two new directories (the check and lower `testdata`
filegroups glob `testdata/**/*.carbon`, toolchain/check/BUILD:11-12 and
toolchain/lower/BUILD:10-11, so no BUILD edit). Their TIP lines are what
autoupdate writes, and the implementer may omit them and let autoupdate add
them. Each source below is byte for byte the text the fill of M-15 ran (rev 2's
sources: `IsLe` and `IsGt` in the concrete splits, the `user_pointer` split and
the `todo_fail_specialize_unused` split are new; amended 2026-10-13, review
fold: A-1, A-3, A-10, B-1) (at substitute paths, which change only the TIP
lines, the `ModuleID`, `source_filename` and `DIFile` names and the split-file
names). The positive check splits bracket their code with
`//@dump-sem-ir-begin`/`end` (the SL-1 and ST-1 rule); function names avoid
prelude names (M-15's `@Eq.loc5`).

toolchain/check/testdata/optional/compare.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/compare.carbon

// Fork (OP-1, fork/optional/plan.md §4): `Core.Optional(T)` implements
// `EqWith` and `OrderedWith` with itself when `T` is `Core.Eq` or
// `Core.Ordered` (D-OP-1..D-OP-3), the pointer niche included when the pointer
// type is `Core.Eq`.

// --- concrete.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn IsEq(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a == b; }
fn IsNe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a != b; }
fn IsLt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a < b; }
fn IsLe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a <= b; }
fn IsGt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a > b; }
fn IsGe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a >= b; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Same[T: Core.Eq & Core.Copy & Core.Destroy](a: Core.Optional(T),
                                               b: Core.Optional(T)) -> bool {
  return a == b;
}

fn UseSame(a: Core.Optional(i64)) -> bool { return Same(a, a); }
//@dump-sem-ir-end

// --- ordered_only.carbon

library "[[@TEST_NAME]]";

class Rank {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

impl Rank as Core.OrderedWith(Rank) {
  fn Less(self, other: Rank) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: Rank) -> bool { return self.v <= other.v; }
  fn Greater(self, other: Rank) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: Rank) -> bool {
    return self.v >= other.v;
  }
}

//@dump-sem-ir-begin
fn RankLess(a: Core.Optional(Rank), b: Core.Optional(Rank)) -> bool {
  return a < b;
}
//@dump-sem-ir-end

// --- user_pointer.carbon

library "[[@TEST_NAME]]";

class C {
  var v: i32;
}

// Allowed in this library because `C` is local; the prelude gives `C*` no
// `==`, so this impl is what makes `Core.Optional(C*)` comparable.
impl C* as Core.EqWith(C*) {
  fn Equal(self, other: C*) -> bool { return self->v == other->v; }
  fn NotEqual(self, other: C*) -> bool { return self->v != other->v; }
}

//@dump-sem-ir-begin
fn SameC(a: Core.Optional(C*), b: Core.Optional(C*)) -> bool {
  return a == b;
}
//@dump-sem-ir-end
```

toolchain/check/testdata/optional/fail_compare.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/fail_compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/fail_compare.carbon

// Fork (OP-1, fork/optional/plan.md §4): what `Core.Optional(T)` comparison
// does not accept (D-OP-1..D-OP-3, W-174, W-176, W-178), and one subsumed
// specialization that compiles today although p5337 makes it an error.

// --- fail_not_eq.carbon

library "[[@TEST_NAME]]";

class NoEq {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

fn F(a: Core.Optional(NoEq), b: Core.Optional(NoEq)) -> bool {
  return a == b;
}

// --- fail_pointer.carbon

library "[[@TEST_NAME]]";

fn F(a: Core.Optional(i32*), b: Core.Optional(i32*)) -> bool {
  return a == b;
}

// --- fail_value_operand.carbon

library "[[@TEST_NAME]]";

fn F(a: Core.Optional(i32), b: i32) -> bool {
  return a == b;
}

// --- fail_different_payloads.carbon

library "[[@TEST_NAME]]";

fn F(a: Core.Optional(i32), b: Core.Optional(i64)) -> bool {
  return a == b;
}

// --- fail_generic_without_copy.carbon

library "[[@TEST_NAME]]";

fn F[T: Core.Eq](a: Core.Optional(T), b: Core.Optional(T)) -> bool {
  return a == b;
}

// --- fail_specialize.carbon

library "[[@TEST_NAME]]";

class Q {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

impl Q as Core.EqWith(Q) {
  fn Equal(self, other: Q) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: Q) -> bool { return self.v != other.v; }
}

impl Core.Optional(Q) as Core.EqWith(Core.Optional(Q)) {
  fn Equal(self, unused other: Core.Optional(Q)) -> bool {
    return self.HasValue();
  }
  fn NotEqual(self, unused other: Core.Optional(Q)) -> bool {
    return not self.HasValue();
  }
}

fn F(a: Core.Optional(Q), b: Core.Optional(Q)) -> bool {
  return a == b;
}

// --- todo_fail_specialize_unused.carbon

library "[[@TEST_NAME]]";

// TODO: p5337 makes a non-final impl that a `final` impl subsumes an error at
// its declaration; the toolchain diagnoses it only where it is used
// (`fail_specialize` above), so this declaration alone compiles (W-179).

class R {
  var v: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.v = self.v}; }
  }
}

impl R as Core.EqWith(R) {
  fn Equal(self, other: R) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: R) -> bool { return self.v != other.v; }
}

impl Core.Optional(R) as Core.EqWith(Core.Optional(R)) {
  fn Equal(self, unused other: Core.Optional(R)) -> bool {
    return self.HasValue();
  }
  fn NotEqual(self, unused other: Core.Optional(R)) -> bool {
    return not self.HasValue();
  }
}
```

toolchain/lower/testdata/optional/compare.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/optional/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/optional/compare.carbon

// Fork (OP-1, fork/optional/plan.md §4): the comparison impls are generic, so
// the `Optional(i32)` specific of each impl function is emitted here, with its
// `HasValue()` tests before its `Get()` calls (D-OP-1, D-OP-2, D-OP-4).

fn IsEq(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a == b; }
fn IsNe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a != b; }
fn IsLt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a < b; }
fn IsLe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a <= b; }
fn IsGt(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a > b; }
fn IsGe(a: Core.Optional(i32), b: Core.Optional(i32)) -> bool { return a >= b; }
```

### §2.4 Conformance programs (bullet "Stdlib: Optional", R7)

fork/conformance/programs/stdlib/optional_missing_ops.carbon, un-SKIPped: line 6
(`// SKIP:`) is deleted, the explanatory paragraph is rewritten (the un-SKIP
condition it states is met), the EXPECT lines are unchanged, and in the body
only one comment changes (:23 before, :22 after the SKIP line goes:
`// Missing: ...` becomes `// ... both hold 1.`); every code line is as written
test-first. The whole file after OP-1:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//
// Written test-first for the Optional bullet and un-SKIPped at OP-1
// (fork/optional/plan.md; working slices: optional_basic.carbon,
// optional_pointer_niche.carbon). `a == b` on two `Core.Optional(i32)` values
// is the conditional `Optional(T) as EqWith(Optional(T))` impl, which applies
// because `i32` is `Core.Eq` (core/prelude/types/optional.carbon; fork design
// F-015, docs/design/optional.md): both values hold 1, so they are equal.

import Core library "io";

fn Run() -> i32 {
  var a: Core.Optional(i32) = Core.Optional(i32).Some(1);
  var b: Core.Optional(i32) = Core.Optional(i32).Some(1);
  // `Optional(T) as EqWith(Optional(T))`: both hold 1.
  Core.Print(if a == b then 1 else 0);
  return 0;
}
```

fork/conformance/programs/stdlib/optional_compare_diff.carbon and its oracle
optional_compare_diff.diff.cpp (clang-format 21.1.8 clean, M-16; rev 2 replaces
the 16 rev 1 lines with the 36-line matrix of every case of all six operators;
amended 2026-10-13, review fold: A-3, B-1):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
//
// Differential pair: optional_compare_diff.diff.cpp is the equivalent C++17
// program over `std::optional<int>`, whose comparison operators compare
// engagement first and then the held values, an empty optional ordering
// before every engaged one ([optional.relops]); the runner requires
// byte-identical exit code and stdout, so C++ is the oracle for every line (no
// EXPECT-STDOUT here, the arith_widths_diff precedent). Carbon side: `==` and
// `!=` are `Optional(T) as EqWith(Optional(T))`, and `<`, `<=`, `>` and `>=`
// are `Optional(T) as OrderedWith(Optional(T))`, both in
// core/prelude/types/optional.carbon (fork design F-015,
// docs/design/optional.md). `Row` prints all six operators for one pair of
// operands, and `Run` covers every case of each operator: both empty, only the
// left empty, only the right empty, and two values that are less, equal and
// greater. `Make` builds every operand at run time, so no comparison folds.
// Core.Print lowers to printf("%d\n", x), mirrored by the C++ side.

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

// `Some(n)` for `n >= 0`, empty for a negative `n`.
fn Make(n: i32) -> Core.Optional(i32) {
  if (n < 0) {
    return Core.Optional(i32).None();
  }
  return Core.Optional(i32).Some(n);
}

// The six comparisons of `a` with `b`, in the order ==, !=, <, <=, >, >=.
fn Row(a: Core.Optional(i32), b: Core.Optional(i32)) {
  Core.Print(B(a == b));
  Core.Print(B(a != b));
  Core.Print(B(a < b));
  Core.Print(B(a <= b));
  Core.Print(B(a > b));
  Core.Print(B(a >= b));
}

fn Run() -> i32 {
  // Both empty.
  Row(Make(-1), Make(-2));
  // Only the left empty: an empty value orders before every value, 0 included.
  Row(Make(-1), Make(0));
  // Only the right empty.
  Row(Make(0), Make(-1));
  // Two values: less, equal, greater.
  Row(Make(0), Make(1));
  Row(Make(1), Make(1));
  Row(Make(1), Make(0));
  return 0;
}
```

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// C++17 oracle for optional_compare_diff.carbon: the same comparisons over
// std::optional<int>, printed as printf("%d\n", x).

#include <cstdio>
#include <optional>

static auto B(bool b) -> int { return b ? 1 : 0; }

static auto Make(int n) -> std::optional<int> {
  if (n < 0) {
    return std::nullopt;
  }
  return n;
}

// The six comparisons of `a` with `b`, in the order ==, !=, <, <=, >, >=.
static auto Row(std::optional<int> a, std::optional<int> b) -> void {
  std::printf("%d\n", B(a == b));
  std::printf("%d\n", B(a != b));
  std::printf("%d\n", B(a < b));
  std::printf("%d\n", B(a <= b));
  std::printf("%d\n", B(a > b));
  std::printf("%d\n", B(a >= b));
}

auto main() -> int {
  Row(Make(-1), Make(-2));
  Row(Make(-1), Make(0));
  Row(Make(0), Make(-1));
  Row(Make(0), Make(1));
  Row(Make(1), Make(1));
  Row(Make(1), Make(0));
  return 0;
}
```

fork/conformance/programs/stdlib/optional_compare_generic.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   1
//   1
//   0
//   1
//
// Comparison in checked-generic code: `Count` and `Before` compare
// `Core.Optional(T)` values through the conditional impls
// `Optional(T) as EqWith(Optional(T))` and
// `Optional(T) as OrderedWith(Optional(T))`, both in
// core/prelude/types/optional.carbon (fork design F-015,
// docs/design/optional.md), which apply when `T` is `Core.Eq` or
// `Core.Ordered`. `T` is `i32`, a user class `Point` with its own
// `EqWith`, and `Core.Optional(i32)` itself, so the nested comparison runs the
// impl twice. The bounds also name `Core.Copy & Core.Destroy` because
// `Core.Optional(T)` needs a storage impl for `T`, which only those provide in
// user code (W-176). Expected, from F-015's rules: two of three `i32` values
// equal `Some(7)`; one `Point` equals `Some(p)` (`q` differs in `y`, an empty
// value differs from every value); `Some(None)` equals only itself, not
// `None` and not `Some(Some(7))`; `Some(7)` does not order before `None`; and
// `None` orders before `Some(None)`.

import Core library "io";

class Point {
  var x: i32;
  var y: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.x = self.x, .y = self.y}; }
  }
}

impl Point as Core.EqWith(Point) {
  fn Equal(self, other: Point) -> bool {
    return self.x == other.x and self.y == other.y;
  }
  fn NotEqual(self, other: Point) -> bool {
    return self.x != other.x or self.y != other.y;
  }
}

// How many of `a`, `b` and `c` equal `want`.
fn Count[T: Core.Eq & Core.Copy & Core.Destroy](
    want: Core.Optional(T), a: Core.Optional(T), b: Core.Optional(T),
    c: Core.Optional(T)) -> i32 {
  var n: i32 = 0;
  if (a == want) {
    ++n;
  }
  if (b == want) {
    ++n;
  }
  if (c == want) {
    ++n;
  }
  return n;
}

// Whether `a` orders before `b`.
fn Before[T: Core.Ordered & Core.Copy & Core.Destroy](
    a: Core.Optional(T), b: Core.Optional(T)) -> bool {
  return a < b;
}

fn Run() -> i32 {
  let none: Core.Optional(i32) = Core.Optional(i32).None();
  let seven: Core.Optional(i32) = Core.Optional(i32).Some(7);
  Core.Print(Count(seven, seven, none, seven));

  let p: Point = {.x = 1, .y = 2};
  let q: Point = {.x = 1, .y = 3};
  let some_p: Core.Optional(Point) = Core.Optional(Point).Some(p);
  let some_q: Core.Optional(Point) = Core.Optional(Point).Some(q);
  let no_point: Core.Optional(Point) = Core.Optional(Point).None();
  Core.Print(Count(some_p, some_q, no_point, some_p));

  let some_none: Core.Optional(Core.Optional(i32)) =
      Core.Optional(Core.Optional(i32)).Some(none);
  let some_seven: Core.Optional(Core.Optional(i32)) =
      Core.Optional(Core.Optional(i32)).Some(seven);
  let outer_none: Core.Optional(Core.Optional(i32)) =
      Core.Optional(Core.Optional(i32)).None();
  Core.Print(Count(some_none, some_none, outer_none, some_seven));

  Core.Print(if Before(seven, none) then 1 else 0);
  Core.Print(if Before(outer_none, some_none) then 1 else 0);
  return 0;
}
```

fork/conformance/programs/stdlib/optional_compare_payload.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   0
//   1
//   0
//   2
//   1
//   2
//   2
//
// Comparing `Core.Optional(T)` values never moves or destroys the values they
// hold (fork design F-015, docs/design/optional.md): a comparison reads each
// held value through `Get()`, which returns a copy, and each copy is destroyed
// by the end of the comparison. `Tracked` counts its live copies through a
// pointer: its `Copy` adds one and its `Destroy` removes one. Expected, from
// F-015's rules: `Some` stores a copy of its argument, so two values are held
// (2); `Some(1) == Some(2)` is 0 and `Some(1) < Some(2)` is 1; comparing an
// empty value reads no storage (0); the comparisons left no copy alive, so the
// count is still 2; the held values are unchanged (1 and 2); and each `Get()`
// copy above died with its statement, so the count is 2 again. The held
// values themselves are never destroyed in 0.1 (W-170, arbitrated by
// optional_destroys_value.carbon), which no line here observes: every count is
// printed before `Run` returns.

import Core library "io";

class Tracked {
  var v: i32;
  var live: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.live;
      return {.v = self.v, .live = self.live};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      --*self.live;
    }
  }
}

impl Tracked as Core.EqWith(Tracked) {
  fn Equal(self, other: Tracked) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: Tracked) -> bool { return self.v != other.v; }
}

impl Tracked as Core.OrderedWith(Tracked) {
  fn Less(self, other: Tracked) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: Tracked) -> bool {
    return self.v <= other.v;
  }
  fn Greater(self, other: Tracked) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: Tracked) -> bool {
    return self.v >= other.v;
  }
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  var live: i32 = 0;
  var t1: Tracked = {.v = 1, .live = &live};
  var t2: Tracked = {.v = 2, .live = &live};
  var a: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t1);
  var b: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t2);
  var n: Core.Optional(Tracked) = Core.Optional(Tracked).None();
  Core.Print(live);
  Core.Print(B(a == b));
  Core.Print(B(a < b));
  Core.Print(B(n == a));
  Core.Print(live);
  Core.Print(a.Get().v);
  Core.Print(b.Get().v);
  Core.Print(live);
  return 0;
}
```

fork/conformance/programs/stdlib/optional_pointer_compare.carbon
(write-tests-first SKIP; R6: its body compiles on §2.1 except for the one
diagnostic its SKIP line quotes, M-16; R10: the SKIP line states that diagnostic
verbatim; its header says that it does not bound the row and that `Optional(T*)`
compares exactly when `T*` is `Core.Eq`; amended 2026-10-13, review fold: A-1,
B-2):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of W-174 (filed under "Stdlib: pointer types"; it does not bound this bullet's row, fork/optional/plan.md D-OP-13): `Core.Optional(T*)` compares exactly when `T*` is `Core.Eq` (the conditional `Optional(T) as EqWith(Optional(T))` impl, core/prelude/types/optional.carbon, OP-1), and the prelude gives the built-in pointer type `i32*` no `==` (no `T* as EqWith(T*)` impl in core/prelude, and docs/design/expressions/comparison_operators.md:479-505 gives no pointer comparison); `a == b` on two Core.Optional(i32*) values fails with "error: cannot access member of interface `Core.EqWith(Core.Optional(i32* as Core.OptionalStorage))` in type `Core.Optional(i32* as Core.OptionalStorage)` that does not implement that interface" (W-174)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   0
//   1
//   0
//
// Write-tests-first program for the pointer-niche slice of the Optional
// bullet (working slices: optional_pointer_niche.carbon,
// optional_compare_diff.carbon). A user library can already make
// `Core.Optional(C*)` compare for its own class `C` by implementing
// `C* as Core.EqWith(C*)`; `i32*` belongs to no user library, so only the
// prelude can give it `==`. Un-SKIP when W-174 gives `T*` an `EqWith(T*)` impl
// that compares addresses; the body then needs no change.
// Expected, from F-015's rules with address equality: two `Some` values
// holding the address of `n` are equal (1); `Some(&n)` and `Some(&m)` differ
// although `n` and `m` hold the same value (0); two empty values are equal
// (1); an empty value differs from `Some(&n)` (0).

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  var n: i32 = 1;
  var m: i32 = 1;
  let some_n: Core.Optional(i32*) = Core.Optional(i32*).Some(&n);
  let some_n_again: Core.Optional(i32*) = Core.Optional(i32*).Some(&n);
  let some_m: Core.Optional(i32*) = Core.Optional(i32*).Some(&m);
  let none: Core.Optional(i32*) = Core.Optional(i32*).None();
  Core.Print(B(some_n == some_n_again));
  Core.Print(B(some_n == some_m));
  Core.Print(B(none == Core.Optional(i32*).None()));
  Core.Print(B(none == some_n));
  return 0;
}
```

fork/conformance/programs/stdlib/optional_destroys_value.carbon
(write-tests-first SKIP, the arbiter of W-170; R6: it compiles, links and runs
on §2.1, printing the wrong counts its SKIP line quotes, and on M-6's `Destroy`
prototype it prints its EXPECT, M-20; amended 2026-10-13, review fold: B-2):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of this PARTIAL bullet (W-170): an Optional never destroys the value it holds, because `DefaultOptionalStorage(T)` holds it as a `MaybeUnformed(T)` (core/prelude/types/optional.carbon:140-143), which runs no destructor (core/prelude/types/maybe_unformed.carbon:12-15), and no `Destroy` impl for `Core.Optional` exists; compiled with OP-1 (and on trunk) this program exits 0 printing 2, 1, 1, 0, 3, 2 where EXPECT is 2, 0, 1, 0, 3, 0
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   0
//   1
//   0
//   3
//   0
//
// Write-tests-first program for the ownership rule of fork design F-015
// (docs/design/optional.md): an Optional owns the value it holds, and
// destroying a non-empty Optional destroys that value. `Tracked` counts its
// live objects through a pointer: `Make` and `Copy` add one, `Destroy`
// removes one. Each helper prints the count while its locals are alive, then
// returns, which destroys them. Expected, from F-015's rules: `Some(t)` holds a
// copy of `t`, so `HoldOne` has two live objects (2) and none once it returns
// (0); an empty Optional holds nothing, so `HoldNone` has one (1) and none
// after (0); copying an Optional copies its value, so `HoldCopy` has three (3)
// and none after (0). Each helper has its own counter, so a miss in one does
// not carry into the next. Un-SKIP when W-170 lands; the body then needs no
// change.

import Core library "io";

class Tracked {
  var live: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.live;
      return {.live = self.live};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      --*self.live;
    }
  }
}

fn Make(live: i32*) -> Tracked {
  ++*live;
  return {.live = live};
}

fn HoldOne(live: i32*) {
  var t: Tracked = Make(live);
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  Core.Print(*live);
}

fn HoldNone(live: i32*) {
  var unused t: Tracked = Make(live);
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).None();
  Core.Print(*live);
}

fn HoldCopy(live: i32*) {
  var t: Tracked = Make(live);
  var o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  var unused p: Core.Optional(Tracked) = o;
  Core.Print(*live);
}

fn Run() -> i32 {
  var one: i32 = 0;
  HoldOne(&one);
  Core.Print(one);
  var none: i32 = 0;
  HoldNone(&none);
  Core.Print(none);
  var copied: i32 = 0;
  HoldCopy(&copied);
  Core.Print(copied);
  return 0;
}
```

fork/conformance/programs/stdlib/optional_bool.carbon (write-tests-first SKIP,
the arbiter of W-171; R6: it checks on §2.1 with no diagnostic, and the abort
its SKIP line quotes is in lowering, M-20; it is the one OP-1 file that compares
`Core.Optional(bool)` values, as a SKIP, so R-3 does not apply to it; amended
2026-10-13, review fold: B-2):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of this PARTIAL bullet (W-171): with OP-1 this program checks with no diagnostic and `carbon compile` then aborts in lowering (exit 134) at "Lowering function Copy(bool as Core.Copy & Core.Destroy)" (core/prelude/types/optional.carbon:172) with "CHECK failure at toolchain/lower/handle_call.cpp:984: args_ok: Argument mismatch: call ptr @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.8ae0339be4ca7eba"(ptr %return, ptr %value1)"; without the copy, `Get()` and `==` abort with "Function return type does not match operand type of return inst!" and "CHECK failure at toolchain/lower/lower.cpp:48: !llvm::verifyModule(*module, options.llvm_verifier_stream)"; `Core.MaybeUnformed(bool)` and `bool` differ in value representation (toolchain/check/convert.cpp:1687-1704)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   1
//   0
//   1
//   0
//   1
//   0
//
// Write-tests-first program for `Core.Optional(bool)`, which fork design F-015
// (docs/design/optional.md) gives the same API and comparisons as every other
// `Core.Optional(T)`. Expected, from F-015's rules: `Some(true)` holds a value
// (1) and reads back as `true` (1); `Some(false)` reads back as `false` (0); a
// copy of `Some(true)` reads back as `true` (1); the empty value holds none
// (0); `Some(true) == Some(true)` (1); `Some(true) == Some(false)` (0). Un-SKIP
// when W-171 lands; the body then needs no change.

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  let yes: Core.Optional(bool) = Core.Optional(bool).Some(true);
  let no: Core.Optional(bool) = Core.Optional(bool).Some(false);
  let none: Core.Optional(bool) = Core.Optional(bool).None();
  Core.Print(B(yes.HasValue()));
  Core.Print(B(yes.Get()));
  Core.Print(B(no.Get()));
  var copy: Core.Optional(bool) = yes;
  Core.Print(B(copy.Get()));
  Core.Print(B(none.HasValue()));
  Core.Print(B(yes == Core.Optional(bool).Some(true)));
  Core.Print(B(yes == no));
  return 0;
}
```

The two existing programs keep their bodies and EXPECT lines; only their header
paragraphs change (§0.3 items 2 and 3). optional_basic.carbon after OP-1:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   -1
//   1
//   42
//   7
//   42
//
// Working slice of the Optional bullet: the API in
// core/prelude/types/optional.carbon that the fork's design F-015
// (docs/design/optional.md) adopts — `Core.Optional(T).None()` /
// `.Some(v)` constructors, `.HasValue()`, `.Get()`, the implicit
// `T -> Optional(T)` conversion (the `OptionalAs`-backed `ImplicitAs` impl,
// exercised as `var _: Core.Optional(i32) = a;` in
// toolchain/lower/testdata/primitives/optional.carbon), and the `Copy` impl
// (initializing one Optional from another, ibid. `fn F(c) { return c; }`).
// Call shapes follow examples/advent2024/io_utils.carbon (`unread_char`).
// Comparison is arbitrated by optional_missing_ops.carbon and the three
// optional_compare_* programs (OP-1).

import Core library "io";

fn ValueOr(o: Core.Optional(i32), fallback: i32) -> i32 {
  if (o.HasValue()) {
    return o.Get();
  }
  return fallback;
}

fn Run() -> i32 {
  var none: Core.Optional(i32) = Core.Optional(i32).None();
  Core.Print(if none.HasValue() then 1 else 0);
  Core.Print(ValueOr(none, -1));

  var some: Core.Optional(i32) = Core.Optional(i32).Some(42);
  Core.Print(if some.HasValue() then 1 else 0);
  Core.Print(some.Get());

  // Implicit conversion i32 -> Optional(i32).
  let v: i32 = 7;
  var conv: Core.Optional(i32) = v;
  Core.Print(ValueOr(conv, -1));

  // Optional(T) is Copy; the copy holds the same value.
  var copy: Core.Optional(i32) = some;
  Core.Print(copy.Get());
  return 0;
}
```

optional_pointer_niche.carbon after OP-1:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   -1
//   5
//   1
//
// Pointer-niche slice of the Optional bullet: `Optional(T*)` uses
// the null pointer as its `None` representation (`final impl forall
// [T: type] T* as OptionalStorage` with "pointer.make_null" /
// "pointer.is_null" builtins, core/prelude/types/optional.carbon:181-204),
// making it ABI-compatible with a C++ nullable pointer. Two `Optional(T*)`
// values compare exactly when `T*` is `Core.Eq`, and the prelude gives built-in
// pointers no `==` yet (W-174; optional_pointer_compare.carbon is the SKIPped
// arbiter). Same shapes as
// toolchain/lower/testdata/primitives/optional.carbon (`fn Convert(o:
// Core.Optional(i32*))` with `*o.Get()`). Also mutates through the stored
// pointer and exercises the implicit `T* -> Optional(T*)` conversion.

import Core library "io";

fn DerefOr(o: Core.Optional(i32*), fallback: i32) -> i32 {
  if (o.HasValue()) {
    return *o.Get();
  }
  return fallback;
}

fn Run() -> i32 {
  var n: i32 = 42;
  var some: Core.Optional(i32*) = Core.Optional(i32*).Some(&n);
  var none: Core.Optional(i32*) = Core.Optional(i32*).None();
  Core.Print(DerefOr(some, -1));
  Core.Print(DerefOr(none, -1));

  // Write through the pointer held by the Optional.
  *some.Get() = 5;
  Core.Print(n);

  // Implicit conversion i32* -> Optional(i32*): non-null pointer => Some.
  var p: i32* = &n;
  var conv: Core.Optional(i32*) = p;
  Core.Print(if conv.HasValue() then 1 else 0);
  return 0;
}
```

fork/conformance/README.md: the program table is regenerated by `python3
fork/conformance/runner.py --update-readme-table` (seven rows new or changed,
M-16; amended 2026-10-13, review fold: B-2), never edited by hand.

The implementation review's fold adds
fork/conformance/programs/stdlib/optional_nested_pointer.carbon, a
write-tests-first SKIP and W-171's second arbiter (R6: compiled on the OP-1
install it exits 0 printing `1 1 1 0 0` where its EXPECT, derived from F-015's
rules in §5, is `1 0 0 1 1`; on trunk the four lines before its `==` print `1 1
1 0` and the `==` is the `MissingImplInMemberAccess` diagnostic; R10: its SKIP
line states both), and to optional_compare_generic.carbon a `Differ` generic (`a
!= b`) with one new line, `Differ` over two `Some` values holding the same NaN,
whose EXPECT is `0` (§5). Their texts are the files of the fold commit, not
reproduced here (amended 2026-10-13, implementation review fold: R1-1, R1-5).

The residue ids W-170 (optional_destroys_value, optional_compare_payload), W-171
(optional_bool, optional_nested_pointer), W-174 (optional_pointer_compare,
optional_pointer_niche), W-176 (optional_compare_generic) and W-174, W-176,
W-178 and W-179 (check/testdata/optional/fail_compare.carbon) are written into
program headers and a golden source (amended 2026-10-13, review fold: B-2,
A-10); if §2.6's re-scan re-allocates them, the discharge commit renumbers them
there too, and refills that golden.

### §2.5 Docs (D-OP-14; dated amendments, never rewrites)

-   **docs/design/optional.md (new, normative).** License comment, the
    table-of-contents markers that the markdown-toc hook fills, and the status
    line "Fork design (F-015, <date>): `Core.Optional` as implemented in the
    fork's prelude; toolchain status: OP-1 landed <date>. Upstream has no
    approved design for `Core.Optional` (proposal p006357, future work)."
    Sections: **Overview** (what Optional is for, with README.md:858-860,
    values.md:1126, loops.md:96, error_handling.md D9 and p006357:107-112 as the
    four uses); **The type** (§1.1's first paragraph and table, every
    declaration copied from the landed optional.carbon and diffed against it
    before commit 4, R27; the class kept per D-EH-1 and why, D-OP-7; the storage
    strategy and the null niche with p006357:247-249; `OptionalStorage` private
    and its consequence, W-176); **Comparison** (§1.2's table, the C++ and Rust
    sources of the rules, `Eq`/`Ordered` independence, same-type only with
    comparison_operators.md:288-289 and W-178, the generic example of §1.2 as
    compiled, the pointer niche with W-174 and M-18, `Core.Optional(bool)` with
    W-171, the copy-and-destroy divergence quoting comparison_operators.md:316
    and :434, `final` with p5337 and W-179, and p002188:488-489's `==` on
    `Optional(T).None`) (amended 2026-10-13, review fold: A-1, A-2, A-8, A-9,
    A-10); **Ownership and lifetime** (§1.3, the design rule that an Optional
    destroys its value stated as design and W-170 as the 0.1 limit, with
    p001154:211-227 and classes.md:1992-2003; comparisons copy and never move;
    `Get()` requires `HasValue()`, W-173, and the TY4 contradiction; not
    `Core.Plain`, F-013 D-SAFE-9) (amended 2026-10-13, review fold: A-9, B-3,
    B-5); **Propagation and iteration** (`?` with `BreakType = ()` and no bridge
    to `Result`, linking error_handling.md; `for` over `Iterate.Next`'s
    Optional; W-176's copyable-element consequence); **Pattern matching** (not
    matchable in 0.1, W-177; use `HasValue()`/`Get()` or `?`; the pattern
    matching design's `Optional(T).None` against the `None()` function; SAFE-1's
    EX-M-5 and EX-M-6 named as waiting on W-177, linked by the discharge commit
    if PR 53 is on trunk then) (amended 2026-10-13, review fold: A-9,
    B-5); **C++ interoperability** (§1.5); **0.1 limits** (W-170..W-179 by
    title, each with the condition under which it closes, and ST-1's W-160 by
    reference); **Alternatives considered** (§7 A-1..A-9; §7 A-10 is a decision
    about the milestone row, not about the design, and is not repeated there)
    (amended 2026-10-13, review fold: B-7); **References** (p006357, p001885,
    loops.md, comparison_operators.md, details.md's conditional conformance,
    sum_types.md, error_handling.md, milestones.md:203, p002188, p001154, p5337,
    classes.md's destructors) (amended 2026-10-13, review fold: A-9). Every
    example in it is a program or golden of this plan, or compiled on the landed
    toolchain before commit 4. Its normative sentences are the verbatim block
    below, placed in the sections named; the implementation review of R29(c)
    reviews the page as a design document against them, and its fold is recorded
    in this plan (§3) (amended 2026-10-13, review fold: B-7).

The normative sentences of docs/design/optional.md, verbatim (`<date>` is the
landing date; each group goes in the section its comment names, and the links
the page adds to the documents named are not part of the wording) (amended
2026-10-13, review fold: B-7, A-1, A-2, A-8, A-10, B-3, B-5; the last two
sentences of the pointer and `bool` paragraph amended 2026-10-13, implementation
review fold: R1-1, R1-4):

```markdown
<!-- Status line, under the title -->

**Status:** Fork design (F-015, <date>): `Core.Optional` as implemented in the
fork's prelude, core/prelude/types/optional.carbon; toolchain status: OP-1
landed <date>. Upstream has no approved design for `Core.Optional` (proposal
p006357, future work).

<!-- Comparison -->

`Core.Optional(T)` implements `Core.EqWith(Core.Optional(T))` when `T` is
`Core.Eq`, and `Core.OrderedWith(Core.Optional(T))` when `T` is `Core.Ordered`;
neither requires the other. Two empty values are equal. An empty value and a
non-empty value are not equal. Two non-empty values are equal exactly when their
values are equal under `T`'s `==`, and `!=` on them is `T`'s `!=`. An empty
value orders before every non-empty value, two empty values are equivalent, and
two non-empty values order as their values do under `T`'s `<`, `<=`, `>` and
`>=`. Both operands have the type `Core.Optional(T)`: there is no comparison
with a bare `T`, with `Cpp.nullptr`, or with `Core.Optional(U)` for another `U`.

A pointer-niche `Core.Optional(T*)` compares exactly when `T*` is `Core.Eq`. The
prelude gives the built-in pointer types no `==` (W-174), so
`Core.Optional(i32*)` does not compare; a library that owns a class `C` may
implement `C* as Core.EqWith(C*)`, and `Core.Optional(C*)` then compares.
`Core.Optional(bool)` is `Core.Eq`, but in 0.1 comparing two of them, like
reading or copying one, crashes the compiler (W-171). The same defect makes
reading, copying and comparing a `Core.Optional(Core.Optional(U*))` return wrong
values with no diagnostic (W-171). For a payload that exists only at compile
time, such as `Core.IntLiteral`, comparing two `Core.Optional(T)` values passes
check and then crashes the compiler in lowering, as a checked generic's `==` on
`Core.IntLiteral` does without Optional (W-190).

In 0.1 a comparison of two non-empty values reads each through `Get()`, which
runs `T`'s `Copy` once and its `Destroy` once per value. The comparison
operators design says that `EqWith`'s operations and the members of an
`OrderedWith` implementation "should have no observable side-effects"; for a `T`
whose `Copy` or `Destroy` has an observable effect, so does comparing two
`Core.Optional(T)` values. This is a fork divergence, which a by-reference
accessor or matchability (W-177) removes.

The impls are `final`: when `T` is `Core.Eq`, no other library can change what
`==` means on `Core.Optional(T)`. Proposal p5337 makes a non-final impl that a
`final` impl completely subsumes an error; the 0.1 toolchain reports it only
where the impl would be used, not at its declaration (W-179).

<!-- Ownership and lifetime -->

An `Optional(T)` owns the value it holds: `Some(v)` stores a copy of `v`,
copying an `Optional(T)` copies its value, and destroying a non-empty
`Optional(T)` destroys its value. In 0.1 the last rule is not implemented: a
held value is never destroyed (W-170), so a `T` whose `Destroy` frees or counts
leaks one destruction per held value. The fix must keep `Core.Optional(T*)`
trivially destructible, because a union may have a `Core.Optional(T*)` field.

`Get()` requires `HasValue()`. In 0.1 the requirement is not checked (W-173): on
an empty value `Get()` returns the unformed storage, and for `Core.Optional(T*)`
it returns a null pointer, whose dereference needs no `unsafe`. That contradicts
the safety design's TY4 ("null is never a hole", F-013) until W-173 lands a
checked `Get()` or TY4 is amended.

`Core.Optional(T)` is not `Core.Plain` for any `T` (F-013, D-SAFE-9): its value
sub-object exists only when it holds one, so under Strict Carbon assigning an
`Optional` through a shared path is an invalidating operation.

<!-- Pattern matching -->

`Core.Optional` is a class, not a `choice`, and is not matchable in 0.1: there
are no `.Some` and `.None` patterns and no `match` over it (W-177). The pattern
matching design's `Optional(T).None`, an expression pattern compared using `==`,
names a value; in this design `None` is a function, `Optional(T).None()`.
```

-   **docs/design/control_flow/loops.md**, after the desugaring block that ends
    at :114 (before `### \`break\``, :116), a blockquote: "**Fork amendment
    (<date>, F-015).** In the fork, `Core.Optional`'s API is designed in
    Optional: `HasValue()` and `Get()` above are that API, and the toolchain's
    `for` calls them by name.", with "Optional" a link to `../optional.md`. The
    sentence at :104-105 stays as written.
-   **docs/design/error_handling.md**, after :444 (the end of the paragraph that
    says rebuilding `Core.Optional` as a choice is part of the choice-payloads
    work), a blockquote, with "Optional design" a link to `optional.md`: "**Fork
    amendment (<date>, OP-1, F-015):** W-058 was discharged without rebuilding
    `Core.Optional` as a choice: the fork's Optional design keeps the class
    (D-EH-1), so the `match` body above does not apply in 0.1, the landed `Try`
    impl stays as the amendment above records it, signature and body, and
    `.Some`/`.None` patterns over `Core.Optional` remain future work (W-177).
    EH-A's amendment above cites the class at
    `core/prelude/types/optional.carbon:29`; it is at :30 in the fork." (amended
    2026-10-13, review fold: A-6) The staging bullet at :905-910 is history and
    is not edited.
-   **docs/design/README.md**, in "Pointer types", after :860 ("... use the type
    `Optional(T*)`."), a blockquote, with "Optional" a link to `optional.md`:
    "**Fork amendment (<date>, F-015).** `Core.Optional(T)` is designed in
    Optional. `Optional(T*)` stores the null pointer as its empty value, so it
    has a C++ pointer's ABI; `Optional(T*)` compares exactly when `T*` is
    `Core.Eq`, and the built-in pointer types have no `==` yet (W-174)."
    (amended 2026-10-13, review fold: A-1) No heading is added, so the README's
    table of contents does not change.
-   **SAFE-1's pages, at discharge, only if PR 53 is on trunk then** (amended
    2026-10-13, review fold: B-3, B-5): after
    docs/design/safety/type_safety.md's TY4 paragraph (:181-195 on the safe
    branch at adaae4e35, re-read at the merge of trunk), a blockquote: "**Fork
    amendment (<date>, OP-1, F-015).** In 0.1, `Get()` on an empty
    `Core.Optional(T*)` is unchecked and returns the null pointer, whose
    dereference needs no `unsafe` (fork/optional/plan.md M-9), so TY4 does not
    yet hold on that path; W-173 tracks the checked `Get()` that restores it,
    and a `match` over a `Core.Optional`, which TY4 also names, waits on W-177."
    (amended 2026-10-13, implementation review fold: IR2-8); and after
    docs/design/safety/mutation_safety.md's staging paragraph for EX-M-5 and
    EX-M-6 (:801-803 there), a blockquote: "**Fork amendment (<date>, OP-1,
    F-015).** The fork's Optional design keeps `Core.Optional` a class, so no
    choice-based redesign comes from W-058; the `match` forms of EX-M-5 and
    EX-M-6 wait on W-177." If PR 53 is not on trunk at discharge, the two texts
    go to SAFE-1's merge of trunk through fork/ORCHESTRATION.md (the ST-1
    handling of its SAFE-1 reconciliation). The commit that lands the two
    amendments also links, from docs/design/optional.md, TY4
    (safety/type_safety.md, "TY4: null is never a hole"), D-SAFE-9 and
    `Core.Plain` (safety/mutation_safety.md) and EX-M-5 and EX-M-6, which the
    page names without links until PR 53 is on trunk (amended 2026-10-13,
    implementation review fold: IR2-8).

The amendments and the status line carry the landing date, not this plan's.

### §2.6 Records (commit 5, after verification)

The "(amended 2026-10-13, review fold: ...)" marks inside §2.3 to §2.6,
including those inside quoted row, note and title texts and ledger table cells,
annotate this plan; they are not copied into the records, programs, goldens or
pages (rev 2).

-   **Id re-scan, immediately before the ledger is written:** the maximum `W-`
    id of fork/inventory/work-items.json on trunk and on every local and
    `origin` `claude/carbon-fork-0-1-*` ref, quoted in commit 5's message and
    the landed notes (the planner's scan: trunk and 68 branch refs, maximum
    W-167). W-168 and W-169 stay SC-1's whether or not it used them. If
    re-allocation triggers, the same commit renumbers the ids already written in
    docs/design/optional.md, the README amendment (W-174), error_handling.md's
    amendment (W-177), and the program headers and the golden source §2.4 lists
    (W-170, W-171, W-174, W-176, W-178, W-179) (amended 2026-10-13, review fold:
    B-2, A-10). W-190, the implementation review's residue, is the first id
    after DD-1's reserved W-180..W-189; if it is taken at discharge, it takes
    the maximum plus one, skipping every reserved block, and the same commit
    renumbers it in docs/design/optional.md (amended 2026-10-13, implementation
    review fold: R1-4).
-   **fork/inventory/work-items.json, W-058:** title prefixed "OP-1 (LANDED
    <date>): ", kind `implemented`; evidence:
    core/prelude/types/optional.carbon:13, :27 and :205-275 (the landed lines;
    amended 2026-10-13, review fold: B-9), the three goldens, the seven programs
    and the oracle, docs/design/optional.md; notes: what landed by D-OP number,
    §0.3 items 1 and 2 as corrected, "the `Try` impl :56-78 unchanged (SF-9
    KEEP)", the residues W-170..W-179 by title, and the decision-log citation as
    the heading text without the date, double-quoted: "OP-1 / F-015:
    Core.Optional comparison and design" (the rows-79/82 citation form).
-   **New items W-170..W-179 and W-190** (amended 2026-10-13, review fold:
    A-10; W-190 amended 2026-10-13, implementation review fold: R1-4), each
    `{id, kind, title, subsystem, size, bullet, evidence, blocked_by, notes}`,
    `blocked_by: []` unless stated:

| Id | Kind | Title | Subsystem | Size | Bullet | Evidence (all measured, §0.2) |
| --- | --- | --- | --- | --- | --- | --- |
| W-170 | missing-feature | OP-1 residue: a `Core.Optional` never destroys the value it holds | core/prelude (+ the union field rule) | M | Stdlib: Optional | optional.carbon:140-143, maybe_unformed.carbon:12-15, M-5's probe, M-6's prototype and its 26 goldens with `UnionFieldNotTriviallyCopyable` for `Core.Optional(i32*)`; notes: the destroy must stay trivial for the pointer niche (unions.md:233-239, p006357:247-249); row-bounding (D-OP-13); arbiter `programs/stdlib/optional_destroys_value.carbon` (SKIP, M-20); design inputs classes.md:1992-2003 (a class that defines a destructor with a non-empty body is not `TrivialDestructor`, :1995-1996; corrected 2026-10-13, implementation review fold: R1-7) and p001154:211-227 (the considered conditional `TrivialDestructor` `Optional` sketch) (amended 2026-10-13, review fold: B-2, A-9); consequences measured by the implementation review: in a checked generic `[T: Core.Eq & Core.Copy & Core.Destroy]`, `Core.Optional(T).Some(a).HasValue()`, `Mk(a) == b` with `Mk` returning `Core.Optional(T)`, and `let o: Core.Optional(T) = ...; o == b` each fail with "cannot access member of interface `Core.Destroy` in type `Core.Optional(T as Core.OptionalStorage)` that does not implement that interface" (trunk too), so generic code compares only Optionals it receives; `o1 == o2` on two `Core.Optional(Core.Optional(P))` values holding P1 and P2 prints `101 102 101 102 202 201 0`, four `P` copies and two destroys, leaking one `P` per operand; on M-6's prototype the three generic forms check and the trace balances (`101 102 101 102 202 201 202 201 0`) (amended 2026-10-13, implementation review fold: R1-2) |
| W-171 | toolchain-defect | OP-1 residue: `Core.Optional`'s default storage mis-lowers `MaybeUnformed(T) unsafe as T` when `T`'s value representation differs: `Get()` and copy crash the compiler for `bool` and silently return the storage address for `Core.Optional(U*)` | toolchain/check (convert.cpp) + toolchain/lower | M | Stdlib: Optional | M-7's three reproducers and messages, check/convert.cpp:1687-1704 (the CHECK at :1698), upstream-trunk 62f1cc6a3 convert.cpp:1559-1562, nightly 2026.10.12; notes: with OP-1 `==` on `Optional(bool)` reaches the same crash, where trunk and upstream give a check error (M-20); row-bounding; arbiter `programs/stdlib/optional_bool.carbon` (SKIP, M-20); SC-1 moves the CHECK to convert.cpp:1712, re-read at the merge of trunk (amended 2026-10-13, review fold: A-8, B-2, B-8); the root cause, optional.carbon:169-171 and :172-178: for `tt: Core.Optional(Core.Optional(i32*))` the unoptimized IR of `*tt.Get().Get()` has the storage `Get` pass `getelementptr inbounds nuw <{ ptr, i1 }>, ptr %value, i32 0, i32 0` to the inner `Optional(i32*)` `Copy`, which is `ret ptr %self`, with no load; reproducers (review 1, re-run by the fold): `Some(None).Get().HasValue()` and the same through a copy print 1 on trunk and OP-1, `*tt.Get().Get()` prints an address, not 7, and with OP-1 `Some(Some(&c1)) == Some(Some(&c2))` with equal pointees prints 0, concrete and through a generic, where trunk gives `MissingImplInMemberAccess`; second arbiter `programs/stdlib/optional_nested_pointer.carbon` (SKIP) (amended 2026-10-13, implementation review fold: R1-1) |
| W-172 | toolchain-defect | OP-1 residue (found while measuring): a float or character literal argument for a `T: Core.Copy & Core.Destroy` parameter aborts check in `CanDestroyType` | toolchain/check (custom_witness.cpp) | S | Generics: generic functions and types | M-8's `Core.Optional(f64).Some(2.5)`, `Core.Optional(char).Some('a')` and `Box(f64).Make(2.5)`, check/custom_witness.cpp:487, nightly :401 |
| W-173 | missing-feature | OP-1 residue: `Core.Optional(T).Get()` on an empty value is unchecked | core/prelude | S | Stdlib: Optional | optional.carbon:40-42, :169-171, :200-202; M-9; notes: a fail-stop like D-SL-4 refills every lower golden that instantiates `Get`; for `Core.Optional(T*)` the null returned is dereferenced with no `unsafe`, M-9 being a counterexample to F-013's TY4 (docs/design/safety/type_safety.md:179-195 and :342 on the safe branch), related to SAFE-1's W-146 and SP4's checked-access model with an `unsafe` opt-out (spatial_safety.md:206); a DONE gate of D-OP-13 while TY4 stands as written (amended 2026-10-13, review fold: B-3) |
| W-174 | design-needed | OP-1 residue: the prelude gives built-in pointer types no `==`, so `Core.Optional(T*)` compares only when `T*` is `Core.Eq` (never for a built-in pointer) | core/prelude + sem_ir builtins | S | Stdlib: pointer types | M-10, comparison_operators.md:479-505, values.md:1119-1131, nullptr.carbon:48, sem_ir/builtin_function_kind.def:150-154, programs/stdlib/optional_pointer_compare.carbon (SKIP); notes: address identity is the expected rule, with p006357's cross-object caveat (:76-85); a user library already makes `Optional(C*)` compare with its own `impl C* as EqWith(C*)` (M-18), and a `final` prelude pointer `EqWith`, which must live in comparison.carbon, would make every such impl "`impl` will never be used" and change `==` on `Optional(C*)` to the prelude's rule (M-18), so the design must decide `final` against non-final and state what happens to user pointer impls; the arbiter does not bound the Optional row (amended 2026-10-13, review fold: A-1) |
| W-175 | missing-feature | OP-1 residue: no explicit `as` between Optionals (`Optional(T) as As(Optional(U))` for `T: As(U)`) | core/prelude | S | Stdlib: Optional | README.md:3260-3261, details.md:4655-4665, M-10 |
| W-176 | missing-feature | OP-1 residue: `Core.Optional(T)` requires `T: Copy & Destroy` (or a pointer) through the private `OptionalStorage` | core/prelude | M | Stdlib: Optional | optional.carbon:16-26, :30, :148; details.md:6988-7015; iterate.carbon:13-14; M-10's `fail_generic_without_copy` |
| W-177 | missing-feature | OP-1 residue: `Core.Optional` is not matchable (no `.Some`/`.None` patterns, `match` or `if let`) | toolchain/check + core/prelude | L | Control flow: matching — sum-type consumption incl. std::variant/std::optional interop | sum_types.md:63-75, :154-184, pattern_matching.md:501-527, error_handling.md:392-405, :432-433, D-EH-1; notes: related W-011; the `Try` signature and the pointer ABI are constraints; SAFE-1's EX-M-5 and EX-M-6 (mutation_safety.md:664-683, :724-725, :801-803 on the safe branch) wait on this item, not on a choice-based redesign from W-058 (amended 2026-10-13, review fold: B-5) |
| W-178 | missing-feature | OP-1 residue: the `like` operator is not parsed, so no comparison admits implicit operand conversions | toolchain/parse + toolchain/check | M | Generics: Checked generics | toolchain/lex/token_kind.def:214, details.md:6598, comparison_operators.md:289-300, M-10 |
| W-179 | toolchain-defect | OP-1 residue (found by review): a non-final impl that a `final` impl completely subsumes is diagnosed only where it is used, not at its declaration as p5337 specifies | toolchain/check (impl lookup and impl declaration checks) | S | Generics: Checked generics | proposals/p005337-interface-extension-and-final-impl-update.md:280-286; M-11 (the declaration alone compiles); check/testdata/optional/fail_compare.carbon splits `fail_specialize` (the use-site `ImplFinalOverlapsNonFinal`) and `todo_fail_specialize_unused` (compiles); notes: rename the split to `fail_specialize_unused` when the declaration is diagnosed (amended 2026-10-13, review fold: A-10) |
| W-190 | toolchain-defect | OP-1 residue (found by the implementation review): a checked generic body that applies a compile-time-only operation to a symbolic `T` (`Core.IntLiteral`'s `==`) aborts lowering instead of being evaluated or diagnosed | toolchain/lower (+ toolchain/check) | S | Generics: generic functions and types | review 1's lit.carbon (`a == b` on two `Core.Optional(Core.IntLiteral)` parameters: with OP-1 `--phase=check` exits 0 and `carbon compile` aborts, exit 134, at "Lowering function Equal(Core.IntLiteral as Core.OptionalStorage & Core.Destroy & Core.Eq)", optional.carbon:217, the call at :224, with "llvm::cast ... [To = llvm::IntegerType, From = llvm::Type]: Assertion ... failed"; trunk: `MissingImplInMemberAccess`) and genlit.carbon (`fn Eq2[T: Core.Eq](a: T, b: T) -> bool { return a == b; }` with `Eq2(1, 2)` aborts the same way on trunk, "Lowering function Eq2(Core.IntLiteral as Core.Eq)"); notes: no ledger item on any ref names it (a grep for "compile-time-only" finds none); the id is the first after DD-1's W-180..W-189, re-scanned at discharge (amended 2026-10-13, implementation review fold: R1-4) |

-   **The ledger's `source` field** gains the dated sentence every discharge
    appends ("Updated <date> by the OP-1 discharge: W-058 DISCHARGED ...;
    W-170..W-179 added ...; the re-scan's maximum and ref count").
-   **W-011's notes** gain: "OP-1 (<date>): W-058 was discharged keeping
    `Core.Optional` a class (F-015, D-EH-1); matchability is W-177; a
    `std::optional` mapping (this item's open half) amends F-015 first if it
    targets `Core.Optional`."
-   **W-049's notes** gain (amended 2026-10-13, implementation review fold:
    R1-3): "OP-1 (<date>): comparing two `Core.Optional(T)` values for an
    imported C++ class `T` that is `Core.Eq` (a header struct with `operator==`)
    fails to check with 'semantics TODO: `interop with non-identifier package
    name`' at core/prelude/types/optional.carbon:30:1, raised at
    toolchain/check/cpp/export.cpp:141 (the keyword package name `Core`), on
    trunk too; `Core.Optional(Cpp.S)` construction and `HasValue()` work, and
    Optionals of Carbon payloads compare in a file that imports C++
    (fork/optional/plan.md, implementation review fold, R1-3)."
-   **W-006's notes** gain: "Risk 9 resolved at OP-1 (F-015, <date>): Optional's
    design landed outside W5, not folded into its deliverables, with the class
    kept per D-EH-1; matchability is W-177 and the `std::optional` mapping
    W-011, which carry the W5 coupling; the ownership rule is in
    docs/design/optional.md with W-170 as the 0.1 limit; decision log "OP-1 /
    F-015: Core.Optional comparison and design"." **W-010's notes** gain: "OP-1
    (<date>): Optional's redesign was not folded into W5 (F-015 keeps the class,
    D-EH-1); a choice `Optional` would be W-177's." (amended 2026-10-13, review
    fold: A-7, B-6)
-   **fork/gap-analysis.md, row 78** (re-read its line at the merge of trunk; it
    is `| Stdlib: Optional |`) stays PARTIAL with this text: "PARTIAL | OP-1
    landed (W-058 DISCHARGED <date>, fork/optional/plan.md, decision-log "OP-1 /
    F-015: Core.Optional comparison and design"): `Core.Optional(T)` has a
    decided fork design, docs/design/optional.md (F-015: the class kept per
    D-EH-1, its storage with the C++-pointer null niche,
    `None`/`Some`/`HasValue`/`Get`, the conversions, `Copy` and `Try`), and
    compares when `T` does: `final impl forall [T: Destroy & OptionalStorage &
    Eq] Optional(T) as EqWith(Optional(T))` and its `Ordered` twin
    (core/prelude/types/optional.carbon), with `std::optional`'s rules (two
    empty values are equal, an empty value orders before every value, two values
    compare as `T` does). Still PARTIAL: an Optional never destroys the value it
    holds (W-170), and `Core.Optional(bool)`'s `Get()` and copy crash the
    compiler on trunk and upstream (W-171), whose root cause also makes `Get()`
    and copy of `Core.Optional(Core.Optional(U*))` return wrong values with no
    diagnostic; since OP-1, `==` on `Core.Optional(bool)` reaches the same
    crash, and `==` on `Core.Optional(Core.Optional(U*))` the same wrong values,
    where each was a check error (amended 2026-10-13, review fold: A-8; amended
    2026-10-13, implementation review fold: R1-1); DONE needs
    optional_destroys_value, optional_bool and optional_nested_pointer to PASS
    in a run of record and F-013's TY4 to hold for `Get()` (amended 2026-10-13,
    review fold: B-2, B-3). Other 0.1 limits, each filed: `Get()` on an empty
    value is unchecked, which for `Core.Optional(T*)` falsifies F-013's TY4
    (W-173); `Optional(T*)` compares only when `T*` is `Core.Eq`, and built-in
    pointers have no `==` (W-174) (amended 2026-10-13, review fold: A-1); no
    explicit `as` between Optionals (W-175); `T` must be `Core.Copy &
    Core.Destroy` or a pointer (W-176); not matchable (W-177); a float or
    character literal passed to `Some` aborts check (W-172); a user
    specialization that the `final` impls subsume is diagnosed only where it is
    used (W-179); `==` on `Core.Optional(Core.IntLiteral)` passes check and
    aborts lowering (W-190) (amended 2026-10-13, implementation review fold:
    R1-4). Conformance: 6 of 10 programs PASS (stdlib/optional_basic,
    optional_pointer_niche, optional_missing_ops SKIP -> PASS,
    optional_compare_diff with a C++17 std::optional oracle over every case of
    the six operators, optional_compare_generic, optional_compare_payload) and
    four are write-tests-first SKIPs: optional_destroys_value (W-170),
    optional_bool and optional_nested_pointer (W-171), the arbiters of this row
    (amended 2026-10-13, implementation review fold: R1-1), and
    optional_pointer_compare (W-174), which does not bound it (amended
    2026-10-13, review fold: B-2) — EXPECTED, not of record: container run
    <date> on the carbonbuild toolchain of <sha> (scoreboard generated
    <timestamp>), <P>/0/<S> over <N>; floor of record
    <the base's totals and run> (re-read at the merge of trunk; today 128/0/22,
    run 37402970811); the hosted run R9 requires is pending with no dispatch
    date (Actions disabled)." The run is cited by toolchain sha, `generated`
    timestamp and totals, never by an output directory (ST-1's RV1-5).
-   **Header:** the counts do not change (row 78 stays PARTIAL); the scoreboard
    sentence is rewritten in CM-1's words with the new expected totals, applied
    to whatever the header reads at the merge of trunk.
-   **§W9:** in the paragraph (:232-239) "a designed (non-placeholder) Optional
    remain" (or, if ST-1 has landed, its replacement "a designed
    (non-placeholder) Optional remains") becomes "the Optional design (F-015)
    and its comparisons landed at OP-1 (W-058 DISCHARGED <date>); the Optional's
    destruction of its value (W-170) and the default storage's defect for
    `Core.Optional(bool)` and nested pointer-niche Optionals (W-171) remain"
    (amended 2026-10-13, implementation review fold: R1-1);
    the "Depends on" line (:226-230) names, for the Optional half, only W-177
    (sum types, for matchability) and W-011 (std::optional interop) (§0.3
    item 8).
-   **Row 68** ("Control flow: matching — sum-type consumption incl.
    std::variant/std::optional interop", PARTIAL) gains one clause before its
    closing parenthesis: "; `Core.Optional` itself is not matchable (W-177,
    F-015)". Rows 51, 52 and 75 are not changed: W-172 (row 51), W-178 and W-179
    (row 52) and W-174 (row 75) are ledger items only (amended 2026-10-13,
    review fold: A-10), because their rows' text makes no claim they falsify
    (the ST-1 handling of W-164 and W-165).
-   **fork/decision-log.md:** a new entry immediately above the newest landed
    entry, which follows "### Full autonomy and the throughput protocol
    (2026-09-27)" (:2843-2862 on trunk; :2863 is SL-2's entry today, and each of
    PRs 52, 53, 54 and 55 inserts its entry at :2863, so the anchor is whichever
    entry is first there at the merge of trunk). Heading: "### OP-1 / F-015:
    Core.Optional comparison and design (<date>)". Content in SL-1's shape
    (:3747): the bullet's status (PARTIAL kept, bounded by W-170/W-171, and why
    the row-82/row-77 precedents do not apply), the commits, WHAT LANDED by
    mechanism, DECISIONS (D-OP-1..15 with break conditions), the residues,
    coherence risk 9 of W-006 closed by D-OP-7 (amended 2026-10-13, review fold:
    A-7, B-6), the not-of-record conformance totals, the review record, and
    "_V-3a divergence-risk register entries_": optional.carbon:13 and :27
    replace upstream lines (the bool import, a blank line) and the appended
    block is fork-only (on an upstream edit of optional.carbon, keep both and
    re-run M-12); `final` on the comparison impls is fork policy (upstream has
    no comparison); F-015 itself is a fork design for a type upstream has not
    designed; the comparisons run `T.Copy` and `T.Destroy` once per value when
    both operands hold one, against comparison_operators.md:316 and :434 (closed
    when W-177 or a by-reference accessor lands, D-OP-4); `None()` is a function
    where p002188:488-489 and pattern_matching.md:527-528 spell
    `Optional(T).None` as a value; and F-015 states that `Get()` on an empty
    `Optional(T*)` falsifies F-013's TY4 until W-173 lands (amended 2026-10-13,
    review fold: A-2, A-9, B-3).
-   **The trunk non-vacuity counts** that commit 5's message, the decision-log
    entry and the PR body quote are the implementation review's re-measurement
    on the trunk install (`--phase=check`), which corrects commit 4's message
    (a8daacf11: "1, 6, 6 and 3 MissingImplInMemberAccess errors", which no
    amend may change): optional_missing_ops 1; optional_compare_diff 6;
    optional_compare_generic 4 (3 `EqWith`, 1 `OrderedWith`) and 2 "cannot
    convert type `Core.Optional(i32 as Core.OptionalStorage)`" at commit 4, and
    5 (4 `EqWith`, 1 `OrderedWith`) and the same 2 after the fold's `Differ`
    line; optional_compare_payload 3; optional_nested_pointer's `==` 1; the
    quoted counts are re-read from §8.8's run on the merge commit
    (amended 2026-10-13, implementation review fold: R1-6, IR2-10).
-   **fork/ORCHESTRATION.md:** the Branches row for `claude/carbon-fork-0-1-op`
    (trunk 162c7e839's :429, "PLANNING", edited in place), the "Last updated" or
    "Later on" stamp paragraph (the PR, the verification record, the not-run
    list), the Scoreboard subsection, the reservation sentence of trunk
    162c7e839 (:87-89, "ids from W-170 and fork design id F-015 if minted") made
    exact ("uses W-170..W-179 and W-190, minted F-015") (amended 2026-10-13,
    review fold: A-10; W-190 amended 2026-10-13, implementation review fold:
    R1-4), and a dated correction of "Next actions" item 3 (§0.3 item 9). Before
    commit 5, the then-current trunk is merged into the branch with a merge
    commit, never a rebase (AGENTS.md; the EV-1 precedent dff212ccc), so commit
    5 edits trunk's records in place, and §8.8 re-verifies that merge commit
    before commit 5 is written (amended 2026-10-13, review fold: B-4). When that
    merge is taken is §3's timing rule (amended 2026-10-13, implementation
    review fold: IR2-12).
-   **Landing-date stamps** to re-stamp in a new commit if the merge date
    differs: optional.md's status line, the amendment lines, W-058's title, row
    78's "DISCHARGED <date>", the §W9 sentence and the decision-log heading;
    optional.carbon:27 keeps commit 2's date (§2.1), because a records commit
    never changes core/ source (amended 2026-10-13, review fold: B-9).

## §3 Commit structure (one PR, "OP-1: Core.Optional comparison and the fork design F-015", R29(b))

1.  **Plan.** Rev 1 (this commit, "OP-1 plan (rev 1): Core.Optional comparison
    and design"); later revisions fold the two plan reviews of R29(c), each
    amended sentence marked "(amended <date>, review fold: <finding>)", each
    revision a new commit. Rev 2 ("OP-1 plan (rev 2): reviews A and B folded, 19
    findings") is that fold.
2.  **Prelude, CHECK-free goldens.** core/prelude/types/optional.carbon (§2.1)
    and the three golden sources of §2.3 with `// AUTOUPDATE` and no CHECK
    lines. Expected gate on this commit alone: red on exactly the three empty
    goldens, nothing else, no abort (M-12: no existing golden changes).
3.  **Fill.** Only the output of `autoupdate.sh` run to its fixpoint before the
    commit is made (R26): the three goldens, each converging on its second run
    (the first fills it, the second prints `.`, M-15); a run after the first
    that changes more than `.loc` numbers is a stop. Message "Autoupdate
    testdata goldens on the container arbiter" (the UA-2 and ST-1 precedent).
4.  **Conformance and docs.** The seven program files and the oracle of §2.4
    (optional_missing_ops un-SKIPped, three new PASS programs, three new SKIPs)
    (amended 2026-10-13, review fold: B-2), the two refreshed headers, the
    regenerated README table, docs/design/optional.md and the three amendments
    of §2.5 that do not wait on the merge of trunk (loops.md, error_handling.md,
    README.md).
5.  **Discharge.** The records of §2.6, and SAFE-1's two amendments of §2.5 if
    PR 53 is on trunk then, written after §8's runs, the merge of trunk and
    §8.8's re-verification of the merge commit, so every count is quoted from a
    run on the tree that lands (R9) (amended 2026-10-13, review fold: B-4, B-3,
    B-5).

**Between commits 4 and 5**, in this order (amended 2026-10-13, review fold:
B-4, B-9): the implementation review of R29(c), whose reviewers also review
docs/design/optional.md as a design document against §2.5's verbatim sentences
(B-7); its fold by a separate fixer (R11) in new commits ("OP-1 fixes: fold the
implementation review", the ST-1 precedent) with an "Implementation review fold
record" in this plan, any refill being its own "Autoupdate testdata goldens on
the container arbiter" commit; then the merge of trunk, a merge commit and never
a rebase; then §8.8 on the merge commit; then commit 5.

**Timing of the merge of trunk** (amended 2026-10-13, implementation review
fold: IR2-12): the merge that precedes commit 5 is taken when OP-1 is next in
D-OP-15's land queue, that is, once PR 53, PR 51, PR 52, SC-1, PR 54 and PR 55
have merged, or once the orchestrator re-orders the queue under D-OP-15's break
condition. Commit 5 then anchors its records on the trunk that OP-1 lands on, PR
53's two SAFE-1 amendments go into commit 5 directly, and §8.8 runs once. Until
then the branch holds commits 2 to 4 and the fold, and the PR may be opened
before commit 5 exists; if a merge of trunk is taken earlier, for example to
resolve a conflict, §8.8 runs on it too, and commit 5 is still written only
after the last merge of trunk before landing; a merge of trunk after commit 5
re-runs §8.8, re-anchors commit 5's records and re-stamps the landing dates,
each in a new commit.

Before each of commits 2, 4 and 5 and each fix commit, `uvx prek run --files
<that commit's files>` runs to a fixpoint (a run that changes nothing), with
R31's heading and list-item counts recorded before and after for every `.md` in
the commit; before the branch is handed to the orchestrator, `uvx prek
run --all-files` runs to a fixpoint as well (R25, §8.10; amended 2026-10-13,
review fold: B-9). Every commit uses explicit paths (R20), the author `jmann345
<jerrymannstan@gmail.com>`, the committer `Claude <noreply@anthropic.com>` and
the session's attribution trailers. A problem found after a commit exists is
fixed by a new commit, never by amending one (AGENTS.md; R29 forbids asking).

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

"Measured" means the line was produced by the trunk file_test with §2.1 in the
scratch mirror of M-15, from the §2.3 sources; at the real paths only the TIP
lines, `ModuleID`, `source_filename` and `DIFile` names (`compare.carbon`, not
the substitute's basename) and the split-file names differ.

| Golden | Split or function | Key lines | Basis |
| --- | --- | --- | --- |
| check/testdata/optional/compare.carbon | `concrete.carbon` | `@IsEq`: `%impl.elem0: %.7b3 = impl_witness_access constants.%EqWith.impl_witness.ce3, element0 [concrete = constants.%Optional.as.EqWith.impl.Equal.5ca]` and `%Optional.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc5_74.2(%a.ref, %b.ref)`; `@IsNe`: element1, `%Optional.as.EqWith.impl.NotEqual.call`; `@IsLt`: `constants.%OrderedWith.impl_witness.064, element0 [concrete = constants.%Optional.as.OrderedWith.impl.Less.3f4]`; `@IsLe`: `constants.%OrderedWith.impl_witness.064, element1 [concrete = constants.%Optional.as.OrderedWith.impl.LessOrEquivalent.1c1]` and `%Optional.as.OrderedWith.impl.LessOrEquivalent.call: init bool = call %bound_method.loc8_74.2(%a.ref, %b.ref)`; `@IsGt`: element2 `[concrete = constants.%Optional.as.OrderedWith.impl.Greater.229]` and `%Optional.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc9_74.2(%a.ref, %b.ref)`; `@IsGe`: element3, `%Optional.as.OrderedWith.impl.GreaterOrEquivalent.call` (amended 2026-10-13, review fold: A-3, B-1) | measured |
| same | `generic.carbon` | `generic fn @Same(%T.loc5_10.2: %facet_type.a1aaf9.1)` with `%EqWith.lookup_impl_witness: <witness> = lookup_impl_witness %T.loc5_10.1, @EqWith, @EqWith(%T.as_type.loc5_66.1) [symbolic ...]`, the symbolic `impl_witness_access constants.%EqWith.impl_witness.1e9, element0 [symbolic = %Optional.as.EqWith.impl.Equal ...]` and `%Optional.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc7_12.2(%a.ref, %b.ref)`; `@UseSame`: `%Same.call: init bool = call %Same.specific_fn(%a.ref.loc10_57, %a.ref.loc10_60)`; 1435 lines, 1345 CHECK (amended 2026-10-13, review fold: A-1, A-3) | measured |
| same | `ordered_only.carbon` | `@RankLess`: `constants.%OrderedWith.impl_witness.74a, element0 [concrete = constants.%Optional.as.OrderedWith.impl.Less.d49]` and `%Optional.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc22_12.2(%a.ref, %b.ref)`: an ordered-only payload orders (D-OP-2) | measured |
| same | `user_pointer.carbon` | `@SameC`: `impl_witness_access constants.%EqWith.impl_witness.c89, element0 [concrete = constants.%Optional.as.EqWith.impl.Equal.e8b]` and `%Optional.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc17_12.2(%a.ref, %b.ref)`, over `%facet_value: %facet_type.a0b = facet_value %ptr.6b6, (%EqWith.impl_witness.8c5, %OptionalStorage.impl_witness.2e9, %custom_witness.f8f)` with `%EqWith.impl_witness.8c5: <witness> = impl_witness @ptr.as.EqWith.impl.%EqWith.impl_witness_table` (the user's impl) and `%OptionalStorage.impl_witness.2e9: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%C)` (the null niche): the pointer niche compares when `T*` is `Core.Eq` (M-18) (amended 2026-10-13, review fold: A-1) | measured |
| check/testdata/optional/fail_compare.carbon | `fail_not_eq` | `` error: cannot access member of interface `Core.EqWith(Core.Optional(NoEq as Core.OptionalStorage))` in type `Core.Optional(NoEq as Core.OptionalStorage)` that does not implement that interface [MissingImplInMemberAccess] `` at column 10 | measured |
| same | `fail_pointer` | the same diagnostic for `Core.Optional(i32* as Core.OptionalStorage)` (W-174) | measured |
| same | `fail_value_operand` | `` ... `Core.EqWith(i32)` in type `Core.Optional(i32 as Core.OptionalStorage)` ... [MissingImplInMemberAccess] `` (D-OP-5) | measured |
| same | `fail_different_payloads` | `` ... `Core.EqWith(Core.Optional(i64 as Core.OptionalStorage))` in type `Core.Optional(i32 as Core.OptionalStorage)` ... `` (D-OP-5) | measured |
| same | `fail_generic_without_copy` | twice, at columns 21 and 42: `` error: cannot convert type `T` that implements `Core.Eq` into type implementing `Core.OptionalStorage` [ConversionFailureFacetToFacet] `` with `` {{.*}}/prelude/types/optional.carbon:30:16: note: initializing generic parameter `T` declared here [InitializingGenericParam] `` (W-176) | measured |
| same | `fail_specialize` | `` error: `impl` will never be used [ImplFinalOverlapsNonFinal] `` at column 1 of the user's impl, with `` {{.*}}/prelude/types/optional.carbon:215:1: note: `final impl` declared here would always be used instead [ImplFinalOverlapsNonFinalNote] `` (D-OP-3) | measured |
| same | `todo_fail_specialize_unused` | no diagnostic: the subsumed specialization compiles as a declaration (W-179; p5337:280-286 makes it an error); 157 lines, 37 CHECK (amended 2026-10-13, review fold: A-10) | measured |
| lower/testdata/optional/compare.carbon | `IsEq`, `IsNe`, `IsLt`, `IsLe`, `IsGt`, `IsGe` | `define i1 @_CIsEq.Main(ptr %a, ptr %b)` calling `@"_CEqual.Optional.1dac4564233fecd1.Core:EqWith.2e6a6153069d9679.Core.103ec1eaa94142c9"(ptr %a, ptr %b)`; that `define linkonce_odr i1` body calls `@_CHasValue.Optional.Core.3530343734a6ea27` on `%self` and `%other` and branches before it calls `@_CGet.Optional.Core.3530343734a6ea27` twice (into `%temp` and `%temp1`, each after `llvm.lifetime.start`), then `@"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %temp1)` and `(ptr %temp)` before it returns (D-OP-4); `Less` and `GreaterOrEquivalent` test `%other` first and `LessOrEquivalent` and `Greater` test `%self` first (D-OP-2); debug info places `Equal`, `NotEqual`, `Less`, `LessOrEquivalent`, `Greater` and `GreaterOrEquivalent` at optional.carbon lines 217, 226, 239, 248, 257 and 266, and `HasValue`, `Get`, the storage's `Has` and `Get` at 37, 40, 166 and 169 (unmoved, D-OP-8); 488 lines, 465 CHECK (amended 2026-10-13, review fold: B-1) | measured |

Falsifiers: any crash; any golden outside this table in the fill's diff; a
`fail_` split that compiles; any key line above that the fill does not
reproduce; a lower body that calls `Get` on a path that has not tested
`HasValue`.

## §5 Conformance: one SKIP → PASS, six new; delta PASS +4, SKIP +2, programs +6

On the floor of record (fork/conformance/out/scoreboard.json at 9d3ca60a3,
generated 2026-10-06T02:26:01, run 37402970811: 128 PASS / 0 FAIL / 22 SKIP over
150, bullets 48/56) the expected result is **132 PASS / 0 FAIL / 24 SKIP over
156, bullets 48/56** (measured, M-16): optional_missing_ops SKIP → PASS,
optional_compare_diff, optional_compare_generic and optional_compare_payload new
PASS, and optional_destroys_value, optional_bool and optional_pointer_compare
new SKIPs (amended 2026-10-13, review fold: B-2). The Optional bullet's rollup
was already PASS (two PASS programs beside one SKIP) and stays PASS, so the
bullet count does not move. Other PRs land first (UA-2's +3 PASS −3 SKIP,
ST-1's +5 PASS −1 SKIP, SC-1's and EV-1's programs), so the absolute numbers are
re-quoted from the run on the merge commit (§8.8), never added by hand (R9);
only the delta relative to trunk is this plan's claim.

After the implementation review's fold the expected result is **132 PASS / 0
FAIL / 25 SKIP over 157, bullets 48/56**: optional_nested_pointer is one more
write-tests-first SKIP, and optional_compare_generic stays PASS with six lines;
the delta on the floor is PASS +4, SKIP +3, programs +7, and the Optional bullet
rolls up as PASS over ten programs (amended 2026-10-13, implementation review
fold: R1-1, R1-5).

EXPECT derivations (R16(d): from the design rules of §1.2 and independent
reasoning; each was written down before its program first ran):

-   **optional_missing_ops** (EXPECT unchanged): `a` and `b` both hold 1; both
    non-empty, so D-OP-1 gives `1 == 1`, true, and the `if` yields 1. Exit 0.
-   **optional_compare_diff**: no EXPECT-STDOUT; the C++17 oracle defines the
    bytes (the arith_widths_diff precedent). Predicted for review, from §1.2's
    table, as six lines per `Row` in the order `==`, `!=`, `<`, `<=`, `>`, `>=`
    (`Make(n)` is empty for a negative `n`): both empty, `1 0 0 1 0 1`; only the
    left empty (right 0), `0 1 1 1 0 0`, an empty value ordering before 0; only
    the right empty, `0 1 0 0 1 1`; 0 against 1, `0 1 1 1 0 0`; 1 against 1, `1
    0 0 1 0 1`; 1 against 0, `0 1 0 0 1 1`. Thirty-six lines, exit 0; measured
    byte-identical on both sides, and together they run all 18 branches of the
    six bodies (amended 2026-10-13, review fold: A-3, B-1).
-   **optional_compare_generic**: `Count(seven, seven, none, seven)`:
    `seven == seven` twice, `none == seven` false, so 2.
    `Count(some_p, some_q, no_point, some_p)`: `q` differs from `p` in `y`,
    empty differs from a value, `some_p` equals itself, so 1. `Count(some_none,
    some_none, outer_none, some_seven)`: `Some(None) == Some(None)` (inner
    values both empty, equal), `None == Some(None)` false (one side empty),
    `Some(Some(7)) == Some(None)` false (inner values differ in emptiness),
    so 1. `Before(seven, none)`: a value is not before empty, 0.
    `Before(outer_none, some_none)`: empty before a value, 1. Exit 0.
-   **optional_compare_payload**: two `Some` calls each store one copy, so
    `live` is 2; `Some(1) == Some(2)` 0 and `Some(1) < Some(2)` 1 (D-OP-1/2);
    `n == a` 0 (one side empty); `live` 2 (each comparison's copies are
    destroyed by the end of its call, D-OP-4); `a.Get().v` 1 and `b.Get().v` 2
    (the held values unchanged); `live` 2 (each `Get()` copy dies with its
    expression statement). Exit 0. Under W-170's fix the program is unchanged:
    every count is printed before any Optional is destroyed.
-   **optional_pointer_compare** (SKIP; for the un-SKIP, with W-174's address
    equality): two `Some(&n)` are equal, 1; `Some(&n)` and `Some(&m)` hold
    different addresses, 0 (although `n == m`); two empty values, 1; empty
    against `Some(&n)`, 0.
-   **optional_destroys_value** (SKIP; for the un-SKIP, from F-015's ownership
    rule): in `HoldOne`, `Make` builds `t` (1) and `Some(t)` stores a copy (2),
    printed while both live; at return `t` and `o` are destroyed and `o`
    destroys its value, so its counter is 0. In `HoldNone`, `t` (1) and an empty
    `o`, printed 1; at return only `t` is destroyed, 0. In `HoldCopy`, `t` (1),
    `Some(t)` (2) and `p = o`, which copies the held value (3), printed 3; at
    return `t`, `o` and `p` are destroyed with their values, 0. Exit 0. Measured
    today: `2 1 1 0 3 2`, one leaked value per non-empty Optional (M-20)
    (amended 2026-10-13, review fold: B-2).
-   **optional_bool** (SKIP; for the un-SKIP, from F-015's API and comparison
    rules): `Some(true)` holds a value, 1, and reads back `true`, 1;
    `Some(false)` reads back `false`, 0; a copy of `Some(true)` reads back
    `true`, 1; `None()` holds none, 0; `Some(true) == Some(true)`, both holding
    `true`, 1; `Some(true) == Some(false)`, the values differ, 0. Exit 0
    (amended 2026-10-13, review fold: B-2).
-   **optional_nested_pointer** (SKIP; for the un-SKIP, from F-015's API, copy
    and comparison rules): `Some(None)` holds a value, 1; its value is empty,
    0; a copy of it holds the same empty inner value, 0; reading through both
    levels of `Some(Some(&n))` reaches `n`, which holds 7, so the test prints
    1; `a == b` on two outer values whose inner values hold pointers to two
    `C` objects with equal `v` is `C*`'s own `==` on those pointers, which
    compares the objects, 1; exit 0; measured today, with OP-1, `1 1 1 0 0`
    (amended 2026-10-13, implementation review fold: R1-1).
-   **optional_compare_generic's NaN line**: `Differ(some_nan, some_nan)` on
    two non-empty values is `f64`'s `!=` on the two NaNs (D-OP-1: "`!=` on
    them is `T`'s `!=`"), and a NaN compares neither equal nor not-equal
    (comparison_operators.md:311-314), so `!=` is false, 0
    (amended 2026-10-13, implementation review fold: R1-5).

Non-vacuity (M-16): on the trunk install, optional_missing_ops,
optional_compare_diff, optional_compare_generic and optional_compare_payload are
COMPILE-FAIL. Under mutants A and B of M-19, rev 2's optional_compare_diff is
DIFF-MISMATCH, where rev 1's passed both (amended 2026-10-13, review fold: A-3,
B-1). What the PASS programs do not observe: that a held value is destroyed
(W-170) and `Optional(bool)` (W-171); the SKIPped arbiters
optional_destroys_value and optional_bool observe exactly these, so the landing
of either item is visible on the scoreboard (amended 2026-10-13, review fold:
B-2); optional_nested_pointer observes W-171's silent case (amended 2026-10-13,
implementation review fold: R1-1). Review 1's mutant M2 (`NotEqual` returning
`not (self.Get() == other.Get())`, §7 A-8) survived every program of commit 4;
with the fold's NaN line optional_compare_generic prints `2 1 1 0 1 1` under it
(OUTPUT-MISMATCH), so A-8 has a program-level arbiter. Mutants of the M7 class (`Get()`
before the `HasValue()` tests) read uninitialized storage, so no program
arbitrates them deterministically; lower/testdata/optional/compare.carbon does,
and is their only arbiter (amended 2026-10-13, implementation review fold:
R1-5).

## §6 Churn and collision analysis (verified by `git diff --stat trunk...<branch>` at the heads named)

-   **Files:** core/prelude/types/optional.carbon (two lines replaced, 71
    appended); three new goldens; fork/conformance/programs/stdlib/ (one
    modified, six new programs and one oracle, two headers) (amended 2026-10-13,
    review fold: B-2), and with the implementation review's fold one more new
    program and one more modified (amended 2026-10-13, implementation review
    fold: R1-1, R1-5); fork/conformance/README.md (generated table);
    docs/design/optional.md (new), docs/design/control_flow/loops.md,
    docs/design/error_handling.md, docs/design/README.md (one blockquote each);
    docs/design/safety/type_safety.md and mutation_safety.md (one blockquote
    each, only if PR 53 is on trunk at discharge; amended 2026-10-13, review
    fold: B-3, B-5); fork/optional/plan.md, fork/inventory/work-items.json,
    fork/gap-analysis.md, fork/decision-log.md, fork/ORCHESTRATION.md.
-   **Goldens:** no existing golden changes (M-12, 1942 of 1942; ST-1's 1950 of
    1950 with OP-1, M-13, and OP-1's three fills byte-identical under ST-1's
    toolchain, M-21); no min_prelude golden can change (D-OP-9). file_test wall
    time moved from 21.8 s to 22.1 s on a quiet machine (M-12).
-   **Line shifts that break citations:** none above :204 (D-OP-8). Citations of
    optional.carbon elsewhere: W-058's and gap row 78's are rewritten anyway;
    the EH-A decision-log entry's and error_handling.md's :69-70 stay valid;
    error_handling.md:424's :29 is already stale on trunk and is corrected by
    OP-1's amendment (§0.3 item 10); SAFE-1's pages on the safe branch keep
    correct citations (D-OP-8's list), although TY4's content is falsified by
    M-9 (W-173); slices.md and unions.md cite no line numbers (amended
    2026-10-13, review fold: A-6, B-3). The prelude's own `Try` comment (:64-68)
    says the `match` form "applies once an approved `Optional` design makes it
    one"; F-015 is that approved design and does not make it one, so the
    conditional stays true, and the comment stays as D-OP-7 requires of :56-78;
    error_handling.md's OP-1 amendment and optional.md state that the design
    keeps the class (amended 2026-10-13, review fold: B-5).
-   **Other branches** (the heads at this plan: ua2 f96fe8a7a, cmake ea573f672,
    safe adaae4e35, ev cb3ef2e74, st 21307851a, sc 2497d5000, and sc 77838fdd5
    at rev 2): none touches core/prelude/types/optional.carbon,
    toolchain/testing/testdata/min_prelude/, a golden under an `optional/`
    directory, the five Optional programs, docs/design/optional.md, loops.md or
    error_handling.md. ST-1 (PR 55) changes core/prelude/types/string.carbon
    only among prelude files, and the two compose with no golden change (M-13);
    SAFE-1 (PR 53) adds blockquotes to docs/design/README.md at :2148, :2168 and
    :3900 and ST-1 one at :633-638, none near :860, so the README hunks merge
    cleanly (re-read the anchor at the merge of trunk). SC-1 changes
    member_access.cpp and name_lookup.cpp, through which `==` resolves, and
    impl_lookup.cpp (+47), impl.cpp (+237), generic.cpp, call.cpp and
    convert.cpp, whose `DiagnoseConversionFailureToConstraintValue` now builds
    the `ConversionFailureFacetToFacet` diagnostic that
    `fail_generic_without_copy` pins and whose W-171 CHECK moves from :1698 to
    :1712; M-14 rules out a runtime difference on its earlier build for the
    probes, and M-22 a golden or program difference on its build of 77838fdd5,
    with the parity caveat M-22 states (R-5) (amended 2026-10-13, review fold:
    B-8). EV-1 (PR 54) writes no text about Optional (`git diff
    trunk...claude/carbon-fork-0-1-ev` adds no line naming `Optional` outside
    the ledger's `source` string). UA-2 (PR 51) and CM-1 (PR 52) touch no OP-1
    file except the shared records. DD-1 (claude/carbon-fork-0-1-dd, W-065, row
    91 "Goal: design docs documented, cohesive, understandable without
    placeholders") has no commit beyond trunk's at this plan; if it edits
    docs/design/README.md near :860, loops.md, error_handling.md or
    pattern_matching.md's `Optional` examples before OP-1 lands, OP-1 re-anchors
    its amendments at the merge of trunk, and docs/design/optional.md is a page
    DD-1 can cite as one placeholder resolved.
-   **Same-anchor records and their resolution:** every live branch edits these
    at the same places, so a merge conflict there is expected and resolved by
    rule, never by merging hunks: fork/decision-log.md (each of CM-1, SAFE-1,
    EV-1 and ST-1 inserts its entry at trunk's :2863, SC-1 elsewhere; OP-1's
    entry goes immediately above the then-newest landed entry, §2.6); the
    fork/gap-analysis.md header sentence (OP-1 changes no count, only the
    scoreboard sentence, re-written from the run); row 78's line (:78 trunk and
    ua2, :79 cmake, :80 ev, :81 safe, :82 st, :83 sc: found by its bullet text);
    the fork/conformance/README.md table (regenerate with
    `--update-readme-table`); fork/ORCHESTRATION.md's Branches table, stamp
    paragraph and Scoreboard subsection (re-stamp);
    fork/inventory/work-items.json (append after the then-last item, ids per
    §2.6's rule, and the `source` sentence at its end).
-   **Ids:** W-170..W-179 used, F-015 minted (amended 2026-10-13, review fold:
    A-10); no other branch's ledger or plan names any of them (scan of trunk and
    68 branch refs, §2.6; trunk's own reservation lines excepted).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1: the carbonbuild fill differs from M-15's measurement.** The OP-1
    build is the trunk toolchain with a regenerated file_test manifest; M-15
    used the trunk file_test at substitute paths. Falsifier: the fill shows a
    crash, a different line count than M-15's (1435, 157, 488) beyond the
    TIP/ModuleID/source_filename/DIFile lines, or any §4 key line missing.
    Contingency: stop before commit 3 and explain the difference in a plan
    revision.
-   **R-2: a golden outside §4 moves.** M-12 rules it out on trunk (1942
    of 1942). Falsifier: the fill's diff or the gate names another file.
    Contingency: stop, diff it, explain it by a revision or revert the cause.
-   **R-3: `Optional(bool) == Optional(bool)` now crashes the compiler (M-7).**
    Accepted in D-OP-13: the crash is `Get()`'s and already reachable on trunk;
    no bound can exclude `bool`. Falsifier: a PASS program, golden or example in
    the OP-1 PR compares `Core.Optional(bool)` values (the SKIPped arbiter
    optional_bool does so on purpose; amended 2026-10-13, review fold: B-2). The
    same holds for `==` on `Core.Optional(Core.Optional(U*))`, a silent wrong
    answer (W-171; the SKIPped arbiter optional_nested_pointer compares them on
    purpose), and on `Core.Optional(Core.IntLiteral)`, a lowering crash (W-190),
    and the falsifier covers those payloads too (amended 2026-10-13,
    implementation review fold: R1-1, R1-4). Contingency: rewrite it to another
    payload and name W-171 or W-190 in its header.
-   **R-4: the composition with ST-1 changes at the merge of trunk.** M-13
    measured 1950 of 1950 on ST-1's head with v1 and again with v2, §2.1 byte
    for byte (amended 2026-10-13, review fold: A-5), and M-21 filled OP-1's
    three goldens with ST-1's toolchain byte-identically to the trunk fills.
    Falsifier: after the merge of a trunk that contains PR 55, §8.8's gate or
    conformance run differs from §4/§5 by more than ST-1's own contribution.
    Contingency: refill in a new autoupdate commit after the merge and explain
    it in a plan revision before commit 5 (amended 2026-10-13, review fold:
    B-4).
-   **R-5: SC-1's checker changes alter how the impls resolve or are
    diagnosed.** SC-1 changes member_access.cpp and name_lookup.cpp (through
    which `a == b` resolves), impl_lookup.cpp and impl.cpp (the witness lookup
    and impl declaration paths of the final impls), generic.cpp, call.cpp and
    convert.cpp (`DiagnoseConversionFailureToConstraintValue` now builds
    `ConversionFailureFacetToFacet` with structural-conformance notes) (amended
    2026-10-13, review fold: B-8). M-14 shows identical runtime output on SC-1's
    earlier build, and M-22 shows SC-1's later toolchain filling OP-1's three
    goldens byte-identically and passing its own 1959 goldens with OP-1's
    prelude, its file_test's parity with SC-1's head unverified. Falsifiers,
    read from §8.8's run on the merge commit: `fail_generic_without_copy`'s two
    `ConversionFailureFacetToFacet` errors gain or lose a note beside their
    `InitializingGenericParam` notes; `fail_specialize`'s
    `ImplFinalOverlapsNonFinal` pair changes; the `generic.carbon` split's
    `lookup_impl_witness` or symbolic `impl_witness_access` line changes; a
    golden outside §4 moves; or a program's output changes. W-171's convert.cpp
    citation becomes :1712 (the hand-off's re-read list). Contingency: refill in
    a new autoupdate commit after the merge and explain it in a plan revision
    before commit 5 (the ST-1 R-9 handling) (amended 2026-10-13, review fold:
    B-4).
-   **R-6: `final` blocks a future specialization.** Falsifier: a design needs
    `impl Optional(X) as EqWith(Optional(X))` for some `X` (for example a
    niche-aware equality). Contingency: D-OP-3's break condition, dropping
    `final`; only `fail_specialize` and `todo_fail_specialize_unused` refill.
    W-174 does not need it: pointer `==` makes the blanket apply to
    `Optional(T*)`, as a user pointer `EqWith` already does (M-18).
-   **R-7: an upstream advance conflicts in optional.carbon.** The fork already
    edits it (EH-A's :12 and :56-78); OP-1 adds :13, :27 and the appended block.
    Falsifier: the weekly upstream check sees optional.carbon change.
    Contingency: D-OP-8's break condition; the V-3a register entry tells the
    merge which side wins.
-   **R-8: upstream designs `Core.Optional`** (p006357's future work) with
    different comparison semantics or none. Falsifier: an accepted proposal.
    Contingency: D-OP-1/2/6 break conditions.
-   **R-9: W-177 re-platforms `Optional` as a choice.** Falsifier: a choice
    `Optional` lands. Contingency: the comparison bodies become `match`-based
    with the same semantics (D-OP-4), the `Try` body becomes error_handling.md's
    sketch (D-OP-7); optional_compare_diff and the payload program keep their
    EXPECT (a choice compares without copying, so the payload program's counts
    still hold: copies made and destroyed balance, where `T`'s own `Destroy` is
    complete; for a nested non-empty Optional payload they balance only once
    W-170 lands (amended 2026-10-13, implementation review fold: R1-2)).
-   **R-10: temporary lifetimes change.** The payload program's middle counts
    assume a comparison's `Get()` copies die by the end of its call and an
    expression statement's temporaries by the end of the statement (M-5; F-013
    D-SAFE-12 ends them at the full-expression, which is no later). Falsifier: a
    toolchain change that keeps them longer makes `live` print 4 after the
    comparisons. Contingency: the program is wrong only if the design says so;
    re-derive from F-013 before changing EXPECT.
-   **R-11: the build or the fill competes with concurrent workstreams.** Four
    cores; a fresh build is 10 to 17 minutes. Falsifier: `uptime` load above 4
    at build start. Contingency: wait; never touch /home/user/carbon-sc,
    carbon-st or carbon-ev or their build directories.

Rejected alternatives (each with the evidence that rejects it):

-   **A-1: heterogeneous `impl forall [U: ..., T: ... & EqWith(U)] Optional(T)
    as EqWith(Optional(U))`** (C++'s `optional<T> == optional<U>`).
    details.md:4466-4469 states the conditional comparison for "the same element
    type"; Rust agrees; a second, overlapping `final` blanket would interact
    with every other `EqWith` blanket's specialization rules for no requirement.
-   **A-2: mixed comparisons with a bare value or `Cpp.nullptr`** (C++'s
    `opt == v`, `opt == std::nullopt`). comparison_operators.md:288-289 selects
    `EqWith` without implicit conversions and offers `like` (W-178) as the
    mechanism; two impls per direction per operand type would also make
    `Optional(Optional(T)) == Optional(T)` ambiguous between nesting levels.
-   **A-3: a storage-level comparison member in `OptionalStorage`, or a
    builtin.** It would avoid M-5's copies but needs pointer equality for the
    niche (W-174) and changes the private interface every storage implements,
    for no 0.1 benefit; R17 favors the one-line bodies over
    `HasValue()`/`Get()`.
-   **A-4: re-platform `Optional` as a choice now.** SF-9's KEEP (D-EH-1),
    p006357's pointer ABI, the `Try` signature, the `for` desugaring's calls by
    name (handle_loop_statement.cpp:280-291) and the C++ mapping's name case
    (type_info.cpp:190) all constrain it, and comparison does not need it
    (D-OP-7, W-177).
-   **A-5: fix payload destruction in OP-1.** M-6: the straightforward declared
    `Destroy` rejects `Core.Optional(T*)` union fields and moves 26 goldens
    (D-OP-12, W-170).
-   **A-6: the dated amendment as a multi-line block after :29.** M-12: 14
    goldens move for a comment (D-OP-8).
-   **A-7: non-`final` impls.** M-11: a payload's library could silently
    redefine `==` on its Optionals when the payload is `Core.Eq` (D-OP-3;
    amended 2026-10-13, review fold: A-10).
-   **A-8: `NotEqual` by the interface default (`not Equal`).** Every prelude
    same-type impl defines it (§0.1 row 8), and C++ uses the contained type's
    `!=` (D-OP-1); for a `T` whose `!=` is not the negation of its `==`, the
    default would disagree with the oracle's rule.
-   **A-9: a checked `Get()` or pointer `==` in OP-1.** Each is its own design
    and golden refill (W-173: every lower golden instantiating `Get`; W-174: an
    undesigned pointer comparison and a new builtin) and neither is needed for
    Optional comparison.
-   **A-10: claim DONE with filed limits.** D-OP-13: W-170 and W-171 are
    operations of the type itself, the kind D-ST-16 keeps PARTIAL.

## §8 Verification and discharge

The carbonbuild scripts are the session scratchpad's
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild/`
(its README.md documents them); `$CB` below is that directory.

1.  **Build** (no Bazel, ever; the owner declined installing it):
    `$CB/build.sh /home/user/carbon-op` then
    `$CB/install.sh /home/user/carbon-op` (outputs under
    /home/user/carbon-build/carbon-op/; 10 to 17 minutes on 4 cores for a first
    build; no C++ changes, so `-Werror` is not at risk).
    `install/bin/carbon version` prints `0.0.0-0.dev+<sha>`. The build
    regenerates the file_test manifest with the three new goldens.
2.  **Fill to fixpoint** (R26): `$CB/autoupdate.sh /home/user/carbon-op` with
    the three golden paths of §4, repeated until a run prints only `.`: each
    converges on its second run (M-15). Commit 3 holds exactly the files the
    fill changed.
3.  **Gate:** `$CB/gate.sh /home/user/carbon-op` → 1945 tests (1942 + 3 on
    9d3ca60a3; on §8.8's merge commit, plus every golden the merged trunk adds),
    0 failed, no `!` or `?` marks. The verdict is read from gate.sh's exit
    status and the log's `[==========] N tests from ... ran.` and `[  PASSED  ]
    N tests.` lines, never from the failed count of gate.sh's summary line,
    which a brief file_test log reads as 0 when red (ST-1's ST1-IR2-8).
4.  **Conformance:** create `/home/user/carbon-build/carbon-op/cache` first (the
    driver otherwise falls back to a temporary cache per invocation,
    toolchain/driver/runtimes_cache.cpp:193-203), then
    `XDG_CACHE_HOME=/home/user/carbon-build/carbon-op/cache $CB/conformance.sh
    /home/user/carbon-op /home/user/carbon-build/carbon-op/conf-out` → §5's
    delta on the base of record, the Optional bullet PASS with six PASS and
    three SKIP, no other status change (amended 2026-10-13, review fold: B-2);
    four SKIP after the implementation review's fold (amended 2026-10-13,
    implementation review fold: R1-1). fork/conformance/out/scoreboard.json is
    not overwritten by a container run; the totals go into the landed notes, row
    78's "expected, not of record" sentence and the PR body, cited by toolchain
    sha, `generated` timestamp and totals. Then the non-vacuity falsifier (R16,
    M-19): the Optional programs run against copies of the built install
    carrying mutant A's and mutant B's optional.carbon make
    `optional_compare_diff` DIFF-MISMATCH and change no other status (amended
    2026-10-13, review fold: A-3, B-1).
5.  **Runner:** `python3 fork/conformance/runner.py --update-readme-table`, then
    `--self-test` → `self-test: 156 programs parsed, 56 bullets in table, OK` on
    9d3ca60a3 plus OP-1 (R7); 157 programs after the implementation review's
    fold (amended 2026-10-13, implementation review fold: R1-1).
6.  **prek fixpoint** (R22, R25), per commit as §3 says: `uvx prek run --files
    <that commit's files>` until a run changes nothing, before each of commits
    2, 4 and 5 and each fix commit; for every `.md` in the commit, heading
    counts per level and list-item counts including indented items (R31(b))
    recorded before and after, and the diff grepped for `^\+\s*#{1,6}
    [0-9]|^\+#[0-9]` (R31(c)); clang-format 21.1.8 on the oracle (R18).
7.  **Reconciliation greps:** `grep -n 'final impl forall \[T: Destroy &
    OptionalStorage' core/prelude/types/optional.carbon` → :69 (the `Try` impl,
    unchanged), :215 and :237; `git diff --numstat 9d3ca60a3 --
    core/prelude/types/optional.carbon` → `73 2` (the two replaced lines, :13
    and :27, and the 71 appended ones, :205-275); `grep -rln 'Optional(T) as
    EqWith' core toolchain/check/testdata toolchain/lower/testdata` →
    core/prelude/types/optional.carbon only (the fills name the impl
    `Optional.as.EqWith.impl`, never the source spelling; rev 1's "and the three
    new goldens" is corrected against M-15's fills, a fixer's correction);
    `grep -n 'optional_missing_ops' fork/conformance/README.md` → a `run` row.
8.  **Merge of trunk and re-verification** (amended 2026-10-13, review fold:
    B-4): after the implementation review's fold (§3), merge the then-current
    trunk into the branch with a merge commit, never a rebase. If `git
    diff --stat <pre-merge head> <merge commit>` names any path outside fork/'s
    records (toolchain/, core/, testdata, fork/conformance/programs/), re-run
    §8.1 to §8.5 on the merge commit: rebuild, fill (any golden change goes in a
    new "Autoupdate testdata goldens on the container arbiter" commit, never an
    amend), gate, conformance with the M-19 falsifier, and runner. R-4's and
    R-5's falsifiers are read from that run, and the counts commit 5 and the PR
    body quote come from it. If the merge brought fork/ records only, this step
    records that diff instead.
9.  **Discharge:** §2.6, then the ORCHESTRATION stamp; the PR body carries the
    verification record and the not-run list.
10. **PR-ready check** (R25) (amended 2026-10-13, review fold: B-9): `uvx prek
    run --all-files` until a run changes nothing, with R31(b) heading and
    list-item counts recorded before and after for every `.md` the PR changes
    and the R31(c) grep of the diff, as the last step before the branch is
    handed to the orchestrator.

**Not run, and why (named in the PR body):** Bazel and every Bazel-only test
(gtest unit tests, lit tests, fuzzers, install_test.py; no C++ is touched);
clangd-tidy (no C++ source changes, and the oracle is excluded by R24); any
hosted run and the owner's runner (R28; Actions is disabled); an opt-mode
(`NDEBUG`) toolchain; LLVM with assertions (the CMake LLVM is Release); macOS,
Windows, ASan; SC-1's file_test built from exactly SC-1's head against OP-1
(M-22's parity caveat; §8.8 covers it on the merge commit once SC-1 is on
trunk).

## Hand-off notes for the implementer

-   Copy §2.1, §2.3 and §2.4 verbatim from this file, and §2.5's verbatim
    sentences into docs/design/optional.md: they are the texts M-3, M-12, M-15,
    M-16 and M-18 to M-22 ran (rev 2) (amended 2026-10-13, review fold: B-7). If
    anything must change, re-run M-12 (file_test over the manifest), M-15 (the
    fill) and M-16 (the nine programs) against your build before committing, and
    record the change in the plan's landed notes.
-   Do not move a line of optional.carbon above :205 (D-OP-8); line 27's date is
    the date of commit 2, never re-stamped, and the line stays at most 80
    columns (amended 2026-10-13, review fold: B-9). Do not touch :56-78
    (D-OP-7).
-   Do not write CHECK lines, do not edit a filled golden, and do not touch
    min_prelude (D-OP-9). The fill must change exactly the three files of §4.
-   After commit 4, stop for the implementation review of R29(c); its fold is a
    separate fixer's (R11), in new commits, before the merge of trunk and §8.8
    (§3) (amended 2026-10-13, review fold: B-9).
-   No PASS program, golden or doc example compares `Core.Optional(bool)` values
    (W-171; the SKIPped arbiter optional_bool does, on purpose; amended
    2026-10-13, review fold: B-2), `Core.Optional(Core.Optional(U*))` values
    (W-171; the SKIPped arbiter optional_nested_pointer does, on purpose) or
    `Core.Optional(Core.IntLiteral)` values (W-190) (amended 2026-10-13,
    implementation review fold: R1-1, R1-4), or passes a float or character
    literal to `Some` (W-172: bind a typed value first); no example relies on an
    Optional destroying its value (W-170) or calls `Get()` without `HasValue()`
    (W-173).
-   docs/design/optional.md's declarations are copied from the landed
    optional.carbon and diffed against it before commit 4 (R27); its examples
    are this plan's programs or compiled on the landed toolchain.
-   Re-read at the merge of trunk (R9): row 78's line and the header sentence,
    the scoreboard base, the decision-log anchor, docs/design/README.md:860 and
    error_handling.md:444 (the amendment anchors), the ids (§2.6), W-171's
    convert.cpp citation (:1698 on trunk, :1712 once SC-1 lands; amended
    2026-10-13, review fold: B-8), and, if PR 53 has landed, type_safety.md's
    TY4 paragraph and mutation_safety.md's EX-M-5/EX-M-6 staging paragraph, the
    anchors of §2.5's SAFE-1 amendments (amended 2026-10-13, review fold: B-3,
    B-5). The `fail_specialize` note pins optional.carbon:215; if the merge
    brings an edit above it, autoupdate follows and the matrix row is amended at
    landing.
-   Never run `git add -A` (R20); commit with the author and committer
    conventions of the brief and end each message with exactly the attribution
    trailers the session's harness notice specifies, plus the brief's
    Claude-Session line (this plan does not reproduce the trailer text, because
    the brief forbids model names in repository files). Do not push or open the
    PR until the orchestrator says so. Fix-ups after a commit exists are new
    commits, never amends.

## Review fold record (rev 2, 2026-10-13)

Every finding of the two rev 1 reviews, its grade, its disposition and where it
is folded. Review A (design soundness and toolchain correctness) returned
APPROVE-WITH-AMENDMENTS with 3 MAJOR and 7 MINOR findings; review B
(concreteness, process, Goodhart and cross-workstream) returned
APPROVE-WITH-AMENDMENTS with 4 MAJOR and 5 MINOR. All 19 are folded; none is
rejected. Review A's ids A-1..A-10 are review findings; the rejected
alternatives of §7 keep their own A-1..A-10 numbering and are always cited as
"§7 A-n". The fixer re-opened every cited location (on 9d3ca60a3 and, for SAFE-1
and SC-1, on the safe head adaae4e35 and the sc head 2497d5000) and re-ran every
measurement a finding is about in its own scratch tree
(`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/op1-fixer`),
after first reproducing rev 1's three fills at 1140, 127 and 362 lines; each
reproduction is the §0.2 entry the table names. Rev 2 changes no line of §2.1,
so M-1 to M-11 and M-14 stand as measured, M-12's whole-manifest pass stands
with its sanity sentence re-measured, and M-13 was re-run on v2; §2.3 and §2.4
changed and were re-measured (M-15, M-16, M-19 to M-22).

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| A-1: pointer-niche Optionals compare when the pointer type has a user `EqWith` | MAJOR | Reproduced (M-18: a user `impl C* as Core.EqWith(C*)` makes `Core.Optional(C*)` print `1 0 0 1 1` on v2, where trunk gives the diagnostic; a `final` prelude pointer impl in comparison.carbon makes the user impl "`impl` will never be used"). Folded as proposed: "compares exactly when `T*` is `Core.Eq`" in §1.2, the F-015 sentences, the README amendment, optional_pointer_compare's SKIP line and header, optional_pointer_niche's header, and W-174's title and notes with the measured `final` overlap; the `user_pointer` split added to check/testdata/optional/compare.carbon and filled | §0.1 row 10; §0.2 M-15, M-18; D-OP-10; §1.1; §1.2; §1.7 W-174; §2.3; §2.4; §2.5; §2.6 W-174, row 78; §4 |
| A-2: the copying bodies give comparisons observable side effects | MAJOR | Reproduced (M-5 prints `101 102 202 201` inside one `a == b`; comparison_operators.md:312-316 and :430-434 re-read). Folded as proposed: V-3 discloses the divergence, D-OP-4 states it and its break condition closes it, §1.2 and §1.3 say it, F-015's Comparison sentences quote the design, and the V-3a register records it | Design authority; V-3; D-OP-4; §1.2; §1.3; §2.5; §2.6 decision log |
| A-3: two wrong bodies survive every test | MAJOR | Reproduced (M-19: under mutant A, rev 1's optional_compare_diff passes against its oracle, as do the other three comparing programs). Folded as proposed: optional_compare_diff and its oracle are the 36-line matrix of every case of the six operators, predicted before the run, byte-identical with the oracle, running all 18 branches and DIFF-MISMATCH under mutant A; `IsLe` and `IsGt` added to the check and lower concrete splits and filled; M-15 and M-16 re-run | §0.2 M-15, M-16, M-19; D-OP-10; D-OP-11; §2.3; §2.4; §4; §5; §8.4 |
| A-4: M-12's `Gett` check does not reproduce | MINOR | Reproduced (1942 run, 1617 pass, 325 fail: 312 full-prelude goldens, 12 driver and 1 language-server tests). Folded: the measured result replaces the sentence | §0.2 M-12 |
| A-5: v1 is not "§2.1 without the line-27 amendment" | MINOR | Reproduced (the planner's v1 differs from §2.1 at line 27 and in a 6-line against a 9-line header comment). Folded both ways: v1 redefined in §0.2 and R-4, M-13 re-run on v2 (1950 of 1950), and M-17 marked superseded by M-16's whole-suite run on v2 | §0.2 setup, M-13, M-17; §7 R-4 |
| A-6: citation errors | MINOR | Reproduced each: milestones.md:55-56 and :68-70; error_handling.md:424's `:29` where the class is at :30; SAFE-1's README:136 and its other optional.carbon cites on adaae4e35, none above :203. Folded as proposed: the criterion re-cited; §0.3 item 10 and the error_handling.md amendment name :30; D-OP-8 lists every SAFE-1 cite; §6 no longer calls :29 valid | Item; §0.3; D-OP-8; §2.5; §6 |
| A-7: W-006's coherence risk 9 is not addressed | MINOR | Reproduced (W-006 and W-058 notes; fork/design-sprint/README.md:234-238). Folded with B-6: D-OP-7 states that risk 9 is resolved the other way, §2.6 adds notes to W-006 and W-010, and the F-015 entry records risk 9 closed | D-OP-7; §2.6 |
| A-8: the `Optional(bool)` crash statements are inaccurate | MINOR | Reproduced (M-20: trunk's `==` on `Core.Optional(bool)` is the clean diagnostic, v2's aborts in lowering). Folded as proposed: row 78's text, W-171, D-OP-13's fuller reason, §1.2 and F-015's comparison sentence carry the `bool` exception | §0.2 M-20; D-OP-13; §1.2; §1.7 W-171; §2.5; §2.6 W-171, row 78 |
| A-9: accepted-design authority is uncited | MINOR | Reproduced (p002188:488-489 and pattern_matching.md:527-528; p001154:211-227 is a considered alternative; classes.md:1992-2003 is the adopted rule). Folded as proposed: design authority, D-OP-1, V-3's `None` against `None()` divergence, §1.3, D-OP-12, W-170 and F-015 | Design authority; V-3; D-OP-1; D-OP-12; §1.3; §1.7 W-170; §2.5; §2.6 W-170, decision log |
| A-10: D-OP-3 overstates what `final` guarantees | MINOR | Reproduced (M-11's declaration-only compile; p5337:280-286). Folded: D-OP-3 narrowed to a `Core.Eq` payload; the toolchain gap recorded in F-015 and filed as W-179, the reserved spare; the optional `todo_fail_specialize_unused` split added and filled (no diagnostic, 157 lines) | Id allocation; D-OP-3; D-OP-10; D-OP-15; §1.7 W-179; §2.3; §2.5; §2.6 W-179; §4; §6; §7 A-7, R-6 |
| B-1: `!=`, `<=`, `>` and `>=` are not checked on held values | MAJOR | Reproduced with review B's 7-line mutant (the fixer's copy is byte-identical to its file): rev 1's optional_compare_diff passes against its oracle, and the other three comparing programs pass. Folded with A-3: the 36-line matrix covers every case B-1 lists and is DIFF-MISMATCH under the mutant; §8.4 runs both mutants as the non-vacuity falsifier; `<=` and `>` added to both concrete splits | As A-3; §8.4 |
| B-2: the two row-bounding residues have no arbiter | MAJOR | Reproduced (scoreboard.json rolls the bullet up as PASS beside its gap status PARTIAL; no program observes W-170 or W-171). Folded as proposed: optional_destroys_value (EXPECT `2 0 1 0 3 0` from F-015, measured `2 1 1 0 3 2`, and `2 0 1 0 3 0` on M-6's prototype) and optional_bool (checks clean, aborts in lowering) added as SKIPs; D-OP-13's break condition is their PASS in a run of record; §5 is 132/0/24 over 156; optional_pointer_compare kept, its header saying that it does not bound the row; row 78 and the README table updated | Outcome; §0.2 M-16, M-20; D-OP-11; D-OP-13; §1.3; §1.7; §2.4; §2.6 row 78; §3; §5; §6; §7 R-3; §8.4; hand-off |
| B-3: W-173 falsifies SAFE-1's TY4 | MAJOR | Reproduced (type_safety.md:179-195 and :342 on adaae4e35 against M-9). Folded as proposed: W-173's notes, §1.3, F-015's Ownership sentences and the V-3a register state the F-013/F-015 tension; D-OP-13's break condition makes TY4 a DONE gate; a dated type_safety.md amendment at discharge if PR 53 is on trunk; D-OP-8 and §6 no longer say that SAFE-1's pages stay correct without qualification | Outcome; D-OP-8; D-OP-13; D-OP-14; §1.3; §1.7 W-173; §2.5; §2.6 W-173, row 78, decision log; §6; hand-off |
| B-4: nothing is re-verified after the merge of trunk | MAJOR | Reproduced (the order of §2.6, §3 and §8; the R-4 and R-5 contingencies; "rebase" where the plan forbids one). Folded as proposed: §8.8 re-runs §8.1 to §8.5 on the merge commit when the merge brings anything outside fork/'s records, refills going in new autoupdate commits; R-4 and R-5 rewritten; §3 states the order; "rebase" replaced by "merge of trunk" except where the plan forbids a rebase; M-21 fills the new goldens with ST-1's toolchain | Item; §0.2 M-21, M-22; D-OP-15; §2.6; §3; §5; §6; §7 R-4, R-5; §8.3, §8.8; hand-off |
| B-5: SAFE-1's EX-M-5 and EX-M-6 wait on a redesign nobody owns | MINOR | Reproduced (mutation_safety.md:317, :664-683, :724-725 and :801-803 on adaae4e35; optional.carbon:64-68). Folded as proposed: W-177 names them; optional.md's Pattern matching and Ownership sentences (non-`Plain`, D-SAFE-9); a dated mutation_safety.md amendment at discharge if PR 53 is on trunk; §6 records why :64-68 stays | §1.3; §1.7 W-177; §2.5; §2.6 W-177; §6 |
| B-6: W-006 and W-010 are not updated | MINOR | Same defect as A-7; W-010's note added too | D-OP-7; §2.6 |
| B-7: optional.md is an outline only; the alternatives range | MINOR | Folded with the first option: §2.5 gives the page's normative sentences verbatim (status, comparison, the pointer and `bool` cases, the side-effect divergence, `final`, ownership with W-170, the `Get()` precondition with W-173 and TY4, non-`Plain`, pattern matching), and the implementation review reviews the page against them (§3); the range is §7 A-1..A-9, with §7 A-10 excluded as a decision about the row, not the design | §2.5; §3; hand-off |
| B-8: SC-1's overlap with the comparison path is understated | MINOR | Reproduced (`git diff trunk...claude/carbon-fork-0-1-sc`: impl_lookup.cpp +47, impl.cpp +237, generic.cpp, call.cpp, and convert.cpp, which now builds `ConversionFailureFacetToFacet` with notes; the CHECK at :1712 there, also on SC-1's later head 77838fdd5). Folded as proposed: R-5 lists the files with the pinned diagnostics and key lines as falsifiers; §6 and W-171 updated; the hand-off's re-read list names convert.cpp's line; and M-22 measured the composition on SC-1's later build: its 1959 goldens pass with OP-1's prelude and OP-1's fills are byte-identical | §0.2 M-14, M-22, "Not measured"; §1.7 W-171; §2.6 W-171; §6; §7 R-5; hand-off |
| B-9: process gaps | MINOR | Folded as proposed: §8.10 runs `uvx prek run --all-files` with R31 counts before hand-over; :205-275 everywhere; line 27's date is commit 2's and is never re-stamped; §3 has the implementation-review slot and its fix commits | §2.1; §2.6 W-058, landing-date stamps; §3; §8.10; hand-off |

Two corrections the fixer made that no review raised, found while re-measuring:
§8.7's grep for `Optional(T) as EqWith` finds core/prelude/types/optional.carbon
only, because the fills spell the impl `Optional.as.EqWith.impl` (rev 1 also
named the three goldens); and the mangled name in the W-171 abort depends on the
program (M-7's `_CSome.74becf39533834ee...`, the arbiter's
`_CSome.5d6f3f3a4b44a8f1...`), so optional_bool's SKIP line quotes its own.

## Sign-off

Signed off for implementation on 2026-10-13 at rev 2 by the orchestrator under
R29(a): the two plan reviews of R29(c) (A, design soundness and toolchain
correctness: APPROVE-WITH-AMENDMENTS, three MAJOR and seven MINOR; B,
concreteness, process, Goodhart and cross-workstream: APPROVE-WITH-AMENDMENTS,
four MAJOR and five MINOR) found no BLOCKER, so no focused re-review is owed;
all nineteen findings are folded in rev 2 (d39c0e91d) and none is rejected. The
row stays PARTIAL by D-OP-13, bounded by W-170 and W-171; the ids W-170 to
W-179 are this workstream's, as trunk's fork/ORCHESTRATION.md records, and
F-015 is minted. Implementation follows §3's commits 2 to 5, with the
implementation review and its fold between commits 4 and 5; the merge position
is last, after PR 55 (ST-1), with DD-1 (ids from W-180) after it.

## Implementation review fold record (2026-10-13)

Two implementation reviews of commits 2 to 4 (5d9edb3e0, 4dc9dbefc, a8daacf11)
and of the implementer's pre-review fix commit 1fc03110e returned
APPROVE-WITH-FIXES: review 1 (correctness and soundness; ids R1-1 to R1-7) with
1 MAJOR and 6 MINOR findings, and review 2 (R27 fidelity, R16 derivations, the
F-015 page as a design document against §2.5's sentences, prelude style and
readiness for commit 5; ids IR2-1 to IR2-12, written OP1-IR2-n by the review)
with 1 MAJOR and 11 MINOR. Neither found a BLOCKER. Two pairs are one finding
seen twice (R1-6 and IR2-10, R1-7 and IR2-9). All 19 are folded and none is
rejected. The fold changes no prelude line, C++ source or golden, so the build
of 5d9edb3e0 (`carbon version` 0.0.0-0.dev+5d9edb3e0) and commit 3's fill stand
and no autoupdate commit is needed; it adds one program, extends one,
regenerates the README table, and amends docs/design/optional.md and this plan,
each plan amendment marked "(amended 2026-10-13, implementation review fold:
<id>)" or "(corrected ...)". The fixer reproduced every finding about behavior
in its own scratch tree (session scratch `op1-impl/fixer`: the OP-1 install of
5d9edb3e0 with its runtimes cache, the trunk install 0.0.0-0.dev+0bdce60a5, a
copy of the OP-1 install carrying M-6's `Destroy` prototype, a copy carrying
review 1's mutant M2, copies of the caches of the implementer's mutant A and B
installs, and the reviews' probes copied from `op1-impl/rev1/p`, `rev1/cpp` and
`rev2/probe`), with each expected line written down before the run.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| R1-1: W-171's root cause also mis-lowers `Get()` and copy of `Core.Optional(Core.Optional(U*))`, and OP-1's `==` now returns wrong answers there | MAJOR | Reproduced on the OP-1 install: cptr.carbon prints `1 0 0 1 1 1 -1 1 0 0 1 1 1 0 1 -2 0 0 0 1 0 0`, its nested `oo1 == oo2` and `Same(oo1, oo2)` printing 0 where F-015 gives 1; nestnone.carbon prints `1 1 1` (expected `1 0 0`) on OP-1 and on trunk; nestptr_get.carbon prints addresses where 7 is right; trunk rejects the nested `==` with `MissingImplInMemberAccess`; the unoptimized IR (`--optimize=none --dump-llvm-ir`) of nestptr_get has the storage `Get` (optional.carbon:169) pass `getelementptr inbounds nuw <{ ptr, i1 }>, ptr %value, i32 0, i32 0` to the inner `Optional(i32*)` `Copy`, which is `ret ptr %self`. Folded as proposed, with the arbiter made deterministic: optional_nested_pointer.carbon (SKIP; EXPECT `1 0 0 1 1` from F-015's rules; measured `1 1 1 0 0` with OP-1 in three runs; on trunk the four lines before its `==` print `1 1 1 0`) prints `B(*...Get().Get() == 7)` rather than the pointee, so that its SKIP line quotes exact output, and adds the copy case; W-171 widened in §1.7 and in §2.6's title and notes; the F-015 sentence extended on the page and in §2.5; the page's W-171 limit and its close condition; D-OP-13, R-3, the Outcome, row 78, §W9; §5 re-derived to 132/0/25 over 157; the README table regenerated | Outcome; D-OP-11; D-OP-13; §1.2; §1.7 W-171; §2.4; §2.5; §2.6 W-171, row 78, §W9; §5; §6; §7 R-3; §8.4, §8.5; hand-off; optional.md Comparison and 0.1 limits |
| R1-2: W-170's consequences for comparison are unrecorded | MINOR | Reproduced: gentemp.carbon, gentemp2.carbon and gentemp3.carbon each fail on OP-1 with "cannot access member of interface `Core.Destroy` in type `Core.Optional(T as Core.OptionalStorage)`" (on trunk gentemp and gentemp3 fail the same way, and gentemp2 stops at `EqWith` first), and all three check on the copy carrying M-6's prototype; nesttrace.carbon prints `101 102 -1 101 102 -2 101 102 101 102 202 201 0 -3 202 201` on OP-1 and `... 101 102 101 102 202 201 202 201 0 -3 ...` on the prototype. Folded as proposed | §1.2; §1.3; §1.7 W-170; §2.6 W-170; §7 R-9; optional.md Comparison and Ownership and lifetime |
| R1-3: comparing `Core.Optional(Cpp.S)` fails with an export TODO | MINOR | Reproduced (`--phase=check` with review 1's s.h): cppeq.carbon and cppopt0.carbon check; cppopt.carbon fails with "semantics TODO: `interop with non-identifier package name`" at optional.carbon:30:1, raised at check/cpp/export.cpp:141, and on trunk with that TODO and `MissingImplInMemberAccess`; cppfile.carbon checks. Folded as proposed: a paragraph in optional.md's C++ interoperability and a W-049 limit; W-049's notes at commit 5 | §2.6 W-049; optional.md C++ interoperability and 0.1 limits |
| R1-4: `==` on `Core.Optional(Core.IntLiteral)` passes check and aborts lowering | MINOR | Reproduced: lit.carbon is `MissingImplInMemberAccess` on trunk, and with OP-1 checks with exit 0 and aborts `carbon compile`, exit 134, at "Lowering function Equal(Core.IntLiteral as Core.OptionalStorage & Core.Destroy & Core.Eq)" (optional.carbon:217, the call at :224) with the `llvm::cast<llvm::IntegerType>` assertion; genlit.carbon aborts the same way on trunk and on OP-1. Folded as proposed, filed as W-190: the ledger maximum over trunk and every local and `origin` `claude/carbon-fork-0-1-*` ref is W-168 (sc), no text on any ref names an id from W-190 up, and DD-1's plan reserves W-180..W-189, so W-190 is the next free id, re-scanned at discharge with the others; no ledger item names the defect (a grep for "compile-time-only" over every ref's ledger finds none) | D-OP-13; §1.2; §1.7 W-190; §2.5; §2.6 id re-scan, W-190, row 78, ORCHESTRATION; §7 R-3; hand-off; optional.md Comparison and 0.1 limits |
| R1-5: two body mutants survive every program | MINOR | Reproduced: review 1's runmut.out records M2 and M7 surviving all nine programs; nan.carbon prints `0 0` for `nan == nan` and `nan != nan` (handle_call.cpp:60 lowers `float.neq` to `FCMP_ONE`, as comparison_operators.md:311-314 designs for NaN). Folded through the generic rather than as a concrete line: optional_compare_generic gains `Differ[T: Core.Eq & Core.Copy & Core.Destroy]` (`a != b`) and `Differ(some_nan, some_nan)`, EXPECT `0` from D-OP-1 and comparison_operators.md:311-314; it prints `2 1 1 0 1 0` with OP-1 and `2 1 1 0 1 1` under M2 (OUTPUT-MISMATCH); §5 records that M7-class mutants have only the lower golden as arbiter | D-OP-11; §2.4; §5 |
| R1-6 / IR2-10: commit 4's message misstates the trunk non-vacuity counts | MINOR | Re-measured on the trunk install (`--phase=check`): optional_missing_ops 1, optional_compare_diff 6, optional_compare_generic 4 (3 `EqWith`, 1 `OrderedWith`) and 2 "cannot convert type", optional_compare_payload 3; after the fold, optional_compare_generic gives 5 (4 `EqWith`, 1 `OrderedWith`) and the same 2, and optional_nested_pointer 1. Folded: here and in §2.6, for commit 5's message, the decision-log entry and the PR body; a8daacf11's message stays, since no commit is amended | §2.6 |
| R1-7 / IR2-9: the plan keeps the imprecise `TrivialDestructor` rule | MINOR | Verified (classes.md:1995-1996: "does not define a destructor or the class defines the destructor with an empty body"). Folded: §1.3, D-OP-12 and the §2.6 W-170 row say "a class that defines a destructor with a non-empty body", as the page does since 1fc03110e | §1.3; D-OP-12; §2.6 W-170 |
| IR2-1: optional.md's claim about `?` in a `Core.Result`-returning function is false | MAJOR | Reproduced: review 2's unit_err.carbon (`Core.Result(i32, ())`) compiles, links and prints `-1 5` on OP-1; int_err.carbon (`Core.Result(i32, i32)`) fails at the `?` with "cannot implicitly convert expression of type `()` to `i32`", noted at result.carbon:51 (`FromBreak(b: E)`). Folded: the Propagation and iteration sentence states the measured behavior (compiles only when `()` converts to `E`; `.Err(())` for `E = ()`); optional.carbon:56-78 untouched | optional.md Propagation and iteration |
| IR2-2: D-EH-1 is quoted without its clause giving the choice question to W-058 | MINOR | Verified (decision-log.md:5611-5615). Folded: "A class, not a choice" says D-EH-1 kept the class at EH-A and left re-platforming onto `choice` to W-058's design, which this page is, and that F-015 keeps the class by D-OP-7; error_handling.md's amendment keeps its plan-verbatim "(D-EH-1)" | optional.md A class, not a choice |
| IR2-3: W-173's close condition mixes in the row's DONE gate | MINOR | Folded as proposed: the W-173 limit closes when `Get()` on an empty value is a fail-stop; the TY4 alternative stays in D-OP-13's DONE gate and in the normative Ownership paragraph, which says when the TY4 contradiction ends | optional.md 0.1 limits |
| IR2-4: Pattern matching conflicts with W-177's close condition | MINOR | Folded: the examples wait on W-177, which may close by `Match` for classes or by a `choice` that keeps the constraints of "A class, not a choice", and no choice redesign comes from this design | optional.md Pattern matching |
| IR2-5: "same-type integer comparisons" mislabels the precedent | MINOR | Verified (int.carbon:91-104 and uint.carbon's `Int(N)`/`UInt(N)` with `Int(M)`/`UInt(M)`; float.carbon:165-170 and cpp/int.carbon:341-375 same-type). Folded: optional.md names the integer comparisons as `Int(N)` with `Int(M)`; §0.1 row 8 and D-OP-3 corrected in place | §0.1 row 8; D-OP-3; optional.md Comparison |
| IR2-6: the `UnformedInit` row misstates the bound | MINOR | Verified (optional.carbon:48, `[T: OptionalStorage & UnformedInit]`). Folded: the page's and §1.1's rows read "when `T` may (`T: UnformedInit`)" | §1.1; optional.md The type |
| IR2-7: the Overview overclaims, and the limits omit the side-effect divergence | MINOR | Folded both ways: the Overview says "the fork's design for those uses" and that the limits section lists each filed limit and the one divergence it discloses; a paragraph after the limits list states the copy-and-destroy divergence and that W-177 or a by-reference accessor closes it (no work item tracks it on its own) | optional.md Overview and 0.1 limits |
| IR2-8: the TY4 amendment misses TY4's `match` path, and the safety terms are unlinked | MINOR | Verified (type_safety.md:186-188 at adaae4e35 names "a `match`"; adaae4e35 is not an ancestor of trunk 162c7e839). Folded: §2.5's TY4 amendment text gains the `match` clause, and the commit that lands it links TY4, D-SAFE-9, `Core.Plain` and EX-M-5/6 from optional.md | §2.5 |
| IR2-11: the pre-review fix commit sits outside §3 | MINOR | Folded: 1fc03110e is recorded here as the implementer's pre-review commit (the D-EH-1 quotation and the `TrivialDestructor` rule on optional.md), reviewed by both reviews, and refined by IR2-2; the fold commit carries §3's title | this record |
| IR2-12: when the merge of trunk before commit 5 is taken is ambiguous | MINOR | Verified (origin/trunk is 162c7e839; none of PR 53, PR 51, PR 52, SC-1, PR 54 and PR 55 has merged). Folded: §3's timing rule, to which §2.6 points | §2.6 ORCHESTRATION; §3 |

Fix-round verification, at the fold's tree with the toolchain of 5d9edb3e0 (the
fold changes no file that the build compiles):

-   **Gate:** gate.sh printed `1945 passed, 0 failed (exit 0, 36s)`; the log
    reads `[==========] 1945 tests from 1 test suite ran.` and
    `[  PASSED  ] 1945 tests.` with no `[  FAILED  ]` line.
-   **Conformance** into `op1-impl/conf-fix`, with
    `XDG_CACHE_HOME=/home/user/carbon-build/carbon-op/cache`: scoreboard
    generated 2026-10-13T23:47:56Z, PASS 132, COMPILE-FAIL 0, LINK-FAIL 0,
    RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 25 of 157, bullets
    48 PASS and 8 SKIP of 56, in 43.0 s. Against the implementation run
    (`op1-impl/conf`) the only change is the new SKIP optional_nested_pointer;
    against fork/conformance/out/scoreboard.json (128/0/22 over 150) the eight
    changes are all Optional (optional_missing_ops SKIP to PASS and seven new
    programs), the 16 error_handling programs PASS, and the Optional bullet is
    PASS over ten programs with its gap status PARTIAL. This is §5's amended
    expectation, not of record.
-   **Mutants (§8.4):** the Optional programs on the implementer's mutant A
    and B installs (private copies of their caches) make optional_compare_diff
    DIFF-MISMATCH and change nothing else; on review 1's M2 only
    optional_compare_generic changes, to OUTPUT-MISMATCH; on the OP-1 install
    every one is PASS or SKIP as above.
-   **Runner:** `--update-readme-table` wrote 157 rows, one new;
    `--self-test` printed `self-test: 157 programs parsed, 56 bullets in table,
    OK`.
-   **Docs:** the page's API listing and examples are unchanged, so R27 and the
    examples' compile check stand. R31 counts before this commit's edits and
    after its prek fixpoint: optional.md h1 1, h2 11, h3 3, numbered 0
    unchanged, dash items 53 before and 55 after (the W-190 and W-049
    limits); this plan h1 1, h3 17, numbered 25 unchanged, h2 12 before and 13
    after (this section), dash items 124 before and 134 after (§1.7 W-190,
    §2.6's W-049 notes and non-vacuity counts, §5's two derivations and this
    record's five); fork/conformance/README.md h1 1, h2 4, h3 3, dash items
    22, numbered 6, unchanged. The R31(c) grep of the commit's diff finds no
    manufactured heading. prek (with the four SKIPs of §3) reached its
    fixpoint on its third run over the five files: the first rewrapped this
    commit's lines and, in row 78's quoted text, the paragraph around the
    placeholder `<the base's totals and run, ...>`, which rumdl keeps on one
    line, so the fold shortened the placeholder to `<the base's totals and
    run>` with its gloss in parentheses; the second rewrapped that paragraph;
    the third changed nothing, and so did two more after this sentence was
    written.
