<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Operator export plan: Carbon operator impls as C++ operator overloads (OX-1, W-054)

**Status:** rev 2, 2026-10-14 -- the fold of the two plan reviews of R29(c), for
a focused re-review (both reviews REJECTed rev 1; the ST-1 and OP-2 precedent).
Review A (toolchain soundness) returned REJECT with 1 BLOCKER, 5 MAJOR and 4
MINOR findings; review B (concreteness, process and cross-workstream) returned
REJECT with 2 BLOCKER, 3 MAJOR and 7 MINOR. Review A numbered its findings B-1,
M-1..M-5 and m-1..m-4, and review B OX-B-1..OX-B-12; this plan cites them as
A-1..A-10 (A-1 is review A's B-1, A-2..A-6 its M-1..M-5, A-7..A-10 its m-1..m-4)
and B-1..B-12, so that none reads as a measurement M-n; the rejected
alternatives of §7.2 keep their numbering and are always cited as "§7 A-n".
Every amended sentence, row or entry is marked "(amended 2026-10-14, review
fold: A-n)" or "(... review fold: B-n)" and tabled in the
[Review fold record](#review-fold-record-rev-2-2026-10-14): all 22 are folded
and none is rejected outright; A-1 is folded partly by a route other than the
one proposed, with its evidence (R17), and A-7 takes the second of the two
routes its finding offers. The fixer re-ran every measurement a finding is about
in its own scratch tree,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1-fixer`
(`$F` below; the planner's tree is `$X`, §0.2): the reviewers' probes copied
under `$F/probes/A-*` and `$F/probes/B-*`, the planner's under `$F/probes/P`,
the fixer's own under `$F/probes/V`, each run on the trunk install, on the
planner's `v4` and on the rev 2 prototype `v5`. Rev 2 replaces the toolchain
spec (`v4` → `v5`, §2.1 to §2.4), the goldens (§2.5) and two programs (§2.6), so
M-7, M-8, M-12, M-13, M-14, M-16, M-18 and M-19 were re-run on `v5` and M-20 to
M-30 added; every other number of rev 1 stands as measured. Rev 1 was the
planner's draft (3128eded5). Nothing below is implemented. Branch
`claude/carbon-fork-0-1-ox`, cut from trunk f67ab650d, whose toolchain and core
sources equal the upstream cut 0bdce60a5 (the toolchain and core paths of `git
diff --stat 0bdce60a5 f67ab650d` print nothing); trunk has since moved to
3eb7f36f0 by two fork/ORCHESTRATION.md-only stamps (44761146d records this
workstream and its id reservation; 3eb7f36f0 records DD-1 as PR 58, SC-1's and
DD-1's new id blocks and these plan reviews), and is not merged into the branch.
Every line number below is against f67ab650d unless a branch is named. Every
measured outcome in §0.2 was taken in this container with the trunk build
(`/home/user/carbon-build/carbon-trunk`, `carbon version` reporting
`0.0.0-0.dev+0bdce60a5`) and its file_test, the upstream nightly 2026.10.12 (an
oracle for the failure only, never for an EXPECT; R16(d), R30), and prototype
toolchains relinked from the trunk build's objects with this plan's §2.1 to §2.4
compiled in (§0.2, setup); no toolchain was built, nothing under
/home/user/carbon-build was modified, no worktree other than this one was
touched (others were read with `git show`), and the owner's runner was not used
(R28). The spec of §2.1 to §2.4 is the prototype `v5`: the diff `$F/ox1-v5.diff`
(sha256 d32f99f5…08919f04, 829 lines) compiled with the trunk build's flags,
clang-format 21.1.8 clean, and measured end to end. The copy embedded in §2.1 is
that diff as prek leaves it, whitespace-normalized (a blank context line loses
its leading space), so its own hash differs; it applies with `git apply` to
f67ab650d and yields the five files whose sha256 §2.1 lists, which is the
identity check (rev 1 claimed the embedded copy was `v4` "byte for byte"; it was
not; amended 2026-10-14, review fold: A-10, B-7).

**Item:** W-054, "Export Carbon operator impls as C++ operator overloads" (kind
missing-feature, size L, subsystem toolchain/check/cpp, blocked_by W-007).
**Milestone row:** fork/gap-analysis.md:48, "Type system: C++ interop —
exporting Carbon operator overloads into C++", MISSING, evidence "No evidence
anywhere of exporting Carbon operator impls for use from C++ (audit: 'operator
interop is one-directional')"; records refer to the row by its bullet text (R7),
because held PRs move its line. **Bullet text** (docs/project/milestones.md:129
to :132): "Operator overloading", "C++ interop:", "Exporting Carbon overloads
into C++". **Arbiter:**
fork/conformance/programs/interop/cpp_operator_export.carbon, SKIP,
EXPECT-STDOUT `42`. **Criterion:** the bullet, read under F-017 (D-OX-1,
D-OX-4, D-OX-14, D-OX-18): every concrete operator impl of the checking file
whose `Self` or operand is a Carbon class that C++ sees as a record of its own,
the design overview's "Carbon types implementing an operator overload"
(docs/design/README.md:3666), and whose interface has a C++ overloaded-operator
counterpart ([over.oper]) is usable from C++ with that operator; every case left
out is filed with its reason; and the overview's conversions, "the
`ImplicitAs(U)` Carbon interface corresponds to implicit conversions in C++"
(:3679-3680), are inside the bullet and filed as W-208, which bounds the row
(rev 1's criterion named every concrete impl of the file, which impls with no
Carbon class among their types falsify, and left conversions out; amended
2026-10-14, review fold: B-3, A-6, B-4).

**Outcome this plan commits to:** the arbiter un-SKIPs to PASS with its EXPECT
`42` re-derived from the program text (30 plus 12; §1.8), its body
byte-identical to the commented sketch (M-15, R6, R27); the impls of 31 `Core`
interface members across seven families (arithmetic, negation, bitwise and
shift, compound assignment, increment and decrement, comparison, indexing)
export as C++ operators — member operators when the impl's `Self` is the
exported class, non-member operators found by argument-dependent lookup in the
operand class's innermost enclosing namespace when it is not (D-OX-2, D-OX-3)
— with `!=` available for an impl that keeps `EqWith`'s default `NotEqual`,
move-only classes included (D-OX-5); an impl whose operand has no C++ form is
omitted and one whose result alone has none is declared deleted (D-OX-9);
Carbon's own operator expressions export nothing and never see an exported
operator as a C++ candidate, so every Carbon-only program compiles and lowers
as on trunk (D-OX-11, D-OX-21; M-9, M-10, M-20, M-22, M-23, M-26); six new
conformance programs, one per family plus the non-member form, PASS with
hand-derived EXPECTs (§1.8); four new goldens (three check, one lower; 47
splits) fill by autoupdate in two passes with no existing golden changing
(M-8, M-12); F-017 is minted with a new design page,
docs/design/interoperability/operators.md, and a dated amendment to
docs/design/interoperability/README.md (D-OX-13); the row moves MISSING →
PARTIAL, **expected, not of record** (D-OX-14), bounded by W-208 (conversions),
with W-202, W-204 to W-207 and W-209 to W-211 filed under it as limits and
W-203, a pre-existing defect the audit found, filed under the type-export row;
the header moves +1 PARTIAL, −1 MISSING (rev 1 said DONE and +1 DONE; amended
2026-10-14, review fold: A-6, B-4, B-3). Conformance: PASS +7, SKIP −1,
programs +6, bullets +1 PASS (from the floor of record 128 / 0 / 22 over 150,
48/56, to 135 / 0 / 21 over 156, 49/56, measured in the container on `v5`,
M-13): the bullet's programs all pass while the row stays PARTIAL, as OP-1's
Optional row did (fork/ORCHESTRATION.md, PR 56).

**Id allocation (recorded so no workstream collides):** re-scanned for rev 2
over the 76 refs `trunk`, `origin/trunk` and every local and `origin`
`claude/carbon-fork-0-1-*` branch with the commands below (M-18): the ledger
maximum is W-234 (SC-1 round 10, claude/carbon-fork-0-1-sc at 0d7ee5c19 and
444ccbafe; its `origin` copy, ae807c7e8, has W-232), and no ref other than this
branch allocates any of W-202..W-211 or F-017: they appear only as reservation
text, in trunk's and origin/trunk's fork/ORCHESTRATION.md, the stale 7mwfb7
copies of it, DD-1's fork/ORCHESTRATION.md, decision-log.md, designdocs/plan.md
and gap-analysis.md, and VA-1's fork/variadics/plan.md (amended 2026-10-14,
review fold: A-10, B-8). OP-2 holds W-196..W-201 and F-016; W-190 is unused
forever; W-169 is SC-1's reserve; W-170..W-179 and W-195 are OP-1's;
W-180..W-194 DD-1's; W-212..W-231 VA-1's (F-018 if VA-1 mints one); SC-1 holds
W-232 and reserves W-233..W-239 (W-233 and W-234 filed), and DD-1 reserves
W-240..W-244, unused (trunk 3eb7f36f0's stamp; amended 2026-10-14, fixer
re-scan). **OX-1 reserves W-202..W-211** and, at rev 2, uses all ten (§1.10:
W-210 and W-211, rev 1's spares, are filed by the folds of B-3 and A-3; amended
2026-10-14, review fold: B-3, A-3). A residue that the implementation reviews
find therefore needs a new block from the orchestrator, recorded in
fork/ORCHESTRATION.md before the id is written; it never takes an id from a
block reserved to another workstream. **OX-1 mints fork design id F-017**
(D-OX-13). An id counts as **taken** only by an allocation on a ref other than
this branch: a ledger entry `"id": "W-202"` to `"id": "W-211"` in that ref's
fork/inventory/work-items.json, or a decision-log heading naming F-017; a
mention in a plan, a stamp or a row is the reservation, not an allocation
(amended 2026-10-14, review fold: B-8). Immediately before the discharge commit
writes the ledger, the commands are re-run; if an id is taken by then, the
residues re-allocate from a block the orchestrator assigns (skipping every
reserved block), the design id from the next free F-id, and the landed notes say
so.

```bash
cd /home/user/carbon-ox
refs=$(git for-each-ref --format='%(refname:short)' \
  refs/heads/claude/carbon-fork-0-1-* refs/remotes/origin/claude/carbon-fork-0-1-* \
  refs/heads/trunk refs/remotes/origin/trunk)
# The ledger maximum.
for r in $refs; do
  git show "$r":fork/inventory/work-items.json 2>/dev/null \
    | grep -oE '"id": "W-[0-9]+"' | grep -oE '[0-9]+'
done | sort -n | tail -1
# Allocations of the reserved ids on any other ref: must print nothing.
for r in $refs; do
  case "$r" in *carbon-fork-0-1-ox) continue ;; esac
  git show "$r":fork/inventory/work-items.json 2>/dev/null \
    | grep -E '"id": "W-(20[2-9]|21[01])"' | sed "s#^#$r: #"
  git show "$r":fork/decision-log.md 2>/dev/null \
    | grep -E '^#+ .*F-017' | sed "s#^#$r: #"
done
# Mentions (the reservation text), for the record only.
for r in $refs; do git grep -l -E 'W-20[2-9]|W-21[01]|F-017' "$r" -- fork docs; done | sort -u
```

**Design authority** (each cited where used):

-   docs/design/README.md:3657-3693, "Operator overloading" under C++
    interoperability, provisional ("no design for this has been through the
    proposal process yet", :3659-3660): "Carbon types implementing an operator
    overload using an interface should get the corresponding operator overload
    in C++. So implementing `ModWith(U)` in Carbon for a type effectively
    implements `operator%` in C++ for that type" (:3666-3668); "However, there
    may be edge cases around implicit conversions or overload selection that
    don't map completely into Carbon" (:3672-3673); "they are matched according
    to which operation has the most similar semantics rather than using the
    same symbols. For example, the `^x` operation and `BitComplement` interface
    in Carbon corresponds to the `~x` operation and `operator~` function in C++"
    (:3676-3679); and, in the same paragraph, "Similarly, the `ImplicitAs(U)`
    Carbon interface corresponds to implicit conversions in C++, which can be
    written in multiple different ways" (:3679-3681), which puts conversions
    inside this section's mapping (D-OX-18; rev 1's quote stopped before it;
    amended 2026-10-14, review fold: A-6, B-4).
-   docs/design/interoperability/README.md:350, "## TODO: The operator
    interoperability model", an empty section: the accepted design does not
    decide the export mapping, hence F-017. :212-238, "Overload resolution",
    the OV-3 amendment (F-009): an exported overload set "appears to C++ as an
    ordinary C++ overload set", resolved "under C++'s rules", "a documented
    divergence"; D-OX-15 follows it.
-   The accepted proposal
    proposals/p006254-c-interop-toolchain-implementation-for-function-calls.md
    at :210-216, "Operator calls": "Carbon identifies the operator call, looks
    up potential C++ operator functions (both member and non-member), and uses
    Clang's overload resolution to select the best candidate". D-OX-11 and
    D-OX-21 keep exported Carbon impls out of that candidate set: an exported
    operator is not a C++ operator function but a Carbon impl seen from C++,
    which Carbon's impl lookup finds itself (amended 2026-10-14, review fold:
    B-11).
-   proposals/p000845-as-expressions.md:184-187: "The `As` interface provides
    the same functionality as single-argument `explicit` constructors and
    `explicit` conversion functions in C++, and can be used to expose those
    operations for interoperability purposes" (D-OX-18; amended 2026-10-14,
    review fold: B-4).
-   docs/design/expressions/README.md:326-358, the operator table (which
    operators exist and which are statements); arithmetic.md:214-292,
    bitwise.md:192-271, comparison_operators.md:248-271 (`EqWith`, its default
    `NotEqual` "`return not (self==u);`" at :260, "The expression `x!=y` calls
    `x.(EqWith(U).NotEqual)(y)`" at :271) and :345-380 (`OrderedWith` with
    `Compare`, which the prelude does not declare), indexing.md:46-97 (`IndexWith.At`
    and the `ref` forms), pointer_operators.md:21-36 (dereference is not an
    interface).
-   core/prelude/operators/arithmetic.carbon:24-91, bitwise.carbon:22-79,
    comparison.carbon:11-34 (`default fn NotEqual`, :14-16; "TODO: fn Compare",
    :24), index.carbon:7-10 (`At` only), deref.carbon:8-10 (`CppUnsafeDeref`,
    for imported C++ types).
-   proposals/p001178-rework-operator-interfaces.md:84-88: "The intent to
    provide a low-level interface for individual operators is directly motivated
    by the desire to provide strong interoperability with operators defined in
    C++"; p000702-comparison-operators.md:339-340: "Overriding `!=` separately
    from `==` is expected to be used to support floating-point NaN comparisons
    and for C++ interoperability";
    p001191-bitwise-and-shift-operators.md:140-143: "permitting separate
    overloading of each of the bitwise operators with custom return types. This
    should allow smooth interoperability with C++ overloaded operators".
-   docs/project/milestones.md:200, "Interfaces powering language syntax
    (operators, conversions, etc.)", a bullet of "Language and syntax support
    library components" under "#### Standard library components" (:190): it
    lists the prelude interfaces the 0.1 library must provide and says nothing
    about the scope of the interop bullet at :129-132, so it is no evidence
    either way on conversions (rev 1 cited it as :169, which is "Good
    equivalents for a range of existing C/C++ looping constructs", and as
    naming operators and conversions apart; amended 2026-10-14, review fold:
    A-6, B-4).
-   fork/decision-log.md, "OV-3: overload-set export, documented divergence"
    (:3517 on): F-009's sub-fork F-009i intended an unmappable set member to be
    omitted after its semantics TODO so that "the exportable subset stays
    callable", and **D-OV-18** recorded that this is false as landed: the TODO
    is an error, so a set with an unmappable member REJECTS the unit
    (:3595-3606). D-OX-9 follows D-OV-18 for a class C++ cannot export, departs
    from it for an operand that has no C++ form at all, and declares a deleted
    operator for a result that has none (rev 1 summarized F-009i as "omitted
    after its TODO" and left D-OV-18 out; amended 2026-10-14, review fold: B-2).
    Rulebook R30.
-   fork/inventory/work-items.json, W-007 (the contention-file discipline:
    additive edits, sequencing), W-118 (two set members with one C++
    signature), W-109 (write-through indexing), W-045 (import-direction
    rewrites).

V-3: no accepted proposal or leads' direction is contradicted. The direction of
the export is the design overview's (:3666-3668, provisional); its form —
member or non-member, the default `!=`, the void compound assignments, the
by-value `operator[]`, the omission of operand-unmappable impls, the deleted
declaration of result-unmappable ones, and Carbon's own lookup exporting
nothing — fills a silence of the accepted design (the README section is empty)
and is minted as fork design F-017 for after-the-fact veto (R29(a)). p006254's
"Operator calls" is kept: Carbon still resolves among the C++ operator
functions with Clang's overload resolution, and an exported Carbon impl is not
one of them (D-OX-11; amended 2026-10-14, review fold: B-11). Conversions are
not exported in 0.1 and the row stays PARTIAL for them (D-OX-18), so the
overview's `ImplicitAs` sentence is deferred, not contradicted (amended
2026-10-14, review fold: A-6, B-4). The divergences it documents (C++
conversions on operands, base-class member lookup, the impl function's own
signature, by-value operands; D-OX-15) are the overview's own caveat
(:3672-3673) and follow OV-3's precedent.

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Sub-feature table (verified in-tree at f67ab650d)

| # | Element | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Exported Carbon class | LANDED, lazy | toolchain/check/cpp/export.cpp:61-98 `ExportClassToCppInDeclContext` creates the `CXXRecordDecl` in the parent's mapped context and sets external lexical and visible storage (:93-95); `ExportClassToCpp` :277-311; the definition is produced by `CarbonExternalASTSource::CompleteType` (generate_ast.cpp:443-588: `final`, base, `ExportAllFieldsToCpp`, the destructor unless trivially copyable, virtual functions); every other member is produced on demand by name. |
| 2 | The name-lookup hook | LANDED; operator names unanswered | generate_ast.cpp:330-441 `FindExternalVisibleDeclsByName`: the switch on the name kind (:364-387) answers `Identifier` and `CXXConstructorName` and returns `false` for every other kind (`default:`, :385-386), operator names among them; a found Carbon entity maps through `MapInstIdToClangDeclOrType` (:202-293). |
| 3 | Function and method export | LANDED | export.cpp `FunctionInfo` :646-753 (`self_param` :682-686; `GetCppName` an identifier or a constructor name, :723-730); `BuildFunctionInfo` :774-825 exports the callee's parent scope first (:780-784), and an impl's scope is neither a namespace nor a class, so it reaches the TODO `non-class non-namespace name scope` (:157); `BuildCppToCarbonThunkDecl` :1096-1191 takes the C++ name as a parameter (:1098), creates a `CXXMethodDecl` in a record (:1148-1151) and a `FunctionDecl` elsewhere (:1167-1170), `inline`, always-inline and internal-linkage (:1185-1188); its type from `BuildCppToCarbonThunkFunctionType` :1028-1093 (`const` for `self`, `&` for `ref self`, :1080-1089); `BuildCppToCarbonThunkBody` :1209-1325 (`*this` as the first argument, :1246-1250; `return_storage` and an NRVO return, :1219-1243 and :1300-1320); `BuildCarbonToCarbonThunk` :1332-1399 generates `<name>__carbon_thunk` in the callee's parent scope (:1337-1342, :1371) and defines it with `BuildThunkDefinitionForExport` (check/thunk.cpp:385-440); `GetOrExportFunctionToCpp` :1606-1644 registers the export in `clang_decls` (:1632-1642). |
| 4 | Overload-set export (OV-3) | LANDED | generate_ast.cpp:256-289, the `OverloadSetValue` arm: each member through `GetOrExportFunctionToCpp`, delivered as one list; export.cpp:1378-1389, the `overload_index` hunk. |
| 5 | Thunk bodies | LANDED | C++ side: export.cpp:1209-1325. Carbon side: check/thunk.cpp:385-440 (`BuildThunkCall` :309-326, `PerformThunkCall` :270-302, which forms `self.(callee)` for a `self` parameter, :292-296). toolchain/check/cpp/thunk.cpp (`BuildCalleeCallExpr` :725, `BuildReturnValueStore` :810, `BuildThunkBody` :916, `BuildCatchingThunkBody` :958) is the import direction, Carbon calling C++ (§0.3 item 3). |
| 6 | Type mapping | LANDED | type_mapping.cpp:504 `MapToCppType`; :196-372 `TryMapClassType` (recognized types; otherwise `ExportClassToCpp`, :366); returns a null type, without a diagnostic, for an unmappable type (a tuple, for one); mapping a class type exports the class, which can diagnose (export.cpp:69, :141, :157, :266, :353), and completing it maps every field (:513; M-20). |
| 7 | Impl storage | LANDED; no index by `Self` | sem_ir/impl.h:18-104 (`self_id`, `interface`, `scope_id`, `witness_id`, `defined`); `ImplStore`'s lookup map is keyed by `(self constant, SpecificInterface)` (:249), so "every impl whose `Self` is `C`" needs a walk of `context.impls()`, as `CollectCandidateImplsForQuery` walks it (check/impl_lookup.cpp:699-726). An impl's functions are entries of its own name scope; a default member is not (M-3). |
| 8 | The import direction (the inverse table) | LANDED | check/cpp/operators.cpp:36-209 `GetClangOperatorKind` maps `Core` interface and member names to `OverloadedOperatorKind`; `FindClangOperator` :864-953 runs Clang's operator overload resolution and rejects a rewritten candidate as a TODO (:891-898). |
| 9 | Carbon's operator expressions ask C++ | LANDED | Two paths, both through `FindClangOperator`: check/operator.cpp:83 and :138 (`BuildUnaryOperator`, `BuildBinaryOperator`) call `LookupCppOperator` (operators.cpp:802-862) **before** Carbon's impl lookup whenever an operand is a C++ class type, and call the C++ operator if one is found; and check/impl_lookup.cpp:1327-1339, for a concrete query with a C++ type among the operands, has `LookupCppImpl` (cpp/impl_lookup.cpp:638-724) build a witness from a C++ operator (operators.cpp:741-800), which replaces any Carbon impl found. Each runs Clang's operator lookup on the operand types, the exported Carbon class among them (M-9, M-10; the first path amended 2026-10-14, review fold: B-1). |
| 10 | `Core` operator interfaces | LANDED (prelude) | core/prelude/operators/arithmetic.carbon:24-91, bitwise.carbon:22-79, comparison.carbon:11-34 (`default fn NotEqual`; no `Compare`), index.carbon:7-10 (`At` only); no dereference interface for Carbon types (deref.carbon:8-10 is `CppUnsafeDeref`). |
| 11 | `inline Cpp` | LANDED | generate_ast.cpp:59-86 and :616-700 (the code is parsed into the file's Clang AST against the exported declarations, in place); the default language mode is C++17 (M-6). |
| 12 | Arbiter | SKIP | fork/conformance/programs/interop/cpp_operator_export.carbon, EXPECT `42`, `return 1;` guard, the body commented out. |
| 13 | Docs | SILENT | docs/design/interoperability/README.md:350, an empty "TODO" section; docs/design/README.md:3657-3693, provisional. DD-1 (claude/carbon-fork-0-1-dd) fills the README section and says the export is not implemented (§6.2). |
| 14 | Clang's per-name lookup cache | LANDED (Clang) | clang/lib/AST/DeclBase.cpp:1921-1965 in /home/user/llvm-src: `DeclContext::lookupImpl` `try_emplace`s (:1952) an entry for the name, asks the external source only for a new entry or one with external declarations, and keeps the entry, empty or not, for every later lookup; upstream e476a2bd3 erases an empty entry the source did not fill, so that a later lookup asks again (D-OX-12, D-OX-21; amended 2026-10-14, review fold: A-4). |

### §0.2 Measurements

Setup, under the planner's scratch directory (`$X` below is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1`):
`$X/bin/relink.py` (the ST-1 and OP-2 relink recipe, generalized) compiles each
patched source with the `cxx`, `cflags` and per-object `extra` flags of
`/home/user/carbon-build/carbon-trunk/build.ninja`, the include root switched to
this worktree (whose headers equal the build's) and an overlay directory first
for a patched header, into `$X/tc/<variant>/obj/`, and relinks `bin/file_test`
and `bin/carbon-busybox` from the trunk build's objects with the patched objects
substituted, writing only under `$X/tc/<variant>/`. Each `install-<variant>` is
a `cp -a` of the trunk install with its busybox replaced. `bin/run.sh` compiles
one program with `--output-last-input-only` (R2), links and runs it;
`bin/mrun.sh` does the same for several units, each compiled last in turn as the
conformance runner does; `bin/ft.sh` runs a file_test in test mode over the full
manifest from this worktree with the trunk runfiles; `bin/fill.sh` previews a
new golden by substituting it for an existing manifest entry in a scratch mirror
(`interop/cpp/class/export/static.carbon` holds check `operator.carbon`,
`layout.carbon` holds `operator_ast.carbon`, lower `mangle.carbon` holds lower
`operator.carbon`), then runs two autoupdate passes and a test-mode pass.
Variants: `v1` (member operators only), `v2` (plus the default `!=` and the
Carbon-side guard), `v3` (plus non-member operators), `v4` (plus the silent
omission of unmappable impls: rev 1's spec), and the mutants of M-14.
`XDG_CACHE_HOME` was a directory under `$X` for every `carbon` run.

Rev 2's setup, under `$F` (amended 2026-10-14, review fold: all): `$F/bin/`
holds copies of the planner's scripts, with `relink.py` taught to take a
precompiled object (`<obj>=<path>.o`) and a `TARGETS` list; `$F/src/v5/` holds
the five patched sources and `$F/inc/` the two patched headers (export.h, and
check/cpp/context.h, whose `CppContext` gains one trailing `bool`, constructed
only in generate_ast.cpp, which is recompiled; the destructor of the trunk
object needs no change for a trivially destructible member). `v5` is §2.1 to
§2.4 (`$F/tc/v5f`, installed as `$F/install-v5`; an earlier link, `$F/tc/v5`,
differed from it in two comments only and measured identically wherever both
ran). `bin/probe.sh <install> <cache> <out> <programs...>` compiles each
program (with the compile arguments of a first-line `// ARGS:` comment), links
and runs it when it defines `Run`, and prints one line per program;
`bin/fill2.sh <file_test> <mirror> <log> [passes]` previews §2.5's four
goldens as the planner's `fill.sh` did, with
`interop/cpp/class/export/base.carbon` holding the fourth,
`operator_cxx20.carbon`, and a snapshot after each autoupdate pass; the mutants
M1 to M3 of M-14 are `v5`'s export.cpp with one edit each, linked with `v5`'s
other two objects (`$F/bin/mutants.sh`). `XDG_CACHE_HOME` was a directory under
`$F/cache/` for every `carbon` run.

**M-1. The arbiter's body fails on trunk and on the nightly, for one reason.**
The SKIP body, uncommented (`$X/probes/p1/op_export.carbon`), compiled with the
trunk install and with the nightly 2026.10.12
(`0.0.0-0.nightly.2026.10.12+62f1cc6`): both exit 1 with the single diagnostic

```text
op_export.carbon:20:13: error: invalid operands to binary expression ('Carbon::Meters' and 'Carbon::Meters')
   20 |   return (a + b).value;
      |           ~ ^ ~
```

What the `inline Cpp` block sees, from `carbon compile` with `--phase=check` and
`--dump-cpp-ast` on the same program with `a+b` replaced by `a.value+b.value`
(trunk): `namespace Carbon` holds `class Meters definition` with
`<undeserialized declarations>`, `DefinitionData ... aggregate standard_layout
trivially_copyable pod trivial`, a `FinalAttr`, `FieldDecl ... value 'int'
mutable`, `CXXMethodDecl ... Make 'Carbon::Meters (int)' static inline
internal-linkage` whose body calls `Make__carbon_thunk 'void (const int &, const
Carbon::Meters &)'` and returns `return_storage` by NRVO, and the implicit
trivial destructor. There is no operator declaration of any kind, and the impl's
`Op` has no C++ view: it is not a member of the class's scope, and operator
names are never answered (§0.1 rows 2 and 3). The record is complete and its
members appear on demand, so a C++ operator lookup into it is a lookup Carbon
can answer. On `v5` the same program prints `42` (M-13).

**M-2. Every path an exported Carbon class reaches today, and where an
operator would enter.** Read end to end (§0.1 rows 1 to 6): a class becomes a
record on first use by name or by type mapping; its fields are exported as a
group at completion or layout; a method, class function, constructor-named
function, overload set, variable or nested type is exported when Clang asks the
class or namespace for that identifier; a virtual function is declared at
completion. Not exported: anything without an identifier name (operators,
conversions), a generic member function (TODO, export.cpp:1596-1598), a
specific of a generic class's members (TODO :68-71 and the generic-class
destructor gap, generate_ast.cpp:506-518), and impls, whose functions live in
impl scopes that `ExportNameScopeToCpp` cannot map (:151-159). The C++
declaration of an exported function is built by `BuildCppToCarbonThunkDecl`
under any `DeclarationName` it is given, and its body by
`BuildCppToCarbonThunk`; both are static functions of export.cpp that take a
`FunctionInfo`, so an impl's `Op` can be exported under `operator+` by new code
that builds the `FunctionInfo` itself, without `BuildFunctionInfo`'s scope
export (M-4).

**M-3. Where an operator impl lives in SemIR.** `carbon compile` with
`--phase=check` and `--dump-sem-ir` of a class `Money` with one `i32` field and
`impl Money as Core.EqWith(Money)` declaring only `Equal`
(`$X/probes/eq/eq.sem`): the impl block holds
`%Money.as.EqWith.impl.Equal.decl`, the witness table is `impl_witness_table
(%Money.as.EqWith.impl.Equal.decl, constants.%EqWith.WithSelf.NotEqual.3da)` —
the default `NotEqual` is the interface's own function with the impl's specific,
not a function of the impl — and the impl scope's members are `.Money =
<poisoned>` and `.Equal = ...`. So a lookup of `NotEqual` in the impl scope
finds nothing, and a lookup of a name the impl's checking poisoned finds an
entry that is not `is_found()`: `v1`, which called `target_inst_id()` on such an
entry, failed `CHECK failure at toolchain/sem_ir/name_scope.h:83: is_found()` on
`a!=b` (the fix is `GetImplMemberFunctionId`'s `is_found()` test, §2.1). The
`Core` interfaces are recognized by name: `CoreIdentifier` names every operator
interface and member (check/core_identifier.def:19-97), while
`SemIR::CoreInterface` (sem_ir/core_interface_kind.def) lacks the bitwise
interfaces, `BitComplement` and `IndexWith`, so `interface.core_interface`
cannot classify them; an interface is a `Core` one when
`IsCorePackage(interface.parent_scope_id)` holds, as `GetCoreInterface` tests
(check/custom_witness.cpp:1440-1449).

**M-4. How Clang asks for an operator, and the form that answers it.** `v1`
(member operators only) failed M-3's CHECK inside the hook, and its stack is the
lookup path: `ExportOperatorsToCpp` ←
`CarbonExternalASTSource::FindExternalVisibleDeclsByName` ←
`DeclContext::lookupImpl` ← `LookupDirect` ← `Sema::LookupQualifiedName` ←
`Sema::AddMemberOperatorCandidates` ← `Sema::LookupOverloadedBinOp` ←
`Sema::CreateOverloadedBinOp`, the record being the left operand's class. With
`v3`, the same hook also receives `namespace Carbon` with the operator name from
argument-dependent lookup on an exported operand (M-7's `3*m`). Clang caches
each answer per context and name: `DeclContext::lookupImpl` returns a stored
entry without asking again once it holds no external declarations
(clang/lib/AST/DeclBase.cpp:1951-1954 in /home/user/llvm-src), so each class and
namespace is asked once per operator name (§0.1 row 14). The declarations that
answer are a `CXXMethodDecl` named `DeclarationNames.getCXXOperatorName(kind)`
in the record (the member form) and a `FunctionDecl` of that name in the
namespace (the non-member form); `v1` exported the arbiter's `operator+` as
`CXXMethodDecl ... used operator+ 'Carbon::Meters (Carbon::Meters) const'
inline internal-linkage` whose body calls `Op__carbon_thunk 'void (const
Carbon::Meters &, const Carbon::Meters &, const Carbon::Meters &)'`, and the
program printed `42` (`$X/probes/p1/v1`). The generated Carbon thunk lowers as
`_COp__carbon_thunk.Meters.Main:AddWith.b69bc498d15e4c3c.Core`, mangled by the
impl's `Self` and the interface's specific (sem_ir/mangler.cpp:92-158), so two
impls of one interface never share a thunk symbol.

**M-5. How values cross.** As for an exported method (export.cpp:1006-1024,
:1209-1325): a value parameter of class type is a by-value C++ parameter
(`operator+(Carbon::Money) const`; a trivially copyable class is passed in a
register, `i32 %.coerce`, lower fill M-12), passed to the Carbon thunk by
`const&`; the result is constructed in the C++ operator's `return_storage` by
the Carbon thunk through a reference parameter and returned by NRVO; a `bool`
result is loaded (LValueToRValue, :1310-1315). A class with a user `Destroy`
(`$X/probes/edge/e9_nontrivial.carbon`: `a+b` on two `Tracked`, then the
destroy count) prints `42 4` with the operator and `42 4` with the equivalent
exported method `a.Plus(b)` on trunk (`e9b_method.carbon`): the operator
inherits the method's value passing exactly, including the by-value
parameter's copy and its destruction (re-run on `v5`: `42 4` and `42 4`). A
by-value parameter also means that C++ copies an lvalue operand, which a class
C++ cannot copy rejects where Carbon accepts it (M-25, D-OX-15; amended
2026-10-14, review fold: A-7).

**M-6. The `inline Cpp` dialect, and what it does to `!=`.** An `inline Cpp`
function returning `__cplusplus` prints `201703` on trunk and on `v5`
(`$X/probes/std/std.carbon`): C++17, which never rewrites `a!=b` as `!(a==b)`.
`v1`, exporting only declared members, rejected `(a!=b)` for an impl without
`NotEqual` with `invalid operands to binary expression ('Carbon::Money' and
'Carbon::Money')` (`$X/probes/fam/fam.compile.log`). With `v2` onwards the
default `operator!=` is declared, and `e7_cxx20.carbon` (only `impl Money as
EqWith(i32)`) rejects `5==m` with `invalid operands to binary expression ('int'
and 'Carbon::Money')` under the default dialect and under
`--clang-arg=-std=c++20` alike, while `m==5` compiles: with `operator!=`
declared beside `operator==`, C++20's reversed `==` candidate is not formed.
At rev 2 this is pinned under C++20, not only measured: the new golden
operator_cxx20.carbon, with `EXTRA-ARGS: --clang-arg=-std=c++20`, rejects
`5 == m` for a member `EqWith(i32)`, `m == 5` for a non-member
`i32 as EqWith(Money)` and `5 > m` for an `OrderedWith(i32)`, each with
`invalid operands`, and compiles a move-only class's `==` and `!=` (M-12, M-21;
rev 1's only pin, `fail_reversed_equality`, runs in C++17, where no reversed
candidate exists; amended 2026-10-14, review fold: A-2).

**M-7. The prototype across every family (re-run on `v5`).**
`$X/probes/fam/fam.carbon` (member operators: `Money` with `AddWith(Money)`,
`SubWith(Money)`, `MulWith(i32)`, `DivWith(i32)`, `ModWith(i32)`, `Negate`, five
compound assignments, `Inc`, `Dec`, `EqWith` with the default `NotEqual`,
`OrderedWith`; `Bits` (a `u8`) with the bitwise, complement, shift and bitwise
compound impls; `Tri` with `IndexWith(i32)`; `Unknowable` with a declared
`NotEqual`) prints `9500450,21002331,-42,2,101110,10,8140843,300115,789,0` on
`v4` and `v5`, each value hand-derived in the probe's comments (950 and 450;
2100, 233 and 1; -42; the compound chain ending at 2; the comparison digits 1 0
1 1 1 0 and 1 0; 8, 14, 6 and 243; 30, 1 and 15; 7 8 9; 0 0 for an unknown
value). `$X/probes/nm/nm.carbon` (non-member operators: `impl i32 as
MulWith(Money)` with a `+ 1` marker, `i32 as EqWith(Money)` with the default
`NotEqual`, `i32 as OrderedWith(Money)`, `i32 as SubAssignWith(Money)`, `Cpp.Foo
as AddWith(Money)`) prints `30 31 111110 42 42 33`, the `31` showing that `3*m`
reached the `i32` impl and not `m*3`'s. Both print the same under
`--clang-arg=-std=c++20` (`$F/probes/P/fam_cxx20.carbon`, `nm_cxx20.carbon`).
The AST dump of `fam.carbon` (`v2`) lists 33 operator declarations of the shapes
§1.1 tabulates, among them `operator+= 'void (Carbon::Money) &'`, `operator++
'void () &'`, `operator~ 'Carbon::Bits () const'`, `operator[] 'int (int)
const'`; `nm.carbon`'s lists `FunctionDecl ... operator* 'Carbon::Money (int,
Carbon::Money)'` and `operator-= 'void (int &, Carbon::Money)'` in `namespace
Carbon` (`v3`). Probes of single features, re-run on `v5` (`$F/probes/P/`): a
class in a Carbon namespace with an `extend impl` in its body (`e5_namespace`)
prints `42` through `Carbon::Units::Money`; a derived class whose base has the
impl (`e11_base`) prints `42` (C++ member lookup reaches the base; §1.7); a
non-member operator whose operand is a nested class prints `42` (M-24).

**M-8. Golden blast radius: none.** file_test in test mode over the whole
manifest (1942 files) from this worktree: trunk 1942 passed; `v1`, `v3`,
`v3`-final and `v4`, 1942 passed each (`$X/ft-*.log`); `v5`, 1942 passed
(`$F/ft-v5f.log`, 76.6 s wall time; and `$F/ft-v5.log` for the first link),
`.failed` lists empty. No existing golden applies a C++ operator to an exported
Carbon class, and none evaluates a Carbon operator whose operands mix a C++
type with a Carbon class that has an operator impl (the only paths §2 reaches),
so no existing golden gains or loses a line; §4 lists no refills. M-8 shows
that no existing golden moves; it does not cover the shapes of M-20 to M-26,
which the goldens did not contain and which §2.5's new splits now pin (amended
2026-10-14, review fold: B-1).

**M-9. Carbon-only code, and why rev 1's fix was not enough.** Carbon's own
operator expressions ask C++ whenever an operand is a C++ type (§0.1 row 9),
and Clang's operator lookup then asks the exported Carbon class (M-4). With
`v3`, which exported an unmappable impl after its per-function TODO (the
landed OV-3 behavior, D-OV-18), `$X/probes/side/side2.carbon` — `impl Money as
Core.AddWith(Cpp.Foo) where .Result = (i32, i32)` and the Carbon-only function
`CarbonSide`, which returns `(m+f).0` — fails with `side2.carbon:7:3: error:
semantics TODO: 'failed to map Carbon return type to C++ type'`; trunk accepts
it. `v4` omitted an impl whose signature mapped to null before building
anything (`IsOperatorSignatureMappable`) and accepted `side2.carbon`; but that
predicate mapped every type with `MapToCppType`, which exports a class and can
diagnose, and `v4` still exported every operator of the class during Carbon's
own lookup, so five more Carbon-only shapes that trunk accepts failed on `v4`
(M-20, M-22, M-23). `v5` exports nothing during Carbon's own lookup and caches
no answer for it (D-OX-21), so no impl's signature is mapped for a Carbon-only
expression at all: `side2.carbon` and every shape of M-20, M-22 and M-23 compile
on `v5` as on trunk, pinned by the `carbon_side_*` splits (M-12) (rev 1 said the
silent omission was the fix and that R-1's third shape would be a BLOCKER, which
review A found; amended 2026-10-14, review fold: A-1, B-1).

**M-10. Carbon operator expressions keep calling the impl.** With `v1`,
`$X/probes/mixed/mixed.carbon`'s Carbon function `m+f` (`impl Money as
AddWith(Cpp.Foo)`) lowered to `call void
@_ZNK6Carbon5MoneyplE3Foo.carbon_thunk.__`: Carbon's lookup found the exported
`Money::operator+(Foo)` as the best C++ candidate and called the impl through
the C++ operator and two thunks (§0.1 row 9 replaces the Carbon witness with a
C++ one). `v2` to `v4` added a guard that declined such a best viable function
after overload resolution, in the `OR_Success` arm only; it missed an ambiguous
result (M-22) and the synthesized non-member `!=`, which it did not recognize
(M-26). `v5` replaces it (D-OX-11): Carbon's lookup exports nothing (D-OX-21),
and an operator C++ code exported earlier is marked non-viable before
`BestViableFunction`, recognized by its `clang_decls` registration, the
default `!=` included; so every `OverloadingResult` is the one Clang gives
without exported operators. `mixed.carbon` prints `42 42` on `v5`; the lower
splits `carbon_side_cpp_operand` (`_CCarbonSide.Main` calls
`_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core` directly, after `AddInCpp`
exported `Money::operator+(Foo)`) and `carbon_side_default_not_equal` (M-26) pin
it. Rev 1's accepted side effect, the unused
`_COp__carbon_thunk.Money.Main:AddWith.1ea11ae296c4d4df.Core` that the
Carbon-only `$X/probes/side/side.carbon` defined (§7 R-5), is gone: the
LLVM IR of `side.carbon` (`--phase=lower --dump-llvm-ir`) has 2 definitions
and no `carbon_thunk` on trunk and on `v5`, and 3, one a thunk, on `v4`
(`$F/probes/R5/`; amended 2026-10-14, review fold: A-3, A-4, B-1).

**M-11. The edges, each measured on `v4` and re-run on `v5` unless named.** (a)
A generic impl, `impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)`
(`e1_generic`): C++ `m*3` fails `invalid operands to binary expression
('Carbon::Money' and 'int')`; Carbon's `m*3` compiles; with a concrete `impl
Money as MulWith(i64)` beside it, C++ converts and calls that one (M-28). (b) An
impl declared after the `inline Cpp` block that uses it (`e3_after`): `invalid
operands`, as C++ itself would reject a use before the declaration. (c) A
second impl of an operator declared after C++ code looked that operator up
(`e4_cache`): the second block's `m+40` fails with `invalid operands ...
('Carbon::Money' and 'int')` and a note naming only the first impl's candidate
(M-4's caching); a Carbon expression in between does not cause this on `v5`
(M-23). (d) A class imported from another library (`e6`, two units through
`bin/mrun.sh`): C++ `m+m` fails `invalid operands`, because only
`context.impls()` is walked and the library's impls are not imported (W-204);
and the class itself is exported wrongly on trunk and on the nightly — `e6b`
(`.cents` of an imported class) fails `no member named 'cents' in
'Carbon::Money'`, and `e6c` (an exported method `Plus` returning the imported
class by value, then `Get()`) links, runs and prints `-1265344497` on trunk and
`-1536643875` on the nightly where 42 is right: the AST dump shows `class Money
definition ... empty aggregate`, no `FieldDecl`, so a 4-byte Carbon result is
written into a 1-byte C++ object (W-203, filed under the type-export row; an
upstream defect; not re-run). (e) Two impls whose operands map to one C++ type
(`e12_samesig`, `AddWith(i64)` and `AddWith(Cpp.long)`): Carbon itself rejects
the pair (`found non-final impl with the same type structure as another
non-final impl`), and C++ reports `use of overloaded operator '+' is
ambiguous`, the W-118 shape (W-207). (f) C++'s operand conversions
(`e13_conv`): C++ `m*k` with `long k = 3` calls the `MulWith(i32)` impl and
prints `42`, while Carbon's `m*k` with `k: i64` fails `cannot access member of
interface 'Core.MulWith(i64)' in type 'Money' that does not implement that
interface` (`e13b`) — the documented divergence (§1.7), now pinned on both
sides (`arithmetic` and `fail_conversion_carbon_side`; amended 2026-10-14,
review fold: A-9, B-10).

**M-12. The new goldens fill, and fail without the feature (re-measured at
rev 2).** `bin/fill2.sh` with `v5`'s file_test on the four new sources (§2.5):
three autoupdate passes, then test mode, 4 passed. Pass 2 changes **all four**
files (22, 24, 6 and 32 diff lines: the `[[@LINE...]]` offsets of `CHECK:STDERR`
source snippets in the two check goldens with diagnostics, the AST golden's
`<line:N:...>` positions, and the lower golden's debug-location lines), and
pass 3 equals pass 2, so the fill needs two passes (R26) and a third is the
fixpoint check (rev 1 said pass 2 changed only the AST golden; review A
measured both check goldens changing; amended 2026-10-14, review fold: A-10).
CHECK lines written: 91 (check `operator.carbon`, 1062 lines; all
`CHECK:STDERR` of the 14 `fail_` splits), 183 (`operator_ast.carbon`, 243
lines), 15 (`operator_cxx20.carbon`, 130 lines), 1079 (lower `operator.carbon`,
1255 lines, with `--clang-arg=-fno-exceptions`). Every `fail_` split fails for
its intended reason (§4), and no other split has a diagnostic. The same sources
under trunk's file_test (`$F/fill-trunk.au1`): 23 positive splits fail (`split
... failed; if failure is expected, add the fail_ prefix`), 22 names because
`non_member` is a split of both the check and the lower golden: arithmetic,
signature_from_impl_function, compound_assignment, comparison,
move_only_not_equal, bitwise, index, non_member (check), non_member_nested,
namespace, base_class, unmappable_impl, deleted_result_unselected,
cpp_side_unrelated_impl, carbon_side_then_cpp, operator (the AST golden),
move_only_equality, member, default_not_equal, non_member (lower),
carbon_side_cpp_operand, carbon_side_default_not_equal and generic_impl_hidden
(rev 1 listed 13 names for 14 failures; amended 2026-10-14, review fold: B-6).
The six Carbon-only regression guards — `carbon_side_unmappable`,
`carbon_side_unexportable_class`, `carbon_side_generic_class`,
`carbon_side_unrelated_impl`, `carbon_side_candidates` and
`carbon_side_user_cpp_operator` — and the library split `money_lib` pass on
trunk, as they must.
Under `v4`'s file_test (`$F/fill-v4.au1`), the file aborts at the move-only
splits (`CHECK failure at .../export.cpp:2152: equal_call.isUsable()`, M-21);
without them (`$F/gen-nomove/`), `carbon_side_unexportable_class`,
`carbon_side_generic_class`, `carbon_side_unrelated_impl`,
`carbon_side_candidates`, `carbon_side_user_cpp_operator`,
`carbon_side_then_cpp`, `cpp_side_unrelated_impl` and `non_member_nested` fail,
and `fail_deleted_result` compiles: each new guard catches the defect it pins.

**M-13. Conformance (re-run on `v5`).** Trunk, the 150 programs of record: 128
PASS / 0 FAIL / 22 SKIP, 48/56 bullets (`$X/conf-trunk`; the floor of record).
`v4`, the same programs: 128 / 0 / 22, 48/56 (`$X/conf-v4-current`). `v5`, the
program tree with §2.6 applied (`$F/progs-full`: the arbiter un-SKIPped, six new
programs, rev 2's compare and nonmember programs and headers): 135 PASS / 0 FAIL
/ 21 SKIP over 156, 49/56 bullets, the row's bullet PASS with 7 programs
(`$F/conf-full-v5`). Trunk on the seven: 7 COMPILE-FAIL (`$F/conf-progs-trunk`).
`runner.py --self-test --programs $F/progs-full`: 156 programs parsed, 56
bullets, one error, the stale README program table that commit 5 regenerates
(§3).

**M-14. The programs are not vacuous (re-run on `v5`, three mutants).** Each
mutant is `v5`'s export.cpp with one edit, relinked with `v5`'s other objects
and run over the seven programs (`$F/conf-progs-m1` to `-m3`). M1 swaps the
`AddWith` and `SubWith` rows (`+` calls `SubWith`): cpp_operator_export
COMPILE-FAIL, cpp_operator_export_arithmetic OUTPUT-MISMATCH (prints
`450,950,2100,233,1,-700`), cpp_operator_export_nonmember COMPILE-FAIL. M2 drops
the `!` from the default `!=`: cpp_operator_export_compare OUTPUT-MISMATCH
(`10,10,100,110,1,11,0`: the `!=` line `10` for `101`),
cpp_operator_export_nonmember OUTPUT-MISMATCH (its `!=` line `10` for `101`).
M3 swaps the `EqWith.NotEqual` and `OrderedWith.Less` rows (review A's third
mutant): cpp_operator_export_compare COMPILE-FAIL (`Unknowable`'s `!=` finds no
`Less`), cpp_operator_export_nonmember OUTPUT-MISMATCH (its `<` line `0` for
`100`). The other programs pass under each mutant because they do not use the
mutated rows. With rev 2's encoding, 100·(x op y) + 10·(x op x) + (y op x),
every within-family swap of the comparison operators changes a printed value
(§1.8; rev 1's true/false pairs printed `10` for several swaps; amended
2026-10-14, review fold: A-8).

**M-15. The un-SKIP is the sketch.** The arbiter's commented body, uncommented,
diffed against §2.6's program from `import Core` to `fn Run`: identical, the C++
comment line included; `Run`'s body is the sketch's "Intended body" verbatim
(two lines). No mechanical repair is needed (R6), and the spelling is the
sketch's (R27).

**M-16. Collisions, by `git apply --check` of the §2.1 to §2.4 diff (re-run on
`v5`, heads of 2026-10-14).** On the five files at claude/carbon-fork-0-1-st
(21307851a, PR 55): applies, two hunks at offset 5 (its 5-line null check at
export.cpp:293-300). At claude/carbon-fork-0-1-sc (0d7ee5c19),
claude/carbon-fork-0-1-op (379f20f67, PR 56), claude/carbon-fork-0-1-op2
(628273444, PR 57), claude/carbon-fork-0-1-dd (fcee90d9b),
claude/carbon-fork-0-1-va (aced92197), the PR 51 to 54 branches and trunk
44761146d: applies with no offset (`$F/applytest/`). At upstream/trunk
66a250ad9 (in /home/user/carbon-lang): export.cpp and export.h apply at
offsets; context.h's hunk does not (upstream's `CppContext` lacks the fork's
`boundary_write_decl` members), nor do generate_ast.cpp's include hunk
(upstream's e476a2bd3 already includes `clang/AST/DeclContextInternals.h`, so
the fork's line is dropped there) and operators.cpp's (the fork's include block
differs): three context refreshes at the next advance. No branch touches
check/cpp/context.h, generate_ast.cpp or operators.cpp, and VA-1's plan names
none of the five files (§6.2). The other files each branch touches are in §6.2
(heads refreshed: rev 1 named SC-1 ee1f905b0, OP-2 c396efeae and DD-1
e27b917c8; amended 2026-10-14, review fold: A-10, B-8).

**M-17. Upstream has not started operator export.** In /home/user/carbon-lang,
`git merge-base 0bdce60a5 upstream/trunk` is c1e83b0b7, the true upstream cut;
`git log c1e83b0b7..upstream/trunk` lists 50 commits (re-run at rev 2: the
same), four under toolchain/check/cpp: e476a2bd3 (exporting names after a lookup
failure: it restructures `FindExternalVisibleDeclsByName` and stops caching
negative lookups), 62f1cc6a3 (`GenericClassType` renamed
`ParameterizedClassType`), 947c1eb52 (`Core.Array`), ae5d1efd1
(`CalleeFunctionInfo` renamed); and 4ab46d448 renames entities for
`-share-cpp-ast`. `git grep CXXOperatorName upstream/trunk --
toolchain/check/cpp` finds only the import direction (import.cpp:1880,
thunk.cpp:400, impl_lookup.cpp:188). OX-1 uses none of the renamed entities; its
names (`ExportOperatorsToCpp`, `ExportNonMemberOperatorsToCpp`,
`IsExportedCarbonOperator`, `in_carbon_operator_lookup`) have no upstream
counterpart to align with; e476a2bd3's change is the one to re-integrate at the
next advance, and its negative-lookup erasure is the same mechanism D-OX-21
uses (§6.3).

**M-18. Ids (re-run at rev 2).** The id-allocation commands of the head, over
76 refs: ledger maximum W-234 (claude/carbon-fork-0-1-sc at 0d7ee5c19); no
allocation of W-202..W-211 or F-017 on any other ref; the mentions are the
reservation text listed in the head; F-016 is OP-2's (rev 1 measured W-232;
amended 2026-10-14, review fold: A-10, B-8).

**M-19. Cost, per family (`v5`, export.cpp line spans with their comments).**
Shared by every family: the entry type and table header (14 + 4 lines),
`IsOperatorImplOfKind` (22), `IsUnmappableWithoutExport` (25), the export kind
and `ClassifyOperatorExport` (9 + 23), `GetImplMemberFunctionId` (25),
`GetExportedOperatorSignature` and `RegisterExportedOperator` (11 + 11),
`BuildCppOperatorDecl` (82), `ExportImplFunctionAsCppOperator` (56),
`ExportImplOperators` (47), `ExportOperatorsToCpp` (29),
`IsExportedCarbonOperator` (17), the generate_ast.cpp arm (39 with its include),
the operators.cpp suppression and filter (21 with two includes) and the
context.h member (11): about 440 lines. Per family, rows of the table:
arithmetic 5, negation 1, bitwise and shift 6, compound assignment 10,
increment and decrement 2, comparison 6 plus `BuildDefaultNotEqualOperator`
(116), and one row for indexing. The non-member form: `GetCarbonRecordClassType`
(20), `ExportNonMemberOperatorsToCpp` (38) and the 3-line condition in
`BuildCppToCarbonThunkBody`. Test cost: §4 (splits) and §5 (programs). Compile
cost: one walk of `context.impls()` per class (or namespace) and operator name,
the first time C++ code looks that name up there (M-4), none for a class whose
operators C++ never uses, and none for Carbon's own operator expressions
(D-OX-21), plus one `clang_decls` lookup per C++ candidate of each Carbon
operator expression with a C++ operand (the filter).

**M-20. Review A's side shapes, on trunk, `v4` and `v5` (A-1).** Review A's
probes (`$F/probes/A-side/`), each with `impl Money as Core.AddWith(Cpp.Foo)`
or a sibling: (a) `.Result = Holder`, where `class Holder { var t: (i32, i32);
}`; (b) a further `impl Money as AddWith(Holder)`; (c) `.Result =
Wrapper((i32, i32))`; (d) `.Result = Vec(3)` with `class Vec(N: i32)`; (f) an
unrelated `impl Vec(3) as Core.ImplicitAs(Money)` — each with a Carbon-only
`m + f`. Trunk and `v5` compile all five; `v4` rejects each with a semantics
TODO (`failed to map Carbon type to C++`, `failed to map specific type arg to
C++`, `binding maps to a non-type template parameter`). (g), the same
`ImplicitAs` impl beside a valid C++ `m + m`: trunk `invalid operands` (no
export), `v4` the TODO, `v5` compiles (the walks select impls by interface and
`Self` from SemIR before any type is mapped). (e), a valid C++ `m + m` beside
`impl Money as AddWith(Holder)`: trunk `invalid operands`, `v4` and `v5`
``semantics TODO: `failed to map Carbon type to C++` `` at Holder's tuple field.
That diagnostic is the class's own, as on trunk: `v_trunk_holder_fn1.carbon`,
with no operator, has C++ call an exported `fn Take(h: Holder)` with a `Money`,
and trunk and `v5` both report the same TODO at the same field, because C++
overload resolution completes `Holder` to rank the candidate; so does `m + m`
on `v5`, whose `AddWith(Holder)` candidate it must rank. It is the landed
OV-3 behavior for a member C++ cannot export (D-OV-18), kept by D-OX-9 and
pinned by `fail_todo_unexportable_operand_class` (amended 2026-10-14, review
fold: A-1).

**M-21. The default `!=` of a move-only class (A-2).** Review A's
`n1_nocopy_default_ne.carbon` (`class Money { var n: Cpp.NoCopy; }`, `NoCopy`
with a deleted copy and a defaulted move constructor, `EqWith(Money)` with
`Equal` only, C++ `std::move(a) != std::move(b)`) aborts `v4` with `CHECK
failure at .../export.cpp:2152: equal_call.isUsable()`, and `n2` (`==` only)
aborts it under `-std=c++20`, where Clang looks `operator!=` up for every `==`.
On `v5` both compile under both dialects (`$F/probes/V/n1_cxx20.carbon`,
`n2_cxx20.carbon`), and `v_ne_nocopy_run.carbon`, which compares
`Carbon::Money{NoCopy(1)}` with `Carbon::Money{NoCopy(2)}` and two equal ones,
prints `10 1` (`!=` then `==`, each 10·(1 vs 2) + (3 vs 3)) under C++17 and
C++20; trunk rejects all four with `invalid operands`. `v5` passes each
by-value parameter on to `operator==` as an xvalue, as a C++ implicit move
does, and builds the body under a `Sema::SFINAETrap`, declaring no `!=` and
diagnosing nothing if the call is still invalid. Pinned by `move_only_not_equal`
(C++17) and `move_only_equality` (C++20) (amended 2026-10-14, review fold: A-2).

**M-22. Carbon-side candidates and hand-written C++ operators (A-3, B-1).**
Review B's `gen.carbon` (concrete `AddWith(i32)` and `AddWith(i64)`, a generic
`AddWith(T)`, and a C++ `Foo` converting to both `int` and `long`),
`enum.carbon` (a C++ enum with `AddWith(i64)`, `AddWith(u32)` and the generic
impl) and `amb.carbon` (the `Foo` impl with a tuple result) print `3` on trunk
and `v5`; `v4` rejects all three with `use of overloaded operator '+' is
ambiguous`, because its guard acted only on `OR_Success`. Review A's
`u2_user_cpp_operator_carbon_side.carbon` (a hand-written C++
`operator+(const Carbon::Money&, const Foo&)` beside `impl Money as
AddWith(Cpp.Foo)`, used from Carbon) prints `1042` on trunk and `v5` and is
ambiguous on `v4`. Review B's `userop.carbon` (a hand-written C++
`operator+(const Carbon::Money&, long)` and a C++ enum operand) is rejected on
trunk and `v5` with ``cannot implicitly convert expression of type `Color` to
`i64` `` (Carbon selects the hand-written operator, then cannot convert), and on
`v4` with ``cannot access member of interface `Core.AddWith(Cpp.Color)` ``: the
exported `operator+(int)` outranked the hand-written one and the guard
discarded it, so `v4` changed which C++ function Carbon would call.
`v_member_after_cpp.carbon` (C++ code exports `Money::operator+(Foo)` first, and
a hand-written `operator+(const Carbon::Money&, long)` exists) prints `42 42` on
`v5`. C++-only code is a different matter: review A's
`u1_user_cpp_operator.carbon`, whose hand-written `operator+(const
Carbon::Money&, const Carbon::Money&)` duplicates `impl Money as
AddWith(Money)`, prints `1042` on trunk and is ambiguous on `v4` and `v5`,
because C++ now sees two equally good candidates; that is filed as W-211 and
pinned by `fail_user_cpp_operator_ambiguous` (amended 2026-10-14, review fold:
A-3, B-1).

**M-23. A Carbon-only expression and later C++ lookups (A-4).** Review A's
`o1_carbon_side_poisons.carbon` and `o2_without_carbon_side.carbon` differ by
one Carbon function, `CarbonSide`, whose `m + f` sits between `impl Money as
AddWith(Cpp.Foo)` and `impl Money as AddWith(Money)`; a later `inline Cpp`
block applies `a + b` to two `Money`. `v4` rejects `o1` (`invalid operands`,
the note naming only the `Foo` candidate) and compiles `o2`; `v5` compiles both,
because Carbon's lookup leaves no answer cached (D-OX-21). Pinned by
`carbon_side_then_cpp`. The C++-to-C++ order of M-11(c) is unchanged (W-205)
(amended 2026-10-14, review fold: A-4).

**M-24. A nested operand class (A-5).** Review A's `n_nested.carbon`, adapted
(`$F/probes/V/v_nested.carbon`: `class Outer { class Inner }`, `impl i32 as
SubWith(Outer.Inner)` and `impl Outer.Inner as AddWith(Outer.Inner)`): `v4`
rejects C++ `50 - Carbon::Outer::Inner::Make(8)` with `invalid operands`
(its walk required the operand's direct parent to be the namespace); `v5`
prints `42 42 42` (member, non-member, and Carbon's own). Pinned by
`non_member_nested` (amended 2026-10-14, review fold: A-5).

**M-25. Signatures (A-7).** Review A's `s1_result_mismatch.carbon`: `impl Money
as AddWith(i32) where .Result = i64 { fn Op(self, k: i32) -> i32 }` and `impl
Money as SubWith(i32) { fn Op(self, k: i64) -> i32 }`. On `v4` and `v5` it
prints `42 1`: Carbon types `m + k` as `i64`, C++ `decltype(m + 1)` is `int`,
and C++ accepts `m - 4294967296L` (the function's `i64` parameter; the impl
body's `k as i32` truncates it to 0), where Carbon's `m - k` needs `k: i32`.
The exported operator is the impl function as written, as an exported method
is, so this is a divergence of D-OX-15's kind, documented and pinned by
`signature_from_impl_function`. `v_noncopy_lvalue.carbon` (`class Money { var
n: Cpp.NoCopy; }`, `AddWith(Money)`): Carbon's `a + b` compiles, and C++'s
`a + b` on two `const Carbon::Money&` fails on `v5` with `call to
implicitly-deleted copy constructor of 'Carbon::Money'`, the by-value operand
of M-5; pinned by `fail_noncopyable_lvalue_operand` (rev 1's §1.7 said C++
rejects nothing Carbon accepts; amended 2026-10-14, review fold: A-7).

**M-26. Carbon's `!=` and the default non-member `!=` (B-1).** Review B's
`ne.carbon` (`impl Cpp.Foo as EqWith(Money)` with `Equal` only, the Carbon
function `CarbonNe(f, m) = f != m`) lowered on `v4` to a call of
`_ZN6CarbonneE3FooNS_5MoneyE.carbon_thunk.__`, through the synthesized C++
`operator!=` (review B's `ne.ll`). On `v5`, `CarbonNe`'s LLVM IR is identical
to trunk's: one call of `_CNotEqual.EqWith.Core.8d8286e58955f8ab`, the
interface's default `NotEqual` for the impl (`$F/probes/B-p5/ne.{trunk,v5}.ll`).
`v_ne_after_cpp.carbon`, where C++ code exports and caches the default
`Carbon::operator!=(Foo, Money)` first, prints `1 0` on `v5`, and the lower
split `carbon_side_default_not_equal` pins that its `CarbonSide` calls
`_CNotEqual.EqWith.Core.8d8286e58955f8ab` while `CppSide` reaches
`_ZN6CarbonneE3FooNS_5MoneyE`: the default `!=` is registered in `clang_decls`
like every exported operator, so the filter recognizes it (amended 2026-10-14,
review fold: B-1).

**M-27. A result with no C++ form (B-2).** Review B's `sel.carbon`: `impl Money
as AddWith(i32) where .Result = (i32, i32)` and `impl Money as AddWith(i64)
where .Result = i32` returning 1000, with Carbon's `(m + k).0` for `k: i32` and
C++'s `Make(5) + k` for `int k`. `v4`, which omitted the tuple impl, prints `5
1000`: C++ converted `k` to `long` and called the impl Carbon does not select.
Trunk rejects the C++ use (`invalid operands`); `v5` rejects it with
`overload resolution selected deleted operator '+'`, the tuple impl being
declared `operator+(int) const = delete` with a `void` result. Pinned by
`fail_deleted_result`, by `deleted_result_unselected` (a `long` operand still
selects the `i64` impl) and by the AST golden's `operator* 'void (int) const'
inline delete` (amended 2026-10-14, review fold: B-2).

**M-28. A generic impl is invisible to C++ (found folding B-2).**
`$F/probes/V/v_generic_conv.carbon`: `impl forall [T: Core.ImplicitAs(i32)]
Money as MulWith(T)` returning 1 and `impl Money as MulWith(i64)` returning 2.
On `v5`, Carbon's `m * k` with `k: i32` prints `1` and C++'s `m * k` with `int
k` prints `2`: C++ never sees the generic impl (W-202) and converts `k` to
`long`. This is B-2's hazard for a generic impl, which no deleted declaration
can cover (it needs a C++ template); it is part of W-202, documented on the page
and pinned by the lower split `generic_impl_hidden` (`_CCarbonSide.Main` calls
the generic impl's specific, `_ZNK6Carbon5MoneymlEl` the `i64` impl's thunk)
(amended 2026-10-14, review fold: B-2).

**M-29. Impls with no Carbon class among their types (B-3).** Review B's
`foreign.carbon`: `impl Cpp.Foo as Core.AddWith(i32)` and `impl Cpp.Foo as
Core.Negate`, both concrete impls of this file. C++ `MakeFoo(40) + 2` fails
`invalid operands to binary expression ('Foo' and 'int')` on trunk, `v4` and
`v5`, and `-MakeFoo(42)` `invalid argument type 'Foo' to unary expression`:
C++'s argument-dependent lookup for `Foo` and `int` never asks namespace
`Carbon`. Filed as W-210, pinned by `fail_todo_non_carbon_operands`, and the
criterion is narrowed to impls whose `Self` or operand is a Carbon class (the
head; D-OX-4) (amended 2026-10-14, review fold: B-3).

**M-30. Every other probe, re-run on `v5`.** The 69 programs of
`$F/probes/list3.txt` (the reviewers', the planner's and the fixer's) on trunk
and `v5` (`$F/runs-trunk3.log`, `$F/runs-v5f.log`): every C++ use of an
exported operator that M-7 and M-11 list behaves as stated; review A's
generic-function, impl-body, generic-class-method and self-recursive probes
(`A-ctx/g1` to `g4`) print `42`, `43`, `42` and `42` on trunk and `v5`; the
adapter probe (`A-adapt/a1_adapter`) fails on trunk and `v5` alike, in Carbon
(cannot copy a value of type Meters, before any export); `x2` (an `extend
impl` member named from C++ as `a.Op(b)`) fails `no member named 'Op'` on trunk
and `v5`, the impl member having no identifier export, and `x1`, which adds the
operator form, fails on `v5` only at `a.Op(b)`.

### §0.3 Ledger and brief claims found stale (each corrected where §2 says)

1.  W-054's evidence cites `fork/gap-analysis.md:30`; the row is line 48
    (corrected at discharge, §2.8).
2.  The brief places a 5-line null check in toolchain/check/cpp/export.cpp on
    SC-1's branch; it is ST-1's (PR 55, claude/carbon-fork-0-1-st,
    ExportClassToCpp :293-300); `git diff --stat f67ab650d
    claude/carbon-fork-0-1-sc -- toolchain/check/cpp` prints nothing (§6.2).
3.  The brief describes toolchain/check/cpp/thunk.cpp's `BuildThunkBody`,
    `BuildCalleeCallExpr`, `BuildReturnValueStore` and the catching variants as
    the bodies that call Carbon functions from C++; they are the import
    direction's (Carbon calling C++). The export bodies are export.cpp's
    `BuildCppToCarbonThunkBody` and check/thunk.cpp's
    `BuildThunkDefinitionForExport` (§0.1 row 5). OX-1 edits neither thunk.cpp.
4.  Row 47's evidence and the brief credit the import direction with
    "spaceship rewrites"; a rewritten candidate is a semantics TODO
    (operators.cpp:891-898; the `fail_todo_spaceship_rewrites` and
    `fail_todo_comparison_rewrites` splits of
    toolchain/check/testdata/interop/cpp/operators/), W-045's scope.
5.  The brief lists `Deref` among the families; Carbon has no dereference
    interface for its own types (§0.1 row 10), so there is nothing to export.
6.  The brief allows `<=>` "if the imported-direction rewrite logic suggests a
    symmetric mapping"; the prelude's `OrderedWith` has no `Compare` to export
    (comparison.carbon:24), so `<=>` is W-206.
7.  W-007's notes end "Remaining contender: SC-B3 (W-029)"; OX-1 is a contender
    in export.cpp, landed by the same sequencing (§2.8 appends the record).
8.  DD-1's interoperability README (held, not on trunk) says "The 0.1 toolchain
    implements the first direction", "The other direction is not implemented: a
    Carbon type's operator interface implementations are not exported as C++
    operators (fork work item W-054)" and, in "Using Carbon from C++", "Carbon
    operator implementations are not exported as C++ operators"; all three are
    replaced at OX-1's merge of trunk (§6.2.1; the first added 2026-10-14,
    review fold: B-9).
9.  The commit shape the brief suggests ("toolchain and goldens in one commit if
    either alone breaks file_test") is measured, not assumed: the toolchain
    alone leaves file_test green (M-8), so they are separate commits (§3). Two
    of rev 1's own claims were stale too. Its D-OX-18 and W-208 cited
    docs/project/milestones.md:169, which is a loops bullet; the
    operators-and-conversions line is :200, a standard-library bullet (corrected
    in the head, D-OX-18 and §2.8; amended 2026-10-14, review fold: A-6, B-4).
    And its D-OX-11 recognized a member operator as exported whenever its record
    is Carbon-owned, which also matches Clang's implicit members of that record
    (`operator=`), so `v5` recognizes exactly the declarations registered in
    `clang_decls` (a fixer correction).

### §0.4 Decisions this plan auto-adopts (R29(a): the design recommendation under V-2/V-3, veto-able after the fact)

Each decision carries the one sentence that would break it. D-OX-21 is rev 2's
(amended 2026-10-14, review fold: A-1, A-4).

-   **D-OX-1 (the operator set).** Exported: the members of the `Core`
    interfaces whose Carbon operator has a C++ overloadable counterpart —
    `AddWith`, `SubWith`, `MulWith`, `DivWith`, `ModWith`, `Negate`,
    `BitAndWith`, `BitOrWith`, `BitXorWith`, `BitComplement`, `LeftShiftWith`,
    `RightShiftWith`, the ten `*AssignWith` interfaces, `Inc`, `Dec`, `EqWith`
    (`Equal`, `NotEqual`), `OrderedWith` (`Less`, `LessOrEquivalent`,
    `Greater`, `GreaterOrEquivalent`) and `IndexWith.At`: 31 members, the
    inverse of the import table (operators.cpp:36-209) less what Carbon does not
    route through an interface (`AssignWith`, unused for `=`, :123-128). Not
    exported, each for a stated reason: dereference and address-of (no
    interface), `<=>` (no `Compare` in the prelude, W-206), `As` and
    `ImplicitAs` (conversions, in the bullet but not in 0.1: W-208, which
    bounds the row, D-OX-18; amended 2026-10-14, review fold: A-6, B-4).
    **Breaks if** a `Core` interface of the prelude whose Carbon operator C++
    can overload is missing from the table without a filed reason.
-   **D-OX-2 (member operators).** A complete, non-generic impl whose `Self` is
    exactly the exported class is a member operator of that class's record:
    `const` for a `self` member, `&`-qualified for `ref self`, by-value
    parameters, the result by value — the exported-method mapping unchanged
    (export.cpp:1028-1093), applied to the impl function as declared, which
    can differ from the interface's signature (M-25, D-OX-15; amended
    2026-10-14, review fold: A-7). C++ then finds it by member lookup on the
    left operand only, as Carbon finds an impl by lookup on `Self` only.
    **Breaks if** C++ finds a member operator for an impl whose `Self` is not
    the class, or misses one whose `Self` is (M-7 and the `arithmetic`..`index`
    splits).
-   **D-OX-3 (non-member operators).** A complete, non-generic binary impl
    whose `Self` is not a Carbon class C++ sees as a record of its own (a Carbon
    primitive such as `i32`, which is a recognized type, or an imported C++
    type; decided from SemIR, never by mapping `Self`) and whose interface
    argument is a non-generic Carbon class exported with the namespace `N` as
    its innermost enclosing namespace is a non-member operator `R
    operator@(S, C)` declared in `N`, so C++ finds it by argument-dependent
    lookup on the `C` operand, nested classes included; `operator[]` is
    excluded because C++ requires it to be a member (rev 1 compared the
    operand's direct parent with `N`, which missed a nested class, and mapped
    `Self` with `MapToCppType` before checking the interface; amended
    2026-10-14, review fold: A-5, A-1). **Breaks if** `int-Carbon::Money` (or
    `Foo+Carbon::Money` for an imported `Foo`, or `int-Carbon::Outer::Inner`)
    does not reach the `i32` (or `Cpp.Foo`) impl in C++ (M-7 `nm.carbon`,
    M-24, the `non_member` and `non_member_nested` splits, the nonmember
    program).
-   **D-OX-4 (which impls).** Only impls of the checking file's
    `context.impls()`: concrete (no `generic_id`), complete at the time C++
    looks the operator up, of an interface in package `Core` with a row for the
    operator in §1.1's table — tested on SemIR before any type of the impl is
    mapped — and with a Carbon class that C++ sees as a record of its own as
    `Self` (the member form) or as the operand (the non-member form). A generic
    impl, an impl on a specific of a generic class (W-202), an impl of an
    imported library (W-204, blocked by W-203) and an impl with no such class
    among its types (W-210) are filed (amended 2026-10-14, review fold: A-1,
    B-3). **Breaks if** a concrete, complete impl of the file with such a class
    as `Self` or operand is not exported.
-   **D-OX-5 (the default `!=`).** An `EqWith` impl that does not declare
    `NotEqual` gets `operator!=` built in C++ as `!(a==b)` over the exported
    `operator==`, of the same form (member or non-member); a declared
    `NotEqual` is exported as itself. That is the interface's default body,
    `not self.Equal(other)` (comparison.carbon:14-16,
    comparison_operators.md:260), and C++17, the `inline Cpp` default, has no
    rewrite to supply it (M-6). The body passes each by-value parameter on to
    `operator==` as an xvalue, as a C++ implicit move does, so a move-only class
    has `!=` too (M-21); it is built under a `Sema::SFINAETrap`, and if the call
    is still invalid (a class C++ can neither copy nor move) no `operator!=` is
    declared and nothing is diagnosed; the declaration is registered in
    `clang_decls` like every exported operator, so Carbon's own lookup
    recognizes it (D-OX-11, M-26) (rev 1 passed lvalues and asserted the call,
    which aborted the compiler for a move-only class; amended 2026-10-14,
    review fold: A-2, B-1). **Breaks if** C++ `a!=b` and Carbon `a!=b` disagree
    for any impl (the compare program's `Unknown` line and M-14's M2), or the
    compiler stops on a `!=` (the `move_only_*` splits).
-   **D-OX-6 (no synthesized candidates).** Because `operator!=` accompanies
    `operator==` (D-OX-5) and no `<=>` is exported, C++20 forms no reversed or
    rewritten candidate, so in every dialect C++ accepts exactly the operand
    orders Carbon has impls for. The one exception is a class C++ can neither
    copy nor move, which gets no default `!=` (D-OX-5), and whose `==` C++ can
    then call only with prvalues anyway. **Breaks if** C++ accepts `5==m` for a
    class that has only `Money as EqWith(i32)`, `m==5` for one that has only
    `i32 as EqWith(Money)`, or `5>m` for one that has only `Money as
    OrderedWith(i32)`, under `-std=c++20` (operator_cxx20.carbon's three
    `fail_reversed_*` splits; rev 1 named only a C++17 split; amended
    2026-10-14, review fold: A-2).
-   **D-OX-7 (statements stay statements).** The compound assignments and
    `Inc`/`Dec` take `ref self`, so they export `&`-qualified and `void`, as
    Carbon's statements produce no value; only prefix `++`/`--` exist, as
    Carbon has no postfix form; `=` is not an interface operator and stays C++'s
    copy assignment. **Breaks if** C++ `a+=b` on an lvalue does not modify
    `a` (the compound program), or a temporary or `a++` is accepted (the two
    `fail_` splits).
-   **D-OX-8 (indexing by value).** `IndexWith(I).At` takes `self` and returns
    a value, so `operator[]` is a `const` member returning the element by
    value; several `IndexWith` impls form one C++ overload set. **Breaks if**
    C++ `t[i]` differs from Carbon `t[i]` for the same impl (the index program).
-   **D-OX-9 (what has no C++ form).** Decided per impl function, after D-OX-4
    has selected the impl, by `ClassifyOperatorExport` (§2.1). (1) An operand
    (`self` or the parameter) whose type has no C++ mapping, decided without
    exporting anything (a type whose mapping stops at a tuple, a struct or
    another kind `MapToCppType` does not map, under `const`, pointer and array
    wrappers): the impl is omitted without a diagnostic, because C++ cannot
    form such an operand, so the omission cannot change which impl a C++
    expression selects. (2) A result with no C++ mapping, decided the same way,
    or an array result, which C++ cannot return by value: the operator is
    declared deleted, with a `void` result, so a C++ expression that would
    select it is rejected (`overload resolution selected deleted operator`)
    rather than resolved to another impl by a conversion (M-27). (3) Any other
    type, a Carbon class included, is mapped, and a diagnostic from exporting
    it — a class C++ cannot export, such as one with a tuple field — is
    reported at the C++ use, as for any exported declaration that names that
    class and as OV-3 landed it for an overload-set member (D-OV-18, M-20). No
    impl is mapped for Carbon's own operator expressions (D-OX-21). Rev 1
    omitted every impl whose signature mapped to null, decided by mapping it,
    and argued that C++ cannot form an unmappable operand; that argument holds
    for operands only, the mapping itself diagnosed for some classes, and the
    omission of a result-unmappable impl let C++ select another impl (amended
    2026-10-14, review fold: A-1, B-2). **Breaks if** a Carbon-only expression
    trunk accepts is rejected (the `carbon_side_*` splits), or a C++ expression
    selects an impl other than the one C++ overload resolution would select
    over all of the operator's concrete impls of the file (the
    `fail_deleted_result` split; a generic impl is W-202's, M-28).
-   **D-OX-10 (thunks and symbols).** No new thunk kind: the C++ operator is
    built by `BuildCppToCarbonThunkDecl` under the operator's name, or by
    `BuildCppOperatorDecl` for the non-member form, and calls the generated
    Carbon thunk `<member>__carbon_thunk` in the impl's scope, which mangles by
    the impl's `Self` and interface specific
    (`_COp__carbon_thunk.Money.Main:AddWith.<specific>.Core`, M-4), so two impls
    never share a symbol; the C++ operators are inline, always-inline and
    internal to the translation unit, as exported methods are; a deleted
    operator has no body and no thunk. Two impls whose operand types map to one
    C++ type are two same-signature declarations, ambiguous at every C++ use
    (W-207, the W-118 shape). **Breaks if** two impls' thunks mangle equal
    (lowering would reuse one, the OV-3 R-10 failure).
-   **D-OX-11 (Carbon is unchanged).** An exported Carbon operator is never a
    C++ candidate for Carbon's own operator lookup, in any of Clang's results:
    Carbon's lookup exports nothing (D-OX-21), and `FindClangOperator` marks
    every candidate that `IsExportedCarbonOperator` recognizes — a declaration
    registered in `clang_decls` as an exported operator, the default `!=`
    included — non-viable before `BestViableFunction`, so the success,
    ambiguous, deleted and no-viable results are each the one Clang gives
    without exported operators, and a hand-written C++ operator Carbon used
    before is still the one it uses. p006254's "Operator calls" stands: an
    exported operator is Carbon's own impl seen from C++, not a C++ operator
    function (rev 1 checked only the `OR_Success` result, after overload
    resolution, and missed the non-member default `!=`; amended 2026-10-14,
    review fold: A-3, B-1, B-11). **Breaks if** a Carbon operator expression
    lowers to a call through an exported C++ operator, or a Carbon-only program
    trunk accepts is rejected or selects another C++ function (the lower
    `carbon_side_cpp_operand` and `carbon_side_default_not_equal` splits,
    `carbon_side_candidates`, `carbon_side_user_cpp_operator`, M-22, M-26).
-   **D-OX-12 (laziness and caching).** Operators are exported when C++ code
    looks their name up in the class or namespace, and Clang keeps the answer
    (M-4), as for every exported name; an impl declared after C++ code looked
    the operator up is not seen by later C++ code (W-205). Carbon's own lookups
    leave no answer (D-OX-21), so they do not narrow what C++ sees (rev 1's
    caching applied to Carbon's lookups too; amended 2026-10-14, review fold:
    A-4). **Breaks if** an operator C++ looks up after its impl is complete is
    not found (the `fail_impl_after_use`, `fail_todo_impl_after_lookup` and
    `carbon_side_then_cpp` splits pin the orders).
-   **D-OX-13 (F-017 and its docs).** The accepted design leaves the operator
    model empty (README :350) and the overview is provisional, so the mapping
    is fork design F-017, documented on a new page,
    docs/design/interoperability/operators.md, with a dated amendment under the
    README's operator section (§2.7); the page, not the README, carries the
    text, because DD-1 rewrites the README (+847 lines, §6.2). **Breaks if** an
    accepted upstream proposal or the leads decide the export differently
    (V-3), or upstream starts operator export (M-17's check, repeated at each
    advance).
-   **D-OX-14 (the row).** Row "Type system: C++ interop — exporting Carbon
    operator overloads into C++" moves MISSING → PARTIAL, expected and not of
    record (R9: the run of record needs Actions). It is bounded by W-208: the
    design overview's operator-overloading interop section maps `ImplicitAs`
    to C++ implicit conversions in the same paragraph as `BitComplement` to
    `operator~` (docs/design/README.md:3676-3681), and conversions are not
    exported in 0.1 (D-OX-18). Every other limit — W-202 and W-204 to W-207,
    W-209 to W-211 — is a generic, cross-library, ordering, not-yet-designed,
    non-Carbon or C++-side case, filed under the row as a limit; the concrete
    set D-OX-4 names is usable from C++ in both operand positions (M-7, M-13,
    M-24). The bullet's seven programs all PASS while the row is PARTIAL, as
    for OP-1's Optional row (rev 1 recorded DONE and kept PARTIAL as a fallback,
    resting on a miscited milestone line, and referred to precedent rows by
    line number; amended 2026-10-14, review fold: A-6, B-4, B-3, B-8). **Breaks
    if** the plan reviews or the leads read the bullet as excluding conversions
    (then the row is DONE with W-208 a limit, a one-word and one-sentence change
    of §2.8), or a concrete same-file impl of D-OX-1's set and D-OX-4's scope
    does not export (then the row stays PARTIAL with that case filed).
-   **D-OX-15 (divergences, documented).** C++ resolves an exported operator
    under C++'s rules, as it resolves an exported overload set (F-009, OV-3):
    (1) it converts operands (`m*3L` calls `MulWith(i32)`, M-11(f)); (2) it
    searches base classes (`d+d` calls the base's impl, M-7); (3) it sees the
    impl function's own declared signature, so the C++ result type is the
    function's return type where Carbon types the expression by the
    interface's `Result`, and C++ takes the function's parameter type where
    Carbon checks the interface argument (M-25); (4) it copies a by-value
    operand, so a class C++ cannot copy is not an lvalue operand in C++ where it
    is in Carbon (M-25). Carbon's impl lookup does none of these — the
    overview's "edge cases around implicit conversions or overload selection"
    (:3672-3673). Each is pinned on both sides by goldens: (1) `arithmetic`'s
    `3L` assertion and `fail_conversion_carbon_side`; (2) `base_class` and
    `fail_base_class_carbon_side`; (3) `signature_from_impl_function`, whose
    Carbon side is the interface's own typing; (4)
    `fail_noncopyable_lvalue_operand`, whose `CarbonSide` compiles. They are
    goldens, not conformance programs, so R30's two-sided program obligation
    does not arise; the arithmetic and index programs' headers cross-reference
    them (R30(a); rev 1 listed (1) and (2) and pinned (1) on the C++ side only;
    amended 2026-10-14, review fold: A-7, A-9, B-10). **Breaks if** C++ selects
    an impl that no C++ overload resolution over the exported declarations
    would select (that would be a toolchain defect, not a divergence).
-   **D-OX-16 (W-007 discipline).** New functions, one new switch arm
    (generate_ast.cpp, not a contention file), one `CppContext` member
    (check/cpp/context.h, not a contention file), one restructured call and a
    candidate filter in `FindClangOperator` (operators.cpp, not a contention
    file), and one in-function hunk in a contention file: the condition
    `target.self_param && isa<clang::CXXMethodDecl>(function_decl)` in
    `BuildCppToCarbonThunkBody` (export.cpp:1247). It is behaviour-preserving,
    because the unchanged line below it casts `function_decl` to
    `CXXMethodDecl` unconditionally whenever `target.self_param` is set, so
    every existing caller already passes a method there; the non-member form is
    the only caller that does not. Nothing is moved or renamed; thunk.cpp (both)
    and type_mapping.cpp are untouched (amended 2026-10-14, review fold: A-1,
    A-3, A-4). **Breaks if** any existing golden changes (M-8: none).
-   **D-OX-17 (programs).** Seven programs for the bullet: the un-SKIPped
    arbiter and one per family (arithmetic with negation, compound assignment
    with increment, comparison, bitwise and shift, indexing, the non-member
    form), each EXPECT hand-derived (§1.8), none with a `.diff.cpp` oracle: the
    agreeing direction needs none (R30(b)), and the divergences live in
    goldens (D-OX-15). Each comparison is printed as 100·(x op y) +
    10·(x op x) + (y op x), a value unique to each of the six operators, so a
    swapped or mis-mapped comparison changes a line (rev 1's true/false pairs
    printed the same `10` under several swaps; amended 2026-10-14, review fold:
    A-8). **Breaks if** a program passes with its family's operator mis-mapped
    (M-14's three mutants are the check).
-   **D-OX-18 (conversions are in the bullet, not in 0.1).** `As(T)` and
    `ImplicitAs(T)` are not exported in 0.1, and the row is PARTIAL for them
    (W-208, D-OX-14). The bullet is read under the design overview, whose
    operator-overloading interop section puts `ImplicitAs(U)` and C++'s
    implicit conversions into the same correspondence as `BitComplement` and
    `operator~` (docs/design/README.md:3679-3681), and proposal p000845 says
    `As` provides the functionality of C++'s `explicit` constructors and
    conversion functions "for interoperability purposes" (:184-187); the
    import table also lists `As` and `ImplicitAs` among the operator interfaces
    (operators.cpp:42-52, "TODO: Support destructors and conversions").
    docs/project/milestones.md:200 lists "operators, conversions" as the
    prelude interfaces the library must provide, and does not bear on the
    interop bullet. Exporting them is not a row of the operator table: C++
    spells a conversion as a conversion function or a converting constructor
    ([class.conv.fct], [class.conv.ctor]) rather than an overloaded operator,
    Clang collects a class's conversion functions from its definition rather
    than by name lookup, so they need an eager export at completion that no
    other export does, and an `impl X as ImplicitAs(C)` would become a
    constructor of `C`, a design choice of its own (rev 1 excluded conversions
    from the bullet on the strength of a miscited milestone line, quoting the
    overview only up to the `BitComplement` sentence; amended 2026-10-14,
    review fold: A-6, B-4). **Breaks if** the plan reviews or the leads read
    the bullet as excluding conversions (then D-OX-14's DONE alternative
    applies), or conversions are exported (then W-208 is discharged and the
    row is re-judged).
-   **D-OX-19 (merge position and the merge of trunk).** OX-1 is cut from
    trunk, not stacked, and merges after DD-1 (PR 58) and PR 57, in the order
    fork/ORCHESTRATION.md records at 3eb7f36f0 (PR 53, PR 51, PR 52, SC-1,
    PR 54 to PR 57, then PR 58 through its state L integration commit, then
    OX-1 and VA-1); before its discharge commit it
    merges trunk (a merge commit, never a rebase) and re-verifies the merge
    commit (§3, §8.8), and that merge applies §6.2.1's three sentence
    replacements in DD-1's README text if DD-1 has merged (rev 1 assumed a
    merge it did not schedule; amended 2026-10-14, review fold: B-5, B-9).
    **Breaks if** DD-1 merges after OX-1; then DD-1's next fold applies the same
    replacements and the ORCHESTRATION stamp says so.
-   **D-OX-20 (no new SemIR, no new diagnostics).** The feature adds no
    instruction kind, no `CARBON_DIAGNOSTIC`, and no SemIR formatting; its
    observable outputs are C++ declarations (the AST golden), generated thunks
    (the lower golden), Clang's own diagnostics, and the existing semantics
    TODOs of type export (D-OX-9 (3); `BuildCppOperatorDecl` reuses the texts
    `BuildCppToCarbonThunkFunctionType` uses). **Breaks if** an implementation
    review finds a case that needs a Carbon diagnostic to be usable (it would
    be added with its own golden split and recorded here).
-   **D-OX-21 (Carbon's own lookup exports nothing; rev 2).** While
    `FindClangOperator` runs `Sema::LookupOverloadedBinOp` for a Carbon
    operator expression, `CppContext::in_carbon_operator_lookup()` is set, and
    the external source's `CXXOperatorName` arm answers nothing, exports
    nothing, and erases the empty entry `DeclContext::lookupImpl` created, as
    upstream e476a2bd3 does for a failed identifier lookup, so that the next
    C++ lookup of that name asks again. This is the new piece of `Context`
    state that rev 1 rejected (§7 A-8); it is adopted because Carbon's lookup
    needs no exported operator (Carbon finds its own impl by impl lookup, and
    D-OX-11 discards exported candidates anyway), and because exporting during
    it rejected Carbon-only programs (M-20), made them ambiguous (M-22),
    narrowed later C++ lookups (M-23) and defined unused thunks (M-10)
    (amended 2026-10-14, review fold: A-1, A-4, A-3, B-1). **Breaks if** a C++
    lookup after a Carbon expression misses an impl that a lookup without that
    expression finds (the `carbon_side_then_cpp` split, M-23), or upstream's
    advance changes the lookup-cache contract the erasure relies on (§6.3,
    re-checked at each advance).

## §1 Design

### §1.1 The export mapping (F-017; D-OX-1)

| `Core` member | C++ | Form when `Self` is the class | Form otherwise (D-OX-3) |
| --- | --- | --- | --- |
| `AddWith(U).Op` | `a + b` | `R operator+(U) const` | `R operator+(S, C)` |
| `SubWith(U).Op` | `a - b` | `R operator-(U) const` | `R operator-(S, C)` |
| `MulWith(U).Op` | `a * b` | `R operator*(U) const` | `R operator*(S, C)` |
| `DivWith(U).Op` | `a / b` | `R operator/(U) const` | `R operator/(S, C)` |
| `ModWith(U).Op` | `a % b` | `R operator%(U) const` | `R operator%(S, C)` |
| `Negate.Op` | `-a` | `R operator-() const` | (unary: none) |
| `BitAndWith(U).Op` | `a & b` | `R operator&(U) const` | `R operator&(S, C)` |
| `BitOrWith(U).Op` | <code>a \| b</code> | <code>R operator\|(U) const</code> | <code>R operator\|(S, C)</code> |
| `BitXorWith(U).Op` | `a ^ b` | `R operator^(U) const` | `R operator^(S, C)` |
| `BitComplement.Op` | `~a` | `R operator~() const` | (unary: none) |
| `LeftShiftWith(U).Op` | `a << b` | `R operator<<(U) const` | `R operator<<(S, C)` |
| `RightShiftWith(U).Op` | `a >> b` | `R operator>>(U) const` | `R operator>>(S, C)` |
| `AddAssignWith(U).Op` .. `ModAssignWith(U).Op` | `+=` `-=` `*=` `/=` `%=` | `void operator+=(U) &` .. | `void operator+=(S&, C)` .. |
| `BitAndAssignWith(U).Op` .. `RightShiftAssignWith(U).Op` | `&=` <code>\|=</code> `^=` `<<=` `>>=` | `void operator&=(U) &` .. | `void operator&=(S&, C)` .. |
| `Inc.Op`, `Dec.Op` | `++a`, `--a` | `void operator++() &` | (unary: none) |
| `EqWith(U).Equal` | `a == b` | `bool operator==(U) const` | `bool operator==(S, C)` |
| `EqWith(U).NotEqual` | `a != b` | `bool operator!=(U) const`, or `!(*this == b)` (D-OX-5) | `bool operator!=(S, C)`, or `!(a == b)` |
| `OrderedWith(U).Less` .. `GreaterOrEquivalent` | `<` `<=` `>` `>=` | `bool operator<(U) const` .. | `bool operator<(S, C)` .. |
| `IndexWith(I).At` | `a[i]` | `E operator[](I) const` | (C++: members only) |

`R`, `U` and `E` are the impl function's own declared return and parameter
types, which Carbon's impl checking lets differ from the interface's
(`Result`, the interface argument, `ElementType`) when they convert (M-25,
D-OX-15); `S` is the impl's `Self` and `C` the exported Carbon class the
interface argument names; each maps by `MapToCppType` (§0.1 row 6), and
D-OX-9 decides what has no C++ form (rev 1 said `R` was the interface's
`Result`; amended 2026-10-14, review fold: A-7). The table is
`OperatorExportTable` (§2.1), one row per interface member with its explicit
parameter count (0 unary, 1 binary) and `OverloadedOperatorKind`; one operator
name can come from two interfaces (`-` from `SubWith` and `Negate`), which
Clang tells apart by parameter count.

### §1.2 How C++ finds it (D-OX-2, D-OX-3, D-OX-12, D-OX-21)

Clang asks the external source for an operator name in two contexts (M-4): the
left operand's class, for member candidates, and each associated namespace, for
argument-dependent lookup. A new arm of `FindExternalVisibleDeclsByName`'s
name-kind switch answers both: `ExportOperatorsToCpp` for a Carbon-owned record,
`ExportNonMemberOperatorsToCpp` for a Carbon-owned namespace. While Carbon's own
operator lookup is running (D-OX-21), the arm instead answers nothing and erases
the entry Clang created, so that nothing is exported or cached. Each walk visits
`context.impls()` in order and first keeps, from SemIR alone, the impls D-OX-4
admits whose interface has a row for the operator (`IsOperatorImplOfKind`:
complete, non-generic, `Core`, and the table; M-3), so an impl of any other
interface, an `ImplicitAs` impl on a class C++ cannot export among them, is
never mapped (M-20 (g)). The member walk then keeps the impls whose `Self`
constant is the record's class type. The non-member walk keeps the impls whose
`Self` is not a Carbon class C++ sees as a record of its own
(`GetCarbonRecordClassType`: a class type from a Carbon scope that is not a
recognized type such as `i32`), whose one interface argument is such a class,
non-generic and already exported, and whose exported declaration has this
namespace as its innermost enclosing namespace (`getEnclosingNamespaceContext`),
where argument-dependent lookup on it looks (M-24; amended 2026-10-14, review
fold: A-1, A-5). For each kept impl and each table row of the operator, the
function the impl declares under the row's member name
(`GetImplMemberFunctionId`: a found entry of the impl's scope, M-3) is
classified (D-OX-9) and exported, declared deleted or omitted, once, and an
exported or deleted declaration is registered in `clang_decls`, keyed by the
declaration and the all-by-value signature and mapped to the function's first
declaration, as `GetOrExportFunctionToCpp` records an exported function
(:1632-1642); the registration is what `IsExportedCarbonOperator` looks up
(D-OX-11). Clang caches the list per context and name; an empty answer from a
C++ lookup is cached as "none" (`SetNoExternalVisibleDeclsForName`, as the
identifier path's null case does at generate_ast.cpp:410).

### §1.3 Equality, inequality and ordering (D-OX-5, D-OX-6)

`Equal` exports as `operator==`. `NotEqual` exports as itself when the impl
declares it; otherwise `BuildDefaultNotEqualOperator` declares `operator!=`
beside the exported `operator==`, with its type and parameters, and builds the
body `return !(*this==other);` (a `CXXMemberCallExpr` of `operator==` under
`UO_LNot`, M-12's AST golden) or, for the non-member form, `return !(a==b);`
(a call of the non-member `operator==`), each by-value parameter passed on as
an xvalue (`ImplicitCastExpr <NoOp>` to `xvalue`, as Clang's own implicit moves
are built), under a `Sema::SFINAETrap`; if the call is invalid the declaration
is removed and nothing is diagnosed (M-21; amended 2026-10-14, review fold:
A-2). The declaration is registered like any exported operator (M-26; amended
2026-10-14, review fold: B-1). Because both are declared together and no `<=>`
exists, Clang under `-std=c++20` adds no reversed or rewritten candidate (M-6,
operator_cxx20.carbon). The four `OrderedWith` members export one to one; there
is no `Compare` to export (W-206).

### §1.4 Statements and indexing (D-OX-7, D-OX-8)

`*AssignWith`, `Inc` and `Dec` members take `ref self`: the member form is
`&`-qualified (`BuildCppToCarbonThunkFunctionType`'s existing `RQ_LValue`,
export.cpp:1081-1082) and returns `void`; the non-member form takes `S&`
first (`MapToCppParamType` maps a `ref` parameter to an lvalue reference,
:1013-1014), as `int k; k-=m` needs. `IndexWith.At` takes `self`: a `const`
member returning the element by value.

### §1.5 What is not exported, and why (D-OX-1, D-OX-4, D-OX-9, D-OX-18)

| Case | Measured | Reason | Filed |
| --- | --- | --- | --- |
| `As`, `ImplicitAs` | — | conversions are in the bullet (README.md:3679-3681) but are not overloaded operators in C++ and need an eager export at completion (D-OX-18); **bounds the row** | W-208 |
| Generic impl; impl on a specific of a generic class | M-11(a), M-28 | the export walk takes concrete impls; a generic `Op` needs a C++ template; while it is missing, a C++ operand that converts to a concrete impl's operand type selects that impl where Carbon selects the generic one | W-202 |
| Impls of an imported library | M-11(d) | only `context.impls()` is walked; and an imported class exports as an empty record | W-204 (blocked by W-203) |
| An imported Carbon class at all | M-11(d) | pre-existing: fields are not exported, by-value results corrupt memory | W-203 (type-export row) |
| An impl declared after C++ code looked its operator up | M-11(c) | Clang's cached answer (M-4); Carbon's own lookups cache nothing (D-OX-21, M-23) | W-205 |
| `<=>` | §0.3 item 6 | no `OrderedWith.Compare` in the prelude | W-206 |
| Two impls mapping to one C++ signature | M-11(e) | non-injective type mapping; C++ ambiguity | W-207 |
| `a[i] = v` | — | the prelude's `IndexWith` has only `At` (W-109) | W-209 |
| An impl with no Carbon class among its types (`impl Cpp.Foo as AddWith(i32)`, `impl Cpp.Foo as Negate`) | M-29 | C++'s argument-dependent lookup never asks namespace `Carbon`; exporting it needs a declaration in the C++ type's own namespace | W-210 |
| A hand-written C++ operator that duplicates an exported impl | M-22 | C++ sees two equally good candidates; C++ code written before OX-1 to fill the gap is now ambiguous (Carbon's own expressions are not; D-OX-11) | W-211 |
| Postfix `++`/`--`, unary `+`, `!`, `&&`, <code>\|\|</code>, `,`, `->`, unary `*` and `&`, `()`, `=` | the `fail_postfix_increment` split | Carbon has no interface for them | (by design, §2.7) |
| An impl whose operand has no C++ form | M-9, `unmappable_impl` | omitted: C++ cannot form the operand (D-OX-9 (1)) | (by design) |
| An impl whose result alone has no C++ form | M-27 | declared deleted (D-OX-9 (2)) | (by design) |
| An impl whose signature names a class C++ cannot export | M-20 (e) | the class's own export diagnostic at the C++ use, as for an overload-set member (D-OV-18; D-OX-9 (3)) | (the class's export; by design) |

(The W-208, W-210, W-211, D-OX-9 and M-28 rows amended 2026-10-14, review
fold: A-6, B-4, B-3, A-3, A-1, B-2.)

### §1.6 The diagnostic policy (D-OX-9)

Nothing is mapped for Carbon's own operator expressions (D-OX-21). For a C++
lookup, `ClassifyOperatorExport` decides each selected impl function before
anything is built. `IsUnmappableWithoutExport` strips `const`, pointer and
array types to their leaf; a class or function leaf is never reported
unmappable, because mapping it exports it; any other type is mapped, which
exports nothing, and a null mapping is "no C++ form". An operand with no C++
form omits the impl; a result with none, or an array result, makes a deleted
declaration; every other impl is exported, and its class types are exported as
for any declaration that names them, so a class C++ cannot export reports its
own semantics TODO at the C++ use (M-20 (e), as `v_trunk_holder_fn1.carbon` does
on trunk). Every other failure is Clang's own diagnostic at the C++ use
(`invalid operands to binary expression`, `no viable overloaded '+='`, `cannot
increment value of type`, `overload resolution selected deleted operator`),
with Clang's notes listing the exported candidates (M-11(c), M-27) (amended
2026-10-14, review fold: A-1, B-2).

### §1.7 Carbon's own expressions, and the divergences (D-OX-11, D-OX-15, D-OX-21)

Carbon's operator expressions ask C++ in two places, `BuildBinaryOperator` (and
`BuildUnaryOperator`) before Carbon's impl lookup and `LookupCppImpl` within it
(§0.1 row 9), both through `FindClangOperator`. That lookup exports nothing and
leaves nothing cached (D-OX-21), and a candidate C++ code exported earlier is
non-viable (D-OX-11), so Carbon sees exactly the C++ operator functions it saw
before OX-1: the Carbon impl stands where it stood, and a hand-written C++
operator it used is still used (M-22, M-26). In C++, the exported declarations
take part in ordinary C++ overload resolution, with the four documented
divergences of D-OX-15: operand conversions, base-class member lookup, the impl
function's own signature, and by-value operands (M-11(f), M-7, M-25). The first
three let C++ accept what Carbon does not; the fourth makes C++ reject an lvalue
operand of a class it cannot copy, which Carbon accepts (rev 1 said "C++ rejects
nothing Carbon accepts"; amended 2026-10-14, review fold: A-7). One more
C++-side change is not a divergence but a migration: C++ code that wrote its own
operator for an exported class to fill the gap now has two candidates (W-211,
M-22).

### §1.8 EXPECT re-derivation (R16(d): from the program text, never from a run)

Each value below follows from the program's Carbon impl bodies and C++ calls
alone; the runs of M-13 agree, and M-14's mutants disagree.

-   cpp_operator_export: `Make(30)+Make(12)` adds the `value` fields:
    `30+12=42`.
-   cpp_operator_export_arithmetic, from 700 and 250 cents: `700+250=950`;
    `700-250=450`; `700*3=2100`; `700/3=233` (`i32` division truncates toward
    zero, arithmetic.md "Integer types"); `700%3=1`; negation gives `-700`.
-   cpp_operator_export_compound, each from 10: `10+5=15`; `10-3=7`;
    `10*4=40`; `10/4=2`; `10%6=4`; two increments and a decrement give `11`.
-   cpp_operator_export_compare, with a = 1 and b = 2, each line
    100·(a op b) + 10·(a op a) + (b op a): `==` gives 0, 1 and 0, so `10`;
    `!=` 1, 0 and 1, so `101`; `<` 1, 0 and 0, so `100`; `<=` 1, 1 and 0, so
    `110`; `>` 0, 0 and 1, so `1`; `>=` 0, 1 and 1, so `11`; for `Unknowable`,
    value 0 against 1, `Equal` and the declared `NotEqual` are both false, so
    the line is 10·0 + 0 = `0` (the default `NotEqual` would make it 1)
    (amended 2026-10-14, review fold: A-8).
-   cpp_operator_export_bitwise, with x = 12 (`0b1100`) and y = 10 (`0b1010`)
    as `u8`: AND gives `8`, OR `14`, XOR `6`, the complement `255-12=243`, the
    left shift by two `48`, `128>>3=16`; z starts at 3 and becomes 12, 13, 12,
    9 and finally `4` under `<<=2`, `|=1`, `&=14`, `^=5` and `>>=1`.
-   cpp_operator_export_index, fields 7, 8 and 9: `7*100+8*10+9=789`;
    `t[true]` is the `bool` impl (an exact match beats the `bool`-to-`int`
    promotion), the last field, and `t[false]` the first: `9*10+7=97`.
-   cpp_operator_export_nonmember: `50-8=42` (the `i32` impl, `Self` on the
    left; the other order would give `-42`); then each comparison as
    100·(4 op m) + 10·(5 op m) + (6 op m) with m's 5 cents: `==` 0, 1, 0, so
    `10`; `!=`, through `NotEqual`'s default, 1, 0, 1, so `101`; `<` 1, 0, 0,
    so `100`; `<=` 1, 1, 0, so `110`; `>` 0, 0, 1, so `1`; `>=` 0, 1, 1, so
    `11`; `10-3=7` written back to the C++ `int`; `30+3=33` (amended
    2026-10-14, review fold: A-8).

### §1.9 Docs and records (D-OX-13, D-OX-14)

The design text is §2.7: a new page and a dated amendment. The records (§2.8)
are written by commit 5 (the row) and commit 6 (everything else, after the
merge of trunk and its re-verification, §3): W-054 discharged and its evidence
corrected; W-202..W-211 filed; W-007's notes extended; the row's status and
evidence; the header delta; the decision-log entry "OX-1 / F-017" with its
V-3a register entries; fork/ORCHESTRATION.md's stamp and Branches row; the
conformance README's generated table (amended 2026-10-14, review fold: B-5,
B-12).

### §1.10 Residues (ids reserved at the head; full ledger entries in §2.8)

| Id | Title | Bullet | blocked_by |
| --- | --- | --- | --- |
| W-202 | OX-1 residue: generic operator impls, and the operator impls of a generic class's specifics, are not exported to C++, so C++ may convert an operand to a concrete impl's type where Carbon selects the generic impl | the row | — |
| W-203 | Exporting a Carbon class imported from another library yields an empty C++ record: no fields, and a by-value result corrupts memory (upstream defect) | Type system: C++ interop — importing C++ types / exporting Carbon types | — |
| W-204 | OX-1 residue: operator impls declared in an imported library are not exported to C++ | the row | W-203 |
| W-205 | OX-1 residue: an operator impl declared after C++ code looked that operator up on the class or namespace is not seen by later C++ code | the row | — |
| W-206 | OX-1 residue: `<=>` is not exported; the prelude's `OrderedWith` has no `Compare` | the row | — |
| W-207 | OX-1 residue: two operator impls whose operand types map to one C++ type are ambiguous at every C++ use (the W-118 shape) | the row | — |
| W-208 | OX-1 residue (bounds the row): `As` and `ImplicitAs` impls are not exported as C++ conversions | the row | — |
| W-209 | OX-1 residue: `operator[]` returns by value; the `ref` forms of indexing are not exported | the row | W-109 |
| W-210 | OX-1 residue: operator impls with no Carbon class among their types (a C++ or primitive `Self` with a non-Carbon operand, or a unary impl on a C++ type) are not exported to C++ | the row | — |
| W-211 | OX-1 residue: a hand-written C++ operator for an exported Carbon class that duplicates a Carbon operator impl is ambiguous with the exported operator in C++ | the row | — |

(W-202's and W-208's titles and the W-210 and W-211 rows amended 2026-10-14,
review fold: B-2, A-6, B-4, B-3, A-3.)

## §2 Implementation spec, file by file

### §2.1 to §2.4 Toolchain (five files, one diff; clang-format 21.1.8 clean; compiled and measured as `v5`)

The diff below is `v5` (`$F/ox1-v5.diff`, sha256
d32f99f54a24f5d4ef61cffedafa5397917520e2ae9db401a5787e1f08919f04, 829 lines):
726 lines added and 4 removed over export.cpp (+625, −1), export.h (+27),
generate_ast.cpp (+41), operators.cpp (+22, −3) and context.h (+11). The copy
below is the same diff after prek, which strips the leading space of a blank
context line; it applies to f67ab650d with `git apply` and yields these files,
the identity check (amended 2026-10-14, review fold: A-10, B-7):

```text
49c2864fc23e07acd9606467956f838af444d940d5721efb7785911acdd96c1d  toolchain/check/cpp/context.h
c7a33d348709b6eafaf0027a38cf7352ffe547f752da8f7607bc49335c2a6d0c  toolchain/check/cpp/export.cpp
9df05ae30196789ab9ebf3db1d4416023acbec76af53b2a86a99f38941f4c70b  toolchain/check/cpp/export.h
6bc75af70f9cc134725fda3fba77b8b884a7a0ba88eeacf7414d53a8abb1ad41  toolchain/check/cpp/generate_ast.cpp
05d7751685f0a93fca8688a63974845c334b7c03afcafd405727e877799b51a1  toolchain/check/cpp/operators.cpp
```

It applies to every live branch's five files and to ST-1's with offset 5, and
needs three context refreshes on upstream/trunk (M-16); every file passes
`clang-format --style=file` from the CI pin (R18). Invariants, by hunk (rev 1's
`IsOperatorSignatureMappable` and the post-resolution guard are gone; amended
2026-10-14, review fold: A-1, A-2, A-3, A-4, A-5, B-1, B-2):

-   **context.h, `in_carbon_operator_lookup()` (new).** One `bool` member,
    appended after the existing ones, and its reference accessor (D-OX-21).
    Only operators.cpp sets it, with `llvm::SaveAndRestore`, and only
    generate_ast.cpp reads it.
-   **export.cpp, the includes and the table (new).** `OperatorExportTable` is
    §1.1; `num_explicit_params` separates `-a` from `a-b`.
    `IsOperatorImplOfKind` is the walks' SemIR-only first test (complete,
    non-generic, `Core`, a table row for the operator kind); `type_info.h` is
    included for `RecognizedTypeInfo`.
-   **export.cpp, `BuildCppToCarbonThunkBody` (the one in-function hunk,
    D-OX-16).** The `this` argument is passed only for a method; the
    non-member form's first parameter is `self` and is passed by the loop that
    follows like every other parameter, matching the generated Carbon thunk's
    parameter order (`self`, the explicit parameters, the result). For every
    existing caller the new conjunct is true: the body already does
    `cast<clang::CXXMethodDecl>(function_decl)` under `target.self_param`.
-   **export.cpp, the classification (D-OX-9).** `IsUnmappableWithoutExport`
    never maps a class or function type (whose mapping exports it) and maps
    every other type, which exports nothing; `ClassifyOperatorExport` returns
    `Omit` for an operand with no C++ form, `Deleted` for a result with none
    or an array result, and `Export` otherwise.
-   **export.cpp, the shared export path.** `GetImplMemberFunctionId` returns
    `None` for a member the impl leaves to its default and for a name the
    impl's checking poisoned (M-3), and rejects a function with an enclosing
    specific. `ExportImplFunctionAsCppOperator` reuses an earlier export
    through `clang_decls`, builds the `FunctionInfo` itself (the impl scope
    cannot be exported, M-2), checks the shape (a `self`, the row's parameter
    count), classifies, and then declares: a member operator to export by the
    existing `BuildCppToCarbonThunkDecl` with the operator's `DeclarationName`,
    a non-member or deleted one by `BuildCppOperatorDecl`; an exported one gets
    its body from the existing `BuildCppToCarbonThunk`; an exported or deleted
    one is registered (`RegisterExportedOperator`: the declaration with the
    all-by-value signature, mapped to the function's first declaration).
    `BuildCppOperatorDecl` maps each parameter with `MapToCppParamType` (a
    `ref` parameter becomes `S&`), reporting the same semantics TODOs as
    `BuildCppToCarbonThunkFunctionType` if a class export fails, gives a
    member `const` or `&` as an exported method has, and declares it inline,
    always-inline and internal-linkage, or deleted with a `void` result.
-   **export.cpp, the default `!=`.** `BuildDefaultNotEqualOperator` gives the
    new declaration `operator==`'s type, parameters, inline, always-inline and
    internal-linkage attributes, and the body `!(this->operator==(p))` or
    `!operator==(p0, p1)`, each by-value parameter passed as an xvalue
    (`ImplicitCastExpr` `CK_NoOp` to `VK_XValue`), under a `Sema::SFINAETrap`;
    if the call, the negation or the return is invalid, the declaration is
    removed and none is returned. A valid one goes to the AST consumer as
    `BuildCppToCarbonThunk` hands its decls on (export.cpp:1463-1464), so
    CodeGen emits it on use, and is registered under `Equal`'s first
    declaration (the reverse map keeps `operator==`, which was registered
    first).
-   **export.cpp, the walks.** `ExportImplOperators` takes one impl's rows for
    the operator (a non-member only binary rows, never `operator[]`) and
    builds the default `!=` from a non-deleted `operator==`.
    `ExportOperatorsToCpp` returns nothing for a specific of a generic class
    (W-202) and keeps the impls whose `Self` is the record's class.
    `ExportNonMemberOperatorsToCpp` keeps the impls whose `Self` is not a
    Carbon record class (`GetCarbonRecordClassType`, SemIR only) and whose
    one interface argument is one, exported, with this namespace as its
    innermost enclosing namespace (`getEnclosingNamespaceContext()->Equals`).
-   **export.cpp, `IsExportedCarbonOperator`.** True for an overloaded
    operator registered in `clang_decls` under the all-by-value signature and
    not imported: exactly the declarations OX-1 created, member or non-member,
    the default `!=` included, and never Clang's implicit members of an
    exported record. The signature is looked up, never added
    (`CanonicalValueStore::Lookup`).
-   **export.h.** Three declarations, with comments naming F-017 and the page.
-   **generate_ast.cpp, the `CXXOperatorName` arm.** Placed first in the
    switch, before `Identifier`. During Carbon's own lookup it erases the empty
    `StoredDeclsMap` entry `lookupImpl` created (`DeclContextInternals.h`) and
    returns false; otherwise record → member walk, namespace → non-member
    walk, an empty answer cached as none; the arm returns before the
    identifier-based lookup below it, which never sees an operator name.
-   **operators.cpp, `FindClangOperator`.** `LookupOverloadedBinOp` runs with
    `in_carbon_operator_lookup()` set (D-OX-21); then every candidate whose
    function `IsExportedCarbonOperator` recognizes is made non-viable, with
    `ovl_non_default_multiversion_function`, the failure kind Clang's
    `NoteFunctionCandidate` skips silently, before `BestViableFunction`, so
    the switch below sees Clang's result without exported operators (D-OX-11).

```diff
--- a/toolchain/check/cpp/context.h
+++ b/toolchain/check/cpp/context.h
@@ -69,6 +69,14 @@ class CppContext {
     boundary_write_decl_ = decl;
   }

+  // Whether Carbon's own operator lookup is asking Clang for C++ operator
+  // candidates (operators.cpp `FindClangOperator`). While it is, no Carbon
+  // operator impl is exported as a C++ operator and no answer for an operator
+  // name is cached (fork decision F-017).
+  auto in_carbon_operator_lookup() -> bool& {
+    return in_carbon_operator_lookup_;
+  }
+
  private:
   // The C++ compilation domain.
   SemIR::CppDomain* domain_;
@@ -97,6 +105,9 @@ class CppContext {

   // Listener for Clang diagnostics while checking this Carbon context.
   std::unique_ptr<CppDiagnosticListener> diagnostic_listener_;
+
+  // See `in_carbon_operator_lookup()`.
+  bool in_carbon_operator_lookup_ = false;
 };

 }  // namespace Carbon::Check
--- a/toolchain/check/cpp/export.cpp
+++ b/toolchain/check/cpp/export.cpp
@@ -12,6 +12,7 @@
 #include "clang/Sema/EnterExpressionEvaluationContext.h"
 #include "clang/Sema/Sema.h"
 #include "llvm/Support/Casting.h"
+#include "toolchain/check/core_identifier.h"
 #include "toolchain/check/cpp/access.h"
 #include "toolchain/check/cpp/import.h"
 #include "toolchain/check/cpp/location.h"
@@ -29,6 +30,7 @@
 #include "toolchain/sem_ir/generic.h"
 #include "toolchain/sem_ir/mangler.h"
 #include "toolchain/sem_ir/pattern.h"
+#include "toolchain/sem_ir/type_info.h"
 #include "toolchain/sem_ir/typed_insts.h"
 #include "toolchain/sem_ir/vtable.h"

@@ -1244,7 +1246,9 @@ static auto BuildCppToCarbonThunkBody(Context& context,

   llvm::SmallVector<clang::Expr*> call_args;
   // For methods, pass the `this` pointer as the first argument to the callee.
-  if (target.self_param) {
+  // A non-member operator (fork decision F-017) declares `self` as its first
+  // parameter instead, which the loop below passes like the others.
+  if (target.self_param && isa<clang::CXXMethodDecl>(function_decl)) {
     call_args.push_back(
         GetThisArg(sema, clang_loc, cast<clang::CXXMethodDecl>(function_decl)));
   }
@@ -1901,4 +1905,624 @@ auto ExportVarToCpp(Context& context, SemIR::InstId inst_id,
   return var_decl;
 }

+namespace {
+// One row of the operator export table (fork decision F-017): the `Core`
+// operator interface and member function that a C++ overloaded operator calls
+// when C++ applies it to an exported Carbon class that implements that
+// interface. The table is the inverse of the import direction's
+// `GetClangOperatorKind` (check/cpp/operators.cpp), restricted to the members
+// that are operators in C++.
+struct OperatorExportEntry {
+  CoreIdentifier interface_name;
+  CoreIdentifier member_name;
+  // The number of explicit parameters after `self`: 0 for a unary operator, 1
+  // for a binary operator.
+  int num_explicit_params;
+  clang::OverloadedOperatorKind op_kind;
+};
+}  // namespace
+
+static constexpr OperatorExportEntry OperatorExportTable[] = {
+    // Arithmetic.
+    {CoreIdentifier::AddWith, CoreIdentifier::Op, 1, clang::OO_Plus},
+    {CoreIdentifier::SubWith, CoreIdentifier::Op, 1, clang::OO_Minus},
+    {CoreIdentifier::MulWith, CoreIdentifier::Op, 1, clang::OO_Star},
+    {CoreIdentifier::DivWith, CoreIdentifier::Op, 1, clang::OO_Slash},
+    {CoreIdentifier::ModWith, CoreIdentifier::Op, 1, clang::OO_Percent},
+    {CoreIdentifier::Negate, CoreIdentifier::Op, 0, clang::OO_Minus},
+    // Bitwise and shift.
+    {CoreIdentifier::BitAndWith, CoreIdentifier::Op, 1, clang::OO_Amp},
+    {CoreIdentifier::BitOrWith, CoreIdentifier::Op, 1, clang::OO_Pipe},
+    {CoreIdentifier::BitXorWith, CoreIdentifier::Op, 1, clang::OO_Caret},
+    {CoreIdentifier::BitComplement, CoreIdentifier::Op, 0, clang::OO_Tilde},
+    {CoreIdentifier::LeftShiftWith, CoreIdentifier::Op, 1, clang::OO_LessLess},
+    {CoreIdentifier::RightShiftWith, CoreIdentifier::Op, 1,
+     clang::OO_GreaterGreater},
+    // Compound assignment.
+    {CoreIdentifier::AddAssignWith, CoreIdentifier::Op, 1, clang::OO_PlusEqual},
+    {CoreIdentifier::SubAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_MinusEqual},
+    {CoreIdentifier::MulAssignWith, CoreIdentifier::Op, 1, clang::OO_StarEqual},
+    {CoreIdentifier::DivAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_SlashEqual},
+    {CoreIdentifier::ModAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_PercentEqual},
+    {CoreIdentifier::BitAndAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_AmpEqual},
+    {CoreIdentifier::BitOrAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_PipeEqual},
+    {CoreIdentifier::BitXorAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_CaretEqual},
+    {CoreIdentifier::LeftShiftAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_LessLessEqual},
+    {CoreIdentifier::RightShiftAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_GreaterGreaterEqual},
+    // Increment and decrement: Carbon's are prefix only.
+    {CoreIdentifier::Inc, CoreIdentifier::Op, 0, clang::OO_PlusPlus},
+    {CoreIdentifier::Dec, CoreIdentifier::Op, 0, clang::OO_MinusMinus},
+    // Comparison. A `NotEqual` the impl does not declare is the interface's
+    // default, `not self.Equal(other)`, and is exported as `!(a == b)`
+    // (`BuildDefaultNotEqualOperator`).
+    {CoreIdentifier::EqWith, CoreIdentifier::Equal, 1, clang::OO_EqualEqual},
+    {CoreIdentifier::EqWith, CoreIdentifier::NotEqual, 1,
+     clang::OO_ExclaimEqual},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::Less, 1, clang::OO_Less},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::LessOrEquivalent, 1,
+     clang::OO_LessEqual},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::Greater, 1,
+     clang::OO_Greater},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::GreaterOrEquivalent, 1,
+     clang::OO_GreaterEqual},
+    // Indexing.
+    {CoreIdentifier::IndexWith, CoreIdentifier::At, 1, clang::OO_Subscript},
+};
+
+// Returns whether `impl` is a complete, non-generic impl of a `Core` interface
+// that has a row in `OperatorExportTable` for `op_kind`. Only the impl's SemIR
+// is read, so an impl that is not an operator of this kind is never mapped to
+// C++.
+static auto IsOperatorImplOfKind(Context& context, const SemIR::Impl& impl,
+                                 clang::OverloadedOperatorKind op_kind)
+    -> bool {
+  if (!impl.is_complete() || impl.generic_id.has_value() ||
+      !impl.interface.interface_id.has_value()) {
+    return false;
+  }
+  const auto& interface = context.interfaces().Get(impl.interface.interface_id);
+  if (!context.name_scopes().IsCorePackage(interface.parent_scope_id)) {
+    return false;
+  }
+  return llvm::any_of(
+      OperatorExportTable, [&](const OperatorExportEntry& entry) {
+        return entry.op_kind == op_kind &&
+               context.core_identifiers().AddNameId(entry.interface_name) ==
+                   interface.name_id;
+      });
+}
+
+// Returns whether `type_id` has no C++ mapping, decided without exporting
+// anything to C++. Mapping a class or function type exports that entity (which
+// can diagnose), so such a type is never reported unmappable here; mapping any
+// other type exports nothing.
+static auto IsUnmappableWithoutExport(Context& context, SemIR::TypeId type_id)
+    -> bool {
+  for (auto inner_type_id = type_id;;) {
+    auto inst = context.types().GetAsInst(inner_type_id);
+    if (auto const_type = inst.TryAs<SemIR::ConstType>()) {
+      inner_type_id =
+          context.types().GetTypeIdForTypeInstId(const_type->inner_id);
+    } else if (auto pointer_type = inst.TryAs<SemIR::PointerType>()) {
+      inner_type_id =
+          context.types().GetTypeIdForTypeInstId(pointer_type->pointee_id);
+    } else if (auto array_type = inst.TryAs<SemIR::ArrayType>()) {
+      inner_type_id = context.types().GetTypeIdForTypeInstId(
+          array_type->element_type_inst_id);
+    } else if (inst.Is<SemIR::ClassType>() || inst.Is<SemIR::FunctionType>()) {
+      return false;
+    } else {
+      break;
+    }
+  }
+  return MapToCppType(context, type_id).isNull();
+}
+
+namespace {
+// How an operator impl's function is exported (fork decision F-017).
+enum class OperatorExportKind : uint8_t {
+  // Declared and defined, calling the impl's function.
+  Export,
+  // Declared deleted: the result has no by-value C++ form.
+  Deleted,
+  // Not declared: an operand has no C++ form.
+  Omit,
+};
+}  // namespace
+
+// Classifies `target`, an operator impl's function. C++ cannot form an operand
+// of a type that has no C++ mapping, so omitting such an impl cannot change
+// which impl a C++ expression selects. An impl whose result alone has no
+// by-value C++ form is declared deleted, so that a C++ expression that would
+// select it is rejected rather than resolved to another impl by a conversion.
+// A class type in the signature is exported, and a failure to export it is
+// diagnosed at that C++ use, as for any exported declaration that names it.
+static auto ClassifyOperatorExport(Context& context, const FunctionInfo& target)
+    -> OperatorExportKind {
+  if (IsUnmappableWithoutExport(context, target.self_param->type_id) ||
+      llvm::any_of(target.explicit_params,
+                   [&](const FunctionInfo::Param& param) {
+                     return IsUnmappableWithoutExport(context, param.type_id);
+                   })) {
+    return OperatorExportKind::Omit;
+  }
+  if (target.return_type_id.has_value() &&
+      (IsUnmappableWithoutExport(context, target.return_type_id) ||
+       context.types().Is<SemIR::ArrayType>(target.return_type_id))) {
+    return OperatorExportKind::Deleted;
+  }
+  return OperatorExportKind::Export;
+}
+
+// Returns the function that `impl` declares as its `member_name`, or `None`
+// when the impl leaves that member to the interface's `default fn`.
+static auto GetImplMemberFunctionId(Context& context, const SemIR::Impl& impl,
+                                    CoreIdentifier member_name)
+    -> SemIR::FunctionId {
+  auto& impl_scope = context.name_scopes().Get(impl.scope_id);
+  auto entry_id =
+      impl_scope.Lookup(context.core_identifiers().AddNameId(member_name));
+  if (!entry_id) {
+    return SemIR::FunctionId::None;
+  }
+  // A name the impl does not declare can still have an entry: checking the
+  // impl poisons the names it looked up in its own scope.
+  const auto& result = impl_scope.GetEntry(*entry_id).result;
+  if (!result.is_found()) {
+    return SemIR::FunctionId::None;
+  }
+  LoadImportRef(context, result.target_inst_id());
+  auto callee = SemIR::GetCallee(context.sem_ir(), result.target_inst_id());
+  auto* callee_function = std::get_if<SemIR::CalleeFunction>(&callee);
+  if (!callee_function || callee_function->enclosing_specific_id.has_value()) {
+    return SemIR::FunctionId::None;
+  }
+  return callee_function->function_id;
+}
+
+// Returns the `clang_decls` signature under which an exported operator is
+// registered: every parameter by value.
+static auto GetExportedOperatorSignature(const clang::FunctionDecl* decl)
+    -> SemIR::ClangDeclSignature {
+  SemIR::ClangDeclSignature signature{
+      .kind = SemIR::ClangDeclSignature::Normal,
+      .num_params = static_cast<int32_t>(decl->getNumParams())};
+  signature.passing_modes.assign(
+      signature.num_params, SemIR::ClangDeclSignature::PassingMode::ByValue);
+  return signature;
+}
+
+// Records `operator_decl` as the C++ export of `inst_id`, so that a later
+// lookup reuses it and `IsExportedCarbonOperator` recognizes it.
+static auto RegisterExportedOperator(Context& context,
+                                     clang::FunctionDecl* operator_decl,
+                                     SemIR::InstId inst_id) -> void {
+  context.clang_decls().Add(
+      {.key = SemIR::ClangDeclKey::ForFunctionDecl(
+           operator_decl, context.clang_decl_signatures().Add(
+                              GetExportedOperatorSignature(operator_decl))),
+       .inst_id = inst_id});
+}
+
+// Declares the C++ operator `op_kind` for `target` in `decl_context`: a member
+// of a record, whose `self` is the object parameter, or a non-member of a
+// namespace, whose first parameter is `self`. A deleted declaration returns
+// `void`. Returns null after a diagnostic if a type does not map.
+static auto BuildCppOperatorDecl(Context& context, SemIR::LocId loc_id,
+                                 const FunctionInfo& target,
+                                 clang::DeclContext* decl_context,
+                                 clang::OverloadedOperatorKind op_kind,
+                                 bool deleted) -> clang::FunctionDecl* {
+  clang::ASTContext& ast_context = context.ast_context();
+  auto clang_loc = GetCppLocation(context, loc_id);
+  auto* record_decl = dyn_cast<clang::CXXRecordDecl>(decl_context);
+
+  llvm::SmallVector<FunctionInfo::Param> params;
+  if (!record_decl) {
+    params.push_back(*target.self_param);
+  }
+  llvm::append_range(params, target.explicit_params);
+  llvm::SmallVector<clang::QualType> param_types;
+  for (const auto& param : params) {
+    auto cpp_type = MapToCppParamType(context, loc_id, param);
+    if (cpp_type.isNull()) {
+      context.TODO(loc_id, "failed to map Carbon type to C++");
+      return nullptr;
+    }
+    param_types.push_back(cpp_type);
+  }
+  clang::QualType return_type = ast_context.VoidTy;
+  if (!deleted && target.return_type_id.has_value()) {
+    return_type = MapToCppType(context, target.return_type_id);
+    if (return_type.isNull()) {
+      context.TODO(loc_id, "failed to map Carbon return type to C++ type");
+      return nullptr;
+    }
+  }
+  clang::FunctionProtoType::ExtProtoInfo ext_proto_info;
+  if (record_decl) {
+    // As for an exported method: `ref self` is `&`, `self` is `const`.
+    if (target.self_param->kind == ParamPatternKind::Ref) {
+      ext_proto_info.RefQualifier = clang::RQ_LValue;
+    } else {
+      ext_proto_info.TypeQuals.addConst();
+    }
+  }
+  auto function_type =
+      ast_context.getFunctionType(return_type, param_types, ext_proto_info);
+  clang::DeclarationNameInfo name_info(
+      ast_context.DeclarationNames.getCXXOperatorName(op_kind), clang_loc);
+  auto* tinfo = ast_context.getTrivialTypeSourceInfo(function_type, clang_loc);
+  clang::FunctionDecl* function_decl = nullptr;
+  if (record_decl) {
+    function_decl = clang::CXXMethodDecl::Create(
+        ast_context, record_decl, clang_loc, name_info, function_type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInline=*/true,
+        clang::ConstexprSpecKind::Unspecified, clang_loc,
+        clang::AssociatedConstraint());
+    function_decl->setAccess(clang::AS_public);
+  } else {
+    function_decl = clang::FunctionDecl::Create(
+        ast_context, decl_context, clang_loc, name_info, function_type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true,
+        /*hasWrittenPrototype=*/true, clang::ConstexprSpecKind::Unspecified,
+        clang::AssociatedConstraint());
+  }
+  llvm::SmallVector<clang::ParmVarDecl*> param_decls;
+  for (auto type : param_types) {
+    param_decls.push_back(clang::ParmVarDecl::Create(
+        ast_context, function_decl, clang_loc, clang_loc, /*Id=*/nullptr, type,
+        /*TInfo=*/nullptr, clang::SC_None, /*DefArg=*/nullptr));
+  }
+  function_decl->setParams(param_decls);
+  decl_context->addHiddenDecl(function_decl);
+  if (deleted) {
+    function_decl->setDeletedAsWritten();
+  } else {
+    function_decl->addAttr(
+        clang::AlwaysInlineAttr::CreateImplicit(ast_context));
+    function_decl->addAttr(
+        clang::InternalLinkageAttr::CreateImplicit(ast_context));
+  }
+  return function_decl;
+}
+
+// Exports `function_id`, an impl's member, as the C++ operator `entry.op_kind`
+// of `decl_context`: a member operator of a record, through the same C++ and
+// Carbon thunks as an exported method, or a non-member operator of a
+// namespace. Returns null if the function's shape is not the operator's or the
+// impl is omitted (`ClassifyOperatorExport`).
+static auto ExportImplFunctionAsCppOperator(Context& context,
+                                            clang::DeclContext* decl_context,
+                                            SemIR::FunctionId function_id,
+                                            const OperatorExportEntry& entry)
+    -> clang::FunctionDecl* {
+  const auto& function = context.functions().Get(function_id);
+  SemIR::LocId loc_id(function.first_decl_id());
+
+  // Reuse an earlier export of this function.
+  if (const auto* clang_decl =
+          context.clang_decls().Lookup(function.first_decl_id())) {
+    return dyn_cast<clang::FunctionDecl>(clang_decl->decl());
+  }
+
+  FunctionInfo target(context, function_id, function, decl_context,
+                      /*export_as_constructor=*/false);
+  if (!target.self_param || static_cast<int>(target.explicit_params.size()) !=
+                                entry.num_explicit_params) {
+    return nullptr;
+  }
+  clang::FunctionDecl* operator_decl = nullptr;
+  switch (ClassifyOperatorExport(context, target)) {
+    case OperatorExportKind::Omit:
+      return nullptr;
+    case OperatorExportKind::Deleted:
+      operator_decl = BuildCppOperatorDecl(context, loc_id, target,
+                                           decl_context, entry.op_kind,
+                                           /*deleted=*/true);
+      break;
+    case OperatorExportKind::Export:
+      // A member operator is declared exactly as an exported method is.
+      operator_decl =
+          isa<clang::CXXRecordDecl>(decl_context)
+              ? BuildCppToCarbonThunkDecl(
+                    context, loc_id, target,
+                    context.ast_context().DeclarationNames.getCXXOperatorName(
+                        entry.op_kind))
+              : BuildCppOperatorDecl(context, loc_id, target, decl_context,
+                                     entry.op_kind, /*deleted=*/false);
+      if (operator_decl) {
+        BuildCppToCarbonThunk(context, loc_id, target, operator_decl,
+                              /*extra_name=*/"");
+      }
+      break;
+  }
+  if (!operator_decl) {
+    return nullptr;
+  }
+  RegisterExportedOperator(context, operator_decl, function.first_decl_id());
+  return operator_decl;
+}
+
+// Builds `operator!=` for an `EqWith` impl that leaves `NotEqual` to its
+// default, `not self.Equal(other)` (docs/design/expressions/
+// comparison_operators.md, "Equality"), as `!(a == b)` over the exported
+// `operator==`, beside it and of the same form, member or non-member: C++17
+// does not rewrite `a != b` itself. Each by-value parameter is passed on as an
+// xvalue, as a C++ implicit move would, so a move-only class works; if the call
+// is still invalid (a class C++ can neither copy nor move), no `operator!=` is
+// declared and nothing is diagnosed.
+static auto BuildDefaultNotEqualOperator(Context& context,
+                                         clang::FunctionDecl* equal_decl,
+                                         SemIR::InstId equal_inst_id)
+    -> clang::FunctionDecl* {
+  clang::ASTContext& ast_context = context.ast_context();
+  clang::Sema& sema = context.clang_sema();
+  auto clang_loc = equal_decl->getLocation();
+  auto* decl_context = equal_decl->getDeclContext();
+
+  clang::DeclarationNameInfo name_info(
+      ast_context.DeclarationNames.getCXXOperatorName(clang::OO_ExclaimEqual),
+      clang_loc);
+  auto type = equal_decl->getType();
+  auto* tinfo = ast_context.getTrivialTypeSourceInfo(type, clang_loc);
+  auto* equal_method_decl = dyn_cast<clang::CXXMethodDecl>(equal_decl);
+  clang::FunctionDecl* not_equal_decl = nullptr;
+  if (equal_method_decl) {
+    not_equal_decl = clang::CXXMethodDecl::Create(
+        ast_context, equal_method_decl->getParent(), clang_loc, name_info, type,
+        tinfo, clang::SC_None, /*UsesFPIntrin=*/false,
+        /*isInline=*/true, clang::ConstexprSpecKind::Unspecified, clang_loc,
+        clang::AssociatedConstraint());
+    not_equal_decl->setAccess(clang::AS_public);
+  } else {
+    not_equal_decl = clang::FunctionDecl::Create(
+        ast_context, decl_context, clang_loc, name_info, type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true,
+        /*hasWrittenPrototype=*/true, clang::ConstexprSpecKind::Unspecified,
+        clang::AssociatedConstraint());
+  }
+  llvm::SmallVector<clang::ParmVarDecl*> params;
+  for (const auto* equal_param : equal_decl->parameters()) {
+    params.push_back(clang::ParmVarDecl::Create(
+        ast_context, not_equal_decl, clang_loc, clang_loc, /*Id=*/nullptr,
+        equal_param->getType(), /*TInfo=*/nullptr, clang::SC_None,
+        /*DefArg=*/nullptr));
+  }
+  not_equal_decl->setParams(params);
+  decl_context->addHiddenDecl(not_equal_decl);
+  not_equal_decl->addAttr(clang::AlwaysInlineAttr::CreateImplicit(ast_context));
+  not_equal_decl->addAttr(
+      clang::InternalLinkageAttr::CreateImplicit(ast_context));
+
+  bool valid = false;
+  {
+    clang::Sema::ContextRAII context_raii(sema, not_equal_decl);
+    clang::EnterExpressionEvaluationContext evaluated(
+        sema, clang::Sema::ExpressionEvaluationContext::PotentiallyEvaluated);
+    clang::Sema::SFINAETrap trap(sema);
+    sema.ActOnStartOfFunctionDef(nullptr, not_equal_decl);
+    llvm::SmallVector<clang::Expr*> args;
+    for (auto* param : params) {
+      clang::Expr* arg =
+          sema.BuildDeclRefExpr(param, param->getType().getNonReferenceType(),
+                                clang::VK_LValue, clang_loc);
+      if (!param->getType()->isReferenceType()) {
+        arg = clang::ImplicitCastExpr::Create(
+            ast_context, param->getType(), clang::CK_NoOp, arg,
+            /*BasePath=*/nullptr, clang::VK_XValue, clang::FPOptionsOverride());
+      }
+      args.push_back(arg);
+    }
+    clang::ExprResult equal_call;
+    if (equal_method_decl) {
+      auto* member_expr = sema.BuildMemberExpr(
+          GetThisArg(sema, clang_loc,
+                     cast<clang::CXXMethodDecl>(not_equal_decl)),
+          /*IsArrow=*/false, clang_loc, clang::NestedNameSpecifierLoc(),
+          clang::SourceLocation(), equal_method_decl,
+          clang::DeclAccessPair::make(equal_method_decl, clang::AS_public),
+          /*HadMultipleCandidates=*/false,
+          clang::DeclarationNameInfo(equal_decl->getDeclName(), clang_loc),
+          ast_context.BoundMemberTy, clang::VK_PRValue, clang::OK_Ordinary);
+      equal_call = sema.BuildCallToMemberFunction(/*S=*/nullptr, member_expr,
+                                                  clang_loc, args, clang_loc);
+    } else {
+      clang::ExprResult callee = sema.BuildDeclRefExpr(
+          equal_decl, equal_decl->getType(), clang::VK_LValue, clang_loc);
+      equal_call = sema.BuildCallExpr(/*S=*/nullptr, callee.get(), clang_loc,
+                                      args, clang_loc);
+    }
+    clang::StmtResult return_stmt = clang::StmtError();
+    if (equal_call.isUsable() && !trap.hasErrorOccurred()) {
+      auto not_expr = sema.CreateBuiltinUnaryOp(clang_loc, clang::UO_LNot,
+                                                equal_call.get());
+      if (not_expr.isUsable()) {
+        return_stmt = sema.BuildReturnStmt(clang_loc, not_expr.get());
+      }
+    }
+    llvm::SmallVector<clang::Stmt*, 1> stmts;
+    valid = return_stmt.isUsable() && !trap.hasErrorOccurred();
+    if (valid) {
+      stmts.push_back(return_stmt.get());
+    }
+    sema.ActOnFinishFunctionBody(
+        not_equal_decl, clang::CompoundStmt::Create(ast_context, stmts,
+                                                    clang::FPOptionsOverride(),
+                                                    clang_loc, clang_loc));
+  }
+  if (!valid) {
+    not_equal_decl->setInvalidDecl();
+    decl_context->removeDecl(not_equal_decl);
+    return nullptr;
+  }
+  sema.getASTConsumer().HandleTopLevelDecl(clang::DeclGroupRef(not_equal_decl));
+  RegisterExportedOperator(context, not_equal_decl, equal_inst_id);
+  return not_equal_decl;
+}
+
+// Exports the members of `impl` that C++ spells `op_kind` as operators of
+// `decl_context` (the member walk's record or the non-member walk's
+// namespace), appending them to `operator_decls`.
+static auto ExportImplOperators(
+    Context& context, const SemIR::Impl& impl, clang::DeclContext* decl_context,
+    clang::OverloadedOperatorKind op_kind,
+    llvm::SmallVectorImpl<clang::NamedDecl*>& operator_decls) -> void {
+  const auto& interface = context.interfaces().Get(impl.interface.interface_id);
+  bool is_member = isa<clang::CXXRecordDecl>(decl_context);
+  for (const auto& entry : OperatorExportTable) {
+    // C++ requires `operator[]` to be a member, and a non-member operator has
+    // the operand that argument-dependent lookup found it by.
+    if (entry.op_kind != op_kind ||
+        context.core_identifiers().AddNameId(entry.interface_name) !=
+            interface.name_id ||
+        (!is_member && (entry.num_explicit_params != 1 ||
+                        entry.op_kind == clang::OO_Subscript))) {
+      continue;
+    }
+    clang::FunctionDecl* operator_decl = nullptr;
+    if (auto function_id =
+            GetImplMemberFunctionId(context, impl, entry.member_name);
+        function_id.has_value()) {
+      operator_decl = ExportImplFunctionAsCppOperator(context, decl_context,
+                                                      function_id, entry);
+    } else if (entry.member_name == CoreIdentifier::NotEqual) {
+      if (auto equal_id =
+              GetImplMemberFunctionId(context, impl, CoreIdentifier::Equal);
+          equal_id.has_value()) {
+        if (auto* equal_decl = ExportImplFunctionAsCppOperator(
+                context, decl_context, equal_id,
+                {.interface_name = CoreIdentifier::EqWith,
+                 .member_name = CoreIdentifier::Equal,
+                 .num_explicit_params = 1,
+                 .op_kind = clang::OO_EqualEqual});
+            equal_decl && !equal_decl->isDeleted()) {
+          operator_decl = BuildDefaultNotEqualOperator(
+              context, equal_decl,
+              context.functions().Get(equal_id).first_decl_id());
+        }
+      }
+    }
+    if (operator_decl) {
+      operator_decls.push_back(operator_decl);
+    }
+  }
+}
+
+auto ExportOperatorsToCpp(Context& context, clang::CXXRecordDecl* record_decl,
+                          clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*> {
+  llvm::SmallVector<clang::NamedDecl*> operator_decls;
+  auto carbon_class =
+      SemIR::GetAsCarbonOwnedClass(context.sem_ir(), record_decl);
+  if (!carbon_class) {
+    return operator_decls;
+  }
+  auto [class_type_id, class_type] = *carbon_class;
+  // TODO: Export the operator impls of a generic class's specifics.
+  if (class_type.specific_id.has_value()) {
+    return operator_decls;
+  }
+  auto class_const_id = context.types().GetConstantId(class_type_id);
+
+  // Impls are visited in the order they were added to the file, which is
+  // declaration order for the impls this file declares. Only an impl whose
+  // `Self` is exactly this class exports here, as a member operator, so C++
+  // finds it by member lookup on the left operand as Carbon finds it by impl
+  // lookup on `Self`.
+  for (const auto& impl : context.impls().values()) {
+    if (IsOperatorImplOfKind(context, impl, op_kind) &&
+        context.constant_values().Get(impl.self_id) == class_const_id) {
+      ExportImplOperators(context, impl, record_decl, op_kind, operator_decls);
+    }
+  }
+  return operator_decls;
+}
+
+// Returns the class type that `type_inst_id` names if it is a class defined in
+// Carbon that is not a recognized type (such as `i32`), which C++ sees as a
+// record of its own.
+static auto GetCarbonRecordClassType(Context& context,
+                                     SemIR::InstId type_inst_id)
+    -> std::optional<SemIR::ClassType> {
+  auto class_type = context.constant_values().TryGetInstAs<SemIR::ClassType>(
+      context.constant_values().Get(type_inst_id));
+  if (!class_type) {
+    return std::nullopt;
+  }
+  const auto& class_info = context.classes().Get(class_type->class_id);
+  if (!class_info.scope_id.has_value() ||
+      context.name_scopes().Get(class_info.scope_id).is_cpp_scope() ||
+      SemIR::RecognizedTypeInfo::ForType(context.sem_ir(), *class_type).kind !=
+          SemIR::RecognizedTypeInfo::None) {
+    return std::nullopt;
+  }
+  return class_type;
+}
+
+auto ExportNonMemberOperatorsToCpp(Context& context,
+                                   clang::NamespaceDecl* namespace_decl,
+                                   clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*> {
+  llvm::SmallVector<clang::NamedDecl*> operator_decls;
+  for (const auto& impl : context.impls().values()) {
+    // A binary operator impl whose operand type is a Carbon class exported
+    // with this namespace as its innermost enclosing namespace, where C++'s
+    // argument-dependent lookup on that operand looks, and whose `Self` is not
+    // a Carbon class: such a `Self` has the impl as a member operator instead
+    // (`ExportOperatorsToCpp`). Only SemIR is read before the impl is known
+    // to be one.
+    if (!IsOperatorImplOfKind(context, impl, op_kind) ||
+        !impl.interface.specific_id.has_value() ||
+        GetCarbonRecordClassType(context, impl.self_id)) {
+      continue;
+    }
+    auto args = context.inst_blocks().Get(
+        context.specifics().Get(impl.interface.specific_id).args_id);
+    if (args.size() != 1) {
+      continue;
+    }
+    auto operand_class = GetCarbonRecordClassType(context, args.front());
+    if (!operand_class || operand_class->specific_id.has_value()) {
+      continue;
+    }
+    const auto* operand_decl = context.clang_decls().Lookup(
+        context.classes().Get(operand_class->class_id).first_decl_id());
+    if (!operand_decl || !operand_decl->decl()
+                              ->getDeclContext()
+                              ->getEnclosingNamespaceContext()
+                              ->Equals(namespace_decl)) {
+      continue;
+    }
+    ExportImplOperators(context, impl, namespace_decl, op_kind, operator_decls);
+  }
+  return operator_decls;
+}
+
+auto IsExportedCarbonOperator(Context& context,
+                              const clang::FunctionDecl* function_decl)
+    -> bool {
+  if (!function_decl->isOverloadedOperator()) {
+    return false;
+  }
+  auto signature_id = context.clang_decl_signatures().Lookup(
+      GetExportedOperatorSignature(function_decl));
+  if (!signature_id.has_value()) {
+    return false;
+  }
+  auto clang_decl_id =
+      context.clang_decls().LookupId(SemIR::ClangDeclKey::ForFunctionDecl(
+          const_cast<clang::FunctionDecl*>(function_decl), signature_id));
+  return clang_decl_id.has_value() &&
+         !context.clang_decls().Get(clang_decl_id).is_imported;
+}
+
 }  // namespace Carbon::Check
--- a/toolchain/check/cpp/export.h
+++ b/toolchain/check/cpp/export.h
@@ -141,6 +141,33 @@ auto ExportDestructorToCpp(Context& context, const SemIR::Class& class_info,
 auto ExportVarToCpp(Context& context, SemIR::InstId inst_id,
                     SemIR::VarStorage var_storage) -> clang::VarDecl*;

+// Exports the operator impls of the Carbon class behind `record_decl` that C++
+// spells as `op_kind` as member operators of `record_decl`, and returns them
+// (fork decision F-017; docs/design/interoperability/operators.md). Only a
+// complete, non-generic impl in this file whose `Self` is exactly the class
+// exports. An impl with an operand that has no C++ mapping is omitted, and one
+// whose result alone has none is declared deleted. Returns an empty list when
+// no impl exports.
+auto ExportOperatorsToCpp(Context& context, clang::CXXRecordDecl* record_decl,
+                          clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*>;
+
+// Exports the binary operator impls whose `Self` is not a Carbon class and
+// whose operand type is an exported Carbon class whose innermost enclosing
+// namespace is `namespace_decl`, as non-member operators of that namespace that
+// C++ finds by argument-dependent lookup on the operand (fork decision F-017).
+// Returns them.
+auto ExportNonMemberOperatorsToCpp(Context& context,
+                                   clang::NamespaceDecl* namespace_decl,
+                                   clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*>;
+
+// Returns whether `function_decl` is a Carbon operator impl exported to C++ by
+// `ExportOperatorsToCpp` or `ExportNonMemberOperatorsToCpp`, a default
+// `operator!=` among them.
+auto IsExportedCarbonOperator(Context& context,
+                              const clang::FunctionDecl* function_decl) -> bool;
+
 }  // namespace Carbon::Check

 #endif  // CARBON_TOOLCHAIN_CHECK_CPP_EXPORT_H_
--- a/toolchain/check/cpp/generate_ast.cpp
+++ b/toolchain/check/cpp/generate_ast.cpp
@@ -9,6 +9,7 @@

 #include "clang/AST/ASTContext.h"
 #include "clang/AST/Decl.h"
+#include "clang/AST/DeclContextInternals.h"
 #include "clang/AST/Mangle.h"
 #include "clang/Basic/DiagnosticParse.h"
 #include "clang/Basic/FileManager.h"
@@ -363,6 +364,46 @@ auto CarbonExternalASTSource::FindExternalVisibleDeclsByName(

   clang::IdentifierInfo* identifier = nullptr;
   switch (decl_name.getNameKind()) {
+    case clang::DeclarationName::CXXOperatorName: {
+      // A C++ overloaded operator applied to an exported Carbon class finds
+      // the class's Carbon operator impls by member lookup (fork decision
+      // F-017), and an impl whose `Self` is not a Carbon class by
+      // argument-dependent lookup in its operand class's namespace. No other
+      // Carbon entity answers an operator name.
+      auto* mutable_decl_context =
+          const_cast<clang::DeclContext*>(decl_context);
+      if (context_->cpp_context()->in_carbon_operator_lookup()) {
+        // Carbon's own operator lookup asks C++ for C++ operator functions,
+        // never for a Carbon impl, which its impl lookup finds: it exports
+        // nothing and leaves no answer cached, so that a later C++ lookup of
+        // this name still exports every impl. Remove the empty entry
+        // `DeclContext::lookupImpl` created for this name.
+        if (auto* lookup_map =
+                mutable_decl_context->getPrimaryContext()->getLookupPtr()) {
+          if (auto it = lookup_map->find(decl_name);
+              it != lookup_map->end() && it->second.isNull()) {
+            lookup_map->erase(it);
+          }
+        }
+        return false;
+      }
+      llvm::SmallVector<clang::NamedDecl*> operator_decls;
+      if (auto* record_decl =
+              dyn_cast<clang::CXXRecordDecl>(mutable_decl_context)) {
+        operator_decls = ExportOperatorsToCpp(
+            *context_, record_decl, decl_name.getCXXOverloadedOperator());
+      } else if (auto* namespace_decl =
+                     dyn_cast<clang::NamespaceDecl>(mutable_decl_context)) {
+        operator_decls = ExportNonMemberOperatorsToCpp(
+            *context_, namespace_decl, decl_name.getCXXOverloadedOperator());
+      }
+      if (operator_decls.empty()) {
+        SetNoExternalVisibleDeclsForName(decl_context, decl_name);
+        return false;
+      }
+      SetExternalVisibleDeclsForName(decl_context, decl_name, operator_decls);
+      return true;
+    }
     case clang::DeclarationName::Identifier: {
       identifier = decl_name.getAsIdentifierInfo();
       break;
--- a/toolchain/check/cpp/operators.cpp
+++ b/toolchain/check/cpp/operators.cpp
@@ -7,10 +7,12 @@
 #include "clang/Sema/Initialization.h"
 #include "clang/Sema/Overload.h"
 #include "clang/Sema/Sema.h"
+#include "llvm/Support/SaveAndRestore.h"
 #include "toolchain/base/kind_switch.h"
 #include "toolchain/check/convert.h"
 #include "toolchain/check/core_identifier.h"
 #include "toolchain/check/cpp/custom_type_mapping.h"
+#include "toolchain/check/cpp/export.h"
 #include "toolchain/check/cpp/import.h"
 #include "toolchain/check/cpp/location.h"
 #include "toolchain/check/cpp/overload_resolution.h"
@@ -873,9 +875,26 @@ static auto FindClangOperator(Context& context, SemIR::LocId loc_id,

   clang::Sema& sema = context.clang_sema();

-  // This works for both unary and binary operators.
-  sema.LookupOverloadedBinOp(candidate_set, op_kind, clang::UnresolvedSet<0>{},
-                             arg_exprs);
+  // This works for both unary and binary operators. Carbon's own lookup
+  // exports no Carbon operator impl to C++ (fork decision F-017).
+  {
+    llvm::SaveAndRestore in_carbon_operator_lookup(
+        context.cpp_context()->in_carbon_operator_lookup(), true);
+    sema.LookupOverloadedBinOp(candidate_set, op_kind,
+                               clang::UnresolvedSet<0>{}, arg_exprs);
+  }
+  // A Carbon operator impl that C++ code exported earlier is not a C++ operator
+  // function but Carbon's own impl seen from C++, which Carbon's impl lookup
+  // finds itself: it is no candidate here, so every result below is the one
+  // Clang gives without it. `ovl_non_default_multiversion_function` is the
+  // failure kind Clang itself ignores silently in its notes.
+  for (auto& candidate : candidate_set) {
+    if (candidate.Function &&
+        IsExportedCarbonOperator(context, candidate.Function)) {
+      candidate.Viable = false;
+      candidate.FailureKind = clang::ovl_non_default_multiversion_function;
+    }
+  }

   clang::OverloadCandidateSet::iterator best_viable_fn;
   switch (candidate_set.BestViableFunction(sema, loc, best_viable_fn)) {
```

### §2.5 Goldens (sources only: `// AUTOUPDATE`, no CHECK lines; R15, R16(a))

Four new files, filled only by autoupdate (commit 4): rev 2 adds
operator_cxx20.carbon and 23 splits (amended 2026-10-14, review fold: A-1,
A-2, A-3, A-4, A-5, A-7, A-9, B-1, B-2, B-3, B-10). Splits whose name begins
`fail_` must fail; the others must compile (M-12 measured both ways on trunk,
`v4` and `v5`). No existing golden changes (M-8).

#### toolchain/check/testdata/interop/cpp/class/export/operator.carbon (36 splits)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator.carbon

// Carbon operator impls on an exported Carbon class are C++ operators (fork
// decision F-017, docs/design/interoperability/operators.md): an impl whose
// `Self` is the class is a member operator, `const` for a `self` member and
// lvalue-ref-qualified (`&`) for a `ref self` one; an impl whose `Self` C++
// sees as anything else and whose operand is the class is a non-member
// operator in the class's innermost enclosing namespace, found by
// argument-dependent lookup. An impl with an operand that has no C++ form is
// omitted, and one whose result alone has none is declared deleted. Carbon's
// own operator expressions export nothing, and an exported operator is never a
// C++ candidate for them (the `carbon_side_*` splits). The `static_assert`s
// pin the C++ result types. The sibling operator_ast.carbon pins the
// declarations Clang is handed, operator_cxx20.carbon the C++20 behavior, and
// lower/.../operator.carbon the thunks.

// --- arithmetic.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents + other.cents); }
}
impl Money as Core.SubWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents - other.cents); }
}
impl Money as Core.MulWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents * k); }
}
impl Money as Core.DivWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents / k); }
}
impl Money as Core.ModWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents % k; }
}
impl Money as Core.Negate where .Result = Money {
  fn Op(self) -> Money { return Money.Make(-self.cents); }
}

inline Cpp '''
using Carbon::Money;
static_assert(__is_same(decltype(Money::Make(1) + Money::Make(2)), Money));
static_assert(__is_same(decltype(Money::Make(1) - Money::Make(2)), Money));
static_assert(__is_same(decltype(Money::Make(1) * 3), Money));
// C++ converts a `long` operand to the impl's `int`; Carbon would need an
// `impl Money as MulWith(i64)` (a documented divergence; the Carbon side is
// fail_conversion_carbon_side).
static_assert(__is_same(decltype(Money::Make(1) * 3L), Money));
static_assert(__is_same(decltype(Money::Make(1) / 3), Money));
static_assert(__is_same(decltype(Money::Make(1) % 3), int));
static_assert(__is_same(decltype(-Money::Make(1)), Money));
inline int Use(const Money& a, const Money& b) {
  return (a + b - b * 2 / 3).cents + a % 7 + (-a).cents;
}
''';

// --- fail_conversion_carbon_side.carbon

library "[[@TEST_NAME]]";

class Money {
  var cents: i32;
}

impl Money as Core.MulWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents * k; }
}

// Carbon looks up `MulWith(i64)` and does not convert the operand, where C++'s
// `m * 3L` converts it to the `int` impl (arithmetic), a documented
// divergence.
fn Use(m: Money, k: i64) -> i32 { return m * k; }

// --- signature_from_impl_function.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

// C++ sees the impl function's own declared signature: Carbon types `m + k` as
// the interface's `Result`, `i64`, and C++ as the function's `i32`; and C++
// takes the function's `i64` parameter, so `m - 1L` compiles, where Carbon's
// `m - k` needs `k: i32`. Both are documented divergences.
impl Money as Core.AddWith(i32) where .Result = i64 {
  fn Op(self, k: i32) -> i32 { return self.cents + k; }
}
impl Money as Core.SubWith(i32) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents - (k as i32); }
}

inline Cpp '''
static_assert(__is_same(decltype(Carbon::Money::Make(1) + 1), int));
inline int Use(Carbon::Money m) { return m - 1L; }
''';

// --- compound_assignment.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}
impl Money as Core.MulAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents *= k; }
}
impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}
impl Money as Core.Dec {
  fn Op(ref self) { --self.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Use(Money a, Money b) {
  static_assert(__is_same(decltype(a += b), void));
  static_assert(__is_same(decltype(++a), void));
  a += b;
  a *= 2;
  ++a;
  --a;
  return a.cents;
}
''';

// --- fail_compound_assignment_rvalue.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}

inline Cpp '''
using Carbon::Money;
// A `ref self` operator is `&`-qualified: like a `ref self` method, it is not
// callable on a temporary.
inline void Use(Money b) { Money::Make(1) += b; }
''';

// --- fail_postfix_increment.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}

inline Cpp '''
// Carbon's `++` is a prefix statement: only `operator++()` is exported.
inline void Use(Carbon::Money& a) { a++; }
''';

// --- comparison.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl Money as Core.OrderedWith(Money) {
  fn Less(self, other: Money) -> bool { return self.cents < other.cents; }
  fn LessOrEquivalent(self, other: Money) -> bool { return self.cents <= other.cents; }
  fn Greater(self, other: Money) -> bool { return self.cents > other.cents; }
  fn GreaterOrEquivalent(self, other: Money) -> bool { return self.cents >= other.cents; }
}

class Unknowable {
  var v: i32;
}

impl Unknowable as Core.EqWith(Unknowable) {
  fn Equal(self, o: Unknowable) -> bool { return self.v != 0 and o.v != 0 and self.v == o.v; }
  fn NotEqual(self, o: Unknowable) -> bool { return self.v != 0 and o.v != 0 and self.v != o.v; }
}

inline Cpp '''
using Carbon::Money;
static_assert(__is_same(decltype(Money() == Money()), bool));
static_assert(__is_same(decltype(Money() != Money()), bool));
static_assert(__is_same(decltype(Money() < Money()), bool));
inline bool Use(Money a, Money b, Carbon::Unknowable u) {
  return (a == b) && (a != b) && (a < b) && (a <= b) && (a > b) && (a >= b) && (u != u);
}
''';

// --- move_only_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct NoCopy {
  explicit NoCopy(int v) : v(v) {}
  NoCopy(const NoCopy&) = delete;
  NoCopy(NoCopy&&) = default;
  int v;
};
''';

class Money {
  var n: Cpp.NoCopy;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, o: Money) -> bool { return self.n.v == o.n.v; }
}

inline Cpp '''
// The default `operator!=` moves its by-value operands on to `operator==`, so
// a move-only class has it too.
inline bool Use() {
  return Carbon::Money{NoCopy(1)} != Carbon::Money{NoCopy(2)};
}
''';

// --- fail_reversed_equality.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `m == 5` but not `5 == m`; with `operator!=` exported beside
// `operator==`, C++20 does not synthesize the reversed candidate either.
impl Money as Core.EqWith(i32) {
  fn Equal(self, k: i32) -> bool { return self.cents == k; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return m == 5; }
inline bool Reversed(Carbon::Money m) { return 5 == m; }
''';

// --- bitwise.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Bits {
  var v: u8;
}

impl Bits as Core.BitAndWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v & o.v}; }
}
impl Bits as Core.BitOrWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v | o.v}; }
}
impl Bits as Core.BitXorWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v ^ o.v}; }
}
impl Bits as Core.BitComplement where .Result = Bits {
  fn Op(self) -> Bits { return {.v = ^self.v}; }
}
impl Bits as Core.LeftShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return {.v = self.v << (n as u8)}; }
}
impl Bits as Core.RightShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v >>= (n as u8); }
}

inline Cpp '''
using Carbon::Bits;
static_assert(__is_same(decltype(~Bits()), Bits));
inline int Use(Bits a, Bits b) {
  Bits c = (a & b) | (a ^ b);
  c >>= 1;
  return (~c << 2).v;
}
''';

// --- index.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Pair {
  var first: i32;
  var second: i32;
}

impl Pair as Core.IndexWith(i32) where .ElementType = i32 {
  fn At(self, i: i32) -> i32 { if (i == 0) { return self.first; } return self.second; }
}
impl Pair as Core.IndexWith(bool) where .ElementType = i32 {
  fn At(self, b: bool) -> i32 { if (b) { return self.second; } return self.first; }
}

inline Cpp '''
using Carbon::Pair;
static_assert(__is_same(decltype(Pair()[0]), int));
// Two impls of one interface are one C++ overload set: `true` selects the
// `bool` member by exact match, as Carbon's `p[true]` selects `IndexWith(bool)`.
inline int Use(const Pair& p) { return p[0] + p[true]; }
''';

// --- non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}
impl i32 as Core.SubAssignWith(Money) {
  fn Op(ref self, m: Money) { self -= m.cents; }
}
impl Cpp.Foo as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self.n + m.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Use(Money m, int k, Foo f) {
  k -= m;
  return (50 - m) + (5 == m) + (4 != m) + k + (f + m);
}
''';

// --- non_member_nested.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Outer {
  class Inner {
    var cents: i32;
  }
}

impl i32 as Core.SubWith(Outer.Inner) where .Result = i32 {
  fn Op(self, m: Outer.Inner) -> i32 { return self - m.cents; }
}

inline Cpp '''
// Argument-dependent lookup on a nested class looks in its innermost enclosing
// namespace, `Carbon`, which declares the non-member operator.
inline int Use(Carbon::Outer::Inner m) { return 50 - m; }
''';

// --- namespace.carbon

library "[[@TEST_NAME]]";

import Cpp;

namespace Units;

class Units.Money {
  var cents: i32;
  extend impl as Core.SubWith(Units.Money) where .Result = i32 {
    fn Op(self, o: Units.Money) -> i32 { return self.cents - o.cents; }
  }
}

impl i32 as Core.MulWith(Units.Money) where .Result = i32 {
  fn Op(self, m: Units.Money) -> i32 { return self * m.cents; }
}

inline Cpp '''
inline int Use(Carbon::Units::Money a, Carbon::Units::Money b) {
  return (a - b) + 2 * a;
}
''';

// --- base_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

base class Base {
  var v: i32;
}

class Derived {
  extend base: Base;
}

impl Base as Core.AddWith(Base) where .Result = i32 {
  fn Op(self, o: Base) -> i32 { return self.v + o.v; }
}

inline Cpp '''
// C++ member lookup finds `Base::operator+` from a `Derived` and converts
// both operands to `Base`; Carbon's impl lookup for `Derived` finds no
// `AddWith` impl (fail_base_class_carbon_side), a documented divergence.
inline int Use(const Carbon::Derived& d) { return d + d; }
''';

// --- fail_base_class_carbon_side.carbon

library "[[@TEST_NAME]]";

base class Base {
  var v: i32;
}

class Derived {
  extend base: Base;
}

impl Base as Core.AddWith(Base) where .Result = i32 {
  fn Op(self, o: Base) -> i32 { return self.v + o.v; }
}

fn Use(d: Derived) -> i32 { return d + d; }

// --- fail_noncopyable_lvalue_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct NoCopy {
  explicit NoCopy(int v) : v(v) {}
  NoCopy(const NoCopy&) = delete;
  NoCopy(NoCopy&&) = default;
  int v;
};
''';

class Money {
  var n: Cpp.NoCopy;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.n.v + o.n.v; }
}

// Carbon passes `b` as a value, without a copy.
fn CarbonSide(a: Money, b: Money) -> i32 { return a + b; }

inline Cpp '''
// The exported operator takes its operand by value, as an exported method
// does, so C++ copies an lvalue operand, and `Money` cannot be copied: a
// documented divergence.
inline int CppSide(const Carbon::Money& a, const Carbon::Money& b) { return a + b; }
''';

// --- fail_todo_generic_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T) where .Result = i32 {
  fn Op(self, k: T) -> i32 { return self.cents * (k as i32); }
}

inline Cpp '''
inline int Use(Carbon::Money m) { return m * 3; }
''';

// --- unmappable_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith((i32, i32)) where .Result = i32 {
  fn Op(self, p: (i32, i32)) -> i32 { return self.cents + p.0 + p.1; }
}

inline Cpp '''
// The tuple impl has no C++ form and is omitted without a diagnostic; C++
// cannot form a tuple operand, so the omission cannot change which impl a
// C++ `+` selects.
inline int Use(Carbon::Money m) { return m + m; }
''';

// --- deleted_result_unselected.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(i32) where .Result = (i32, i32) {
  fn Op(self, k: i32) -> (i32, i32) { return (self.cents, k); }
}
impl Money as Core.AddWith(i64) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents + (k as i32); }
}

inline Cpp '''
// The tuple-result impl is declared deleted; a `long` operand selects the
// `i64` impl by exact match, as Carbon's `m + k` does for `k: i64`.
inline int Use(Carbon::Money m, long k) { return m + k; }
''';

// --- fail_deleted_result.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// The exact match for a C++ `int`, but its tuple result has no C++ form: the
// operator is declared deleted, so C++ rejects `m + k` instead of converting
// `k` to `long` for the `i64` impl, which Carbon's `m + k` does not select.
impl Money as Core.AddWith(i32) where .Result = (i32, i32) {
  fn Op(self, k: i32) -> (i32, i32) { return (self.cents, k); }
}
impl Money as Core.AddWith(i64) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents + (k as i32); }
}

inline Cpp '''
inline int Use(Carbon::Money m, int k) { return m + k; }
''';

// --- fail_todo_unexportable_operand_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// A class C++ cannot export: its tuple field has no C++ form.
class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents + h.t.0; }
}

inline Cpp '''
// Both `+` impls are C++ candidates, and ranking the `Holder` one makes C++
// complete `Carbon::Holder`: the class's own export diagnoses its field, as
// for a C++ call of an exported function that takes a `Holder` (the OV-3
// overload-set shape, D-OV-18).
inline int Use(Carbon::Money m) { return m + m; }
''';

// --- cpp_side_unrelated_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Vec(N: i32) {
  var x: i32;
}

class Money {
  var cents: i32;
}

// Not an operator impl: C++'s lookup of `operator+` never maps its `Self`,
// whose non-type parameter has no C++ form.
impl Vec(3) as Core.ImplicitAs(Money) {
  fn Convert(self) -> Money { return {.cents = self.x}; }
}
impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
inline int Use(Carbon::Money m) { return m + m; }
''';

// --- carbon_side_unmappable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

// Carbon's impl lookup for `Money as AddWith(Cpp.Foo)` asks C++ for an
// operator, which looks up `operator+` in the exported `Carbon::Money`. That
// lookup exports nothing, so the tuple result is never mapped to C++, and this
// Carbon-only expression is checked as it would be without operator export.
impl Money as Core.AddWith(Cpp.Foo) where .Result = (i32, i32) {
  fn Op(self, f: Cpp.Foo) -> (i32, i32) { return (self.cents, f.n); }
}

fn Use(m: Money, f: Cpp.Foo) -> i32 { return (m + f).0; }

// --- carbon_side_unexportable_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

class Holder {
  var t: (i32, i32);
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = Holder {
  fn Op(self, f: Cpp.Foo) -> Holder { return {.t = (self.cents, f.n)}; }
}
impl Money as Core.SubWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents - f.n; }
}
impl Money as Core.SubWith(Holder) where .Result = i32 {
  fn Op(self, h: Holder) -> i32 { return self.cents - h.t.0; }
}

// Carbon-only: neither lookup maps `Holder`, which C++ cannot export.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return (m + f).t.0 + (m - f); }

// --- carbon_side_generic_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Wrapper(T: type) {
  var v: T;
}

class Vec(N: i32) {
  var x: i32;
}

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = Wrapper((i32, i32)) {
  fn Op(self, f: Cpp.Foo) -> Wrapper((i32, i32)) { return {.v = (self.cents, f.n)}; }
}
impl Money as Core.SubWith(Cpp.Foo) where .Result = Vec(3) {
  fn Op(self, f: Cpp.Foo) -> Vec(3) { return {.x = self.cents - f.n}; }
}

// Carbon-only: neither result, a specific C++ cannot export, is mapped.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return (m + f).v.0 + (m - f).x; }

// --- carbon_side_unrelated_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Vec(N: i32) {
  var x: i32;
}

class Money {
  var cents: i32;
}

impl Vec(3) as Core.ImplicitAs(Money) {
  fn Convert(self) -> Money { return {.cents = self.x}; }
}
impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

// Carbon-only: the `ImplicitAs` impl's `Self` is never mapped.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_candidates.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo {
  int n;
  operator int() const { return n; }
  operator long() const { return n; }
};
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents + k; }
}
impl Money as Core.AddWith(i64) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents; }
}
impl forall [T: type] Money as Core.AddWith(T) where .Result = i32 {
  fn Op(self, x: T) -> i32 { return self.cents; }
}

// Carbon-only: `Foo` converts to both `int` and `long`, so the two concrete
// impls would be equally good C++ candidates. Carbon's own lookup exports
// neither, finds no C++ candidate, and selects the generic impl.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_user_cpp_operator.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

inline Cpp '''
// A hand-written C++ operator for the exported class.
inline int operator+(const Carbon::Money& m, const Foo& f) { return m.cents + f.n + 1000; }
''';

// Carbon's lookup finds the hand-written operator as its only C++ candidate,
// as it did before operator impls were exported.
fn Use(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

// --- carbon_side_then_cpp.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

// Carbon's lookup for this expression asks C++ about `operator+` in
// `Carbon::Money` and leaves no answer cached...
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
// ...so C++'s first lookup of it, here, exports both impls.
inline int CppSide(Carbon::Money a, Carbon::Money b) { return a + b; }
''';

// --- fail_user_cpp_operator_ambiguous.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
// A hand-written C++ operator that duplicates the Carbon impl, as C++ code had
// to write before operator impls were exported: the two are equally good
// candidates (fork work item W-211).
inline int operator+(const Carbon::Money& a, const Carbon::Money& b) { return a.cents + b.cents; }
inline int Use() { return Carbon::Money::Make(30) + Carbon::Money::Make(12); }
''';

// --- fail_todo_non_carbon_operands.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

// Neither type is a Carbon class: C++'s argument-dependent lookup never asks
// namespace `Carbon`, so the impl is not exported (fork work item W-210).
impl Cpp.Foo as Core.AddWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.n + k; }
}

inline Cpp '''
inline int Use(Foo f) { return f + 2; }
''';

// --- fail_impl_after_use.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

inline Cpp '''
inline int Use(Carbon::Money m) { return m + m; }
''';

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// --- fail_todo_impl_after_lookup.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
inline int First(Carbon::Money m) { return m + m; }
''';

impl Money as Core.AddWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents + k; }
}

inline Cpp '''
inline int Second(Carbon::Money m) { return m + 1; }
''';

// --- money_lib.carbon

library "[[@TEST_NAME]]";

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// --- fail_todo_imported_class.carbon

library "[[@TEST_NAME]]";

import Cpp;
import library "money_lib";

inline Cpp '''
// An imported class's impls are not enumerated (W-204), and the class itself
// exports as an empty C++ record (W-203).
inline int Use(Carbon::Money m) { return m + m; }
''';
```

#### toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon (1 split, `--dump-cpp-ast`)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-cpp-ast
// SET-CHECK-SUBSET
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon

// The C++ AST that exported Carbon operator impls produce (fork decision
// F-017): `CXXMethodDecl`s of the exported class for impls whose `Self` is
// the class — `const` for `self`, `&` for `ref self` — each an inline
// function whose body calls the impl member's own Carbon thunk
// (`Op__carbon_thunk`, `Equal__carbon_thunk`); an `operator!=` beside an
// `operator==` whose impl leaves `NotEqual` to its default, with the body
// `!(*this == other)`, its operand moved on as an xvalue; a deleted
// `operator*` returning `void` for an impl whose result, a tuple, has no C++
// form; and a `FunctionDecl` in `namespace Carbon` for an impl whose `Self` is
// `i32`. The sibling operator.carbon pins the uses.

// --- operator.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return {.cents = self.cents + other.cents}; }
}
impl Money as Core.AddAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents += k; }
}
impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl Money as Core.MulWith(Money) where .Result = i32 {
  fn Op(self, other: Money) -> i32 { return self.cents * other.cents; }
}
impl Money as Core.MulWith(i32) where .Result = (i32, i32) {
  fn Op(self, k: i32) -> (i32, i32) { return (self.cents, k); }
}

inline Cpp '''
inline int Use(Carbon::Money a, Carbon::Money b) {
  a += 1;
  return (a + b != b) + (1 - a) + a * b;
}
''';
```

#### toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon (4 splits, `-std=c++20`)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-std=c++20
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon

// Exported Carbon operator impls under C++20 (fork decision F-017,
// docs/design/interoperability/operators.md): `operator!=` is always declared
// beside `operator==`, and no `operator<=>` is exported, so C++20 synthesizes
// no reversed or rewritten candidate, and C++ accepts exactly the operand
// orders that Carbon has impls for. The sibling operator.carbon pins the
// default language mode, C++17.

// --- move_only_equality.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct NoCopy {
  explicit NoCopy(int v) : v(v) {}
  NoCopy(const NoCopy&) = delete;
  NoCopy(NoCopy&&) = default;
  int v;
};
''';

class Money {
  var n: Cpp.NoCopy;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, o: Money) -> bool { return self.n.v == o.n.v; }
}

inline Cpp '''
// C++20 looks up `operator!=` for every `==`, which builds the default
// `operator!=`: it moves its by-value operands on to `operator==`.
inline bool Use() {
  return (Carbon::Money{NoCopy(1)} == Carbon::Money{NoCopy(1)}) &&
         (Carbon::Money{NoCopy(1)} != Carbon::Money{NoCopy(2)});
}
''';

// --- fail_reversed_equality.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `m == 5` but not `5 == m`.
impl Money as Core.EqWith(i32) {
  fn Equal(self, k: i32) -> bool { return self.cents == k; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return m == 5; }
inline bool Reversed(Carbon::Money m) { return 5 == m; }
''';

// --- fail_reversed_equality_non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `5 == m` but not `m == 5`.
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return 5 == m; }
inline bool Reversed(Carbon::Money m) { return m == 5; }
''';

// --- fail_reversed_ordering.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `m < 5` but not `5 > m`; with no `operator<=>`, C++20 does not
// rewrite either.
impl Money as Core.OrderedWith(i32) {
  fn Less(self, k: i32) -> bool { return self.cents < k; }
  fn LessOrEquivalent(self, k: i32) -> bool { return self.cents <= k; }
  fn Greater(self, k: i32) -> bool { return self.cents > k; }
  fn GreaterOrEquivalent(self, k: i32) -> bool { return self.cents >= k; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return m < 5; }
inline bool Reversed(Carbon::Money m) { return 5 > m; }
''';
```

#### toolchain/lower/testdata/interop/cpp/class/export/operator.carbon (6 splits)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/export/operator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/export/operator.carbon

// The lowering of exported Carbon operator impls (fork decision F-017): the
// C++ operator inlines into its caller and calls the impl member's Carbon
// thunk, `_COp__carbon_thunk.<class>.<package>:<interface>...`, which calls
// the impl member `_COp.<class>...`; a default `!=` negates the `==` thunk's
// result; a Carbon operator expression with a C++ operand still calls the
// Carbon impl directly, not its C++ export, even after C++ code exported it;
// and a generic impl, which is not exported, leaves C++ to convert its operand
// to a concrete impl's.

// --- member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return {.cents = self.cents + other.cents}; }
}
impl Money as Core.AddAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents += k; }
}

inline Cpp '''
inline int AddInCpp(Carbon::Money a, Carbon::Money b) {
  a += 2;
  return (a + b).cents;
}
''';

fn Call(a: Money, b: Money) -> i32 { return Cpp.AddInCpp(a, b); }

// --- default_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}

inline Cpp '''
inline bool NotEqualInCpp(Carbon::Money a, Carbon::Money b) { return a != b; }
''';

fn Call(a: Money, b: Money) -> bool { return Cpp.NotEqualInCpp(a, b); }

// --- non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}

inline Cpp '''
inline int SubInCpp(Carbon::Money m) { return 50 - m; }
''';

fn Call(m: Money) -> i32 { return Cpp.SubInCpp(m); }

// --- carbon_side_cpp_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

inline Cpp '''
inline int AddInCpp(Carbon::Money m, Foo f) { return m + f; }
''';

// Carbon's impl lookup for `Money as AddWith(Cpp.Foo)` also asks C++, which
// finds the `Money::operator+(Foo)` that `AddInCpp` exported; that candidate is
// Carbon's own impl, not a C++ operator, so the call below still calls
// `_COp.Money...` directly.
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

fn CppSide(m: Money, f: Cpp.Foo) -> i32 { return Cpp.AddInCpp(m, f); }

// --- carbon_side_default_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Cpp.Foo as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self.n == m.cents; }
}

inline Cpp '''
// Exports `Equal` as `Carbon::operator==(Foo, Money)` and the default
// `Carbon::operator!=(Foo, Money)` beside it.
inline bool NotEqualInCpp(Foo f, Carbon::Money m) { return f != m; }
''';

// The exported default `operator!=` is not a C++ candidate for Carbon's
// lookup: this calls the interface's default `NotEqual` for the impl.
fn CarbonSide(f: Cpp.Foo, m: Money) -> bool { return f != m; }

fn CppSide(f: Cpp.Foo, m: Money) -> bool { return Cpp.NotEqualInCpp(f, m); }

// --- generic_impl_hidden.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T) where .Result = i32 {
  fn Op(self, k: T) -> i32 { return self.cents * (k as i32); }
}
impl Money as Core.MulWith(i64) where .Result = i32 {
  fn Op(self, k: i64) -> i32 { return self.cents; }
}

inline Cpp '''
// The generic impl is not exported (fork work item W-202), so C++ converts
// `k` to `long` and calls the `i64` impl.
inline int MulInCpp(Carbon::Money m, int k) { return m * k; }
''';

// Carbon selects the generic impl for an `i32` operand.
fn CarbonSide(m: Money, k: i32) -> i32 { return m * k; }

fn CppSide(m: Money, k: i32) -> i32 { return Cpp.MulInCpp(m, k); }
```

### §2.6 Conformance programs (bullet "Type system: C++ interop — exporting Carbon operator overloads into C++", R7)

All seven are single-file `run` programs in fork/conformance/programs/interop/.
The arbiter keeps its filename and bullet; its SKIP line, guard and the
"Write-tests-first stub" header go, its body is the sketch (M-15). Each EXPECT
is re-derived in §1.8. Rev 2 re-encodes the compare and nonmember programs'
comparisons and adds the divergence cross-references to the arithmetic and
index headers (amended 2026-10-14, review fold: A-8, A-9).

#### interop/cpp_operator_export.carbon (SKIP → PASS)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// A Carbon class's `Core.AddWith` impl is C++'s `operator+` on the exported
// `Carbon::` type (fork decision F-017): an `inline Cpp` block applies `+`
// to two `Carbon::Meters` values, and Carbon reads the sum back through
// `Cpp.`, so the round trip is observable at runtime (mirroring
// interop/cpp_export_function.carbon). Shape verbatim from
// types/operator_overloading.carbon and
// toolchain/check/testdata/operators/overloaded/add.carbon. 30 + 12 = 42: the
// impl adds the two `value` fields, and `.value` reads the result's field.

import Core library "io";
import Cpp;

class Meters {
  var value: i32;
  fn Make(n: i32) -> Meters { return {.value = n}; }
}

impl Meters as Core.AddWith(Meters) where .Result = Meters {
  fn Op(self, other: Meters) -> Meters {
    return Meters.Make(self.value + other.value);
  }
}

inline Cpp '''
inline int AddMetersInCpp() {
  Carbon::Meters a = Carbon::Meters::Make(30);
  Carbon::Meters b = Carbon::Meters::Make(12);
  // The exported Carbon Core.AddWith impl must surface as operator+ here.
  return (a + b).value;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddMetersInCpp());
  return 0;
}
```

#### interop/cpp_operator_export_arithmetic.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   950
//   450
//   2100
//   233
//   1
//   -700
//
// The arithmetic family (fork decision F-017): `AddWith`, `SubWith`,
// `MulWith`, `DivWith` and `ModWith` impls whose `Self` is the class are
// C++ member operators `+ - * / %`, and `Negate` is the unary `-`, each a
// `const` member because each `Op` takes `self` by value. Every value is
// computed by C++ from two amounts of 700 and 250 cents: 700 + 250 = 950;
// 700 - 250 = 450; 700 * 3 = 2100; 700 / 3 = 233 (Carbon's `i32` division
// truncates); 700 % 3 = 1; -(700) = -700. `MulWith(i32)` takes C++'s `int`
// operand, the mixed-type case. C++ resolves these operators under its own
// rules, so it also converts a `long` operand to that `int`, where Carbon needs
// an `i64` impl: a documented divergence (docs/design/interoperability/
// operators.md, "Divergences"), pinned by the `arithmetic` and
// `fail_conversion_carbon_side` splits of
// toolchain/check/testdata/interop/cpp/class/export/operator.carbon.

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents + other.cents); }
}
impl Money as Core.SubWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents - other.cents); }
}
impl Money as Core.MulWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents * k); }
}
impl Money as Core.DivWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents / k); }
}
impl Money as Core.ModWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents % k); }
}
impl Money as Core.Negate where .Result = Money {
  fn Op(self) -> Money { return Money.Make(-self.cents); }
}

inline Cpp '''
using Carbon::Money;
inline int Sum() { return (Money::Make(700) + Money::Make(250)).cents; }
inline int Difference() { return (Money::Make(700) - Money::Make(250)).cents; }
inline int Product() { return (Money::Make(700) * 3).cents; }
inline int Quotient() { return (Money::Make(700) / 3).cents; }
inline int Remainder() { return (Money::Make(700) % 3).cents; }
inline int Negated() { return (-Money::Make(700)).cents; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Sum());
  Core.Print(Cpp.Difference());
  Core.Print(Cpp.Product());
  Core.Print(Cpp.Quotient());
  Core.Print(Cpp.Remainder());
  Core.Print(Cpp.Negated());
  return 0;
}
```

#### interop/cpp_operator_export_compound.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   15
//   7
//   40
//   2
//   4
//   11
//
// The compound-assignment and increment family (fork decision F-017):
// `AddAssignWith` .. `ModAssignWith`, `Inc` and `Dec` impls take `ref self`,
// so each is a C++ member operator qualified `&` that returns `void` (in
// Carbon these are statements, docs/design/expressions/README.md), and writes
// through to the C++ object it is applied to. Each C++ function starts from
// 10 cents: 10 += 5 is 15; 10 -= 3 is 7; 10 *= 4 is 40; 10 /= 4 is 2
// (truncating); 10 %= 6 is 4; ++, ++, -- from 10 is 11 (prefix only: Carbon
// has no postfix form).

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}
impl Money as Core.SubAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents -= other.cents; }
}
impl Money as Core.MulAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents *= k; }
}
impl Money as Core.DivAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents /= k; }
}
impl Money as Core.ModAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents %= k; }
}
impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}
impl Money as Core.Dec {
  fn Op(ref self) { --self.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int AddAssign() { Money a = Money::Make(10); a += Money::Make(5); return a.cents; }
inline int SubAssign() { Money a = Money::Make(10); a -= Money::Make(3); return a.cents; }
inline int MulAssign() { Money a = Money::Make(10); a *= 4; return a.cents; }
inline int DivAssign() { Money a = Money::Make(10); a /= 4; return a.cents; }
inline int ModAssign() { Money a = Money::Make(10); a %= 6; return a.cents; }
inline int IncDec() { Money a = Money::Make(10); ++a; ++a; --a; return a.cents; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddAssign());
  Core.Print(Cpp.SubAssign());
  Core.Print(Cpp.MulAssign());
  Core.Print(Cpp.DivAssign());
  Core.Print(Cpp.ModAssign());
  Core.Print(Cpp.IncDec());
  return 0;
}
```

#### interop/cpp_operator_export_compare.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   101
//   100
//   110
//   1
//   11
//   0
//
// The comparison family (fork decision F-017): `EqWith.Equal` is C++'s `==`,
// `OrderedWith`'s four members are `<`, `<=`, `>` and `>=`. With a = 1 and
// b = 2, each C++ function returns 100 * (a op b) + 10 * (a op a) + (b op a),
// which differs for every operator, so a swapped or mis-mapped operator prints
// another operator's value: `==` gives 0, 1, 0, so 10; `!=` 1, 0, 1, so 101;
// `<` 1, 0, 0, so 100; `<=` 1, 1, 0, so 110; `>` 0, 0, 1, so 1; and `>=`
// 0, 1, 1, so 11.
// `Money` leaves `NotEqual` to the interface's default, `not self.Equal(o)`
// (docs/design/expressions/comparison_operators.md), exported as `!(a == b)`.
// `Unknowable` defines its own `NotEqual`, under which an unknown value (0)
// is neither equal nor unequal to anything: (z == one) * 10 + (z != one) is 0
// because C++ calls that `NotEqual`; rewriting `!=` as `!(==)` would print 1.

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl Money as Core.OrderedWith(Money) {
  fn Less(self, other: Money) -> bool { return self.cents < other.cents; }
  fn LessOrEquivalent(self, other: Money) -> bool { return self.cents <= other.cents; }
  fn Greater(self, other: Money) -> bool { return self.cents > other.cents; }
  fn GreaterOrEquivalent(self, other: Money) -> bool { return self.cents >= other.cents; }
}

class Unknowable {
  var v: i32;
  fn Make(v: i32) -> Unknowable { return {.v = v}; }
}

impl Unknowable as Core.EqWith(Unknowable) {
  fn Equal(self, o: Unknowable) -> bool {
    return self.v != 0 and o.v != 0 and self.v == o.v;
  }
  fn NotEqual(self, o: Unknowable) -> bool {
    return self.v != 0 and o.v != 0 and self.v != o.v;
  }
}

inline Cpp '''
using Carbon::Money;
inline Money A() { return Money::Make(1); }
inline Money B() { return Money::Make(2); }
inline int Code(bool ab, bool aa, bool ba) { return ab * 100 + aa * 10 + ba; }
inline int Eq() { return Code(A() == B(), A() == A(), B() == A()); }
inline int Ne() { return Code(A() != B(), A() != A(), B() != A()); }
inline int Lt() { return Code(A() < B(), A() < A(), B() < A()); }
inline int Le() { return Code(A() <= B(), A() <= A(), B() <= A()); }
inline int Gt() { return Code(A() > B(), A() > A(), B() > A()); }
inline int Ge() { return Code(A() >= B(), A() >= A(), B() >= A()); }
inline int Unknown() {
  Carbon::Unknowable z = Carbon::Unknowable::Make(0);
  Carbon::Unknowable one = Carbon::Unknowable::Make(1);
  return (z == one) * 10 + (z != one);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.Eq());
  Core.Print(Cpp.Ne());
  Core.Print(Cpp.Lt());
  Core.Print(Cpp.Le());
  Core.Print(Cpp.Gt());
  Core.Print(Cpp.Ge());
  Core.Print(Cpp.Unknown());
  return 0;
}
```

#### interop/cpp_operator_export_bitwise.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
//   14
//   6
//   243
//   48
//   16
//   4
//
// The bitwise and shift family (fork decision F-017): `BitAndWith`,
// `BitOrWith`, `BitXorWith`, `LeftShiftWith` and `RightShiftWith` are C++'s
// `& | ^ << >>`; Carbon's unary `^x`, `BitComplement`, is C++'s `~x` (the
// operation with the most similar semantics, docs/design/README.md, "Operator
// overloading" under C++ interop); the compound forms are `&= |= ^= <<= >>=`.
// `Bits` holds a `u8` (C++ `unsigned char`). With x = 12 (0b1100) and
// y = 10 (0b1010): x & y = 8; x | y = 14; x ^ y = 6; ~x = 255 - 12 = 243;
// x << 2 = 48; 128 >> 3 = 16; and z = 3, then z <<= 2 (12), z |= 1 (13),
// z &= 14 (12), z ^= 5 (9), z >>= 1 (4).

import Core library "io";
import Cpp;

class Bits {
  var v: u8;
  fn Make(v: u8) -> Bits { return {.v = v}; }
}

impl Bits as Core.BitAndWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v & o.v); }
}
impl Bits as Core.BitOrWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v | o.v); }
}
impl Bits as Core.BitXorWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v ^ o.v); }
}
impl Bits as Core.BitComplement where .Result = Bits {
  fn Op(self) -> Bits { return Bits.Make(^self.v); }
}
impl Bits as Core.LeftShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return Bits.Make(self.v << (n as u8)); }
}
impl Bits as Core.RightShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return Bits.Make(self.v >> (n as u8)); }
}
impl Bits as Core.BitAndAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v &= o.v; }
}
impl Bits as Core.BitOrAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v |= o.v; }
}
impl Bits as Core.BitXorAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v ^= o.v; }
}
impl Bits as Core.LeftShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v <<= (n as u8); }
}
impl Bits as Core.RightShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v >>= (n as u8); }
}

inline Cpp '''
using Carbon::Bits;
inline Bits X() { return Bits::Make(12); }
inline Bits Y() { return Bits::Make(10); }
inline int And() { return (X() & Y()).v; }
inline int Or() { return (X() | Y()).v; }
inline int Xor() { return (X() ^ Y()).v; }
inline int Complement() { return (~X()).v; }
inline int ShiftLeft() { return (X() << 2).v; }
inline int ShiftRight() { return (Bits::Make(128) >> 3).v; }
inline int Compound() {
  Bits z = Bits::Make(3);
  z <<= 2;
  z |= Bits::Make(1);
  z &= Bits::Make(14);
  z ^= Bits::Make(5);
  z >>= 1;
  return z.v;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.And());
  Core.Print(Cpp.Or());
  Core.Print(Cpp.Xor());
  Core.Print(Cpp.Complement());
  Core.Print(Cpp.ShiftLeft());
  Core.Print(Cpp.ShiftRight());
  Core.Print(Cpp.Compound());
  return 0;
}
```

#### interop/cpp_operator_export_index.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   789
//   97
//
// The indexing family (fork decision F-017): `IndexWith(I).At` is C++'s
// `operator[]`, a `const` member returning the element by value (`At` takes
// `self` and returns a value; the `ref` forms are W-109's). Two impls of one
// interface, `IndexWith(i32)` and `IndexWith(bool)`, are one C++ overload
// set: `t[true]` selects the `bool` member by exact match (`bool` to `int`
// would be a promotion), as Carbon's `t[true]` selects `IndexWith(bool)`; where
// the two sides' rules differ (operand conversions, base classes), the
// divergence is documented (docs/design/interoperability/operators.md,
// "Divergences") and pinned by the `arithmetic`, `fail_conversion_carbon_side`,
// `base_class` and `fail_base_class_carbon_side` splits of
// toolchain/check/testdata/interop/cpp/class/export/operator.carbon. With
// fields 7, 8, 9: t[0] * 100 + t[1] * 10 + t[2] = 789; t[true] is the last
// field (9) and t[false] the first (7), so t[true] * 10 + t[false] = 97.

import Core library "io";
import Cpp;

class Triple {
  var a: i32;
  var b: i32;
  var c: i32;
  fn Make(a: i32, b: i32, c: i32) -> Triple { return {.a = a, .b = b, .c = c}; }
}

impl Triple as Core.IndexWith(i32) where .ElementType = i32 {
  fn At(self, i: i32) -> i32 {
    if (i == 0) {
      return self.a;
    }
    if (i == 1) {
      return self.b;
    }
    return self.c;
  }
}
impl Triple as Core.IndexWith(bool) where .ElementType = i32 {
  fn At(self, last: bool) -> i32 {
    if (last) {
      return self.c;
    }
    return self.a;
  }
}

inline Cpp '''
inline int Digits() {
  const Carbon::Triple t = Carbon::Triple::Make(7, 8, 9);
  return t[0] * 100 + t[1] * 10 + t[2];
}
inline int Ends() {
  const Carbon::Triple t = Carbon::Triple::Make(7, 8, 9);
  return t[true] * 10 + t[false];
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.Digits());
  Core.Print(Cpp.Ends());
  return 0;
}
```

#### interop/cpp_operator_export_nonmember.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   10
//   101
//   100
//   110
//   1
//   11
//   7
//   33
//
// Operator impls whose `Self` is not an exported Carbon class (fork decision
// F-017): `impl i32 as SubWith(Money)` is the non-member C++ operator
// `int operator-(int, Carbon::Money)` in `namespace Carbon`, found by
// argument-dependent lookup on the `Money` operand, and so are `EqWith`,
// `OrderedWith` and `SubAssignWith` from `i32`, and `AddWith(Money)` from
// the C++ type `Foo`. The left operand is `Self`, as in Carbon: 50 - m(8)
// = 42 (the other order would be -42). Each comparison returns
// 100 * (4 op m(5)) + 10 * (5 op m(5)) + (6 op m(5)), which differs for every
// operator: `==` 0, 1, 0, so 10; `!=`, from `Equal` alone through `NotEqual`'s
// default, 1, 0, 1, so 101; `<` 1, 0, 0, so 100; `<=` 1, 1, 0, so 110; `>`
// 0, 0, 1, so 1; `>=` 0, 1, 1, so 11. Then k = 10, k -= m(3) leaves 7 in the
// C++ `int`; and Foo{30} + m(3) = 33.

import Core library "io";
import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}
impl i32 as Core.OrderedWith(Money) {
  fn Less(self, m: Money) -> bool { return self < m.cents; }
  fn LessOrEquivalent(self, m: Money) -> bool { return self <= m.cents; }
  fn Greater(self, m: Money) -> bool { return self > m.cents; }
  fn GreaterOrEquivalent(self, m: Money) -> bool { return self >= m.cents; }
}
impl i32 as Core.SubAssignWith(Money) {
  fn Op(ref self, m: Money) { self -= m.cents; }
}
impl Cpp.Foo as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self.n + m.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Difference() { return 50 - Money::Make(8); }
inline Money M() { return Money::Make(5); }
inline int Code(bool lo, bool eq, bool hi) { return lo * 100 + eq * 10 + hi; }
inline int Eq() { return Code(4 == M(), 5 == M(), 6 == M()); }
inline int Ne() { return Code(4 != M(), 5 != M(), 6 != M()); }
inline int Lt() { return Code(4 < M(), 5 < M(), 6 < M()); }
inline int Le() { return Code(4 <= M(), 5 <= M(), 6 <= M()); }
inline int Gt() { return Code(4 > M(), 5 > M(), 6 > M()); }
inline int Ge() { return Code(4 >= M(), 5 >= M(), 6 >= M()); }
inline int Assign() { int k = 10; k -= Money::Make(3); return k; }
inline int Foreign() { return Foo{30} + Money::Make(3); }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Difference());
  Core.Print(Cpp.Eq());
  Core.Print(Cpp.Ne());
  Core.Print(Cpp.Lt());
  Core.Print(Cpp.Le());
  Core.Print(Cpp.Gt());
  Core.Print(Cpp.Ge());
  Core.Print(Cpp.Assign());
  Core.Print(Cpp.Foreign());
  return 0;
}
```

### §2.7 Docs (D-OX-13; a new page and a dated amendment, never a rewrite)

#### docs/design/interoperability/operators.md (new)

The page's example is the arbiter's program, so it is compile-verified by the
conformance run (R6); its prose claims are each a measurement of §0.2 or a
split of §2.5. The page carries the two table-of-contents marker lines that
`printf '<!-- %s -->\n' toc tocstop` prints: the first on its own line after the
license comment, the second on its own line after the table of contents, as in
docs/design/interoperability/README.md:9 and its matching stop line. They are
not written out literally in this plan, because prek's `markdown-toc` hook
replaces the text between the first such pair in any markdown file, fenced or
not (pre_commit_hooks/markdown_toc.py:45-72 in the prek cache), so a literal
pair here would overwrite this copy with the plan's own table of contents; on
the page the hook fills the list from the headings (amended 2026-10-14, review
fold: B-12). Rev 2 rewrites the mapping table's result column, the sections on
Carbon's own expressions and divergences, adds "Conversions" and a migration
note, and extends the 0.1 limits (amended 2026-10-14, review fold: A-1, A-3,
A-6, A-7, B-2, B-3, B-4, B-11).

````markdown
# Exporting Carbon operators to C++

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

## Table of contents

-   [Overview](#overview)
-   [The mapping](#the-mapping)
-   [Member and non-member operators](#member-and-non-member-operators)
-   [Equality and inequality](#equality-and-inequality)
-   [Assignment, increment, and indexing](#assignment-increment-and-indexing)
-   [Implementations with no C++ form](#implementations-with-no-c-form)
-   [Carbon operator expressions are unchanged](#carbon-operator-expressions-are-unchanged)
-   [Divergences](#divergences)
-   [Conversions](#conversions)
-   [Hand-written C++ operators](#hand-written-c-operators)
-   [0.1 limits](#01-limits)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

## Overview

> **Fork design (F-017, 2026-10-14).** No accepted proposal specifies how Carbon
> operators are used from C++. This page is the fork's design decision F-017
> (fork/decision-log.md, "OX-1"), recorded for after-the-fact veto.

The [design overview](../README.md#operator-overloading-1) says that Carbon types
implementing an operator overload using an interface "should get the
corresponding operator overload in C++", so that "implementing `ModWith(U)` in
Carbon for a type effectively implements `operator%` in C++ for that type", and
that operations are matched "according to which operation has the most similar
semantics rather than using the same symbols". This page decides how, for the
operators; conversions are not yet exported (see [Conversions](#conversions)).

An `impl` of one of the `Core` operator interfaces below, for a Carbon class, is
a C++ operator on the exported Carbon type. C++ code in an `inline Cpp` block
that applies the operator calls the impl's function, through the same kind of
thunk as an exported method:

```carbon
import Core library "io";
import Cpp;

class Meters {
  var value: i32;
  fn Make(n: i32) -> Meters { return {.value = n}; }
}

impl Meters as Core.AddWith(Meters) where .Result = Meters {
  fn Op(self, other: Meters) -> Meters {
    return Meters.Make(self.value + other.value);
  }
}

inline Cpp '''
inline int AddMetersInCpp() {
  Carbon::Meters a = Carbon::Meters::Make(30);
  Carbon::Meters b = Carbon::Meters::Make(12);
  return (a + b).value;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddMetersInCpp());
  return 0;
}
```

This prints `42`.

## The mapping

| `Core` interface member                     | C++ operator                            | Form                       |
| ------------------------------------------- | --------------------------------------- | -------------------------- |
| `AddWith(U).Op`                             | `a + b`                                 | `const`                    |
| `SubWith(U).Op`                             | `a - b`                                 | `const`                    |
| `MulWith(U).Op`                             | `a * b`                                 | `const`                    |
| `DivWith(U).Op`                             | `a / b`                                 | `const`                    |
| `ModWith(U).Op`                             | `a % b`                                 | `const`                    |
| `Negate.Op`                                 | `-a`                                    | `const`                    |
| `BitAndWith(U).Op`                          | `a & b`                                 | `const`                    |
| `BitOrWith(U).Op`                           | <code>a \| b</code>                     | `const`                    |
| `BitXorWith(U).Op`                          | `a ^ b`                                 | `const`                    |
| `BitComplement.Op`                          | `~a`                                    | `const`                    |
| `LeftShiftWith(U).Op`                       | `a << b`                                | `const`                    |
| `RightShiftWith(U).Op`                      | `a >> b`                                | `const`                    |
| `AddAssignWith(U).Op` .. `ModAssignWith(U)` | `+=` `-=` `*=` `/=` `%=`                | `&`-qualified, `void`      |
| `BitAndAssignWith(U).Op` .. shifts          | `&=` <code>\|=</code> `^=` `<<=` `>>=` | `&`-qualified, `void`      |
| `Inc.Op`, `Dec.Op`                          | `++a`, `--a`                            | `&`-qualified, `void`      |
| `EqWith(U).Equal`                           | `a == b`                                | `const`                    |
| `EqWith(U).NotEqual`                        | `a != b`                                | `const`                    |
| `OrderedWith(U).Less`                       | `a < b`                                 | `const`                    |
| `OrderedWith(U).LessOrEquivalent`           | `a <= b`                                | `const`                    |
| `OrderedWith(U).Greater`                    | `a > b`                                 | `const`                    |
| `OrderedWith(U).GreaterOrEquivalent`        | `a >= b`                                | `const`                    |
| `IndexWith(I).At`                           | `a[i]`                                  | `const`                    |

The table is the inverse of the C++ operator import, which maps the same C++
operators onto the same interfaces. An exported operator is the impl's function
as declared, mapped as for an exported method: a value parameter is a C++
by-value parameter, `self` makes a `const` member operator, `ref self` an
lvalue-ref-qualified (`&`) one, and the result, the function's declared return
type, is returned by value. A function's parameter and return types may differ
from the interface's argument and `Result` where Carbon converts between them;
C++ sees the function's own types (see [Divergences](#divergences)).

Carbon's prefix `^` is C++'s `~`: they are the operations with the most similar
semantics. Some C++ operators have no Carbon interface to come from, so a Carbon
type never has them: unary `+`, postfix `++` and `--`, `!`, `&&`, `||`, the
comma operator, `->`, unary `*` and `&`, `()`, and `<=>`.

## Member and non-member operators

Carbon finds an operator by looking up the impl for the type of its left
operand, `Self`. When `Self` is the exported Carbon class, the impl is a
member operator of that class, so C++ finds it by member lookup on the left
operand, as Carbon does. When `Self` is any other type — a Carbon primitive such
as `i32`, or an imported C++ type — and the operand is an exported Carbon class,
the impl is a non-member operator declared in the innermost C++ namespace that
encloses that class, which C++ finds by argument-dependent lookup on the
operand, a nested class's included:

```carbon
impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
```

is `int Carbon::operator-(int, Carbon::Money)`, and C++'s `50-m` calls it.
C++ requires `operator[]` to be a member, so only an `IndexWith` impl whose
`Self` is the class is exported.

## Equality and inequality

`a==b` calls `EqWith(U).Equal` and `a!=b` calls `EqWith(U).NotEqual`. An impl
that does not define `NotEqual` uses the interface's default,
`not self.Equal(other)` ([comparison operators](../expressions/comparison_operators.md#equality)),
and `operator!=` is then exported as `!(a==b)`, passing its operands on as a
C++ implicit move would, so `!=` is available in every C++ language mode, for a
class that can only be moved too. Because `operator!=` is declared beside
`operator==`, C++20 does not synthesize reversed `==` candidates: C++ accepts
`5==m` only if Carbon has an `impl i32 as EqWith(Money)`, as Carbon does. No
`<=>` is exported, so C++ never rewrites the relational operators either.

## Assignment, increment, and indexing

The compound assignment operators and `++`/`--` are statements in Carbon and
take `ref self`, so the exported operators are `&`-qualified, return `void`, and
modify the object C++ applies them to; `a+=b` on a temporary does not compile.
`a = b` is not an operator interface in Carbon and stays C++'s copy assignment.
`IndexWith(I).At` takes `self` and returns a value, so `a[i]` is a `const`
member returning the element by value and cannot be assigned to.

## Implementations with no C++ form

An impl whose operand type has no C++ form, such as a tuple, is not exported:
C++ code cannot form such an operand, so leaving it out cannot change which
impl a C++ expression selects. An impl whose result alone has no C++ form is
exported as a deleted operator, so that a C++ expression that would select it
is rejected, rather than converted to the operand type of another impl:

```carbon
impl Money as Core.AddWith(i32) where .Result = (i32, i32) { ... }
impl Money as Core.AddWith(i64) where .Result = i32 { ... }
```

Here C++'s `m + k` with an `int k` is an error ("overload resolution selected
deleted operator"), while `m + k` with a `long k` calls the `i64` impl, as
Carbon does for an `i64` operand. A class that C++ cannot export at all, such as
one with a tuple field, makes a C++ use of an operator whose impls name it report
that class's export error, as it does for a C++ call of any exported function
that names it.

## Carbon operator expressions are unchanged

When an operand of a Carbon operator expression is a C++ type, Carbon also asks
C++ for a matching operator, which it resolves with C++ overload resolution
(see the
[C++ interop proposal's operator calls](/proposals/p006254-c-interop-toolchain-implementation-for-function-calls.md#operator-calls)).
That lookup does not export any Carbon impl, and an operator that C++ code
exported earlier is not among its candidates: it is Carbon's own impl seen from
C++, which Carbon's impl lookup finds itself. So a Carbon operator expression
calls the same function it called before operators were exported, a
hand-written C++ operator included.

## Divergences

Each side resolves an operator expression under its own rules, as for an
exported [overload set](README.md#overload-resolution):

-   C++ applies its implicit conversions to the operands of an exported
    operator, so `m*3L` calls an `impl Money as MulWith(i32)` by converting the
    `long` to `int`, where Carbon would need an impl for `i64`.
-   C++ member lookup searches base classes, so `d+d` on a class derived
    from a Carbon base class calls the base's `AddWith(Base)` impl after
    converting both operands to the base, where Carbon finds no impl for the
    derived class.
-   C++ sees the impl function's own signature: for
    `impl Money as AddWith(i32) where .Result = i64` whose `Op` returns `i32`,
    Carbon's `m + k` is an `i64` and C++'s `m + 1` an `int`; and a function
    whose parameter is `i64` takes a C++ `long` that Carbon's `AddWith(i32)`
    lookup would not.
-   C++ passes a value operand by value, so it copies an lvalue operand: a class
    that C++ cannot copy, such as one with a move-only C++ field, can be an
    operand in Carbon but only an rvalue operand in C++.

The divergence is bounded to which impl runs, the static type C++ gives the
result, or whether the expression compiles; every exported operator calls
exactly one Carbon impl function.

## Conversions

The design overview also says that "the `ImplicitAs(U)` Carbon interface
corresponds to implicit conversions in C++", and the
[`as` expressions proposal](/proposals/p000845-as-expressions.md) that `As` provides the
functionality of C++'s `explicit` constructors and conversion functions for
interoperability. Neither is exported yet (fork work item W-208): C++ spells a
conversion as a conversion function or a converting constructor, not an
overloaded operator, and Clang collects a class's conversion functions from its
definition rather than by name, so exporting them is a design of its own.

## Hand-written C++ operators

C++ code may have declared its own operator for an exported Carbon class before
Carbon operator impls were exported. Where it duplicates an impl, C++ now finds
two equally good candidates and reports the use as ambiguous (fork work item
W-211); remove the hand-written operator. Carbon's own operator expressions are
not affected (see
[Carbon operator expressions are unchanged](#carbon-operator-expressions-are-unchanged)).

## 0.1 limits

-   A generic impl, such as
    `impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)`, and the
    impls of a specific of a generic class are not exported (fork work item
    W-202). While they are not, C++ may convert an operand to the operand type
    of a concrete impl, and so call another impl than the generic one Carbon
    selects.
-   Only the impls of the file that contains the `inline Cpp` block are
    exported; the impls of an imported library are not (W-204), and a class
    imported from another library is not yet exported correctly (W-203).
-   An impl declared after C++ code has looked up that operator on the class or
    namespace is not seen by later C++ code (W-205). A Carbon operator
    expression is not such a lookup.
-   `<=>` is not exported until `OrderedWith` declares its three-way `Compare`
    (W-206).
-   Two impls whose operand types map to one C++ type make every use of that
    operator ambiguous in C++ (W-207).
-   `As` and `ImplicitAs` are not exported as C++ conversions (W-208).
-   `a[i]` returns a value until the reference forms of indexing exist
    (W-209, W-109).
-   An impl with no Carbon class among its types, such as
    `impl Cpp.Foo as AddWith(i32)`, is not exported, because C++'s
    argument-dependent lookup does not look in namespace `Carbon` for it
    (W-210).

## Alternatives considered

-   Exporting only `operator+`, the arbiter's case: rejected, because the
    bullet is the whole operator mapping, not one operator.
-   Exporting every impl as a non-member operator: rejected, because C++ would
    then convert the left operand implicitly, which Carbon's dispatch on `Self`
    never does.
-   Hidden friend functions for impls whose `Self` is the class: rejected,
    because argument-dependent lookup finds a friend through either operand,
    so C++ would convert the left operand implicitly, as with a non-member
    operator.
-   Leaving `!=` to C++20's rewrite of `==`: rejected, because the default
    language mode of an `inline Cpp` block is C++17, and because the rewrite
    adds reversed `==` candidates that Carbon does not have.
-   Leaving out an impl whose result has no C++ form: rejected, because C++
    could then select another impl by converting the operand.
-   Making each exported operator evaluate the Carbon operator expression
    rather than call the impl's function: rejected for 0.1, because only
    concrete impls are exported, for which impl lookup selects exactly that
    impl, so both call the same function, and the expression form needs a new
    kind of thunk.

## References

-   [Bidirectional interoperability with C and C++](README.md)
-   [Design overview: operator overloading in C++ interoperability](../README.md#operator-overloading-1)
-   [Operator expressions](../expressions/README.md#operators)
-   Proposal
    [#702: Comparison operators](/proposals/p000702-comparison-operators.md)
-   Proposal [#845: `as` expressions](/proposals/p000845-as-expressions.md)
-   Proposal
    [#1178: Rework operator interfaces](/proposals/p001178-rework-operator-interfaces.md)
-   Proposal
    [#1191: Bitwise and shift operators](/proposals/p001191-bitwise-and-shift-operators.md)
-   Proposal
    [#6254: C++ interop toolchain implementation for function calls](/proposals/p006254-c-interop-toolchain-implementation-for-function-calls.md)
````

#### docs/design/interoperability/README.md (amendment)

Inserted after the heading at :350, "## TODO: The operator interoperability
model", which stays as it is (DD-1 replaces the section; §6.2.1 gives the
merge-time edit):

```markdown
> **Fork amendment (2026-10-14, F-017).** The export direction is specified in
> [Exporting Carbon operators to C++](operators.md): an implementation of a
> `Core` operator interface for a Carbon class is a C++ operator on the exported
> Carbon type — a member operator when the implementing type is that class, and
> otherwise a non-member operator in the class's namespace that C++ finds by
> argument-dependent lookup. C++ resolves these operators under its own rules,
> a documented divergence like that of exported overload sets; conversions are
> not yet exported.
```

### §2.8 Records (commit 5 moves the row; commit 6 writes the rest, after the merge of trunk and §8.8)

**The row** (commit 5, fork/gap-analysis.md:48 at f67ab650d; re-read its line at
the merge of trunk, R7). Status MISSING → PARTIAL (D-OX-14); the evidence cell
becomes (the status, W-208's clause and the residue list amended 2026-10-14,
review fold: A-6, B-4, B-3, A-3; the decision-log entry and the README
amendment are no longer cited from commit 5, which precedes them, B-5):

```text
OX-1 landed (W-054 DISCHARGED <date>, fork/opexport/plan.md, fork design F-017, docs/design/interoperability/operators.md): an impl of a `Core` operator interface for a Carbon class is a C++ operator on the exported Carbon type — the arithmetic, negation, bitwise and shift, compound-assignment, increment and decrement, comparison and indexing interfaces, 31 members — a member operator (`const` for `self`, `&` for `ref self`) when the impl's `Self` is the class, and otherwise a non-member operator in the class's innermost enclosing namespace found by argument-dependent lookup (`int - Carbon::Money` from `impl i32 as SubWith(Money)`, `Foo + Carbon::Money` from an imported C++ `Self`); `!=` is exported for an impl that keeps `EqWith`'s default `NotEqual`, as `!(a == b)`, so C++17 has it and C++20 synthesizes no reversed `==`; an impl whose operand has no C++ form is omitted and one whose result alone has none is declared deleted; Carbon's own operator expressions export nothing and never call an exported operator (cpp/class/export/operator.carbon, operator_ast.carbon, operator_cxx20.carbon, lower cpp/class/export/operator.carbon). 7/7 programs PASS — interop/cpp_operator_export (SKIP -> PASS, EXPECT 42) and cpp_operator_export_{arithmetic,compound,compare,bitwise,index,nonmember} — expected, not of record: container run on the built toolchain, GitHub Actions disabled. C++ resolves the exported operators under C++'s rules (operand conversions, base-class lookup, the impl function's own signature, by-value operands), a documented divergence. PARTIAL: the design overview maps `ImplicitAs` to C++ implicit conversions in the same section (docs/design/README.md:3679-3681), and `As`/`ImplicitAs` are not exported (W-208). Filed limits: generic impls and generic-class specifics (W-202), impls of an imported library (W-204, blocked by W-203), an impl declared after C++ code looked its operator up (W-205), `<=>` (W-206), same-signature impls (W-207), `ref` indexing (W-209), impls with no Carbon class among their types (W-210), hand-written C++ operators that duplicate an impl (W-211).
```

**The header** (commit 5): "N DONE / M PARTIAL / K MISSING / L DESIGN-ONLY" as
it stands at the commit becomes M+1 PARTIAL and K−1 MISSING (at f67ab650d: 30 /
21 / 4 / 1 → 30 / 22 / 3 / 1), and the reconciliation sentence after it names
the expected conformance totals of §5 relative to the trunk floor at the
commit, "expected, not of record". Recompute with `grep -cE '^\| [^|]+ \| DONE
\|' fork/gap-analysis.md` and the same for PARTIAL, MISSING and DESIGN-ONLY,
before and after; commit 6 recounts it on the merge commit (amended 2026-10-14,
review fold: A-6, B-4, B-5).

**The ledger** (commit 6, fork/inventory/work-items.json). W-054 becomes:

```json
{
 "id": "W-054",
 "title": "OX-1 (LANDED <date>): Carbon operator impls exported as C++ operator overloads (fork design F-017) — member operators for impls on the exported class, non-member operators found by argument-dependent lookup otherwise, the default `!=`, deleted operators for results with no C++ form; Carbon operator expressions export nothing and never call an export",
 "kind": "implemented",
 "subsystem": "toolchain/check/cpp (export, generate_ast, operators, context) + docs/design/interoperability",
 "size": "L",
 "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++",
 "evidence": [
  "toolchain/check/cpp/export.cpp (`OperatorExportTable`, `IsOperatorImplOfKind`, `IsUnmappableWithoutExport`, `ClassifyOperatorExport`, `GetImplMemberFunctionId`, `RegisterExportedOperator`, `BuildCppOperatorDecl`, `ExportImplFunctionAsCppOperator`, `BuildDefaultNotEqualOperator`, `ExportImplOperators`, `ExportOperatorsToCpp`, `ExportNonMemberOperatorsToCpp`, `IsExportedCarbonOperator`; the one in-function hunk, `BuildCppToCarbonThunkBody`'s `isa<clang::CXXMethodDecl>` condition)",
  "toolchain/check/cpp/generate_ast.cpp (`FindExternalVisibleDeclsByName`: the `CXXOperatorName` arm, which answers nothing and caches nothing during Carbon's own operator lookup)",
  "toolchain/check/cpp/operators.cpp (`FindClangOperator`: Carbon's lookup runs with `in_carbon_operator_lookup()` set; exported Carbon operators are non-viable candidates) and toolchain/check/cpp/context.h (`CppContext::in_carbon_operator_lookup()`)",
  "toolchain/check/testdata/interop/cpp/class/export/operator.carbon (36 splits), operator_ast.carbon and operator_cxx20.carbon (4 splits); toolchain/lower/testdata/interop/cpp/class/export/operator.carbon (6 splits); filled at <fill commit>",
  "fork/conformance/programs/interop/cpp_operator_export.carbon (SKIP -> PASS) and cpp_operator_export_{arithmetic,compound,compare,bitwise,index,nonmember}.carbon",
  "docs/design/interoperability/operators.md (F-017); <the README text at the merge commit: DD-1's operator section as §6.2.1 edits it, or this plan's dated amendment if DD-1 has not merged>; fork/opexport/plan.md; fork/decision-log.md \"OX-1 / F-017\"",
  "fork/gap-analysis.md, the row \"Type system: C++ interop — exporting Carbon operator overloads into C++\" (line 48 at f67ab650d; the original evidence's :30 was stale), PARTIAL, bounded by W-208"
 ],
 "blocked_by": [],
 "notes": "Discharged by OX-1 (fork/opexport/plan.md). W-007's precondition was met by sequencing, as for EH-B, UN-2 and OV-3: no other export.cpp contender was in flight except ST-1's disjoint 5-line hunk (PR 55), and every OX-1 edit is a new function, a new switch arm in generate_ast.cpp, a `CppContext` member, a restructured call and a candidate filter in operators.cpp, or the one behaviour-preserving condition in BuildCppToCarbonThunkBody; thunk.cpp and type_mapping.cpp untouched. The row stays PARTIAL for conversions (W-208). Residues W-202, W-204..W-211 under this row; W-203 under the type-export row."
}
```

New items (commit 6; `kind`, `subsystem` and `size` as below, `evidence` as
cited; W-202, W-205 and W-208 amended and W-210 and W-211 added 2026-10-14,
review fold: B-2, A-4, A-6, B-4, B-3, A-3):

```json
[
 {"id": "W-202", "title": "OX-1 residue: generic operator impls, and the operator impls of a generic class's specifics, are not exported to C++, so C++ may convert an operand to a concrete impl's type where Carbon selects the generic impl", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["toolchain/check/cpp/export.cpp `IsOperatorImplOfKind` (skips `impl.generic_id`) and `ExportOperatorsToCpp` (skips a class specific)", "toolchain/check/testdata/interop/cpp/class/export/operator.carbon split fail_todo_generic_impl (`impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)`: C++ `m * 3` is `invalid operands`; Carbon's `m * 3` compiles)", "toolchain/lower/testdata/interop/cpp/class/export/operator.carbon split generic_impl_hidden (with a concrete `MulWith(i64)` beside it, C++ `m * k` for an `int k` calls the `i64` impl; Carbon's `m * k` for `k: i32` calls the generic impl)", "fork/opexport/plan.md M-11(a), M-28"], "blocked_by": [], "notes": "A generic impl's `Op` needs a C++ template (or one declaration per C++ argument type C++ asks about), the machinery of the generics-export row (W-117 is the overload-set analogue). Until then the generic impl is invisible to C++, and a C++ operand that converts to a concrete impl's operand type selects that impl (M-28); a deleted declaration cannot cover it. Filed at the OX-1 discharge."},
 {"id": "W-203", "title": "Exporting a Carbon class imported from another library yields an empty C++ record: no fields, and an exported method returning it by value corrupts memory (upstream defect)", "kind": "toolchain-defect", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — importing C++ types / exporting Carbon types", "evidence": ["fork/opexport/plan.md M-11(d): `.cents` of an imported class is `no member named 'cents'`; an exported `Plus` returning the imported class then `Get()` prints -1265344497 on trunk 0bdce60a5 and -1536643875 on the nightly 2026.10.12 where 42 is right; the C++ AST shows `class Money definition ... empty aggregate` with no FieldDecl", "toolchain/check/cpp/export.cpp:570-618 `ExportAllFieldsToCpp` (a struct field whose class-scope entry is not found is skipped, :581-583)"], "blocked_by": [], "notes": "Found by the OX-1 audit; pre-existing and upstream. The root cause is not yet confirmed: the hypothesis is that `LookupClassFieldByStructField` does not find an imported class's fields in its scope before their import refs are loaded. Fix belongs to the type-export row, not to OX-1."},
 {"id": "W-204", "title": "OX-1 residue: operator impls declared in an imported library are not exported to C++", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["toolchain/check/cpp/export.cpp `ExportOperatorsToCpp` walks `context.impls()` only (the impl lookup's import of associated libraries' impls, check/impl_lookup.cpp:669-691, has no counterpart)", "operator.carbon splits money_lib + fail_todo_imported_class", "fork/opexport/plan.md M-11(d)"], "blocked_by": ["W-203"], "notes": "Needs the class's defining library's impls imported (filtered to the Core operator interfaces), and W-203's class export fixed first. When it lands, check that two files exporting the same impl's operator do not both define the external `<member>__carbon_thunk` symbol at link time (exported methods share that open question)."},
 {"id": "W-205", "title": "OX-1 residue: an operator impl declared after C++ code looked that operator up on the class or namespace is not seen by later C++ code", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (generate_ast)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["operator.carbon split fail_todo_impl_after_lookup (the second block's `m + 1` is `invalid operands`, the note names only the first impl)", "clang/lib/AST/DeclBase.cpp:1952-1954 (a stored answer is returned without asking again)", "upstream e476a2bd3 (re-enables external lookup for identifiers after a failure; not yet on the fork)"], "blocked_by": [], "notes": "Only C++ code's lookups are cached: Carbon's own operator expressions export nothing and leave no answer (D-OX-21; the carbon_side_then_cpp split). A use before the impl (fail_impl_after_use) is C++'s own rule and not this item. The fix re-asks the source when the impl set has grown since the cached answer."},
 {"id": "W-206", "title": "OX-1 residue: `<=>` is not exported; the prelude's `OrderedWith` has no `Compare`", "kind": "missing-feature", "subsystem": "core/prelude + toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["core/prelude/operators/comparison.carbon:24 (`TODO: fn Compare`)", "docs/design/expressions/comparison_operators.md:345-380 (`fn Compare(self, u: U) -> Ordering`)"], "blocked_by": [], "notes": "When `Compare` lands, export it as `operator<=>` returning a C++ ordering type that `Ordering`'s four values map to (`std::partial_ordering`, given `Incomparable`), and revisit D-OX-6: `<=>` lets C++20 rewrite the relational operators."},
 {"id": "W-207", "title": "OX-1 residue: two operator impls whose operand types map to one C++ type are ambiguous at every C++ use (the W-118 shape)", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["fork/opexport/plan.md M-11(e) (`AddWith(i64)` beside `AddWith(Cpp.long)`: Carbon rejects the pair as same-structure non-final impls; C++ reports `use of overloaded operator '+' is ambiguous`)"], "blocked_by": [], "notes": "Reachable only with `final` impls or types such as `Core.CppCompat.Long64` beside `i64` (W-118's notes). Each impl keeps its own thunk symbol, so no call has the wrong ABI."},
 {"id": "W-208", "title": "OX-1 residue (bounds the row): `As` and `ImplicitAs` impls are not exported as C++ conversions", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export, generate_ast)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["docs/design/README.md:3679-3681 (`ImplicitAs(U)` corresponds to implicit conversions in C++, in the operator-overloading interop section)", "proposals/p000845-as-expressions.md:184-187 (`As` exposes C++'s `explicit` constructors and conversion functions for interoperability)", "toolchain/check/cpp/operators.cpp:42-52 (the import direction's `As`/`ImplicitAs`: `TODO: Support destructors and conversions`)", "fork/opexport/plan.md D-OX-18"], "blocked_by": [], "notes": "The row is PARTIAL until this lands. Clang collects conversion functions from the class definition, so these need an eager export at `CompleteType`, explicit for `As`, implicit for `ImplicitAs`; and C++ may convert by constructor or by conversion function (an `impl X as ImplicitAs(C)` is a converting constructor of `C`), a design choice F-017 does not make. docs/project/milestones.md:200 (the prelude's 'operators, conversions') does not bear on the scope."},
 {"id": "W-209", "title": "OX-1 residue: `operator[]` returns by value; the `ref` forms of indexing are not exported", "kind": "missing-feature", "subsystem": "core/prelude + toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["core/prelude/operators/index.carbon:7-10 (`At` only)", "docs/design/expressions/indexing.md:46-97 (`IndexWith.Ref`, `IndirectIndexWith`)"], "blocked_by": ["W-109"], "notes": "When W-109 adds the `ref` forms, export `Ref` as a non-`const` `operator[]` returning `E&` beside the `const` one."},
 {"id": "W-210", "title": "OX-1 residue: operator impls with no Carbon class among their types are not exported to C++ (a C++ or primitive `Self` with a non-Carbon operand, or a unary impl on a C++ type)", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export, generate_ast)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["operator.carbon split fail_todo_non_carbon_operands (`impl Cpp.Foo as AddWith(i32)`: C++ `f + 2` is `invalid operands`)", "fork/opexport/plan.md M-29 (`impl Cpp.Foo as Negate`: `invalid argument type 'Foo' to unary expression`)"], "blocked_by": [], "notes": "C++'s argument-dependent lookup for such operands never asks namespace `Carbon`. Exporting them needs the external source to answer operator lookups in the C++ type's own namespace (a C++-owned context the source does not serve today) or in the global namespace, and a rule for impls on Carbon primitives, which C++ sees as builtin types with no associated namespace. Outside the row's criterion as narrowed by OX-1 (the design overview's 'Carbon types implementing an operator overload'), filed as a limit."},
 {"id": "W-211", "title": "OX-1 residue: a hand-written C++ operator for an exported Carbon class that duplicates a Carbon operator impl is ambiguous with the exported operator in C++", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export) + docs/design/interoperability", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["operator.carbon split fail_user_cpp_operator_ambiguous (`operator+(const Carbon::Money&, const Carbon::Money&)` beside `impl Money as AddWith(Money)`: `use of overloaded operator '+' is ambiguous`; on trunk the same program printed 1042)", "fork/opexport/plan.md M-22"], "blocked_by": [], "notes": "C++ code written before OX-1 to fill the gap changes meaning: it now fails to compile. Carbon's own operator expressions are unaffected (D-OX-11). The page's 'Hand-written C++ operators' section gives the migration (remove the hand-written operator); a diagnostic note pointing at the Carbon impl, or a rule preferring one candidate, is the open design."}
]
```

W-007's notes gain (commit 6): "OX-1 (<date>, fork/opexport/plan.md D-OX-16):
landed additively by sequencing — new functions in export.cpp and export.h, a
new `CXXOperatorName` arm in generate_ast.cpp, a `CppContext` member in
check/cpp/context.h, a restructured `LookupOverloadedBinOp` call and a candidate
filter in operators.cpp's `FindClangOperator`, and ONE in-function hunk in a
contention file, `BuildCppToCarbonThunkBody`'s `target.self_param &&
isa<clang::CXXMethodDecl>(function_decl)` condition, behaviour-preserving for
every earlier caller; thunk.cpp and type_mapping.cpp untouched; nothing moved or
renamed; ST-1's disjoint export.cpp hunk, in PR 55, was the only other contender
in flight. W-054's blocked_by edge is cleared. Remaining contender: SC-B3
(W-029)."

**The decision log** (commit 6, fork/decision-log.md, newest first under
"Decided"): an entry headed "### OX-1 / F-017: Carbon operator impls exported as
C++ operator overloads (<date>)" that records, in the ST-1 entry's order: the
bullet and the row's move (MISSING → PARTIAL, bounded by W-208, expected and not
of record, the header delta, the conformance totals as expected); the context
(the empty README section, the provisional overview and its `ImplicitAs`
sentence, p006254's "Operator calls", V-3); the landed commits by hash (§3's
commits 2 to 6, the plan's revisions, the review folds, the merge of trunk);
WHAT LANDED by mechanism (the table, the two walks, the classification, the
deleted declarations, the default `!=`, Carbon's lookup exporting nothing, the
candidate filter, the one in-function hunk); D-OX-1..D-OX-21 as a veto digest,
one line each with its break condition; the residues W-202..W-211;
DEVIATIONS from this plan (each with its measurement); the verification record
of §8 (what ran, on which commit, what did not); and the V-3a divergence-risk
register entries (process.md standing rule 7, as the OV-3, ST-1 and OP-2
entries carry them, reviewed at each upstream merge): (1) the
`CXXOperatorName` arm of `FindExternalVisibleDeclsByName` against upstream
e476a2bd3's restructure (a `GetCarbonOwnedDecl` prologue, the re-export guard
for a filled entry and the negative-lookup erasure): on merge, keep upstream's
prologue and put the arm after it, drop OX-1's own erasure code if upstream's
covers operator names, and drop the duplicate `DeclContextInternals.h`
include; (2) `CppContext::in_carbon_operator_lookup()` and the suppression in
`FindClangOperator`: if upstream gives the external source its own notion of
which lookups come from Carbon, use it; (3) the candidate filter's use of
`ovl_non_default_multiversion_function` as a silent non-viable marker: if
Clang changes how that kind is noted, or upstream adds a way to exclude
candidates, switch; (4) the `isa<clang::CXXMethodDecl>` conjunct in
`BuildCppToCarbonThunkBody`, against any upstream change of that function's
`this` handling. The entry is the decision record F-017 (the register entries
and the merge added 2026-10-14, review fold: B-12, B-5).

**fork/ORCHESTRATION.md** (commit 6, on the merge commit, whose trunk side
carries the Branches row for `claude/carbon-fork-0-1-ox` that 44761146d added;
f67ab650d has none): a dated stamp paragraph after the latest one — "OX-1
(claude/carbon-fork-0-1-ox, head <hash>: Carbon operator impls exported as C++
operator overloads, fork design F-017; W-054 discharged, W-202 to W-211 filed;
expected <totals>; row PARTIAL, bounded by W-208) is OPEN and HELD, verified on
the container-built toolchain at the merge commit" — and that Branches row
changed from PLANNING to "HELD OPEN as PR <n> — OX-1 at <hash> (W-054
discharged; W-202..W-211 filed; expected <totals>; row PARTIAL, W-208);
merged trunk after DD-1 and PR 57" (amended 2026-10-14, review fold: B-5).

**fork/conformance/README.md** (commit 5): the generated program table, by
`python3 fork/conformance/runner.py --update-readme-table` (the arbiter's row
from SKIP to `run`, six new `run` rows); `--self-test` then passes; commit 6
regenerates it on the merge commit.

## §3 Commit structure (one PR, "OX-1: Carbon operator impls exported as C++ operator overloads", R29(b))

Every commit `--author="jmann345 <jerrymannstan@gmail.com>"`, committer
`Claude <noreply@anthropic.com>`, the session trailers after a blank line,
explicit paths only (R20). A problem found after a commit exists is fixed by a
new commit, never by amending or rebasing one (AGENTS.md: the history of a PR is
never rewritten; amended 2026-10-14, review fold: B-12).

1.  **This plan** (fork/opexport/plan.md), then its review folds: rev 2 (this
    revision, folding reviews A and B of rev 1, 3128eded5), and rev 3 if the
    focused re-review asks for one.
2.  **Toolchain**: toolchain/check/cpp/export.cpp, export.h, generate_ast.cpp,
    operators.cpp and context.h, §2.1 to §2.4 applied with `git apply`. Alone it
    keeps file_test green (M-8: 1942 of 1942 with `v5`), so it is a commit of
    its own.
3.  **Golden sources**: the four files of §2.5 with `// AUTOUPDATE` and no
    CHECK lines. file_test is red from here until commit 4, as R19 expects for
    unfilled goldens.
4.  **The fill**: "Autoupdate testdata goldens on the container arbiter" —
    `autoupdate.sh` twice (R26; M-12 measured that pass 2 changes all four
    files), then a third pass that must change nothing, then `gate.sh`; only the
    four new files change.
5.  **Programs, docs and the row**: the seven programs of §2.6, the README
    program table (`--update-readme-table`),
    docs/design/interoperability/operators.md and the README amendment (§2.7),
    and the row and header of §2.8, quoting §8.4's container run on commit 2's
    build (which commits 3 and 4 do not change), as expected, not of record.
    The row names no record that commit 6 writes.
6.  **Discharge**, after everything in the next paragraph: the ledger (W-054,
    W-202..W-211, W-007's notes), the decision-log entry, the ORCHESTRATION
    stamp and Branches row, the row's and header's re-quote and the README
    table from §8.8's run on the merge commit, and this plan's landed notes;
    preceded by the id re-scan of the head.

**Between commits 5 and 6**, in this order (the OP-2 plan's sequence; amended
2026-10-14, review fold: B-5, B-12): the implementation reviews of R29(c) (two,
because Actions is disabled and no hosted verification can be green; the OP-1
and OP-2 precedent); their fold by a separate fixer agent (R11: never the
implementer continuing, never a reviewer), in new commits ("OX-1 fixes: fold the
implementation reviews"), each refill its own "Autoupdate testdata goldens on
the container arbiter" commit; then the merge of trunk, taken when DD-1 (PR 58)
and PR 57 have merged (D-OX-19; fork/ORCHESTRATION.md's order at 3eb7f36f0 puts
PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, PR 56 and PR 57 before PR 58, and OX-1
and VA-1 after PR 58); then §8.8 on the merge commit; then commit 6. Before each
of commits 2 to 6 and each fix commit, `uvx prek run --files <that commit's
files>` runs to a fixpoint, with R31's heading and list-item counts recorded
before and after for every `.md` in the commit; before hand-over, `uvx prek run`
with `--all-files` in place of the file list runs to a fixpoint too (R25).

**The merge of trunk** (a merge commit, never a rebase; amended 2026-10-14,
review fold: B-5). Each kind of conflict has a fixed rule:

-   **Goldens.** A conflicted golden takes trunk's side
    (`git checkout --theirs <path>`, trunk being the merged branch) and is
    refilled by autoupdate in a new "Autoupdate testdata goldens on the
    container arbiter" commit after the merge; CHECK lines are never merged by
    hand (R16(a)). OX-1's four new goldens do not conflict, but the lower golden
    includes min_prelude/full.carbon, whose prelude PR 55 and PR 57 change; if
    §8.8's gate shows any of the four (or any trunk golden) red on the merge
    commit, that refill commit refills it.
-   **The interop README.** If DD-1 has merged, the README takes trunk's side,
    OX-1's dated amendment of §2.7 is dropped, and §6.2.1's three sentence
    replacements are applied in the merge's resolution, with R31's counts
    before and after; if DD-1 has not, the amendment stays and DD-1's next fold
    applies §6.2.1 (D-OX-19's break condition).
-   **Records.** gap-analysis.md, work-items.json, decision-log.md,
    ORCHESTRATION.md and conformance/README.md keep trunk's rows and entries for
    other branches and take this branch's OX-1 rows, re-anchored by bullet text,
    item id or heading, never by line number (R7); the gap header is recounted,
    never merged; the README table is regenerated by
    `runner.py --update-readme-table`.
-   **Ids.** If any of W-202..W-211 or F-017 is taken by then (the head's
    test), the head's re-allocation rule applies in a new commit to every
    program header, golden source, doc and record that names it.
-   **Dates.** If commit 6's date differs from commit 5's, commit 6 re-stamps
    every `<date>` commit 5 wrote (the page's F-017 line, the README amendment
    if kept, the row) to the landing date.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

No existing golden is refilled (M-8). Predicted key lines, each taken from the
`v5` fill in the scratch mirror (`$F/fill-v5f.snap3/`, M-12) with the split's
own filename in place of the substitute's (amended 2026-10-14, review fold:
A-1, A-2, A-3, A-4, A-5, A-7, A-9, B-1, B-2, B-3, B-6, B-10):

| File / split | Must | Key line(s) |
| --- | --- | --- |
| check operator.carbon: arithmetic, signature_from_impl_function, compound_assignment, comparison, move_only_not_equal, bitwise, index, non_member, non_member_nested, namespace, base_class, unmappable_impl, deleted_result_unselected, cpp_side_unrelated_impl, carbon_side_unmappable, carbon_side_unexportable_class, carbon_side_generic_class, carbon_side_unrelated_impl, carbon_side_candidates, carbon_side_user_cpp_operator, carbon_side_then_cpp, money_lib | compile | no output (no SemIR ranges; the `static_assert`s hold) |
| fail_conversion_carbon_side | fail | ``error: cannot access member of interface `Core.MulWith(i64)` in type `Money` that does not implement that interface [MissingImplInMemberAccess]`` |
| fail_compound_assignment_rvalue | fail | `error: no viable overloaded '+=' [CppInteropParseError]`; note `candidate function not viable: expects an lvalue for object argument` |
| fail_postfix_increment | fail | `error: cannot increment value of type 'Carbon::Money' [CppInteropParseError]` |
| fail_reversed_equality | fail | `error: invalid operands to binary expression ('int' and 'Carbon::Money') [CppInteropParseError]` (the `Reversed` line only) |
| fail_base_class_carbon_side | fail | ``error: cannot access member of interface `Core.AddWith(Derived)` in type `Derived` that does not implement that interface [MissingImplInMemberAccess]`` |
| fail_noncopyable_lvalue_operand | fail | `error: call to implicitly-deleted copy constructor of 'Carbon::Money' [CppInteropParseError]`; notes `copy constructor of 'Money' is implicitly deleted because field 'n' has a deleted copy constructor`, `'NoCopy' has been explicitly marked deleted here`, `passing argument to parameter here` (the `CppSide` line only) |
| fail_todo_generic_impl | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'int') [CppInteropParseError]` |
| fail_deleted_result | fail | `error: overload resolution selected deleted operator '+' [CppInteropParseError]`; notes `candidate function has been explicitly deleted` and `candidate function` |
| fail_todo_unexportable_operand_class | fail | ``error: semantics TODO: `failed to map Carbon type to C++` [SemanticsTodo]`` at Holder's field `t` |
| fail_user_cpp_operator_ambiguous | fail | `error: use of overloaded operator '+' is ambiguous (with operand types 'Carbon::Money' and 'Carbon::Money') [CppInteropParseError]`; two `candidate function` notes |
| fail_todo_non_carbon_operands | fail | `error: invalid operands to binary expression ('Foo' and 'int') [CppInteropParseError]` |
| fail_impl_after_use | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'Carbon::Money')` |
| fail_todo_impl_after_lookup | fail | `error: invalid operands ... ('Carbon::Money' and 'int')`; note `candidate function not viable: no known conversion from 'int' to 'Carbon::Money' for 1st argument` |
| fail_todo_imported_class | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'Carbon::Money')` |
| check operator_ast.carbon: operator | compile | `CXXMethodDecl ... used operator+= 'void (int) &' inline internal-linkage`; `CXXMethodDecl ... used operator+ 'Carbon::Money (Carbon::Money) const'` calling `Op__carbon_thunk`; `CXXMethodDecl ... used operator!= 'bool (Carbon::Money) const'` whose body is `UnaryOperator ... prefix '!'` over the `.operator==` call with an `ImplicitCastExpr ... 'Carbon::Money' xvalue <NoOp>` argument; `CXXMethodDecl ... operator* 'void (int) const' inline delete external-linkage` beside `used operator* 'int (Carbon::Money) const'`; `FunctionDecl ... used operator- 'int (int, Carbon::Money)' inline internal-linkage` in `namespace Carbon` (183 CHECK lines) |
| check operator_cxx20.carbon: move_only_equality | compile | no output |
| fail_reversed_equality | fail | `error: invalid operands to binary expression ('int' and 'Carbon::Money') [CppInteropParseError]` (the `Reversed` line) |
| fail_reversed_equality_non_member | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'int') [CppInteropParseError]`; note `candidate function not viable: no known conversion from 'Carbon::Money' to 'int' for 1st argument` |
| fail_reversed_ordering | fail | `error: invalid operands to binary expression ('int' and 'Carbon::Money') [CppInteropParseError]` (15 CHECK lines in the file) |
| lower operator.carbon: member | compile | `define void @"_COp__carbon_thunk.Money.Main:AddWith.7b773fb4f7cbc162.Core"`; `define internal i32 @_ZNK6Carbon5MoneyplES0_` calling it; `define internal void @_ZNR6Carbon5MoneypLEi` |
| default_not_equal | compile | `define internal noundef zeroext i1 @_ZNK6Carbon5MoneyneES0_` calling `@_ZNK6Carbon5MoneyeqES0_` and negating its result |
| non_member | compile | `define internal noundef i32 @_ZN6CarbonmiEiNS_5MoneyE` calling `@"_COp__carbon_thunk.Int.be1e879c1ad406d8.Core:SubWith.7b773fb4f7cbc162.Core"` |
| carbon_side_cpp_operand | compile | `define i32 @_CCarbonSide.Main` whose one call is `call i32 @"_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core"`; `@_CCppSide.Main` reaches `@_ZNK6Carbon5MoneyplE3Foo` |
| carbon_side_default_not_equal | compile | `define i1 @_CCarbonSide.Main` calling `@_CNotEqual.EqWith.Core.8d8286e58955f8ab` (the interface's default for the impl), which calls `@"_CEqual.Foo.Cpp:EqWith.7b773fb4f7cbc162.Core"`; `@_CCppSide.Main` reaches `@_ZN6CarbonneE3FooNS_5MoneyE`, which calls `@_ZN6CarboneqE3FooNS_5MoneyE` |
| generic_impl_hidden | compile | `define i32 @_CCarbonSide.Main` calling the generic impl's specific `@"_COp.Money.Main:MulWith.dc0fcff0a74064b8.Core.cfa19092a257b072"`; `define internal noundef i32 @_ZNK6Carbon5MoneymlEl` calling `@"_COp__carbon_thunk.Money.Main:MulWith.f249b435619a5146.Core"` (1079 CHECK lines in the file) |

The fingerprints in symbol names are the fill's; a reviewer checks the shapes,
not the hex digits, which depend on the specific's fingerprint and are
reproduced by any fill of the same sources. Falsifiers: any crash; a golden
outside §2.5's four in the fill's diff; a `fail_` split that compiles or a
non-`fail_` split with a diagnostic; any key line above that the fill does not
reproduce; a third autoupdate pass that changes anything (R26).

## §5 Conformance: one SKIP → PASS, six new; delta PASS +7, SKIP −1, programs +6

From the floor of record 128 / 0 / 22 over 150, 48/56 bullets (trunk;
re-measured in the container, M-13) to 135 / 0 / 21 over 156, 49/56 (M-13,
`v5`). Programs that move: interop/cpp_operator_export (SKIP → PASS). New, PASS:
interop/cpp_operator_export_arithmetic, _compound, _compare, _bitwise, _index,
_nonmember. No other program changes status (128 of 128 PASS stay PASS under
`v4`; the full tree under `v5` has no failure). The bullet "Type system: C++
interop — exporting Carbon operator overloads into C++" goes from SKIP to PASS
with 7 programs, while its row is PARTIAL (D-OX-14). At OX-1's land time the
totals are measured, not computed: §8.8 runs the conformance suite on the
merge commit, and commit 6 quotes that run (amended 2026-10-14, review fold:
B-5).

## §6 Churn and collision analysis

### §6.1 Churn

toolchain: export.cpp +625/−1, export.h +27, generate_ast.cpp +41,
operators.cpp +22/−3, context.h +11. Goldens: four new files (≈971, 58, 112 and
177 source lines; after the fill 1062, 243, 130 and 1255 lines); no existing
golden changes. Programs: one modified, six new. Docs: one new page (≈300
lines), one 8-line amendment. Records: the row and header, the ledger (one item
replaced, ten added, one note extended), the decision log, ORCHESTRATION, the
conformance README table (amended 2026-10-14, review fold: all).

### §6.2 Collisions (measured against each live branch at the heads named, 2026-10-14)

| Branch (PR) | Head | Shared paths | Resolution |
| --- | --- | --- | --- |
| ST-1 (PR 55) | 21307851a | export.cpp (+5 at :293-300), interop README (+5 at :300), prelude and its full-prelude goldens, records | the diff applies at offset 5 (M-16); the README hunks are disjoint; OX-1's lower golden is refilled at the merge if the prelude change moves it (§3) |
| SC-1 | 0d7ee5c19 (444ccbafe at commit time, still none of OX-1's files) | records only (no file under toolchain/check/cpp; its toolchain work is in check/, impl_lookup.cpp among it, which OX-1 does not edit) | applies cleanly (M-16) |
| UA-2 (PR 51) | f96fe8a7a | records only | none |
| CM-1 (PR 52), SAFE-1 (PR 53), EV-1 (PR 54) | ea573f672, adaae4e35, cb3ef2e74 | records only | none |
| OP-1 (PR 56) | 379f20f67 | records only (prelude and other check files) | none |
| OP-2 (PR 57) | 628273444 | records; core/prelude/types/optional.carbon and toolchain/lower/handle.cpp, which refill full-prelude lower goldens | the diff applies cleanly; OX-1's lower golden includes the full prelude, so it is refilled at the merge if needed (§3) |
| DD-1 (PR 58) | fcee90d9b | docs/design/interoperability/README.md (+847: it fills "The operator interoperability model"), docs/design/README.md (a fork note at :3659 linking that section), records; its records mention W-202..W-211 only as OX-1's reservation | §6.2.1's three replacements at OX-1's merge of trunk after DD-1 |
| VA-1 | aced92197 (plan only) | records only: its plan names no file under toolchain/check/cpp, and its toolchain edits (check/context.h, call.cpp, deduce.cpp, lower and parse files, among others) touch none of OX-1's five files nor W-007's three | the id blocks are disjoint; VA-1 merges after OX-1 or DD-1, whichever is later (ORCHESTRATION at 3eb7f36f0) |

(Heads, the PR 55 and PR 57 prelude paths and the VA-1 row amended 2026-10-14,
review fold: A-10, B-5, B-8.)

#### §6.2.1 The merge-time edit of DD-1's text

At OX-1's merge of trunk after DD-1: drop OX-1's amendment block (§2.7) and keep
DD-1's section; in it, make three replacements, each of a whole sentence
wherever DD-1's wrapping puts it (re-checked at DD-1's head fcee90d9b, where
they are at :1113-1116, :1187-1189 and :782-784; amended 2026-10-14, review
fold: B-9). In "The operator interoperability model", replace the sentence that
begins

```text
The 0.1 toolchain implements the first direction: a Carbon operator expression with a C++ operand looks up the C++ operator functions, members and non-members, and resolves among them with C++ overload resolution (proposal 6254, "Operator calls").
```

with

```text
The 0.1 toolchain implements both directions. In the first, a Carbon operator expression with a C++ operand looks up the C++ operator functions, members and non-members, and resolves among them with C++ overload resolution (proposal 6254, "Operator calls"); a Carbon operator exported to C++ is not among them.
```

replace the section's last sentence

```text
The other direction is not implemented: a Carbon type's operator interface implementations are not exported as C++ operators (fork work item W-054).
```

with

```text
The other direction is specified in [Exporting Carbon operators to C++](operators.md) (fork design F-017): a Carbon type's operator interface implementations are C++ operators; conversions are not yet exported (fork work item W-208).
```

and in "Using Carbon from C++" replace

```text
Carbon operator implementations are not exported as C++ operators ([The operator interoperability model](#the-operator-interoperability-model)),
```

with

```text
Carbon operator implementations are C++ operators ([Exporting Carbon operators to C++](operators.md)),
```

Records: every branch edits fork/ORCHESTRATION.md, decision-log.md,
gap-analysis.md and work-items.json; OX-1's edits are an appended entry, one
row, new items and one note, merged at the merge of trunk by §3's rules.

### §6.3 Upstream

Upstream has not started operator export (M-17). At the next advance,
e476a2bd3's restructured `FindExternalVisibleDeclsByName` (a
`GetCarbonOwnedDecl` prologue, a re-export guard for an entry already filled,
and the erasure of an empty entry after a failed identifier lookup) takes OX-1's
arm as one more case after the prologue; its erasure is the mechanism D-OX-21
already uses for Carbon's own operator lookups, and applying it to an empty C++
operator answer too would close W-205's first half. context.h's,
generate_ast.cpp's and operators.cpp's hunks need their context refreshed, and
the fork's `DeclContextInternals.h` include is dropped as upstream's duplicate
(M-16; the decision log's V-3a entries, §2.8).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1 (Carbon-only code rejected).** Carbon's own operator expressions with
    a C++ operand reach Clang's operator lookup in the exported class (M-9).
    Rev 2 removes the cause instead of filtering its effects: that lookup
    exports nothing (D-OX-21). Falsifier: any `carbon_side_*` split, or any
    Carbon-only probe of M-20, M-22, M-23 or M-26 that trunk accepts, rejected
    or lowered differently on the implementation (rev 1's R-1 fired on review
    A's third shapes; amended 2026-10-14, review fold: A-1, B-1).
-   **R-2 (the condition hunk).** D-OX-16's claim that every earlier caller
    passes a method under `self_param`. Falsifier: any existing golden changing
    (M-8 says none), or a `cast` assertion in the gate.
-   **R-3 (hand-written C++ operators).** C++ code that declared its own
    operator for an exported class, beside a Carbon impl of the same operator,
    now has two candidates; where they tie, C++ reports an ambiguity (M-22,
    W-211). Carbon's own expressions are unaffected (D-OX-11). Falsifier: a
    Carbon-only expression whose C++ candidate set changes (the
    `carbon_side_user_cpp_operator` split, `userop.carbon`); the C++-side
    ambiguity is accepted, documented with its migration, and filed (rev 1
    treated both sides as a user error; amended 2026-10-14, review fold: A-3).
-   **R-4 (hook reach).** Unqualified lookups of an operator name inside
    `namespace Carbon` C++ code (the support header) reach the non-member walk;
    it only answers for impls whose operand is a Carbon class with that
    namespace as its innermost enclosing namespace. Falsifier: a support-header
    use that changes behaviour; none exists in the goldens (M-8).
-   **R-5 (the lookup-cache contract).** D-OX-21 erases the empty entry that
    `DeclContext::lookupImpl` creates before asking the source, relying on
    lookupImpl not touching that entry afterwards (DeclBase.cpp:1952-1965) and
    on Clang asking again for a missing entry — the contract upstream
    e476a2bd3 relies on too. Falsifier: `carbon_side_then_cpp` failing, or a
    Clang update that changes lookupImpl (re-checked at each advance, §6.3).
    Rev 1's R-5 (unused thunks from Carbon's lookup) is gone (M-10) (amended
    2026-10-14, review fold: A-4).
-   **R-6 (fill drift).** All four goldens need two autoupdate passes (M-12). A
    third pass that changes anything is nondeterminism: stop and diagnose (R26).
-   **R-7 (the row's status).** D-OX-14 records PARTIAL on the overview's
    `ImplicitAs` sentence; the reviews or the leads may read the bullet as
    operators only. Then the row is DONE with W-208 a limit, a one-word and
    one-sentence change in §2.8 (rev 1 recorded DONE with PARTIAL as the
    fallback; amended 2026-10-14, review fold: A-6, B-4).
-   **R-8 (the non-viable marker).** The candidate filter reuses
    `ovl_non_default_multiversion_function`, whose notes Clang skips
    (SemaOverload.cpp `NoteFunctionCandidate`, "Do nothing, these should simply
    be ignored"). Falsifier: a Clang note printed for an exported operator in a
    Carbon-side diagnostic, or a Clang update that changes the kind's handling
    (a V-3a register entry, §2.8).
-   **R-9 (class export diagnostics at a C++ use).** D-OX-9 (3) reports a class
    C++ cannot export at every C++ use of an operator whose impls name it
    (M-20 (e)), as OV-3 does for overload sets. Falsifier: a class that C++
    can export reporting a diagnostic there (that would be a type-export
    defect to file under the type-export row).

### §7.2 Rejected alternatives

-   **§7 A-1: export only `operator+`, the arbiter's case, to flip the row.**
    Rejected as the Goodhart move R16 forbids in spirit: the arbiter would pass
    while the bullet ("Exporting Carbon overloads into C++") stays mostly
    unmet; M-19 shows the other families cost table rows, not mechanisms.
-   **§7 A-2: every impl as a non-member operator.** Rejected: C++ would then
    convert the left operand implicitly, which Carbon's dispatch on `Self` never
    does (D-OX-2).
-   **§7 A-3: hidden friends.** Rejected for the same reason: argument-dependent
    lookup finds a friend through either operand.
-   **§7 A-4: leave `!=` to C++20's rewrite.** Rejected: the default dialect is
    C++17 (M-6), and the rewrite adds reversed `==` candidates Carbon lacks.
-   **§7 A-5: export the witness table's default `NotEqual` function.**
    Rejected for 0.1: it is the interface's function with the impl's specific
    (M-3), which the export path cannot take (it requires a non-generic
    function, export.cpp:891); the C++ `!(a==b)` is the default's body by the
    design text (comparison_operators.md:260).
-   **§7 A-6: export the Carbon operator expression (a thunk that calls through
    the interface) instead of the impl's function.** Rejected for 0.1: for a
    concrete impl both select the same function, and it needs a new thunk kind
    in check/thunk.cpp, a contention file.
-   **§7 A-7: keep OV-3's TODO for an unmappable impl.** Rejected for an
    operand or result with no C++ form at all (D-OX-9 (1) and (2)); kept for a
    class C++ cannot export (D-OX-9 (3), D-OV-18) (amended 2026-10-14, review
    fold: A-1).
-   **§7 A-8: suppress export while Carbon's impl lookup runs (a context
    flag).** Rejected at rev 1 as a new piece of `Context` state; **adopted at
    rev 2** as D-OX-21, because the silent omission and the guard that rev 1
    preferred were each falsified (M-20, M-22, M-23, M-26) (amended 2026-10-14,
    review fold: A-1, A-4).
-   **§7 A-9: export conversions (`As`, `ImplicitAs`) now.** Rejected for 0.1
    (D-OX-18): a design of its own; the row stays PARTIAL for it (W-208).
-   **§7 A-10: a differential `.diff.cpp` oracle per program.** Rejected: the
    agreeing direction needs none (R30(b)), and an oracle would hide the
    divergences D-OX-15 documents.
-   **§7 A-11: record the row DONE by reading the bullet as operators only.**
    Rejected at rev 2 (rev 1's choice): the overview's operator-overloading
    interop section maps `ImplicitAs` to C++ conversions in the same paragraph
    as `BitComplement` to `operator~`, and the only contrary evidence rev 1
    cited was a miscited, unrelated milestone line (D-OX-18) (amended
    2026-10-14, review fold: A-6, B-4).
-   **§7 A-12: a side-effect-free SemIR predicate that predicts whether a class
    exports without a diagnostic, to omit such impls silently (review A's
    proposal for A-1).** Rejected: C++'s own overload resolution completes an
    operand class to rank a candidate, so the predicate would have to reproduce
    `CompleteType`'s whole pipeline — parent scopes, bases, fields, destructor
    and virtual functions — to be exact; and an inexact one is unsafe in the
    unsafe direction, because omitting an impl whose operand class C++ _can_
    form lets C++ pick another impl by a derived-to-base or other conversion,
    B-2's hazard. The class's own diagnostic is what an exported method or
    overload set reports for the same class (M-20, D-OV-18) (amended
    2026-10-14, review fold: A-1).
-   **§7 A-13: `const&` operands for exported operators.** Rejected for 0.1: it
    would remove M-25's by-value divergence and D-OX-5's xvalue, but it departs
    from the exported-method mapping D-OX-2 keeps (export.cpp `PassAsConstRef`
    gives `const&` to arrays only, with a TODO about other types), and it would
    not avoid M-20 (e), because a reference to `Holder` from a `Money` still
    makes C++ consider `Holder`'s constructors.
-   **§7 A-14: export the witness-table entry (the interface's signature at the
    impl's specific) instead of the impl function (review A's proposal for
    A-7).** Deferred, not adopted for 0.1: when the signatures differ the entry
    is a thunk that impl checking generates, which `GetImplMemberFunctionId`
    cannot reach by name and whose export path is unexercised; the observable
    difference is the C++ static type and the accepted operand conversions, a
    divergence of D-OX-15's kind, so 0.1 documents and pins it (M-25,
    `signature_from_impl_function`) (amended 2026-10-14, review fold: A-7).
-   **§7 A-15: export impls with no Carbon class among their types (B-3's
    alternative to narrowing).** Rejected for 0.1: the external source answers
    lookups only in Carbon-owned contexts, and such an impl's operands are found
    by argument-dependent lookup in C++-owned namespaces or none (a primitive);
    filed as W-210, outside the narrowed criterion (amended 2026-10-14, review
    fold: B-3).

## §8 Verification and discharge

`$CB` below is the carbonbuild script directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild`
(not in the repository; its README.md documents it), and `$OUT` a fresh output
directory under the implementer's scratch (amended 2026-10-14, review fold:
B-12).

1.  Build and install this worktree (a full build; the planner and the fixer
    relinked only, so the first full build is the implementer's):
    `$CB/build.sh /home/user/carbon-ox` then `$CB/install.sh
    /home/user/carbon-ox`, whose `carbon version` is stamped with the head.
2.  Fill (commit 4): `$CB/autoupdate.sh /home/user/carbon-ox
    toolchain/check/testdata/interop/cpp/class/export/operator.carbon
    toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon
    toolchain/check/testdata/interop/cpp/class/export/operator_cxx20.carbon
    toolchain/lower/testdata/interop/cpp/class/export/operator.carbon`, three
    times; the third run changes nothing (R26). Then `$CB/gate.sh
    /home/user/carbon-ox`: the trunk count plus four (`1942+4=1946` files at
    f67ab650d), all passing.
3.  Self-test: `python3 fork/conformance/runner.py --self-test` passes after
    `python3 fork/conformance/runner.py --update-readme-table`.
4.  Conformance (commit 5's quote): `XDG_CACHE_HOME=$OUT/cache
    $CB/conformance.sh /home/user/carbon-ox $OUT/conf`: 135 / 0 / 21 over 156,
    49/56 on this branch alone.
5.  The mutants of M-14, rebuilt from the implemented export.cpp with the
    planner's relink recipe (`$F/bin/relink.py <dir>
    obj/toolchain/check/cpp/export.cpp.o=<mutant source>` plus the build's own
    generate_ast and operators objects, `TARGETS=bin/carbon-busybox`) or by a
    second full build, each run with `--filter cpp_operator_export`: each must
    fail the programs M-14 names.
6.  The probes of M-9, M-10 and M-20 to M-30 (`$F/probes/list3.txt`, with
    `$F/bin/probe.sh <install> <cache> <out> $(cat $F/probes/list3.txt)`):
    each prints what §0.2 says.
7.  prek: before each commit, to a fixpoint (a run that changes nothing), with
    R31's heading and list-item counts before and after for every `.md`:

    ```bash
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest \
      uvx prek run --files <that commit's files>
    ```

    and before hand-over, the same with `--all-files` in place of `--files ...`,
    to a fixpoint (R25).
8.  On the merge commit of §3, before commit 6: steps 1, 2 (`gate.sh` only, and
    an autoupdate commit if it is red), 3, 4 and 6 again; commit 6 quotes this
    run, and the id re-scan of the head is run last.

Not run, and why: no hosted gate, autoupdate or conformance (Actions is
disabled, R28); no `bazel test` (no Bazel in the container); no clangd-tidy
(not installed); no run of the programs on macOS; the multi-file thunk-symbol
question (W-204's note) cannot be exercised until W-203 is fixed.

## Hand-off notes for the implementer

-   §2.1 to §2.4 is a measured diff: apply it (`git apply`) rather than
    retyping, check the five sha256 sums §2.1 lists, and keep it identical
    unless a review finding changes it.
-   The previews used substituted file names; the real files' `[[@TEST_NAME]]`
    and TIP lines differ, which is why the fill must run on the real paths.
-   `$F/probes/list3.txt` (69 programs) with `$F/bin/probe.sh` is the quickest
    regression set for an implementation-review finding; `$F/runs-trunk3.log`
    and `$F/runs-v5f.log` are the expected results.
-   Watch R31 in every markdown edit: §1.8 and §2.8 hold arithmetic and code
    spans that a reflow could push to a line start, and the page's two
    table-of-contents markers (§2.7) must be written on the page only.
-   All ten reserved ids are used; a new residue needs a new block from the
    orchestrator (the head).
-   If DD-1 has merged when OX-1 merges trunk, apply §6.2.1's three
    replacements in the merge and drop the amendment block of §2.7.

## Review fold record (rev 2, 2026-10-14)

Every finding of the two rev 1 reviews, its grade, its disposition and where it
is folded. Review A (toolchain soundness) returned REJECT with 1 BLOCKER, 5
MAJOR and 4 MINOR findings; review B (concreteness, process and
cross-workstream) returned REJECT with 2 BLOCKER, 3 MAJOR and 7 MINOR. All 22
are folded and none is rejected outright; A-1 is folded partly by a route other
than the one proposed, with its evidence (R17), and A-7 takes the second of the
two routes its finding offers. Review A's ids are cited as A-1 (its B-1),
A-2..A-6 (its M-1..M-5) and A-7..A-10 (its m-1..m-4), review B's as B-1..B-12
(its OX-B-1..OX-B-12), so that none reads as a measurement; the rejected
alternatives of §7 are always cited as "§7 A-n". The fixer re-opened every cited
location (f67ab650d; DD-1 at fcee90d9b; trunk 44761146d; upstream/trunk
66a250ad9; the SemaOverload.cpp, DeclBase.cpp and markdown_toc.py sources cited)
and re-ran every measurement a finding is about in its own scratch tree (`$F`),
on the trunk install, the planner's `v4` and the rev 2 prototype `v5`; each
reproduction is the §0.2 entry the table names. Rev 2 changes §2.1 to §2.4
(`v5`), §2.5 (a fourth golden and 23 splits) and §2.6 (two programs re-encoded,
two headers), so M-7, M-8, M-12, M-13, M-14, M-16, M-18 and M-19 were re-run and
M-20 to M-30 added; every number those changes could move was re-measured, and
every other number of rev 1 stands as measured.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| A-1 (review A's B-1): D-OX-9's silent omission is not silent; export-time TODOs reject Carbon-only programs, and an unrelated impl breaks a valid C++ use | BLOCKER | Reproduced (M-20: (a) to (d) and (f) compile on trunk, fail on `v4` with the TODOs review A names; (e) and (g) fail on `v4`). Folded: Carbon's own lookup exports nothing (D-OX-21, review A's fix 4 and §7 A-8 adopted), so (a)-(d) and (f) compile; the walks select impls by interface, operator and `Self` from SemIR before any mapping (fixes 2 and 3), so (g) compiles; `IsOperatorSignatureMappable` is replaced by `ClassifyOperatorExport`, whose `IsUnmappableWithoutExport` maps no class or function type (fix 1 in part); the shapes are pinned (fix 5) and M-8, M-12, M-13 re-run (fix 6). Folded by another route for (e): the class is exported and its own TODO stands, as on trunk for an exported function taking `Holder` (`v_trunk_holder_fn1.carbon`) and as OV-3 landed it (D-OV-18), because C++ overload resolution itself completes the operand class, and the exact SemIR predicate fix 1 proposes would have to reproduce `CompleteType`, while an inexact one could let C++ select another impl by conversion (§7 A-12); pinned by `fail_todo_unexportable_operand_class` | Head (Outcome, V-3); §0.1 rows 6, 9; §0.2 setup, M-9, M-20; D-OX-3, D-OX-4, D-OX-9, D-OX-16, D-OX-21; §1.2; §1.5; §1.6; §2.1; §2.5 (`carbon_side_unexportable_class`, `carbon_side_generic_class`, `carbon_side_unrelated_impl`, `cpp_side_unrelated_impl`, `fail_todo_unexportable_operand_class`); §2.7 page; §4; §7 R-1, R-9, A-7, A-8, A-12 |
| A-2 (review A's M-1): the default `!=` aborts the compiler for a non-copyable operand; C++20's `==` triggers it | MAJOR | Reproduced (M-21: `n1` aborts `v4` at export.cpp:2152, `n2` aborts it under `-std=c++20`). Folded as proposed: the arguments are xvalues (`ImplicitCastExpr <NoOp>` to `xvalue`), the three `CARBON_CHECK`s are a diagnostic-free bail under a `Sema::SFINAETrap` that removes the declaration; `move_only_not_equal` (C++17) and the new golden operator_cxx20.carbon's `move_only_equality` (C++20) pin it; `v_ne_nocopy_run.carbon` prints `10 1` in both dialects. D-OX-6's C++20 claims are pinned there too | §0.2 M-6, M-21; D-OX-5, D-OX-6; §1.3; §2.1; §2.5; §4 |
| A-3 (review A's M-2): the guard acts only on `OR_Success`; trunk-accepted programs become ambiguous, one Carbon-only | MAJOR | Reproduced (M-22: `u2` and review B's `gen`, `enum`, `amb` ambiguous on `v4`, `1042`/`3` on trunk; `userop` shows `v4` also changed which C++ function Carbon would call). Folded by fix 1's preferred route: no export during Carbon's lookup (D-OX-21) plus marking exported operators non-viable before `BestViableFunction` (D-OX-11), so every result equals Clang's without them; `u2`, `gen`, `enum`, `amb` and `userop` match trunk on `v5`. Fix 2: the C++-only `u1` is filed as W-211 with the page's migration note and `fail_user_cpp_operator_ambiguous`. Fix 3: D-OX-11, R-3 and the page corrected | §0.2 M-10, M-22; D-OX-11, D-OX-16; §1.5; §1.7; §1.10 W-211; §2.1; §2.5; §2.7 page ("Carbon operator expressions are unchanged", "Hand-written C++ operators"); §2.8 W-211; §7 R-3 |
| A-4 (review A's M-3): a Carbon-only expression poisons later C++ lookups | MAJOR | Reproduced (M-23: `o1` rejected, `o2` accepted on `v4`). Folded as proposed (§7 A-8 adopted): during Carbon's lookup the arm erases the empty entry `lookupImpl` created, as e476a2bd3 does; `o1` compiles on `v5`; `carbon_side_then_cpp` pins it; W-205, D-OX-12 and the page say only C++ code's lookups are cached | §0.1 row 14; §0.2 M-23; D-OX-12, D-OX-21; §1.2; §1.5; §2.1; §2.5; §2.7 page; §2.8 W-205; §7 R-5 |
| A-5 (review A's M-4): no non-member export for a nested operand class | MAJOR | Reproduced (M-24: `50 - Carbon::Outer::Inner::Make(8)` is `invalid operands` on `v4`). Folded as proposed: the namespace test is `getEnclosingNamespaceContext()->Equals(namespace)`; `v_nested.carbon` prints `42 42 42` on `v5`; `non_member_nested` pins it, so D-OX-14's break condition no longer fires on it | §0.2 M-24; D-OX-3; §1.2; §2.1; §2.5; §2.7 page |
| A-6 (review A's M-5): D-OX-18 cites the wrong milestone line and is contradicted by README.md:3679-3681 | MAJOR | Reproduced (milestones.md:169 is a loops bullet; :200 is under "#### Standard library components"; README.md:3679-3681 maps `ImplicitAs` to C++ conversions in the same section). Folded by the first route: the row is recorded PARTIAL now, bounded by W-208; D-OX-18 is rewritten, citing :200 correctly as not bearing on the scope; every :169 citation is gone | Head (Criterion, Outcome, design authority, V-3); §0.3, closing paragraph; D-OX-1, D-OX-14, D-OX-18; §1.5; §1.10; §2.7 page ("Conversions"); §2.8 row, header, W-208; §7 R-7, A-9, A-11 |
| A-7 (review A's m-1): exported operators use the impl function's signature; the docs and §1.1 are wrong | MINOR | Reproduced (M-25: `s1` prints `42 1`, C++ `decltype(m+1)` is `int` against Carbon's `i64`; `v_noncopy_lvalue.carbon` rejected in C++, accepted in Carbon). Folded by the proposal's second route: §1.1, D-OX-2, the page's table and mapping text say "the impl function as declared"; D-OX-15 gains the signature and by-value divergences; `signature_from_impl_function` and `fail_noncopyable_lvalue_operand` pin them; §1.7's "rejects nothing" corrected. The first route, exporting the witness entry, is §7 A-14, deferred with its reason | §0.2 M-5, M-25; D-OX-2, D-OX-15; §1.1; §1.7; §2.5; §2.7 page; §7 A-13, A-14 |
| A-8 (review A's m-2): the compare program cannot tell several operators apart | MINOR | Reproduced (rev 1's pairs give `10` for the listed swaps). Folded as proposed: 100·(a op b) + 10·(a op a) + (b op a), EXPECTs `10 101 100 110 1 11 0` re-derived by hand before any run; the nonmember program's comparisons re-encoded the same way (six lines); M-14's third mutant (`!=`/`<` rows swapped) is caught (compare COMPILE-FAIL, nonmember OUTPUT-MISMATCH) | §0.2 M-14; D-OX-17; §1.8; §2.6 |
| A-9 (review A's m-3): only the C++ half of the conversion divergence is pinned | MINOR | Reproduced (`e13b` pinned nowhere). Folded as proposed: `fail_conversion_carbon_side`; the arithmetic and index program headers cross-reference the divergence goldens | §0.2 M-11; D-OX-15; §2.5; §2.6 |
| A-10 (review A's m-4): stale or inexact measurement and record claims | MINOR | Reproduced (the embedded diff did not hash to rev 1's sha256; pass 2 changed both check goldens; heads moved; DD-1 mentions the reservation; VA-1 unassessed). Folded as proposed: the hash restated as the diff file's, with the five files' sums as the identity check; M-12 restated (at rev 2 pass 2 changes all four goldens); M-16, M-18 and §6.2 re-measured at the 2026-10-14 heads; VA-1's files assessed (none of OX-1's five, none of W-007's three) | Head (Status, Id allocation); §0.2 M-12, M-16, M-18; §2.1; §6.2 |
| B-1: the guard is unsound: Carbon-only code rejected, and Carbon's `!=` goes through an exported operator | BLOCKER | Reproduced (M-22 `gen`, `enum`, `amb`; M-26: `ne.carbon` lowered through `_ZN6CarbonneE3FooNS_5MoneyE.carbon_thunk.__` on `v4`). Folded as proposed: exported candidates are non-viable before `BestViableFunction` (D-OX-11); the default `!=` is registered in `clang_decls`, so it is recognized; and Carbon's lookup exports nothing (D-OX-21). `ne.carbon`'s `CarbonNe` lowers identically to trunk; the lower split `carbon_side_default_not_equal` (after C++ code exported the default `!=`) and the check splits `carbon_side_candidates` pin it; M-8 is restated as covering existing goldens only | §0.1 row 9; §0.2 M-8, M-9, M-10, M-22, M-26; D-OX-5, D-OX-11, D-OX-21; §1.3; §1.7; §2.1; §2.5; §4; §7 R-1 |
| B-2: D-OX-9's argument is false for a result-only unmappable impl; C++ silently selects another impl | BLOCKER | Reproduced (M-27: `sel.carbon` prints `5 1000` on `v4`). Folded as proposed: an operand with no C++ form is omitted; a result with none (or an array) is a deleted declaration with a `void` result, so `sel.carbon`'s C++ use is `overload resolution selected deleted operator '+'`; `fail_deleted_result`, `deleted_result_unselected` and the AST golden's deleted `operator*` pin it; D-OX-9, its break condition, §1.6, the page and the golden comments rewritten, D-OV-18 cited. The fixer found the same hazard for a generic impl (M-28), which no deleted declaration can cover; it is documented under W-202 and pinned by `generic_impl_hidden` | Head (design authority, V-3); §0.2 M-27, M-28; D-OX-9; §1.5; §1.6; §1.10 W-202; §2.1; §2.5; §2.7 page; §2.8 W-202; §4 |
| B-3: impls in the file on C++ types are not exported and not filed; D-OX-14's break condition fires | MAJOR | Reproduced (M-29: `foreign.carbon` fails on trunk, `v4` and `v5`). Folded as proposed: the criterion is narrowed to impls whose `Self` or operand is a Carbon class C++ sees as a record (README.md:3666); W-210 filed (impls with no Carbon class among their types, unary ones on C++ types included), pinned by `fail_todo_non_carbon_operands`, in §1.5, the page's 0.1 limits and the row; D-OX-4 and D-OX-14 decide against the narrowed criterion (with A-6, PARTIAL) | Head (Criterion, Id allocation); §0.2 M-29; D-OX-4, D-OX-14; §1.5; §1.10; §2.5; §2.7 page; §2.8 row, W-210; §7 A-15 |
| B-4: D-OX-18 is miscited and quotes its authority selectively | MAJOR | Reproduced (as A-6; also p000845:184-187 and operators.cpp:42-52). Folded with A-6: milestones.md:200 cited correctly, README.md:3679-3681 and p000845:184-187 quoted in the design-authority list and on the page, the exclusion argued and the row recorded PARTIAL; the scope question is named in D-OX-14's and D-OX-18's break conditions for the re-review and the leads to rule on | Head (Criterion, design authority, V-3); D-OX-14, D-OX-18; §2.7 page; §2.8 W-208; §7 R-7, A-11 |
| B-5: no merge of trunk or post-merge re-verification is scheduled; the records depend on one | MAJOR | Reproduced (§3 had commits 1-6 only; f67ab650d's ORCHESTRATION has no `-ox` row, 44761146d's has; the records cited an amendment §6.2.1 drops; PR 55 and PR 57 change the prelude). Folded as proposed: §3 gains "Between commits 5 and 6" (two implementation reviews, a separate R11 fixer in new commits, refills as their own commits) and "The merge of trunk" with its resolution rules; §8.8 re-verifies the merge commit and commit 6 quotes it; the ORCHESTRATION row is edited on the merge commit; the ledger cites the README text as it stands at the merge commit; §6.2 records the PR 55 and PR 57 prelude paths | D-OX-19; §1.9; §2.8 (row, header, ledger, ORCHESTRATION, README table); §3; §5; §6.2; §8 |
| B-6: M-12 undercounts the positive splits that fail on trunk | MINOR | Reproduced (14 failures, 13 names: `non_member` is a split of two goldens). Folded: at rev 2, 23 failures, 22 names, the lower `non_member` listed, the duplicate name explained | §0.2 M-12 |
| B-7: the "byte for byte" sha256 claim is false for the embedded diff | MINOR | Reproduced (rev 1's embedded text hashed to f4ee6267…). Folded as proposed: the embedded diff is described as prek-normalized, and the five resulting files' sha256 are the identity check (verified by applying the embedded copy) | Head (Status); §2.1 |
| B-8: stale collision heads; the id re-scan cannot tell a mention from an allocation; a row cited by line | MINOR | Reproduced (OP-2 628273444, DD-1 then 6b692aa14 and now fcee90d9b, SC-1 then ae807c7e8 and now 0d7ee5c19; DD-1's four files mention the reservation; D-OX-14 named "row 82"). Folded as proposed: §6.2 and M-16 re-measured; "taken" is mechanical (a ledger `"id"` or an F-017 decision heading on another ref) and the commands print allocations and mentions separately; D-OX-14 names no row by number | Head (Id allocation); §0.2 M-16, M-18; D-OX-14; §6.2 |
| B-9: the merge-time edit leaves DD-1's "implements the first direction" stale | MINOR | Reproduced (fcee90d9b:1113-1116). Folded as proposed: a third replacement, "The 0.1 toolchain implements both directions. In the first, ...", which also says an exported Carbon operator is not a candidate; R31 counts at the merge | §0.3 item 8; D-OX-19; §3; §6.2.1 |
| B-10: the conversion divergence is pinned on the C++ side only | MINOR | Reproduced (as A-9). Folded with A-9: `fail_conversion_carbon_side`, cited in D-OX-15 and on the page | §0.2 M-11; D-OX-15; §2.5; §2.7 page |
| B-11: the design authority omits p006254, whose mechanism the guard modifies | MINOR | Reproduced (p006254:210-216, "Operator calls"). Folded as proposed: cited in the design-authority list, V-3 and D-OX-11, and on the page, which says why an exported impl is not a C++ operator function | Head (design authority, V-3); D-OX-11; §2.7 page |
| B-12: process steps missing or not concrete | MINOR | Reproduced (no `--all-files` pass; no R11 fixer or no-amend rule; no script paths or arguments; no V-3a entries; no toc lines). Folded as proposed: §8 gives `$CB`'s path and every command with its arguments, and a `--all-files` fixpoint before hand-over; §3 names the separate fixer and forbids amending; §2.8's decision-log entry lists four V-3a register entries; §2.7 gives the page's two marker lines by the command that prints them, because prek's `markdown-toc` hook would rewrite the text between a literal pair in this plan (its source cited) | §2.7; §2.8 decision log; §3; §8 |

Corrections the fixer made that no review raised, found while re-measuring: rev
1's `IsExportedCarbonOperator` treated every overloaded-operator member of a
Carbon-owned record as exported, which also matches Clang's implicit members
(`operator=`), so `v5` recognizes exactly the `clang_decls` registrations (§0.3,
closing paragraph); rev 1's M-11(c) and W-205 described C++-only caching, which
after A-4's fold is the whole of it; the ledger maximum moved from W-232 to
W-234 during the fold (SC-1 round 10), and DD-1's head from 6b692aa14 to
fcee90d9b, at which §6.2.1's three sentences were re-read; trunk moved to
3eb7f36f0, whose stamp makes DD-1 PR 58, puts OX-1 after it and gives SC-1
W-233..W-239 and DD-1 W-240..W-244, which the head, D-OX-19, §3 and §6.2 now
cite; and with W-210 and W-211 filed, all ten reserved ids are used, so the head
says what a further residue needs.
